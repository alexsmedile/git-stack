#!/usr/bin/env bash
# check-author-email.sh — Guard against committing/pushing with the wrong identity.
#
# Warns when the author OR committer email on the commits under inspection is:
#   • a real personal email (anything not a *@users.noreply.github.com alias)
#   • GitHub's web-UI signature  GitHub <noreply@github.com>  (attribution lands
#     on the author but the committer reads as "GitHub", not you)
#   • a machine-hostname default  name@Hostname.local  (unverifiable → unlinked
#     on GitHub, no profile attribution)
#
# The lesson behind this script: a mailmap rewrite (or a plain commit) can leave
# the AUTHOR correct while the COMMITTER still leaks — and stale side-branch refs
# keep old emails after main is fixed. A grep of `%ae` alone misses both. This
# checks author AND committer, and can scan a range or all refs.
#
# The "right" identity is your GitHub noreply alias:  ID+username@users.noreply.github.com
# (github.com/settings/emails → "Keep my email addresses private"). Set it once:
#   git config --global user.email "ID+username@users.noreply.github.com"
#
# Usage:
#   check-author-email.sh                 # check HEAD (the commit you're about to make/push)
#   check-author-email.sh --staged        # check configured user.email BEFORE committing
#   check-author-email.sh --range A..B     # check a commit range (e.g. origin/main..HEAD)
#   check-author-email.sh --all            # audit every commit on every ref
#   check-author-email.sh --allow a@b.com  # add an extra allowed email (repeatable)
#
# Config: extra allowed emails may also be set via
#   git config --get-all gitstack.allowedEmail
# or a GITSTACK_ALLOWED_EMAILS env var (space/comma separated).
#
# macOS bash 3.2 compatible.
#
# Exit codes:
#   0  all inspected identities are clean noreply aliases (or nothing to check)
#   1  leak found (personal / GitHub-signature / hostname email)  → WARNING, caller decides
#   2  not a git repo / bad arguments

set -uo pipefail

bold() { printf '\033[1m%s\033[0m' "$1"; }
red()  { printf '\033[31m%s\033[0m' "$1"; }
yel()  { printf '\033[33m%s\033[0m' "$1"; }
grn()  { printf '\033[32m%s\033[0m' "$1"; }
dim()  { printf '\033[2m%s\033[0m' "$1"; }

git rev-parse --git-dir >/dev/null 2>&1 || { echo "$(red "not a git repository")"; exit 2; }

MODE="head"          # head | staged | range | all
RANGE=""
EXTRA_ALLOWED=()

while [ $# -gt 0 ]; do
  case "$1" in
    --staged)  MODE="staged" ;;
    --all)     MODE="all" ;;
    --range)   MODE="range"; RANGE="${2:-}"; shift ;;
    --allow)   EXTRA_ALLOWED+=("${2:-}"); shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "$(red "unknown arg: $1")"; exit 2 ;;
  esac
  shift
done

# --- build the allowlist ------------------------------------------------------
# Always allowed: any *@users.noreply.github.com (the whole point of the migration).
# Extra explicit allows come from flags, git config, and env.
ALLOWED=()
add_allowed() { [ -n "$1" ] && ALLOWED+=("$1"); }

for e in "${EXTRA_ALLOWED[@]:-}"; do add_allowed "$e"; done
while IFS= read -r e; do add_allowed "$e"; done < <(git config --get-all gitstack.allowedEmail 2>/dev/null)
if [ -n "${GITSTACK_ALLOWED_EMAILS:-}" ]; then
  for e in $(printf '%s' "$GITSTACK_ALLOWED_EMAILS" | tr ',' ' '); do add_allowed "$e"; done
fi

# classify one email → prints a reason if it's a leak, empty if clean
classify() {
  local email="$1"
  # clean: GitHub noreply alias
  case "$email" in
    *@users.noreply.github.com) return 0 ;;
  esac
  # explicitly allowed
  for a in "${ALLOWED[@]:-}"; do [ "$email" = "$a" ] && return 0; done
  # GitHub web-UI signature — author is usually fine, committer reads as "GitHub"
  [ "$email" = "noreply@github.com" ] && { printf 'github-web-signature'; return 1; }
  # machine hostname default → unverifiable, unlinked on GitHub
  case "$email" in
    *@*.local|*@*.lan|*@localhost) printf 'machine-hostname (unlinked on GitHub)'; return 1 ;;
  esac
  # anything else = a real personal email being leaked into history
  printf 'personal-email'
  return 1
}

# --- gather (email<TAB>role<TAB>commit<TAB>subject) lines to inspect ----------
LINES=""
case "$MODE" in
  staged)
    cfg=$(git config user.email 2>/dev/null)
    if [ -z "$cfg" ]; then
      echo "$(red "✗ no user.email configured")"
      echo "  Set it: git config --global user.email \"ID+username@users.noreply.github.com\""
      exit 1
    fi
    LINES="$cfg	config	(pending)	your configured commit identity"
    ;;
  head)
    LINES=$(git log -1 --format='%ae	author	%h	%s
%ce	committer	%h	%s' HEAD 2>/dev/null)
    ;;
  range)
    [ -n "$RANGE" ] || { echo "$(red "--range needs A..B")"; exit 2; }
    LINES=$(git log --format='%ae	author	%h	%s
%ce	committer	%h	%s' "$RANGE" 2>/dev/null)
    ;;
  all)
    LINES=$(git log --all --format='%ae	author	%h	%s
%ce	committer	%h	%s' 2>/dev/null)
    ;;
esac

if [ -z "$LINES" ]; then
  echo "$(dim "nothing to check")"
  exit 0
fi

# --- inspect ------------------------------------------------------------------
LEAK=0
CLEAN=0
echo
bold "── Author-email check ($MODE)"; echo
# de-dup identical email+role so a big --all scan stays readable
printf '%s\n' "$LINES" | sort -u | while IFS=$'\t' read -r email role commit subject; do
  [ -n "$email" ] || continue
  reason=$(classify "$email")
  if [ -n "$reason" ]; then
    printf '  %s %-9s %s  %s  %s\n' "$(red '✗')" "$role" "$(red "$email")" "$(dim "$commit")" "$(yel "[$reason]")"
  fi
done

# The subshell above can't set LEAK; recompute the verdict directly.
BAD=$(printf '%s\n' "$LINES" | sort -u | while IFS=$'\t' read -r email role commit subject; do
  [ -n "$email" ] || continue
  if classify "$email" >/dev/null; then :; else echo x; fi
done | wc -l | tr -d ' ')

TOTAL=$(printf '%s\n' "$LINES" | sort -u | grep -c .)
GOOD=$((TOTAL - BAD))

echo
if [ "$BAD" -gt 0 ]; then
  echo "$(red "⚠ $BAD identity leak(s)") across inspected commits ($GOOD clean)."
  echo "  Right identity: $(grn "ID+username@users.noreply.github.com")  (github.com/settings/emails)"
  echo "  $(dim "Fix going forward:")  git config --global user.email \"ID+username@users.noreply.github.com\""
  echo "  $(dim "Fix history:")        git filter-repo --mailmap <map>   (rewrites author+committer; force-push)"
  echo "  $(dim "Allow an email:")     git config --add gitstack.allowedEmail you@example.com"
  exit 1
fi

echo "$(grn "✓ all inspected identities are GitHub noreply aliases") ($GOOD clean)."
exit 0
