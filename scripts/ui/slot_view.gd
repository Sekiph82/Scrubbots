extends Button
## SlotView — preload this script (res://scripts/ui/slot_view.gd) rather than
## relying on global class_name lookup (AL-001).
##
## M21-C001 V04 minimal production-compatible native Godot slot component (owner
## playtest decision F-M21-OWNER-PLAYTEST-003; pulls forward M22-002/005/007). It
## represents exactly ONE real SlotSystem slot by ID and displays that slot's bound
## LevelData palette color. It consumes only scalar/query state (slot id + a Color)
## and NEVER retains a mutable SlotState/SlotSystem reference, so UI can never
## become gameplay truth or mutate slot state by reference leakage.
##
## Clicking emits `slot_activated(slot_id)`; the scene routes that through the real
## CompleteClearingLoop path. SlotView itself never clears a cell, mutates
## BoardState, selects a target, or spawns an agent. Active/in-flight state is a
## presentation-only highlight.

signal slot_activated(slot_id)

var _slot_id: int = -1
var _color: Color = Color(1, 0, 1, 1)
var _swatch: ColorRect
var _active: bool = false

## slot_id: the real SlotSystem slot id. color: the bound LevelData palette color
## (a scalar value, not a live reference).
func setup(slot_id: int, color: Color) -> void:
	_slot_id = slot_id
	_color = color
	custom_minimum_size = Vector2(120, 120)
	focus_mode = Control.FOCUS_NONE
	text = ""
	if _swatch == null:
		_swatch = ColorRect.new()
		_swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
		_swatch.offset_left = 8
		_swatch.offset_top = 8
		_swatch.offset_right = -8
		_swatch.offset_bottom = -8
		_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_swatch)
	_swatch.color = _color
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _on_pressed() -> void:
	slot_activated.emit(_slot_id)

func get_slot_id() -> int:
	return _slot_id

func get_color() -> Color:
	return _color

## Presentation-only active/in-flight highlight. Not gameplay truth.
func set_active_visual(value: bool) -> void:
	_active = value
	modulate = Color(1.35, 1.35, 1.35, 1.0) if value else Color(1, 1, 1, 1)

func is_active_visual() -> bool:
	return _active
