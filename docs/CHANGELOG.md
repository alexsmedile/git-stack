# Changelog

All notable changes are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

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
