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

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	_build_ui()
	call_deferred("_refresh")

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
	_fixture_option.item_selected.connect(func(_i): _refresh())
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

func _refresh() -> void:
	if _board_area.size.x <= 0 or _board_area.size.y <= 0:
		return
	var fixture: Dictionary = FIXTURE_OPTIONS[_fixture_option.selected]
	var pattern_entry: Dictionary = PATTERN_OPTIONS[_pattern_option.selected]

	# Size dropdown only applies to Synthetic Stripes; Real Artwork uses the
	# fixed JSON dimensions and must not be resized/resampled.
	var is_real: bool = fixture.kind == "real"
	_size_option.disabled = is_real

	var level: LevelData
	var board: BoardState
	var info_prefix: String

	if is_real:
		var loaded: Dictionary = BoardDebugFixtures.load_real_fixture(fixture.path)
		if not loaded.ok:
			_info_label.text = "FIXTURE LOAD ERROR: %s" % loaded.error
			return
		level = loaded.level
		board = BoardState.from_level_data(level)
		BoardDebugFixtures.apply_pattern_masked(board, pattern_entry.value, loaded.void_mask)
		_board_bg.color = REAL_BACKGROUND_COLOR
		info_prefix = "%s — %dx%d (%d artwork + %d VOID) — subset=%s — BG01=%s" % [
			loaded.display_name, loaded.width, loaded.height,
			loaded.artwork_cell_count, loaded.void_count,
			str(loaded.palette_subset_ids), loaded.background_hex,
		]
	else:
		var size_entry: Dictionary = SIZE_OPTIONS[_size_option.selected]
		level = BoardDebugFixtures.make_level(size_entry.w, size_entry.h)
		board = BoardState.from_level_data(level)
		BoardDebugFixtures.apply_pattern(board, pattern_entry.value)
		_board_bg.color = SYNTHETIC_BACKGROUND_COLOR
		info_prefix = "Synthetic Stripes — %dx%d (%d cells)" % [
			size_entry.w, size_entry.h, size_entry.w * size_entry.h,
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
