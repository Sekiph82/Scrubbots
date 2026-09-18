extends RefCounted
## SlotOriginProvider — M29 read-only slot-origin seam for the AutoDispatchScheduler.
## Preload this script (res://scripts/gameplay/runtime/slot_origin_provider.gd); do not
## rely on global class_name (AL-001).
##
## Maps a batch slot index -> the route START origin in board-local cell units, exposing
## the exact `origin_for_slot(slot)` seam M26 consumes. The origin is the ACTUAL visible
## production slot top-center on the M28 screen, mapped live through the presentation
## transform (M29-C001 V02, F-M29-V01-STRICT-001):
##
##   global_anchor      = FiveSlotStrip.get_slot_anchor_global(slot)
##   board_local_origin = BoardPresentation.global_to_board_local(global_anchor)
##
## so what the owner sees and where a Scrubbot's route starts are the SAME point — the
## visible slot -> BOTTOM connector -> canonical Railroad V1 contract. It queries the
## CURRENT laid-out geometry every call (no cached screen pixels), so the origin follows
## responsive relayout automatically. It reserves/selects/routes nothing.
##
## Fail closed (Vector2(INF, INF) -> RouteRequest fails -> no robot) for an out-of-range
## slot, a missing/dead strip or presentation, or a non-finite mapped origin. There is NO
## synthetic board-width fallback: a broken layout produces no robot rather than a robot
## starting from a position the owner cannot see.

const SLOT_COUNT := 5

var _presentation = null   # BoardPresentation (global_to_board_local)
var _strip = null          # FiveSlotStrip (get_slot_anchor_global)
var _board = null          # retained only for slot-count context; not an origin source

func _init(presentation, strip, board) -> void:
	_presentation = presentation
	_strip = strip
	_board = board

func origin_for_slot(slot_index: int) -> Vector2:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return Vector2(INF, INF)
	if _strip == null or not is_instance_valid(_strip) \
			or _presentation == null or not is_instance_valid(_presentation):
		return Vector2(INF, INF)   # missing/dead layout -> fail closed, no robot
	# Exact visible slot top-center -> board-local, queried from the CURRENT layout.
	var anchor: Vector2 = _strip.get_slot_anchor_global(slot_index)
	var local: Vector2 = _presentation.global_to_board_local(anchor)
	if not (is_finite(local.x) and is_finite(local.y)):
		return Vector2(INF, INF)   # non-finite mapping (unlaid-out/degenerate) -> fail closed
	return local
