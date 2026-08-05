#!/usr/bin/env python3
"""GLOBAL PreToolUse(Bash) hook — BLOCK `git push` while cross-session working memory is uncommitted.

WHY THIS EXISTS (owner directive 2026-08-05, after a real loss-near-miss):
    Every project in this family keeps its cross-session state in exactly four files (global
    CLAUDE.md §"🗂️ Session continuity — three-tier working memory"): `.claude/SESSION.md`
    (snapshot), `.claude/TASKS.md` (hot tier), `.claude/tasks/backlog.md` (pending),
    `.claude/tasks/archive.md` (shipped). Those files ARE the assistant's memory between
    sessions — a session starts with no other context. They are durable only once COMMITTED.

    THE FAILURE THIS CLOSES (gazers-universe, commit be526ac, 2026-08-04): `/handoff` wrote the
    session-20 SESSION.md; the sync commit that followed staged and committed TASKS.md +
    backlog.md but NOT SESSION.md. The handoff survived only as a staged working-tree change
    that happened to travel across a later branch switch. No error, no signal. One `git checkout
    .` — or the next session starting from a fresh clone — and an entire session's handoff would
    have been gone silently, with `/resume` loading the session-19 snapshot and presenting it as
    current.

    Three-layer design (mechanize-to-the-reliability-floor, the owner's 2026-07-16 directive —
    remembering is ELIMINATED with a blocking gate, never softened into a reminder):
      1. the /checkpoint · /handoff · /post-merge skills (model-driven — they carry the JUDGMENT
         of what the write-up should say and which items move tiers);
      2. THIS hook (deterministic ENFORCEMENT at the push boundary — cannot be forgotten, and
         unlike a git hook it is not bypassable with `--no-verify`);
      3. each repo's own pre-push chain, where one exists (covers pushes typed by a human in a
         terminal, which no Claude Code hook can see).

    Layer 2 is the one that generalizes: it is GLOBAL, so it travels to every project and every
    host without per-repo tooling — no pre-commit, no uv, no per-repo install step.

GLOBAL SAFETY (it runs in every project):
    Silent and free unless the command is a `git push` AND the cwd is a git repo AND at least one
    tier file exists AND one of them is dirty. A repo with no `.claude/` working memory (most
    repos) → pure no-op. The command-shape check runs before any subprocess, so the common case
    (any Bash command that is not a push) costs one regex.

TOKEN COST:
    A local script, not an LLM call — running it is free. It emits output ONLY when it blocks.

CONTRACT (Claude Code hooks):
    stdin : JSON `{"tool_name": "Bash", "tool_input": {"command": ...}, ["cwd": ...]}`.
    stdout: JSON `{"hookSpecificOutput": {"hookEventName": "PreToolUse",
            "permissionDecision": "deny", "permissionDecisionReason": ...}}`.
    Fail-OPEN: malformed payload, no git, not a repo, git error → silent no-op, exit 0. A gate
    that guards memory must never become a gate that blocks all work; a missed block costs one
    handoff, a false block costs every push in every project.

REGRESSIONS TO AVOID:
    - Never auto-commit the files. Committing working memory without the content judgment is the
      "auto-writing truth = silently wrong" failure mode the owner's directive warns about — the
      gate must stop and hand control back, never paper over.
    - Never fail closed on an unexpected error (see fail-OPEN above).
    - Do not extend this to untracked files under `.claude/`: that directory legitimately holds
      untracked scratch (proposal drafts live there by convention), so it would fire constantly
      on files that must NOT be committed.
    - Do not add a "SESSION.md must be newer than the newest commit" rule: mechanical commits are
      a legitimate checkpoint NO-OP, so it would fire on exactly the commits the judgment skips.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

# The three-tier working memory + the per-session snapshot, repo-root-relative. Extending this
# tuple is the whole cost of adding a tier file.
TIER_FILES = (
    ".claude/SESSION.md",
    ".claude/TASKS.md",
    ".claude/tasks/backlog.md",
    ".claude/tasks/archive.md",
)

# `git push` as an actual command word, not inside a quoted string in some other command. Matches
# a compound line (`git commit -m x && git push`) because the push still happens there. A false
# positive is harmless: the hook only blocks when working memory is genuinely dirty.
_GIT_PUSH_RE = re.compile(r"(?:^|[;&|]|\s)git\s+(?:-[^\s]+\s+)*push\b")

# Every git invocation is capped — a hung git (credential prompt, network fs) must not stall the
# tool call. On timeout we fail open.
_GIT_TIMEOUT_SECONDS = 5


def _git(args: list[str], cwd: Path) -> subprocess.CompletedProcess[str] | None:
    """Run a git command in `cwd`, or return None if git is unusable.

    Returns None (never raises) when git is missing, times out, or the OS refuses the spawn —
    every one of which must fail OPEN so the push proceeds.
    """
    try:
        return subprocess.run(
            ["git", *args],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=_GIT_TIMEOUT_SECONDS,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return None


def _repo_root(cwd: Path) -> Path | None:
    """Absolute path of the git repo containing `cwd`, or None if it is not a work tree."""
    result = _git(["rev-parse", "--show-toplevel"], cwd)
    if result is None or result.returncode != 0:
        return None
    root = result.stdout.strip()
    return Path(root) if root else None


def _is_dirty(root: Path, relative_path: str, *, staged: bool) -> bool:
    """True iff `relative_path` differs between the index and HEAD (staged) or the tree (unstaged).

    `git diff --quiet` exits 1 when differences exist and 0 when clean — the inverse of the usual
    convention, hence the explicit comparison. Any other exit code (e.g. the file is untracked, or
    HEAD does not exist in a repo with no commits) is treated as clean: fail open.
    """
    args = ["diff", "--cached", "--quiet"] if staged else ["diff", "--quiet"]
    result = _git([*args, "--", relative_path], root)
    return result is not None and result.returncode == 1


def _collect_dirty(root: Path) -> tuple[list[str], list[str]]:
    """Partition the existing tier files into (staged-uncommitted, modified-unstaged)."""
    staged: list[str] = []
    unstaged: list[str] = []
    for relative_path in TIER_FILES:
        if not (root / relative_path).exists():
            continue
        if _is_dirty(root, relative_path, staged=True):
            staged.append(relative_path)
        if _is_dirty(root, relative_path, staged=False):
            unstaged.append(relative_path)
    return staged, unstaged


def _build_reason(staged: list[str], unstaged: list[str]) -> str:
    """Compose the block message: what is dirty, why it matters, and the exact way forward."""
    lines = ["Push blocked — cross-session working memory is not committed.", ""]
    if staged:
        lines.append(f"  STAGED but never committed: {', '.join(staged)}")
    if unstaged:
        lines.append(f"  Modified, not staged: {', '.join(unstaged)}")
    lines += [
        "",
        "These files ARE the memory between sessions and are durable only once committed.",
        "An edit left in the index looks fine locally and is invisible to the next session —",
        "exactly what happened at be526ac (a handoff written, staged, never committed, and one",
        "`git checkout .` from silent loss).",
        "",
        "Commit them first, then push:",
        "    git add .claude/ && git commit -m 'chore: sync working memory — <what changed>'",
        "",
        "If the edit is genuinely not meant to land, discard it deliberately — but READ it first;",
        "it may be a handoff you are about to lose. Do not bypass this by other means.",
    ]
    return "\n".join(lines)


def main() -> None:
    """Deny the Bash call iff it pushes while this repo's working memory is uncommitted.

    Reads the PreToolUse payload from stdin. Stays silent (and exits 0) for every command that is
    not a `git push`, every non-repo cwd, and every repo whose tier files are clean or absent.
    """
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return  # malformed/empty → no-op

    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        return
    command = tool_input.get("command", "") or ""
    if not _GIT_PUSH_RE.search(command):
        return  # not a push → the common case, one regex, zero subprocesses

    # The hook payload carries the session cwd; fall back to the process cwd when absent.
    cwd_value = payload.get("cwd") or ""
    cwd = Path(cwd_value) if cwd_value else Path.cwd()
    if not cwd.is_dir():
        return

    root = _repo_root(cwd)
    if root is None:
        return  # not a git work tree → nothing to gate

    staged, unstaged = _collect_dirty(root)
    if not staged and not unstaged:
        return

    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": _build_reason(staged, unstaged),
            }
        },
        sys.stdout,
    )


if __name__ == "__main__":
    main()
