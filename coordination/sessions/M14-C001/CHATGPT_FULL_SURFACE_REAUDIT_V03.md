# M14-C001 — Full Attack-Surface Strict Re-Audit V03

Decision: **CHANGES_REQUIRED / FINDING_SET_FROZEN**

This is the canonical current strict-v2 correction basis for M14 and supersedes
the narrower correction scope in CHATGPT_STRICT_REAUDIT_V02.md. Historical V01
and strict V01/V02 evidence remain preserved.

The locked full attack-surface rule in coordination/AUDIT_POLICY.md requires a
complete subsystem/public-API sweep before implementation.

## Current subsystem

Production:
`scripts/gameplay/targeting/reservation_state.gd`

Immediate consumers:
- ColorCandidateIndex exclusion seam;
- TargetSelector;
- later dispatcher lifecycle.

## Sweep scope

ChatGPT independently inspected:
- current ReservationState source;
- complete current M14 tests and integration/performance blocks;
- prior M14 V01 prompt/log/audit;
- strict re-audits V01/V02;
- M14 canonical task ledger;
- current TargetSelector consumer;
- current ColorCandidateIndex exclusion contract;
- current BoardState;
- FOUNDATION-STRICT-001;
- relevant locked audit learnings including AL-040, AL-050, AL-053, AL-058 and
  AL-059.

Godot is unavailable in the ChatGPT audit environment. Existing runtime results
remain E1/E2. Findings below are E3 current-source/contract evidence.

## Public surface reviewed

- create();
- bind(board);
- rebind(board);
- is_bound();
- is_bound_to(board);
- reserve(target_index, owner_id);
- is_reserved(target_index);
- get_owner(target_index);
- get_target_for_owner(owner_id);
- release(target_index, owner_id);
- release_for_owner(owner_id);
- resolve_arrival(target_index, owner_id);
- reset();
- get_reservation_count();
- get_reserved_indices().

Attack classes considered:
- null/scalar/non-object dependency;
- plain RefCounted;
- method-compatible Node lifecycle;
- partial API;
- malformed get_cell_count;
- count min/max/over-max;
- malformed live is_valid_index/get_cell_state return;
- unknown/noncanonical cell state;
- repeated bind same/different/null/malformed;
- destructive rebind same/different/null/malformed;
- duplicate target/owner;
- wrong-owner release/arrival;
- release_for_owner;
- reset;
- repeated arrival/release;
- mirrored-map consistency;
- detached reserved-index aliasing;
- invalid scalar IDs;
- 59x59 production maximum;
- immediate M13/M15 consumer assumptions.

## Frozen findings

### F-M14-STRICT-001 — BoardState dependency contract is not fail-closed

Retained from CHATGPT_STRICT_REAUDIT_V02 and expanded by the current full-surface
sweep.

Current bind(board) rejects null only, then stores any non-null Variant and marks
the layer bound.

Consequences:
- scalar/non-object or partial API dependencies can be accepted;
- method-compatible Node lifecycle can be accepted even though canonical
  BoardState is RefCounted;
- reserve() may later fault on is_valid_index/get_cell_state;
- bind does not validate a canonical board cell-count domain;
- reserve relies on unvalidated live return types.

Required dependency contract:

#### Lifecycle category
Canonical BoardState is RefCounted. Prefer:
- RefCounted + narrow required API;
- reject Node even if method-compatible.

Narrow M14 board API:
- get_cell_count();
- is_valid_index(index);
- get_cell_state(index).

#### Bind-time domain snapshot
On an UNBOUND ReservationState, successful bind must:
- validate get_cell_count return is TYPE_INT;
- accept count in [0, 3481];
- reject negative;
- reject >3481;
- store the validated count as immutable bound-domain metadata.

The stored count is used only for target-domain validation. ReservationState
must not full-scan the board.

#### reserve-time live truth
reserve() must:
- reject owner_id < 0;
- reject target outside stored [0,count) before board per-index calls;
- call is_valid_index only for a target inside stored domain;
- require TYPE_BOOL true;
- boolean false for an in-domain target is dependency contradiction and must
  fail without reservation mutation;
