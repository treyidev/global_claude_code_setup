#!/usr/bin/env python3
"""GLOBAL PreToolUse(Write|Edit) hook — deterministically trigger the ADR authoring/review ceremony.

WHY THIS EXISTS (owner directive 2026-07-20: the ADR skills "must be triggered appropriately by
Claude", and must be global not project):
    Repos in this family keep their ADRs as a knowledge graph (the ADR-0041 practice, vendored
    across repos — gazers-universe, byte-gazers, …): every relation needs `dependents:`
    reciprocity, every supersedes/amends a prose banner, status must stay honest, enforced by a
    pre-commit `adr-graph lint` gate. Two GLOBAL skills operationalize the ceremony — `/adr-new`
    (author a new ADR) and `/adr-review` (update/amend/reconcile an existing one). A *skill*
    trigger is model-driven and best-effort, too weak for a "never leave a stale ADR" guarantee.
    This hook makes the TRIGGER deterministic: whenever Claude is about to create or graph-edit an
    ADR file — in ANY repo — it injects a reminder to run the matching skill.

    Three-layer design (mechanize-to-the-reliability-floor):
      1. skill auto-trigger clauses (model-driven, proactive) — in the skills' descriptions;
      2. THIS hook (deterministic trigger — fires on the tool call, can't be silently skipped);
      3. the repo's `adr-graph lint` pre-commit (deterministic ENFORCEMENT — blocks the commit).

GLOBAL SAFETY (it runs in every project):
    It is SILENT and free of tokens unless the target is a numbered ADR record under `docs/adr/`.
    A repo with no such files (most repos) → the hook is a pure no-op. So living in
    `~/.claude/settings.json` costs nothing outside repos that actually keep ADR graphs. The
    reminder is intentionally tool-path-agnostic ("the repo's adr-graph lint") because the tool is
    vendored at different paths across repos.

TOKEN COST (mirrors installer_drift_reminder.py):
    A local shell script, not an LLM call — running it is free. It emits `additionalContext` (the
    only token cost) ONLY on a NEW ADR file (Write) or an Edit that touches graph-structural
    frontmatter — exactly the edits that can leave the graph inconsistent. A prose-only ADR edit,
    or any non-ADR file, → no output → zero tokens.

CONTRACT (Claude Code hooks):
    stdin : JSON `{"tool_name": "Write"|"Edit", "tool_input": {"file_path": ..., ["old_string"],
            ["new_string"]}}`.
    stdout: JSON `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": ...}}`.
    Fail-open: any malformed/empty payload → silent no-op. NEVER exits non-zero, NEVER blocks.

REGRESSIONS TO AVOID:
    - Never exit non-zero / never emit a deny decision: a reminder must not block an edit.
    - Keep the ADR-file match tight (a four-digit-prefixed `.md` under `docs/adr/`) so it stays
      silent on TEMPLATE.md, ADOPTION.md, READMEs, and audit notes.
    - Keep the reminder tool-path-agnostic — the adr-graph tool is vendored at different paths.
    - Keep the structural-key list in sync with the ADR relation vocabulary (supersedes/amends/
      refines/extends/realizes/relates/dependents/status).
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import PurePosixPath

# An actual ADR record: a four-digit-prefixed markdown file anywhere under docs/adr/. Excludes
# TEMPLATE.md, ADOPTION.md, README.md, audits/*.md — none is a decision record owing reciprocity.
_ADR_BASENAME_RE = re.compile(r"^\d{4}-.*\.md$")

# Graph-structural frontmatter keys — the ONLY edits that can create a stale/unmarked edge. A
# prose-body edit touches none of these, so it stays silent.
_STRUCTURAL_KEY_RE = re.compile(
    r"^\s*(?:supersedes|amends|refines|extends|realizes|relates|dependents|status)\s*:",
    re.MULTILINE,
)

_CEREMONY = (
    "declare each relation with a non-empty scope + why, insert the reciprocal `dependents:` "
    "entry into every target ADR, add the banner/inline marker for any supersedes/amends, then "
    "run the repo's `adr-graph lint` (the ADR knowledge-graph pre-commit gate) until it is green."
)


def _is_adr_file(file_path: str) -> bool:
    """True iff `file_path` is a numbered ADR record under docs/adr/ (not template/readme/audit)."""
    if not file_path:
        return False
    parts = PurePosixPath(file_path).parts
    if "docs" not in parts or "adr" not in parts:
        return False
    return bool(_ADR_BASENAME_RE.match(PurePosixPath(file_path).name))


def main() -> None:
    """Emit the ceremony reminder iff this Write/Edit touches an ADR graph-relevantly.

    Reads the PreToolUse payload from stdin; stays silent (zero tokens) unless the target is a
    numbered ADR record AND the operation can leave the graph inconsistent. Always exits 0.
    """
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return  # malformed/empty → no-op

    tool_name = payload.get("tool_name", "") or ""
    tool_input = payload.get("tool_input")
    if not isinstance(tool_input, dict):
        return
    file_path = tool_input.get("file_path", "") or ""
    if not _is_adr_file(file_path):
        return  # not an ADR record → silent → zero tokens

    name = PurePosixPath(file_path).name
    if tool_name == "Write":
        message = (
            f"📐 New ADR file ({name}). Run the **/adr-new** skill rather than hand-rolling the "
            f"graph: {_CEREMONY}"
        )
    elif tool_name == "Edit":
        # Only a graph-structural frontmatter change can create a stale edge; a prose edit can't.
        edit_text = f"{tool_input.get('old_string', '')}\n{tool_input.get('new_string', '')}"
        if not _STRUCTURAL_KEY_RE.search(edit_text):
            return  # prose-only ADR edit → silent
        message = (
            f"📐 Graph-structural edit to {name}. Run the **/adr-review** skill so the change "
            f"stays consistent: {_CEREMONY}"
        )
    else:
        return

    json.dump(
        {"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": message}},
        sys.stdout,
    )


if __name__ == "__main__":
    main()
