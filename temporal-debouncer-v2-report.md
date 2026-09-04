# Temporal Debouncer v2 - Technical Report

*Source: `backend-csa-coverage/apps/temporal-debouncer-v2` (Go service), `lib/gateway/src/temporal-debouncer` (TS client), plus feature flags and codemods.*

---

## 1. What it is and why it exists

The Temporal Debouncer v2 is a standalone Go service that debounces requests to **start** Temporal workflows. Application code asks it to "start workflow `(namespace, workflow_id, type, args)`", and the service collapses bursts of those requests into a **single** start that carries the freshest arguments. It is a ground-up replacement for the older signal-based v1 (`apps/temporal-debouncer`).

Two invariants define the contract:

1. **Conflation** - at most one pending entry exists per `(namespace, workflow_id)`. Each new request resets a trailing `wait` window and overwrites the entry's payload (latest wins), all bounded by a `max_wait` ceiling fixed at entry creation.
2. **Never interrupt a running run** - if a workflow with the same ID is already executing when the entry comes due, the start is held and re-attempted after that run closes (any closure: completed, failed, terminated, timed out, canceled). The freshest request always eventually executes.

v1 and v2 deploy independently and use **disjoint Valkey key namespaces**, so they coexist safely during migration. v1 listens on port 8082 in local dev; v2 on 8083.

### The v1 -> v2 semantic shift

| | v1 (`temporal-debouncer`) | v2 (`temporal-debouncer-v2`) |
|---|---|---|
| Debounces | signal-with-start calls | workflow **starts** |
| Caller passes | a raw serialized `SignalWithStartWorkflowExecutionRequest` + a caller-supplied `debounceKey` | structured start fields; key derived server-side |
| Workflow code | a `retryOnSignal` loop: body runs once, re-runs on each delivered signal | a single normal start - no signal, no loop |
| In-flight runs | signals interrupt / re-drive the running workflow | never interrupted; start deferred until the run closes |
| Backpressure | none built in | three-state admission + AIMD throttling |
| Storage | Valkey buffer | sharded ZSET timer wheel (512 shards) |

The upshot: v2 is simpler for workflow authors (no signal handling), scales via shard-partitioned dispatch, and respects in-flight executions.

---

## 2. Public API (gRPC)

Defined in `proto/debouncer/v2/debouncer.proto`. Three RPCs:

- **`StartWorkflow(StartWorkflowRequest)`** - the debounced start. Required fields: `namespace`, `workflow_id`, `workflow_type`, `task_queue`, `wait`, `max_wait`. Optional `input` (data-converter-encoded `Payloads`) and `options`. Returns an `Outcome` (`CREATED` vs `CONFLATED`) - informational and racy by nature.
- **`FlushWorkflow(FlushWorkflowRequest)`** - expedite a pending entry: skip the remaining debounce window (or in-flight backoff), making it immediately due. Never creates an entry (no-op if nothing pending); still won't interrupt a running run. Returns `EXPEDITED` / `NO_ENTRY` / `ALREADY_DISPATCHING`.
- **`Health(HealthRequest)`** - returns `{status: "OK"}`.

**Debounce key** is derived server-side as `namespace + "/" + workflow_id` - never caller-supplied. The in-flight-hold semantics depend on this 1:1 relationship with the workflow ID.

**Service-owned `StartOptions`.** Callers may pass execution/run/task timeouts, retry policy, memo, search attributes, header, user metadata, and priority. Deliberately **excluded** because they are service-owned or nonsensical under debouncing: `request_id` (regenerated per dispatch), `workflow_id_reuse_policy` + `workflow_id_conflict_policy` (forced to `ALLOW_DUPLICATE` + `FAIL` - they *are* the semantics), `cron_schedule`, `workflow_start_delay`, completion callbacks, and links.

A removed field is instructive: `caller_team` (field 9) is reserved/retired because callers resolved their team by walking the synchronous call stack, which couldn't see past the tracing decorator wrapping the client - so every request carried the same constant.

---

## 3. Storage: the sharded timer wheel (Valkey)

All persistent state lives in Valkey, mutated **only** by atomic Lua scripts that read time from the Valkey server clock (`redis.call('TIME')`) - eliminating client clock skew.

### Sharding

- **512 fixed shards** (`ShardCount = 512`). A debounce key maps to a shard via FNV-1a-32: `fnv32a(key) % 512`.
- Every key for a shard shares a hash tag `{s:N}`, so all of a shard's structures land on one cluster slot - which makes the multi-key Lua scripts legal and atomic in cluster mode.
- Lease keys are deliberately **un-tagged** (single-key ops, spread across slots).

