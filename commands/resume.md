---
model: sonnet
allowed-tools: Read, Glob
description: Resume session from previous state
---

# Resume Previous Session

Load context from last session and continue work.

## Steps

1. Read session state:
   - !`cat .claude/SESSION.md 2>/dev/null || echo "No SESSION.md found"`

2. Read task tracker:
   - !`cat .claude/TASKS.md 2>/dev/null || echo "No TASKS.md found"`

3. Check git state:
   - Branch: !`git branch --show-current`
   - Status: !`git status --short`
   - Recent: !`git log --oneline -3`

4. Summarize to user:
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
   ```

5. If no SESSION.md exists:
   - Suggest: "No previous session found. Run /project:init to start tracking."
