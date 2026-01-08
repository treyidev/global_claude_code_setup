#!/bin/bash
# .claude/utils/task_status.sh
# Intelligent detection and analysis layer
#
# Detects spawned task crash state, analyzes situation, generates
# structured STATE REPORT for LLM orchestration.
#
# Usage:
#   source .claude/utils/task_status.sh
#   task_detect_crash_state > state_report.json
#
# Output: Structured JSON with scenario analysis and recommendations

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
# Helper: JSON output functions
# ============================================================================

json_quote() {
    local str="$1"
    echo "$str" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g'
}

json_object_start() {
    echo -n "{"
}

json_object_end() {
    echo "}"
}

json_field() {
    local key="$1"
    local value="$2"
    echo -n "\"$key\":\"$(json_quote "$value")\","
}

json_field_bool() {
    local key="$1"
    local value="$2"
    if [ "$value" = "true" ] || [ "$value" = "1" ]; then
        echo -n "\"$key\":true,"
    else
        echo -n "\"$key\":false,"
    fi
}

json_field_number() {
    local key="$1"
    local value="$2"
    echo -n "\"$key\":$value,"
}

# ============================================================================
# Function: Detect spawned task from SESSION.md
# ============================================================================

detect_spawned_task() {
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    local session_file="$git_root/.claude/SESSION.md"

    if [ ! -f "$session_file" ]; then
        echo ""
        return 1
    fi

    # Extract current_task_id from SESSION.md
    grep "^current_task_id:" "$session_file" 2>/dev/null | cut -d':' -f2- | xargs || echo ""
}

# ============================================================================
# Function: Validate spawned task integrity
# ============================================================================

validate_task() {
    local task_id="$1"

    # Check patch file exists
    if ! patch_exists "$task_id"; then
        return 1
    fi

    # Validate patch format
    if ! patch_validate_format "$task_id" >/dev/null 2>&1; then
        return 1
    fi

    return 0
}

# ============================================================================
# Function: Analyze git state
# ============================================================================

analyze_git_state() {
    local task_id="$1"

    local current_branch=$(git_current_branch)
    local is_clean=$(git_is_clean && echo "true" || echo "false")
    local commits_ahead=$(git_commits_ahead_of main 2>/dev/null || echo "0")

    # Get diff summary
    local files_changed=$(git status --porcelain 2>/dev/null | wc -l)

    echo "{"
    echo "\"current_branch\":\"$current_branch\","
    echo "\"is_clean\":$is_clean,"
    echo "\"commits_ahead_of_main\":$commits_ahead,"
    echo "\"files_changed\":$files_changed"
    echo "}"
}

# ============================================================================
# Function: Check branch state
# ============================================================================

check_branch_state() {
    local task_id="$1"
    local git_branch=$(patch_read_field "$task_id" "GIT_BRANCH" 2>/dev/null)

    if [ -z "$git_branch" ]; then
        # No branch for this task
        echo "{"
        echo "\"exists\":false,"
        echo "\"name\":null,"
        echo "\"commits_ahead\":0"
        echo "}"
        return 0
    fi

    # Check if branch exists
    if ! git_branch_exists "$git_branch"; then
        echo "{"
        echo "\"exists\":false,"
        echo "\"name\":\"$git_branch\","
        echo "\"commits_ahead\":0"
        echo "}"
        return 0
    fi

    # Branch exists - check commits
    local commits_ahead=$(git rev-list --count "main..$git_branch" 2>/dev/null || echo "0")

    echo "{"
    echo "\"exists\":true,"
    echo "\"name\":\"$git_branch\","
    echo "\"commits_ahead\":$commits_ahead"
    echo "}"
}

# ============================================================================
# Function: Check MR state (GitLab)
# ============================================================================

check_mr_state() {
    local task_id="$1"
    local mr_id=$(patch_read_field "$task_id" "GITLAB_ISSUE_ID" 2>/dev/null)

    if [ -z "$mr_id" ]; then
        echo "{"
        echo "\"exists\":false,"
        echo "\"id\":null,"
        echo "\"status\":null"
        echo "}"
        return 0
    fi

    # Check if MR exists (simplified - just check if ID is set)
    # In real implementation, would call glab to get status
    local mr_status="unknown"

    echo "{"
    echo "\"exists\":true,"
    echo "\"id\":$mr_id,"
    echo "\"status\":\"$mr_status\""
    echo "}"
}

# ============================================================================
# Function: Analyze scenario (critical decision point)
# ============================================================================

