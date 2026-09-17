# M25 Work Package 01 — Claim Model and Binding

Covers primarily: `SB-M25-001..006`, plus foundations for `011..018`.

## Objective

Create the production Batch Target Claim Engine skeleton and exact dependency/coherence contract without implementing M26 scheduling/spawn.

## Required implementation

1. Add one gameplay-domain claim engine under `scripts/gameplay/targeting/` or a comparably appropriate gameplay folder.
2. Add a compact claim record/value representation if helpful.
3. Bind one coherent bundle:
   - BoardState;
   - accepted FiveSlotBatchEngine;
   - TargetSelector;
   - ReservationState.
4. Require selector/reservation coherence with the same BoardState.
5. Reject null, mixed-board, foreign/malformed dependency bundles with zero mutation.
6. Define a session-scoped monotonically unique ReservationState owner identity for M25 claims.
7. Define a stable unique claim/work identity suitable for direct use as the M24 opaque work ID.
8. Claim record must capture at least batch ID, slot index, placement sequence, color, target index/coord, reservation owner ID and claim ID.
9. Expose detached read-only live-claim snapshots/queries. Never return mutable internal maps/records.
10. Do not create a duplicate target-reservation authority. ReservationState remains authoritative for live target ownership.

## Access truth

Define the narrow production call boundary by which the claim engine receives slot-scoped targetability for the selected slot.

The production acceptance path must consume real/coherent ProductionTargetAccess-derived truth. Do not implement a second BFS, route heuristic or target sorter.

## Direct evidence

Add focused tests proving:

- unbound engine cannot claim;
- good coherent bind succeeds;
- second/mixed/foreign bind policy is deterministic and documented;
- exact dependency identity is preserved;
- empty five-slot engine yields no candidate batch;
- one occupied batch is visible to M25 only via read-only M24 query APIs;
- claim IDs and reservation owner IDs are unique/deterministic for identical replay history;
- detached claim snapshots cannot mutate engine truth.

## Boundaries

No target claim transaction is considered complete until WP02. No spawn, robot, scheduler or solver code here.
