extends HBoxContainer
## BatchSupplyPanel — M28 production READ-ONLY presentation of the M23 batch supply.
## Preload this script (res://scripts/ui/batch_supply_panel.gd); do not rely on
## global class_name (AL-001).
##
## Production player input is supply-front batch selection (M29 wires touch). This
## panel is presentation ONLY: it renders 3/4/5 FIFO supply columns, and in V1
## shows EXACTLY three visible rows per column (front + two preview). The front row
## (row 0, the future selectable batch) is visually primary; rows 1/2 are secondary
## preview; deeper hidden queue depth is NEVER rendered or exposed. End-of-column /
## exhausted state renders as clean empty tiles.
##
## Input is the DETACHED scalar snapshot produced by
## BatchSupplyEngine.player_snapshot() (per column {front, preview(<=depth),
## remaining}, batches as ColorBatch.to_dict()). It retains NO engine reference and
## reads `remaining` only to decide emptiness — never to render hidden depth.

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const ColorBatchTile = preload("res://scripts/ui/color_batch_tile.gd")

const VISIBLE_ROWS := UiTokens.SUPPLY_VISIBLE_ROWS   # exactly 3 in V1
const MIN_COLUMNS := 3
const MAX_COLUMNS := 5

## Presentation-only production-input signal (M29 WP01). Emitted EXACTLY ONCE per
## accepted physical activation gesture on a column FRONT (row 0) surface. It carries
## only the column index — the panel retains NO M23/M24 engine reference and mutates no
## gameplay truth. The M29 ProductionInputController owns the real transactional
## placement; the panel just reports which front the player activated.
signal front_batch_activated(column_index: int)

## Mouse/touch de-duplication. Godot emulates a mouse click from the first touch
## (emulate_mouse_from_touch, default on) and dispatches that emulated mouse event BEFORE the
## ScreenTouch it mirrors (core/input/input.cpp), tagged device InputEvent.DEVICE_ID_EMULATION.
## M47-FAMILY-APK-TOUCH-R01: the old handler only had the time window below, which cannot catch
## an emulated PRESS that precedes its touch: the emulated press armed a "mouse" gesture, the
## touch press was ignored as a second gesture, the emulated release fell inside the window and
## the touch release did not match - so a quick tap placed nothing (only a >200 ms hold did).
## Emulated mouse events are therefore ignored outright (the real touch carries the gesture);
## the window still drops an OS-synthesized (non-emulation-device) mouse that follows a touch.
## A genuine desktop mouse (no preceding touch) is untouched.
const _TOUCH_MOUSE_DEDUP_MSEC := 200

var _columns: Array = []   # each: {root:VBoxContainer, rows:[ {panel, tile, swatch, count, front} x3 ]}

# --- production-input state (opt-in via enable_front_input(); default OFF so M28
# presentation stays IGNORE-only and unchanged) --------------------------------------
var _input_enabled := false
var _front_panels: Array = []      # PanelContainer per column front (row 0)
var _front_enabled: Array = []     # bool per column: front is a live selectable batch
# One serialized in-progress gesture at a time (WP03 multi-touch / reentry safety):
var _pending_col: int = -1
var _pending_is_touch := false
var _pending_touch_index: int = -1
var _last_touch_msec: int = -100000

## M28-C002-C002 static master shell mode: the panel is placed exactly over the baked
## Batch Supply cell grid; columns/rows become equal cells separated by the baked gaps, so
## every tile (and every front hitbox) coincides with a baked cell interior. Tiles draw no
## frame chrome — only the live batch colour, count and front/preview state.
var _shell_mode := false
var _gap := Vector2(UiTokens.SPACE_SM, UiTokens.SPACE_XS)

func _ready() -> void:
	add_theme_constant_override("separation", int(_gap.x))
	if not _shell_mode:
		custom_minimum_size.x = maxf(custom_minimum_size.x, UiTokens.SUPPLY_PANEL_MIN_WIDTH)

## M28-C002-C002-R01 (owner S2-B): invisible front touch geometry may exceed the painted
## cell up to the nominal touch target, never beyond half the baked gap (no overlap).
var _min_hit: float = 0.0

func set_min_hit_size(px: float) -> void:
	_min_hit = px
	if _input_enabled:
		_apply_front_input_surfaces()

## Re-fit every front HitArea to its tile's CURRENT global rect (call after layout).
func refresh_hit_areas() -> void:
	for p in _front_panels:
		if p != null and is_instance_valid(p):
			_size_hit(p)

func get_front_hit_rect(column: int) -> Rect2:
	if column < 0 or column >= _front_panels.size():
		return Rect2()
	var hit = _front_panels[column].get_node_or_null("HitArea")
	return hit.get_global_rect() if hit != null else _front_panels[column].get_global_rect()

