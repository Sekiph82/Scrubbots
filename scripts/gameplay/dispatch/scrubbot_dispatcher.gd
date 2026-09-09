extends Node
## ScrubbotDispatcher — preload this script
## (res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd) rather than relying
## on global class_name lookup (AL-001 / ADR-009).
##
## M19 — dispatch ORCHESTRATION ONLY. It wires the already-separate systems
## together for exactly one slot/color request at a time and structurally
## enforces the locked one-by-one flow (CLAUDE.md §3, docs/01_GAMEPLAY_SPEC.md):
##
##   slot/color request
##   -> TargetSelector.select_and_reserve()  (WHAT + atomic reservation, using
##      the injected reachability truth — a raw color candidate is NOT enough)
##   -> RouteRequest.for_target()
##   -> RoutingSystem.compute_route()         (HOW, for that one reserved target)
##   -> route fails  -> release reservation, spawn nothing (NO retarget)
##   -> route ok     -> instantiate exactly ONE ScrubbotAgent, assign()
##   -> assign fails -> release reservation, free the agent, spawn nothing
##   -> assign ok    -> attach the one agent, keep the reservation held
##
## It NEVER (that is M20+ orchestration):
##   - mutates BoardState (ACTIVE->CLEARED on arrival);
##   - resolves/releases a SUCCESSFUL reservation on arrival;
##   - scores;
##   - retargets after a route failure;
##   - spawns a fallback/second bot for one request.
##
## It NEVER selects a target itself (TargetSelector), computes route geometry
## (RoutingSystem), owns reservation storage (ReservationState), or carries a
## cell color as a resource — those remain their own modules.
##
## strict-v2 (F-M19-STRICT-001..004; V02 + V03 second-stage closure):
##   - bind is initialization-only and fail-closed. Every injected collaborator
##     is category-narrowed to the production lifecycle (RefCounted + narrow API;
##     only agent_parent is a Node) and proven bundle-coherent (all bound to the
##     SAME board / reservation / routing / access identities) BEFORE any ref is
##     committed. select_access MUST expose is_targetable AND is_coherent_with —
##     coherence is mandatory, never an absence-based exemption.
##   - the serial re-entry guard is armed and the reset generation captured
##     BEFORE the first live collaborator callback (the live coherence probe), so
##     recursion/reset injected from ANY coherence seam is covered.
##   - the reset generation is re-checked immediately after EVERY external
##     boundary (live coherence, set_origin, select_and_reserve, consume_route,
##     compute_route, factory, assign, add_child); once it moves, no new
##     downstream phase begins, the pending reservation is released and any
##     dispatcher-owned fresh agent is freed.
##   - exact bundle coherence is re-checked between phases, so a sibling that
##     drifts inside an injected callback aborts the pending dispatch before it
##     commits, without disturbing prior committed assignments.
##   - a NON-NULL cached route that fails shared validation is a route-seam
##     failure (release + ROUTE_FAILED, NO fresh compute); only a null memo
##     permits fresh routing.
##   - an explicit agent_factory that becomes invalid after bind fails closed
##     (no silent default-agent substitution).
##   - after assign() returns true the agent's postconditions (valid, unparented,
##     MOVING, exact owner/color/target) are validated before attach.
##   - completion is validated against immutable owner/target/color/agent identity.
##
## Owner/assignment IDs are unique and monotonically increasing for the
## dispatcher's whole lifetime. They are a dedicated token, never a color_id,
## slot index, or target index. The counter is NEVER restarted (not even on
## reset), so a delayed/stale completion can never collide with a fresh
## assignment (prompt: keep monotonic for dispatcher lifetime).

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const DispatchResult = preload("res://scripts/gameplay/dispatch/dispatch_result.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

const DEFAULT_SPEED := 6.0

## Narrow required API surfaces validated at bind (F-M19-STRICT-001). A dependency
## missing any listed method is a partial/junk dependency and fails closed before
## any escaped call reaches it. select_access requires is_coherent_with — bundle
## coherence is mandatory, not optional (V03 F-M19-STRICT-001.A).
const _SELECTOR_API := ["select_and_reserve", "is_bound_to"]
const _RESERVATION_API := ["reserve", "release", "release_for_owner", "get_target_for_owner", "get_owner", "is_bound_to"]
const _ROUTING_API := ["compute_route"]
const _ROUTING_ACCESS_API := ["is_segment_traversable", "is_bound_to"]
const _SELECT_ACCESS_API := ["is_targetable", "is_coherent_with"]

# --- injected collaborators (all null until bind()) --------------------------
var _board = null
var _selector = null            ## TargetSelector (already bound to its deps).
var _reservations = null        ## ReservationState (dispatcher owns released ids).
var _routing_system = null      ## RoutingSystem.compute_route(request, board, access).
var _routing_access = null      ## segment-traversable access truth for routing.
var _select_access = null       ## is_targetable() reachability truth for selection.
var _agent_parent: Node = null  ## node the spawned agents are attached under.
var _agent_factory: Callable = Callable() ## optional () -> Node2D agent factory.
## Whether an explicit factory Callable was intentionally supplied at bind. Lets
## _make_agent distinguish "no factory configured" from "explicit factory whose
## target was freed after bind" (V03 F-M19-STRICT-002.B).
var _explicit_factory: bool = false

var _bound: bool = false
var _resetting: bool = false
## Serial re-entry guard: at most one dispatch() body executes at a time. Armed
## BEFORE the first live collaborator callback so recursion from any coherence
## seam is covered (V03 F-M19-STRICT-003.A). A recursive dispatch returns
## REENTRANT and creates no reservation/agent/owner-id.
var _in_dispatch: bool = false
## Monotonic reset generation. reset() increments it; a dispatch captures it at
## start and, after every external-callback boundary, aborts (releasing the
## pending reservation and freeing any dispatcher-owned fresh agent) if it moved.
var _generation: int = 0

## Monotonic assignment id. Never reused, never restarted for the dispatcher's
## lifetime — guarantees uniqueness even across resets.
var _next_owner_id: int = 0

## owner_id -> { "owner": int, "target": int, "color": int, "agent": ScrubbotAgent,
## "cb": Callable, "arrived": bool }. One entry per live successful dispatch. The
## reservation for that target stays held while the entry exists (M20 resolves it).
var _active: Dictionary = {}

## Bind the separate systems (initialization-only, F-M19-STRICT-001). Every
## required collaborator is category-narrowed (RefCounted + narrow API; only
## agent_parent may be a Node) and proven bundle-coherent BEFORE any ref is
## committed. Any failure returns false and leaves the dispatcher fully unbound.
## bind() while already bound returns false and changes nothing (no destructive
## rebind in M19 — construct a new dispatcher to replace the whole bundle).
func bind(board, selector, reservations, routing_system, routing_access, select_access,
		agent_parent: Node = null, agent_factory: Callable = Callable()) -> bool:
	if _bound:
		return false
	if not (board is BoardState):
		return false
	# All injected collaborators are the production RefCounted lifecycle category
	# (V03 F-M19-STRICT-001.B): a method-compatible externally-freeable Node is
	# rejected, so it can never become a stale callable inside the bundle.
	if not _is_ref_with(selector, _SELECTOR_API):
		return false
	if not _is_ref_with(reservations, _RESERVATION_API):
		return false
	if not _is_ref_with(routing_system, _ROUTING_API):
		return false
	if not _is_ref_with(routing_access, _ROUTING_ACCESS_API):
		return false
	if not _is_ref_with(select_access, _SELECT_ACCESS_API):
		return false
	if agent_parent != null and not _is_live_node(agent_parent):
		return false
	if not (agent_factory == Callable() or agent_factory.is_valid()):
		return false
	# Bundle coherence: no split-brain assignment truth (F-M19-STRICT-001, AL-062).
	if not _bundle_coherent(board, selector, reservations, routing_system, routing_access, select_access):
		return false
	_board = board
	_selector = selector
	_reservations = reservations
	_routing_system = routing_system
	_routing_access = routing_access
	_select_access = select_access
	_agent_parent = agent_parent if agent_parent != null else self
	_agent_factory = agent_factory
	_explicit_factory = agent_factory.is_valid()
	_bound = true
	return true

func is_bound() -> bool:
	return _bound

# --------------------------------------------------------------- dispatch ----

## One synchronous dispatch attempt for one slot/color request. Produces AT MOST
## one ScrubbotAgent. Every failure path spawns zero agents and leaves no orphan
## node and no dangling reservation. Returns a detached DispatchResult.
func dispatch(color_id: int, start_position: Vector2, speed: float = DEFAULT_SPEED) -> RefCounted:
	if not _bound or _resetting:
		return DispatchResult.failure(DispatchResult.FailureReason.RESETTING if _resetting
			else DispatchResult.FailureReason.INVALID_REQUEST)
	# Serial re-entry guard: recursive dispatch from an injected callback fails
	# closed with no side effect (F-M19-STRICT-003).
	if _in_dispatch:
		return DispatchResult.failure(DispatchResult.FailureReason.REENTRANT)
	# Pure numeric request boundaries BEFORE any collaborator callback
	# (F-M19-STRICT-004): reject negative color, non-finite origin, and non-finite
	# / non-positive speed. NaN fails is_finite, so it never slips past `<= 0`.
	if color_id < 0 or not _is_finite_vec(start_position) or not is_finite(speed) or speed <= 0.0:
		return DispatchResult.failure(DispatchResult.FailureReason.INVALID_REQUEST)

	# V03 F-M19-STRICT-003.A: arm the serial guard and capture the reset
	# generation BEFORE the first live collaborator callback (the coherence probe
	# below is the first external boundary and can inject recursion/reset).
	_in_dispatch = true
	var my_gen: int = _generation

	# Live bundle-coherence drift: a sibling may have been rebound after bind.
	var coherent: bool = _bundle_coherent(_board, _selector, _reservations, _routing_system, _routing_access, _select_access)
	if _reset_since(my_gen):
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))
	if not coherent:
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.COHERENCE_FAILED))

	# Point the reachability truth at this slot origin (production adapter memoizes
	# the winning route; fixed test doubles simply ignore this hook).
	if _select_access.has_method("set_origin"):
		_select_access.set_origin(start_position)
		if _reset_since(my_gen):
			return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))

	# WHAT + atomic reservation, in one call, using reachability truth. A raw
	# color candidate that is unreachable is never selected (AL-028).
	var owner_id: int = _next_owner_id
	var target: int = _selector.select_and_reserve(color_id, owner_id, _select_access)
	if _reset_since(my_gen):
		if target >= 0:
			_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))
	if target < 0:
		# No reachable target: no reservation, no route, no agent.
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.NO_REACHABLE_TARGET))
	# The target is now reserved for owner_id — commit the id (never reused).
	_next_owner_id += 1
	# V03 F-M19-STRICT-001.C/003.C: a sibling may have drifted inside the selection
	# callback. Re-check exact bundle coherence before any further side effect.
	if not _bundle_coherent(_board, _selector, _reservations, _routing_system, _routing_access, _select_access):
		_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.COHERENCE_FAILED))

	# HOW, for that ONE reserved target only. Build the dispatcher's own request.
	var request = RouteRequest.for_target(_board, start_position, target)
	if request == null:
		# Defensive: target validated by the selector, so this should not happen.
		_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.ROUTE_FAILED))

	# V03 F-M19-STRICT-002.A: distinguish a MISSING cached route (null -> fresh
	# compute is legitimate) from a PRESENT-but-invalid cached route (a route-seam
	# failure that must NOT silently fall back to a fresh compute).
	var route = null
	var had_cache: bool = false
	if _select_access.has_method("consume_route"):
		route = _select_access.consume_route(target)
		if _reset_since(my_gen):
			_reservations.release(target, owner_id)
			return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))
		had_cache = route != null
	if had_cache:
		if not _route_ok(route, request, target):
			_reservations.release(target, owner_id)
			return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.ROUTE_FAILED))
	else:
		route = _routing_system.compute_route(request, _board, _routing_access)
		if _reset_since(my_gen):
			_reservations.release(target, owner_id)
			return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))
		if not _route_ok(route, request, target):
			# Route failure -> release reservation, spawn nothing, NO retarget.
			_reservations.release(target, owner_id)
			return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.ROUTE_FAILED))
	# Re-check bundle coherence after the routing boundary (drift detection).
	if not _bundle_coherent(_board, _selector, _reservations, _routing_system, _routing_access, _select_access):
		_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.COHERENCE_FAILED))

	# Exactly one agent. The factory product must be a fresh, unparented, still
	# UNASSIGNED ScrubbotAgent/subclass before the dispatcher will own it.
	var agent = _make_agent()
	if _reset_since(my_gen):
		_reservations.release(target, owner_id)
		if _dispatcher_ownable(agent):
			agent.free()
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))
	if not _dispatcher_ownable(agent):
		# Invalid/foreign factory product (incl. an invalidated explicit factory):
		# release the reservation, create no child, and NEVER free/mutate a
		# foreign parented/reused object.
		_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.AGENT_ASSIGN_FAILED))
	# Re-check bundle coherence after the factory boundary (drift detection).
	if not _bundle_coherent(_board, _selector, _reservations, _routing_system, _routing_access, _select_access):
		_reservations.release(target, owner_id)
		agent.free()
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.COHERENCE_FAILED))

	if not agent.assign(owner_id, color_id, request, route, speed):
		_reservations.release(target, owner_id)
		agent.free() # our own fresh agent; never leave an orphan node.
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.AGENT_ASSIGN_FAILED))
	if _reset_since(my_gen):
		_reservations.release(target, owner_id)
		agent.free()
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))
	# V03 F-M19-STRICT-002.C: a lying subclass can return true from assign() while
	# remaining UNASSIGNED or recording the wrong identity. Validate postconditions.
	if not _agent_assigned_ok(agent, owner_id, color_id, target):
		_reservations.release(target, owner_id)
		agent.free()
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.AGENT_ASSIGN_FAILED))
	# Re-check bundle coherence after the assign boundary (drift detection).
	if not _bundle_coherent(_board, _selector, _reservations, _routing_system, _routing_access, _select_access):
		_reservations.release(target, owner_id)
		agent.free()
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.COHERENCE_FAILED))

	# Parent must still be attachable at attach time (freed/queued-for-delete
	# parent -> clean rollback, no orphan).
	if not _is_live_node(_agent_parent):
		_reservations.release(target, owner_id)
		agent.free()
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.AGENT_ASSIGN_FAILED))

	_agent_parent.add_child(agent)
	# _ready / add_child lifecycle may inject reset().
	if _reset_since(my_gen):
		_reservations.release(target, owner_id)
		var p = agent.get_parent()
		if p != null:
			p.remove_child(agent)
		agent.free()
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))

	# Immutable per-assignment identity for completion validation (F-M19-STRICT-003).
	# Bind the agent onto the completion callback so a stale/foreign source is
	# structurally distinguishable.
	var cb := Callable(self, "_on_agent_completed").bind(agent)
	agent.agent_completed.connect(cb)
	_active[owner_id] = {"owner": owner_id, "target": target, "color": color_id,
		"agent": agent, "cb": cb, "arrived": false}
	return _end_dispatch(DispatchResult.success_result(owner_id, target, agent))

