# SB-M52-C001-R01 — CHATGPT AUDIT CRITERIA

Verdict: PASS only if the new production runtime behavior is real, deterministic, transaction-safe and re-proven against the First 10 pack.

## 1. Owner rule

Implementation must conform to:
`coordination/OWNER_PARALLEL_SLOT_DISPATCH_AND_DEPARTURE_COUNT_V01.md`.

No hidden retention of old same-color monopolization in the production path.

## 2. Five-BLUE fixture

Required production evidence:
- five occupied BLUE batches, 30 each;
- one dispatch cadence wave;
- exactly five accepted live assignments;
- one assignment from each distinct slot/batch;
- five unique targets;
- five unique reservations/claims/agents;
- before any target clears, all five displayed counts = 29;
- board ACTIVE total unchanged until authenticated arrivals actually clear targets.

Failure = CHANGES_REQUIRED.

## 3. Per-slot fairness

- waiting is slot-specific;
- one blocked same-color slot does not block a legal sibling;
- no slot emits more than one new assignment per wave;
- baseline wave max 5;
- +1 Slot wave max 6;
- deterministic ordering.

## 4. No-ghost / accounting

Across N parallel live agents:
scheduler assignments == dispatcher agents == M25 claims == reservations == M24 live committed work.

Rollback/reset/Retry/Tornado/pause/focus paths cannot orphan or double-finalize any identity.

M24 authoritative remaining still changes only on authenticated clear.

## 5. Departure count

Before clear:
remaining=30, committed=1, display=29.

After clear:
remaining=29, committed=0, display=29.

Rollback before clear:
remaining=30, committed=0, display=30.

The implementation must not fake the number in UI independently from M24 snapshot truth.

## 6. 2x

No-entitlement press cannot be silent.

It must open the functional purchase flow.

Purchase options/prices:
- level 200;
- 15m 300;
- 30m 500;
- 60m 750.

Successful purchase:
- exact wallet debit once;
- entitlement committed/saved;
- runtime immediately 2x;
- UI shows 2x.

Cancel/failure/insufficient funds:
- no debit;
- no entitlement;
- remains 1x.

Existing valid entitlement toggles normally.

Free supply-exhausted auto-2x remains free.

## 7. Temporal correctness

At 2x:
- wave cadence exactly 2x frequency vs 1x;
- agent travel exactly 2x;
- gameplay accounting/target/order truth unchanged.

No Engine.time_scale shortcut.

## 8. Stutter

Audit must inspect Claude's instrumentation and code diff.

A claimed fix requires:
- identified dominant source(s);
- before/after evidence;
- no replacement with disabled correctness checks.

If completion/deadlock proof was hot, new gating must still detect true LOST deterministically.

## 9. Solver consistency

ProofKernel/M27 documentation and implementation must match the new runtime policy or contain a defensible conservative equivalence.

Re-run First 10:
- solver/proof accepted;
- trace/replay accepted;
- owner queues unchanged;
- production runtime 9/9 WON;
- Level 1 unchanged;
- frontier 11 CONTENT_MISSING.

Any false proof/runtime divergence = CHANGES_REQUIRED.

## 10. Regression

Focused R01 tests pass.
M52 owner-plan tests pass.
Relevant M23–M42 regression pass.
Root suite pass.
No new SCRIPT ERROR / unexplained engine errors.
Diff check clean.

## Verdicts

PASS:
`AUDITED_PASS / M52-C001-R01 / OWNER REPLAY REQUIRED`

Otherwise:
`CHANGES_REQUIRED / M52-C001-R01`
