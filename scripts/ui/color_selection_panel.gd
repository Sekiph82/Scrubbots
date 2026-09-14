extends HBoxContainer
## ColorSelectionPanel — preload this script
## (res://scripts/ui/color_selection_panel.gd) rather than relying on global
## class_name lookup (AL-001).
##
## M22-C001 V01 reusable PRODUCTION five-slot / color-selection component.
## Owns exactly five production SlotCell instances in deterministic left-to-right
## order and binds each to a real slot id + a scalar Color snapshot. It is
## presentation-ONLY: it consumes scalar (slot_id, Color) snapshots and NEVER
## retains a mutable SlotState/SlotSystem/BoardState/ReservationState reference, so
## the UI can never become gameplay truth or mutate slot state by reference leakage
## (prompt §9; criteria M22-V01-029/030). It never selects a target, routes,
## dispatches, mutates the board, or clears a cell.
##
## Container-driven layout (HBoxContainer), not five absolute screen positions.
## Two independent instances share no mutable presentation state — each owns its
## own SlotCell children and its own active-visual bookkeeping.
##
## A cell activation is re-emitted as slot_activated(slot_id); a production
## adapter/controller routes that through the accepted M21 CompleteClearingLoop.

signal slot_activated(slot_id)

const SlotCellScene = preload("res://scenes/components/ui/gameplay/slot_cell.tscn")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const SLOT_COUNT := 5

var _cells: Array = []

func _ready() -> void:
	add_theme_constant_override("separation", UiTokens.SPACE_MD)
	alignment = BoxContainer.ALIGNMENT_CENTER
	# Protected usable minimum width per Master UI System (criteria M22-V01-061).
	custom_minimum_size = Vector2(UiTokens.COLOR_SELECTION_MIN_WIDTH, UiTokens.TOUCH_MIN)

## Build exactly five cells bound to scalar Color snapshots. `colors` is a plain
## Array[Color] indexed by slot id — no gameplay reference is stored. Idempotent:
## a re-bind rebuilds the cells from the new scalar snapshot.
func bind_colors(colors: Array) -> void:
	_clear_cells()
	for slot_id in range(SLOT_COUNT):
		var col: Color = colors[slot_id] if slot_id < colors.size() else Color(1, 0, 1, 1)
		var cell = SlotCellScene.instantiate()
		add_child(cell)
		cell.setup(slot_id, col)
		cell.slot_activated.connect(_on_cell_activated)
		_cells.append(cell)

func _clear_cells() -> void:
	for c in _cells:
		if is_instance_valid(c):
			remove_child(c)
			c.free()
	_cells.clear()

func _on_cell_activated(slot_id) -> void:
	slot_activated.emit(slot_id)

func get_slot_cells() -> Array:
	return _cells

func get_cell(slot_id: int):
	return _cells[slot_id] if slot_id >= 0 and slot_id < _cells.size() else null

func get_slot_count() -> int:
	return _cells.size()

## Presentation-only active/in-flight highlight for one slot. Not gameplay truth.
func set_slot_active(slot_id: int, value: bool) -> void:
	if slot_id >= 0 and slot_id < _cells.size():
		_cells[slot_id].set_active_visual(value)

func is_slot_active(slot_id: int) -> bool:
	return slot_id >= 0 and slot_id < _cells.size() and _cells[slot_id].is_active_visual()

## Presentation-only GLOBAL spawn anchor (top-center) of a slot cell, derived from
## the cell's ACTUAL laid-out geometry. Requires a completed layout frame; a
## production adapter maps it through BoardPresentation into board/AgentLayer
## route space (criteria M22-V01-052..057).
func get_spawn_anchor_global(slot_id: int) -> Vector2:
	var cell = get_cell(slot_id)
	return cell.get_spawn_anchor_global() if cell != null else Vector2.ZERO

## Clear all active visuals (presentation bookkeeping only; no gameplay reset).
func reset_active_visuals() -> void:
	for c in _cells:
		c.set_active_visual(false)
