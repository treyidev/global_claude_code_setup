---
paths:
  - "**/*.py"
---

# Python standards (auto-loaded on `**/*.py`)

Deep Python-specific standards. **Path-scoped**: the Claude Code harness loads this file
deterministically — only when you read or edit a Python file (see *Instruction architecture* in
`~/.claude/CLAUDE.md`). The always-on `CLAUDE.md` keeps a 3-line Python core (for brand-new files
written before this rule triggers); this file is the full guidance. Cross-language principles
(SOLID, clean code, architecture, documentation discipline, fail-fast, domain exception
hierarchies, universal anti-patterns) live in `CLAUDE.md` and apply on top of this.

## Type Hints (Required)

Use **modern builtin generics** (PEP 585, Python 3.9+) and the **`X | None` union** (PEP 604,
3.10+). The collection generics (`list`, `dict`, `tuple`, `set`) and `|` are built in — import
from `typing` only what has no builtin form (`Any`, `Protocol`, `TypeVar`, `Callable`,
`ClassVar`, …). Add `from __future__ import annotations` when forward refs or heavy annotations
warrant it.

```python
# ✅ CORRECT - builtin generics + `X | None`
def process(
    items: list[Item],
    config: Config | None = None,
) -> ProcessResult:
    ...

# ❌ WRONG - typing-module collection aliases / Optional (legacy, soft-deprecated since 3.9)
from typing import Dict, List, Optional        # NO — use list/dict + `X | None`
def process(items: List[Item], config: Optional[Config] = None) -> ProcessResult:
    ...

# ✅ Still imported from typing (no builtin form):
from typing import Any, Protocol, TypeVar, Callable
```

## Imports (Explicit, Grouped, Sorted)
```python
# Standard library
from pathlib import Path
from typing import Any, Protocol   # only what has no builtin form (collections use list/dict/…)

# Third-party
from pydantic import BaseModel, Field

# Local
from myproject.domain import User
from myproject.repository import UserRepository
```

## Properties Over Getters
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

## Visibility Tiers (Module-private / Package-private / Public)

Python has no access specifiers, so visibility is **simulated through `__init__.py`
exposure**: a class/function is "private" precisely when it is *not* re-exported from its
package's `__init__.py`. A consumer then can't reach it without dotting into a module path,
which is itself the signal "you're touching an internal." This is the house convention
across the **math-gazers suite of applications** — default a new symbol to private and
promote it only when a real caller appears. Three visibility tiers, signaled via naming +
export:

| Tier | Naming | In `__init__.py` re-exports? | When to use |
| ---- | ------ | ---------------------------- | ----------- |
| **Module-private** | `_name` (leading underscore) — **functions / constants / variables only, never classes** | No | Used only within the defining module. The underscore signals "do not import from outside this file." Classes skip this tier entirely; see the directive below. |
| **Package-private** | `Name` (no underscore) | No (NOT in `__init__.py`) | Used across modules in the same package; not part of the package's public API. Fine for sibling modules to import directly. |
| **Public** | `Name` (no underscore) | Yes (in `__init__.py` `__all__` / re-exported) | Part of the package's public API. |

**Why package-private exists**: A leading underscore on a Protocol or class used as a type hint in a public function's signature is awkward — callers see the hint but can't import it without violating the underscore convention. Package-private (no underscore, not exported) signals "implementation detail at the package level, not consumer-facing" without that import friction. Sibling modules in the same package can import it freely.

**Docstring convention** for package-private classes: lead with "Package-private contract for X" / "Package-private helper for X" and state explicitly "not re-exported from the package's `__init__.py`." This tells future readers (including future-you) that the class is intentionally not in the public surface.

### Classes NEVER take a leading underscore — package-private is their floor (owner directive 2026-07-31)

**A leading `_` is for module-level functions, constants and variables — never for a class, Protocol, dataclass or Exception.** A class's visibility is expressed by whether it appears in the package's `__init__.py`, not by its name. So the *lowest* tier a class occupies is **package-private**: no underscore, not re-exported.

WHY: a class is the thing most likely to be imported by name from somewhere else — a sibling module, the package's own factory, and above all the mirrored `tests/` tree (see the tests-are-a-sibling-consumer rule below). An underscore-prefixed class either blocks that import or gets imported anyway, which normalises violating the convention and makes the `_` meaningless everywhere else. It also produces uglier tracebacks and awkward docs. Nothing is gained: "not exported from `__init__.py`" already says "internal", enforceably and in one place.

This holds even for a class used only inside its defining module *today* — internal control-flow exceptions included. Today's single-module helper is tomorrow's tested unit, and renaming it later churns every call site for no benefit.

```python
# ❌ WRONG — leading underscore on a class, whatever its scope
class _StorageUnavailable(Exception): ...
class _InternalCacheKey: ...

# ✅ CORRECT — package-private: no underscore, simply absent from __init__.py
class StorageUnavailable(Exception):
    """Package-private signal that storage failed. Not re-exported from ``__init__.py``."""

# ✅ Leading underscores remain correct for module-level functions/constants/variables
_DIGEST_BYTES = 16
def _normalise_scheme(url: str) -> str: ...
```

