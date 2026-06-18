---
name: shared_memory
description: Cross-session shared memory for communication between Claude instances
model: sonnet
---

# Shared Memory - Cross-Session Communication

Manages shared notes across different Claude Code sessions (VSCode, PyCharm, WebStorm) and across ALL projects.
All notes stored globally in `~/.claude/shared_memory.yaml`.

## Usage

```bash
/shared_memory list              # List active notes
/shared_memory list --all        # List all notes (including done)
/shared_memory show <id>         # Show full note details
/shared_memory add               # Add new note (interactive)
/shared_memory done <id>         # Mark note as done
/shared_memory discard <id>      # Mark note as discard
/shared_memory compact           # Remove done/discard notes
/shared_memory help              # Show help
```

## Commands

### list [--all]
List active notes. Use `--all` to include done/discard notes.

**Example**:
```bash
/shared_memory list              # Active notes only
/shared_memory list --all        # All notes
```

### show <id>
Display full content of a specific note by ID.

**Example**:
```bash
/shared_memory show 1
```

### add
Add a new note to shared memory. Claude will prompt for:
- **from**: Source identifier (vscode-main, pycharm-cli, webstorm-web, etc.)
- **hint**: Short summary for quick scanning
- **content**: Full note content (can be multiline)

**Example**:
```bash
/shared_memory add
# Claude will ask for details interactively
```

### done <id>
Mark note as done (soft delete). Note remains in file but hidden from default `list`.

**Example**:
```bash
/shared_memory done 1
```

### discard <id>
Mark note as discard (orphaned/failed task). Different from `done` - indicates task was abandoned.

**Example**:
```bash
/shared_memory discard 2
```

### compact
Remove all done and discard notes permanently. Creates backup before compacting.

**Example**:
```bash
/shared_memory compact
```

### help
Show full usage information.

## Implementation

When user invokes this command, you should:

1. **Parse the command**: Extract operation and arguments
2. **Validate**: Check if required arguments are present
3. **Execute**: Run the corresponding bash command via `Bash` tool
4. **Present results**: Display output in readable format

### Command Mapping

```
User Input                       → Bash Command
─────────────────────────────────────────────────────────────
/shared_memory list              → ~/.claude/commands/shared-memory/cmd.sh list
/shared_memory list --all        → ~/.claude/commands/shared-memory/cmd.sh list --all
/shared_memory show 1            → ~/.claude/commands/shared-memory/cmd.sh show 1
/shared_memory add               → Interactive (ask for from, hint, content)
                                   then: cmd.sh add --from X --hint Y --content Z
/shared_memory done 1            → ~/.claude/commands/shared-memory/cmd.sh done 1
/shared_memory discard 2         → ~/.claude/commands/shared-memory/cmd.sh discard 2
/shared_memory compact           → ~/.claude/commands/shared-memory/cmd.sh compact
/shared_memory help              → ~/.claude/commands/shared-memory/cmd.sh
```

### Interactive Add Flow

When user runs `/shared_memory add`:

1. **Ask for source** (from):
   ```
   Which session is this note from?
   Options:
   - vscode-main (Main VSCode session)
   - pycharm-cli (PyCharm CLI package)
   - webstorm-web (WebStorm web package)
   - other (specify custom identifier)
   ```

2. **Ask for hint** (short summary):
   ```
   Enter a short hint (1 line summary):
   Example: "Issue #166 mgz doctor - Ready for implementation"
   ```

3. **Ask for content** (full details):
   ```
   Enter the full note content (multiline supported):
   This can include context, links, code snippets, etc.
   ```

4. **Execute**:
   ```bash
   ~/.claude/commands/shared-memory/cmd.sh add \
     --from "vscode-main" \
     --hint "User's hint here" \
     --content "Full content here with
   multiple lines if needed"
   ```

5. **Confirm**: Show the note ID and summary.

## Output Formatting

### For list command
Parse the bash output and present it cleanly:

```
Active Shared Memory Notes
==========================

ID: 1
From: vscode-main | 2026-01-09T08:15:52Z
Hint: Issue #166: mgz doctor - Full handoff in .claude/handoffs/
---

ID: 3
From: pycharm-cli | 2026-01-09T10:22:15Z
Hint: Render quality preset needs validation
---

Total: 2 active note(s)
```

### For show command
Display full note details with proper formatting.

### For add/done/discard/compact
Show confirmation message from bash script.

## Error Handling

- **Not in git repo**: "Error: Not in a git repository. Shared memory requires git root."
- **Missing yq**: "Error: yq is required. Install: brew install yq"
- **Invalid note ID**: "Error: Note {id} not found"
- **Missing arguments**: Show usage for that specific command

## Notes

- This command should ALWAYS use Sonnet model (specified in frontmatter)
- All shared memory operations are fast bash commands, no heavy computation
- The bash script handles all YAML operations, Claude just wraps the interface
- Notes persist across sessions and can be read from ANY IDE session in ANY project
- Location: **Global** at `~/.claude/shared_memory.yaml` (cross-project communication)
- **IMPORTANT**: Always use absolute file paths in note content for cross-project access

## Examples

### Example 1: Quick handoff between sessions
```bash
# In VSCode (main session)
/shared_memory add
# From: vscode-main
# Hint: Bootstrap system deps merged, now working on mgz doctor
# Content: Issue #166 ready for PyCharm. Branch: feature/mgz-doctor-diagnostics-166

# Later in PyCharm
/shared_memory list
# Shows: Bootstrap system deps merged, now working on mgz doctor

/shared_memory show 1
# Full details with branch name and issue

/shared_memory done 1
# Mark as handled
```

### Example 2: Track blocking issues
```bash
/shared_memory add
# From: pycharm-cli
# Hint: Blocked: Need CSS fix before continuing render command
# Content: The render preview window needs fixed CSS. Blocked on Issue #155.

# In WebStorm (later)
/shared_memory list
# See the blocker, fix CSS

/shared_memory add
# From: webstorm-web
# Hint: CSS fixed in Issue #155, unblocking render preview
# Content: Fixed viewport sizing bug. Render command can continue.
```

### Example 3: Cleanup
```bash
/shared_memory list --all
# Shows active + done notes

/shared_memory compact
# Removes all done/discard notes, creates backup
```

## Related Commands

- `/project:resume` - Load session context from SESSION.md
- `/project:checkpoint` - Save mid-session progress
- `/project:handoff` - Full session handoff before stopping

Shared memory complements these by enabling **cross-session** communication when
different IDE instances need to coordinate.
