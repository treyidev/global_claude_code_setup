---
description: Review frontend code against universal standards + house patterns where defined
model: sonnet
---

# /review-frontend (global generic)

> **A project-local `.claude/commands/review-frontend.md` shadows this skill** — project versions
> carry house dimensions (bus contracts, engine confinement, design-token rules) and are
> authoritative in their repo. This generic version serves projects without one.

Review the target code (current file, selection, or path passed as argument).

## Steps

1. **Load `~/.claude/reference/review-core.md`** — apply ALL universal dimensions (U1–U8),
   its severity tiers, and its output format.

2. **Apply the language standard.** For TypeScript/JavaScript there is currently no
   `~/.claude/rules/` file — apply the project's tsconfig/eslint strictness as the baseline
   (strict mode expected; `any` without justification: MUST-FIX). For other languages, the
   path-scoped `~/.claude/rules/<lang>.md` auto-loads — treat it as authoritative.

3. **Frontend-generic dimensions** (on top of review-core):
   - **Component/module SRP:** a component that fetches AND transforms AND renders AND manages
     global state: SHOULD-FIX — split by responsibility.
   - **Type-safe boundaries:** external data (API responses, storage, URL params) validated at
     the boundary (schema layer, e.g. Zod) — trusted-cast `as` from the wire: MUST-FIX.
   - **Finite string sets** behind a single constant/enum construct, never raw string literals
     compared at call sites: MUST-FIX. Exhaustive dispatch (record/map or never-guarded
     switch) over silent fallthrough: SHOULD-FIX.
   - **Lifecycle hygiene:** event listeners / subscriptions / timers cleaned up on
     unmount/teardown: MUST-FIX.
   - **No magic values in styles/animation** — durations, easings, breakpoints, z-indexes as
     named tokens/constants (review-core U3 applies to the design space too).
   - **Bundle discipline:** heavyweight engines/libs lazy-loaded, never in the initial chunk,
     where the project declares such rules.
   - **Observability:** logging through the project's shared logger seam if one exists;
     `console.*` in shipped source: MUST-FIX.
