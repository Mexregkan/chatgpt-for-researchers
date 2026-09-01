#!/bin/sh
# bootstrap.sh — interactive setup for the chatgpt-for-researchers workflow (OpenAI Codex).
#
# Usage (run it from the folder you want to set up):
#   sh /path/to/chatgpt-for-researchers/scripts/bootstrap.sh
# or without cloning the repo first:
#   curl -fsSL https://raw.githubusercontent.com/Mexregkan/chatgpt-for-researchers/main/scripts/bootstrap.sh | sh
#
# It asks a few questions and installs:
#   - the universal core, for every project: AGENTS.md + the "holy trinity"
#     (workbook.tex, brief.tex, next-session-prompts.md) + BUGS.md
#   - generic infrastructure: .codex/config.toml, .codex/hooks.json + hook scripts,
#     .gitignore
#   - ONLY the skills your answers make relevant, into .agents/skills/ (a skill
#     already present in ~/.agents/skills/ is skipped — user-scope skills work in
#     every project)
#   - numerics/generated/ and figures/generated/ staging folders if you run numerics
#
# The script gives you correct STRUCTURE; the domain CONTENT (introduction,
# conventions, the first task) still comes from your first Codex session —
# the script prints the exact prompt to paste when it finishes.
# Existing files are never overwritten.

REPO_RAW="https://raw.githubusercontent.com/Mexregkan/chatgpt-for-researchers/main"

say() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

# Prefer the local clone next to this script; fall back to fetching from GitHub
# (the curl | sh case).
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || SCRIPT_DIR=""
REPO_LOCAL=""
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../starter/AGENTS.md" ]; then
    REPO_LOCAL=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
fi

# Interaction goes through /dev/tty so the script stays interactive when piped
# from curl; fall back to stdin when no tty is available.
if ( : </dev/tty ) 2>/dev/null; then IN=/dev/tty; else IN=""; fi
ask() { # $1 = prompt -> sets ANS
    if [ -n "$IN" ]; then
        printf '%s ' "$1" >/dev/tty
        IFS= read -r ANS <"$IN"
    else
        printf '%s ' "$1"
        IFS= read -r ANS || ANS=""
    fi
}
yesno() { # $1 = prompt, $2 = default y|n -> return 0 for yes
    while :; do
        ask "$1 [$2]"
        [ -z "$ANS" ] && ANS=$2
        case $ANS in [Yy]*) return 0 ;; [Nn]*) return 1 ;; esac
    done
}

fetch() { # $1 = path relative to repo root, $2 = destination
    if [ -n "$REPO_LOCAL" ]; then
        cp "$REPO_LOCAL/$1" "$2" || die "cannot copy $1"
    else
        curl -fsSL "$REPO_RAW/$1" -o "$2" || die "cannot fetch $1 from GitHub"
    fi
}
core() { # $1 = source rel path, $2 = destination — never overwrite
    if [ -e "$2" ]; then
        say "  skip $2 (already exists — not overwriting)"
    else
        fetch "$1" "$2" && say "  ok   $2"
    fi
}
skill() { # $1 = skill name [, $2.. = companion files relative to the skill dir]
    if [ -f "$HOME/.agents/skills/$1/SKILL.md" ]; then
        say "  skip skill $1 (in ~/.agents/skills — available in every project already)"
        return 0
    fi
    name=$1; shift
    mkdir -p ".agents/skills/$name"
    fetch "starter/.agents/skills/$name/SKILL.md" ".agents/skills/$name/SKILL.md"
    for comp in "$@"; do   # companions may live in subdirs (e.g. scripts/foo.py)
        mkdir -p ".agents/skills/$name/$(dirname "$comp")"
        fetch "starter/.agents/skills/$name/$comp" ".agents/skills/$name/$comp"
    done
    say "  ok   skill $name"
}

