#!/usr/bin/env python3
# apply-notebook-ux.py -- enable two notebook quality-of-life features in VS Code
# (and forks): (1) word wrap inside notebook cells AND wrapping of long output
# (including Wolfram results, rendered as plain text so they wrap instead of forcing a
# sideways scroll), and (2) Mathematica-style keyboard folding of markdown sections.
# Works for Wolfbook .wb notebooks and any other VS Code notebook.
#
# Usage (from anywhere):
#   python3 apply-notebook-ux.py                 # word wrap -> ./.vscode/settings.json
#                                                # folding   -> user keybindings.json
#   python3 apply-notebook-ux.py --project DIR   # put word wrap in DIR/.vscode/settings.json
#   python3 apply-notebook-ux.py --user-wrap     # ALSO put word wrap in USER settings (global)
#   python3 apply-notebook-ux.py --dry-run       # show what would change, write nothing
#   python3 apply-notebook-ux.py --revert        # restore every file from its .cfr-ux.bak
#
# After running, RELOAD the VS Code window (Cmd/Ctrl+Shift+P -> "Developer: Reload
# Window") so the cell editors and keybindings pick up the change.
#
# WHY THIS EXISTS
#   * Word wrap: VS Code does NOT apply a language-scoped setting such as
#     "[wolfram]": { "editor.wordWrap": "on" } inside notebook cells, and the plain
#     unscoped "editor.wordWrap": "on" wraps EVERY file you open. The key that wraps
#     notebook *cells only* (leaving your .tex/.py/etc. alone) is
#     "notebook.editorOptionsCustomizations": { "editor.wordWrap": "on" }. This sets it,
#     plus "notebook.output.wordWrap" for long output lines, plus -- for Wolfbook --
#     "wolfbook.notebook.rendering.outputFormat": "InputForm" so results render as
#     wrapping plain text rather than a fixed-width image that can only scroll sideways.
#   * Folding: section folding is already built into VS Code notebooks -- a markdown
#     heading cell (#, ##, ###, ####) folds every cell beneath it. There is no command
#     to build; this only adds ergonomic keybindings (guarded so they fire only in a
#     focused notebook outside cell edit mode) and is the keyboard twin of the fold
#     chevron in a heading cell's gutter.
#
# SAFE BY DESIGN: every file is backed up to "<file>.cfr-ux.bak" before the first
# change; --revert restores it; re-running is idempotent (no duplicate keys/bindings).
# When merging into an EXISTING config, the file is re-serialised as plain JSON, so any
# comments in it are dropped (the backup keeps the original). New files are written with
# explanatory comments.

import argparse
import json
import os
import platform
import sys

BACKUP_SUFFIX = ".cfr-ux.bak"

# Word-wrap keys. notebook.editorOptionsCustomizations wraps notebook CELL editors only
# (not regular files); notebook.output.wordWrap wraps long rendered output lines; and
# wolfbook.notebook.rendering.outputFormat=InputForm renders Wolfram results as wrapping
# plain text instead of a fixed-width image that can only scroll sideways (Wolfbook-only
# key -- harmless and ignored by Jupyter and other notebooks).
WRAP_KEYS = {
    "notebook.editorOptionsCustomizations": {"editor.wordWrap": "on"},
    "notebook.output.wordWrap": True,
    "wolfbook.notebook.rendering.outputFormat": "InputForm",
}

# Section-folding keybindings. Confined to a focused notebook with no cell in edit mode.
FOLD_BINDINGS = [
    {"key": "ctrl+alt+[", "mac": "alt+cmd+[", "command": "notebook.fold",
     "when": "notebookEditorFocused && !inputFocus"},
    {"key": "ctrl+alt+]", "mac": "alt+cmd+]", "command": "notebook.unfold",
     "when": "notebookEditorFocused && !inputFocus"},
]

# VS Code-family product names whose User/ dir holds settings.json + keybindings.json.
PRODUCT_NAMES = ["Code", "Code - Insiders", "VSCodium", "Cursor", "Windsurf", "Code - OSS"]


# ---- tiny JSONC reader (comments + trailing commas; string-aware) -------------------

