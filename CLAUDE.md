# Claude Code Global Directives

> Universal standards for Abhijit Bandyopadhyay's projects.
> 25+ years software development | M2 Max 96GB | Privacy-first

---

## Identity

- **Author**: Abhijit Bandyopadhyay <abhijitb@gmail.com>
- **Git**: NO Co-Authored-By Claude - NEVER add AI attribution
- **Philosophy**: Local-first, privacy-conscious solutions

---

## Custom Command Model Routing (CRITICAL - ENFORCE ALWAYS)

**MANDATORY: This rule applies to ALL Claude Code instances, regardless of current task.**

When you encounter ANY custom command invocation (any `.claude/commands/*.md` or `.claude/commands/*.sh` file):

### Protocol

1. **Read the command file frontmatter** (YAML header at top of file)
2. **Extract the `model:` field** (e.g., `model: sonnet`, `model: haiku`)
3. **Check if current instance model matches** (e.g., "Am I Sonnet?" vs `model: sonnet`)

### Routing Decision

| Situation | Action |
|-----------|--------|
| Current model = `model:` field | Execute command directly in this instance |
| Current model ≠ `model:` field | **Delegate via Task tool** |

### Delegation Format

If delegating to correct model:

```
Task(
  model="<model_from_frontmatter>",
  subagent_type="general-purpose",
  description="<command description>",
  prompt="<command instructions from file>"
)
```

### Examples

**Example 1: /docs-build (model: sonnet)**
```
Current: Haiku working on git operations
Encounter: /docs-build command
Action: Task(model="sonnet", ...) → Sonnet takes over docs-build
```

**Example 2: /project:commit (model: sonnet)**
```
Current: Haiku checking file syntax
Encounter: /project:commit command
Action: Task(model="sonnet", ...) → Sonnet handles commit with analysis
```

**Example 3: /project:resume (model: sonnet)**
```
Current: Sonnet building feature
Encounter: /project:resume command
Action: Execute directly (model matches) → Sonnet loads session context
```

### Why This Matters

- **Commands own their workflows**: /docs-build is Sonnet because it needs semantic understanding
- **Context preservation**: Correct model has right reasoning capability
- **Cost optimization**: Don't waste Opus on simple tasks, don't skimp on complex ones
- **Consistency**: Same command always uses same model, regardless of caller

### CRITICAL ENFORCEMENT

- ❌ DO NOT assume "I'll just run this since I'm here"
- ✅ DO read frontmatter and route appropriately
- ❌ DO NOT skip this because "it might work anyway"
- ✅ DO enforce this 100% of the time - no exceptions

---

## SOLID Principles (Strictly Enforced)

| Principle | Meaning | Violation Sign |
|-----------|---------|----------------|
| **S**ingle Responsibility | One reason to change | Class has multiple unrelated methods |
| **O**pen/Closed | Extend, don't modify | Changing existing code to add features |
| **L**iskov Substitution | Subtypes are substitutable | Override changes behavior unexpectedly |
| **I**nterface Segregation | Specific over general | Interface with unused methods |
| **D**ependency Inversion | Depend on abstractions | Concrete class in constructor |

### SRP Example
```python
# WRONG - Multiple responsibilities
class ReportGenerator:
    def generate(self, data): ...
    def save_to_file(self, path): ...      # File I/O responsibility
    def send_email(self, recipient): ...   # Email responsibility
    def format_as_pdf(self): ...           # Formatting responsibility

# CORRECT - Single responsibility each
class ReportGenerator:
    def generate(self, data) -> Report: ...

class ReportSaver:
    def save(self, report: Report, path: Path): ...

class ReportEmailer:
    def send(self, report: Report, recipient: str): ...
```

### DI Example
```python
# WRONG - Depends on concrete class
class UserService:
    def __init__(self):
        self.repo = PostgresUserRepository()  # Concrete!

# CORRECT - Depends on abstraction
class UserService:
    def __init__(self, repo: UserRepository):  # Abstract!
        self.repo = repo
```

---

## Clean Code Rules (Non-Negotiable)

| Rule | Violation | Correct |
|------|-----------|---------|
| No global functions | `def create_grid():` | `class GridFactory:` |
| No hardcoded values | `timeout=30` | `TIMEOUT_SECONDS = 30` |
| No magic numbers | `if x > 86400:` | `if x > SECONDS_PER_DAY:` |
| No star imports | `from typing import *` | `from typing import List, Dict` |
| No circular deps | A imports B, B imports A | Unidirectional flow |
| Fail-fast | `return None` on error | `raise ValueError(...)` |