say "== chatgpt-for-researchers bootstrap =="
say "A few questions; only the relevant pieces get installed."
say ""
ask "Project title:";                       TITLE=$ANS
ask "Author name (for the LaTeX documents):"; AUTHOR=$ANS
ask "Numerics engine — (m)athematica, (p)ython, (b)oth, (n)one:"
case $ANS in
    [Mm]*) NUMERICS=mathematica ;;
    [Pp]*) NUMERICS=python ;;
    [Bb]*) NUMERICS=both ;;
    *)     NUMERICS=none ;;
esac
yesno "Will you cite literature (bibliography)?" y          && CITE=1    || CITE=0
yesno "Install validation skills (reality-check, cross-validate)? Recommended when the model does derivations." y \
                                                            && VALID=1   || VALID=0
yesno "Is this paired with a SHARED Overleaf project?" n    && OVERLEAF=1 || OVERLEAF=0
yesno "Do you push to TWO git remotes (e.g. personal GitHub + institution GitLab)?" n \
                                                            && DUALREMOTE=1 || DUALREMOTE=0
yesno "Large / multi-branch project? (adds bigPicture.tex overview, strategy-map.md route plan, CHANGELOG.md result log)" n \
                                                            && BIGPROJECT=1 || BIGPROJECT=0
yesno "Will a SECOND agent (e.g. Claude Code) also work in this repo? (adds handoff/, the agent mailbox)" n \
                                                            && TWOAGENTS=1 || TWOAGENTS=0

