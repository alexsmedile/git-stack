# Approved guardrail application

Use this when: the owner explicitly approves named proposal item IDs.

1. Re-read each selected item's current state and dependencies. Mark already
   satisfied items without writing.
   Completion: every approved ID has a fresh before-state and dependency status.
2. Present one batch: IDs, exact effects, provider/local targets, reversals, and
   any credential/secret steps the owner must perform. Apply only approved IDs.
   Completion: the authorized ID set and exact effect set are identical.
3. Execute prerequisites before dependent enforcement. Use the narrowest
   provider endpoint or local edit; preserve unrelated settings.
   Completion: every attempted item has an attributable response and dependents
   run only after prerequisites verify.
4. Immediately query/read the target state. Record `APPLIED` only on an exact
   match. Timeout or ambiguous response triggers read-after-write diagnosis.
   Completion: every attempted item has a matched postcondition or UNKNOWN.
5. Stop dependent items after a failure. Do not roll back successful independent
   items automatically; report partial state and offer the recorded reversals.
   Completion: every unattempted ID names its blocker and successful state remains explicit.

Completion: every approved ID is `APPLIED`, `ALREADY_SATISFIED`, `BLOCKED`, or
`UNKNOWN`; every applied item has attributable postcondition evidence; every
unattempted dependent item names its blocker.

## Safe rerun

Rerun begins by reading current state and skips exact matches. For an UNKNOWN
write, query before repeating. If the provider cannot represent a proposal
without replacing a whole ruleset/protection object, fetch the full current
object, preserve unrelated fields, show the replacement diff, and require exact
authorization for that broader effect.

Secret values and interactive credentials are owner-performed. The skill may
verify only names, scopes, timestamps, or provider metadata that does not expose
the value.
