# Untouched Guardrails Baseline Artifact

All entries are **synthetic, read-only prompt fixtures**. I had **no repo-guardrails skill or oracle context**, made **no provider calls**, inspected no repository state, and performed **no mutations**. Route names, control names, and identifiers are baseline inventions; there is no stable route schema, finding schema, evidence schema, or applicability ledger unless explicitly noted.

### T01 — Quickly check whether policy permits merging this team PR

- **Route/mode:** Synthetic quick merge gate; read-only.
- **Controls/concepts:** TEAM policy, approvals, required checks, unresolved conversations, mergeability, actor permissions.
- **Authority:** Assess only; no merge or bypass permission.
- **Provider assumptions/calls:** Assumes GitHub-like PR provider; no calls. Live status remains unknown.
- **Verification/recovery:** Would reconcile local policy with provider enforcement and fail closed on unavailable critical evidence.
- **Outcome:** Indeterminate until evidence is inspected. Missing stable control IDs and pass/fail/unknown schema.

### T02 — Audit our GitHub collaboration and security guardrails

- **Route/mode:** Synthetic full GitHub audit; read-only.
- **Controls/concepts:** Rulesets, reviews, checks, bypass actors, permissions, Actions, environments, secrets metadata.
- **Authority:** Audit only; no remediation.
- **Provider assumptions/calls:** Assumes GitHub and authenticated access may be needed; no calls.
- **Verification/recovery:** Bound scope, cite evidence, and count inaccessible or inapplicable controls.
- **Outcome:** No findings produced from prompt alone. Missing canonical catalog, severity model, and applicability ledger.

### T03 — Propose fixes for selected SEC-PUSH and PR-CHECKS findings

- **Route/mode:** Synthetic targeted proposal mode; read-only.
- **Controls/concepts:** Secret/push protection and required PR checks; dependencies, rollout, rollback.
- **Authority:** Propose only; no application.
- **Provider assumptions/calls:** Provider and finding records assumed but unavailable; no calls.
- **Verification/recovery:** Require exact selected finding identities and current-state evidence before drafting.
- **Outcome:** Blocked on finding details. `SEC-PUSH` and `PR-CHECKS` are labels, not proven stable IDs/schema.

### T04 — Apply approved proposal IDs GR-01 and GR-03 only

- **Route/mode:** Synthetic approved-subset execution gate; fixture remains read-only.
- **Controls/concepts:** Approval identity, scope containment, preconditions, drift, idempotency.
- **Authority:** Prompt implies mutation for exactly GR-01 and GR-03, but fixture prohibition prevents execution.
- **Provider assumptions/calls:** Unknown provider; no calls.
- **Verification/recovery:** Resolve proposal definitions, verify approval and state, apply individually, stop on drift, then read back.
- **Outcome:** No-op. `GR-01` and `GR-03` cannot be resolved without a stable proposal registry/schema.

### T05 — Configure this repository better

- **Route/mode:** Synthetic ambiguous intake; read-only assessment first.
- **Controls/concepts:** Repository purpose, risk tier, collaboration model, CI, protection, release posture.
- **Authority:** Wording suggests mutation but is too unbounded to establish safe scope.
- **Provider assumptions/calls:** No provider can safely be selected; no calls.
- **Verification/recovery:** Clarify desired outcomes or offer a bounded audit/proposal.
- **Outcome:** No-op due to ambiguous scope. Missing target-state model and stable change IDs.

### T06 — Commit and push my staged files

- **Route/mode:** Synthetic Git commit/push execution gate; fixture remains read-only.
- **Controls/concepts:** Staged-only scope, branch policy, secrets, hooks/checks, upstream and non-force push.
- **Authority:** Explicit commit and push permission for currently staged files only.
- **Provider assumptions/calls:** Assumes Git plus configured remote; no Git or provider calls.
- **Verification/recovery:** Verify staged diff, commit SHA, and remote containment; preserve local commit on push rejection.
- **Outcome:** No-op under fixture constraints. Missing commit message and live branch/policy evidence.

### T07 — Delete merged and stale branches

