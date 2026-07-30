---
name: overleaf-sync
description: Sync the Overleaf/ git clone of a shared Overleaf paper: status, pull, diff, or (guarded, explicit-confirmation) publish. Never force-pushes, never auto-resolves conflicts.
---

# overleaf-sync

Sync a local git clone of a shared Overleaf project: pull collaborators' latest,
check whether Overleaf has moved ahead, or (only on explicit request) publish your
local edits back — without ever erasing collaborators' work.

## Background: the setup this skill assumes

Overleaf exposes each project as a git remote (Overleaf menu → Sync → Git; paid
feature). The shared project is cloned into a subfolder of your repo — **`Overleaf/`**
by convention — which is its OWN git repo, separate from your project's repo.

- Remote `origin` = `https://git.overleaf.com/<project-id>`.
- Auth is an Overleaf git token (`olp_…`), stored in the OS keychain via
  `git credential` so pulls are non-interactive (username `git`, not your email).
- Branch layout inside `Overleaf/`:
  - `master` — pristine mirror of Overleaf. Only ever updated by `git pull`. NEVER edit here.
  - `local-edits` — where you edit offline.
- **Push is physically disabled** as a safety net: `remote.origin.pushurl` is set to
  `no_push`, so `git push` fails until deliberately re-enabled. Clone, `fetch`, and
  `pull` only READ from Overleaf and cannot change the shared project; only `push` writes.
- `Overleaf/` should be in your project's top-level `.gitignore` so the shared paper
  is never pushed to your personal repo. (See the one-time setup note at the end.)

## When to invoke

`$overleaf-sync [status|pull|diff|publish]` — default action is `status`.

Use `status`/`pull`/`diff` freely (read-only w.r.t. Overleaf). Use `publish` ONLY when
the user explicitly says to publish/push, and treat it as the one dangerous operation.

## Preconditions (check first, every time)

1. `Overleaf/` exists and is a git repo: `git -C Overleaf rev-parse --git-dir`. If not,
   stop and point the user to the one-time setup at the end of this file; do not improvise.
2. Run all git commands with `-C Overleaf`. If the project root path has spaces, quote it;
   the `Overleaf` clone dir itself should have no spaces.

## Actions

### `status` (default) — is Overleaf ahead? [read-only]
1. `git -C Overleaf fetch origin` (non-interactive).
2. Report ahead/behind of `master` vs `origin/master`:
   `git -C Overleaf rev-list --left-right --count master...origin/master`.
3. If `origin/master` is ahead, list the new commits
   (`git -C Overleaf log --oneline master..origin/master`) and the changed files
   (`git -C Overleaf diff --stat master origin/master`).
4. Report the current branch and whether the working tree is clean.
Output e.g.: "Overleaf is 2 commits ahead; main.tex changed (+34/-1). You are on
local-edits (clean). Run `$overleaf-sync pull` to update the mirror." Make NO changes.

### `pull` — update the local mirror from Overleaf [read-only w.r.t. Overleaf]
1. `git -C Overleaf fetch origin`.
2. If `master` is behind: fast-forward it — `git -C Overleaf fetch origin master:master`
   if not currently on master, else `git -C Overleaf pull --ff-only`. Never a non-ff pull.
3. Summarise what changed (diff --stat + the new commit subjects).
4. If the user is on `local-edits` and `master` advanced, OFFER (do not auto-run) to
   update their branch: `git -C Overleaf rebase master` (or `merge master`). Let them choose.
Never touches Overleaf.

### `diff` — show differences
- `local-edits` vs `master`: `git -C Overleaf diff master..local-edits -- <file>` (your
  unpublished edits).
- mirror vs Overleaf: run `status` first, then `git -C Overleaf diff master origin/master`.
Pick based on the user's wording; default to "what are my unpublished edits"
(local-edits vs master).

### `publish` — send local edits to Overleaf [WRITES to the shared project — DANGEROUS]
Do NOT run any step past 3 without an explicit, in-this-turn "yes, publish" from the user.
Never use `--force`/`-f`. The merge step is the guard against erasing others' work.
1. Confirm intent. Restate exactly what will be pushed (branch, files, commit summaries).
   Get explicit confirmation before proceeding.
2. Ensure `local-edits` is committed: if the tree is dirty, show `git -C Overleaf status`
   and commit with the user's message (author: the user; NO Co-Authored-By trailer).
3. `git -C Overleaf checkout master && git -C Overleaf pull --ff-only` — grab everyone's
   newest first. (If this isn't a fast-forward, STOP — the mirror diverged; investigate.)
4. `git -C Overleaf merge --no-ff local-edits`. If git reports CONFLICTS: STOP, show the
   conflicted files, and have the user resolve them — never auto-resolve, never overwrite.
5. Show the merged result for review: `git -C Overleaf diff origin/master..master --stat`
   and the relevant hunks. Get a final go-ahead.
6. Re-enable push, push, then immediately re-disable it:
   - `git -C Overleaf remote set-url --push origin "$(git -C Overleaf remote get-url origin)"`
   - `git -C Overleaf push origin master`
   - `git -C Overleaf remote set-url --push origin no_push`  ← restore the safety
7. `git -C Overleaf checkout local-edits`. Confirm the push succeeded and push is disabled again.

## Output format
```
overleaf-sync [action]: <one-line result>
  branch: <current> (clean|dirty)
  mirror vs Overleaf: <N ahead / M behind>
  [changed files / next suggested action]
```

## Non-negotiables
- `status`, `pull`, `diff` never write to Overleaf. `publish` is the only writing path and
  needs explicit per-invocation confirmation.
- Never `git push --force`. Never resolve merge conflicts on the user's behalf.
- Always leave push DISABLED (`pushurl=no_push`) after finishing.
- If the auth token was rotated, a pull fails with an auth error — tell the user to
  re-store the new `olp_…` token in the keychain (do NOT put the token in a URL or commit it):
  ```
  printf "protocol=https\nhost=git.overleaf.com\nusername=git\npassword=<token>\n\n" | git credential approve
  ```

## One-time setup (do this once, by hand, before the skill is usable)

Run from your project root. Replace `<project-id>` and `<token>` with your own.
```bash
# 1. Store the Overleaf git token so pulls are non-interactive (macOS/Linux keychain):
printf "protocol=https\nhost=git.overleaf.com\nusername=git\npassword=<token>\n\n" \
  | git credential approve

# 2. Clone the shared project into Overleaf/ (its own repo, NOT a submodule):
git clone https://git@git.overleaf.com/<project-id> Overleaf

# 3. Create the editing branch and disable accidental pushes:
git -C Overleaf branch local-edits
git -C Overleaf remote set-url --push origin no_push

# 4. Keep the shared paper out of your personal repo:
echo "/Overleaf/" >> .gitignore
```
After this, `$overleaf-sync` works. Edit on `local-edits`; `master` stays a clean mirror.
