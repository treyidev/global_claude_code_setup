# Architecture Patterns Reference

> Read this when designing new systems, reviewing architectural decisions,
> or when Claude needs to understand Abhijit's architectural philosophy.

---

## Core Philosophy

**Managers delegate. Workers work. Data is passive.**

Every system should follow clear separation of concerns with unidirectional
dependency flow. No component should do more than its designated role.

---

## Layered Architecture

### The Hierarchy
```
Coordinator → "I know WHO to ask, not HOW"
    ↓
Dispatcher  → "I know WHICH worker, not HOW it works"
    ↓
Leaf Worker → "I DO the actual work"
    ↓
Data        → Passive, immutable
```

### Rules

1. **Each layer knows only what it NEEDS to know**
2. **Each layer DELEGATES what it DOESN'T know**
3. **Leaf nodes do the REAL work** (filtering, matching, transforming)
4. **Never filter/process at coordinator level**
5. **Logging decisions belong to logger, not components**

### Example: Correct vs Incorrect
```python
# BAD - Coordinator filters (violates layered architecture)
class Detector:
    def find(self, items):
        filtered = [i for i in items if i.type == self.type]  # NO!
        return self.matcher(filtered)

# GOOD - Worker filters (coordinator delegates)
class Detector:
    def find(self, items):
        return self.matcher(items)  # Pass ALL, let worker decide

class Matcher:  # Leaf does real work
    def __call__(self, items):
        for item in items:
            if item.type != self.type:
                continue
            # Actual matching logic...
```

### Reasoning

- **Testability**: Each layer can be tested in isolation
- **Flexibility**: Swap implementations without touching coordinators
- **Clarity**: Reading code top-down reveals WHAT, drilling down reveals HOW
- **SRP**: Each component has exactly one reason to change

---

## Output/Rendering Architecture

### Principle

**Workers emit WHAT. Renderers decide HOW.**

Components should never directly call output sinks (console, file, API).
Instead, they emit structured events that renderers transform appropriately.

### Architecture Diagram
```
Worker (emits events) → OutputManager (routes) → Renderer (transforms) → Sink
                              ↓
                    ┌─────────┼─────────┐
                    ↓         ↓         ↓
              Console      Log       API
```

### Rules

1. **Workers emit events/structured data** - NEVER call sinks directly
2. **OutputManager routes to ALL renderers** (composite pattern)
3. **Each renderer decides HOW to render** for its specific sink
4. **Adding new output = add new renderer** (Open/Closed Principle)

### Example: Correct vs Incorrect
```python
# BAD - Worker calls sink directly
class Displayer:
    def __call__(self, console, results):
        console.print(table.render())  # NO! Tight coupling to console

# GOOD - Worker emits, renderers handle
class Displayer:
    def __call__(self, output_manager, results):
        output_manager.progress_table(results)  # Emit event, let renderers decide
```

### Benefits

- **Testability**: Workers can be tested without mocking console/file/API
- **Flexibility**: Add JSON API output without changing any worker code
- **Consistency**: All output goes through same pipeline
- **Separation**: Business logic knows nothing about presentation

---

## Pipeline Pattern & Operators

### Operator Semantics

| Operator | Purpose | Example |
|----------|---------|---------|
| `<<` | Emit to sink | `emitter << formatter(data)` |
| `>>` | Sequential chain | `validator >> normalizer >> formatter` |
| `+` | Parallel combine | `console_emitter + file_emitter` |

### Usage Examples
```python
# Emission - send formatted data to emitter
emitter << session_start(job_id="abc")

# Sequential composition - data flows through pipeline
pipeline = validator >> normalizer >> formatter
result = pipeline(raw_data)

# Parallel composition - emit to multiple sinks
multi_sink = console_emitter + file_emitter + api_emitter

# Combined - validate, format, then emit to multiple sinks
(console + file) << (validator >> formatter)(data)
```

### Design Reasoning

- **Readability**: `emitter << data` reads as "emit data to emitter"
- **Composability**: Pipelines can be built incrementally
- **Testability**: Each stage is a pure function (mostly)
- **Flexibility**: Swap stages without changing pipeline structure

---

## Emitter/Registry/Output Architecture

### Principle

**Commands NEVER call console.print() directly.**

All output flows through a structured pipeline:
```
Formatter → FormattedMessage → Emitter → Registry → Renderer → Sink
```

### Three Registries

| Registry | Purpose | Used By |
|----------|---------|---------|
| `FormatterRegistry` | domain → formatter | Lookup formatters by domain |
| `ConsoleRegistry` | domain → console renderer | `ConsoleEmitter` |
| `LogRegistry` | domain → log renderer | `LoguruEmitter` |

### Registration Pattern
```python
# Register renderers with decorators
@console("cli.setup.ssh")
class SshConsoleRenderer:
    """Renders SSH status for console output."""
    
    def __call__(self, data: Dict[str, Any]) -> str:
        return f"[green]✓[/] SSH: {data['path']}"

@log("cli.setup.ssh")
class SshLogRenderer:
    """Renders SSH status for log output."""
    
    def __call__(self, data: Dict[str, Any]) -> str:
        return f"ssh status={data['status']} path={data['path']}"

# Command usage - emit, don't print
emitter << ssh_formatter(status="found", path="~/.ssh/id_ed25519")
```

