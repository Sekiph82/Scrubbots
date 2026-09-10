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
## Monotonic bind generation. Incremented on every successful bind so an active
## select operation can prove the selector was not rebound underneath it
## (F-M15-STRICT-005 snapshot token).
var _bind_generation: int = 0
## True only while select_and_reserve() is running. Guards bind() and nested
## select_and_reserve() against re-entrant callbacks that would otherwise move
## the selector to a foreign bundle or start a second transaction mid-selection
## (F-M15-STRICT-005.A/.B). Armed BEFORE the first external coherence callback.
var _in_selection: bool = false
## True only while bind() is validating/committing. Guards bind() against a
## re-entrant bind triggered by a candidate/reservation is_bound_to() callback
## during the outer bind's own coherence checks (F-M15-STRICT-005.G).
var _in_bind: bool = false

## Matches the sibling-module convention: returns the real instance, typed as
## RefCounted because self-referential static typing is unreliable headless.
static func create() -> RefCounted:
	return load("res://scripts/gameplay/targeting/target_selector.gd").new()

## Narrow required API surfaces (strict-v2, F-M15-STRICT-001): bind validates that
## each non-null dependency actually implements the methods M15 uses, so a
## malformed double fails closed at the boundary instead of erroring mid-select.
const _CANDIDATE_API := ["get_candidates", "is_bound_to"]
## Full reservation API M15 depends on, incl. release/get_owner used by the
## post-reserve ownership proof and exact-entry rollback (F-M15-STRICT-004/005).
const _RESERVATION_API := ["reserve", "release", "get_target_for_owner", "get_owner", "get_reserved_indices", "is_reserved", "is_bound_to"]

## Bind the three narrow dependencies. Fails closed (returns false, stays UNBOUND,
## clears any prior refs) when:
##   - the board is not a real BoardState (F-M15-STRICT-004: category, not just
##     method-name compatibility — a method-compatible Node is rejected);
##   - the candidate index / reservation state are not RefCounted objects
##     exposing the full narrow required API;
##   - the candidate index / reservation state are not exact-bound to the SAME
##     BoardState instance passed here, proven by an ACTUAL bool-true is_bound_to
##     (F-M15-STRICT-002/004: a non-bool true-ish value does not pass).
## The access_query is NOT bound here — it is passed per call, because
## reachability truth is call-time state supplied by the caller.
##
## While a select_and_reserve() operation is active, bind() fails closed WITHOUT
## touching the active operation's binding (F-M15-STRICT-005): a re-entrant bind
## from an access/candidate/reservation callback cannot move the selector to a
## different bundle.
func bind(board, candidate_index, reservation_state) -> bool:
	# Re-entrant bind during an active selection OR an outer bind transaction is
	# refused and preserves the current binding untouched (no _clear_binding, no
	# field change) — a callback cannot overwrite the requested bundle
	# (F-M15-STRICT-005.A/.G).
	if _in_selection or _in_bind:
		return false
	# Arm the bind transaction guard BEFORE the is_bound_to() coherence callbacks
	# inside validation, so a nested bind from either callback returns false and
	# cannot commit ahead of / over the outer bind.
	_in_bind = true
	var ok := _bind_validate_and_commit(board, candidate_index, reservation_state)
	_in_bind = false
	return ok

## Validate the requested bundle and commit it, or neutralize on any failure.
## Runs inside the _in_bind transaction guard.
func _bind_validate_and_commit(board, candidate_index, reservation_state) -> bool:
	if not (board is BoardState) \
			or not (candidate_index is RefCounted) or not _has_methods(candidate_index, _CANDIDATE_API) \
			or not (reservation_state is RefCounted) or not _has_methods(reservation_state, _RESERVATION_API) \
			or not _bool_true(candidate_index.is_bound_to(board)) \
			or not _bool_true(reservation_state.is_bound_to(board)):
		# Any failure neutralizes prior state so stale deps cannot be reused.
		_clear_binding()
		return false
	_board = board
	_candidate_index = candidate_index
	_reservations = reservation_state
	_bound = true
	_bind_generation += 1
	return true

func _clear_binding() -> void:
	_board = null
	_candidate_index = null
	_reservations = null
	_bound = false

static func _has_methods(obj, names) -> bool:
	for n in names:
		if not obj.has_method(n):
			return false
	return true

## Strict truthiness: only an ACTUAL TYPE_BOOL true passes. A non-bool true-ish
## value (int 1, "x", an object, …) never counts as approval (F-M15-STRICT-004).
static func _bool_true(v) -> bool:
	return typeof(v) == TYPE_BOOL and v == true

func is_bound() -> bool:
	return _bound

