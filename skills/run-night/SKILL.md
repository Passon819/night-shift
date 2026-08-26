---
name: run-night
description: Supervised in-chat autonomous run (ralph mode) — same queue semantics as the night-shift launcher but inside this session so the human can watch and interrupt. Accepts --only NNN, --for DUR, --max-iter N. Use for the first supervised runs before trusting the headless launcher.
argument-hint: "[--only NNN] [--for 2h] [--max-iter 5]"
---

Run the night-shift loop INSIDE this session (the human is present and
watching). Same rules as the headless runner, with these differences: progress
is narrated here, and the human may interrupt at any time.

Parse args from the invocation (defaults: --for 2h, --max-iter 5 per feature).

## Queue (same semantics as the launcher)
Scan `specs/*/spec.md` frontmatter. Pick features with status `IMPLEMENTING`
first (resume), then `APPROVED`, ordered by number, honoring `depends_on`
(dep must be DONE, or completed this run → stack on its branch). Apply `--only`
filter if given. Empty queue → say so and stop.

## Per feature
1. Create/reuse worktree `.worktrees/<name>` on branch `<name>`; run
   `.agent/setup.sh` in it if present. Set frontmatter `status: IMPLEMENTING`
   (in this supervised mode you act as the launcher, so you DO own frontmatter).
2. Loop (max `--max-iter`, stop at `--for` deadline):
   - Run `bash .agent/gate.sh` in the worktree. Green → break.
   - Red → execute the next tasks per `${CLAUDE_PLUGIN_ROOT}/prompts/implement.md`
     rules (decision ladder, green-only commits, blockers protocol). Narrate a
     one-line summary per iteration.
3. Gate green → run `${CLAUDE_PLUGIN_ROOT}/prompts/finalize.md` steps (one-pass
   review report-only, post-impact, report section into docs/report/agent-run-<date>.md).
4. Set final status (READY_FOR_HUMAN_REVIEW / READY_WITH_WARNINGS /
   NEEDS_HUMAN_DECISION / FAILED), push the branch (never to main), move to the
   next feature.

## End of run
Print: per-feature outcomes, blockers awaiting answers, the report file path,
and iteration counts (so the human can judge whether the unattended launcher
can be trusted next).
