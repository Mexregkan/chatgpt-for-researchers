---
name: latex-compile
description: Compile a LaTeX document and fix every error plus aesthetic issue (overfull/underfull boxes, widows, alignment, fonts) for a clean PDF and log. Use instead of running pdflatex/latexmk by hand — avoids the latexmk stale-log trap and silent grep failures on binary log output; reformats, never rewords.
---

# latex-compile

Compile a LaTeX document, fix all errors **and** all aesthetic issues so the PDF is clean
and the log is empty — without ever altering content to make things fit.

## When to invoke
After any edit to a .tex file. Also invoke before committing.

## Input
The user may specify one or more files: `$latex-compile brief.tex workbook.tex`.
Default: `workbook.tex`. Work from the project root (wherever AGENTS.md lives).

## 1. Compile — always force a real pass, capture stdout

**Critical: never trust the `.log` for warnings.** When `latexmk` decides targets are
up-to-date it skips compilation and leaves a **stale** log that under-reports (or zeroes
out) overfull warnings. Force a real `pdflatex` pass and capture its **stdout**:

```
pdflatex -interaction=nonstopmode <file> > /tmp/tex.txt 2>&1
```

Run **twice** when cross-references, TOC, or forward `\ref`s changed (or a manual `\label`
bibliography needs a second pass to resolve `\cite`).

**Always use `grep -a`.** pdflatex embeds binary font-path bytes in its output, so plain
`grep` treats the stream as binary and matches nothing. Every grep below uses `-a`.

## 2. Collect ALL issues from the fresh stdout

```
grep -anE "^! |LaTeX Error|[Uu]ndefined|Overfull|Underfull|multiply defined|Font (shape|Warning)|File .*not found" /tmp/tex.txt
```

**Case matters — this is the bug that lets `[?]`/`??` ship.** pdflatex writes `Undefined
control sequence` (capital, a fatal error) but the broken-ref/cite *warnings* are lowercase:
`Reference 'x' … undefined`, `Citation 'x' … undefined`, and the end-of-run summary `There
were undefined references`/`Citation 'x' undefined`. A pattern of `Undefined` alone silently
misses every one of those — so the PDF prints `??` for a dead `\ref` and `[?]` for a dead
`\cite` while the grep reports nothing. The bracketed class `[Uu]ndefined` catches both.

| Category | Marker | Threshold to fix |
|---|---|---|
| Fatal errors | `! `, `LaTeX Error`, `Runaway argument`, `Emergency stop` | Always |
| Undefined refs/cites | `Reference … undefined`, `Citation … undefined` | Always (or note if intentional forward ref) |
| Overfull hbox | `Overfull \hbox … too wide by Xpt` | Fix if X > 5pt (see triage) |
| Underfull hbox | `Underfull \hbox … badness N` | Fix if N ≥ 1000 |
| Over/underfull vbox | `Overfull \vbox`, `Underfull \vbox … badness N` | vbox: always; underfull vbox: N ≥ 10000 |
| Font warnings | `Font shape … not found`, `LaTeX Font Warning` | Fix (but see the harmless cases in §6) |
| Missing packages | `File … not found` | Always |
| Multiply-defined labels | `multiply defined` | Always |

## 3. Fix fatal errors first

The `! …` line and the `l.<N>` line below it locate the fault.
- **Undefined control sequence** → check macro definitions / `\newcommand` spelling
- **Missing `{`/`}`** → stray brace; count braces around the line
- **Missing `$`** → stray char in math, or a fragile macro in a section title →
  `\DeclareRobustCommand` or `\texorpdfstring`
- **`\begin{X}` without `\end{X}`** → find the unclosed environment
- **`File not found`** → add `\usepackage` or report the missing dependency

Recompile and repeat until the fatal grep is empty.

## 4. Undefined references and citations
A dead `\ref` prints `??`; a dead `\cite` prints `[?]`. Resolve **every** one — the run is
not clean while any `[Uu]ndefined` warning remains.
- Label/cite exists in the document → just add a second compile pass.
- **Key mismatch** (the common dead-`\cite`): the `\cite{key}` doesn't match any
  `\bibitem{key}` (manual `thebibliography`) or `.bib` entry — usually a spelling/format
  drift (e.g. `\cite{Author:2024xyz}` vs the defined `\bibitem{Author2024}`). Grep the
  used vs. defined keys and reconcile:
  `grep -oE "\\\\cite\{[^}]*\}" <file> | sort -u` against
  `grep -oE "\\\\bibitem\{[^}]*\}" <file>` (or the `.bib` keys). Fix the `\cite` to the real
  key (or add the missing entry) — never leave the mismatch.
- Label exists only in a **different file** (cross-file `\ref`) → it can never resolve.
  Replace `\ref{label}` with the section/theorem title as literal text — e.g.
  ``\S\,``Title of that section''``. Never leave a dangling `\ref` that prints `??`.

## 5. Overfull hboxes — triage, then REFORMAT (never reword)

