# Oracle-withheld skilled run

Evaluator: `/root/guardrails_skilled_eval`. Independent synthetic, read-only
evaluation of the current package. I did not implement the skill, read
`oracle.md`, call a provider, or mutate Git/provider state. The suite contains
eight trigger cases and twenty behavior cases (28 total).

## Notation

`C=controls.md`, `P=profiles.md`, `G=guard.md`, `A=audit.md`, `X=apply.md`.
`RG=repo-guardrails`, `GO=git-ops`, `HP=human/provider`. Finding tuples are:

```text
CONTROL | STATE | EVIDENCE | DESIRED | OWNER | AUTHORITY | VERIFY
```

All fixture evidence is prefixed `SYNTHETIC`.

## Trigger cases

| ID | Mode/profile | Exact IDs/context | Finding/authority behavior | Recovery/done evidence | Result |
|---|---|---|---|---|---|
| T01 | guard/TEAM | C,P,G; `PR-REVIEWS,PR-CHECKS,PR-CONVERSATION,PR-MERGE`; conditional `ENV-REVIEW` | G02-shaped read-only findings | Exact merge handoff and proceed disposition | PASS |
| T02 | audit/TEAM | C,P,A; all 19 | A02 matrix; read-only | 19 unique, reasoned N/A/UNKNOWN, no score | PASS |
| T03 | propose/inherited | C,P,A; `SEC-PUSH,PR-CHECKS`+deps | Stable items; approval required | Passing check before enforcement | PASS |
| T04 | apply/inherited | C,P,X; `GR-01,GR-03`+deps | Already requested for exact IDs | Fresh reads and per-ID postconditions | PASS |
| T05 | clarify/none | description; none | Generic config gives no finding/apply authority | Ask audit vs named workstream | PASS |
| T06 | `git-ops`/none | description; none | Commit/push execution excluded | Exact owner handoff | PASS |
| T07 | repo hygiene/none | description; none | Cleanup excluded | Exact owner handoff | PASS |
| T08 | docs update/none | description; none | Documentation excluded | Exact owner handoff | PASS |

## Guard cases

### G01 — SOLO commit

Mode/profile: guard/SOLO. Context: C,P,G. Exact IDs:
`BR-DIRECT,LOCAL-HOOKS,LOCAL-SIGN`.

```text
BR-DIRECT | NOT_APPLICABLE | SYNTHETIC: HEAD=docs-fix, default=main | discourage default direct writes | RG | read-only | re-read HEAD/default
LOCAL-HOOKS | NOT_APPLICABLE | SYNTHETIC: no adopted hook policy | no undeclared gate | RG | read-only | re-read instructions
LOCAL-SIGN | NOT_APPLICABLE | SYNTHETIC: no signing/supply-chain policy | SOLO optional | GO | read-only | re-read policy
```

Recovery/done: PROCEED; exact staged-docs commit handoff; no network. **PASS**.

### G02 — TEAM merge

Mode/profile: guard/TEAM. Context: C,P,G. Exact IDs:
`PR-REVIEWS,PR-CHECKS,PR-CONVERSATION,PR-MERGE`.

```text
PR-REVIEWS | ENFORCED | SYNTHETIC: required=1, approvals=1 | TEAM requires review | RG | read-only | re-query decision
PR-CHECKS | ENFORCED | SYNTHETIC: ci/test=success | TEAM requires checks | GO | read-only | re-query checks
PR-CONVERSATION | ENFORCED | SYNTHETIC: unresolved=0 | resolve before merge | RG | read-only | re-query threads
PR-MERGE | ENFORCED | SYNTHETIC: squash-only matches policy | method matches history policy | RG | read-only | re-query methods/policy
```

Recovery/done: PROCEED; exact merge handoff; material controls only. **PASS**.

### G03 — PRODUCTION release 2.0.0

Mode/profile: guard/PRODUCTION+RELEASED. Context: C,P,G. Exact IDs:
`REL-TAGS,REL-CI,ENV-SCOPE,ENV-REVIEW,ENV-SECRETS`.

