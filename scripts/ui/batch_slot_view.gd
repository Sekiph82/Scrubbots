extends PanelContainer
## BatchSlotView — M28 production READ-ONLY view of exactly one of the five M24
## batch slots. Preload this script (res://scripts/ui/batch_slot_view.gd); do not
## rely on global class_name (AL-001).
##
## Deliberately NOT a Button and NOT the historical M21/M22 `SlotView`
## (slot_view.gd, which emits slot_activated). Production batch input is
## supply-front selection (M23) placed into the rightmost EMPTY slot (M24 truth) —
## the five slots are occupancy/status PRESENTATION, never player-selected
## destination controls. M28 must not revive slot destination clicking; M29 owns
## touch. Therefore this view exposes NO signal, NO pressed handler, NO activation.
##
## It consumes only a DETACHED scalar snapshot dict (the shape produced by
## SlotBatchState.to_dict() / FiveSlotBatchEngine.snapshot()) plus a scalar Color.
## It retains NO SlotBatchState / FiveSlotBatchEngine reference, so UI can never
## become or mutate gameplay truth by reference leakage.

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const EMPTY := "EMPTY"
const ACTIVE := "ACTIVE"
const WAITING := "WAITING"

const _EMPTY_BG := Color(0.12, 0.14, 0.18, 1.0)
const _OCC_BG := Color(0.16, 0.19, 0.25, 1.0)
const _ACTIVE_EDGE := Color(0.20, 0.85, 0.95, 1.0)
const _WAITING_EDGE := Color(0.45, 0.50, 0.60, 1.0)

var _snapshot: Dictionary = {}
var _color: Color = Color(1, 0, 1, 1)

var _swatch: ColorRect
var _remaining_label: Label
var _state_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(UiTokens.BATCH_SLOT_MIN, UiTokens.BATCH_SLOT_MIN)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _swatch == null:
		_build_children()

func _build_children() -> void:
	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	add_child(vbox)

	_swatch = ColorRect.new()
	_swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swatch.custom_minimum_size = Vector2(0, UiTokens.ICON_SM)
	_swatch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_swatch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_swatch)

	_remaining_label = Label.new()
	_remaining_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_remaining_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_remaining_label)

	_state_label = Label.new()
	_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_state_label)

## Bind a DETACHED scalar snapshot (dict is duplicated; no reference retained) plus
## a scalar palette Color for the batch color. Safe to call before or after _ready.
func bind_snapshot(snapshot: Dictionary, color: Color = Color(1, 0, 1, 1)) -> void:
	_snapshot = snapshot.duplicate(true)
	_color = color
	if _swatch == null:
		_build_children()
	_refresh()

func _refresh() -> void:
	var state: String = str(_snapshot.get("state", EMPTY))
	var occupied: bool = bool(_snapshot.get("occupied", false)) and state != EMPTY
	if not occupied:
		_swatch.color = Color(0, 0, 0, 0)
		_remaining_label.text = ""
		_state_label.text = "EMPTY"
		_set_panel_bg(_EMPTY_BG, _WAITING_EDGE, false)
		return
	_swatch.color = _color
	var remaining: int = int(_snapshot.get("remaining_to_clear", 0))
	var committed: int = int(_snapshot.get("committed", 0))
	# Player-facing main number = robots still physically WAITING in this slot =
	# M24 capacity = remaining_to_clear - committed (OWNER_BATCH_SLOT_DISPLAY_DECISION_V01).
	# A committed/in-flight Scrubbot has already left the slot, so it is subtracted
	# immediately; remaining_to_clear and committed decrement together on an authenticated
	# clear, so the displayed waiting count stays correct. The old "50 (2)" raw form is gone.
	var capacity: int = maxi(remaining - committed, 0)
	_remaining_label.text = "%d" % capacity
	_state_label.text = state
	var edge := _ACTIVE_EDGE if state == ACTIVE else _WAITING_EDGE
	_set_panel_bg(_OCC_BG, edge, state == ACTIVE)

func _set_panel_bg(bg: Color, edge: Color, emphasized: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(UiTokens.RADIUS_SM)
	sb.set_border_width_all(3 if emphasized else 1)
	sb.border_color = edge
	sb.set_content_margin_all(UiTokens.SPACE_XS)
	add_theme_stylebox_override("panel", sb)

# --- read-only test/presentation accessors (no gameplay authority) ---
func get_state() -> String:
	return str(_snapshot.get("state", EMPTY))

func is_occupied_view() -> bool:
	return bool(_snapshot.get("occupied", false)) and get_state() != EMPTY

func get_remaining_view() -> int:
	return int(_snapshot.get("remaining_to_clear", 0))

func get_committed_view() -> int:
	return int(_snapshot.get("committed", 0))

## The player-facing MAIN number currently displayed = M24 capacity (waiting robots).
func get_display_count() -> int:
	if not is_occupied_view():
		return 0
	return maxi(int(_snapshot.get("remaining_to_clear", 0)) - int(_snapshot.get("committed", 0)), 0)

## The raw displayed label text (for asserting the old "N (c)" form is gone).
func get_count_label_text() -> String:
	return _remaining_label.text if _remaining_label != null else ""

## Presentation-only GLOBAL spawn anchor (top-center) of this slot view, used by the
## M29 runtime origin provider to derive a real laid-out slot->route origin. Presentation
## geometry only; carries no gameplay/target authority.
func get_spawn_anchor_global() -> Vector2:
	return global_position + Vector2(size.x * 0.5, 0.0)
