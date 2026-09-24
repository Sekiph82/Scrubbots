extends HBoxContainer
## FiveSlotStrip — M28 production READ-ONLY presentation of the five M24 batch slots.
## Preload this script (res://scripts/ui/five_slot_strip.gd); do not rely on global
## class_name (AL-001).
##
## M28/M29 BASELINE renders exactly five BatchSlotView positions, left→right by slot index.
## Economy V1 +1 Slot does NOT exist in this accepted baseline yet; M39 must extend this
## presentation to authoritative capacity 5/6 without falsifying the completed M28 evidence.
## It is a
## status/occupancy strip, NOT a row of destination buttons: neither it nor its
## children emit any activation signal, and it never wires touch/click to M24/M23.
## M29 owns actual input; M28 is presentation only.
##
## Input is a DETACHED scalar snapshot Array (the shape produced by
## FiveSlotBatchEngine.snapshot(): five SlotBatchState.to_dict() dicts) plus a
## per-slot palette Color list. The strip retains NO engine/state reference.

const BatchSlotView = preload("res://scripts/ui/batch_slot_view.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

## Baseline attempt capacity. Economy V1 +1 Slot may grow the strip to
## `MAX_CAPACITY` for the current attempt via `set_capacity(n)` (M39 V03,
## F-M39-V02-001). A new attempt always returns to `SLOT_COUNT`.
const SLOT_COUNT := 5
const MAX_CAPACITY := 6

var _views: Array = []
var _capacity: int = SLOT_COUNT

func _ready() -> void:
	add_theme_constant_override("separation", UiTokens.SPACE_SM)
	custom_minimum_size.y = maxf(custom_minimum_size.y, UiTokens.FIVE_SLOT_STRIP_MIN_HEIGHT)
	if _views.is_empty():
		_build_views()

func _build_views() -> void:
	while _views.size() < _capacity:
		var v = BatchSlotView.new()
		v.name = "BatchSlot%d" % _views.size()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(v)
		_views.append(v)

## Grow/shrink the strip to `n` slots (5 or 6). Grows by appending a fresh
## BatchSlotView; shrinks by removing the trailing view. Hard-clamped to
## [SLOT_COUNT, MAX_CAPACITY] — never a seventh slot (M39 V03,
## F-M39-V02-001). Returns true on a legal capacity for the strip.
func set_capacity(n: int) -> bool:
	if n < SLOT_COUNT or n > MAX_CAPACITY:
		return false
	_capacity = n
	while _views.size() < n:
		var v = BatchSlotView.new()
		v.name = "BatchSlot%d" % _views.size()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(v)
		_views.append(v)
	while _views.size() > n:
		var v = _views.pop_back()
		v.queue_free()
	return true

## Bind detached slot snapshots. Truncated/padded to the CURRENT active capacity
## (5 or 6). Deeper input beyond capacity is ignored so the strip can never
## expose more than `MAX_CAPACITY` positions. `colors` maps color_id -> Color.
func bind_snapshots(snapshots: Array, colors: Array = []) -> void:
	if _views.is_empty():
		_build_views()
	for i in range(_views.size()):
		var snap: Dictionary = snapshots[i] if i < snapshots.size() and snapshots[i] is Dictionary else {"state": "EMPTY", "occupied": false}
		var cid: int = int(snap.get("color_id", -1))
		var col: Color = colors[cid] if cid >= 0 and cid < colors.size() else Color(1, 0, 1, 1)
		_views[i].bind_snapshot(snap, col)

func get_slot_views() -> Array:
	return _views.duplicate()

func get_slot_count() -> int:
	return _views.size()

## Active presentation capacity (5 or 6) as last set by set_capacity.
func get_capacity() -> int:
	return _capacity

## Presentation-only GLOBAL top-center anchor of slot `i`, or Vector2.ZERO when out of
## range. The M29 origin provider maps this through BoardPresentation.global_to_board_local
## to build a real laid-out slot->route origin. Geometry only; no gameplay authority.
func get_slot_anchor_global(i: int) -> Vector2:
	if i < 0 or i >= _views.size():
		return Vector2.ZERO
	return _views[i].get_spawn_anchor_global()
