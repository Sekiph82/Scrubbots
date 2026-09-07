extends RefCounted
## ProductionTargetAccess — preload this script
## (res://scripts/gameplay/dispatch/production_target_access.gd) rather than
## relying on global class_name lookup (AL-001 / ADR-009).
##
## M19 — the PRODUCTION reachability/access truth TargetSelector consumes
## (its injected access_query, exposing is_targetable(index)). TargetSelector
## must never assume a raw color candidate is reachable (AL-028); it asks this.
##
## Single source of reachability truth: the SAME ProductionRoutingSystem that
## will later actually move the bot. is_targetable(index) is true iff production
## routing can compute a valid route from the current slot origin to that target.
## This deliberately avoids a second, independently-drifting reachability BFS —
## if routing can reach it, it is targetable; if not, it is not.
##
## Reachability depends on WHERE the bot leaves from, so the dispatcher calls
## set_origin() with the slot origin before each dispatch's selection pass.
##
## The winning target's RouteResult is memoized so the dispatcher can reuse it
## via consume_route() instead of recomputing the identical route — one routing
## computation per successful dispatch, not two. This owns NO selection, NO
## reservation, and NEVER mutates BoardState.

const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")

var _routing_system
var _routing_access
var _board
var _origin: Vector2 = Vector2.ZERO
## Memo of the most recent successful probe (winning target reuse).
var _last_index: int = -1
var _last_route = null

func _init(routing_system, routing_access, board, origin: Vector2 = Vector2.ZERO) -> void:
	_routing_system = routing_system
	_routing_access = routing_access
	_board = board
	_origin = origin

## Point subsequent reachability probes at a new slot origin. Clears the memo so
## a route from a previous origin can never be reused for a different dispatch.
func set_origin(origin: Vector2) -> void:
	_origin = origin
	_last_index = -1
	_last_route = null

func is_targetable(index: int) -> bool:
	if _routing_system == null or _board == null:
		return false
	var req = RouteRequest.for_target(_board, _origin, index)
	if req == null:
		return false
	var r = _routing_system.compute_route(req, _board, _routing_access)
	if r != null and r.success:
		_last_index = index
		_last_route = r
		return true
	return false

## The memoized RouteResult for `index` if it was the last successful probe,
## else null. Lets the dispatcher skip a redundant recompute for the winner.
func consume_route(index: int):
	if index == _last_index:
		return _last_route
	return null
