# Global Claude Code Setup

**Universal Claude Code Infrastructure for All Projects**

This repository contains reusable Claude Code infrastructure that enables consistent, powerful development workflows across all your projects. It includes global commands, bash utilities, session management, and comprehensive documentation.

---

## What is This Repository?

This is a global infrastructure repository that lives at `~/.claude/` on your machine. It provides:

1. **Custom Commands** - Reusable `.claude/commands/*.md` files that automate complex workflows
2. **Bash Utilities** - Shared shell scripts for git operations, patch management, task spawning, and crash recovery
3. **Documentation** - Comprehensive guides for task spawning, session management, crash recovery, and platform architecture
4. **Session Templates** - Standard format for maintaining project state across Claude Code sessions

Think of it as a **global toolkit** that every project can leverage, complemented by project-specific state (`.claude/SESSION.md`, `.claude/patches/`, etc.).

---

## Why Does This Exist?

### The Problem

Initially, task spawning, crash recovery, and session management logic was duplicated in each project's `.claude/` directory. This meant:

- **No consistency** across projects
- **Bugs fixed in one project** weren't fixed in others
- **Platform infrastructure wasn't versioned** (no git history)
- **Difficult to improve** (would require updates in every project)
- **Hard to share** improvements with other developers

### The Solution

By migrating platform infrastructure to a global, versioned repository:

- ✅ **Single source of truth** for all reusable logic
- ✅ **Version controlled** - full git history of improvements
- ✅ **Consistent** across all projects
- ✅ **Easy to update** - one change benefits all projects
- ✅ **Portable** - new machines just clone and symlink
- ✅ **Shareable** - can be published and shared with other developers

---

## Repository Structure

```
~/.claude/
├── README.md                          # This file
├── .gitignore                         # Excludes debug/IDE files
│
├── CLAUDE.md                          # Global directives & rules
├── PLATFORM_INFRASTRUCTURE.md         # Complete platform documentation
├── SESSION.md.template                # Standard session format
│
├── commands/                          # Global custom commands
│   ├── task_spawn.sh                  # Spawn hierarchical subtasks
│   ├── task_recover.md                # Crash recovery orchestration
│   ├── resume.md                      # Resume previous session
│   ├── checkpoint.md                  # Save progress mid-session
│   ├── handoff.md                     # Persist state for next session
│   └── shared-memory/
│       └── cmd.sh                     # Cross-IDE communication (symlink)
│
├── utils/                             # Reusable bash utilities
│   ├── git_operations.sh              # Git utilities (25+ functions)
│   ├── patch_manager.sh               # Patch file lifecycle management
│   ├── task_status.sh                 # Crash detection & analysis
│   ├── task_execute.sh                # Execution with validation
│   └── shared_memory_updater.sh       # Shared memory backend
│
└── .git/                              # Version control (git repository)
```

### Key Separation: Global vs Project-Local

| Location | Purpose | Versioned |
|----------|---------|-----------|
| `~/.claude/` (this repo) | Reusable infrastructure | ✅ Yes |
| `./.claude/` (project) | Project-specific state | ❌ No (usually gitignored) |

**Global** (`~/.claude/`):
- Commands, utilities, documentation
- Used by all projects
- Tracked in this git repository
- Updated independently

**Project-Local** (`./.claude/`):
- `SESSION.md` - Current session state
- `patches/` - Task patch files (crash recovery)
- `shared_memory.yaml` - Cross-IDE notes
- `docs/` - Project-specific examples
- Usually gitignored (project-local state)

---

## Installation & Setup

### First-Time Setup

**Clone the repository to `~/.claude/`:**

```bash
git clone https://gitlab.com/treyipune/global_claude_code_setup.git ~/.claude
cd ~/.claude
git remote add github https://github.com/treyidev/global_claude_code_setup.git
```

**Verify installation:**

```bash
ls -la ~/.claude/
# Should show: CLAUDE.md, PLATFORM_INFRASTRUCTURE.md, commands/, utils/

cd ~/.claude
git log --oneline
# Should show commit: c6a4130 chore: initialize global claude code setup
```

### Using in a New Project

Once `~/.claude/` is set up globally, any project can use it immediately:

```bash
cd /path/to/your/project
# ~/.claude is already available globally - no per-project setup needed!

# Create project-local Claude Code state
mkdir -p .claude/patches
```

