#!/usr/bin/env bash
# GENERATED COPY — source of truth: src/scripts/git-stack.sh
# Edit the source and run `node src/sync-scripts.mjs`. Do not edit here.
set -u

# Compact, cross-runtime Git safety runner. It intentionally prints summaries,
# not raw diffs or command logs, so agents can call it without polluting context.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Shared secret regex + optional gitleaks escalation. Sourced rather than
# duplicated: the pattern previously lived in two files and drifted unnoticed.
# shellcheck source=secret-patterns.sh
. "$SCRIPT_DIR/secret-patterns.sh"

OP=${1:-}
shift 2>/dev/null || true

MODE=check
MESSAGE=
VERSION=
REMOTE=origin
ALLOW_MAIN=0
ALLOW_LARGE=0
NO_FETCH=0
STALE_DAYS=90
PATH_ARGS=()

usage() {
  cat <<'EOF'
Usage: git-stack.sh <state|commit|push|tag|release|cleanup|scan> [options]

Write ops: commit, push, tag, release
Read-only reports (never write):
  state               Compact local branch/status/worktree/target facts
  cleanup             Repo hygiene counts: branches, stashes, junk, size
  scan                Commit subjects since last tag, grouped by type

Options:
  --execute             Perform the clean-path write after checks pass
  --message <text>      Commit message (required to execute commit/push with staged changes)
  --version <X.Y.Z>     Version for tag/release
  --remote <name>       Remote name (default: origin)
  --allow-main          Explicitly allow commit/push on the default branch
  --allow-large         Explicitly allow staged files larger than 500KB
  --no-fetch            Skip fetch during push/release/cleanup checks
  --stale-days <n>      Stale-branch threshold for cleanup (default: 90)
  --path <path>         Report existence/tracking/dirty state (repeatable; state only)

Exit: 0 clean/done, 1 blocker or command failure, 2 nothing to do.
EOF
}

if [[ "$OP" == "-h" || "$OP" == "--help" ]]; then
  usage
  exit 0
fi

while (($#)); do
  case "$1" in
    --execute) MODE=execute ;;
    --message) shift; MESSAGE=${1:-} ;;
    --version) shift; VERSION=${1:-} ;;
    --remote) shift; REMOTE=${1:-} ;;
    --allow-main) ALLOW_MAIN=1 ;;
    --allow-large) ALLOW_LARGE=1 ;;
    --no-fetch) NO_FETCH=1 ;;
    --stale-days) shift; STALE_DAYS=${1:-90} ;;
    --path) shift; PATH_ARGS+=("${1:-}") ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'VERDICT=BLOCKED\nBLOCKER=unknown-option:%s\n' "$1"; exit 1 ;;
  esac
  shift
done

case "$OP" in state|commit|push|tag|release|cleanup|scan) ;; *) usage; exit 1 ;; esac

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'VERDICT=BLOCKED\nOP=%s\nBLOCKER=not-a-git-repository\n' "$OP"
  exit 1
fi

branch=$(git branch --show-current 2>/dev/null || true)
default_branch=$(git symbolic-ref --quiet --short "refs/remotes/$REMOTE/HEAD" 2>/dev/null | sed "s#^$REMOTE/##")
default_branch_source=remote-head
if [[ -z "$default_branch" ]]; then
  case "$branch" in
    main|master) default_branch=$branch; default_branch_source=current-conventional ;;
    *) default_branch=main; default_branch_source=heuristic-main ;;
  esac
fi

