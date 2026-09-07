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
## Owner/assignment IDs are unique and monotonically increasing for the
## dispatcher's whole lifetime. They are a dedicated token, never a color_id,
## slot index, or target index. The counter is NEVER restarted (not even on
## reset), so a delayed/stale completion can never collide with a fresh
## assignment (prompt: keep monotonic for dispatcher lifetime).

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const DispatchResult = preload("res://scripts/gameplay/dispatch/dispatch_result.gd")

const DEFAULT_SPEED := 6.0

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

## Monotonic assignment id. Never reused, never restarted for the dispatcher's
## lifetime — guarantees uniqueness even across resets.
var _next_owner_id: int = 0

## owner_id -> { "agent": ScrubbotAgent, "target": int, "arrived": bool }.
## One entry per live successful dispatch. The reservation for that target stays
## held while the entry exists (M20 resolves it on arrival).
var _active: Dictionary = {}

## Bind the separate systems. All are required except agent_parent (defaults to
## this node) and agent_factory (defaults to a real ScrubbotAgent). Returns
## false and stays unbound if any required collaborator is null.
func bind(board, selector, reservations, routing_system, routing_access, select_access,
		agent_parent: Node = null, agent_factory: Callable = Callable()) -> bool:
	if board == null or selector == null or reservations == null \
			or routing_system == null or routing_access == null or select_access == null:
		_bound = false
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
	if color_id < 0 or not _is_finite(start_position) or speed <= 0.0:
		return DispatchResult.failure(DispatchResult.FailureReason.INVALID_REQUEST)

	# Point the reachability truth at this slot origin (production adapter memoizes
	# the winning route; fixed test doubles simply ignore this hook).
	if _select_access.has_method("set_origin"):
		_select_access.set_origin(start_position)

	# WHAT + atomic reservation, in one call, using reachability truth. A raw
	# color candidate that is unreachable is never selected (AL-028).
	var owner_id: int = _next_owner_id
	var target: int = _selector.select_and_reserve(color_id, owner_id, _select_access)
	if target < 0:
		# No reachable target: no reservation, no route, no agent. The candidate
		# id was never actually reserved, so it is not consumed.
		return DispatchResult.failure(DispatchResult.FailureReason.NO_REACHABLE_TARGET)
	# The target is now reserved for owner_id — commit the id (never reused).
	_next_owner_id += 1

	# HOW, for that ONE reserved target only. Build the dispatcher's own request;
	# reuse the reachability probe's route when the adapter memoized it.
	var request = RouteRequest.for_target(_board, start_position, target)
	if request == null:
		# Defensive: target validated by the selector, so this should not happen.
		_reservations.release(target, owner_id)
		return DispatchResult.failure(DispatchResult.FailureReason.ROUTE_FAILED)

	var route = null
	if _select_access.has_method("consume_route"):
		route = _select_access.consume_route(target)
	if route == null or not route.success or route.target_index != target:
		route = _routing_system.compute_route(request, _board, _routing_access)
	if route == null or not route.success:
		# Route failure -> release reservation, spawn nothing, NO retarget.
		_reservations.release(target, owner_id)
		return DispatchResult.failure(DispatchResult.FailureReason.ROUTE_FAILED)

	# Exactly one agent. Assign fully or roll everything back.
	var agent = _make_agent()
	if not agent.assign(owner_id, color_id, request, route, speed):
		_reservations.release(target, owner_id)
		agent.free() # never leave an orphan node.
		return DispatchResult.failure(DispatchResult.FailureReason.AGENT_ASSIGN_FAILED)

	_agent_parent.add_child(agent)
	agent.agent_completed.connect(_on_agent_completed)
	_active[owner_id] = {"agent": agent, "target": target, "arrived": false}
	return DispatchResult.success_result(owner_id, target, agent)

# ------------------------------------------------------ completion (observe) --

## M19 observes completion ONLY to track active-agent lifecycle. It does NOT
## clear BoardState, release the successful reservation, or score — that is M20.
## The entry (and its held reservation) is preserved so M20 can resolve arrival
## from the owner/target mapping.
func _on_agent_completed(owner_id: int, _target_index: int, _color_id: int) -> void:
	if _resetting:
		return
	if _active.has(owner_id):
		_active[owner_id]["arrived"] = true

# ------------------------------------------------------------------ reset ----

## Explicit cancel-all. Cancels and frees every active agent, releases every
## dispatcher-owned reservation, and clears bookkeeping — leaving no orphan node
## and no delayed completion able to mutate the dispatcher afterwards. Does NOT
## mutate BoardState, and does NOT restart the owner-id counter.
func reset() -> void:
	_resetting = true
	for owner_id in _active.keys():
		var entry: Dictionary = _active[owner_id]
		var agent = entry["agent"]
		if agent != null and is_instance_valid(agent):
			if agent.agent_completed.is_connected(_on_agent_completed):
				agent.agent_completed.disconnect(_on_agent_completed)
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

static func _is_finite(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)
