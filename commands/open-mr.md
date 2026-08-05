---
model: sonnet
argument-hint: "[closes-issue-number] [target-branch]"
description: Open an MR/PR from the current branch, applying the house MR-anatomy conventions
---

# /open-mr

Open a merge request from the current branch, applying the MR-anatomy conventions from
`~/.claude/reference/workflow.md` §7 — that table is the law; this skill is the procedure.
Counterpart of `/post-merge` (run that after the merge).

## Arguments

- `[closes-issue-number]` — the issue this MR closes (e.g. `36`). Omit ONLY for
  working-memory/plumbing MRs the owner has explicitly sanctioned as issue-free — and say so
  in the description's Process section.
- `[target-branch]` — override the target. Default: the branch's fork point — the matching
  `integration/<epic-slug>` branch if this is an epic unit, else the repo's default branch.

## Steps

1. **Preflight:**
   - `git status --short` — uncommitted changes ⇒ STOP and ask (commit them or confirm they
     stay behind).
   - Branch pushed and up to date? If not: push through the project's **normal** push gate.
     `--no-verify` ONLY with an explicit owner sanction for this change class — and that
     sanction gets disclosed in the MR description (exceptions are per-context, never standing).
   - Detect the host from `git remote get-url origin`: GitLab ⇒ `glab mr create`,
     GitHub ⇒ `gh pr create`.

2. **Target resolution:** honor the override argument; else, if the branch forked from an
   `integration/*` branch (`git merge-base` against candidates), target that (two-tier epic
   model); else the default branch.

3. **Compose:**
   - **Title:** conventional-commit style, from the branch's commits — searchable summary, no
     `Closes` in the title (it does nothing there).
   - **Description sections:** `## What` (summary; a small table for multi-file changes) ·
     `## Why` · `## Verification` (gates/tests run, fidelity checks — state failures plainly) ·
     `## Process` (sanctions/exceptions disclosed; issue-free rationale when no issue).
   - **`Closes #N` goes IN THE DESCRIPTION BODY** — GitLab scans only descriptions for
     auto-close keywords; title-only silently fails (the MR !40 lesson, 2026-07-14).

4. **Create with assignee:**
   `glab mr create --source-branch <b> --target-branch <t> --assignee "@me" --title … --description …`
   (GitHub: `gh pr create --assignee "@me" …`).

5. **Report and STOP — the merge is the HUMAN GATE.** Report the MR URL, target, closes-ref,
   assignee — then hand off. **Claude NEVER merges** (`glab mr merge` / `gh pr merge` / API/UI
   equivalents) — no recipe wording ("→ MR → merge") overrides this; the owner merges (global
   CLAUDE.md §Git Conventions, owner directive 2026-07-26). After the OWNER has merged, run
   `/post-merge` (Sonnet-delegated housekeeping).
