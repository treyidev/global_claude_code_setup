#!/bin/bash
# .claude/utils/patch_manager.sh
# Utility library for patch file management
#
# Usage (in other scripts):
#   source .claude/utils/patch_manager.sh
#   patch_create_file "task-id" "prompt" "model"
#   patch_read_field "task-id" "LAST_GOOD_COMMIT"
#   etc.
#
# Patch files stored in: .claude/patches/${TASK_ID}.patch

# ============================================================================
# Patch File Initialization & Management
# ============================================================================

PATCHES_DIR=".claude/patches"

patch_ensure_dir() {
    # Ensure patches directory exists
    if [ ! -d "$PATCHES_DIR" ]; then
        mkdir -p "$PATCHES_DIR"
        echo "[+] Created patches directory: $PATCHES_DIR"
    fi
}

patch_get_path() {
    # Get full path to patch file
    local task_id="$1"
    echo "$PATCHES_DIR/$task_id.patch"
}

patch_exists() {
    # Check if patch file exists
    local task_id="$1"
    local patch_file=$(patch_get_path "$task_id")
    [ -f "$patch_file" ]
}

# ============================================================================
# Patch File Creation
# ============================================================================

patch_create_file() {
    # Create a patch file with metadata
    local task_id="$1"
    local prompt="$2"
    local model="$3"
    local depth="${4:-0}"
    local parent_task_id="${5:-}"
    local git_branch="${6:-}"
    local gitlab_issue_id="${7:-}"

    if [ -z "$task_id" ] || [ -z "$prompt" ] || [ -z "$model" ]; then
        echo "[X] Error: task_id, prompt, and model required" >&2
        return 1
    fi

    patch_ensure_dir

    local patch_file=$(patch_get_path "$task_id")

    if [ -f "$patch_file" ]; then
        echo "[X] Patch file already exists: $patch_file" >&2
        return 1
    fi

    local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

    cat > "$patch_file" << EOF
TASK_ID=$task_id
CREATED_AT=$timestamp
MODEL=$model
DEPTH=$depth
PARENT_TASK_ID=$parent_task_id
GIT_BRANCH=$git_branch
GITLAB_ISSUE_ID=$gitlab_issue_id
STATE=active

---PROMPT---
$prompt
---END-PROMPT---
EOF

    if [ $? -eq 0 ]; then
        echo "[+] Created patch file: $patch_file"
        return 0
    else
        echo "[X] Failed to create patch file: $patch_file" >&2
        return 1
    fi
}

# ============================================================================
# Patch File Reading
# ============================================================================

patch_read_field() {
    # Read a field from patch file
    local task_id="$1"
    local field="$2"

    if [ -z "$task_id" ] || [ -z "$field" ]; then
        echo "[X] Error: task_id and field required" >&2
        return 1
    fi

    local patch_file=$(patch_get_path "$task_id")

    if [ ! -f "$patch_file" ]; then
        echo "[X] Patch file not found: $patch_file" >&2
        return 1
    fi

    # Extract field value (format: FIELD=value)
    grep "^$field=" "$patch_file" | cut -d'=' -f2-
}

patch_read_prompt() {
    # Read the prompt from patch file
    local task_id="$1"

    if [ -z "$task_id" ]; then
        echo "[X] Error: task_id required" >&2
        return 1
    fi

    local patch_file=$(patch_get_path "$task_id")

    if [ ! -f "$patch_file" ]; then
        echo "[X] Patch file not found: $patch_file" >&2
        return 1
    fi

    # Extract content between ---PROMPT--- and ---END-PROMPT---
    sed -n '/^---PROMPT---$/,/^---END-PROMPT---$/p' "$patch_file" | \
        sed '1d;$d'
}

patch_read_all_fields() {
    # Read all metadata fields from patch file (without prompt)
    local task_id="$1"

    if [ -z "$task_id" ]; then
        echo "[X] Error: task_id required" >&2
        return 1
    fi

    local patch_file=$(patch_get_path "$task_id")

    if [ ! -f "$patch_file" ]; then
        echo "[X] Patch file not found: $patch_file" >&2
        return 1
    fi

    # Extract everything before ---PROMPT---
    sed -n '1,/^---PROMPT---$/p' "$patch_file" | sed '$d'
}

# ============================================================================
# Patch File Updates
# ============================================================================

patch_update_field() {
    # Update a field in patch file
    local task_id="$1"
    local field="$2"
    local value="$3"

    if [ -z "$task_id" ] || [ -z "$field" ] || [ -z "$value" ]; then
        echo "[X] Error: task_id, field, and value required" >&2
        return 1
    fi

    local patch_file=$(patch_get_path "$task_id")

    if [ ! -f "$patch_file" ]; then
        echo "[X] Patch file not found: $patch_file" >&2
        return 1
    fi

    # Use sed to update field (if exists) or add it (if not)
    if grep -q "^$field=" "$patch_file"; then
        # Field exists, update it
        sed -i.bak "s/^$field=.*/$field=$value/" "$patch_file"
        rm -f "$patch_file.bak"
    else
        # Field doesn't exist, add it before ---PROMPT---
        sed -i.bak "/^---PROMPT---$/i\\
$field=$value
" "$patch_file"
        rm -f "$patch_file.bak"
    fi

    if [ $? -eq 0 ]; then
        return 0
    else
        echo "[X] Failed to update patch file: $patch_file" >&2
        return 1
    fi
}

