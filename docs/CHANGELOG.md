# Changelog

All notable changes are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [1.5.0] — 2026-05-12

### Added
- `git-guard/scripts/bump-manifests.sh` — companion to `check-manifests.sh`. Writes a target version into every detected project-level manifest (plugin.json, marketplace.json, package.json, pyproject.toml, Cargo.toml, composer.json, *.gemspec, pom.xml, build.gradle, VERSION, README badge). Idempotent. Component-level frontmatter and CHANGELOG entries are not touched. Exit 0 success, 1 write failure, 2 nothing detected.
- `git-guard` SKILL.md → safety rule #15: releases must use the **bump → audit** pattern. Pre-write check is informational only; the post-write audit against the target version is the real release gate.

### Changed
- `/wrap-up` → v1.2.0: Phase 4i (manifest alignment) downgraded to "pre-state snapshot" (informational). New Phase 6c executes `bump-manifests.sh`. New Phase 6.5 re-audits against the target version and offers auto-fix on remaining drift. The post-write audit is now the real release gate.
- `/release` → v1.2.0: Step 2.5 split into 2.5a (dry-run preview), 2.5b (execute bump), 2.5c (post-write audit + auto-fix). Closing reminder about manual manifest bumps removed — the bumper handles it.
- `git-guard` SKILL.md rule #13: now scoped to `/push` only (informational warning). Release-time manifest behavior moved to new rule #15.
- `git-guard` skill → v1.4.0.

### Fixed
- `pre-commit-block-secrets.sh` and the canonical secrets-scan snippet in `core.md`, `commands/commit.md`, `commands/wrap-up.md`: now scan ADDED lines only (`grep '^+' | grep -v '^+++'`). Previous behavior matched on `-` lines too, which blocked legitimate cleanup commits that removed a previously-leaked secret. Cleanup commits no longer require `--no-verify`.

---

## [1.4.0] — 2026-05-11

### Added
- `git-guard/scripts/pre-commit-block-secrets.sh` — reusable pre-commit hook that scans staged content for known secret patterns (same set as `core.md` → "Secrets / API key scan") and blocks the commit on match. Exit 0 on clean, exit 1 on detected secret. Works as drop-in or via symlink.
- `git-guard/scripts/install-hooks.sh` — preview-only installer. Detects the target repo's `.git/hooks/` location and prints both `cp` (snapshot) and `ln -s` (auto-update) install commands. Never modifies anything itself.
- `git-guard` SKILL.md → safety rule #14: invoke the installer when the user asks to wire up secret protection in a repo.
- `core.md` → new "Installing the secret-block hook (per-repo)" section with mode comparison (copy vs symlink) and `--no-verify` caveat.

### Changed
- `git-guard` skill → v1.3.0

---

## [1.3.0] — 2026-05-11

### Added
- `git-guard/scripts/check-manifests.sh` — general-purpose manifest auditor that detects which ecosystems a repo uses (Claude plugin, Codex plugin, Node, Python, Rust, PHP, Ruby, Maven, Gradle, generic `VERSION` file) and verifies every project-level version field aligns: plugin manifests, package manifests, `CHANGELOG.md` top entry, `README.md` shields.io badge. Reports drift with severity and exit codes (0 aligned, 1 drift, 2 nothing-found). Component-level versions (per-skill/per-command frontmatter) shown informationally.
- `git-guard` SKILL.md → safety rule #13: run the manifest auditor before any release.
- `/release` → Step 2.5: manifest alignment check, BLOCKS on drift, asks fix/override/abort.
- `/wrap-up` → Phase 4i: same check, HIGH severity, blocks the release confirmation gate.
- `/push` → Step 2h: same check, WARNING severity (push isn't a release, so drift is informational).

### Changed
- `git-guard` skill → v1.2.0
- `/push` → v2.1.0, `/wrap-up` → v1.1.0, `/release` → v1.1.0

---

## [1.2.0] — 2026-05-11

### Added
- `git-guard` SKILL.md → safety rules #11 (pre-commit secrets scan) and #12 (on-request repo-wide audit of working tree + git history)
- `git-guard/references/core.md` → "Secrets / API key scan" with patterns for OpenAI (`sk-proj-`, `sk-`), Anthropic (`sk-ant-`), Jina, Tavily, Apify, GitHub PATs (`ghp_`, `gho_`, `github_pat_`), AWS (`AKIA`), Google (`AIza`), Slack (`xoxb-`), Hugging Face (`hf_`), and PEM private key blocks
- `git-guard/references/core.md` → "Repo-wide secret audit" (3-pass: tracked files, env/config files, full git history) with severity table and false-positive guidance
- `git-guard/references/decisions.md` → "I want to back up a config file that always contains secrets" branch documenting the git clean-filter pattern with full setup steps (`.gitattributes` + `scripts/redact-secrets.sh` + pre-commit safety net)

### Changed
- `/commit` and `/push` → v2.0.0: rewritten as thin orchestrators that reference `git-guard/references/core.md` for canonical scan patterns; eliminates duplication between command checks and skill knowledge
- `git-guard` skill bumped to v1.1.0 (new behavior, backwards-compatible)

---

## [1.1.0] — 2026-05-10

### Added
- `/release` command — tag a release, update CHANGELOG, and push the tag
- `hooks/hooks.json` + `hooks/hooks-codex.json` — empty hook stubs required by plugin spec

### Fixed
- Renamed `git-repo-prettifier` → `repo-prettifier` across skill folder, symlinks, AGENTS.md, README.md
- `.agents/plugins/marketplace.json` — corrected `source.path` from `../../` to `./`, added `policy` block
- `.codex-plugin/plugin.json` — added missing `hooks` field

---

## [1.0.1] — 2026-05-06

### Added
- `docs/CHANGELOG.md` — changelog for this plugin bundle
- Orphan branch technique for squashing full history in `git-guard/references/core.md`

### Changed
- Added `version: 1.0.0` frontmatter to all commands (`changelog`, `commit`, `push`, `update-docs`, `wrap-up`) and skills (`git-guard`, `git-repo-prettifier`)
