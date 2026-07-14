---
model: sonnet
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git:*)
description: Reconcile code ↔ docs before an MR — CLAUDE.md triggers, package docs, doc builds, deferrals
---

# /sync-docs

Run **before opening an MR** (global CLAUDE.md → *Documentation Discipline*: docs ship in the
SAME MR as the build, never a follow-up). Reconciles what the branch changed against the
documentation that describes it. Report-then-fix: apply mechanical fixes directly on the
branch; flag anything needing owner wording instead of guessing.

## Steps

1. **Scope the change set** (what this branch actually touched):
   - Branch: !`git branch --show-current`
   - Changed files: !`git diff --name-status $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null || echo HEAD~10)..HEAD`

2. **Documentation-impact scan** — walk the CLAUDE.md triggers table against the diff:

   | Change found in diff | Documentation to update |
   |---|---|
   | New/changed/removed public API | Package README / barrel docstring + the package's CLAUDE.md |
   | File moved between packages | **Both** packages' CLAUDE.md |
   | New pattern used 2+ times | Root CLAUDE.md BAD/GOOD example |
   | Deprecated API | Remove or mark deprecated wherever documented |
   | New command / script / skill | Commands reference (root CLAUDE.md / README) |
   | Config or env-var change | Config section + `.env.example` if the project has one |

3. **Stale-doc sweep on touched files** — for every changed source file, check that its module
   header / docstrings / TSDoc still match the new behavior (a stale doc is worse than none —
   MUST-FIX class). Check any narrative doc (`docs/`) that names the changed symbols.

4. **Verify the docs build if the project has one** — run the project's documented build
   (e.g. mkdocs / TypeDoc / Storybook build) per its CLAUDE.md Commands section, from the
   directory it documents. New warnings introduced by this branch are findings; pre-existing
   ones are noted, not fixed here.

5. **Deferrals** — anything consciously left undocumented goes to `.claude/tasks/backlog.md`
   (three-tier standard, global CLAUDE.md §"🗂️ Session continuity") with the deferral
   protocol: need + activation trigger + dated ref + re-survey clause. Never a silent skip.

6. **Report:**

   ```text
   ## /sync-docs: <branch>
   | # | Status | Trigger | File | Action |
   |---|--------|---------|------|--------|
   | 1 | FIXED | New public API | pkg/CLAUDE.md | Added X to API list |
   | 2 | NEEDS-OWNER | New pattern ×2 | CLAUDE.md | BAD/GOOD example wording |
   | 3 | DEFERRED | ... | tasks/backlog.md | entry added (trigger: ...) |
   Docs build: <clean / N new warnings / not present>
   ```

   Zero gaps ⇒ `✓ Docs in sync with the branch.`
