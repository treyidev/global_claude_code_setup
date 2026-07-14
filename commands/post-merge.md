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
   > (e.g. `github`), push the default branch to it. (6) Verify local / origin / mirror SHAs
   > are identical (`git rev-parse` + `git ls-remote`). NO force-pushes, NO other branches,
   > NO commits. Report: final SHA, three-remote match, deletion status, deviations verbatim.

2. On the subagent's report: relay the outcome (final SHA, remotes-in-sync, deletions). Any
   deviation (non-ff, unmerged branch, SHA mismatch) is surfaced to the owner verbatim — never
   auto-resolved.

3. Apply the post-commit checkpoint judgment (global CLAUDE.md): if the merged unit's write-up
   has not yet moved to `.claude/tasks/archive.md` per the three-tier protocol, flag it —
   the move should have happened in the unit's own MR.
