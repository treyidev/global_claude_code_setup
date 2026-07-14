---
description: Review backend code (any language) against universal standards + the per-language rules
model: sonnet
---

# /review-backend (global generic)

> **A project-local `.claude/commands/review-backend.md` shadows this skill** — project versions
> carry house dimensions (seams, ADR-derived rules) and are authoritative in their repo. This
> generic version serves projects without one.

Review the target code (current file, selection, or path passed as argument).

## Steps

1. **Load `~/.claude/reference/review-core.md`** — apply ALL universal dimensions (U1–U8),
   its severity tiers, and its output format.

2. **Apply the language standard.** Identify the language(s) under review; the matching
   path-scoped `~/.claude/rules/<lang>.md` (python / kotlin / java / cpp) auto-loads when you
   read the files — treat it as the authoritative language standard and assign severities per
   review-core. If the language has **no** rules file, flag that as a finding itself: the
   CLAUDE.md stack-adoption discipline requires one before significant code lands.

3. **Backend-generic dimensions** (on top of review-core):
   - **Layering is one-directional** (handlers/controllers → services → repositories → models,
     or the project's documented equivalent). A handler doing persistence inline, or a model
     importing a handler: MUST-FIX.
   - **DI:** dependencies injected as abstractions (constructor/container), never constructed
     inline in business code: MUST-FIX.
   - **Configuration centralized:** env/config reads live in one settings surface, injected
     from there — scattered `getenv`-style reads: MUST-FIX.
   - **Secrets:** any credential/connection string with a literal default in code: MUST-FIX.
   - **Boundary validation:** external input validated at the boundary (schema/DTO layer),
     not deep inside business logic: SHOULD-FIX.
   - **Observability:** diagnostics through the project's shared logging seam if one exists
     (project skill defines it); raw stdout prints as diagnostics: MUST-FIX.
