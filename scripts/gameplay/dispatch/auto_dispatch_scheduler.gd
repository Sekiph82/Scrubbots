extends RefCounted
## AutoDispatchScheduler — M26 Auto Dispatch Scheduler. Preload this script
## (res://scripts/gameplay/dispatch/auto_dispatch_scheduler.gd); do not rely on
## global class_name. Gameplay-domain ORCHESTRATION ONLY. It owns pacing, fairness,
## WAITING/wake policy, and the exact mapping from an M25 claim to a preclaimed
## ScrubbotDispatcher assignment and back from an authenticated clear to
## M25.finalize_clear. It introduces NO new target-selection, reservation, routing
## or clearing authority — every one of those stays with its accepted M23/M24/M25/
## M19/M20 owner (CLAUDE.md §9, OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01 §9).
##
## HARD NO-GHOST production order (master prompt §38):
##   M25 claim+reservation -> exact route to the claimed target -> RouteValidator
##   clean -> ScrubbotDispatcher.dispatch_preclaimed (exact preclaimed assignment)
##   -> exactly one ScrubbotAgent.
## Therefore: no target => no robot; no claim/reservation => no robot; no valid
## route => no robot; any pre-spawn failure => M25.rollback_claim + zero robot; a
## failed claim is NEVER retargeted; one accepted transaction => exactly one agent.
##
## Quota (M24 remaining) is decremented ONLY after a successful M20 authenticated
## clear commit — the scheduler maps CompleteClearingLoop.authenticated_clear back to
## the exact live claim and calls M25.finalize_clear(claim_id) once. Claim/route/
## spawn NEVER decrement remaining.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const BatchTargetClaimEngine = preload("res://scripts/gameplay/targeting/batch_target_claim_engine.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")

const DEFAULT_SPEED := 6.0

# --- injected bundle (all null until bind()) ---------------------------------
var _board = null
var _batches = null             # FiveSlotBatchEngine (M24)
var _claim = null               # BatchTargetClaimEngine (M25)
var _reservations = null        # ReservationState (shared with M25 + dispatcher)
var _routing_system = null      # ProductionRoutingSystem (compute_route)
var _routing_access = null      # ProductionAccessQuery bound to _board
var _dispatcher = null          # ScrubbotDispatcher (bound to _board + _reservations)
var _loop = null                # CompleteClearingLoop (arrival-only or legacy bind)
var _origin_provider = null     # object exposing origin_for_slot(slot)->Vector2
var _speed: float = DEFAULT_SPEED

var _bound: bool = false
var _paused: bool = false
## Serialized against re-entrant step() and against a reset injected from a callback
## (rapid-input safety, master prompt §158). A nested step()/reset() fails closed.
var _in_step: bool = false
var _resetting: bool = false
var _clear_cb: Callable = Callable()

## owner_id -> {claim_id, slot, color, target, agent}. One entry per live scheduler
## assignment (in-flight robot). The reservation + M24 committed work for that entry
## stay held until an authenticated clear finalizes it (or reset rolls it back).
var _assignments: Dictionary = {}
## Colors whose oldest capacity-bearing batch produced no claimable target on their
## most recent scheduling turn. Skipped (no reservation churn / busy-loop) until an
## authoritative wake event (placement, authenticated clear, resume) clears the set.
var _waiting_colors: Dictionary = {}
## Fairness cursor: the color id that most recently received a scheduling turn. The
## next step starts round-robin at the eligible color AFTER it.
var _last_served_color: int = -1

# --------------------------------------------------------------------- bind --

