extends RefCounted
## ProductionAccessQuery — PRODUCTION access truth for routing. Preload it
## (AL-001). It is the promoted, owner-selected (M17-C002,
## OWNER_MOVEMENT_DECISION_V01) canonical translation of BoardState ACTIVE/CLEARED
## semantics into the injected segment access contract the M16 RouteValidator and
## ProductionRoutingSystem consume:
##   is_segment_traversable(from_position, to_position, target_index) -> bool
##
## It performs NO target selection, owns NO reservation, and NEVER mutates
## BoardState. Semantics (locked, ADR-019/ADR-024/ADR-025):
##   - a cell is OPEN when CLEARED;
##   - outside-board / background free space is OPEN (slot origins live outside
##     the board and reach it through open exterior space);
##   - a non-target ACTIVE cell is BLOCKED;
##   - the assigned ACTIVE target cell is enterable ONLY as the final arrival:
##     OPEN only for a segment whose `to` endpoint is that target cell's centre.
##
## Segment traversability is decided by dense sampling at SAMPLE_STEP. This is the
## same access model the M17 lab validated; it is now canonical production truth
## rather than experimental scope. (The experimental
## prototypes/prototype_access_query.gd copy is retained only for the diagnostic
## lab, per the owner decision.)

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

enum CellClass { OPEN, BLOCKED, TARGET }

## Sample spacing along a segment, in cell units. 0.1 gives multiple samples
## inside any crossed 1x1 cell for axis-aligned segments and is dense enough for
## controlled organized/curved segments.
const SAMPLE_STEP := 0.1

var _board

func _init(board) -> void:
	_board = board

## floor()-based cell of a board-local point (may be outside the board).
func cell_of_point(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x)), int(floor(p.y)))

func _is_outside(cx: int, cy: int) -> bool:
	return cx < 0 or cy < 0 or cx >= _board.get_width() or cy >= _board.get_height()

## Classify a board cell for the given target. Outside-board is OPEN.
func classify_cell(cx: int, cy: int, target_index: int) -> int:
	if _is_outside(cx, cy):
		return CellClass.OPEN
	var idx: int = _board.get_cell_index(cx, cy)
	if idx == target_index:
		return CellClass.TARGET
	if _board.get_cell_state(idx) == BoardState.CellState.CLEARED:
		return CellClass.OPEN
	return CellClass.BLOCKED

func _target_center(target_index: int) -> Vector2:
	var pos: Vector2i = _board.get_cell_position(target_index)
	if pos.x < 0:
		return Vector2(-INF, -INF)
	return Vector2(float(pos.x) + 0.5, float(pos.y) + 0.5)

func _cell_enterable(cx: int, cy: int, target_index: int, arriving_at_target: bool) -> bool:
	var c: int = classify_cell(cx, cy, target_index)
	if c == CellClass.OPEN:
		return true
	if c == CellClass.TARGET:
		return arriving_at_target
	return false

## Injected access contract (duck-typed for RouteValidator / routing).
func is_segment_traversable(from_position: Vector2, to_position: Vector2, target_index: int) -> bool:
	var arriving: bool = to_position.is_equal_approx(_target_center(target_index))
	var delta: Vector2 = to_position - from_position
	var length: float = delta.length()
	var steps: int = int(ceil(length / SAMPLE_STEP))
	if steps < 1:
		steps = 1
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector2 = from_position + delta * t
		var cell: Vector2i = cell_of_point(p)
		if not _cell_enterable(cell.x, cell.y, target_index, arriving):
			return false
	return true
