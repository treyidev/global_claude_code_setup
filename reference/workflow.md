# Feature Development Workflow

> Standard practice for all non-trivial features. No exceptions.
> Read this when starting new features, creating PRs, or onboarding.

---

## Overview
```
Epic → Integration branch → Issues → Feature branch (off integration) → Playground →
Verify → Commit → Test → MR → Review → Merge into integration   ⟲ per unit
… then, epic done: one MR integration → main
```

Every feature follows this flow. A multi-unit epic gets an **integration branch** off `main`; each
unit is a feature branch off *that* (not `main`), reviewed back into integration, and the whole epic
lands on `main` in one final MR (see *Branch Strategy* below). Shortcuts lead to messy rollbacks.

---

## Step-by-Step Process

### 1. Planning & Tracking (GitLab)

| Step | Action |
|------|--------|
| **Epic** | Create epic capturing brainstorming, architecture decisions, scope |
| **Issues** | Break down into subtasks/issues under the epic |
| **Labels** | Tag with priority, component, type (feature, refactor, bug) |

#### Epic Content Template
```markdown
## Overview
[What problem are we solving?]

## Architecture Decisions
[Key design choices and rationale]

## Scope
- In scope: [list]
- Out of scope: [list]

## Subtasks
- [ ] Issue #1: ...
- [ ] Issue #2: ...

## Open Questions
[Things to resolve during implementation]
```

---

### 2. Branch Strategy — integration branch per epic (two-tier)

A multi-unit epic does **not** merge unit-by-unit into `main`. It gets a long-lived
**integration branch**; each unit is a **feature branch off that integration branch**; units merge
**back into integration via MR**; and the whole epic lands on `main` in **one** final MR. `main`
only ever receives whole, proven epics (plus genuinely standalone single-unit work).

```bash
# 1. Epic ⇒ one integration branch off main (long-lived; lives for the epic's duration)
git checkout main && git pull
git checkout -b integration/<epic-slug>
git push -u origin integration/<epic-slug>

# 2. Each unit ⇒ a feature branch OFF THE INTEGRATION BRANCH (never off main)
git checkout integration/<epic-slug> && git pull
git checkout -b feat/<epic-slug>-<unit>      # or fix/… , refactor/… , test/…
# … implement + test + document …

# 3. Feature → integration via MR (target = the integration branch), after review + validation.
#    Repeat 2–3 for every unit in the epic.

# 4. Epic done ⇒ ONE MR merges integration → main.
```

#### Rules

| Rule | Rationale |
|------|-----------|
| Epic ⇒ its own `integration/<epic-slug>` branch off `main` | Keeps `main` clean while the epic is in flight |
| One feature branch per logical unit, **off the integration branch** | Atomic, reviewable MRs that don't touch `main` |
| Feature → integration via MR (reviewed + validated) — never feature → `main` | Per-unit gate; integration stays releasable |
| Epic complete ⇒ one MR integration → `main` | Whole-epic gate; `main` history reads as proven epics |
| Never commit directly to `main` **or** the integration branch | All changes flow through an MR gate |
| No epic (standalone single unit)? Branch directly off `main` | The integration tier is only for multi-unit epics |

> **GitLab Free has no first-class Epics** — use a **parent tracking issue** with a task-list of
> child issues as the epic (see global `CLAUDE.md` *Issue / Story Tracker Convention*). The
> integration branch is named for that epic; child-issue MRs target the integration branch and tick
> the parent's checklist on merge.
>
> **A unit already merged to `main`** before the epic adopted this model stays there as the
> foundation — fork the integration branch from the current `main` (it already contains that unit)
> and carry the remaining units on it.

---

### 3. Playground-First Development

**Experiment in playground before committing to package code.**
```
grades/playground/src/playground/scenes/  ← Experiment here first
packages/*/src/*/                          ← Move here after verification
```

| Phase | Location | Purpose |
|-------|----------|---------|
| **Experiment** | `playground/scenes/` | Quick iteration, visual verification |
| **Verify** | Run scene, check output | Confirm behavior matches expectations |
| **Formalize** | Package source | Clean implementation with full docs |

#### Why Playground First?

1. **Fast iteration** - No need to maintain quality during exploration
2. **Visual verification** - See results immediately
3. **Safe to break** - Playground is disposable
4. **Clear promotion path** - Working code moves to packages

---

### 4. Implementation Checklist

For each feature unit:

