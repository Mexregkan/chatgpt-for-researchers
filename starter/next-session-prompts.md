# next-session-prompts.md

<!--
PURPOSE: Session continuity across Codex sessions.

HOW TO USE:
- TOP SECTION: Keep the 1-3 most important upcoming tasks here, written as
  self-contained prompts you can paste into a new Codex session.
  Good prompts include: the goal, why it matters, what's already known,
  what success looks like, and which file/section to edit.

- DONE LOG: Move completed tasks here with a date and a one-line result.
  This is the durable project record. AGENTS.md is the current-state snapshot.

DISCIPLINE: Before ending each session, update the top section. Five minutes
of writing now saves 30 minutes of re-orientation next session.
-->

---

## Prompt A — [SHORT DESCRIPTIVE NAME] ← NEXT

**Context:**
[One paragraph. What is the mathematical/scientific situation? What was the
last result? Why is this the next thing to do?]

**What to do:**
[Precise instruction. Name the file, the section, the equation. Don't say
"work on the residue calculation" — say "compute the residue of M_3 at
mu_0 = 1 using eq (completeMaster) in sec:completeclosedform of workbook.tex,
then update brief.tex §11 to match."]

**Success criterion:**
[What does done look like? A number, a passing test, a compiled document,
a specific sentence written?]

**Files involved:** `workbook.tex`, `brief.tex`, `numerics/script.py`

---

## Prompt B — [NEXT AFTER A]

[Same structure as Prompt A]

---

## Tooling reminders
<!-- Anything Codex should check at session start: venv path, model to use, etc. -->

- Run scripts as: `numerics/venv/bin/python numerics/<script>.py`
- Compile: `pdflatex -interaction=nonstopmode workbook.tex` (twice for TOC)
- Check run log: `tail -f numerics/run.log`

---
---

# DONE

<!-- Completed tasks, most recent first. -->

### [DATE] — [Task name]
**Result:** [One-line summary of what was found/built/proved]
**Files changed:** [list]
**Notes:** [Anything surprising, any caveat, any correction to earlier results]

---

### [DATE] — [Task name]
...
