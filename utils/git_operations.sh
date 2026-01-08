#!/bin/bash
# .claude/utils/git_operations.sh
# Utility library for git operations
#
# Usage (in other scripts):
#   source .claude/utils/git_operations.sh
#   git_get_head_commit
#   git_reset_hard "abc123"
#   etc.
#
# This is a library, not a command. Source it from other scripts.

# ============================================================================
# Git Repository Utilities
# ============================================================================

git_get_root() {
    # Get git repository root directory
    git rev-parse --show-toplevel 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "[X] Error: Not in a git repository" >&2
        return 1
    fi
}

git_current_branch() {
    # Get current branch name
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

git_get_head_commit() {
    # Get current HEAD commit hash (short)
    git rev-parse --short HEAD 2>/dev/null
}

git_get_head_commit_full() {
    # Get current HEAD commit hash (full)
    git rev-parse HEAD 2>/dev/null
}

# ============================================================================
# Branch Operations
# ============================================================================

git_branch_exists() {
    # Check if branch exists locally
    local branch="$1"
    git rev-parse --verify "$branch" >/dev/null 2>&1
    return $?
}

git_create_branch() {
    # Create new branch from current HEAD
    local branch="$1"
    if git_branch_exists "$branch"; then
        echo "[X] Branch already exists: $branch" >&2
        return 1
    fi
    git checkout -b "$branch" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Created branch: $branch"
        return 0
    else
        echo "[X] Failed to create branch: $branch" >&2
        return 1
    fi
}

git_delete_branch() {
    # Delete a branch (force)
    local branch="$1"
    if ! git_branch_exists "$branch"; then
        echo "[X] Branch does not exist: $branch" >&2
        return 1
    fi
    git branch -D "$branch" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Deleted branch: $branch"
        return 0
    else
        echo "[X] Failed to delete branch: $branch" >&2
        return 1
    fi
}

git_switch_branch() {
    # Switch to a branch
    local branch="$1"
    if ! git_branch_exists "$branch"; then
        echo "[X] Branch does not exist: $branch" >&2
        return 1
    fi
    git checkout "$branch" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Switched to branch: $branch"
        return 0
    else
        echo "[X] Failed to switch to branch: $branch" >&2
        return 1
    fi
}

# ============================================================================
# Commit Operations
# ============================================================================

git_reset_hard() {
    # Reset to a commit (hard reset, discards changes)
    local commit="$1"
    if [ -z "$commit" ]; then
        echo "[X] Error: commit hash required" >&2
        return 1
    fi

    git reset --hard "$commit" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Reset to commit: $commit"
        return 0
    else
        echo "[X] Failed to reset to commit: $commit" >&2
        return 1
    fi
}

git_has_uncommitted_changes() {
    # Check if there are uncommitted changes
    git status --porcelain 2>/dev/null | grep -q .
    return $?
}

git_commit() {
    # Create a commit
    local message="$1"
    if [ -z "$message" ]; then
        echo "[X] Error: commit message required" >&2
        return 1
    fi

    git commit -m "$message" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Committed: $message"
        return 0
    else
        echo "[X] Failed to commit" >&2
        return 1
    fi
}

# ============================================================================
# Rebasing Operations
# ============================================================================

git_rebase_on() {
    # Rebase current branch on another branch
    local target_branch="$1"
    if [ -z "$target_branch" ]; then
        echo "[X] Error: target branch required" >&2
        return 1
    fi

    if ! git_branch_exists "$target_branch"; then
        echo "[X] Target branch does not exist: $target_branch" >&2
        return 1
    fi

    git rebase "$target_branch" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Rebased onto: $target_branch"
        return 0
    else
        echo "[X] Rebase failed. Conflicts may need resolution." >&2
        echo "Run: git rebase --abort (to cancel) or resolve conflicts manually"
        return 1
    fi
}

git_rebase_abort() {
    # Abort an in-progress rebase
    git rebase --abort 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Rebase aborted"
        return 0
    else
        echo "[X] No rebase in progress" >&2
        return 1
    fi
}

# ============================================================================
# Stash Operations
# ============================================================================

git_stash_save() {
    # Stash current changes with optional message
    local message="${1:-checkpoint}"
    git stash save "$message" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Stashed: $message"
        return 0
    else
        echo "[X] Failed to stash changes" >&2
        return 1
    fi
}

git_stash_pop() {
    # Apply and remove latest stash
    git stash pop 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Stash applied"
        return 0
    else
        echo "[X] Failed to apply stash" >&2
        return 1
    fi
}

git_stash_list() {
    # List all stashes
    git stash list 2>/dev/null
}

# ============================================================================
# Branch Analysis
# ============================================================================

git_commits_ahead_of() {
    # Count commits current branch is ahead of target branch
    local target_branch="${1:-main}"

    if ! git_branch_exists "$target_branch"; then
        echo "[X] Target branch does not exist: $target_branch" >&2
        return 1
    fi

    local count=$(git rev-list --count "$target_branch..HEAD" 2>/dev/null)
    echo "$count"
    return 0
}

git_branch_has_diverged() {
    # Check if branch has diverged from target (not a fast-forward)
    local target_branch="${1:-main}"

    local ahead=$(git rev-list --count "$target_branch..HEAD" 2>/dev/null)
    local behind=$(git rev-list --count "HEAD..$target_branch" 2>/dev/null)

    if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
        return 0  # Diverged
    fi
    return 1  # Not diverged
}

git_last_commit_message() {
    # Get last commit message
    git log -1 --pretty=%B 2>/dev/null
}

# ============================================================================
# Fetch/Pull Operations
# ============================================================================

git_fetch_origin() {
    # Fetch from origin
    git fetch origin 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Fetched from origin"
        return 0
    else
        echo "[X] Failed to fetch from origin" >&2
        return 1
    fi
}

git_pull_origin() {
    # Pull from origin current branch
    local branch=$(git_current_branch)
    git pull origin "$branch" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "[+] Pulled from origin/$branch"
        return 0
    else
        echo "[X] Failed to pull from origin" >&2
        return 1
    fi
}

# ============================================================================
# Diff/Status Operations
# ============================================================================

git_diff_summary() {
    # Get summary of changes (files changed, lines added/removed)
    git diff --stat 2>/dev/null
}

git_status_short() {
    # Get short status (porcelain format)
    git status --porcelain 2>/dev/null
}

git_files_changed_since() {
    # List files changed since a commit
    local commit="$1"
    if [ -z "$commit" ]; then
        echo "[X] Error: commit hash required" >&2
        return 1
    fi

    git diff --name-only "$commit..HEAD" 2>/dev/null
}

# ============================================================================
# Validation Functions
# ============================================================================

git_is_clean() {
    # Check if working directory is clean (no uncommitted changes)
    ! git_has_uncommitted_changes
}

git_validate_commit_hash() {
    # Validate that a commit hash exists
    local commit="$1"
    if [ -z "$commit" ]; then
        return 1
    fi

    git rev-list --all | grep -q "^$commit"
    return $?
}

# ============================================================================
# End of Library
# ============================================================================
