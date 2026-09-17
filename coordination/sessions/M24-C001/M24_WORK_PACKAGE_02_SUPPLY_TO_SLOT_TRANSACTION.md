# M24 Work Package 02 — Supply-to-Slot Transaction

Covers: `SB-M24-006..011`, `SB-M24-023`, `SB-M24-027`

## Goal

Integrate accepted M23 front-batch transactions with M24's five slots so the player chooses only a supply column/front batch and M24 automatically fills the rightmost EMPTY slot.

## Production API rule

The production selection API must take a supply source/column request, **not a destination slot**.

Expected flow:

1. validate engine/supply coherence;
2. determine rightmost EMPTY slot;
3. begin M23 front selection transaction;
4. validate detached batch data against M24 state contract;
5. stage exact slot placement;
6. atomically commit the M23 selection and M24 placement;
7. expose success containing detached placement result only.

The exact internal order may differ, but there must be no reachable state where the M23 batch has been consumed and M24 failed to place it, or M24 placed it while M23 did not consume it.

## Rightmost-empty rule

With slots indexed left-to-right `0..4`, selection chooses the highest-index EMPTY slot.

Examples:

- all empty -> slot 4;
- slot 4 occupied -> slot 3;
- occupied `[0,2,4]`, empty `[1,3]` -> slot 3;
- after slot 3 later becomes empty while slot 4 remains occupied -> next accepted batch goes to slot 3.

Never shift or compact occupied slots.

## Full-five rejection

When all five slots are occupied:

- reject before permanent M23 consumption;
- no slot state changes;
- no placement-sequence advance;
- supply column/front remains exactly unchanged/selectable;
- no transaction leak remains open;
- no side effect in other supply columns.

## Accepted placement

On success:

- exactly one M23 front disappears;
- exactly one slot changes EMPTY -> ACTIVE;
- batch identity/color/count are copied exactly;
- `remaining_to_clear == initial_count`;
- `committed == 0`;
- placement sequence advances exactly once;
- all other occupied slots remain byte-for-byte/logically unchanged;
- no batch duplication.

## Failure/rollback safety

Directly test stale/invalid M23 transaction, malformed batch snapshot, failed M23 commit, re-entrant selection, reset during staged placement if the design permits an external callback, and rapid repeated requests.

Any failure must restore/preserve exact pre-operation slot state and supply state.

If no callback/re-entrant seam exists in production, document why the final post-M23-commit step is non-fallible and test the nearest adversarial boundary instead.

## Rapid repeated selections

Prove:

- one click/request cannot insert twice;
- two sequential legal requests consume two distinct FIFO fronts and fill two rightmost empty slots in order;
- stale duplicate transaction cannot double-advance a supply column;
- nested/re-entrant operation fails closed or deterministically defers without split-brain.

## Newly freed slot

After a later package frees a slot, the same rightmost-empty placement logic must accept the next selected front batch. Add the reusable test seam now; Work Package 04/05 will exercise the full cycle.

## Tests

Add focused M23->M24 transactional tests with detached before/after snapshots for every failure path.

## Completion criterion

Do not proceed to Work Package 03 until placement atomicity and full-slot rejection are directly proven green.
