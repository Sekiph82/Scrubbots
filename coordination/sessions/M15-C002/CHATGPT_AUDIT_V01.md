# M15-C002 — ChatGPT Independent Audit V01

Decision: **CHANGES_REQUIRED / SAME_FROZEN_SET / V02_REQUIRED**

Audited implementation commit:
`5a2ed2765a1d2d77578223f88e2b456d2709d985`

H!veAI start transition:
`2df67b21fc547f243ea7a83ff137858223a0fd0c`

Prompt:
`coordination/sessions/M15-C002/CHATGPT_PROMPT_V01.md`

Criteria:
`coordination/sessions/M15-C002/CHATGPT_AUDIT_CRITERIA_V01.md`

Claude evidence:
`coordination/sessions/M15-C002/CLAUDE_LOG_V01.md`

Frozen basis:
`coordination/sessions/M15-C002/CHATGPT_FULL_SURFACE_REAUDIT_V01.md`

## Runtime / independence

Claude reports Godot `4.7.1.stable.official.a13da4feb`, full root suite **2941 / 2941 ALL PASS**, zero SCRIPT/Parse errors and clean `git diff --check`.

These runtime results are E1/E2. Godot is unavailable in the ChatGPT audit environment, so ChatGPT did not independently rerun the suite.

ChatGPT independently inspected the exact implementation commit, current `TargetSelector`, new M15 doubles/tests, ReservationState semantics, the V01 prompt/criteria, and the H!veAI v3 lifecycle. This is E3 source/diff/adversarial-test evidence.

## H!veAI v3 — PASS

Claude correctly pushed:
- `CHANGES_REQUIRED -> IN_PROGRESS` before production edits;
- final `IN_PROGRESS -> AWAITING_AUDIT`;
- final requiredActor `CHATGPT`;
- progress unchanged at `278/719 = 38.66%`;
- no COMPLETE / READY_FOR_NEXT_TASK claim.

## Pre-fix sensitivity — STRONG PASS

The V01 pre-fix probe directly confirmed all four requested defect classes:
1. scalar `access_query` produced a SCRIPT ERROR;
2. integer `1` targetability was incorrectly accepted as reachable;
3. re-entrant selector bind from targetability callback reserved in foreign bundle B;
4. ReservationState rebind from targetability callback produced reservation in the drifted bundle.

This establishes that M15-C002 was a concrete defect, not merely missing coverage.

## V01 corrections accepted

Preserve these changes:
- real BoardState bind category;
- RefCounted candidate/reservation categories;
- actual-bool coherence checks;
- safe access_query Variant/category boundary;
- actual-bool targetability;
- dynamic return type validation for owner/snapshot/candidates/is_reserved/reserve/get_owner;
- non-int candidate-entry rejection before BoardState calls;
- operation snapshot identity/generation;
- active-selection bind protection for callbacks reached after the guard is armed;
- post-reserve owner->target and target->owner proof;
- exact-pair rollback concept;
- preserved same-owner/different-owner contention semantics;
- no routing / board mutation / full-board scan.

## Remaining defects and false-positive gaps

No new top-level finding IDs are opened. Everything below remains inside **F-M15-STRICT-004 / F-M15-STRICT-005**.

### F-M15-STRICT-005.A — selection guard is armed after the first external coherence callback

Current order is effectively:

```gdscript
if not _op_coherent(...):
    return -1
_in_selection = true
```

But `_op_coherent()` itself calls injected `candidate_index.is_bound_to()` and `reservation_state.is_bound_to()`.

Therefore a callback from either initial coherence seam can call `selector.bind(...)` before `_in_selection` becomes true. The nested bind can mutate the selector bundle/generation before the outer operation has entered its protected transaction.

V01 criteria 30/31 required candidate/reservation callback bind re-entry coverage, but the new candidate/reservation doubles expose no `is_bound_to` hook, so those criteria are not directly sensitivity-tested.

Required:
- reject recursive selection immediately if `_in_selection` is already true;
- arm `_in_selection` before the first injected coherence callback;
- initial coherence failure must clear the guard through one deterministic exit path;
- nested bind from candidate and reservation initial-coherence callbacks returns false and cannot move the bundle;
- later sequential selection still works.

### F-M15-STRICT-005.B — recursive `select_and_reserve()` is not guarded

`_in_selection` currently protects `bind()` but `select_and_reserve()` itself does not reject when `_in_selection` is already true.

An injected targetability/candidate/reservation callback can recursively start a second selection transaction on the same selector.

Required:
- nested `select_and_reserve()` returns `-1` with no new reservation;
- outer operation remains deterministic;
- same-owner and different-owner recursive variants are challenged;
- later non-reentrant call recovers.

