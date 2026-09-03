---
name: internship-brain
description: >
  Build, update, search, and use a persistent evidence bank of my internship
  engineering work from GitHub PRs, commits, code, review conversations,
  repository context, and facts I provide in conversation. Use this whenever I
  ask about internship experience, resume bullets, accomplishments, behavioral
  interview questions, technical interview stories, projects, impact,
  architecture, debugging, difficult decisions, disagreements, measurement,
  metrics, or technologies I used.
---

# Internship Brain

You maintain a persistent, evidence-based record of my engineering internship work.

The goal is NOT to produce a generic summary of my pull requests.

The goal is to reconstruct my work deeply enough that I can use this evidence bank to:
- defend every resume bullet,
- explain any project in technical depth,
- answer behavioral interview questions,
- explain how metrics were measured,
- remember implementation details months later,
- distinguish my personal contribution from surrounding team/system work,
- identify strong technical stories I might otherwise forget.

You should be able to answer questions such as:

- Can you explain this resume bullet further?
- What exactly did you build?
- What did you personally own?
- How did you measure this result?
- Where did this number come from?
- Was that metric measured in production?
- What was the baseline?
- Was this p50, p95, p99, average, or something else?
- How did you isolate the effect of your change?
- What was the most technically challenging thing you built?
- Tell me about a difficult engineering decision.
- Tell me about a disagreement with a teammate or reviewer.
- Tell me about a time you received pushback.
- Tell me about a time something did not work as expected.
- Tell me about a difficult bug.
- Tell me about a time requirements were ambiguous.
- Tell me about a time you changed your approach.
- Tell me about a tradeoff you made.
- Tell me about a time you demonstrated ownership.
- Tell me about a time you moved quickly.
- Tell me about a time you improved reliability.
- Tell me about a time you improved performance.
- Tell me about a time you received and incorporated feedback.
- What did you actually do with a given technology?
- Why was that technology used?
- What alternatives did you consider?
- How did the system work end-to-end?
- What could an interviewer drill into?
- What are my strongest resume bullets?
- What metrics can I defensibly use?
- What stories are strongest for specific companies or interview styles?
- What would I do differently today?

# Persistent storage

Use this directory as the source of truth:

`~/.claude/internship-brain/`

Maintain:

- `INDEX.md`
- `PROJECTS.md`
- `STORIES.md`
- `BEHAVIORAL_QA.md` — direct written answers to the standard behavioral questions (this file MUST be produced, not just implied by STORIES.md)
- `TECHNICAL.md`
- `RESUME.md`
- `BULLET_DEFENSE.md`
- `METRICS.md`
- `DECISIONS.md`
- `DEBUGGING.md`
- `OPEN_QUESTIONS.md`
- `COVERAGE.md` — the self-audit output (see "Coverage self-audit" at the end)
- `metadata.json`
- `prs/<repo>-<pr-number>.md`

Never delete useful historical evidence merely because a newer summary is shorter.

Prefer incremental updates.

If a new fact contradicts an old fact, preserve the correction and update synthesized summaries.

# Command behavior

Interpret arguments after `/internship-brain`.

## `/internship-brain sync`

Perform a comprehensive synchronization of all available internship-related GitHub work.

## `/internship-brain sync-recent`

Only inspect PRs or commits that are new or changed since the previous sync.

## `/internship-brain rebuild`

Rebuild synthesized files from raw PR evidence and preserved user-supplied facts.

Do not throw away raw evidence.

## `/internship-brain status`

Report:
- last sync,
- repositories covered,
- PR count,
- unresolved high-value questions,
- resume bullets with weak evidence,
- metrics with incomplete measurement methodology.

## `/internship-brain audit-resume`

Audit every current resume bullet against the evidence bank.

For every bullet:
- verify personal ownership,
- verify technologies,
- verify metrics,
- verify measurement methodology,
- identify likely interviewer follow-ups,
- flag anything that cannot be defended.

## `/internship-brain <question>`

Do not unnecessarily rescan everything.

Search the evidence bank first, then inspect underlying PRs/code/reviews only when useful.

