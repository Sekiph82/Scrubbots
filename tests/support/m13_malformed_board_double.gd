extends RefCounted
## M13MalformedBoardDouble — M13 adversarial BoardState-compatible double.
## Preload it (AL-001). Never referenced by production code.
##
## Exposes the FULL narrow M13 board API (get_cell_count / is_valid_index /
## get_cell_state / get_color_id) so it passes the duck-typed API gate, but each
## return can be configured malformed so the transactional build/rebuild and the
## sync_cell path (F-M13-STRICT-001 / F-M13-STRICT-002) can be exercised without
## a real BoardState. All-default = a valid board of `count` ACTIVE cells of
## `color`, which must bind and query normally.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

var count: int = 4
var color: int = 0
var count_type_wrong: bool = false   # get_cell_count -> String
var state_type_wrong: bool = false   # get_cell_state -> float
var color_type_wrong: bool = false   # get_color_id -> String
var unknown_state_at: int = -1       # index whose state is an unknown int
var unknown_state_value: int = 99

func get_cell_count():
	if count_type_wrong:
		return "four"
	return count

func is_valid_index(index):
	return index >= 0 and index < count

func get_cell_state(index):
	if state_type_wrong:
		return 3.14
	if index == unknown_state_at:
		return unknown_state_value
	return BoardState.CellState.ACTIVE

func get_color_id(index):
	if color_type_wrong:
		return "red"
	return color
