#!/usr/bin/env bash
# check-manifests.sh — Audit version fields in a repo.
#
# Step 1: Detect which ecosystems/conventions this repo uses (by marker files).
# Step 2: For each detected ecosystem, read its primary version field(s).
# Step 3: Always also read CHANGELOG top entry + README badge.
# Step 4: Report drift across project-level fields. Component-level (.md
#         frontmatter, sub-packages) is shown for visibility only.
#
# macOS bash 3.2 compatible: no associative arrays, no `declare -A`.
#
# Exit codes:
#   0  no project-level drift
#   1  project-level drift detected
#   2  nothing found

set -uo pipefail

# --- colors -------------------------------------------------------------------
bold() { printf '\033[1m%s\033[0m' "$1"; }
red()  { printf '\033[31m%s\033[0m' "$1"; }
yel()  { printf '\033[33m%s\033[0m' "$1"; }
grn()  { printf '\033[32m%s\033[0m' "$1"; }
dim()  { printf '\033[2m%s\033[0m' "$1"; }

# --- capabilities -------------------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }

# --- value cleaning -----------------------------------------------------------
clean() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"
  s="${s#\"}"; s="${s%\"}"; s="${s#\'}"; s="${s%\'}"
  printf '%s' "$s"
}

# --- field readers ------------------------------------------------------------

