extends RefCounted
## ProductionAccessQuery — PRODUCTION access truth for routing. Preload it
## (AL-001). Owner-selected canonical translation of BoardState ACTIVE/CLEARED
## semantics into the injected segment access contract consumed by the M16
## RouteValidator and ProductionRoutingSystem (ADR-024/ADR-025).
##
## It performs NO target selection, owns NO reservation, and NEVER mutates
## BoardState. It NEVER exposes its board reference.
##
## Fail-closed (M17-C002 V03 F-M17-STRICT-007): the constructor recognizes ONLY a
## real BoardState; an unbound/invalid instance never throws — it reports
## everything blocked/false. is_bound_to() gives exact-identity board coherence so
## a same-size DIFFERENT board is rejected upstream (F-M17-STRICT-005).
##
## Locked semantics (ADR-019/ADR-024/ADR-025):
##   - CLEARED and outside-board / background free space are OPEN;
##   - a non-target ACTIVE cell is BLOCKED;
##   - the assigned ACTIVE target is enterable ONLY as the final arrival — a
##     segment whose `to` endpoint is exactly the target cell centre. The target
##     is never ordinary transit.
##
## Segment truth is EXACT deterministic supercover grid traversal (F-M17-STRICT-
## 002): it enumerates every logical cell the segment geometrically crosses, and
## at an exact lattice-corner crossing it also requires both diagonal "squeeze"
## cells to be enterable, so a diagonal cannot be cut between two blockers. There
## is NO fixed-step sampling in production correctness truth.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

enum CellClass { OPEN, BLOCKED, TARGET }

## Documented stable sentinel returned by cell_of_point() for a non-finite point:
## a far outside-board cell (treated as OPEN exterior; never a real board cell).
const OUTSIDE_SENTINEL := Vector2i(-2147483647, -2147483647)

## Set ONLY when a real BoardState is supplied; null otherwise (fail-closed).
var _board = null

func _init(board) -> void:
	if board != null and typeof(board) == TYPE_OBJECT and board is BoardState:
		_board = board

## Exact-identity coherence check (read-only). False when unbound, when `board`
## is null/scalar, or when it is a DIFFERENT object (even if same dimensions).
func is_bound_to(board) -> bool:
	if _board == null:
		return false
	if typeof(board) != TYPE_OBJECT:
		return false
	return board == _board

func _is_outside(cx: int, cy: int) -> bool:
	return cx < 0 or cy < 0 or cx >= _board.get_width() or cy >= _board.get_height()

## floor()-based cell of a board-local point. Non-finite -> documented sentinel.
func cell_of_point(p: Vector2) -> Vector2i:
	if not p.is_finite():
		return OUTSIDE_SENTINEL
	return Vector2i(int(floor(p.x)), int(floor(p.y)))

## Classify a board cell for the given target. Unbound/invalid -> BLOCKED
## (fail-closed). Outside-board -> OPEN.
func classify_cell(cx: int, cy: int, target_index: int) -> int:
	if _board == null:
		return CellClass.BLOCKED
	if _is_outside(cx, cy):
		return CellClass.OPEN
	var idx: int = _board.get_cell_index(cx, cy)
	if idx == target_index and _board.is_valid_index(target_index):
		return CellClass.TARGET
	if _board.get_cell_state(idx) == BoardState.CellState.CLEARED:
		return CellClass.OPEN
	return CellClass.BLOCKED

func _target_center(target_index: int) -> Vector2:
	var pos: Vector2i = _board.get_cell_position(target_index)
	return Vector2(float(pos.x) + 0.5, float(pos.y) + 0.5)

## Enterable? OPEN always; TARGET only on the arriving segment (to == target
## centre); BLOCKED never.
func _enterable(cx: int, cy: int, target_index: int, arriving: bool) -> bool:
	var c: int = classify_cell(cx, cy, target_index)
	if c == CellClass.OPEN:
		return true
	if c == CellClass.TARGET:
		return arriving
	return false

## Injected access contract (duck-typed). Fail-closed: unbound board, non-finite
## endpoints, or invalid target index all return false.
func is_segment_traversable(from_position: Vector2, to_position: Vector2, target_index: int) -> bool:
	if _board == null:
		return false
	if not from_position.is_finite() or not to_position.is_finite():
		return false
	if not _board.is_valid_index(target_index):
		return false
	var target_center: Vector2 = _target_center(target_index)
	var arriving: bool = to_position.is_equal_approx(target_center)
	return _supercover_ok(from_position, to_position, target_index, arriving)

## Exact deterministic supercover traversal. Every crossed cell must be
## enterable; at an exact corner crossing, both diagonal squeeze cells must be
## enterable too (conservative — no diagonal corner-cutting between blockers).
func _supercover_ok(from_p: Vector2, to_p: Vector2, target_index: int, arriving: bool) -> bool:
	var x0: float = from_p.x
	var y0: float = from_p.y
	var x1: float = to_p.x
	var y1: float = to_p.y
	var cx: int = int(floor(x0))
	var cy: int = int(floor(y0))
	var ex: int = int(floor(x1))
	var ey: int = int(floor(y1))
	if not _enterable(cx, cy, target_index, arriving):
		return false
	if cx == ex and cy == ey:
		return true

	var dx: float = x1 - x0
	var dy: float = y1 - y0
	var step_x: int = 0 if dx == 0.0 else (1 if dx > 0.0 else -1)
	var step_y: int = 0 if dy == 0.0 else (1 if dy > 0.0 else -1)

	var t_max_x: float = INF
	var t_delta_x: float = INF
	if step_x != 0:
		var nbx: float = float(cx + 1) if step_x > 0 else float(cx)
		t_max_x = (nbx - x0) / dx
		t_delta_x = absf(1.0 / dx)
	var t_max_y: float = INF
	var t_delta_y: float = INF
	if step_y != 0:
		var nby: float = float(cy + 1) if step_y > 0 else float(cy)
		t_max_y = (nby - y0) / dy
		t_delta_y = absf(1.0 / dy)

	# Bounded by the Manhattan cell span plus slack; guards float drift.
	var guard: int = (absi(ex - cx) + absi(ey - cy)) * 2 + 8
	while guard > 0:
		guard -= 1
		if t_max_x < t_max_y:
			cx += step_x
			t_max_x += t_delta_x
		elif t_max_y < t_max_x:
			cy += step_y
			t_max_y += t_delta_y
		else:
			# Exact corner crossing: reject if either diagonal squeeze cell blocks.
			if step_x != 0 and step_y != 0:
				if not _enterable(cx + step_x, cy, target_index, arriving):
					return false
				if not _enterable(cx, cy + step_y, target_index, arriving):
					return false
			cx += step_x
			cy += step_y
			t_max_x += t_delta_x
			t_max_y += t_delta_y
		if not _enterable(cx, cy, target_index, arriving):
			return false
		if cx == ex and cy == ey:
			return true
	# Fell through the guard without arriving -> fail closed.
	return false
