#!/usr/bin/env bash
# bump-manifests.sh — Write a target version into every project-level manifest
# this repo uses. Mirrors the detection logic of check-manifests.sh.
#
# Project-level only: package.json, pyproject.toml, Cargo.toml, composer.json,
# *.gemspec, pom.xml, build.gradle, VERSION, .claude-plugin/plugin.json,
# .claude-plugin/marketplace.json (.metadata.version + .plugins[].version),
# .codex-plugin/plugin.json, README.md shields.io version badge.
#
# CHANGELOG.md is NOT touched — entries are written by /wrap-up's changelog phase.
# Component-level versions (per-skill SKILL.md, per-command frontmatter) are
# NOT touched — they evolve independently of the project release.
#
# macOS bash 3.2 compatible.
#
# Usage:
#   bump-manifests.sh <target-version>           # write
#   bump-manifests.sh <target-version> --dry-run # preview only
#
# Exit codes:
#   0  success (or dry-run preview)
#   1  bad usage / write failure
#   2  no manifests detected (silent skip — caller decides what to do)

set -uo pipefail

# --- args --------------------------------------------------------------------

TARGET="${1:-}"
DRY=0
[ "${2:-}" = "--dry-run" ] && DRY=1

if [ -z "$TARGET" ]; then
  echo "usage: bump-manifests.sh <target-version> [--dry-run]" >&2
  exit 1
fi

# strip leading 'v' if present
TARGET="${TARGET#v}"

# very loose semver sanity check
case "$TARGET" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "✗ '$TARGET' doesn't look like a semver (X.Y.Z)" >&2; exit 1 ;;
esac

# --- helpers -----------------------------------------------------------------

bold() { printf '\033[1m%s\033[0m' "$1"; }
red()  { printf '\033[31m%s\033[0m' "$1"; }
yel()  { printf '\033[33m%s\033[0m' "$1"; }
grn()  { printf '\033[32m%s\033[0m' "$1"; }
dim()  { printf '\033[2m%s\033[0m' "$1"; }

has() { command -v "$1" >/dev/null 2>&1; }

# Parallel arrays of planned writes.
PLAN_FILE=()
PLAN_FROM=()
PLAN_DESC=()

plan() {
  PLAN_FILE+=("$1"); PLAN_FROM+=("$2"); PLAN_DESC+=("$3")
}

# Read current value (best-effort, used for plan display only).
json_top_version() {
  if has jq; then
    jq -r '.version // empty' "$1" 2>/dev/null
  else
    grep -m1 '"version"' "$1" 2>/dev/null | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
  fi
}

readme_badge_version() {
  grep -oE 'badge/version-[0-9]+\.[0-9]+\.[0-9]+' "$1" 2>/dev/null | head -1 | sed -E 's|.*version-||'
}

toml_section_version() {
  local file="$1" section="$2"
  if has python3; then
    python3 - "$file" "$section" 2>/dev/null <<'PY'
import sys
try: import tomllib
except ImportError:
    try: import tomli as tomllib
    except ImportError: sys.exit(0)
path, section = sys.argv[1], sys.argv[2]
with open(path, "rb") as f: data = tomllib.load(f)
node = data
for part in section.split("."):
    if not isinstance(node, dict) or part not in node: sys.exit(0)
    node = node[part]
if isinstance(node, dict) and "version" in node: print(node["version"])
PY
  else
    awk -v sec="[$section]" '
      $0 == sec { in_sec=1; next }
      /^\[/ && in_sec { exit }
      in_sec && $1 == "version" {
        sub(/^[^=]+=[[:space:]]*/, ""); gsub(/["'\'']/, ""); print; exit
      }
    ' "$file" 2>/dev/null
  fi
}

# In-place edit helpers (sed -i differs on macOS vs GNU; use a temp file).
write_inplace() {
  local file="$1" tmp
  tmp=$(mktemp) || return 1
  cat > "$tmp" || { rm -f "$tmp"; return 1; }
  mv "$tmp" "$file"
}

# Top-level JSON .version replacement (line-targeted, preserves formatting).
bump_json_top_version() {
  local file="$1"
  awk -v new="$TARGET" '
    !done && /^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"[^"]*"/ {
      sub(/"version"[[:space:]]*:[[:space:]]*"[^"]*"/, "\"version\": \"" new "\"")
      done=1
    }
    { print }
  ' "$file" | write_inplace "$file"
}

