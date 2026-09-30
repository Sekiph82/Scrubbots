extends SceneTree
## M42-C002 — Home Scrubby hero scale + placement lock (SB-M42-034) focused suite.
## Authority: coordination/sessions/M42-C002/CHATGPT_PROMPT_V01.md (owner lock 1.612 =
## 1.24 x 1.30, current 940x1672 Home world). Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_c002_scrubby_scale.gd
##
## measure() is shared with tests/tools/m42_c002_scale_evidence.gd (measurement report).

const AppState = preload("res://scripts/app/app_state.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const HS = preload("res://scripts/ui/home/home_screen.gd")
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")

const OLD_SCALE := 1.24
const VIEWPORTS := [Vector2i(1080, 2160), Vector2i(1080, 1920), Vector2i(1290, 2796), Vector2i(1536, 2048)]
const SCRUBBY_PATH := "res://assets/ui/final/characters/scrubby/scrubby_home_pose.png"
## HOME-026 approved pin (assets/ui/HOME_ASSET_MANIFEST.json) — the texture is never replaced.
const SCRUBBY_SHA := "fc30b992787c644822a6cd02510e481fab9010cd89ab75fc4a9909ca713d5c18"
## Functional surfaces the hero must leave clear (hit rects of the live controls).
const FUNCTIONAL := ["TopCurrencyHUD", "GiftMeter", "PlayButton", "BottomNav",
	"Shortcut_shop", "Shortcut_collection", "Shortcut_tasks", "Shortcut_daily"]
## Live controls probed with real pointer events (hero area neighbours included).
const FUNCTIONAL_CONTROLS := ["PlayButton", "Shortcut_shop", "Shortcut_collection", "Shortcut_tasks",
	"Shortcut_daily", "Nav_settings", "Nav_home", "ScrubBucksPlus", "HeartsPlus"]
## Measured M42-C002 geometry of the fixed-anchor 1.612 hero vs the left baked helper bot's
## catalog rect: only the brush bristles (canvas x >= 204, bucket/spray strip) enter it.
const LEFT_BOT_MAX_X_INTRUSION := 47.0

var EXPECTED_CASES := [
	"exact_scale", "soles_registration", "ui_collision_matrix", "sign_helper",
	"responsive_relayout", "ui_truth", "identity_scope",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_exact_scale()
	var rows: Array = []
	for vp in VIEWPORTS:
		var r = await _home(vp, "m")
		rows.append(measure(r[1]))
		r[0].free()
		await process_frame
	_soles(rows)
	_collisions(rows)
	_sign_helper(rows)
	await _relayout()
	await _ui_truth()
	await _identity()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	_done()

# ------------------------------------------------------------ geometry ----

static func canonical_for(home, scale: float) -> Dictionary:
	var c: Dictionary = home.get_scrubby_canonical()
	var feet: Vector2 = home.get_world()["scrubby_feet_anchor"]
	var vis := HS.SCRUBBY_VISIBLE_BBOX
	var k: float = float(c["k_v04"]) * scale
	var origin := Vector2(feet.x - (vis.position.x + vis.size.x * 0.5) * k, feet.y - HS.SCRUBBY_FEET_Y * k)
	return {"k": k, "visible_rect": Rect2(origin + vis.position * k, vis.size * k)}

static func _to_screen(home, r: Rect2) -> Rect2:
	return Rect2(home.world_to_screen(r.position), r.size * float(home.get_world_transform()["scale"]))

static func _local_rect(home, n: String) -> Rect2:
	var r: Rect2 = home.get_region(n).get_global_rect()
	r.position -= home.global_position
	return r

## Opaque (alpha > 128) hero pixels drawn inside screen rect R (hero node rect `hr`).
static func opaque_in(img: Image, hr: Rect2, r: Rect2) -> Dictionary:
	var ov := hr.intersection(r)
	if ov.size.x <= 0.0 or ov.size.y <= 0.0:
		return {"px": 0, "rect": Rect2()}
	var ppx := hr.size.x / float(img.get_width())
	var x0 := clampi(int(floor((ov.position.x - hr.position.x) / ppx)), 0, img.get_width())
	var x1 := clampi(int(ceil((ov.end.x - hr.position.x) / ppx)), 0, img.get_width())
	var y0 := clampi(int(floor((ov.position.y - hr.position.y) / ppx)), 0, img.get_height())
	var y1 := clampi(int(ceil((ov.end.y - hr.position.y) / ppx)), 0, img.get_height())
	var n := 0
	var hit := Rect2()
	for y in range(y0, y1):
		for x in range(x0, x1):
			if img.get_pixel(x, y).a > 128.0 / 255.0:
				n += 1
				var p := Rect2(hr.position + Vector2(x, y) * ppx, Vector2(ppx, ppx))
				hit = p if hit.size == Vector2.ZERO else hit.merge(p)
	# screen px^2 covered (texture px scaled), and the covered bounds clipped to R
	return {"px": n, "area": n * ppx * ppx, "rect": hit.intersection(r) if n > 0 else Rect2()}

## Smallest screen distance from any opaque hero pixel to rect R (searched within `pad`).
static func clearance(img: Image, hr: Rect2, r: Rect2, pad := 96.0) -> float:
	var g := r.grow(pad).intersection(hr)
	if g.size.x <= 0.0 or g.size.y <= 0.0:
		return INF
	var ppx := hr.size.x / float(img.get_width())
	var best := INF
	for y in range(clampi(int(floor((g.position.y - hr.position.y) / ppx)), 0, img.get_height()), clampi(int(ceil((g.end.y - hr.position.y) / ppx)), 0, img.get_height())):
		for x in range(clampi(int(floor((g.position.x - hr.position.x) / ppx)), 0, img.get_width()), clampi(int(ceil((g.end.x - hr.position.x) / ppx)), 0, img.get_width())):
			if img.get_pixel(x, y).a > 128.0 / 255.0:
				var c := hr.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * ppx
				var d := Vector2(maxf(maxf(r.position.x - c.x, 0.0), c.x - r.end.x), maxf(maxf(r.position.y - c.y, 0.0), c.y - r.end.y))
				best = minf(best, d.length())
	return best

## Full per-viewport measurement (tests + evidence report).
static func measure(home) -> Dictionary:
	var t: Dictionary = home.get_world_transform()
	var s: float = t["scale"]
	var w: Dictionary = home.get_world()
	var c: Dictionary = home.get_scrubby_canonical()
	var sc: TextureRect = home.get_region("Art_scrubby")
	var img: Image = sc.texture.get_image()
	if img.is_compressed():
		img.decompress()
	var hr := _local_rect(home, "Art_scrubby")
	var tex := Vector2(img.get_width(), img.get_height())
	var vis := HS.SCRUBBY_VISIBLE_BBOX
	var m := {
		"viewport": home.get_viewport().size, "world_scale": s, "world_offset": t["offset"],
		"k_v04": c["k_v04"], "k": c["k"], "hero_node_rect": hr,
		"old_visible_canvas": canonical_for(home, OLD_SCALE)["visible_rect"],
		"new_visible_canvas": c["visible_rect"],
		"old_visible_screen": _to_screen(home, canonical_for(home, OLD_SCALE)["visible_rect"]),
		"new_visible_screen": Rect2(hr.position + vis.position * hr.size.x / tex.x, vis.size * hr.size.x / tex.x),
		"feet_screen": Vector2(hr.position.x + (vis.position.x + vis.size.x * 0.5) * hr.size.x / tex.x, hr.position.y + HS.SCRUBBY_FEET_Y * hr.size.y / tex.y),
		"contact_screen": home.world_to_screen(w["scrubby_feet_anchor"]),
		"world_clip": _local_rect(home, "Background"),
		"ui": {}, "sign": {}, "bots": [],
	}
	for n in FUNCTIONAL + ["WinStreakRewardTrack", "AdBannerSlot"]:
		var r := _local_rect(home, n)
		var o := opaque_in(img, hr, r)
		m["ui"][n] = {"rect": r, "bbox_hit": (m["new_visible_screen"] as Rect2).intersects(r), "opaque_px": o["px"], "opaque_rect": o["rect"], "clearance": clearance(img, hr, r)}
	var sr := _to_screen(home, w["baked_sign_rect"])
	var so := opaque_in(img, hr, sr)
	m["sign"] = {"rect": sr, "bbox_hit": (m["new_visible_screen"] as Rect2).intersects(sr), "opaque_px": so["px"]}
	for b in w["helper_bot_rects"]:
		var br := _to_screen(home, b)
		var bo := opaque_in(img, hr, br)
		var panels: Array = []
		for id in ["shop", "collection", "tasks", "daily"]:
			if _local_rect(home, "Shortcut_" + id).intersects(br):
				panels.append(id)
		m["bots"].append({"canvas": b, "rect": br, "bbox_hit": (m["new_visible_screen"] as Rect2).intersects(br), "opaque_px": bo["px"], "opaque_area": bo.get("area", 0.0), "opaque_rect": bo["rect"], "panel_hits": panels})
	return m

# --------------------------------------------------------------- cases ----

func _exact_scale() -> void:
	print("[exact scale]")
	_ok(HS.SCRUBBY_SCALE == 1.612, "SCRUBBY_SCALE == 1.612 exactly (%s)" % str(HS.SCRUBBY_SCALE))
	_ok(absf(HS.SCRUBBY_SCALE / OLD_SCALE - 1.30) < 1e-9, "1.612 / 1.24 == 1.30 (%.12f)" % (HS.SCRUBBY_SCALE / OLD_SCALE))
	_complete("exact_scale")

func _soles(rows: Array) -> void:
	print("[soles / platform registration]")
	for m in rows:
		var err: float = (m["feet_screen"] as Vector2).distance_to(m["contact_screen"])
		_ok(err <= 1.0, "%s soles %s vs platform contact %s: error %.4f px <= 1" % [str(m["viewport"]), str(m["feet_screen"]), str(m["contact_screen"]), err])
		_ok(absf(float(m["k"]) / float(m["k_v04"]) - HS.SCRUBBY_SCALE) < 1e-6, "%s hero stays 1.612 x V04 fit (no responsive scale-down)" % str(m["viewport"]))
		var old_h: float = (m["old_visible_screen"] as Rect2).size.y
		var new_h: float = (m["new_visible_screen"] as Rect2).size.y
		_ok(absf(new_h / old_h - 1.30) < 0.001, "%s on-screen visible height x%.4f (%.1f -> %.1f px)" % [str(m["viewport"]), new_h / old_h, old_h, new_h])
		var clip: Rect2 = m["world_clip"]
		_ok(clip.encloses(m["new_visible_screen"]), "%s hero fully inside the visible Home world %s (hero %s)" % [str(m["viewport"]), str(clip), str(m["new_visible_screen"])])
	_complete("soles_registration")

func _collisions(rows: Array) -> void:
	print("[ui collision matrix]")
	for m in rows:
		var hr: Rect2 = m["hero_node_rect"]
		for n in FUNCTIONAL:
			var u: Dictionary = m["ui"][n]
			_ok(int(u["opaque_px"]) == 0, "%s %s %s: no opaque hero pixel (bbox overlap %s, pixel clearance %s px)" % [str(m["viewport"]), n, str(u["rect"]), str(u["bbox_hit"]), ("%.1f" % u["clearance"]) if is_finite(u["clearance"]) else ">96"])
	_complete("ui_collision_matrix")

func _sign_helper(rows: Array) -> void:
	print("[sign / helper bots]")
	for m in rows:
		var vp: String = str(m["viewport"])
		_ok(not bool(m["sign"]["bbox_hit"]) and int(m["sign"]["opaque_px"]) == 0, "%s clears the baked sign" % vp)
		var right: Dictionary = m["bots"][1]
		_ok(int(right["opaque_px"]) == 0, "%s right helper bot: no hero pixel in its rect" % vp)
		var left: Dictionary = m["bots"][0]
		var lr: Rect2 = left["rect"]
		var intrusion: float = (left["opaque_rect"] as Rect2).end.x - (left["opaque_rect"] as Rect2).position.x if int(left["opaque_px"]) > 0 else 0.0
		var s: float = m["world_scale"]
		_ok(intrusion <= LEFT_BOT_MAX_X_INTRUSION * s + 1.0 and (left["opaque_rect"] as Rect2).position.x >= lr.end.x - LEFT_BOT_MAX_X_INTRUSION * s - 1.0, "%s left helper bot: only the brush bristles enter its rect's right %.0f-canvas-px strip (%.1f screen px, %d tex px)" % [vp, LEFT_BOT_MAX_X_INTRUSION, intrusion, left["opaque_px"]])
	# No horizontal re-anchor can clear both bots at 1.612: the hero's opaque span in the
	# bots' rows is wider than the gap between their rects (documented, measured).
	var img: Image = load(SCRUBBY_PATH).get_image()
	if img.is_compressed():
		img.decompress()
	var k: float = minf(330.0 / 1130.0, 620.0 / 1311.0) * HS.SCRUBBY_SCALE
	var oy: float = 1240.0 - HS.SCRUBBY_FEET_Y * k
	var lo := INF
	var hi := -INF
	for y in range(img.get_height()):
		var cy := oy + y * k
		if cy < 1010.0 or cy > 1260.0:
			continue
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 128.0 / 255.0:
				lo = minf(lo, x)
				hi = maxf(hi, x)
	var span := (hi - lo) * k
	_ok(span > 690.0 - 250.0, "fixed canonical anchor kept: opaque span in the bot rows %.1f > bot gap 440 (no shift clears both)" % span)
	for m in rows:
		_ok((m["bots"][0]["panel_hits"] as Array).is_empty() and (m["bots"][1]["panel_hits"] as Array).is_empty(), "%s panel helper-bot avoidance still holds (no panel over a bot)" % str(m["viewport"]))
	_complete("sign_helper")

func _relayout() -> void:
	print("[responsive relayout]")
	var r = await _home(VIEWPORTS[0], "relayout")
	var sub: SubViewport = r[0]
	var home = r[1]
	var sc: TextureRect = home.get_region("Art_scrubby")
	var shade: Control = home.get_region("HeroFocusShade")
	var tex := sc.texture
	var first := measure(home)
	var first_shade := _local_rect(home, "HeroFocusShade")
	var conns: int = home.get_signal_connection_list("resized").size()
	var timers := _count(home, "Timer")
	var tweens := get_processed_tweens().size()
	for vp in VIEWPORTS.slice(1) + [VIEWPORTS[0]]:
		sub.size = vp
		for _i in range(8):
			await process_frame
		var chars: Control = home.get_region("Layer_characters")
		var heroes := 0
		var shades := 0
		for ch in chars.get_children():
			heroes += int(ch.name.begins_with("Art_scrubby"))
			shades += int(ch.name.begins_with("HeroFocusShade"))
		var m := measure(home)
		_ok(home.get_region("Art_scrubby") == sc and sc.texture == tex and heroes == 1 and shades == 1 and home.get_region("HeroFocusShade") == shade, "%s same hero node + texture object, 1 hero / 1 shade" % str(vp))
		_ok((m["feet_screen"] as Vector2).distance_to(m["contact_screen"]) <= 1.0, "%s live-resized soles on platform contact" % str(vp))
	var back := measure(home)
	_ok((back["hero_node_rect"] as Rect2).is_equal_approx(first["hero_node_rect"]) and _local_rect(home, "HeroFocusShade").is_equal_approx(first_shade), "back at 1080x2160: identical hero rect %s and shade rect" % str(back["hero_node_rect"]))
	_ok(home.get_signal_connection_list("resized").size() == conns and _count(home, "Timer") == timers and get_processed_tweens().size() <= tweens, "no accumulating resized connections / timers / tweens (%d / %d / %d)" % [conns, timers, tweens])
	sub.free()
	await process_frame
	_complete("responsive_relayout")

func _ui_truth() -> void:
	print("[ui truth — real clicks through the hero area]")
	for vp in VIEWPORTS:
		var r = await _home(vp, "click")
		var sub: SubViewport = r[0]
		var home = r[1]
		var app = home.get_app_state()
		var before: Dictionary = app.economy.snapshot()
		var got: Array = []
		home.play_requested.connect(func(): got.append("play"))
		home.shortcut_requested.connect(func(id): got.append(id))
		home.settings_requested.connect(func(): got.append("settings"))
		# Every functional control is the topmost hit under its own centre (the hero and
		# shade never intercept); SHOP / COLLECTION / TASKS stay disabled by design (V04).
		var picks: Array = []
		for n in FUNCTIONAL_CONTROLS:
			var ctl: Control = home.get_region(n)
			var mv := InputEventMouseMotion.new()
			mv.position = _local_rect(home, n).get_center()
			mv.global_position = mv.position
			sub.push_input(mv)
			await process_frame
			var hov: Control = sub.gui_get_hovered_control()
			if hov == null or not (hov == ctl or ctl.is_ancestor_of(hov)):
				picks.append("%s->%s" % [n, hov.name if hov else "null"])
		_ok(picks.is_empty(), "%s every functional control is the top hit at its centre %s" % [str(vp), str(picks)])
		for n in ["PlayButton", "Shortcut_shop", "Shortcut_collection", "Shortcut_tasks", "Shortcut_daily", "Nav_settings"]:
			await _click(sub, _local_rect(home, n).get_center())
			home.close_top_popup()
			await process_frame
		_ok(got == ["play", "daily", "settings"], "%s real clicks: Play / DAILY / Settings fire, disabled SHOP/COLLECTION/TASKS stay inert %s" % [str(vp), str(got)])
		_ok(app.economy.snapshot() == before, "%s no economy mutation from presentation" % str(vp))
		for n in ["Art_scrubby", "HeroFocusShade", "Layer_characters"]:
			_ok(home.get_region(n).mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s %s never takes input" % [str(vp), n])
		sub.free()
		await process_frame
	_complete("ui_truth")

func _identity() -> void:
	print("[identity / scope]")
	var r = await _home(VIEWPORTS[0], "id")
	var home = r[1]
	var sc: TextureRect = home.get_region("Art_scrubby")
	_ok(sc.texture.resource_path == SCRUBBY_PATH and FileAccess.get_sha256(SCRUBBY_PATH) == SCRUBBY_SHA, "same approved HOME-026 texture (sha %s…)" % FileAccess.get_sha256(SCRUBBY_PATH).left(8))
	_ok(sc.get_parent() == home.get_region("Layer_characters") and sc.get_parent().get_parent() == home.get_region("Background"), "separate runtime hero layer above the world background")
	var legacy := false
	for n in ["scrubby_face_blink_layer", "scrubby_brush_arm_layer", "Art_scrubby_face", "Art_scrubby_brush"]:
		legacy = legacy or home.find_child(n, true, false) != null
	_ok(not legacy, "no revived face/brush overlay layers")
	_ok(_count(home, "AnimationPlayer") == 0 and _count(home, "AnimatedSprite2D") == 0 and _count(home, "AnimationTree") == 0, "no animation component on Home")
	_ok(HS.HERO_SHADE_RECT == Rect2(260, 600, 420, 690) and HS.HERO_SHADE_ALPHA == 0.20, "HeroFocusShade unchanged (still centred behind the torso; wider would reach the helper bots)")
	var c: Dictionary = home.get_scrubby_canonical()
	var torso := Vector2(c["center_x"], (c["visible_rect"] as Rect2).get_center().y)
	_ok(HS.HERO_SHADE_RECT.has_point(torso), "enlarged torso centre %s inside the shade" % str(torso))
	r[0].free()
	await process_frame
	_complete("identity_scope")

# ------------------------------------------------------------- helpers ----

func _home(size: Vector2i, tag: String) -> Array:
	var p := "user://m42_c002_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	var clock := func(): return 1790000000   # fixed clock: no Heart-regen drift between snapshots
	var app = AppState.new(p, clock, LocalCalendar.offset_provider(clock, 0))
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	home.get_region("SafeAreaRoot").set_synthetic_insets(0, 0, 0, 0)
	for _i in range(8):
		await process_frame
	return [sub, home]

func _click(sub: SubViewport, at: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		e.global_position = at
		sub.push_input(e)
		await process_frame

func _count(n: Node, cls: String) -> int:
	var c := int(n.is_class(cls))
	for ch in n.get_children():
		c += _count(ch, cls)
	return c

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		_fail += 1
		print("  FAIL: ", msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: cases not completed: ", missing)
	print("m42_c002_scrubby_scale: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