```text
REL-TAGS | ENFORCED | SYNTHETIC: annotated semver tags from main | explicit production tag policy | GO | read-only | re-read policy/tag
REL-CI | REQUIRED | SYNTHETIC: build passes, provenance absent | production CI/provenance | GO | read-only | query workflow/attestation
ENV-SCOPE | ENFORCED | SYNTHETIC: production environment exists | separate stages | RG | read-only | query environments
ENV-REVIEW | ENFORCED | SYNTHETIC: two production reviewers | production approval | RG | read-only | query environment rules
ENV-SECRETS | ENFORCED | SYNTHETIC: RELEASE_TOKEN production-scoped; value unread | scope per stage | HP | read-only | query metadata only
```

Recovery/done: BLOCKED on provenance, then exact release handoff. **PASS**.

### G04 — TEAM shared protected rebase

Mode/profile: guard/TEAM. Context: C,P,G. Exact IDs: `BR-FORCE,PR-CHECKS`.

```text
BR-FORCE | ENFORCED | SYNTHETIC: force push forbidden | prohibit shared rewrite | RG | read-only | query rule
PR-CHECKS | REQUIRED | SYNTHETIC: CI depends on current shared SHA | automation remains valid | GO | read-only | query proposed-head checks
```

Recovery/done: BLOCKED; rerun after policy change; exact rebase handoff. **PASS**.

### G05 — TEAM push to protected default

Mode/profile: guard/TEAM. Context: C,P,G. Exact IDs:
`BR-DIRECT,BR-FORCE,PR-CHECKS,SEC-PUSH`.

```text
BR-DIRECT | ENFORCED | SYNTHETIC: main requires PR | TEAM restricts direct writes | RG | read-only | query ruleset
BR-FORCE | ENFORCED | SYNTHETIC: main blocks force push | TEAM prohibits force/deletion | RG | read-only | query rule
PR-CHECKS | REQUIRED | SYNTHETIC: proposed SHA has no ci/test result | TEAM requires checks | GO | read-only | query SHA checks
SEC-PUSH | ENFORCED | SYNTHETIC: push protection enabled | TEAM requires protection | RG | read-only | query setting
```

Recovery/done: BLOCKED; use topic branch/PR; exact push handoff. **PASS**.

### G06 — TEAM open and mark PR ready

Mode/profile: guard/TEAM. Context: C,P,G. Exact IDs:
`PR-REVIEWS,PR-CHECKS,PR-CONVERSATION,COL-OWNERS`.

```text
PR-REVIEWS | REQUIRED | SYNTHETIC: review count=0 | TEAM review before integration | RG | read-only | query decision
PR-CHECKS | ENFORCED | SYNTHETIC: ci/test=success | TEAM requires checks | GO | read-only | query checks
PR-CONVERSATION | REQUIRED | SYNTHETIC: supported; one unresolved thread | resolve before ready/integration per policy | RG | read-only | query threads
COL-OWNERS | ENFORCED | SYNTHETIC: paths map to @docs-team | TEAM ownership mapping | RG | read-only | re-read CODEOWNERS/paths
```

Recovery/done: BLOCK ready transition until conversation resolves; PR creation
may be separated; exact handoff and no unrelated controls. **PASS**.

### G07 — PUBLIC SOLO release v1.4.0

Mode/profile: guard/SOLO+PUBLIC+RELEASED; PUBLIC is a flag. Context: C,P,G.
Exact IDs: `REL-TAGS,REL-CI,ENV-SCOPE,ENV-REVIEW,ENV-SECRETS`.

```text
REL-TAGS | ENFORCED | SYNTHETIC: semver policy; v1.4.0 unused | explicit tag policy | GO | read-only | re-read tags/policy
REL-CI | ENFORCED | SYNTHETIC: release workflow succeeds | SOLO risk-based CI | GO | read-only | query workflow
ENV-SCOPE | NOT_APPLICABLE | SYNTHETIC: no deployments | no environment surface | RG | read-only | re-check config
ENV-REVIEW | NOT_APPLICABLE | SYNTHETIC: no sensitive deployment | no reviewer surface | RG | read-only | re-check config
ENV-SECRETS | NOT_APPLICABLE | SYNTHETIC: no deployment secrets | no secret-scope surface | HP | read-only | re-check metadata
```

