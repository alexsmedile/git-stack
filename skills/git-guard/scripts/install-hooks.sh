#!/usr/bin/env bash
# install-hooks.sh — print install instructions for the secret-block hook.
#
# Does NOT modify anything. Detects the current repo's .git/hooks/ location
# and prints the exact command(s) the user can copy-paste to install the hook.
#
# Usage:
#   install-hooks.sh                # current dir as target repo
#   install-hooks.sh /path/to/repo  # explicit target

set -uo pipefail

TARGET="${1:-.}"
TARGET=$(cd "$TARGET" 2>/dev/null && pwd) || { echo "Not a directory: $1"; exit 2; }

# Resolve hook source — prefer CLAUDE_SKILL_DIR (set when git-guard skill is active),
# fall back to this script's own dir.
if [ -n "${CLAUDE_SKILL_DIR:-}" ] && [ -f "$CLAUDE_SKILL_DIR/scripts/pre-commit-block-secrets.sh" ]; then
  HOOK_SRC="$CLAUDE_SKILL_DIR/scripts/pre-commit-block-secrets.sh"
else
  HOOK_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pre-commit-block-secrets.sh"
fi

# Locate target .git directory (handles plain repos, worktrees, submodules)
GITDIR=$(git -C "$TARGET" rev-parse --git-dir 2>/dev/null)
if [ -z "$GITDIR" ]; then
  echo "✗ $TARGET is not inside a git repository."
  echo "  Run from inside a repo, or pass a repo path as the first argument."
  exit 1
fi

# rev-parse may return a relative path — normalize
case "$GITDIR" in
  /*) ABS_GITDIR="$GITDIR" ;;
  *)  ABS_GITDIR="$TARGET/$GITDIR" ;;
esac

HOOK_DEST="$ABS_GITDIR/hooks/pre-commit"

# Color helpers
if [ -t 1 ]; then
  bold() { printf '\033[1m%s\033[0m' "$1"; }
  dim()  { printf '\033[2m%s\033[0m' "$1"; }
  grn()  { printf '\033[32m%s\033[0m' "$1"; }
  yel()  { printf '\033[33m%s\033[0m' "$1"; }
else
  bold() { printf '%s' "$1"; }
  dim()  { printf '%s' "$1"; }
  grn()  { printf '%s' "$1"; }
  yel()  { printf '%s' "$1"; }
fi

echo
bold "── git-guard: pre-commit secret-block hook installer (preview only)"; echo
echo
echo "  Target repo:   $TARGET"
echo "  Hook source:   $HOOK_SRC"
echo "  Hook dest:     $HOOK_DEST"
echo

# Source readable?
if [ ! -r "$HOOK_SRC" ]; then
  yel "  ⚠ Hook source not found at the path above."; echo
  echo "    Make sure the git-guard skill is installed, or pass --skill-dir explicitly."
  exit 1
fi

# Dest already exists?
if [ -e "$HOOK_DEST" ]; then
  if [ -L "$HOOK_DEST" ]; then
    yel "  ⚠ $HOOK_DEST already exists (symlink → $(readlink "$HOOK_DEST"))"; echo
  else
    yel "  ⚠ $HOOK_DEST already exists as a regular file."; echo
  fi
  echo "    Decide: replace it, chain hooks manually, or leave the existing one."
  echo
fi

echo "  $(bold "To install (copy approach — survives upgrades, snapshot in repo):")"
echo "    cp '$HOOK_SRC' '$HOOK_DEST'"
echo "    chmod +x '$HOOK_DEST'"
echo
echo "  $(bold "To install (symlink approach — auto-updates when git-guard updates):")"
echo "    ln -sf '$HOOK_SRC' '$HOOK_DEST'"
echo
echo "  $(dim "Note: .git/hooks/ is NOT versioned by git. Other clones will not")"
echo "  $(dim "      get the hook automatically — they must run this installer too.")"
echo
echo "  $(bold "To verify after install:")"
echo "    git -C '$TARGET' hook run --ignore-missing pre-commit"
echo
echo "  $(bold "To bypass the hook for one commit (NOT recommended):")"
echo "    git commit --no-verify"
echo

grn "  No changes were made."; echo
