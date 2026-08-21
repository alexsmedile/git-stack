# TODO

## Backlog

- [] git-stack to git-operator?

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
  >
  > **Two audiences, one command.** The checks above answer "safe to publish?"
  > for a solo repo. Sharing this bundle with a team raises a different set of
  > questions that the same audit should cover, gated by whether the repo has
  > other contributors:
  > - **Repo posture** (`gh api`): is branch protection on for the default
  >   branch, are reviews required, is force-push blocked, is GitHub secret
  >   scanning + push protection enabled? These are the controls that make the
  >   local hook redundant — worth reporting as "already covered upstream".
  > - **Contributor hygiene**: are commits signed / is signing required; do any
  >   contributors leak a real email instead of the `@users.noreply` alias
  >   (`check-author-email.sh` already does this for the current user — widen to
  >   a range across authors); any commits from unexpected accounts.
  > - **Shared-skill trust**: when the bundle itself is distributed to a team,
  >   the hook and script run on *their* machines. Document what executes, what
  >   it sends anywhere (nothing today), and which overrides (`--allow-main`,
  >   `--allow-large`, `--no-verify`) silently weaken the gate. A team install
  >   should be able to answer "what did this just run on my repo".
  > - **Depth for public repos**: history scanning is the weak spot — the
  >   commit-time scan only sees the staged diff. Prefer `gitleaks detect` over
  >   the built-in patterns for the full-history pass (added in 1.13.0), and
  >   note `trufflehog --results=verified` when confirming a key is still live
  >   matters more than speed.
  >
  > Keep the solo path fast: run the team checks only when the repo has multiple
  > contributors or an explicit `--team` flag, and never make `gh` a hard
  > dependency — degrade to the local-only checks when it is absent or
  > unauthenticated.
  ```yaml
  kind: feat
  ```

- [ ] Collaboration surface — branches, issues, GH Projects ~backlog
  > The bundle covers the solo path end to end (commit → push → tag → release)
  > but drops off wherever work is *tracked* rather than *written*. Branch
  > mechanics exist in `core.md` and `workflows.md`; issues and project boards
  > have no coverage at all beyond `github.md`'s PR/issue basics.
  >
  > Scope to decide before building — likely a `references/collaboration.md`
  > under git-ops plus script subcommands, not a new skill, unless it outgrows
  > that:
  > - **Branches as workstreams**: pick up an existing branch and re-orient
  >   ("what was I doing here"), switch between parallel workstreams safely,
  >   keep a long-lived branch current without rebasing shared history.
  >   Distinct from `core.md`'s atomic branch ops, which answer "how do I
  >   branch", not "how do I work across several".
  > - **Issues**: open from the current diff, link a branch/PR to an issue,
  >   close via commit trailer, triage and label. `gh issue` is the substrate.
  > - **GH Projects (v2)**: read board state, move items across columns, tie a
  >   branch or PR to a project item. Note `gh project` needs the `project`
  >   scope — most users' `gh auth` will not have it, so the first run must
  >   detect and explain that rather than failing opaquely.
  >
  > Follow the established split: mechanical scans (which issues are open, what
  > column is this in) go in `git-stack.sh` as read-only subcommands returning
  > compact `KEY=value`; judgment stays in prose. Check whether `gh project`
  > output is stable enough to parse before committing to a script path.
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