## Bind one coherent production bundle. Fails closed (returns false, stays unbound)
## for a null/foreign/incoherent dependency: the dispatcher must be bound to the
## SAME board + reservations, the routing access + M25 must be bound to the same
## board, and the clearing loop must be bound. Connects to the loop's
## authenticated_clear notification so an M20 committed clear finalizes the exact
## live claim. Initialization-only: a second bind fails closed.
func bind(board, batch_engine, claim_engine, reservations, routing_system, routing_access,
		dispatcher, clearing_loop, origin_provider, speed: float = DEFAULT_SPEED) -> bool:
	if _bound:
		return false
	if not (board is BoardState):
		return false
	if not (batch_engine is FiveSlotBatchEngine):
		return false
	if not (claim_engine is BatchTargetClaimEngine) or not claim_engine.is_bound():
		return false
	if not (reservations is ReservationState) or not reservations.is_bound_to(board):
		return false
	if typeof(routing_system) != TYPE_OBJECT or not routing_system.has_method("compute_route"):
		return false
	if typeof(routing_access) != TYPE_OBJECT or not routing_access.has_method("is_bound_to") \
			or not _bool_true(routing_access.is_bound_to(board)):
		return false
	if not (dispatcher is ScrubbotDispatcher) or not dispatcher.is_bound_to(board, reservations):
		return false
	if not (clearing_loop is CompleteClearingLoop) or not clearing_loop.is_bound():
		return false
	if typeof(origin_provider) != TYPE_OBJECT or not origin_provider.has_method("origin_for_slot"):
		return false
	if not is_finite(speed) or speed <= 0.0:
		return false
	_board = board
	_batches = batch_engine
	_claim = claim_engine
	_reservations = reservations
	_routing_system = routing_system
	_routing_access = routing_access
	_dispatcher = dispatcher
	_loop = clearing_loop
	_origin_provider = origin_provider
	_speed = speed
	_clear_cb = Callable(self, "_on_authenticated_clear")
	_loop.authenticated_clear.connect(_clear_cb)
	_bound = true
	return true

func is_bound() -> bool:
	return _bound

# ------------------------------------------------------------- read-only ------

func is_paused() -> bool:
	return _paused

func live_assignment_count() -> int:
	return _assignments.size()

func get_assignment(owner_id) -> Dictionary:
	if not _assignments.has(owner_id):
		return {}
	return _assignments[owner_id].duplicate(true)

func assignment_snapshot() -> Array:
	var out: Array = []
	var keys: Array = _assignments.keys()
	keys.sort()
	for k in keys:
		out.append(_assignments[k].duplicate(true))
	return out

func is_color_waiting(color_id) -> bool:
	return _waiting_colors.has(color_id)

# ------------------------------------------------------------- scheduling -----

## One deterministic scheduling step/cadence event. Produces AT MOST one new accepted
## assignment (one M25 claim + one preclaimed spawn), never a synchronous batch burst.
## Round-robin across eligible colors so a continuously busy color cannot starve
## another. Returns a detached result dict; {ok:true,...} exactly when one agent was
## created this step. Idle/paused/reset/no-eligible-work return {ok:false, reason}.
func step() -> Dictionary:
	if not _bound:
		return {"ok": false, "reason": "unbound"}
	if _paused:
		return {"ok": false, "reason": "paused"}
	if _resetting:
		return {"ok": false, "reason": "resetting"}
	if _in_step:
		return {"ok": false, "reason": "reentrant"}
	_in_step = true
	var r := _step_guarded()
	_in_step = false
	return r

func _step_guarded() -> Dictionary:
	var ordered := _eligible_colors()
	if ordered.is_empty():
		return {"ok": false, "reason": "idle"}
	var start := 0
	var pos := ordered.find(_last_served_color)
	if pos != -1:
		start = (pos + 1) % ordered.size()
	# Give at most one color an ACCEPTED assignment this step. A color that yields no
	# claimable target is marked WAITING and the rotation continues to the next color.
	for k in range(ordered.size()):
		var color: int = ordered[(start + k) % ordered.size()]
		var res := _attempt_color(color)
		if res.get("ok", false):
			_last_served_color = color
			return res
	# No color produced an assignment (all waiting/failed this pass): advance the
	# cursor deterministically so the next step does not re-favour the same color.
	_last_served_color = ordered[(start + ordered.size() - 1) % ordered.size()]
	return {"ok": false, "reason": "no_assignment"}