### Summary

> "Formatters pack WHAT. Registries route WHERE. Renderers decide HOW."

---

## Status Codes (POSIX errno-style)

### Design Philosophy

Use numeric status codes for programmatic handling, with semantic names
for readability. Follows POSIX errno conventions for familiarity.

### Code Ranges

| Range | Category | Examples |
|-------|----------|----------|
| 0 | Success | `SUCCESS` |
| 1-9 | General errors | `ERROR`, `FILE_NOT_FOUND`, `CONFIG_INVALID` |
| 10-19 | Validation | `VALIDATION_FAILED`, `OUTPUT_EXISTS` |
| 30-39 | Prerequisites | `PREREQUISITE_FAILED`, `SETUP_INCOMPLETE` |
| 40-49 | Translation | `MODEL_NOT_FOUND` |
| 50-59 | Media | `FFMPEG_FAILED` |
| 1000+ | Warnings | `NO_RESULTS` (shell sees 0) |

### Usage
```python
# Exit with status code
sys.exit(Status.CONFIG_INVALID.to_exit_code())  # Returns 3

# Check status properties
Status.SUCCESS.is_success      # True
Status.NO_RESULTS.is_warning   # True (shell sees 0, app sees warning)
```

### Reasoning

- **Scriptability**: Shell scripts can handle different exit codes
- **Clarity**: Named constants are self-documenting
- **Compatibility**: POSIX-style familiar to Unix users
- **Warnings vs Errors**: Warnings don't fail pipelines but are trackable

---

## Lifecycle Stages

### Principle

**Declarative sequencing with `>>` and `|` operators.**

Lifecycle stages should be declared, not imperatively managed.
The framework enforces valid transitions.

### Operator Semantics
```python
# Declare valid transitions
start >> complete >> (success | fail)

# >> means "then" (sequential)
# | means "or" (alternative)
```

### Usage
```python
# Declare lifecycle
lifecycle = start >> complete >> (success | fail)

# Use in context
ctx.lifecycle.start(session=ctx.session)
# ... do work ...
ctx.lifecycle.complete(files_processed=10)
# ... finalize ...
ctx.lifecycle.succeed()  # or .fail(error=e)
```

### Benefits

- **Safety**: Invalid transitions are caught at runtime
- **Clarity**: Lifecycle is documented in declaration
- **Logging**: Transitions can be automatically logged
- **Metrics**: Stage durations can be automatically captured

---

## Dependency Flow Rules

### The Rule

**Dependencies flow ONE direction only. No exceptions.**
```
Higher-level modules
        │
        ▼ (depends on)
Lower-level modules
```

### What This Means

- **Service layer** depends on **Repository layer**
- **Repository layer** NEVER depends on **Service layer**
- **UI layer** depends on **Business layer**
- **Business layer** NEVER depends on **UI layer**

### Detecting Violations

If you need to import from a "higher" layer, you have a design problem:
```python
# VIOLATION - repository importing from service
# repositories/user_repo.py
from services.auth_service import AuthService  # NO!

# CORRECT - use dependency injection
# repositories/user_repo.py
from protocols.auth import AuthProtocol  # Depend on abstraction

class UserRepository:
    def __init__(self, auth: AuthProtocol):
        self.auth = auth
```

### Circular Import = Architecture Smell

If you have circular imports, your architecture is wrong:

1. **Extract shared code** to a lower-level module
2. **Use dependency injection** with protocols/interfaces
3. **Reconsider responsibilities** - maybe SRP is violated

---

## Composition Over Inheritance

### Preference

**Prefer composition (has-a) over inheritance (is-a).**

### When to Use Inheritance

- True "is-a" relationship (a Dog IS an Animal)
- Framework requires it (extending VGroup in Manim)
- Liskov Substitution is genuinely applicable

### When to Use Composition

- "Has-a" or "uses-a" relationship
- Behavior can change at runtime
- Multiple "inheritance" of behavior needed
- Testing requires swapping implementations

### Example
```python
# INHERITANCE - appropriate when extending framework
class Pupil(VGroup):  # Pupil IS a VGroup (Manim requirement)
    pass

# COMPOSITION - appropriate for behavior injection
class Eye:
    def __init__(self, tracker: EyeTracker):  # Eye HAS a tracker
        self.tracker = tracker
    
    def look_at(self, point):
        self.tracker.track(point)  # Delegate to composed object
```

---

## Summary Checklist

When designing a new system, verify:

- [ ] Clear layer separation (Coordinator → Dispatcher → Worker → Data)
- [ ] Unidirectional dependency flow
- [ ] Workers emit events, don't call sinks directly
- [ ] Each component has single responsibility
- [ ] Composition preferred over inheritance
- [ ] No circular dependencies
- [ ] Status codes follow POSIX conventions
- [ ] Lifecycle stages are declarative