### F-M15-STRICT-005.C — `is_reserved()` true branch skips the promised post-callback coherence check

Current flow validates the return type, then:

```gdscript
if reserved:
    continue
if not _op_coherent(...):
    return -1
```

So when `is_reserved()` returns actual true, the operation proceeds to the next candidate without first verifying that the callback did not rebind candidate/reservation state.

This contradicts the frozen rule to re-check after every external collaborator boundary.

Required:
- perform operation-coherence check immediately after `is_reserved()` regardless of true/false result;
- drift plus `reserved == true` must stop before querying the next candidate.

### F-M15-STRICT-004.A / F-M15-STRICT-005.D — malformed `reserve()` return can hide a real mutation

V01 test for non-bool reserve explicitly sets:

```gdscript
reserve_force = 1
do_store = false
```

That proves a non-bool return is not treated as success, but it does NOT prove fail-closed rollback when the external call mutates first and then returns malformed metadata.

The V01 production path currently does:

```gdscript
var ok = rs.reserve(idx, owner_id)
if typeof(ok) != TYPE_BOOL:
    return -1
```

If the collaborator stores the exact `(idx, owner_id)` pair and returns integer `1`, the selector returns `-1` while leaving the newly-created reservation behind.

Required sensitivity:
- `reserve()` stores exact pair, returns int `1`;
- selector returns `-1`;
- exact requested pair is rolled back;
- no unrelated reservation is removed.

### F-M15-STRICT-005.E — malformed ownership proof can defeat `_rollback_own()`

After a successful reserve, ownership-proof failure calls `_rollback_own()`, but `_rollback_own()` first calls `get_owner(idx)` and only calls `release()` when that query returns an int matching owner.

If the reservation really stores the exact requested pair but `get_owner()` returns malformed metadata, the proof fails and `_rollback_own()` cannot reach release, leaving the exact reservation behind.

The V01 malformed-get_owner test checks only the returned `-1`; it does not assert reservation count / exact-pair cleanup.

Required:
- rollback after a reserve that returned actual true must attempt the exact requested `release(idx, owner_id)` without relying on the same malformed ownership query that caused the failure;
- canonical `ReservationState.release()` already protects unrelated ownership by exact pair;
- direct malformed-get_owner + exact stored pair test must prove no leak;
- other-owner-at-target case must remain preserved.

### F-M15-STRICT-005.F — owner assignment side effect can escape the no-later-candidate rule when targetability is false/malformed

The historical accepted law is: once a callback side effect has assigned `owner_id`, selection stops and does not query later candidates.

Current code checks owner assignment after a failed `reserve()`, but if `access_query.is_targetable()` itself reserves another target for the same owner and then returns `false` or malformed metadata, the code can `continue` to a later candidate before checking owner ownership again.

Required:
- after targetability callback + coherence validation, re-check `get_target_for_owner(owner_id)` with TYPE_INT validation before any `continue`/next-candidate work;
- if owner now holds any target, return `-1` and preserve that external side-effect reservation;
- prove no later candidate targetability query occurs;
- test actual bool false and non-bool verdict variants.

### F-M15-STRICT-005.G — bind itself has no bind-in-progress guard

Outside selection, `bind()` calls injected `candidate_index.is_bound_to()` / `reservation_state.is_bound_to()` before committing state. A coherence callback can recursively call `bind()` while the outer bind is still validating.

Required:
- add an initialization/bind-in-progress guard or equivalent transaction protection;
- nested bind from candidate/reservation bind-time coherence returns false;
- outer bind commits at most once and to its original requested bundle;
- failed outer bind leaves documented neutral state;
- later clean bind/rebind remains supported.

## Direct-observability gaps in V01 criteria

The following V01 criteria are not adequately demonstrated by the added doubles/tests and must be made direct in V02:
- 30: candidate callback nested bind;
- 31: reservation callback nested bind;
- 80: drift during candidate query;
- 81: drift during reserved-snapshot/owner query;
- 82: drift during is_reserved;
- 92: rollback after malformed post-reserve proof, including reservation-count/exact-pair observation.

A 2941/2941 aggregate cannot establish scenarios that the doubles cannot inject.

## Frozen status

- F-M15-STRICT-004 — OPEN
- F-M15-STRICT-005 — OPEN

M19 remains blocked on M15-C002.

Root task checkboxes remain auditor-owned and unchanged in this audit.

Progress remains:
- Main + UI: **278/719 = 38.66%**
- Overall: **278/943 = 29.48%**

## Verdict

**CHANGES_REQUIRED / SAME_FROZEN_SET / V02_REQUIRED**

Next:
`coordination/sessions/M15-C002/CHATGPT_PROMPT_V02.md`
