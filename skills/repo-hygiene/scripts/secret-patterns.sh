#!/usr/bin/env bash
# GENERATED COPY — source of truth: src/scripts/secret-patterns.sh
# Edit the source and run `node src/sync-scripts.mjs`. Do not edit here.
# secret-patterns.sh — the built-in secret regex, defined once.
#
# Sourced by git-stack.sh and pre-commit-block-secrets.sh. Both used to carry
# their own verbatim copy of this pattern; they drifted apart silently because
# nothing compared them. Add new patterns HERE and both callers pick them up.
#
# This is the always-works floor: no dependencies, prefix-matching only. It
# catches tokens with a recognizable vendor prefix and misses everything else
# (bare high-entropy values, embedded DB passwords, unprefixed vendor tokens).
# gitleaks_scan below escalates to a real scanner when one is installed.

# shellcheck disable=SC2034  # consumed by the sourcing script
GIT_STACK_SECRET_RE='(sk-proj-[A-Za-z0-9_-]{40,}|sk-ant-[a-z0-9-]+-[A-Za-z0-9_-]{40,}|sk-[A-Za-z0-9]{40,}|jina_[A-Za-z0-9]{40,}|tvly-(dev-|prod-)?[A-Za-z0-9_-]{20,}|apify_api_[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{30,}|xoxb-[A-Za-z0-9-]{20,}|hf_[A-Za-z0-9]{30,}|-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----)'

# Suggested install line, shown when gitleaks is absent. Kept here so the two
# callers word it identically.
GIT_STACK_GITLEAKS_HINT='optional: install gitleaks for ~170 rules + entropy detection (brew install gitleaks)'

# gitleaks_scan — run gitleaks over the staged diff, if it is installed.
#
# Prints nothing. Exit codes are deliberately distinct from "found/not found"
# so callers can tell an absent scanner from a clean one:
#   0  gitleaks ran and found nothing
#   1  gitleaks ran and found leaks
#   2  gitleaks is not installed (caller decides whether to hint)
#   3  gitleaks is installed but errored (bad config, unreadable repo)
#
# `--staged` scans the index, matching what the built-in regex looks at.
# `--redact` keeps the secret value out of stdout and out of agent context.
#
# gitleaks trades false negatives for false positives: it flags placeholder
# and fixture values such as "sk_test_placeholder" in example code. A repo
# with such fixtures should allowlist them in .gitleaks.toml, which gitleaks
# picks up from the repo root automatically. Callers should point the user
# there rather than suggesting they bypass the hook.
gitleaks_scan() {
  command -v gitleaks >/dev/null 2>&1 || return 2

  local out status
  # gitleaks writes BOTH its progress logs and its findings to stderr, so the
  # capture must include it. NO_COLOR strips ANSI escapes that would otherwise
  # land in hook output and agent context.
  # -v prints the finding table (file, line, rule). Without it, --redact
  # reduces the output to a bare "leaks found: N" the user cannot act on.
  out=$(NO_COLOR=1 gitleaks protect --staged --redact -v --no-banner 2>&1)
  status=$?

  case "$status" in
    0) return 0 ;;
    1)
      # Keep the finding table; drop timing/progress lines. gitleaks ignores
      # NO_COLOR for the REDACTED marker, so strip ANSI escapes explicitly.
      printf '%s\n' "$out" \
        | grep -vE '(INF|DBG|WRN)[[:space:]]' \
        | sed $'s/\033\[[0-9;]*m//g' \
        | sed '/^[[:space:]]*$/d'
      return 1
      ;;
    *) return 3 ;;
  esac
}
