---
name: cross-validate
description: Format a result, derivation, or numerical value for independent verification by a second model (Claude, Gemini, or a fresh Codex context). Use for a cross-check on an important or contested result.
---

# $cross-validate

Format a physics or mathematics claim for cross-model validation.

Use this when Codex has produced a result you want to check against a second AI
model (Claude, Gemini, or a fresh Codex context). Different models fail in
different ways on the same physics, so agreement between models is meaningful
evidence; disagreement tells you exactly where to look harder.

Inspired by the "hallucination orthogonality" principle and council-mode
verification in [flonat/claude-research](https://github.com/flonat/claude-research),
and the physics-specific failure modes documented by Tim Andersen
([How to use Claude to do physics](https://timandersen.substack.com/p/how-to-use-claude-to-do-physics-and))
— documented for Claude, but the same categories (dimensional analysis, formula
provenance, plausible-but-wrong arguments) apply to every current model, including
the ones behind Codex.

## Usage

```
$cross-validate "the Gaussian integral sqrt(pi) follows from squaring and polar coordinates"
$cross-validate  (no argument — validate the last substantial result)
```

## Steps

**Step 1 — State the claim precisely.**
Write the claim as a self-contained statement including:
- The exact formula or result
- All notation and conventions needed to read it (do not assume the other model
  shares your conventions)
- The domain of validity or the specific input values

Example:
> Claim: The Gaussian integral I = ∫_{-∞}^{∞} e^{-x²} dx equals √π.
> Check this by computing I² = ∫∫ e^{-(x²+y²)} dx dy in polar coordinates,
> and confirm the radial integral gives π.

**Step 2 — List the specific checkpoints.**
Identify what a second model should verify. Focus on the documented LLM weak spots:

- **Dimensional analysis**: are all quantities dimensionally consistent?
- **Sign conventions**: which sign convention is being used and is it applied consistently?
- **Formula provenance**: is this formula standard? Does it appear (with the same
  normalisation) in a named reference?
- **Special-case check**: does the result reduce correctly at a known special value?
- **Step that looks too easy**: any step summarised as "one computes" or "it follows
  that" — ask the other model to expand it.

**Step 3 — Output the validation prompt.**
Produce a prompt ready to paste into another model. Format:

```
I want to verify a specific mathematical claim. Please check it independently —
do not try to agree with me, just derive it yourself from scratch.

[Exact statement from Step 1]

Please check:
1. [Checkpoint from Step 2]
2. [Checkpoint from Step 2]
...

If you reach a different answer, say so and explain where the derivations diverge.
```

**Step 4 — After the user returns with the second model's answer.**
Compare the two answers:

| Outcome | Interpretation |
|---------|----------------|
| Both agree | High confidence — proceed |
| Disagree on a sign or factor | Check the normalisation convention; one model is using a different definition |
| Disagree on the method | Both might be right via different routes — or one is wrong; trace the discrepancy |
| Second model refuses or is vague | Try a fresh Codex context (`codex exec`) instead |

Report which specific step or factor differs and what the most likely source of
the discrepancy is.

## Free scriptable option

The [Gemini CLI](https://github.com/google-gemini/gemini-cli) and Anthropic's
[Claude Code](https://claude.com/claude-code) can both be called from the terminal:

```bash
gemini -p "$(cat /tmp/validation_prompt.txt)"
# or, with Claude Code installed:
claude -p "$(cat /tmp/validation_prompt.txt)"
```

This lets you run the second-model check from the same terminal without switching
context. The cross-validate skill can write the prompt to `/tmp/validation_prompt.txt`
automatically if you pass `--write-prompt`.
