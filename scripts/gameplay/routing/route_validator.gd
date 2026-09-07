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

## Reusable finite-Vector2 check (Godot 4.7.1). Rejects NaN and +INF/-INF on
## either axis so malformed coordinates never reach routing math
## (floor/distance/sorting) or an access query. Godot 4's global is_finite()
## returns false for both NaN and infinities.
static func is_finite_vector(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y)

## Narrow M16 BoardState method surface required before any board call. Any input
## that is not an object, or an object missing ANY of these methods, is malformed
## and must fail closed BEFORE the first method call (AL-040/AL-041: non-null is
## not enough — a scalar Variant like int/String/Vector2 has no has_method and
## would fault). The TYPE_OBJECT check runs first and short-circuits, so
## has_method is never called on a non-object. This guard cannot itself fault. The
## board is only queried, never stored/exposed.
static func _board_has_api(board) -> bool:
	if typeof(board) != TYPE_OBJECT:
		return false
	return board.has_method("get_width") \
		and board.has_method("get_height") \
		and board.has_method("is_valid_index") \
		and board.has_method("get_cell_state") \
		and board.has_method("get_cell_position")

## Validate the request against live BoardState. Returns FailureReason.NONE when
## structurally valid, else the specific stable reason.
static func validate_request(request, board) -> StringName:
	# Boundary guards (AL-040) BEFORE reading any request field / calling any board
	# method: a non-null but malformed request or board fails closed to
	# INVALID_REQUEST without a runtime fault. `x is RouteRequest` is false for
	# null and for arbitrary junk objects, and never throws.
	if not (request is RouteRequest):
		return RouteResult.FailureReason.INVALID_REQUEST
	if not _board_has_api(board):
		return RouteResult.FailureReason.INVALID_REQUEST
	# Non-finite coordinates are rejected BEFORE any access/routing geometry call
	# (center_of_index / is_valid_index below) so NaN/INF can never enter math.
	if not is_finite_vector(request.start_position):
		return RouteResult.FailureReason.INVALID_REQUEST
	if not is_finite_vector(request.target_position):
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
	# Result boundary (AL-040/AL-041) BEFORE reading .success/.failure_reason/
	# .target_index or get_points(): a scalar/RefCounted/null result fails closed to
	# INVALID_ROUTE with a false `is RouteResult`, which never throws. This runs
	# before the access loop, so a malformed result makes ZERO access calls.
	if not (result is RouteResult):
		return RouteResult.FailureReason.INVALID_ROUTE
	if not result.success:
		return RouteResult.FailureReason.INVALID_ROUTE
	# A claimed-success route must not carry a contradictory failure reason
	# (e.g. success == true with failure_reason == NO_ROUTE). Internal metadata
	# must be coherent before the route is trusted.
	if result.failure_reason != RouteResult.FailureReason.NONE:
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
	# Every route point must be finite BEFORE any access query — a malformed
	# (NaN/INF) point, including an intermediate one, is a structural defect and
	# must make ZERO access calls rather than being delegated to access truth.
	for p in points:
		if not is_finite_vector(p):
			return RouteResult.FailureReason.INVALID_ROUTE
	# Access truth is mandatory — no route may be trusted without it (fail closed).
	# A non-object access_query (null or a scalar Variant) has no has_method and
	# would fault, so the TYPE_OBJECT check runs first and short-circuits: has_method
	# is never called on a non-object. A real object lacking the method also fails
	# closed to the single stable MISSING_ACCESS_QUERY reason (AL-040/AL-041).
	if typeof(access_query) != TYPE_OBJECT or not access_query.has_method("is_segment_traversable"):
		return RouteResult.FailureReason.MISSING_ACCESS_QUERY
	# Every consecutive segment must be accepted by authoritative access truth.
	# The verdict must be an ACTUAL bool: a query returning int/string/null fails
	# closed rather than letting a truthy non-bool count as approval.
	for i in range(points.size() - 1):
		var verdict = access_query.is_segment_traversable(points[i], points[i + 1], request.target_index)
		if typeof(verdict) != TYPE_BOOL or not verdict:
			return RouteResult.FailureReason.INVALID_ROUTE
	return RouteResult.FailureReason.NONE

## Structural validator for a canonical FAILURE result. Returns NONE when the
## result is a coherent failure and the specific rejection reason otherwise. A
## well-formed failure: success == false; a non-NONE failure_reason; zero points;
## and (when a request is supplied) the originally requested target retained. This
## proves failure metadata cannot be internally contradictory, without widening
## RouteResult's mutable internals.
static func validate_failure_result(request, result) -> StringName:
	# A malformed/null result cannot be a coherent failure (AL-040: never
	# dereference a non-RouteResult). `x is RouteResult` is false for null/junk.
	if not (result is RouteResult):
		return RouteResult.FailureReason.INVALID_ROUTE
	# A success result is not a failure result.
	if result.success:
		return RouteResult.FailureReason.INVALID_ROUTE
	# A failure must name a real reason, never NONE.
	if result.failure_reason == RouteResult.FailureReason.NONE:
		return RouteResult.FailureReason.INVALID_ROUTE
	# A failure carries no route points.
	if result.point_count() != 0:
		return RouteResult.FailureReason.INVALID_ROUTE
	# Request handling at the boundary (AL-040): a null request keeps its
	# documented semantics (no target comparison). A non-null request that is NOT
	# a real RouteRequest is malformed and fails closed — its target_index is never
	# dereferenced. A real RouteRequest must have its target retained (no retarget).
	if request != null:
		if not (request is RouteRequest):
			return RouteResult.FailureReason.INVALID_ROUTE
		if result.target_index != request.target_index:
			return RouteResult.FailureReason.INVALID_ROUTE
	return RouteResult.FailureReason.NONE
