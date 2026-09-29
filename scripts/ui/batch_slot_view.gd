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
const ColorBatchTile = preload("res://scripts/ui/color_batch_tile.gd")

const EMPTY := "EMPTY"
const ACTIVE := "ACTIVE"
const WAITING := "WAITING"

## The tile sits this many px inside the baked slot interior (cartridge inside its housing).
const _TILE_INSET := 2.0
const _HOUSING_BG := Color(0.12, 0.14, 0.18, 1.0)
const _HOUSING_EDGE := Color(0.45, 0.50, 0.60, 1.0)

var _snapshot: Dictionary = {}
var _color: Color = Color(1, 0, 1, 1)

var _tile: ColorBatchTile
var _state_label: Label

var _shell := false
var _shell_tile_size := Vector2.ZERO
var _reserve_base := Vector2.ZERO

func _ready() -> void:
	if not _shell:
		custom_minimum_size = Vector2(UiTokens.BATCH_SLOT_MIN, UiTokens.BATCH_SLOT_MIN)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _tile == null:
		_build_children()
	_reserve_state_line()   # in the tree now: the real theme font

func _build_children() -> void:
	# M28-C002-C004: the shared ColorBatchTile draws the whole occupied/empty presentation and
	# owns the exact face-centred count. It is a direct child of this PanelContainer (no VBox),
	# so nothing else in the slot can push the number.
	_tile = ColorBatchTile.new()
	_tile.name = "Tile"
	_tile.set_inset(_TILE_INSET)
	add_child(_tile)
	_apply_tile_size()

	# Owner (M28-C002-C003-R01 V02): the words WAITING / ACTIVE are not shown on the slot.
	# The label is kept ONLY as an always-empty, invisible min-size reserve so the slot's
	# measured OUTER layout and every slot origin / anchor derived from it stay exactly as
	# accepted. It is a SIBLING of the tile, overlaps nothing that draws, and is never part of
	# the tile's face/count layout (C004: it cannot move the number).
	_state_label = Label.new()
	_state_label.name = "StateLineReserve"
	_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.add_theme_font_size_override("font_size", 18)
	add_child(_state_label)
	_reserve_state_line()

## Reserve exactly the outer min box the old VBox (swatch + count + state line) occupied, so the
## slot's measured layout - and every slot origin / anchor derived from it - is unchanged.
## Measured with the label's real theme font; draws nothing.
func _reserve_state_line() -> void:
	if _state_label == null:
		return
	var f: Font = _state_label.get_theme_font("font")
	if f == null:
		return
	var w := 0.0
	for word in [ACTIVE, WAITING]:
		w = maxf(w, f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x)
	# old VBox: [swatch ICON_SM (hidden in shell mode)] + count(34) + state(18), XS separations
	var h: float = ceilf(f.get_height(34)) + UiTokens.SPACE_XS + ceilf(f.get_height(18))
	if not _shell:
		h += UiTokens.ICON_SM + UiTokens.SPACE_XS
	_reserve_base = Vector2(ceilf(w), h)
	_apply_reserve()

## The accepted layout's outer size also grew by the old state border (ACTIVE 3 px, WAITING 2 px,
## empty 0, each side, shell mode). Keep that identical so slot origins / anchors never drift;
## it lives on the invisible reserve sibling only, never on the tile.
func _apply_reserve() -> void:
	if _state_label == null:
		return
	var b := 0.0
	if _shell and bool(_snapshot.get("occupied", false)) and str(_snapshot.get("state", EMPTY)) != EMPTY:
		b = 3.0 if str(_snapshot.get("state", EMPTY)) == ACTIVE else 2.0
	_state_label.custom_minimum_size = _reserve_base + Vector2(b, b) * 2.0

## Bind a DETACHED scalar snapshot (dict is duplicated; no reference retained) plus
## a scalar palette Color for the batch color. Safe to call before or after _ready.
func bind_snapshot(snapshot: Dictionary, color: Color = Color(1, 0, 1, 1)) -> void:
	_snapshot = snapshot.duplicate(true)
	_color = color
	if _tile == null:
		_build_children()
	_refresh()

## M28-C002-C002 static master shell: the slot FRAME is baked into the shell art, so this
## view draws no housing chrome of its own - the shared ColorBatchTile sits inside it.
func set_shell_mode(on: bool) -> void:
	_shell = on
	if on:
		custom_minimum_size = Vector2.ZERO
	if _tile != null:
		_reserve_state_line()
		_refresh()

func is_shell_mode() -> bool:
	return _shell

## Shell mode: the strip reports the baked slot interior this view was fitted to. The view's
## own (legacy, min-size-reserved) outer rect is deliberately left alone so slot origins /
## anchors do not move; the TILE is drawn in exactly the baked interior, top-left aligned,
## so its base never overshoots the housing. Presentation only.
func set_shell_tile_size(sz: Vector2) -> void:
	if sz.is_equal_approx(_shell_tile_size):
		return
	_shell_tile_size = sz
	_apply_tile_size()

func _apply_tile_size() -> void:
	if _tile == null or _shell_tile_size == Vector2.ZERO:
		return
	_tile.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_tile.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_tile.custom_minimum_size = _shell_tile_size

func _refresh() -> void:
	var state: String = str(_snapshot.get("state", EMPTY))
	var occupied: bool = bool(_snapshot.get("occupied", false)) and state != EMPTY
	_state_label.text = ""   # V02/C004: the words WAITING / ACTIVE are never shown
	_set_housing()
	_apply_reserve()
	if not occupied:
		_tile.set_empty(not _shell)   # shell: the baked slot frame is the empty housing
		return
	# Player-facing main number = robots still physically WAITING in this slot =
	# M24 capacity = remaining_to_clear - committed (OWNER_BATCH_SLOT_DISPLAY_DECISION_V01).
	# A committed/in-flight Scrubbot has already left the slot, so it is subtracted
	# immediately; remaining_to_clear and committed decrement together on an authenticated
	# clear, so the displayed waiting count stays correct. The old "50 (2)" raw form is gone.
	_tile.set_batch(_color, "%d" % get_display_count())
	_tile.set_active(state == ACTIVE)   # visual only; WAITING is the plain occupied tile

## Slot housing: baked into the shell art in production (draw nothing); the legacy non-shell
## strip keeps a plain housing so the tile still reads as a cartridge inside it.
func _set_housing() -> void:
	if _shell:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = _HOUSING_BG
	sb.set_corner_radius_all(UiTokens.RADIUS_MD)
	sb.set_border_width_all(2)
	sb.border_color = _HOUSING_EDGE
	sb.set_content_margin_all(UiTokens.SPACE_XS)
	sb.anti_aliasing = true
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

## The (always empty) state-word label text; the words WAITING/ACTIVE are never displayed.
func get_state_text() -> String:
	return _state_label.text if _state_label != null else ""

## The raw displayed label text (for asserting the old "N (c)" form is gone).
func get_count_label_text() -> String:
	return _tile.get_count_text() if _tile != null else ""

## The shared tile (presentation only) - test/evidence access to face rect / count rect.
func get_tile() -> ColorBatchTile:
	return _tile

## Presentation-only GLOBAL spawn anchor (top-center) of this slot view, used by the
## M29 runtime origin provider to derive a real laid-out slot->route origin. Presentation
## geometry only; carries no gameplay/target authority.
func get_spawn_anchor_global() -> Vector2:
	return global_position + Vector2(size.x * 0.5, 0.0)
