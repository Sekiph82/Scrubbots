extends RefCounted
## BatchTargetClaimEngine — M25 Batch Target Claim Engine. Preload this script
## (res://scripts/gameplay/targeting/batch_target_claim_engine.gd); do not rely on
## global class_name. Gameplay-domain ONLY: no UI/Node, no route calculation, no robot
## spawn (M26), no solvability/deadlock search (M27).
##
## M25 answers ONE question: given the currently occupied M24 batches and the current
## BoardState/routing truth, which exact live batch owns which exact currently-targetable
## pixel reservation? It arbitrates same-color batches and books one live claim as a
## strict one-to-one tuple:
##
##   one M25 claim  <->  one ReservationState (target,owner) pair  <->  one M24
##   committed work identity (the claim_id).
##
## Authorities are REUSED, never replaced:
## - ReservationState is the single live target-reservation authority; M25 never keeps a
##   competing reservation map (the ledger only mirrors identity for bookkeeping);
## - TargetSelector is the WHAT authority and preserves bottom-most -> left-most order;
## - ProductionTargetAccess (supplied per slot by the caller) is the reachability truth;
## - FiveSlotBatchEngine owns slot/batch counters, placement sequence and committed work;
## - CompleteClearingLoop remains the authenticated board-clear authority.
##
## Owner-locked arbitration (OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01): same-color batches
## are independent; claims go to the OLDEST placement-sequence batch while it has dispatch
## capacity; only when that batch's capacity is exhausted (filtered out at capacity 0) may
## claims spill to the next same-color batch. remaining_to_clear is NEVER decremented by a
## claim; each accepted claim increments M24 committed exactly once via commit_work(slot,
## claim_id). A blocked/unreachable future pixel is never pre-owned.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")

var _board = null
var _batches = null          # FiveSlotBatchEngine
var _selector = null         # TargetSelector (bound to _board + _reservations)
var _reservations = null     # ReservationState (bound to _board)
var _bound: bool = false

# Session-scoped ledger: claim_id (String) -> record Dictionary. The record is engine-
# owned truth used for exact rollback/finalization; ReservationState stays authoritative
# for live target ownership.
var _claims: Dictionary = {}
# Identity counters are MONOTONIC for the whole engine lifetime and are NEVER rewound by
# reset() (F-M25-V01-STRICT-001): a public claim id / reservation-owner id is never
# recycled, so a stale pre-reset handle can never act on a post-reset claim.
var _next_owner: int = 0     # monotonic ReservationState owner id (>=0)
var _next_claim: int = 1     # monotonic claim/work id suffix
var _busy: bool = false      # re-entrancy guard for external-collaborator paths

# --------------------------------------------------------------------- bind --

## Bind one coherent production bundle. Fails closed (returns false, stays unbound) for
## null/foreign/mixed-board dependencies: the selector must be bound to the SAME board +
## reservations, and reservations must be bound to the same board (exact-identity).
## Session-stable / initialization-only (F-M25-V01-STRICT-005): once bound, any further
## bind() fails closed and preserves the exact original bundle, so a second (even coherent)
## bind can never migrate a live engine — including while live claims exist. There is no
## rebind that moves authorities under live claims.
func bind(board, batch_engine, selector, reservations) -> bool:
	if _busy:
		return false
	if _bound:
		return false
	if not (board is BoardState):
		return false
	if not (batch_engine is FiveSlotBatchEngine):
		return false
	if not (selector is TargetSelector) or not (reservations is ReservationState):
		return false
	if not reservations.is_bound_to(board):
		return false
	if not selector.is_bound_to(board, reservations):
		return false
	_board = board
	_batches = batch_engine
	_selector = selector
	_reservations = reservations
	_bound = true
	return true

func is_bound() -> bool:
	return _bound

# ------------------------------------------------------------ read-only query --

func live_claim_count() -> int:
	return _claims.size()

## Detached snapshot of a single claim (fresh Dictionary), or {} if unknown.
func get_claim(claim_id) -> Dictionary:
	if not _claims.has(claim_id):
		return {}
	return _claims[claim_id].duplicate(true)

## Detached snapshot of every live claim, sorted by claim_id for deterministic order.
func claim_snapshot() -> Array:
	var out: Array = []
	var keys: Array = _claims.keys()
	keys.sort()
	for k in keys:
		out.append(_claims[k].duplicate(true))
	return out

## True iff a live claim already targets this board index.
func is_target_claimed(target_index) -> bool:
	for k in _claims:
		if int(_claims[k]["target"]) == int(target_index):
			return true
	return false

# ------------------------------------------------------ same-color arbitration --