## Repeatedly step() until idle or `max_steps` reached. Still one assignment per
## step. Returns the number of accepted assignments created.
func run_until_idle(max_steps: int = 100000) -> int:
	var n := 0
	var guard := max_steps
	while guard > 0:
		guard -= 1
		var r := step()
		if r.get("ok", false):
			n += 1
		else:
			break
	return n

## Ordered eligible color ids: colors with at least one occupied capacity-bearing
## batch that is NOT currently WAITING, ordered by the oldest placement sequence
## among those batches (never arbitrary Dictionary iteration order).
func _eligible_colors() -> Array:
	var min_seq: Dictionary = {}   # color -> min placement sequence
	for i in range(_batches.get_slot_count()):
		if not _batches.is_occupied(i):
			continue
		if _batches.get_capacity(i) <= 0:
			continue
		var color: int = _batches.get_color_id(i)
		if _waiting_colors.has(color):
			continue
		var seq: int = _batches.get_placement_sequence(i)
		if not min_seq.has(color) or seq < int(min_seq[color]):
			min_seq[color] = seq
	var colors: Array = min_seq.keys()
	colors.sort_custom(func(a, b): return int(min_seq[a]) < int(min_seq[b]))
	return colors

## Attempt exactly one claim+dispatch for `color`. On no claimable target the color
## is marked WAITING (no robot, no reservation churn). On any pre-spawn failure after
## a successful claim, the whole claim is rolled back through M25 and zero robot
## exists. On success exactly one ScrubbotAgent is registered.
func _attempt_color(color: int) -> Dictionary:
	var access_by_slot := _build_access_for_color(color)
	var claim: Dictionary = _claim.claim_for_color(color, access_by_slot)
	if not claim.get("ok", false):
		# no_target -> WAITING; commit_failed/other -> not an assignment, no rollback
		# needed (M25 already restored its own prestate). Never retarget.
		if claim.get("waiting", false):
			_waiting_colors[color] = true
		return {"ok": false, "reason": claim.get("error", "no_claim")}
	var claim_id = claim["claim_id"]
	var slot: int = int(claim["slot"])
	var owner: int = int(claim["owner_id"])
	var target: int = int(claim["target"])
	var origin: Vector2 = _origin_for_slot(slot)
	# Build the exact route request for the SAME claimed target from the slot origin.
	var request = RouteRequest.for_target(_board, origin, target)
	if request == null:
		_claim.rollback_claim(claim_id)
		return {"ok": false, "reason": "route_request_failed"}
	# Reuse M25's memoized winning route for this exact target when present; otherwise
	# recompute a route ONLY for the same claimed target (no reselection).
	var route = null
	var access = access_by_slot.get(slot, null)
	if access != null and access.has_method("consume_route"):
		route = access.consume_route(target)
	if route == null:
		route = _routing_system.compute_route(request, _board, _routing_access)
	# Exact preclaimed assignment. The dispatcher RouteValidator-validates the route
	# and proves the M25 reservation; it never selects/reserves and never releases the
	# reservation on failure.
	var dr = _dispatcher.dispatch_preclaimed(owner, color, target, origin, request, route, _speed)
	if dr == null or not dr.success:
		_claim.rollback_claim(claim_id)
		return {"ok": false, "reason": "dispatch_failed",
			"dispatch_reason": (dr.failure_reason if dr != null else &"NULL")}
	_assignments[owner] = {"claim_id": claim_id, "slot": slot, "color": color,
		"target": target, "agent": dr.agent}
	return {"ok": true, "reason": "assigned", "owner_id": owner, "target": target,
		"color": color, "slot": slot, "claim_id": claim_id, "agent": dr.agent}

## Build {slot_index: ProductionTargetAccess} for every occupied slot of `color`,
## each pointed at that slot's real board-local origin. M25 chooses which slot (the
## oldest capacity-bearing one) — the scheduler never overrides that ordering.
func _build_access_for_color(color: int) -> Dictionary:
	var out: Dictionary = {}
	for i in range(_batches.get_slot_count()):
		if not _batches.is_occupied(i):
			continue
		if _batches.get_color_id(i) != color:
			continue
		var origin: Vector2 = _origin_for_slot(i)
		out[i] = ProductionTargetAccess.new(_routing_system, _routing_access, _board, origin)
	return out

