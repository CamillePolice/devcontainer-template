#!/bin/bash
# setup-worktree.sh - Create git worktrees for feature development
# Usage: sh .claude/scripts/setup-worktree.sh <branch-name>

set -e

# Logging function
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# Validate arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <branch-name>"
    echo "  branch-name: Name without '/' (e.g., opv_123-feature_name)"
    exit 1
fi

BRANCH_NAME="$1"

# Validate no slashes in branch name
if echo "$BRANCH_NAME" | grep -q '/'; then
    echo "Error: Branch name cannot contain '/' as it's used as folder name"
    exit 1
fi

# Get repository info
REPO_ROOT=$(git rev-parse --show-toplevel)
REPO_NAME=$(basename "$REPO_ROOT")
PARENT_DIR=$(dirname "$REPO_ROOT")
WORKTREE_PATH="${PARENT_DIR}/${REPO_NAME}-${BRANCH_NAME}"

# Detect default branch (main or master)
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

log "Creating worktree for branch: $BRANCH_NAME"
log "Worktree path: $WORKTREE_PATH"

# Check if worktree already exists
if [ -d "$WORKTREE_PATH" ]; then
    echo "Error: Worktree directory already exists: $WORKTREE_PATH"
    exit 1
fi

# Fetch latest from remote
log "Fetching latest from remote..."
git fetch origin

# Check if branch exists, create if not
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" || \
   git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
    log "Branch '$BRANCH_NAME' exists, creating worktree..."
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
else
    log "Branch '$BRANCH_NAME' doesn't exist, creating from $DEFAULT_BRANCH..."
    git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "origin/$DEFAULT_BRANCH"
fi

log "Worktree created successfully!"
echo ""
echo "Next steps:"
echo "  cd $WORKTREE_PATH"
echo ""
git worktree list
