#!/usr/bin/env bash
# pipeline-guard.sh — PostToolUse hook for Codex (matcher: apply_patch/Edit/Write)
#
# Nudges the Pipeline workflow (see AGENTS.md "## Pipeline workflow"):
#   - you edited a pipeline DOC    -> nudge $apply-pipeline (code follows the doc),
#                                     or $check-pipeline if the code was ground truth.
#   - you edited a documented CODE -> nudge $check-pipeline (+ a pipeline-auditor pass).
#
# It only NUDGES (emits additionalContext); it never blocks an edit.
#
# SELF-QUIETING: on a code edit it says nothing until at least one Pipeline/*.md
# actually exists. So this hook is harmless to leave enabled from day one — it stays
# silent until you adopt the workflow (write your first pipeline doc with
# $write-pipeline), then starts helping automatically.
#
# OPT-IN — OFF by default. To enable, add this block to the "PostToolUse" array in
# .codex/hooks.json (create the key if absent), then trust the hook via /hooks:
#   { "matcher": "apply_patch|Edit|Write",
#     "hooks": [ { "type": "command",
#                  "command": "bash .codex/hooks/pipeline-guard.sh",
#                  "timeout": 10 } ] }
#
# NOTE: notebook edits made through a live-kernel MCP (e.g. Wolfbook) do NOT fire
# file-edit hooks, so this hook won't catch those — the workflow rule in AGENTS.md
# covers the MCP-edit case.
#
# --- CONFIGURE: which directories hold the project's "main" code -----------------
# Space-separated path fragments. A file edit under any of these is treated as a
# code edit. Default: numerics/. Add yours (e.g. "src/ engine/ notebooks/").
CODE_DIRS="numerics/"
# ---------------------------------------------------------------------------------

set -uo pipefail

INPUT=$(cat) || exit 0

# Extract candidate file paths from tool_input. apply_patch input embeds the paths
# in the patch text; Edit/Write-style inputs carry a file path field. We scan all
# string content defensively and keep path-looking tokens. Fails open (silent).
PATHS=$(printf '%s' "$INPUT" | python3 -c "
import json, re, sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
ti = d.get('tool_input') or {}
chunks = []
def walk(x):
    if isinstance(x, str): chunks.append(x)
    elif isinstance(x, dict):
        for v in x.values(): walk(v)
    elif isinstance(x, list):
        for v in x: walk(v)
walk(ti)
blob = '\n'.join(chunks)
seen = []
for tok in re.findall(r'[A-Za-z0-9_./-]+\.[A-Za-z0-9]+', blob):
    if '/' in tok and tok not in seen:
        seen.append(tok)
print('\n'.join(seen[:40]))
" 2>/dev/null) || exit 0

[ -n "$PATHS" ] || exit 0

NUDGE=""
# 1) Pipeline doc edited?
DOC=$(printf '%s\n' "$PATHS" | grep -E '(^|/)Pipeline/.*\.md$' | head -1 || true)
if [ -n "$DOC" ]; then
  NUDGE="pipeline-guard: you edited the pipeline doc '$(basename "$DOC")'. WORKFLOW: when a pipeline updates, the code follows it — run \$apply-pipeline to reconcile the documented code (or confirm the code already matches). If instead the code was ground truth and the doc merely drifted, that is \$check-pipeline."
else
  # 2) Code edit only matters once the workflow is in use — stay silent until a
  #    pipeline doc exists anywhere in the repo.
  [ -n "$(find Pipeline -name '*.md' -type f 2>/dev/null | head -1)" ] || exit 0
  CODE=""
  for d in $CODE_DIRS; do
    hit=$(printf '%s\n' "$PATHS" | grep -F "$d" | head -1 || true)
    [ -n "$hit" ] && { CODE=$hit; break; }
  done
  [ -n "$CODE" ] || exit 0
  NUDGE="pipeline-guard: you edited main code '$(basename "$CODE")'. WORKFLOW: run \$check-pipeline on its Pipeline/ doc to catch code/doc drift, and consider a pipeline-auditor pass to confirm it stays healthy + optimized. (If it is one half of a mirrored pair, e.g. .wb/.nb, also sync the mirror.)"
fi

[ -n "$NUDGE" ] || exit 0

NUDGE="$NUDGE" python3 -c "
import json, os
print(json.dumps({
  'hookSpecificOutput': {
    'hookEventName': 'PostToolUse',
    'additionalContext': os.environ['NUDGE']
  }
}))
"
exit 0