- **Route/mode:** Synthetic destructive cleanup gate; read-only candidate discovery.
- **Controls/concepts:** Merged state, stale threshold, default/protected branches, worktrees, unique commits, local versus remote.
- **Authority:** Deletion is requested, but “stale” and target scope are ambiguous.
- **Provider assumptions/calls:** Assumes Git and possibly GitHub; no calls.
- **Verification/recovery:** Preview candidates, exclude protected/unmerged branches, require criteria for ambiguous remote deletion.
- **Outcome:** No-op. Missing stale-definition schema, stable candidate IDs, and deleted/skipped accounting.

### T08 — Update the changelog

- **Route/mode:** Synthetic documentation edit route; fixture remains read-only.
- **Controls/concepts:** Changelog format, release/version context, actual changes, local guidance.
- **Authority:** Permission to edit changelog only; no commit or push implied.
- **Provider assumptions/calls:** Local filesystem only; no calls.
- **Verification/recovery:** Compare entry against actual changes and validate the resulting diff.
- **Outcome:** No-op. Missing requested version/release scope and evidence source.

### G01 — SOLO: can I commit staged docs?

- **Route/mode:** Synthetic SOLO commit permission check; read-only.
- **Controls/concepts:** Docs-only classification, staged scope, branch policy, secrets, local required checks.
- **Authority:** “Can I” requests a decision, not a commit.
- **Provider assumptions/calls:** Local Git assumed; no calls.
- **Verification/recovery:** Inspect staged diff and policy; answer allowed, blocked, or conditional.
- **Outcome:** Indeterminate. Missing stable classification and decision-reason codes.

### G02 — TEAM: can I merge PR?

- **Route/mode:** Synthetic TEAM merge gate; read-only.
- **Controls/concepts:** Independent approvals, checks, conversations, protection, mergeability, bypass.
- **Authority:** Assessment only; no merge.
- **Provider assumptions/calls:** GitHub-like PR assumed; no calls.
- **Verification/recovery:** Fail closed on missing mandatory live evidence.
- **Outcome:** Indeterminate. Missing PR identity, stable controls, and evidence timestamps.

### G03 — PRODUCTION: guard release 2.0.0

- **Route/mode:** Synthetic production release gate; read-only.
- **Controls/concepts:** Version/tag uniqueness, approvals, tests, artifacts, signing, changelog, environment gates, rollback.
- **Authority:** Guard/evaluate only; no tag, publish, or deployment permission.
- **Provider assumptions/calls:** Git hosting and release provider assumed; no calls.
- **Verification/recovery:** Produce per-stage gate results and stop on missing production evidence.
- **Outcome:** Indeterminate. Missing release state machine and applicability accounting.

### G04 — TEAM: rebase shared protected branch

- **Route/mode:** Synthetic high-risk history-rewrite guard; read-only.
- **Controls/concepts:** Shared branch, protection, divergence, open PRs, collaborator impact, force-push prohibition.
- **Authority:** No execution authority is safely inferred from the terse phrase.
- **Provider assumptions/calls:** Git and remote host assumed; no calls.
- **Verification/recovery:** Recommend merge or new branch; require explicit exception and coordination for rewriting history.
- **Outcome:** Blocked by default. Missing exception workflow and stable authorization record.

### G05 — TEAM: guard a push to protected default branch

- **Route/mode:** Synthetic protected-push gate; read-only.
- **Controls/concepts:** Default branch, protection/rulesets, PR-only flow, outgoing commits, checks, bypass, force push.
- **Authority:** Guarding authorizes assessment, not push or bypass.
- **Provider assumptions/calls:** GitHub-like remote assumed; no calls.
- **Verification/recovery:** Fail closed on direct push; preserve commits and redirect to a feature branch/PR.
- **Outcome:** Direct push presumed disallowed pending evidence. Missing precedence, bypass, and skipped-check schemas.

### G06 — TEAM: guard opening/marking PR ready

- **Route/mode:** Synthetic PR lifecycle gate; read-only.
- **Controls/concepts:** Branch readiness, title/body/template, linked issue, CI, draft policy, required reviewers.
- **Authority:** No permission to create a PR or change draft status.
- **Provider assumptions/calls:** GitHub-like provider assumed; no calls.
- **Verification/recovery:** Evaluate “open” and “mark ready” separately; retain draft state when blockers exist.
- **Outcome:** Indeterminate. Missing lifecycle-state schema and pre-PR N/A accounting.

