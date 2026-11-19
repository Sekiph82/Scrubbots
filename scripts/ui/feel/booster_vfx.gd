extends Control
## BoosterVfx — preload (res://scripts/ui/feel/booster_vfx.gd).
##
## SB-POLISH-003 (owner playtest 2026-10-31): the short activation effect of each booster,
##   tornado       — SB-TF-06: the owner's tornado video (additive, one VideoStreamPlayer) grows
##                   from the Tornado button to the board centre; the purged colour's board cells
##                   (one ghost ImageTexture) and its supply / slot tiles spiral into the moving
##                   tornado; then the layer spin-collapses and a burst pops at the board centre;
##   plus_one_slot — glow + burst pop + sparkles on the new sixth slot (the screen crossfades
##                   the 5-slot master into the 6-slot master and fades the new slot in);
##   random        — dice-pip colour flicker over every visible supply tile, then sparkles;
##   selector      — a reticle locks onto the picked batch, flashes, and the tile flies into
##                   its slot (the real slot tile fades in as it lands).
## ONE Control draws everything (plus one ghost TextureRect and, while Tornado plays, its one
## VideoStreamPlayer): never a Node per board cell. Presentation only: GameplayScreen feeds
## detached global rects / colours AFTER the action committed; nothing here reads or writes
## gameplay truth, and input passes through (mouse_filter IGNORE). Each effect is <= 0.85 s
## (Tornado: clip + 0.5 s); Reduced Effects -> no effect at all.
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
## Tornado: nominal clip + collapse + burst; play() uses the opened clip's real length.
const DURATION := {"tornado": 1.833, "plus_one_slot": 0.7, "random": 0.6, "selector": 0.8}
const SPARKLE := Color(1.0, 0.97, 0.78)
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
## SB-TF-06: the Tornado clip (assets/ui/final/boosters/videos/PROVENANCE.md, built by
## tools/build_tornado_booster_video.py): 544x1008, 32 frames at 24 fps, black background.
const TORNADO_VIDEO := "res://assets/ui/final/boosters/videos/tornado_additive.ogv"
const TORNADO_SIZE := Vector2(544, 1008)
const TORNADO_FPS := 24.0
const TORNADO_CLIP_S := 32.0 / 24.0   # also the code-only duration when the clip cannot play
const COLLAPSE_S := 0.25
const BURST_S := 0.25
const STRETCH_MAX := 1.25             # max(sx, sy) / min(sx, sy) of the video layer
const PULL_FROM := 0.6                # clip fraction at which the cells start into the tornado
const PULL_TURNS := 0.75              # turns the ghost swirls around the tornado while converging
## Measured tornado per clip frame: [frame, centre x, centre y, diameter] in clip pixels (bbox
## of pixels brighter than 40/255). Key 0 = at the button, last key = end of travel.
const TORNADO_TRACK := [
	[0, 397.5, 957.0, 83.0],
	[2, 397.5, 956.0, 81.0],
	[5, 399.5, 954.5, 87.0],
	[7, 400.0, 942.0, 104.0],
	[10, 387.5, 896.5, 153.0],
	[12, 375.5, 845.5, 195.0],
	[14, 361.0, 784.5, 236.0],
	[17, 339.0, 677.5, 296.0],
	[19, 324.5, 597.5, 339.0],
	[21, 312.5, 520.0, 381.0],
	[24, 293.5, 400.5, 431.0],
	[26, 287.0, 331.5, 456.0],
	[29, 277.0, 249.0, 484.0],
	[31, 272.5, 217.0, 493.0],
]

## Injectable for tests (null / broken = the code-only effect, as on failure).
static var tornado_video: VideoStream = load(TORNADO_VIDEO)