# Replace marketplace.json .metadata.version + every .plugins[].version.
# Uses jq if available (clean), falls back to a coarser sed-style awk pass.
bump_marketplace_json() {
  local file="$1"
  if has jq; then
    local tmp; tmp=$(mktemp)
    jq --arg v "$TARGET" '
      (if .metadata? then .metadata.version = $v else . end)
      | (if .plugins? then .plugins |= map(.version = $v) else . end)
    ' "$file" > "$tmp" && mv "$tmp" "$file"
  else
    # Fallback: rewrite every "version": "..." occurrence in the file. Coarse
    # but acceptable since marketplace.json should only contain version fields
    # we want bumped together.
    awk -v new="$TARGET" '
      { gsub(/"version"[[:space:]]*:[[:space:]]*"[^"]*"/, "\"version\": \"" new "\"") }
      { print }
    ' "$file" | write_inplace "$file"
  fi
}

# Replace `version = "..."` under a TOML [section].
bump_toml_section_version() {
  local file="$1" section="$2"
  awk -v sec="[$section]" -v new="$TARGET" '
    BEGIN { in_sec=0; done=0 }
    {
      line=$0
      if (line == sec) { in_sec=1; print; next }
      if (in_sec && line ~ /^\[/) { in_sec=0 }
      if (in_sec && !done && line ~ /^[[:space:]]*version[[:space:]]*=/) {
        sub(/=[[:space:]]*"[^"]*"/, "= \"" new "\"", line)
        sub(/=[[:space:]]*'\''[^'\'']*'\''/, "= \"" new "\"", line)
        done=1
      }
      print line
    }
  ' "$file" | write_inplace "$file"
}

# setup.cfg: top-level `version = X.Y.Z`
bump_setup_cfg_version() {
  awk -v new="$TARGET" '
    !done && /^[[:space:]]*version[[:space:]]*=/ {
      sub(/=[[:space:]]*.*/, "= " new); done=1
    }
    { print }
  ' "$1" | write_inplace "$1"
}