### Fail-Fast Example
```python
# WRONG - Silent failure
def get_user(user_id: str) -> Optional[User]:
    user = db.find(user_id)
    if not user:
        return None  # Caller doesn't know WHY
    return user

# CORRECT - Fail-fast with context
def get_user(user_id: str) -> User:
    if not user_id:
        raise ValueError("user_id cannot be empty")
    
    user = db.find(user_id)
    if not user:
        raise UserNotFoundError(f"No user with id: {user_id}")
    
    return user
```

---

## Architecture Principles

**Managers delegate. Workers work. Data is passive.**
```
Coordinator → "I know WHO to ask, not HOW"
    ↓
Dispatcher  → "I know WHICH worker, not HOW it works"
    ↓
Leaf Worker → "I DO the actual work"
    ↓
Data        → Passive, immutable
```

### Example
```python
# WRONG - Coordinator does filtering (leaf work)
class Detector:
    def find(self, items):
        filtered = [i for i in items if i.type == self.type]  # NO!
        return self.matcher(filtered)

# CORRECT - Coordinator delegates, worker filters
class Detector:
    def find(self, items):
        return self.matcher(items)  # Delegate ALL

class TypeMatcher:  # Worker does the filtering
    def __call__(self, items):
        return [i for i in items if i.type == self.type]
```

→ Deep patterns: `~/.claude/reference/architecture.md`

---

## Documentation Requirements

| Element | Required | Notes |
|---------|----------|-------|
| Summary | Always | One-line, ends with period |
| Description | Always | Detailed behavior |
| Args/Parameters | Always | Type, purpose, valid values |
| Returns | Always | Including edge cases |
| Raises | If applicable | Conditions for each |
| Example | Always | Runnable code |
| Reasoning | Non-trivial | WHY this approach |
| Limitations | Always | Boundaries, constraints |

### Documentation Quality (Inline Examples)
```python
# ❌ UNACCEPTABLE - Will be rejected in review
def process(data):
    """Process the data."""
    pass


# ❌ INSUFFICIENT - Needs more detail
def process(data: List[Item]) -> Result:
    """
    Process a list of items.
    
    Args:
        data: Items to process.
    
    Returns:
        Processing result.
    """
    pass


# ✅ REQUIRED - Minimum acceptable standard
def process(data: List[Item], strict: bool = False) -> ProcessResult:
    """
    Process items with optional strict validation.

    Iterates through items, applies transformations, and aggregates
    results. Uses fail-soft approach by default.

    Args:
        data: Items to process. Empty list returns empty result.
            Each item must have 'id' and 'value' attributes.
            Maximum recommended batch: 10,000 items.
        strict: Validation mode.
            - False (default): Collect failures, continue.
            - True: Raise on first failure.

    Returns:
        ProcessResult containing:
        - successful: List of transformed items (order preserved)
        - failed: List of (item, error) tuples
        - stats: Dict with 'total', 'succeeded', 'failed'

    Raises:
        ProcessingError: In strict mode, when any item fails.
        ValueError: If data is None (use empty list instead).

    Reasoning:
        Fail-soft default because batch processing typically
        tolerates partial failure and allows inspection of
        all failures in one run.

    Limitations:
        - Max practical batch: 10,000 items (memory)
        - Sequential processing; see ProcessorPool for parallel
        - Not thread-safe

    Example:
        >>> items = [Item(id=1, value="a"), Item(id=2, value="b")]
        >>> result = process(items)
        >>> print(f"Processed {len(result.successful)} items")
        Processed 2 items

        >>> # Handle failures
        >>> for item, error in result.failed:
        ...     logger.warning(f"Item {item.id}: {error}")

    See Also:
        - process_single: For single-item processing
        - ProcessorPool: For parallel processing
    """
    pass
```

→ More templates: `~/.claude/reference/documentation-standards.md`

---

## Python Standards

### Type Hints (Required)
```python
# CORRECT - Use typing module
from typing import Any, Dict, List, Optional, Tuple, Union

def process(
    items: List[Item],
    config: Optional[Config] = None,
) -> ProcessResult:
    ...

# WRONG - Don't use builtin generics (enforce typing module)
def process(items: list[Item], config: Config | None = None) -> ProcessResult:
    ...  # NO!
```

