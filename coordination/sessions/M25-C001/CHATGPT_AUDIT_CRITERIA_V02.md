# M25-C001 V02 — Strict Remediation Audit Criteria

Milestone: `M25 — Batch Target Claim Engine`
Cycle: `M25-C001 V02`
Repository: `Sekiph82/Scrubbots`
Actor: Claude
Auditor: ChatGPT
Prior audit: `coordination/sessions/M25-C001/CHATGPT_AUDIT_V01.md`

## Verdict policy

V02 passes only if every finding `F-M25-V01-STRICT-001..005` is closed in real production code and direct adversarial evidence, while every accepted M25 V01 behavior and all M24/M23/M22 regressions remain green.

This is ONE narrow M25 remediation cycle. Do not implement M26 or M27.

## 1. Identity non-reuse / stale invalidation

Claim identities must not become valid again after reset.

Directly prove:
- create claim A and retain its claim id;
- reset M25;
- create claim B;
- A and B cannot share an externally actionable claim identity;
- stale A rollback/finalize cannot mutate B;
- stale pre-reset owner identity cannot be confused with B.

Reservation owner allocation must not stall on unrelated live ReservationState owners:
- pre-reserve an unrelated target with owner id equal to M25's next candidate (including 0 in a fresh engine);
- a valid M25 claim must select a different unused owner identity and succeed;
- the unrelated reservation survives unchanged.

Do not solve this by stealing/releasing unrelated owners.

## 2. Commit-failure exact lifecycle rollback

Drive a selected batch from WAITING into a now-targetable state, then force M24 `commit_work` failure after TargetSelector reservation.

After failure prove exact pre-attempt truth:
- lifecycle restored to WAITING;
- remaining unchanged;
- committed unchanged;
- no M25 ledger entry;
- exact new reservation released;
- unrelated reservations untouched;
- no identity counter/claim publication that can create a stale alias.

If the prestate was ACTIVE, ACTIVE remains ACTIVE.

## 3. Transaction-safe rollback_claim

Before mutating, validate enough engine-owned tuple truth to guarantee exact cleanup, or implement compensation with direct proof.

For a healthy live claim, rollback still:
- decrements M24 committed exactly once;
- leaves remaining unchanged;
- releases exact ReservationState pair;
- erases exact ledger entry.

Adversarial cases must fail closed without hiding inconsistency:
- exact reservation pair externally absent;
- target reserved by a foreign owner after M25 ownership was removed;
- M24 exact work identity absent/stale;
- wrong/random claim id.

If any required canonical mutation fails, no half-cleaned tuple may be reported as success and the ledger must not simply disappear.

## 4. Transaction-safe reset / teardown

Reset must first validate/clean every live M25 tuple safely.

Required:
- multiple healthy claims all clean;
- unrelated ReservationState owners survive;
- if one live tuple cannot be cleaned consistently, reset must not silently clear the ledger and report success while leaving orphan M24/reservation truth;
- define deterministic failure/compensation policy;
- stale claim identities remain invalid after any successful reset.

Document session teardown order: M25 cleanup before M24 reset.

## 5. Strict production access category/coherence

The production claim path must reject generic method-compatible RefCounted access objects.

Accepted production access must be:
- canonical `ProductionTargetAccess`, or
- a narrowly-defined production adapter whose category/coherence contract proves it derives targetability from production routing and the exact bound BoardState.

Direct tests:
- real coherent ProductionTargetAccess accepted;
- generic all-true RefCounted rejected;
- foreign-board ProductionTargetAccess rejected;
- null/malformed rejected;
- no reservation/M24 mutation on rejection.

If a minimal read-only coherence method must be added to ProductionTargetAccess, keep it non-mutating, document it, and run protected M19/M22 regressions.

Re-entry tests must not depend on weakening the production access category. Inject re-entry through another strict/canonical boundary or a category-correct test subclass/adapter.

## 6. Session-stable binding

Once M25 is successfully bound, a second ordinary `bind()` must fail closed and preserve the exact original bundle.

Directly prove:
- second coherent same-bundle bind is rejected or declared idempotent without mutation;
- coherent foreign-bundle bind is rejected;
- foreign bind while one or more live claims exist cannot move authorities;
- original live claims remain rollback/finalize-capable against the original bundle.

If an explicit rebind API is introduced, it must require zero live claims and verified cleanup; ordinary bind must never migrate a live session.

## 7. Preserve owner-locked arbitration

Re-run/prove unchanged:
- BLUE 8 / BLUE 14 / BLUE 12 distinct;
- oldest capacity-bearing blue batch wins;
- capacity spill to next blue only at zero capacity;
- no future blocked target pre-owned;
- opening-time claim goes to oldest eligible batch;
- TargetSelector bottom-most then left-most;
- one target one live claim/reservation.

## 8. Scope

Do not implement:
- M26 scheduler, route-to-agent handoff, spawn, pacing/fairness;
- M27 solver/deadlock;
- UI.

Root `TASKS.md` is read-only for Claude.

Zero image-generation credits.

## 9. Required validation

At minimum:
- full `tests/run_tests.gd`;
- all M25 V01 dedicated evidence;
- new V02 identity/access/rollback/reset/lifecycle evidence;
- M24 V01/V02 evidence;
- M23 V01/V02/V03 evidence;
- M22 V07 + V03-V06 evidence;
- M21 real-art + V10;
- representative M20 lifecycle/queue-free;
- `git diff --check`.

Report exact checks/failures/exits.

## 10. Handoff

Push implementation commit(s) first.
Then create `coordination/sessions/M25-C001/CLAUDE_LOG_V02.md` as a separate final commit.

Map every V01 finding to code + direct tests. Confirm:
- root TASKS modified = NO;
- M26/M27 implementation = NO;
- image credits = 0;
- `AWAITING_AUDIT`.
