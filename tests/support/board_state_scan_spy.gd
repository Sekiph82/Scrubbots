extends RefCounted
## Test-only spy exposing the subset of the BoardState API that
## EligibleTargetIndex consumes, while counting EVERY read an implementation
## could use to traverse the board.
##
## Used by M13 to prove (AL-018) that steady-state color queries read prebuilt
## buckets instead of rescanning the board through ANY BoardState API — not
## only get_cell_state() (F-M13-001). This script lives under tests/ and is
## never referenced by production code.
##
## Per-method counters plus an aggregate `traversal_reads` let a test snapshot
## counts right after build and after N queries and assert a zero delta. A
## future regression that loops the board via get_color_id(), get_cell_state(),
## or get_cell_count()/is_valid_index() will move `traversal_reads` and fail.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

var _color_ids: PackedInt32Array
var _states: PackedByteArray
var _width: int
var _height: int

## Per-method call counters.
var count_get_cell_count: int = 0
var count_is_valid_index: int = 0
var count_get_color_id: int = 0
var count_get_cell_state: int = 0

func setup(color_ids: Array, width: int, height: int) -> void:
	_width = width
	_height = height
	_color_ids = PackedInt32Array(color_ids)
	_states = PackedByteArray()
	_states.resize(color_ids.size())
	_states.fill(BoardState.CellState.DIRTY)

## Aggregate of every BoardState read an index could use to walk the board.
func traversal_reads() -> int:
	return count_get_cell_count + count_is_valid_index + count_get_color_id + count_get_cell_state

func reset_counters() -> void:
	count_get_cell_count = 0
	count_is_valid_index = 0
	count_get_color_id = 0
	count_get_cell_state = 0

# --- BoardState API surface (every read is counted) ---

func get_cell_count() -> int:
	count_get_cell_count += 1
	return _width * _height

func is_valid_index(index: int) -> bool:
	count_is_valid_index += 1
	return index >= 0 and index < _width * _height

func get_color_id(index: int) -> int:
	count_get_color_id += 1
	if index < 0 or index >= _color_ids.size():
		return -1
	return _color_ids[index]

func get_cell_state(index: int) -> int:
	count_get_cell_state += 1
	if index < 0 or index >= _states.size():
		return -1
	return _states[index]

## Mutation is not a board traversal read; not counted.
func set_cell_state(index: int, state: int) -> bool:
	if index < 0 or index >= _states.size():
		return false
	_states[index] = state
	return true
