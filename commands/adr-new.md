---
description: >-
  Author a NEW Architecture Decision Record with full knowledge-graph rigor — scaffold from the
  repo's TEMPLATE, declare relations, mechanically insert reciprocity into every target, add
  supersedes/amends banners, and drive `adr-graph lint` to green so no stale edge is ever left.
  TRIGGER AUTOMATICALLY whenever a new decision is being recorded — the owner says "write/add an
  ADR", a decision crystallizes that the repo's "new decision ⇒ new ADR" rule covers, or you are
  about to create a new file under `docs/adr/` — not only on an explicit /adr-new.
---

# /adr-new — author a new ADR (graph-consistent by construction)

Author one new ADR in the current repo's `docs/adr/` knowledge graph. This skill exists so the
mechanical, forgettable parts (reciprocity, markers, lint) are **never** hand-missed — the exact
failure that leaves the corpus stale. The deterministic backstop is the repo's `adr-graph lint`
pre-commit gate; this skill keeps you from reaching it red.

## Applicability check (this is a global skill — repos differ)

1. Confirm the repo keeps ADRs: a `docs/adr/` tree exists. If not, this skill does not apply —
   author whatever decision doc the repo uses and stop.
2. Confirm the knowledge-graph practice: `docs/adr/TEMPLATE.md` exists **and** the repo has an
   `adr-graph` lint gate (grep `.pre-commit-config.yaml` for `adr-graph`). If `TEMPLATE.md` is
   present but there is no lint gate, follow steps 1–6 for the prose/frontmatter but skip the
   lint verification (note its absence to the owner). If neither exists, fall back to a plain ADR
   and flag that this repo isn't on the graph practice.
3. **Discover the lint command from the repo, don't hardcode it** — the `adr-graph` tool is
   vendored at different paths across repos. Read the exact `entry:` from the `adr-graph` hook in
   `.pre-commit-config.yaml` (e.g. `uv run --project tools/graph/adr-graph adr-graph lint`) and
   use that verbatim.

## Steps

1. **Allocate the number.** `NNNN` = next free four-digit id across the whole corpus (scan every
   `docs/adr/**/*.md`, including scope subfolders and any branch-only ADRs the owner names). Pick
   the scope folder: `adr/` root = cross-cutting; `platform/…`, `products/…`, `infra/` = scoped.
2. **Scaffold.** Copy `docs/adr/TEMPLATE.md` to `docs/adr/<scope>/NNNN-short-slug.md`. Fill the
   frontmatter (`adr`, `title`, `status`, `date`, `tags`, `decision`) and the prose sections
   (Status line — its keyword MUST match the frontmatter status; Context; Decision with
   rejected-alternatives; Consequences incl. Limitations / SAFE EXTENSIONS / REGRESSIONS TO AVOID).
   Delete any relation key you don't use; keep `dependents: []`.
3. **Declare relations** (closed vocabulary — `supersedes` · `amends` · `refines` · `extends` ·
   `realizes` · `relates`). Every entry needs a **non-empty `scope` and `why`** (an empty one is
   exactly what rots). Pick the weakest accurate verb: `supersedes`/`amends` assert the target's
   text is now (partly) wrong — do NOT use them from a *proposed* ADR that hasn't overturned
   anything yet; use `relates`/`refines` and note in prose that it escalates on acceptance.
4. **Insert reciprocity (the mechanical step — never skip).** For **every** forward relation you
   declared, open the target ADR and append the matching entry to its `dependents:` list:
   `- adr: "NNNN"` / `type: <same relation>` / `scope: <one line>`. This is what the lint's L1
   rule blocks on; doing it here means it never blocks you.
5. **Markers.** For each `supersedes`/`amends` target, add the banner/inline marker to that ADR's
   **body** naming `ADR-NNNN` (L3 requires the target body to mention you). If the marker must be
   deferred (a drift batch owns it), record it in the sidecar's `pending_markers` instead.
6. **Prose-staleness sweep (judgment).** Check each target's *body* for now-stale references: a
   concept this new ADR gives a home to (a previously record-less precedent) should gain a pointer
   to `ADR-NNNN`. Fix those — reciprocity alone is not "not stale".
7. **Lint to green.** Run the discovered lint command; fix every error (and the warnings you can —
   L7 mention-without-relation is warn-only but usually means a missing relation or a cross-repo
   id collision to reword). Repeat until `0 error(s)`.
8. **Land via the repo's workflow.** Issue → branch → MR (never direct to main); or, if this ADR
   records a spike verdict, the `/spike` ADR-landing flow (short-lived `adr/` branch). Stage ONLY
   the ADR + its reciprocity targets — not unrelated working-memory files.

## Reference (don't duplicate the rules here)

The authoritative rules live in `docs/adr/TEMPLATE.md` (the frontmatter contract) and the repo's
ADR-graph ADR (gazers-universe: ADR-0041). This skill *operationalizes* them; when they and this
skill disagree, they win. The complement is **/adr-review** (update/amend/reconcile existing ADRs).
