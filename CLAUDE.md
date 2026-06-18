# Claude Code Global Directives

> Universal standards for Abhijit Bandyopadhyay's projects.
> 25+ years software development | M2 Max 96GB | Privacy-first

---

## Identity

- **Author**: Abhijit Bandyopadhyay <abhijitb@gmail.com>
- **Git**: NO Co-Authored-By Claude - NEVER add AI attribution
- **Philosophy**: Local-first, privacy-conscious solutions

---

## Instruction architecture (how these standards are organized — our way)

Standards are tiered by **how they load**, to keep this always-on file lean while keeping rules
enforced. Put new guidance in the right tier:

1. **Always-on core — this `CLAUDE.md`.** Cross-language *principles*: SOLID, clean code,
   architecture, reuse-first, documentation discipline, review stance, git — plus a 3-line
   *core* per language (see *Language standards*). Loaded every session, so keep it lean:
   principles and non-negotiables, not deep per-language syntax. (An example here may use one
   language to illustrate a *universal* rule — the rule is what's universal.)
2. **Path-scoped rules — `~/.claude/rules/<topic>.md` with `paths:` frontmatter.** Deep,
   language- or domain-specific guidance. The harness loads these **deterministically and
   on-demand** — only when Claude reads/edits a file matching the glob (e.g. `rules/python.md`'s
   `paths: ["**/*.py"]` loads only when touching Python). This is how language standards stay
   *mandatory* without bloating always-on context — no skill to forget, no model judgment.
   User-level (`~/.claude/rules/`) applies to every project; a project can add/override via its
   own `.claude/rules/`. **Edge case:** rules trigger on *reading* a matching file; a brand-new
   file written without a prior read may not trigger — tier 1's 3-line core covers that, and a
   tier-3 hook can close it.
3. **Hooks — `~/.claude/settings.json`.** Deterministic *enforcement* + tooling: run a
   formatter/linter on write (we run `PostToolUse: Write(*.py) → ruff`), or inject a rule for the
   brand-new-file case above. Global hooks fire in every project; they can match tools
   (`Write|Edit`), inspect the file path, inject context, or block.
4. **Skills — `.claude/commands/*.md`.** Optional, multi-step *workflows* the user/model invokes
   (`/review-backend`, `/handoff`, `/sync-docs`). **NOT for passive always-apply standards** —
   skill invocation is model-driven and best-effort, so a standard buried in a skill gets
   silently missed. A standard is a *rule* (declarative, auto-loaded); a procedure is a *skill*.

**Routing new guidance:** cross-language principle → here · language/stack syntax →
`rules/<lang>.md` (`paths:`) · must-run tooling / hard block → a hook · a chosen workflow → a
skill. **Adding a language?** Create `~/.claude/rules/<lang>.md` with its `paths:` glob and add a
3-line core to *Language standards* below.

---

## Custom Command / Skill Model Selection

Slash commands and skills live in `.claude/commands/*.md` (project + global); they are invoked
via the **Skill tool** and run **in the main conversation**. Claude Code **honors a `model:`
field in a command's frontmatter** — the command runs on that model automatically.

**This supersedes the old "read the frontmatter, and if your model ≠ the command's, delegate via
the `Task` tool" protocol** — that was a manual workaround for a prior setup and is now obsolete:
you don't hand-route models per command, and there is no `subagent_type="Bash"`.

- **Make a command run on a specific model:** set `model:` in its frontmatter — `model: sonnet`
  for mechanical / scaffolding / git commands; `model: opus` for architecture / design /
  algorithms. Keep the command body focused so it runs well on that tier.
- **Offload a command's heavy or independent work to a cheaper model for cost:** use the
  Agent/Task tool with a `model` override — same mechanism as *Delegating shell work to Sonnet*
  (under Model Selection, below).
- **Session-wide model control** is the harness's job (`/model`, fast mode), not per-command
  delegation.

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
| No star imports | `from typing import *` | `from typing import Any, Protocol` |
| No circular deps | A imports B, B imports A | Unidirectional flow |
| Fail-fast | `return None` on error | `raise ValueError(...)` |

### Fail-Fast Example
```python
# WRONG - Silent failure
def get_user(user_id: str) -> User | None:
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

## Reuse-First Discipline (CRITICAL — ENFORCE BEFORE WRITING ANY NEW CLASS)

**Before writing a new class, behavior, animation, component, utility, or service, audit
the existing codebase for reusable infrastructure. Reuse maximally. If reuse forces a
code smell or architectural degradation, FLAG IT to the user before proceeding — never
silently invent a parallel hierarchy and never silently bend existing infrastructure to
fit a wrong shape.**

### The Three-Step Audit (mandatory, in this order)

1. **Inventory the reusable surface.** Identify the conceptual slot the new code occupies
   (e.g. "rhythmic scaling synced to a pulse"), then list every existing class/protocol
   in the dependency-pointed-at packages (libraries, sibling packages, the package being
   extended) that occupies that slot. Cite file paths.

2. **Trace the integration path concretely.** For each candidate, write the import + call
   that would integrate it. Read the candidate's source far enough to confirm:
   - The protocol/contract surface it expects (methods, properties, types).
   - Whether the target object already conforms (or trivially can — e.g. via inheritance).
   - Whether composition is clean or requires conditional/`hasattr` branching.

3. **Validate premises with code, not memory.** If the design hinges on a claim like
   "the target doesn't have X", verify it from the current source — config files,
   wirers, factories, defaults — not from prior conversations or assumptions. **A
   wrong premise discovered after writing the code is a design bug; a wrong premise
   caught during audit is a saved hour.**

### Smell Detection — Flag Before Fixing

The bar to flag is intentionally low. If the cleanest reuse path requires ANY of the
following, stop and surface to the user before continuing:

- A new `hasattr` / `isinstance` branch to dispatch around an interface mismatch.
- A subclass that overrides 3+ methods just to change one semantic.
- A string ↔ enum bridge in more than one place.
- A monkey-patch or attribute injection on the imported class.
- A workaround comment longer than three lines.
- A "playground-side" class that duplicates the existing one's logic with worse semantics
  to dodge a (real or imagined) collision.
- A composition where the imported class's preconditions would be violated.

**The flag is the deliverable.** Name the smell concretely, name the alternative concretely,
ask which to take. Do not ship a silent workaround.

### Quantify Before You Defend

When proposing reuse vs. fresh-write, quantify the difference: lines of new code, classes
added, surface area introduced, drift risk. "150 lines of new code becomes 80, all mechanics
visuals-owned and battle-tested" is the right shape. "It's cleaner this way" is not.

### When Fresh-Write IS Correct

Reuse is the default, not the law. Writing a new class IS correct when:

- The existing class's contract genuinely doesn't fit the target's anatomy (e.g.
  `LookAt(pupil)` on a creature with no pupil — a real anatomical asymmetry).
- The reuse path requires bending the imported class's preconditions.
- A protocol can be conformed-to but the resulting object would be semantically wrong.

In every such case, the decision still gets flagged so the user can confirm the
asymmetry is intended.

### Why This Matters

- Every duplicated class is future drift waiting to happen — when the original evolves,
  the duplicate ages out silently.
- Every silent workaround is a comment-without-a-comment — the next reader can't tell
  it was a deliberate choice vs. an accident.
- Every wrong-premise design is debugging time spent later that could have been
  five minutes of audit now.
- Pattern discipline compounds: when reuse is the visible default, future contributors
  follow the same discipline.

---

## Documentation Standards

Universal documentation discipline that applies across every project, every language, every stack. Stack-specific tooling (linters, AST checks, examples) lives in each project's CLAUDE.md and **extends** these principles; this section is the source of truth.

### Core principle

- **Documentation captures context the code cannot express.** Code shows WHAT and HOW; documentation explains WHY, WHERE, WHEN.
- **Three universal failure modes** to detect and reject:
  1. **Structurally adequate, contextually empty** — every required field is present, none of them tells the reader anything they couldn't infer from the signature.
  2. **WHAT-narration instead of WHY-explanation** — restating what the code does in English instead of explaining why it does it that way.
  3. **Stale docs** — docstrings that once matched the code and silently drifted. Worse than no docs: actively misleading.

### Universal content requirements

**Module / file documentation** (any language):

| Element | Required | Why |
|---|---|---|
| Why this exists | Always | Problem solved; rejected alternatives if non-obvious. |
| Design decisions | Always | The reasoning behind structural choices that future maintainers will second-guess. |
| Where it fits in the system | Always | Upstream / downstream / siblings. Spatial orientation for the reader. |
| Limitations with mitigations | Always | Boundaries and recovery paths — not just "this doesn't do X" but "for X, use Y". |
| Future evolution markers | Always for new modules | SAFE EXTENSIONS (where the design tolerates change) and REGRESSIONS TO AVOID (paths that look reasonable but would break the model). |

**Class / type documentation:**

| Element | Required | Why |
|---|---|---|
| Purpose / role | Always | What slot does this class occupy in the architecture? |
| Lifecycle | Always | Instantiation, destruction, invariants between calls. |
| Non-obvious design decisions | Always | Especially if rejected alternatives shaped the current shape. |
| Realistic usage example | Always | One example readers can transplant, not synthetic. |

**Function / method documentation:**

| Element | Required | Why |
|---|---|---|
| Parameters / returns / errors | Always | Stack-appropriate idiom (Google docstring for Python, JSDoc/TSDoc for TypeScript, rustdoc, godoc, etc.). |
| WHY this function exists | When not self-evident from signature | Names + types already say WHAT; reserve prose for WHY. |
| Side effects | Always when present | I/O, mutation of arguments, global state — must be called out explicitly. |
| Examples | For non-trivial functions | At least one realistic call site. |

### Inline comment discipline

**When required:**

- **Subtle code** — explain WHY the subtlety exists.
- **Logic for a specific bug or scenario** — note the scenario the code is defending against.
- **Defensive checks for non-obvious failures** — note the failure mode the check guards.
- **Magic values that can't become named constants** — explain the semantics inline.

**When NOT required:**

- **Self-explanatory code** — names + types already tell the reader.
- **Restatements of type signatures** — adds noise without information.
- **Section-header comments inside functions** — extract a named subfunction instead.

### Universal anti-patterns

- **Empty / missing module docstring.** A file with code but no module docs gives the next reader no orientation.
- **Docstring restates the function name.** `def get_user(...): """Get user."""` — adds nothing.
- **Docstring lists params without explaining them.** "Args: id: the id" — the type already says it's an id; the doc should say what an id is, where it comes from, what values are valid.
- **Stale docstring that no longer matches code.** Once-accurate, now misleading. Periodic review catches these; reviewer skills surface them as MUST-FIX.
- **"TODO: document this" placeholders.** Worse than no docstring — they advertise neglect.
- **WHAT-narrating comments instead of WHY-explaining comments.** `# loop through items` next to a `for` loop. The code already says that.

### Future-stack adoption discipline

When ANY new language or technology is introduced to ANY project, the workstream adopting it **must** extend that project's CLAUDE.md with the stack's documentation tooling **before** significant code lands. Adopting a stack without documentation discipline is forbidden across all projects.

Adoption checklist:

1. Identify the language's standard documentation convention (Google docstring, JSDoc/TSDoc, rustdoc, godoc, etc.).
2. Identify linting tools that enforce documentation structure (ruff D rules, eslint-plugin-jsdoc, rustdoc lints, etc.).
3. Add stack-specific rules to the project's custom AST/style checks for content depth (beyond what generic linters cover).
4. Update review skills (`/review-<stack>`) to include a Documentation severity dimension.
5. Add stack-specific WRONG/CORRECT examples to the project's CLAUDE.md, using real files from that project.

### Universal verification checklist

Pre-commit language-agnostic items:

- [ ] Every public function / method / class has documentation.
- [ ] Module documentation includes WHY, WHERE-it-fits, LIMITATIONS-with-mitigations, FUTURE-EVOLUTION markers.
- [ ] Class documentation includes purpose, lifecycle, at least one realistic example.
- [ ] Function documentation explains WHY (not just WHAT) when the purpose isn't self-evident from signature.
- [ ] Side effects documented explicitly.
- [ ] Inline comments explain WHY, not WHAT.
- [ ] No stale documentation (docstring matches code behavior).
- [ ] No "TODO: document this" placeholders.
- [ ] For new modules: SAFE EXTENSIONS and REGRESSIONS TO AVOID sections present.

Project-specific tooling items (ruff D rules in Python, eslint-plugin-jsdoc rules in TypeScript, custom AST checks, etc.) live in the project's CLAUDE.md "Documentation Standards" section.

### Review-skill integration

Any review skill in any project (`/review-backend`, `/review-frontend`, future `/review-<stack>`) includes a Documentation severity dimension in its deviation reports. Categorization:

| Severity | Pattern |
|---|---|
| **MUST-FIX** | Missing docs on a public API; missing a required section (WHY, lifecycle, side effects when present). |
| **SHOULD-FIX** | WHAT-narration instead of WHY-explanation; missing context; missing limitations / mitigations. |
| **CONSIDER** | Missing examples on a non-trivial function; missing future-evolution markers on a new module; missing teaching layer where one would help. |

The principle is universal; the per-skill implementation in each project's CLAUDE.md cites these severity rules.

### Tracked-deferral convention

When a documentation rule must be deferred to a future commit:

1. Add an inline disable using the project's stack-specific linter syntax.
2. Use the project's convention for the inline marker text (e.g., `-- deferred; see TASKS.md` in mg-blocks).
3. Add a backlog entry to the project's TASKS.md (or equivalent working memory) so the deferral is tracked, not silent.

`--no-verify` is forbidden across all projects: violations are fix-or-defer-with-tracking, never bypass. The principle (fix-or-track-explicitly, never silent suppression) is universal; the syntax per stack lives in each project's CLAUDE.md.

---

## Language standards (deep per-language rules auto-load from `~/.claude/rules/<lang>.md`)

Full, language-specific standards live in path-scoped rule files that load **only** when you
touch that language (see *Instruction architecture* above). Always-on cores — enough to keep a
brand-new file honest before its rule triggers:

- **Python** — `**/*.py` → `~/.claude/rules/python.md`. uv only (never pip); type hints =
  builtin generics + `X | None`; Google docstrings; properties over getters; module/package/
  public visibility tiers; AST over runtime metadata.
- **Kotlin** — `**/*.kt`, `**/*.kts` → `~/.claude/rules/kotlin.md`. Explicit nullability
  (`T?`/`T`, avoid `!!`); immutable `data class` (`val`, not `var`); structured coroutines (no
  `GlobalScope`).
- **C++** — `**/*.cpp`, `**/*.h`, … → `~/.claude/rules/cpp.md`. RAII + smart pointers (no raw
  `new`/`delete`); const-correctness; modern C++17/20 (`std::optional`, range-for, structured
  bindings).
- **Java** — `**/*.java` → `~/.claude/rules/java.md`. `Optional` for nullable returns;
  immutability (records, `final`, no setters); constructor injection; Streams for collection
  transforms.

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
| Low | Sonnet | Git ops, `glab` commands, `gh` commands, scaffolding, rendering, formatting |
| Medium | Sonnet | Implementation, debugging, refactoring |
| High | Opus | Architecture, design decisions, algorithms |

**Note**: All GitLab (`glab`) and GitHub (`gh`) CLI operations should use Sonnet - they're simple command execution, not complex reasoning.

### Delegating shell work to Sonnet (cost optimization)

Running shell work on a **Sonnet subagent** is cheaper than inline Opus — the subagent runs on
the cheaper model AND only its summary returns to the Opus context (large/verbose output never
fills the expensive window). But spawning a subagent has fixed overhead, so delegate **by output
size and independence, not by "it's a shell command."**

**Mechanism (current Claude Code harness):** there is **no** `subagent_type="Bash"`. Delegate via
the Agent/Task tool with a model override and a `general-purpose` subagent:

```text
Task(subagent_type="general-purpose", model="sonnet",
     description="run the suite",
     prompt="Run `pytest -q`; report pass/fail + any failures verbatim")
```

**Delegate to Sonnet when:**

- The command yields **large/verbose output** you don't need word-for-word (test suites, builds,
  broad `grep`/`find`, log scans) — the subagent runs it, digests it, and returns a summary.
