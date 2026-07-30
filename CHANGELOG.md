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
