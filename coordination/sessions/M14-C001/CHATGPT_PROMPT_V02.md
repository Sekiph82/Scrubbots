# M14-C001 — Frozen Full-Surface Reservation Closure V02

Status: **ISSUED — FINDING SET FROZEN**

Execute ONLY this V02 correction.

Read:
- coordination/AUDIT_POLICY.md
- coordination/AUDIT_INDEX.md
- coordination/VERSIONED_LOG_POLICY.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/sessions/M14-C001/CHATGPT_FULL_SURFACE_REAUDIT_V03.md
- coordination/sessions/M14-C001/CHATGPT_STRICT_REAUDIT_V02.md
- prior M14 V01 artifacts
- this prompt + V02 criteria

Expected log:
`coordination/sessions/M14-C001/CLAUDE_LOG_V02.md`

Fix ONLY:
- F-M14-STRICT-001
- F-M14-STRICT-002

Do not modify BoardState.
Do not implement M15+ behavior.

## 1. Harden the BoardState dependency boundary

Canonical accepted dependency category:
- RefCounted;
- complete narrow M14 API:
  - get_cell_count();
  - is_valid_index(index);
  - get_cell_state(index).

Reject before committing bind:
- int;
- String;
- Vector2;
- Dictionary/Array if supplied as board;
- plain RefCounted without API;
- partial API RefCounted;
- Node without API;
- method-compatible Node.

Do not call has_method on unsupported scalar/non-object Variants.

### Bind-time count snapshot

For an UNBOUND instance:
- read get_cell_count once;
- require TYPE_INT;
- require 0 <= count <= 3481;
- store it as bound-domain metadata together with board/bound state;
- no board full scan.

Direct tests:
- count "4" -> fail;
- count -1 -> fail;
- count 0 -> allowed, no reservations possible;
- count 3481 -> allowed;
- count 3482 -> fail;
- count 1,000,000 -> fail;
- very large positive -> fail.

Oversized rejection must happen without is_valid_index/get_cell_state calls.
Use a counting RefCounted double.

Every failed initial bind:
- false;
- unbound;
- reservation count 0;
- reserved indices empty;
- no board identity claim.

## 2. Make ordinary bind strictly UNBOUND-only

This finding protects live ownership.

After a successful bind, EVERY subsequent bind() call must:
- return false;
- make zero destructive ownership changes;
- keep the original board binding and count/domain;
- preserve every target->owner and owner->target mapping.

Direct repeated-bind matrix after creating at least two reservations:
- bind(same board);
- bind(different valid board);
- bind(null);
- bind(int/scalar);
- bind(partial RefCounted);
- bind(method-compatible Node).

After EACH attempt prove:
- is_bound true;
- is_bound_to(original board) true;
- is_bound_to(other board) false;
- exact reservation count unchanged;
- each target owner unchanged;
- each owner target unchanged;
- exact sorted reserved indices unchanged.

Do not make same-board bind idempotently clear or silently succeed.
Ordinary bind is initialization only.

## 3. Preserve explicit destructive rebind

rebind() is the intentional board-replacement API.

Direct cases:

### valid board B
From board A with live reservations:
- rebind(B) succeeds;
- all A reservations cleared;
- bound to B only;
- new B count/domain installed;
- old target ownership absent;
- valid B reservation works.

### same board
- rebind(same board) may intentionally clear all reservations;
- remains bound to same board;
- count/domain valid.

### null
From live A state:
- rebind(null) returns false;
- old reservations cleared;
- unbound;
- no board identity;
- domain metadata reset;
- later valid bind/rebind recovers.

### malformed
Use scalar/partial/oversized compatible RefCounted:
- rebind returns false;
- leaves safe unbound/empty;
- no malformed board stored;
- later valid bind/rebind recovers.

## 4. Harden reserve() live return contract

Use the stored count before any per-target board call.

### Healthy caller invalid target
After valid count N:
- target -1;
- target == N;
- target much larger.

Required:
- reserve false;
- no is_valid_index/get_cell_state call for out-of-domain target if using a
  counting double;
