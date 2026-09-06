extends Control
## Debug-only grid overlay for the BoardRenderer manual-QA tool. Draws thin
## lines on square cell boundaries so the flat board keeps visible per-cell
## separation, WITHOUT one Node per cell: this is a single Control whose
## `_draw()` issues `cols + rows + 2` batched `draw_line()` calls. It never
## fills cells (that stays the BoardRenderer's flat texture) — it only outlines
## the square grid. Presentation-only; not production UI.

var _cell_size: float = 0.0
var _cols: int = 0
var _rows: int = 0
var _line_color: Color = Color(0, 0, 0, 0.30)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(cell_size: float, cols: int, rows: int, line_color: Color) -> void:
	_cell_size = cell_size
	_cols = cols
	_rows = rows
	_line_color = line_color
	queue_redraw()

func _draw() -> void:
	if _cell_size <= 0.0 or _cols <= 0 or _rows <= 0:
		return
	var w: float = _cols * _cell_size
	var h: float = _rows * _cell_size
	for c in _cols + 1:
		var x: float = c * _cell_size
		draw_line(Vector2(x, 0), Vector2(x, h), _line_color, 1.0)
	for r in _rows + 1:
		var y: float = r * _cell_size
		draw_line(Vector2(0, y), Vector2(w, y), _line_color, 1.0)