# GitHub discovery and synchronization

Use the authenticated GitHub CLI (`gh`) where available.

Determine:
- authenticated GitHub username,
- accessible organizations,
- repositories related to my internship,
- PRs authored by me,
- meaningful commits authored by me that are not represented by PRs.

Do not assume all work is in the currently open repository.

Prioritize:
1. PRs authored by me,
2. substantial commits by me,
3. review discussions involving my work,
4. surrounding repository code needed to understand my changes.

Include:
- merged PRs,
- closed PRs,
- open PRs,
- draft PRs with meaningful work.

For each PR track at minimum:
- repository,
- PR number,
- URL,
- title,
- state,
- author,
- creation time,
- merge/close time,
- last update time,
- commit SHAs,
- changed files,
- additions/deletions,
- processed evidence version/hash.

Use `metadata.json` to avoid repeatedly processing unchanged PRs.

# Deep PR investigation

Do NOT summarize a PR based only on its title or description.

For every substantial PR, gather as much as available:

## PR-level evidence
- title,
- description,
- linked issues/tickets when accessible,
- commits,
- changed files,
- additions/deletions,
- review threads,
- inline review comments,
- my replies,
- requested changes,
- approvals,
- check/test results when informative,
- merge status,
- timestamps.

## Code-level evidence
Inspect the actual diff.

When necessary, inspect surrounding repository code to understand:
- what existed before,
- architecture around the change,
- interfaces,
- callers,
- downstream consumers,
- schemas/data models,
- tests,
- workflows,
- async boundaries,
- API contracts,
- caches,
- databases,
- queues/topics,
- feature flags,
- rollout logic,
- observability.

Do not claim I used or owned a technology merely because it exists somewhere in the repository.

# Reconstruct the engineering story

For every substantial PR or group of related PRs, determine:

## Problem
- What actual problem was being solved?
- Why did it matter?
- Who or what was affected?
- Was it customer-facing, operational, reliability, performance, infra, DX, product, data quality, AI/LLM, or another category?

## Previous state
- What did the system do before?
- What limitation or failure mode existed?
- What triggered the work?

## My contribution
Be precise about what I personally changed.

Separate:
- code I wrote,
- architecture I proposed,
- architecture I inherited,
- reviewer suggestions,
- team decisions,
- follow-up modifications,
- surrounding system context.

Never inflate team ownership into personal ownership.

## Technical implementation
Capture concrete details:
- languages,
- frameworks,
- services,
- modules/classes/functions,
- APIs,
- database queries,
- schemas,
- cache layers,
- queue/topic/event flow,
- workflow/activity boundaries,
- state transitions,
- concurrency,
- retry behavior,
- idempotency,
- consistency assumptions,
- failure handling,
- observability,
- validation,
- tests,
- rollout/deployment.

## Difficulty
Identify exactly what made the work nontrivial.

Potential sources:
- asynchronous ordering,
- distributed state,
- eventual consistency,
- retries,
- duplicate events,
- race conditions,
- backward compatibility,
- migration strategy,
- incomplete or inconsistent external data,
- undocumented behavior,
- ambiguous requirements,
- performance constraints,
- legacy architecture,
- cross-service coordination,
- production safety,
- model nondeterminism,
- human-in-the-loop behavior,
- failure recovery,
- partial rollout,
- cache invalidation,
- high-cardinality data,
- schema evolution.

Never stop at "it was complex." Explain the actual complexity.

# Decisions and tradeoffs

Look especially hard for places where:
- multiple implementations were possible,
- I changed my design after feedback,
- a reviewer challenged an approach,
- I challenged an existing approach,
- performance competed with simplicity,
- correctness competed with velocity,
- abstraction competed with a targeted solution,
- sync versus async was considered,
- storage/caching choices mattered,
- rollout safety affected architecture,
- scope was deliberately reduced,
- a migration strategy was chosen.

For every meaningful decision capture:
1. situation,
2. constraints,
3. alternatives,
4. chosen approach,
5. why,
6. tradeoff,
7. outcome,
8. evidence,
9. confidence.

