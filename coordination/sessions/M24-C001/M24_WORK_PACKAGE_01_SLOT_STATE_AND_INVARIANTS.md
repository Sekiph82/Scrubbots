# M24 Work Package 01 — Slot State and Core Invariants

Covers: `SB-M24-001..005`, `SB-M24-012..015`, `SB-M24-024`

## Goal

Create the production five-slot batch-state domain model without UI, target claims, routing or robot dispatch.

## Required implementation

Implement a production gameplay-domain slot engine, preferably new classes under `scripts/gameplay/slots/` such as:

- `slot_batch_state.gd`
- `five_slot_batch_engine.gd`

Names may differ if clearer, but responsibilities must match.

### Exactly five slots

- Fixed invariant: exactly five production batch slots.
- All five begin `EMPTY`.
- No public configuration may change slot count.
- Invalid indexes/types fail closed.

### SlotBatchState

An occupied slot must own at least:

- stable `batch_id`
- canonical integer `color_id`
- `initial_count`
- `remaining_to_clear`
- `committed`
- monotonic/deterministic `placement_sequence`
- lifecycle state: `EMPTY`, `ACTIVE`, `WAITING`

EMPTY must not retain stale batch/color/count/work identity.

Use detached/read-only queries. Do not hand out mutable internal state objects/arrays/maps.

### Same-color independence

Allow duplicate colors in different slots. Never merge same-color batches or pool their quotas.

### Invariants

For every occupied slot enforce:

`0 <= committed <= remaining_to_clear <= initial_count`

`dispatch_capacity = remaining_to_clear - committed`

Malformed counts, color IDs, batch IDs, placement sequence or state transitions must fail closed.

### Queries

Expose detached read-only queries sufficient for future presentation/save/replay:

- slot count
- empty/occupied
- state
- batch id
- color id
- initial count
- remaining count
- committed count
- capacity
- placement sequence
- full detached snapshot

Returned data mutation must not mutate engine truth.

## Historical boundary

Do not remove/rewrite historical `slot_system.gd` / `slot_state.gd` unless a regression-safe additive compatibility adaptation is required. M21/M22 tests must remain valid.

## Direct tests

Add focused headless tests proving:

- count exactly 5;
- initial all EMPTY;
- cannot create/configure 4/6-slot production engine;
- valid occupied state;
- malformed state rejected;
- duplicate colors legal;
- stable batch identities remain separate;
- every invariant boundary including zero/full capacity;
- snapshot mutation isolation;
- invalid indexes/types fail closed;
- no dependency on Node/Control/UI classes.

## Completion criterion

Do not proceed to Work Package 02 until all package tests pass and no accepted historical regression fails.
