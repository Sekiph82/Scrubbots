extends Control
## BoosterVfx — preload (res://scripts/ui/feel/booster_vfx.gd).
##
## SB-POLISH-003 (owner playtest 2026-10-31): the short activation effect of each booster,
##   tornado       — a swirling vortex; the purged colour's board cells (one ghost ImageTexture)
##                   and its supply / slot tiles spiral into it, then a burst at the centre;
##   plus_one_slot — glow + burst pop + sparkles on the new sixth slot (the screen crossfades
##                   the 5-slot master into the 6-slot master and fades the new slot in);
##   random        — dice-pip colour flicker over every visible supply tile, then sparkles;
##   selector      — a reticle locks onto the picked batch, flashes, and the tile flies into
##                   its slot (the real slot tile fades in as it lands).
## ONE Control draws everything (plus one ghost TextureRect for Tornado): never a Node per
## board cell. Presentation only: GameplayScreen feeds detached global rects / colours AFTER the
## action committed; nothing here reads or writes gameplay truth, and input passes through
## (mouse_filter IGNORE). Each effect is <= 0.85 s; Reduced Effects -> no effect at all.
## SB-POLISH-012 (owner 2026-10-31): every slot batch that finishes (slot empties) gets a short
## lift + pop + star burst (pop_batch). Pops are plain dict entries drawn here (no nodes made, so
## nothing to pool or leak) and run alongside a booster effect. SB-PHONE-2026-11-12-F: the host
## holds the finished slot against new picks for pop_duration() (FiveSlotBatchEngine finish hold).
## SB-POLISH-013 (owner 2026-11-03): the pop is slower and higher, in three strictly ordered
## phases: LIFT (the batch tile rises, ease-in-out, until its bottom edge is POP_GAP x slot
## height above the former slot top), BURST (the tile explodes into the burst art), STARS (eight
## stars travel outward, ease-in-out). Timings are one preset of POP_PRESETS (owner picks A/B/C).

const BURST_ART := "res://assets/ui/final/boosters/states/booster_activated_burst.png"
const GLOW_ART := "res://assets/ui/final/boosters/states/booster_reward_glow.png"
const DURATION := {"tornado": 0.85, "plus_one_slot": 0.7, "random": 0.6, "selector": 0.8}
const SPARKLE := Color(1.0, 0.97, 0.78)
const VORTEX := Color(0.78, 0.93, 1.0)
const RETICLE := Color(1.0, 0.36, 0.3)
## Seconds per phase; total = lift + burst + stars.
const POP_PRESETS := {
	"A": {"lift": 0.38, "burst": 0.20, "stars": 0.37},   # 0.95 s
	"B": {"lift": 0.50, "burst": 0.25, "stars": 0.50},   # 1.25 s
	"C": {"lift": 0.64, "burst": 0.32, "stars": 0.64},   # 1.60 s
}
const POP_DEFAULT := "C"   # owner picked C (1.60 s) 2026-11-06
const POP_GAP := 0.25      # clear gap under the lifted tile, x slot height
const POP_MAX := 6         # live pops bounded: one per slot; the oldest gives way

var _kind := ""
var _t := 0.0
var _d: Dictionary = {}
var _burst: Texture2D
var _glow: Texture2D
var _ghost: TextureRect
var _pops: Array = []             # live batch-complete pops: {rect (global), color, t}
var _tile := StyleBoxFlat.new()   # rounded batch-tile silhouette (one reused style)
var _pop_timing: Dictionary = POP_PRESETS[POP_DEFAULT]

func _init() -> void:
	name = "BoosterVfx"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_burst = load(BURST_ART) as Texture2D
	_glow = load(GLOW_ART) as Texture2D
	_tile.set_corner_radius_all(10)
	_tile.anti_aliasing = true
	_ghost = TextureRect.new()
	_ghost.name = "TornadoGhost"
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp logical pixels
	_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ghost.stretch_mode = TextureRect.STRETCH_SCALE
	_ghost.show_behind_parent = true   # under the vortex arms
	_ghost.visible = false
	add_child(_ghost)

