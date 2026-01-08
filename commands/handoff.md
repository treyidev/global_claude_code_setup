---
model: sonnet
allowed-tools: Read, Write, Bash(git:*)
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

2. Documentation Impact Check:
   - Did I add/remove/rename any public APIs?
   - Did I move files between packages?
   - Did I introduce new patterns?
   - Did I deprecate existing patterns?

   If YES to any:
   - Note in SESSION.md under "Documentation Updates Needed"
   - List specific CLAUDE.md files affected

3. Update `.claude/TASKS.md`:
   - Finalize completed tasks with timestamps
   - Ensure backlog is current

4. Verify uncommitted changes:
   - If uncommitted work exists, note in SESSION.md
   - Suggest: "Uncommitted changes exist. Commit before closing?"

5. Confirm handoff:
   ```
   ✓ Handoff Complete
   ─────────────────────
   Session saved to .claude/SESSION.md

   Next session: Run /project:resume

   Summary:
   - Completed: [count] tasks
   - In Progress: [task]
   - Next: [first next step]
   ```
