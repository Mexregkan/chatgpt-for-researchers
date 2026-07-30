#!/usr/bin/env bash
# promise-checker.sh — Stop hook for Codex
#
# Fires when Codex finishes a response. Scans the end of the session transcript
# for "performative compliance" phrases — cases where the model says it saved,
# noted, or remembered something without actually editing a file. If found, the
# hook blocks the stop with a reason, which Codex receives as a continuation
# prompt: it then either actually writes the file or corrects its wording.
#
# Adapted from flonat/claude-research (github.com/flonat/claude-research) via the
# claude-for-researchers starter; ported to Codex's hook system.
#
# HONEST CAVEAT: this parses the session transcript (transcript_path from the
# hook event) with grep-level heuristics, because the rollout file format is an
# internal detail that may evolve. It FAILS OPEN: on anything unexpected it
# stays silent. If it ever misfires repeatedly, disable it in .codex/hooks.json.
#
# SETUP: referenced from .codex/hooks.json (shipped in this starter). Trust it
# via /hooks before it will run.

set -uo pipefail

INPUT=$(cat) || exit 0

TRANSCRIPT=$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    print(json.load(sys.stdin).get('transcript_path') or '')
except Exception:
    print('')
" 2>/dev/null) || exit 0
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || exit 0

# Look only at the tail of the transcript (≈ the current turn).
TAIL=$(tail -c 200000 "$TRANSCRIPT" 2>/dev/null) || exit 0

# Phrases that indicate the model claims to have persisted something.
PROMISE_RE="I'll remember|I've noted|I've saved|I've recorded|I'll note|I've logged|I'll keep that in mind|I've updated|I've added that|saved to memory|I've made a note"

FOUND=$(printf '%s' "$TAIL" | grep -oiE "$PROMISE_RE" | tail -1 || true)
[ -n "$FOUND" ] || exit 0

# Did any file-editing tool run in this stretch of the transcript?
if printf '%s' "$TAIL" | grep -qE '"(apply_patch|write_file|edit_file)"|apply_patch'; then
  exit 0
fi

python3 - "$FOUND" <<'PYEOF'
import json, sys
phrase = sys.argv[1]
print(json.dumps({
    "decision": "block",
    "reason": (
        f'promise-checker: you said something like "{phrase}" but no file edit is '
        'visible in this turn. If you intended to save or record something, do it '
        'now by editing AGENTS.md or next-session-prompts.md. If you only meant it '
        'conversationally, restate it precisely — do not claim to have saved '
        'something you have not saved. Then finish.'
    ),
}))
PYEOF
exit 0
