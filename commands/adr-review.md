---
description: >-
  Update / amend / reconcile an EXISTING ADR (or sweep the corpus) so it never goes stale — status
  transitions, relation changes with cascading `dependents:` reciprocity, relates→amends
  escalations with banners, and prose-staleness fixes, all driven to `adr-graph lint` green.
  TRIGGER AUTOMATICALLY whenever an existing ADR's status or relations change — flipping a status
  (e.g. proposed→accepted), adding/retargeting a relation, a new decision that supersedes/amends a
  prior one, or any graph-structural edit under `docs/adr/` — not only on an explicit /adr-review.
---

# /adr-review — update & reconcile ADRs (keep the graph un-stale)

Make a change to one or more EXISTING ADRs and keep the whole knowledge graph consistent. This
owns the *maintenance* half of "never stale" (its sibling **/adr-new** owns creation). The
deterministic backstop is the repo's `adr-graph lint` gate; this skill is how you satisfy it
deliberately rather than by trial and error.

## Applicability check (global skill — repos differ)

Same as /adr-new: needs a `docs/adr/` tree; the graph practice needs `docs/adr/TEMPLATE.md` + an
`adr-graph` pre-commit gate. **Discover the exact lint command from `.pre-commit-config.yaml`'s
`adr-graph` hook — never hardcode the tool path** (it is vendored differently per repo). If the
repo has no graph gate, do the edit plainly and note the gate's absence.

## Modes

- **Targeted update** — the common case: change a specific ADR (status flip, add/change a
  relation, fix a stale reference).
- **Corpus sweep** — review for drift across many ADRs. Until the repo's staleness-hash detection
  exists (gazers-universe: epic #47 MR 2, the L8 hash stamps), *detection is manual* — walk the
  candidates the owner names or that the current change touches. Do **not** claim an automated
  sweep the tooling can't yet back.

## Steps

1. **Load** the target ADR(s). Restate what is changing and why.
2. **Apply the change:**
   - **Status transition** — edit `status:` in frontmatter AND the prose `- **Status:**` line so
     the keyword still matches (L9 blocks a mismatch). On **proposed → accepted**, this is where
     **deferred escalations fire**: any relation the ADR recorded as "escalates to `amends` on
     acceptance" gets upgraded now — change the relation type, add the target's banner, update the
     reciprocal `dependents:` type. Surface these as a checklist from the ADR's own prose so none
     is missed.
   - **Relation add/change** — update the forward relation (non-empty scope + why), then **cascade
     reciprocity**: add/adjust/remove the matching `dependents:` entry on the target. A removed
     relation means removing its orphaned dependents entry (L1 blocks orphans too).
   - **Escalation `relates`/`refines` → `amends`/`supersedes`** — change the type AND add the
     banner/inline marker to the target's body (L3), or record it in the sidecar `pending_markers`.
3. **Prose-staleness sweep (judgment).** For every ADR touched — and every ADR that *links to* the
   one you changed — check the body for statements the change made incomplete or wrong: a now-
   recorded precedent needing a pointer, a mechanic the change amended, a status the prose still
   describes the old way. Fix them. Reciprocity is necessary, not sufficient.
4. **Lint to green.** Run the discovered `adr-graph lint`; fix every error. A green run is the
   proof there are no unmarked edges, orphan dependents, missing markers, cycles, or status lies.
5. **Land via the repo's workflow** — issue → branch → MR, never direct to main. Stage only the
   ADRs you changed.

## Reference

Authoritative rules: `docs/adr/TEMPLATE.md` + the repo's ADR-graph ADR (gazers-universe: ADR-0041,
whose lint rules L1/L2/L3/L6/L9 are exactly what this skill keeps green). When they and this skill
disagree, they win. Complement: **/adr-new** (author a brand-new ADR).
