# night-shift 🌙

**Plan by day. Run autonomously while you're away. Review from a single report.**

A Claude Code plugin that turns approved specs into working, tested, reviewed,
pushed branches — while you are not at the keyboard. Day/night is a metaphor:
the run binds to *your command*, not the clock (plan in the morning, run in the
afternoon, review at night — same flow).

> วางแผนตอนอยู่หน้าจอ → ปล่อย agent ทำ+ตรวจเองตอนไม่อยู่ → กลับมาอ่าน report
> ฉบับเดียวแล้วตัดสิน — ไม่ต้องนั่งเฝ้าตอบคำถามระหว่างทาง

## The loop

```
plan (you + chat)        run (no chat needed)             review (you + chat)
─────────────────        ────────────────────             ───────────────────
grill → spec →           night-shift run --for 8h         /night-shift:review-morning
clarify → plan →         ├─ per APPROVED spec:            ├─ screenshots → diff →
tasks → analyze          │   worktree → implement loop    │   findings → blockers
→ YOU set                │   until gate.sh passes         └─ you merge (or not)
  status: APPROVED       │   → one-pass self review
                         │   → impact check → report
                         └─ push branch (never main)
```

- **State lives in files** — spec frontmatter is the state machine *and* the
  queue; tasks.md is cross-context progress. Kill it anytime; it resumes.
- **Gates are scripts** (`.agent/gate.sh` per repo) — "done" is never a vibe.
- **Guard hook** blocks protected-branch pushes, destructive SQL, `rm -rf`
  escapes and infra tools even though runs use bypass permissions — and it is
  inert in your normal sessions (`NIGHT_SHIFT=1` only).
- **Review is advice, not a fix loop** — one pass; only findings that falsify
  the gate/spec get fixed autonomously. You decide the rest next morning.

## Install (per machine)

```bash
claude plugin marketplace add Passon819/night-shift   # or a local path
claude plugin install night-shift@night-shift
```

## Per repo (once, then committed — clones get it for free)

```
/night-shift:init
```

Scaffolds [spec-kit](https://github.com/github/spec-kit) if missing, writes the
`.agent/` contract (gate/setup/preflight/guard-rules), fixes gitignore traps,
installs the `night-shift` shim on PATH.

## Use

```bash
# in chat: plan one feature end-to-end (or invoke each speckit skill manually)
/night-shift:feature  <your idea>
# you: review artifacts, set status: APPROVED in specs/NNN/spec.md, commit

# in a NORMAL terminal (not the chat) — this is the whole trick:
night-shift run ~/work/repoA ~/work/repoB --for 8h
night-shift run --only 004 --until 06:30
night-shift status            # show the queue, touch nothing

# back in chat, when you return:
/night-shift:review-morning
```

`--for/--until` is a **ceiling, not a quota**: an empty queue ends the run
immediately; hitting the ceiling ends the current iteration cleanly, pushes
green work, and the next run resumes from tasks.md.

Supervised trial mode (watch it work before trusting it):
`/night-shift:run-night --only 002 --for 2h`

## Cross-platform

macOS and Windows (Git Bash — which Claude Code already requires) with the same
two install commands. The launcher picks `caffeinate` vs PowerShell keep-awake,
`launchd` vs Task Scheduler (`/night-shift:schedule`, optional) by itself.
Scripts are plain portable bash: LF, no `flock`, bundled timeout fallback.
Windows note: `/night-shift:init` sets `core.longpaths` (worktree + node_modules
exceeds MAX_PATH).

## Swapping the coding agent (codex / glm / kimi / ...)

Everything that matters is agent-agnostic markdown + bash. The single Claude
binding is the iteration command — override it per repo in `.agent/config`:

```bash
NS_AGENT_CMD='codex exec --full-auto'   # must read the prompt on stdin
```

(The guard hook is Claude Code's mechanism; other agents bring their own
sandboxing.)

## Files it expects in a repo

```
specs/NNN-slug/spec.md     frontmatter: status/risk/approved_by/depends_on
  plan.md tasks.md decisions.md blockers.md screenshots/ run.log
.agent/gate.sh setup.sh [preflight.sh guard-rules config screenshot.sh]
.specify/                  spec-kit scaffold (committed!)
docs/report/agent-run-<date>.md   append-only run reports
```

Only a human ever writes `status: APPROVED`. Only the launcher moves run states.

## License

MIT
