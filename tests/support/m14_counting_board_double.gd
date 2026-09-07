extends RefCounted
## M14CountingBoardDouble — configurable, counting BoardState double for M14
## ReservationState strict tests (F-M14-STRICT-001). Preload it (AL-001); never
## referenced by production.
##
## RefCounted with the FULL narrow M14 API (get_cell_count / is_valid_index /
## get_cell_state), so it passes the dependency-category gate. Every knob injects
## a malformed live return; per-index counters let a test prove that an
## out-of-domain target is rejected against the bind-time count snapshot WITHOUT
## any is_valid_index/get_cell_state call, and that no operation full-scans.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

## get_cell_count() return. Any Variant, so count-typing/bounds can be tested
## (String, -1, 0, 3481, 3482, 1_000_000, ...).
var cell_count = 6
## is_valid_index() behaviour: "normal" (index in [0,count)), "false" (always
## false for an in-domain index — a dependency contradiction), "nonbool".
var valid_mode := "normal"
## index -> arbitrary Variant returned by get_cell_state(); absent => ACTIVE.
var state_overrides: Dictionary = {}

var count_get_cell_count: int = 0
var count_is_valid_index: int = 0
var count_get_cell_state: int = 0

## Per-index board reads (excludes the one-shot bind-time get_cell_count).
func per_index_calls() -> int:
	return count_is_valid_index + count_get_cell_state

func reset_counters() -> void:
	count_get_cell_count = 0
	count_is_valid_index = 0
	count_get_cell_state = 0

func get_cell_count():
	count_get_cell_count += 1
	return cell_count

func is_valid_index(index):
	count_is_valid_index += 1
	if valid_mode == "false":
		return false
	if valid_mode == "nonbool":
		return "yes"
	return index >= 0 and typeof(cell_count) == TYPE_INT and index < cell_count

func get_cell_state(index):
	count_get_cell_state += 1
	if state_overrides.has(index):
		return state_overrides[index]
	return BoardState.CellState.ACTIVE