### Imports (Explicit, Grouped, Sorted)
```python
# Standard library
from pathlib import Path
from typing import Dict, List, Optional

# Third-party
from pydantic import BaseModel, Field

# Local
from myproject.domain import User
from myproject.repository import UserRepository
```

### Properties Over Getters
```python
# ❌ Java-style
class User:
    def get_full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"

# ✅ Pythonic
class User:
    @property
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"
```

---

## Kotlin Standards

### Null Safety (Required)
```kotlin
// ✅ CORRECT - Explicit nullability
fun findUser(id: String): User?  // May return null
fun getUser(id: String): User    // Never returns null, throws if not found

// ✅ CORRECT - Safe calls and elvis
val name = user?.profile?.displayName ?: "Anonymous"

// ❌ WRONG - Forcing non-null without check
val name = user!!.name  // Avoid !! unless absolutely certain
```

### Data Classes (Prefer)
```kotlin
// ✅ CORRECT - Immutable data class
data class User(
    val id: String,
    val name: String,
    val email: String,
)

// ❌ WRONG - Mutable with var
data class User(
    var id: String,    // NO! Use val
    var name: String,
)
```

### Extension Functions (Idiomatic)
```kotlin
// ✅ CORRECT - Extend existing types
fun String.toSlug(): String =
    this.lowercase().replace(" ", "-")

// Usage
val slug = "Hello World".toSlug()  // "hello-world"
```

### Coroutines (Structured)
```kotlin
// ✅ CORRECT - Structured concurrency
suspend fun fetchData(): Data = coroutineScope {
    val user = async { fetchUser() }
    val posts = async { fetchPosts() }
    Data(user.await(), posts.await())
}

// ❌ WRONG - GlobalScope (unstructured)
GlobalScope.launch { ... }  // NO! Use structured scope
```

---

## C++ Standards

### Memory Management (RAII)
```cpp
// ✅ CORRECT - Smart pointers
auto user = std::make_unique<User>("Alice");
auto shared = std::make_shared<Config>();

// ❌ WRONG - Raw new/delete
User* user = new User("Alice");  // NO! Memory leak risk
delete user;
```

### Const Correctness (Required)
```cpp
// ✅ CORRECT - Const where possible
class UserService {
public:
    const User& getUser(const std::string& id) const;
    void updateUser(const User& user);  // Takes const ref
};

// ❌ WRONG - Missing const
User& getUser(std::string id);  // Non-const, copies string
```

### Modern C++ (C++17/20)
```cpp
// ✅ CORRECT - Structured bindings
auto [name, age, email] = getUser();

// ✅ CORRECT - std::optional for nullable
std::optional<User> findUser(const std::string& id);

// ✅ CORRECT - Range-based for
for (const auto& item : items) { ... }

// ❌ WRONG - C-style
for (int i = 0; i < items.size(); i++) { ... }  // Prefer range-based
```

### Error Handling
```cpp
// ✅ CORRECT - Exceptions for errors, optional for absence
std::optional<User> findUser(const std::string& id);  // May not exist
User getUser(const std::string& id);  // Throws if not found

// ✅ CORRECT - noexcept where guaranteed
void swap(User& a, User& b) noexcept;
```

---

## Java Standards

### Null Handling (Required)
```java
// ✅ CORRECT - Optional for nullable returns
public Optional<User> findUser(String id) {
    return Optional.ofNullable(repository.find(id));
}

// ✅ CORRECT - @Nullable/@NonNull annotations
public void process(@NonNull String input, @Nullable Config config) { }

// ❌ WRONG - Returning null without indication
public User findUser(String id) {
    return null;  // NO! Use Optional
}
```

### Immutability (Prefer)
```java
// ✅ CORRECT - Immutable with records (Java 16+)
public record User(String id, String name, String email) {}

// ✅ CORRECT - Final fields, no setters
public final class User {
    private final String id;
    private final String name;

    public User(String id, String name) {
        this.id = id;
        this.name = name;
    }
}

// ❌ WRONG - Mutable bean
public class User {
    private String id;
    public void setId(String id) { this.id = id; }  // NO!
}
```

### Streams (Idiomatic)
```java
// ✅ CORRECT - Stream API for collections
List<String> names = users.stream()
    .filter(User::isActive)
    .map(User::getName)
    .collect(Collectors.toList());

// ❌ WRONG - Manual iteration for transformations
List<String> names = new ArrayList<>();
for (User user : users) {
    if (user.isActive()) {
        names.add(user.getName());
    }
}
```

