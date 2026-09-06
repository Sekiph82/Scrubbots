extends Control
## Development-only visual comparison / manual-QA tool for BoardRenderer under
## the ACTIVE/CLEARED board model (ADR-019, owner decision META-C004). NOT
## production UI — see docs/04_ROADMAP.md for where the real gameplay screen
## belongs.
##
## Two fixture sources (M10-C001):
##   - Synthetic Stripes: procedural placeholder palette, size dropdown +
##     ACTIVE/CLEARED pattern; conspicuous magenta transparency-test background.
##   - Real Artwork - Level 007/010/013: owner-authorized debug fixtures loaded
##     directly from data/debug/board_renderer_fixtures/*.json (fixed logical
##     dimensions, canonical C01..C15 subset colors, VOID mask). Background is
##     BG01 Midnight Slate #202533; the ACTIVE/CLEARED pattern applies only to
##     artwork cells, VOID stays background.
##
## The board is drawn by the single-Image/ImageTexture BoardRenderer (ADR-011);
## square-cell separation is a batched grid overlay (one Control, no per-cell
## Nodes). ACTIVE = flat source palette color, opaque; CLEARED = transparent
## (background shows through). No gloss/bevel/shadow/interpolation.
##
## UI is built procedurally in _ready() (verifiable by headless boot) rather
## than hand-authored in the .tscn.

const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BoardGridOverlay = preload("res://scripts/debug/board_grid_overlay.gd")

## Synthetic-Stripes transparency-test background (deliberately garish so
## alpha-0 CLEARED cells obviously reveal THIS colour, not a black artifact).
const SYNTHETIC_BACKGROUND_COLOR := Color(0.9, 0.2, 0.8)
## Real Artwork background — BG01 Midnight Slate #202533 (owner-locked).
const REAL_BACKGROUND_COLOR := Color("#202533")

const FIXTURE_OPTIONS := [
	{"label": "Synthetic Stripes", "kind": "synthetic"},
	{"label": "Real Artwork - Level 007", "kind": "real", "path": "res://data/debug/board_renderer_fixtures/level_007.json"},
	{"label": "Real Artwork - Level 010", "kind": "real", "path": "res://data/debug/board_renderer_fixtures/level_010.json"},
	{"label": "Real Artwork - Level 013", "kind": "real", "path": "res://data/debug/board_renderer_fixtures/level_013.json"},
]

const SIZE_OPTIONS := [
	{"label": "20x20 (Easy min)", "w": 20, "h": 20},
	{"label": "29x29 (Easy max)", "w": 29, "h": 29},
	{"label": "20x27 (Easy rect)", "w": 20, "h": 27},
	{"label": "30x30 (Medium min)", "w": 30, "h": 30},
	{"label": "39x39 (Medium max)", "w": 39, "h": 39},
	{"label": "34x39 (Medium rect)", "w": 34, "h": 39},
	{"label": "40x40 (Hard min)", "w": 40, "h": 40},
	{"label": "49x49 (Hard max)", "w": 49, "h": 49},
	{"label": "48x41 (Hard rect)", "w": 48, "h": 41},
	{"label": "50x50 (Very Hard min)", "w": 50, "h": 50},
	{"label": "59x59 (Very Hard max, CURRENT MAXIMUM)", "w": 59, "h": 59},
	{"label": "53x59 (Very Hard rect)", "w": 53, "h": 59},
]

const PATTERN_OPTIONS := [
	{"label": "All ACTIVE", "value": BoardDebugFixtures.StatePattern.ALL_ACTIVE},
	{"label": "All CLEARED (fully transparent)", "value": BoardDebugFixtures.StatePattern.ALL_CLEARED},
	{"label": "Half ACTIVE / half CLEARED", "value": BoardDebugFixtures.StatePattern.HALF_SPLIT},
	{"label": "Checker ACTIVE/CLEARED", "value": BoardDebugFixtures.StatePattern.CHECKER},
]