analyze_scenario() {
    local task_id="$1"
    local last_good_commit=$(patch_read_field "$task_id" "LAST_GOOD_COMMIT" 2>/dev/null)
    local git_branch=$(patch_read_field "$task_id" "GIT_BRANCH" 2>/dev/null)
    local mr_id=$(patch_read_field "$task_id" "GITLAB_ISSUE_ID" 2>/dev/null)
    local current_branch=$(git_current_branch)

    # Scenario A: Branch-aware task, no branch created
    if [ -n "$git_branch" ] && ! git_branch_exists "$git_branch"; then
        echo "\"scenario\":\"pre_work_crash\","
        echo "\"description\":\"Task spawned but no work started (branch not created)\","
        echo "\"recovery_options\":[\"retry\",\"modify_prompt\",\"cancel\"]"
        return 0
    fi

    # Scenario B: Branch exists, but no commits
    if [ -n "$git_branch" ] && git_branch_exists "$git_branch"; then
        local commits=$(git rev-list --count "main..$git_branch" 2>/dev/null || echo "0")
        if [ "$commits" -eq "0" ]; then
            echo "\"scenario\":\"pre_work_crash\","
            echo "\"description\":\"Task spawned but no work started (branch empty)\","
            echo "\"recovery_options\":[\"retry\",\"modify_prompt\",\"cancel\"]"
            return 0
        fi
    fi

    # Scenario C: Work done but no MR (or MR not merged)
    if [ -n "$git_branch" ] && git_branch_exists "$git_branch"; then
        local commits=$(git rev-list --count "main..$git_branch" 2>/dev/null || echo "0")
        if [ "$commits" -gt "0" ] && [ -z "$mr_id" ]; then
            echo "\"scenario\":\"post_work_no_mr\","
            echo "\"description\":\"Work done but MR not created\","
            echo "\"recovery_options\":[\"create_mr\",\"review_work\",\"modify_approach\"]"
            return 0
        fi
    fi

    # Scenario D: MR exists but not merged
    if [ -n "$mr_id" ]; then
        echo "\"scenario\":\"mr_pending\","
        echo "\"description\":\"MR created but not yet merged\","
        echo "\"recovery_options\":[\"check_mr_status\",\"await_merge\",\"modify_mr\"]"
        return 0
    fi

    # Default: Unknown state
    echo "\"scenario\":\"unknown\","
    echo "\"description\":\"Unable to determine crash scenario\","
    echo "\"recovery_options\":[\"investigate\",\"manual_recovery\"]"
}

# ============================================================================
# Function: Generate complete state report
# ============================================================================

task_detect_crash_state() {
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    local session_file="$git_root/.claude/SESSION.md"

    # Verify we're in a git repo
    if [ -z "$git_root" ]; then
        echo "{\"error\":\"not_in_git_repo\"}"
        return 1
    fi

    # Check if SESSION.md exists
    if [ ! -f "$session_file" ]; then
        echo "{\"error\":\"no_session_md\",\"message\":\"No active session detected\"}"
        return 1
    fi

    # Detect task ID
    local task_id=$(detect_spawned_task)
    if [ -z "$task_id" ]; then
        echo "{\"error\":\"no_spawned_task\",\"message\":\"No spawned task in SESSION.md\"}"
        return 1
    fi

    # Validate task integrity
    if ! validate_task "$task_id"; then
        echo "{\"error\":\"invalid_task\",\"task_id\":\"$task_id\",\"message\":\"Task validation failed\"}"
        return 1
    fi

    # Read task context
    local prompt=$(patch_read_prompt "$task_id" 2>/dev/null)
    local last_good_commit=$(patch_read_field "$task_id" "LAST_GOOD_COMMIT" 2>/dev/null)
    local model=$(patch_read_field "$task_id" "MODEL" 2>/dev/null)
    local git_branch=$(patch_read_field "$task_id" "GIT_BRANCH" 2>/dev/null)

    # Analyze states
    local git_state=$(analyze_git_state "$task_id")
    local branch_state=$(check_branch_state "$task_id")
    local mr_state=$(check_mr_state "$task_id")

    # Generate report
    echo "{"
    echo "\"status\":\"crash_detected\","
    echo "\"task_id\":\"$task_id\","
    echo "\"task_context\":{"
    echo "\"model\":\"$model\","
    echo "\"prompt\":\"$(json_quote "$prompt")\","
    echo "\"last_good_commit\":\"$last_good_commit\","
    echo "\"git_branch\":\"$git_branch\""
    echo "},"
    echo "\"git_state\":$git_state,"
    echo "\"branch_state\":$branch_state,"
    echo "\"mr_state\":$mr_state,"
    echo "\"scenario_analysis\":{"
    analyze_scenario "$task_id"
    echo "},"
    echo "\"recovery_required\":true"
    echo "}"
}

# ============================================================================
# Export for use
# ============================================================================

export -f task_detect_crash_state
export -f detect_spawned_task
export -f validate_task
export -f analyze_git_state
export -f check_branch_state
export -f check_mr_state
export -f analyze_scenario
