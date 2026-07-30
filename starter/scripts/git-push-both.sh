#!/usr/bin/env bash
# git-push-both.sh
#
# Push to both a primary GitHub remote and a secondary GitLab remote,
# using different git identities for each.
#
# Usage: ./scripts/git-push-both.sh [branch]
#        Default branch: main
#
# Prerequisites:
#   - Two remotes configured: `github` and `gitlab`
#   - For gitlab: SSH key configured for your institution account
#   - Your institution email set in the environment or hardcoded below
#
# Setup (run once):
#   git remote add github  https://github.com/YOUR_GITHUB_USER/your-repo.git
#   git remote add gitlab  git@git.YOUR_INSTITUTION.ac.uk:YOUR_ID/your-repo.git

set -euo pipefail

BRANCH="${1:-main}"
GITHUB_REMOTE="github"
GITLAB_REMOTE="gitlab"

# --- Configure these for your setup ---
GITHUB_EMAIL="YOUR_NOREPLY@users.noreply.github.com"  # GitHub no-reply email
GITLAB_EMAIL="YOUR_ID@YOUR_INSTITUTION.ac.uk"          # Institution email
GITLAB_NAME="Your Full Name"
# --------------------------------------

echo "=== Pushing to $GITHUB_REMOTE/$BRANCH ==="
git push "$GITHUB_REMOTE" "$BRANCH"
echo "Done."

echo ""
echo "=== Pushing to $GITLAB_REMOTE/$BRANCH (as $GITLAB_NAME <$GITLAB_EMAIL>) ==="

# GitLab protected branches are often append-only: we use a sync branch.
# If your GitLab allows direct pushes to main, replace the block below with:
#   git -c user.email="$GITLAB_EMAIL" -c user.name="$GITLAB_NAME" \
#       push "$GITLAB_REMOTE" "$BRANCH"

SYNC_BRANCH="gitlab-sync"

# Create or reset the sync branch to the current gitlab/main
if git show-ref --quiet "refs/remotes/$GITLAB_REMOTE/$BRANCH"; then
    git checkout -B "$SYNC_BRANCH" "$GITLAB_REMOTE/$BRANCH" 2>/dev/null || \
    git checkout -B "$SYNC_BRANCH"
else
    git checkout -B "$SYNC_BRANCH"
fi

# Cherry-pick or merge commits that are on main but not on gitlab/main
git cherry-pick "$(git merge-base HEAD "$GITHUB_REMOTE/$BRANCH")".."$GITHUB_REMOTE/$BRANCH" \
    --no-commit 2>/dev/null || true
git add -A
git -c user.email="$GITLAB_EMAIL" -c user.name="$GITLAB_NAME" \
    commit --allow-empty -m "Sync from github/$BRANCH" || true
git push "$GITLAB_REMOTE" "$SYNC_BRANCH:$BRANCH"

# Return to main
git checkout "$BRANCH"
echo "Done."