var _fixture_option: OptionButton
var _size_option: OptionButton
var _pattern_option: OptionButton
var _info_label: Label
var _board_area: Control
var _board_bg: ColorRect # visible background behind the board
var _renderer: Control # BoardRenderer instance (extends TextureRect)
var _grid: Control # BoardGridOverlay
## Immutable source fixture (from load_real_fixture) for the selected Real
## Artwork option, or {} for Synthetic Stripes. The source matrix is never
## mutated; it is embedded into the selected canvas per _refresh().
var _current_source: Dictionary = {}

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()
	call_deferred("_on_fixture_changed")

func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.anchor_right = 1.0
	root_vbox.anchor_bottom = 1.0
	add_child(root_vbox)

	var controls_row := HBoxContainer.new()
	root_vbox.add_child(controls_row)

	_fixture_option = OptionButton.new()
	for entry in FIXTURE_OPTIONS:
		_fixture_option.add_item(entry.label)
	_fixture_option.item_selected.connect(func(_i): _on_fixture_changed())
	controls_row.add_child(_fixture_option)

	_size_option = OptionButton.new()
	for entry in SIZE_OPTIONS:
		_size_option.add_item(entry.label)
	_size_option.item_selected.connect(func(_i): _refresh())
	controls_row.add_child(_size_option)

	_pattern_option = OptionButton.new()
	for entry in PATTERN_OPTIONS:
		_pattern_option.add_item(entry.label)
	_pattern_option.item_selected.connect(func(_i): _refresh())
	controls_row.add_child(_pattern_option)

	_info_label = Label.new()
	root_vbox.add_child(_info_label)

	_board_area = Control.new()
	_board_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_area.resized.connect(_refresh)
	root_vbox.add_child(_board_area)

	# Background sits behind the board; CLEARED (alpha-0) and VOID cells reveal it.
	_board_bg = ColorRect.new()
	_board_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_area.add_child(_board_bg)

	_renderer = BoardRenderer.new()
	_board_area.add_child(_renderer)

	# Batched square-cell separation overlay (one Node, drawn above the board).
	_grid = BoardGridOverlay.new()
	_board_area.add_child(_grid)

## True only when SIZE_OPTIONS[idx] can fully contain the given source matrix
## (canvas must be >= source in both dimensions; too small would crop).
func _size_fits(idx: int, source_w: int, source_h: int) -> bool:
	var e: Dictionary = SIZE_OPTIONS[idx]
	return int(e.w) >= source_w and int(e.h) >= source_h

## Reload the selected fixture's immutable source, mark which Size options can
## contain it (disabling too-small ones so they can never crop), snap the Size
## selection to a valid option, then refresh. Synthetic Stripes re-enables all
## sizes and keeps its existing behavior.
func _on_fixture_changed() -> void:
	var fixture: Dictionary = FIXTURE_OPTIONS[_fixture_option.selected]
	if fixture.kind == "real":
		var source: Dictionary = BoardDebugFixtures.load_real_fixture(fixture.path)
		_current_source = source
		if source.ok:
			var sw: int = int(source.source_width)
			var sh: int = int(source.source_height)
			var first_valid := -1
			for i in SIZE_OPTIONS.size():
				var fits := _size_fits(i, sw, sh)
				_size_option.set_item_disabled(i, not fits)
				if fits and first_valid < 0:
					first_valid = i
			# If the current selection can't contain the source, move to the
			# smallest valid canvas rather than cropping.
			if _size_option.selected < 0 or _size_option.get_item_disabled(_size_option.selected):
				if first_valid >= 0:
					_size_option.select(first_valid)
	else:
		_current_source = {}
		for i in SIZE_OPTIONS.size():
			_size_option.set_item_disabled(i, false)
	_refresh()

