# Review core — shared scaffolding + universal dimensions (ALL projects)

> **Single source** for the review skills' shared machinery (severity tiers, output format) and
> the language-agnostic review dimensions. Extracted 2026-07-14 when the third review skill
> appeared (the gazers rule-of-three watch fired). Consumers:
>
> - **Global** `~/.claude/commands/review-{frontend,backend}.md` — thin generic skills for any
>   project without house review skills.
> - **Project-local** `.claude/commands/review-*.md` — shadow the global skills by name; carry
>   ONLY house dimensions (repo-coupled: seams, engines, ADR-derived rules) plus a pointer here.
>
> **Never duplicate per-language standards into a review skill.** They live once in the
> path-scoped `~/.claude/rules/<lang>.md` files, which the harness auto-loads when the reviewed
> files are read. Duplication is proven drift: the 2026-07 gazers audit caught a review skill
> asserting `tenant_id`/RLS, ZITADEL, and mypy — all three superseded in the repo it reviewed.

## Severity tiers

| Tier | When to use |
|---|---|
| **MUST-FIX** | Violates a hard rule; merging as-is causes bugs, silent failures, or architectural drift |
| **SHOULD-FIX** | Violates a pattern; won't break today but compounds into technical debt |
| **CONSIDER** | An improvement that would make the code clearer or more consistent |

Review posture: report only real deviations — omit praise, filler, and "looks good" lines.
Before flagging, ask the cost/benefit questions from `~/.claude/CLAUDE.md` §Code Review Stance:
*what breaks if we don't fix this?* — if nothing, it is at most CONSIDER.

## Universal dimensions (apply in every review, any language)

### U1 — SOLID / SRP

- One reason to change per class/module/function. God-objects (3+ unrelated method groups):
  MUST-FIX with the mixed concerns named.
- Coordinators delegate; they never do leaf work (managers delegate · workers work · data is
  passive — `~/.claude/reference/architecture.md`).
- Open/Closed: new behaviour by registration/composition, not by editing a growing
  `if/elif`/`switch` ladder: SHOULD-FIX.
- Liskov: an override that narrows the contract or raises on a promised method: MUST-FIX.
- Interface Segregation: narrow contracts; an interface forcing consumers to stub methods they
  never call: SHOULD-FIX.
- Dependency Inversion: depend on abstractions, inject them; a concrete type constructed inline
  where an abstraction should be injected: MUST-FIX.

### U2 — DRY / Reuse-first (with the anti-over-engineering counterweight)

- Confirm duplication is real before flagging — three similar lines beat a premature
  abstraction; only genuine copy-paste counts.
- Identical logic blocks (>5 lines) in 2+ places: SHOULD-FIX.
- A new class/function duplicating a role an existing one already serves (name it): SHOULD-FIX.
- **Rule-of-three:** deliberate 2-instance duplication is acceptable when cross-referenced;
  flag the THIRD instance and demand extraction. Project skills may list known tripwires.
- **YAGNI:** abstraction/configuration/flexibility added for a hypothetical future: SHOULD-FIX.
  "Might be useful later" is not a reason.

### U3 — Magic values

- Design-space constants (durations, thresholds, sizes, radii, retry counts, paths, colours)
  live in named constants — never bare at the call site: MUST-FIX (exceptions: obvious `0`,
  `1`, `-1`, `0.5`, `Math.PI`-class literals).
- Duplicate numeric literal (same value, 2+ sites): SHOULD-FIX even if named elsewhere.
- A named constant whose value/units/derivation is unexplained: SHOULD-FIX (magic values teach —
  what changing it does, sensible range, provenance).

### U4 — Fail-fast error handling

- Silent absorption (empty catch, bare `except: pass`): MUST-FIX.
- Returning null/undefined/None to signal an *error* at internal call sites (vs a legitimately
  optional value): SHOULD-FIX — raise/throw a domain error with context.
- Validation deferred past the point of first knowledge (not at the boundary/startup):
  SHOULD-FIX.
- Domain errors are typed (project exception hierarchy), not generic: SHOULD-FIX.

### U5 — Naming & module organization

- Catch-all modules (`utils`, `helpers`, `common`, `misc`): MUST-FIX — name for responsibility.
- Vague names (`data`, `temp`, `doStuff`, bare `Manager`): SHOULD-FIX
  (`~/.claude/reference/code-standards.md` naming table).
- Domain-driven file organization, not organize-by-type.
- No circular dependencies: MUST-FIX.

### U6 — Documentation depth

Per `~/.claude/reference/documentation-standards.md` (WHY not WHAT; module headers with
WHY/WHERE/LIMITATIONS/SAFE-EXTENSIONS/REGRESSIONS-TO-AVOID; lifecycle on classes; side effects
called out; non-obvious third-party calls explained at the call site). Severity mapping:
missing public-API docs / missing required section — MUST-FIX; WHAT-narration, missing
limitations — SHOULD-FIX; missing examples / evolution markers — CONSIDER. Stale docstring
that no longer matches code: MUST-FIX.

### U7 — Debuggability-first shape

Paradigm is subordinate to maintainability/debuggability. A shape must pass: importable +
testable in isolation · clean breakpoint · legible traceback (no anonymous inner closures as
load-bearing logic) · inspectable state. A factory returning logic-hiding closures where
top-level functions + an injected immutable config would do: SHOULD-FIX. A class whose methods
only read constants (namespace pretending to be an object): SHOULD-FIX. Language shape:
`~/.claude/rules/<lang>.md` §"Style earns its keep" where present.

### U8 — Testing posture

- Tests live outside `src/` (mirrored `tests/` tree or the project's convention): MUST-FIX.
- New public surface with no test: SHOULD-FIX.
- Fakes-only coverage where a real-engine / prod-wiring integration test is feasible:
  SHOULD-FIX — propose the real-integration layer, don't just note it.

## Output format

```text
## Review: <filename or description>

| # | Severity | Dimension | Location | Finding |
|---|---|---|---|---|
| 1 | MUST-FIX | <dimension> | file.ext:42 | <one-line finding> |

### Finding 1 — MUST-FIX: <title>
<one concise paragraph: what the violation is, why it matters, exact fix>
```

If there are zero findings in a dimension, omit that dimension entirely from the output.
If there are zero findings overall, output: `✓ No deviations found against house patterns.`