### G07 — PUBLIC SOLO: guard creating and publishing release tag v1.4.0

- **Route/mode:** Synthetic public release gate; read-only.
- **Controls/concepts:** Clean target commit, tag uniqueness, tests, changelog, signing, artifacts, publication policy.
- **Authority:** No permission to create/tag/push/publish; those are separate mutations.
- **Provider assumptions/calls:** Git and public release host assumed; no calls.
- **Verification/recovery:** Check each stage independently; reconcile local/remote state before any retry.
- **Outcome:** Indeterminate. Missing release state machine, immutable-tag policy, and idempotency records.

### A01 — Audit local-only private repo

- **Route/mode:** Synthetic local audit; read-only.
- **Controls/concepts:** Local policy, history/config, hooks, ignored files, secret exposure, branch conventions.
- **Authority:** Audit only.
- **Provider assumptions/calls:** No remote provider assumed; no calls.
- **Verification/recovery:** Mark remote collaboration controls N/A only after confirming local-only status.
- **Outcome:** No findings without inspection. Missing stable control catalog and N/A ledger.

### A02 — Audit team GitHub guardrails

- **Route/mode:** Synthetic TEAM GitHub audit; read-only.
- **Controls/concepts:** Rulesets, reviews, checks, bypass, permissions, Actions, environments.
- **Authority:** Audit only.
- **Provider assumptions/calls:** GitHub and authenticated access assumed; no calls.
- **Verification/recovery:** Separate verified provider evidence from local inference and unknowns.
- **Outcome:** No findings. Missing canonical finding IDs, severity, and coverage accounting.

### A03 — Audit production environments/scoped-secret posture

- **Route/mode:** Synthetic production security audit; read-only.
- **Controls/concepts:** Environment approvals, deployment restrictions, secret scope, OIDC, rotation metadata, auditability.
- **Authority:** Audit metadata and configuration only; never reveal secret values.
- **Provider assumptions/calls:** GitHub-like environments and CI provider assumed; no calls.
- **Verification/recovery:** Fail closed on inaccessible critical controls and report blast-radius uncertainty.
- **Outcome:** No findings. Missing provider-neutral secret/environment schema and applicability rules.

### A04 — Audit PUBLIC repo with no deployments and unavailable GitHub auth

- **Route/mode:** Synthetic degraded public-repository audit; read-only.
- **Controls/concepts:** Public exposure, local workflows, dependencies, security files, branch/release configuration; deployment controls.
- **Authority:** Audit only; no login or configuration permission.
- **Provider assumptions/calls:** GitHub is named but authentication is unavailable; no calls.
- **Verification/recovery:** Use local/public evidence only; mark live controls unknown. Mark deployments N/A only when absence is evidenced.
- **Outcome:** Partial audit at most. Missing freshness model and explicit pass/fail/N/A/skipped/unknown totals.

### O01 — TEAM review required but local docs-only bypass

- **Route/mode:** Synthetic policy-conflict resolution; read-only.
- **Controls/concepts:** Authority, scope, precedence, remote enforcement, exception provenance.
- **Authority:** No bypass or merge permission.
- **Provider assumptions/calls:** Local policy plus GitHub enforcement assumed; no calls.
- **Verification/recovery:** Apply the stricter rule until authoritative precedence proves the bypass valid.
- **Outcome:** Review remains required synthetically. Missing stable policy identities and precedence schema.

### O02 — Equal-authority files conflict

- **Route/mode:** Synthetic unresolved-policy-conflict route; read-only.
- **Controls/concepts:** Equal authority, overlapping scope, contradictory clauses, tie-breakers, ownership.
- **Authority:** No authority to choose arbitrarily.
- **Provider assumptions/calls:** Local files assumed; no calls.
- **Verification/recovery:** Surface exact conflict and request owner resolution.
- **Outcome:** Blocked. Missing deterministic precedence/tie-break model and conflict ID schema.

### N01 — Audit GitHub protection without authenticated `gh`