# ---- read-only reports: emit compact counts and exit, never write ----------
if [[ "$OP" == state ]]; then
  root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  status=$(git status --porcelain 2>/dev/null || true)
  staged=$(printf '%s\n' "$status" | awk 'NF && substr($0,1,2)!="??" && substr($0,1,1)!=" "{n++} END{print n+0}')
  unstaged=$(printf '%s\n' "$status" | awk 'NF && substr($0,1,2)!="??" && substr($0,2,1)!=" "{n++} END{print n+0}')
  untracked=$(printf '%s\n' "$status" | awk 'substr($0,1,2)=="??"{n++} END{print n+0}')

  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)
  ahead=0
  behind=0
  if [[ -n "$upstream" ]]; then
    counts=$(git rev-list --left-right --count "$upstream...HEAD" 2>/dev/null || printf '0 0')
    behind=${counts%%[[:space:]]*}
    ahead=${counts##*[[:space:]]}
  fi

  interrupted=NONE
  for item in MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD BISECT_START; do
    marker=$(git rev-parse --git-path "$item" 2>/dev/null || true)
    if [[ -n "$marker" && -e "$marker" ]]; then interrupted=$item; break; fi
  done
  if [[ "$interrupted" == NONE ]]; then
    for item in rebase-merge rebase-apply; do
      marker=$(git rev-parse --git-path "$item" 2>/dev/null || true)
      if [[ -n "$marker" && -e "$marker" ]]; then interrupted=REBASE; break; fi
    done
  fi

  worktree_count=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree /{n++} END{print n+0}')
  printf 'OP=state\nROOT=%s\nBRANCH=%s\nDEFAULT_BRANCH=%s\nDEFAULT_BRANCH_SOURCE=%s\nSTAGED=%s\nUNSTAGED=%s\nUNTRACKED=%s\nUPSTREAM=%s\nAHEAD=%s\nBEHIND=%s\nINTERRUPTED=%s\nWORKTREES=%s\n' \
    "$root" "${branch:-DETACHED}" "$default_branch" "$default_branch_source" "$staged" "$unstaged" "$untracked" "${upstream:-NONE}" "$ahead" "$behind" "$interrupted" "$worktree_count"

  worktree_index=0
  while IFS= read -r line; do
    case "$line" in
      'worktree '*)
        worktree_index=$((worktree_index + 1))
        wt_path=${line#worktree }
        printf 'WORKTREE_%s_PATH=%q\n' "$worktree_index" "$wt_path"
        wt_dirty=$(git -C "$wt_path" status --porcelain 2>/dev/null | awk 'NF{n++} END{print n+0}')
        printf 'WORKTREE_%s_DIRTY=%s\n' "$worktree_index" "$wt_dirty"
        ;;
      'branch refs/heads/'*)
        printf 'WORKTREE_%s_BRANCH=%s\n' "$worktree_index" "${line#branch refs/heads/}"
        ;;
      detached)
        printf 'WORKTREE_%s_BRANCH=DETACHED\n' "$worktree_index"
        ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null)

  target_index=0
  if ((${#PATH_ARGS[@]})); then
    for target in "${PATH_ARGS[@]}"; do
      [[ -n "$target" ]] || continue
      target_index=$((target_index + 1))
      exists=no
      [[ -e "$target" || -L "$target" ]] && exists=yes
      tracked=no
      git ls-files --error-unmatch -- "$target" >/dev/null 2>&1 && tracked=yes
      dirty=no
      [[ -n "$(git status --porcelain -- "$target" 2>/dev/null)" ]] && dirty=yes
      printf 'TARGET_%s_PATH=%q\nTARGET_%s_EXISTS=%s\nTARGET_%s_TRACKED=%s\nTARGET_%s_DIRTY=%s\n' \
        "$target_index" "$target" "$target_index" "$exists" "$target_index" "$tracked" "$target_index" "$dirty"
    done
  fi
  printf 'TARGETS=%s\nVERDICT=OBSERVED\n' "$target_index"
  exit 0
fi

if [[ "$OP" == cleanup ]]; then
  [[ "$NO_FETCH" -eq 1 ]] || git fetch --quiet --prune "$REMOTE" >/dev/null 2>&1 || true

  merged=$(git branch --merged "$default_branch" --format='%(refname:short)' 2>/dev/null \
    | grep -vxE "$default_branch|main|master" | awk 'NF{n++} END{print n+0}')

  cutoff=$(( $(date +%s) - STALE_DAYS * 86400 ))
  stale=0; unsynced=0
  while IFS=$'\t' read -r ref ts up; do
    [[ -n "$ref" ]] || continue
    [[ "$ref" == "$default_branch" ]] && continue
    ((ts < cutoff)) && stale=$((stale + 1))
    [[ -z "$up" ]] && unsynced=$((unsynced + 1))
  done < <(git for-each-ref --format='%(refname:short)%09%(committerdate:unix)%09%(upstream:short)' refs/heads/ 2>/dev/null)

  gone=$(git for-each-ref --format='%(upstream:track)' refs/heads/ 2>/dev/null | grep -c 'gone' || true)
  stashes=$(git stash list 2>/dev/null | awk 'NF{n++} END{print n+0}')
  oldest_stash=$(git stash list --format='%cr' 2>/dev/null | tail -1)
  size=$(git count-objects -vH 2>/dev/null | awk '/^size-pack:/{print $2 $3}')
  loose_size=$(git count-objects -vH 2>/dev/null | awk '/^size:/{print $2 $3}')
  loose=$(git count-objects -v 2>/dev/null | awk '/^count:/{print $2}')
  junk=$(git ls-files 2>/dev/null | grep -cE '(^|/)(\.DS_Store|Thumbs\.db|npm-debug\.log|\.env\.bak)$' || true)

  printf 'OP=cleanup\nDEFAULT_BRANCH=%s\nBRANCHES_MERGED=%s\nBRANCHES_STALE=%s\nBRANCHES_UNSYNCED=%s\nBRANCHES_GONE=%s\nSTASHES=%s\nOLDEST_STASH=%s\nPACKED_SIZE=%s\nLOOSE_SIZE=%s\nLOOSE_OBJECTS=%s\nTRACKED_JUNK=%s\nSTALE_DAYS=%s\n' \
    "$default_branch" "$merged" "$stale" "$unsynced" "${gone:-0}" "$stashes" "${oldest_stash:-none}" "${size:-unknown}" "${loose_size:-unknown}" "${loose:-0}" "${junk:-0}" "$STALE_DAYS"

  # The verdict covers only what needs a human decision: which branch to delete,
  # whether a stash is still wanted, whether junk should be untracked. Loose
  # objects are deliberately excluded — git creates them on every commit and
  # packs them during routine `gc`, so counting them made DIRTY fire on any
  # repo touched since its last repack. A verdict that is always DIRTY gets
  # ignored, which is how a real forgotten stash slips past.
  if ((merged + stale + unsynced + stashes + junk > 0)); then
    printf 'VERDICT=DIRTY\n'
  else
    printf 'VERDICT=CLEAN\n'
  fi

  # Loose objects are a maintenance hint (tier 2), not repo dirt. Report them
  # separately so `gc` can still be suggested against a CLEAN verdict.
  ((${loose:-0} > 500)) && printf 'SUGGEST=gc\n'
  exit 0
fi

if [[ "$OP" == scan ]]; then
  last_tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
  range=${last_tag:+$last_tag..HEAD}
  subjects=$(git log --no-merges --format='%s' ${range:-} 2>/dev/null || true)
  total=$(printf '%s\n' "$subjects" | awk 'NF{n++} END{print n+0}')

  printf 'OP=scan\nSINCE=%s\nCOMMITS=%s\n' "${last_tag:-repo-root}" "$total"
  for t in feat fix docs refactor test chore perf ci; do
    n=$(printf '%s\n' "$subjects" | grep -cE "^$t(\(|!|:)" || true)
    ((n > 0)) && printf '%s=%s\n' "$(printf '%s' "$t" | tr '[:lower:]' '[:upper:]')" "$n"
  done
  other=$(printf '%s\n' "$subjects" | grep -vcE '^(feat|fix|docs|refactor|test|chore|perf|ci)(\(|!|:)' || true)
  ((other > 0)) && printf 'UNCONVENTIONAL=%s\n' "$other"
  printf '%s\n' "$subjects" | grep -qE '^[a-z]+(\(.*\))?!:|BREAKING CHANGE' && printf 'BREAKING=yes\n'

  if ((total == 0)); then printf 'VERDICT=NOTHING_TO_DO\n'; exit 2; fi
  printf 'VERDICT=CLEAN\n'
  exit 0
fi
# ---------------------------------------------------------------------------

staged_count=$(git diff --cached --name-only 2>/dev/null | awk 'NF{n++} END{print n+0}')
unstaged_count=$(git status --porcelain 2>/dev/null | awk 'substr($0,1,2)!="??" && substr($0,2,1)!=" "{n++} END{print n+0}')
untracked_count=$(git status --porcelain 2>/dev/null | awk 'substr($0,1,2)=="??"{n++} END{print n+0}')
outgoing=0
blockers=()
warnings=()

add_blocker() { blockers+=("$1"); }
add_warning() { warnings+=("$1"); }

if [[ "$OP" == commit || "$OP" == push ]]; then
  if [[ -z "$branch" ]]; then
    add_blocker detached-head
  elif [[ "$branch" == "$default_branch" && "$ALLOW_MAIN" -ne 1 ]]; then
    add_blocker "direct-write-to-default-branch:$branch"
  fi

  staged_names=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)
  if [[ -n "$staged_names" ]]; then
    if printf '%s\n' "$staged_names" | grep -Eq '(^|/)\.env($|\.)'; then
      add_blocker staged-env-file
    fi
    if printf '%s\n' "$staged_names" | grep -Eq '(^|/)(_archive|_backups|node_modules|dist|build)(/|$)'; then
      add_blocker staged-generated-or-stale-directory
    fi

    added_lines=$(git diff --cached --no-ext-diff --unified=0 2>/dev/null | awk '/^\+\+\+/{next} /^\+/{print}' || true)
    if printf '%s\n' "$added_lines" | grep -Eq "$GIT_STACK_SECRET_RE"; then
      add_blocker staged-secret-pattern
    fi

    # Escalate to gitleaks when it is installed. The regex above is the floor,
    # not the ceiling: it only matches known vendor prefixes. gitleaks adds
    # entropy detection and ~170 rules. Never a hard dependency — an absent
    # scanner produces a hint, not a blocker.
    gitleaks_scan >/dev/null
    case $? in
      1) add_blocker gitleaks-detected-secret ;;
      2) add_warning "$GIT_STACK_GITLEAKS_HINT" ;;
      3) add_warning gitleaks-error-skipped ;;
    esac
    if printf '%s\n' "$added_lines" | grep -Eq '(/Users/[A-Za-z0-9._-]+/|/home/[A-Za-z0-9._-]+/)'; then
      add_blocker staged-absolute-user-path
    fi

    large_files=0
    while IFS= read -r path; do
      [[ -f "$path" ]] || continue
      if stat -f '%z' "$path" >/dev/null 2>&1; then
        size=$(stat -f '%z' "$path")
      else
        size=$(stat -c '%s' "$path" 2>/dev/null || printf 0)
      fi
      ((size > 512000)) && large_files=$((large_files + 1))
    done <<< "$staged_names"
    ((large_files > 0 && ALLOW_LARGE != 1)) && add_blocker "staged-files-over-500KB:$large_files"
  fi

  if [[ ! -f .gitignore ]]; then
    add_blocker missing-gitignore
  else
    grep -Eq '(^|/)\.env([.*]|$)' .gitignore || add_warning gitignore-missing-env-pattern
  fi

  if ! bash "$SCRIPT_DIR/check-author-email.sh" --staged >/dev/null 2>&1; then
    add_warning author-email-leak
  fi
