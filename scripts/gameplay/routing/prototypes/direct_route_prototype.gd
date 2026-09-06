extends "res://scripts/gameplay/routing/routing_system.gd"
## DirectRoutePrototype — M17 Prototype A. Minimal deterministic baseline.
## Preload it (AL-001). Subclasses RoutingSystem (M16 contract).
##
## It emits the single straight segment [start_position, target_position] and
## succeeds ONLY when that one segment is accepted by the injected access truth
## and passes RouteValidator. If the straight segment is blocked it returns an
## explicit NO_ROUTE — it never bends around the blocker and never retargets.
##
## Purpose: minimum route distance / minimum point-count / easiest crossing
## reference for comparison. It is NOT a presumed production winner.

const RouteValidator = preload("res://scripts/gameplay/routing/route_validator.gd")

func compute_route(request, board, access_query) -> RefCounted:
	if request == null:
		return RouteResult.failure(RouteResult.FailureReason.INVALID_REQUEST, -1)
	var idx: int = request.target_index
	var req_reason: StringName = RouteValidator.validate_request(request, board)
	if req_reason != RouteResult.FailureReason.NONE:
		return RouteResult.failure(req_reason, idx)
	if access_query == null or not access_query.has_method("is_segment_traversable"):
		return RouteResult.failure(RouteResult.FailureReason.MISSING_ACCESS_QUERY, idx)
	if not access_query.is_segment_traversable(request.start_position, request.target_position, idx):
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, idx)
	var points := PackedVector2Array([request.start_position, request.target_position])
	return RouteResult.success_route(idx, points)
