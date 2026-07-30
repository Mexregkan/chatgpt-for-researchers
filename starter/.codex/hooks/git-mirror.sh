#!/usr/bin/env bash
# git-mirror.sh — PostToolUse hook for Codex (matcher: Bash)
#
# Dual-remote mirror: after Codex pushes to your PRIMARY remote, automatically
# mirror to the secondary remote (e.g. institution GitLab) by running
# scripts/git-push-both.sh. Codex hook matchers select the TOOL (Bash), so this
# script inspects the actual command from the event payload and acts only on
# pushes to the primary remote.
#
# OPT-IN — OFF by default, for the same reason as in the Claude twin: a mirror
# hook pointing at a remote you don't have would fail silently and you would
# believe your work was backed up when it was not. Enable it only after (1)
# configuring scripts/git-push-both.sh with your remotes and identities, and
# (2) adding this block to the "PostToolUse" array in .codex/hooks.json (create
# the key if absent), then trusting the hook via /hooks:
#   { "matcher": "Bash",
#     "hooks": [ { "type": "command",
#                  "command": "bash .codex/hooks/git-mirror.sh",
#                  "timeout": 60 } ] }
#
# CONFIGURE: your primary remote's name as it appears in the push command.
PRIMARY_REMOTE="github"

set -uo pipefail

INPUT=$(cat) || exit 0

CMD=$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    ti = d.get('tool_input') or {}
    c = ti.get('command')
    if isinstance(c, list): c = ' '.join(str(x) for x in c)
    print(c or '')
except Exception:
    print('')
" 2>/dev/null) || exit 0

case "$CMD" in
  *"git push $PRIMARY_REMOTE"*)
    bash scripts/git-push-both.sh 2>/dev/null || true
    ;;
esac
exit 0