var _kind := ""
var _t := 0.0
var _d: Dictionary = {}
var _burst: Texture2D
var _glow: Texture2D
var _ghost: TextureRect
var _pops: Array = []             # live batch-complete pops: {rect (global), color, t}
var _tile := StyleBoxFlat.new()   # rounded batch-tile silhouette (one reused style)
var _pop_timing: Dictionary = POP_PRESETS[POP_DEFAULT]
var _dur := 0.0                   # running effect's length (Tornado: clip + collapse + burst)
var _video: VideoStreamPlayer     # Tornado only; freed at the burst / stop()
var _clip := 0.0                  # Tornado clip seconds
var _map := {}                    # Tornado layer: scale (Vector2), base (local), drift (x px)

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
	_ghost.show_behind_parent = true   # under the spiral tiles and the video
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
	_dur = float(DURATION[kind])
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
	if kind == "tornado":
		_start_video()
		_dur = _clip + COLLAPSE_S + BURST_S
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
	_free_video()
	_ghost.visible = false
	_ghost.texture = null
	set_process(not _pops.is_empty())
	queue_redraw()

## SB-POLISH-012: the batch that just left the slot at `rect` lifts, pops and sheds stars.
## `slot` tags the pop so the slot's finish hold can follow it (is_slot_popping).
func pop_batch(rect: Rect2, col: Color, slot: int = -1) -> void:
	if _pops.size() >= POP_MAX:
		_pops.pop_front()
	_pops.append({"rect": rect, "color": col, "t": 0.0, "slot": slot})
	set_process(true)
	queue_redraw()

func pop_count() -> int:
	return _pops.size()

## SB-TF-02: true while the finish pop of slot `slot` is still on the overlay.
func is_slot_popping(slot: int) -> bool:
	for p in _pops:
		if int(p["slot"]) == slot:
			return true
	return false

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
	if _t >= _dur:
		stop()
		return
	var view = _d.get("fade_in")
	if is_instance_valid(view) and view is CanvasItem:
		var start: float = float(_d.get("fade_from", 0.0))
		view.modulate.a = clampf((_t - start) / 0.15, 0.0, 1.0)
	if _kind == "tornado":
		_tick_tornado()
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
	var c: Vector2 = tornado_pos()
	var s: float = _pull() * 0.85   # the SB-POLISH-003 0.85 s timeline over the pull window
	# The colour's supply / slot tiles and sampled board cells spiral into the moving tornado.
	for tile in _d["tiles"]:
		_spiral_rect(c, tile["rect"], tile["color"], clampf((s - 0.05) / 0.6, 0.0, 1.0), 2.4)
	var cell: float = float(_d["cell"])
	for p in _d["samples"]:
		var u: float = clampf((s - float(p["delay"])) / 0.55, 0.0, 1.0)
		_spiral_rect(c, Rect2(p["pos"] - Vector2.ONE * cell * 0.5, Vector2.ONE * cell), p["color"], u, 3.2)
	# After the spin-collapse: burst at the board centre.
	var bu: float = clampf((_t - _clip - COLLAPSE_S) / BURST_S, 0.0, 1.0)
	if bu > 0.0 and _burst != null:
		var sz: float = float(_d["radius"]) * (0.5 + 0.9 * bu)
		draw_texture_rect(_burst, Rect2(c - Vector2.ONE * sz * 0.5, Vector2.ONE * sz), false, Color(1, 1, 1, 1.0 - bu))

# ------------------------------------------------------------------ tornado --

## SB-TF-06: one additive VideoStreamPlayer, mapped so track key 0 sits on the Tornado button
## centre and the last key on the board centre. Axis-wise scale, no rotation: sy = screen / clip
## travel on y; sx follows the x travel but stays within STRETCH_MAX of sy, and the x travel the
## stretch cannot cover (the real layout is wider than the clip's path) drifts in with the
## tornado's travel progress. A stream that is missing or does not start leaves the code-only
## effect (cells into the board centre) over TORNADO_CLIP_S.
func _start_video() -> void:
	_clip = TORNADO_CLIP_S
	_map = {}
	if tornado_video == null or not (_d.get("button_center") is Vector2) or not (_d.get("board_center") is Vector2):
		return
	var v := VideoStreamPlayer.new()
	v.name = "TornadoVideo"
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.expand = true
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # black adds nothing over the board
	v.material = mat
	v.stream = tornado_video
	add_child(v)
	v.play()
	if not v.is_playing() or v.get_stream_length() <= 0.0:
		remove_child(v)
		v.free()
		return
	_video = v
	_clip = v.get_stream_length()
	var k0 := _track_key(0.0)
	var kn := _track_key(INF)
	var dt: Vector2 = kn - k0
	var ds: Vector2 = _d["board_center"] - _d["button_center"]
	var sy: float = ds.y / dt.y
	var sc := Vector2(clampf(ds.x / dt.x, sy / STRETCH_MAX, sy * STRETCH_MAX), sy)
	_map = {"scale": sc, "drift": ds.x - sc.x * dt.x,
		"base": _d["button_center"] - global_position - kn - sc * (k0 - kn)}
	v.size = TORNADO_SIZE
	v.pivot_offset = kn   # the collapse spins around the end-of-travel tornado
	v.scale = sc
	v.position = _map["base"]

