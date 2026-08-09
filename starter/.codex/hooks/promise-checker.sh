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

# --- handoff stub check (no-op unless this project has a handoff/ mailbox) -----
# A message left as an empty template is worse than no message: the other agent
# opens a blank form and the thread stalls. hx.sh refuses to create a body-less
# message; this is the backstop for the explicit `--stub` path, and for a stub
# that got written and then forgotten. Deliberately computed BEFORE the
# transcript checks below, because it does not depend on the transcript — an
# unreadable transcript must not silently skip it. Must not abort: || true.
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HX_LINT=""
if [ -f "$REPO_ROOT/handoff/hx.sh" ]; then
  HX_LINT=$( (cd "$REPO_ROOT" && bash handoff/hx.sh lint 2>&1) || true )
  case "$HX_LINT" in
    *FAIL*) : ;;          # keep it, there is something to report
    *)      HX_LINT="" ;; # clean, say nothing
  esac
fi

# Emit whatever we have and stop. $1 = the promise phrase, or "" if none. The
# two findings are independent, so both are reported rather than one masking
# the other.
report() {
  if [ -z "${1:-}" ] && [ -z "$HX_LINT" ]; then exit 0; fi
  PROMISE_HIT="${1:-}" HX_LINT="$HX_LINT" python3 - <<'PYEOF'
import json, os
notes = []
phrase = os.environ.get('PROMISE_HIT', '')
lint = os.environ.get('HX_LINT', '')
if phrase:
    notes.append(
        f'promise-checker: you said something like "{phrase}" but no file edit is '
        'visible in this turn. If you intended to save or record something, do it '
        'now by editing AGENTS.md or next-session-prompts.md. If you only meant it '
        'conversationally, restate it precisely — do not claim to have saved '
        'something you have not saved. Then finish.'
    )
if lint:
    notes.append(
        'handoff-lint: an outgoing handoff message is unfilled or over the line cap. '
        'Do NOT leave it — the other agent would open a blank template. Fix it now, '
        'then re-run: bash handoff/hx.sh lint\n' + lint
    )
print(json.dumps({"decision": "block", "reason": "\n\n".join(notes)}))
PYEOF
  exit 0
}

INPUT=$(cat) || report ""

TRANSCRIPT=$(printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    print(json.load(sys.stdin).get('transcript_path') or '')
except Exception:
    print('')
" 2>/dev/null) || report ""
{ [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; } || report ""

# Look only at the tail of the transcript (≈ the current turn).
TAIL=$(tail -c 200000 "$TRANSCRIPT" 2>/dev/null) || report ""

# Phrases that indicate the model claims to have persisted something.
PROMISE_RE="I'll remember|I've noted|I've saved|I've recorded|I'll note|I've logged|I'll keep that in mind|I've updated|I've added that|saved to memory|I've made a note"

FOUND=$(printf '%s' "$TAIL" | grep -oiE "$PROMISE_RE" | tail -1 || true)
[ -n "$FOUND" ] || report ""

# Did any file-editing tool run in this stretch of the transcript?
if printf '%s' "$TAIL" | grep -qE '"(apply_patch|write_file|edit_file)"|apply_patch'; then
  report ""
fi

report "$FOUND"
