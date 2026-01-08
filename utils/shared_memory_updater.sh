#!/bin/bash
# .claude/commands/shared-memory/cmd.sh
# Cross-session shared memory via YAML (Haiku runs this)
# Requires: yq (Mike Farah version) - https://github.com/mikefarah/yq
#
# IMPORTANT: Always writes to MONOREPO ROOT's .claude/ directory
# This enables cross-session communication regardless of which
# subdirectory Claude Code is opened from.
#
# Operations:
#   add --from <source> --hint <hint> --content <content>
#   list [--all]
#   show <id>
#   update <id> [--hint <hint>] [--content <content>]
#   done <id>
#   discard <id>
#   compact

set -e

# CRITICAL: Anchor to git repository root for cross-session access
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$GIT_ROOT" ]; then
    echo "[X] Error: Not in a git repository"
    exit 1
fi

CLAUDE_DIR="$GIT_ROOT/.claude"
MEMORY_FILE="$CLAUDE_DIR/shared_memory.yaml"
BACKUP_FILE="$CLAUDE_DIR/shared_memory.backup.yaml"

# Ensure yq is available
if ! command -v yq &> /dev/null; then
    echo "[X] Error: yq is required but not installed"
    echo "    Install: brew install yq"
    exit 1
fi

# Initialize memory file if needed
init_memory() {
    if [ ! -d "$CLAUDE_DIR" ]; then
        mkdir -p "$CLAUDE_DIR"
    fi

    if [ ! -f "$MEMORY_FILE" ]; then
        local TIMESTAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
        cat > "$MEMORY_FILE" << EOF
# Shared Memory - Cross-session communication
# Managed by /shared-memory command (Haiku)
# Location: Always at monorepo root (.claude/shared_memory.yaml)

common:
  description: "Shared context across all sessions"
  items: []

projects:
  web:
    description: "Frontend (WebStorm) session context"
  api:
    description: "Backend (PyCharm) session context"

notes:
  # Notes for cross-session communication
  # id: unique identifier
  # from: source session (web|api|manual)
  # status: active|done
  # timestamp: ISO 8601 UTC
  # hint: short summary for quick scan
  # content: full note content
  items: []

meta:
  last_id: 0
  created: "$TIMESTAMP"
  updated: "$TIMESTAMP"
EOF
        echo "[+] Initialized $MEMORY_FILE"
    fi
}

# Generate next ID
next_id() {
    local last_id=$(yq '.meta.last_id' "$MEMORY_FILE")
    local new_id=$((last_id + 1))
    yq -i ".meta.last_id = $new_id" "$MEMORY_FILE"
    echo "$new_id"
}

# Update timestamp
update_timestamp() {
    local TIMESTAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
    yq -i ".meta.updated = \"$TIMESTAMP\"" "$MEMORY_FILE"
}

# Add a note
cmd_add() {
    local from=""
    local hint=""
    local content=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --from)
                from="$2"
                shift 2
                ;;
            --hint)
                hint="$2"
                shift 2
                ;;
            --content)
                content="$2"
                shift 2
                ;;
            *)
                echo "[X] Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$from" ] || [ -z "$hint" ] || [ -z "$content" ]; then
        echo "[X] Error: --from, --hint, and --content are required"
        echo "Usage: cmd.sh add --from <web|api|manual> --hint \"short hint\" --content \"full content\""
        exit 1
    fi

    local id=$(next_id)
    local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

    # Add note to items array - escape content for YAML
    yq -i ".notes.items += [{
        \"id\": $id,
        \"from\": \"$from\",
        \"status\": \"active\",
        \"timestamp\": \"$timestamp\",
        \"hint\": \"$hint\",
        \"content\": \"$content\"
    }]" "$MEMORY_FILE"

    update_timestamp

    echo "==============================================================================="
    echo "NOTE ADDED"
    echo "==============================================================================="
    echo ""
    echo "ID: $id"
    echo "From: $from"
    echo "Hint: $hint"
    echo "Timestamp: $timestamp"
    echo ""
    echo "Content:"
    echo "$content"
    echo ""
    echo "==============================================================================="
}

