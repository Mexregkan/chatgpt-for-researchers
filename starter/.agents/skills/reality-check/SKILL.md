---
name: reality-check
description: Re-derive a contested or pushed-back claim in isolation from the definitions, to catch sycophantic capitulation. Use when a result is disputed or an answer may have changed only because the user pushed back.
---

# $reality-check

Re-examine a contested claim in isolation to detect sycophantic capitulation.

Use this when you have pushed back on an answer and are not sure whether
the model revised correctly or just agreed to avoid conflict.

## The problem this solves

When you say "are you sure?" or "that sign looks wrong," the model will often revise
toward your suggestion even if the original answer was correct. The revision is
stated with the same confidence as the original. You have no way to tell from the
reply whether it actually found an error or just yielded.

This skill runs the check in a way that is insulated from the prior exchange.

## Usage

```
$reality-check "the residue at s=1/2 is +1/2, not -1/2"
$reality-check "the Euler product converges absolutely for Re(s) > 1"
$reality-check  (no argument — re-examine the last contested claim)
```

## Steps

**Step 1 — Extract the claim.**
Identify the specific assertion: the formula, sign, step, or statement that was
contested. Strip it of the conversational context — state it as a bare mathematical
or physical claim.

**Step 2 — Check it independently.**
Derive or verify the claim from scratch, using only:
- The definitions and conventions stated in AGENTS.md
- The content of brief.tex or workbook.tex (the authoritative documents)
- First principles

Do NOT use the prior conversation as evidence. Do not let the earlier exchange
influence this derivation. If the answer this time differs from the original,
say so explicitly and explain why.

**Step 3 — Compare and report.**

| Outcome | Response |
|---------|----------|
| Same answer as original | "The original answer was correct. I yielded incorrectly — reverting to [original answer]. Here is the reasoning: ..." |
| Different answer | "The revision was correct. The original error was: ..." |
| Genuinely ambiguous | "I cannot resolve this from first principles. The specific ambiguity is: ..." |

Always name which answer you are standing behind at the end of the report.

**Step 4 — If the original was right, correct the record.**
If any file was edited based on the incorrect revision (e.g., a sign in workbook.tex
was changed), fix it back now. State which files were corrected.

## When to run this without being asked

If you notice during a session that you have changed an answer after the user
expressed doubt, and you did not flag the change explicitly, run this skill
automatically. Do not wait for the user to catch the discrepancy.

## Note on fresh-context checks

For a maximally reliable check, the user can run the same question through a fresh, isolated Codex context:
`codex exec --sandbox read-only "<the bare question>"` — a non-interactive run that
has no memory of the prior exchange and cannot edit anything. If the fresh-session answer matches the original,
that is strong evidence the original was right. This skill approximates that
check within the current session; for critical claims, use a fresh session.
