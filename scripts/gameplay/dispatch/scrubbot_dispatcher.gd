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
## strict-v2 (F-M19-STRICT-001..004): bind is initialization-only and fail
## closed — every collaborator is category/API/bundle-coherence validated BEFORE
## any ref is committed, so a scalar/junk/partial dependency or a split-brain
## bundle (a selector/reservation/access bound to a DIFFERENT board) can never be
## stored. Bundle coherence is re-checked live before every dispatch, so a
## sibling rebound after bind fails closed before any new reservation. External
## route/access/agent-factory results are validated through ONE shared path
## (RouteValidator + a fresh-unparented-ScrubbotAgent gate) before an agent is
## created or attached. A dispatch-in-progress guard rejects recursive dispatch,
## and a reset generation token cancels a pending assignment if reset() is
## injected from any external callback. Completion is validated against immutable
## per-assignment identity (owner/target/color/agent).
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
## any escaped call reaches it.
const _SELECTOR_API := ["select_and_reserve", "is_bound_to"]
const _RESERVATION_API := ["reserve", "release", "release_for_owner", "get_target_for_owner", "get_owner", "is_bound_to"]
const _ROUTING_API := ["compute_route"]
const _ROUTING_ACCESS_API := ["is_segment_traversable", "is_bound_to"]
const _SELECT_ACCESS_API := ["is_targetable"]

# --- injected collaborators (all null until bind()) --------------------------
var _board = null
var _selector = null            ## TargetSelector (already bound to its deps).
var _reservations = null        ## ReservationState (dispatcher owns released ids).
var _routing_system = null      ## RoutingSystem.compute_route(request, board, access).
var _routing_access = null      ## segment-traversable access truth for routing.
var _select_access = null       ## is_targetable() reachability truth for selection.
var _agent_parent: Node = null  ## node the spawned agents are attached under.
var _agent_factory: Callable = Callable() ## optional () -> Node2D agent factory.

