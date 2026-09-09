extends "res://scripts/gameplay/routing/routing_system.gd"
## DispatchRoutingDouble — M19 TEST-ONLY configurable fake RoutingSystem.
## Preload it (AL-001). Satisfies the M16 compute_route contract so the
## ScrubbotDispatcher can be exercised without the production planner, and lets a
## test force every route-seam fault the dispatcher must reject (F-M19-STRICT-002)
## plus reset injection during compute_route (F-M19-STRICT-003).
##
## Modes:
##   "ok"          -> trivial valid 2-point route [origin, target center].
##   "fail"        -> NO_ROUTE failure for the request's own target.
##   "mismatch" /
##   "wrong_start" -> success route whose START does not match the request origin.
##   "wrong_end"   -> success route whose END is not the target centre.
##   "wrong_target"-> success route carrying a DIFFERENT target_index.
##   "nonfinite"   -> success route with a non-finite intermediate point.
##   "short"       -> success route with a single point (< 2).
##   "null"        -> returns null.
##   "junk_ref"    -> returns a plain RefCounted (not a RouteResult).
## Never retargets, never touches TargetSelector/ReservationState/BoardState.

var mode: String = "ok"
var call_count: int = 0
## Optional side effect invoked at the start of compute_route (e.g. inject
## dispatcher.reset()), to prove reset-during-routing rollback.
var on_compute: Callable = Callable()

func compute_route(request, _board, _access_query) -> RefCounted:
	call_count += 1
	if on_compute.is_valid():
		on_compute.call()
	if request == null:
		return RouteResult.failure(RouteResult.FailureReason.INVALID_REQUEST, -1)
	match mode:
		"fail":
			return RouteResult.failure(RouteResult.FailureReason.NO_ROUTE, request.target_index)
		"mismatch", "wrong_start":
			var bad := PackedVector2Array([request.start_position + Vector2(9.0, 9.0), request.target_position])
			return RouteResult.success_route(request.target_index, bad)
		"wrong_end":
			var bad_end := PackedVector2Array([request.start_position, request.target_position + Vector2(2.0, 2.0)])
			return RouteResult.success_route(request.target_index, bad_end)
		"wrong_target":
			var pts_wt := PackedVector2Array([request.start_position, request.target_position])
			return RouteResult.success_route(request.target_index + 1, pts_wt)
		"nonfinite":
			var nf := PackedVector2Array([request.start_position, Vector2(NAN, 0.0), request.target_position])
			return RouteResult.success_route(request.target_index, nf)
		"short":
			return RouteResult.success_route(request.target_index, PackedVector2Array([request.start_position]))
		"null":
			return null
		"junk_ref":
			return RefCounted.new()
		_:
			var pts := PackedVector2Array([request.start_position, request.target_position])
			return RouteResult.success_route(request.target_index, pts)
