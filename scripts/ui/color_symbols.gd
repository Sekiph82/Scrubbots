extends Control
## ColorSymbols — M50 decision A (owner 2026-10-15): one distinct non-colour shape per canonical
## Palette V3 colour identity. Two styles: WATERMARK (default) - a large translucent silhouette
## behind the count on every occupied ColorBatchTile (Batch Supply front + preview, 5/6 slots)
## and Selector chips, dark ink on light colours / light ink on dark ones; EMBLEM - an opaque
## white shape with a dark outline where no number competes (Tornado colour chips).
## Preload this script (res://scripts/ui/color_symbols.gd); no global class_name (AL-001).
##
## Identity is the CANONICAL C-ID resolved from the exact colour (level palettes are local hex
## lists, so a local color_id index never means the same hue across levels). A colour that is not
## a canonical V3 colour gets no symbol. Presentation only: no input, no gameplay state.
## Shapes are an initial candidate; their appearance still needs owner visual sign-off.

const OUTLINE := Color(0.03, 0.04, 0.09, 1.0)
const FILL := Color(1, 1, 1, 1)
const WATERMARK_LIGHT := Color(1, 1, 1, 0.40)
const WATERMARK_DARK := Color(0.03, 0.04, 0.09, 0.30)
## Faces brighter than this get the dark watermark ink.
const LIGHT_FACE_LUMINANCE := 0.55

## Palette V3 (data/palettes/scrubbots_palette_v3.json); tests assert this table matches it.
const CID_BY_HEX := {
	"FF4500": "C01", "FFA800": "C02", "FFD635": "C03", "00CC78": "C04",
	"00CCC0": "C05", "51E9F4": "C06", "3690EA": "C07", "2450A4": "C08",
	"6A5CFF": "C09", "FF3881": "C10", "9C6926": "C11", "FFF8B8": "C12",
	"D4D7D9": "C13", "515252": "C14", "FFFFFF": "C15", "000000": "C16",
}

## C-ID -> shape id. Every shape has a different silhouette (never fill colour alone).
const SHAPE_BY_CID := {
	"C01": "triangle", "C02": "circle", "C03": "star", "C04": "diamond",
	"C05": "frame", "C06": "ring", "C07": "plus", "C08": "half_disc",
	"C09": "cross", "C10": "heart", "C11": "bars", "C12": "triangle_down",
	"C13": "hourglass", "C14": "dots", "C15": "bullseye", "C16": "chevron",
}

var _shape := ""
var _color := Color(0, 0, 0, 0)
var emblem := false

static func cid_for_color(c: Color) -> String:
	return String(CID_BY_HEX.get(c.to_html(false).to_upper(), ""))

static func shape_for_color(c: Color) -> String:
	return String(SHAPE_BY_CID.get(cid_for_color(c), ""))

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_color(c: Color) -> void:
	var s := shape_for_color(c)
	if s != _shape or c != _color:
		_shape = s
		_color = c
		queue_redraw()

static func watermark_ink(face: Color) -> Color:
	return WATERMARK_DARK if face.get_luminance() > LIGHT_FACE_LUMINANCE else WATERMARK_LIGHT

func get_shape() -> String:
	return _shape if visible else ""

func _draw() -> void:
	if _shape.is_empty():
		return
	var r := minf(size.x, size.y) * 0.5
	var c := size * 0.5
	var o := maxf(r * 0.16, 1.5)   # outline thickness
	var parts := _parts(_shape)
	if not emblem:
		_draw_parts(parts, c, r, watermark_ink(_color), 0.0)
		return
	# Outline: the same parts in the dark outline colour, offset in 8 directions.
	for d in [Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1), Vector2(-1, 0), Vector2(1, 0), Vector2(-1, 1), Vector2(0, 1), Vector2(1, 1)]:
		_draw_parts(parts, c + d * o, r - o, OUTLINE, o)
	_draw_parts(parts, c, r - o, FILL, 0.0)