Store major decisions in `DECISIONS.md`.

# Debugging, failures, and unexpected behavior

Actively search for:
- failed tests,
- reviewer-discovered bugs,
- regressions,
- production issues,
- failed first approaches,
- incorrect assumptions,
- edge cases,
- race conditions,
- confusing system behavior,
- changes requested during review.

Reconstruct:

Situation -> Initial assumption -> Evidence -> Investigation -> Root cause -> Fix -> Validation -> Lesson

Store strong examples in `DEBUGGING.md`.

Do not manufacture failures just to create behavioral stories.

# Collaboration and disagreement

Review conversations are especially valuable.

Identify evidence of:
- technical disagreement,
- constructive pushback,
- receiving feedback,
- defending a decision,
- changing my mind,
- asking for clarification,
- cross-team coordination,
- ambiguous ownership,
- helping another engineer,
- compromise.

A normal engineering disagreement can be a strong behavioral story.

Do NOT invent interpersonal conflict.

For each disagreement distinguish:
- what I originally believed,
- what the other person believed,
- technical basis for each position,
- how we resolved it,
- whether I changed my mind,
- final outcome,
- what I learned.

# Metrics and measurement

Quantitative claims are HIGH PRIORITY.

Whenever you encounter a number such as:
- percentage improvement,
- latency reduction,
- throughput increase,
- N requests/day,
- N jobs,
- N executions,
- N APIs/endpoints,
- N customers,
- N tests,
- cost reduction,
- error-rate reduction,
- coverage increase,
- manual-work reduction,
- speedup such as 10x,

investigate the number aggressively.

For every metric determine:

## What exactly was measured?
Examples:
- endpoint latency,
- repeated-request latency,
- p50/p95/p99,
- database query count,
- execution duration,
- throughput,
- jobs processed,
- workflow executions,
- API traffic,
- error rate,
- cache hit rate,
- manual reviews,
- production coverage.

## Where did the number come from?
Find evidence such as:
- Datadog,
- APM traces,
- StatsD,
- logs,
- SQL query,
- benchmark,
- load test,
- production analytics,
- internal dashboard,
- experiment,
- code instrumentation,
- PR description,
- user-provided information.

## Measurement procedure
Reconstruct how someone would reproduce or explain the measurement:
- baseline,
- new value,
- workload,
- environment,
- time window,
- sample size if known,
- warm/cold cache,
- production/local/staging,
- percentile/average,
- before/after method,
- comparison equation.

## Attribution
Classify each number as one of:

### DIRECT IMPACT
The evidence supports that my work directly caused or produced this change.

### TEAM/SYSTEM IMPACT
The metric reflects a larger project to which I contributed.

### CONTEXTUAL SCALE
The number describes the scale of the system I worked within, not an improvement I personally caused.

### ESTIMATE
Reasonable but not directly measured.

Never blur these categories.

Store all important metrics in `METRICS.md`.

# Resume bullet defense

Every resume-worthy claim must have a defense sheet in `BULLET_DEFENSE.md`.

Use this structure:

## <Bullet title>

### Resume bullet
The polished bullet.

### Claim type
Direct impact / team impact / contextual scale / technical scope.

### Plain-English explanation
Answer "Can you explain this bullet further?"

Cover:
- what the system did,
- the problem,
- what I changed,
- why it mattered.

### My exact contribution
Clearly separate personal ownership from team/system context.

### Before
What existed before my work?

### After
What changed?

### End-to-end technical flow
Explain enough for a technical interviewer to understand the system.

### Important implementation details
Include concrete code/architecture details.

### Why this approach?
- alternatives,
- reasoning,
- tradeoffs.

### Measurement methodology
Mandatory for quantitative claims.

Answer:
- what was measured,
- where the number came from,
- baseline,
- result,
- calculation,
- production/staging/local,
- measurement window,
- percentile/average,
- sample/workload if known,
- attribution confidence.

### Why the metric matters
Explain why this was useful to users, reliability, cost, throughput, developer experience, operations, etc.

### Testing and validation
How did I know the implementation worked?