To use the CLI commands in your project:

```bash
cd /path/to/your/project

# All global commands are available
/project:resume          # Load previous session
/project:checkpoint      # Save progress
/project:handoff         # Persist state for next session
```

### Keeping Global Infrastructure Updated

Since `~/.claude/` is a git repository, you can pull updates:

```bash
cd ~/.claude
git pull origin main
git pull github main      # Mirror also available
```

Or push local improvements:

```bash
cd ~/.claude
git add .
git commit -m "chore: improve task spawn error handling"
git push origin main
git push github main
```

---

## Contents Overview

### 1. CLAUDE.md - Global Directives

**File**: `~/.claude/CLAUDE.md`

The global Claude directives file containing universal standards for all projects. This includes:

- **Identity**: Author, git conventions (NO Co-Authored-By Claude)
- **Custom Command Model Routing** (CRITICAL): Rules for automatic task delegation based on command model requirements
- **SOLID Principles**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
- **Clean Code Rules**: No globals, no hardcoded values, no magic numbers, fail-fast pattern
- **Architecture Principles**: Managers delegate, workers work, data is passive
- **Language-Specific Standards**: Python, Kotlin, C++, Java with examples
- **File Organization**: Domain-driven structure, forbidden file names
- **Git Conventions**: Conventional commits format
- **Model Selection**: When to use Haiku, Sonnet, or Opus
- **Haiku Delegation Rule** (PERMANENT): ALL shell commands must delegate to Haiku via Task tool
- **Code Review Stance**: When to push back on suggestions
- **Exception Hierarchy**: Domain-specific exception patterns
- **Global Custom Commands & Platform Infrastructure**: Session management, task spawning, shared memory
- **Session Lifecycle**: When to use `/project:resume`, `/project:checkpoint`, `/project:handoff`
- **Reference Files**: Links to architecture, workflow, and documentation standards

**Usage**: This file is automatically consulted by any Claude Code instance working on your projects. Every rule applies globally.

### 2. PLATFORM_INFRASTRUCTURE.md - Complete Documentation

**File**: `~/.claude/PLATFORM_INFRASTRUCTURE.md`

Comprehensive guide to the entire platform infrastructure (112KB). Covers:

#### Part 1: Overview
- Philosophy: stateless sessions, context preservation via git
- Architecture diagram: Task spawning hierarchy
- Workflow overview: How commands execute and coordinate

#### Part 2: Task Spawning System
- **`task_spawn.sh`** command reference
  - Spawning subtasks with state tracking
  - Branch-aware spawning (GitLab integration)
  - Nesting tasks at arbitrary depth
  - Patch file lifecycle

#### Part 3: Crash Recovery
- **Crash Detection** (`task_status.sh`)
  - Detecting spawned tasks from SESSION.md
  - Validating patch integrity
  - Analyzing git state
  - Checking branch and MR status
  - Scenario analysis (pre-work crash, post-work crash, MR pending)

- **Recovery Execution** (`task_execute.sh`)
  - Zero-tolerance validation
  - Atomic actions (execute → validate → report)
  - Composite recovery procedures
  - Orphaned task cleanup

#### Part 4: Session Management
- **Session Continuity** commands
  - `/project:resume` - Load context from previous session
  - `/project:checkpoint` - Save progress mid-session
  - `/project:handoff` - Persist state for next session
  - Format: SESSION.md in standard YAML format

#### Part 5: Shared Memory System
- **Cross-IDE Communication** via `/shared-memory` command
  - Add notes accessible from other IDE sessions
  - Mark notes as processed
  - Track IDE-specific state

#### Part 6: Architecture Details
- Bash utilities reference (all functions documented)
- Patch file format specification
- JSON state report structure
- Recovery scenario decision tree

**Usage**: Read this documentation to understand the complete platform. Reference it when:
- Setting up a new project
- Understanding crash recovery
- Learning about task spawning
- Implementing new commands

### 3. SESSION.md.template - Session State Template

**File**: `~/.claude/SESSION.md.template`

Standard template for project-local `.claude/SESSION.md` files. Ensures consistency across all projects.

Contains sections for:
- Last updated timestamp
- Current branch
- Current focus
- Completed this session
- Status (✅ COMPLETE, ⏳ IN_PROGRESS, etc.)
- Next steps
- Blockers
- Key architectural decisions
- Files modified
- Git state
- For next session (handoff context)

