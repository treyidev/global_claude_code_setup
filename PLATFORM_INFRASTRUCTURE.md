# Claude Global Custom Commands & Platform Infrastructure

> Reusable platform infrastructure for ALL Claude Code projects.
> These are global utilities, not project-specific code.

---

## Overview

The following infrastructure is available globally (via `~/.claude/`) and can be used across all projects:

### Session Management Commands
- **`/project:resume`** - Load context from previous session
- **`/project:checkpoint`** - Save progress mid-session
- **`/project:handoff`** - Persist state for next session

### Task Spawning & Recovery
- **`/project:spawn`** (via `task_spawn.sh`) - Create hierarchical subtasks with context preservation
- **`/project:recover`** (via `task_recover.md`) - Intelligent crash recovery orchestration

### Shared Infrastructure
- **`/shared-memory`** - Cross-IDE communication (symlinked to `shared_memory_updater.sh`)

---

## Session Management Commands

### `/project:resume` - Load Previous Context

**Location:** `~/.claude/commands/resume.md`

**Purpose:** Restore context from previous session stored in `.claude/SESSION.md`

**When to use:**
- At session start (if previous context exists)
- After Claude crashes and session is resumed

**What it does:**
1. Reads `.claude/SESSION.md`
2. Parses current focus, completed work, next steps
3. Restores project context
4. Identifies any active spawned tasks

**Example:**
```bash
/project:resume
```

**Output:**
- Current branch and status
- Last completed work
- Active spawned tasks (if any)
- Next steps to continue with

---

### `/project:checkpoint` - Save Progress Mid-Session

**Location:** `~/.claude/commands/checkpoint.md`

**Purpose:** Save progress without stopping work

**When to use:**
- Every 30-45 minutes of continuous work
- After completing major features
- Before attempting risky refactoring

**What it does:**
1. Captures current git state
2. Validates no uncommitted secrets
3. Updates `.claude/SESSION.md` with progress
4. Summarizes completed work
5. Continues session (unlike handoff)

**Example:**
```bash
/project:checkpoint
```

**Output:**
- Progress saved
- Session continues
- Next steps confirmed

---

### `/project:handoff` - Persist Full Context

**Location:** `~/.claude/commands/handoff.md`

**Purpose:** Save complete state for next session (before stopping)

**When to use:**
- End of day / before stopping
- Before long break
- When switching to different project

**What it does:**
1. Runs git status check
2. Updates `.claude/SESSION.md` comprehensively
3. Saves all progress markers
4. Preserves active spawned task state
5. Documents "For Next Session" section
6. Cleans up temporary state

**Example:**
```bash
/project:handoff
```

**Output:**
- Full context persisted
- Ready for next session
- Safe to close editor

---

## Task Spawning & Recovery Commands

### `/project:spawn` - Create Hierarchical Subtasks

**Location:** `~/.claude/commands/task_spawn.sh`

**Purpose:** Spawn focused subtasks when blocking work is encountered

**Minimal Interface:**
```bash
./.claude/commands/task_spawn.sh \
  --model "sonnet" \
  --prompt "Your task description here"
```

**Optional Flags:**
```bash
--parent-task "task-id"    # Nest under parent task (for multi-level hierarchy)
--branch-aware             # Create git branch + GitLab issue for MR workflow
```

**What it does:**
1. Generates unique task ID: `task-XXXXXXXXX-XXXXX`
2. Captures current git state (LAST_GOOD_COMMIT)
3. Creates patch file with task metadata
4. Creates git branch (if `--branch-aware`)
5. Creates GitLab issue (if `--branch-aware`)
6. Creates shared_memory entry
7. Updates `.claude/SESSION.md`
8. Returns task ID and branch name

**Example - Simple spawn (no branch):**
```bash
./.claude/commands/task_spawn.sh \
  --model "sonnet" \
  --prompt "Refactor authentication service to support multi-device sessions"

# Output:
# Task ID: task-1767893084-236b25
# Model: sonnet
# Last Good Commit: c0f61be940fdffa16ce82c6a81211c1145342feb
# Run on crash: /project:recover
```

**Example - Branch-aware spawn (for code review workflow):**
```bash
./.claude/commands/task_spawn.sh \
  --model "sonnet" \
  --prompt "Implement multi-device session storage layer. Must support: PostgreSQL backend, concurrent device tracking, session invalidation on logout, automatic session expiry after 30 days inactivity." \
  --branch-aware

# Output:
# Task ID: task-1767893181-a5f7
# Model: sonnet
# Branch: feature/task-1767893181-a5f7
# GitLab Issue: #456
# Last Good Commit: c0f61be940fdffa16ce82c6a81211c1145342feb
# MR will be created on recovery if work completes
```

**How Context is Preserved:**

When spawned task crashes:
1. Last good commit is stored in patch file
2. On recovery, you can rollback via `git reset --hard <last_good_commit>`
3. SESSION.md maintains pointer to active task
4. Entire task context (prompt, model, branch) persists

---

### `/project:recover` - Intelligent Crash Recovery

**Location:** `~/.claude/commands/task_recover.md`

