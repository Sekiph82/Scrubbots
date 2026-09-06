extends RefCounted
## RouteValidator — preload this script
## (res://scripts/gameplay/routing/route_validator.gd) rather than relying on
## global class_name lookup (AL-001). Stateless: only static functions.
##
## M16 — reusable validity checks for the routing CONTRACT. It does NOT invent
## path topology (4-neighbour vs 8-neighbour vs curves vs pixel collision vs
## AStar vs navmesh) — that is M17. It only checks that a request is well-formed
## and that a claimed route honours the contract, delegating every "can a bot
## cross this segment?" question to injected authoritative access truth
## (ADR-024, docs/05_TECH_DECISIONS.md).
##
## The injected access contract is narrow:
##   access_query.is_segment_traversable(from_position, to_position, target_index)
##       -> bool
## representing the locked semantic law (non-target ACTIVE cells block;
## CLEARED/background/outside-board free space is open; the assigned ACTIVE target
## may be the final endpoint). M16 does not decide HOW that truth is computed.

const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const RouteResult = preload("res://scripts/gameplay/routing/route_result.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

## Tolerant point equality — routing coordinates are exact half-integers, so a
## small epsilon absorbs float representation without accepting a materially
## wrong endpoint (a whole cell away is ~1.0, far above this).
const POINT_EPS := 0.0001

## Validate the request against live BoardState. Returns FailureReason.NONE when
## structurally valid, else the specific stable reason.
static func validate_request(request, board) -> StringName:
	if request == null:
		return RouteResult.FailureReason.INVALID_REQUEST
	if board == null:
		return RouteResult.FailureReason.INVALID_REQUEST
	if request.board_width != board.get_width() or request.board_height != board.get_height():
		return RouteResult.FailureReason.INVALID_REQUEST
	if not board.is_valid_index(request.target_index):
		return RouteResult.FailureReason.INVALID_TARGET
	if board.get_cell_state(request.target_index) != BoardState.CellState.ACTIVE:
		return RouteResult.FailureReason.TARGET_NOT_ACTIVE
	# target_position must be the canonical center of target_index (no drift).
	var canonical: Vector2 = RouteRequest.center_of_index(board, request.target_index)
	if not request.target_position.is_equal_approx(canonical):
		return RouteResult.FailureReason.INVALID_REQUEST
	return RouteResult.FailureReason.NONE

## Validate a claimed SUCCESS route for a request through injected access truth.
## Returns FailureReason.NONE when the route is genuinely valid, else the reason
## it is rejected. A failure result (success == false) is not this function's
## job — check success first; here we assume a route is being asserted valid.
##
## No retarget ever happens here: this only accepts or rejects the route for the
## request's own target_index.
static func validate_route(request, result, board, access_query) -> StringName:
	var req_reason: StringName = validate_request(request, board)
	if req_reason != RouteResult.FailureReason.NONE:
		return req_reason
	if result == null or not result.success:
		return RouteResult.FailureReason.INVALID_ROUTE
	# The route must be for the SAME already-assigned target.
	if result.target_index != request.target_index:
		return RouteResult.FailureReason.INVALID_ROUTE
	var points: PackedVector2Array = result.get_points()
	if points.size() < 2:
		return RouteResult.FailureReason.INVALID_ROUTE
	# Exact endpoints: starts at slot origin, ends at assigned target center.
	if not points[0].is_equal_approx(request.start_position):
		return RouteResult.FailureReason.INVALID_ROUTE
	if not points[points.size() - 1].is_equal_approx(request.target_position):
		return RouteResult.FailureReason.INVALID_ROUTE
	# Access truth is mandatory — no route may be trusted without it (fail closed).
	if access_query == null or not access_query.has_method("is_segment_traversable"):
		return RouteResult.FailureReason.MISSING_ACCESS_QUERY
	# Every consecutive segment must be accepted by authoritative access truth.
	for i in range(points.size() - 1):
		if not access_query.is_segment_traversable(points[i], points[i + 1], request.target_index):
			return RouteResult.FailureReason.INVALID_ROUTE
	return RouteResult.FailureReason.NONE
