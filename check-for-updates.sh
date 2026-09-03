#!/usr/bin/env bash
set -euo pipefail

BRAIN_DIR="${HOME}/.claude/internship-brain"
META="${BRAIN_DIR}/metadata.json"

mkdir -p "${BRAIN_DIR}"

if ! command -v gh >/dev/null 2>&1; then
  echo "[internship-brain] gh CLI is not installed; automatic GitHub freshness check skipped."
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "[internship-brain] gh is not authenticated; run 'gh auth login' to enable GitHub sync."
  exit 0
fi

if [ ! -f "${META}" ]; then
  echo "[internship-brain] Evidence bank has not been synced yet. Run /internship-brain sync."
  exit 0
fi

LAST_SYNC="$(python3 - <<'PY'
import json, os
p=os.path.expanduser("~/.claude/internship-brain/metadata.json")
try:
    with open(p) as f:
        d=json.load(f)
    print(d.get("last_sync",""))
except Exception:
    print("")
PY
)"

if [ -z "${LAST_SYNC}" ]; then
  echo "[internship-brain] No valid last_sync timestamp found. Run /internship-brain sync-recent."
  exit 0
fi

# Cheap freshness signal: search for PRs authored by the authenticated user
# updated after the last recorded sync. The skill performs the deep analysis.
COUNT="$(gh search prs --author=@me --updated=">${LAST_SYNC}" --limit 100 --json number 2>/dev/null | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' || echo 0)"

if [ "${COUNT}" -gt 0 ] 2>/dev/null; then
  echo "[internship-brain] ${COUNT} authored PR(s) changed since the last sync (${LAST_SYNC}). Run /internship-brain sync-recent when useful."
else
  echo "[internship-brain] Evidence bank appears current relative to authored PR updates since ${LAST_SYNC}."
fi
