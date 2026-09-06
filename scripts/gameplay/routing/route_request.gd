extends RefCounted
## RouteRequest — preload this script
## (res://scripts/gameplay/routing/route_request.gd) rather than relying on
## global class_name lookup (AL-001).
##
## M16 — the narrow input a RoutingSystem receives. It represents EXACTLY ONE
## already-assigned, already-reserved target (M15/TargetSelector decided it).
## It deliberately carries NO alternate candidate list, NO color-candidate list,
## NO random fallback, NO target-selection callback and NO reservation-mutation
## callback — so a routing implementation structurally cannot retarget
## (ADR-024, docs/05_TECH_DECISIONS.md).
##
## Coordinate space (board-local cell units, resolution-independent):
##   - board top-left boundary = Vector2(0, 0);
##   - one logical cell = 1.0 x 1.0 units;
##   - cell (x,y) spans x in [x, x+1], y in [y, y+1];
##   - cell center = Vector2(x + 0.5, y + 0.5);
##   - board rectangle spans x in [0, board_width], y in [0, board_height];
##   - slot origins live in this SAME space and MAY lie outside the board.
## This is NOT screen pixels and NOT global Canvas coordinates; presentation maps
## these to pixels later using live BoardRenderer geometry. Never embed 1080x2160
## or any UI pixel size into route data.
##
## BoardState is NOT stored here (it is mutable board truth) — it is passed as a
## method argument to for_target()/RoutingSystem/validator instead, so route data
## stays a detached value object (AL-020).

## Slot origin, board-local cell coordinates. May be outside the board rectangle.
var start_position: Vector2 = Vector2.ZERO
## The already-assigned target's flat row-major index.
var target_index: int = -1
## Canonical center of target_index's cell, board-local coordinates.
var target_position: Vector2 = Vector2.ZERO
var board_width: int = 0
var board_height: int = 0

## Canonical center of a cell index using BoardState's index/position API — index
## math is centralized in BoardState and must never be re-derived here.
## Returns Vector2(-inf, -inf) for an out-of-range index so callers/validators
## can detect the failure rather than get a plausible-but-wrong center.
static func center_of_index(board, index: int) -> Vector2:
	if board == null:
		return Vector2(-INF, -INF)
	var pos: Vector2i = board.get_cell_position(index)
	if pos.x < 0:
		return Vector2(-INF, -INF)
	return Vector2(float(pos.x) + 0.5, float(pos.y) + 0.5)

## Build a request for an already-assigned target. Derives target_position and
## board dimensions from BoardState so the caller cannot supply a mismatched
## center. Returns null for an out-of-range target index (fail closed — the
## caller must have a real assigned target).
static func for_target(board, a_start_position: Vector2, a_target_index: int) -> RefCounted:
	if board == null or not board.is_valid_index(a_target_index):
		return null
	var r = load("res://scripts/gameplay/routing/route_request.gd").new()
	r.start_position = a_start_position
	r.target_index = a_target_index
	r.target_position = center_of_index(board, a_target_index)
	r.board_width = board.get_width()
	r.board_height = board.get_height()
	return r