say ""
say "Core files (universal — every project gets these):"
mkdir -p .codex/hooks .codex/agents .agents/skills
core starter/AGENTS.md                        AGENTS.md
core starter/workbook.tex                     workbook.tex
core starter/brief.tex                        brief.tex
core starter/next-session-prompts.md          next-session-prompts.md
core starter/BUGS.md                          BUGS.md
core starter/.gitignore                       .gitignore
core starter/.codex/config.toml               .codex/config.toml
core starter/.codex/hooks.json                .codex/hooks.json
core starter/.codex/hooks/pre-compact.sh      .codex/hooks/pre-compact.sh
core starter/.codex/hooks/promise-checker.sh  .codex/hooks/promise-checker.sh
core starter/.codex/agents/git-committer.toml .codex/agents/git-committer.toml
core starter/.codex/agents/claim-auditor.toml .codex/agents/claim-auditor.toml
core starter/.codex/agents/round-planner.toml .codex/agents/round-planner.toml
chmod +x .codex/hooks/*.sh 2>/dev/null
say "  -> BUGS.md is the recurring-mistake registry: one symptom -> cause -> guard entry"
say "     per class of mistake, read before writing any code. It ships with generic"
say "     starting entries; replace them with your own as the project bites you."
say "  -> claim-auditor + round-planner are read-only sub-agents (sandbox_mode=read-only,"
say "     so they cannot write). Spawn claim-auditor with artifacts and the drafted claim"
say "     but NOT your reasoning; round-planner tells you whether a thread is looping."
say "  -> \$simple-case-gate before you compute, \$claim-audit after the script passes and"
say "     BEFORE you write it up. claim-audit's gate_audit.sh reads checks written as"
say "     gate(\"short neutral label\", <expression>) — wrap your checks that way."
say "  -> git-committer is the commit-and-push sub-agent (every commit goes through it,"
say "     so nothing ever gets \`git add .\`-ed by accident). FILL IN its two project"
say "     blocks: your repos + remotes + push order, and your protected files."

# Big-project templates (optional): the equation-light overview doc, the strategy
# map, and the research changelog. Only useful once a project is large /
# multi-branch, so they are gated on the answer above rather than installed for
# every project. (CHANGELOG.md stays EMPTY of rows until the DONE log in
# next-session-prompts.md outgrows itself — the template says so.)
if [ "$BIGPROJECT" -eq 1 ]; then
    core starter/bigPicture.tex  bigPicture.tex
    core starter/strategy-map.md strategy-map.md
    core starter/CHANGELOG.md    CHANGELOG.md
    say "  -> big-project templates: fill in bigPicture.tex (5-min overview, read first)"
    say "     and strategy-map.md (route plan). See the guide's dual-document and"
    say "     session-continuity sections."
    say "  -> CHANGELOG.md is the per-result log; start moving entries into it when the"
    say "     DONE log or the AGENTS.md status section grows past a screenful."
fi

# Fill the placeholders a script CAN fill (Codex fills the rest in session 1).
# Escape the sed metacharacters &, \ and the | delimiter.
esc() { printf '%s' "$1" | sed 's/[&\\|]/\\&/g'; }
for f in workbook.tex brief.tex bigPicture.tex; do
    [ -f "$f" ] || continue
    sed -i.bak "s|\[Project Title\]|$(esc "$TITLE")|g; s|\[Author Name\]|$(esc "$AUTHOR")|g" "$f" \
        && rm -f "$f.bak"
done

say ""
say "Skills (by relevance):"
skill latex-compile
skill sync-brief
# Universal core: AGENTS.md's "Simple-case gate" and "Research-claim discipline" blocks
# reference these by name, so installing them conditionally would leave a dangling $command.
# Both are inert until invoked, and every project makes claims — even one with no code.
skill simple-case-gate
skill claim-audit gate_audit.sh
[ "$CITE" -eq 1 ]     && skill verify-citation
if [ "$VALID" -eq 1 ]; then skill reality-check; skill cross-validate; fi
case $NUMERICS in mathematica|both)
    skill nb-to-wolfbook nb2wb.py nb2wb_extract.wls wl_normalize.py
    skill sync-wb-nb sync-wb-nb.wls
    skill wolfram-headless scripts/greek2esc.py hooks/wolfram-license-notice.sh
    skill wolfbook                                  # MCP playbook (harmless if you don't use the Wolfbook MCP)
    mkdir -p .vscode
    core starter/.vscode/settings.json .vscode/settings.json ;;  # notebook word wrap
esac
[ "$OVERLEAF" -eq 1 ] && skill overleaf-sync

if [ "$NUMERICS" != "none" ]; then
    mkdir -p numerics/generated figures/generated
    say "  ok   numerics/generated/ and figures/generated/ (AI-output staging — see AGENTS.md)"

    # Pipeline workflow: install for any project with code. The skills + agent are
    # inert until you invoke them, and the guard hook ships OFF (and self-quiets
    # until a Pipeline/ doc exists) — so there is nothing to predict at setup. You
    # ADOPT the workflow later, when a code grows too big to hold in context (run
    # $write-pipeline on it).
    say ""
    say "Pipeline workflow (dormant until you have a big code to document):"
    skill write-pipeline dump_code.py
    skill check-pipeline
    skill apply-pipeline
    core starter/.codex/agents/pipeline-auditor.toml .codex/agents/pipeline-auditor.toml
    core starter/.codex/hooks/pipeline-guard.sh      .codex/hooks/pipeline-guard.sh
    core starter/.codex/hooks/pipeline-coverage.sh   .codex/hooks/pipeline-coverage.sh
    chmod +x .codex/hooks/pipeline-*.sh 2>/dev/null
    mkdir -p Pipeline
    core starter/Pipeline/README.md Pipeline/README.md
    say "  -> when a code gets too big to read top-to-bottom, run \$write-pipeline on it."
    say "     to get the auto-nudge on edits, enable pipeline-guard in .codex/hooks.json"
    say "     (the exact block is documented at the top of the script; it stays silent"
    say "     until a Pipeline/ doc exists)."
fi

if [ "$DUALREMOTE" -eq 1 ]; then
    mkdir -p scripts
    core starter/scripts/git-push-both.sh scripts/git-push-both.sh
    core starter/.codex/hooks/git-mirror.sh .codex/hooks/git-mirror.sh
    chmod +x scripts/git-push-both.sh .codex/hooks/git-mirror.sh 2>/dev/null
    say "  -> dual remotes: edit scripts/git-push-both.sh (set your remotes + identities),"
    say "     then enable the mirror hook in .codex/hooks.json (the exact block to paste"
    say "     is documented at the top of .codex/hooks/git-mirror.sh)."
fi

# The agent mailbox. Gated on there actually being a second agent: with one agent
# there is nobody to hand over to, and an empty inbox is just one more file to
# explain. (Unlike the Pipeline workflow, this one is not inert when unused — the
# protocol asks every session to read INBOX.md.)
if [ "$TWOAGENTS" -eq 1 ]; then
    mkdir -p handoff/msgs handoff/archive
    [ -e handoff/msgs/.gitkeep ]    || : > handoff/msgs/.gitkeep
    [ -e handoff/archive/.gitkeep ] || : > handoff/archive/.gitkeep
    core starter/handoff/README.md handoff/README.md
    core starter/handoff/INBOX.md  handoff/INBOX.md
    core starter/handoff/hx.sh     handoff/hx.sh
    chmod +x handoff/hx.sh 2>/dev/null
    say "  -> agent mailbox: AGENTS.md already carries the \"Handover to the other agent\""
    say "     section — keep it. AGENTS.md is the single source of truth, so pointing"
    say "     CLAUDE.md at it (a one-line \"@AGENTS.md\" import) briefs both agents at once."
else
    say ""
    say "  note: AGENTS.md carries a \"Handover to the other agent\" section for the"
    say "        two-agent mailbox. Delete it — you said only one agent works here."
fi

if [ ! -d .git ]; then
    say ""
    yesno "This folder is not a git repository — run git init?" y && git init -q && say "  ok   git init"
fi

say ""
say "One-time Codex steps (in your FIRST session in this folder):"
say "  1. Trust the project when Codex asks — the shared .codex/config.toml only"
say "     applies to trusted projects."
say "  2. Type /hooks, review pre-compact.sh and promise-checker.sh, and trust them"
say "     — Codex does not run un-reviewed hooks."
say "  3. Type /skills to confirm the installed skills are visible."
say ""
say "Optional one-time installs (run yourself if wanted):"
case $NUMERICS in mathematica|both)
    say "  code --install-extension wolfbook.wolfbook      # Mathematica notebooks in VS Code"
    say "  # then fix Wolfbook's comment-split bug (safe: idempotent, backs up, --revert):"
    say "  curl -fsSL $REPO_RAW/scripts/patch-wolfbook-splitter.py | python3 -   # reload VS Code after"
    say "  # add Mathematica-style section-folding keybindings (word wrap is already set above):"
    say "  curl -fsSL $REPO_RAW/scripts/apply-notebook-ux.py | python3 -          # reload VS Code after" ;;
esac
say "  # Anthropic's pdf skill uses the same open SKILL.md standard and works in Codex:"
say "  mkdir -p ~/.agents/skills/pdf && curl -o ~/.agents/skills/pdf/SKILL.md \\"
say "    https://raw.githubusercontent.com/anthropics/skills/main/skills/pdf/SKILL.md"

say ""
say "Structure is in place; content is not. Start a Codex session in this"
say "folder and paste (after the last line, describe your project in your own words):"
say "--------------------------------------------------------------------------"
say "I set this project up with the chatgpt-for-researchers bootstrap script, so"
say "all files and skills are already in place. Read AGENTS.md, workbook.tex,"
say "brief.tex, next-session-prompts.md, and BUGS.md. Then replace every bracketed"
say "stub in them with real content from the description below — goal, file map,"
say "conventions, introduction, a real first task in next-session-prompts.md, and"
say "my name plus today's date in the BUGS.md standing rule."
say "Do not leave placeholder text anywhere; ask me rather than inventing"
say "anything you do not know."
say ""
say "Project description:"
say "--------------------------------------------------------------------------"