## Oldest occupied batch of `color_id` with dispatch capacity > 0 (placement-sequence
## ascending), or -1 if none. This is the whole owner-locked FIFO+spill rule: a batch at
## capacity 0 is filtered out, so work naturally spills to the next oldest.
func oldest_capacity_slot(color_id) -> int:
	var best_slot := -1
	var best_seq := 0
	for i in range(_batches.get_slot_count()):
		if not _batches.is_occupied(i):
			continue
		if _batches.get_color_id(i) != color_id:
			continue
		if _batches.get_capacity(i) <= 0:
			continue
		var seq: int = _batches.get_placement_sequence(i)
		if best_slot == -1 or seq < best_seq:
			best_slot = i
			best_seq = seq
	return best_slot

# ------------------------------------------------------- accepted claim (WP02) --

## Attempt one claim for `color_id`, choosing the oldest capacity-bearing same-color
## batch and one currently production-targetable target through the real TargetSelector.
## `access_by_slot` maps slot_index -> a ProductionTargetAccess-like object (RefCounted
## exposing is_targetable) prepared by the caller for that slot's origin. Returns a
## detached result dict; on success establishes the atomic claim/reservation/commit tuple.
func claim_for_color(color_id, access_by_slot) -> Dictionary:
	if _busy:
		return {"ok": false, "error": "reentrant"}
	_busy = true
	var r := _claim_for_color_guarded(color_id, access_by_slot)
	_busy = false
	return r

func _claim_for_color_guarded(color_id, access_by_slot) -> Dictionary:
	if not _bound:
		return {"ok": false, "error": "unbound"}
	if typeof(color_id) != TYPE_INT or color_id < 0:
		return {"ok": false, "error": "bad_color"}
	if typeof(access_by_slot) != TYPE_DICTIONARY:
		return {"ok": false, "error": "bad_access_map"}
	var slot := oldest_capacity_slot(color_id)
	if slot == -1:
		return {"ok": false, "error": "no_eligible_batch"}
	var access = access_by_slot.get(slot, null)
	# Strict production trust boundary (F-M25-V01-STRICT-004): only a canonical
	# ProductionTargetAccess coherent with the EXACT bound board is accepted as production
	# reachability truth. A generic method-compatible/all-true RefCounted, a null/malformed
	# object, or a foreign-board ProductionTargetAccess is rejected here — before any
	# reservation or M24 mutation.
	if not (access is ProductionTargetAccess):
		return {"ok": false, "error": "bad_access", "slot": slot}
	if not access.is_bound_to_board(_board):
		return {"ok": false, "error": "foreign_board_access", "slot": slot}
	# Mint deterministic unique identities. The reservation-owner id must be an integer NOT
	# already live in the shared ReservationState (F-M25-V01-STRICT-001): skip past any
	# unrelated live owner (including owner 0 in a fresh session) WITHOUT stealing/releasing
	# it, so an unrelated reservation can never stall a valid M25 claim.
	while _reservations.get_target_for_owner(_next_owner) != -1:
		_next_owner += 1
	var owner_id := _next_owner
	var claim_id := "M25C%d" % _next_claim
	# TargetSelector selects + reserves exactly one target (or -1). It preserves the
	# owner-locked bottom-most/left-most order and only accepts production-targetable,
	# ACTIVE, matching-color, unreserved pixels.
	var target: int = _selector.select_and_reserve(color_id, owner_id, access)
	if target == -1:
		# No claimable target now: WAITING without discarding the batch. No reservation,
		# no committed increment, no ledger entry.
		_batches.set_claimable_work_available(slot, false)
		return {"ok": false, "error": "no_target", "slot": slot, "waiting": true}
	# Snapshot the exact lifecycle prestate BEFORE the ACTIVE confirmation so a later commit
	# failure can restore it (F-M25-V01-STRICT-002). Reserved -> confirm/resume ACTIVE, then
	# commit exactly one M24 work unit.
	var prestate = _batches.get_state(slot)
	_batches.set_claimable_work_available(slot, true)
	if not _batches.commit_work(slot, claim_id):
		# M24 commit failed. Restore EXACT pre-attempt truth: release the new reservation and
		# roll the lifecycle back to its prestate (WAITING stays WAITING; ACTIVE stays
		# ACTIVE). No claim published, and NO identity counter advanced — so the attempt
		# leaves no stale claim/owner alias behind. Capacity is unchanged (committed did not
		# move), so the WAITING restore is always legal for the batch we selected.
		_reservations.release(target, owner_id)
		if prestate == "WAITING":
			_batches.set_claimable_work_available(slot, false)
		return {"ok": false, "error": "commit_failed", "slot": slot}
	# Both reservation + M24 commit proven — advance identities and publish the ledger.
	_next_owner += 1
	_next_claim += 1
	var coord = _board.get_cell_position(target)
	var rec := {
		"claim_id": claim_id, "slot": slot, "batch_id": _batches.get_batch_id(slot),
		"placement_sequence": _batches.get_placement_sequence(slot), "color_id": color_id,
		"target": target, "coord": coord, "owner_id": owner_id, "status": "live"}
	_claims[claim_id] = rec
	return {"ok": true, "claim_id": claim_id, "slot": slot, "batch_id": rec["batch_id"],
		"color_id": color_id, "target": target, "coord": coord, "owner_id": owner_id}

