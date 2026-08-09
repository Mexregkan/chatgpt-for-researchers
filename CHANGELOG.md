# Changelog

Notable, user-facing changes to this toolkit. This is a curated list of the
updates worth knowing about — not every commit (see the git history for that).
Useful for deciding whether to re-copy anything from `starter/` into a project
you set up from an earlier version.

Versioning is primarily calendar-based (`vYYYY.MM`): this is a guide and a copy-in
starter pack, not a linked library, so there is no API to break — the calendar tag
answers "how current is my copy?". Alongside it each release also carries a semantic
version (`MAJOR.MINOR.PATCH`): **PATCH** for a fix or clarification, **MINOR** for a new
skill/tool/guide section, **MAJOR** only if an update would break an existing setup (force
a re-copy to keep working).

## v2026.08 · v1.4.0 — 2026-08-09 (update)

### Changed
- **Mailbox: a message body is now mandatory, and `hx.sh lint` is the backstop.** From
  real use — a body file passed as a bare extra argument was *silently ignored* and the
  message went out as an empty template, so the other agent opened a blank form and the
  thread stalled. Three fixes, all worth copying into any agent-facing tool: `hx.sh`
  refuses to create a body-less message (`-b <file>` supplies it, `--stub` is the
  explicit opt-in to a template); any unknown or extra argument is a **hard error**
  instead of being dropped; and `hx.sh lint` fails on unfilled placeholders, a body
  under six content lines, or a message over the cap. The starter's Stop hook
  (`promise-checker.sh`) runs the lint, so a forgotten stub is caught at session end.
  A detail from writing the linter that generalises: "does the line start with `<`" is
  the obvious stub test and it is wrong — it flags bra-ket notation like `<e1|M|v>` and
  every `<=`. Placeholders are matched as exact fixed strings from the template instead.
- **The model now lives in the identity, not a separate field.** `FROM:`/`TO:` read
  `claude (Opus 5)` / `codex (ChatGPT Sol 5.6)`. The first word is the routing key
  (`mine`, replies, filenames and archiving all match on it); the parenthesised model is
  for humans. Both strings are two variables at the top of `hx.sh` — one place to edit
  when you switch model, and no one ever hand-types an identity. This replaces the
  per-message `MODEL:` field, `HX_MODEL` and `hx.sh reindex` from the previous release:
  same goal, no per-message bookkeeping and nothing to leave unfilled.
- **The line cap is now 100** (`MAXLINES` in `hx.sh`), raised twice under real use after
  rounds of genuine content had to be squeezed to fit. The cap exists to stop a message
  becoming a write-up, not to force compression of substance — if the gates and their
  limitations need the room, take it.

### Fixed
- **`-b` paths now resolve against your own directory.** `hx.sh` cd's into `handoff/` at
  startup, so a relative `-b body.md` written from the repo root was looked up inside
  `handoff/` — failing confusingly, or picking up a same-named file that happened to live
  there. (Same root cause as the earlier `$0` usage-text bug.)
- **The Stop hook no longer skips the mailbox check.** It returned early whenever the last
  assistant turn could not be parsed, which also skipped the handoff lint — a check that
  does not depend on the transcript at all. It also reported only the first of the two
  findings; a promise-checker hit no longer masks a pending stub.
- `hx.sh list` reads the front matter rather than parsing the filename, and `thread`
  column widths fit the longer identities. `INBOX.md` keeps its file mode when rewritten.

