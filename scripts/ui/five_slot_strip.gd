extends HBoxContainer
## FiveSlotStrip — M28 production READ-ONLY presentation of the five M24 batch slots.
## Preload this script (res://scripts/ui/five_slot_strip.gd); do not rely on global
## class_name (AL-001).
##
## Renders EXACTLY five BatchSlotView positions, left→right by slot index. It is a
## status/occupancy strip, NOT a row of destination buttons: neither it nor its
## children emit any activation signal, and it never wires touch/click to M24/M23.
## M29 owns actual input; M28 is presentation only.
##
## Input is a DETACHED scalar snapshot Array (the shape produced by
## FiveSlotBatchEngine.snapshot(): five SlotBatchState.to_dict() dicts) plus a
## per-slot palette Color list. The strip retains NO engine/state reference.

const BatchSlotView = preload("res://scripts/ui/batch_slot_view.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const SLOT_COUNT := 5

var _views: Array = []

func _ready() -> void:
	add_theme_constant_override("separation", UiTokens.SPACE_SM)
	custom_minimum_size.y = maxf(custom_minimum_size.y, UiTokens.FIVE_SLOT_STRIP_MIN_HEIGHT)
	if _views.is_empty():
		_build_views()

func _build_views() -> void:
	for i in range(SLOT_COUNT):
		var v = BatchSlotView.new()
		v.name = "BatchSlot%d" % i
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(v)
		_views.append(v)

## Bind detached slot snapshots. `snapshots` is truncated/padded to exactly five;
## deeper input is ignored so the strip can never expose more than five positions.
## `colors` maps color_id -> Color (or is indexed per snapshot color_id).
func bind_snapshots(snapshots: Array, colors: Array = []) -> void:
	if _views.is_empty():
		_build_views()
	for i in range(SLOT_COUNT):
		var snap: Dictionary = snapshots[i] if i < snapshots.size() and snapshots[i] is Dictionary else {"state": "EMPTY", "occupied": false}
		var cid: int = int(snap.get("color_id", -1))
		var col: Color = colors[cid] if cid >= 0 and cid < colors.size() else Color(1, 0, 1, 1)
		_views[i].bind_snapshot(snap, col)

func get_slot_views() -> Array:
	return _views.duplicate()

func get_slot_count() -> int:
	return _views.size()