## Re-evaluate a color after an authoritative BoardState change (future M26 seam). Uses
## live production targetability (never UI state) — it simply retries a claim, so a WAITING
## batch resumes ACTIVE only when a real targetable pixel now exists under FIFO order.
func reconsider_color(color_id, access_by_slot) -> Dictionary:
	return claim_for_color(color_id, access_by_slot)

# --------------------------------------------- pre-spawn rollback seam (WP03 A) --

## Roll back exactly one live claim before any robot exists (future M26 route/spawn
## failure). Releases exactly its reservation pair, rolls back exactly its M24 committed
## work (committed-1, remaining unchanged), erases exactly that ledger entry. Unrelated
## claims/reservations untouched. M24 rollback runs first so a failure aborts before any
## reservation release (no half-release).
func rollback_claim(claim_id) -> bool:
	if _busy:
		return false
	if not _claims.has(claim_id):
		return false
	var rec: Dictionary = _claims[claim_id]
	var target := int(rec["target"])
	var owner := int(rec["owner_id"])
	# Preflight EXACT engine-owned tuple coherence BEFORE any destructive mutation
	# (F-M25-V01-STRICT-003). The reservation pair must still be exactly this claim's
	# target<->owner, and the M24 committed work identity must still be live+coherent. Any
	# drift — reservation absent, target reserved by a foreign owner, M24 work stale/absent
	# — fails closed with the ledger and BOTH canonical halves untouched (no half cleanup,
	# no false success). This synchronous path has no external callback between preflight
	# and mutation, so once both halves are proven exact the two mutations below cannot fail.
	if _reservations.get_owner(target) != owner:
		return false
	if _reservations.get_target_for_owner(owner) != target:
		return false
	if not _batches.is_work_coherent(claim_id):
		return false
	if not _batches.rollback_work(claim_id):
		return false
	_reservations.release(target, owner)
	_claims.erase(claim_id)
	return true

# ----------------------------------------- authenticated-clear finalization (WP03 B) --

## Finalize one live claim AFTER the authoritative clear pipeline has cleared its target
## and released its reservation. Requires exact engine-owned identity + canonical
## postconditions (target CLEARED, reservation no longer owned by this claim's owner).
## Then calls M24.resolve_clear(claim_id) exactly once (committed-1 AND remaining-1) and
## erases the claim. M25 never edits M24 counters directly. Fails closed for stale/wrong/
## double/random identities with zero extra quota loss.
func finalize_clear(claim_id) -> bool:
	if _busy:
		return false
	if not _claims.has(claim_id):
		return false
	var rec: Dictionary = _claims[claim_id]
	var target := int(rec["target"])
	var owner := int(rec["owner_id"])
	# Canonical postconditions of an already-authenticated clear.
	if not _board.is_valid_index(target):
		return false
	if _board.get_cell_state(target) == BoardState.CellState.ACTIVE:
		return false  # target still ACTIVE -> not cleared yet -> fail closed
	if _reservations.get_owner(target) == owner:
		return false  # reservation not yet resolved by the clear pipeline -> fail closed
	if not _batches.resolve_clear(claim_id):
		return false
	_claims.erase(claim_id)
	return true

# --------------------------------------------------------- reset / teardown (WP03 D) --

## Deterministic M25 teardown: for every still-live (pre-clear) claim, release its exact
## reservation pair and roll back its exact M24 committed work, then clear the ledger and
## transient arbitration state. Unrelated ReservationState owners survive (only exact
## pairs are released). Does NOT reset M24/M23. Re-entry safe (fails closed while busy).
func reset() -> bool:
	if _busy:
		return false
	# Phase 1 — preflight EVERY live tuple read-only (F-M25-V01-STRICT-003/004). If any
	# claim's reservation pair or M24 work identity is incoherent, abort WITHOUT mutating
	# anything and report failure: never silently clear the ledger over orphan
	# M24/reservation truth.
	for claim_id in _claims.keys():
		var rec: Dictionary = _claims[claim_id]
		var target := int(rec["target"])
		var owner := int(rec["owner_id"])
		if _reservations.get_owner(target) != owner:
			return false
		if _reservations.get_target_for_owner(owner) != target:
			return false
		if not _batches.is_work_coherent(claim_id):
			return false
	# Phase 2 — all tuples proven coherent: clean each exactly. Teardown order is M25 claim
	# cleanup BEFORE any M24 reset (a session caller resets M24/M23 separately) so committed
	# work rolls back coherently. Only exact pairs are released, so unrelated ReservationState
	# owners survive untouched.
	for claim_id in _claims.keys():
		var rec: Dictionary = _claims[claim_id]
		_batches.rollback_work(claim_id)
		_reservations.release(int(rec["target"]), int(rec["owner_id"]))
	_claims.clear()
	# Identity counters stay MONOTONIC across reset (F-M25-V01-STRICT-001): a claim id /
	# owner id is NEVER recycled, so stale pre-reset handles stay permanently invalid.
	return true
