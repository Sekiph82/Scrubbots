extends "res://scripts/gameplay/routing/routing_system.gd"
## RouteFakeStraight — M16 TEST-ONLY fake RoutingSystem. Preload it (AL-001).
##
## Proves the swappable contract without any M17 algorithm: it emits a trivial
## 2-point route [slot origin, assigned target center] for the request's own
## target. It computes NO topology, never retargets, never touches
## TargetSelector/ReservationState/BoardState. A different fake
## (route_fake_relay.gd) satisfies the SAME compute_route contract, showing
## implementations are swappable with no TargetSelector source change.
## RouteResult is inherited from the RoutingSystem base (do not redeclare it).

func compute_route(request, _board, _access_query) -> RefCounted:
	if request == null:
		return RouteResult.failure(RouteResult.FailureReason.INVALID_REQUEST, -1)
	var pts := PackedVector2Array([request.start_position, request.target_position])
	return RouteResult.success_route(request.target_index, pts)
