---
model: sonnet
allowed-tools: Read, Write, Bash(git:*)
description: Save current progress mid-session
---

# Checkpoint Current Progress

Save session state without ending the session.

## Context
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Time: !`date "+%Y-%m-%d %H:%M"`

## Steps

1. Gather current state:
   - What task is currently in progress?
   - What has been completed since last checkpoint?
   - What decisions have been made?
   - Any blockers or open questions?

2. Update `.claude/SESSION.md`:
   - Last Updated: [current timestamp]
   - Current Focus: [active work]
   - Status: [in_progress / blocked / waiting]
   - Completed: [list items done]
   - Next Steps: [immediate actions]
   - Decisions: [key choices made]
   - Blockers: [if any]

3. Update `.claude/TASKS.md`:
   - Move completed tasks to "Completed This Session"
   - Add timestamps to completed items
   - Add any newly discovered tasks to backlog

4. Pattern verification (self-check):
   - Am I following CLAUDE.md patterns?
   - Any drift from established conventions?
   - Note corrections needed

5. Confirm checkpoint saved:
   ```
   ✓ Checkpoint saved at [timestamp]

   Progress:
   - Completed: [count] tasks
   - In Progress: [current task]
   - Remaining: [count] tasks

   Continuing...
   ```
