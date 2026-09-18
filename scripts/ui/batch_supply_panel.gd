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

const VISIBLE_ROWS := UiTokens.SUPPLY_VISIBLE_ROWS   # exactly 3 in V1
const MIN_COLUMNS := 3
const MAX_COLUMNS := 5

const _EMPTY_TILE := Color(0.10, 0.12, 0.16, 1.0)
const _ROW_BG := Color(0.16, 0.19, 0.25, 1.0)

var _columns: Array = []   # each: {root:VBoxContainer, rows:[ {panel, swatch, count} x3 ]}

func _ready() -> void:
	add_theme_constant_override("separation", UiTokens.SPACE_SM)
	custom_minimum_size.x = maxf(custom_minimum_size.x, UiTokens.SUPPLY_PANEL_MIN_WIDTH)

## Bind detached player snapshot. `column_snapshots` is clamped to [3,5] columns;
## `colors` maps color_id -> Color. Rebuilds column widgets when the column count
## changes (3/4/5 supported). Always renders exactly VISIBLE_ROWS rows per column.
func bind_player_snapshot(column_snapshots: Array, colors: Array = []) -> void:
	var n: int = clampi(column_snapshots.size(), MIN_COLUMNS, MAX_COLUMNS)
	if _columns.size() != n:
		_rebuild_columns(n)
	for c in range(n):
		var snap: Dictionary = column_snapshots[c] if c < column_snapshots.size() and column_snapshots[c] is Dictionary else {}
		var preview: Array = snap.get("preview", []) if snap.get("preview", []) is Array else []
		for r in range(VISIBLE_ROWS):
			_bind_row(_columns[c]["rows"][r], preview[r] if r < preview.size() else null, r == 0, colors)

func _rebuild_columns(n: int) -> void:
	for child in get_children():
		child.queue_free()
	_columns.clear()
	for c in range(n):
		var col := VBoxContainer.new()
		col.name = "SupplyColumn%d" % c
		col.add_theme_constant_override("separation", UiTokens.SPACE_XS)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(col)
		var rows: Array = []
		for r in range(VISIBLE_ROWS):
			rows.append(_make_row(col, r == 0))
		_columns.append({"root": col, "rows": rows})

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

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hbox)

	var swatch := ColorRect.new()
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.custom_minimum_size = Vector2(UiTokens.ICON_SM, UiTokens.ICON_SM)
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(swatch)

	var count := Label.new()
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(count)

	return {"panel": panel, "swatch": swatch, "count": count, "front": front}

func _bind_row(row: Dictionary, batch, front: bool, colors: Array) -> void:
	var panel: PanelContainer = row["panel"]
	var swatch: ColorRect = row["swatch"]
	var count: Label = row["count"]
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(UiTokens.RADIUS_SM)
	sb.set_content_margin_all(UiTokens.SPACE_XS)
	if batch == null or not (batch is Dictionary):
		# Clean empty / end-of-column tile.
		swatch.color = Color(0, 0, 0, 0)
		count.text = ""
		sb.bg_color = _EMPTY_TILE
		panel.add_theme_stylebox_override("panel", sb)
		panel.modulate = Color(1, 1, 1, 1)
		return
	var cid: int = int(batch.get("color_id", -1))
	swatch.color = colors[cid] if cid >= 0 and cid < colors.size() else Color(1, 0, 1, 1)
	count.text = "x%d" % int(batch.get("robot_count", 0))
	sb.bg_color = _ROW_BG
	if front:
		sb.set_border_width_all(3)
		sb.border_color = Color(0.20, 0.85, 0.95, 1.0)
		panel.modulate = Color(1, 1, 1, 1)
	else:
		sb.set_border_width_all(1)
		sb.border_color = Color(0.30, 0.35, 0.44, 1.0)
		# Preview rows visibly secondary.
		panel.modulate = Color(1, 1, 1, 0.7)
	panel.add_theme_stylebox_override("panel", sb)

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