fm_version() {  # markdown frontmatter
  awk '
    /^---[[:space:]]*$/ { if (++c == 1) next; if (c == 2) exit }
    c == 1 && /^version:/ { sub(/^version:[[:space:]]*/,""); gsub(/["'\'']/,""); print; exit }
    c == 1 && /^metadata:[[:space:]]*$/ { in_metadata=1; next }
    c == 1 && in_metadata && /^[^[:space:]]/ { in_metadata=0 }
    c == 1 && in_metadata && /^[[:space:]]+version:/ {
      sub(/^[[:space:]]+version:[[:space:]]*/,""); gsub(/["'\'']/,""); print; exit
    }
  ' "$1" 2>/dev/null
}

json_top_version() {  # .version from top-level JSON
  if has jq; then
    jq -r '.version // empty' "$1" 2>/dev/null
  else
    grep -m1 '"version"' "$1" 2>/dev/null | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
  fi
}

toml_version() {  # version under [section]
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

# --- result accumulators (parallel arrays; bash 3.2 safe) --------------------

PROJ_LOCS=()
PROJ_VERS=()
COMP_LOCS=()
COMP_VERS=()
DETECTED=()

add_proj() {
  local v; v=$(clean "$2"); [ -n "$v" ] || return
  PROJ_LOCS+=("$1"); PROJ_VERS+=("$v")
}
add_comp() {
  local v; v=$(clean "$2"); [ -n "$v" ] || return
  COMP_LOCS+=("$1"); COMP_VERS+=("$v")
}
mark_detected() { DETECTED+=("$1"); }

# --- ecosystem detection + collection ----------------------------------------

# Node ----------
if [ -r package.json ]; then
  mark_detected "Node (package.json)"
  add_proj "package.json" "$(json_top_version package.json)"
fi

# Python (pyproject) ----------
if [ -r pyproject.toml ]; then
  v=$(toml_version pyproject.toml project)
  [ -z "$v" ] && v=$(toml_version pyproject.toml tool.poetry)
  if [ -n "$v" ]; then
    mark_detected "Python (pyproject.toml)"
    add_proj "pyproject.toml" "$v"
  fi
fi

# Python (setup.cfg) ----------
if [ -r setup.cfg ]; then
  v=$(awk -F= '/^[[:space:]]*version[[:space:]]*=/ {gsub(/[[:space:]]/,"",$2); print $2; exit}' setup.cfg)
  if [ -n "$v" ]; then
    mark_detected "Python (setup.cfg)"
    add_proj "setup.cfg" "$v"
  fi
fi

# Rust ----------
if [ -r Cargo.toml ]; then
  v=$(toml_version Cargo.toml package)
  if [ -n "$v" ]; then
    mark_detected "Rust (Cargo.toml)"
    add_proj "Cargo.toml" "$v"
  fi
fi

# PHP ----------
if [ -r composer.json ]; then
  v=$(json_top_version composer.json)
  if [ -n "$v" ]; then
    mark_detected "PHP (composer.json)"
    add_proj "composer.json" "$v"
  fi
fi

# Ruby ----------
for g in *.gemspec; do
  [ -e "$g" ] || continue
  v=$(grep -E "^\s*[a-z_]+\.version\s*=" "$g" 2>/dev/null | head -1 | sed -E 's/.*=\s*["'"'"']([^"'"'"']+)["'"'"'].*/\1/')
  if [ -n "$v" ]; then
    mark_detected "Ruby ($g)"
    add_proj "$g" "$v"
  fi
  break
done

# Maven ----------
if [ -r pom.xml ]; then
  if has xmllint; then
    v=$(xmllint --xpath "string(/*[local-name()='project']/*[local-name()='version'])" pom.xml 2>/dev/null)
  else
    v=$(grep -m1 -oE '<version>[^<]+</version>' pom.xml 2>/dev/null | sed -E 's|</?version>||g')
  fi
  if [ -n "$v" ]; then
    mark_detected "Maven (pom.xml)"
    add_proj "pom.xml" "$v"
  fi
fi

# Gradle ----------
for gf in build.gradle build.gradle.kts; do
  [ -r "$gf" ] || continue
  v=$(grep -m1 -E '^\s*version\s*=' "$gf" 2>/dev/null | sed -E "s/.*=\s*[\"']([^\"']+)[\"'].*/\1/")
  if [ -n "$v" ]; then
    mark_detected "Gradle ($gf)"
    add_proj "$gf" "$v"
  fi
done

# Generic VERSION file ----------
for vf in VERSION VERSION.txt; do
  if [ -r "$vf" ]; then
    v=$(head -1 "$vf")
    if [ -n "$v" ]; then
      mark_detected "Generic ($vf)"
      add_proj "$vf" "$v"
    fi
  fi
done

# Claude plugin ----------
if [ -d .claude-plugin ]; then
  mark_detected "Claude plugin"
  [ -r .claude-plugin/plugin.json ] && add_proj ".claude-plugin/plugin.json" "$(json_top_version .claude-plugin/plugin.json)"
  if [ -r .claude-plugin/marketplace.json ]; then
    if has jq; then
      add_proj ".claude-plugin/marketplace.json (metadata)" "$(jq -r '.metadata.version // empty' .claude-plugin/marketplace.json 2>/dev/null)"
      while IFS=$'\t' read -r name ver; do
        [ -n "$ver" ] && add_proj ".claude-plugin/marketplace.json (plugins[$name])" "$ver"
      done < <(jq -r '.plugins // [] | .[] | [.name, .version] | @tsv' .claude-plugin/marketplace.json 2>/dev/null)
    else
      add_proj ".claude-plugin/marketplace.json" "$(grep -m1 '"version"' .claude-plugin/marketplace.json | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
    fi
  fi
fi

# Codex plugin ----------
if [ -d .codex-plugin ]; then
  mark_detected "Codex plugin"
  [ -r .codex-plugin/plugin.json ] && add_proj ".codex-plugin/plugin.json" "$(json_top_version .codex-plugin/plugin.json)"
fi

# Cursor plugin ----------
if [ -d .cursor-plugin ]; then
  mark_detected "Cursor plugin"
  [ -r .cursor-plugin/plugin.json ] && add_proj ".cursor-plugin/plugin.json" "$(json_top_version .cursor-plugin/plugin.json)"
fi

# --- always-applicable: CHANGELOG + README badge -----------------------------

for cl in docs/CHANGELOG.md CHANGELOG.md; do
  if [ -r "$cl" ]; then
    cl_ver=$(awk '/^## \[[0-9]+\.[0-9]+\.[0-9]+\]/ {
      match($0, /\[[0-9]+\.[0-9]+\.[0-9]+\]/)
      print substr($0, RSTART+1, RLENGTH-2); exit
    }' "$cl")
    add_proj "$cl (top entry)" "$cl_ver"
    break
  fi
done

if [ -r README.md ]; then
  readme_ver=$(grep -oE 'badge/version-[0-9]+\.[0-9]+\.[0-9]+' README.md | head -1 | sed -E 's|.*version-||')
  add_proj "README.md (badge)" "$readme_ver"
fi

# --- component-level: plugin and skill bundles -------------------------------

if [ -d .claude-plugin ] || [ -d .codex-plugin ] || [ -d .cursor-plugin ] || [ -d skills ] || [ -d adapters ]; then
  while IFS= read -r f; do
    add_comp "$f" "$(fm_version "$f")"
  done < <(find skills adapters .claude .agents -maxdepth 7 -type f -name "*.md" 2>/dev/null | sort)
fi

# --- if nothing detected, bail -----------------------------------------------

if [ ${#PROJ_LOCS[@]} -eq 0 ] && [ ${#COMP_LOCS[@]} -eq 0 ]; then
  echo "No recognized version-bearing files in this repo."
  echo "Looked for: package.json, pyproject.toml, Cargo.toml, composer.json, *.gemspec,"
  echo "pom.xml, build.gradle, VERSION, .claude-plugin/, .codex-plugin/, .cursor-plugin/, CHANGELOG.md, README.md."
  exit 2
fi

# --- compute drift on project-level (bash 3.2 way, no assoc arrays) ----------

PROJ_UNIQUE=$(printf '%s\n' "${PROJ_VERS[@]}" | sort -u | wc -l | tr -d ' ')
PROJ_UNIQUE=${PROJ_UNIQUE:-0}
PROJ_DRIFT=0
[ "$PROJ_UNIQUE" -gt 1 ] && PROJ_DRIFT=1

# Majority version for highlighting
MAJORITY=$(printf '%s\n' "${PROJ_VERS[@]}" | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')

# --- print report ------------------------------------------------------------

echo
bold "── Detected ecosystems"; echo
if [ ${#DETECTED[@]} -eq 0 ]; then
  echo "  $(dim "(generic — CHANGELOG/README only)")"
else
  for d in "${DETECTED[@]}"; do
    echo "  • $d"
  done
fi

echo
bold "── Project-level versions (must align)"; echo
if [ ${#PROJ_LOCS[@]} -eq 0 ]; then
  echo "  (none found)"
else
  i=0
  while [ $i -lt ${#PROJ_LOCS[@]} ]; do
    loc="${PROJ_LOCS[$i]}"; ver="${PROJ_VERS[$i]}"
    if [ $PROJ_DRIFT -eq 1 ] && [ "$ver" != "$MAJORITY" ]; then
      printf "  %s  %s  %s\n" "$(red "$ver")" "$loc" "$(red "← drift")"
    else
      printf "  %s  %s\n" "$(grn "$ver")" "$loc"
    fi
    i=$((i+1))
  done
fi

if [ ${#COMP_LOCS[@]} -gt 0 ]; then
  echo
  bold "── Component-level versions (independent — informational)"; echo
  i=0
  while [ $i -lt ${#COMP_LOCS[@]} ]; do
    printf "  %s  %s\n" "$(yel "${COMP_VERS[$i]}")" "${COMP_LOCS[$i]}"
    i=$((i+1))
  done
fi

echo
if [ $PROJ_DRIFT -eq 1 ]; then
  echo "$(red "✗ Project-level drift detected.") $PROJ_UNIQUE distinct versions across ${#PROJ_LOCS[@]} locations."
  echo "  Fix: align all project-level locations to the intended release version, then re-run."
  exit 1
elif [ ${#PROJ_LOCS[@]} -gt 0 ]; then
  echo "$(grn "✓ Project-level versions aligned") (${PROJ_VERS[0]} across ${#PROJ_LOCS[@]} locations)."
  [ ${#COMP_LOCS[@]} -gt 0 ] && echo "  Component versions shown for visibility only — they evolve independently."
  exit 0
fi
