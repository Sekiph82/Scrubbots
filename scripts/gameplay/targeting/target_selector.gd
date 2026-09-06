extends RefCounted
## TargetSelector — preload this script
## (res://scripts/gameplay/targeting/target_selector.gd) rather than relying on
## global class_name lookup (AL-001).
##
## M15 — TargetSelector. Decides WHAT target a Scrubbot assignment gets, and
## atomically reserves it, in ONE synchronous call. It never decides HOW a bot
## travels there — that is RoutingSystem (M16+) and must stay a separate module
## (CLAUDE.md hard rule 14, ADR separation below).
##
## Canonical separation this class relies on:
##   ColorCandidateIndex (M13) -> raw ACTIVE matching-color candidates, no
##                                reachability claim (AL-028).
##   ReservationState    (M14) -> atomic assignment ownership (ADR-022).
##   access_query (injected)   -> authoritative "is this target currently
##                                reachable/targetable?" truth. M15 consumes it;
##                                it does NOT compute route geometry, run AStar,
##                                inspect route points, or invent topology.
##   TargetSelector      (M15) -> chooses WHICH reachable candidate and reserves.
##
## A raw color candidate is NOT a reachable final target (AL-028). A matching
## ACTIVE cell can be fully enclosed by other ACTIVE cells with no legal access.
## The selector therefore never assumes a candidate is reachable: it asks the
## injected access_query, and FAILS CLOSED (returns -1) when no valid query is
## supplied. It never selects a blocked/unreachable matching-color ACTIVE cell.
##
## BoardState is used for narrow final truth checks only (is_valid_index /
## get_cell_state / get_color_id) so stale/corrupt upstream candidate data can
## never make the selector return an invalid, CLEARED, or wrong-color target.
## It never scans the whole board, duplicates board arrays, mutates BoardState,
## re-derives index math, or owns the ACTIVE/CLEARED lifecycle.
##
## Selection + reservation are one operation to avoid a race-prone
## choose()->gap->reserve() caller sequence. Godot gameplay is main-thread /
## synchronous, so competing select_and_reserve() calls serialize and exactly
## one wins a contested target (ReservationState.reserve() is the final gate).

## Explicit preload rather than global class_name lookup — AL-001.
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

## Bound dependencies, or null when unbound.
var _board = null
var _candidate_index = null
var _reservations = null
var _bound: bool = false

## Matches the sibling-module convention: returns the real instance, typed as
## RefCounted because self-referential static typing is unreliable headless.
static func create() -> RefCounted:
	return load("res://scripts/gameplay/targeting/target_selector.gd").new()

## Bind the three narrow dependencies. Returns false (and stays unbound) if any
## is null. The access_query is NOT bound here — it is passed per call, because
## reachability truth is call-time state supplied by the caller.
func bind(board, candidate_index, reservation_state) -> bool:
	if board == null or candidate_index == null or reservation_state == null:
		_bound = false
		return false
	_board = board
	_candidate_index = candidate_index
	_reservations = reservation_state
	_bound = true
	return true

func is_bound() -> bool:
	return _bound

## Choose the first targetable candidate in ascending row-major candidate order
## and atomically reserve it for owner_id, all inside this one synchronous call.
##
## Returns the selected/reserved target index on success, or -1 on any
## no-target / invalid-call / failed-assignment condition:
##   - unbound / missing dependency;
##   - access_query missing or lacking is_targetable() -> fail closed;
##   - owner_id < 0 or color_id < 0;
##   - owner already holds a reservation;
##   - no raw candidates, or all reserved / CLEARED / invalid / wrong-color;
##   - all matching ACTIVE candidates blocked/unreachable;
##   - every reservation attempt lost to a competing synchronous assignment.
##
## No exception, no dispatch, no route request, no board mutation.
func select_and_reserve(color_id: int, owner_id: int, access_query) -> int:
	if not _bound or _board == null or _candidate_index == null or _reservations == null:
		return -1
	# Fail closed: never assume reachability without an authoritative query.
	if access_query == null or not access_query.has_method("is_targetable"):
		return -1
	if owner_id < 0:
		return -1
	if color_id < 0:
		return -1
	# One target per owner: an owner already holding a reservation gets nothing.
	if _reservations.get_target_for_owner(owner_id) != -1:
		return -1

	# Raw ascending candidates minus already-reserved targets. ColorCandidateIndex
	# returns a detached, row-major-ordered copy; we never mutate its truth.
	var excluded: PackedInt32Array = _reservations.get_reserved_indices()
	var candidates: Array = _candidate_index.get_candidates(color_id, excluded)

	for idx in candidates:
		# Narrow final validation against live BoardState truth (guards stale
		# upstream candidate data — AL-028 / prompt step order).
		if not _board.is_valid_index(idx):
			continue
		if _board.get_cell_state(idx) != BoardState.CellState.ACTIVE:
			continue
		if _board.get_color_id(idx) != color_id:
			continue
		if _reservations.is_reserved(idx):
			continue
		# Authoritative reachability/access truth — blocked cells are skipped.
		if not access_query.is_targetable(idx):
			continue
		# Atomic ownership gate. If it loses to a competing synchronous
		# assignment that grabbed this target between the checks above and here,
		# the owner still holds nothing, so continue to the next candidate.
		if _reservations.reserve(idx, owner_id):
			return idx

	return -1