func _refresh() -> void:
	if _board_area.size.x <= 0 or _board_area.size.y <= 0:
		return
	var fixture: Dictionary = FIXTURE_OPTIONS[_fixture_option.selected]
	var pattern_entry: Dictionary = PATTERN_OPTIONS[_pattern_option.selected]
	var is_real: bool = fixture.kind == "real"
	# Size dropdown stays usable for both; Real Artwork just disables the
	# too-small options (handled in _on_fixture_changed).
	_size_option.disabled = false

	var level: LevelData
	var board: BoardState
	var info_prefix: String

	if is_real:
		var source: Dictionary = _current_source
		if source == null or not source.get("ok", false):
			_info_label.text = "FIXTURE LOAD ERROR: %s" % (source.get("error", "no source") if source else "no source")
			return
		var sw: int = int(source.source_width)
		var sh: int = int(source.source_height)
		# Guard: never crop. If the selected canvas is too small, snap to the
		# smallest option that fully contains the source.
		var sel: int = _size_option.selected
		if sel < 0 or not _size_fits(sel, sw, sh):
			sel = -1
			for i in SIZE_OPTIONS.size():
				if _size_fits(i, sw, sh):
					sel = i
					break
			if sel < 0:
				_info_label.text = "%s — no canvas size can contain source %dx%d without cropping" % [source.display_name, sw, sh]
				return
			_size_option.select(sel)
		var size_entry: Dictionary = SIZE_OPTIONS[sel]
		var embedded: Dictionary = BoardDebugFixtures.embed_real_fixture_in_canvas(source, int(size_entry.w), int(size_entry.h))
		if not embedded.ok:
			_info_label.text = "EMBED ERROR: %s" % embedded.error
			return
		level = embedded.level
		board = BoardState.from_level_data(level)
		BoardDebugFixtures.apply_pattern_masked(board, pattern_entry.value, embedded.void_mask)
		_board_bg.color = REAL_BACKGROUND_COLOR
		info_prefix = "%s — source=%dx%d — canvas=%dx%d — offset=(%d,%d) — artwork=%d — void=%d — subset=%s — BG01=%s" % [
			embedded.display_name, embedded.source_width, embedded.source_height,
			embedded.canvas_width, embedded.canvas_height,
			embedded.offset_x, embedded.offset_y,
			embedded.artwork_cell_count, embedded.void_count,
			str(embedded.palette_subset_ids), embedded.background_hex,
		]
	else:
		var syn_entry: Dictionary = SIZE_OPTIONS[_size_option.selected]
		level = BoardDebugFixtures.make_level(int(syn_entry.w), int(syn_entry.h))
		board = BoardState.from_level_data(level)
		BoardDebugFixtures.apply_pattern(board, pattern_entry.value)
		_board_bg.color = SYNTHETIC_BACKGROUND_COLOR
		info_prefix = "Synthetic Stripes — %dx%d (%d cells)" % [
			int(syn_entry.w), int(syn_entry.h), int(syn_entry.w) * int(syn_entry.h),
		]

	_renderer.configure(board, level.palette, _board_area.size)
	var board_pixels: Vector2 = _renderer.get_board_pixel_size()
	var origin: Vector2 = (_board_area.size - board_pixels) / 2.0
	_renderer.position = origin
	# Background + grid overlay cover exactly the board rect.
	_board_bg.position = origin
	_board_bg.size = board_pixels
	_grid.position = origin
	_grid.size = board_pixels
	# On BG01 use a light separation line; on the garish synthetic bg use dark.
	var line_color := Color(1, 1, 1, 0.18) if is_real else Color(0, 0, 0, 0.30)
	_grid.configure(_renderer.get_cell_size(), board.get_width(), board.get_height(), line_color)

	_info_label.text = (
		"%s — cell_size=%.2fpx — board_pixels=%s — pattern=%s — renderer child count=%d"
		% [
			info_prefix, _renderer.get_cell_size(), str(board_pixels),
			pattern_entry.label, _renderer.get_child_count(),
		]
	)
