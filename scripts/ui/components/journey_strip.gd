extends Control
## JourneyStrip — preload (res://scripts/ui/components/journey_strip.gd).
##
## M43-C001R (SB-M43-R01-005..007) — the one presentation of a ResultsMomentum journey
## model, used by Results and Home. Ten nodes drawn natively on ONE Control (no child per
## node, no Button): it ignores the mouse, takes no focus and has no action, so a node can
## never skip, rewind, unlock or navigate. Information only.
##
## States: complete (green + check) / current (gold, larger) / next (white ring) / future
## (dim). Beats: slot 5 mini-boss = diamond with an orange rim; slot 10 cycle boss = diamond
## with a crimson rim. V02 owner decision: size hierarchy ordinary < mini-boss < boss
## (BEAT_SCALE), the base radius fitted so the boss always fits the strip height. Beats
## never imply a reward.

const HomeStyle = preload("res://scripts/ui/home/home_style.gd")

const NAVY := Color(0.043, 0.114, 0.259, 0.92)
const FUTURE := Color(0.20, 0.27, 0.42)
const MINI_EDGE := Color(1.0, 0.55, 0.12)
const BOSS_EDGE := Color(0.86, 0.13, 0.20)
const LINE := Color(0.62, 0.894, 1.0, 0.55)
## Node size by beat (V02): ordinary 1.0 < mini-boss < boss. A current ordinary node gets a
## smaller lift so it never outranks a beat.
const BEAT_SCALE := {"normal": 1.0, "mini_boss": 1.3, "boss": 1.6}
const CURRENT_SCALE := 1.12
const RIM := 3.0

var _model: Dictionary = {}
var font_size := 22
## Home draws a translucent navy plate behind the nodes for legibility over world art.
var backplate := false

func _init() -> void:
	name = "JourneyStrip"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(520, 64)

func set_model(m: Dictionary) -> void:
	_model = m.duplicate(true)
	visible = bool(_model.get("ok", false))
	queue_redraw()

func get_model() -> Dictionary:
	return _model.duplicate(true)

func node_count() -> int:
	return (_model.get("nodes", []) as Array).size()

## Local rect of each drawn node, in slot order (tests / layout evidence).
func node_rects() -> Array:
	var out: Array = []
	var n := node_count()
	if n == 0:
		return out
	var r := _radius()
	# Centres are inset by the largest (boss) half-width so the end nodes stay inside.
	var margin: float = r * float(BEAT_SCALE["boss"]) + RIM
	var step: float = (size.x - 2.0 * margin) / maxf(n - 1, 1)
	for i in range(n):
		var nd: Dictionary = _model["nodes"][i]
		var rr: float = r * _scale(nd)
		var c := Vector2(margin + step * i, size.y * 0.5)
		out.append(Rect2(c - Vector2(rr, rr), Vector2(rr, rr) * 2.0))
	return out

## Base (ordinary) radius, the largest that keeps (a) the boss inside the strip height and
## (b) every node inside the width with no neighbour overlap: with centres inset by the boss
## half-width, the tightest neighbours are the boss and a current node.
func _radius() -> float:
	var n := maxi(node_count(), 2)
	var boss: float = BEAT_SCALE["boss"]
	var by_height: float = (size.y * 0.5 - RIM - 1.0) / boss
	var by_width: float = (size.x - 2.0 * RIM * n) / (2.0 * boss + (n - 1) * (boss + CURRENT_SCALE))
	return maxf(minf(by_height, by_width), 4.0)

static func _scale(nd: Dictionary) -> float:
	var s: float = BEAT_SCALE.get(String(nd["beat"]), 1.0)
	if String(nd["state"]) == "current" and s < CURRENT_SCALE:
		s = CURRENT_SCALE
	return s

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var n := node_count()
	if n == 0:
		return
	var rects := node_rects()
	if backplate:
		var plate := StyleBoxFlat.new()
		plate.bg_color = Color(0.02, 0.06, 0.16, 0.62)
		plate.set_corner_radius_all(int(size.y * 0.5))
		draw_style_box(plate, Rect2(Vector2.ZERO, size))
	draw_line(rects[0].get_center(), rects[n - 1].get_center(), LINE, 4.0)
	var font: Font = get_theme_default_font()
	for i in range(n):
		var nd: Dictionary = _model["nodes"][i]
		var rc: Rect2 = rects[i]
		var c := rc.get_center()
		var rr := rc.size.x * 0.5
		var state := String(nd["state"])
		var fill := FUTURE
		match state:
			"complete": fill = HomeStyle.GREEN
			"current": fill = HomeStyle.GOLD
			"next": fill = Color(0.96, 0.97, 1.0)
		var edge := LINE
		if nd["beat"] == "mini_boss":
			edge = MINI_EDGE
		elif nd["beat"] == "boss":
			edge = BOSS_EDGE
		elif state == "current" or state == "next":
			edge = Color(1, 1, 1)
		if nd["beat"] == "normal":
			draw_circle(c, rr + 3.0, NAVY)
			draw_circle(c, rr, fill)
			draw_arc(c, rr, 0, TAU, 32, edge, 3.0, true)
		else:
			var d := PackedVector2Array([c + Vector2(0, -rr - 3), c + Vector2(rr + 3, 0), c + Vector2(0, rr + 3), c + Vector2(-rr - 3, 0)])
			draw_colored_polygon(d, edge)
			var inner := rr - 2.0
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -inner), c + Vector2(inner, 0), c + Vector2(0, inner), c + Vector2(-inner, 0)]), fill)
		if state == "complete":
			var k := rr * 0.5
			draw_polyline(PackedVector2Array([c + Vector2(-k, 0), c + Vector2(-k * 0.25, k * 0.7), c + Vector2(k, -k * 0.6)]), Color(1, 1, 1), 4.0, true)
		elif font != null:
			var txt := str(int(nd["level"]))
			var fs := clampi(int(rr * 0.9), 14, font_size + 8) if txt.length() <= 2 else clampi(int(rr * 0.75), 12, font_size + 4)
			var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			var ink := HomeStyle.OUTLINE if state in ["current", "next"] else Color(0.85, 0.90, 1.0)
			draw_string(font, c + Vector2(-ts.x * 0.5, ts.y * 0.32), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ink)
