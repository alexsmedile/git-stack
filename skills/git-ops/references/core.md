# git-stack / core — Git Reference & Guardrails

This reference defines custom Git rules, conventions, regexes, and security checks for the `git-ops` skill.

---

## git-stack.core.commit
Logical units only. One commit = one clear story.
- **Subject**: ≤72 chars, imperative mood ("fix" not "fixed"), lowercase type.
- **Format**: `type(scope): description`
- **Types**: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `ci`
- **Guardrails**: No secrets, `.env`, `node_modules/`, build output, or staged files >500KB.

### Commit identity (email)
Prefer GitHub's **noreply** address over a real email — keeps the personal address out of public history while still linking commits to the profile.
- **Format**: `ID+username@users.noreply.github.com` (accounts created after 2017-07-18). Plain `username@users.noreply.github.com` only links for pre-2017 accounts that enabled email privacy back then — do not assume it.

**First check** — if `git config user.email` already returns a `@users.noreply.github.com` address, it's set; use it as-is and skip setup. Only run the setup flow when the configured email is a real/personal address or unset.

**Setup flow (walk the user through this):**
1. Ask the user to open **https://github.com/settings/emails**.
2. Have them tick **"Keep my email addresses private"**. GitHub then shows their noreply address (`ID+username@users.noreply.github.com`) right under that checkbox.
3. Ask them to paste that exact address back.
4. Set it: `git config --global user.email "<pasted-address>"` (per-repo: drop `--global`). If a repo has a local override with a real email, `git config --unset user.email` so it inherits global.
5. Confirm: `git config user.email`.

Never guess or construct the address — the ID is account-specific and only GitHub shows it.

### Secrets / API key scan
Run BEFORE every commit on ADDED lines only:
```bash
git diff --cached | grep '^+' | grep -v '^+++' | grep -nE '(sk-proj-[A-Za-z0-9_-]{40,}|sk-ant-[a-z0-9-]+-[A-Za-z0-9_-]{40,}|sk-[A-Za-z0-9]{40,}|jina_[A-Za-z0-9]{40,}|tvly-(dev-|prod-)?[A-Za-z0-9_-]{20,}|apify_api_[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{30,}|xoxb-[A-Za-z0-9-]{20,}|hf_[A-Za-z0-9]{30,}|-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----)'
```
If matched: STOP. Block commit unless overridden or clean filter is set up (see `decisions.md`).

### Installing the secret-block hook
To protect a repo, run the installer to preview command:
```bash
bash "${CLAUDE_SKILL_DIR}/scripts/install-hooks.sh" /path/to/repo
```
Options are copy (frozen script) or symlink (dynamic updates).

### Repo-wide secret audit (on request)
Scan currently tracked files, env/config files, and git history:
```bash
SECRET_RE='(sk-proj-[A-Za-z0-9_-]{40,}|sk-ant-[a-z0-9-]+-[A-Za-z0-9_-]{40,}|sk-[A-Za-z0-9]{40,}|jina_[A-Za-z0-9]{40,}|tvly-(dev-|prod-)?[A-Za-z0-9_-]{20,}|apify_api_[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|gho_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[0-9A-Z]{16}|AIza[A-Za-z0-9_-]{30,}|xoxb-[A-Za-z0-9-]{20,}|hf_[A-Za-z0-9]{30,}|-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----)'

# 1. Currently tracked files
git ls-files -z | xargs -0 grep -nHE "$SECRET_RE" 2>/dev/null

# 2. Config/env files (tracked or ignored)
find . -type f \( -name '.env*' -o -name '*.env' -o -name 'config.toml' -o -name 'settings.json' -o -name 'secrets.*' -o -name '*.pem' -o -name '*.key' \) -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null | xargs grep -nHE "$SECRET_RE" 2>/dev/null

# 3. Full git history
git log --all -p -- . | grep -nE "$SECRET_RE"
```
- **Live + Untracked Match**: HIGH severity. Rotate key, gitignore file.
- **History Match**: CRITICAL. Rotate key, scrub using `git filter-repo`, force-push.

---

## git-stack.core.branch
- **Convention**: Never work on `main`/`master`. Create features/fixes on dedicated branches.
- **Naming**: `feat/` `fix/` `refactor/` `docs/` `chore/` (e.g., `feat/login-flow`).

---

## git-stack.core.merge & rebase
- **Merge**: Use PRs on GitHub (preferred). Use `--no-ff` on `main` to preserve history if merging locally.
- **Rebase**: Rebase local feature branch onto `main` frequently. Never rebase shared branches.
- **Force Push**: Prefer `--force-with-lease` over `--force`. Never force push to shared branches.

---

## git-stack.core.stash
- Stash is a temporary holding area. Do not let stashes sit for days.
- Always name stashes (`git stash push -m "description"`).

---

## git-stack.core.worktree
- Use separate directories to work on multiple branches in parallel.
- Clean up when done (`git worktree remove`).

---

## History rewriting (Squash to clean root)
Safe squash to a single root commit via orphan branch:
```bash
git checkout --orphan clean-main
git commit -m "feat: initial release — v1.0.0"
git branch -M clean-main main
git push --force-with-lease origin main
```