## Clear the in-dispatch guard and return the result (single exit for the guarded
## body, since GDScript has no try/finally).
func _end_dispatch(result: RefCounted) -> RefCounted:
	_in_dispatch = false
	return result

func _reset_since(my_gen: int) -> bool:
	return _generation != my_gen

# ------------------------------------------------------ completion (observe) --

## M19 observes completion ONLY to track active-agent lifecycle. It does NOT
## clear BoardState, release the successful reservation, or score — that is M20.
## The completion is accepted only when the payload AND the emitting agent match
## the immutable assignment identity (F-M19-STRICT-003): correct owner, target,
## color and exact agent instance. Anything mismatched/stale is ignored;
## repeated correct completion stays idempotently arrived.
func _on_agent_completed(owner_id: int, target_index: int, color_id: int, src_agent) -> void:
	if _resetting:
		return
	if not _active.has(owner_id):
		return
	var entry: Dictionary = _active[owner_id]
	if src_agent != entry["agent"]:
		return
	if target_index != int(entry["target"]):
		return
	if color_id != int(entry["color"]):
		return
	entry["arrived"] = true

# ------------------------------------------------------------------ reset ----

## Explicit cancel-all. Cancels and frees every active agent, releases every
## dispatcher-owned reservation, and clears bookkeeping — leaving no orphan node
## and no delayed completion able to mutate the dispatcher afterwards. Advances
## the reset generation so a dispatch currently mid-flight (reset injected from
## one of its external callbacks) aborts and releases its pending reservation.
## Does NOT mutate BoardState, and does NOT restart the owner-id counter.
func reset() -> void:
	_resetting = true
	_generation += 1
	for owner_id in _active.keys():
		var entry: Dictionary = _active[owner_id]
		var agent = entry["agent"]
		if agent != null and is_instance_valid(agent):
			if agent.agent_completed.is_connected(entry["cb"]):
				agent.agent_completed.disconnect(entry["cb"])
			agent.cancel()
			var parent = agent.get_parent()
			if parent != null:
				parent.remove_child(agent)
			agent.free()
		_reservations.release_for_owner(owner_id)
	_active.clear()
	_resetting = false