- [ ] Create feature branch
- [ ] Implement in playground for rapid testing
- [ ] Visually verify behavior (run scenes, check output)
- [ ] Move to package with proper structure
- [ ] Add type hints and comprehensive docstrings
- [ ] Write pytest tests
- [ ] Run full test suite
- [ ] Commit with conventional message
- [ ] Push and create PR
- [ ] Address review feedback
- [ ] Merge after approval

---

### 5. Testing Requirements

#### Test Types
```python
# Unit tests - logic and state
def test_eyelid_openness_clamps_to_bounds():
    """Verify openness is clamped to [0, 1] range."""
    eyelid = Eyelid(openness=1.5)
    assert eyelid.openness == 1.0
    
    eyelid = Eyelid(openness=-0.5)
    assert eyelid.openness == 0.0

# Graphical tests - visual behavior (Manim frame comparison)
@frames_comparison(last_frame=False)
def test_eyelid_blink_animation(scene):
    """Verify blink animation produces expected frames."""
    eye = Eye()
    scene.add(eye)
    scene.play(Blink(eye))
```

#### Coverage Expectations

| Requirement | Coverage |
|-------------|----------|
| All public methods | Unit tests |
| All animations | Graphical tests |
| Edge cases | Explicit tests |
| Error conditions | Exception tests |

---

### 6. Commit Conventions

#### Format
```
<type>: <description>

[optional body]

[optional footer]
```

#### Types

| Type | Use For |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes nor adds |
| `test` | Adding or correcting tests |
| `chore` | Maintenance, dependencies |

#### Rules

- **Author**: Abhijit Bandyopadhyay <abhijitb@gmail.com>
- **NO Co-Authored-By Claude** - Never add AI attribution
- **Imperative mood** - "Add feature" not "Added feature"
- **72 char limit** - For subject line

#### Examples
```bash
# Good
feat: add blink animation for Eye component
fix: clamp eyelid openness to valid range
refactor: extract pupil tracking to separate class
docs: add architecture diagram for Eye hierarchy

# Bad
Added blink animation  # Past tense
Fix stuff  # Vague
WIP  # Not descriptive
```

---

### 7. PR Protocol

#### PR Description Template
```markdown
## Summary
- What this PR implements
- Link to epic/issue: Closes #ISSUE_NUMBER

## Design Decisions
- Key choices made and why
- Alternatives considered

## Test Plan
- [ ] Unit tests pass
- [ ] Graphical tests pass
- [ ] Playground verification done
- [ ] Manual testing completed

## Screenshots/Videos
(Attach visual proof for UI/animation changes)

## Checklist
- [ ] Type hints on all signatures
- [ ] Docstrings on all public APIs
- [ ] No hardcoded values
- [ ] Semantic colors used
```

#### Review Process

1. **Author** creates PR with full description
2. **Reviewer** reviews code, runs tests
3. **Reviewer** provides feedback (approve, request changes, comment)
4. **Author** addresses feedback, pushes updates
5. **Reviewer** re-reviews if needed
6. **Reviewer** approves
7. **Author** merges (or reviewer, depending on policy)

---

### 8. Git Workflow Commands

#### Daily Workflow
```bash
# Start new feature
git checkout main
git pull origin main
git checkout -b feature/epic-name/component-name

# Work on feature
# ... make changes ...
git add -p  # Stage selectively
git commit -m "feat: implement component"

# Push and create MR
git push origin feature/epic-name/component-name -u

# Create MR on GitLab (NOT GitHub)
glab mr create --base main --title "feat: implement component" \
    --description "Closes #123"
```

#### Sync and Rebase
```bash
# Keep feature branch up to date
git checkout feature/my-feature
git fetch origin
git rebase origin/main

# If conflicts, resolve then:
git rebase --continue
```

#### After Merge
```bash
# Clean up local branch
git checkout main
git pull origin main
git branch -d feature/my-feature

# Push to both remotes
git push origin main
git push github-mirror main
```

---

## Why This Workflow?

| Problem | Solution |
|---------|----------|
| Messy git rollbacks | Feature branches + PRs |
| Breaking changes to main | PR review gate |
| "Works on my machine" | Playground verification first |
| Regressions | Pytest suite |
| Lost context | Epic with brainstorming details |

> "No more `git reset --hard`. Branches are cheap. Experimentation is encouraged."

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Do Instead |
|--------------|--------------|------------|
| Commit directly to main | Bypasses review | Always use feature branches |
| Huge PRs | Hard to review, risky | Break into smaller PRs |
| "WIP" commits | No context | Write descriptive messages |
| Skip playground | Bugs in package code | Always prototype first |
| Skip tests | Regressions | Tests are mandatory |
| Force push to shared branch | Loses others' work | Only force push personal branches |