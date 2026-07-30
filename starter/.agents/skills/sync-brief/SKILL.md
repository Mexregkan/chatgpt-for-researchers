---
name: sync-brief
description: Propagate load-bearing changes from workbook.tex to brief.tex (new theorems, corrected formulas, status changes). Use after establishing a new result; not for every edit.
---

# sync-brief

Propagate load-bearing changes from workbook.tex to brief.tex.

## When to invoke
After establishing a new result, correcting a formula, or completing a section
in workbook.tex. NOT for every edit — only for changes that affect what
is established.

## What "load-bearing" means
Propagate:
- New theorem or proposition (statement, not proof)
- Corrected formula (sign flip, wrong prefactor, wrong argument)
- New result about the mathematical structure (new pole, new residue value, etc.)
- Change to a key definition
- A claim moved from "open" to "established" (or vice versa)

Do NOT propagate:
- Pedagogical re-derivations of existing results
- Reorganization / renaming without content change
- Summary and outlook subsections
- Typo fixes

When in doubt, ask the user.

## Steps

1. **Identify the change.** Ask the user what changed, or run `git diff workbook.tex`
   to see recent edits.

2. **Classify.** Apply the load-bearing filter above. If ambiguous, ask.

3. **Locate the corresponding section in brief.tex.** Grep for a related
   label, theorem name, or keyword. Do NOT read brief.tex in full.

4. **Make the targeted edit.** In brief.tex:
   - Add the new theorem statement (without proof)
   - Replace the old formula with the corrected one
   - Update the "Status" line (ESTABLISHED / OPEN / CORRECTED)
   - Add a cross-reference to the workbook.tex section label

5. **Compile brief.tex** (use `$latex-compile brief.tex`).

6. **Report:**
   - What was propagated (which result, from which section)
   - What was deemed not load-bearing and skipped
   - Compilation status

## Output format
```
Propagated: [result name] from sec:[label] → brief.tex §N (eq. [label])
Skipped (not load-bearing): [what and why]
brief.tex: M pages, clean.
```
