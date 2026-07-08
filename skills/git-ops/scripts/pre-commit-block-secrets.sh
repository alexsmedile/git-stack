#!/usr/bin/env bash
# pre-commit-block-secrets.sh — block commits containing known secret patterns.
#
# Reusable hook. Drop into .git/hooks/pre-commit (or symlink) and `chmod +x`.
# Scans the STAGED diff (what will actually be committed) for patterns matching
# common API keys, tokens, and private keys. Blocks the commit if any match.
#
# Patterns mirror git-ops/references/core.md → "Secrets / API key scan".
# Keep this script and core.md in sync when adding new patterns.
#
# Exit codes:
#   0  no secrets detected, commit proceeds
#   1  secrets detected, commit blocked

set -uo pipefail

PATTERNS='(sk-proj-[A-Za-z0-9_-]{40,}|sk-ant-[a-z0-9-]+-[A-Za-z0-9_-]{40,}|sk-[A-Za-z0-9]{40,}|jina_[A-Za-z0-9]{40,}|tvly-(dev-|prod-)?[A-Za-z0-9_-]{20,}|apify_api_[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{30,}|xoxb-[A-Za-z0-9-]{20,}|hf_[A-Za-z0-9]{30,}|-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----)'

# Inspect what git is ACTUALLY about to commit (after any clean filters).
# Scan ADDED lines only — '^+' filter excludes '-' (deletions) so cleanup
# commits removing a previously-leaked secret aren't blocked by the hook.
# 'grep -v "^+++"' drops the file-header lines that also start with '+'.
hits=$(git diff --cached -U0 2>/dev/null | grep '^+' | grep -v '^+++' | grep -nE "$PATTERNS" || true)

if [ -z "$hits" ]; then
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
  echo "$hits"
  echo
  echo "Options:"
  echo "  1. Remove the secret manually, then re-stage and commit."
  echo "  2. Move the value to a gitignored file and reference it via env var."
  echo "  3. If this file always contains secrets (e.g., a config backup),"
  echo "     install a git clean filter — see git-ops/references/decisions.md"
  echo "     → 'I want to back up a config file that always contains secrets'."
  echo
  echo "To bypass this hook for a single commit (NOT recommended), use:"
  echo "  git commit --no-verify"
} >&2

exit 1