def _strip_jsonc(text):
    """Return `text` with // and /* */ comments removed and trailing commas dropped,
    without touching anything inside string literals."""
    out, i, n, in_str = [], 0, len(text), False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1]); i += 2; continue
            if c == '"':
                in_str = False
            i += 1; continue
        if c == '"':
            in_str = True; out.append(c); i += 1; continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            i += 2
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i < n and not (text[i] == "*" and i + 1 < n and text[i + 1] == "/"):
                i += 1
            i += 2; continue
        out.append(c); i += 1
    s = "".join(out)
    # drop trailing commas ( , followed by whitespace then } or ] ), string-aware
    res, i, n, in_str = [], 0, len(s), False
    while i < n:
        c = s[i]
        if in_str:
            res.append(c)
            if c == "\\" and i + 1 < n:
                res.append(s[i + 1]); i += 2; continue
            if c == '"':
                in_str = False
            i += 1; continue
        if c == '"':
            in_str = True; res.append(c); i += 1; continue
        if c == ",":
            j = i + 1
            while j < n and s[j] in " \t\r\n":
                j += 1
            if j < n and s[j] in "}]":
                i += 1; continue
        res.append(c); i += 1
    return "".join(res)


def read_jsonc(path, default):
    if not os.path.exists(path):
        return default
    raw = open(path, encoding="utf-8").read()
    if not raw.strip():
        return default
    return json.loads(_strip_jsonc(raw))


# ---- file helpers -------------------------------------------------------------------

def backup_once(path):
    bak = path + BACKUP_SUFFIX
    if os.path.exists(path) and not os.path.exists(bak):
        with open(path, "rb") as a, open(bak, "wb") as b:
            b.write(a.read())


def write_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(json.dumps(obj, indent=4) + "\n")


# ---- editor config discovery --------------------------------------------------------

def user_config_dirs():
    home = os.path.expanduser("~")
    sysname = platform.system()
    if sysname == "Darwin":
        base = os.path.join(home, "Library", "Application Support")
    elif sysname == "Windows":
        base = os.environ.get("APPDATA", os.path.join(home, "AppData", "Roaming"))
    else:
        base = os.environ.get("XDG_CONFIG_HOME", os.path.join(home, ".config"))
    found = []
    for name in PRODUCT_NAMES:
        d = os.path.join(base, name, "User")
        if os.path.isdir(d):
            found.append(d)
    return found


# ---- merge logic --------------------------------------------------------------------

def merge_settings(path, dry):
    """Ensure WRAP_KEYS are present in the settings.json at `path`."""
    cur = read_jsonc(path, {})
    if not isinstance(cur, dict):
        print("  ! %s is not a JSON object -- skipping (merge by hand)" % path)
        return
    changed, conflicts = {}, []
    for k, v in WRAP_KEYS.items():
        if isinstance(v, dict):
            # Nested object (notebook.editorOptionsCustomizations): merge sub-keys so we
            # never clobber the user's other cell-editor customizations.
            existing = cur.get(k) if isinstance(cur.get(k), dict) else {}
            merged = dict(existing)
            for sk, sv in v.items():
                if merged.get(sk) != sv:
                    if sk in merged:
                        conflicts.append(("%s.%s" % (k, sk), merged[sk], sv))
                    merged[sk] = sv
            if merged != existing:
                changed[k] = merged
        else:
            if cur.get(k) == v:
                continue
            if k in cur and cur[k] != v:
                conflicts.append((k, cur[k], v))
            changed[k] = v
    if not changed:
        print("  = %s already has word wrap" % path)
        return
    for label, old, new_val in conflicts:
        print("  ~ %s: '%s' currently = %r, setting to %r" % (path, label, old, new_val))
    if dry:
        print("  + would set in %s: %s" % (path, ", ".join(changed)))
        return
    if os.path.exists(path):
        backup_once(path)
        new = dict(cur); new.update(changed)
        write_json(path, new)
    else:
        # brand-new file: keep the explanatory comment
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(
                "{\n"
                '    // Word wrap inside notebook CELLS only (not your .tex/.py/etc. files).\n'
                '    // The unscoped "editor.wordWrap" wraps every file; a language-scoped\n'
                '    // "[wolfram]" form does not reach cells -- this cell-scoped key is right.\n'
                '    "notebook.editorOptionsCustomizations": { "editor.wordWrap": "on" },\n'
                '    "notebook.output.wordWrap": true,\n'
                '    // Wolfbook output as wrapping plain text, not a fixed-width image that can\n'
                '    // only scroll sideways (Wolfbook-only key; ignored by other notebooks).\n'
                '    "wolfbook.notebook.rendering.outputFormat": "InputForm"\n'
                "}\n"
            )
    print("  + wrote word wrap to %s" % path)


