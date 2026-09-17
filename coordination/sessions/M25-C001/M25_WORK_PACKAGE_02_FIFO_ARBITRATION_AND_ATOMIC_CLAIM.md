# M25 Work Package 02 — FIFO Arbitration and Atomic Claim

Covers primarily: `SB-M25-006..018`.

## Objective

Implement deterministic duplicate-color batch arbitration and the exact logical transaction that converts one currently targetable matching pixel into one live claim + one ReservationState reservation + one M24 committed work unit.

## Same-color arbitration

For a requested color:

1. read the five M24 slots through public read-only queries/snapshot;
2. collect occupied matching-color batches with capacity > 0;
3. sort by placement sequence oldest first;
4. choose the oldest capacity-bearing batch;
5. do not merge same-color batches;
6. do not skip the oldest merely because a newer one exists;
7. if oldest capacity is 0, select the next oldest capacity-bearing batch.

Use deterministic tie/fail rules. Reject malformed duplicate placement-sequence state fail-closed if it would make ownership ambiguous.

## Target authority

For the chosen slot/batch:

- consume that slot's supplied production targetability object;
- invoke existing TargetSelector `select_and_reserve`;
- preserve TargetSelector bottom-most -> left-most -> index ordering;
- do not scan/sort targets independently in M25;
- no blocked/unreachable target may enter the ledger.

## Atomic accepted claim

Implement the full claim transaction under one re-entry/state-drift guard:

1. snapshot chosen M24 batch identity/state/capacity/lifecycle;
2. mint one claim ID + one reservation owner ID;
3. TargetSelector atomically selects/reserves target;
4. if no target, create no claim and transition the selected batch to WAITING when legal;
5. on reserved target, make/confirm selected batch ACTIVE;
6. commit one exact M24 work unit with `claim_id`;
7. if M24 commit fails, release only the new ReservationState pair and restore lifecycle prestate;
8. publish claim record only after reservation + M24 commit are both proven;
9. return detached claim result.

After success, assert exact postconditions:

- M24 committed increased by 1 on the chosen batch only;
- M24 remaining unchanged;
- ReservationState owner(target)==claim owner;
- ReservationState target_for_owner(owner)==target;
- ledger has exactly one new claim matching all identities;
- no other slot/batch/reservation changed.

## Failure tests

Directly test:

- invalid color;
- no matching live batch;
- zero-capacity oldest batch spilling to next oldest;
- no targetable candidate -> WAITING, no reservation, no committed increment;
- blocked future candidate is not claimed;
- same target contested by repeated requests -> unique ownership;
- malformed/foreign access input fails closed;
- M24 commit failure after successful reservation rolls the reservation back exactly and restores lifecycle/state;
- nested/re-entrant claim/reset attempt from an access/selector callback cannot create half-state.

## Scope

No route construction, robot spawn or automatic scheduler loop.
