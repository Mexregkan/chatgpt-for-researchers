# Fixing the Wolfbook "comment splits a cell" bug

**Who needs this:** anyone running Mathematica notebooks through
[Wolfbook](https://wolfbook.app/) in VS Code (see the *Wolfbook* section of the main
README). It is optional — the `$nb-to-wolfbook` skill already avoids the bug by putting
each statement on one line — but this patch fixes the root cause in the extension, so the
bug cannot bite even in hand-written cells.

## The symptom

A cell that looks fine throws two unrelated-looking errors at once, and a definition you
"made" silently does not exist. The classic trigger is a comment sitting right after an
operator, with the rest of the statement on the next line:

```mathematica
LValue[w_, j_] :=(*-(2 Pi I)^weight*)
NIntegrate[Delta[w, tau] tau^j, {tau, 0, I, I Infinity}, WorkingPrecision -> 100]
```

Evaluating it produces:

```
Syntax::sntxi: Incomplete expression; more input is needed.
NIntegrate::inumr: The integrand ... has evaluated to non-numerical values ...
```

## Why it happens

Wolfbook evaluates a cell by splitting it into separate kernel inputs at top-level
(bracket-depth-0) newlines. To decide whether a line *continues* onto the next, it checks
whether the trimmed line ends in a continuation operator (`:=`, `=`, `->`, `+`, …). The bug:
it checks the text **with the trailing `(* ... *)` comment still attached**, so the line
above looks like it ends in `*)` rather than `:=`. The splitter concludes the line is
complete and sends the two halves separately:

1. `LValue[w_, j_] :=` → an assignment with no right-hand side → `Syntax::sntxi`, and the
   definition is **never made**;
2. `NIntegrate[...]` → evaluated on its own with `w`, `j`, `tau` still symbolic → the
   integrand is non-numeric → `NIntegrate::inumr`.

Same root cause as the more general "a statement wrapped across several lines is silently
mis-evaluated" footgun the README warns about — here a trailing comment hides the operator
that would otherwise keep the lines together.

## The fix

Strip trailing `(* ... *)` comment(s) from a line **before** testing whether it ends in a
continuation operator. This is a one-line change in the extension's compiled splitter
(`out/extension/execution/checkout.js`).

### Automatic (recommended)

```sh
python3 scripts/patch-wolfbook-splitter.py
```

If you set the project up with the bootstrap (and never cloned this repo), run it
straight from GitHub instead — no file to download:

```sh
curl -fsSL https://raw.githubusercontent.com/Mexregkan/chatgpt-for-researchers/main/scripts/patch-wolfbook-splitter.py | python3 -
# add --dry-run to preview first, or --revert to undo
```

Then reload the VS Code window: `Cmd/Ctrl+Shift+P → "Developer: Reload Window"`.

The script:

- finds every installed Wolfbook (`~/.vscode`, `~/.cursor`, `~/.vscode-server`, … — VS Code
  and common forks/remote installs);
- is **idempotent** — safe to re-run; skips installs already patched;
- backs up the original to `checkout.js.prewolfpatch.bak`;
- verifies the result with `node --check` (if Node is available) and auto-restores the
  backup if anything is wrong;
- `--dry-run` previews; `--revert` restores the backup.

A Wolfbook **update overwrites the patch** — just re-run the script afterwards.

### Manual

In `out/extension/execution/checkout.js`, find:

```js
const t = current.trim();
const endsWithOp = t.length > 0 && /(&&|\|\||->|:>|...|[+\-*\/=,&|~@?])$/.test(t);
```

and replace the second line with:

```js
let tNoCmt = t;
while (/\(\*[\s\S]*?\*\)\s*$/.test(tNoCmt)) tNoCmt = tNoCmt.replace(/\(\*[\s\S]*?\*\)\s*$/, '').replace(/\s+$/, '');
const endsWithOp = tNoCmt.length > 0 && /(&&|\|\||->|:>|...|[+\-*\/=,&|~@?])$/.test(tNoCmt);
```

(keep the original regex exactly; only the `.test(...)` argument changes from `t` to
`tNoCmt`). Reload the window.

## Good habit either way

Even with the patch, keep the habit the README recommends: **don't end a `.wb` line with a
`(* ... *)` comment when the expression is incomplete** (right after `:=`, `=`, a binary
operator, or a trailing comma). Put the inline comment on the same line as the code that
continues it, or on its own full-comment line. The patch is a safety net, not a licence to
write fragile cells.
