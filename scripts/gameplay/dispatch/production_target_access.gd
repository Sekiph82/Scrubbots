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
## routing can compute a valid route from the current slot origin to that target
## AND that route is RouteValidator-clean for the exact request/board/access. This
## deliberately avoids a second, independently-drifting reachability BFS — if
## routing can reach it validly, it is targetable; if not, it is not.
##
## strict-v2 (F-M19-STRICT-002): fail closed for malformed construction or
## dependencies (non-BoardState board, malformed routing system/access, non-finite
## origin, invalid index, malformed/mismatched/geometrically-invalid route). A
## success is memoized ONLY after RouteValidator accepts it. A FAILED probe clears
## any stale memo, set_origin clears the memo, and consume_route is ONE-SHOT (it
## returns the winning route once, then clears it).
##
## Reachability depends on WHERE the bot leaves from, so the dispatcher calls
## set_origin() with the slot origin before each dispatch's selection pass. This
## owns NO selection, NO reservation, and NEVER mutates BoardState. It never
## exposes its board/routing references (only a read-only identity coherence query).

const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

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

## Read-only exact-identity coherence query (F-M19-STRICT-001). Proves this access
## adapter carries the EXACT board/routing_system/routing_access bundle the
## dispatcher expects (reference identity, not merely compatible shapes), so a
## mismatched/mixed bundle is rejected upstream. Never exposes the references.
func is_coherent_with(board, routing_system, routing_access) -> bool:
	return _board != null and _board == board \
		and _routing_system != null and _routing_system == routing_system \
		and _routing_access != null and _routing_access == routing_access

## Point subsequent reachability probes at a new slot origin. Clears the memo so
## a route from a previous origin can never be reused for a different dispatch.
func set_origin(origin: Vector2) -> void:
	_origin = origin
	_clear_memo()

func is_targetable(index: int) -> bool:
	if _probe(index):
		return true
	# A failed probe must not leave a stale successful memo queryable.
	_clear_memo()
	return false

## Compute + validate a route to `index` from the current origin, memoizing the
## RouteResult ONLY on a RouteValidator-clean success. Fail closed (no fault) for
## every malformed dependency/argument.
func _probe(index: int) -> bool:
	if not (_board is BoardState):
		return false
	if typeof(_routing_system) != TYPE_OBJECT or not _routing_system.has_method("compute_route"):
		return false
	if _routing_access == null:
		return false
	if not (is_finite(_origin.x) and is_finite(_origin.y)):
		return false
	var req = RouteRequest.for_target(_board, _origin, index)
	if req == null:
		return false
	var r = _routing_system.compute_route(req, _board, _routing_access)
	# ONE shared validation path: a real RouteResult, success, exact target, and
	# access-clean geometry. Malformed/mismatched/invalid -> not targetable.
	if RouteValidator.validate_route(req, r, _board, _routing_access) != RouteResult.FailureReason.NONE:
		return false
	_last_index = index
	_last_route = r
	return true

## The memoized RouteResult for `index` if it was the last successful probe, else
## null. ONE-SHOT (F-M19-STRICT-002): returning the winning route clears the memo,
## so a second consume without a new successful probe returns null. Lets the
## dispatcher skip a redundant recompute for the winner exactly once.
func consume_route(index: int):
	if index == _last_index and _last_route != null:
		var r = _last_route
		_clear_memo()
		return r
	return null

func _clear_memo() -> void:
	_last_index = -1
	_last_route = null