## Start effect `kind` with its data (global coordinates). A running effect is finished first.
func play(kind: String, data: Dictionary) -> void:
	stop()
	if not DURATION.has(kind):
		return
	_kind = kind
	_d = data
	_t = 0.0
	if data.get("fade_in") is CanvasItem:
		data["fade_in"].modulate.a = 0.0
	if kind == "tornado" and data.get("ghost") is Image:
		var br: Rect2 = data["board_rect"]
		_ghost.texture = ImageTexture.create_from_image(data["ghost"])
		_ghost.position = br.position - global_position
		_ghost.size = br.size
		_ghost.pivot_offset = data["center"] - br.position
		_ghost.rotation = 0.0
		_ghost.scale = Vector2.ONE
		_ghost.modulate = Color.WHITE
		_ghost.visible = true
	set_process(true)
	queue_redraw()

func stop() -> void:
	if _kind == "":
		return
	var view = _d.get("fade_in")
	if is_instance_valid(view) and view is CanvasItem:
		view.modulate.a = 1.0
	_kind = ""
	_d = {}
	_ghost.visible = false
	_ghost.texture = null
	set_process(not _pops.is_empty())
	queue_redraw()

## SB-POLISH-012: the batch that just left the slot at `rect` lifts, pops and sheds stars.
func pop_batch(rect: Rect2, col: Color) -> void:
	if _pops.size() >= POP_MAX:
		_pops.pop_front()
	_pops.append({"rect": rect, "color": col, "t": 0.0})
	set_process(true)
	queue_redraw()

func pop_count() -> int:
	return _pops.size()

func clear_pops() -> void:
	_pops.clear()
	set_process(_kind != "")
	queue_redraw()

## SB-POLISH-013: pick timing preset "A" / "B" / "C". Returns false for an unknown id.
func set_pop_preset(id: String) -> bool:
	if not POP_PRESETS.has(id):
		return false
	_pop_timing = POP_PRESETS[id]
	return true

func pop_duration() -> float:
	return float(_pop_timing["lift"]) + float(_pop_timing["burst"]) + float(_pop_timing["stars"])

## Pop state `t` s after a batch left the slot at `r` (pure; drawing and tests share it):
## phase LIFT/BURST/STARS/DONE, the tile rect, and burst / star progress 0..1.
func pop_frame(r: Rect2, t: float) -> Dictionary:
	var lift_s: float = float(_pop_timing["lift"])
	var burst_s: float = float(_pop_timing["burst"])
	var lu: float = _ease_in_out(clampf(t / lift_s, 0.0, 1.0))
	var bu: float = clampf((t - lift_s) / burst_s, 0.0, 1.0)
	var su: float = _ease_in_out(clampf((t - lift_s - burst_s) / float(_pop_timing["stars"]), 0.0, 1.0))
	var phase := "LIFT"
	if t >= pop_duration():
		phase = "DONE"
	elif t >= lift_s + burst_s:
		phase = "STARS"
	elif t >= lift_s:
		phase = "BURST"
	var rise: float = r.size.y * (1.0 + POP_GAP) * lu
	return {"phase": phase, "tile": Rect2(r.position - Vector2(0, rise), r.size), "burst": bu, "stars": su}

func is_playing() -> bool:
	return _kind != ""

func get_kind() -> String:
	return _kind

func _ready() -> void:
	set_process(is_playing() or not _pops.is_empty())   # Godot enables _process on ready

func _process(delta: float) -> void:
	for p in _pops:
		p["t"] += delta
	var total := pop_duration()
	_pops = _pops.filter(func(p): return p["t"] < total)
	if _kind == "":
		set_process(not _pops.is_empty())
		queue_redraw()
		return
	_t += delta
	if _t >= float(DURATION[_kind]):
		stop()
		return
	var view = _d.get("fade_in")
	if is_instance_valid(view) and view is CanvasItem:
		var start: float = float(_d.get("fade_from", 0.0))
		view.modulate.a = clampf((_t - start) / 0.15, 0.0, 1.0)
	if _kind == "tornado" and _ghost.visible:
		var u: float = _ease_in(clampf((_t - 0.08) / 0.62, 0.0, 1.0))
		_ghost.rotation = -TAU * 0.9 * u
		_ghost.scale = Vector2.ONE * (1.0 - u)
		_ghost.modulate.a = 1.0 - u * u
	queue_redraw()

