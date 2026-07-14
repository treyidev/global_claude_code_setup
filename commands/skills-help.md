---
model: sonnet
allowed-tools: Read, Glob, Grep
argument-hint: "[with-examples] [skill-name]"
description: Live catalog of all your skills (global + project) — what each does, how to invoke it, with examples on demand
---

# /skills-help

Show everything invocable in the current session from YOUR skill tiers: **global**
(`~/.claude/commands/*.md`) and **project-local** (`./.claude/commands/*.md`). ALWAYS scan the
directories live at invocation — never answer from a remembered list (skills change; a stale
catalog is worse than none).

## Arguments

| Invocation | Behaviour |
|---|---|
| `/skills-help` | Compact grouped catalog of every skill |
| `/skills-help with-examples` | Catalog + one realistic invocation example per skill |
| `/skills-help <skill-name>` | Deep dive on that one skill (full usage, arguments, 2 examples, related skills) |
| `/skills-help with-examples <skill-name>` | Same as deep dive (examples are always included there) |

## Steps

1. **Enumerate both tiers:**
   - Global: `~/.claude/commands/*.md`
   - Project: `./.claude/commands/*.md` (relative to the project root)
   - Same filename in both ⇒ the **project version shadows the global one** in this repo — show
     the project one as active and note the global fallback in the Tier column
     (`project (shadows global)`).
   - Non-`.md` entries (e.g. `task_spawn.sh`, `shared-memory/`) are helper tooling, not
     Skill-tool skills — list them in a short footnote with their invocation form (`bash` path).

2. **For each skill file**, read the frontmatter (`description`, `model`, `argument-hint`,
   `allowed-tools`) and skim the body for purpose, when-to-run, and any arguments/parameters
   the body defines beyond the frontmatter.

3. **Output — grouped catalog** (group by role; omit empty groups):

   ```text
   ## Your skills — <N> global · <M> project (<repo-name>)

   ### Session continuity
   | Skill | Tier | Model | What it does | When to use |
   |---|---|---|---|---|
   | /resume | global | sonnet | ... | session start |

   ### Code review        (… same columns)
   ### Workflow & tracking (… issue/story, commit helpers)
   ### Docs               (… /sync-docs)
   ### Task ops / recovery (… /task_recover, spawn tooling footnote)
   ```

4. **If `with-examples` was passed:** after each group's table, add one realistic, copyable
   example per skill — real paths/arguments from THIS project where possible, plus the expected
   outcome in half a sentence. Example shape:

   ```text
   /review-backend platform/backend/core/src/gazers_core/cache.py
     → severity-table review of the cache seam against house dimensions + U1–U8
   ```

5. **If a skill name was passed:** skip the catalog; deep-dive that skill only — description,
   tier + shadowing status, model, all arguments, a summary of its steps, TWO realistic
   examples, and its related skills (e.g. `/checkpoint` ↔ `/handoff` ↔ `/resume`). If the name
   matches nothing, say so and list the closest matches.

6. **Scope note (print once, small):** plugin- and harness-provided skills (e.g. plugin review
   or research commands) are surfaced by the harness itself and are not files in these two
   directories — this catalog covers the skills YOU own and version.

7. **ALWAYS end with the self-reference footer** — the catalog must advertise itself, so it is
   never forgotten:

   ```text
   ─────────────────────────────────────────────────────────
   📚 This catalog: /skills-help · /skills-help with-examples · /skills-help <skill-name>
   ```
