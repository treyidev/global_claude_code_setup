---
model: sonnet
argument-hint: "[merged-branch-name]"
description: Post-merge housekeeping via a Sonnet subagent — sync main, clean branches, push mirror, verify remotes
---

# /post-merge

Run after an MR/PR merges. **Owner directive (2026-07-14): merge housekeeping is DELEGATED to a
Sonnet subagent, never run inline in the main (expensive) context** — the subagent absorbs the
verbose pre-push/CI hook output and returns only a summary. This skill is the durable, versioned
encoding of that directive (the auto-memory copy is machine-local).

## Arguments

- `[merged-branch-name]` — the source branch that just merged. If omitted, infer it from the
  merge commit on the remote default branch (`git log origin/main --merges -1`) and confirm the
  inference in the report.

## Steps

1. Spawn a **general-purpose subagent with `model: sonnet`** (Agent/Task tool) with this exact
   task — do not run these commands inline:

   > Post-merge housekeeping for the repo at `<repo-root>`; branch `<branch>` just merged.
   > In order: (1) `git fetch origin --prune`. (2) `git switch <default-branch>` +
   > `git pull --ff-only` — non-fast-forward ⇒ STOP and report. (3) Delete the local branch
   > with `git branch -d` (lowercase only; refusal ⇒ STOP and report — never `-D`).
   > (4) Verify the remote branch is gone (`git ls-remote origin <branch>`); if the host did
   > not auto-delete it, `git push origin --delete <branch>`. (5) If a mirror remote exists
   > (e.g. `github`), push the default branch to it. **Run this push in the FOREGROUND and
   > wait for it to exit — NEVER background it and NEVER end your turn while it is running.**
   > A pre-push hook may run a full Docker CI pipeline taking several minutes; that is
   > expected — wait for it. Returning early KILLS the push mid-run, which leaves an
   > orphaned container pinning Docker volumes and breaks the *next* push (see the failure
   > note below). Report its exit status explicitly. (6) Verify local / origin / mirror SHAs
   > are identical (`git rev-parse` + `git ls-remote`). **Report the mirror SHA you actually
   > observed — "a push was started" is NOT evidence a push succeeded; if the mirror SHA does
   > not match, that is a deviation, report it.** NO force-pushes, NO other branches,
   > NO commits. Report: final SHA, three-remote match, deletion status, deviations verbatim.

2. On the subagent's report: relay the outcome (final SHA, remotes-in-sync, deletions). Any
   deviation (non-ff, unmerged branch, SHA mismatch) is surfaced to the owner verbatim — never
   auto-resolved.

   **VERIFY, do not relay on trust.** A subagent cannot "wait" across its own return — returning
   terminates it and every process it spawned, with no notification to anyone and its output file
   truncated mid-line. So before reporting success, independently confirm the end state yourself:
   `git rev-parse main`, `git ls-remote origin main`, `git ls-remote <mirror> main` must all match.
   If the subagent's report says a push is "in progress" or that it will "wait for" something,
   treat that as **step 5 did not complete** and finish the push yourself in the foreground.

   > **Real failure this encodes (2026-08-02, gazers-universe MR !65).** The subagent backgrounded
   > the mirror push, then returned with *"I'll pause here and wait for the background push to
   > finish."* The push was killed mid-CI; its output ended at
   > `local clean-room CI gate …......` with no verdict. Nothing was running, no notification was
   > ever coming, and the main context relayed "mid-way through step 5" without checking — it would
   > have waited forever had the owner not asked. The killed run also left a `Created`-state
   > container pinning two `gcl-*` volumes, so the *next* push failed on volume removal. One
   > command (`git ls-remote <mirror> main` vs `git rev-parse main`) would have caught it
   > immediately.

3. Apply the post-commit checkpoint judgment (global CLAUDE.md): if the merged unit's write-up
   has not yet moved to `.claude/tasks/archive.md` per the three-tier protocol, flag it —
   the move should have happened in the unit's own MR.