Recovery/done: PROCEED; exact tag/publish handoff; no secret values. **PASS**.

## Audit cases

Each audit accounts for the exact catalog sequence:
`LOCAL-IGNORE,LOCAL-HOOKS,LOCAL-SIGN,BR-DIRECT,BR-FORCE,PR-REVIEWS,PR-CHECKS,PR-CONVERSATION,PR-MERGE,SEC-SCAN,SEC-PUSH,SEC-DEPS,SEC-CODE,ENV-SCOPE,ENV-REVIEW,ENV-SECRETS,REL-TAGS,REL-CI,COL-OWNERS`.

### A01 — local-only PRIVATE SOLO

Mode/profile: audit/SOLO+PRIVATE. Context: C,P,A; all 19.

```text
LOCAL-IGNORE | ENFORCED | SYNTHETIC local: .env/generated ignored | exclude sensitive/generated | RG | read-only | re-read ignores
LOCAL-HOOKS | NOT_APPLICABLE | SYNTHETIC local: no hook policy | no declared gate | RG | read-only | re-read instructions
LOCAL-SIGN | NOT_APPLICABLE | SYNTHETIC local: no signing policy | SOLO optional | GO | read-only | re-read policy
BR-DIRECT | NOT_APPLICABLE | SYNTHETIC local: sole owner/no shared default | SOLO recommendation if relevant | RG | read-only | re-check collaboration
BR-FORCE | NOT_APPLICABLE | SYNTHETIC local: no protected/shared branch | no surface | RG | read-only | re-read refs
PR-REVIEWS | NOT_APPLICABLE | SYNTHETIC local: no PR surface | SOLO optional | RG | read-only | re-read forge
PR-CHECKS | RECOMMENDED | SYNTHETIC local: CI script, no gate | recommend when CI exists | GO | read-only | run/inspect CI
PR-CONVERSATION | NOT_APPLICABLE | SYNTHETIC local: no PR surface | no gate | RG | read-only | re-read forge
PR-MERGE | NOT_APPLICABLE | SYNTHETIC local: PR integration unused | no surface | RG | read-only | re-read workflow
SEC-SCAN | NOT_APPLICABLE | SYNTHETIC local: no provider surface | support required | RG | read-only | re-read provider
SEC-PUSH | NOT_APPLICABLE | SYNTHETIC local: no provider surface | support required | RG | read-only | re-read provider
SEC-DEPS | RECOMMENDED | SYNTHETIC local: manifest, no owner | SOLO recommends automation | RG | read-only | inspect config/owner
SEC-CODE | RECOMMENDED | SYNTHETIC local: source, no scanner | risk-based recommendation | RG | read-only | inspect config
ENV-SCOPE | NOT_APPLICABLE | SYNTHETIC local: no deployments | no surface | RG | read-only | inspect config
ENV-REVIEW | NOT_APPLICABLE | SYNTHETIC local: no deployments | no surface | RG | read-only | inspect config
ENV-SECRETS | NOT_APPLICABLE | SYNTHETIC local: no deployment secrets | no surface | HP | read-only | inspect identifiers only
REL-TAGS | NOT_APPLICABLE | SYNTHETIC local: no published versions | no surface | GO | read-only | inspect tags
REL-CI | NOT_APPLICABLE | SYNTHETIC local: no publish/deploy | no surface | GO | read-only | inspect release config
COL-OWNERS | NOT_APPLICABLE | SYNTHETIC local: sole owner | no TEAM requirement | RG | read-only | inspect collaborators
```

Recovery/done: no network; all 19 once; select IDs before proposal. **PASS**.

### A02 — TEAM GitHub

Mode/profile: audit/TEAM. Context: C,P,A; all 19.

