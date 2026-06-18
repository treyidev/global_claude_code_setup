# Code Standards Reference

> **Mostly superseded — this file is now a thin pointer.** Canonical sources:
>
> - **Cross-language principles** (SOLID, DRY/KISS/YAGNI, fail-fast, file organization,
>   code-review stance, domain exception hierarchy) → **`~/.claude/CLAUDE.md`**.
> - **Per-language standards** (type hints, imports, idioms, data classes, generics) → the
>   path-scoped rules **`~/.claude/rules/{python,kotlin,cpp,java}.md`**, which load automatically
>   when you touch that language (see `CLAUDE.md` → *Instruction architecture*).
>
> **Removed from here** (was duplicated or stale): the SOLID / DRY / error-handling /
> code-review / per-language sections (now canonical in the sources above) — and the old
> *"Python: use the `typing` module; builtin generics WRONG"* guidance, which is **reversed**:
> the house standard is now **builtin generics + `X | None`** (PEP 585/604). See
> `~/.claude/rules/python.md`.
>
> Retained below: the two bits not captured elsewhere — a naming-quality table and a new-code
> checklist.

---

## Naming quality (language-agnostic)

| Bad | Good | Why |
|-----|------|-----|
| `data` | `user_records` | Specific |
| `temp` | `unprocessed_items` | Descriptive |
| `x` | `retry_count` | Meaningful |
| `doStuff()` | `validateAndSave()` | Action-specific |
| `Manager` | `UserAuthenticator` | Role-specific |

**Forbidden catch-all file names** (any language): `utils` / `helpers` / `common` / `misc`.
Use descriptive names instead — `string_formatting`, `date_calculations`, `validation_rules`.

---

## Checklist for new code

- [ ] SOLID principles followed (see `CLAUDE.md`)
- [ ] No star imports
- [ ] Explicit type hints / annotations (per-language rule: `~/.claude/rules/<lang>.md`)
- [ ] Comprehensive documentation (see `documentation-standards.md`)
- [ ] No hardcoded values / magic numbers
- [ ] Meaningful names
- [ ] Single responsibility per class / function
- [ ] Fail-fast error handling
- [ ] Domain-specific exceptions
- [ ] Tests written