**Usage**: When creating a new project:
```bash
cp ~/.claude/SESSION.md.template ./.claude/SESSION.md
```

### 4. Global Commands

#### task_spawn.sh
**File**: `~/.claude/commands/task_spawn.sh`

Spawns a new subtask as an independent Claude Code session with full context isolation.

**What it does:**
1. Creates a unique task ID
2. Saves task context to patch file (`.claude/patches/<task-id>.yml`)
3. Spawns new Claude instance with the task prompt
4. Returns task ID for future reference

**Usage:**
```bash
~/.claude/commands/task_spawn.sh \
  --model "sonnet" \
  --prompt "Implement user authentication with Firebase"

~/.claude/commands/task_spawn.sh \
  --model "haiku" \
  --prompt "Run tests and report results" \
  --branch-aware

~/.claude/commands/task_spawn.sh \
  --model "opus" \
  --prompt "Design authentication architecture" \
  --parent-task "task-1234"
```

#### task_recover.md
**File**: `~/.claude/commands/task_recover.md`

Orchestrates crash recovery when a spawned task fails to complete.

**What it does:**
1. Detects crash state via `task_status.sh`
2. Analyzes scenario (pre-work, post-work, MR pending)
3. Guides user through recovery options
4. Executes recovery with validation
5. Reports completion

**Scenarios handled:**
- **Pre-work crash**: Task spawned but no work started → Retry/modify/cancel
- **Post-work crash**: Work done but MR not created → Create MR/review/restart
- **MR pending**: MR created but not merged → Check status/await/address feedback
- **MR merged**: Work merged, main task rebases → Course correction options

#### resume.md
**File**: `~/.claude/commands/resume.md`

Resumes a previous session by reading `.claude/SESSION.md` and restoring context.

**What it does:**
1. Reads `./.claude/SESSION.md` from current project
2. Extracts previous session state, focus, progress
3. Summarizes what was accomplished
4. Highlights next steps
5. Prepares for continuation

#### checkpoint.md
**File**: `~/.claude/commands/checkpoint.md`

Saves progress mid-session without stopping work.

**What it does:**
1. Snapshots current git state
2. Updates `./.claude/SESSION.md` with current progress
3. Commits any work in progress
4. Allows continuing work immediately after

#### handoff.md
**File**: `~/.claude/commands/handoff.md`

Persists full session state for next session.

**What it does:**
1. Finalizes all work
2. Updates `./.claude/SESSION.md` with completion notes
3. Commits any remaining changes
4. Prepares context for next session via `/project:resume`

#### shared-memory/cmd.sh
**File**: `~/.claude/commands/shared-memory/cmd.sh`

Symlink to `~/.claude/utils/shared_memory_updater.sh`.

Enables cross-IDE communication via shared memory entries.

**What it does:**
1. Add notes visible across IDE sessions
2. Track state changes
3. Mark items as processed
4. Maintain audit trail

---

## Bash Utilities Reference

All utilities are located in `~/.claude/utils/` and are sourced by commands.

### git_operations.sh

**25+ git utility functions** for common git operations.

**Key functions:**
- `git_current_branch()` - Get current branch name
- `git_is_clean()` - Check if working tree is clean
- `git_commits_ahead_of()` - Count commits ahead of main
- `git_branch_exists()` - Check if branch exists
- `git_delete_branch()` - Delete local branch
- `git_reset_hard()` - Hard reset to commit
- `git_fetch_origin()` - Fetch latest from remote
- `git_rebase_on()` - Rebase onto another branch
- `git_stash_save()` - Stash changes with message
- `git_stash_pop()` - Apply and remove stash
- `git_get_head_commit()` - Get current commit hash
- `git_get_head_commit_full()` - Get full commit hash

**Usage**: Sourced by other utilities and commands:
```bash
source ~/.claude/utils/git_operations.sh
git_current_branch  # Returns: "main" or "feature/something"
```

### patch_manager.sh

**Patch file lifecycle management** for task spawning and recovery.

Patch files store task context in YAML format:

```yaml
task_id: task-1234
model: sonnet
prompt: |
  Implement user authentication...

git_branch: feature/auth
last_good_commit: abc123def456
created_at: 2026-01-09T15:30:00Z
updated_at: 2026-01-09T15:35:00Z
status: in_progress
```

