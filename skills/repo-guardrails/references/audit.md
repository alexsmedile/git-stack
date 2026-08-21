# Audit and proposal

Use this when: the user requests repository posture/readiness or wants findings
converted into a concrete improvement plan.

## Audit

Inspect applicable categories exhaustively:

Start from [controls.md](controls.md); the categories explain evidence gathering
but do not add unnamed controls.

1. Local repository authority: instructions, ignore/attributes, hooks policy,
   ownership files, release/deployment configuration, required local gates.
2. Branch/integration: default branch, protection/rulesets, direct writes,
   force-push/deletion, merge strategies, required reviews/checks/conversations.
3. Security: secret scanning, push protection, dependency updates, code scanning,
   token/permission posture without reading secret values.
4. Delivery: environments, reviewers, scoped secret names, deployment branches,
   preview/staging/production separation, provenance/signing where applicable.
5. Collaboration: contributor count/signals, CODEOWNERS or equivalent, issue/PR
   templates, decision/ownership memory when repository policy requires it.

Use direct `git` for local facts and `gh api`/`gh` for GitHub facts. Prefer stable
provider fields; retain endpoint/command attribution for UNKNOWN and verification.

Completion: every profile-applicable control has a finding, NOT_APPLICABLE has
a reason, UNKNOWN names the unavailable observation, every catalog ID is
accounted for exactly once, and no score hides severity.

## Propose

Convert only selected findings. If no prior finding IDs are supplied, run the
smallest audit needed to recover candidates, present them, and obtain selection
before drafting changes. Each proposal item contains:

```text
ID=<stable id>
CONTROL=<control id>
CURRENT=<observed state>
CHANGE=<exact local/provider mutation>
TRADEOFF=<workflow/cost/availability consequence>
DEPENDENCIES=<required existing checks, teams, environments, credentials>
REVERSAL=<exact rollback or why hard to reverse>
AUTHORITY=<who must approve/perform>
VERIFY=<postcondition query>
```

Order prerequisites before dependent enforcement: a required status check must
exist and pass before a ruleset requires it; an environment must exist before
secrets or reviewers are scoped to it. Completion: every item is independently
selectable, dependency-ordered, reversible where possible, and executable by
`apply` or explicitly owner-performed.
