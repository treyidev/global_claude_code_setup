# Global Claude Code Setup

**A versioned `~/.claude/` that makes Claude Code consistent, reliable, and powerful across every
project — on macOS, Linux, and Windows (WSL).**

This repo *is* the setup. Clone it to `~/.claude` on any machine and Claude Code behaves the same
everywhere: the same standards load, the same hooks fire, the same session/commands work. It is
mirrored to **GitLab (primary)** and **GitHub**.

- GitLab: <https://gitlab.com/treyipune/global_claude_code_setup>
- GitHub: <https://github.com/treyidev/global_claude_code_setup>

---

## TL;DR — set up on a new machine

```bash
# 1. Clone the setup into place (works on macOS /Users, Linux + WSL /home)
git clone git@gitlab.com:treyipune/global_claude_code_setup.git ~/.claude
cd ~/.claude
git remote add github https://github.com/treyidev/global_claude_code_setup.git

# 2. That's it. No path edits — everything resolves via $HOME / $CLAUDE_CONFIG_DIR.
#    Machine-specific bits (extra permissions, etc.) go in ~/.claude/settings.local.json (gitignored).
#    Plugins reinstall themselves from settings.json `enabledPlugins`.
```

To roll back to the last known-good pre-overhaul setup at any time:

```bash
git -C ~/.claude checkout old-setup-2026-06-18    # tag = restore point
```

---

## The mental model: how guidance is tiered (read this first)

The single most important idea. Guidance is organized by **how it loads**, so the always-on
context stays lean while rules stay enforced. (Full version: `CLAUDE.md` → *Instruction
architecture*.)

| Tier | Lives in | Loads | Use for |
|---|---|---|---|
| **1. Always-on core** | `CLAUDE.md` | every session | cross-language principles (SOLID, clean code, docs, git) + a 3-line core per language |
| **2. Path-scoped rules** | `rules/<topic>.md` (`paths:` frontmatter) | **deterministically, on-demand** when a matching file is touched | deep language/stack standards — *mandatory without bloat* |
| **3. Hooks** | `settings.json` + `hooks/` | deterministically on tool events | enforcement + tooling (format-on-write; inject a rule for new files) |
| **4. Skills** | `commands/*.md` | model- or user-invoked (`/name`) | optional multi-step **workflows** — *never* passive standards |

**Why it matters:** a standard placed in a **skill** can be silently skipped (invocation is
best-effort). A standard in a **path-scoped rule** is loaded by the harness, deterministically.
So: **standards are rules; procedures are skills.**

**Routing new guidance:** cross-language principle → `CLAUDE.md` · language/stack syntax →
`rules/<lang>.md` · must-run tooling / hard block → a hook · a chosen workflow → a skill.

---

## What's in here

```
~/.claude/
├── CLAUDE.md                 # Tier 1: always-on core (principles + per-language 3-line cores)
├── rules/                    # Tier 2: path-scoped, auto-loading per-language standards
│   ├── python.md             #   paths: **/*.py   (builtin generics, uv, docstrings, dataclasses…)
│   ├── kotlin.md             #   paths: **/*.kt,*.kts
│   ├── cpp.md                #   paths: **/*.cpp,*.h,…
│   └── java.md               #   paths: **/*.java
├── hooks/
│   └── inject_lang_rule.py   # Tier 3: PreToolUse(Write) — new-file safety net for rules/
├── settings.json             # permissions, model, plugins, HOOK WIRING (tracked)
├── settings.local.json       # machine-specific overrides (GITIGNORED — never pushed)
├── commands/                 # Tier 4: global skills + scripts
│   ├── resume.md / checkpoint.md / handoff.md   # session continuity  (/resume, /checkpoint, /handoff)
│   ├── task_recover.md       # crash recovery (/task_recover)
│   ├── shared_memory.md      # cross-IDE notes (/shared_memory)
│   ├── task_spawn.sh         # spawn hierarchical subtasks (shell script)
│   └── shared-memory/cmd.sh
├── utils/                    # bash utilities sourced by the commands above
├── reference/                # deep-dive docs (architecture, workflow, documentation-standards)
│   └── code-standards.md     #   now a thin pointer → CLAUDE.md + rules/
├── SESSION.md.template        # template for project-local .claude/SESSION.md
├── PLATFORM_INFRASTRUCTURE.md # full task-spawn / crash-recovery / session reference
├── .gitignore                # keeps runtime state OUT of the repo (see below)
└── README.md                 # this file
```

**Global vs project-local:** `~/.claude/` = the versioned *setup* (this repo). `./.claude/` in a
project = that project's *state* (`SESSION.md`, patches, its own `CLAUDE.md`/`rules/`). Project
rules **override** global ones (project loads after global).

**Tracked vs ignored (privacy + reproducibility):** the `.gitignore` excludes all runtime/personal
state — `projects/` (session transcripts + auto-memory), `sessions/`, `telemetry/`, `security/`,
`shell-snapshots/`, caches, and `settings.local.json`. Only the *setup* is tracked, so nothing
personal lands in the GitHub mirror, and a clone reproduces the setup exactly.

