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

## v2026.09 · v1.10.0 — 2026-09-03

**Document audits.** `$claim-audit` guards the moment a computation becomes prose. Nothing
guarded what happened next: the prose becoming the record that every later session, every
collaborator and eventually the paper reads as true. A record is written in the same pass,
from the same context, as the claim it records — so the first adversarial reader of your
workbook is whoever you send it to. This release adds the workflow for doing that read
yourself, first.

### Added
- **New section 10, [Auditing a document before you rely on it](README.md#auditing-a-document-before-you-rely-on-it)**
  (Part II; the following sections renumber 10–25 → 11–26). The five moves — mechanical
  pre-filter, sweep before you judge, an evidence class per claim, a second witness who does
  not know the story, a rubric per document type — plus the two ideas that transfer even if
  you never install anything: **sibling records are co-claims, not corroboration**, and the
  five-minute version (do the pointers resolve, is every headline typed, does the strongest
  sentence appear identically in the sibling records).
- **`$doc-audit` skill** — [`starter/.agents/skills/doc-audit/`](starter/.agents/skills/doc-audit/):
  `SKILL.md`, the mechanical pre-filter `doc_lint.sh`, per-type checklists in `rubrics.md`,
  the `report-template.md`, and `selftest.sh` (39 cases). It evaluates **one** finished
  document — workbook section, `bigPicture.tex`, `strategy-map.md`, `brief.tex`, a handoff
  message, a paper draft — and **never edits it**: findings carry proposed replacement text
  and you decide what to apply.
- **`doc_lint.sh`** reports dangling `\ref`/`\cite` keys and dead links, strength words in
  paragraphs carrying none of the eight claim statuses, hand-waving, count leads, **file
  pointers that no longer resolve** (telling "moved" apart from "gone"), unfinished markers,
  append-style retractions, relative dates, and a structural check per document type. Like
  `gate_audit.sh`, it exits non-zero with a loud banner rather than reporting a clean run on
  a file it could not parse.
- **Two read-only sub-agents (`sandbox_mode = "read-only"`).** [`doc-sweeper`](starter/.codex/agents/doc-sweeper.toml)
  extracts one ledger row per checkable claim and deliberately returns **no verdicts** —
  reading and judging in one pass gives confident verdicts on the easy claims and silence on
  the load-bearing ones. [`doc-auditor`](starter/.codex/agents/doc-auditor.toml) is the
  fresh-context adversary for a single claim, handed the claim and the evidence but never the
  caller's verdict.
- **An [`audits/`](starter/audits/README.md) folder** with the convention: one dated report
  per run, and the rule that nothing downstream may cite an audit as evidence — cite what it
  *checked*.
- **Five `BUGS.md` entries** in § F: pointers broken silently by a folder move, sibling
  records as co-claims, deleting a section orphaning the claims that pointed into it, and an
  audit report not being a record.

### Changed
- `starter/AGENTS.md` — the *Research-claim discipline* block now carries the document half
  ("audit the document before you rely on it"), `$doc-audit` is in the Skills list, and
  `audits/` is in the Files map.
- `scripts/bootstrap.sh` and the bootstrapping prompt in Part I install the kit as universal
  core, with the one fill-in it needs.

### Action needed (optional)
- To use it in an existing project: copy `starter/.agents/skills/doc-audit/`,
  `starter/.codex/agents/doc-sweeper.toml`, `starter/.codex/agents/doc-auditor.toml` and
  `starter/audits/README.md`, then **fill in the `SEARCH_DIRS` line near the top of
  `doc_lint.sh`** with the folders your documents cite scripts, logs and data from — without
  it every pointer is reported as unresolved. Run `bash .agents/skills/doc-audit/selftest.sh`
  once; it should print `39 passed, 0 failed`.

### Fixed
- **The bootstrapping prompt in Part I never installed the claim-discipline kit.** v1.16.0
  wired `simple-case-gate`, `claim-audit`, `claim-auditor` and `round-planner` into
  `scripts/bootstrap.sh` only, so a project set up through the pasted prompt got a
  `AGENTS.md` naming two `$`-commands that did not exist. The prompt now copies the kit
  verbatim.

## v2026.09 · v1.9.3 — 2026-09-01 (fix)

### Fixed
- **`disk-sweep.sh` overstated how much it protected.** The keep-list was checked *before* the
  age filter, so files that were never deletion candidates in the first place (too new) were
  counted as rescued — one project reported `protected: 105` where 88 were real. The filter now
  runs first and the count reflects what the keep-list actually saved. A reassuring number that
  nobody had audited is the same failure class as everything in `BUGS.md` §I; it is worth
  noticing that it appeared in the reporting of the tool built to prevent it.

## v2026.09 · v1.9.2 — 2026-09-01 (fix)

`disk-sweep.sh` would have queued research evidence for deletion. Found by a researcher
running v1.9.0 on a real project, which is the only place this could have shown up.

### Fixed
- **The keep-list, `SWEEP_KEEP_RE`.** v1.9.0 said the tool "asks git what is disposable".
  The code was right and the sentence was not: git was asked what is *untracked and ignored*,
  which is a **necessary** condition for disposable, never a sufficient one. On a real project
  the ignored set is not clean — a `generated/` tree is ignored *wholesale* because most of it
  is scratch, and then some of it becomes the evidence behind a published claim while keeping
  the same extension as the scratch beside it. Three collisions on one first dry run, all
  gitignored: `*.out` (hyperref bookmarks in the LaTeX glob — also the engine result logs
  behind a published section), `*.log` (run noise — also the file carrying a cited rank line),
  `*.mx` (engine scratch — also the frozen regression base states). The script now takes an
  extended regex of ignored-but-precious repo-relative paths, defaulting to the `generated/`
  convention this toolkit already teaches, and **counts and reports what it held back**
  (`protected: 3 gitignored file(s)`). `DISK_SWEEP_KEEP_RE=''` disables it deliberately.
- **The `dupes` scan no longer defaults to `$HOME`**, where the report fills with caches,
  films and audiobooks and that noise buries the findings that matter. It scans your
  `PROJECTS`; `DISK_SWEEP_DUPES_ROOT` widens it. (A deliberate wider pass did turn up a
  genuine 25 GB duplicated data file across two working directories.)
- **The documented escape hatch was inert.** `SWEEP_KEEP_RE="${DISK_SWEEP_KEEP_RE:-...}"`
  uses `:-`, which substitutes the default for an *empty* value as well as an unset one — so
  `DISK_SWEEP_KEEP_RE=''` silently kept the default. Now `-`, and tested: the default
  protects 3 of 6 fixture files and the empty override sweeps all 6.
- New `BUGS.md` §G entry for the class.

### The reason it is worth reading the section again
The guide now says what happened, because it is its own medicine: the first version's label
("asks git what is disposable") claimed more than the code checked. That is exactly the
failure the `claim-audit` skill exists to catch — **a noun in the claim that is absent from
what was computed** — and it went out in a released tool anyway.

### Action needed
- **Recommended, not optional, if you copied `disk-sweep.sh` from v1.9.0.** Re-copy
  [`starter/scripts/disk-sweep.sh`](starter/scripts/disk-sweep.sh) and set `SWEEP_KEEP_RE`
  for your project. Then run it once as a dry run and read every line before `--apply`.

## v2026.09 · v1.9.1 — 2026-09-01 (fix)

A bug found in `gate_audit.sh` by a research project that had independently hit it, plus the
regression suite that would have caught it.

### Fixed
- **`gate_audit.sh` counted the helper's own definition as a check.** A Wolfram
  `gate[lbl_, cond_] := ...` was parsed as a call site, so a file with 2 real checks reported
  3 — and every count the tool printed was inflated by one, silently and plausibly. Wolfram and
  Maple-style definitions are now recognised and skipped, and reported separately.

### Added
- **Section `[0] PARSE SANITY`** in `gate_audit.sh`: it now prints how many call sites it found,
  how many were definitions, and how many it parsed — and says **PARSE MISMATCH** when those do
  not reconcile. That catches a parser which silently *drops* checks, which the previous
  zero-checks guard could not see: dropping four of five still leaves a plausible report.
- **[`selftest.sh`](starter/.agents/skills/claim-audit/selftest.sh)**, a 16-case regression
  suite for `gate_audit.sh`. Every case asserts a detector **fires** on input designed to trip
  it, in both Wolfram and Python: zero checks, definition-only, definition-not-counted, parse
  reconciliation, all four detectors, a renamed helper via `GATE=`, and an unreadable file as a
  distinct failure from a vacuous parse.
- The design rule behind it is now in the guide, because it generalises past this one tool:
  **a tool whose output is mostly the word "none" needs a regression suite more than most code
  does**, since a detector that quietly stops firing is indistinguishable from a clean input.
  Both bugs above printed a plausible number and neither crashed. It is the skill's own "a
  control that cannot fail is not a control" rule, turned on the tool itself.
- `scripts/bootstrap.sh` now installs `selftest.sh` alongside the skill.

### Action needed
- Optional. If you copied `claim-audit` already, re-copy
  `starter/.agents/skills/claim-audit/gate_audit.sh` and add `selftest.sh`. Any counts you
  recorded from the old version were one too high wherever the helper was defined in the same
  file. Run `bash .claude/skills/claim-audit/selftest.sh` after any edit to the audit script.

## v2026.09 · v1.9.0 — 2026-09-01

Two things long runs leave behind. Mirrors the Claude twin's v1.17.0. Both cost real money, neither announces itself, and one
of them silently changes how you should read a result.

### Added
- **New guide section, [Long runs leave things behind](README.md#long-runs-leave-things-behind)**,
  under *Numerics and computation*.
- **[`wolfram-reap.sh`](starter/scripts/wolfram-reap.sh)** — kills headless
  `wolframscript -file` jobs that **finished but never exited**. A measured instance held a
  core at 100% for 2 days after writing its results: 40.7 CPU-hours after the mathematics
  was over, noticed only because the laptop was hot. The wasted core is the least of it —
  a runner blocking on the engine never reaches its own gate block, so **the runner's
  verdict is never printed** and you read the raw log and assume the runner agreed; and the
  process is reparented to init, so it outlives the terminal, the session and the agent.
- The design rule is the transferable part: **elapsed time and CPU load are never used as
  evidence.** A job is killed only when its log already contains the marker the script
  prints after all its work. Research runs are legitimately silent for hours, so a staleness
  rule would eventually kill live work — worse than a wasted core. The failure mode is safe
  in the right direction: no marker in your scripts means the reaper does nothing at all.
  Note this reuses a discipline the guide already teaches — `BUGS.md` §E gates a run on "the
  log ends with the script's own done-line"; the reaper just reads that same line as proof
  the work is over.
- **[`reap-wolfram.sh`](starter/.codex/hooks/reap-wolfram.sh)**, a Stop hook, now
  pre-registered in [`starter/.codex/hooks.json`](starter/.codex/hooks.json) (a
  harmless no-op in projects without the script). ⚠ Codex will not run a non-managed hook
  until you review and trust it — `/hooks`, inspect, trust, and re-trust after any edit.
  Until then it is silent, and that silence comes from Codex, not from the hook. Safe to fire every turn, precisely because
  a still-computing job has no marker. Pair it with a ~30-minute scheduled job for runs left
  going after you close the session — the guide gives a launchd plist and a cron line.
- **[`disk-sweep.sh`](starter/scripts/disk-sweep.sh)** — reclaims disk from regenerable
  files. Symbolic computation makes the precious file and the disposable one look identical:
  a 2 GB proof object sits next to a 2 GB scratch dump, same extension, same directory. So
  the script does not decide what is precious — **it asks git.** Its only candidates are
  files matching `git ls-files --others --ignored --exclude-standard`, so a tracked file
  cannot be selected and committed results are safe *structurally*, not by a remembered
  exception. Dry run by default; research data is reported (`dupes`), never deleted.
- The habit that falls out of it, and the reason it is in the guide: **`.gitignore` is your
  delete list.** If a heavy generated file is precious, commit it or un-ignore it. One file
  then drives both git and the cleanup, and the two cannot disagree.
- Two new `BUGS.md` entries in §E (a finished run that never exits; never kill on elapsed
  time) and three in §G (never delete generated files by extension/size/age; identical size
  is a hint not evidence; a cleanup tool that logs forever becomes a disk-growth source).
- `scripts/bootstrap.sh` installs `disk-sweep.sh` for every project and the reaper + its hook
  only for Mathematica projects.

### Action needed
- Optional. Mathematica projects: copy `starter/scripts/wolfram-reap.sh` and
  `starter/.codex/hooks/reap-wolfram.sh`, and add the `Stop` hook block from
  [`starter/.codex/hooks.json`](starter/.codex/hooks.json). If your scripts print a
  gate counter or summary line after all their work, set `WOLFRAM_REAP_DONE_RE` to match it —
  a marker printed only after every check has run is stronger evidence than a done-line.
- Optional. Any project: copy `starter/scripts/disk-sweep.sh` and fill in its `PROJECTS`
  array, listing nested repos separately — a nested repo is invisible to its parent's
  `git ls-files`, so an unlisted one is simply never swept.

## v2026.09 · v1.8.0 — 2026-09-01

Two disciplines that sit either side of a calculation: choosing which case to test, and
choosing what to call the result. Mirrors the Claude twin's v1.16.0.

### Added
- **New guide section, [Claim discipline: name only what you computed](README.md#claim-discipline-name-only-what-you-computed)**
  (Part II, section 9 — the Table of Contents renumbers 9–24 to 10–25). The two failure
  modes: escalating to a harder case after a proposal fails at the simplest one, and naming
  more than you computed.
- **[`simple-case-gate`](starter/.agents/skills/simple-case-gate/SKILL.md) skill** — identify
  the simplest admissible nondegenerate case and make the *exact* proposal pass there before
  increasing order, weight, rank, dimension, or free parameters. When it fails, preserve the
  first exact residual and **stop escalating**. A modified proposal restarts the gate, and a
  simple case may be skipped only if the exclusion follows from the domain you stated *before*
  the test.
- **[`claim-audit`](starter/.agents/skills/claim-audit/SKILL.md) skill** — the hostile read of
  your own result, after the script passes and **before** any prose exists. The idea it rests
  on: an overclaim is not written in the summary, it is minted in the **label on a check**, and
  the summary, commit message, changelog row and workbook section then inherit it because they
  are written in one pass from one context. Ships the *computed-object ledger* (symbol
  literally constructed in the code → restriction actually established → headline, banning a
  headline noun absent from the code), the weakest-statement rewrite of every label, and the
  tell that costs nothing: if you are writing a sentence explaining why a check is not trivial,
  the check is trivial.
- **`gate_audit.sh`**, the mechanical pre-filter: hand-assigned values, over-budget labels,
  advocacy language, and bodies whose shape is true for every input. It reads both
  `gate("label", body)` and `gate[...]`, so Python, Julia and Wolfram all work — and it
  **exits non-zero and says so loudly when it parses no labelled checks**, rather than
  printing an all-clear on a file it could not read.
- Two non-negotiable blocks in [`starter/AGENTS.md`](starter/AGENTS.md) — *Simple-case gate*
  and *Research-claim discipline* — so both rules apply when nobody invokes a skill.
- Two new sections in [`starter/BUGS.md`](starter/BUGS.md): **H** (strategy selection and
  escalation) and **I** (claim generation).
- **Two read-only sub-agents**, [`claim-auditor`](starter/.codex/agents/claim-auditor.toml)
  and [`round-planner`](starter/.codex/agents/round-planner.toml). The first is the
  fresh-context hostile reader: give it the artifacts and the drafted claim, and deliberately
  **not** your reasoning or what you hope is true — those are what the audit exists to test
  around, and a fresh context handed the narrative will reconstruct your conclusion and agree
  with you. The second answers "is this thread still moving?", classifying a round ADVANCE /
  USEFUL NEGATIVE / LOOP / UNRESOLVED and naming which loop signal fired. Its mechanical test:
  compare the tuple (target · simplest case in play · exact residual · the step being
  established) against the previous round — unchanged means loop, however different the code.
- Both use `sandbox_mode = "read-only"`, which on this side is the **stronger** of the two
  available levers: it blocks writes at the filesystem, including a write a shell command
  would attempt. (The Claude twin restricts the agent's tool list instead, which leaves a
  hole — an agent holding a shell tool can write through it whatever its prompt says. Codex
  has no per-agent tool allowlist, so the sandbox is the lever here, and for a read-only agent
  it is the better one.) Both READMEs now say this in the same place.
- Both skills and both agents install as **universal core** in `scripts/bootstrap.sh` — the
  `AGENTS.md` blocks name the skills, so a conditional install would leave a dangling
  `$command`.

### Changed
- **One epistemic-status vocabulary with documented coarsenings.** The
  [trust ledger](README.md#make-epistemic-status-explicit-a-trust-ledger)'s four levels stay as
  the minimum workable set and now point at the finer eight-status list, which splits the two
  distinctions the four blur: exact-but-bounded (`finite verification`) against approximate
  (`numerical evidence`), and a proved negative (`obstruction`) against simply `open`.

### Action needed
- Optional. Existing projects: copy `starter/.agents/skills/simple-case-gate/` and
  `starter/.agents/skills/claim-audit/` into `.agents/skills/`, and add the two blocks from
  [`starter/AGENTS.md`](starter/AGENTS.md) to your own. To let `gate_audit.sh` read your
  scripts, wrap checks as `gate("short neutral label", <expression>)` — the change that makes
  labels auditable at all, worth doing even if you never run the script.
- Optional. Existing projects: copy `starter/.codex/agents/claim-auditor.toml` and
  `starter/.codex/agents/round-planner.toml` into `.codex/agents/`. Nothing else changes if
  you don't — an unspawned sub-agent costs nothing.

## v2026.08 · v1.7.0 — 2026-08-25 (update)

### Added
- **A commit-and-push sub-agent, [`git-committer`](starter/.codex/agents/git-committer.toml)**
  — the second agent to ship in `starter/`, and the first that is not tied to an optional
  workflow. The idea: stop letting the main session run `git commit` at all. A research
  working tree is almost never clean, and a session that is deep in a long task reaches for
  `git add -A`; your half-finished workbook section then lands in the permanent record
  attached to somebody else's commit message. The agent stages **only** the files it was
  named — never `git add .`, `-A`, `-u`, or a glob it expanded itself — appends nothing to
  your message (no `Co-Authored-By`), refuses the protected files you list, pushes to each
  remote in the order you gave, and reports git's own output verbatim. A rejected push stops
  and reports; it never pulls, merges, rebases, or forces on its own.
- New guide subsection, **"Give commits to a dedicated sub-agent"**, in
  [Git workflow for academics](README.md#git-workflow-for-academics) — the failure mode, the
  rules and why each one is there, and the two project blocks you fill in inside
  `developer_instructions` (your repos with their remotes and push order, and your protected
  files). If your tree contains a nested repo — a sub-project with its own remote, or a cloned
  `Overleaf/` — you list it there with its own rule, including "never push this one", so the
  agent cannot publish to a shared paper by accident.
- **Two Codex specifics are stated honestly rather than glossed.** The committer runs
  `sandbox_mode = "workspace-write"`, not the auditor's `read-only`, because git writes; and
  Codex agent TOML has **no per-agent tool allowlist**, so there is no way to hand an agent
  git without also handing it your editor — "it never modifies your sources" is enforced by
  its instructions, not by the platform. (The Claude twin's equivalent agent can simply omit
  the edit tool; the differences table now says so.) Separately, `git push` needs the network:
  with `network_access = true` it runs inside the sandbox, and with it `false` the push raises
  an approval request that can surface from the inactive agent thread — check `/agent` if a
  commit seems to hang.
- The bootstrap script installs it as part of the **universal core** (every project commits),
  and the README's bootstrapping prompt tells Codex to fill in its project blocks in
  session 1.

### Action needed
- Optional. Existing projects: copy
  [`starter/.codex/agents/git-committer.toml`](starter/.codex/agents/git-committer.toml) into
  `.codex/agents/` and fill in the two project blocks inside `developer_instructions`.
  Nothing else changes if you don't.

## v2026.08 · v1.6.0 — 2026-08-14 (update)

### Added
- **The permission modes are now documented properly, including "Approve for me".**
  Previously this guide mentioned auto-review only as a one-line aside. It now carries the
  full table — **Ask for approval** (the default: `workspace-write` / `on-request`, you are
  the reviewer), **Approve for me**, **Full access**, **Custom** — plus a subsection on what
  delegating approvals actually buys you. In "Approve for me", Codex routes each approval
  request to a **separate reviewer agent** that decides and returns a rationale; it is
  designed to deny sending secrets or credentials to untrusted locations, credential and
  token extraction, broad security weakening, and irreversibly destructive operations. The
  policy is open source and customisable, and organisations can pin their own via
  `guardian_policy_config` in managed requirements. Enable it with
  `approvals_reviewer = "auto_review"` alongside `approval_policy = "on-request"`, from
  `/permissions`, or under **Settings → General → Permissions** in the desktop app. It is
  **not** the default, and OpenAI notes it "carries elevated risk of mistakes".
  - Two properties decide how much it protects you: it **does not widen the sandbox** (it
    changes *who decides* about a boundary crossing, not where the boundary sits), and
    **routine in-sandbox actions bypass review entirely** — only boundary crossings reach
    the reviewer.

### Changed
- **New subsection: protecting what is irreplaceable** — the consequence of that second
  property, and the one thing neither the sandbox nor the reviewer does for you. An
  overwrite of a ground-truth data file *inside* the workspace never crosses a boundary, so
  it is never reviewed in either mode; a table that took three weeks of CPU looks exactly
  like a scratch file to an OS-level sandbox. Codex has **no per-path deny list** —
  `sandbox_workspace_write.writable_roots` only *extends* where writes are allowed, and
  there is no `exclude` key — so the guide now recommends the two mechanisms that do work:
  **keep irreplaceable data outside the workspace root** (making any write to it a boundary
  crossing, enforced by the OS), and **forbid destructive command prefixes** with an
  execution-policy rule. Rules live in `~/.codex/rules/default.rules`, are written in
  Starlark (`prefix_rule(pattern = ["rm", "-rf"], decision = "forbidden", …)`, where the
  most restrictive match wins), and are checkable with
  `codex execpolicy check --rules <file> -- <command>`. They are still marked experimental,
  and the guide says so.
- `starter/.codex/config.toml` carries the same warning inline, next to the keys it applies
  to.
- The Claude/Codex differences table now states the real distinction rather than implying
  the two are equivalent: Claude's auto mode is a *session-wide default baseline*; Codex's
  "Approve for me" is *opt-in* and only vets *boundary crossings*, with the sandbox — not a
  classifier — as the primary mechanism.

**Action needed (optional):** none for existing setups; the default mode is unchanged. If
you keep irreplaceable data inside your project folder, the new subsection is worth five
minutes — moving it outside the workspace root is what turns a silent overwrite into a
prompt.

*Mirrors the Claude twin's v1.14.0/v1.14.1 permissions work, adapted: the two ecosystems
differ more here than anywhere else in these guides.*

## v2026.08 · v1.5.0 — 2026-08-14 (update)

### Added
- **`BUGS.md` — the recurring-mistake registry**, now a fifth universal file alongside
  `AGENTS.md` and the trinity, with a new guide section
  ([BUGS.md: the recurring-mistake registry](README.md#bugsmd-the-recurring-mistake-registry))
  and a [`starter/BUGS.md`](starter/BUGS.md) template. The premise: the bugs that cost days
  are the ones that hand back a **plausible number with no error at all** — a pattern that
  matched nothing and so "changed nothing", a control that could not have failed, a
  convention imported from a paper that computes perfectly and answers a different question.
  They recur, and they are invisible to code review. So each one gets a short
  `symptom → cause → guard` entry, filed by failure mode, and the file carries a standing
  rule at the top: **read it before writing or editing any code, and add a new class in the
  same turn you fix it**.
  - **The unit is the class, not the incident.** "The run on 3 June gave the wrong
    normalisation" is a logbook entry; "a formula imported from a paper carries the paper's
    conventions, so gate it against something this project measured independently" is a
    registry entry — it will fire again, on a different paper, next year. Narratives stay in
    `workbook.tex` and `CHANGELOG.md`; the entry links to them in one parenthesis.
  - **Three marks that make it self-maintaining**: 🔴 has bitten us more than once · ⚠ silent
    (a confident wrong answer, not an error) · ✅ has a mechanical guard. Promoting an entry
    to 🔴 the second time it bites is a standing instruction to go build the ✅ — an assert
    that aborts beats a sentence you have to remember, and the prose entry then survives as
    the explanation of what the gate does *not* cover.
  - **Why a separate file rather than a `GOTCHAS` section of `AGENTS.md`**: the instruction
    file is loaded in full at the start of every session and is subject to
    `project_doc_max_bytes` (32 KiB by default). A trap list grows without limit and is only
    needed when code is about to be written — so it is read on demand instead, and a second
    agent in the repo reads the same one registry.
  - **Two rules worth adopting even without the file**, both now in `starter/AGENTS.md`:
    *if two diagnostics in one run disagree, the bug is in a diagnostic, not in the science*;
    and *a control that cannot fail is worse than no control* — before calling a control
    passed, state what it could have detected, and if the answer is "nothing", call it
    **vacuous**. The second is a rule about *reporting*, which is exactly where an eager
    assistant rounds "the test was empty" up to "the test passed".
  - The template ships the section skeleton, the legend, the standing rule, and a set of
    starting entries that are true in almost any computational project. It is
    **agent-agnostic and byte-identical to the Claude twin's copy** — like the `handoff/`
    mailbox kit, a fix on either side belongs on both.

### Changed
- **The trap-log advice in *Honest limitations* is now a pointer, not a second copy.** That
  section previously suggested keeping traps in a `GOTCHAS` section; it now explains *why*
  silent wrong answers belong under "what the model gets wrong" and sends the reader to the
  registry for the mechanics. Codex's memories feature is the complement, not the substitute
  — and since it is experimental and off by default, the file does the real work here.
- **`scripts/bootstrap.sh` installs `BUGS.md` for every project**, and both setup routes
  (the paste-in prompt and the script) now ask Codex to stamp your name and date into the
  standing rule, keep the sections matching your engine, and delete the `[EXAMPLE]` entries.

**Action needed (optional):** copy [`starter/BUGS.md`](starter/BUGS.md) into your project
root and add the pointer + standing rule to your `AGENTS.md` (the block is in
[`starter/AGENTS.md`](starter/AGENTS.md), under *Recurring mistakes*). Nothing breaks
without it — but the file only starts paying when something is written in it, so the useful
first step is to add the last trap that cost you an afternoon.

*Mirrors the Claude twin's v1.13.0.*

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
