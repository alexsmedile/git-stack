#!/usr/bin/env bash
# pre-commit-block-secrets.sh — block commits containing known secret patterns.
#
# Reusable hook. Drop into .git/hooks/pre-commit (or symlink) and `chmod +x`.
# Scans the STAGED diff (what will actually be committed) for patterns matching
# common API keys, tokens, and private keys. Blocks the commit if any match.
#
# Requires secret-patterns.sh alongside it — install-hooks.sh copies both.
#
# The pattern list lives in secret-patterns.sh, shared with git-stack.sh.
# When gitleaks is installed it runs as a second pass with far broader
# coverage; it is never required.
#
# Exit codes:
#   0  no secrets detected, commit proceeds
#   1  secrets detected, commit blocked

set -uo pipefail

# Locate secret-patterns.sh. Git invokes hooks with $0 pointing at
# .git/hooks/pre-commit, so the script's own directory is NOT where the skill
# lives. Resolve symlinks to find the real install, then fall back to the
# copy-install case where both files sit in .git/hooks/ together.
resolve_dir() {
  local src=$1 dir
  # Follow symlinks to the real file (readlink -f is not on stock macOS).
  while [ -L "$src" ]; do
    dir=$(CDPATH= cd -- "$(dirname -- "$src")" && pwd)
    src=$(readlink "$src")
    case "$src" in /*) ;; *) src="$dir/$src" ;; esac
  done
  CDPATH= cd -- "$(dirname -- "$src")" && pwd
}

SCRIPT_DIR=$(resolve_dir "${BASH_SOURCE[0]:-$0}")
PATTERNS_FILE="$SCRIPT_DIR/secret-patterns.sh"

if [ ! -r "$PATTERNS_FILE" ] && [ -n "${CLAUDE_SKILL_DIR:-}" ]; then
  PATTERNS_FILE="$CLAUDE_SKILL_DIR/scripts/secret-patterns.sh"
fi

# Fail CLOSED. A hook that cannot load its patterns must block the commit, not
# wave it through — silently passing is worse than having no hook at all.
if [ ! -r "$PATTERNS_FILE" ]; then
  {
    echo
    echo "✗ pre-commit: cannot load secret-patterns.sh"
    echo "  Looked in: $SCRIPT_DIR"
    echo
    echo "  This hook needs secret-patterns.sh next to it. Reinstall with:"
    echo "    bash install-hooks.sh /path/to/repo"
    echo "  and run BOTH commands it prints (the hook and its patterns file)."
    echo
    echo "  Blocking the commit because secrets cannot be checked."
    echo "  To override for one commit: git commit --no-verify"
  } >&2
  exit 1
fi

# shellcheck source=secret-patterns.sh
. "$PATTERNS_FILE"

# Inspect what git is ACTUALLY about to commit (after any clean filters).
# Scan ADDED lines only — '^+' filter excludes '-' (deletions) so cleanup
# commits removing a previously-leaked secret aren't blocked by the hook.
# 'grep -v "^+++"' drops the file-header lines that also start with '+'.
hits=$(git diff --cached -U0 2>/dev/null | grep '^+' | grep -v '^+++' | grep -nE "$GIT_STACK_SECRET_RE" || true)

# Second pass: gitleaks, when present. Catches what prefix matching cannot —
# high-entropy values, embedded credentials, unprefixed vendor tokens.
gitleaks_out=$(gitleaks_scan) && gitleaks_status=0 || gitleaks_status=$?
gitleaks_hint=""
case "$gitleaks_status" in
  2) gitleaks_hint="$GIT_STACK_GITLEAKS_HINT" ;;
  3) gitleaks_hint="gitleaks is installed but errored; only the built-in patterns ran" ;;
esac

if [ -z "$hits" ] && [ "$gitleaks_status" -ne 1 ]; then
  # Clean. Nudge toward better coverage once, on the way out.
  [ -n "$gitleaks_hint" ] && printf 'pre-commit: %s\n' "$gitleaks_hint" >&2
  exit 0
fi

# Color helpers (skip if not a TTY)
if [ -t 2 ]; then
  red()  { printf '\033[31m%s\033[0m' "$1"; }
  bold() { printf '\033[1m%s\033[0m'  "$1"; }
else
  red()  { printf '%s' "$1"; }
  bold() { printf '%s' "$1"; }
fi

{
  echo
  bold "✗ pre-commit: unredacted secret detected in staged content"; echo
  echo
  if [ -n "$hits" ]; then
    echo "Built-in pattern match:"
    echo "$hits"
    echo
  fi
  if [ "$gitleaks_status" -eq 1 ]; then
    echo "gitleaks (values redacted):"
    echo "$gitleaks_out"
    echo
  fi
  [ -n "$gitleaks_hint" ] && { echo "Note: $gitleaks_hint"; echo; }
  echo "Options:"
  echo "  1. Remove the secret manually, then re-stage and commit."
  echo "  2. Move the value to a gitignored file and reference it via env var."
  echo "  3. If this file always contains secrets (e.g., a config backup),"
  echo "     install a git clean filter — see git-ops/references/decisions.md"
  echo "     → 'I want to back up a config file that always contains secrets'."
  if [ "$gitleaks_status" -eq 1 ]; then
    echo "  4. If a gitleaks hit is a placeholder or test fixture, allowlist it"
    echo "     in .gitleaks.toml (by Fingerprint above) rather than bypassing."
  fi
  echo
  echo "To bypass this hook for a single commit (NOT recommended), use:"
  echo "  git commit --no-verify"
} >&2

exit 1
