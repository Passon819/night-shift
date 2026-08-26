---
name: schedule
description: Optional — create/remove an OS-level schedule for night-shift run (launchd on macOS, Task Scheduler on Windows) and set keep-awake power settings. Manual `night-shift run` needs none of this.
argument-hint: "e.g. 18:00 ~/work/repoA ~/work/repoB   (or: remove)"
---

Set up (or remove) an automatic schedule for the night-shift launcher on THIS
machine. Scheduling is optional — confirm the user actually wants it, since
manual `night-shift run` before leaving is the default workflow (D5: the flow
binds to the human's command, not the clock).

Collect: run time, repo list, duration cap (--for / --until). Then:

**macOS**: write `~/Library/LaunchAgents/dev.night-shift.run.plist` running
`$HOME/.local/bin/night-shift run <repos> --until <HH:MM>` at the chosen time;
`launchctl load` it. `remove` → unload + delete the plist.

**Windows (Git Bash)**: `schtasks /Create /TN night-shift /SC DAILY /ST <time>`
running `"C:\Program Files\Git\bin\bash.exe" -lc "night-shift run <repos> --until <HH:MM>"`,
with wake-to-run enabled. Advise `powercfg` sleep settings. `remove` →
`schtasks /Delete /TN night-shift`.

Also write the repo list to `~/.config/night-shift/projects` (one path per
line) so a bare scheduled `night-shift run` can fall back to it. Finish by
showing how to verify the schedule and how to watch a run's logs
(`specs/<n>/run.log`).