# ------------------------------------------------------------- read-only -----

func get_active_count() -> int:
	return _active.size()

func has_owner(owner_id: int) -> bool:
	return _active.has(owner_id)

func get_target_for_owner(owner_id: int) -> int:
	if _active.has(owner_id):
		return int(_active[owner_id]["target"])
	return -1

func get_agent_for_owner(owner_id: int):
	if _active.has(owner_id):
		return _active[owner_id]["agent"]
	return null

func has_arrived(owner_id: int) -> bool:
	return _active.has(owner_id) and bool(_active[owner_id]["arrived"])

## Next owner id that WOULD be handed out — for tests asserting monotonicity.
func peek_next_owner_id() -> int:
	return _next_owner_id

# ------------------------------------------------------------- internals -----

func _make_agent():
	# An explicit factory that was configured at bind but is now invalid (its
	# target freed / Callable invalidated) fails closed — NO silent default-agent
	# substitution (V03 F-M19-STRICT-002.B).
	if _explicit_factory and not _agent_factory.is_valid():
		return null
	if _agent_factory.is_valid():
		return _agent_factory.call()
	return ScrubbotAgent.new()

## A factory product the dispatcher may own: a real ScrubbotAgent (or subclass),
## a valid instance, fresh UNASSIGNED, and unparented. Anything else (null,
## scalar, RefCounted, arbitrary Node, parented/assigned/moved/arrived/cancelled
## agent) is rejected and must NOT be freed or mutated by the dispatcher.
func _dispatcher_ownable(agent) -> bool:
	if not (agent is ScrubbotAgent):
		return false
	if not is_instance_valid(agent):
		return false
	if agent.get_parent() != null:
		return false
	if agent.get_state() != ScrubbotAgent.State.UNASSIGNED:
		return false
	return true

