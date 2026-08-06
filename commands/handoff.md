---
model: sonnet
allowed-tools: Read, Write, Edit, Bash(git:*)
description: Persist session state for next session
---

# Session Handoff

Preserve all context for the next Claude Code session.

## Context
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Recent commits: !`git log --oneline -5`

## Steps

1. Write `.claude/SESSION.md` with:
   - **Last Updated**: Current timestamp
   - **Branch**: Current branch name
   - **Current Focus**: What was being worked on
   - **Status**: completed / in-progress / blocked
   - **Completed This Session**: List of finished tasks
   - **In Progress**: Partially complete work
   - **Next Steps**: Explicit, actionable items
   - **Blockers**: Any decisions needed or issues
   - **Files Touched**: Key files modified
   - **Key Decisions**: Important choices made

   > **No self-invalidating references (owner directive 2026-08-06).** SESSION.md must never
   > assert its *own carrier* (the branch/MR this very handoff rides) as live state, and must
   > never list "owner: merge this handoff's MR" as a tracked next step — both go stale the
   > instant the owner merges, and fixing the staleness would take another sync commit → MR →
   > merge → another stale reference: the recursion that blocked clean handoffs in
   > gazers-universe sessions 23–24 (MRs !72/!73). Write only merged, SHA-anchored facts;
   > `git log -1` names the carrier if it ever matters. The complementary fix lives in
   > `/post-merge` (its sync-only-MR taper skips tier reconciliation for handoff merges).

2. Documentation Impact Check:
   - Did I add/remove/rename any public APIs?
   - Did I move files between packages?
   - Did I introduce new patterns?
   - Did I deprecate existing patterns?

   If YES to any:
   - Note in SESSION.md under "Documentation Updates Needed"
   - List specific CLAUDE.md files affected

3. Update the task tiers (three-tier standard — global CLAUDE.md
   §"🗂️ Session continuity"):
   - `.claude/TASKS.md` (HOT): finalize in-flight / blocked-on-owner /
     approved items with timestamps
   - Shipped write-ups → `.claude/tasks/archive.md`; gated/deferred items →
     `.claude/tasks/backlog.md` (need + activation trigger preserved)
   - Ensure no DONE prose is left accumulating in TASKS.md

4. Verify uncommitted changes:
   - If uncommitted work exists, note in SESSION.md
   - Suggest: "Uncommitted changes exist. Commit before closing?"

5. **Durability check — the handoff is not done until it is COMMITTED (never skip this).**
   Writing the files is not persisting them. A tier file left staged-but-uncommitted looks
   fine locally and is invisible to the next session; one `git checkout .`, or a fresh clone,
   and the whole handoff is gone with no error and no signal.

   > **Placement (owner rule 2026-08-06): commit tier files DIRECTLY to the durable
   > designated branch and push — NEVER open an MR for a session sync.** Designated = the
   > repo's default branch when no epic is in flight (or the recorded facts are already
   > merged); the live epic's `integration/*` branch while its epic is open, with `main`'s
   > SESSION.md carrying a one-line pointer to that branch. Never leave session state on an
   > ephemeral feature branch — GitLab auto-deletes those post-merge, and sync MRs recurse
   > (the gazers-universe handoff-recursion lesson). Canonical rule: global `~/.claude/CLAUDE.md`
   > §"🗂️ Session continuity".

   Run `git status --short .claude/` and confirm every tier file you touched is either
   committed or deliberately staged for a commit you are about to make. Then, after
   committing, VERIFY with `git show --stat HEAD` that each one is actually in the commit —
   do not assume `git add .claude/` caught them.

   > **Real failure this encodes** (gazers-universe `be526ac`, 2026-08-04): this skill wrote
   > SESSION.md, the sync commit that followed included TASKS.md + backlog.md but NOT
   > SESSION.md, and the entire session-20 handoff survived only as a staged working-tree
   > change that happened to travel across a later branch switch. `/resume` would have loaded
   > the session-19 snapshot and presented it as current.

   Two deterministic backstops exist, but neither replaces this step — both fire at `git push`,
   which may be much later than the handoff, and only the first is global:
   - `~/.claude/hooks/working_memory_sync_gate.py` — GLOBAL PreToolUse(Bash) hook; denies any
     `git push` Claude issues while a tier file is dirty, in every project.
   - a repo's own pre-push hook where one exists (e.g. gazers-universe's `working-memory-sync`
     pre-commit hook) — also catches pushes a human types in a terminal.

6. Confirm handoff:
   ```
   ✓ Handoff Complete
   ─────────────────────
   Session saved to .claude/SESSION.md
   Committed:    [commit SHA, or "NOT YET — <what still needs committing>"]

   Next session: Run /resume

   Summary:
   - Completed: [count] tasks
   - In Progress: [task]
   - Next: [first next step]
   ```