### Per-shard data structures

| Key format | Type | Holds |
|---|---|---|
| `due:{s:N}` | ZSET | The timer wheel. Member = debounce key, score = epoch-ms of when it is next due. **Every** entry is always present here regardless of state. |
| `dd:{s:N}:<key>` | Hash | The entry itself: `EntryId`, `Payload`, `WorkflowType`, `WaitMs`, `MaxWaitMs`, `MaxDeadlineMs`, `Seq` (conflation generation), `State`, `Attempts`, `CreatedAtMs`, and claim bookkeeping (`ClaimSeq`, `ClaimedAtMs`, `ClaimedBy`). |
| `cnt:{s:N}` | Integer | Exact live-entry count for the shard. Incremented only on create, decremented only on delete. |
| `wait:{s:N}` | ZSET | Index of entries currently held behind a running execution (`WAITING_RUNNING`). Member = key, score = `CreatedAtMs`. Lets you read how many are held and how long the oldest has waited without walking hashes. |
| `lease:s:N` | String (TTL) | Shard lease: value = owning instance ID, `PX` expiry. |
| `inst` | ZSET | Instance registry: member = instance ID, score = last-heartbeat epoch-ms. |

### Entry lifecycle states

- **`DEBOUNCING`** - trailing window running; each new request overwrites payload and re-arms the window.
- **`CLAIMED`** - a dispatcher owns it and a start attempt is in progress. If the dispatcher dies, the claim times out and it becomes due again.
- **`WAITING_RUNNING`** - a run with this ID is in flight; the entry is held and re-attempted on backoff after the run closes.

### The Lua scripts (each atomic)

