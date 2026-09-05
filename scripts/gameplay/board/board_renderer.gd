extends TextureRect
## BoardRenderer — preload this script
## (res://scripts/gameplay/board/board_renderer.gd) rather than relying on
## global class_name lookup; see scripts/data/level_validator.gd for why.
##
## Draws a BoardState efficiently: ONE Image -> ONE ImageTexture -> ONE
## TextureRect, regardless of board size (verified up to 59x59 = 3481
## cells). Never one Node per logical cell. See docs/05_TECH_DECISIONS.md
## (renderer ADR) for why this technique was chosen over per-cell Nodes or
## per-frame draw_rect() calls.
##
## BoardRenderer is presentation-only. It never chooses targets, mutates
## BoardState, dispatches Scrubbots, routes, or decides difficulty — it
## only reads BoardState/palette data and draws it. See
## docs/02_TECH_ARCHITECTURE.md.
##
## Geometry: given an available display rect, computes an integer cell_size
## (floored, never fractional) that fits width x height cells inside it
## while preserving the board's true aspect ratio — a rectangular board
## (e.g. 53x59) is never stretched into a square. Exposes cell-center
## queries for a future routing system to target.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const PaletteColors = preload("res://scripts/data/palette_colors.gd")

## Color drawn for a CLEARED cell: fully transparent, so the gameplay
## background behind the board shows through the cleared hole (ADR-019,
## owner decision META-C004). Never a black/gray/palette substitute.
const CLEARED_COLOR := Color(0, 0, 0, 0)

var _board: BoardState
var _palette_colors: Array[Color] = []
var _cell_size: float = 1.0
var _image: Image

## available_size: the display rect (in this Control's parent's local
## space) that the board should fit inside. Palette is a LevelData.palette
## PackedStringArray (the renderer only needs the palette, not the whole
## LevelData — keeps it decoupled from level metadata it has no reason to
## know about).
func configure(board: BoardState, palette: PackedStringArray, available_size: Vector2) -> void:
	_board = board
	var parse_result = PaletteColors.parse(palette)
	_palette_colors = parse_result.colors
	if not parse_result.is_ok():
		push_warning("BoardRenderer: palette parse errors: %s" % str(parse_result.errors))
	_recompute_geometry(available_size)
	refresh_all()

func _recompute_geometry(available_size: Vector2) -> void:
	var w: int = _board.get_width()
	var h: int = _board.get_height()
	var fit: float = min(available_size.x / float(w), available_size.y / float(h))
	_cell_size = max(floor(fit), 1.0)
	var board_pixel_size := Vector2(w * _cell_size, h * _cell_size)
	custom_minimum_size = board_pixel_size
	size = board_pixel_size
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = TEXTURE_FILTER_NEAREST

func get_cell_size() -> float:
	return _cell_size

func get_board_pixel_size() -> Vector2:
	return size

## Local-space (relative to this Control's top-left) center of a logical
## cell — the seam a future RoutingSystem will use to target Scrubbot
## movement. Does not implement any movement itself.
func get_cell_center_local(x: int, y: int) -> Vector2:
	return Vector2((x + 0.5) * _cell_size, (y + 0.5) * _cell_size)

func get_cell_center_global(x: int, y: int) -> Vector2:
	return global_position + get_cell_center_local(x, y)

## Full rebuild of the displayed image from current BoardState. Use
## update_cells() instead when only a few cells changed.
func refresh_all() -> void:
	var w: int = _board.get_width()
	var h: int = _board.get_height()
	_image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var index: int = _board.get_cell_index(x, y)
			_image.set_pixel(x, y, _color_for_cell(index))
	texture = ImageTexture.create_from_image(_image)

## Partial update: only re-paints the given cell indices, then re-uploads
## the (still small, <= 59x59) image once. Cheaper than refresh_all() when
## few cells changed; still one texture upload either way, since Godot 4's
## Texture2D has no partial/sub-rect update API.
func update_cells(indices: Array) -> void:
	if _image == null:
		refresh_all()
		return
	for index in indices:
		var pos: Vector2i = _board.get_cell_position(index)
		if pos.x < 0:
			continue
		_image.set_pixel(pos.x, pos.y, _color_for_cell(index))
	texture = ImageTexture.create_from_image(_image)

## Reads back the currently-displayed color for a logical cell. Useful for
## tests/tooling; not needed for normal rendering operation.
func get_pixel_color(x: int, y: int) -> Color:
	return _image.get_pixel(x, y)

## ACTIVE  -> the exact source palette color, opaque (subject only to the
##            renderer's existing 8-bit RGBA quantization).
## CLEARED -> fully transparent, so the background shows through.
func _color_for_cell(index: int) -> Color:
	if _board.get_cell_state(index) == BoardState.CellState.CLEARED:
		return CLEARED_COLOR
	var color_id: int = _board.get_color_id(index)
	return _palette_colors[color_id]
