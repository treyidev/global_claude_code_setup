#!/usr/bin/env python3
"""PreToolUse(Write) hook — new-file safety net for path-scoped language rules.

WHY THIS EXISTS
    Path-scoped rules (`~/.claude/rules/<lang>.md`, see `~/.claude/CLAUDE.md` →
    "Instruction architecture") load deterministically when Claude *reads* a file matching the
    rule's `paths:` glob. Editing an existing file is covered — the Edit tool requires a prior
    Read, which triggers the rule. But a **brand-new file created via Write** may have had no
    prior read, so its language rule might not have loaded. This hook closes that gap: it fires
    before a Write and, if the target is a supported language file, injects a reminder
    (`additionalContext`) to apply the matching rule.

WHERE IT FITS
    Wired in `~/.claude/settings.json` as a global `PreToolUse` hook with matcher `"Write"`.
    The matcher is intentionally `Write` only (not `Edit`) — edits are already covered by the
    read-trigger, so matching Edit would add noise without adding coverage.

CONTRACT (Claude Code hooks)
    stdin  : JSON payload with at least `{"tool_input": {"file_path": "..."}}`.
    stdout : JSON `{"hookSpecificOutput": {"hookEventName": "PreToolUse",
             "additionalContext": "<text>"}}` — the harness wraps `additionalContext` in a
             system reminder for the next model request. Emitting nothing = no-op.

LIMITATIONS / SAFE BEHAVIOUR
    - Fail-open: any malformed/empty input → silent no-op (return). This hook must NEVER block a
      Write; it only *adds context*. (It does not emit a permission decision.)
    - Non-language files → no-op.
    - `.h` maps to C++ (matches `rules/cpp.md`'s globs); a pure-C header gets C++-leaning advice,
      an accepted minor imprecision.

SAFE EXTENSIONS
    - Add a language: extend `_EXT_TO_RULE` and create `~/.claude/rules/<rule>.md`.
REGRESSIONS TO AVOID
    - Do not exit non-zero / emit a deny decision — that would block legitimate writes.
    - Do not read the file from disk (it may not exist yet — it's about to be created).
"""

from __future__ import annotations

import json
import sys

# File extension → rule-file stem under `~/.claude/rules/`. Kept in sync with each rule file's
# `paths:` frontmatter. Longest-suffix match is unnecessary here (extensions are unambiguous).
_EXT_TO_RULE: dict[str, str] = {
    ".py": "python",
    ".ts": "typescript",
    ".tsx": "typescript",
    ".mts": "typescript",
    ".cts": "typescript",
    ".kt": "kotlin",
    ".kts": "kotlin",
    ".cpp": "cpp",
    ".cc": "cpp",
    ".cxx": "cpp",
    ".h": "cpp",
    ".hpp": "cpp",
    ".hh": "cpp",
    ".java": "java",
    ".sh": "shell",
    ".bash": "shell",
    ".zsh": "shell",
}

# Deliberately NOT hooked (deferred with reason, 2026-07-14): a PostToolUse formatter hook for
# TypeScript (prettier/eslint --fix, the ruff analogue). Unlike ruff, those are project-local
# deps — a global hook must guard on per-project config presence and adds latency to every TS
# write. Need: format-on-write parity with Python. Trigger to revisit: a project where manual
# formatting churn actually shows up in diffs/reviews. Until then, per-project pre-commit hooks
# own TS formatting.


def main() -> None:
    """Read the PreToolUse payload and, for a supported language file, emit the reminder."""
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError, OSError):
        return  # malformed/absent input → no-op (never block the Write)

    file_path = (payload.get("tool_input") or {}).get("file_path", "") or ""
    rule = next((stem for ext, stem in _EXT_TO_RULE.items() if file_path.endswith(ext)), None)
    if rule is None:
        return  # not a supported language file

    context = (
        f"Writing a {rule} file ({file_path}). Apply the standards in "
        f"~/.claude/rules/{rule}.md. Path-scoped rules load when Claude *reads* a matching file, "
        f"so this freshly-written file may not have triggered it — read ~/.claude/rules/{rule}.md "
        f"now if it is not already in context."
    )
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "additionalContext": context,
            }
        },
        sys.stdout,
    )


if __name__ == "__main__":
    main()