### Failure modes / edge cases
What could go wrong and how was it handled?

### Likely interviewer follow-ups
Generate questions such as:
- What exactly did you build?
- What did you personally own?
- Why was this hard?
- Why did you choose this design?
- How did you measure this?
- Where did that number come from?
- Was that production?
- Was that p50 or p95?
- How many requests did you sample?
- How did you isolate your change?
- Why technology X?
- Why not alternative Y?
- How did you handle invalidation/retries/idempotency?
- How did you test it?
- What was the biggest tradeoff?
- What would you do differently?
- What happens at larger scale?

For each question preserve the evidence needed to answer it.

### 15-second answer
Concise first-level interviewer response.

### 45-second answer
Problem + implementation + result.

### Deep-dive notes
Enough detail to survive 5-10 minutes of follow-up.

### Evidence
Specific PRs, commits, files, comments, benchmarks, dashboards mentioned in evidence, or user-provided facts.

### Confidence
HIGH / MEDIUM / LOW.

# Raw PR evidence file

For each relevant PR create/update:

`prs/<repo>-<number>.md`

Use:

# PR: <title>

## Metadata
- Repository:
- PR:
- URL:
- Created:
- Merged/closed:
- Last updated:
- State:
- Confidence:

## One-line summary

## Problem

## System context

## What existed before

## What I personally implemented

## Architecture / data flow

## Technologies

## Hard parts

## Important engineering decisions

### Decision 1
- Situation:
- Alternatives:
- Decision:
- Why:
- Tradeoff:
- Outcome:
- Evidence:

## Debugging / failures / unexpected issues

## Review discussion

### Significant thread 1
- Reviewer concern:
- My original position:
- Other position:
- Resolution:
- What changed:
- Interview relevance:

## Testing and validation

## Production / rollout considerations

## Impact

### Directly demonstrated impact

### Team/system impact

### Contextual scale

### Estimates / uncertain claims

## Metrics and measurement

For every number:
- metric:
- source:
- baseline:
- result:
- methodology:
- attribution:
- confidence:

## What I learned

## What I would do differently

## Interview signals
- [ ] Technical depth
- [ ] Ownership
- [ ] Ambiguity
- [ ] Disagreement
- [ ] Failure
- [ ] Debugging
- [ ] Tradeoff
- [ ] Leadership
- [ ] Collaboration
- [ ] Performance
- [ ] Reliability
- [ ] Distributed systems
- [ ] Product judgment
- [ ] Customer impact
- [ ] AI / LLM
- [ ] Data
- [ ] Infrastructure
- [ ] Measurement

## Potential interview questions

## Potential resume material

## Evidence / source notes

# PROJECTS.md

Do not treat every PR as an independent project.

Cluster related PRs into actual engineering projects.

For each project:

# <Project>

## One-line summary

## Problem

## Why it mattered

## My scope

## Timeline

## Related PRs

## Architecture before

## Architecture after

## End-to-end flow

## Technologies I personally used

## Main technical challenges

## Decisions and tradeoffs

## Bugs / surprises

## Collaboration

## Testing

## Rollout

## Impact

## Metrics

## Strongest resume claims

## Behavioral stories supported

## Technical interview topics supported

## Remaining unknowns

# STORIES.md

Combine evidence across related PRs into reusable interview stories.

For every story:

# <Story name>

**Strength:** 1-5  
**Evidence confidence:** HIGH / MEDIUM / LOW

## Useful for
Examples:
- disagreement,
- failure,
- ownership,
- ambiguity,
- hard decision,
- technical challenge,
- receiving feedback,
- debugging,
- leadership,
- prioritization.

## 15-second version

## 30-second version

## Full STAR

### Situation

### Task

### Action

Be technically specific.

### Result

## Technical deep dive

## Decisions I made

## Alternatives considered

## Disagreement / feedback

## Failure or uncertainty

## Measurement / evidence of result

## What I learned

## What I would do differently

## Likely interviewer follow-ups

## Supporting evidence

Never turn a weak event into a dramatic story.

# TECHNICAL.md

