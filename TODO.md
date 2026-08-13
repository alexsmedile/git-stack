# TODO

## Backlog

- [x] Send git issue to current repo or specified repo ~backlog → octopus:send-git-issue-current-repo-specified-repo
  ```yaml
  kind: feat
  ```

- [x] Maintain version index/manifest/aggregator ~backlog → octopus:maintain-version-index-manifest-aggregator
  > Script that checks version across repos — index/aggregator for version tracking.
  ```yaml
  kind: feat
  ```

- [ ] `/undo` — guided recovery command ~backlog
  > Panic button for "I messed up". Read `git reflog`, classify what went wrong
  > (bad commit / bad merge / wrong reset --hard / lost branch), then present the
  > *safe* recovery path for that specific case. Fills the bundle's biggest safety
  > gap — recovery is the highest-stress, highest-mistake moment and nothing here
  > covers it. `core.md` has the undo *commands*; this is the guided "what happened
  > → what to do" front door over them. Mostly composition, little new logic.
  ```yaml
  kind: feat
  ```

- [ ] `/security-audit` — pre-public safety pass ~backlog
  > One guided front door over security capability that already exists but is
  > scattered: 3-pass repo-wide secret scan (working tree + full history, in
  > core.md), tracked `.env`/credential files, hardcoded `/Users/<name>/` paths &
  > internal URLs, big/binary blobs (reuse cleanup.md Tier 3a scan), `.gitignore`
  > completeness, pre-commit hook installed? → single "safe to make public?"
  > verdict. Delegate checks to a new `references/security.md`; the command is the
  > orchestrator. Pairs with repo-prettifier (audit right before going public).
  ```yaml
  kind: feat
  ```

- [ ] Apple Sparkle appcast integration ~backlog
  > Teach `check-manifests.sh` / `bump-manifests.sh` to understand Sparkle's
  > update feed so macOS-app repos stay aligned. Sparkle version lives in two
  > places that must match the release: the app's `Info.plist`
  > (`CFBundleShortVersionString` = marketing version, `CFBundleVersion` = build)
  > and the **appcast XML** (`appcast.xml`) — each `<item>` carries
  > `sparkle:version` / `sparkle:shortVersionString` (attributes on `<enclosure>`
  > or elements in the item). On release, bump the plist versions AND add/point the
  > newest appcast item at the new build. Detect by presence of `appcast.xml`
  > and/or an `Info.plist` with `SUFeedURL`. Read plist via `/usr/libexec/PlistBuddy
  > -c "Print :CFBundleShortVersionString"` (or `plutil -extract`), appcast via
  > `xmllint --xpath`. Report drift when plist, appcast top item, and CHANGELOG/tag
  > disagree.
  ```yaml
  kind: feat
  ```

- [ ] Broaden version-bearing file awareness ~backlog
  > `check`/`bump-manifests.sh` already cover: package.json, pyproject.toml,
  > setup.cfg, Cargo.toml, composer.json, *.gemspec, pom.xml, build.gradle,
  > VERSION, .claude-plugin/{plugin,marketplace}.json, .codex-plugin/plugin.json,
  > CHANGELOG top entry, README shields.io badge. Gaps worth adding, by frequency:
  > - **App/desktop**: Apple `Info.plist` + Sparkle `appcast.xml` (see item above);
  >   Electron/Tauri (`tauri.conf.json` → `package.version`, `src-tauri/Cargo.toml`);
  >   Android `build.gradle` `versionName`/`versionCode`; Flutter `pubspec.yaml`.
  > - **JS ecosystem**: `package-lock.json` / `pnpm-lock.yaml` top `version`,
  >   `jsr.json`, `deno.json`, browser-extension/web `manifest.json` (same filename,
  >   different schema than plugins — disambiguate before writing).
  > - **Containers/infra**: Helm `Chart.yaml` (`version` + `appVersion`),
  >   Dockerfile `LABEL version` / `ARG VERSION`, `.github/workflows/*` pinned
  >   release versions, the git tag itself.
  > - **Other langs**: Go (no canonical file — usually the tag; sometimes a
  >   `version.go` const), .NET `*.csproj` `<Version>`, Swift `Package.swift`
  >   (SPM uses tags, no version field).
  > - **Marketplace/badges beyond Claude/Codex**: VS Code `package.json`
  >   `publisher`+`version`, JetBrains `plugin.xml` `<version>`, Obsidian
  >   `manifest.json` + `versions.json`, Raycast `package.json`; README badges that
  >   embed a version (npm, PyPI, crates.io, Docker tag) — auto-updating ones are
  >   fine, static ones drift.
  > Add incrementally, each behind marker-file detection like the existing ones.
  > Obsidian `versions.json` and Helm `appVersion` are the highest-value quick wins
  > for this vault's own repos.
  ```yaml
  kind: feat
  ```

- [ ] Optional pre-commit hook for version drift ~backlog
  > `check-manifests.sh` catches version drift, but only when someone remembers to
  > run it. During the 1.12.0 release the CHANGELOG was still on 1.11.1 and only
  > surfaced mid-release. A pre-commit hook would make the check automatic.
  >
  > Not urgent — nothing is broken. `validate-distribution.mjs --native` already
  > blocks tagging on drift, and manifest alignment only truly matters at release
  > time.
  >
  > If done, extend the existing `install-hooks.sh` to optionally chain
  > `check-manifests.sh` — do **not** adopt skizl's `git-guard`, which was
  > evaluated and rejected for three reasons:
  > - it looks for `CHANGELOG.md` at the repo root; ours is `docs/CHANGELOG.md`,
  >   so that source would be silently skipped
  > - it has no project-level vs component-level distinction, so its `skill_check`
  >   is all-or-nothing; our four skills are deliberately versioned independently
  >   (1.9.0 / 1.0.0 / 2.0.0 / 1.1.0) and "all" would block every commit until they
  >   were flattened
  > - it sets `core.hooksPath`, which redirects hook lookup away from `.git/hooks/`
  >   and could orphan a secrets hook installed via `install-hooks.sh`
  >
  > Keep it preview-only per git-ops safety rule #15 — never install a hook
  > automatically.
  ```yaml
  kind: feat
  ```
