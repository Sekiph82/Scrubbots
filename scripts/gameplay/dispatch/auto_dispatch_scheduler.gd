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
## Serialized against re-entrant step() (rapid-input safety, master prompt §158). A
## nested step() fails closed.
var _in_step: bool = false
## Deferred/generation-safe reset (F-M26-V01-STRICT-001). A reset injected from ANY
## callback boundary while step() is active is NEVER dropped: it records intent
## (_reset_requested) and advances a monotonic generation, the active step aborts +
## rolls back before it can spawn, and the heavy teardown drains once the step unwinds.
## _generation moving away from a step's snapshot is the single "a reset arrived during
## this step" signal checked after every callback-bearing boundary.
var _generation: int = 0
var _reset_requested: bool = false
var _reset_in_progress: bool = false
## Outcome of the most recent teardown attempt (F-M26-V01-STRICT-002). A reset that
## cannot prove every live claim rollback-coherent fails closed and leaves this false.
var _last_reset_ok: bool = true
## Deterministic fatal state (F-M26-V01-STRICT-003). Set only when an otherwise-valid
## authenticated clear cannot finalize its M25 claim: the assignment/claim/committed
## truth is retained for diagnosis and NEW scheduling is blocked until reset/recovery.
var _fatal: bool = false
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
	if not (claim_engine is BatchTargetClaimEngine):
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
	if not (clearing_loop is CompleteClearingLoop):
		return false
	if typeof(origin_provider) != TYPE_OBJECT or not origin_provider.has_method("origin_for_slot"):
		return false
	if not is_finite(speed) or speed <= 0.0:
		return false
	# Exact cross-engine bundle coherence (F-M26-V01-STRICT-004). Every collaborator must
	# prove — through a minimal read-only identity seam — that it owns THIS exact board/
	# reservation/M24/dispatcher bundle, so individually-valid engines from different
	# sessions can never be stitched together. Proven BEFORE any signal connection or
	# state commit, so a rejected bundle leaves zero side effects and the loop stays fully
	# disconnected. reservations.is_bound_to(board) and dispatcher.is_bound_to(board,
	# reservations) above already anchor M14/M19; these two anchor M25 and M20:
	#   - M25 exact BoardState == board, exact M24 == batch_engine, exact reservations;
	#   - M20 exact BoardState == board, exact reservations, exact dispatcher.
	if not _bool_true(claim_engine.is_bound_to(board, batch_engine, reservations)):
		return false
	if not _bool_true(clearing_loop.is_bound_to(board, reservations, dispatcher)):
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
	if _fatal:
		return {"ok": false, "reason": "fatal"}
	if _paused:
		return {"ok": false, "reason": "paused"}
	if _reset_in_progress:
		return {"ok": false, "reason": "resetting"}
	if _in_step:
		return {"ok": false, "reason": "reentrant"}
	if _reset_requested:
		# A reset was recorded but not yet drained (deferred from an earlier step, or a
		# prior fail-closed teardown awaiting repair+retry). Never schedule over it: drain
		# it here and report, so new scheduling stays blocked until reset succeeds.
		_drain_pending_reset()
		return {"ok": false, "reason": "resetting"}
	_in_step = true
	var my_gen: int = _generation
	var r := _step_guarded(my_gen)
	_in_step = false
	# Drain any reset injected DURING this step (from an origin/route/access/dispatcher
	# callback). The step already rolled back its own in-progress claim and recorded no
	# assignment, so the teardown below only frees prior in-flight state — and by the time
	# step() returns, a mid-step reset has produced zero net robot.
	_drain_pending_reset()
	return r

