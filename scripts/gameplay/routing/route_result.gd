extends RefCounted
## RouteResult — preload this script
## (res://scripts/gameplay/routing/route_result.gd) rather than relying on
## global class_name lookup (AL-001).
##
## M16 — the detached, immutable-by-convention answer a RoutingSystem gives for
## exactly ONE already-assigned target (M15 decided WHAT; M16 answers HOW, or
## fails). It carries no candidate list, no alternate target, and no way to
## retarget: a route failure for target X is NOT permission to pick target Y
## (ADR-024, docs/05_TECH_DECISIONS.md).
##
## Coordinate space is board-local cell units (see route_request.gd): NOT screen
## pixels and NOT global Canvas coordinates.
##
## Success contract:
##   success == true; target_index == request.target_index; points.size() >= 2;
##   points[0] == request.start_position; points[-1] == request.target_position;
##   every consecutive segment accepted by injected access truth.
## Failure contract:
##   success == false; points empty; target_index still the requested target;
##   failure_reason is a stable StringName; no retarget occurs.
##
## "No route" is ordinary, first-class failure — never an exception.

## Stable failure categories. Used by RoutingSystem implementations and the
## route validator; stable enough for tests and debug output to assert on.
class FailureReason:
	const NONE := &"NONE"
	const INVALID_REQUEST := &"INVALID_REQUEST"
	const INVALID_TARGET := &"INVALID_TARGET"
	const TARGET_NOT_ACTIVE := &"TARGET_NOT_ACTIVE"
	const MISSING_ACCESS_QUERY := &"MISSING_ACCESS_QUERY"
	const NO_ROUTE := &"NO_ROUTE"
	const INVALID_ROUTE := &"INVALID_ROUTE"
	const NOT_IMPLEMENTED := &"NOT_IMPLEMENTED"

var success: bool = false
var target_index: int = -1
## Board-local cell-coordinate polyline. Empty on failure. Stored detached; also
## handed back detached via get_points() so callers cannot mutate routing truth.
var _points: PackedVector2Array = PackedVector2Array()
var failure_reason: StringName = FailureReason.NONE

## Build a success result. `points` is copied so the caller's array and the
## result's internal array cannot alias.
static func success_route(a_target_index: int, points: PackedVector2Array) -> RefCounted:
	var r = load("res://scripts/gameplay/routing/route_result.gd").new()
	r.success = true
	r.target_index = a_target_index
	r._points = points.duplicate()
	r.failure_reason = FailureReason.NONE
	return r

## Build a failure result. Points stay empty; the originally requested target is
## retained so callers can see WHICH target failed without any retarget.
static func failure(reason: StringName, a_target_index: int) -> RefCounted:
	var r = load("res://scripts/gameplay/routing/route_result.gd").new()
	r.success = false
	r.target_index = a_target_index
	r._points = PackedVector2Array()
	r.failure_reason = reason
	return r

## Detached copy — mutating it never touches internal routing truth.
func get_points() -> PackedVector2Array:
	return _points.duplicate()

func point_count() -> int:
	return _points.size()
