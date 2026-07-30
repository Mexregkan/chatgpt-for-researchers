#!/usr/bin/env python3
# patch-wolfbook-splitter.py — fix Wolfbook's cell splitter so a trailing
# (* ... *) comment after a continuation operator no longer tears a statement in two.
#
# Usage (from anywhere):
#   python3 /path/to/claude-for-researchers/scripts/patch-wolfbook-splitter.py
#   python3 .../patch-wolfbook-splitter.py --revert     # undo (restore the backup)
#   python3 .../patch-wolfbook-splitter.py --dry-run    # show what would change
#
# After patching, RELOAD the VS Code window (Cmd/Ctrl+Shift+P -> "Developer: Reload
# Window") for the change to take effect.
#
# WHY: Wolfbook evaluates a notebook cell by splitting it into separate kernel inputs
# at top-level (depth-0) newlines. It decides "does this line continue onto the next?"
# by testing whether the trimmed text ends in a continuation operator (:=, =, ->, +, …).
# But it tests the text WITH any trailing (* ... *) comment still attached, so a line
# like
#       LValue[w_] :=(*-(2 Pi I)^weight*)
#       NIntegrate[ ... ]
# looks like it ends in "*)" rather than ":=" — so the splitter thinks it is complete
# and sends the two halves as separate inputs. The kernel then reports
#   Syntax::sntxi: Incomplete expression; more input is needed   (the ":=" half)
# and separately evaluates the bare RHS with unbound symbols (e.g. NIntegrate::inumr),
# and the definition is silently never made.
#
# THE FIX: strip trailing (* ... *) comment(s) from the line before the operator test.
# This is a minimal, additive change to one line of the extension's compiled splitter
# (out/extension/execution/checkout.js). It is idempotent and re-runnable.
#
# CAVEATS:
#   * A VS Code window reload is required after running.
#   * A Wolfbook extension UPDATE overwrites the patch — just re-run this script.
#   * The original file is backed up next to it as checkout.js.prewolfpatch.bak.
#
# This complements the /nb-to-wolfbook skill (which puts each statement on one line):
# that avoids the bug at the source; this fixes the extension so it cannot happen.

import glob
import os
import re
import shutil
import subprocess
import sys

REL = os.path.join("out", "extension", "execution", "checkout.js")
MARK = "tNoCmt"  # idempotency marker: present iff already patched
BACKUP_SUFFIX = ".prewolfpatch.bak"

# Editor extension roots to search (VS Code + common forks + remote/server installs).
EDITOR_DIRS = [
    ".vscode", ".vscode-insiders", ".vscode-server", ".vscode-server-insiders",
    ".cursor", ".cursor-server", ".windsurf", ".vscodium", ".openvscode-server",
]

# The exact splitter line, version-tolerant: capture the leading indent and the
# original regex literal so we can preserve both. Greedy /.*/ captures the whole
# regex literal up to the final slash before .test(t).
PAT = re.compile(
    r"(?P<indent>[ \t]*)const endsWithOp = t\.length > 0 && (?P<re>/.*/)\.test\(t\);"
)


def replacement(m):
    ind = m.group("indent")
    rx = m.group("re")
    lines = [
        "// [claude-for-researchers] strip trailing (* ... *) comments before the operator",
        "// test, so a comment after an operator (e.g.  x :=(*note*)  with the RHS on the next",
        "// line) cannot hide the operator and split one statement into two broken inputs.",
        "let tNoCmt = t;",
        r"while (/\(\*[\s\S]*?\*\)\s*$/.test(tNoCmt)) tNoCmt = tNoCmt.replace(/\(\*[\s\S]*?\*\)\s*$/, '').replace(/\s+$/, '');",
        "const endsWithOp = tNoCmt.length > 0 && " + rx + ".test(tNoCmt);",
    ]
    return ("\n" + ind).join([""] + lines)[1:]  # prefix every line with the indent


def find_files():
    home = os.path.expanduser("~")
    files = []
    for d in EDITOR_DIRS:
        pattern = os.path.join(home, d, "extensions", "wolfbook.wolfbook-*", REL)
        files.extend(glob.glob(pattern))
    return sorted(set(files))


def node_check(path):
    node = shutil.which("node")
    if not node:
        return None  # cannot verify; assume ok
    r = subprocess.run([node, "--check", path], capture_output=True, text=True)
    return (r.returncode == 0, r.stderr.strip())


def do_patch(path, dry_run=False):
    src = open(path, encoding="utf-8").read()
    if MARK in src:
        return "already patched"
    if not PAT.search(src):
        return "splitter line not found (extension version changed?) — skipped"
    new, n = PAT.subn(replacement, src)
    if n != 1:
        return f"expected 1 match, found {n} — skipped (report this)"
    if dry_run:
        return "WOULD patch (dry-run)"
    shutil.copy2(path, path + BACKUP_SUFFIX)
    open(path, "w", encoding="utf-8").write(new)
    chk = node_check(path)
    if chk is not None and not chk[0]:
        shutil.copy2(path + BACKUP_SUFFIX, path)  # restore
        return "ERROR: patched file failed `node --check`; backup restored\n  " + chk[1]
    suffix = "" if chk is None else " (node --check OK)"
    return "patched" + suffix


def do_revert(path):
    bak = path + BACKUP_SUFFIX
    if not os.path.isfile(bak):
        return "no backup found — nothing to revert"
    shutil.copy2(bak, path)
    return "reverted from backup"


def main():
    dry = "--dry-run" in sys.argv
    revert = "--revert" in sys.argv
    files = find_files()
    if not files:
        print("No Wolfbook extension found under any known editor extensions dir.")
        print("Install Wolfbook (extension id: wolfbook.wolfbook) and re-run.")
        return 1
    action = "Reverting" if revert else ("Checking (dry-run)" if dry else "Patching")
    print(f"{action} {len(files)} Wolfbook install(s):")
    changed = False
    for f in files:
        if revert:
            res = do_revert(f)
        else:
            res = do_patch(f, dry_run=dry)
        print(f"  - {f}\n      -> {res}")
        if res.startswith(("patched", "reverted", "WOULD")):
            changed = True
    if changed and not dry:
        print("\nDone. Reload the VS Code window for it to take effect:")
        print("  Cmd/Ctrl+Shift+P -> \"Developer: Reload Window\"")
        if not revert:
            print("Note: a Wolfbook update overwrites this — just re-run the script.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