func _draw() -> void:
	if _kind == "" and _pops.is_empty():
		return
	draw_set_transform_matrix(get_global_transform().affine_inverse())
	for p in _pops:
		_draw_pop(p)
	match _kind:
		"tornado":
			_draw_tornado()
		"plus_one_slot":
			_draw_plus_one()
		"random":
			_draw_random()
		"selector":
			_draw_selector()

# ------------------------------------------------------------------ effects --

func _draw_tornado() -> void:
	var c: Vector2 = _d["center"]
	var radius: float = float(_d["radius"])
	var a: float = clampf(_t / 0.15, 0.0, 1.0) * clampf((0.85 - _t) / 0.15, 0.0, 1.0)
	var spin: float = -_t * 9.0
	var shrink: float = 1.0 - 0.75 * _ease_in(clampf((_t - 0.55) / 0.3, 0.0, 1.0))
	# Three spiral arms + two dashed rings, all rotating inward.
	for arm in range(3):
		var pts := PackedVector2Array()
		for i in range(25):
			var f: float = float(i) / 24.0
			var ang: float = spin + arm * TAU / 3.0 + f * TAU * 1.1
			pts.append(c + Vector2.from_angle(ang) * radius * shrink * (1.0 - f * 0.92))
		draw_polyline(pts, Color(VORTEX, 0.55 * a), maxf(radius * 0.035, 2.0), true)
	for k in range(2):
		var rr: float = radius * shrink * (0.45 + 0.4 * k)
		for s in range(6):
			var st: float = spin * (1.4 - 0.5 * k) + s * TAU / 6.0
			draw_arc(c, rr, st, st + TAU / 10.0, 8, Color(1, 1, 1, 0.45 * a), maxf(radius * 0.02, 1.5), true)
	# The colour's supply / slot tiles and sampled board cells spiral into the eye.
	for tile in _d["tiles"]:
		_spiral_rect(c, tile["rect"], tile["color"], clampf((_t - 0.05) / 0.6, 0.0, 1.0), 2.4)
	var cell: float = float(_d["cell"])
	for p in _d["samples"]:
		var u: float = clampf((_t - float(p["delay"])) / 0.55, 0.0, 1.0)
		_spiral_rect(c, Rect2(p["pos"] - Vector2.ONE * cell * 0.5, Vector2.ONE * cell), p["color"], u, 3.2)
	# Collapse: burst at the eye.
	var bu: float = clampf((_t - 0.6) / 0.25, 0.0, 1.0)
	if bu > 0.0 and _burst != null:
		var sz: float = radius * (0.5 + 0.9 * bu)
		draw_texture_rect(_burst, Rect2(c - Vector2.ONE * sz * 0.5, Vector2.ONE * sz), false, Color(1, 1, 1, 1.0 - bu))

func _draw_plus_one() -> void:
	var r: Rect2 = _d["slot_rect"]
	var c: Vector2 = r.get_center()
	var s: float = maxf(r.size.x, r.size.y)
	var gu: float = clampf(_t / 0.6, 0.0, 1.0)
	if _glow != null:
		var gs: float = s * (0.8 + 1.0 * _ease_out(gu))
		draw_texture_rect(_glow, Rect2(c - Vector2.ONE * gs * 0.5, Vector2.ONE * gs), false, Color(1, 1, 1, 1.0 - gu))
	var bu: float = clampf(_t / 0.45, 0.0, 1.0)
	if _burst != null and bu < 1.0:
		var bs: float = s * (0.5 + 1.1 * _ease_out(bu))
		draw_texture_rect(_burst, Rect2(c - Vector2.ONE * bs * 0.5, Vector2.ONE * bs), false, Color(1, 1, 1, 1.0 - bu))
	draw_arc(c, s * (0.4 + 0.6 * _ease_out(gu)), 0.0, TAU, 32, Color(SPARKLE, 0.8 * (1.0 - gu)), maxf(s * 0.05, 2.0), true)
	var su: float = clampf((_t - 0.08) / 0.6, 0.0, 1.0)
	for i in range(8):
		var dir := Vector2.from_angle(i * TAU / 8.0 + 0.3)
		_sparkle(c + dir * s * (0.35 + 0.65 * _ease_out(su)), s * 0.16 * (1.0 - su), Color(SPARKLE, 1.0 - su * su))