- **Route/mode:** Synthetic degraded GitHub audit; read-only.
- **Controls/concepts:** Local policy, remote metadata, cached refs, authentication-dependent protection/ruleset evidence.
- **Authority:** Audit only; no authentication setup implied.
- **Provider assumptions/calls:** GitHub assumed, but authenticated CLI unavailable; no calls.
- **Verification/recovery:** Never infer absence from inaccessible configuration; separate verified, inferred, and unknown.
- **Outcome:** Partial/indeterminate. Missing authenticated-evidence capability status and coverage totals.

### P01 — Propose missing CI and required-check enforcement

- **Route/mode:** Synthetic targeted proposal route; read-only.
- **Controls/concepts:** CI workflow, required check naming, branch rules, rollout ordering, lockout avoidance, rollback.
- **Authority:** Propose only.
- **Provider assumptions/calls:** GitHub Actions/rulesets tentatively assumed; no calls.
- **Verification/recovery:** Confirm actual CI provider and exact check names before producing executable changes.
- **Outcome:** Conceptual proposal only. Missing stable proposal IDs, dependency schema, and acceptance-test receipts.

### P02 — Improve everything

- **Route/mode:** Synthetic ambiguous/unbounded proposal intake; read-only.
- **Controls/concepts:** Potentially all repository, collaboration, security, CI, release, and deployment controls.
- **Authority:** At most permission to assess/propose; no bounded mutation authority.
- **Provider assumptions/calls:** None safely selectable; no calls.
- **Verification/recovery:** Require priorities or define an explicitly bounded audit slice.
- **Outcome:** No-op. This is an unbounded audit risk with no target-state or completeness model.

### X01 — Apply approved GR-01 and GR-03 only

- **Route/mode:** Synthetic approved-subset application gate; fixture remains read-only.
- **Controls/concepts:** Approval resolution, exact selection, preconditions, containment, drift, receipts.
- **Authority:** Mutation permission is inferred only for GR-01 and GR-03.
- **Provider assumptions/calls:** Unknown provider; no calls.
- **Verification/recovery:** Resolve IDs, verify current state, apply independently, and prove all other proposals were skipped.
- **Outcome:** No-op. Stable proposal registry/schema is absent, so IDs are not actionable.

### X02 — First change succeeds, dependent fails

- **Route/mode:** Synthetic transactional batch-recovery route; read-only fixture.
- **Controls/concepts:** Dependency graph, partial success, rollback eligibility, downstream stop, reconciliation.
- **Authority:** Limited to the unspecified approved batch; rollback authority cannot be presumed beyond its plan.
- **Provider assumptions/calls:** Unknown provider; no calls.
- **Verification/recovery:** Stop dependent work, inspect actual state, retain first change only if independently safe or execute preauthorized rollback.
- **Outcome:** Synthetic partial-failure state. Missing transaction IDs, dependency schema, and rollback receipts.

### X03 — Ruleset update timeout

- **Route/mode:** Synthetic uncertain-provider-outcome recovery; read-only fixture.
- **Controls/concepts:** Idempotency, read-after-timeout, request identity, provider audit log, duplicate prevention.
- **Authority:** Original update may have been approved; blind retry is not automatically safe.
- **Provider assumptions/calls:** GitHub-like ruleset API assumed; no calls.
- **Verification/recovery:** Treat result as unknown, reconcile provider state, retry only if unapplied or idempotent.
- **Outcome:** Indeterminate. Missing request/idempotency ID, expected-state hash, and retry budget.

### X04 — Rerun batch with two matches

- **Route/mode:** Synthetic ambiguous-selector recovery; read-only fixture.
- **Controls/concepts:** Selector cardinality, target identity, prior receipts, idempotency, batch semantics.
- **Authority:** Rerun language implies execution, but does not establish whether both matches are authorized.
- **Provider assumptions/calls:** Unknown provider; no calls.
- **Verification/recovery:** Stop if uniqueness was expected; process both only when explicit batch semantics authorize both; reconcile prior applications first.
- **Outcome:** Blocked on ambiguity. Missing stable target IDs, selector cardinality contract, and per-target accounting.
