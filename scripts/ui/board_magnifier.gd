extends Control
## BoardMagnifier — preload this script (res://scripts/ui/board_magnifier.gd); AL-001.
##
## M50-BOARD (owner 2026-10-15): press and hold the board to inspect it. A framed square loupe
## follows the finger and shows the SAME board — the renderer's own texture and ShaderMaterial,
## so the same per-cell colour symbols, grid and transparent CLEARED holes — at >= MIN_ZOOM_CELL
## px per cell (a 59x59 board has ~5..13 px cells on a portrait phone; 16 shapes cannot be
## decoded at that size, the loupe is the readable route). Release hides it.
##
## Covers exactly the board rect (GameplayScreen places it), so Supply fronts, slots, boosters,
## Pause and 2x never route through it. Presentation only: reads the renderer, never touches
## BoardState, routing, agents or any gameplay state. Constant node count (this + Loupe + Zoom +
## Focus), whatever the board size.

const MIN_ZOOM_CELL := 28.0
## Loupe side as a fraction of the viewport's shorter side, clamped to [LOUPE_MIN, LOUPE_MAX] px.
const LOUPE_FRACTION := 0.42
const LOUPE_MIN := 180.0
const LOUPE_MAX := 520.0
## Gap between the finger and the loupe edge.
const FINGER_GAP := 36.0
const FRAME := Color(1, 1, 1)
const BACKDROP := Color(0.125, 0.145, 0.2)   # BG01 Midnight Slate, behind CLEARED holes

var _renderer = null
var _loupe: Panel
var _zoom: TextureRect
var _focus: Panel
var _active := false
var _cell := Vector2.ZERO   # inspected point in board cell units

func _init() -> void:
	name = "BoardMagnifier"
	mouse_filter = Control.MOUSE_FILTER_STOP
	_loupe = Panel.new()
	_loupe.name = "Loupe"
	_loupe.top_level = true
	_loupe.clip_contents = true
	_loupe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loupe.visible = false
	var box := StyleBoxFlat.new()
	box.bg_color = BACKDROP
	_loupe.add_theme_stylebox_override("panel", box)
	add_child(_loupe)
	_zoom = TextureRect.new()
	_zoom.name = "Zoom"
	_zoom.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_zoom.stretch_mode = TextureRect.STRETCH_SCALE
	_zoom.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_zoom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loupe.add_child(_zoom)
	# Frame drawn over the zoomed board (a Panel on top, so the rounded clip stays clean).
	var ring := Panel.new()
	ring.name = "Ring"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	var rb := StyleBoxFlat.new()
	rb.draw_center = false
	rb.border_color = FRAME
	rb.set_border_width_all(6)
	rb.border_color = FRAME
	ring.add_theme_stylebox_override("panel", rb)
	_loupe.add_child(ring)
	_focus = Panel.new()
	_focus.name = "Focus"
	_focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fb := StyleBoxFlat.new()
	fb.draw_center = false
	fb.border_color = FRAME
	fb.set_border_width_all(3)
	fb.expand_margin_left = 2
	fb.expand_margin_right = 2
	fb.expand_margin_top = 2
	fb.expand_margin_bottom = 2
	_focus.add_theme_stylebox_override("panel", fb)
	_loupe.add_child(_focus)
	set_process(false)

## Bind the board renderer to magnify (the presentation's, identity-stable across relayout).
func bind(renderer) -> void:
	_renderer = renderer
	if _active:
		end_inspect()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			inspect_at(event.global_position)
		else:
			end_inspect()
		accept_event()
	elif event is InputEventMouseMotion and _active:
		inspect_at(event.global_position)
		accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and _active:
		end_inspect()

## Show the loupe for the board point under `global_point` (also the test seam).
func inspect_at(global_point: Vector2) -> void:
	if _renderer == null or not is_instance_valid(_renderer) or _renderer.texture == null:
		return
	var inv: Transform2D = _renderer.get_global_transform().affine_inverse()
	var cs: float = _renderer.get_cell_size()
	var grid: Vector2 = Vector2(_renderer.texture.get_size())
	_cell = ((inv * global_point) / cs).clamp(Vector2.ZERO, grid - Vector2(0.001, 0.001))
	var vp := get_viewport_rect().size
	var side := clampf(minf(vp.x, vp.y) * LOUPE_FRACTION, LOUPE_MIN, LOUPE_MAX)
	var z := get_zoom_cell()
	_zoom.texture = _renderer.texture
	_zoom.material = _renderer.material
	_zoom.size = grid * z
	_zoom.position = Vector2(side, side) * 0.5 - _cell * z
	var focus_cell := _cell.floor()
	_focus.position = _zoom.position + focus_cell * z
	_focus.size = Vector2(z, z)
	_loupe.size = Vector2(side, side)
	# Above the finger, clamped on screen; below it when there is no room above.
	var pos := global_point + Vector2(-side * 0.5, -side - FINGER_GAP)
	if pos.y < 0.0:
		pos.y = global_point.y + FINGER_GAP
	pos.x = clampf(pos.x, 0.0, maxf(vp.x - side, 0.0))
	pos.y = clampf(pos.y, 0.0, maxf(vp.y - side, 0.0))
	_loupe.global_position = pos
	_loupe.visible = true
	_active = true
	set_process(true)

func end_inspect() -> void:
	_active = false
	_loupe.visible = false
	_zoom.texture = null
	set_process(false)

## The renderer swaps its ImageTexture on every repaint; keep the loupe on the live one.
func _process(_delta: float) -> void:
	if _renderer == null or not is_instance_valid(_renderer):
		end_inspect()
		return
	if _zoom.texture != _renderer.texture:
		_zoom.texture = _renderer.texture
	if _zoom.material != _renderer.material:
		_zoom.material = _renderer.material

## Displayed px per board cell inside the loupe (>= MIN_ZOOM_CELL and >= 2.5x the board cell).
func get_zoom_cell() -> float:
	var vp := get_viewport_rect().size
	var side := clampf(minf(vp.x, vp.y) * LOUPE_FRACTION, LOUPE_MIN, LOUPE_MAX)
	var shown := 1.0
	if _renderer != null and is_instance_valid(_renderer):
		shown = _renderer.get_cell_size() * absf(_renderer.get_global_transform().get_scale().x)
	return maxf(maxf(MIN_ZOOM_CELL, side / 7.0), shown * 2.5)

# ---------------------------------------------------------------- test accessors ----

func is_inspecting() -> bool:
	return _active and _loupe.visible

## Board cell (x, y) currently under the loupe's focus frame.
func get_focus_cell() -> Vector2i:
	return Vector2i(_cell.floor())

func get_loupe() -> Panel:
	return _loupe

func get_zoom_view() -> TextureRect:
	return _zoom