```text
LOCAL-IGNORE | ENFORCED | SYNTHETIC: sensitive/generated ignored | exclude them | RG | read-only | re-read ignores
LOCAL-HOOKS | ENFORCED | SYNTHETIC: adopted gate present | declared gates present | RG | read-only | inspect gate
LOCAL-SIGN | RECOMMENDED | SYNTHETIC: signing not required | TEAM policy-dependent | GO | read-only | inspect policy
BR-DIRECT | REQUIRED | SYNTHETIC: main permits admin direct write | TEAM restricts | RG | read-only | query ruleset
BR-FORCE | ENFORCED | SYNTHETIC: force/deletion disabled | TEAM prohibits | RG | read-only | query ruleset
PR-REVIEWS | REQUIRED | SYNTHETIC: approvals required=0 | TEAM requires review | RG | read-only | query protection
PR-CHECKS | ENFORCED | SYNTHETIC: ci/test required/passing | TEAM requires checks | GO | read-only | query checks
PR-CONVERSATION | ENFORCED | SYNTHETIC: resolution required | resolve before merge | RG | read-only | query protection
PR-MERGE | ENFORCED | SYNTHETIC: squash-only matches policy | matching method | RG | read-only | query methods
SEC-SCAN | ENFORCED | SYNTHETIC: scanning enabled | TEAM requires | RG | read-only | query setting
SEC-PUSH | REQUIRED | SYNTHETIC: protection disabled | TEAM requires | RG | read-only | query setting
SEC-DEPS | ENFORCED | SYNTHETIC: updater+owner present | TEAM requires where supported | RG | read-only | inspect config
SEC-CODE | REQUIRED | SYNTHETIC: scanner present, owner absent | owned scanning | RG | read-only | inspect workflow/owner
ENV-SCOPE | RECOMMENDED | SYNTHETIC: one staging environment | separate by risk | RG | read-only | query environments
ENV-REVIEW | RECOMMENDED | SYNTHETIC: staging has no reviewers | sensitive-stage reviewers | RG | read-only | query rules
ENV-SECRETS | RECOMMENDED | SYNTHETIC: DEPLOY_TOKEN repo-scoped; value unread | environment scope | HP | read-only | query metadata only
REL-TAGS | ENFORCED | SYNTHETIC: release policy adopted | explicit policy | GO | read-only | inspect tags/policy
REL-CI | ENFORCED | SYNTHETIC: release/provenance passes | release checks | GO | read-only | query workflow
COL-OWNERS | REQUIRED | SYNTHETIC: multiple collaborators/no CODEOWNERS | ownership mapping | RG | read-only | inspect mapping/teams
```

Recovery/done: select finding IDs; all 19 once; no score. **PASS**.

### A03 — PRODUCTION delivery

Mode/profile: audit/PRODUCTION. Context: C,P,A; all 19.

```text
LOCAL-IGNORE | ENFORCED | SYNTHETIC: secrets/generated ignored | exclude them | RG | read-only | re-read ignores
LOCAL-HOOKS | ENFORCED | SYNTHETIC: adopted gates present | required gates | RG | read-only | inspect gates
LOCAL-SIGN | ENFORCED | SYNTHETIC: signed-release policy observed | production provenance | GO | read-only | verify signature
BR-DIRECT | ENFORCED | SYNTHETIC: default requires PR | prohibit direct writes | RG | read-only | query ruleset
BR-FORCE | ENFORCED | SYNTHETIC: force/deletion disabled | prohibit both | RG | read-only | query ruleset
PR-REVIEWS | ENFORCED | SYNTHETIC: two+CODEOWNER required | named reviewers | RG | read-only | query protection
PR-CHECKS | ENFORCED | SYNTHETIC: strict checks pass | strict deployment checks | GO | read-only | query checks
PR-CONVERSATION | ENFORCED | SYNTHETIC: resolution required | production gate | RG | read-only | query protection
PR-MERGE | ENFORCED | SYNTHETIC: method matches release policy | controlled integration | RG | read-only | query settings
SEC-SCAN | ENFORCED | SYNTHETIC: enabled | production enforced | RG | read-only | query setting
SEC-PUSH | ENFORCED | SYNTHETIC: enabled | production enforced | RG | read-only | query setting
SEC-DEPS | ENFORCED | SYNTHETIC: updater+owner | enforced with triage | RG | read-only | inspect config
SEC-CODE | ENFORCED | SYNTHETIC: scan+owner | production scan/triage | RG | read-only | query analyses
ENV-SCOPE | REQUIRED | SYNTHETIC: staging+prod, preview absent | stages per deployment | RG | read-only | query list
ENV-REVIEW | ENFORCED | SYNTHETIC: prod has two reviewers | production approval | RG | read-only | query rules
ENV-SECRETS | REQUIRED | SYNTHETIC: PROD scoped; STAGING repo-scoped; values unread | scope per stage | HP | read-only | query metadata
REL-TAGS | ENFORCED | SYNTHETIC: protected tag policy | explicit policy | GO | read-only | inspect tags
REL-CI | ENFORCED | SYNTHETIC: release CI/provenance passes | production provenance | GO | read-only | query workflow
COL-OWNERS | ENFORCED | SYNTHETIC: prod paths map to release team | named owners | RG | read-only | inspect mapping
```