**Key functions:**
- `patch_create_file()` - Create new patch file
- `patch_exists()` - Check if patch exists
- `patch_read_field()` - Read a field from patch
- `patch_update_field()` - Update a field
- `patch_read_prompt()` - Read task prompt
- `patch_validate_format()` - Validate patch structure
- `patch_add_note()` - Add audit note

**Usage**:
```bash
source ~/.claude/utils/patch_manager.sh
patch_read_field "task-1234" "MODEL"      # Returns: "sonnet"
patch_update_field "task-1234" "STATUS" "completed"
```

### task_status.sh

**Crash detection and scenario analysis** for intelligent recovery.

Detects if a spawned task crashed and analyzes the situation:

```json
{
  "status": "crash_detected",
  "task_id": "task-1234",
  "task_context": {
    "model": "sonnet",
    "prompt": "...",
    "git_branch": "feature/auth"
  },
  "git_state": {
    "current_branch": "feature/auth",
    "is_clean": false,
    "commits_ahead_of_main": 3,
    "files_changed": 5
  },
  "branch_state": {
    "exists": true,
    "name": "feature/auth",
    "commits_ahead": 3
  },
  "scenario_analysis": {
    "scenario": "post_work_no_mr",
    "description": "Work done but MR not created",
    "recovery_options": ["create_mr", "review_work", "modify_approach"]
  }
}
```

**Key functions:**
- `task_detect_crash_state()` - Generate full state report (JSON)
- `detect_spawned_task()` - Detect task ID from SESSION.md
- `analyze_git_state()` - Analyze current git state
- `check_branch_state()` - Check branch existence and commits
- `analyze_scenario()` - Determine recovery scenario

**Usage**:
```bash
source ~/.claude/utils/task_status.sh
task_detect_crash_state > state_report.json
```

### task_execute.sh

**Execution with zero-tolerance validation** for atomic operations.

Every action follows: execute → validate → report success or FAIL HARD.

```
Execute: Run the operation
   ↓
Validate: Verify success
   ↓
Report: Success or ABORTING (no recovery)
```

**Key functions:**
- `execute_reset_to_commit()` - Rollback to commit
- `execute_delete_branch()` - Delete branch with validation
- `execute_stash_changes()` - Stash with validation
- `execute_rebase_on_main()` - Rebase with conflict detection
- `execute_apply_stash()` - Apply stash with validation
- `execute_create_mr()` - Create GitLab MR
- `execute_check_mr_status()` - Check MR status
- Composite: `execute_cleanup_orphaned_task()`, `execute_post_work_recovery()`

**Usage**:
```bash
source ~/.claude/utils/task_execute.sh
execute_reset_to_commit "task-1234" "abc123"  # Rolls back or FAILs
```

### shared_memory_updater.sh

**Cross-IDE communication backend** for shared memory entries.

Enables different IDE sessions to communicate via a shared file.

**Key functions:**
- `shared_memory_add()` - Add entry
- `shared_memory_list()` - List entries
- `shared_memory_mark_processed()` - Mark as done
- `shared_memory_read()` - Read entries

**Usage**:
```bash
source ~/.claude/utils/shared_memory_updater.sh
shared_memory_add "web" "Added authentication" "Implemented OAuth with Firebase"
```

---

## How Global Infrastructure Works

### Example: Task Spawning Workflow

```
User: "Implement authentication"
   ↓
Command: /project:spawn --model sonnet --prompt "..."
   ↓
task_spawn.sh:
  1. Generate task ID: task-1234
  2. Create patch file: ./.claude/patches/task-1234.yml
  3. Save context (model, prompt, branch, commit)
  4. Spawn new Sonnet instance
   ↓
Spawned Sonnet Session:
  1. Reads task from patch file
  2. Works autonomously
  3. Creates branch, commits work
  4. Updates patch file status
  5. Returns or crashes
   ↓
If crash detected:
  1. task_status.sh analyzes crash
  2. Determines scenario (pre-work, post-work, MR pending)
  3. task_execute.sh follows recovery procedure
  4. Validates each step
  5. Guides user through options
```

### Example: Session Continuity Workflow