**Purpose:** Orchestrate recovery from crashes with intelligent scenario detection

**When to use:**
- After Claude crashes during spawned task
- When task execution is interrupted

**What it does:**
1. **Detects:** Analyzes git state, branch, commits, MR status
2. **Analyzes:** Determines scenario (pre-work crash vs post-work crash vs MR pending)
3. **Guides:** Shows user clear options for each scenario
4. **Executes:** Calls bash functions with zero-tolerance validation
5. **Validates:** Each action validates success before proceeding

**Scenarios Handled:**

#### Scenario 1: Pre-Work Crash
**What happened:** Task spawned but no work started (branch not created or empty)

**Options:**
- (1) Retry with same prompt
- (2) Modify prompt and retry
- (3) Cancel task

#### Scenario 2: Post-Work Crash (No MR)
**What happened:** Work done on branch, but MR not created yet

**Options:**
- (1) Create MR automatically → await merge → rebase main task
- (2) Review work before creating MR
- (3) Modify approach and restart

#### Scenario 3: MR Pending
**What happened:** MR created but not yet merged

**Options:**
- (1) Check MR status and await merge
- (2) Review and address feedback
- (3) Abandon MR and restart

#### Scenario 4: MR Merged (Course Correction)
**What happened:** Work was merged, main task needs to rebase

**Options:**
- (1) Continue as planned (full integration)
- (2) Modify approach based on actual implementation
- (3) Ask questions about the session layer design

---

## Global Utilities (Shared Infrastructure)

### Git Operations (`~/.claude/utils/git_operations.sh`)

25+ reusable git functions available to any command:

```bash
source ~/.claude/utils/git_operations.sh

# Basic info
git_get_root                      # Get git repo root
git_current_branch                # Get current branch
git_get_head_commit               # Get HEAD commit hash
git_commits_ahead_of              # Count commits ahead of main

# Branch operations
git_branch_exists                 # Check if branch exists
git_create_branch                 # Create new branch
git_delete_branch                 # Delete branch
git_rebase_on                     # Rebase onto target

# State management
git_is_clean                      # Check if working tree is clean
git_stash_save                    # Stash changes with message
git_stash_pop                     # Apply stashed changes
git_fetch_origin                  # Fetch latest from origin
git_reset_hard                    # Hard reset to commit (DESTRUCTIVE)
```

### Patch Manager (`~/.claude/utils/patch_manager.sh`)

Lifecycle management for task patch files:

```bash
source ~/.claude/utils/patch_manager.sh

# Patch file operations
patch_create_file                 # Create new patch file
patch_exists                      # Check if patch exists
patch_read_field                  # Read metadata field (TASK_ID, MODEL, etc.)
patch_update_field                # Update field atomically
patch_read_prompt                 # Get task prompt
patch_validate_format             # Validate patch file integrity
patch_add_note                    # Add audit trail note
```

### Task Status & Detection (`~/.claude/utils/task_status.sh`)

Intelligent crash detection and analysis:

```bash
source ~/.claude/utils/task_status.sh

# Crash detection (main entry point)
task_detect_crash_state           # Returns JSON report with:
                                  # - task_id, task_context
                                  # - git_state, branch_state, mr_state
                                  # - scenario_analysis + recovery options

# Individual analysis functions
detect_spawned_task               # Extract task ID from SESSION.md
validate_task                     # Verify patch file integrity
analyze_git_state                 # Analyze branch, commits, changes
check_branch_state                # Check if branch exists + commits ahead
check_mr_state                    # Check GitLab MR status
analyze_scenario                  # Determine crash scenario
```

### Task Execution (`~/.claude/utils/task_execute.sh`)

Execute recovery actions with zero-tolerance validation:

```bash
source ~/.claude/utils/task_execute.sh

# Individual actions (each validates after execution)
execute_reset_to_commit           # Rollback to specific commit
execute_delete_branch             # Remove abandoned branch
execute_mark_discarded            # Mark task as discarded (audit trail)
execute_cleanup_patch             # Clean up patch file
execute_stash_changes             # Stash working directory changes
execute_rebase_on_main            # Rebase branch on main
execute_apply_stash               # Reapply stashed changes
execute_create_mr                 # Create GitLab merge request
execute_check_mr_status           # Poll MR status

# Composite workflows
execute_cleanup_orphaned_task     # Clean pre-work crash: delete branch + mark discarded + cleanup
execute_post_work_recovery       # Rebase workflow: stash + rebase + apply stash
```

### Shared Memory (`~/.claude/utils/shared_memory_updater.sh`)

Cross-IDE communication and task state tracking:

```bash
# Add note (accessible from any IDE)
~/.claude/commands/shared-memory/cmd.sh add \
  --from web \
  --hint "API contract change" \
  --content "Changed /api/progress response schema..."

# List all notes
~/.claude/commands/shared-memory/cmd.sh list

# Mark as processed
~/.claude/commands/shared-memory/cmd.sh done <id>

# Discard orphaned task
~/.claude/commands/shared-memory/cmd.sh discard <id>

# Compact (remove done + discard)
~/.claude/commands/shared-memory/cmd.sh compact
```

---

## Architecture

