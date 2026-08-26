---
name: review-morning
description: Walk the human through reviewing an autonomous run — despite the name it works whenever they return. Reads the latest agent-run report, surfaces HIGH items first, handles blocker answers, converts accepted review findings into tasks, and offers per-feature merge.
---

Guide the review of the most recent autonomous run. Target: ≤30 minutes.

1. **Find the report**: newest `agent-run-*.md` in the repo's report dir
   (default `docs/report/`). Show its HIGH/"must look first" block, then the
   per-feature summaries. If no report exists, list branches + spec statuses
   instead.
2. **Per feature in the report**:
   - UI: point to the screenshots dir first — fastest signal.
   - Show `git diff main...<branch> --stat`, offer to open files the report
     flags.
   - Review findings: for each, ask fix / skip / discuss. Accepted fixes →
     invoke `speckit-converge` (or append tasks manually) so they enter the
     next run's queue; set the feature's status back to `APPROVED` if it now
     has pending tasks.
   - Blockers: show each entry from `blockers.md`, record the human's answer
     INTO the file, then set status back to `APPROVED`.
3. **Verdicts**: for an approved feature offer the merge flow (use the
   `finishing-a-development-branch` skill if available, else: merge to main,
   delete worktree + branch, set status `DONE`). For a rejected feature record
   why in the spec and ask whether to CANCEL or replan.
4. **Housekeeping**: offer to commit the report file (WORM — never edit old
   reports), prune merged worktrees (`git worktree prune`), and show the
   remaining queue for the next run.
Keep the human deciding; you execute. Never merge without an explicit yes.