Overfulls come in three flavors: `in paragraph at lines N--M`, `in alignment at lines
N--M`, and `detected at line N` (math/box mode — the wide row is a line or two **above** N).

Triage by overrun magnitude:
- **> 10pt** — runs off the page → fix
- **5–10pt** — noticeable → fix if quick
- **< 5pt** — below visual threshold → leave; `\hfuzz=1pt` / `\emergencystretch=3em` in
  the preamble absorbs these silently

**Hard rule: do not change mathematical content, wording, table data, or abbreviate
headers to make things fit.** Fix overflow only by changing *layout*:
- **Inline `$…$` that overruns** → promote to a `\[ … \]` display
- **Long single-line display** → break before a relational operator (`=`, `\le`, `\to`).
  In `align`, end the line with `\notag\\` then `&\quad` continuation. **Keep the `\label`
  and number** — `\notag` goes only on continuation lines, never the labelled one
- **Long boxed equation** → `\boxed{\begin{aligned} … \end{aligned}}`
- **Wide smallmatrix-bracket display** → split the multi-integral/product across two
  `align` lines, or wrap the whole display in `{\small … }`
- **Wide table** → `\small` / `\footnotesize` / `\resizebox{\textwidth}{!}{…}` —
  do NOT abbreviate headers or cells
- **Overflowing prose** → `\begin{sloppypar}…\end{sloppypar}`; or split a long unbreakable
  `\texttt`/`\code` token across two `\code{…}` units at a natural boundary; or set
  multi-line code as a `verbatim` / `\begin{quote}\small\ttfamily\raggedright … \end{quote}`
  block (raggedright avoids the new overfull but yields harmless underfulls)
- **Single wide inline token** → `\allowbreak` at a factor boundary, or promote to display

## 6. Other aesthetic issues
- **Underfull hbox (badness ≥ 1000)** → restructure so the last line fills; for a genuinely
  ragged/centred context it's expected — suppress locally with `\hbadness=1000` only if
  unavoidable. (Beware: `\emergencystretch` can turn a sub-`\hfuzz` overfull into a noisy
  underfull — prefer fixing the overfull or leaving it under `\hfuzz`.)
- **Widows/orphans** → `\widowpenalty=10000 \clubpenalty=10000` in the preamble; for one
  case, `\needspace{3\baselineskip}` or a manual break before the paragraph.
- **Alignment** → in `align`, every row needs the same number of `&`; remove blank lines
  inside `align` (spurious gap) and a stray trailing `\\` on the last row.
- **Fonts** → `OT1` warnings: ensure `\usepackage[T1]{fontenc}`. Use `\bfseries`/`\itshape`,
  not `\bf`/`\it`. *Harmless:* `\code{}`/`\texttt` inside a bold section title falls back
  to medium typewriter (CM has no bold tt) — a Font **Info**, not a warning; leave it.
- **Typography** → thin space `\,` before units / between adjacent integrals; `\ldots`/`\dots`
  not `...`; ``` ``…'' ``` not `"…"`; `e.g.\ `/`cf.\ ` to avoid double sentence-spacing.

## 7. hyperref / PDF-bookmark and Unicode gotchas
- A macro or math in a `\section`/`\subsection` title makes hyperref choke building the PDF
  bookmark — `Token not allowed in a PDF string` (harmless) or `Illegal parameter number in
  \Hy@…` (a real error, from a multi-arg macro like a smallmatrix-bracket in the title).
  Wrap the title: `\section{\texorpdfstring{<TeX with macros>}{plain-text bookmark}}`.
- **Literal Unicode** (ω, π, … in code listings or prose) under `pdflatex`+`inputenc` needs
  `\DeclareUnicodeCharacter{03C9}{\ensuremath{\omega}}` (and `{03C0}{…\pi}` etc.) in the
  preamble, or it errors with `Unicode character … not set up for use with LaTeX`. In a
  `verbatim` block prefer ASCII (`Pi`, names) — declarations don't fully apply there.

## 8. Verify
Recompile with `pdflatex` (same `> /tmp/tex.txt` capture), re-run the §2 grep on the
**fresh** stdout, and confirm: no `! ` errors, targeted overfulls gone or < 5pt, no new
issues, refs/cites resolved.

**Mandatory broken-ref gate — never report success while it fails.** On the fresh stdout,
this must print `0`:
```
grep -acE "Reference .* undefined|Citation .* undefined|There were undefined" /tmp/tex.txt
```
A nonzero count means the PDF still prints `??`/`[?]` somewhere — go back to §4 and fix it
before reporting. (Run the final pass twice first: refs/cites need a second pass to settle,
so a leftover here is genuinely broken, not just stale.)

## 9. Report
```
Compiled <file>: N pages.
Errors fixed: <list or "none">
Aesthetic fixes: <list with the layout rule used, or "none">
Remaining warnings: <list or "none — log is clean">
```
If a warning is genuinely unavoidable, say so and explain why it is harmless.
