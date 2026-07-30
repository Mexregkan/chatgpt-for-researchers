---
name: verify-citation
description: Confirm a paper actually exists (arXiv / Semantic Scholar / OpenAlex) before citing it. Use before writing any new citation into a .tex, .bib, or .md file.
---

# $verify-citation

Verify that a paper exists before writing it as a citation.

Inspired by the citation-verification patterns in
[flonat/claude-research](https://github.com/flonat/claude-research) and
[Imbad0202/academic-research-skills](https://github.com/Imbad0202/academic-research-skills).

## When to use

Run `$verify-citation` before writing any new citation into a `.tex`, `.bib`,
or `.md` file. If the user asks you to "add a reference to X", run this skill
first — do not write the citation until verification passes.

## Usage

```
$verify-citation "Author, Title, Year"
$verify-citation "the paper we discussed about spectral geometry"
$verify-citation  (no argument — verify all citations in the last assistant turn)
```

## Steps

**Step 1 — Extract the citation.**
If an argument is given, use it. Otherwise, extract every paper reference from
the last assistant turn (titles, author–year pairs, DOIs, arXiv IDs).

**Step 2 — Search.**
For each citation, search at least two of:
- arXiv: `https://arxiv.org/search/?searchtype=all&query=<title+author>`
- Semantic Scholar: `https://api.semanticscholar.org/graph/v1/paper/search?query=<title>`
- OpenAlex: `https://api.openalex.org/works?search=<title>`

Run the searches with Codex's web-search tool (`web_search = "cached"` is the
default; `codex --search` or `web_search = "live"` forces live search), or fetch
the API URLs directly with `curl`.

**Step 3 — Report verdict.**

| Result | Action |
|--------|--------|
| Found on 2+ sources, title and authors match | **VERIFIED** — write the citation |
| Found on 1 source, minor title variation | **LIKELY** — note the discrepancy, write with caution |
| Found on 0 sources, or title/author mismatch | **UNVERIFIED** — do NOT write the citation |

For UNVERIFIED: say "I cannot confirm this paper exists. Do you have a DOI or
arXiv ID?" Do not invent an alternative. Do not write a citation that cannot be
verified.

**Step 4 — Write the citation (VERIFIED and LIKELY only).**
Use the metadata from the verified source (exact title, exact authors, correct
year). Never reconstruct citation details from memory — use what the database
returned.

## Anti-patterns to avoid

- Do not assume a paper exists because the title sounds familiar.
- Do not cite a paper you read during training without verifying it still exists
  and the details are correct.
- Do not mix elements from different papers into one citation ("vibe citing" —
  the hardest fabrication to detect).
- Do not mark something VERIFIED if you only searched once and found one result
  with a slightly different title.

## AGENTS.md instruction

Add this to your project's AGENTS.md to make this the default:

```
Never write a citation into any file without first running $verify-citation.
If you cannot confirm a paper exists on Semantic Scholar, arXiv, or OpenAlex,
say so explicitly and wait for a DOI or arXiv ID from me.
```
