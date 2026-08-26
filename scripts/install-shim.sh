#!/usr/bin/env bash
# Installs the `night-shift` command onto PATH (~/.local/bin).
# The shim resolves the CURRENT plugin version at call time, so plugin updates
# never require re-installing the shim. Run once per machine (the /night-shift:init
# skill calls this for you). Works on macOS and Windows Git Bash.
set -eu
BIN="$HOME/.local/bin"
mkdir -p "$BIN"

cat > "$BIN/night-shift" <<'INNER'
#!/usr/bin/env bash
# shim: locate the newest installed night-shift plugin and delegate
set -eu
CANDIDATES=$(ls -dt "$HOME"/.claude/plugins/cache/*/night-shift/*/scripts/night-shift 2>/dev/null | head -1)
[ -z "$CANDIDATES" ] && { echo "night-shift plugin not installed (claude plugin install night-shift@night-shift)" >&2; exit 1; }
exec bash "$CANDIDATES" "$@"
INNER
chmod +x "$BIN/night-shift"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    cat > "$BIN/night-shift.cmd" <<'CMD'
@echo off
"%ProgramFiles%\Git\bin\bash.exe" -lc "night-shift %*"
CMD
    ;;
esac

case ":$PATH:" in
  *":$BIN:"*) echo "night-shift installed at $BIN/night-shift" ;;
  *)
    for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
      [ -f "$rc" ] && ! grep -q '\.local/bin' "$rc" && printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$rc"
    done
    echo "night-shift installed at $BIN/night-shift (added ~/.local/bin to PATH — open a new terminal)"
    ;;
esac