**Action needed (optional):** re-copy `starter/handoff/` and
`starter/.codex/hooks/promise-checker.sh`. The command signature changed — `new`/`reply`
now require `-b <bodyfile>`, `-t` replaces the bare third argument for a thread slug, and
`reindex` is gone — so if your instruction file documents the old form, update it (the
starter's *Handover to the other agent* section is already updated). Existing messages
keep working; identities without a model just display as written.

Mirrored from the Claude twin (`claude-for-researchers` v1.12.0); the `handoff/` kit
stays byte-identical between the two repos.

## v2026.08 · v1.3.0 — 2026-08-04 (update)

### Added
- **Mailbox messages now record which *model* wrote them.** A `MODEL:` front-matter
  field, shown in the `INBOX.md` row and in `hx.sh list` / `thread` as
  `codex (GPT-5.6-sol)` / `claude (Opus 5)`. "Codex said the sign was wrong" ages
  badly: `gpt-5.6-sol` and `gpt-5.6-terra` are not the same witness, and neither are
  Opus 5 and Haiku 4.5. When two messages disagree, or a six-week-old claim turns out
  to be wrong, the model is half of *who said it*. Neither CLI exports its model name,
  so it cannot be sniffed — set `HX_MODEL="GPT-5.6-sol"` once per session, or fill the
  `MODEL:` line the stub leaves you. An unstamped message shows as `(?)` rather than
  passing as anonymous, and `hx.sh` says so at the point of writing.
- **`hx.sh reindex`.** Rebuilds every open `INBOX.md` row from the messages themselves
  — for after you fill in a `MODEL:` by hand, or any time the index and the messages
  disagree. The messages win; the closed-threads table is left alone.
  **Action needed (optional):** if you already copied `starter/handoff/`, re-copy
  `hx.sh`, `README.md` and `INBOX.md` to get the model field. Existing messages
  without a `MODEL:` line keep working — they just show as `(?)`.

Mirrored in the Claude twin (`claude-for-researchers` v1.11.0); `starter/handoff/`
remains byte-identical between the two repos.

## v2026.08 · v1.2.0 — 2026-08-04 (update)

### Added
- **The agent mailbox (`handoff/`).** A new subsection of *Using both: Claude and Codex
  on one project* — **The mailbox: how they hand work to each other** — plus a ready-made
  kit in `starter/handoff/`. The bridge pattern already in the guide is *synchronous*
  (one agent calls the other and waits); most two-agent work is asynchronous, and left
  alone it degenerates: handover notes pile up as ad-hoc files, both agents re-read all
  of them every session, and the obvious way to "reply" is to edit the other's note in
  place, which the other never notices. The mailbox fixes all three: `INBOX.md` is an
  index (one row per thread) and is the only file read at session start; `hx.sh` writes
  the message and the index row so neither agent has to recall the format; threads are
  archived, not deleted, because settled threads are the only record of *why* a decision
  was reversed.
  Three rules, each from a real failure: never edit the other agent's message (reply
  instead); cap messages at 40 lines (detail belongs in the workbook and changelog); and
  **state your gates including what they do not cover** — the section documents a case
  where a 71-value exact check was cited as confirming a result while contributing
  exactly zero to the quantity in dispute, and a second error of the same shape in the
  same session. A gate whose scope is unstated is not evidence.
  `hx.sh` selects threads on the `THREAD:` front-matter field, never on the filename —
  a filename glob both misses renamed messages (it archives nothing while reporting
  success) and over-matches any slug that merely *ends* in the same text, so closing
  `z11` would take a live `delta-z11` thread with it.
- **`starter/AGENTS.md` carries the wiring.** A new *Handover to the other agent*
  section makes checking `handoff/INBOX.md` step 1 of resuming a session, with the
  message rules inline. Since `AGENTS.md` is the single source of truth and `CLAUDE.md`
  can be a one-line `@AGENTS.md` import, that one section briefs both agents.
  **Action needed (optional):** delete the section if only one agent works in your repo.
- **`scripts/bootstrap.sh` now offers the mailbox.** A new question — *"Will a SECOND
  agent (e.g. Claude Code) also work in this repo?"*, default no — installs
  `starter/handoff/`. Gated rather than installed by default: unlike the Pipeline
  workflow, the mailbox is not inert when unused, because the protocol asks every
  session to read `INBOX.md`.

This section is mirrored in the Claude twin (`claude-for-researchers` v1.10.0); the
`handoff/` kit itself is agent-agnostic and byte-identical between the two repos.

## v2026.07 · v1.1.1 — 2026-07-30 (update)

### Clarified
- **distill: point the standing rule at your global `~/.codex/AGENTS.md`.** The distill
  section (§18) previously said to add the "always prefix noisy commands with distill"
  rule to "your AGENTS.md" without saying which one, so a reader would drop it into a
  single project's file. It now names the personal `~/.codex/AGENTS.md` (which loads in
  every project) as the place for a machine-wide tool like distill — with a link to the
  configuration-files section that explains that file — and notes a project `AGENTS.md`
  as the option for scoping it to one repo. This mirrors the Claude twin's wording, which
  already pointed at the global `~/.claude/` location.

### Action needed
- **Nothing — guide-only.** No starter file changed.

---

## v2026.07 · v1.1.0 — 2026-07-30 (update)

