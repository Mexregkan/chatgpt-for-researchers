#!/usr/bin/env bash
# PostToolUse hook: when a wolframscript/WolframKernel command output contains
# "exited because of a license error", inject a correcting note so the next person
# (human or model) doesn't misdiagnose it as a licensing problem. Non-blocking.
#
# Opt-in: OFF by default. To enable, add this block to the "PostToolUse" array in
# .codex/hooks.json (create the key if absent), then trust the hook via /hooks:
#   { "matcher": "Bash",
#     "hooks": [ { "type": "command",
#       "command": "bash .agents/skills/wolfram-headless/hooks/wolfram-license-notice.sh" } ] }
# (If you installed wolfram-headless in your user scope instead, use the
#  ~/.agents/skills/wolfram-headless/hooks/... path.)
payload=$(cat)
if grep -qi "exited because of a license error" <<<"$payload" \
   && grep -qiE "wolframscript|wolframkernel|\.wls" <<<"$payload"; then
  read -r -d '' MSG <<'EOF'
NOTE (wolfram-headless): "The product exited because of a license error" from wolframscript is
almost never a license problem. It is a mis-reported kernel CRASH, usually a MEMORY SPIKE from a
huge symbolic intermediate. Ruled out as causes in practice: the shell sandbox, ulimit, encoding,
wall-clock time, and the license itself. Do this: (1) confirm the license is valid
[wolframscript -code 'Print[{$LicenseType,DateString[$LicenseExpirationDate]}]']; (2) treat it as a
memory crash -- shrink the symbolic input (substitute solved sub-results BEFORE the heavy step),
chunk huge products, set $HistoryLength=0, or run it in the desktop/Wolfbook kernel which has more
headroom; (3) ensure the .wls uses ASCII escapes (\[Omega] etc.), never literal Greek (it mojibakes
silently and corrupts results). See the wolfram-headless skill.
EOF
  ctx=$(python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' <<<"$MSG")
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":%s}}\n' "$ctx"
  echo "wolfram-headless: 'license error' is a mis-reported crash, not a license issue (see skill)." >&2
fi
exit 0