### Dependency Injection
```java
// ✅ CORRECT - Constructor injection
public class UserService {
    private final UserRepository repository;

    public UserService(UserRepository repository) {
        this.repository = repository;
    }
}

// ❌ WRONG - Field injection
public class UserService {
    @Inject
    private UserRepository repository;  // Harder to test
}
```

---

## File Organization

### Domain-Driven (Required)
```
# ✅ CORRECT - Organized by domain
dialogue/
├── blocks/          # Domain: Atomic elements
│   ├── speech.py
│   └── pause.py
├── script/          # Domain: Structure & loading
│   └── loader.py
└── converter/       # Domain: Format conversion
    └── ssml.py

# ❌ WRONG - Organized by type
src/
├── models/          # All models dumped here
├── services/        # All services dumped here
└── utils/           # Catch-all garbage
```

### Forbidden File Names

- `utils.py` / `helpers.py` / `common.py` / `misc.py`
- Use descriptive names: `string_formatting.py`, `validation_rules.py`

---

## Git Conventions
```bash
# Format
<type>: <description>

# Types
feat     # New feature
fix      # Bug fix
docs     # Documentation only
refactor # Code change (no fix/feature)
test     # Adding tests
chore    # Maintenance

# Examples
feat: add blink animation for Eye component
fix: clamp eyelid openness to valid range
refactor: extract pupil tracking to separate class

# NEVER
Co-Authored-By: Claude  # NEVER add this
```

→ Full workflow: `~/.claude/reference/workflow.md`

---

## Model Selection

| Complexity | Model | Use For |
|------------|-------|---------|
| Low | Haiku | Git ops, `glab` commands, `gh` commands, scaffolding, rendering, formatting |
| Medium | Sonnet | Implementation, debugging, refactoring |
| High | Opus | Architecture, design decisions, algorithms |

**Note**: All GitLab (`glab`) and GitHub (`gh`) CLI operations should use Haiku - they're simple command execution, not complex reasoning.

### ⚠️ CRITICAL: Haiku Delegation Rule (PERMANENT)

```
┌─────────────────────────────────────────────────────────────────────┐
│  UNIVERSAL RULE FOR ALL PROJECTS - ALL MACHINES                     │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ❌ FORBIDDEN: Bash(command="...")                                  │
│  ✅ REQUIRED:  Task(model="haiku", subagent_type="Bash", ...)      │
│                                                                     │
│  ALL shell commands MUST be delegated to Haiku via Task tool.      │
│                                                                     │
│  Applies to:                                                        │
│  - Git operations (status, add, commit, push, pull, log, diff)     │
│  - File operations (ls, find, cat, grep, head, tail)               │
│  - Build operations (npm, pnpm, yarn, poetry, cargo, make)         │
│  - Test operations (pytest, jest, vitest, cargo test)              │
│  - Lint operations (eslint, ruff, clippy, prettier)                │
│  - ANY shell command execution whatsoever                           │
│                                                                     │
│  Why this is mandatory:                                             │
│  1. Keeps Opus context window clean (10x cost reduction)           │
│  2. Follows documented model routing strategy                      │
│  3. Consistent behavior across all projects                        │
│  4. Enables proper cost optimization                               │
│                                                                     │
│  NO EXCEPTIONS. NO "QUICK COMMANDS". ALWAYS DELEGATE.              │
│                                                                     │
│  If you catch yourself using Bash tool: STOP and delegate.         │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Code Review Stance

### Push Back When:

| Comment | Response |
|---------|----------|
| "Could use specific exceptions" | "What concrete bug does this fix?" |
| "Add soft failure mode" | "Fail-fast is correct. Silent failures are worse." |
| "Extract to separate class" | "One-time code. Abstraction adds complexity." |
| "More flexible for future" | "YAGNI. Add when actually needed." |

### Questions to Ask:

1. **What breaks if we don't fix this?** If nothing, skip it.
2. **Does this violate YAGNI?** Don't add for hypotheticals.
3. **Cost/benefit ratio?** 300 lines for marginal benefit = over-engineering.

**Exception**: Documentation is NEVER over-engineering.

---

## Universal Anti-Patterns
```python
# ❌ Star imports
from typing import *

# ❌ Catch-all silently
try:
    risky_operation()
except:
    pass

# ❌ Suppress warnings without reason
import warnings
warnings.filterwarnings("ignore")