```
Session 1 (Day 1):
  User: /project:resume         # Load previous session
  Work for 1 hour...
  User: /project:checkpoint     # Save progress
  Work continues...
  User: /project:handoff        # Save state before stopping
   ↓
Session 2 (Day 2):
  User: /project:resume         # Restores context from SESSION.md
  Claude: "Yesterday you completed X, Y, Z. Next: ..."
  Work continues from where we left off
```

### Example: Crash Recovery Workflow

```
User spawns task: task-1234
   ↓
Task spawned with work done but no MR created
Claude crashes mid-work
   ↓
User runs: /project:recover
   ↓
task_status.sh:
  1. Detects task-1234 from SESSION.md
  2. Reads patch file
  3. Analyzes git state (branch exists, 3 commits)
  4. Determines: "post_work_no_mr" scenario
  5. Recommends: ["create_mr", "review_work", "modify_approach"]
   ↓
User chooses: create_mr
   ↓
task_execute.sh:
  1. Execute: glab mr create ...
  2. Validate: MR created successfully
  3. Report: ✓ MR !123 created
```

---

## Custom Command Model Routing (CRITICAL RULE)

This repository enforces automatic model routing for all custom commands.

### The Rule

Every `.claude/commands/*.md` file has a `model:` field in its frontmatter:

```yaml
---
model: sonnet
---

# Command content
```

**When any Claude Code instance encounters a command:**

1. **Read the frontmatter** to extract the `model:` field
2. **Check current instance**: "Am I Sonnet?"
3. **Route appropriately**:
   - If `model: sonnet` and current = Sonnet → Execute directly
   - If `model: sonnet` and current = Haiku → Delegate via Task(model="sonnet")
   - If `model: sonnet` and current = Opus → Delegate via Task(model="sonnet")

### Example

```
Haiku working on git operations
   ↓
Encounters: /project:docs-build command (has model: sonnet)
   ↓
Haiku recognizes: "This requires Sonnet"
   ↓
Haiku delegates: Task(model="sonnet", prompt="...docs-build command...")
   ↓
Sonnet takes over and completes the docs build
```

### Why This Matters

- **Correct model for the job**: Complex commands get Sonnet, simple ones get Haiku
- **Cost optimization**: Don't waste Opus on simple tasks
- **Consistency**: Same command always uses same model
- **Autonomy**: Commands own their complete workflows

This rule is **MANDATORY** and documented in `CLAUDE.md`.

---

## Integration with Projects

### For Each Project

Create minimal project-local setup:

```bash
# Create project-local Claude Code directory
mkdir -p ./.claude/patches

# Copy SESSION.md template
cp ~/.claude/SESSION.md.template ./.claude/SESSION.md

# (Optional) Add project-specific examples
mkdir -p ./.claude/docs
# Add project-specific command examples
```

### Using Global Commands in Projects

All global commands work immediately in any project:

```bash
cd /path/to/project

/project:resume              # Load previous session
/project:checkpoint         # Save progress
/project:handoff            # Persist state for next

# And any other commands defined in ~/.claude/commands/
```

### Updating Global Infrastructure in Projects

When global infrastructure improves (bug fixes, new features):

```bash
cd ~/.claude
git pull origin main          # Update global setup

# All projects automatically benefit!
```

---

## Versioning & History

This repository is **version controlled via git** with full commit history.

### Viewing History

```bash
cd ~/.claude
git log --oneline --all
git show <commit>
git diff <commit1> <commit2>
```

### Key Commits

```
c6a4130 chore: initialize global claude code setup
  - Initial global infrastructure
  - All commands, utilities, documentation
  - Dual remotes (GitLab + GitHub)
```

### Contributing Improvements

Found a bug? Improved a utility? Make improvements and push:

```bash
cd ~/.claude
git add .
git commit -m "fix: improve error handling in task_spawn"
git push origin main
git push github main
```

All projects benefit immediately!

---

## File Sizes & Complexity

| File | Size | Complexity |
|------|------|-----------|
| `CLAUDE.md` | ~50KB | High (comprehensive rules) |
| `PLATFORM_INFRASTRUCTURE.md` | ~112KB | High (detailed guide) |
| `git_operations.sh` | ~8KB | Medium (25+ functions) |
| `patch_manager.sh` | ~6KB | Medium (patch lifecycle) |
| `task_status.sh` | ~10KB | Medium (state analysis) |
| `task_execute.sh` | ~12KB | Medium (atomic operations) |
| `task_spawn.sh` | ~5KB | Medium (task creation) |
| `task_recover.md` | ~4KB | Medium (orchestration) |

