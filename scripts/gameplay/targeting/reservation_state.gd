extends RefCounted
## ReservationState — preload this script
## (res://scripts/gameplay/targeting/reservation_state.gd) rather than relying
## on global class_name lookup (AL-001).
##
## M14 — Reservation State. A SEPARATE ephemeral assignment layer (ADR-022).
##
## This class owns temporary target-assignment metadata ONLY: which future
## in-flight dispatch/agent assignment currently "owns" a given target cell.
## It is deliberately NOT part of the physical cell lifecycle. BoardState.
## CellState stays exactly ACTIVE/CLEARED (ADR-019); there is no RESERVED cell
## state. Reservation is assignment bookkeeping, not artwork/access state.
##
## Ownership contract:
##   - owner_id is a deterministic integer token (>= 0) standing for ONE future
##     dispatch/agent assignment. It is NOT a color id, slot id, or cell id.
##   - one target index has at most one owner;
##   - one owner_id holds at most one target at a time.
##
## "Atomic" here means synchronous check-and-set: reserve() validates, checks
## for conflict, and stores within one uninterrupted call — no await, no
## deferred mutation, no multi-step caller dance between check and store. Godot
## gameplay is main-thread/synchronous, so competing reserve() calls for the
## same target are serialized and exactly one wins.
##
## This class does NOT own reachability, target selection (M15), routing
## (M16+), agents/dispatch (M18/M19), or board mutation. resolve_arrival()
## clears only the reservation, never the BoardState cell — board mutation on
## successful cleaning is a later orchestration responsibility.
##
## ColorCandidateIndex (M13) stays reservation-agnostic: it never reads this
## class. Callers pass get_reserved_indices() as the excluded set into
## ColorCandidateIndex.get_candidates()/has_candidates().

## Explicit preload rather than global class_name lookup — AL-001.
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

## Production board-domain ceiling: 59x59 = 3481 cells (tasks.md §8.3). A bind
## whose get_cell_count() exceeds this is rejected WITHOUT any per-cell scan.
const MAX_CELL_COUNT := 3481

## Bound board (RefCounted BoardState) or null when unbound.
var _board = null
var _bound: bool = false
## Immutable bound-domain metadata: the board's get_cell_count() captured once
## at successful bind. Used only to reject out-of-domain targets BEFORE any
## per-index board call (F-M14-STRICT-001). 0 when unbound. Never a full scan.
var _cell_count: int = 0
## target_index (int) -> owner_id (int). One entry per active reservation.
var _target_to_owner: Dictionary = {}
## owner_id (int) -> target_index (int). Inverse of _target_to_owner; enforces
## one-target-per-owner in O(1).
var _owner_to_target: Dictionary = {}

## Matches the sibling-module convention: returns the real instance, typed as
## RefCounted because self-referential static typing is unreliable headless.
static func create() -> RefCounted:
	return load("res://scripts/gameplay/targeting/reservation_state.gd").new()

## Bind to a BoardState so reservations can be validated against live cell
## truth. Ordinary bind is INITIALIZATION-ONLY and UNBOUND-only
## (F-M14-STRICT-002): any bind() call while already bound returns false and
## makes zero destructive changes — board identity, bound status, reservation
## count and both ownership maps are all preserved. Use rebind() to
## deliberately replace the board, or reset() to clear reservations in place.
## A first bind fails closed (stays unbound, no domain claimed) unless the
## dependency is a canonical board (F-M14-STRICT-001).
func bind(board) -> bool:
	if _bound:
		return false
	return _try_bind(board)

## Explicit destructive board replacement. Drops any prior board AND all
## reservations FIRST, then attempts to bind the new board. On a malformed/null
## board the layer is left safely cleared+unbound (recoverable by a later valid
## bind/rebind); on success the new board's domain replaces the old one.
func rebind(board) -> bool:
	_board = null
	_bound = false
	_cell_count = 0
	_target_to_owner.clear()
	_owner_to_target.clear()
	return _try_bind(board)

func is_bound() -> bool:
	return _bound

## Exact-identity board coherence check (strict-v2, F-M15-STRICT-002). Returns
## true only when this layer is bound to the SAME BoardState INSTANCE (reference
## identity — not merely equal dimensions/content), false when unbound. It never
## exposes the internal board reference; a caller can only ask "are you bound to
## THIS board?", never obtain the board.
func is_bound_to(board) -> bool:
	return _bound and _board != null and _board == board