- existing reservations unchanged.

### is_valid_index
For in-domain target:
- TYPE_BOOL true -> continue;
- TYPE_BOOL false -> reserve false, ownership unchanged;
- non-bool -> reserve false, ownership unchanged.

Do not erase live reservations on dependency validation failure.

### get_cell_state
For in-domain + valid index:
- ACTIVE -> may reserve when ownership free;
- CLEARED -> false;
- 2 -> false;
- -1 -> false;
- 255 -> false;
- 99 -> false;
- float/String/Object return -> false.

Every failed state check:
- no new reservation;
- existing maps unchanged;
- no runtime fault.

This is M14 fail-closed behavior. Do not modify BoardState to manufacture a new
canonical state.

## 5. Prove mirrored-map invariants through every mutation API

Directly cover:

### reserve
- valid reserve inserts both directions;
- duplicate target other owner fails;
- duplicate target same owner fails;
- same owner second target fails;
- independent owners on independent targets succeed;
- failures preserve both maps.

### release
- wrong owner fails/no mutation;
- correct owner removes both directions;
- released target and owner become reusable;
- repeated release fails/no mutation.

### release_for_owner
Add direct strict coverage:
- unknown owner false/no mutation;
- valid owner removes exactly its target from both maps;
- sibling reservations unchanged;
- repeated release_for_owner false;
- released target/owner reusable.

### resolve_arrival
- wrong owner false/no mutation;
- correct owner removes exactly once;
- second resolve false;
- no BoardState cell mutation.

### reset
- clears every reservation;
- keeps board binding/domain;
- second reset harmless;
- reserve works after reset.

## 6. Query/encapsulation regression

Directly prove:
- is_reserved negative/large -> false;
- get_owner negative/large/unreserved -> -1;
- get_target_for_owner negative/unknown -> -1;
- get_reservation_count exact after mixed operations;
- get_reserved_indices ascending;
- every call returns detached PackedInt32Array;
- mutate/clear/append snapshot cannot alter internal maps;
- no public getter exposes internal dictionaries.

## 7. M13 and M15 immediate-consumer regression

Preserve:
- ReservationState.get_reserved_indices() remains PackedInt32Array;
- passing it to ColorCandidateIndex excludes reserved raw candidates;
- release/release_for_owner restores candidate visibility on next snapshot;
- ColorCandidateIndex owns no reservation state.

Run existing M15 root regressions to prove:
- is_bound_to exact board identity remains compatible;
- reserve/get_target_for_owner/get_reserved_indices/is_reserved APIs remain
  compatible with TargetSelector.

Do not move target selection into M14.

## 8. 59x59 and no-scan structural regression

Directly cover real 59x59 / 3481 BoardState:
- bind succeeds;
- reserve/release works;
- no board full scan is introduced into reserve/release/query operations.

Use call-count structural evidence where useful. CPU timing is informational
only, never an FPS/GPU claim or hardware threshold.

## 9. Architecture boundaries

Preserve:
- ReservationState RefCounted;
- BoardState CellState exactly ACTIVE/CLEARED;
- reservation metadata separate from BoardState;
- no board mutation by release/resolve/reset;
- no candidate ownership;
- no reachability;
- no TargetSelector implementation;
- no routing;
- no agent/dispatcher;
- no M15+ responsibility.

FOUNDATION-STRICT-001 remains separate and unresolved in this M14 cycle.

## Governance

Do NOT modify:
- tasks.md
- .hiveai/*
- coordination/SESSION_INDEX.md
- coordination/AUDIT_INDEX.md
- coordination/STRICT_FOUNDATION_REPAIR_QUEUE_V01.md
- coordination/STRICT_UPSTREAM_REPAIR_SEQUENCE_V01.md
- any CHATGPT_* file
- scripts/gameplay/board/board_state.gd

Run and record separately:
- godot --version
- full root headless suite
- git diff --check

Write:
`coordination/sessions/M14-C001/CLAUDE_LOG_V02.md`

Commit/push safely.

Return exactly:
`AWAITING_AUDIT`

Then STOP.
