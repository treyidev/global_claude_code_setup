---
model: sonnet
allowed-tools: Read, Write, Bash(glab:*), Bash(gh:*), Bash(cat:*)
description: Create a tracker story/issue (GitLab/GitHub) using the house convention — searchable, filterable, structured
---

# Create a Story / Issue (house convention)

> Universal, cross-project workflow for filing a story/issue in **any** tracker (GitLab via
> `glab`, GitHub via `gh`). Every issue MUST be **searchable** (good title), **filterable**
> (reused, scoped labels), and **structured** (a consistent gold-doc body) so future lookups,
> filtering, and analysis are reliable. Follow this religiously — do not free-form an issue.

`$ARGUMENTS` = the story to file (a sentence or paragraph describing the work).

## Step 0 — Discover the tracker conventions BEFORE creating (mandatory)

Never invent labels or guess the body shape. Learn the project's taxonomy first:

```bash
# GitLab
glab label list            # the project's label taxonomy (kind::*, area:*, theme:* …)
glab issue list --all      # recent issues — copy their label-combo + body style
glab issue view <N>        # read one analogous issue body to match structure

# GitHub (equivalent)
gh label list
gh issue list --state all
gh issue view <N>
```

Detect which tracker the repo uses (check `git remote -v` — GitLab-primary vs GitHub) and use
the matching CLI. Reuse the project's existing labels; **never create a new label silently** —
if no existing label fits, flag it to the owner and ask before inventing one.

## Step 1 — Title (searchable)

- **Lead with the searchable noun phrase** — the thing a future search will grep for goes first
  (e.g. "Environment replication tool — …", "Device-local tracking DB — …").
- Append a short scope/ref parenthetical when one applies (`(ADR-00NN new)`, `(Python uv CLI)`).
- One line, specific, no filler.

## Step 2 — Labels (filterable)

Apply the project's **scoped** labels so the issue surfaces under every relevant filter. Typical
axes (match the repo's actual set from Step 0 — these are the gazers-universe scheme):

- **`kind::*`** — exactly one: `feature` · `fix` · `chore` · `docs` · `refactor` · `architecture`.
- **`area: *`** — one or more area tags (`docs`, `infra`, `platform`, `products/…`, `setup`, …).
- **`theme: *`** / epic tags — when the work belongs to a tracked theme.
- **`ADR`** — only when the issue introduces/amends an ADR (an ADR file exists or is committed-to).

Reuse existing labels verbatim. If the work genuinely spans two areas, apply both.

## Step 3 — Body (structured, gold-doc — write to a file, pass via `--description`)

Write the body as markdown to a scratchpad file, then feed it to the CLI (avoids quoting hell).
Use these sections (drop ones that don't apply; keep the order):

1. **`## Summary`** — what the story delivers, in 2–4 sentences. Bold the key nouns.
2. **`## Motivation / Why`** — the problem solved; how it fits the system; rejected alternatives if
   non-obvious. Cross-link ADRs/issues.
3. **`## Scope`** — what's in. A **dimension/keyword table** here is ideal — it makes the issue
   richly searchable and makes "what exact-state means" concrete.
4. **`## Open questions / decisions needed`** — the real forks that must be resolved before build.
   **Do NOT invent answers** — list the decision and its constraints. (Honors the owner-approval
   gate: a story scopes the goal; it does not authorize a design.)
5. **`## Suggested shape`** *(non-binding)* — a sketch for discussion, explicitly marked non-binding.
6. **`## Definition of done`** — a checkbox list of what "done" means when the story graduates.
7. **`## Related`** — cross-references to ADRs, sibling issues, prior decisions (for future analysis).

### Approval-gate framing (when the story scopes future implementation)

If the issue describes work to be *built later*, state explicitly near the top:

> ⚠️ **Approval gate** — this issue *scopes the goal*. Implementation requires a separate
> propose-then-approve cycle. No code is authorised by this issue.

A new architectural decision ⇒ note that a **new ADR is likely needed** before build.

## Step 4 — Create

```bash
# GitLab
glab issue create \
  --title "<searchable title>" \
  --label "kind::feature" --label "area: …" \
  --description "$(cat /path/to/scratchpad/issue-body.md)"

# GitHub
gh issue create \
  --title "<searchable title>" \
  --label "kind::feature" --label "area: …" \
  --body-file /path/to/scratchpad/issue-body.md
```

Report back: the issue URL/number, the labels applied (noting they were reused, not invented),
and a one-line note on how title + labels + body make it searchable/filterable.

## Reuse-first reminder

Before filing, scan for a **duplicate** existing issue (`glab issue list --all` / search). If one
exists, update or comment on it instead of opening a parallel story.

## Why this is a skill + a CLAUDE.md pointer (not memory)

Memory is project-local and arrives as background context (a nudge, not an enforced rule) — it
would neither travel across repos nor reliably fire. This skill holds the verbose template at
**zero token cost until invoked**; a 3-line pointer in `~/.claude/CLAUDE.md` is the always-on,
cross-project trigger that routes every issue-creation here. Lean trigger + detailed skill.
