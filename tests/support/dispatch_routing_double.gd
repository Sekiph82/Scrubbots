extends "res://scripts/gameplay/routing/routing_system.gd"
## DispatchRoutingDouble — M19 TEST-ONLY configurable fake RoutingSystem.
## Preload it (AL-001). Satisfies the M16 compute_route contract so the
## ScrubbotDispatcher can be exercised without the production planner, and lets a
## test force route failure and agent-assign failure deterministically.
##
##   mode "ok"       -> trivial valid 2-point route [origin, target center].
##   mode "fail"     -> NO_ROUTE failure for the request's own target.
##   mode "mismatch" -> a "successful" route whose start point does NOT match the
##                      request origin, so the REAL ScrubbotAgent.assign() rejects
##                      it — proving the dispatcher's assign-failure rollback.
## Never retargets, never touches TargetSelector/ReservationState/BoardState.

var mode: String = "ok"
var call_count: int = 0

func compute_route(request, _board, _access_query) -> RefCounted:
	call_count += 1
	if request == null:
		return RouteResult.failure(RouteResult.FailureReason.INVALID_REQUEST, -1)
	if mode == "fail":
		return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, request.target_index)
	if mode == "mismatch":
		var bad := PackedVector2Array([request.start_position + Vector2(9.0, 9.0), request.target_position])
		return RouteResult.success_route(request.target_index, bad)
	var pts := PackedVector2Array([request.start_position, request.target_position])
	return RouteResult.success_route(request.target_index, pts)
