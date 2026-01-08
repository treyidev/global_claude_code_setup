#!/bin/bash
# .claude/commands/task_spawn.sh
# Spawn a new hierarchical task with context preservation
#
# Usage:
#   task_spawn.sh --model "sonnet" --prompt "Your task description"
#
# Optional:
#   --parent-task "task-id"     # If nesting under another task
#   --branch-aware              # Create git branch + GitLab issue for MR workflow
#
# This script:
# 1. Generates unique task ID
# 2. Captures current git state (LAST_GOOD_COMMIT)
# 3. Creates patch file with metadata
# 4. Creates git branch (if --branch-aware)
# 5. Creates GitLab issue (if --branch-aware)
# 6. Creates shared_memory entry
# 7. Updates SESSION.md
# 8. Reports task creation to user

set -e

# ============================================================================
# Setup & Utilities
# ============================================================================

GLOBAL_CLAUDE_DIR="$HOME/.claude"
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
PROJECT_CLAUDE_DIR="$GIT_ROOT/.claude"
PATCHES_DIR="$PROJECT_CLAUDE_DIR/patches"

# Source global utility libraries
source "$GLOBAL_CLAUDE_DIR/utils/git_operations.sh"
source "$GLOBAL_CLAUDE_DIR/utils/patch_manager.sh"

# ============================================================================
# Function: Generate unique task ID
# ============================================================================

generate_task_id() {
    local timestamp=$(date +%s)
    local random=$(head -c 3 /dev/urandom | od -An -tx1 | tr -d ' ')
    echo "task-${timestamp}-${random}"
}

# ============================================================================
# Function: Get GitLab project
# ============================================================================

get_gitlab_project() {
    # Try to get from glab config
    glab config get host 2>/dev/null | head -1 || echo ""
}

# ============================================================================
# Function: Parse arguments
# ============================================================================

parse_args() {
    MODEL=""
    PROMPT=""
    PARENT_TASK=""
    BRANCH_AWARE=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --model)
                MODEL="$2"
                shift 2
                ;;
            --prompt)
                PROMPT="$2"
                shift 2
                ;;
            --parent-task)
                PARENT_TASK="$2"
                shift 2
                ;;
            --branch-aware)
                BRANCH_AWARE=true
                shift
                ;;
            *)
                echo "[X] Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [ -z "$MODEL" ] || [ -z "$PROMPT" ]; then
        echo "[X] Error: --model and --prompt are required"
        echo ""
        echo "Usage: task_spawn.sh --model <model> --prompt <prompt> [--parent-task <id>] [--branch-aware]"
        echo ""
        echo "Examples:"
        echo "  task_spawn.sh --model sonnet --prompt 'Refactor auth service'"
        echo "  task_spawn.sh --model haiku --prompt 'Analyze code' --parent-task task-123 --branch-aware"
        exit 1
    fi
}

# ============================================================================
# Function: Create patch file
# ============================================================================

create_patch() {
    local task_id="$1"
    local last_good_commit="$2"
    local depth="${3:-0}"

    patch_create_file \
        "$task_id" \
        "$PROMPT" \
        "$MODEL" \
        "$depth" \
        "$PARENT_TASK"

    # Add LAST_GOOD_COMMIT to patch file
    patch_update_field "$task_id" "LAST_GOOD_COMMIT" "$last_good_commit"
}

# ============================================================================
# Function: Create git branch (for MR workflow)
# ============================================================================

create_branch() {
    local task_id="$1"

    if [ "$BRANCH_AWARE" != true ]; then
        return 0
    fi

    # Branch name: feature/task-${ID}
    local branch_name="feature/task-${task_id}"

    git_create_branch "$branch_name" 2>/dev/null || {
        echo "[!] Failed to create branch: $branch_name"
        return 1
    }

    echo "$branch_name"
}

# ============================================================================
# Function: Create GitLab issue (for MR workflow)
# ============================================================================

create_gitlab_issue() {
    local task_id="$1"
    local gitlab_project="$2"

    if [ "$BRANCH_AWARE" != true ]; then
        return 0
    fi

    if [ -z "$gitlab_project" ]; then
        echo "[!] Warning: Could not determine GitLab project. Skipping issue creation."
        return 1
    fi

    # Extract first line of prompt as issue title
    local issue_title=$(echo "$PROMPT" | head -1 | cut -c1-70)
    local issue_body="Task ID: $task_id

**Prompt:**
$PROMPT

---
*Auto-created by /task:spawn*"

    local issue_result=$(glab issue create \
        --title "$issue_title" \
        --description "$issue_body" 2>&1) || {
        echo "[!] Failed to create GitLab issue"
        return 1
    }

    # Extract issue number from result (format: #123 or similar)
    local issue_id=$(echo "$issue_result" | grep -oP '#\K\d+' | head -1)
    echo "$issue_id"
}

