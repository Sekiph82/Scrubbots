extends RefCounted
## SlotOriginProvider — M29 read-only slot-origin seam for the AutoDispatchScheduler.
## Preload this script (res://scripts/gameplay/runtime/slot_origin_provider.gd); do not
## rely on global class_name (AL-001).
##
## Maps a batch slot index -> the route START origin in board-local cell units, exposing
## the exact `origin_for_slot(slot)` seam M26 consumes. It uses the canonical five-lane
## below-board geometry the accepted M27 ProofKernel certified (see below), so the live
## runtime reproduces the proven reachability. It reserves/selects/routes nothing.

## Five lanes spread across the board width; y one cell below the outer bottom rail
## (CENTER_OFFSET 2.5 + RAIL_WIDTH*0.5 0.5 + 1.0 = 4.0). This is EXACTLY the canonical
## slot-origin geometry the accepted M27 ProofKernel certified as solvable, so the real
## runtime routing reproduces the proven reachability — the M27-solved play order clears
## the real board through this exact origin mapping.
const SLOT_COUNT := 5
const ORIGIN_BELOW := 4.0

var _presentation = null   # retained so the manual scene ties the mapping to the real
var _strip = null          # laid-out screen; the certified geometry below is authority.
var _board = null

func _init(presentation, strip, board) -> void:
	_presentation = presentation
	_strip = strip
	_board = board

func origin_for_slot(slot_index: int) -> Vector2:
	if _board == null or slot_index < 0 or slot_index >= SLOT_COUNT:
		return Vector2(INF, INF)   # fail closed -> no route -> no robot
	var w: float = float(_board.get_width())
	var h: float = float(_board.get_height())
	var lane_x: float = (float(slot_index) + 0.5) * w / float(SLOT_COUNT)
	return Vector2(lane_x, h + ORIGIN_BELOW)
