# M25 Work Package 03 — Rollback, Clear Finalization, WAITING and Reset

Covers primarily: `SB-M25-019..027`.

## Objective

Complete the live-claim lifecycle without implementing M26 scheduling or M27 solving.

## A. Pre-spawn rollback seam — SB-M25-019

Implement a narrow future-M26 rollback operation for an exact live claim when route construction/validation/spawn preparation fails before a robot exists.

Required result:

- exact claim erased;
- exact ReservationState target/owner released;
- exact M24 `claim_id` committed-work entry rolled back;
- M24 committed decreases by 1;
- M24 remaining does not change;
- no unrelated claim/reservation/slot changes;
- no robot/spawn side effect exists in M25.

Make the multi-layer rollback transactionally safe. Directly test a failure/compensation seam if one canonical mutation can fail after another has already mutated.

## B. Authenticated-clear finalization — SB-M25-020..023

Implement a narrow post-clear accounting operation for one exact live claim.

Do not replace CompleteClearingLoop authentication.

Before M24 quota resolution, require canonical postconditions consistent with an already-authenticated clear:

- exact live claim exists;
- submitted claim identity matches engine record;
- target index/owner/batch/slot are the record's identities, not caller authority;
- BoardState target is CLEARED;
- ReservationState no longer owns target for that claim owner;
- M24 still has the exact claim/work committed to the same batch.

Then:

- call M24 `resolve_clear(claim_id)` exactly once;
- erase claim only after successful M24 resolution;
- never manually decrement M24 counters;
- double/stale/random finalization fails closed;
- wrong target/owner cannot redirect the claim;
- no retargeting.

Provide direct tests for success, double call, random ID, wrong identity, ACTIVE-not-cleared target, still-reserved target, already-freed/stale slot, and unrelated claim preservation.

## C. WAITING / re-evaluation — SB-M25-026..027

When an oldest capacity-bearing batch has no currently targetable matching pixel:

- transition that batch to M24 WAITING;
- preserve batch identity, remaining, committed and supply state;
- create no ReservationState entry and no M25 claim.

Provide a gameplay-domain board-clear/reconsideration seam so future M26 can request retry after authoritative BoardState changes. Do not poll UI state.

On a later successful claim:

- WAITING batch returns ACTIVE;
- same-color FIFO order still applies;
- no target is considered owned before it becomes production-targetable.

## D. Reset / teardown — SB-M25-024

Define and implement deterministic M25 reset/teardown order.

Preferred order:

1. for each live claim, safely release its exact ReservationState pair if still owned;
2. roll back its exact M24 committed work identity if still live/pre-clear;
3. verify unrelated ReservationState entries survive;
4. clear M25 ledger/transient state;
5. invalidate stale claim IDs.

M25 reset must not silently reset M24 or M23 supply unless an explicit session-level caller later owns that orchestration.

Directly test multiple live claims, duplicate colors, unrelated reservation owner, stale claims, repeated reset, and reset during a guarded claim transaction/re-entry.

## E. Batch completion guard — SB-M25-025

Prove a batch with any live M25 claim necessarily has corresponding M24 committed > 0 and therefore cannot complete/free prematurely.

After authenticated final claim clear, M24 may free the slot only through its accepted `remaining==0 && committed==0` rule.
