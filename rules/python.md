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

Three visibility tiers, signaled via naming + export:

| Tier | Naming | In `__init__.py` re-exports? | When to use |
| ---- | ------ | ---------------------------- | ----------- |
| **Module-private** | `_Name` (leading underscore) | No | Used only within the defining module. The underscore signals "do not import from outside this file." |
| **Package-private** | `Name` (no underscore) | No (NOT in `__init__.py`) | Used across modules in the same package; not part of the package's public API. Fine for sibling modules to import directly. |
| **Public** | `Name` (no underscore) | Yes (in `__init__.py` `__all__` / re-exported) | Part of the package's public API. |

**Why package-private exists**: A leading underscore on a Protocol or class used as a type hint in a public function's signature is awkward — callers see the hint but can't import it without violating the underscore convention. Package-private (no underscore, not exported) signals "implementation detail at the package level, not consumer-facing" without that import friction. Sibling modules in the same package can import it freely.

**Docstring convention** for package-private classes: lead with "Package-private contract for X" / "Package-private helper for X" and state explicitly "not re-exported from the package's `__init__.py`." This tells future readers (including future-you) that the class is intentionally not in the public surface.

```python
# Module-private — only this file uses it
class _InternalCacheKey:
    """Module-private cache key helper — do not import from sibling modules."""

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

**When picking**: default to module-private (`_X`). Promote to package-private (drop the underscore) when a sibling module needs to import it. Promote to public (export from `__init__.py`) only when callers outside the package would reasonably need it.

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
