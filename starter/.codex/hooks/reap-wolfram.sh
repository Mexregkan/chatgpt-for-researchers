#!/usr/bin/env bash
# reap-wolfram.sh — Stop-hook guard against Wolfram batch runs that finished but never exited.
#
# WHAT THIS IS FOR. A headless `wolframscript -file` job can write its results and its
# done-line and then keep burning a core indefinitely. It gets reparented to init/launchd,
# so it outlives the terminal, the session and the agent that started it. You find out when
# the laptop gets hot. See the toolkit README, "Long runs leave things behind".
#
# WIRING. Register it as a Stop hook in .codex/hooks.json:
#
#   "Stop": [{ "hooks": [
#     { "type": "command", "command": "bash .codex/hooks/reap-wolfram.sh", "timeout": 30 }
#   ]}]
#
# ⚠ Codex requires every non-managed hook to be reviewed and TRUSTED before it runs: type
# /hooks, inspect this script, trust it. Re-trust after editing it. Until you do, it does
# not run at all — and unlike a missing tool, that silence comes from Codex, not from here.
#
# If a second agent also works in this repo, point ITS config at this same file — both
# agents leave orphans, and one shared script is one place to fix a bug. (Claude Code:
# register `bash .codex/hooks/reap-wolfram.sh 2>/dev/null || true` under "Stop" in
# .claude/settings.json.)
#
# A Stop hook alone is not enough: it only fires when an agent finishes a turn, so a run
# left going after you close the session is never reached. Pair it with a scheduled job
# every ~30 minutes — the README section gives a launchd plist and a cron line.
#
# WHAT IT CAN AND CANNOT KILL. It delegates to `wolfram-reap`, which kills a
# `wolframscript -file` job ONLY when that job's log already contains the script's own
# completion marker. A run that is still computing has no such marker and is therefore
# untouchable — which is what makes this safe to fire at the end of EVERY turn, including
# turns where you have deliberately left a long job running in the background.
#
# NEVER SILENT-FAILS: if the tool is missing, it says so rather than pretending all is well.
# A cleanup hook that quietly does nothing is worse than no hook, because you stop looking.

REAP="$HOME/.local/bin/wolfram-reap"
[ -x "$REAP" ] || REAP="$(command -v wolfram-reap 2>/dev/null)"
# fall back to the copy in this project, if it was not installed on PATH
[ -n "$REAP" ] && [ -x "$REAP" ] || REAP="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)/scripts/wolfram-reap.sh"

if [ -z "$REAP" ] || [ ! -x "$REAP" ]; then
  echo "reap-wolfram: wolfram-reap not found — orphaned kernels are NOT being reaped." >&2
  echo "              install it on your PATH, or keep scripts/wolfram-reap.sh executable." >&2
  exit 0
fi

"$REAP" --apply --quiet
exit 0
