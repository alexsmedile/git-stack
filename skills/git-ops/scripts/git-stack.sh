#!/usr/bin/env bash
set -u

# Compact, cross-runtime Git safety runner. It intentionally prints summaries,
# not raw diffs or command logs, so agents can call it without polluting context.

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OP=${1:-}
shift 2>/dev/null || true

MODE=check
MESSAGE=
VERSION=
REMOTE=origin
ALLOW_MAIN=0
ALLOW_LARGE=0
NO_FETCH=0

usage() {
  cat <<'EOF'
Usage: git-stack.sh <commit|push|tag|release> [options]

Options:
  --execute             Perform the clean-path write after checks pass
  --message <text>      Commit message (required to execute commit/push with staged changes)
  --version <X.Y.Z>     Version for tag/release
  --remote <name>       Remote name (default: origin)
  --allow-main          Explicitly allow commit/push on the default branch
  --allow-large         Explicitly allow staged files larger than 500KB
  --no-fetch            Skip fetch during push/release checks

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
    -h|--help) usage; exit 0 ;;
    *) printf 'VERDICT=BLOCKED\nBLOCKER=unknown-option:%s\n' "$1"; exit 1 ;;
  esac
  shift
done

case "$OP" in commit|push|tag|release) ;; *) usage; exit 1 ;; esac

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'VERDICT=BLOCKED\nOP=%s\nBLOCKER=not-a-git-repository\n' "$OP"
  exit 1
fi

branch=$(git branch --show-current 2>/dev/null || true)
default_branch=$(git symbolic-ref --quiet --short "refs/remotes/$REMOTE/HEAD" 2>/dev/null | sed "s#^$REMOTE/##")
if [[ -z "$default_branch" ]]; then
  case "$branch" in main|master) default_branch=$branch ;; *) default_branch=main ;; esac
fi

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
    secret_re='(sk-proj-[A-Za-z0-9_-]{40,}|sk-ant-[a-z0-9-]+-[A-Za-z0-9_-]{40,}|sk-[A-Za-z0-9]{40,}|jina_[A-Za-z0-9]{40,}|tvly-(dev-|prod-)?[A-Za-z0-9_-]{20,}|apify_api_[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{30,}|xoxb-[A-Za-z0-9-]{20,}|hf_[A-Za-z0-9]{30,}|-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----)'
    if printf '%s\n' "$added_lines" | grep -Eq "$secret_re"; then
      add_blocker staged-secret-pattern
    fi
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