func _size_hit(panel: PanelContainer) -> void:
	var hit: Control = panel.get_node_or_null("HitArea")
	if hit == null:
		return
	var sz: Vector2 = panel.size
	var ex: float = clampf((_min_hit - sz.x) * 0.5, 0.0, maxf(_gap.x * 0.5 - 0.5, 0.0))
	var ey: float = clampf((_min_hit - sz.y) * 0.5, 0.0, maxf(_gap.y * 0.5 - 0.5, 0.0))
	hit.global_position = panel.global_position - Vector2(ex, ey)
	hit.size = sz + Vector2(ex, ey) * 2.0

func set_shell_grid(gap: Vector2) -> void:
	_shell_mode = true
	_gap = gap
	custom_minimum_size = Vector2.ZERO
	add_theme_constant_override("separation", int(round(gap.x)))
	for col in _columns:
		_apply_shell_column(col["root"])
		for r in col["rows"]:
			_apply_shell_row(r["panel"])

func is_shell_mode() -> bool:
	return _shell_mode

func _apply_shell_column(col: VBoxContainer) -> void:
	col.add_theme_constant_override("separation", int(round(_gap.y)))

func _apply_shell_row(panel: PanelContainer) -> void:
	panel.custom_minimum_size = Vector2.ZERO
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

## Bind detached player snapshot. `column_snapshots` is clamped to [3,5] columns;
## `colors` maps color_id -> Color. Rebuilds column widgets when the column count
## changes (3/4/5 supported). Always renders exactly VISIBLE_ROWS rows per column.
func bind_player_snapshot(column_snapshots: Array, colors: Array = []) -> void:
	var n: int = clampi(column_snapshots.size(), MIN_COLUMNS, MAX_COLUMNS)
	if _columns.size() != n:
		_rebuild_columns(n)
	_front_enabled.resize(n)
	for c in range(n):
		var snap: Dictionary = column_snapshots[c] if c < column_snapshots.size() and column_snapshots[c] is Dictionary else {}
		var preview: Array = snap.get("preview", []) if snap.get("preview", []) is Array else []
		# Front is selectable only when a live front batch exists; an exhausted-column
		# front is disabled (presentation dim + input ignored).
		_front_enabled[c] = snap.get("front", null) is Dictionary
		for r in range(VISIBLE_ROWS):
			_bind_row(_columns[c]["rows"][r], preview[r] if r < preview.size() else null, r == 0, colors)
	if _input_enabled:
		_apply_front_input_surfaces()

func _rebuild_columns(n: int) -> void:
	for child in get_children():
		child.queue_free()
	_columns.clear()
	_front_panels.clear()
	_front_enabled.clear()
	_pending_col = -1
	for c in range(n):
		var col := VBoxContainer.new()
		col.name = "SupplyColumn%d" % c
		col.add_theme_constant_override("separation", UiTokens.SPACE_XS)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(col)
		var rows: Array = []
		for r in range(VISIBLE_ROWS):
			rows.append(_make_row(col, r == 0))
		if _shell_mode:
			_apply_shell_column(col)
			for row in rows:
				_apply_shell_row(row["panel"])
		_columns.append({"root": col, "rows": rows})
		_front_panels.append(rows[0]["panel"])
		_front_enabled.append(false)
	if _input_enabled:
		_apply_front_input_surfaces()

# --------------------------------------------------- production front input (WP01/03) --

## Opt-in: make ONLY the column FRONT (row 0) surfaces player-selectable and emit
## front_batch_activated on an accepted gesture. Preview rows (1/2) and every other
## widget stay presentation-only. Idempotent. Default OFF, so a screen used purely for
## M28 presentation is unchanged (all IGNORE).
func enable_front_input() -> void:
	_input_enabled = true
	_apply_front_input_surfaces()

func is_front_input_enabled() -> bool:
	return _input_enabled

func get_front_enabled(column: int) -> bool:
	return column >= 0 and column < _front_enabled.size() and bool(_front_enabled[column])

func get_pending_column() -> int:
	return _pending_col

## Cancel any in-progress gesture (focus/background loss, WP03). A subsequent stale
## release then matches no pending gesture and emits nothing.
func cancel_all_gestures() -> void:
	_pending_col = -1
	_pending_is_touch = false
	_pending_touch_index = -1

func _apply_front_input_surfaces() -> void:
	for c in range(_front_panels.size()):
		var panel: PanelContainer = _front_panels[c]
		if panel == null or not is_instance_valid(panel):
			continue
		# Front row becomes the single activation surface for its column.
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var cb := Callable(self, "_on_front_gui_input").bind(c)
		if not panel.gui_input.is_connected(cb):
			panel.gui_input.connect(cb)
		# S2-B: invisible, slightly larger hit surface over the same front (top_level, so no
		# container resizes it); same gesture handler, so one gesture = one activation.
		if _shell_mode and _min_hit > 0.0 and panel.get_node_or_null("HitArea") == null:
			var hit := Control.new()
			hit.name = "HitArea"
			hit.top_level = true
			hit.mouse_filter = Control.MOUSE_FILTER_STOP
			panel.add_child(hit)
			hit.gui_input.connect(cb)
			panel.item_rect_changed.connect(_size_hit.bind(panel))
		_size_hit(panel)

