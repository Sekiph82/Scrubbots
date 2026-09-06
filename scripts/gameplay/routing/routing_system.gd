extends RefCounted
## RoutingSystem — preload this script
## (res://scripts/gameplay/routing/routing_system.gd) rather than relying on
## global class_name lookup (AL-001).
##
## M16 — the SWAPPABLE base contract for answering HOW a Scrubbot travels to an
## already-assigned target. M15/TargetSelector decides WHAT; this decides HOW,
## or reports explicit failure. It is deliberately NOT a global singleton so
## implementations can be swapped per caller with no TargetSelector change
## (ADR-024, docs/05_TECH_DECISIONS.md, CLAUDE.md hard rule 14).
##
## Contract (subclasses override compute_route):
##   compute_route(request, board, access_query) -> RouteResult
##
## Locked laws every implementation MUST obey:
##   - never choose or reserve another target;
##   - never call TargetSelector / ColorCandidateIndex / ReservationState;
##   - never mutate BoardState;
##   - never spawn or move a Scrubbot;
##   - "no route" is a first-class RouteResult failure, NOT a silent retarget
##     and NOT an exception.
##
## M16 does NOT implement a production path algorithm (no AStar, BFS/DFS,
## direct/curved strategy, collision radius, congestion). The final routing
## algorithm and movement language are M17. This base therefore returns a clean
## NOT_IMPLEMENTED failure rather than inventing a route; real implementations
## (and test fakes) subclass it.

const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")

## Base/default behaviour: no algorithm, so no route. Fails cleanly with the
## originally requested target retained. Subclasses override this.
func compute_route(request, _board, _access_query) -> RefCounted:
	var idx: int = request.target_index if request != null else -1
	return RouteResult.failure(RouteResult.FailureReason.NOT_IMPLEMENTED, idx)
