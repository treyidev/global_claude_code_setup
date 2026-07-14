---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
---

# Shell standards (auto-loaded on `**/*.sh`, `**/*.bash`, `**/*.zsh`)

Deep shell-specific standards, bash-first (a `.zsh` file gets bash-leaning advice — accepted
imprecision, mirroring `rules/cpp.md`'s `.h` note). **Path-scoped**: loaded deterministically
when you read or edit shell files; brand-new files are covered by the `inject_lang_rule.py`
hook. Cross-language principles (SOLID-for-scripts = small single-purpose functions, fail-fast,
documentation) live in `~/.claude/CLAUDE.md` and apply on top.

## Strict mode (Required — with the sourced-library caveat)

```bash
# ✅ CORRECT — every EXECUTABLE script starts with:
#!/usr/bin/env bash
set -euo pipefail

# ⚠️ CAVEAT — a SOURCED library file (lib/*.sh consumed via `source`) must NOT set these
# globally: it would mutate the caller's shell options. Libraries define functions only;
# the entrypoint script owns the strict-mode line. (This is the setup/lib/*.sh pattern.)
```

- `set -e` alone is not enough: `-u` catches typo'd variables, `-o pipefail` catches a failing
  producer in a pipe (`curl … | grep …` otherwise reports grep's status).

## Quote everything

```bash
# ❌ WRONG — word-splits and glob-expands on spaces/special chars
rm -rf $BUILD_DIR/$name
[ -f $config ] && source $config

# ✅ CORRECT — quote every expansion; braces for adjacency
rm -rf "${BUILD_DIR:?}/${name}"      # :? aborts if BUILD_DIR is unset/empty — never rm -rf "/"
[[ -f "$config" ]] && source "$config"
```

- `[[ ]]` over `[ ]` in bash (no word-splitting inside, `&&`/`==`/regex support).
- `"${var:?message}"` on any variable feeding a destructive command (`rm`, `mv` to overwrite).
- Never parse `ls` — glob (`for f in *.csv`) or `find -print0 | while read -r -d ''`.

## Functions, locals, and structure

```bash
# ✅ CORRECT — small named functions; locals; a main() entrypoint guard
detect_platform() {
    local uname_out                      # local ALWAYS — bash vars are global by default
    uname_out="$(uname -s)"              # declare and assign separately: `local x=$(cmd)`
    case "$uname_out" in                 # masks the command's exit status under set -e
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unsupported: $uname_out" >&2; return 1 ;;
    esac
}

main() { ... }
main "$@"
```

- Errors to stderr (`>&2`); exit codes are the API — `return 1` from functions, `exit 1` from
  main; never `exit` from a sourced library function (kills the caller's shell).
- Temp files via `mktemp` + `trap 'rm -rf "$tmpdir"' EXIT` — cleanup survives failures.
- `printf` over `echo` for anything with escapes/variables (`echo -e` is unportable).

## Lint posture

`shellcheck` is the standard; treat its findings as review findings (severity mapping: quoting
and `set -e`-masking bugs = MUST-FIX; style = SHOULD-FIX). Suppress only with a reasoned
`# shellcheck disable=SCnnnn -- why` — same fix-or-track-explicitly discipline as every linter
(never blanket-disable).

## Docs

Header comment block on every script: WHY it exists, WHERE it fits (who calls it), inputs
(env vars, args), side effects. Non-obvious invocations (`uv run --frozen`, `brew --caskroom`,
csv parsing one-liners) explained at the call site — same gold-level bar as every language.
