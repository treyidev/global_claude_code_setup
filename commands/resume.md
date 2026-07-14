---
model: sonnet
allowed-tools: Read, Glob, Write, Edit, Bash(git:*)
description: Resume session from previous state
---

# Resume Previous Session

Load context from last session and continue work.

## Steps

1. Read session state:
   - !`cat .claude/SESSION.md 2>/dev/null || echo "No SESSION.md found"`

2. Read task tracker:
   - !`cat .claude/TASKS.md 2>/dev/null || echo "No TASKS.md found"`

3. **Format alignment — three-tier standard (global CLAUDE.md §"🗂️ Session continuity").**
   If `.claude/TASKS.md` exists in the OLD monolithic format — DONE write-ups and/or
   approval-gated backlog inline, no `.claude/tasks/` directory — **align it FIRST**,
   before any other work this session:
   - Create `.claude/tasks/archive.md` — move shipped/DONE write-ups there **verbatim**.
   - Create `.claude/tasks/backlog.md` — move approval-gated + deferred items there,
     preserving each item's need + activation-trigger wording.
   - Slim `.claude/TASKS.md` to the HOT tier only (in-flight · blocked-on-owner ·
     approved queue) and prepend the movement-protocol header (copy it from an
     already-aligned project, e.g. gazers-universe).
   - An archived write-up carrying an embedded open fragment (deferred sub-item,
     pending owner action): lift that fragment into `backlog.md` with a pointer back —
     archiving must never bury open work.
   - Moves are **verbatim** — never rewrite, dedupe, or "improve" content while
     migrating. Content edits (stale items, rewording) are a separate, owner-approved
     pass.
   - Respect the project's git workflow (e.g. branch + MR where direct-to-main is
     forbidden) and report the migration in the resume summary.

   Already-aligned projects (a `.claude/tasks/` directory exists): skip this step.

4. Check git state:
   - Branch: !`git branch --show-current`
   - Status: !`git status --short`
   - Recent: !`git log --oneline -3`

5. Summarize to user — ALWAYS include the skills-catalog footer as the last lines (owner
   directive 2026-07-14: never let the catalog be forgotten):
   ```
   📍 Resuming Session
   ─────────────────────
   Last Focus: [from SESSION.md]
   Branch: [current branch]

   In Progress:
   - [active tasks]

   Next Steps:
   1. [from SESSION.md]

   Continue with next step, or redirect?
   ─────────────────────
   📚 Skills catalog: /skills-help · /skills-help with-examples · /skills-help <skill-name>
   ```

6. If no SESSION.md exists:
   - Suggest: "No previous session found. Run /init to start tracking."
