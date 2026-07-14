---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.mts"
  - "**/*.cts"
---

# TypeScript standards (auto-loaded on `**/*.ts(x)`)

Deep TypeScript-specific standards. **Path-scoped**: loaded deterministically by the harness
when you read or edit TypeScript (see *Instruction architecture* in `~/.claude/CLAUDE.md`);
brand-new files are covered by the `inject_lang_rule.py` PreToolUse hook. Cross-language
principles (SOLID, clean code, architecture, documentation, fail-fast) live in `CLAUDE.md`
and apply on top of this. Graduated 2026-07-14 from the gazers-universe house standards —
the universal subset; project CLAUDE.md files may add stack rules (framework seams, bundling).

## Strictness (Required)

`tsconfig` runs `strict: true` — code must hold without loosening it.

```typescript
// ❌ WRONG — `any` erases the type system silently
function handle(payload: any) { ... }

// ✅ CORRECT — `unknown` forces narrowing before use
function handle(payload: unknown) {
  const parsed = PayloadSchema.parse(payload);  // or a type guard
}
```

- Bare `any` without an `eslint-disable` + justification comment: never.
- `as` casts that bypass checking need a comment saying why the cast is safe.
- Non-null assertions (`!`) need a preceding guard or a comment proving non-null.

## Finite string sets — object-const enum (MANDATORY)

Any finite set of string values used in comparisons, dispatch, or schemas. SCREAMING_SNAKE
keys, lowercase wire values; never TS `enum` (runtime baggage, poor unions), never a bare
string-literal union (allows raw strings at call sites), never raw literals in comparisons.

```typescript
// ✅ CORRECT
export const NodeStatus = {
  LOCKED:    'locked',
  AVAILABLE: 'available',
} as const;
export type NodeStatus = (typeof NodeStatus)[keyof typeof NodeStatus];
// Zod v4: z.enum(NodeStatus)         — NOT z.nativeEnum (deprecated)
// Call site: status === NodeStatus.LOCKED

// ❌ WRONG — raw string at a call site
if (status === 'locked') { ... }

// ❌ WRONG — plain union type; raw strings then appear everywhere
type Status = 'locked' | 'available';
```

## Exhaustive dispatch — Record over if-chains

```typescript
// ✅ CORRECT — the compiler errors the moment a variant is added but unhandled
const COLOR: Record<NodeStatus, string> = {
  [NodeStatus.LOCKED]:    '#888',
  [NodeStatus.AVAILABLE]: '#4af',
};

// ❌ WRONG — silent fallthrough swallows new variants
if (status === NodeStatus.LOCKED) return '#888';
return '#4af';
```

`if`/`switch` chains over a union need a `never`-guarded default
(`default: { const _exhaustive: never = x; throw ... }`) or a `Record` dispatch.

## Validate at external boundaries

Data crossing an external boundary (API response, storage, URL params, config/env, message
payloads) is `unknown` until validated — Zod (or equivalent) schema at the boundary, typed from
then on. Env is validated **at startup**, not at first use. Never trust-cast the wire:
`(await res.json()) as User` is the canonical violation.

## Immutability by default

```typescript
// ✅ prefer
const config = { retries: 3, timeoutMs: 5_000 } as const;
interface Point { readonly x: number; readonly y: number }

// ❌ avoid — mutable shared shapes invite action-at-a-distance
let config = { retries: 3 };
```

`readonly` on interface fields and arrays (`readonly T[]`) unless mutation is the point;
`as const` for literal shapes; discriminated unions (tagged by an object-const field) for
variant data instead of optional-field soup.

## Imports & visibility

- `import type { X }` for type-only imports (keeps runtime graphs honest, enables
  `verbatimModuleSyntax`).
- **Visibility mirrors the Python tiers** (`rules/python.md`): a symbol not re-exported from
  the package's public barrel (`index.ts`) is **package-private** — sibling modules may import
  it directly; external consumers must not reach into `src/` paths. Default new symbols to
  unexported; promote when a real consumer appears.
- No star re-exports of internals; the barrel is a curated API, not a mirror.

## Style earns its keep — debuggability first (TS shape)

Same tests as every language (importable/testable · clean breakpoint · legible stack trace ·
inspectable state):

- **Named top-level functions for load-bearing logic** — an anonymous arrow in a pipeline or a
  factory-returned closure shows up as `anonymous`/`inner` in stack traces and can't be
  imported by a test. `export function scoreAnswer(...)` beats
  `const make = () => (...) => ...`.
- **A class earns its keep only with real state or a lifecycle** (or a framework demands it).
  Methods-over-constants is a namespace pretending to be an object — use a module of functions
  + an exported `as const` record.
- **Inject configuration as a readonly object parameter**, not hidden closure state.

## Docs — TSDoc

TSDoc on every exported symbol; module header with WHY / WHERE-it-fits / LIMITATIONS /
SAFE-EXTENSIONS / REGRESSIONS-TO-AVOID; non-obvious third-party calls explained at the call
site. Depth bar + templates: `~/.claude/reference/documentation-standards.md`.
