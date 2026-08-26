# night-shift: finalize (runs once, after the gate is green)

You are the finalize step of an unattended run. CONTEXT above names the feature
dir, repo root, and the report file (absolute path, in the main checkout — you
may write to it). The gate has passed. Do these four things, then stop.

## 1. Self code-review — ONE pass, report-only by default
Review the full branch diff (`git diff main...HEAD` or the base named in
plan.md). Use the `/code-review` skill at medium effort if available; otherwise
review manually for: spec mismatches, bugs waiting to happen, duplicated or
overcomplicated code, impact on existing code.
- A finding that makes the gate or the spec FALSE (broken acceptance criterion,
  wrong error envelope, missing required audit event) → FIX it now, re-run the
  gate, note the fix.
- Every other finding → do NOT fix. Record it for the report with severity
  (Medium/Low/Info), reasoning, and impact. The human decides tomorrow.
- Never loop until the review is clean. One pass only.

## 2. Post-impact check
`git diff --name-only <base>...HEAD` → for each changed shared file (exported
symbol, shared component, API handler, migration), find its consumers (grep /
knowledge tools) and RUN the consumers' tests too, not only this feature's.
Note what you ran in the report.

## 3. Evidence (UI features only)
If the feature has UI screens and `.agent/screenshot.sh` exists, run it (it
captures the declared states into `<feature_dir>/screenshots/`). Otherwise skip.

## 4. Append the report section
Append to the report file (do not rewrite earlier content):
```
## <feature> · <READY_FOR_HUMAN_REVIEW | READY_WITH_WARNINGS>
Implemented: T001–T0xx (blocked: ...)
Changed: N files · migrations · new APIs
Tests: ✓/✗ counts (new: N) · typecheck · lint · contract
Code Review: findings with severity + recommendation (fixed: which)
Impact: consumers checked + their test results
Screenshots: path (UI only)
Decisions: count → specs/<feature>/decisions.md
Suggest manual test: ...
```
If you recorded any warning-level item, also create the empty marker file
`<feature_dir>/.warnings` (the launcher uses it to set READY_WITH_WARNINGS).
Commit any files you changed inside the worktree (review fixes, screenshots).
Do NOT push; do NOT edit spec.md frontmatter.
