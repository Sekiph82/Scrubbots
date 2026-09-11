# M20-C001 V10 — Final Closure-Only Exact-Evidence Reconciliation

You are Claude, validation/test runner only. ChatGPT owns audit verdicts and task closure.

Repository:
`https://github.com/Sekiph82/Scrubbots`

Canonical live tracker: root `TASKS.md` ONLY.

Read first:
- `TASKS.md`
- `CLAUDE.md`
- `AGENTS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V09.md`
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V10.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V10.md`

This is **validation-only**. Production is source-accepted and immutable.

## 0. Tracker start

Expected initial state after ChatGPT audit handoff:
- M20-C001 V10;
- status CHANGES_REQUIRED;
- actor CLAUDE;
- progress 290/719 main+ui, 290/943 overall;
- lastCompletedTaskId M19-C001-V06;
- all SB-M20-001..014 open.

Before ANY V10 test/smoke edit:
1. safe sync origin/main, preserve owner work;
2. change only root Project Status lifecycle to `M20-C001-V10 / IN_PROGRESS / CLAUDE`;
3. tracker-only commit + push;
4. verify remote;
5. record no V10 validation edit existed before the push.

## 1. Production lock

Required exact blobs before and after:
- loop `06391839523cbc27e88a4b3ef12b730012cd45fa`;
- dispatcher `eee10149e4f116af6706beec832042352bf3a6dd`.

No committed `scripts/**` change.

If any V10 test exposes a production defect, do NOT fix it. Return `BLOCKED / V10_VALIDATION_EXPOSED_PRODUCTION_DEFECT`.

## 2. Add one narrow V10 reconciliation group

Add `_run_m20_v10_closure_reconciliation_tests()` to `tests/run_tests.gd`, preserving all prior M19/M20 tests.

Use separate helpers/groups for G-V09-01..06. Reuse wiring helpers, but every requested invariant below must have its own direct assertion.

## 3. G-V09-01 claim/reset actual usability

Use at least two reachable targets.
- diagnostic observer before first loop bind;
- first loop binds and clears A;
- snapshot BoardState + exact reservation map/count;
- `reset()` owner loop with no active work;
- prove both snapshots unchanged;
- second different loop remains unable to bind;
- ORIGINAL first loop then executes a second real activation/dispatch/arrival and clears B;
- cleared_count increments exactly one additional time;
- second loop remains zero attribution;
- claim still belongs to first loop until it is released/GC'd.

Do not call `is_coherent()` alone “usable”. Actual second gameplay operation is required.

## 4. G-V09-02 activation serialization exactness

### 4A nested activation
- capture `peek_next_owner_id()` before outer call;
- inject nested `activate_slot()` during outer activation preflight;
- nested result = REENTRANT;
- outer healthy result succeeds;
- active/reservation count = one;
- final next-owner id = before + exactly 1, proving nested request consumed no owner token.

### 4B activation DURING arrival drain
Build two reachable targets/slots and use the test-only candidate/reservation transaction hook so that, while arrival A is actively committing (`_draining` true), the hook calls a second `activate_slot()`.

Directly assert:
- inner activation = REENTRANT;
- inner request creates no extra owner token, reservation, or active agent;
- A transaction completes normally in the healthy arrangement;
- after drain completes, a later ordinary activation remains usable.

## 5. G-V09-03 exact failed-preflight matrix

Fresh/table-driven cases:
- missing reservation;
- candidate rebind(foreign);
- candidate rebind(null);
- externally CLEARED target;
- renderer foreign after dispatch/before arrival;
- renderer queued after dispatch/before arrival.

For each directly assert all applicable exact truth:
- rejection/no clear;
- cleared_count unchanged;
- BoardState expected state;
- reservation both `target->owner` and `owner->target` when pair is supposed to remain;
- dispatcher assignment pending when pair/assignment should remain;
- raw target candidate present when BoardState is ACTIVE and candidate index healthy;
- unrelated sentinel truth unchanged if arranged.

Add/extend a frame V10 smoke for truly-freed renderer before arrival with the same preservation assertions, including raw candidate and owner->target.

### Failed-preflight cleanup frame proof
In a frame smoke:
- hold one real assignment via an intentional preflight failure;
- confirm it is pending;
- call authorized loop reset;
- await frames;
- agent is no longer valid;
- dispatcher has no orphan child for that assignment;
- original reservation pair is gone;
- unrelated sentinel reservation/cell remains intact.

## 6. G-V09-04 exact ledger identity

### Five-slot
After first of five arrivals:
- first `get_owner(target) == -1`;
- first `get_target_for_owner(owner) == -1`;
- remaining four exact both directions;
- then all five finalize and final active/reservation counts are zero.

### Scale rows
For Easy, Medium, Hard, Very Hard, 59x59 and rectangular:
- record expected target index;
- run normal real-production M20 sequence;
- assert success;
- assert `get_cell_state(expected_target) == CLEARED` directly;
- assert total CLEARED count delta exactly +1.

## 7. G-V09-05 detached rollback prestate

### Candidate mutate-before-false
Arrange target T + unrelated same-color U + different-color V, plus at least one unrelated reservation if useful.
Before fault snapshot DETACHED:
- full BoardState states;
- target/same-color candidate bucket;
- different-color bucket;
- exact reservation target->owner map/count;
- active count and relevant dispatcher owner identities.

Run mutate-before-false.
- outcome CANDIDATE_ROLLBACK or ROLLBACK_FAILED;
- if CANDIDATE_ROLLBACK, compare EVERY snapshot exactly.

### Reservation mutate-before-false
Arrange current pair plus an unrelated pair.
Snapshot detached:
- full exact target->owner map/count;
- owner->target reverse identity for each arranged owner;
- BoardState;
- dispatcher active/owner identities.

Run fault.
- outcome RESERVATION_ROLLBACK or ROLLBACK_FAILED;
- if RESERVATION_ROLLBACK, compare EVERY snapshot exactly.

## 8. G-V09-06 evidence table

`CLAUDE_LOG_V10.md` must contain rows G-V09-01..06 with:
- exact test/smoke name;
- exact assertion names;
- actual runtime result;
- whether evidence is synchronous root-suite or frame-smoke.

No aggregate count substitution.

## 9. Final validation

No new production sensitivity is required. Do not spend time mutating production again unless a V10 test unexpectedly needs diagnostic confirmation.

Run after all test edits:
1. exact production blobs;
2. `godot --version`;
3. full root suite;
4. separately run queue-free, V04, V05, V07, V08, V09 and any new V10 lifecycle smoke;
5. inspect each final output for literal `SCRIPT ERROR` and `Parse Error`;
6. `git diff --check`;
7. exact changed files;
8. `git diff e189ee8 -- scripts/` must be empty;
9. push/verify remote.

Allowed committed files:
- `TASKS.md` lifecycle fields;
- `tests/run_tests.gd`;
- `tests/m20_v10_lifecycle_smoke.gd` if needed;
- narrow test support only if absolutely required;
- `coordination/sessions/M20-C001/CLAUDE_LOG_V10.md`.

No docs. No production.

## 10. Handoff

On clean validation:
- leave SB-M20-001..014 open;
- progress unchanged;
- lastCompleted unchanged;
- set tracker to `M20-C001-V10 / AWAITING_AUDIT / CHATGPT`;
- commit/push/verify;
- return `AWAITING_AUDIT` and stop.

Do not start M21.