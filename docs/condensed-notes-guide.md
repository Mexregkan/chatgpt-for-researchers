# Guide: writing brief.tex (the condensed reference)

`brief.tex` solves a specific problem: `workbook.tex` grows too large for Codex to
hold in context, but Codex needs to understand your project accurately to help you.
`brief.tex` is what Codex reads at the start of new sessions instead of the full
working record.

---

## What it is

A SHORT (15–30 pages / 1000–3000 lines), SELF-CONTAINED reference document.
It contains the current state of the project — theorems, key formulas, results,
open questions — without proofs, derivations, or history.

It is NOT a summary of `workbook.tex`. It is a COMPRESSED KNOWLEDGE BASE that a
reader (or Codex) could use to understand the current state of the project from
scratch, without reading anything else. Because it states results cleanly without
the working-out, `brief.tex` is also the document closest to an eventual published
paper.

---

## What to include

**YES — include these:**
- Every established theorem and proposition, stated precisely (without proof)
- Every key formula, with the exact normalizations and signs you use
- The current status: what is proved, what is conjectured, what is open
- Open problems, ranked by importance
- Notational conventions (what every symbol means)
- Cross-references to `workbook.tex` (section labels, equation names)
  so Codex can navigate there when needed
- Recent corrections: if you found an error and fixed it, the corrected
  statement — with a note that the old version was wrong

**NO — exclude these:**
- Proofs and derivations (these are in `workbook.tex`)
- Pedagogical examples and motivation
- History of how you arrived at results
- "We will see in §X that..." forward references
- In-progress work or speculative ideas (these belong in next-session-prompts)
- Anything that is not yet established

---

## Structure

A structure that works well for mathematical research:

```
§1 Abstract / main results
   — The 2-3 key theorems stated precisely. Someone reading only this
     section should know what the paper proves.

§2 Conventions and definitions
   — Every symbol defined. Normalizations stated. This section prevents
     Codex from getting confused about which convention you use.

§3-N Results by topic
   — Each section = one topic. Theorem, formula, key data.
     Reference to workbook.tex for proof.
     Mark what is established vs what is a conjecture.

§N+1 Numerical results
   — Exact computed values, what method was used, what was validated.

§N+2 Open problems
   — Ranked list. "Item 1 is the next thing to prove."
```

---

## Sync discipline

`brief.tex` and `workbook.tex` will drift apart unless you actively sync them.
Two situations require a sync:

1. **New result established:** After adding a theorem or corrected formula to
   `workbook.tex`, add the statement (not the proof) to `brief.tex`.

2. **Correction:** If you find that something in `brief.tex` is wrong, fix it
   immediately. A wrong `brief.tex` is worse than no `brief.tex` — Codex will
   confidently work from incorrect information.

The `$sync-brief` skill automates part of this: it identifies which changes
in `workbook.tex` are "load-bearing" (new theorems, corrected formulas) and
prompts you to propagate them.

---

## What NOT to do

**Don't let it grow.** The whole point is that it's short. When it exceeds
~30 pages, prune it: move historical context to `workbook.tex`, collapse
routine results into a single table, remove anything that is not load-bearing.

**Don't put in-progress work in it.** `brief.tex` contains what is established.
If you're in the middle of a calculation, that goes in next-session-prompts, not here.

**Don't stop maintaining it.** A `brief.tex` that is 3 months out of date is
useless. Treat syncing it as part of the cost of every new result.

---

## Example entry

Bad (too much context, wrong level of detail):

> In §7 of workbook.tex, after a lengthy computation involving the functional equation
> of ξ(s) applied three times and a symmetrization over the Weyl group, we found
> that the residue of M_3 at the boundary hyperplane μ_0 = 1 equals...

Good (self-contained, exact, no derivation):

> **Theorem (boundary residue).**
> Res_{μ_0=1} M_3(μ_0, μ_1, μ_2, μ_3) = ½ Z(μ_1, μ_2, μ_3),
> where Z is the Zagier triple product (eq. Zagier3eisen).
> Analogously at all four boundary hyperplanes {μ_i = 1} and {μ_i = 0}.
> Proved: Thm 1 = Thm 2 comparison, workbook.tex sec:boundaryStructure.
> Status: ESTABLISHED.