# ❌ God class
class ApplicationManager:  # Does everything
    def handle_users(self): ...
    def process_orders(self): ...
    def send_emails(self): ...
    def generate_reports(self): ...
    def manage_cache(self): ...

# ❌ Circular dependency
# file_a.py
from file_b import B  # B imports A

# ❌ Clever over readable
result = [x for x in (y for y in data if y.active) if x.valid][:10]
# vs
active_items = [item for item in data if item.active]
valid_items = [item for item in active_items if item.valid]
result = valid_items[:10]
```

---

## Exception Hierarchy
```python
# Define domain-specific exceptions
class ProjectError(Exception):
    """Base exception for project."""

class ConfigError(ProjectError):
    """Configuration-related errors."""

class ValidationError(ProjectError):
    """Validation-related errors."""

class NotFoundError(ProjectError):
    """Resource not found errors."""

# Usage
raise ConfigError(f"Invalid config key: {key}")
raise NotFoundError(f"User not found: {user_id}")
```

---

## Claude Global Custom Commands & Platform Infrastructure

**Location:** `~/.claude/` - Reusable across ALL projects

### Session Management Commands (GLOBAL)

**Location:** `~/.claude/commands/` (Global, reusable across ALL projects)

These commands manage session state and continuity. They read/write to **project-local** `./.claude/SESSION.md` but the command implementations live globally.

| Command | When | What It Does | Model |
|---------|------|--------------|-------|
| `/project:resume` | Session start | Load context from `./.claude/SESSION.md` (previous session) | Sonnet |
| `/project:checkpoint` | Every 30-45 mins | Save progress mid-session WITHOUT stopping | Sonnet |
| `/project:handoff` | Before stopping | Persist full state for next session | Sonnet |

**Example Workflow:**
```bash
# Session 1: Work and save progress
/project:resume              # Load context from previous session
# ... work for 30-45 mins
/project:checkpoint         # Save progress, continue working
# ... more work
/project:handoff            # Save state before closing

# Session 2: Next day
/project:resume             # Restores context from ./.claude/SESSION.md
# ... continue from where we left off
```

**Key Points:**
- ✅ Commands are **global** (in `~/.claude/commands/`)
- ✅ State is **project-local** (in `./.claude/SESSION.md`)
- ✅ All projects use the same session system
- ✅ Each project maintains its own SESSION.md
- ✅ Seamless context preservation across sessions

### Task Spawning & Crash Recovery Commands

**Spawn hierarchical subtasks when you encounter blocking work:**

```bash
# Minimal interface - just model and prompt
./.claude/commands/task_spawn.sh \
  --model "sonnet" \
  --prompt "Your task description"

# Optional: branch-aware (creates git branch + GitLab issue)
./.claude/commands/task_spawn.sh \
  --model "sonnet" \
  --prompt "Your task" \
  --branch-aware

# Optional: nest under parent task
./.claude/commands/task_spawn.sh \
  --model "haiku" \
  --prompt "Subtask" \
  --parent-task "task-1234"
```

**Recovery from crash:**

When Claude crashes during spawned task, run:
```bash
/project:recover
```

This command:
1. **Detects** what happened (via bash utilities with JSON state report)
2. **Analyzes** scenario (pre-work crash vs post-work vs MR pending)
3. **Guides** user through recovery options
4. **Executes** recovery with zero-tolerance validation
5. **Validates** each step before proceeding

**Scenarios Handled:**
- **Pre-work crash:** Task spawned but no work started → Retry/modify/cancel
- **Post-work crash:** Work done but MR not created → Create MR/review/restart
- **MR pending:** MR created but not merged → Check status/await/address feedback
- **MR merged:** Work merged, main task rebases → Course correction options

**Architecture:**
- **Bash utilities** (5 files, ~50 functions):
  - `git_operations.sh` - Git operations (25+ functions)
  - `patch_manager.sh` - Patch file management
  - `task_status.sh` - Crash detection & scenario analysis
  - `task_execute.sh` - Execution with validation
  - `shared_memory_updater.sh` - Cross-IDE communication

- **LLM orchestration** (`task_recover.md`):
  - Minimal: detect → analyze → guide → execute
  - Calls bash utilities for actual work
  - Fail-hard on validation errors

### Shared Memory (Cross-IDE Communication)

```bash
# Add note accessible from other IDE sessions
~/.claude/commands/shared-memory/cmd.sh add \
  --from web \
  --hint "What changed" \
  --content "Description..."

# List all notes
~/.claude/commands/shared-memory/cmd.sh list

