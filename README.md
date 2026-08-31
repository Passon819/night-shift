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

## Two ways to drive it

Skills run **inside a chat session** — planning, reviewing, and supervised runs
where you watch and can interrupt. The launcher runs **with no session at all**
— that is the whole point: no window to keep open, no tokens burned while you
sleep. Same queue semantics either way.

### In chat — skills

| skill | what it does | writes? |
|---|---|---|
| `/night-shift:init` | prepare a repo, once — speckit scaffold, `.agent/` contract, PATH shim | yes |
| `/night-shift:feature <idea>` | plan ONE feature: grill → spec → clarify → plan → tasks → analyze. Stops at `SPEC_READY`; it never signs your approval | yes |
| `/night-shift:status [--only NNN]` | what would run right now, and what blocks everything else | **no** |
| `/night-shift:run-night [--only NNN] [--for 2h] [--max-iter N]` | supervised run in this session; defaults are deliberately small (2h, 5 iterations per feature) | yes |
| `/night-shift:review-morning` | walk the newest run — findings, blocker answers, per-feature merge | yes |
| `/night-shift:schedule` | optional OS-level schedule (launchd / Task Scheduler) | yes |

### In a terminal — the launcher

```bash
night-shift status [repo ...] [--only NNN,NNN]   # show the queue, touch nothing
night-shift run    [repo ...] [flags]            # the unattended run
night-shift version
night-shift run --help
```

| flag | default | notes |
|---|---|---|
| `--for DUR` | `12h` | ceiling, not a quota |
| `--until HH:MM` | — | wall clock, wraps past midnight |
| `--only NNN,NNN` | all | **zero-padded, no spaces** — `002,003` works, `2,3` and `002, 003` do not |
| `--max-iter N` | `20` | per feature |
| `--agent "CMD"` | claude | must read the prompt on stdin |
| `--model` / `--effort` | saved settings | precedence: CLI > `.agent/config` > saved settings |
| `--dry-run` | off | resolve queue + run preflight, then stop |

No repo argument = the current directory. Several repos = run them in order.

`--for/--until` is a **ceiling, not a quota**: an empty queue ends the run
immediately; hitting the ceiling ends the current iteration cleanly, pushes
green work, and the next run resumes from tasks.md.

## Recipes

**Your first feature — before you trust it**

```bash
/night-shift:feature add CSV export to the report screen
#  you: read specs/002-*/spec.md, write status: APPROVED + approved_by:, commit
/night-shift:status                                  # confirm it is queued
/night-shift:run-night --only 002 --for 1h --max-iter 3
```

Watch a few iterations, interrupt, then hand the rest to the launcher.

**"Nothing ran last night"** — `/night-shift:status` names the one thing in the
way of each feature: unsigned spec, unmet `depends_on`, unanswered blockers, or
a run left mid-flight.

**Tonight, only this one** — approve everything, run one:

```bash
night-shift run --only 004 --until 06:30
```

**Two features that touch the same files** — the launcher runs features
sequentially, but each branches from the same base and merges later, so
overlapping change surfaces collide at merge time. Chain them instead:
put `depends_on: [002]` in 003's frontmatter and the launcher stacks 003's
branch on 002's. Anything touching migrations should always be chained.

**Several repos in one go** — one queue after another, ceiling shared:

```bash
night-shift run ~/work/repoA ~/work/repoB --for 8h
```

**A run failed and you want the why** — `FAILED` features get an autopsy block
appended to `docs/report/agent-run-<date>.md` (iterations used, gate tail).
`/night-shift:review-morning` opens it for you.

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
