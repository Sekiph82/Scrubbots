# M24 Work Package 05 — Final Invariant Matrix and Integration Evidence

Covers: `SB-M24-030` and final closure evidence for `SB-M24-001..029`

## Goal

Turn M24 into an auditable closed milestone by building the exhaustive invalid-transition matrix, real M23 handoff evidence and full historical regression proof.

## Required dedicated evidence scripts

Create focused scripts (names may differ) that directly prove:

1. **M24 slot-state evidence**
   - exactly five EMPTY initial slots;
   - rightmost-empty placement;
   - no shifting/reordering;
   - duplicate colors legal;
   - detached queries;
   - invariants.

2. **M23 -> M24 transaction evidence**
   - accepted placement consumes exactly one M23 front;
   - rejected/full placement consumes none;
   - stale/malformed/repeated requests fail closed;
   - no split-brain between supply queue and slot state.

3. **BLUE 8/14/12 evidence**
   - three distinct same-color batches coexist and evolve independently.

4. **Lifecycle/accounting evidence**
   - committed work ledger;
   - capacity;
   - clear resolution;
   - rollback;
   - WAITING/ACTIVE transitions;
   - true completion/freeing.

5. **Five-full -> reject -> complete -> refill evidence**
   - full cycle exactly as specified in WP04.

These may be separate scripts or one clearly sectioned script, but the final log must provide literal commands and exits.

## SB-M24-030 invalid/state-transition matrix

Add direct root-suite checks for at least:

### Slot/category inputs

- invalid slot index negative/out of range;
- float/String/bool/null/object indexes where public seams are Variant-capable;
- malformed batch IDs/colors/counts;
- duplicate batch ID insertion;
- attempts to mutate EMPTY as occupied without legal placement.

### Placement

- full slots;
- holes and rightmost-hole choice;
- stale M23 transaction;
- exhausted M23 column;
- malformed front batch;
- rapid repeated request;
- duplicate placement attempt;
- nested/re-entrant request if any synchronous external callback exists.

### Accounting

- zero capacity;
- over-commit;
- duplicate work ID;
- malformed/unknown work ID;
- resolve wrong identity;
- rollback wrong identity;
- double resolve;
- double rollback;
- resolve after rollback;
- rollback after resolve;
- counter underflow/overflow attempts;
- remaining never decreases except legitimate resolve;
- committed never exceeds remaining.

### State machine

- EMPTY -> WAITING rejected;
- EMPTY -> ACTIVE through claimability seam rejected;
- WAITING preserves counters;
- WAITING -> ACTIVE on authoritative availability;
- ACTIVE -> WAITING on authoritative no-work notification while remaining > 0;
- completed/EMPTY batch cannot resume;
- final completion frees exactly one slot.

### Reset/pause/snapshot

- pause/resume exact-state preservation;
- reset with ACTIVE + WAITING + committed work;
- pre-reset work identities stale;
- returned snapshot mutation cannot alter engine;
- deterministic replay of same supply/placement/accounting sequence.

## Cross-module non-regression

Run and report:

- full root suite;
- all M23 V01/V02/V03 dedicated evidence;
- M22 V03/V04/V05/V06 dedicated evidence;
- M21 real-art full clear;
- M21 V10 reservation evidence;
- representative M20 queue-free and lifecycle evidence;
- `git diff --check`.

Historical direct-color SlotSystem evidence must remain green.

## M25/M26/M27 boundary audit

Before finalizing, inspect the implementation diff and explicitly prove it contains no:

- target pixel arbitration/ownership policy;
- new ReservationState replacement;
- changed TargetSelector WHAT ordering;
- route calculation or Railroad policy change;
- Scrubbot spawn/dispatch scheduler;
- level solvability/deadlock search.

M24 may contain only slot/accounting seams needed by those future systems.

## Final self-check mapping

In `CLAUDE_LOG_V01.md`, include a table with **all 30 tasks**:

`SB-M24-001` through `SB-M24-030`

For every row provide:

- implementation file/function;
- direct test/evidence location;
- result.

Do not mark anything DONE in root `TASKS.md`; ChatGPT owns that after audit.

## Final handoff

Only after every work package and full regression pass:

- push final implementation SHA;
- push `CLAUDE_LOG_V01.md` separately;
- return `AWAITING_AUDIT`, final implementation SHA and direct log URL.
