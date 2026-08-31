---
name: status
description: Show what the launcher would do right now — the run queue, and for every feature that is NOT queued, the one thing standing in its way (no APPROVED signature yet, unmet depends_on, unanswered blockers, a run left in flight). Strictly read-only — touches no file, changes no status, starts nothing. Use before approving a spec, before scheduling a run, and whenever "why did nothing run?" comes up.
argument-hint: "[--only NNN] [repo ...]"
---

Answer one question: **would a run right now do anything, and if not, why not?**
Read-only. Never write a file, never set a status, never create a worktree.

1. **Get the queue from the launcher, don't recompute it.** Run
   `night-shift status` (pass through any repo args and `--only`). If the shim
   is not on PATH use `"${CLAUDE_PLUGIN_ROOT}/scripts/night-shift" status`.
   The launcher is the source of truth — if your own reading ever disagrees
   with its output, report the launcher's and say where you disagreed.

2. **Explain what that output cannot.** `queue empty (nothing APPROVED)` is
   true but unhelpful. For every feature found (`specs/*/spec.md` plus local
   branches matching `^[0-9]{3}-`), resolve status the way the launcher does —
   worktree `.worktrees/<name>/specs/<name>/spec.md`, then `git show
   <name>:specs/<name>/spec.md`, then the checkout — and say which source you
   read when they disagree, because that mismatch is usually the confusion.

   | status | what it is waiting for |
   |---|---|
   | `DRAFT` / `SPEC_READY` | a human to write `status: APPROVED` + `approved_by:` — you must not do this |
   | `APPROVED` | nothing — it is queued |
   | `IMPLEMENTING` | nothing — resumed before any `APPROVED` feature |
   | `REVIEWING` | nothing — a run stopped mid-finalize; the next run continues it |
   | `READY_FOR_HUMAN_REVIEW` / `READY_WITH_WARNINGS` | the human — `/night-shift:review-morning` |
   | `NEEDS_HUMAN_DECISION` | answers written into `blockers.md`, then status back to `APPROVED` |
   | `FAILED` | the autopsy block in the newest `docs/report/agent-run-*.md` |
   | `DONE` / `CANCELLED` | nothing, ever again |

3. **Flag what will bite the next run**, only when actually present: a
   `depends_on` naming a feature that does not exist or is not in a state the
   launcher accepts (it silently skips the dependent); a non-empty
   `blockers.md`; unchecked `- [ ]` lines in the tasks of a feature that is
   *not* the one being worked (`.agent/gate.sh` may glob more than one spec —
   check what this repo's copy actually does before claiming it is a problem);
   worktrees under `.worktrees/` whose feature is already `DONE`.

4. **Output**: one compact table (feature · status · waiting for), then a
   single line naming the next concrete action for the human. Keep it under
   25 lines — this skill is consulted often, so it must stay skimmable. If the
   queue is non-empty, end by stating what would run and in what order, and
   that `/night-shift:run-night` or `night-shift run` starts it — do not start
   it yourself.