```python
# Module-private helper *function* — the underscore tier that still applies
def _internal_cache_key(user_id: str) -> str:
    """Module-private key helper — do not import from sibling modules."""

# Package-private — sibling modules in the same package may import; not public API
class FeelTarget(Protocol):
    """Package-private contract for ``Feel``.

    Not re-exported from the package's ``__init__.py``. Sibling modules
    may import directly. Callers don't need to — Python's structural
    typing applies it implicitly.
    """

# Public — exported from package's __init__.py
class Feel(AnimationGroup):
    """Animated emotion transition. Public API."""
```

**When picking**: for a **class**, start at package-private (no underscore, not exported) — per the directive above, that is its floor — and promote to public (export from `__init__.py`) only when callers outside the package would reasonably need it. For a module-level **function, constant or variable**, default to module-private (`_x`) and drop the underscore when a sibling module needs it.

### `__init__.py` stays lean — the curated API surface, nothing else (owner directive 2026-07-15)

`__init__.py` is the package's public-API declaration: **re-exports + `__all__` + `__version__`
only.** Never use it as a dumping ground:

- **No narrative documentation.** The package's WHY / WHERE-it-fits / limitations story lives in
  the project's `README.md` (or the implementing modules' headers) — a one-line docstring
  pointing there is the ceiling. A 30-line prose header in `__init__.py` is pollution
  (flagged on adr-graph, 2026-07-15).
- **No logic, no classes, no functions.** Implementation lives in named modules; `__init__.py`
  only *selects* what is public (the Visibility Tiers above depend on this staying true).
- **No import-time side effects** beyond the re-export imports themselves.

```python
# ✅ CORRECT — the whole file
"""Frobnicator public API (see README.md for design + usage)."""

from frob.core import Frobnicator
from frob.errors import FrobError

__version__ = "1.2.0"
__all__ = ["FrobError", "Frobnicator", "__version__"]
```

**Tests count as a sibling consumer — prefer package-private over a leading underscore for anything a test imports.** A class its own package's tests need to construct and exercise *in isolation* (the debuggability-first *importable + unit-testable* test) is a reason to make it **package-private** (no underscore, not exported) rather than module-private: a leading-underscore name is awkward to import from the mirrored `tests/` tree, and the `_` signals "do not import from outside this file" — which a test then violates. So don't reflexively reach for `_` on an implementation class; ask "does anything outside this *file* (a sibling module, the package's factory, its tests) import it by name?" — if yes, it's package-private. The canonical case is **a seam's concrete adapter**: e.g. an aiocache-backed `Cache` implementation that consumers receive via DI *as the seam type* (so it is **not** public — no `__init__.py` export; consumers depend on the `Cache` Protocol, never the adapter), yet that the package's own factory and tests build directly by name (so it is **not** underscore-private either). Package-private — no underscore, not re-exported — is the correct tier.

## Style earns its keep — debuggability first (functions vs classes vs closures)

Paradigm is subordinate to **maintainability and debuggability** — the priorities for a solo
maintainer. Pick the plainest shape that does the job; every abstraction (a class, a closure, a
factory, an extra indirection) must **earn its keep** against a concrete, named benefit. Never
apply functional *or* OO style dogmatically. (Universal principle; this is its Python shape — the
cross-language statement lives in `~/.claude/CLAUDE.md`.)

The debuggability tests a shape must pass:

- **Importable + unit-testable in isolation** — can I `from mod import thing` and exercise it alone?
- **Clean breakpoint** — can I set one on the logic without stepping through a wrapper?
- **Legible traceback** — does a failure name a real top-level symbol, not `factory.<locals>.inner`?
- **Inspectable state** — can I `print()` the thing that decides behaviour?

Concrete calls:

- **Prefer top-level pure functions + explicit immutable data** over a closure that hides
  otherwise-testable functions inside `<locals>`. A `make_thing(config)` factory returning inner
  closures fails every test above; `do_thing(arg, config=DEFAULT)` passes them and is just as
  "functional" (pure, config injected as data). Reach for a closure only to capture genuinely
  per-instance state a default arg can't express.
- **A class earns its keep only with real mutable state or a lifecycle** — or when the framework
  demands one (ASGI middleware, `Exception` subclasses, a `Protocol`). A class whose methods only
  read constants is a *namespace pretending to be an object*: prefer a module of functions + a
  frozen-dataclass record (see *Visibility Tiers* and the value-object rule above).
- **Inject configuration as an immutable record** (`@dataclass(frozen=True)` passed as a defaulted
  parameter), not as hidden closure state — the record is printable, and a test can pass a tiny one.

This is the design counterpart to YAGNI and the Reuse-First "quantify before you defend" rule: the
question is never "is this more FP or more OO?" but "does this shape make the code easier to
maintain and debug — and if not, what concrete benefit pays for the abstraction?"

## Prefer AST Static Analysis Over Runtime Metadata

