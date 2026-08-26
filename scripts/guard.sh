#!/usr/bin/env bash
# night-shift guard — PreToolUse hook (Bash|Write|Edit)
#
# Active ONLY during night-shift runs (NIGHT_SHIFT=1, exported by the launcher).
# In normal interactive sessions this exits immediately at line one — zero cost.
#
# Generic, company-agnostic rules live here. Per-repo rules are read from
# $NIGHT_SHIFT_REPO/.agent/guard-rules (one extended-regex per line, # comments).
# Exit 2 blocks the tool call; the agent sees the reason and must escalate
# (write a blocker) instead of acting — dangerous actions are fail-closed
# even though the run itself uses bypass permissions.

[ "${NIGHT_SHIFT:-0}" = "1" ] || exit 0

INPUT="$(cat)"
# Claude Code guarantees node (it runs on it) — the one JSON parser we can rely on
PARSED="$(printf '%s' "$INPUT" | node -e '
let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
  try{const j=JSON.parse(d);
    const t=j.tool_name||"";
    const c=(j.tool_input&&(j.tool_input.command||j.tool_input.file_path))||"";
    process.stdout.write(t+"\n"+c);
  }catch(e){process.stdout.write("\n");}
});' 2>/dev/null)"
TOOL="$(printf '%s' "$PARSED" | head -1)"
TARGET="$(printf '%s' "$PARSED" | tail -n +2)"
[ -z "$TARGET" ] && exit 0

deny() { printf 'night-shift guard: blocked (%s). Write a blocker entry instead of retrying.\n' "$1" >&2; exit 2; }

if [ "$TOOL" = "Bash" ]; then
  C="$TARGET"
  # protected branches & history rewrites
  printf '%s' "$C" | grep -qE 'git[[:space:]]+push[^|;&]*[[:space:]](main|master|develop)([[:space:]]|$)' && deny "push to protected branch"
  printf '%s' "$C" | grep -qE 'git[[:space:]]+push[^|;&]*([[:space:]](--force|--force-with-lease|-f|--delete|--mirror))' && deny "force/delete push"
  # destructive filesystem outside the worktree
  printf '%s' "$C" | grep -qE 'rm[[:space:]]+-[a-zA-Z]*[rf][a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+("|'"'"')?(/|~|\.\.)' && deny "rm -rf outside worktree"
  # infra & destructive SQL (additive migrations never need these; escalate instead)
  printf '%s' "$C" | grep -qE '(^|[[:space:];&|])(kubectl|terraform|helm)[[:space:]]' && deny "infra tool during autonomous run"
  printf '%s' "$C" | grep -qiE '(DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)|TRUNCATE[[:space:]]|DELETE[[:space:]]+FROM)' && deny "destructive SQL"
  printf '%s' "$C" | grep -qE 'prisma[[:space:]]+migrate[[:space:]]+reset' && deny "prisma migrate reset"
  # per-repo extra rules
  RULES="${NIGHT_SHIFT_REPO:-}/.agent/guard-rules"
  if [ -n "${NIGHT_SHIFT_REPO:-}" ] && [ -f "$RULES" ]; then
    while IFS= read -r rule; do
      case "$rule" in ''|'#'*) continue ;; esac
      printf '%s' "$C" | grep -qE "$rule" && deny "repo rule: $rule"
    done < "$RULES"
  fi
elif [ "$TOOL" = "Write" ] || [ "$TOOL" = "Edit" ]; then
  # absolute writes must stay inside: worktree, the repo (report/specs), or tmp
  case "$TARGET" in
    /*)
      case "$TARGET" in
        "${NIGHT_SHIFT_WORKTREE:-/__none__}"*|"${NIGHT_SHIFT_REPO:-/__none__}"*|/tmp/*|/private/tmp/*) ;;
        *) deny "write outside worktree/repo: $TARGET" ;;
      esac ;;
  esac
fi
exit 0