- require get_cell_state to return TYPE_INT;
- accept reservation only for exactly ACTIVE;
- CLEARED -> false;
- unknown states 2/-1/255/99 -> false;
- non-int state -> false;
- every dependency validation failure must preserve existing reservation
  ownership maps.

Unlike M13's derived cache, M14 owns live assignment metadata. A dependency fault
must NOT silently erase existing reservations. The safe M14 policy is:
- reject the new reserve;
- preserve mirrored ownership truth;
- preserve the current binding unless an explicit rebind/reset occurs.

This distinction is intentional.

#### Domain maximum
3481 is the production ceiling (59x59). 3482/huge counts must fail at bind
without per-cell traversal.

### F-M14-STRICT-002 — repeated ordinary bind silently destroys live ownership

Retained from CHATGPT_STRICT_REAUDIT_V02.

Current bind() clears both maps on every successful call.

Therefore:
```text
bind(board A)
reserve(target, owner)
bind(board A or board B)
=> reservation silently disappears
```

This is unacceptable because ReservationState already provides explicit
destructive APIs:
- reset() clears reservations while keeping board binding;
- rebind() intentionally replaces board and clears old reservation truth.

Required:
- ordinary bind is UNBOUND-only;
- ANY bind call while already bound returns false and preserves:
  - exact board identity;
  - bound status;
  - all target->owner truth;
  - all owner->target truth;
  - reservation count;
  - reserved-index snapshot.

Direct re-entry cases:
- same valid board;
- different valid board;
- null;
- scalar;
- partial/malformed compatible dependency.

Explicit rebind remains destructive:
- valid rebind clears old maps and installs new board/domain;
- rebind same board may intentionally clear maps;
- rebind(null) clears old maps and leaves unbound;
- malformed rebind clears old maps and leaves unbound;
- later valid bind/rebind can recover.

## Accepted / not reopened

### Mirrored ownership model
Current dictionary structure correctly represents:
- one target -> at most one owner;
- one owner -> at most one target.

No mutable dictionary references are exposed.

### Core release behavior
Current source structurally:
- rejects wrong-owner release;
- removes both mirrored entries on correct release;
- release_for_owner removes both directions;
- resolve_arrival delegates to ownership-safe release;
- repeated release/arrival returns false after first removal.

release_for_owner lacks direct M14 V01 coverage, so it must be added to strict
validation even though no source defect is currently identified.

### reset/rebind architecture
reset() intentionally clears both maps while retaining binding.
rebind() is intentionally destructive. These semantics remain accepted, but
malformed/null rebind and exact board-identity transitions require direct strict
tests.

### Query/encapsulation
- is_reserved/get_owner/get_target_for_owner are scalar dictionary queries;
- get_reserved_indices returns a sorted detached PackedInt32Array;
- no mutable map leak found.

Invalid negative/large query IDs should be directly regression-tested for stable
false/-1/no-mutation behavior.

### Reservation versus BoardState
ReservationState remains separate metadata.
BoardState remains ACTIVE/CLEARED only.
resolve_arrival must not mutate BoardState.
FOUNDATION-STRICT-001 remains separate.

M14 must nevertheless reject unknown/noncanonical state values from a compatible
test dependency during reserve.

### Performance
Normal ownership/query operations remain dictionary-based and do not full-scan
the board. Bind may read get_cell_count once; reserve may inspect one target.
No hardware timing threshold is required.

### Scope
M14 owns reservation bookkeeping only:
- no candidate indexing;
- no reachability;
- no target selection;
- no routing;
- no agent/dispatcher behavior;
- no board clearing.

## Frozen M14 finding set

Frozen to:
- F-M14-STRICT-001
- F-M14-STRICT-002

Affected open tasks remain:
- SB-M14-001
- SB-M14-004
- SB-M14-007
- SB-M14-009

No other M14 task is reopened.

Next:
`coordination/sessions/M14-C001/CHATGPT_PROMPT_V02.md`