func _draw_parts(parts: Array, c: Vector2, r: float, col: Color, grow: float) -> void:
	for p in parts:
		match String(p[0]):
			"poly":
				var pts := PackedVector2Array()
				for v in p[1]:
					pts.append(c + v * r)
				draw_colored_polygon(pts, col)
			"disc":
				draw_circle(c + (p[2] as Vector2) * r if p.size() > 2 else c, float(p[1]) * r, col)
			"ring":
				draw_arc(c, float(p[1]) * r, 0.0, TAU, 32, col, float(p[2]) * r + grow, true)

static func _rect(x0: float, y0: float, x1: float, y1: float) -> Array:
	return [Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)]

## Unit-space parts ([-1,1], y down): ["poly", points] / ["disc", radius(, centre)] / ["ring", radius, width].
static func _parts(shape: String) -> Array:
	match shape:
		"triangle":
			return [["poly", [Vector2(0, -0.95), Vector2(0.95, 0.8), Vector2(-0.95, 0.8)]]]
		"triangle_down":
			return [["poly", [Vector2(-0.95, -0.8), Vector2(0.95, -0.8), Vector2(0, 0.95)]]]
		"circle":
			return [["disc", 0.85]]
		"star":
			var pts: Array = []
			for i in range(10):
				var a := -PI / 2 + PI * i / 5
				pts.append(Vector2(cos(a), sin(a)) * (1.0 if i % 2 == 0 else 0.36))
			return [["poly", pts]]
		"diamond":
			return [["poly", [Vector2(0, -1), Vector2(0.75, 0), Vector2(0, 1), Vector2(-0.75, 0)]]]
		"ring":
			return [["ring", 0.68, 0.32]]
		"plus":
			return [["poly", [Vector2(-0.28, -0.95), Vector2(0.28, -0.95), Vector2(0.28, -0.28), Vector2(0.95, -0.28), Vector2(0.95, 0.28), Vector2(0.28, 0.28),
				Vector2(0.28, 0.95), Vector2(-0.28, 0.95), Vector2(-0.28, 0.28), Vector2(-0.95, 0.28), Vector2(-0.95, -0.28), Vector2(-0.28, -0.28)]]]
		"cross":
			var pts: Array = []
			for v in _parts("plus")[0][1]:
				pts.append((v as Vector2).rotated(PI / 4))
			return [["poly", pts]]
		"half_disc":
			var pts: Array = []
			for i in range(13):
				pts.append(Vector2(0.45, 0) + Vector2(cos(PI / 2 + PI * i / 12), sin(PI / 2 + PI * i / 12)) * 0.95)
			return [["poly", pts]]
		"dots":
			return [["disc", 0.33, Vector2(0, -0.52)], ["disc", 0.33, Vector2(-0.55, 0.45)], ["disc", 0.33, Vector2(0.55, 0.45)]]
		"heart":
			var pts: Array = []
			for i in range(28):
				var t := TAU * i / 28
				pts.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))) / 17.0 + Vector2(0, -0.1))
			return [["poly", pts]]
		"bars":
			return [["poly", _rect(-0.9, -0.85, 0.9, -0.43)], ["poly", _rect(-0.9, -0.21, 0.9, 0.21)], ["poly", _rect(-0.9, 0.43, 0.9, 0.85)]]
		"hourglass":
			return [["poly", [Vector2(-0.8, -0.95), Vector2(0.8, -0.95), Vector2(0, 0.02)]], ["poly", [Vector2(0, -0.02), Vector2(0.8, 0.95), Vector2(-0.8, 0.95)]]]
		"frame":
			return [["poly", _rect(-0.85, -0.85, 0.85, -0.5)], ["poly", _rect(-0.85, 0.5, 0.85, 0.85)],
				["poly", _rect(-0.85, -0.85, -0.5, 0.85)], ["poly", _rect(0.5, -0.85, 0.85, 0.85)]]
		"bullseye":
			return [["ring", 0.72, 0.26], ["disc", 0.28]]
		"chevron":
			return [["poly", [Vector2(0, -0.85), Vector2(0.95, 0.15), Vector2(0.95, 0.75), Vector2(0, -0.2), Vector2(-0.95, 0.75), Vector2(-0.95, 0.15)]]]
	return []