Recovery/done: owner enters secret values; metadata only; all 19 once. **PASS**.

### A04 — PUBLIC SOLO, no deployments, unavailable auth

Mode/profile: audit/SOLO+PUBLIC; PUBLIC is a flag. Context: C,P,A; all 19.
Override fixture: adopted `AGENTS.md` sets `PR-REVIEWS=REQUIRED` for external
contributions with source, scope, rationale, and expiry; it outranks SOLO.

```text
LOCAL-IGNORE | ENFORCED | SYNTHETIC local: .env/generated ignored | exclude them | RG | read-only | re-read ignores
LOCAL-HOOKS | NOT_APPLICABLE | SYNTHETIC local: no hook policy | no declared gate | RG | read-only | re-read instructions
LOCAL-SIGN | NOT_APPLICABLE | SYNTHETIC local: no signing policy | SOLO optional | GO | read-only | re-read policy
BR-DIRECT | UNKNOWN | SYNTHETIC: GitHub rule unavailable without auth | SOLO recommends restriction | RG | unavailable | authenticate/query
BR-FORCE | UNKNOWN | SYNTHETIC: branch rule unavailable | SOLO recommends no force | RG | unavailable | authenticate/query
PR-REVIEWS | UNKNOWN | SYNTHETIC: local override observed; provider enforcement unavailable | REQUIRED in override scope | RG | unavailable | authenticate/query
PR-CHECKS | UNKNOWN | SYNTHETIC local: CI exists; enforcement unavailable | SOLO recommends checks | GO | unavailable | authenticate/query
PR-CONVERSATION | UNKNOWN | SYNTHETIC: setting unavailable | resolve when supported | RG | unavailable | authenticate/query
PR-MERGE | UNKNOWN | SYNTHETIC local: PR used; methods unavailable | match history policy | RG | unavailable | authenticate/query
SEC-SCAN | UNKNOWN | SYNTHETIC: state unavailable | PUBLIC recommends scanning | RG | unavailable | authenticate/query
SEC-PUSH | UNKNOWN | SYNTHETIC: state unavailable | PUBLIC recommends protection | RG | unavailable | authenticate/query
SEC-DEPS | UNKNOWN | SYNTHETIC local: manifest; automation unavailable | SOLO recommends | RG | unavailable | authenticate/inspect
SEC-CODE | UNKNOWN | SYNTHETIC local: source; analyses unavailable | risk-based recommendation | RG | unavailable | authenticate/inspect
ENV-SCOPE | NOT_APPLICABLE | SYNTHETIC local: no deployments | no surface | RG | read-only | re-check config
ENV-REVIEW | NOT_APPLICABLE | SYNTHETIC: no sensitive deployment | no surface | RG | read-only | re-check config
ENV-SECRETS | NOT_APPLICABLE | SYNTHETIC: no deployment secrets | no surface | HP | read-only | re-check metadata
REL-TAGS | ENFORCED | SYNTHETIC local: semver policy followed | explicit tag policy | GO | read-only | inspect tags
REL-CI | UNKNOWN | SYNTHETIC local: workflow exists; run unavailable | release CI recommended | GO | unavailable | authenticate/query
COL-OWNERS | UNKNOWN | SYNTHETIC local: CODEOWNERS; team resolution unavailable | ownership mapping | RG | unavailable | authenticate/resolve
```