# Mark as processed
~/.claude/commands/shared-memory/cmd.sh done <id>
```

### Global vs Project-Local

**Global `~/.claude/`** (Platform infrastructure, reusable):
```
commands/
├── resume.md                    # Session resume
├── checkpoint.md                # Session checkpoint
├── handoff.md                   # Session handoff
├── task_spawn.sh                # Task spawn
├── task_recover.md              # Crash recovery
└── shared-memory/cmd.sh         # Shared memory

utils/
├── git_operations.sh            # Git utilities
├── patch_manager.sh             # Patch lifecycle
├── task_status.sh               # Crash detection
├── task_execute.sh              # Execution + validation
└── shared_memory_updater.sh     # Shared memory backend
```

**Project-local `./.claude/`** (Project-specific):
```
SESSION.md                       # Session state (respects global format)
patches/                         # Task patch files
docs/                           # Project examples & docs
```

### Full Documentation

See `~/.claude/PLATFORM_INFRASTRUCTURE.md` for comprehensive documentation of:
- All commands with detailed usage
- Architecture and design principles
- Utilities reference
- Testing & troubleshooting

---

## Session Lifecycle (IMPORTANT)

Claude Code sessions are stateless. Use these **global commands** to maintain continuity:

| Command | When | Purpose | Location |
|---------|------|---------|----------|
| `/project:resume` | **Session start** | Load previous context from `./.claude/SESSION.md` | `~/.claude/commands/resume.md` |
| `/project:checkpoint` | **Every 30-60 mins** | Save progress, verify patterns | `~/.claude/commands/checkpoint.md` |
| `/project:handoff` | **Before stopping** | Persist state for next session | `~/.claude/commands/handoff.md` |

**Note:** Commands are GLOBAL (in `~/.claude/`) but they read/write project-local state (`./.claude/SESSION.md`)

### Proactive Prompting Rules

**At session start** (no prior context visible):
- If `.claude/SESSION.md` exists but hasn't been mentioned → Suggest: "I see a SESSION.md from a previous session. Would you like me to `/project:resume` to restore context?"
- If starting fresh with no context → Ask: "What would you like to work on today?"

**During extended work** (after ~30-45 minutes of continuous work):
- Suggest: "We've been working for a while. Would you like to `/project:checkpoint` to save progress?"

**At natural milestones** (feature complete, tests passing, ready to commit):
- Suggest: "Good milestone reached. Consider `/project:checkpoint` before continuing."

**When user says goodbye/stopping/break/lunch/EOD**:
- Prompt: "Before you go, let me run `/project:handoff` to save our progress for next time."
- If user declines, respect it but note: "No problem. Note that context may be lost without handoff."

**When context seems unclear** (user asks "where were we?" or Claude is uncertain):
- Suggest: "Let me check `.claude/SESSION.md` for context" or "Would `/project:resume` help restore context?"

**When detecting pattern drift** (own code violating CLAUDE.md rules):
- Self-correct and suggest: "I notice I may have drifted from patterns. Running a mental `/project:checkpoint` to realign."

### Session Files

| File | Purpose |
|------|---------|
| `.claude/SESSION.md` | Handoff state (written by `/project:handoff`) |
| `.claude/JOURNAL.md` | Historical log (optional, append-only) |

### Never Assume Prior Context

Unless SESSION.md has been read or user provides context, assume this is a fresh start. Don't pretend to remember previous sessions.

---

## Reference Files **MANDATORY**

| Need | Read |
|------|------|
| Architecture patterns (layered, pipeline, emitter) | `~/.claude/reference/architecture.md` |
| Feature workflow (epic→branch→PR) | `~/.claude/reference/workflow.md` |
| Code standards (all languages) | `~/.claude/reference/code-standards.md` |
| Documentation templates | `~/.claude/reference/documentation-standards.md` |


## Documentation Discipline

When completing any feature:

1. **Before MR**: Run `/project:sync-docs`
2. **In commit**: Include CLAUDE.md updates in same commit as code
3. **In MR description**: Note what documentation was updated

### Triggers for CLAUDE.md Updates

| Change | Action |
|--------|--------|
| New public API | Add to package CLAUDE.md |
| Move file between packages | Update both package CLAUDE.md files |
| New pattern (used 2+ times) | Add BAD/GOOD example to root |
| Deprecate API | Remove or mark deprecated |
| New command | Add to commands reference |
| Config change | Update config section |