func _origin_for_slot(slot: int) -> Vector2:
	var o = _origin_provider.origin_for_slot(slot)
	if typeof(o) == TYPE_VECTOR2:
		return o
	# Fail-closed: a malformed provider return yields a non-finite origin so the route
	# request fails and no robot is produced (never a plausible-but-wrong origin).
	return Vector2(INF, INF)

# ----------------------------------------------- authenticated clear bridge ---

## M20 committed-clear notification handler (§J). Maps the authenticated owner id back
## to the exact live scheduler claim and calls M25.finalize_clear once, then wakes
## WAITING colors (a cleared cell can open new corridors). A duplicate/stale/unknown
## owner id (no live assignment) is ignored and CANNOT double-decrement M24 quota.
func _on_authenticated_clear(owner_id: int, target_index: int, color_id: int, _agent) -> void:
	if not _assignments.has(owner_id):
		return  # stale/duplicate/foreign -> fail closed, no quota change
	var rec: Dictionary = _assignments[owner_id]
	# Defence-in-depth: the notification identity must match the live assignment.
	if int(rec["target"]) != target_index or int(rec["color"]) != color_id:
		return
	var claim_id = rec["claim_id"]
	_assignments.erase(owner_id)
	# finalize_clear is idempotent/fail-closed in M25; a false return (already gone)
	# still leaves the assignment removed and decrements nothing extra.
	_claim.finalize_clear(claim_id)
	_wake()

# ------------------------------------------------------- WAITING / wake -------

## Authoritative wake: a new batch was placed into M24. Reconsider WAITING colors and
## reset fairness so newly placed work is scheduled promptly. Emit-only seam — the
## caller invokes this AFTER a successful M24 placement commit; it changes no
## authority.
func notify_placed() -> void:
	_wake()

func _wake() -> void:
	_waiting_colors.clear()

# --------------------------------------------------------- pause / resume -----

## Pause blocks new scheduler dispatches only. It fabricates no rollback/quota change
## and preserves every live claim/agent.
func pause() -> void:
	_paused = true

## Resume restarts deterministic scheduling and reconsiders WAITING colors. It never
## duplicates a live claim/spawn (assignments are keyed by monotonic owner ids).
func resume() -> void:
	_paused = false
	_wake()

# ------------------------------------------------------------- reset ----------

## Serialized teardown (master prompt §170). Cleans M25 live claims/committed work
## FIRST (while their ReservationState pairs still exist) so M24 committed rolls back
## coherently and each exact reservation is released; THEN resets the dispatcher/M20
## agents (which finds the pairs already gone and only frees agents); THEN clears the
## scheduler ledger. Cancelled work never decrements remaining quota, unrelated
## reservations survive, and it is idempotent. Fails closed if re-entered.
func reset() -> void:
	if not _bound:
		return
	if _resetting or _in_step:
		return
	_resetting = true
	# Phase 1 — roll back every live scheduler claim through M25 while reservation
	# truth is intact (releases the exact reservation pair + rolls back M24 committed;
	# remaining quota is NOT decremented for cancelled in-flight work).
	for owner_id in _assignments.keys():
		var claim_id = _assignments[owner_id]["claim_id"]
		_claim.rollback_claim(claim_id)
	# Phase 2 — cancel/free dispatcher + M20 agents. The dispatcher's own reset finds
	# each reservation pair already released by M25 and only frees agents (no double
	# release), leaving zero orphan ScrubbotAgent nodes.
	_loop.reset()
	# Phase 3 — clear scheduler bookkeeping. Identities are never recycled (M25 owner/
	# claim ids and dispatcher owner ids stay monotonic), so stale callbacks after
	# reset cannot mutate new-session state.
	_assignments.clear()
	_waiting_colors.clear()
	_last_served_color = -1
	_resetting = false

static func _bool_true(v) -> bool:
	return typeof(v) == TYPE_BOOL and v == true
