---
description: Spike lifecycle (all projects) — open (a spike dir in the shared gz-spike submodule + tracker story + README scaffold), build sittings, verdict + freeze. TRIGGER AUTOMATICALLY whenever spike work arises, not only on explicit /spike — an ADR/design defers a fork to a prototype, the owner asks to prototype/explore/test a question, sitting evidence lands, or a verdict closes a spike. Spikes live in the gz-spike shared repo (submoduled at spikes/), NOT on branches.
---

# /spike — spike lifecycle (universal; project ADRs refine)

Modes by args: `new <slug> "<question>"` · `verdict <NNNN> "<one-line verdict>"` ·
no args: report in-flight spikes (spike dirs in gz-spike whose README `status: open` +
their story status).

**Before acting, read the project's spike governance:** the repo CLAUDE.md Spikes section
and any spike ADRs. Project rules refine these defaults; where a project has none, these
defaults ARE the convention.

## Model — spikes live in the shared `gz-spike` submodule (NOT branches)

Spikes are **family-shared** and durable: they live in the **gz-spike** repo, which is
**submoduled at `spikes/`** in each parent (gazers-universe, byte-gazers, future products).
There are **no permanent `spike/*` branches** and `spikes/` is **not gitignored** — the
submodule IS the home. *(Superseded 2026-07-20: the earlier permanent-branch model — a
`spike/<slug>` branch, gitignored `spikes/` — is retired in favour of this.)*

## Ground rules (universal)

- **One spike = one question.** It is a directory `NNNN-<slug>/` at the **root of gz-spike**
  (so, `spikes/NNNN-<slug>/` inside a parent). The README (frontmatter `question` / `status`
  / `verdict`) is the only mandatory artifact and the paper trail decisions cite.
- **Work is committed IN the gz-spike submodule** (its own history), then the **gitlink is
  bumped** in the parent (the two-commit rule — see the parent's README "Submodules"). Cited
  gz-spike commit SHAs stay stable.
- **Numbering is family-wide** — scan gz-spike (`git -C spikes ls-files | grep -oE '^[0-9]{4}'`
  or `ls spikes/`) for the next free `NNNN`, across all products.
- Spike code is **exempt from production standards**; **nothing imports from `spikes/`**.
  Promotion = rewrite under production standards **in the parent**, never copy.
- **A tracker story anchors the lifecycle** — filed in the **parent** whose ADR the spike
  feeds (project label grammar, e.g. `kind::spike` + `area: platform`), via `/create-story`.
- **The verdict lands as an ADR in the parent** (via `/adr-new` when the repo keeps a corpus),
  then the spike **freezes** in gz-spike — only its README status may change afterward.

## `/spike new <slug> "<question>"`

1. **Preconditions:** the parent's `spikes/` submodule is initialized
   (`git submodule update --init spikes`); on gz-spike's `main`, clean, synced.
2. **Number it:** `NNNN` = next free four-digit id across gz-spike (family-wide scan above).
3. **Create the spike dir** in the submodule: `spikes/NNNN-<slug>/README.md` (frontmatter:
   `question` / `status: open` / `started` / `timebox` / `answered-by` (the gated ADR/decision
   record) / `issue`) + a verdict rubric table when the question is comparative. A per-spike
   `.gitignore` covers build junk (node_modules, dist, venvs).
4. **File the story** in the **parent** via `/create-story` with the project's spike labels;
   backfill the story ref into the README `issue:` field.
5. **Commit in gz-spike** (`cd spikes && git switch main && git add … && git commit && git push`
   to all gz-spike remotes) — get onto `main` first (submodules check out detached HEAD).
6. **Bump the gitlink** in the parent when you want it to reference the spike
   (`git add spikes && git commit -m "chore: add spike NNNN-<slug>"`). No `spike/*` branch,
   no landing MR for the spike itself — gz-spike IS the home.

## Build sittings

- Edit + commit **in the gz-spike submodule**; push gz-spike. Update the README rubric
  **measurement column in the same commit** the evidence lands. Bump the parent gitlink when
  the parent should reference the new state.
- Owner decisions taken mid-spike (a fork resolved early) get their decision record
  immediately — landed as an ADR in the parent (`/adr-new`), citing the gz-spike SHA. Don't
  wait for the verdict.
- **Detached HEAD:** always `git switch main` inside `spikes/` before committing, or work
  lands on no branch.

## `/spike verdict <NNNN> "<one-line verdict>"`

1. **In the gz-spike submodule:** README frontmatter `status: answered` + `verdict:` +
   `answered-by:`; fill the Verdict section + rubric gaps; final commit; push all gz-spike
   remotes; bump the parent gitlink. **The spike is frozen** — no further build commits.
2. **Land the decision record as an ADR in the parent** via **`/adr-new`** (or `/adr-review`
   if amending an existing ADR): a short-lived `adr/<slug>` branch off the parent's `main`
   carrying **only decision artifacts** (the ADR + reciprocity + directly-coupled governance
   text) → **MR → owner reviews and merges → delete the `adr/` branch**. The MR never contains
   spike or feature code — the ADR cites the **gz-spike commit SHA**.
3. **Close the story** with a comment naming verdict + ADR + the gz-spike path/SHA.
4. **The spike stays in gz-spike, frozen** — it is never deleted; the `adr/*` landing branch
   dies after merge.