## Read-only exact-identity coherence check (strict-v2, F-M19-STRICT-001). Returns
## true only when this selector is bound to the SAME BoardState INSTANCE and the
## SAME ReservationState INSTANCE the caller supplies (reference identity, not
## equal dimensions/content), false when unbound. It lets a dispatcher prove the
## selector shares its exact board+reservation bundle, so the selector can never
## reserve through a different-board ReservationState than the one the dispatcher
## later releases through (AL-062). It changes NO selection semantics and never
## exposes the internal references.
func is_bound_to(board, reservation_state) -> bool:
	return _bound and _board != null and _board == board \
		and _reservations != null and _reservations == reservation_state

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
##
## strict-v2 second stage (F-M15-STRICT-004/005): every dynamic collaborator
## return is validated before typed use, the injected access_query is category-
## and verdict-checked, and the whole operation runs against an immutable
## snapshot of (board, candidate index, reservation state, bind generation)
## captured at entry. Any drift/rebind detected after a collaborator boundary
## fails the operation closed (-1) and never reserves through a foreign bundle.
func select_and_reserve(color_id: int, owner_id: int, access_query) -> int:
	# Reject re-entrant selection immediately, BEFORE any collaborator callback and
	# with zero mutation:
	#   - during an active selection: a nested select_and_reserve() injected from a
	#     targetability/candidate/reservation callback returns -1 (F-M15-STRICT-005.B);
	#   - during a bind transaction: a nested select injected from a bind-time
	#     candidate/reservation is_bound_to() callback returns -1 so it can never run
	#     against the OLD bundle and leave an orphan reservation while the outer
	#     bind is mid-commit (F-M15-STRICT-005.H).
	if _in_selection or _in_bind:
		return -1
	if not _bound or _board == null or _candidate_index == null or _reservations == null:
		return -1
	# access_query boundary (F-M15-STRICT-004): must be a RefCounted exposing
	# is_targetable. `is RefCounted` short-circuits BEFORE any has_method call, so
	# a scalar/String/Vector2/Array/Dictionary never reaches has_method and a
	# method-compatible Node is rejected on category. (Pure local checks — no
	# collaborator call — so they run before the guard is armed.)
	if not (access_query is RefCounted) or not access_query.has_method("is_targetable"):
		return -1
	if owner_id < 0:
		return -1
	if color_id < 0:
		return -1
	# Immutable operation snapshot (F-M15-STRICT-005).
	var board = _board
	var ci = _candidate_index
	var rs = _reservations
	var gen := _bind_generation
	# Arm the operation guard BEFORE the first external coherence callback, so a
	# nested bind() from the INITIAL candidate/reservation is_bound_to() callback
	# is refused and cannot move the bundle (F-M15-STRICT-005.A). Every exit from
	# _select_core clears the guard through this one deterministic path, so an
	# initial-coherence failure never leaves the selector stuck busy.
	_in_selection = true
	var result := _select_core(color_id, owner_id, access_query, board, ci, rs, gen)
	_in_selection = false
	return result

## True only when the ORIGINAL operation snapshot is still intact: the bind
## generation is unchanged, the selector still holds exactly the snapshot deps,
## and both deps still return ACTUAL bool-true is_bound_to for the snapshot board.
func _op_coherent(board, ci, rs, gen) -> bool:
	if gen != _bind_generation or not _bound:
		return false
	if _board != board or _candidate_index != ci or _reservations != rs:
		return false
	if not _bool_true(ci.is_bound_to(board)):
		return false
	if not _bool_true(rs.is_bound_to(board)):
		return false
	return true

## Roll back ONLY this operation's exact (idx, owner_id) reservation entry via the
## canonical exact-pair release (F-M15-STRICT-005.E). ReservationState.release()
## removes the entry ONLY when target idx is currently owned by exactly owner_id,
## so it never erases another owner's reservation or a different target. It
## deliberately does NOT consult get_owner()/get_target_for_owner() first: a
## malformed ownership query (the very failure that triggers rollback) must never
## be able to prevent rollback of our own exact requested pair. It also does not
## treat release()'s own return as proof — the exact-pair contract is what makes
## it safe, not the return value.
func _rollback_own(rs, idx: int, owner_id: int) -> void:
	rs.release(idx, owner_id)

