extends Control
## Development-only visual comparison tool for BoardRenderer and the
## DIRTY/CLEAN presets. NOT production UI — see docs/04_ROADMAP.md M3 for
## where the real gameplay screen belongs. Lets the project owner compare
## Preset A/B/C at native gameplay scale on every difficulty band's
## boundary sizes plus representative rectangular boards, without any code
## changes (dropdowns only). See tasks.md M06/M10.
##
## UI is built procedurally in _ready() rather than hand-authored in the
## .tscn, since this session has no interactive editor available to
## visually verify a complex hand-written scene tree; procedural
## construction is verifiable by headless boot instead.

const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const DirtyCleanPresets = preload("res://scripts/gameplay/board/dirty_clean_presets.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")

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
	{"label": "All DIRTY", "value": BoardDebugFixtures.StatePattern.ALL_DIRTY},
	{"label": "All CLEAN", "value": BoardDebugFixtures.StatePattern.ALL_CLEAN},
	{"label": "Half DIRTY / half CLEAN", "value": BoardDebugFixtures.StatePattern.HALF_SPLIT},
	{"label": "Checker DIRTY/CLEAN", "value": BoardDebugFixtures.StatePattern.CHECKER},
]

var _size_option: OptionButton
var _pattern_option: OptionButton
var _preset_option: OptionButton
var _info_label: Label
var _board_area: Control
var _renderer: Control # BoardRenderer instance (extends TextureRect)

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

	_preset_option = OptionButton.new()
	for preset_name in DirtyCleanPresets.preset_names():
		_preset_option.add_item("Preset %s — %s" % [preset_name, DirtyCleanPresets.get_preset(preset_name).label])
	_preset_option.item_selected.connect(func(_i): _refresh())
	controls_row.add_child(_preset_option)

	_info_label = Label.new()
	root_vbox.add_child(_info_label)

	_board_area = Control.new()
	_board_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_area.resized.connect(_refresh)
	root_vbox.add_child(_board_area)

	_renderer = BoardRenderer.new()
	_board_area.add_child(_renderer)

func _refresh() -> void:
	if _board_area.size.x <= 0 or _board_area.size.y <= 0:
		return
	var size_entry: Dictionary = SIZE_OPTIONS[_size_option.selected]
	var pattern_entry: Dictionary = PATTERN_OPTIONS[_pattern_option.selected]
	var preset_name: String = DirtyCleanPresets.preset_names()[_preset_option.selected]

	var level: LevelData = BoardDebugFixtures.make_level(size_entry.w, size_entry.h)
	var board: BoardState = BoardState.from_level_data(level)
	BoardDebugFixtures.apply_pattern(board, pattern_entry.value)

	_renderer.configure(board, level.palette, _board_area.size)
	_renderer.set_dirty_preset(preset_name)
	_renderer.position = (_board_area.size - _renderer.get_board_pixel_size()) / 2.0

	_info_label.text = (
		"%dx%d (%d cells) — cell_size=%.2fpx — board_pixels=%s — preset=%s — pattern=%s — renderer child count=%d"
		% [
			size_entry.w, size_entry.h, size_entry.w * size_entry.h,
			_renderer.get_cell_size(), str(_renderer.get_board_pixel_size()),
			preset_name, pattern_entry.label, _renderer.get_child_count(),
		]
	)
