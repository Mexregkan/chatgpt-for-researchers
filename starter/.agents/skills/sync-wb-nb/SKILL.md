---
name: sync-wb-nb
description: Propagate a change made in a Wolfbook .wb notebook into the paired .nb notebook so the two stay identical. Use immediately after every .wb edit; regenerate mode rebuilds a whole .nb.
---

# sync-wb-nb

Keep a `.wb` and its paired `.nb` mirror in sync. We edit/test in the `.wb` (Wolfbook, in VS Code);
the `.nb` is the mirror we cannot run but the user opens in desktop Mathematica. Direction is
always `.wb` → `.nb` (the `.wb` is authoritative; `$nb-to-wolfbook` handles the initial
reverse conversion). Set the default pair via `defaultWb`/`defaultNb` at the top of
`sync-wb-nb.wls`, or pass absolute paths as trailing args.

Two operations, one helper script (`sync-wb-nb.wls`, in this skill's directory):

- **Snippet sync** (`replace`/`insert`/`verify`/`stability`) — propagate ONE edited cell,
  preserving the rest of a hand-crafted `.nb` (its outputs, manual tweaks). This is the
  standing-rule after editing the main notebook.
- **`regenerate`** — rebuild the WHOLE `.nb` from the `.wb` so it opens in Mathematica
  looking normal: syntax-coloured code, styled headings. Use it to create a fresh `.nb`
  (e.g. a new `generated/*.wb`) or after a wholesale rewrite. It **overwrites** the `.nb`,
  so never use it to patch one cell of a hand-crafted notebook.

## When to invoke
- After editing/adding cells in the MAIN `.wb`: snippet sync, **immediately**. Add to your
  AGENTS.md:
  > Always run `$sync-wb-nb` immediately after editing or adding cells in any `.wb`.
- For a NEW or fully-rewritten `.nb`: `regenerate`.

## regenerate — full colourised rebuild

```bash
WLS=".agents/skills/sync-wb-nb/sync-wb-nb.wls"   # path from project root
wolframscript -file "$WLS" regenerate "<abs wbPath>" "<abs nbPath>"
```

What it produces, cell by cell from the `.wb`:
- code cells → `Cell[BoxData[…], "Input"]` parsed by the **front-end parser**
  (`FrontEnd`UndocumentedTestFEParserPacket`), which is what makes Mathematica colour them
  (blue user symbols, green pattern vars, black built-ins). A plain `Cell["string","Input"]`
  shows up all black — that was the bug this mode fixes.
- markdown cells → `Title`/`Section`/`Subsection`/`Subsubsection` (by `#`/`##`/`###`/`####`)
  and `Text` styles, with `**bold**`/`` `code` ``/`[t](l)` markup stripped.
- in-code `(* … *)` comments → lifted into an adjacent `Text` cell (the box parser drops
  comments, same as the snippet engine).

Hard-won rules baked into the mode (don't undo them):
- **Absolute paths only.** A relative `Export["generated/x.nb"]` lands in wolframscript's own
  cwd, not the project — the file silently doesn't change and you debug a ghost. The mode
  re-reads the exact path and asserts the file is a `Notebook`, contains `BoxData`, and has
  one coloured cell per code cell.
- **FE parser, not `MakeBoxes`.** The FE parser preserves the source line breaks and the
  literal expression; `MakeBoxes` reassociates `Times` in product-numerator fractions (the
  stability hazard below) and would risk changing the maths on a whole-file rewrite.
- **Tell the user to reopen.** If the `.nb` is open in Mathematica, the stale in-memory copy
  must be closed WITHOUT saving (or `File ▸ Revert`) — otherwise a save overwrites the rebuild.

`regenerate` is not `$sync-wb-nb`-incremental: it is the same skill's bulk path. Re-run it
whenever the `.wb` changes (there is no cheaper incremental update for a `generated/` notebook).

## Snippet sync — propagate one edited cell

For the main hand-crafted `.nb`: backup, box conversion, stability gate, unique-target
assertions, post-write verification with automatic restore — all in `sync-wb-nb.wls`. One
Bash call per operation:

```bash
WLS=".agents/skills/sync-wb-nb/sync-wb-nb.wls"   # path from project root
wolframscript -file "$WLS" stability "<snippet>"            # is the .wb cell box-stable?
wolframscript -file "$WLS" replace   "<wbSnippet>" ["<nbOldSnippet>"]   # sync an edited cell
wolframscript -file "$WLS" insert    "<wbSnippet>" "<nbAnchorSnippet>"  # sync a new cell
wolframscript -file "$WLS" verify    "<snippet>"            # check a cell is in sync
```

- `<snippet>` selects the cell and **must be a single token** (a symbol name defined in the
  cell, e.g. `"myFunction"`): in box structures `myFunc[x_` never matches — `myFunc`, `[`,
  `x_` are separate strings.
- `replace` takes a second snippet when the OLD `.nb` cell doesn't contain the new token
  (e.g. new code introduces `newSymbol`; locate the old cell by one of its own existing tokens).
- `insert` needs a snippet of the `.nb` cell the new cell goes AFTER.
- Non-default notebook pair: append `<wbPath> <nbPath>` (absolute paths) as trailing args.
- Exit 0 + `PASS: …` = success. Exit 1 + `FAIL: …` = nothing (or a restored backup) on disk.

Workflow per synced cell: `stability` → fix source if it fails → `replace`/`insert` →
done (verification is built in). Report the PASS lines.

## Hard rules (the script enforces #2–#5; you own #1)

1. **Keep synced code cells pure code.** The code→boxes conversion discards `(* … *)`
   comments, so a commented cell would differ between the two files. Notes go in a separate
   text cell or the workbook.
2. **Box-round-trip stability.** A fraction with a *product* numerator (`a*b/c`)
   reassociates `Times` through `FractionBox` and breaks `===`; atomic-numerator fractions
   are stable. Fix by assigning the numerator to a local (`c2 = a*b; … c2/c`), re-validate
   the maths numerically, then sync. The script refuses to write unstable code.
3. **Backup before write, restore on failed verification.** Automatic (`/tmp/sync-wb-nb-backup-*.nb`).
4. **Unique-target assertion.** Ambiguous or missing snippet matches abort before writing.
5. **Verify, don't trust**: after writing, the `.nb` cell must parse `===` the `.wb` code.

## Why wolframscript (not Python)

Only the Wolfram kernel can convert code text to Input boxes (`MakeBoxes` or the front-end
parser) and parse `.nb` box structures back; a Python splice would also leave the `.nb`'s
internal byte-offset cache stale. Import→modify→Export regenerates it correctly and
preserves outputs.

## Implementation notes (for maintaining the script)

Snippet modes:
- Snippet matching uses `ToString[boxes, InputForm, PageWidth -> Infinity]` — default
  `ToString` line-wraps and can split a token across a `\` continuation, silently breaking
  `StringContainsQ`.
- Cell replacement uses `Position`+`Select`(SameQ)+`ReplacePart`, never `nb /. oldCell ->
  new`: a literal Cell as a `/.` LHS can silently fail to fire. UUID-anchored `/.` rules
  are fine for *insertion* (the anchor cell is matched by its UUID option, not its body).
- Markdown `.wb` cells (kind 1) are NOT touched by the snippet modes; mirror them manually as
  `Cell[text, "Subsection"/"Text"]` matching neighbouring styles. (`regenerate` DOES handle
  them — it rebuilds the whole file.)

regenerate mode:
- The FE parser returns `{BoxData[…], …}`; take `[[1]]`. It yields the multi-line *list-form*
  `BoxData[{box, "\n", box, …}]` (the FE's native typed-input shape — it colours correctly);
  `Import` later normalises that to a single `RowBox`. So the faithfulness check must NOT
  compare held expressions of the two shapes — it just asserts every stored cell re-parses
  without `$Failed`.
- The FE parser drops `(* *)` comments (with the `True` flag too — tested), so comments are
  lifted to a Text cell.

General:
- Quote the project path (spaces + parentheses); wolframscript needs absolute paths. For
  `regenerate` the absolute output path is load-bearing, not just convenient.