patch_set_state() {
    # Set patch file state (active|completed|failed)
    local task_id="$1"
    local state="$2"

    if [ -z "$task_id" ] || [ -z "$state" ]; then
        echo "[X] Error: task_id and state required" >&2
        return 1
    fi

    patch_update_field "$task_id" "STATE" "$state"
}

patch_add_note() {
    # Append a note to patch file
    local task_id="$1"
    local note="$2"

    if [ -z "$task_id" ] || [ -z "$note" ]; then
        echo "[X] Error: task_id and note required" >&2
        return 1
    fi

    local patch_file=$(patch_get_path "$task_id")

    if [ ! -f "$patch_file" ]; then
        echo "[X] Patch file not found: $patch_file" >&2
        return 1
    fi

    local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

    # Append note at end of file
    cat >> "$patch_file" << EOF

NOTES:
[$timestamp] $note
EOF

    if [ $? -eq 0 ]; then
        return 0
    else
        echo "[X] Failed to add note to patch file" >&2
        return 1
    fi
}

# ============================================================================
# Patch File Cleanup
# ============================================================================

patch_delete_file() {
    # Delete a patch file
    local task_id="$1"

    if [ -z "$task_id" ]; then
        echo "[X] Error: task_id required" >&2
        return 1
    fi

    local patch_file=$(patch_get_path "$task_id")

    if [ ! -f "$patch_file" ]; then
        echo "[X] Patch file not found: $patch_file" >&2
        return 1
    fi

    rm "$patch_file"

    if [ $? -eq 0 ]; then
        echo "[+] Deleted patch file: $patch_file"
        return 0
    else
        echo "[X] Failed to delete patch file: $patch_file" >&2
        return 1
    fi
}

# ============================================================================
# Patch File Validation
# ============================================================================

patch_validate_format() {
    # Validate patch file format
    local task_id="$1"

    if [ -z "$task_id" ]; then
        echo "[X] Error: task_id required" >&2
        return 1
    fi

    local patch_file=$(patch_get_path "$task_id")

    if [ ! -f "$patch_file" ]; then
        echo "[X] Patch file not found: $patch_file" >&2
        return 1
    fi

    # Check required fields
    local required_fields=("TASK_ID" "MODEL" "STATE")
    local missing=0

    for field in "${required_fields[@]}"; do
        if ! grep -q "^$field=" "$patch_file"; then
            echo "[X] Missing required field: $field" >&2
            missing=$((missing + 1))
        fi
    done

    if [ $missing -gt 0 ]; then
        return 1
    fi

    # Check prompt section
    if ! grep -q "^---PROMPT---$" "$patch_file"; then
        echo "[X] Missing ---PROMPT--- section" >&2
        return 1
    fi

    if ! grep -q "^---END-PROMPT---$" "$patch_file"; then
        echo "[X] Missing ---END-PROMPT--- section" >&2
        return 1
    fi

    return 0
}

# ============================================================================
# Patch File Display
# ============================================================================

patch_show_metadata() {
    # Display patch file metadata
    local task_id="$1"

    if [ -z "$task_id" ]; then
        echo "[X] Error: task_id required" >&2
        return 1
    fi

    local patch_file=$(patch_get_path "$task_id")

    if [ ! -f "$patch_file" ]; then
        echo "[X] Patch file not found: $patch_file" >&2
        return 1
    fi

    echo "==============================================================================="
    echo "PATCH FILE: $patch_file"
    echo "==============================================================================="
    echo ""
    patch_read_all_fields "$task_id"
    echo ""
    echo "==============================================================================="
}

patch_show_full() {
    # Display full patch file content
    local task_id="$1"

    if [ -z "$task_id" ]; then
        echo "[X] Error: task_id required" >&2
        return 1
    fi

    local patch_file=$(patch_get_path "$task_id")

    if [ ! -f "$patch_file" ]; then
        echo "[X] Patch file not found: $patch_file" >&2
        return 1
    fi

    echo "==============================================================================="
    echo "PATCH FILE: $patch_file"
    echo "==============================================================================="
    echo ""
    cat "$patch_file"
    echo ""
    echo "==============================================================================="
}

# ============================================================================
# Patch File Listing
# ============================================================================

patch_list_all() {
    # List all patch files
    patch_ensure_dir

    if [ ! -d "$PATCHES_DIR" ] || [ -z "$(ls -A $PATCHES_DIR 2>/dev/null)" ]; then
        echo "[i] No patch files found"
        return 0
    fi

    echo "==============================================================================="
    echo "PATCH FILES"
    echo "==============================================================================="
    echo ""

    for patch_file in $PATCHES_DIR/*.patch; do
        if [ -f "$patch_file" ]; then
            local task_id=$(basename "$patch_file" .patch)
            local state=$(patch_read_field "$task_id" "STATE")
            local model=$(patch_read_field "$task_id" "MODEL")
            local created=$(patch_read_field "$task_id" "CREATED_AT")

            echo "[$state] $task_id (model: $model, created: $created)"
        fi
    done

    echo ""
    echo "==============================================================================="
}

# ============================================================================
# End of Library
# ============================================================================