def merge_keybindings(path, dry):
    """Ensure FOLD_BINDINGS are present in the keybindings.json at `path`."""
    cur = read_jsonc(path, [])
    if not isinstance(cur, list):
        print("  ! %s is not a JSON array -- skipping (merge by hand)" % path)
        return

    def present(b):
        return any(
            isinstance(e, dict)
            and e.get("command") == b["command"]
            and e.get("when") == b["when"]
            for e in cur
        )

    to_add = [b for b in FOLD_BINDINGS if not present(b)]
    if not to_add:
        print("  = %s already has the folding keybindings" % path)
        return
    if dry:
        print("  + would add %d folding keybinding(s) to %s"
              % (len(to_add), path))
        return
    if os.path.exists(path):
        backup_once(path)
        write_json(path, cur + to_add)
    else:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(
                "// Mathematica-style section folding in notebooks. Select a heading cell\n"
                "// (Esc out of edit mode) then Ctrl+Alt+[ / ] (mac Option+Cmd+[ / ]).\n"
                + json.dumps(FOLD_BINDINGS, indent=4) + "\n"
            )
    print("  + added folding keybindings to %s" % path)


def revert(path):
    bak = path + BACKUP_SUFFIX
    if os.path.exists(bak):
        with open(bak, "rb") as a, open(path, "wb") as b:
            b.write(a.read())
        os.remove(bak)
        print("  - reverted %s" % path)
    else:
        print("  = no backup for %s" % path)


# ---- main ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description="Enable notebook word wrap + section folding in VS Code.")
    ap.add_argument("--project", default=os.getcwd(),
                    help="project dir whose .vscode/settings.json gets word wrap (default: cwd)")
    ap.add_argument("--user-wrap", action="store_true",
                    help="ALSO put word wrap in the user (global) settings.json")
    ap.add_argument("--dry-run", action="store_true", help="show changes, write nothing")
    ap.add_argument("--revert", action="store_true", help="restore every file from its backup")
    args = ap.parse_args()

    user_dirs = user_config_dirs()
    proj_settings = os.path.join(args.project, ".vscode", "settings.json")
    settings_targets = [proj_settings]
    if args.user_wrap:
        settings_targets += [os.path.join(d, "settings.json") for d in user_dirs]
    kb_targets = [os.path.join(d, "keybindings.json") for d in user_dirs]

    if args.revert:
        print("Reverting:")
        for p in settings_targets + kb_targets:
            revert(p)
        print("Done. Reload the VS Code window.")
        return

    if not user_dirs:
        print("! No VS Code-family user config dir found (searched %s)."
              % ", ".join(PRODUCT_NAMES))
        print("  Word wrap will still be applied to the project; add the folding")
        print("  keybindings by hand from vscode-keybindings.snippet.jsonc.")

    print("Word wrap (settings.json):")
    for p in settings_targets:
        merge_settings(p, args.dry_run)

    print("Section folding (keybindings.json):")
    if kb_targets:
        for p in kb_targets:
            merge_keybindings(p, args.dry_run)
    else:
        print("  (no editor config dir -- add by hand from the snippet)")

    print("\nDone%s. Reload the VS Code window: Cmd/Ctrl+Shift+P -> \"Developer: Reload Window\"."
          % (" (dry run -- nothing written)" if args.dry_run else ""))


if __name__ == "__main__":
    sys.exit(main())
