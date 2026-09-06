extends "res://scripts/gameplay/routing/routing_system.gd"
## RouteFakeRelay — M16 TEST-ONLY fake RoutingSystem. Preload it (AL-001).
##
## Second implementation of the SAME compute_route contract as
## route_fake_straight.gd, proving swappability. It emits a 3-point route with a
## single relay waypoint (the midpoint) between slot origin and assigned target
## center. It still invents NO real topology, never retargets, and never touches
## TargetSelector/ReservationState/BoardState — the midpoint is a fixed fake, not
## a pathfinding decision (M17 owns real routing).
## RouteResult is inherited from the RoutingSystem base (do not redeclare it).

func compute_route(request, _board, _access_query) -> RefCounted:
	if request == null:
		return RouteResult.failure(RouteResult.FailureReason.INVALID_REQUEST, -1)
	var mid: Vector2 = (request.start_position + request.target_position) * 0.5
	var pts := PackedVector2Array([request.start_position, mid, request.target_position])
	return RouteResult.success_route(request.target_index, pts)