# List notes
cmd_list() {
    local show_all=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                show_all=true
                shift
                ;;
            *)
                echo "[X] Unknown option: $1"
                exit 1
                ;;
        esac
    done

    echo "==============================================================================="
    if [ "$show_all" = true ]; then
        echo "ALL NOTES (including done)"
    else
        echo "ACTIVE NOTES"
    fi
    echo "==============================================================================="
    echo ""

    local count=0

    if [ "$show_all" = true ]; then
        count=$(yq '.notes.items | length' "$MEMORY_FILE")
        if [ "$count" -eq 0 ]; then
            echo "  No notes found."
        else
            yq -r '.notes.items[] | "ID: \(.id) [\(.status)]\nFrom: \(.from) | \(.timestamp)\nHint: \(.hint)\n---"' "$MEMORY_FILE"
        fi
    else
        count=$(yq '[.notes.items[] | select(.status == "active")] | length' "$MEMORY_FILE")
        if [ "$count" -eq 0 ]; then
            echo "  No active notes."
        else
            yq -r '.notes.items[] | select(.status == "active") | "ID: \(.id)\nFrom: \(.from) | \(.timestamp)\nHint: \(.hint)\n---"' "$MEMORY_FILE"
        fi
    fi

    echo ""
    echo "==============================================================================="
    echo "Total: $count note(s)"
    echo "==============================================================================="
}

# Show note content
cmd_show() {
    local id="$1"

    if [ -z "$id" ]; then
        echo "[X] Error: Note ID required"
        echo "Usage: cmd.sh show <id>"
        exit 1
    fi

    # Check if note exists
    local exists=$(yq ".notes.items[] | select(.id == $id) | .id" "$MEMORY_FILE")
    if [ -z "$exists" ]; then
        echo "[X] Error: Note $id not found"
        exit 1
    fi

    echo "==============================================================================="
    echo "NOTE DETAILS"
    echo "==============================================================================="
    echo ""
    yq -r ".notes.items[] | select(.id == $id) | \"ID: \(.id) [\(.status)]\nFrom: \(.from)\nTimestamp: \(.timestamp)\nHint: \(.hint)\n\nContent:\n\(.content)\"" "$MEMORY_FILE"
    echo ""
    echo "==============================================================================="
}

# Update a note
cmd_update() {
    local id="$1"
    shift

    if [ -z "$id" ]; then
        echo "[X] Error: Note ID required"
        echo "Usage: cmd.sh update <id> [--hint \"new hint\"] [--content \"new content\"]"
        exit 1
    fi

    # Check if note exists
    local exists=$(yq ".notes.items[] | select(.id == $id) | .id" "$MEMORY_FILE")
    if [ -z "$exists" ]; then
        echo "[X] Error: Note $id not found"
        exit 1
    fi

    local hint=""
    local content=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --hint)
                hint="$2"
                shift 2
                ;;
            --content)
                content="$2"
                shift 2
                ;;
            *)
                echo "[X] Unknown option: $1"
                exit 1
                ;;
        esac
    done

    if [ -z "$hint" ] && [ -z "$content" ]; then
        echo "[X] Error: At least --hint or --content required"
        exit 1
    fi

    if [ -n "$hint" ]; then
        yq -i "(.notes.items[] | select(.id == $id)).hint = \"$hint\"" "$MEMORY_FILE"
    fi

    if [ -n "$content" ]; then
        yq -i "(.notes.items[] | select(.id == $id)).content = \"$content\"" "$MEMORY_FILE"
    fi

    update_timestamp

    echo "==============================================================================="
    echo "NOTE UPDATED"
    echo "==============================================================================="
    echo ""
    echo "ID: $id"
    if [ -n "$hint" ]; then
        echo "New hint: $hint"
    fi
    if [ -n "$content" ]; then
        echo "New content: $content"
    fi
    echo ""
    echo "==============================================================================="
}

