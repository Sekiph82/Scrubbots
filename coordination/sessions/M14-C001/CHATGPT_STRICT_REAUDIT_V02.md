# M14-C001 — Strict Re-Audit V02

Decision: **CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

This supersedes the earlier M14 strict re-audit V01 verdict for current strict-v2 task truth. The earlier audit remains historical evidence.

Godot is not available in the ChatGPT audit environment. Existing Claude runtime results remain E1/E2; findings below come from independent current-source lifecycle/dependency inspection.

## Previously accepted architecture remains valid

- ReservationState remains separate from BoardState.
- BoardState CellState remains ACTIVE/CLEARED only.
- target -> owner and owner -> target uniqueness still use mirrored dictionaries.
- synchronous reserve/release ownership logic remains structurally sound.
- resolve_arrival() still removes reservation metadata only and does not clear BoardState.
- detached sorted reserved-index output remains intact.

## F-M14-STRICT-001 — malformed non-null BoardState dependency is accepted

Severity: **material dependency-boundary defect**

bind(board) checks only null. A malformed non-null object can be stored and marked bound, with the runtime fault deferred until reserve() calls BoardState APIs.

Required correction:
- validate the narrow required BoardState API before committing bind state;
- malformed bind must leave ReservationState unbound and stale refs unusable;
- direct non-null malformed dependency tests.

Affected:
- SB-M14-001
- SB-M14-004
- SB-M14-009

## F-M14-STRICT-002 — repeated bind silently destroys live reservation ownership

Severity: **material lifecycle defect**

bind(board) always clears both reservation maps.

Therefore:
1. bind(board)
2. reserve(target, owner)
3. accidental second bind(board)
4. reservation truth disappears silently

The class already has explicit destructive lifecycle APIs reset() and rebind(), so ordinary bind re-entry should not be an implicit reservation reset.

Required correction:
- define bind as initial/unbound binding only, or otherwise reject destructive re-entry;
- preserve explicit rebind() as the intentional board replacement path and reset() as the intentional reservation clear path;
- direct regression: reserve -> second bind -> reservation must not silently disappear;
- preserve rebind/reset clearing semantics.

Affected:
- SB-M14-001
- SB-M14-007
- SB-M14-009

## Strict task state

Reopen:
- SB-M14-001
- SB-M14-004
- SB-M14-007
- SB-M14-009

Other M14 task truth remains accepted.