- **`upsert_entry.lua`** - create or conflate. New key: (respecting a `rejectNew` admission flag) writes the hash with `Seq=1`, `State=DEBOUNCING`, `MaxDeadlineMs = now + maxWait`, scores the due ZSET at `min(now + wait, maxDeadline)`, and `INCR`s the counter -> returns `CREATED`. Existing key: overwrites payload/type/wait fields, bumps `Seq` (`HINCRBY`), and **only if still `DEBOUNCING`** re-scores the window; if `CLAIMED`/`WAITING_RUNNING` the schedule is left alone (the in-flight dispatch picks up the fresh payload, and the `Seq` bump lets completion detect the overwrite) -> returns `CONFLATED`. `EntryId` is never overwritten.
- **`claim_batch.lua`** - the dispatcher's per-shard claim. `ZRANGEBYSCORE(due, -inf, now, LIMIT 0, startLimit+probeLimit)` grabs due members oldest-first; classifies each as a **start** (`DEBOUNCING`) or **probe** (`WAITING_RUNNING`); enforces **separate start/probe budgets** (over-budget entries are "skipped" - pushed forward by `skipDelay` without counting an attempt); heals orphans (member present but hash gone -> removed from `due` and `wait`); for claimed entries pushes the score to `now + claimTimeout` (invisible until timeout), sets `State=CLAIMED`, and returns the rows. Returns `{claimedRows, skippedStarts, skippedProbes}`.
- **`complete_entry.lua`** - terminal outcome after a start attempt, guarded by the `Seq` captured at claim time. If `Seq` unchanged -> delete the entry (`DEL` + `ZREM` from both ZSETs + `DECR` counter) -> `DELETED`. If `Seq` advanced (a new request conflated mid-dispatch) -> reschedule: back to `DEBOUNCING`, `Attempts=0`, recompute `MaxDeadlineMs`, re-score, drop from `wait` -> `RESCHEDULED`. Entry gone -> `GONE`.
- **`rearm_entry.lua`** - schedule the next attempt. Sets `State` to `WAITING_RUNNING` or `DEBOUNCING`, optionally increments `Attempts` (a `countAttempt` flag distinguishes real dispatch failures from capacity deferrals), pushes the due score to `now + delayMs`, and maintains the held index bidirectionally (`ZADD wait` at `CreatedAtMs` on entering `WAITING_RUNNING`, `ZREM wait` on leaving).
- **`flush_entry.lua`** - expedite: if `CLAIMED`, return `ALREADY_DISPATCHING` (don't race the owner); otherwise re-score to `now` -> `EXPEDITED`. No entry -> `NO_ENTRY`.
- **`delete_entry.lua`** - unconditional removal (poison handling). Ignores `Seq` so conflations can't revive a poisoned entry; idempotent (`DELETED` vs `GONE`); decrements the counter only if the hash actually existed.
- **`lease_heartbeat.lua` / `lease_renew.lua` / `lease_release.lua`** - registry + lease maintenance (below).

**Score semantics in one place:** create/conflate-while-debouncing -> `min(now+wait, maxDeadline)`; claim -> `now+claimTimeout`; skip (over budget) -> `now+skipDelay`; rearm -> `now+delayMs`; flush -> `now`. `max_wait` caps the debounce phase only - it does **not** cap time held behind a running execution (the service alerts on, but never drops, long-held entries).

---

## 4. Dispatch: leases, poll ticks, and starts

### Instance discovery and shard leasing (`internal/leases/manager.go`, `internal/storage/leases.go`)

- Each instance heartbeats into the `inst` ZSET every `HeartbeatInterval` (**5s**) via `lease_heartbeat.lua`, which stamps server time, GCs members older than `4 x LivenessWindow` (60s), and returns the count of instances seen within `LivenessWindow` (**15s**). That live count drives per-instance quotas.
- Shard ownership uses **rendezvous hashing**: each instance ranks all 512 shards by `fnv64a(instanceID + "|" + shard)` descending. Because the ranking is stable and different per instance, instances prefer disjoint shards and rarely contend.
- Every `AcquireInterval` (**~2s ± 25%**), an instance targets `ceil(512 / liveInstances)` shards. Under target, it walks its rendezvous order and grabs shards via `SET NX PX` (`lease:s:N`, TTL = `LeaseTTL` **15s**). Over target, it sheds least-preferred shards first.
- Every `RenewInterval` (**5s**), `lease_renew.lua` extends TTL only if `GET == instanceID`; a lost renewal drops the shard immediately so dispatch stops. Dead instances' leases simply expire - no consensus needed. Shards tend to return to the same owner after a blip because rendezvous order is deterministic.

### The poll tick (`internal/debouncer/dispatcher.go`)

Every `PollInterval` (**100ms**):

1. Rescale limiter ceilings to this instance's share: `FleetMaxStartsPerSec / live` and `FleetMaxProbesPerSec / live`.
2. Withdraw tokens for the tick (up to `MaxInFlight`) from the start and probe AIMD limiters, forming a `tickBudget`.
3. Shuffle owned shards, then walk them on `min(PollConcurrency, len(shards))` goroutines (**PollConcurrency = 8**) sharing an atomic cursor. Each poller reserves `ceilDiv(remaining, pollersRemaining)` of the budget per class before each `claim_batch` (batch cap `ClaimBatchLimit` **100**), refunds what it didn't claim, and as pollers finish, the divisor shrinks so the stragglers can spend the leftovers.

`PollConcurrency` exists because the tick is bound by Valkey round-trip latency (one round-trip per shard), not CPU - so the tick isn't serialized behind one shard at a time.

### From claimed entry to `StartWorkflowExecution`

Each claimed entry is handed to a bounded worker pool (`MaxInFlight` **64**; over-saturation re-arms with a 1s delay without counting an attempt). Dispatch (`dispatchEntry`) runs under `context.WithoutCancel` so it survives shutdown, with a `DispatchTimeout` (**10s**) on the attempt and a separate `SettleTimeout` (**5s**) on writing the result back - so a start that burns its whole deadline can still settle cleanly:

1. **Probe first (only for `WAITING_RUNNING`):** a cheap `DescribeWorkflowExecution` (`IsWorkflowRunning`). Still running -> re-arm `WAITING_RUNNING` on backoff, no start. Not running -> fall through.
2. **Start:** `StartWorkflow(ctx, req, requestID(entry), identity)` where identity is `temporal-debouncer:<instanceID>`. Outcomes:
   - **Success** -> `complete_entry` (delete or reschedule if conflated mid-flight).
   - **`WorkflowExecutionAlreadyStarted`** -> re-arm `WAITING_RUNNING` on backoff (the designed hold, not a failure).
   - **`ResourceExhausted`** -> limiter `backoff()` (halve rate) + re-arm to prior state.
   - **Poison** (`InvalidArgument` / `NotFound` / `PermissionDenied`) -> increment attempts; drop after `PoisonMaxAttempts` (**5**), else re-arm.
   - **Other** -> re-arm on backoff.

### Request-ID dedup (why at-least-once is safe)

Dispatch is at-least-once (a dispatcher can start a workflow, then die before settling; or a claim can time out and get re-claimed). The Temporal `request_id` is a deterministic UUIDv5:

```
uuid.NewSHA1(NameSpaceOID, "temporal-debouncer-v2|" + DebounceKey + "|" + EntryID + "|" + ClaimedSeq)
```

- `EntryID` is minted once when the entry is created (cryptographic random, `rand.Text()`) and persists across re-claims - so a **new incarnation** of the same key can never reuse a prior one's request IDs. This matters because Temporal keeps deduping against a run's request IDs long after the run closes, and a silent repeat there is a swallowed start.
- `ClaimedSeq` distinguishes dispatch attempts within one incarnation.

Net effect: a re-dispatch of the *same* attempt dedupes into a no-op at Temporal (surfaced via a `RequestIDDeduped()` flag); a genuinely new generation always gets fresh IDs.

### Re-arm backoff

```
delay = min(5s << min(attempts, 6), 5m);  jitter = 0.8 + 0.4*rand()  // ±20%
```

So 5s, 10s, 20s, 40s, 80s, 160s, capped at 5m, decorrelated by jitter so probe herds don't synchronize. `WAITING_RUNNING` entries decay toward 5-minute probe intervals while they wait for a long run to close.

**Claim timeout = 30s** is chosen to exceed `DispatchTimeout + SettleTimeout` (15s), so re-claims only happen after a genuine stall/death, never while a live dispatcher is making progress.

---

## 5. Backpressure

### Three-state admission (`internal/debouncer/admission.go`)

A sampler reads occupancy every `SampleInterval` (**1s**) - both `countFraction` (summed shard counters / `MaxEntries`, default **10M**) and `memFraction` (Valkey max-memory usage) - and sets an atomic state the ingest hot path reads cheaply:

- **GREEN** - accept everything.
- **YELLOW** - `RejectNew()` true: shed brand-new keys, but still accept conflating overwrites (they don't grow the count and they preserve the freshest-args promise).
- **RED** - `RejectAll()`: reject even overwrites.

Thresholds have hysteresis and are asymmetric (escalate greedily, de-escalate one step at a time):

| | count enter / exit | mem enter / exit |
|---|---|---|
| YELLOW | 0.70 / 0.65 | 0.65 / 0.60 |
| RED | 0.95 / 0.90 | 0.80 / 0.75 |

At the gRPC layer, RED -> `ResourceExhausted` "ingest rejected: buffer at capacity"; a YELLOW rejection of a new key -> `ResourceExhausted` "new entry rejected: buffer above shedding threshold".

### AIMD rate limiter (`internal/debouncer/limiter.go`)

Token bucket whose refill rate adapts to Temporal pushback. Additive increase (`+increase` tokens/sec per clean second: **5** for starts, **10** for probes), multiplicative decrease (`backoff()` halves the rate, floor 1/sec) on `ResourceExhausted`. Two independent limiters - **starts** and **probes** - each with its own fleet ceiling (`FleetMaxStartsPerSec` **1000**, `FleetMaxProbesPerSec` **2000**) divided by live-instance count, so neither class starves the other. Probes get the higher ceiling because a `conflict=FAIL` rejection is a cheap mutable-state read with no history writes.

---

## 6. Configuration

| Env var | Default | Purpose |
|---|---|---|
| `PORT` | `8083` | gRPC port (v1 uses 8082 locally) |
| `VALKEY_ADDRESS` | `localhost:6379` | Valkey server |
| `VALKEY_PASSWORD` | `dev-pass` | Valkey password |
| `VALKEY_DB` | `0` | Valkey database number |
| `TEMPORAL_ADDRESS` | `localhost:7233` | Temporal server |
| `TEMPORAL_NAMESPACE` | `default` | Temporal namespace |
| `FLEET_MAX_STARTS_PER_SEC` | `1000` | Fleet-wide ceiling on starts |
| `FLEET_MAX_PROBES_PER_SEC` | `2000` | Fleet-wide ceiling on liveness probes |
| `MAX_BUFFERED_ENTRIES` | `10000000` | Capacity admission thresholds scale on |
| `POLL_CONCURRENCY` | `8` | Shards claimed in parallel per poll tick |

Other internal defaults: `PollInterval` 100ms, `ClaimTimeout` 30s, `ClaimBatchLimit` 100, `MaxInFlight` 64, `DispatchTimeout` 10s, `SettleTimeout` 5s, `PoisonMaxAttempts` 5, `PendingAgeAlertThreshold` 24h, `LeaseTTL`/`LivenessWindow` 15s, `HeartbeatInterval`/`RenewInterval` 5s, `AcquireInterval` ~2s±25%.

**Boot** (`cmd/server/main.go` -> `internal/app/app.go`): parse flags/env -> logger (JSON if `GO_ENV=production`) -> Datadog statsd (`temporal_debouncer_v2`) + tracer -> Valkey client (ping, 5s) -> Temporal client (health, 5s) -> instance identity (`hostname + "-" + uuid[:8]`) -> construct lease manager, admission, dispatcher, and the gRPC service -> run their loops -> serve gRPC -> graceful shutdown on SIGINT/SIGTERM.

---

## 7. How callers use it (TypeScript client)

`TemporalDebouncerV2Service` (`lib/gateway/src/temporal-debouncer/temporal-debouncer-v2.service.ts`) exposes `startWorkflow(req)` and `health()` over gRPC/Connect (`LOOP_TEMPORAL_DEBOUNCER_V2_URL`). Callers pass structured fields (`namespace`, `workflowId`, `workflowType`, `taskQueue`, `input`, `wait`, `maxWait`, `options`); Temporal SDK options are pre-serialized to `Uint8Array` with `@temporalio/proto` and decoded server-side with `@bufbuild/protobuf` (wire-compatible).

Error mapping matters for correctness:
- **`TemporalDebouncerShedError`** (`ResourceExhausted`) - shed under backpressure. **Not** auto-retried or redirected to a direct Temporal start; shedding signals Temporal overload, so redirecting would defeat it. Caller owns the retry.
- **`TemporalDebouncerUnavailableError`** (`Unavailable`/`Internal`/`DeadlineExceeded`/`Unimplemented`) - the debouncer itself is down; caller *may* degrade to a direct, undebounced start.
- Other codes (`InvalidArgument`, `FailedPrecondition`) propagate as caller bugs.

Both clients are provided/exported by `TemporalDebouncerModule` (NestJS) so v1 and v2 coexist during migration.

---

## 8. Migration tooling

### Feature flags

- **`use-temporal-debouncer`** (bool, default `false`) - gate v1.
- **`use-temporal-debouncer-v2`** (bool, default `false`) - gate v2 per workflow type / tenant, with LaunchDarkly exclusion targeting to protect workflows that genuinely need signals.
- **`debounce-service-run-if-last-run-is-after-timestamp-ttl-minutes`** (number, default `10`) - skip re-running if the last run completed within this window.

### Codemods (`scripts/codemods/transforms/`)

- **`convert-signal-with-start-to-start-workflow-debounced.codemod.ts`** - rewrites `signalWorkflowWithStart(...)` -> `startWorkflowDebounced(...)`, dropping `signal` / `signalArgs` / `excludeSignalArgsFromDebounceKey` and defaulting `{wait: 1s, maxWait: 10s}`. Skips workflows that require signals (an `EXCLUDED_WORKFLOW_TYPES` list) and anything it can't resolve statically (spreads, variable workflow types) - those are reported for manual review.
- **`retire-signal-loop-for-debounced-workflows.codemod.ts`** - rewrites the workflow body's `retryOnSignal(...)` -> `retryOnRetiredSignal(...)`, only for converted workflows. Because v2 delivers no signal, a plain `retryOnSignal` loop would wait forever; `retryOnRetiredSignal` wraps it in a Temporal `patched()` guard so **new** executions run the body once while **in-flight** executions (whose history predates the patch) keep the old loop. A `KEPT_WORKFLOW_TYPES` list is left untouched.

Together these mechanize the "signal-loop -> single debounced start" transition without breaking running histories.

---

## Appendix: end-to-end flow of one start

1. Caller invokes `startWorkflow` -> gRPC `StartWorkflow` -> validate -> derive key `ns/wfid` -> admission check.
2. `upsert_entry.lua` creates (`CREATED`) or conflates (`CONFLATED`) the entry in shard `fnv32a(key)%512`, scoring the due ZSET at `min(now+wait, maxDeadline)`.
3. The shard's leased owner, on a 100ms poll tick, `claim_batch`es the entry once due, marks it `CLAIMED` (score pushed `now+30s`), and hands it to the dispatch pool.
4. Dispatcher calls Temporal `StartWorkflowExecution` with a deterministic `request_id`. On success -> `complete_entry` deletes it (or reschedules if a newer request conflated mid-flight). On `AlreadyStarted` -> `rearm` to `WAITING_RUNNING` on jittered backoff, re-probed until the run closes, then started with the freshest args.
5. Backpressure (admission + AIMD) throttles ingest and outflow throughout; at-least-once dispatch is deduped at Temporal via the stable `request_id`.
