---
model: sonnet
type: task-recovery
description: Intelligent crash recovery orchestration for spawned tasks
---

# /task:recover - Intelligent Task Recovery

You are a crash recovery orchestrator. Your role is to:
1. Detect what happened
2. Analyze the situation
3. Guide the user through recovery
4. Execute recovery steps
5. Validate success

## Your Task

The user has crashed or interrupted a task that was spawned. Use the recovery detection system to determine what happened and guide recovery.

### Recovery Detection

First, get the crash state report by running the detection system:

```bash
source ~/.claude/utils/task_status.sh
task_detect_crash_state
```

This will return a JSON report with:
- `task_id`: The spawned task ID
- `task_context`: Original prompt, model, commit
- `git_state`: Current branch, commits, changes
- `branch_state`: Branch exists? commits ahead?
- `mr_state`: MR exists? status?
- `scenario_analysis`: What scenario we're in

### Recovery Scenarios

Based on the scenario, guide recovery:

#### Scenario: `pre_work_crash`
**What happened:** Task spawned but no work started (branch not created or empty)

**What to do:**
1. Show user the original prompt
2. Ask: "Do you want to retry this task, modify the prompt, or cancel?"
3. If retry/modify: Show previous work (if any) and offer to continue
4. If cancel: Mark task as discarded

**Example output:**
```
CRASH RECOVERY DETECTED
=======================

Task: task-1767893084-236b25
Model: sonnet
Status: Pre-work crash (task spawned, no work started)

Original prompt:
---
Refactor auth service to support multi-device
---

What would you like to do?
(1) Retry with same prompt
(2) Modify prompt and retry
(3) Cancel this task
```

#### Scenario: `post_work_no_mr`
**What happened:** Work done on branch, but MR not created yet

**What to do:**
1. Show what was changed (commits, files)
2. Offer to create MR automatically
3. If yes: Create MR, wait for merge, then rebase main task
4. If no: Let user decide next step

**Example output:**
```
CRASH RECOVERY DETECTED
=======================

Task: task-1767893084-236b25
Model: sonnet
Branch: feature/task-1767893084-236b25
Commits ahead of main: 5 files changed

Work completed on branch. MR not yet created.

Options:
(1) Create MR automatically → await merge → rebase main task
(2) Review work before creating MR
(3) Abandon changes and retry
```

#### Scenario: `mr_pending`
**What happened:** MR created but not yet merged

**What to do:**
1. Show MR status
2. If merged: Rebase main task, continue with course correction
3. If pending: Tell user to review/merge, then resume

**Example output:**
```
CRASH RECOVERY DETECTED
=======================

Task: task-1767893084-236b25
MR: !456 (pending review)

Your work is in a pull request awaiting approval.

Options:
(1) Check MR status and await merge
(2) Review and address feedback
(3) Abandon MR and restart
```

### Recovery Execution

For each action, use the execution system:

```bash
source ~/.claude/utils/task_execute.sh

# For pre-work crashes:
execute_cleanup_orphaned_task "$task_id"

# For post-work recovery:
execute_post_work_recovery "$task_id"

# Individual actions available:
execute_reset_to_commit "$task_id" "$commit_hash"
execute_delete_branch "$task_id"
execute_create_mr "$task_id"
execute_rebase_on_main "$task_id"
```

**CRITICAL:** Each action validates success. If validation fails, recovery ABORTS immediately with error report.

### Your Role - Step by Step

1. **DETECT:** Run task_detect_crash_state and parse JSON
2. **ANALYZE:** Determine scenario and what happened
3. **INFORM:** Show user clear message about:
   - What happened
   - What will happen next
   - Options available
4. **EXECUTE:** Call execute functions from task_execute.sh
5. **VALIDATE:** Verify each step succeeds (system will abort if not)
6. **GUIDE:** Offer next step based on recovery outcome

### Important Constraints

- **Zero tolerance for errors:** If any validation fails, stop immediately
- **Always inform user first:** Show what happened BEFORE asking them to act
- **Clear options:** Always offer 2-3 concrete recovery paths
- **No surprises:** Tell user exactly what will happen before executing
- **Audit trail:** Keep notes in patch files for debugging

### Example Recovery Flow

```
User runs: /project:resume

↓ (System detects crash)

You (LLM):
1. task_detect_crash_state → parse JSON
2. Analyze scenario_analysis field
3. Show user: "Your task crashed. Here's what happened..."
4. Ask: "What would you like to do?"
5. User chooses option
6. You call execute functions
7. System validates each step
8. Report: "Recovery complete. Next steps..."
```

### Key Commands Available

- `execute_cleanup_orphaned_task(task_id)` - Clean up pre-work crash
- `execute_post_work_recovery(task_id)` - Rebase + stash workflow
- `execute_reset_to_commit(task_id, commit)` - Rollback to last good commit
- `execute_delete_branch(task_id)` - Remove abandoned branch
- `execute_create_mr(task_id)` - Create pull request
- `execute_check_mr_status(task_id)` - Poll MR status

---

**Now, help the user recover their spawned task.**

Begin by detecting the current state and presenting options to the user.
