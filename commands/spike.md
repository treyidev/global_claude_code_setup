---
description: Spike lifecycle (all projects) — open (permanent branch + tracker story + README scaffold), build sittings, verdict + freeze. TRIGGER AUTOMATICALLY whenever spike work arises, not only on explicit /spike — an ADR/design defers a fork to a prototype, the owner asks to prototype/explore/test a question, sitting evidence lands, or a verdict closes a spike. Spike branches are permanent; spikes never merge to main.
---

# /spike — spike lifecycle (universal; project ADRs refine)

Modes by args: `new <slug> "<question>"` · `verdict <NNNN> "<one-line verdict>"` ·
no args: report in-flight spikes (open `spike/*` branches + story status).

**Before acting, read the project's spike governance:** the repo CLAUDE.md Spikes section
and any spike ADRs (e.g. byte-gazers: ADR-0003 as amended by ADR-0008). Project rules
refine these defaults; where a project has none, these defaults ARE the convention.

## Ground rules (universal)

- **One spike = one question.** Code lives in `spikes/NNNN-<slug>/`; the README (with
  `question` / `status` / `verdict` frontmatter) is the only mandatory artifact and the
  paper trail decisions will cite.
- **The `spike/<slug>` branch is the spike's permanent home:** pushed to ALL of the
  project's remotes, **never merged to main, never deleted, no landing MR**. Access =
  the branch + its tracker story. Cited commit SHAs stay stable forever.
- **`main` gitignores `spikes/`**; the spike branch's **first commit removes that line**.
  Branches never merge back, so the divergence never conflicts. (Project without the
  ignore line yet: add it to main first, as its own commit.)
- Spike code is **exempt from production standards**; **nothing imports from `spikes/`**.
  Promotion = rewrite under production standards, never copy.
- **A tracker story anchors the lifecycle** (project label grammar, e.g. `kind::spike` +
  `area: spikes`) — question, open forks, verdict trail, pointer to the branch. File it
  via `/create-story`.
- **The verdict lands in an ADR** (when the project keeps a corpus), then the spike
  **freezes** — only the README status may change afterward.

## `/spike new <slug> "<question>"`

1. **Preconditions:** on `main`, clean tree, synced.
2. **Number it:** NNNN = next free four-digit id. `main` carries no `spikes/`, so
   inventory the branches (`git branch -r --list '*/spike/*'` +
   `git ls-tree <branch> spikes/`) and the tracker's spike stories.
3. **Cut `spike/<slug>`** off main (branch carries the slug; directory carries
   `NNNN-<slug>`).
4. **First commit — un-ignore:** remove the `spikes/` line from `.gitignore`, committed
   alone: `chore: open spike NNNN-<slug> — un-ignore spikes/ on branch`.
5. **Scaffold** `spikes/NNNN-<slug>/README.md` (frontmatter: `question` / `status: open` /
   `started` / `timebox` / `answered-by` (the gated ADR/decision record) / `issue`) + a
   verdict rubric table when the question is comparative. Build junk (node_modules, dist,
   venvs) goes in the branch `.gitignore`.
6. **File the story** via `/create-story` with the project's spike labels; backfill the
   story ref into the README `issue:` field.
7. **Push the branch to every remote. Do NOT open an MR.** Protect `spike/*` on the host
   (no deletion, no force-push) if not already done.

## Build sittings

- Commit on the spike branch only. Update the README rubric **measurement column in the
  same commit** the evidence lands.
- Owner decisions taken mid-spike (a fork resolved early) get their decision record
  immediately — landed via the **ADR-landing flow** below, citing branch + SHAs. Don't
  wait for the verdict.
- Session-continuity files (`.claude/*`) on the branch are stale copies — never edit
  them there; that state lives on `main`.

## `/spike verdict <NNNN> "<one-line verdict>"`

1. **On the spike branch:** README frontmatter `status: answered` + `verdict:` +
   `answered-by:`; fill the Verdict section + rubric gaps; final commit; push every
   remote. **The branch is frozen** — no further commits.
2. **Land the decision record via the ADR-landing flow** (byte-gazers ADR-0009; use it
   as the default everywhere): a **short-lived `adr/<slug>` branch** off `main` carrying
   **only decision artifacts** (the ADR status flip / amending ADR + reciprocity +
   sidecar/lint tooling where present + directly-coupled governance text) → **MR → owner
   reviews and merges → delete the `adr/` branch**. The MR never contains spike or
   feature code — **the ADR gets the MR; the spike branch stays unmerged, forever**.
3. **Close the story** with a comment naming verdict + decision record + branch (the
   permanent pointer).
4. **Never** delete or merge the spike branch (`adr/*` branches, by contrast, die after
   merge — they are landing vehicles, not archives).
