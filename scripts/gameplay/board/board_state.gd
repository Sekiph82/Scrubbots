extends RefCounted
## BoardState — preload this script
## (res://scripts/gameplay/board/board_state.gd) rather than relying on
## global class_name lookup; see scripts/data/level_validator.gd for why.
##
## Runtime source of truth for one in-progress board. Says what is
## CURRENTLY HAPPENING to a level (cleaning progress), as opposed to
## LevelData, which says what the level IS (immutable source definition).
## See docs/02_TECH_ARCHITECTURE.md.
##
## Board size is whatever the source LevelData specifies — this class makes
## no assumption about width, height, or their relationship (see ADR-008,
## docs/05_TECH_DECISIONS.md). Cell data is stored as flat packed arrays,
## never one Node/object per cell, to stay cheap at any board size
## (verified up to 50x50 = 2500 cells).
##
## Indexing rule (centralized here, must not be re-derived elsewhere):
##   index = y * width + x
##   x     = index % width
##   y     = index / width   (integer division)

## Explicit preload rather than global class_name lookup — see
## scripts/data/level_validator.gd for why.
const LevelData = preload("res://scripts/data/level_data.gd")

enum CellState {
	DIRTY = 0,
	CLEAN = 1,
}

var _width: int
var _height: int
## Palette id per cell, flat row-major. Copied from LevelData at construction
## time so runtime BoardState never mutates the source LevelData.
var _color_ids: PackedInt32Array
## Current CellState per cell, flat row-major. All cells start DIRTY.
var _cell_states: PackedByteArray

## Returns RefCounted (not a self-typed return) because self-referential
## static typing is unreliable in headless Godot without a prebuilt global
## script class cache. Callers get the real BoardState instance at runtime;
## treat the static type as RefCounted and call methods on it directly.
static func from_level_data(level: LevelData) -> RefCounted:
	var board = load("res://scripts/gameplay/board/board_state.gd").new()
	board._width = level.width
	board._height = level.height
	board._color_ids = level.cells.duplicate()
	var count: int = level.get_cell_count()
	board._cell_states = PackedByteArray()
	board._cell_states.resize(count)
	board._cell_states.fill(CellState.DIRTY)
	return board

func get_width() -> int:
	return _width

func get_height() -> int:
	return _height

func get_cell_count() -> int:
	return _width * _height

func is_valid_coordinate(x: int, y: int) -> bool:
	return x >= 0 and x < _width and y >= 0 and y < _height

func is_valid_index(index: int) -> bool:
	return index >= 0 and index < get_cell_count()

## Returns -1 for an out-of-range coordinate.
func get_cell_index(x: int, y: int) -> int:
	if not is_valid_coordinate(x, y):
		return -1
	return y * _width + x

## Returns Vector2i(-1, -1) for an out-of-range index.
func get_cell_position(index: int) -> Vector2i:
	if not is_valid_index(index):
		return Vector2i(-1, -1)
	return Vector2i(index % _width, index / _width)

## Returns -1 for an out-of-range index.
func get_color_id(index: int) -> int:
	if not is_valid_index(index):
		return -1
	return _color_ids[index]

## Returns -1 for an out-of-range index.
func get_cell_state(index: int) -> int:
	if not is_valid_index(index):
		return -1
	return _cell_states[index]

## Returns false (and makes no change) for an out-of-range index.
func set_cell_state(index: int, state: CellState) -> bool:
	if not is_valid_index(index):
		return false
	_cell_states[index] = state
	return true

func count_cells_by_state(state: CellState) -> int:
	var count := 0
	for value in _cell_states:
		if value == state:
			count += 1
	return count