func _draw_random() -> void:
	var tiles: Array = _d["tiles"]
	var cols: Array = _d["colors"]
	var flick: float = clampf(_t / 0.42, 0.0, 1.0)
	var frame := int(_t / 0.06)
	for i in range(tiles.size()):
		var r: Rect2 = tiles[i]["rect"]
		if flick < 1.0:
			var col: Color = cols[(i * 7 + frame * 3) % cols.size()] if not cols.is_empty() else Color.WHITE
			_draw_tile(r.grow(-r.size.x * 0.06), Color(col, 0.92 * (1.0 - flick * flick)))
			_pips(r, 1 + (i + frame) % 6, Color(1, 1, 1, 1.0 - flick))
		var su: float = clampf((_t - 0.3 - 0.015 * i) / 0.28, 0.0, 1.0)
		if su > 0.0 and su < 1.0:
			_sparkle(r.position + r.size * Vector2(0.85, 0.15), r.size.x * 0.28 * sin(su * PI), Color(SPARKLE, 1.0 - su))

func _draw_selector() -> void:
	var src: Rect2 = _d["src_rect"]
	var dst: Rect2 = _d["dst_rect"]
	var col: Color = _d["color"]
	var mu: float = _ease_in_out(clampf((_t - 0.32) / 0.33, 0.0, 1.0))
	var pos: Vector2 = src.get_center().lerp(dst.get_center(), mu) + Vector2(0, -src.size.y * 1.2 * sin(mu * PI))
	var sz: Vector2 = src.size.lerp(dst.size, mu)
	# Lock-on: the reticle closes in and turns 90 degrees, then rides the tile.
	var lu: float = _ease_out(clampf(_t / 0.28, 0.0, 1.0))
	var ra: float = 1.0 - clampf((_t - 0.6) / 0.15, 0.0, 1.0)
	var rad: float = maxf(sz.x, sz.y) * (1.6 - 0.9 * lu)
	if mu > 0.0:   # trail while flying; the tile itself is drawn from the lock-on onward
		for k in range(1, 4):
			var tp: float = maxf(mu - 0.09 * k, 0.0)
			var tpos: Vector2 = src.get_center().lerp(dst.get_center(), tp) + Vector2(0, -src.size.y * 1.2 * sin(tp * PI))
			_draw_tile(Rect2(tpos - sz * 0.4, sz * 0.8), Color(col, 0.35 / k))
	_draw_tile(Rect2(pos - sz * 0.5, sz), col)
	if ra > 0.0:
		var rot: float = PI * 0.5 * lu
		draw_arc(pos, rad, 0.0, TAU, 40, Color(RETICLE, ra), maxf(rad * 0.08, 2.0), true)
		for q in range(4):
			var dir := Vector2.from_angle(rot + q * PI * 0.5)
			draw_line(pos + dir * rad * 0.55, pos + dir * rad * 1.3, Color(RETICLE, ra), maxf(rad * 0.08, 2.0), true)
	var fu: float = clampf((_t - 0.26) / 0.14, 0.0, 1.0)
	if fu > 0.0 and fu < 1.0:
		_draw_tile(src.grow(src.size.x * 0.1 * fu), Color(1, 1, 1, 0.9 * (1.0 - fu)))
	var bu: float = clampf((_t - 0.62) / 0.18, 0.0, 1.0)
	if bu > 0.0 and bu < 1.0 and _burst != null:
		var bs: float = maxf(dst.size.x, dst.size.y) * (0.8 + 0.8 * bu)
		draw_texture_rect(_burst, Rect2(dst.get_center() - Vector2.ONE * bs * 0.5, Vector2.ONE * bs), false, Color(1, 1, 1, 1.0 - bu))