# *.gemspec: spec.version = "X.Y.Z"
bump_gemspec_version() {
  awk -v new="$TARGET" '
    !done && /^[[:space:]]*[a-z_]+\.version[[:space:]]*=/ {
      sub(/=[[:space:]]*["'\''][^"'\'']*["'\'']/, "= \"" new "\""); done=1
    }
    { print }
  ' "$1" | write_inplace "$1"
}

# pom.xml: only the FIRST top-level <version>…</version>.
# Real Maven projects often have many <version> tags (parent, deps); we target
# the project's own version block. Heuristic: first <version> after <project ...>
# and before any <dependencies>/<parent>. xmllint preferred when available.
bump_pom_xml_version() {
  local file="$1"
  awk -v new="$TARGET" '
    BEGIN { done=0; in_parent=0; in_deps=0 }
    /<parent>/        { in_parent=1 }
    /<\/parent>/      { in_parent=0 }
    /<dependencies>/  { in_deps=1 }
    /<\/dependencies>/{ in_deps=0 }
    !done && !in_parent && !in_deps && /<version>[^<]+<\/version>/ {
      sub(/<version>[^<]+<\/version>/, "<version>" new "</version>"); done=1
    }
    { print }
  ' "$file" | write_inplace "$file"
}

# Gradle: top-level `version = "X.Y.Z"` (Kotlin DSL or Groovy DSL).
bump_gradle_version() {
  awk -v new="$TARGET" '
    !done && /^[[:space:]]*version[[:space:]]*=/ {
      sub(/=[[:space:]]*["'\''][^"'\'']*["'\'']/, "= \"" new "\""); done=1
    }
    { print }
  ' "$1" | write_inplace "$1"
}

# Generic VERSION file: replace contents entirely.
bump_version_file() {
  printf '%s\n' "$TARGET" > "$1"
}

# README badge: shields.io `badge/version-X.Y.Z`.
bump_readme_badge() {
  awk -v new="$TARGET" '
    !done && /badge\/version-[0-9]+\.[0-9]+\.[0-9]+/ {
      sub(/badge\/version-[0-9]+\.[0-9]+\.[0-9]+/, "badge/version-" new); done=1
    }
    { print }
  ' "$1" | write_inplace "$1"
}

# --- detection + plan --------------------------------------------------------

# Node
if [ -r package.json ]; then
  plan "package.json" "$(json_top_version package.json)" "Node — top-level .version"
fi

# Python pyproject
if [ -r pyproject.toml ]; then
  v=$(toml_section_version pyproject.toml project)
  if [ -n "$v" ]; then
    plan "pyproject.toml" "$v" "Python — [project] version"
    PROJ_TOML_SECTION="project"
  else
    v=$(toml_section_version pyproject.toml tool.poetry)
    if [ -n "$v" ]; then
      plan "pyproject.toml" "$v" "Python — [tool.poetry] version"
      PROJ_TOML_SECTION="tool.poetry"
    fi
  fi
fi

# Python setup.cfg
if [ -r setup.cfg ]; then
  v=$(awk -F= '/^[[:space:]]*version[[:space:]]*=/ {gsub(/[[:space:]]/,"",$2); print $2; exit}' setup.cfg)
  [ -n "$v" ] && plan "setup.cfg" "$v" "Python — version ="
fi

# Rust
if [ -r Cargo.toml ]; then
  v=$(toml_section_version Cargo.toml package)
  [ -n "$v" ] && plan "Cargo.toml" "$v" "Rust — [package] version"
fi

# PHP
if [ -r composer.json ]; then
  v=$(json_top_version composer.json)
  [ -n "$v" ] && plan "composer.json" "$v" "PHP — top-level .version"
fi

# Ruby gemspec
GEMSPEC=""
for g in *.gemspec; do
  [ -e "$g" ] || continue
  v=$(grep -E "^\s*[a-z_]+\.version\s*=" "$g" 2>/dev/null | head -1 | sed -E 's/.*=\s*["'"'"']([^"'"'"']+)["'"'"'].*/\1/')
  if [ -n "$v" ]; then
    plan "$g" "$v" "Ruby — spec.version"
    GEMSPEC="$g"
  fi
  break
done

# Maven
if [ -r pom.xml ]; then
  if has xmllint; then
    v=$(xmllint --xpath "string(/*[local-name()='project']/*[local-name()='version'])" pom.xml 2>/dev/null)
  else
    v=$(grep -m1 -oE '<version>[^<]+</version>' pom.xml 2>/dev/null | sed -E 's|</?version>||g')
  fi
  [ -n "$v" ] && plan "pom.xml" "$v" "Maven — project <version>"
fi

# Gradle
for gf in build.gradle build.gradle.kts; do
  [ -r "$gf" ] || continue
  v=$(grep -m1 -E '^\s*version\s*=' "$gf" 2>/dev/null | sed -E "s/.*=\s*[\"']([^\"']+)[\"'].*/\1/")
  [ -n "$v" ] && plan "$gf" "$v" "Gradle — top-level version ="
done

# Generic VERSION
for vf in VERSION VERSION.txt; do
  if [ -r "$vf" ]; then
    v=$(head -1 "$vf")
    [ -n "$v" ] && plan "$vf" "$v" "Generic — VERSION file contents"
  fi
done

# Claude plugin
if [ -d .claude-plugin ]; then
  if [ -r .claude-plugin/plugin.json ]; then
    plan ".claude-plugin/plugin.json" "$(json_top_version .claude-plugin/plugin.json)" "Claude plugin manifest"
  fi
  if [ -r .claude-plugin/marketplace.json ]; then
    cur=""
    if has jq; then
      cur=$(jq -r '.metadata.version // empty' .claude-plugin/marketplace.json 2>/dev/null)
    else
      cur=$(grep -m1 '"version"' .claude-plugin/marketplace.json | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    fi
    plan ".claude-plugin/marketplace.json" "$cur" "Claude marketplace (.metadata + .plugins[].version)"
  fi
fi

# Codex plugin
if [ -d .codex-plugin ] && [ -r .codex-plugin/plugin.json ]; then
  plan ".codex-plugin/plugin.json" "$(json_top_version .codex-plugin/plugin.json)" "Codex plugin manifest"
fi

# README badge (only if it actually carries a version badge)
if [ -r README.md ]; then
  rv=$(readme_badge_version README.md)
  [ -n "$rv" ] && plan "README.md" "$rv" "README — shields.io version badge"
fi

# --- nothing detected: silent skip -------------------------------------------

if [ ${#PLAN_FILE[@]} -eq 0 ]; then
  # Caller (e.g. /wrap-up) decided this is OK — exit 2, no noise on stderr.
  exit 2
fi

# --- print plan --------------------------------------------------------------

echo
bold "── bump-manifests"; [ $DRY -eq 1 ] && bold "  (dry-run)"; echo
echo
echo "  Target version: $(grn "$TARGET")"
echo
bold "  Planned writes:"; echo
i=0
while [ $i -lt ${#PLAN_FILE[@]} ]; do
  file="${PLAN_FILE[$i]}"
  from="${PLAN_FROM[$i]}"
  desc="${PLAN_DESC[$i]}"
  if [ "$from" = "$TARGET" ]; then
    printf "    %s  %s  %s\n" "$(dim "= $TARGET")" "$file" "$(dim "($desc — already aligned)")"
  else
    printf "    %s  %s  %s\n" "$(yel "$from → $TARGET")" "$file" "$(dim "($desc)")"
  fi
  i=$((i+1))
done
echo

if [ $DRY -eq 1 ]; then
  echo "  $(dim "Dry-run — no files modified.")"
  exit 0
fi

# --- execute writes ----------------------------------------------------------

WRITES=0
SKIPS=0
FAILS=0

for i in $(seq 0 $((${#PLAN_FILE[@]} - 1))); do
  file="${PLAN_FILE[$i]}"
  from="${PLAN_FROM[$i]}"

  if [ "$from" = "$TARGET" ]; then
    SKIPS=$((SKIPS+1))
    continue
  fi

  ok=1
  case "$file" in
    package.json|composer.json) bump_json_top_version "$file" || ok=0 ;;
    .claude-plugin/plugin.json) bump_json_top_version "$file" || ok=0 ;;
    .codex-plugin/plugin.json)  bump_json_top_version "$file" || ok=0 ;;
    .claude-plugin/marketplace.json) bump_marketplace_json "$file" || ok=0 ;;
    pyproject.toml) bump_toml_section_version "$file" "${PROJ_TOML_SECTION:-project}" || ok=0 ;;
    Cargo.toml)     bump_toml_section_version "$file" "package" || ok=0 ;;
    setup.cfg)      bump_setup_cfg_version "$file" || ok=0 ;;
    pom.xml)        bump_pom_xml_version "$file" || ok=0 ;;
    build.gradle|build.gradle.kts) bump_gradle_version "$file" || ok=0 ;;
    VERSION|VERSION.txt) bump_version_file "$file" || ok=0 ;;
    README.md)      bump_readme_badge "$file" || ok=0 ;;
    *.gemspec)      bump_gemspec_version "$file" || ok=0 ;;
    *)
      echo "    $(red "✗ no bump rule for") $file" >&2
      ok=0
      ;;
  esac

  if [ $ok -eq 1 ]; then
    WRITES=$((WRITES+1))
  else
    FAILS=$((FAILS+1))
  fi
done

echo
if [ $FAILS -eq 0 ]; then
  echo "  $(grn "✓ Bumped $WRITES file(s)") (skipped $SKIPS already-aligned)."
  echo "  $(dim "Re-run scripts/check-manifests.sh to verify post-write alignment.")"
  exit 0
else
  echo "  $(red "✗ Bumped $WRITES, $FAILS failed, $SKIPS skipped.")"
  echo "  $(dim "Inspect failures above. Some files may be partially updated.")"
  exit 1
fi