Recovery/done: retain local evidence; authenticate and rerun provider reads
only; three delivery N/As; override precedence; all 19 once. **PASS**.

### O01 — adopted docs-only bypass

Mode/profile: audit/TEAM. Context: C,P,A; all 19. The 18 unaffected controls
use A02 findings; the affected finding is:

```text
PR-REVIEWS | ENFORCED | SYNTHETIC: provider requires one review; adopted AGENTS.md permits docs/** bypass, rationale low-risk docs, expiry 2026-12-31 | bypass overrides TEAM only in exact scope; TEAM required elsewhere | RG | read-only | query protection and re-read scope/expiry
```

Recovery/done: honor only `docs/**` while unexpired; all 19 once. **PASS**.

### O02 — equal-authority disagreement

Mode/profile: audit/TEAM. Context: C,P,A; all 19. The 18 unaffected controls
use A02 findings; the affected finding is:

```text
PR-REVIEWS | UNKNOWN | SYNTHETIC: AGENTS.md requires one approval; policy/repository.md requires two; equal authority | do not average; desired count unresolved | RG | read-only | obtain one owner decision
```

Recovery/done: one decision request; no silent choice; all 19 once. **PASS**.

### N01 — unauthenticated GitHub protection

Mode/profile: audit/synthetic TEAM. Context: C,P,A; all 19. Local controls use
A02 local findings. Each applicable provider control is:

```text
<CONTROL> | UNKNOWN | SYNTHETIC: gh unauthenticated; named observation unavailable | <TEAM desired posture> | <catalog owner> | unavailable | authenticate then query named control
```

Demonstrably absent surfaces remain reasoned NOT_APPLICABLE. Recovery/done:
authenticate and retry provider reads only; local evidence retained; all 19
once. **PASS**.

## Proposal cases

### P01 — missing CI and check enforcement

Mode/profile: propose/synthetic TEAM. Context: C,P,A. Exact ID: `PR-CHECKS`.

```text
PR-CHECKS | REQUIRED | SYNTHETIC: no CI workflow/rule | TEAM requires checks | GO | approval required | workflow run, then ruleset
GR-01 | CONTROL=PR-CHECKS | CURRENT=no workflow | CHANGE=add ci/test pull_request workflow | TRADEOFF=runner cost/latency | DEPENDENCIES=write approval | REVERSAL=remove workflow | AUTHORITY=approval required | VERIFY=workflow exists and succeeds
GR-03 | CONTROL=PR-CHECKS | CURRENT=not required | CHANGE=require existing ci/test | TRADEOFF=CI outage blocks merge | DEPENDENCIES=GR-01 verified/passing | REVERSAL=remove context | AUTHORITY=approval required | VERIFY=exact ruleset query
```

Recovery/done: GR-01 before GR-03; independently selectable; no write. **PASS**.

### P02 — Improve everything

Mode/profile: clarify/none. Context/IDs: description only/none. No findings or
authority. Recovery/done: offer audit, present candidates, obtain selection
before proposals. **PASS**.

## Apply cases

All responses/effects are synthetic; no write occurred.

### X01

Mode/profile: apply/synthetic TEAM. Context: C,P,X. Control: `PR-CHECKS`.
Approved IDs: `GR-01,GR-03` only.

```text
GR-01 | CONTROL=PR-CHECKS | STATE=REQUIRED | EVIDENCE=SYNTHETIC before: absent | DESIRED=TEAM CI | OWNER=GO | AUTHORITY=already requested | VERIFY=workflow/run query | BEFORE=absent,deps available | EFFECT=add approved workflow only | RESPONSE=201 | POSTQUERY=list/run | POSTRESULT=exists/success | RECOVERY=none | FINAL=APPLIED
GR-03 | CONTROL=PR-CHECKS | STATE=REQUIRED | EVIDENCE=SYNTHETIC before: not required; GR-01 verified | DESIRED=TEAM enforcement | OWNER=RG | AUTHORITY=already requested | VERIFY=GET ruleset | BEFORE=absent,dep satisfied | EFFECT=add context preserving fields | RESPONSE=200 | POSTQUERY=GET ruleset | POSTRESULT=required/unrelated unchanged | RECOVERY=none | FINAL=APPLIED
```