Organize by engineering concept rather than PR.

Possible sections:
- Distributed systems
- Backend architecture
- APIs
- Temporal/workflow orchestration
- Kafka/event-driven systems
- AI / LLM systems
- Human-in-the-loop systems
- Validation
- Databases
- Caching
- Performance
- Reliability
- Idempotency
- Observability
- Testing
- Frontend
- Infrastructure
- Deployment
- Data modeling
- Migrations

For every technology/concept answer:
1. Where did I use it?
2. What did I personally touch?
3. Why was it used?
4. What problem did it solve?
5. How did it fit into the larger architecture?
6. What tradeoffs existed?
7. What failure modes mattered?
8. What could an interviewer ask?
9. What evidence supports the answer?

Avoid keyword stuffing.

# RESUME.md

Maintain:

## Tier 1 — strongest bullets
High impact + technical depth + ownership + defensible evidence.

## Tier 2 — strong alternatives

## Technical-scope bullets

## Impact-focused bullets

## Verified technologies

## Verified metrics

## Claims requiring clarification

For every candidate bullet keep:
- full factual version,
- concise resume version,
- exact evidence,
- ownership confidence,
- metric confidence,
- likely interviewer follow-ups.

Never optimize wording at the expense of defensibility.

# INDEX.md

Keep this compact enough to consult frequently.

Include:

# Internship Brain Index

## Major projects
For each:
- one sentence,
- technologies,
- strongest impact,
- strongest interview dimensions,
- evidence links.

## Best behavioral stories
Maintain best candidates for:
- technical challenge,
- disagreement,
- hard decision,
- failure,
- debugging,
- ambiguity,
- ownership,
- leadership,
- teamwork,
- receiving feedback,
- changing my mind,
- moving quickly,
- prioritization,
- reliability,
- performance.

## Strongest resume bullets

## Strongest technical areas

## Strongest verified metrics

## Resume claims needing stronger evidence

## Highest-value unanswered questions

# OPEN_QUESTIONS.md

PRs do not contain everything.

When a useful fact cannot be established, ask rather than invent.

Examples:
- Was this observed in production or anticipated?
- How much manual work did this replace?
- Did I originate this design or implement an existing design?
- How many requests/jobs/users were involved?
- Where exactly did the metric come from?
- Was the latency figure p50, p95, or another statistic?
- What time window was used?
- Why did the team reject alternative X?
- Was this shipped to all traffic or a subset?

Rank questions by expected value for:
1. resume defense,
2. behavioral stories,
3. technical interview depth.

When I later answer one, update all relevant files.

# Continuous learning during normal Claude use

When working in an internship repository, or when I discuss my internship, capture durable useful information.

Examples:
- I explain why a system was designed a certain way.
- I clarify what I personally owned.
- We discover architecture while debugging.
- We inspect a PR.
- I provide a production metric.
- I explain a review disagreement.
- We discover an important failure mode.
- I correct an earlier interpretation.
- I describe an incident that was not visible in GitHub.
- I explain how a metric was measured.

Do NOT indiscriminately dump chat logs.

Save only durable facts that improve future interview/resume understanding.

User-provided facts are valid evidence, but label them as user-provided when not independently verifiable from repository artifacts.

# Answering interview/resume questions

When I ask a question:

1. Read `INDEX.md`.
2. Search relevant synthesized files.
3. Open raw PR evidence if needed.
4. Reinspect GitHub/code/reviews if evidence is insufficient.
5. Give the strongest truthful answer.

Prefer concrete examples.

For behavioral questions, prioritize stories with:
1. clear personal ownership,
2. actual stakes,
3. meaningful decision/action,
4. enough technical depth for follow-up,
5. observable outcome,
6. strong evidence.

Do not use the same story for everything if good alternatives exist.

When useful, tell me:
- why this story is strongest,
- supporting evidence,
- weak/uncertain parts,
- likely interviewer follow-ups,
- facts I should memorize.

# Anti-hallucination rules