### Added
- **The Claude twin: claude-for-researchers.** A new appendix section introducing the
  sister repo this toolkit was ported from —
  [claude-for-researchers](https://github.com/Mexregkan/claude-for-researchers), the
  battle-tested Claude Code original — with a side-by-side table of exactly which files
  differ between the twins and how (AGENTS.md ↔ CLAUDE.md, config.toml sandbox/approvals
  ↔ settings.json permission lists, `$skill` ↔ `/skill`, hooks.json + `/hooks` trust ↔
  settings.json hooks, and so on). Everything agent-agnostic is byte-identical between
  the twins and kept in sync. The same section, mirrored, now also lives in that repo.
- **Using both: Claude and Codex on one project.** A second new appendix section for
  researchers who want *both* agents on the same project: one setup without drift (a
  single `AGENTS.md` as source of truth with `CLAUDE.md` reduced to an `@AGENTS.md`
  import; one canonical skills folder, symlinked; the same hook scripts registered in
  both `.codex/hooks.json` and `.claude/settings.json`; the one-writer-at-a-time rule
  with git as the handover). It then documents **the bridge**: each agent can consult
  the other as a subprocess — `claude -p "…"` from a Codex session,
  `codex exec --sandbox read-only "…"` from a Claude session — turning cross-model
  validation into one shell command. Three worked patterns (second opinion, cross-review
  of a landed diff, a standing second-opinion rule) plus the honest caveats: you are the
  referee, keep consultations read-only and blind, one round only.

### Action needed
- **Nothing — guide-only.** No starter file changed.

---

## v2026.07 · v1.0.0 — 2026-07-30 (initial release)

### Added
- **The full toolkit, ported for OpenAI Codex.** This repository is the ChatGPT twin of
  [claude-for-researchers](https://github.com/Mexregkan/claude-for-researchers), created
  by porting that toolkit (at its v2026.07 · v1.8.0) section by section and re-verifying
  every platform-specific claim against OpenAI's official Codex documentation. The
  workflow patterns — the AGENTS.md discipline, the dual-document pattern
  (workbook/brief), session continuity via next-session-prompts.md, the validation
  habits — are the ones proven in months of real research use on the Claude side. The
  Codex-specific wiring is a faithful port; the README says honestly that it has not yet
  been load-tested in a long research project of its own.
- **README guide** (Parts I–IV + appendix): installation and first launch (VS Code
  extension + CLI), bootstrapping a project with one pasted prompt or
  `scripts/bootstrap.sh`, the AGENTS.md chapter (including nested AGENTS.md, the
  status-vs-changelog split, and the research changelog), dual-document pattern, session
  continuity and strategy maps, context limits and compaction (with `/status`, `/usage`,
  `/compact`, and the PreCompact hook), plan mode (`/plan`), skills, git for academics
  (dual remotes + the Overleaf git-clone workflow), numerics (mpmath + Wolfbook, incl.
  the bridge-safety and headless-Wolfram trap write-ups), config and hooks, group
  projects, sub-agents, token economy, the pipeline workflow, distill, GitHub README
  math, and the honest-limitations chapter.
- **Starter package** (`starter/`): `AGENTS.md` template; workbook/brief/
  next-session-prompts trinity; optional big-project templates (bigPicture.tex,
  strategy-map.md, research CHANGELOG.md); project config
  (`.codex/config.toml`: workspace-write sandbox + on-request approvals); hooks
  (`.codex/hooks.json` with pre-compact + promise-checker enabled, git-mirror /
  pipeline-guard / wolfram-license-notice shipped off with documented enable blocks);
  the read-only `pipeline-auditor` sub-agent (`.codex/agents/pipeline-auditor.toml`,
  `sandbox_mode = "read-only"`); and **fourteen skills** in `.agents/skills/`:
  latex-compile, sync-brief, verify-citation, reality-check, cross-validate,
  overleaf-sync, nb-to-wolfbook (+ helper scripts), sync-wb-nb (+ helper), wolfbook,
  wolfram-headless (+ helpers), write-pipeline (+ dump_code.py), check-pipeline,
  apply-pipeline.
- **Scripts**: `bootstrap.sh` (interactive setup installing the core + only the relevant
  skills, with the one-time trust steps printed at the end), `git-push-both.sh`,
  `readme-latex-check.sh`, `patch-wolfbook-splitter.py`, `apply-notebook-ux.py`,
  `generate_flowcharts.py`.
- **Docs**: `condensed-notes-guide.md`, `pipeline-workflow.md`, and the three Wolfbook
  write-ups (kernel errors, comment-split fix, notebook UX).

### Notes on the port (what differs from the Claude twin, and why)
- `CLAUDE.md` → `AGENTS.md` (the open agents.md standard; Codex merges a root-to-subdir
  chain natively, with a 32 KiB default project-doc budget).
- `.claude/settings.json` permission lists → `.codex/config.toml` sandbox + approval
  policy (the same allow-routine / ask-before-dangerous philosophy, enforced by an
  OS-level sandbox instead of command-pattern lists).
- Skills use the same open SKILL.md folder standard, live in `.agents/skills/`
  (project) or `~/.agents/skills/` (user scope), and are invoked with `$name`
  mentions instead of `/name`.
- Hooks use Codex's Claude-compatible hooks system (`.codex/hooks.json`); every hook
  must be reviewed and trusted once via `/hooks` before it runs.
- The pipeline-auditor sub-agent is a TOML definition whose read-only sandbox is
  platform-enforced; `$reality-check` uses `codex exec --sandbox read-only` for its
  fresh-context check.
- The rtk section of the Claude guide has no Codex equivalent to recommend; the token
  chapter covers Codex-native levers (cached web search, model/effort switching,
  sub-agents) plus the agent-agnostic distill filter.

### Action needed
- Nothing — this is the initial release.