Done: exact authorized/effect sets. **PASS**.

### X02

Mode/profile: apply/synthetic TEAM. Context: C,P,X. Control: `PR-CHECKS`.
Approved IDs: `GR-01,GR-03`.

```text
GR-01 | CONTROL=PR-CHECKS | STATE=REQUIRED | EVIDENCE=SYNTHETIC before: absent | DESIRED=TEAM CI | OWNER=GO | AUTHORITY=already requested | VERIFY=workflow/run | BEFORE=absent | EFFECT=add workflow | RESPONSE=201 | POSTQUERY=list/run | POSTRESULT=exists/success | RECOVERY=retain; offer reversal | FINAL=APPLIED
GR-03 | CONTROL=PR-CHECKS | STATE=REQUIRED | EVIDENCE=SYNTHETIC before: not required; dep verified | DESIRED=TEAM enforcement | OWNER=RG | AUTHORITY=already requested | VERIFY=ruleset | BEFORE=absent | EFFECT=add context | RESPONSE=403 | POSTQUERY=GET ruleset | POSTRESULT=still absent | RECOVERY=obtain authority; no GR-01 rollback | FINAL=BLOCKED
```

Done: partial state explicit; dependents stop. **PASS**.

### X03

Mode/profile: apply/synthetic TEAM. Context: C,P,X. Control: `PR-CHECKS`.
Approved ID: `GR-03`.

```text
GR-03 | CONTROL=PR-CHECKS | STATE=REQUIRED | EVIDENCE=SYNTHETIC before: check passes/not required | DESIRED=TEAM enforcement | OWNER=RG | AUTHORITY=already requested | VERIFY=GET ruleset | BEFORE=absent,dep satisfied | EFFECT=add context | RESPONSE=timeout | POSTQUERY=GET before retry | POSTRESULT=read unavailable | RECOVERY=no retry; restore access/read first | FINAL=UNKNOWN
```

Done: timeout not success; no blind retry. **PASS**.

### X04

Mode/profile: apply/synthetic TEAM. Context: C,P,X. Control: `PR-CHECKS`.
Approved IDs: `GR-01,GR-03`.

```text
GR-01 | CONTROL=PR-CHECKS | STATE=ENFORCED | EVIDENCE=SYNTHETIC before: exact workflow succeeds | DESIRED=TEAM CI | OWNER=GO | AUTHORITY=already requested | VERIFY=workflow/run | BEFORE=match | EFFECT=no-op | RESPONSE=not called | POSTQUERY=fresh read | POSTRESULT=match | RECOVERY=none | FINAL=ALREADY_SATISFIED
GR-03 | CONTROL=PR-CHECKS | STATE=ENFORCED | EVIDENCE=SYNTHETIC before: context required | DESIRED=TEAM enforcement | OWNER=RG | AUTHORITY=already requested | VERIFY=ruleset | BEFORE=match | EFFECT=no-op | RESPONSE=not called | POSTQUERY=fresh read | POSTRESULT=match/unrelated preserved | RECOVERY=none | FINAL=ALREADY_SATISFIED
```

Done: zero writes; result per approved ID. **PASS**.

## Verdict and defects

**28/28 PASS.** G06 now includes `PR-CONVERSATION`; O01/O02 explicitly select
audit and pass; guard/audit observations consistently use `AUTHORITY=read-only`.
PUBLIC remains a context flag, guards remain operation-bounded, audits account
for all 19 IDs, and no unnamed control, opaque score, authority expansion,
secret-value exposure, or retry without read-after-write appears.

No blocking package defect remains in the rerun scope. Minor non-blocking
documentation latitude remains: the package requires endpoint/command
attribution for provider UNKNOWN and verification but does not prescribe one
canonical endpoint string per control, so implementations can differ while
remaining attributable and bounded.
