---
name: init
description: Initialize a repo for the night-shift workflow — speckit scaffold, constitution, .agent/ contract (gate/setup/preflight/guard-rules), gitignore checks, PATH shim. Run once per repo; commit the result so every machine gets it from git clone.
---

Initialize the CURRENT repository for night-shift. Do the steps in order, report
what you did at the end. Ask before anything destructive. If a step is already
done, verify it instead of redoing it.

## 1. speckit scaffold
- If `.specify/` is missing: run `specify init --here --integration claude --script sh`
  (offer `uv tool install specify-cli` if the CLI is absent). If the user's setup
  installs speckit skills globally, project-local duplicates under
  `.claude/skills/speckit-*` may be removed — ask first.
- Constitution: create/extend `.specify/memory/constitution.md` by LINKING to the
  repo's CLAUDE.md sections (never copy rules — two copies always drift). Add the
  night-shift rules: decision ladder, review policy (one pass, report-only),
  launcher owns frontmatter.

## 2. `.agent/` contract (the only per-repo part)
Analyze the repo's real stack (package.json scripts, Makefile, go.mod, compose
files) and generate — using `${CLAUDE_PLUGIN_ROOT}/templates/*.example` as shape
references:
- `.agent/gate.sh` — build + typecheck + lint + tests, per service, fail-fast,
  clear output. MUST exit non-zero on any failure. Prove it by running it.
- `.agent/setup.sh` — prepare a fresh worktree (npm ci / go mod download / …).
- `.agent/preflight.sh` — only if the repo needs running deps (DB, docker
  compose healthchecks). Optional otherwise.
- `.agent/guard-rules` — repo-specific deny regexes (company conventions live
  HERE, never in the plugin). Include a comment header explaining the format.
- `.agent/config` — only if defaults need overriding (NS_REPORT_DIR,
  NS_MAX_ITER, NS_AGENT_CMD adapter for other coding agents).
- **Model/effort (one optional question, always ask it):** "pin a model/effort
  for this repo's night runs?" Build the options from what this repo actually
  used last: read `.worktrees/.last-agent` (machine-local, written by the
  launcher after every session), else the `agent:` line in the newest
  `docs/report/agent-run-*.md`. Offer that pair as the recommended option,
  plus "skip". Skip = write nothing — the launcher then follows claude's saved
  settings (the old behavior). **Sentinel rule:** the literal `saved-settings`
  (seen in report headers/log lines) means "not pinned" — it is NOT a value;
  never offer it and never write `NS_MODEL=saved-settings` /
  `NS_EFFORT=saved-settings`. `.last-agent` omits the `effort=` field entirely
  when effort was not pinned. If chosen, write into `.agent/config`:

  ```bash
  # model/effort หลักของ repo นี้ตอน night run — ลำดับชนะ: CLI --model/--effort > ไฟล์นี้ > claude saved settings
  NS_MODEL=claude-opus-5
  NS_EFFORT=high
  ```

## 3. Spec frontmatter convention
Ensure the spec template (`.specify/templates/spec-template.md`) carries the
night-shift frontmatter fields; if not, document them in the constitution:
`status: DRAFT|SPEC_READY|APPROVED|IMPLEMENTING|REVIEWING|READY_FOR_HUMAN_REVIEW|READY_WITH_WARNINGS|NEEDS_HUMAN_DECISION|FAILED|DONE|CANCELLED`,
`risk: normal|high`, `approved_by:`, `depends_on: []`.
Only a human sets APPROVED; only the launcher moves the run states.

## 4. Git hygiene (hard requirements)
- `.gitignore` must TRACK `specs/`, `.specify/` (its own inner .gitignore already
  excludes machine-local state) — warn loudly if they are ignored.
- Add `.worktrees/` to `.gitignore`.
- On Windows: `git config core.longpaths true` and advise the LongPathsEnabled
  registry setting (worktree + node_modules exceeds MAX_PATH).
- Shell files: LF + executable bit (`git update-index --chmod=+x` on Windows).

## 5. Machine setup
Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-shim.sh"` so the `night-shift`
command is on PATH.

## 6. Commit
Commit everything generated with a message like `chore(night-shift): init repo
for autonomous runs`. Then print a short "what happens next" note: write specs
via /night-shift:feature (or the speckit chain manually), flip status to
APPROVED, run `night-shift run --for 8h` from a NORMAL terminal (not this chat).