func _select_core(color_id: int, owner_id: int, access_query, board, ci, rs, gen) -> int:
	# Initial coherence probe under the armed guard: original deps still exact-bound
	# to original board, proven by actual bool-true (also the per-call
	# F-M15-STRICT-002 re-check). A nested bind from either is_bound_to() callback
	# here is already refused by the armed _in_selection guard.
	if not _op_coherent(board, ci, rs, gen):
		return -1
	# One target per owner. get_target_for_owner MUST be an int; malformed fails
	# closed with no reservation (F-M15-STRICT-004).
	var owned = rs.get_target_for_owner(owner_id)
	if typeof(owned) != TYPE_INT:
		return -1
	if owned != -1:
		return -1
	if not _op_coherent(board, ci, rs, gen):
		return -1

	# Reserved snapshot MUST be a PackedInt32Array; candidate list MUST be an Array.
	var excluded = rs.get_reserved_indices()
	if typeof(excluded) != TYPE_PACKED_INT32_ARRAY:
		return -1
	if not _op_coherent(board, ci, rs, gen):
		return -1
	var candidates = ci.get_candidates(color_id, excluded)
	if typeof(candidates) != TYPE_ARRAY:
		return -1
	if not _op_coherent(board, ci, rs, gen):
		return -1

	for entry in candidates:
		# Each candidate entry MUST be an int before any BoardState call; other
		# entry types are skipped fail-closed, never faulted on.
		if typeof(entry) != TYPE_INT:
			continue
		var idx: int = entry
		# Narrow final validation against live BoardState truth (AL-028).
		if not board.is_valid_index(idx):
			continue
		if board.get_cell_state(idx) != BoardState.CellState.ACTIVE:
			continue
		if board.get_color_id(idx) != color_id:
			continue
		# is_reserved MUST be a bool; a malformed verdict aborts fail-closed. Re-check
		# operation coherence AFTER the call regardless of true/false — an is_reserved
		# callback can drift candidate/reservation state and return true, which must
		# stop the operation before any later candidate is inspected
		# (F-M15-STRICT-005.C).
		var reserved = rs.is_reserved(idx)
		if typeof(reserved) != TYPE_BOOL:
			return -1
		if not _op_coherent(board, ci, rs, gen):
			return -1
		if reserved:
			continue
		# Authoritative reachability/access truth. The callback can run arbitrary
		# side effects, so re-check operation coherence immediately after it (the
		# primary drift seam).
		var verdict = access_query.is_targetable(idx)
		if not _op_coherent(board, ci, rs, gen):
			return -1
		# The post-targetability owner query is itself a full external collaborator
		# boundary (F-M15-STRICT-005.I): the callback may have independently assigned
		# owner_id a target (same-owner side effect, F-M15-STRICT-005.F) AND/OR drifted
		# candidate/reservation state while returning a normal int. So: call it,
		# validate TYPE_INT, THEN re-check operation coherence, and only then branch on
		# owner assignment / verdict. Detected drift stops here — no reserve, no later
		# candidate targetability query.
		var owned_after = rs.get_target_for_owner(owner_id)
		if typeof(owned_after) != TYPE_INT:
			return -1
		if not _op_coherent(board, ci, rs, gen):
			return -1
		# Owner already holds a target -> stop, preserving that external reservation.
		if owned_after != -1:
			return -1
		# Verdict accepted ONLY on actual bool-true; otherwise skip this candidate.
		if not _bool_true(verdict):
			continue
		# Atomic ownership gate. reserve MUST return a bool; only actual true is a
		# success.
		var ok = rs.reserve(idx, owner_id)
		if typeof(ok) != TYPE_BOOL:
			# A malformed (non-bool) return is never success AND is never proof that
			# nothing was stored: the collaborator may have mutated first and then
			# returned malformed metadata. Roll back the exact requested pair before
			# failing closed (F-M15-STRICT-004.A/005.D).
			_rollback_own(rs, idx, owner_id)
			return -1
		if ok:
			# reserve succeeded. Prove exact atomic ownership before returning, with
			# each ownership-proof callback transactionally bracketed one at a time
			# (F-M15-STRICT-005.J): after reserve and after EACH proof callback, verify
			# coherence; validate each return type immediately; on any malformed return
			# or detected drift, exact-pair rollback and return -1 WITHOUT invoking the
			# next proof callback.
			#
			# Step 1: coherence after reserve.
			if not _op_coherent(board, ci, rs, gen):
				_rollback_own(rs, idx, owner_id)
				return -1
			# Step 2: get_owner proof callback; validate TYPE_INT immediately.
			var owner_of = rs.get_owner(idx)
			if typeof(owner_of) != TYPE_INT:
				# Known failure: roll back and return WITHOUT the target-proof callback.
				_rollback_own(rs, idx, owner_id)
				return -1
			# Step 3: coherence after the get_owner callback (before target proof).
			if not _op_coherent(board, ci, rs, gen):
				_rollback_own(rs, idx, owner_id)
				return -1
			# Step 4: get_target_for_owner proof callback; validate TYPE_INT immediately.
			var target_of = rs.get_target_for_owner(owner_id)
			if typeof(target_of) != TYPE_INT:
				_rollback_own(rs, idx, owner_id)
				return -1
			# Step 5: coherence after the target-proof callback (before success).
			if not _op_coherent(board, ci, rs, gen):
				_rollback_own(rs, idx, owner_id)
				return -1
			# Step 6: exact owner/target identity, only after both typed + coherent.
			if owner_of != owner_id or target_of != idx:
				_rollback_own(rs, idx, owner_id)
				return -1
			return idx
		# reserve returned actual false: the reserve lost. Re-check THIS owner —
		# a same-owner side effect may have assigned owner_id another target during
		# reserve() itself. If so, stop immediately (no later candidates, no new
		# reservation). Different-owner contention leaves owner_id unassigned and
		# continues.
		var owned2 = rs.get_target_for_owner(owner_id)
		if typeof(owned2) != TYPE_INT:
			return -1
		if owned2 != -1:
			return -1
		if not _op_coherent(board, ci, rs, gen):
			return -1

	return -1
