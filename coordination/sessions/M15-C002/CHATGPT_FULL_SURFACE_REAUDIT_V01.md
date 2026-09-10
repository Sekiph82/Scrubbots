# M15-C002 — TargetSelector Full-Surface Strict Re-Audit V01

Decision: **CHANGES_REQUIRED / FINDING_SET_FROZEN / UPSTREAM_GATE_FOR_M19**

This cycle is opened by the independent M19-C001 V03 audit. It does not invalidate historical M15-C001 work wholesale; it addresses newly exposed strict-v2 boundary and lifecycle classes in current TargetSelector.

Production:
`scripts/gameplay/targeting/target_selector.gd`

Immediate consumers:
- M19 ScrubbotDispatcher;
- ReservationState;
- ColorCandidateIndex;
- injected targetability/access truth.

## Full public surface reviewed

- create();
- bind(board, candidate_index, reservation_state);
- is_bound();
- is_bound_to(board, reservation_state);
- select_and_reserve(color_id, owner_id, access_query).

Attack classes:
- null/scalar/non-object/method-compatible Node dependencies;
- wrong return types from coherence/query methods;
- stale/rebound candidate/reservation dependencies;
- arbitrary access_query Variant;
- non-bool targetability verdict;
- malformed candidate container / entries;
- malformed reservation snapshots/results;
- rebind during candidate/access/reservation callback;
- same-owner/different-owner contention;
- successful reserve without exact ownership proof;
- rollback after dependency drift;
- deterministic/no-routing/no-board-mutation boundaries.

## Frozen findings

### F-M15-STRICT-004 — dependency and Variant-return boundaries are not fully fail-closed

Current bind validates only method names and can call `has_method()` on a scalar Variant. Canonical production dependencies are RefCounted/BoardState lifecycle objects.

Required bind boundary:
- board must be a real BoardState;
- candidate_index must be RefCounted + `get_candidates`, `is_bound_to`;
- reservation_state must be RefCounted + `reserve`, `release`, `get_target_for_owner`, `get_owner`, `get_reserved_indices`, `is_reserved`, `is_bound_to`;
- method-compatible Nodes rejected;
- coherence methods must return actual TYPE_BOOL true;
- malformed bind fails closed according to existing neutralization semantics.

Current per-call access boundary also null-checks then calls `has_method()` on arbitrary Variant.

Required access_query:
- RefCounted;
- has `is_targetable`;
- scalar/String/Vector2/Array/Dictionary/Node fail closed to -1;
- targetability verdict accepted only on actual TYPE_BOOL true;
- non-bool falsey/truthy values never count as reachable.

Dynamic collaborator returns must be validated before typed assignment/use:
- `get_target_for_owner` -> TYPE_INT;
- `get_reserved_indices` -> PackedInt32Array;
- `get_candidates` -> Array;
- every candidate entry -> TYPE_INT before BoardState calls;
- `is_reserved` -> TYPE_BOOL;
- `reserve` -> TYPE_BOOL;
- `get_owner` -> TYPE_INT when ownership is verified.

Malformed return => stable -1/no mutation/no runtime fault.

### F-M15-STRICT-005 — one selection operation is not protected from dependency drift/rebind during callbacks

TargetSelector is stateful. `select_and_reserve()` calls external collaborators during the operation.

Current code can continue after those callbacks without proving that its binding/dependencies are still the same operation snapshot.

The critical adversary:
1. selector starts bound to board/candidate/reservation A;
2. `access_query.is_targetable()` synchronously rebinds selector, candidate index, or ReservationState;
3. selector continues into reserve using mutated fields;
4. reservation can occur in a foreign bundle.

Required operation contract:
- capture immutable operation snapshot/version at select entry;
- bind/rebind of TargetSelector during an active selection must fail closed and preserve the active operation's original binding;
- after every external collaborator boundary that precedes reservation/return-success, verify selector binding version/identity is unchanged and original candidate/reservation dependencies remain exact-bound to original board;
- at minimum re-check after initial coherence calls, owner query, reserved snapshot, candidate query, `is_reserved`, `is_targetable`, and `reserve`;
- never reserve through a different board/bundle than the one captured at operation start.

On `reserve()` true:
- verify exact ownership before returning target:
  - owner -> target;
  - target -> owner;
- if operation drift happened during reserve and this operation created an ownership entry, release that exact entry before returning -1;
- do not delete an unrelated pre-existing/competing reservation.

Preserve existing accepted contention law:
- a same-owner side effect that independently reserves another target causes selector to stop and return -1 while preserving that external reservation;
- different-owner contention may continue to the next candidate.

## Accepted / preserve

- deterministic candidate-order strategy;
- color match;
- ACTIVE-only target;
- blocked/unreachable candidate skipped;
- one target per owner;
- no routing/path generation;
- no BoardState mutation;
- no candidate-index mutation;
- no full-board scan;
- 59x59 and rectangular behavior;
- read-only `is_bound_to(board, reservation_state)` exact identity seam used by M19.

## Frozen set

Exactly:
- F-M15-STRICT-004
- F-M15-STRICT-005

No other M15 finding ID is opened in this sweep.

Task disposition remains auditor-owned. Root M15 task checkboxes are not changed before runtime/correction audit.

M19-C001 V03 remains open/blocked until this gate independently passes.
