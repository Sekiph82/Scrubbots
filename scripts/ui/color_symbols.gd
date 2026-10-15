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
	"C05": "frame", "C06": "tee", "C07": "plus", "C08": "half_disc",
	"C09": "cross", "C10": "heart", "C11": "bolt", "C12": "triangle_down",
	"C13": "hourglass", "C14": "dots", "C15": "arrow", "C16": "chevron",
}

## M50-BOARD: the player's COLOR SYMBOLS setting (AppState settings.effects.color_symbols,
## default ON). One process-wide presentation flag; set_enabled() repaints every live symbol
## surface (tiles, chips, board renderers) through GROUP.
static var enabled := true
const GROUP := "color_symbols"

## Board glyph atlas: 16 tiles in C-ID order (C01 = tile 0), each ATLAS_TILE px square,
## built ONCE from the same _parts() shapes. R = shape coverage, G = halo (shape dilated by
## ATLAS_HALO px) so the board ink reads on light and dark pixels. The shape's unit square
## [-1, 1] spans 2 / ATLAS_SPAN of the tile, leaving an empty margin for the halo and mipmaps.
const ATLAS_TILE := 48
const ATLAS_SPAN := 2.6
const ATLAS_HALO := 3
static var _atlas: ImageTexture = null

var _shape := ""
var _color := Color(0, 0, 0, 0)
var emblem := false

static func cid_for_color(c: Color) -> String:
	return String(CID_BY_HEX.get(c.to_html(false).to_upper(), ""))

static func shape_for_color(c: Color) -> String:
	return String(SHAPE_BY_CID.get(cid_for_color(c), ""))

## 1..16 for a canonical colour (C01 -> 1), 0 for none.
static func cid_index_for_color(c: Color) -> int:
	var cid := cid_for_color(c)
	return 0 if cid.is_empty() else int(cid.substr(1))

## Switch symbols on/off everywhere: tiles, booster chips and every live BoardRenderer.
static func set_enabled(on: bool, tree: SceneTree) -> void:
	enabled = on
	if tree != null:
		tree.call_group(GROUP, "refresh_color_symbols")

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group(GROUP)

func refresh_color_symbols() -> void:
	queue_redraw()

func set_color(c: Color) -> void:
	var s := shape_for_color(c)
	if s != _shape or c != _color:
		_shape = s
		_color = c
		queue_redraw()

static func watermark_ink(face: Color) -> Color:
	return WATERMARK_DARK if face.get_luminance() > LIGHT_FACE_LUMINANCE else WATERMARK_LIGHT

func get_shape() -> String:
	return _shape if visible and enabled else ""

func _draw() -> void:
	if _shape.is_empty() or not enabled:
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

## The shared board glyph atlas (built on first use, then cached for the process).
static func board_atlas() -> ImageTexture:
	if _atlas == null:
		_atlas = ImageTexture.create_from_image(build_atlas_image())
	return _atlas

## 16 * ATLAS_TILE x ATLAS_TILE RG8 image (see ATLAS_* above), mipmapped. Halo polygons come
## from Geometry2D.offset_polygon, so both channels are exact point-in-shape tests.
static func build_atlas_image() -> Image:
	var n := ATLAS_TILE
	var img := Image.create(n * 16, n, false, Image.FORMAT_RG8)
	var halo_unit := float(ATLAS_HALO) * ATLAS_SPAN / float(n)   # halo width in unit space
	for i in range(16):
		var shape := String(SHAPE_BY_CID["C%02d" % (i + 1)])
		var fill := _unit_regions(shape, 0.0)
		var halo := _unit_regions(shape, halo_unit)
		for y in range(n):
			for x in range(n):
				var p := Vector2((x + 0.5) / n - 0.5, (y + 0.5) / n - 0.5) * ATLAS_SPAN
				var r := 1.0 if _in_regions(fill, p) else 0.0
				var g := 1.0 if r > 0.0 or _in_regions(halo, p) else 0.0
				img.set_pixel(i * n + x, y, Color(r, g, 0.0))
	img.generate_mipmaps()
	return img

## Shape parts grown by `grow` (unit space): ["poly", PackedVector2Array] / ["disc", r, centre].
static func _unit_regions(shape: String, grow: float) -> Array:
	var out: Array = []
	for p in _parts(shape):
		if String(p[0]) == "poly":
			var poly := PackedVector2Array(p[1])
			if grow <= 0.0:
				out.append(["poly", poly])
			else:
				for q in Geometry2D.offset_polygon(poly, grow, Geometry2D.JOIN_ROUND):
					out.append(["poly", q])
		else:
			out.append(["disc", float(p[1]) + grow, p[2] if p.size() > 2 else Vector2.ZERO])
	return out

static func _in_regions(regions: Array, p: Vector2) -> bool:
	for r in regions:
		if String(r[0]) == "poly":
			if Geometry2D.is_point_in_polygon(p, r[1]):
				return true
		elif p.distance_to(r[2]) <= float(r[1]):
			return true
	return false

static func _rect(x0: float, y0: float, x1: float, y1: float) -> Array:
	return [Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)]

## Unit-space parts ([-1,1], y down): ["poly", points] / ["disc", radius(, centre)].
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
		"tee":
			return [["poly", _rect(-0.92, -0.92, 0.92, -0.45)], ["poly", _rect(-0.26, -0.5, 0.26, 0.92)]]
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
		"bolt":
			return [["poly", [Vector2(0.45, -0.98), Vector2(-0.88, 0.18), Vector2(-0.12, 0.18), Vector2(-0.45, 0.98), Vector2(0.88, -0.18), Vector2(0.12, -0.18)]]]
		"hourglass":
			return [["poly", [Vector2(-0.8, -0.95), Vector2(0.8, -0.95), Vector2(0, 0.02)]], ["poly", [Vector2(0, -0.02), Vector2(0.8, 0.95), Vector2(-0.8, 0.95)]]]
		"frame":
			return [["poly", _rect(-0.85, -0.85, 0.85, -0.5)], ["poly", _rect(-0.85, 0.5, 0.85, 0.85)],
				["poly", _rect(-0.85, -0.85, -0.5, 0.85)], ["poly", _rect(0.5, -0.85, 0.85, 0.85)]]
		"arrow":
			return [["poly", [Vector2(-0.95, -0.25), Vector2(0.15, -0.25), Vector2(0.15, -0.8), Vector2(0.98, 0), Vector2(0.15, 0.8), Vector2(0.15, 0.25), Vector2(-0.95, 0.25)]]]
		"chevron":
			return [["poly", [Vector2(0, -0.85), Vector2(0.95, 0.15), Vector2(0.95, 0.75), Vector2(0, -0.2), Vector2(-0.95, 0.75), Vector2(-0.95, 0.15)]]]
	return []