## Per-front gesture handler. Press arms a single serialized pending gesture; the
## matching release emits exactly once. Mouse and touch are de-duplicated so one
## physical touch (+ its synthesized mouse) yields at most one activation; desktop
## mouse works independently. A disabled/exhausted front ignores all input.
func _on_front_gui_input(event: InputEvent, column: int) -> void:
	if not _input_enabled:
		return
	if event is InputEventScreenTouch:
		_last_touch_msec = Time.get_ticks_msec()
		if event.pressed:
			_begin_gesture(column, true, event.index)
		else:
			_release_gesture(column, true, event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Ignore the engine's touch-emulated mouse (it precedes its touch) and any mouse
		# synthesized from a touch just handled (dedup window).
		if event.device == InputEvent.DEVICE_ID_EMULATION or Time.get_ticks_msec() - _last_touch_msec < _TOUCH_MOUSE_DEDUP_MSEC:
			return
		if event.pressed:
			_begin_gesture(column, false, -1)
		else:
			_release_gesture(column, false, -1)

func _begin_gesture(column: int, is_touch: bool, touch_index: int) -> void:
	if not get_front_enabled(column):
		return
	# Serialize: while one gesture is pending, a second (rapid tap / other finger /
	# other column) is ignored — never a partial/duplicate activation.
	if _pending_col != -1:
		return
	_pending_col = column
	_pending_is_touch = is_touch
	_pending_touch_index = touch_index

func _release_gesture(column: int, is_touch: bool, touch_index: int) -> void:
	if _pending_col != column or _pending_is_touch != is_touch:
		return
	if is_touch and touch_index != _pending_touch_index:
		return
	cancel_all_gestures()
	if get_front_enabled(column):
		front_batch_activated.emit(column)

func _make_row(col: VBoxContainer, front: bool) -> Dictionary:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(UiTokens.SUPPLY_TILE_MIN, UiTokens.SUPPLY_TILE_MIN)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Front row visually primary (taller, opaque, full alpha); preview rows secondary.
	if front:
		panel.custom_minimum_size.y = UiTokens.SUPPLY_TILE_MIN
	else:
		panel.custom_minimum_size.y = int(UiTokens.SUPPLY_TILE_MIN * 0.72)
	col.add_child(panel)

	# M28-C002-C004: every tile (front + preview, shell or not) is the shared ColorBatchTile -
	# the SAME rounded 3D component the slots use. The row panel stays the (front-only) input
	# surface and draws nothing itself; colour/count stay live Godot UI.
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var tile := ColorBatchTile.new()
	tile.name = "Tile"
	tile.set_preview(not front)
	panel.add_child(tile)
	var swatch := ColorRect.new()   # data probe only (never drawn)
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.visible = false
	panel.add_child(swatch)
	return {"panel": panel, "tile": tile, "swatch": swatch, "count": tile.get_count_label(), "front": front}

func _bind_row(row: Dictionary, batch, front: bool, colors: Array) -> void:
	var panel: PanelContainer = row["panel"]
	var tile: ColorBatchTile = row["tile"]
	var swatch: ColorRect = row["swatch"]
	if batch == null or not (batch is Dictionary):
		# Clean empty / end-of-column tile.
		swatch.color = Color(0, 0, 0, 0)
		tile.set_empty(not _shell_mode)   # shell: the baked cell is the empty tile
		panel.modulate = Color(1, 1, 1, 1)
		return
	var cid: int = int(batch.get("color_id", -1))
	var col: Color = colors[cid] if cid >= 0 and cid < colors.size() else Color(1, 0, 1, 1)
	swatch.color = col
	tile.set_batch(col, "%d" % int(batch.get("robot_count", 0)))
	tile.set_preview(not front)
	# Front = the only selectable batch: full strength + cyan rim. Preview rows are visibly
	# secondary (dimmed, no rim) and never interactive.
	tile.set_active(front)
	panel.modulate = Color(1, 1, 1, 1) if front else Color(0.62, 0.62, 0.70, 0.85)

## Test/evidence accessor: displayed count text of a row (column, row).
func get_row_count_text(column: int, row: int) -> String:
	if column < 0 or column >= _columns.size() or row < 0 or row >= VISIBLE_ROWS:
		return ""
	return _columns[column]["rows"][row]["count"].text

func get_column_count() -> int:
	return _columns.size()

func get_visible_row_count() -> int:
	return VISIBLE_ROWS

## Test accessor: the row PanelContainers for a column (front first). Never exposes
## hidden queue depth — always exactly VISIBLE_ROWS entries.
func get_column_row_panels(column: int) -> Array:
	if column < 0 or column >= _columns.size():
		return []
	var out: Array = []
	for r in _columns[column]["rows"]:
		out.append(r["panel"])
	return out
