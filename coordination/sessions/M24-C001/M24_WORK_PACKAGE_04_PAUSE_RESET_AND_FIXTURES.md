# M24 Work Package 04 — Pause/Reset and Canonical Fixtures

Covers: `SB-M24-025..029`

## Goal

Lock deterministic pause/resume/reset behavior and prove the canonical multi-batch/fill-full/free/refill gameplay fixtures through the real M23 -> M24 path.

## Pause / resume — SB-M24-025

M24 pause/resume must preserve exact state.

If M24 itself does not own a pause clock/timer, provide an explicit no-op/persisted pause-state seam or prove that all M24 state is time-independent and untouched by gameplay pause/resume integration.

Directly prove before/after equality for:

- slot occupancy/order;
- batch IDs/colors;
- initial/remaining/committed counts;
- live work identities;
- placement sequence;
- ACTIVE/WAITING states;
- M23 supply queues.

Do not silently resolve, rollback, complete, reorder or refill anything merely because pause/resume occurred.

## Reset — SB-M24-026

M24 reset must deterministically restore its own initial production state:

- exactly five EMPTY slots;
- no batch IDs/colors/counts;
- no live work identities;
- no WAITING/ACTIVE occupied state;
- placement sequence reset to the documented initial value;
- no pending placement/re-entrancy guard stuck;
- all pre-reset work IDs invalid afterward;
- all pre-reset slot/batch references/snapshots detached/stale and unable to mutate engine truth.

M24 reset must **not silently reset M23** unless an explicit higher-level session operation owns both. Keep reset ownership documented.

## Canonical BLUE fixture — SB-M24-028

Build a deterministic regression fixture containing three distinct same-color supply batches:

- `BLUE 8`
- `BLUE 14`
- `BLUE 12`

Use stable distinct `batch_id`s.

Feed them through the accepted M23 transactional front-selection path and M24 production placement API. Do not insert them by directly mutating M24 internals.

Prove:

- first accepted batch goes to slot 4;
- second to slot 3;
- third to slot 2;
- all three keep separate batch IDs;
- all three keep separate `initial_count`/`remaining_to_clear`/`committed` state;
- committing/resolving work on one never changes the other two;
- same color does not merge or pool quota;
- detached queries cannot cross-mutate siblings.

The fixture need not assign real target pixels; that is M25.

## Five-full -> rejection -> completion -> refill — SB-M24-029

Build a direct end-to-end state-machine fixture:

1. M23 candidate has at least six selectable batches across legal columns.
2. Fill all five M24 slots via production selection.
3. Snapshot M23+M24.
4. Attempt sixth selection while full.
5. Prove rejection and exact state preservation; sixth batch remains at front.
6. Choose one occupied slot and create legitimate opaque committed-work identities up to its remaining quota using the M24 accounting seam.
7. Resolve them successfully until that batch truly completes.
8. Prove only that slot becomes EMPTY; neighbors do not shift.
9. Retry/select the previously rejected supply batch.
10. Prove it fills the now-rightmost EMPTY hole.
11. Prove the originating M23 column advances exactly once on successful retry.
12. Prove every slot invariant and supply FIFO invariant still holds.

Use practical counts in this fixture so the test remains fast; exact large batch values are already covered elsewhere.

## Rapid-selection transaction fixture — SB-M24-027 reinforcement

Include rapid sequential selections and, if any external callback seam exists, an adversarial nested/re-entrant selection/reset attempt. There must be no duplicate batch insertion or double supply advance.

## Reset with live state

Directly reset while the engine contains:

- multiple occupied slots;
- at least one WAITING batch;
- at least one ACTIVE batch;
- at least one live committed work ID.

After reset all five must be exact EMPTY and every stale work ID must fail closed.

## Completion criterion

Do not proceed to WP05 until pause/resume, reset, BLUE 8/14/12, full-five rejection and refill cycle all pass focused headless evidence.
