extends RefCounted
## Test-only spy exposing the subset of the BoardState API that
## EligibleTargetIndex consumes, while counting per-cell state reads.
##
## Used by M13-23 to prove steady-state color queries read prebuilt buckets
## instead of rescanning the board (AL-018: directly observe the claim). This
## script lives under tests/ and is never referenced by production code.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

var _color_ids: PackedInt32Array
var _states: PackedByteArray
var _width: int
var _height: int
## Incremented on every get_cell_state() read — a full board scan costs
## >= get_cell_count() increments.
var scan_count: int = 0

func setup(color_ids: Array, width: int, height: int) -> void:
	_width = width
	_height = height
	_color_ids = PackedInt32Array(color_ids)
	_states = PackedByteArray()
	_states.resize(color_ids.size())
	_states.fill(BoardState.CellState.DIRTY)

func get_cell_count() -> int:
	return _width * _height

func is_valid_index(index: int) -> bool:
	return index >= 0 and index < get_cell_count()

func get_color_id(index: int) -> int:
	if not is_valid_index(index):
		return -1
	return _color_ids[index]

func get_cell_state(index: int) -> int:
	if not is_valid_index(index):
		return -1
	scan_count += 1
	return _states[index]

func set_cell_state(index: int, state: int) -> bool:
	if not is_valid_index(index):
		return false
	_states[index] = state
	return true