---

## Using it day-to-day

**Standards just apply — you don't invoke anything.** Edit a `.py` and `rules/python.md` loads
automatically (the harness matches the path). Edit Kotlin/C++/Java and their rule loads. The
always-on core in `CLAUDE.md` always applies.

**Hooks run automatically** (wired in `settings.json`):
- `PostToolUse(Write *.py)` → `ruff check --fix && ruff format` (auto-format on write).
- `PreToolUse(Write)` → `hooks/inject_lang_rule.py` injects the matching `rules/<lang>.md`
  reminder when a **brand-new** language file is written (path-scoped rules trigger on *reading*
  a matching file, so a freshly-created file could otherwise miss its rule; edits are already
  covered).

**Session continuity** (commands resolve as `/<filename>`, no prefix):

```text
/resume        # start of session — restore context from ./.claude/SESSION.md
/checkpoint    # mid-session — save progress (most invocations no-op by design)
/handoff       # before stopping — persist full state for next time
```

**Bigger workflows** (detail in `PLATFORM_INFRASTRUCTURE.md`):
- `/task_recover` — intelligent crash recovery for spawned tasks.
- `~/.claude/commands/task_spawn.sh --model … --prompt …` — spawn an isolated subtask.
- `/shared_memory` — cross-IDE notes.

**Model & cost:** `model:` in a command's frontmatter is honored by the harness (`model: sonnet`
for mechanical/scaffolding, `model: opus` for architecture/design). To save cost on **verbose or
independent shell work**, delegate it to a Sonnet subagent (`Task(subagent_type="general-purpose",
model="sonnet", …)`) — its summary returns to the Opus context. Run trivial commands inline.

---

## Updating & extending it

**Add a language:**
1. Create `~/.claude/rules/<lang>.md` with `paths:` frontmatter for its globs.
2. Add a 3-line core to `CLAUDE.md` → *Language standards*.
3. (Optional) extend `hooks/inject_lang_rule.py`'s extension map for the new-file safety net.

**Add a standard / pattern:** route it by tier (table above) — principle → `CLAUDE.md`;
language-specific → the relevant `rules/<lang>.md`.

**Add a hook:** edit `settings.json` `hooks` (matcher + command). Keep commands path-portable —
use `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/…`, **never** an absolute `/Users/...` path.

**Add a skill/command:** drop a `commands/<name>.md` (with `model:` frontmatter) → invoke as
`/<name>`.

**Machine-specific config** (an extra permission, a local path) → `settings.local.json`
(gitignored). Keep the tracked `settings.json` free of machine paths.

**Pull updates / push improvements** (keep both remotes in sync):

```bash
cd ~/.claude
git pull origin main                      # get latest
# …make changes…
git add <specific files>                  # never `git add -A` here (runtime state is untracked)
git commit -m "…"                         # NO Co-Authored-By (see CLAUDE.md → Identity)
git push origin main && git push github main
```

---

## Getting the best out of Claude Code

- **Keep `CLAUDE.md` lean.** It loads every session; long prompts dilute attention. Push depth
  into `rules/` (auto-loaded) and `reference/` (read on demand). `@import` does **not** help —
  imported files load at startup like inline content.
- **Standards = rules, procedures = skills.** Don't bury a must-apply standard in a skill (it can
  be skipped). Put it in a path-scoped rule.
- **Use hooks for anything that must be deterministic** — formatting, validation, guaranteed
  reminders. Model judgment is best-effort; hooks are not.
- **No hardcoded paths, no secrets** in tracked files (this repo is on GitHub). Machine-specifics
  → `settings.local.json`; verify with `git grep -nE '/Users/|/home/'`.
- **Session discipline:** `/handoff` before stopping so the next session resumes cleanly;
  `/resume` to pick up.
- **Tag before big changes** so you always have a restore point (e.g. `old-setup-2026-06-18`).

---

## Deeper docs

| Want | Read |
|---|---|
| The global rules & the tier model | `CLAUDE.md` |
| Per-language standards | `rules/{python,kotlin,cpp,java}.md` |
| Task spawning / crash recovery / session internals | `PLATFORM_INFRASTRUCTURE.md` |
| Architecture patterns, feature workflow, doc standards | `reference/` |

---

## Compatibility

Pure-portable: hook commands and doc references resolve via `$HOME` / `$CLAUDE_CONFIG_DIR`, so the
setup runs unchanged on **macOS** (`/Users`), **Linux**, and **Windows via WSL** (`/home`). The
bash utilities under `utils/` need a POSIX shell (native on macOS/Linux/WSL).

> **Note:** `PLATFORM_INFRASTRUCTURE.md` predates the 2026-06-18 overhaul and may still reference
> the old `/project:` command names and the retired "manual model-routing / all-shell-to-Sonnet"
> rules — reconcile it against this README + `CLAUDE.md` when next touched.