## Atomic check-and-set reservation. Returns false WITHOUT mutation when:
##   - unbound;
##   - target index invalid;
##   - target is not ACTIVE;
##   - owner_id invalid (< 0);
##   - target already reserved by any owner (incl. a same-owner duplicate);
##   - owner already holds a different target.
## No await/deferred gap between the checks and the stores.
func reserve(target_index: int, owner_id: int) -> bool:
	if not _bound or _board == null:
		return false
	if owner_id < 0:
		return false
	# Out-of-domain target is rejected against the stored bind-time count BEFORE
	# any per-index board call (F-M14-STRICT-001). Guarantees is_valid_index /
	# get_cell_state are never invoked for a target outside [0, count).
	if target_index < 0 or target_index >= _cell_count:
		return false
	# Live dependency truth must be well-typed; a malformed/contradictory return
	# fails closed WITHOUT erasing existing reservation ownership (M14 owns live
	# assignment metadata, unlike M13's derived cache).
	var valid = _board.is_valid_index(target_index)
	if typeof(valid) != TYPE_BOOL or valid != true:
		return false
	var state = _board.get_cell_state(target_index)
	if typeof(state) != TYPE_INT or state != BoardState.CellState.ACTIVE:
		return false
	# Target already owned (also rejects a same-owner duplicate reserve).
	if _target_to_owner.has(target_index):
		return false
	# Owner already holds a target (a different one, since the same target
	# would have been caught above).
	if _owner_to_target.has(owner_id):
		return false
	_target_to_owner[target_index] = owner_id
	_owner_to_target[owner_id] = target_index
	return true

func is_reserved(target_index: int) -> bool:
	return _target_to_owner.has(target_index)

## Owner id currently holding target_index, or -1 when unreserved/invalid.
func get_owner(target_index: int) -> int:
	return _target_to_owner.get(target_index, -1)

## Target index currently held by owner_id, or -1 when the owner holds none.
func get_target_for_owner(owner_id: int) -> int:
	return _owner_to_target.get(owner_id, -1)

## Ownership-safe release. Only the current owner of that target may release
## it. Wrong-owner or non-reserved release returns false and changes nothing.
## This is the API a future dispatcher uses to release a failed assignment.
func release(target_index: int, owner_id: int) -> bool:
	return _release_owned(target_index, owner_id)

## Release whatever target an owner holds (owner-keyed convenience). Returns
## false when the owner holds nothing.
func release_for_owner(owner_id: int) -> bool:
	if not _owner_to_target.has(owner_id):
		return false
	var target_index: int = _owner_to_target[owner_id]
	_target_to_owner.erase(target_index)
	_owner_to_target.erase(owner_id)
	return true

## Resolve a successful arrival: validate ownership and remove the reservation
## exactly once. Wrong owner / non-reserved target / second resolution returns
## false. Deliberately does NOT clear the BoardState cell, animate/dispatch a
## robot, choose another target, or generate a route — reservation bookkeeping
## only (see class doc / ADR-022).
func resolve_arrival(target_index: int, owner_id: int) -> bool:
	return _release_owned(target_index, owner_id)

## Clear every reservation deterministically, keeping the current board binding.
func reset() -> void:
	_target_to_owner.clear()
	_owner_to_target.clear()

func get_reservation_count() -> int:
	return _target_to_owner.size()

## Detached, ascending list of all reserved target indices. Returns a fresh
## PackedInt32Array every call, so callers cannot mutate internal state and can
## pass it straight to ColorCandidateIndex.get_candidates() as the excluded set.
func get_reserved_indices() -> PackedInt32Array:
	var keys: Array = _target_to_owner.keys()
	keys.sort()
	var out := PackedInt32Array()
	out.resize(keys.size())
	for i in keys.size():
		out[i] = keys[i]
	return out

# ------------------------------------------------------------- internals --

## Validate + install a board as the bound dependency, taking a one-shot domain
## snapshot. On success sets _board/_bound/_cell_count and clears the maps; on
## ANY validation failure returns false having mutated nothing. Shared by the
## unbound-only bind() and the destructive rebind().
func _try_bind(board) -> bool:
	if not _is_canonical_board(board):
		return false
	# Bind-time domain snapshot: one read, strictly typed, within production
	# bounds. Oversized/malformed counts are rejected here — no per-cell scan.
	var count = board.get_cell_count()
	if typeof(count) != TYPE_INT:
		return false
	if count < 0 or count > MAX_CELL_COUNT:
		return false
	_board = board
	_bound = true
	_cell_count = count
	_target_to_owner.clear()
	_owner_to_target.clear()
	return true

## Fail-closed dependency category check (AL-040): a non-null Variant is not
## enough. The canonical BoardState is RefCounted, so a method-compatible Node
## (externally freeable lifecycle) is rejected on category alone, and every
## scalar/non-object Variant fails the RefCounted test before any has_method
## call. Requires the complete narrow M14 board API.
func _is_canonical_board(board) -> bool:
	if not (board is RefCounted):
		return false
	return board.has_method("get_cell_count") \
		and board.has_method("is_valid_index") \
		and board.has_method("get_cell_state")

## Shared ownership-checked removal for release()/resolve_arrival(). Removes
## the reservation only when target_index is currently reserved by exactly
## owner_id. O(1).
func _release_owned(target_index: int, owner_id: int) -> bool:
	if not _target_to_owner.has(target_index):
		return false
	if _target_to_owner[target_index] != owner_id:
		return false
	_target_to_owner.erase(target_index)
	_owner_to_target.erase(owner_id)
	return true
