extends Node2D
## RoutingLabOverlay — M17 debug-only visualization for the Routing Prototype
## Lab. Preload it (AL-001). It draws a board (ACTIVE vs CLEARED cells) and a set
## of route polylines for owner visual comparison. It computes NOTHING: it only
## draws data handed to it (board + already-computed route point sets). It never
## selects a target, never routes, never mutates BoardState. Not production UI.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

var cell_pixels: float = 16.0
var pixel_origin: Vector2 = Vector2(24, 24)
var show_routes: bool = true

var _board
var _target_cells: Dictionary = {} # Vector2i -> true
var _routes: Array = []            # Array of PackedVector2Array (successful only)

func set_data(board, target_cells: Dictionary, routes: Array) -> void:
	_board = board
	_target_cells = target_cells
	_routes = routes
	queue_redraw()

## Fit cell_pixels so the board fills up to `avail` pixels (diagnostic only).
func fit_to(avail: Vector2) -> void:
	if _board == null:
		return
	var w: int = _board.get_width()
	var h: int = _board.get_height()
	if w <= 0 or h <= 0:
		return
	var usable := avail - pixel_origin * 2.0
	cell_pixels = maxf(2.0, minf(usable.x / float(w), usable.y / float(h)))
	queue_redraw()

func _to_px(p: Vector2) -> Vector2:
	return pixel_origin + p * cell_pixels

func _draw() -> void:
	if _board == null:
		return
	var w: int = _board.get_width()
	var h: int = _board.get_height()
	var active_col := Color(0.35, 0.40, 0.55)
	var target_col := Color(0.95, 0.75, 0.20)
	var grid_col := Color(1, 1, 1, 0.06)
	# Cells: ACTIVE filled; CLEARED left as background. Target cells highlighted.
	for y in h:
		for x in w:
			var idx: int = _board.get_cell_index(x, y)
			var rect := Rect2(_to_px(Vector2(x, y)), Vector2(cell_pixels, cell_pixels))
			if _target_cells.has(Vector2i(x, y)):
				draw_rect(rect, target_col, true)
			elif _board.get_cell_state(idx) == BoardState.CellState.ACTIVE:
				draw_rect(rect, active_col, true)
	# Light grid outline for orientation on big boards.
	if cell_pixels >= 6.0:
		for x in range(w + 1):
			draw_line(_to_px(Vector2(x, 0)), _to_px(Vector2(x, h)), grid_col, 1.0)
		for y in range(h + 1):
			draw_line(_to_px(Vector2(0, y)), _to_px(Vector2(w, y)), grid_col, 1.0)
	if not show_routes:
		return
	# Deterministic per-route hue so overlapping routes are distinguishable.
	var n: int = _routes.size()
	for i in range(n):
		var pts: PackedVector2Array = _routes[i]
		if pts.size() < 2:
			continue
		var hue: float = fposmod(float(i) * 0.61803, 1.0)
		var col := Color.from_hsv(hue, 0.7, 1.0, 0.9)
		var px := PackedVector2Array()
		for p in pts:
			px.append(_to_px(p))
		draw_polyline(px, col, 2.0)
		draw_circle(_to_px(pts[0]), 3.0, Color(0.3, 1.0, 0.4))
		draw_circle(_to_px(pts[pts.size() - 1]), 3.0, Color(1.0, 0.4, 0.2))