func _free_video() -> void:
	if _video == null:
		return
	_video.visible = false
	_video.queue_free()   # the decoder teardown (~3 ms on the dev PC) runs at the frame's delete flush
	_video = null

## Clip-pixel tornado centre at clip time `t` (linear between the track keys, clamped).
func _track_key(t: float) -> Vector2:
	var f: float = t * TORNADO_FPS
	for i in range(1, TORNADO_TRACK.size()):
		var a: Array = TORNADO_TRACK[i - 1]
		var b: Array = TORNADO_TRACK[i]
		if f < float(b[0]):
			var u: float = clampf((f - float(a[0])) / float(b[0] - a[0]), 0.0, 1.0)
			return Vector2(a[1], a[2]).lerp(Vector2(b[1], b[2]), u)
	return Vector2(TORNADO_TRACK[-1][1], TORNADO_TRACK[-1][2])

## Travel progress 0..1 at clip time `t` (along y; the x drift follows it).
func _travel(t: float) -> float:
	var y0: float = TORNADO_TRACK[0][2]
	return clampf((_track_key(t).y - y0) / (float(TORNADO_TRACK[-1][2]) - y0), 0.0, 1.0)

## Global position of the tornado now (the board centre when no clip plays).
func tornado_pos() -> Vector2:
	if _map.is_empty():
		return _d.get("board_center", _d.get("center", Vector2.ZERO))
	return _d["button_center"] + _map["scale"] * (_track_key(_t) - _track_key(0.0)) + Vector2(_map["drift"] * _travel(_t), 0.0)

## "VIDEO" -> "COLLAPSE" -> "BURST" while Tornado plays, else "".
func tornado_phase() -> String:
	if _kind != "tornado":
		return ""
	if _t < _clip:
		return "VIDEO"
	return "COLLAPSE" if _t < _clip + COLLAPSE_S else "BURST"

func get_video_player() -> VideoStreamPlayer:
	return _video

## Pull progress 0..1: the cells wait on the board until PULL_FROM of the clip (the tornado has
## grown onto the board), then are sucked in, reaching the eye as the clip ends.
func _pull() -> float:
	return clampf((_t / _clip - PULL_FROM) / (1.0 - PULL_FROM), 0.0, 1.0)

func _tick_tornado() -> void:
	var c: Vector2 = tornado_pos()
	if _ghost.visible:   # every purged cell (one texture) is pulled toward the tornado as it is now
		var u: float = _ease_in(_pull())   # starts once the tornado nears the board, eye at clip end
		var off: Vector2 = (_d["center"] - c).rotated(-TAU * PULL_TURNS * u) * (1.0 - u)   # swirl in
		_ghost.position = (_d["board_rect"] as Rect2).position - global_position + c + off - _d["center"]
		_ghost.rotation = -TAU * 0.9 * u
		_ghost.scale = Vector2.ONE * (1.0 - u)
		_ghost.modulate.a = 1.0 - u * u
	if _video == null:
		return
	if _t >= _clip + COLLAPSE_S:
		_free_video()   # the burst takes over: no decoder while it is not seen
		return
	if _t >= _clip:
		_video.paused = true   # hold the last frame
		var cu: float = _ease_in(clampf((_t - _clip) / COLLAPSE_S, 0.0, 1.0))
		_video.rotation = -TAU * 1.5 * cu
		_video.scale = _map["scale"] * (1.0 - 0.85 * cu)
	_video.position = _map["base"] + Vector2(_map["drift"] * _travel(_t), 0.0)

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