func _step_guarded(my_gen: int) -> Dictionary:
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
		var res := _attempt_color(color, my_gen)
		if res.get("ok", false):
			_last_served_color = color
			return res
		# A reset injected during this color's attempt aborts the whole step immediately
		# (the in-progress claim, if any, was already rolled back inside _attempt_color).
		if _generation != my_gen:
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
func _attempt_color(color: int, my_gen: int) -> Dictionary:
	# _build_access_for_color reads the origin provider (a callback boundary that can
	# inject reset) but performs NO claim/reservation yet, so a reset here just aborts.
	var access_by_slot := _build_access_for_color(color)
	if _generation != my_gen:
		return {"ok": false, "reason": "reset_pending"}
	# claim_for_color runs the M25 selector + per-slot access callbacks (a callback
	# boundary). A failure creates no claim (M25 restored its own prestate), so a reset
	# during it needs no rollback here.
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
	# From here a live M25 claim EXISTS. Every subsequent early return that observes a
	# generation move (reset injected before the assignment is committed) MUST roll that
	# claim back through M25 so no orphan claim/reservation/committed-work survives, and
	# it MUST NOT record an assignment — the step then produces zero robot.
	if _generation != my_gen:
		_claim.rollback_claim(claim_id)
		return {"ok": false, "reason": "reset_pending"}
	var origin: Vector2 = _origin_for_slot(slot)  # origin-provider callback boundary
	if _generation != my_gen:
		_claim.rollback_claim(claim_id)
		return {"ok": false, "reason": "reset_pending"}
	# Build the exact route request for the SAME claimed target from the slot origin.
	var request = RouteRequest.for_target(_board, origin, target)
	if request == null:
		_claim.rollback_claim(claim_id)
		return {"ok": false, "reason": "route_request_failed"}
	# Reuse M25's memoized winning route for this exact target when present; otherwise
	# recompute a route ONLY for the same claimed target (no reselection). Both are
	# route/access callback boundaries.
	var route = null
	var access = access_by_slot.get(slot, null)
	if access != null and access.has_method("consume_route"):
		route = access.consume_route(target)
	if route == null:
		route = _routing_system.compute_route(request, _board, _routing_access)
	if _generation != my_gen:
		_claim.rollback_claim(claim_id)
		return {"ok": false, "reason": "reset_pending"}
	# Exact preclaimed assignment. The dispatcher RouteValidator-validates the route
	# and proves the M25 reservation; it never selects/reserves and never releases the
	# reservation on failure. Its factory/assign/add-child callbacks are the last
	# callback boundary that can inject a reset.
	var dr = _dispatcher.dispatch_preclaimed(owner, color, target, origin, request, route, _speed)
	# A reset injected DURING preclaimed dispatch does not move the dispatcher's own
	# generation (the scheduler's reset is deferred while _in_step), so dispatch may
	# return SUCCESS with a spawned agent. Detect the scheduler reset here: roll the M25
	# claim back and record NO assignment. Any agent the dispatch spawned is torn down by
	# the deferred teardown (_loop.reset()) that drains right after the step unwinds, so
	# the net result is zero robot.
	if _generation != my_gen:
		_claim.rollback_claim(claim_id)
		return {"ok": false, "reason": "reset_pending"}
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
func _on_authenticated_clear(owner_id: int, target_index: int, color_id: int, agent) -> void:
	# A fatal scheduler state blocks further clear processing until reset/recovery.
	if _fatal:
		return
	if not _assignments.has(owner_id):
		return  # stale/duplicate/foreign -> fail closed, no quota change
	var rec: Dictionary = _assignments[owner_id]
	# Exact immutable identity match, INCLUDING the exact agent instance (F-M26-V01-
	# STRICT-003). A wrong agent / wrong target / wrong color notification (even with an
	# otherwise-correct owner) is ignored with zero side effects — no finalize, no quota
	# change, assignment intact.
	if int(rec["target"]) != target_index:
		return
	if int(rec["color"]) != color_id:
		return
	if rec["agent"] != agent:
		return
	var claim_id = rec["claim_id"]
	# Finalize the M25 claim FIRST and preserve the owner->claim mapping until it truly
	# succeeds (F-M26-V01-STRICT-003). M24 quota (remaining-1) is decremented ONLY inside
	# a successful finalize_clear, so a failed finalize decrements nothing.
	if not _bool_true(_claim.finalize_clear(claim_id)):
		# Finalize failed (e.g. the exact M24 work tuple drifted). Do NOT erase the
		# assignment, do NOT wake, do NOT pretend completion: retain the scheduler
		# assignment + M25 claim + M24 committed truth for diagnosis/recovery and surface
		# a deterministic fatal state that blocks new scheduling.
		_fatal = true
		return
	# Finalization proven: only now erase the scheduler assignment and wake WAITING colors
	# (a cleared cell can open new corridors).
	_assignments.erase(owner_id)
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