## Postconditions after agent.assign() returns true, before attach
## (V03 F-M19-STRICT-002.C): a truthful assign leaves the exact fresh agent
## MOVING, unparented, and recording this dispatch's owner/color/target. A lying
## subclass that returns true without truly assigning is rejected.
func _agent_assigned_ok(agent, owner_id: int, color_id: int, target: int) -> bool:
	if not is_instance_valid(agent):
		return false
	if agent.get_parent() != null:
		return false
	if agent.get_state() != ScrubbotAgent.State.MOVING:
		return false
	if agent.owner_id != owner_id:
		return false
	if agent.color_id != color_id:
		return false
	if agent.target_index != target:
		return false
	return true

## Shared route validation path for BOTH a cached and a freshly-computed route
## (F-M19-STRICT-002): a real RouteResult, for the exact reserved target, that is
## RouteValidator-clean for the exact request/board/routing-access. A null,
## scalar, junk, failure, or geometrically-invalid route fails here without a
## fault, so a malformed route can never reach agent creation.
func _route_ok(route, request, target: int) -> bool:
	if not (route is RouteResult):
		return false
	if route.target_index != target:
		return false
	return RouteValidator.validate_route(request, route, _board, _routing_access) == RouteResult.FailureReason.NONE

## Bundle coherence proof (bind AND live): every collaborator belongs to the SAME
## board / reservation / routing / access identities (F-M19-STRICT-001, AL-062).
## select_access coherence is MANDATORY (V03 F-M19-STRICT-001.A) — its presence is
## guaranteed by the bind API check, so it is always queried, never skipped.
func _bundle_coherent(board, selector, reservations, routing_system, routing_access, select_access) -> bool:
	var sel_ok = selector.is_bound_to(board, reservations)
	if typeof(sel_ok) != TYPE_BOOL or not sel_ok:
		return false
	var res_ok = reservations.is_bound_to(board)
	if typeof(res_ok) != TYPE_BOOL or not res_ok:
		return false
	var acc_ok = routing_access.is_bound_to(board)
	if typeof(acc_ok) != TYPE_BOOL or not acc_ok:
		return false
	var sa_ok = select_access.is_coherent_with(board, routing_system, routing_access)
	if typeof(sa_ok) != TYPE_BOOL or not sa_ok:
		return false
	return true

static func _is_ref_with(obj, api: Array) -> bool:
	if not (obj is RefCounted):
		return false
	for m in api:
		if not obj.has_method(m):
			return false
	return true

static func _is_live_node(n) -> bool:
	return n is Node and is_instance_valid(n) and not n.is_queued_for_deletion()

static func _is_finite_vec(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