### Global vs Project-Local Separation

```
~/.claude/                           # GLOBAL (reusable across all projects)
├── utils/                           # Shared utilities
│   ├── git_operations.sh
│   ├── patch_manager.sh
│   ├── task_status.sh
│   ├── task_execute.sh
│   └── shared_memory_updater.sh
├── commands/
│   ├── resume.md                   # Session resume
│   ├── checkpoint.md               # Session checkpoint
│   ├── handoff.md                  # Session handoff
│   ├── task_spawn.sh               # Task spawn
│   ├── task_recover.md             # Task recovery
│   └── shared-memory/cmd.sh        # Shared memory (symlink)
└── SESSION.md.template             # Standard format for all projects

./.claude/                           # PROJECT-LOCAL
├── SESSION.md                       # Project instance (respects global format)
├── docs/
│   └── TASK_SPAWN_EXAMPLES.md      # Project-specific examples
└── patches/                         # Task patch files (local to project)
```

### How It Works

**Session Lifecycle (Global):**
```
User starts session
    ↓
/project:resume
    ↓
Loads ./.claude/SESSION.md (local instance)
    ↓
Work continues
    ↓
/project:checkpoint (every 30-45 mins)
    ↓
Updates ./.claude/SESSION.md with progress
    ↓
Work completes
    ↓
/project:handoff
    ↓
Comprehensive ./.claude/SESSION.md saved
    ↓
Session ends
```

**Task Spawning (Global + Project-Local):**
```
/project:spawn --model sonnet --prompt "task"
    ↓
Creates patch file in ./.claude/patches/
    ↓
Updates ./.claude/SESSION.md (spawned_task_id)
    ↓
Creates branch (if --branch-aware)
    ↓
Spawned task executes
    ↓
CRASH
    ↓
/project:recover
    ↓
Detects state, guides recovery, executes fix
    ↓
Continue main task
```

---

## Usage from Any Project

Each project has its own context, but uses global commands:

```bash
# From any project directory
cd /path/to/any/project

# Resume previous session
/project:resume

# Save progress
/project:checkpoint

# Spawn subtask
./.claude/commands/task_spawn.sh --model sonnet --prompt "Task description"

# Recover from crash
/project:recover

# Save before stopping
/project:handoff
```

---

## Key Design Principles

### 1. Zero-Tolerance Validation
Every execution action validates → fails immediately if validation fails → no silent corruption

### 2. Git as Source of Truth
LAST_GOOD_COMMIT stored in patch files enables instant rollback on crash

### 3. Platform Infrastructure (Not Project-Specific)
Global utilities are generic, reusable across all projects
Project-local files contain only project-specific configuration and examples

### 4. Backward Compatibility
Existing project SESSION.md files continue to work
Global utilities enhance, don't replace

### 5. Audit Trail
Patch files maintain historical record for debugging
Status field (active|done|discard) tracks lifecycle

---

## Quick Reference

| Need | Command | Location |
|------|---------|----------|
| Load previous context | `/project:resume` | `~/.claude/commands/resume.md` |
| Save progress (continue) | `/project:checkpoint` | `~/.claude/commands/checkpoint.md` |
| Save state (stop session) | `/project:handoff` | `~/.claude/commands/handoff.md` |
| Spawn subtask | `task_spawn.sh --model sonnet --prompt "..."` | `~/.claude/commands/task_spawn.sh` |
| Recover from crash | `/project:recover` | `~/.claude/commands/task_recover.md` |
| Cross-IDE messages | `/shared-memory add ...` | `~/.claude/commands/shared-memory/cmd.sh` |

---

## Testing Platform Infrastructure

```bash
# Test session management
/project:resume                    # Load context
/project:checkpoint               # Save progress
/project:handoff                  # Save state

# Test task spawning
./.claude/commands/task_spawn.sh \
  --model haiku \
  --prompt "Test simple spawn"

# Test recovery detection
source ~/.claude/utils/task_status.sh
task_detect_crash_state           # Returns JSON report

# Test utilities
source ~/.claude/utils/git_operations.sh
git_current_branch               # Should return current branch
```

---

## Files Overview

| File | Purpose |
|------|---------|
| `~/.claude/SESSION.md.template` | Standard SESSION.md format for all projects |
| `~/.claude/PLATFORM_INFRASTRUCTURE.md` | This file - explains global commands |
| `~/.claude/commands/resume.md` | Resume command |
| `~/.claude/commands/checkpoint.md` | Checkpoint command |
| `~/.claude/commands/handoff.md` | Handoff command |
| `~/.claude/commands/task_spawn.sh` | Spawn command |
| `~/.claude/commands/task_recover.md` | Recovery command |
| `~/.claude/commands/shared-memory/cmd.sh` | Shared memory (symlink to utils) |
| `~/.claude/utils/git_operations.sh` | Git utilities (25+ functions) |
| `~/.claude/utils/patch_manager.sh` | Patch file management |
| `~/.claude/utils/task_status.sh` | Crash detection & analysis |
| `~/.claude/utils/task_execute.sh` | Execution with validation |
| `~/.claude/utils/shared_memory_updater.sh` | Shared memory management |
