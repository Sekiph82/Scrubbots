extends RefCounted
## SlotState — preload this script
## (res://scripts/gameplay/slots/slot_state.gd) rather than relying on
## global class_name lookup (AL-001).
##
## Lightweight headless-testable model for a single gameplay slot.
## Holds stable identity, palette/color ID, availability and activity.
## No UI, no dispatch, no target selection.

var _id: int
var _palette_id: int = -1
var _available: bool = true
var _active: bool = false

func _init(id: int) -> void:
	_id = id

func get_id() -> int:
	return _id

func get_palette_id() -> int:
	return _palette_id

func set_palette_id(palette_id: int) -> void:
	_palette_id = palette_id

func is_available() -> bool:
	return _available

func set_available(value: bool) -> void:
	_available = value

func is_active() -> bool:
	return _active

func set_active(value: bool) -> void:
	_active = value
