# Internship Brain — Claude Code Bundle

This bundle contains a persistent Claude Code skill for mining your previous internship PRs and turning them into an evidence bank for resumes and interviews.

## Included

- `skills/internship-brain/SKILL.md` — full skill
- `brain-template/` — persistent knowledge-base skeleton
- `CLAUDE.md-snippet.md` — small global context pointer
- `settings-hook.json` — optional SessionStart freshness check
- `check-for-updates.sh` — checks whether authored PRs changed since last sync
- `BOOTSTRAP_PROMPT.md` — paste this into Claude Code with the bundle available and let Claude install/configure it

## Easiest setup

1. Unzip this bundle somewhere.
2. Open Claude Code in that directory.
3. Paste the full contents of `BOOTSTRAP_PROMPT.md`.
4. Let Claude install the files and perform the first sync.
5. Later use:
   - `/internship-brain sync`
   - `/internship-brain sync-recent`
   - `/internship-brain audit-resume`
   - `/internship-brain <your question>`

The skill is designed to preserve evidence and avoid inventing metrics, ownership, disagreements, or impact.