# Mark note as done
cmd_done() {
    local id="$1"

    if [ -z "$id" ]; then
        echo "[X] Error: Note ID required"
        echo "Usage: cmd.sh done <id>"
        exit 1
    fi

    # Check if note exists
    local exists=$(yq ".notes.items[] | select(.id == $id) | .id" "$MEMORY_FILE")
    if [ -z "$exists" ]; then
        echo "[X] Error: Note $id not found"
        exit 1
    fi

    yq -i "(.notes.items[] | select(.id == $id)).status = \"done\"" "$MEMORY_FILE"
    update_timestamp

    echo "==============================================================================="
    echo "NOTE MARKED DONE"
    echo "==============================================================================="
    echo ""
    echo "ID: $id marked as done"
    echo ""
    echo "Run 'compact' to remove done notes permanently"
    echo "==============================================================================="
}

# Mark note as discard (orphaned/failed task)
cmd_discard() {
    local id="$1"

    if [ -z "$id" ]; then
        echo "[X] Error: Note ID required"
        echo "Usage: cmd.sh discard <id>"
        exit 1
    fi

    # Check if note exists
    local exists=$(yq ".notes.items[] | select(.id == $id) | .id" "$MEMORY_FILE")
    if [ -z "$exists" ]; then
        echo "[X] Error: Note $id not found"
        exit 1
    fi

    yq -i "(.notes.items[] | select(.id == $id)).status = \"discard\"" "$MEMORY_FILE"
    update_timestamp

    echo "==============================================================================="
    echo "NOTE MARKED DISCARD"
    echo "==============================================================================="
    echo ""
    echo "ID: $id marked as discard (orphaned/failed task)"
    echo ""
    echo "Discarded notes are skipped during resume and can be reviewed with --all"
    echo "Run 'compact' to remove discard notes permanently"
    echo "==============================================================================="
}

# Compact - remove done and discard notes
cmd_compact() {
    # Count done and discard notes
    local done_count=$(yq '[.notes.items[] | select(.status == "done")] | length' "$MEMORY_FILE")
    local discard_count=$(yq '[.notes.items[] | select(.status == "discard")] | length' "$MEMORY_FILE")
    local total_removed=$((done_count + discard_count))

    if [ "$total_removed" -eq 0 ]; then
        echo "[i] No done or discard notes to compact"
        exit 0
    fi

    # Backup before compaction
    cp "$MEMORY_FILE" "$BACKUP_FILE"
    echo "[+] Backup created: $BACKUP_FILE"

    # Remove done and discard notes, keep only active
    yq -i '.notes.items = [.notes.items[] | select(.status == "active")]' "$MEMORY_FILE"
    update_timestamp

    echo "==============================================================================="
    echo "COMPACTION COMPLETE"
    echo "==============================================================================="
    echo ""
    echo "Removed: $done_count done note(s) + $discard_count discard note(s)"
    echo "Total removed: $total_removed note(s)"
    echo "Backup: $BACKUP_FILE"
    echo ""
    echo "==============================================================================="
}

# Main
init_memory

case "${1:-}" in
    add)
        shift
        cmd_add "$@"
        ;;
    list)
        shift
        cmd_list "$@"
        ;;
    show)
        shift
        cmd_show "$@"
        ;;
    update)
        shift
        cmd_update "$@"
        ;;
    done)
        shift
        cmd_done "$@"
        ;;
    discard)
        shift
        cmd_discard "$@"
        ;;
    compact)
        cmd_compact
        ;;
    *)
        echo "==============================================================================="
        echo "SHARED MEMORY - Cross-session communication"
        echo "==============================================================================="
        echo ""
        echo "Location: $MEMORY_FILE"
        echo ""
        echo "Usage: cmd.sh <command> [options]"
        echo ""
        echo "Commands:"
        echo "  add --from <source> --hint <hint> --content <content>"
        echo "      Add a new note"
        echo "      source: web|api|manual"
        echo ""
        echo "  list [--all]"
        echo "      List active notes (--all includes done)"
        echo ""
        echo "  show <id>"
        echo "      Show full note content"
        echo ""
        echo "  update <id> [--hint <hint>] [--content <content>]"
        echo "      Update note hint or content"
        echo ""
        echo "  done <id>"
        echo "      Mark note as done (soft delete)"
        echo ""
        echo "  discard <id>"
        echo "      Mark note as discard (orphaned/failed task)"
        echo ""
        echo "  compact"
        echo "      Remove done and discard notes (creates backup first)"
        echo ""
        echo "==============================================================================="
        ;;
esac