fi

if [[ "$OP" == push || "$OP" == tag || "$OP" == release ]]; then
  if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
    add_blocker "missing-remote:$REMOTE"
  elif [[ "$NO_FETCH" -ne 1 ]] && ! git fetch --quiet "$REMOTE" >/dev/null 2>&1; then
    add_blocker "fetch-failed:$REMOTE"
  fi

  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)
  if [[ -n "$upstream" ]]; then
    counts=$(git rev-list --left-right --count "$upstream...HEAD" 2>/dev/null || printf '0 0')
    behind=${counts%%[[:space:]]*}
    ahead=${counts##*[[:space:]]}
    outgoing=$ahead
    ((behind > 0)) && add_blocker "branch-behind-upstream:$behind"
    if ((ahead > 0)) && ! bash "$SCRIPT_DIR/check-author-email.sh" --range "$upstream..HEAD" >/dev/null 2>&1; then
      add_warning outgoing-author-email-leak
    fi
  else
    outgoing=$(git rev-list --count HEAD 2>/dev/null || printf 0)
    if [[ "$OP" == tag || "$OP" == release ]]; then add_blocker no-upstream; else add_warning no-upstream; fi
  fi

  if [[ "$OP" == tag && "$outgoing" -gt 0 ]]; then
    add_blocker "unpushed-commits:$outgoing"
  fi

  if [[ "$OP" == push || "$OP" == release ]]; then
    bash "$SCRIPT_DIR/check-manifests.sh" >/dev/null 2>&1
    manifest_exit=$?
    if [[ "$manifest_exit" -eq 1 ]]; then
      if [[ "$OP" == release ]]; then add_blocker manifest-version-drift; else add_warning manifest-version-drift; fi
    fi
  fi
fi

if [[ "$OP" == tag || "$OP" == release ]]; then
  [[ -n "$VERSION" ]] || add_blocker missing-version
  VERSION=${VERSION#v}
  [[ -z "$VERSION" || "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]] || add_blocker invalid-version
  [[ "$branch" == "$default_branch" ]] || add_blocker "tag-requires-default-branch:$default_branch"
  [[ -z "$(git status --porcelain 2>/dev/null)" ]] || add_blocker dirty-working-tree
  [[ -z "$VERSION" ]] || ! git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null || add_blocker "tag-exists:v$VERSION"
fi

printf 'OP=%s\nMODE=%s\nBRANCH=%s\nDEFAULT_BRANCH=%s\nSTAGED=%s\nUNSTAGED=%s\nUNTRACKED=%s\nOUTGOING=%s\n' \
  "$OP" "$MODE" "${branch:-DETACHED}" "$default_branch" "$staged_count" "$unstaged_count" "$untracked_count" "$outgoing"
if ((${#warnings[@]})); then
  for item in "${warnings[@]}"; do printf 'WARNING=%s\n' "$item"; done
fi

if ((${#blockers[@]})); then
  printf 'VERDICT=BLOCKED\n'
  for item in "${blockers[@]}"; do printf 'BLOCKER=%s\n' "$item"; done
  exit 1
fi

if [[ "$MODE" == check ]]; then
  if [[ "$OP" == commit && "$staged_count" -eq 0 ]]; then
    printf 'VERDICT=NOTHING_TO_DO\n'
    exit 2
  fi
  if [[ "$OP" == push && "$staged_count" -eq 0 && "$outgoing" -eq 0 ]]; then
    printf 'VERDICT=NOTHING_TO_DO\n'
    exit 2
  fi
  printf 'VERDICT=CLEAN\n'
  exit 0
fi

if [[ "$OP" == commit || "$OP" == push ]]; then
  if ((staged_count > 0)); then
    if [[ -z "$MESSAGE" ]]; then
      printf 'VERDICT=BLOCKED\nBLOCKER=missing-commit-message\n'
      exit 1
    fi
    if ! git commit -m "$MESSAGE" >/dev/null; then
      printf 'VERDICT=BLOCKED\nBLOCKER=commit-failed\n'
      exit 1
    fi
    printf 'COMMIT=%s\n' "$(git log -1 --format='%h %s')"
  fi
fi

if [[ "$OP" == push ]]; then
  if git rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then
    git push --quiet || { printf 'VERDICT=BLOCKED\nBLOCKER=push-failed\n'; exit 1; }
  else
    git push --quiet --set-upstream "$REMOTE" "$branch" || { printf 'VERDICT=BLOCKED\nBLOCKER=push-failed\n'; exit 1; }
  fi
  printf 'PUSHED=%s->%s/%s\n' "$branch" "$REMOTE" "$branch"
elif [[ "$OP" == tag ]]; then
  git tag -a "v$VERSION" -m "Release v$VERSION" || { printf 'VERDICT=BLOCKED\nBLOCKER=tag-failed\n'; exit 1; }
  git push --quiet "$REMOTE" "v$VERSION" || { printf 'VERDICT=BLOCKED\nBLOCKER=tag-push-failed\n'; exit 1; }
  printf 'TAGGED=v%s\n' "$VERSION"
elif [[ "$OP" == release ]]; then
  printf 'VERDICT=CLEAN\nNEXT=bump-changelog-then-run-tag\n'
  exit 0
fi

printf 'VERDICT=DONE\n'
