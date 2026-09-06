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

## Bound board (RefCounted BoardState) or null when unbound.
var _board = null
var _bound: bool = false
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
## truth. Starts with no reservations. Returns false (stays unbound) for null.
func bind(board) -> bool:
	if board == null:
		return false
	_board = board
	_bound = true
	_target_to_owner.clear()
	_owner_to_target.clear()
	return true

## Discard any prior board AND all reservations, then bind to a fresh board.
## Prevents stale reservations from an old board leaking into the new one.
## Returns false and leaves the layer cleared+unbound if the new board is null.
func rebind(board) -> bool:
	_board = null
	_bound = false
	_target_to_owner.clear()
	_owner_to_target.clear()
	return bind(board)

func is_bound() -> bool:
	return _bound

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
	if not _board.is_valid_index(target_index):
		return false
	if _board.get_cell_state(target_index) != BoardState.CellState.ACTIVE:
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