# ============================================================================
# Function: Create shared_memory entry
# ============================================================================

create_shared_memory_entry() {
    local task_id="$1"

    # Use shared_memory_updater to create entry
    $GLOBAL_CLAUDE_DIR/commands/shared-memory/cmd.sh add \
        --from "spawned-task" \
        --hint "Task: $task_id" \
        --content "Task ID: $task_id
Model: $MODEL
Prompt:
$PROMPT" 2>&1 | tail -1

    # Returns the task_id as the entry identifier
    echo "$task_id"
}

# ============================================================================
# Function: Update SESSION.md
# ============================================================================

update_session_md() {
    local task_id="$1"

    local session_file="$PROJECT_CLAUDE_DIR/SESSION.md"

    # If SESSION.md doesn't exist, create it
    if [ ! -f "$session_file" ]; then
        cat > "$session_file" << EOF
# Session

## Current Task
current_task_id: $task_id
shared_memory_id: $task_id
status: spawned

## Last Updated
$(date -u +'%Y-%m-%dT%H:%M:%SZ')
EOF
    else
        # Update existing SESSION.md using sed
        # (Simple approach - assumes YAML structure exists)
        sed -i.bak "s/^current_task_id:.*/current_task_id: $task_id/" "$session_file" 2>/dev/null || true
        sed -i.bak "s/^shared_memory_id:.*/shared_memory_id: $task_id/" "$session_file" 2>/dev/null || true
        rm -f "$session_file.bak"
    fi
}

# ============================================================================
# Function: Display spawn summary
# ============================================================================

display_summary() {
    local task_id="$1"
    local last_good_commit="$2"
    local git_branch="$3"
    local gitlab_issue_id="$4"

    echo ""
    echo "==============================================================================="
    echo "TASK SPAWNED"
    echo "==============================================================================="
    echo ""
    echo "Task ID:           $task_id"
    echo "Model:             $MODEL"
    echo "Last Good Commit:  $last_good_commit"

    if [ -n "$PARENT_TASK" ]; then
        echo "Parent Task:       $PARENT_TASK"
    fi

    if [ -n "$git_branch" ]; then
        echo "Branch:            $git_branch"
    fi

    if [ -n "$gitlab_issue_id" ]; then
        echo "GitLab Issue:      #$gitlab_issue_id"
    fi

    echo ""
    echo "Prompt:"
    echo "---"
    echo "$PROMPT"
    echo "---"
    echo ""
    echo "Patch File: .claude/patches/$task_id.patch"
    echo ""
    echo "On crash, run: /project:resume"
    echo "==============================================================================="
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    parse_args "$@"

    # Generate task ID
    local task_id=$(generate_task_id)
    echo "[+] Generated task ID: $task_id"

    # Get current git state
    local last_good_commit=$(git_get_head_commit_full)
    echo "[+] Captured last good commit: $last_good_commit"

    # Create patch file
    echo "[+] Creating patch file..."
    local depth=0
    if [ -n "$PARENT_TASK" ]; then
        depth=1
    fi
    create_patch "$task_id" "$last_good_commit" "$depth"

    # Create git branch (if applicable)
    local git_branch=""
    if [ "$BRANCH_AWARE" = true ]; then
        echo "[+] Creating git branch..."
        git_branch=$(create_branch "$task_id")
        if [ -n "$git_branch" ]; then
            echo "[+] Branch: $git_branch"
            patch_update_field "$task_id" "GIT_BRANCH" "$git_branch"
        fi
    fi

    # Create GitLab issue (if applicable)
    local gitlab_issue_id=""
    if [ "$BRANCH_AWARE" = true ]; then
        echo "[+] Creating GitLab issue..."
        local gitlab_project=$(get_gitlab_project)
        gitlab_issue_id=$(create_gitlab_issue "$task_id" "$gitlab_project") || true
        if [ -n "$gitlab_issue_id" ]; then
            echo "[+] GitLab issue: #$gitlab_issue_id"
            patch_update_field "$task_id" "GITLAB_ISSUE_ID" "$gitlab_issue_id"
        fi
    fi

    # Create shared_memory entry
    echo "[+] Creating shared_memory entry..."
    create_shared_memory_entry "$task_id"

    # Update SESSION.md
    echo "[+] Updating SESSION.md..."
    update_session_md "$task_id"

    # Display summary
    display_summary "$task_id" "$last_good_commit" "$git_branch" "$gitlab_issue_id"

    echo "[✓] Task spawned successfully!"
}

main "$@"