- The work is **independent and multi-step** and can run start-to-finish without Opus reasoning
  between steps.

**Run inline (Bash tool) when:**

- It's a **quick, low-output command** (`git status`, `ls`, a single `git commit`, one file
  check) — the subagent round-trip would cost *more* than just running it.
- You need the **exact output** in the main context to decide the next step.

When in doubt on a verbose or long-running command, delegate to Sonnet.

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
| `/resume` | Session start | Load context from `./.claude/SESSION.md` (previous session) | Sonnet |
| `/checkpoint` | Every 30-45 mins | Save progress mid-session WITHOUT stopping | Sonnet |
| `/handoff` | Before stopping | Persist full state for next session | Sonnet |

**Example Workflow:**
```bash
# Session 1: Work and save progress
/resume       # Load context from previous session
# ... work for 30-45 mins
/checkpoint   # Save progress, continue working
# ... more work
/handoff      # Save state before closing

# Session 2: Next day
/resume       # Restores context from ./.claude/SESSION.md
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
  --model "sonnet" \
  --prompt "Subtask" \
  --parent-task "task-1234"
```

**Recovery from crash:**

When Claude crashes during spawned task, run:
```bash
/task_recover
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
| `/resume` | **Session start** | Load previous context from `./.claude/SESSION.md` | `~/.claude/commands/resume.md` |
| `/checkpoint` | **Every 30-60 mins** | Save progress, verify patterns | `~/.claude/commands/checkpoint.md` |
| `/handoff` | **Before stopping** | Persist state for next session | `~/.claude/commands/handoff.md` |

**Note:** Commands are GLOBAL (in `~/.claude/`) but they read/write project-local state (`./.claude/SESSION.md`)

### Proactive Prompting Rules

**At session start** (no prior context visible):
- If `.claude/SESSION.md` exists but hasn't been mentioned → Suggest: "I see a SESSION.md from a previous session. Would you like me to `/resume` to restore context?"
- If starting fresh with no context → Ask: "What would you like to work on today?"

**During extended work** (after ~30-45 minutes of continuous work):
- Suggest: "We've been working for a while. Would you like to `/checkpoint` to save progress?"

**Post-commit checkpoint judgment**: After every successful `git commit` that becomes visible to the assistant in the current session — whether the assistant invoked it directly, the user invoked it after assistant-staged work, or the user committed independently — evaluate whether SESSION.md needs an update.

This is a manual discipline applied by the assistant on every commit — NOT an automated hook. No `PostToolUse` binding for `Bash(git commit*)` exists in `~/.claude/settings.json`; earlier prose in `~/.claude/commands/checkpoint.md` describing a "post-commit auto-trigger" was aspirational and has been corrected. The discipline lives here, in this rule, applied by the assistant proactively without waiting for a prompt.

**Marker semantics**:

- `.claude/auto-checkpoint` present in the repo → apply the judgment after **every** successful commit (most should NO-OP).
- `.claude/auto-checkpoint` absent → apply the judgment only on manual `/checkpoint` invocations; suggest checkpoint at natural milestones (phase completions, architectural decisions, before `/clear` or `/compact`).

**Judgment criteria** (full version in `~/.claude/commands/checkpoint.md`):

Ask: *"What did we learn or decide in this commit that future sessions need to know that they would not get from `git log` and the current code?"*

- **Mechanical commit** (lint fixes, formatting, typo corrections, dependency bumps, routine refactors that execute a previously-decided plan, small docs touches) → **NO-OP**. Surface the no-op explicitly so absence-of-update is visible:

  ```text
  ✓ Checkpoint no-op at [timestamp]
  Nothing notable since last update — leaving SESSION.md unchanged.
  ```

- **Substantive commit** (architectural decisions resolved, unexpected verification results, productive pushback that refined the approach, phase completions, work-thread pivots, near-misses with signal) → **UPDATE**. Refresh `.claude/SESSION.md` in place per canonical shape (single snapshot, overwrite): Last Updated, Branch, Current Focus, Status, Completed This Session, In Progress, Next Steps, Blockers, Key Decisions. Update `.claude/TASKS.md` only if the backlog actually changed. Surface:

  ```text
  ✓ Checkpoint saved at [timestamp]
  Updated: SESSION.md [+ TASKS.md if applicable]
  Reason: [one-line summary of what changed in understanding]
  ```

If unsure between mechanical and substantive, lean toward NO-OP. A stale SESSION.md is worse than an absent update.

**When user says goodbye/stopping/break/lunch/EOD**:
- Prompt: "Before you go, let me run `/handoff` to save our progress for next time."
- If user declines, respect it but note: "No problem. Note that context may be lost without handoff."

**When context seems unclear** (user asks "where were we?" or Claude is uncertain):
- Suggest: "Let me check `.claude/SESSION.md` for context" or "Would `/resume` help restore context?"

**When detecting pattern drift** (own code violating CLAUDE.md rules):
- Self-correct and suggest: "I notice I may have drifted from patterns. Running a mental `/checkpoint` to realign."

### Session Files

| File | Purpose |
|------|---------|
| `.claude/SESSION.md` | Handoff state (written by `/handoff`) |
| `.claude/JOURNAL.md` | Historical log (optional, append-only) |

### Never Assume Prior Context

Unless SESSION.md has been read or user provides context, assume this is a fresh start. Don't pretend to remember previous sessions.

---

## Reference Files **MANDATORY**

| Need | Read |
|------|------|
| Architecture patterns (layered, pipeline, emitter) | `~/.claude/reference/architecture.md` |
| Feature workflow (epic→branch→PR) | `~/.claude/reference/workflow.md` |
| Per-language standards (auto-loaded, path-scoped) | `~/.claude/rules/{python,kotlin,cpp,java}.md` — see *Instruction architecture*. `reference/code-standards.md` is legacy, pending reconciliation. |
| Documentation templates | `~/.claude/reference/documentation-standards.md` |


## Documentation Discipline

When completing any feature:

1. **Before MR**: Run `/sync-docs`
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