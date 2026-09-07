# M13-C001 — Strict Re-Audit V01

Decision: **CHANGES_REQUIRED / STRICT_VALIDATION_OPEN**

Strict-v2 inspection of ColorCandidateIndex.

The cache/no-full-board-rescan design remains accepted. Godot is not available in the ChatGPT audit environment; existing runtime totals remain E1/E2.

## F-M13-STRICT-001 — malformed non-null BoardState can be accepted before first method call

Severity: **material dependency-boundary defect**

bind(board) currently checks only null, then stores _board, sets _bound = true, and calls _rebuild_internal().

A non-null malformed dependency can therefore transition the index into bound state before the first missing BoardState method call faults.

Required correction:
- validate only the narrow BoardState API required by M13 before storing the dependency or setting bound truth;
- malformed bind must leave the object unbound with no stale usable refs;
- direct non-null malformed dependency regression.

Affected:
- SB-M13-001
- SB-M13-004

## F-M13-STRICT-002 — unknown cell state is silently treated as CLEARED

Severity: **state-coherence robustness defect**

sync_cell() currently implements ACTIVE -> add, else -> remove.

That silently maps any future/corrupt non-canonical state to CLEARED semantics.

Required correction:
- ACTIVE -> add;
- CLEARED -> remove;
- any other state -> fail closed / no mutation;
- direct adversarial test proving an unknown state cannot silently mutate candidate membership.

Affected:
- SB-M13-001
- SB-M13-004

## Strict task state

Reopen:
- SB-M13-001
- SB-M13-004

The remaining M13 cache, exclusion, deterministic ordering and 3,481-cell task truth remains accepted.
