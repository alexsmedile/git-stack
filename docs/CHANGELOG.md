# Changelog

All notable changes are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---

## [1.7.2] — 2026-07-08

### Added
- **`git-stack-runner` subagent** (`agents/git-stack-runner.md`, model `sonnet`): runs the mechanical `commit`/`push` pre-flight sequence headlessly and executes the git writes when clean, returning a one-line verdict. Keeps noisy `git status`/`diff`/scan output and write ops off the main orchestrator's context, on a cheaper model. Owns read-only checks + clean-path writes only — every blocker decision (the `AskUserQuestion` modal) stays with the orchestrator, since a plugin agent can't ask the user.

### Changed
- `/commit` and `/push` now delegate to `git-stack-runner` by default (new "Delegate the mechanical work" section), falling back to the inline sequence when the agent is unavailable or the user wants to watch each check.
- Documented the new `agents/` directory and delegation model in AGENTS.md (structure tree + Agents section).

---

## [1.7.1] — 2026-07-08

### Added
- **Commit identity (noreply email) setup** in `references/core.md`: documents GitHub's `ID+username@users.noreply.github.com` format, the pre-2017 caveat, and a step-by-step setup flow (check existing email → https://github.com/settings/emails → tick "Keep my email addresses private" → paste the shown address → set + confirm). Never construct the ID-prefixed address — only GitHub shows it.
- Surfaced "commit identity (noreply email setup)" in the `git-ops` SKILL.md domain map so the skill routes email setup to `core.md`.

---

## [1.7.0] — 2026-07-08

### Breaking
- **Renamed skill** from `git-guard` to `git-ops` across all references, scripts, folder names, and command execution contexts.

### Added
- **Repository hygiene skill**: Added `skills/git-ops/references/cleanup.md` to support repo-wide cleanup, dead branch pruning, and large-blob purges.

### Changed
- **Token Efficiency Optimization**: Optimized all slash commands (`commit`, `push`, `wrap-up`, `update-docs`) and references (`core.md`) to drastically reduce token bloat. Streamlined duplicated rules, operating principles, blocker lists, and instructions. Kept 100% of the functional logic and commands while reducing overall instruction context sizes by **~63%** (from 53.4 KB to 19.9 KB).
- Updated documentation and helper scripts to reflect the `git-ops` renaming.

---

## [1.6.0] — 2026-05-29

### Changed
- **All slash commands reworked around one model: invocation = consent.** They run end-to-end when the change is simple and the session is clean, and stop only when something is truly off. Clarifications now use the `AskUserQuestion` interactive modal instead of inline `(yes / edit / abort)` text prompts. Instructions are phrased in positive form.
- **Reports are now left-border ASCII boxes** (`┌─` / `│` / `└─`, no right border) so they never misalign, with clearly labelled sections.
- **Blocker model unified** across `/commit`, `/push`, `/wrap-up`, `/release`: stop on personal/secret files, stale/outdated folders staged, errors, missing files, non-`main` branch, diverged remote, version/manifest mismatch, or genuine ambiguity. A simple, verified, non-breaking change on `main` runs without questions.
- `/commit` → v2.1.0: added the "simplicity test"; committing to `main` for a simple change is normal (reported as a plain branch field). DONE box now shows a `[CLEAN]`/`[INFO]` pre-flight checklist.
- `/push` → v2.2.0: same model; diverged remote / no remote are HIGH blockers; DONE box includes the pre-flight checklist.
- `/wrap-up` → v2.1.0: reframed as **close-the-session** (commit + push always) with **tagging as an opt-in release decision** — asked via modal when no version is given, run automatically when a version is. Restructured as a pipeline (`/commit` + `/push`, then `/update-docs` + bump + tag on release). Final report is a full recap: VERSION (+ reason), NEW / EDITED files, COMPONENTS + MANIFESTS bumps, CHANGELOG, COMMIT / TAG / PUSH, PRE-FLIGHT checklist, NOTES.
- `/update-docs` → v1.2.0: supports `[Unreleased]` (default) and versioned `[X.Y.Z]` entries with promotion on release; new internal-vs-external **scope clarification** (internal = CLAUDE/AGENTS/GEMINI/specs; external = README/public docs) asked via modal.
- `/changelog` → v1.1.0: `[Unreleased]`-aware with promotion; positive-consent flow; left-border box.
- `/release` → v1.3.0: modal gates replace inline prompts; promotes `[Unreleased]` → `[X.Y.Z]`; manifest drift auto-fixes before blocking; full recap box with COMPONENTS/MANIFESTS/PRE-FLIGHT sections.

---

## [1.5.1] — 2026-05-16

### Fixed
- `.agents/plugins/marketplace.json` — plugin `source` changed from `local`/`./` to `url` pointing at the GitHub remote. The local source was not resolvable from Codex's remote marketplace, which blocked plugin installation.

### Changed
- `.codex-plugin/plugin.json` — Codex category from `Coding` to `Productivity`, consistent with the other plugins.
- `README.md` — corrected Codex install flow: `codex plugin marketplace add` + `codex /plugins` instead of the nonexistent `codex plugin install`; added a note that in Codex the primary surface is the skills `/git-stack:git-guard` and `/git-stack:repo-prettifier`.

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
