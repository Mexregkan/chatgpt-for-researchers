#!/usr/bin/env bash
# pre-compact.sh — PreCompact hook for Codex
#
# Runs automatically before Codex compresses (compacts) the conversation context —
# both manual /compact and automatic compaction near the context limit.
#
# PURPOSE: Ensure you don't lose track of where you are when the context rolls
# over. After compaction, Codex continues from a summarised version of the
# conversation — this hook writes a timestamp marker so you can see exactly when
# a compaction happened and resume cleanly.
#
# SETUP: referenced from .codex/hooks.json (shipped in this starter). Codex
# requires you to review and TRUST hooks before they run: type /hooks in a
# session, inspect this script, and trust it. Re-trust after any edit (trust is
# recorded against the hook's hash).

set -euo pipefail

# Consume the JSON event Codex passes on stdin (session_id, transcript_path, ...).
# The useful work here is file-level, so we read and discard it.
INPUT=$(cat) || INPUT=""

TIMESTAMP=$(date "+%Y-%m-%d %H:%M")

# --- 1. Stamp AGENTS.md ---
# Appends a visible marker so you know a compaction occurred.
# Prune these markers when they accumulate (they are working notes, not content).
if [[ -f "AGENTS.md" ]]; then
    cat >> AGENTS.md << MARKER

## ⚠️ Auto-saved before context compact [$TIMESTAMP]
Session was compacted. Last known state is in the "Current status" section above.
To resume: start a new session, open next-session-prompts.md, paste the top prompt.
MARKER
fi

# --- 2. Snapshot next-session-prompts.md (optional) ---
# Creates a timestamped backup so you never lose the task log.
# Remove this block if you don't want backup files.
if [[ -f "next-session-prompts.md" ]]; then
    BACKUP_DIR=".codex/snapshots"
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/next-session-prompts-$(date +%Y%m%d-%H%M).md"
    cp "next-session-prompts.md" "$BACKUP_FILE"
fi

# --- 3. Optional: git commit current state ---
# Uncomment to auto-commit before compaction. Useful if you run long sessions
# and want a breadcrumb.
#
# if git diff --quiet && git diff --cached --quiet; then
#     : # nothing to commit
# else
#     git add AGENTS.md next-session-prompts.md 2>/dev/null || true
#     git commit -m "Auto-save before context compact [$TIMESTAMP]" \
#         --no-verify 2>/dev/null || true
# fi

exit 0
