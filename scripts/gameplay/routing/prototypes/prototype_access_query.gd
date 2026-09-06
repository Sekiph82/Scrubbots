extends RefCounted
## PrototypeAccessQuery — M17 EXPERIMENTAL access truth. Preload it (AL-001).
##
## Translates BoardState ACTIVE/CLEARED semantics into the injected segment
## access contract the M16 RouteValidator consumes:
##   is_segment_traversable(from_position, to_position, target_index) -> bool
##
## This is an EXPERIMENTAL prototype-lab implementation, NOT canonical production
## access semantics. It must not silently become production truth before the
## owner movement-language design gate is resolved (M17 prompt "Experimental
## access implementation"). It performs NO target selection, owns NO reservation,
## and NEVER mutates BoardState.
##
## Experimental topology (documented, not canonical):
##   - coordinate space is board-local cell units (ADR-024): cell (x,y) spans
##     [x,x+1]x[y,y+1]; a point maps to cell (floor(x), floor(y)).
##   - a cell is OPEN (a bot may occupy/cross it) when it is CLEARED.
##   - outside-board / background free space is OPEN (exterior model — slot
##     origins live outside the board and reach it through open exterior space).
##   - a non-target ACTIVE cell is BLOCKED.
##   - the assigned ACTIVE target cell is enterable ONLY as the final arrival:
##     it is treated OPEN only for a segment whose `to` endpoint is that target
##     cell's center; a segment merely passing THROUGH the target without
##     stopping there is BLOCKED. This encodes "target may be entered only as the
##     final endpoint" and forbids using the target as a corridor.
##
## Segment traversability is decided by dense sampling of the segment at
## SAMPLE_STEP resolution (axis-aligned grid segments are exact; arbitrary/curved
## segments from the organized prototype are approximated — documented as an
## experimental sampled check, not a pixel-exact supercover).

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

enum CellClass { OPEN, BLOCKED, TARGET }

## Sample spacing along a segment, in cell units. 0.1 guarantees multiple
## samples inside any crossed 1x1 cell for axis-aligned segments and is dense
## enough for the experimental organized/curved prototype.
const SAMPLE_STEP := 0.1

var _board

func _init(board) -> void:
	_board = board

## floor()-based cell of a board-local point. Returns Vector2i; may be outside
## the board (caller treats outside as OPEN exterior).
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

## Center of a cell index (board-local). Vector2(-inf,-inf) if out of range.
func _target_center(target_index: int) -> Vector2:
	var pos: Vector2i = _board.get_cell_position(target_index)
	if pos.x < 0:
		return Vector2(-INF, -INF)
	return Vector2(float(pos.x) + 0.5, float(pos.y) + 0.5)

## Is a cell enterable for this segment? OPEN always; TARGET only when this
## segment arrives at the target (to == target center).
func _cell_enterable(cx: int, cy: int, target_index: int, arriving_at_target: bool) -> bool:
	var c: int = classify_cell(cx, cy, target_index)
	if c == CellClass.OPEN:
		return true
	if c == CellClass.TARGET:
		return arriving_at_target
	return false

## Injected access contract (duck-typed for RouteValidator / prototypes).
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