## Transaction-safe, deferred/generation-safe teardown (F-M26-V01-STRICT-001/002).
##
## Deferred: a reset requested while a step() is active (from any callback boundary) is
## NEVER dropped — it records intent and advances the generation so the running step
## aborts+rolls back before spawn, and the heavy teardown drains once the step unwinds.
##
## Transaction-safe: the teardown proves every live scheduler assignment still maps to an
## exact live, rollback-coherent M25 claim BEFORE any destructive dispatcher/M20 teardown
## or ledger clear. If any claim is incoherent (e.g. a drifted M24 work tuple), it fails
## closed leaving the healthy sibling claim, its reservation, and its dispatcher agent all
## recoverable — never a half-torn state or an orphan committed tuple.
##
## Returns true iff the teardown completed successfully in THIS call; false when it was
## deferred (a step is active), was re-entered, or failed closed. last_reset_succeeded()
## and is_reset_pending() expose the recorded outcome for the deferred case.
func reset() -> bool:
	if not _bound:
		return false
	_reset_requested = true
	_generation += 1
	if _in_step or _reset_in_progress:
		return false  # deferred/re-entrant; drained at a safe point (see _drain_pending_reset)
	return _perform_reset()

## Drain a deferred/pending reset once no step is mid-flight. Invoked at the tail of
## step() and at the head of a fresh step() so a reset injected during a step, or a
## fail-closed reset awaiting repair, is never left silently pending.
func _drain_pending_reset() -> void:
	if _reset_requested and not _in_step and not _reset_in_progress:
		_perform_reset()

func _perform_reset() -> bool:
	if _reset_in_progress:
		return false
	_reset_in_progress = true
	var ok := _reset_teardown()
	_last_reset_ok = ok
	if ok:
		# A successful teardown clears the pending request AND any fatal state (the
		# incoherent claim it guarded has been rolled back / drained).
		_reset_requested = false
		_fatal = false
	_reset_in_progress = false
	return ok

## The actual all-or-nothing teardown. Read-only preflight first; only mutate once every
## live claim is proven rollback-coherent.
func _reset_teardown() -> bool:
	# Preflight A (scheduler<->M25 mapping): every live scheduler assignment must still
	# name a live M25 claim before any destructive teardown. A vanished claim fails closed.
	for owner_id in _assignments.keys():
		var claim_id = _assignments[owner_id]["claim_id"]
		if _claim.get_claim(claim_id).is_empty():
			return false
	# Preflight B + rollback (M25 all-or-nothing): BatchTargetClaimEngine.reset() preflights
	# EVERY live claim's exact reservation pair AND M24 work tuple read-only, and mutates
	# NOTHING if any is incoherent. So a single drifted/uncommitted claim makes this return
	# false with the healthy sibling claim, its reservation and — because we have not yet
	# touched the dispatcher — its in-flight agent all intact and recoverable. On success
	# every claim's exact reservation pair is released and its M24 committed rolled back
	# (remaining quota is NOT decremented for cancelled in-flight work).
	if not _bool_true(_claim.reset()):
		return false  # fail closed BEFORE any dispatcher/M20 teardown or ledger clear
	# Every claim proven rolled back: now free dispatcher + M20 agents. The dispatcher's
	# own reset finds each reservation pair already released by M25 and only frees agents
	# (no double release), leaving zero orphan ScrubbotAgent nodes; unrelated reservations
	# survive (only exact pairs are released anywhere).
	_loop.reset()
	# Clear scheduler bookkeeping. Identities are never recycled (M25 owner/claim ids and
	# dispatcher owner ids stay monotonic), so stale callbacks after reset cannot mutate
	# new-session state.
	_assignments.clear()
	_waiting_colors.clear()
	_last_served_color = -1
	return true

## Outcome of the most recent teardown attempt (true until the first failed one).
func last_reset_succeeded() -> bool:
	return _last_reset_ok

## True while a reset has been recorded but not yet successfully completed (deferred
## during a step, or a fail-closed teardown awaiting repair + retry).
func is_reset_pending() -> bool:
	return _reset_requested

## True once a fatal scheduler state has been surfaced (a valid authenticated clear that
## could not finalize its M25 claim). New scheduling is blocked until reset/recovery.
func is_fatal() -> bool:
	return _fatal

static func _bool_true(v) -> bool:
	return typeof(v) == TYPE_BOOL and v == true