## SB-POLISH-013: LIFT the tile clear of the slot, BURST it, then the STARS fly out.
func _draw_pop(p: Dictionary) -> void:
	var f: Dictionary = pop_frame(p["rect"], float(p["t"]))
	var r: Rect2 = f["tile"]
	var c: Vector2 = r.get_center()
	var s: float = maxf(r.size.x, r.size.y)
	var bu: float = f["burst"]
	if bu < 1.0:   # the tile, swelling and fading as it explodes (never darker than its colour)
		var sz: Vector2 = r.size * (1.0 + 0.35 * _ease_out(bu))
		_draw_tile(Rect2(c - sz * 0.5, sz), Color(p["color"], 1.0 - bu))
	if bu > 0.0 and _burst != null:
		var bs: float = s * (0.6 + 0.9 * _ease_out(bu))
		var ba: float = 1.0 - float(f["stars"])
		draw_texture_rect(_burst, Rect2(c - Vector2.ONE * bs * 0.5, Vector2.ONE * bs), false, Color(1, 1, 1, ba))
	if f["phase"] == "STARS":
		var su: float = f["stars"]
		for i in range(8):
			var dir := Vector2.from_angle(i * TAU / 8.0 + 0.4)
			_sparkle(c + dir * s * (0.35 + 0.9 * su), s * 0.16 * (1.0 - 0.6 * su), Color(SPARKLE, 1.0 - su * su))

# ------------------------------------------------------------------ helpers --

## A rect of colour `col` pulled along a tightening spiral into `c` (u = 0..1 progress).
func _spiral_rect(c: Vector2, r: Rect2, col: Color, u: float, turns: float) -> void:
	if u >= 1.0:
		return
	var off: Vector2 = r.get_center() - c
	var e: float = _ease_in(u)
	var p: Vector2 = c + off.rotated(-turns * e) * (1.0 - e)
	var sz: Vector2 = r.size * (1.0 - 0.8 * e)
	_draw_tile(Rect2(p - sz * 0.5, sz), Color(col, 1.0 - e * e))

## Rounded tile of colour `col` (corner radius follows the tile size).
func _draw_tile(r: Rect2, col: Color) -> void:
	if r.size.x < 12.0:
		draw_rect(r, col)
		return
	_tile.bg_color = col
	_tile.set_corner_radius_all(int(r.size.x * 0.16))
	draw_style_box(_tile, r)

## Four-point star.
func _sparkle(p: Vector2, s: float, col: Color) -> void:
	if s <= 0.5:
		return
	var w: float = s * 0.22
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -s), p + Vector2(w, 0), p + Vector2(0, s), p + Vector2(-w, 0)]), col)
	draw_colored_polygon(PackedVector2Array([p + Vector2(-s, 0), p + Vector2(0, -w), p + Vector2(s, 0), p + Vector2(0, w)]), col)

## Dice face with `n` pips (1..6) centred in `r`.
func _pips(r: Rect2, n: int, col: Color) -> void:
	const LAYOUT := {1: [[0, 0]], 2: [[-1, -1], [1, 1]], 3: [[-1, -1], [0, 0], [1, 1]],
		4: [[-1, -1], [1, -1], [-1, 1], [1, 1]], 5: [[-1, -1], [1, -1], [0, 0], [-1, 1], [1, 1]],
		6: [[-1, -1], [1, -1], [-1, 0], [1, 0], [-1, 1], [1, 1]]}
	var s: float = minf(r.size.x, r.size.y)
	for q in LAYOUT[n]:
		draw_circle(r.get_center() + Vector2(q[0], q[1]) * s * 0.24, s * 0.075, col)

func _ease_in(u: float) -> float:
	return u * u

func _ease_out(u: float) -> float:
	return 1.0 - (1.0 - u) * (1.0 - u)

func _ease_in_out(u: float) -> float:
	return u * u * (3.0 - 2.0 * u)
