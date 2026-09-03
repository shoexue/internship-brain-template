Set up my persistent Claude Code "Internship Brain" system using the files in the attached/downloaded `internship-brain` bundle.

Do the setup yourself rather than only explaining it to me.

Requirements:

1. Install the skill by copying:
   `skills/internship-brain/SKILL.md`
   to:
   `~/.claude/skills/internship-brain/SKILL.md`

2. Create:
   `~/.claude/internship-brain/`
   and initialize its evidence-bank files from the `brain-template/` directory.

3. Copy:
   `check-for-updates.sh`
   to:
   `~/.claude/internship-brain/check-for-updates.sh`
   and make it executable.

4. Add the contents of `CLAUDE.md-snippet.md` to my global `~/.claude/CLAUDE.md`.
   Preserve anything already in that file. Do not duplicate the section if it is already present.

5. Merge the SessionStart hook from `settings-hook.json` into my Claude Code settings rather than overwriting unrelated settings or hooks.
   Preserve all existing configuration.

6. Verify that `gh` is installed and authenticated.
   If it is installed but not authenticated, tell me the exact command I need to run.
   Do not fabricate access.

7. After installation, run the equivalent of:
   `/internship-brain sync`

   Search all GitHub repositories available to my authenticated account for internship-related PRs authored by me. Do not limit yourself to the currently open repository.

8. Deeply inspect substantive PRs:
   - diff,
   - surrounding code when needed,
   - commits,
   - review threads,
   - reviewer pushback,
   - my responses,
   - tests,
   - architecture,
   - failure handling,
   - metrics,
   - measurement methodology.

9. Build the persistent evidence bank so that later I can ask things like:
   - "Can you explain this bullet further?"
   - "How did you measure this?"
   - "Where did the 60-70% number come from?"
   - "Tell me about a disagreement."
   - "Tell me about a difficult decision."
   - "What was my hardest technical problem?"
   - "What did I personally own?"
   - "Why did we use this technology?"
   - "What alternatives did I consider?"
   - "What would I do differently?"
   - "Give me my strongest resume bullets."

10. Be extremely strict about evidence:
    - distinguish personal ownership from team ownership,
    - distinguish direct impact from contextual system scale,
    - never invent metrics,
    - never invent disagreements,
    - never invent architecture rationale,
    - flag weak claims in OPEN_QUESTIONS.md.

11. For every quantitative resume claim, capture:
    - exact metric definition,
    - source,
    - baseline,
    - result,
    - whether it was prod/staging/local,
    - p50/p95/p99/average when known,
    - sample/workload when known,
    - how the improvement was calculated,
    - how confidently the result can be attributed to my change.

12. When you finish, give me only a concise setup/sync summary:
    - what was installed,
    - repos scanned,
    - PRs analyzed,
    - major projects found,
    - strongest resume evidence,
    - strongest behavioral story,
    - metrics verified,
    - important unanswered questions.

Do not stop after creating the files. If GitHub access works, perform the first synchronization now.
