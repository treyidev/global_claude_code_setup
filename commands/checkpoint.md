---
model: sonnet
allowed-tools: Read, Write, Edit, Bash(git:*)
description: Save current progress when state has meaningfully changed
---

# Checkpoint Current Progress

Save session state — when there is something meaningful to save. Most
invocations should be no-ops; the bar is whether future sessions need
to know something they would not get from `git log` and the current code.

## When to run

Two invocation paths:

1. **Manual.** User invokes `/checkpoint` directly. Run the full
   judgment below.

2. **Post-commit.** After every successful `git commit`, when the
   project's `.claude/auto-checkpoint` marker is present, the
   assistant applies the same judgment per the global rule in
   `~/.claude/CLAUDE.md` under "Post-commit checkpoint judgment"
   (within Proactive Prompting Rules). Most commits no-op.

   This is a manual discipline applied by the assistant
   proactively, NOT a runtime trigger. No `PostToolUse` hook in
   `~/.claude/settings.json` binds `Bash(git commit*)` to this
   skill; earlier wording in this file describing a "post-commit
   auto-trigger" was aspirational. The discipline lives in the
   global rule; this skill provides the judgment criteria and the
   SESSION.md shape that the rule applies.

Projects opt in by creating an empty `.claude/auto-checkpoint`
file. Absent that file, only manual `/checkpoint` invocations
trigger the judgment.

## Context
- Branch: !`git branch --show-current`
- Status: !`git status --short`
- Triggering commit: !`git log --oneline -1`
- Recent context (last 5): !`git log --oneline -5`
- Time: !`date "+%Y-%m-%d %H:%M"`
- Auto-trigger active: !`test -f .claude/auto-checkpoint && echo yes || echo no`

## Judgment: does this checkpoint warrant an update?

Ask: **"what did we learn or decide that future sessions need to know?"**
If the honest answer is "nothing notable — this was mechanical execution
of a previously-decided plan," produce no update and exit with a no-op
confirmation.

**When auto-triggered, evaluate against the triggering commit specifically.**
Earlier commits in "Recent context" are context, not subject. The question
"did this commit change what future sessions need to know?" is about
the triggering commit, not the last five.

**Signals worth checkpointing:**

- Architectural decisions resolved
- Unexpected verification results that updated the mental model
- Productive pushback from the user that refined the working approach
- Pivots between different work threads
- Near-misses (paths considered then rejected) that hold signal
- A scope completed (phase, feature, MR landed)

**Signals NOT worth checkpointing:**

- Routine task progress where the plan did not change
- Successful execution of a previously-decided approach
- Small mechanical commits (lint fixes, formatting, typo corrections,
  dependency bumps)

If unsure, lean toward no-op. A stale SESSION.md is worse than an
absent update.

## Steps

1. Read current state to compare against what's about to be written:
   - `.claude/SESSION.md` (existing snapshot, if any)
   - `.claude/TASKS.md` (existing backlog, if any)
   - Triggering commit (above) — the focus of judgment
   - Recent context (above) — surrounding commits

2. Gather candidate facts:
   - What task is currently in progress?
   - What has been completed since last checkpoint?
   - What decisions have been made?
   - Any blockers or open questions?

3. Apply the judgment above. If no update warranted, skip to step 6
   with a no-op confirmation.

4. Refresh `.claude/SESSION.md` in place (single snapshot, overwrite).
   Use the canonical shape:
   - Last Updated: [current timestamp]
   - Branch: current branch + parenthetical (clean / N ahead / etc.)
   - Current Focus: [active work]
   - Status: [in_progress / blocked / waiting]
   - Completed This Session: [grouped by feature/MR if multiple]
   - In Progress: explicit, or "Nothing partially complete"
   - Next Steps: [immediate actions]
   - Blockers: explicit, or "None"
   - Key Decisions (this session): table format (Decision | Choice)
   - Repo-specific reference sections (commands, gotchas, resume
     protocol) at the end if helpful

5. Update the task tiers if the backlog actually changed (three-tier
   standard — global CLAUDE.md §"🗂️ Session continuity"):
   - Shipped unit ⇒ move its write-up to `.claude/tasks/archive.md` with a
     date stamp (`[x] **YYYY-MM-DD** — description`); a one-liner stays in
     TASKS.md only while its parent epic is still open. Lift any embedded
     open fragment into `backlog.md` (never bury open work in the archive).
   - Newly discovered work ⇒ `.claude/TASKS.md` if in-flight/approved;
     `.claude/tasks/backlog.md` if gated/deferred (record need +
     activation trigger — never bare YAGNI).
   - **Obligation ledger, where the project has one** (`.claude/tasks/obligations.toml` —
     gazers-universe issue #91): a new cross-cutting owed item (a tracker note owed, a
     pending owner action, a cleanup promise) becomes a ledger record with a
     machine-evaluable close condition (declarative predicate preferred; `honor` + reason
     only when genuinely unmechanisable); a closed obligation's entry is DELETED in the
     closing commit — the gate fails satisfied-but-present entries.
   - If no tier's content changed, do not rewrite any of them.

   **Whatever you write here is durable only once COMMITTED.** A checkpoint that leaves a tier
   file staged-but-uncommitted has not saved anything the next session can read — it looks fine
   locally and vanishes on a `git checkout .` or a fresh clone, with no error (this is the
   `be526ac` failure: a handoff written, staged, never committed). A checkpoint mid-work
   legitimately leaves them dirty, so this is a note rather than a gate — but the moment the
   work is committed, verify with `git show --stat HEAD` that the tier files are in it. The
   global `~/.claude/hooks/working_memory_sync_gate.py` hook is the deterministic backstop: it
   denies any `git push` while a tier file is uncommitted, in every project.

6. Confirm:

   **If updates were made**, run a focused self-check first: is the
   artifact I just wrote consistent with CLAUDE.md patterns? Any drift
   from established conventions in the written content? Note corrections
   needed. Then confirm:

   ```text
   ✓ Checkpoint saved at [timestamp]
   Updated: SESSION.md [+ TASKS.md if applicable]
   Reason: [one-line summary of what changed in understanding]
   ```

   **If no update warranted**, skip the self-check entirely and confirm:

   ```text
   ✓ Checkpoint no-op at [timestamp]
   Nothing notable since last update — leaving SESSION.md unchanged.
   ```