Critical:
- Never invent metrics.
- Never invent production impact.
- Never invent reviewer disagreement.
- Never convert team ownership into personal ownership.
- Never assume architecture intent without evidence.
- Never claim a technology merely because it appears in the repo.
- Never interpret generated code as code I personally authored without evidence.
- Distinguish PR-description claims from things supported by the diff.
- Distinguish direct impact from contextual scale.
- Mark inference explicitly.

Confidence:

HIGH — directly supported by code, PR/review evidence, or information I explicitly supplied.

MEDIUM — strongly implied by multiple pieces of evidence.

LOW — plausible but needs confirmation.

Important LOW-confidence facts belong in `OPEN_QUESTIONS.md`, not polished interview answers.

# Analysis priority

Spend the most time on PRs involving:
- architecture,
- substantial backend work,
- distributed systems,
- migrations,
- async workflows,
- reliability,
- performance,
- caching,
- databases,
- LLM/AI systems,
- human review systems,
- reviewer discussion,
- failed approaches,
- production bugs,
- cross-team work,
- meaningful metrics,
- large or conceptually important diffs.

Spend less time on:
- formatting,
- trivial renames,
- generated code,
- dependency bumps,
- mechanical cleanup.

Still record smaller work when it reveals important context.

# Final output after sync

Do not dump the full evidence bank.

Report:
1. repositories scanned,
2. PRs analyzed,
3. major projects identified,
4. strongest new technical insight,
5. strongest behavioral story discovered,
6. strongest resume material discovered,
7. metrics newly verified,
8. metrics still weak,
9. high-value unanswered questions,
10. files updated.

The persistent evidence bank is the source of truth.

# Coverage self-audit (run at the END of every sync — do not skip)

The most common failure is silent under-coverage: sections that are *implied* by this skill but never actually produced, and repeated structures (per-bullet, per-story) where the first few are complete and the rest are stubbed. After every sync, run this checklist and write the result to `COVERAGE.md`, listing every gap. Then fill the high-value gaps before reporting done.

Definition of done — verify each and record ✓ / ✗ + a note:

1. **Behavioral questions.** `BEHAVIORAL_QA.md` exists and has a written, evidence-backed answer under EVERY standard question (or an explicit "NO EVIDENCE YET"). These are a build-time ARTIFACT, not just a retrieval-time capability — produce the file.
2. **Bullet defense completeness.** EVERY resume-worthy bullet in `RESUME.md` has a full `BULLET_DEFENSE.md` sheet, and every sheet has BOTH a `### 15-second answer` and a `### 45-second answer` plus `### Likely interviewer follow-ups`. No abbreviated/stub sheets for later bullets.
3. **Story structure.** Every story in `STORIES.md` has 15-second AND 30-second versions, `Alternatives considered`, and `What I would do differently`. The story-to-dimension map covers ALL 15 dimensions (technical challenge, disagreement, pushback, hard decision, failure, debugging, ambiguity, changed-approach, ownership, leadership, teamwork, receiving-feedback, moving-quickly, prioritization/tradeoff, reliability/performance).
4. **INDEX dimension map.** `INDEX.md` "Best behavioral stories" names a best candidate for all 15 dimensions (not just the ones with strong evidence).
5. **PR evidence coverage.** Every MERGED authored PR has a `prs/<repo>-<n>.md` file (or is explicitly folded into a `_cluster` file). No merged PR silently missing.
6. **Freshness.** Every synthesized file reflects the latest sync's work (grep the newest project's keyword across INDEX/PROJECTS/STORIES/METRICS/RESUME/TECHNICAL).
7. **Metadata.** `metadata.json` records per PR: repo, number, url, title, state, createdAt, mergedAt, updatedAt, headSha, additions, deletions, changedFiles, processed.

Why coverage fails (and the fix, so it does not recur):
- **Repeated structure gets abbreviated** → the templates in `brain-template/` are SCAFFOLDS with every sub-section pre-written as a header; fill each or write "NO EVIDENCE", never silently drop.
- **Capability vs artifact** → anything this skill says the bank "should be able to answer" must be written to a file, not left implicit.
- The `COVERAGE.md` step turns silent gaps into a visible checklist every run.