var _bound: bool = false
var _resetting: bool = false
## Serial re-entry guard: at most one dispatch() body executes at a time. A
## recursive dispatch from an injected callback returns REENTRANT and creates no
## reservation/agent (F-M19-STRICT-003).
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
## required collaborator is category/API validated and proven bundle-coherent
## (all bound to the SAME board / reservation / routing / access identities)
## BEFORE any ref is committed. Any failure returns false and leaves the
## dispatcher fully unbound with no refs and no active assignments. bind() while
## already bound returns false and changes nothing (no destructive rebind in
## M19 — construct a new dispatcher to replace the whole bundle).
func bind(board, selector, reservations, routing_system, routing_access, select_access,
		agent_parent: Node = null, agent_factory: Callable = Callable()) -> bool:
	if _bound:
		return false
	if not (board is BoardState):
		return false
	if not _is_ref_with(selector, _SELECTOR_API):
		return false
	if not _is_ref_with(reservations, _RESERVATION_API):
		return false
	if not _is_object_with(routing_system, _ROUTING_API):
		return false
	if not _is_object_with(routing_access, _ROUTING_ACCESS_API):
		return false
	if not _is_object_with(select_access, _SELECT_ACCESS_API):
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
	# Numeric request boundaries BEFORE any side effect (F-M19-STRICT-004): reject
	# negative color, non-finite origin, and non-finite / non-positive speed. NaN
	# fails `is_finite`, so it can never slip past a bare `speed <= 0` comparison.
	if color_id < 0 or not _is_finite_vec(start_position) or not is_finite(speed) or speed <= 0.0:
		return DispatchResult.failure(DispatchResult.FailureReason.INVALID_REQUEST)
	# Live bundle-coherence drift: a sibling may have been rebound after bind. Fail
	# closed BEFORE any reservation/route (F-M19-STRICT-001).
	if not _bundle_coherent(_board, _selector, _reservations, _routing_system, _routing_access, _select_access):
		return DispatchResult.failure(DispatchResult.FailureReason.COHERENCE_FAILED)

	_in_dispatch = true
	var my_gen: int = _generation

	# Point the reachability truth at this slot origin (production adapter memoizes
	# the winning route; fixed test doubles simply ignore this hook).
	if _select_access.has_method("set_origin"):
		_select_access.set_origin(start_position)

	# WHAT + atomic reservation, in one call, using reachability truth. A raw
	# color candidate that is unreachable is never selected (AL-028).
	var owner_id: int = _next_owner_id
	var target: int = _selector.select_and_reserve(color_id, owner_id, _select_access)
	# select_access.is_targetable may have injected reset(). If so, release any
	# reservation that got acquired for this pending owner and abort.
	if _reset_since(my_gen):
		if target >= 0:
			_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))
	if target < 0:
		# No reachable target: no reservation, no route, no agent. The candidate
		# id was never actually reserved, so it is not consumed.
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.NO_REACHABLE_TARGET))
	# The target is now reserved for owner_id — commit the id (never reused).
	_next_owner_id += 1

	# HOW, for that ONE reserved target only. Build the dispatcher's own request;
	# reuse the reachability probe's route when the adapter memoized it.
	var request = RouteRequest.for_target(_board, start_position, target)
	if request == null:
		# Defensive: target validated by the selector, so this should not happen.
		_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.ROUTE_FAILED))

	var route = null
	if _select_access.has_method("consume_route"):
		route = _select_access.consume_route(target)
	if not _route_ok(route, request, target):
		route = _routing_system.compute_route(request, _board, _routing_access)
	# compute_route may have injected reset().
	if _reset_since(my_gen):
		_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))
	if not _route_ok(route, request, target):
		# Route failure -> release reservation, spawn nothing, NO retarget. Both a
		# cached and a freshly-computed route pass the SAME validation path.
		_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.ROUTE_FAILED))

	# Exactly one agent. The factory product must be a fresh, unparented, still
	# UNASSIGNED ScrubbotAgent/subclass before the dispatcher will own it.
	var agent = _make_agent()
	if _reset_since(my_gen):
		_reservations.release(target, owner_id)
		if _dispatcher_ownable(agent):
			agent.free()
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))
	if not _dispatcher_ownable(agent):
		# Invalid/foreign factory product: release the reservation, create no
		# child, and NEVER free/mutate a foreign parented/reused object.
		_reservations.release(target, owner_id)
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.AGENT_ASSIGN_FAILED))

	if not agent.assign(owner_id, color_id, request, route, speed):
		_reservations.release(target, owner_id)
		agent.free() # our own fresh agent; never leave an orphan node.
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.AGENT_ASSIGN_FAILED))
	# agent.assign is a controllable seam for subclasses; it may inject reset().
	if _reset_since(my_gen):
		_reservations.release(target, owner_id)
		agent.free()
		return _end_dispatch(DispatchResult.failure(DispatchResult.FailureReason.RESETTING))

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
	# select_access coherence is verified only when it exposes the read-only
	# identity query (the production ProductionTargetAccess does); a fixed
	# reachability double without one cannot drift a board/routing bundle.
	if select_access.has_method("is_coherent_with"):
		var sa_ok = select_access.is_coherent_with(board, routing_system, routing_access)
		if typeof(sa_ok) != TYPE_BOOL or not sa_ok:
			return false
	return true

static func _is_ref_with(obj, api: Array) -> bool:
	if not (obj is RefCounted):
		return false
	return _has_all_methods(obj, api)

static func _is_object_with(obj, api: Array) -> bool:
	if typeof(obj) != TYPE_OBJECT:
		return false
	return _has_all_methods(obj, api)

static func _has_all_methods(obj, api: Array) -> bool:
	for m in api:
		if not obj.has_method(m):
			return false
	return true

static func _is_live_node(n) -> bool:
	return n is Node and is_instance_valid(n) and not n.is_queued_for_deletion()

static func _is_finite_vec(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