**Total**: ~200KB of infrastructure code

---

## Troubleshooting

### Problem: Commands not found

**Cause**: `~/.claude/` not properly initialized

**Solution**:
```bash
# Verify global setup
ls -la ~/.claude/commands/
ls -la ~/.claude/utils/

# Re-clone if needed
rm -rf ~/.claude
git clone https://gitlab.com/treyipune/global_claude_code_setup.git ~/.claude
```

### Problem: Permission denied when pushing

**Cause**: SSH keys not configured

**Solution**:
```bash
cd ~/.claude
git remote set-url origin https://gitlab.com/treyipune/global_claude_code_setup.git
git push origin main
```

### Problem: Patch files not being created

**Cause**: Project `./.claude/patches/` directory missing

**Solution**:
```bash
mkdir -p ./.claude/patches
```

### Problem: Task recovery not working

**Cause**: SESSION.md doesn't exist or is malformed

**Solution**:
```bash
# Check SESSION.md
cat ./.claude/SESSION.md

# Copy template if missing
cp ~/.claude/SESSION.md.template ./.claude/SESSION.md
```

---

## FAQ

**Q: Do I need to manage `~/.claude/` as a git repo?**
A: Yes! It's already initialized as a git repo when cloned. Just keep it updated with `git pull`.

**Q: Can I modify global commands for my projects?**
A: You can override them in `./.claude/commands/` locally, but improvements should be pushed to `~/.claude/` so all projects benefit.

**Q: What if two projects need different command behavior?**
A: Create a project-local version in `./.claude/commands/` that overrides the global one. Better: fix the global version!

**Q: How do I share this with other developers?**
A: They clone the same repository:
```bash
git clone https://gitlab.com/treyipune/global_claude_code_setup.git ~/.claude
```

**Q: Is `.claude/` version controlled in projects?**
A: No! `./.claude/` (project-local) is typically gitignored. `~/.claude/` (global) IS version controlled.

**Q: What's the difference between `.claude/` and `~/.claude/`?**
A: `./.claude/` = project-local state (SESSION.md, patches, notes)
`~/.claude/` = global infrastructure (commands, utilities, documentation)

**Q: Can I use this on Windows?**
A: These are bash scripts, so you'll need WSL2 or Git Bash. Not tested on Windows natively.

**Q: How often should I pull updates?**
A: Whenever you start a new session or when significant improvements are merged. At minimum, monthly.

---

## Next Steps

### For New Setup
1. ✅ Clone repository: `git clone https://gitlab.com/treyipune/global_claude_code_setup.git ~/.claude`
2. ✅ Verify: `ls ~/.claude/` shows all files
3. ✅ Create project setup: `mkdir -p ./.claude/patches`
4. ✅ Start using: `/project:resume` in any project

### For Improvements
1. Identify improvement needed
2. Make change in `~/.claude/`
3. Test in a project
4. Commit: `git commit -m "..."`
5. Push: `git push origin main && git push github main`

### For New Features
1. Design in PLATFORM_INFRASTRUCTURE.md
2. Implement utilities in `utils/`
3. Create command in `commands/`
4. Add to CLAUDE.md if it's a rule
5. Commit and push

---

## Resources

| Document | Location | Purpose |
|----------|----------|---------|
| **Global Rules** | `CLAUDE.md` | Universal standards (SOLID, clean code, model routing) |
| **Platform Guide** | `PLATFORM_INFRASTRUCTURE.md` | Complete infrastructure documentation |
| **Session Template** | `SESSION.md.template` | Standard project session format |
| **This README** | `README.md` | Overview and usage guide |

---

## Repositories

- **GitLab (Primary)**: https://gitlab.com/treyipune/global_claude_code_setup
- **GitHub (Mirror)**: https://github.com/treyidev/global_claude_code_setup

Both are kept in sync. Use whichever fits your workflow.

---

## License

These instructions and infrastructure are part of your personal development workflow. Use as needed across all your projects.

---

## Questions?

Refer to `PLATFORM_INFRASTRUCTURE.md` for detailed documentation or check `CLAUDE.md` for specific rules.

