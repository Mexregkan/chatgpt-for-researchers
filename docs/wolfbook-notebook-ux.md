# Notebook UX: word wrap + Mathematica-style section folding

**Who needs this:** anyone working in VS Code notebooks — primarily
[Wolfbook](https://wolfbook.app/) `.wb` notebooks (see the *Wolfbook* section of the main
README), but both features apply to any VS Code notebook (Jupyter included). Neither is a
patch to the Wolfbook extension; both configure VS Code itself, so they survive extension
updates.

It fixes two everyday annoyances:

1. **Long lines scroll sideways** instead of wrapping — both in the cell you are editing and
   in the *output* below it. You drag the view right just to read the end of a line or a result.
2. **No easy way to collapse a section.** In Mathematica you double-click a section bracket
   to fold a whole group away; in a VS Code notebook that affordance is easy to miss.

---

## Feature 1 — word wrap inside cells

### The catch

There are two natural-looking settings, and **both are wrong**. The language-scoped form does
nothing to cells:

```jsonc
// Looks right. Does NOT reach notebook cell editors (a VS Code limitation).
"[wolfram]": { "editor.wordWrap": "on" }
```

and the plain unscoped form works but wraps **every file you open** — your `.tex`, `.py`, and
`.md` included, which you probably don't want:

```jsonc
// Works, but wraps ALL editors, not just notebooks.
"editor.wordWrap": "on"
```

The right key applies editor options to notebook **cell editors only**, and two more keys make
the *output* wrap as well:

```jsonc
"notebook.editorOptionsCustomizations": { "editor.wordWrap": "on" }, // cell editors
"notebook.output.wordWrap": true,                                    // text output lines
"wolfbook.notebook.rendering.outputFormat": "InputForm"              // Wolfram results (see below)
```

These ship on by default in the starter package's
[`starter/.vscode/settings.json`](../starter/.vscode/settings.json), so a project set up from
the starter wraps its notebook cells *and* output — and nothing else — with no extra step.

### The catch, part 2 — Wolfram output is an image, so word wrap can't touch it

`notebook.output.wordWrap` only wraps output that is **text**. By default Wolfbook renders an
evaluated result as a single fixed-width **image** (`wolfbook.notebook.rendering.outputFormat`
defaults to `"Image"`), and an image can only ever scroll sideways — word wrap has nothing to
reflow, so a wide result still runs off the right edge. Setting the format to `"InputForm"`
makes Wolfbook emit the result as plain text (`white-space: pre-wrap`), which wraps to the
notebook width and uses a single colour that reads cleanly on any theme:

```jsonc
"wolfbook.notebook.rendering.outputFormat": "InputForm"
```

The other choices are `"HTML"` (wraps, but carries Wolfram-Cloud styling that can clash with a
light theme), `"MathML"`, and the default `"Image"`. This key is Wolfbook-specific — Jupyter
and other notebooks simply ignore it, so it is harmless to set everywhere.

**Trade-off (be honest with yourself):** `InputForm` is linear text, so a large matrix or a
heavily typeset expression loses the 2-D layout you get from the image. If you prefer the
typeset look in a particular notebook, set that one back to `"Image"` — you keep wrapping
everywhere else.

### Where to put it

- **Project-scoped (recommended):** `<project>/.vscode/settings.json` — wraps notebook cells
  in that project only. This is what the starter ships.
- **Global:** your user `settings.json` — wraps notebook cells everywhere.

After saving, reload the window (`Cmd/Ctrl+Shift+P` → "Developer: Reload Window") so the
cell editors re-read the option.

---

## Feature 2 — collapse sections like Mathematica

This one needs **nothing built** — VS Code notebooks already fold markdown sections. A
markdown heading cell (`#`, `##`, `###`, `####`) gets a fold chevron in its left gutter;
folding it hides every cell beneath it down to the next heading of equal-or-higher level,
and it nests exactly like Section › Subsection › Subsubsection. The only reason it feels
missing is that the chevron is small and only shows on hover.

So this feature is just **ergonomic keybindings** — the keyboard twin of clicking that
chevron:

```jsonc
{ "key": "ctrl+alt+[", "mac": "alt+cmd+[", "command": "notebook.fold",   "when": "notebookEditorFocused && !inputFocus" },
{ "key": "ctrl+alt+]", "mac": "alt+cmd+]", "command": "notebook.unfold", "when": "notebookEditorFocused && !inputFocus" }
```

Select a cell (click its left margin, or press `Esc` to leave edit mode), then `Ctrl+Alt+[`
(mac `⌥⌘[`) collapses the section and `Ctrl+Alt+]` (mac `⌥⌘]`) expands it. The `when` clause
keeps the keys inactive while you are editing a cell, so they never clash with normal typing
or with code folding *inside* a cell (Wolfbook provides its own bracket/comment folding for
that). Keybindings are user-global only — VS Code has no per-project keybindings — which is
why these are not a starter file; the guard makes them safe to set globally.

**One caveat for existing notebooks:** only real markdown cells fold. If a heading was saved
as a code cell with markdown styling (Wolfbook occasionally does this for a Title cell), it
won't show a chevron. Convert it to a markdown cell and it folds like the rest.

---

## Install

Manual (copy-paste each snippet above into the matching file) works fine. The script just
does it for you across every installed VS Code / Cursor / VSCodium / Windsurf:

```sh
python3 scripts/apply-notebook-ux.py            # word wrap -> ./.vscode/settings.json ; folding -> user keybindings
python3 scripts/apply-notebook-ux.py --project /path/to/project   # word wrap into that project
python3 scripts/apply-notebook-ux.py --user-wrap                  # ALSO put word wrap in user (global) settings
python3 scripts/apply-notebook-ux.py --dry-run                    # preview, write nothing
python3 scripts/apply-notebook-ux.py --revert                     # undo (restores every .cfr-ux.bak)
```

If you set the project up with the bootstrap (and never cloned this repo), run it straight
from GitHub instead — no file to download:

```sh
curl -fsSL https://raw.githubusercontent.com/Mexregkan/chatgpt-for-researchers/main/scripts/apply-notebook-ux.py | python3 -
# add --dry-run to preview first, or --revert to undo
```

The script:

- finds every VS Code-family user config dir (macOS / Linux / Windows paths);
- reads JSONC tolerantly (comments and trailing commas are fine, strings are respected);
- is **idempotent** — re-running adds nothing and never double-binds a key;
- backs up each file to `<file>.cfr-ux.bak` before its first change, and `--revert` restores
  it. (When merging into an existing config the file is re-serialised as plain JSON, so its
  comments are dropped — the backup keeps the original verbatim.)

Then reload the VS Code window.