When introspecting Python source (e.g., discovering classes defined in a file, listing functions, extracting imports), **always use `ast.parse()`** instead of runtime metadata like `__module__`, `__qualname__`, or `inspect.getfile()`.

```python
# ❌ WRONG - Runtime metadata is loader-dependent and unreliable
def find_local_classes(module):
    return [
        name for name in dir(module)
        if isinstance(getattr(module, name), type)
        and getattr(getattr(module, name), "__module__", None) == module.__name__
    ]

# ✅ CORRECT - AST gives deterministic, loader-independent results
import ast
from pathlib import Path

def get_defined_class_names(file_path: Path) -> set:
    source = file_path.read_text(encoding="utf-8")
    tree = ast.parse(source)
    return {node.name for node in ast.walk(tree) if isinstance(node, ast.ClassDef)}
```

**Why**: `__module__` depends on *how* the module was loaded (the `module_name` argument to `spec_from_file_location`). Dynamic loading with synthetic names makes it unreliable. AST parsing reads source text directly — deterministic, no side effects, no imports needed.

**When to use AST**: Class/function discovery, import analysis, static validation.
**When runtime is OK**: Type checking (`isinstance`), method resolution, actual class usage.

## NEVER Use pip install — Use uv

**All Python projects use uv for dependency management.** Never use `pip install` directly — it bypasses the lockfile, breaks reproducibility, and can corrupt the virtual environment.

```bash
# ❌ WRONG - Bypasses lockfile, breaks venv
pip install -e ../../packages/shared/mgz_foundation
pip install some-package

# ✅ CORRECT - uv manages dependencies via lockfile
uv add some-package
uv add --dev some-package
uv sync                           # Install all deps from lockfile
uv lock                           # Regenerate lockfile
```

**Why**: uv's lockfile (`uv.lock`) ensures deterministic installs across machines. `pip install` operates outside uv's dependency graph, leading to version conflicts and missing transitive dependencies.

**For path dependencies** (local packages in monorepo): Declare them in `pyproject.toml` and use `uv sync`.

### Interpreter invocation — `uv run python`, never the global interpreter (no deviation)

**If a uv environment exists, use it — invoke Python ONLY via `uv run python`.** This applies to
every invocation, including throwaway `-c` one-liners inside shell pipelines (JSON parsing, quick
transforms). The global `python3` is unmanaged — its version and site-packages are outside the
project's lockfile, so behavior silently diverges from the project environment.

```bash
# ❌ WRONG - global interpreter, unmanaged version/env
python3 -c "import json,sys; print(json.load(sys.stdin)['body'])"
python3 scripts/check.py

# ✅ CORRECT - project venv via uv, even for one-liners
uv run python -c "import json,sys; print(json.load(sys.stdin)['body'])"
uv run python scripts/check.py
uv run --package gazers-core python -m pytest …   # workspace-member selection when relevant
```

(Owner directive 2026-07-23 — standing rule, all projects.)

## Gold-level docstring template (Google style)

The depth bar for a non-trivial public function. (The universal documentation discipline — WHY/WHERE/limitations, no WHAT-narration, no stale docs — lives in `CLAUDE.md` "Documentation Standards"; this is the Python *shape*.)

```python
# ❌ UNACCEPTABLE - Will be rejected in review
def process(data):
    """Process the data."""
    pass


# ❌ INSUFFICIENT - Needs more detail
def process(data: list[Item]) -> Result:
    """
    Process a list of items.

    Args:
        data: Items to process.

    Returns:
        Processing result.
    """
    pass


# ✅ REQUIRED - Minimum acceptable standard
def process(data: list[Item], strict: bool = False) -> ProcessResult:
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

## Data classes & value objects

Immutable value objects are `@dataclass(frozen=True, slots=True)` — frozen for hashability +
safety, slots for memory. (DTOs crossing an external boundary are Pydantic models — see the
backend rules where applicable.)

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class Coordinate:
    """Immutable 2D coordinate. Frozen for hashability; slots for memory efficiency."""
    x: float
    y: float

    def distance_to(self, other: "Coordinate") -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5
```

## Idiomatic: factory with auto-registration (Open/Closed)

Extend by *registering*, not by editing a dispatch ladder. A class registers itself via a
decorator; the factory resolves by key — new variants never touch the factory. (House pattern;
see `math-gazers` component registries.)

```python
from typing import ClassVar

class ConverterFactory:
    """Factory with automatic registration via decorators."""

    _registry: ClassVar[dict[str, type]] = {}   # builtin generics (PEP 585)

    @classmethod
    def register(cls, *providers: str):
        """Register a converter for one or more providers."""
        def decorator(converter_cls: type) -> type:
            for provider in providers:
                cls._registry[provider.lower()] = converter_cls
            return converter_cls
        return decorator

    @classmethod
    def create(cls, provider: str) -> "Converter":
        converter_cls = cls._registry.get(provider.lower())
        if converter_cls is None:
            raise ValueError(f"Unknown provider: {provider}")   # fail-fast
        return converter_cls()

@ConverterFactory.register("edge", "azure")
class SSMLConverter(Converter): ...
```
