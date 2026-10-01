extends SceneTree
## M42-C003 V03 — Home Scrubby runtime animation (SB-M42-035) focused suite.
## Authority: coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V03.md,
## coordination/sessions/M42-C003/ASSET_PRODUCTION_SPEC_V03.md, AUDIT_CRITERIA_V03.md.
## The hero is driven through its deterministic step() seam (process off) with a fixed
## RNG seed; real pointer events check that Home stays usable mid-gesture.
##
## Run: godot --headless --path . -s res://tests/m42_c003_scrubby_animation.gd
## measure_frames() is shared with tests/tools/m42_c003_animation_evidence.gd.

const AppState = preload("res://scripts/app/app_state.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const HS = preload("res://scripts/ui/home/home_screen.gd")
const Hero = preload("res://scripts/ui/home/home_scrubby_hero.gd")
const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")
const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")

const VIEWPORTS := [Vector2i(1080, 2160), Vector2i(1080, 1920), Vector2i(1290, 2796), Vector2i(1536, 2048)]
const SET_ID := "home_scrubby_gestures_v03"
const HOME_PATH := "res://assets/ui/final/characters/scrubby/scrubby_home_pose.png"
const HOME_SHA := "fc30b992787c644822a6cd02510e481fab9010cd89ab75fc4a9909ca713d5c18"
const COUNTS := {"wave": 14, "bow": 15, "turn": 17, "full_turn": 17}
const DURATION := {"wave": [1.0, 1.5], "bow": [1.0, 1.6], "turn": [1.2, 1.8], "full_turn": [1.0, 1.8]}
const SOURCE_FAMILY := {"wave": "wave", "bow": "bow", "turn": "turn_look", "full_turn": "full_turn"}
## Hard blockers (live functional UI). Helper bots are warning-only (owner V03).
const HARD := ["TopCurrencyHUD", "GiftMeter", "PlayButton", "BottomNav",
	"Shortcut_shop", "Shortcut_collection", "Shortcut_tasks", "Shortcut_daily"]
const DT := 1.0 / 60.0

var EXPECTED_CASES := [
	"assets_manifest", "final_only_and_parity", "static_fallback", "base_geometry",
	"pivot_mapping_no_jitter", "frame_feet_registration", "idle_identity", "durations",
	"scheduler_weights_no_repeat", "no_stack_and_restore", "screen_space_gates",
	"reduced_effects", "modal", "route_visibility", "focus_pause", "stability_20x",
	"presentation_only", "buttons_usable",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_assets()
	_final_only()
	await _static_fallback()
	await _geometry()
	_feet()
	await _idle()
	await _durations()
	await _scheduler()
	await _no_stack()
	await _screen_space()
	await _reduced()
	await _modal()
	await _route()
	await _focus()
	await _stability()
	await _presentation_only()
	await _buttons()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	_done()

# ----------------------------------------------------------------- helpers ----

func _app():
	var p := "user://m42_c003_%d.save" % Time.get_ticks_usec()
	_tmp.append(p)
	var clock := func(): return 1790000000
	return AppState.new(p, clock, LocalCalendar.offset_provider(clock, 0))

func _home(size: Vector2i, app = null) -> Array:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app if app != null else _app())
	home.get_region("SafeAreaRoot").set_synthetic_insets(0, 0, 0, 0)
	for _i in range(8):
		await process_frame
	var hero = home.get_region("HomeScrubbyHero")
	hero.set_process(false)
	hero.set_rng_seed(42)
	return [sub, home, hero]

func _local(home, n: String) -> Rect2:
	var r: Rect2 = home.get_region(n).get_global_rect()
	r.position -= home.global_position
	return r

func _run(hero, seconds: float) -> void:
	for _i in range(int(round(seconds / DT))):
		hero.step(DT)

static func manifest_set() -> Dictionary:
	return V.load_manifest()["animation_sets"][SET_ID]

## Screen-space geometry of every frame at the live layout (shared with the evidence tool).
static func measure_frames(home) -> Dictionary:
	var hero = home.get_region("HomeScrubbyHero")
	var s: Dictionary = hero.get_set()
	var g: TextureRect = hero.get_gesture_rect()
	var gr := Rect2(g.position, g.size)
	var px: float = gr.size.x / float(s["canvas"][0])
	var vp: Vector2 = home.get_viewport().size
	var clip: Rect2 = (home.get_region("Background") as Control).get_global_rect()
	clip.position -= home.global_position
	var rects := {}
	for n in HARD:
		var r: Rect2 = home.get_region(n).get_global_rect()
		r.position -= home.global_position
		rects[n] = r
	var w: Dictionary = home.get_world()
	var bots := []
	for b in w["helper_bot_rects"]:
		bots.append(Rect2(home.world_to_screen(b.position), b.size * float(home.get_world_transform()["scale"])))
	var out := {"viewport": vp, "gesture_rect": gr, "px": px, "hard": {}, "clip_out": [], "helpers": {}, "union": Rect2()}
	for gesture in s["textures"]:
		var frames: Array = s["textures"][gesture]
		for i in frames.size():
			var img: Image = (frames[i] as Texture2D).get_image()
			if img.is_compressed():
				img.decompress()
			var used := img.get_used_rect()
			var sr := Rect2(gr.position + Vector2(used.position) * px, Vector2(used.size) * px)
			out["union"] = sr if out["union"] == Rect2() else (out["union"] as Rect2).merge(sr)
			var tag := "%s_%02d" % [gesture, i + 1]
			if not clip.encloses(sr) or sr.position.x < 0.0 or sr.end.x > vp.x:
				(out["clip_out"] as Array).append(tag)
			for n in rects:
				var c := _opaque_in(img, gr.position, px, rects[n])
				if c > 0:
					out["hard"][n + ":" + tag] = c
			for bi in bots.size():
				var c := _opaque_in(img, gr.position, px, bots[bi])
				if c > 0:
					out["helpers"]["%s:%s" % ["left" if bi == 0 else "right", tag]] = c
	return out

static func _opaque_in(img: Image, origin: Vector2, px: float, r: Rect2) -> int:
	var x0 := clampi(int(floor((r.position.x - origin.x) / px)), 0, img.get_width())
	var x1 := clampi(int(ceil((r.end.x - origin.x) / px)), 0, img.get_width())
	var y0 := clampi(int(floor((r.position.y - origin.y) / px)), 0, img.get_height())
	var y1 := clampi(int(ceil((r.end.y - origin.y) / px)), 0, img.get_height())
	var n := 0
	for y in range(y0, y1):
		for x in range(x0, x1):
			if img.get_pixel(x, y).a > 0.5:
				var c := origin + (Vector2(x, y) + Vector2(0.5, 0.5)) * px
				if r.has_point(c):
					n += 1
	return n

# ------------------------------------------------------------------- cases ----

func _assets() -> void:
	print("[assets / manifest]")
	var m = V.load_manifest()
	var res: Dictionary = V.validate(m)
	_ok(res["ok"], "HOME manifest (incl. animation_sets) validates %s" % str(res["errors"]))
	var s: Dictionary = m["animation_sets"][SET_ID]
	var counts := {}
	var sizes := {}
	for g in s["gestures"]:
		counts[g] = (s["gestures"][g]["frames"] as Array).size()
		for f in s["gestures"][g]["frames"]:
			var tex := load("res://" + String(f["path"])) as Texture2D
			sizes[Vector2i(tex.get_width(), tex.get_height())] = true
	_ok(counts == COUNTS, "exact counts 14/15/17/17 %s" % str(counts))
	_ok(sizes.size() == 1 and sizes.has(Vector2i(s["canvas"][0], s["canvas"][1])), "all 63 frames share one canvas %s" % str(sizes.keys()))
	_ok((s["pivot"] as Array).size() == 2 and int(s["pivot"][0]) > 0 and int(s["pivot"][1]) > 0 and int(s["pivot"][1]) < int(s["canvas"][1]), "one common animation pivot %s inside canvas %s" % [str(s["pivot"]), str(s["canvas"])])
	_ok(FileAccess.get_sha256(HOME_PATH) == HOME_SHA and s["idle_texture_sha256"] == HOME_SHA, "HOME-026 byte-identical (%s)" % HOME_SHA.left(12))
	# One uniform scale per source family (normalization evidence, every frame).
	var ev = JSON.parse_string(FileAccess.get_file_as_string("res://coordination/sessions/M42-C003/evidence_v03/normalization_measurements.json"))
	var per_family := {}
	var shas_ok := true
	for f in ev["frames"]:
		var fam := String(f["source_family"])
		if not per_family.has(fam):
			per_family[fam] = {}
		per_family[fam][str(f["scale_anim_px_per_source_px"])] = true
	for g in s["gestures"]:
		var i := 0
		for f in s["gestures"][g]["frames"]:
			var e: Dictionary = ev["frames"].filter(func(x): return x["gesture"] == g and int(x["frame"]) == i + 1)[0]
			shas_ok = shas_ok and e["sha256"] == f["sha256"] and String(e["source_family"]) == SOURCE_FAMILY[g]
			i += 1
	var uniform := true
	for fam in per_family:
		uniform = uniform and (per_family[fam] as Dictionary).size() == 1
	_ok(uniform and per_family.size() == 4, "one uniform scale per source family %s" % str(per_family.keys()))
	_ok(shas_ok, "deterministic tool output == promoted bytes == manifest pins (63/63); Turn/Look from the turn_look family")
	var rr := FileAccess.get_file_as_string("res://coordination/sessions/M42-C003/evidence_v03/deterministic_rerun.md")
	_ok(rr.find("63/63 frames byte-identical") != -1, "deterministic rerun evidence 63/63")
	_complete("assets_manifest")

func _final_only() -> void:
	print("[final-only paths + SHA parity]")
	var s := manifest_set()
	var final_ok := true
	var parity := true
	for g in s["gestures"]:
		for f in s["gestures"][g]["frames"]:
			final_ok = final_ok and String(f["path"]).begins_with("assets/ui/final/characters/scrubby/home_animation/%s/" % g)
			parity = parity and FileAccess.get_sha256("res://" + String(f["path"])) == String(f["sha256"])
	_ok(final_ok, "runtime frame paths are final/home_animation/{wave,bow,turn,full_turn} only")
	_ok(parity, "every pinned sha256 == file bytes")
	var src := FileAccess.get_file_as_string("res://scripts/ui/home/home_scrubby_hero.gd") + FileAccess.get_file_as_string("res://scripts/ui/home/home_screen.gd")
	_ok(src.find("ui/generated") == -1 and src.find("face_blink") == -1 and src.find("brush_arm") == -1, "runtime never references generated candidates or the V03 overlay layers")
	var b = HomeArtBinder.new()
	var a: Dictionary = b.animation_set(SET_ID)
	_ok(a.has("textures") and (a["textures"]["wave"] as Array).size() == 14, "binder serves the pinned set")
	_ok(not b.can_write(String(s["gestures"]["wave"]["frames"][0]["path"])), "promoted frames are write-protected")
	var m = V.load_manifest()
	m["animation_sets"][SET_ID]["gestures"]["bow"]["frames"][3]["sha256"] = "0".repeat(64)
	var bad = HomeArtBinder.new(m)
	_ok(not bad.is_manifest_valid() and bad.animation_set(SET_ID).is_empty(), "a changed frame pin invalidates the manifest -> no animation")
	_complete("final_only_and_parity")

func _static_fallback() -> void:
	print("[static fallback]")
	var r = await _home(VIEWPORTS[0])
	var home = r[1]
	var hero = r[2]
	_ok(hero.has_frames() and home.get_region("Art_scrubby").texture.resource_path == HOME_PATH, "live Home binds HOME-026 + the frame set")
	hero.set_frames({})
	_run(hero, 30.0)
	_ok(not hero.has_frames() and hero.get_state()["gesture"] == "" and not hero.get_gesture_rect().visible and home.get_region("Art_scrubby").self_modulate.a == 1.0, "without a valid set: static HOME-026 only, no gesture in 30 s")
	r[0].free()
	await process_frame
	_complete("static_fallback")

func _geometry() -> void:
	print("[base geometry]")
	_ok(HS.SCRUBBY_SCALE == 1.612, "SCRUBBY_SCALE 1.612 unchanged")
	for vp in VIEWPORTS:
		var r = await _home(vp)
		var home = r[1]
		var hero = r[2]
		var c: Dictionary = home.get_scrubby_canonical()
		var sc := _local(home, "Art_scrubby")
		var expect := Rect2(home.world_to_screen(c["origin"]), Vector2(1158, 1358) * float(c["k"]) * float(home.get_world_transform()["scale"]))
		_ok(sc.is_equal_approx(expect), "%s HOME-026 keeps the accepted M42-C002 rect %s" % [str(vp), str(sc)])
		_run(hero, 1.3)   # mid-idle: the shader squash never moves the node rect
		_ok(_local(home, "Art_scrubby").is_equal_approx(sc), "%s idle never alters Art_scrubby rect" % str(vp))
		r[0].free()
		await process_frame
	_complete("base_geometry")

func _pivot_check(home, hero) -> Array:
	var s: Dictionary = hero.get_set()
	var sc := _local(home, "Art_scrubby")
	var k: float = sc.size.x / 1158.0
	var root := sc.position + Vector2(s["home_root_texels"][0], s["home_root_texels"][1]) * k
	var g: TextureRect = hero.get_gesture_rect()
	var d := float(s["home_texels_per_anim_pixel"])
	var mapped: Vector2 = g.position + Vector2(s["pivot"][0], s["pivot"][1]) * d * k
	return [mapped.distance_to(root), g.size.distance_to(Vector2(s["canvas"][0], s["canvas"][1]) * d * k), Rect2(g.position, g.size)]

func _pivot_mapping(home, hero, vp) -> void:
	var p := _pivot_check(home, hero)
	_ok(p[0] < 0.01 and p[1] < 0.01, "%s animation pivot -> HOME screen soles (err %.4f px), size = canvas x %d x k" % [str(vp), p[0], int(hero.get_set()["home_texels_per_anim_pixel"])])

func _feet() -> void:
	print("[frame feet registration]")
	var s := manifest_set()
	var pv := Vector2(s["pivot"][0], s["pivot"][1])
	var worst := 0.0
	var bad: Array = []
	for g in s["gestures"]:
		var i := 0
		for f in s["gestures"][g]["frames"]:
			i += 1
			var img: Image = (load("res://" + String(f["path"])) as Texture2D).get_image()
			if img.is_compressed():
				img.decompress()
			var root := _sole_root(img)
			var e: float = root.distance_to(pv)
			worst = maxf(worst, e)
			if e > 2.0:
				bad.append("%s_%02d %.1f" % [g, i, e])
	_ok(bad.is_empty(), "63/63 frames: planted sole midpoint on the common pivot (worst %.2f anim px <= 2) %s" % [worst, str(bad)])
	_complete("frame_feet_registration")

## Same rule as the asset tool: dark unsaturated rubber soles, lowest 8% band midpoint.
static func _sole_root(img: Image) -> Vector2:
	var used := img.get_used_rect()
	var y_lo := 0
	var y_hi := -1
	for y in range(used.end.y - 1, used.position.y, -1):
		for x in range(used.position.x, used.end.x):
			if img.get_pixel(x, y).a > 0.5:
				y_hi = y
				break
		if y_hi >= 0:
			break
	for y in range(used.position.y, used.end.y):
		var any := false
		for x in range(used.position.x, used.end.x, 2):
			if img.get_pixel(x, y).a > 0.5:
				any = true
				break
		if any:
			y_lo = y
			break
	var h := y_hi - y_lo + 1
	var sole_y := -1
	for y in range(y_hi, int(y_hi - 0.25 * h), -1):
		for x in range(used.position.x, used.end.x):
			if _rubber(img.get_pixel(x, y)):
				sole_y = y
				break
		if sole_y >= 0:
			break
	var xmin := 1 << 30
	var xmax := -1
	for y in range(int(sole_y - 0.08 * h), sole_y + 1):
		for x in range(used.position.x, used.end.x):
			if _rubber(img.get_pixel(x, y)):
				xmin = mini(xmin, x)
				xmax = maxi(xmax, x)
	return Vector2((xmin + xmax) / 2.0, sole_y)

static func _rubber(c: Color) -> bool:
	if c.a <= 128.0 / 255.0:
		return false
	var r := c.r * 255.0
	var g := c.g * 255.0
	var b := c.b * 255.0
	return 0.299 * r + 0.587 * g + 0.114 * b < 70.0 and maxf(r, maxf(g, b)) - minf(r, minf(g, b)) < 45.0

func _idle() -> void:
	print("[idle identity]")
	var r = await _home(VIEWPORTS[0])
	var hero = r[2]
	hero.start_gesture("wave")
	while hero.get_state()["gesture"] != "":
		hero.step(DT)
	_ok(hero.get_state()["idle_t"] == 0.0 and hero.get_idle_squash() == Vector2.ONE, "after a gesture idle restarts at phase 0 = identity squash")
	r[1].set_modal_active("settings", true)   # holds the scheduler; idle keeps breathing
	var peak := 0.0
	var n := int(round(Hero.IDLE_PERIOD / DT))
	for _c in range(10):
		for _i in range(n):
			hero.step(DT)
			peak = maxf(peak, absf(hero.get_idle_squash().y - 1.0))
	var st: Dictionary = hero.get_state()
	_ok(peak > 0.0 and peak <= Hero.IDLE_SQUASH + 1e-6, "restrained idle: peak squash %.4f <= %.3f" % [peak, Hero.IDLE_SQUASH])
	var wrapped: float = minf(st["idle_t"], Hero.IDLE_PERIOD - st["idle_t"])
	_ok(wrapped < 1e-3 and absf(hero.get_idle_squash().y - 1.0) < 1e-4, "after 10 whole periods: back at phase %.6f s, squash %.6f (no drift)" % [wrapped, hero.get_idle_squash().y])
	_ok((hero.get_idle_material() as ShaderMaterial).get_shader_parameter("pivot").distance_to(hero.get_pivot_screen() - (r[1].get_region("Art_scrubby") as Control).position) < 0.01, "idle squashes about the HOME soles pivot (feet never move)")
	r[0].free()
	await process_frame
	_complete("idle_identity")

func _durations() -> void:
	print("[gesture durations]")
	var r = await _home(VIEWPORTS[0])
	var hero = r[2]
	for g in COUNTS:
		var d: float = hero.gesture_duration(g)
		_ok(d >= DURATION[g][0] and d <= DURATION[g][1], "%s %d frames @ %d fps = %.3f s in %s" % [g, COUNTS[g], int(hero.get_set()["fps"]), d, str(DURATION[g])])
		_ok(hero.start_gesture(g), "%s starts" % g)
		var steps := 0
		while hero.get_state()["gesture"] != "" and steps < 1000:
			hero.step(DT)
			steps += 1
		_ok(absf(steps * DT - d) <= DT * 2.01, "%s plays once and returns (%.3f s)" % [g, steps * DT])
	r[0].free()
	await process_frame
	_complete("durations")

func _scheduler() -> void:
	print("[scheduler: weights / no repeat / 6..12 s]")
	var r = await _home(VIEWPORTS[0])
	var hero = r[2]
	_ok(Hero.WEIGHTS == {"wave": 35, "turn": 30, "bow": 25, "full_turn": 10}, "weights 35/30/25/10")
	# Long deterministic run through the real scheduler.
	var seq: Array = []
	var intervals: Array = []
	var idle_since := 0.0
	var prev := ""
	for _i in range(int(3600.0 / DT)):
		hero.step(DT)
		var g: String = hero.get_state()["gesture"]
		if g != "" and prev == "":
			seq.append(g)
			intervals.append(idle_since)
		idle_since = 0.0 if g != "" else idle_since + DT
		prev = g
	var repeats := 0
	for i in range(1, seq.size()):
		repeats += int(seq[i] == seq[i - 1])
	_ok(seq.size() > 250 and repeats == 0, "%d gestures in 1 h, 0 immediate repeats" % seq.size())
	_ok(intervals.min() >= Hero.INTERVAL_MIN - DT and intervals.max() <= Hero.INTERVAL_MAX + DT, "idle intervals %.2f..%.2f s within 6..12" % [intervals.min(), intervals.max()])
	# Conditional distribution after each previous gesture == weights of the others.
	var dist_ok := true
	var report := []
	for last in Hero.WEIGHTS:
		var counts := {}
		var total := 0
		for i in range(1, seq.size()):
			if seq[i - 1] == last:
				counts[seq[i]] = int(counts.get(seq[i], 0)) + 1
				total += 1
		var wsum := 0
		for g in Hero.WEIGHTS:
			if g != last:
				wsum += int(Hero.WEIGHTS[g])
		for g in Hero.WEIGHTS:
			if g == last:
				continue
			var expect := float(Hero.WEIGHTS[g]) / wsum
			var got := float(counts.get(g, 0)) / maxf(1.0, total)
			report.append("%s>%s %.2f/%.2f" % [last, g, got, expect])
			if total >= 20 and absf(got - expect) > 0.2:
				dist_ok = false
	_ok(dist_ok, "picks follow the weights of the non-previous gestures %s" % str(report))
	# Exact pick probabilities via the RNG seam (large sample, no scheduling noise).
	var picks := {}
	hero.set_rng_seed(7)
	for i in range(20000):
		var g: String = hero.pick_gesture()
		picks[g] = int(picks.get(g, 0)) + 1
	var full_turn_share := float(picks.get("full_turn", 0)) / 20000.0
	_ok(full_turn_share < 0.15 and int(picks.get("wave", 0)) > int(picks.get("turn", 0)) and int(picks.get("turn", 0)) > int(picks.get("bow", 0)), "Full Turn rare (%.1f%%), wave > turn > bow %s" % [full_turn_share * 100.0, str(picks)])
	r[0].free()
	await process_frame
	_complete("scheduler_weights_no_repeat")

func _no_stack() -> void:
	print("[no stacking / exact restoration / pivot / no jitter]")
	for vp in VIEWPORTS:
		var r = await _home(vp)
		var home = r[1]
		var hero = r[2]
		_pivot_mapping(home, hero, vp)
		var sc_before := _local(home, "Art_scrubby")
		for g in COUNTS:
			_ok(hero.start_gesture(g), "%s %s starts" % [str(vp), g])
			_ok(not hero.start_gesture("wave" if g != "wave" else "bow"), "%s second gesture refused while %s runs" % [str(vp), g])
			var rects := {}
			var shown := {}
			while hero.get_state()["gesture"] != "":
				var gr: TextureRect = hero.get_gesture_rect()
				rects[Rect2(gr.position, gr.size)] = true
				shown[hero.get_frame_index()] = true
				_ok_quiet(home.get_region("Art_scrubby").self_modulate.a == 0.0 and gr.visible, "%s %s HOME hidden while gesturing" % [str(vp), g])
				hero.step(DT)
			_ok(rects.size() == 1 and shown.size() == COUNTS[g], "%s %s: %d/%d frames shown, 1 gesture rect (no swap jitter)" % [str(vp), g, shown.size(), COUNTS[g]])
			var st: Dictionary = hero.get_state()
			_ok(not hero.get_gesture_rect().visible and hero.get_gesture_rect().texture == null and home.get_region("Art_scrubby").self_modulate.a == 1.0 and hero.get_idle_squash() == Vector2.ONE and _local(home, "Art_scrubby").is_equal_approx(sc_before) and st["wait"] >= Hero.INTERVAL_MIN, "%s %s -> exact HOME-026 idle (rect, squash identity, fresh %.2f s interval)" % [str(vp), g, st["wait"]])
		r[0].free()
		await process_frame
	_complete("pivot_mapping_no_jitter")
	_complete("no_stack_and_restore")

func _screen_space() -> void:
	print("[screen-space gates: 63 frames x 4 viewports]")
	for vp in VIEWPORTS:
		var r = await _home(vp)
		var m := measure_frames(r[1])
		_ok((m["hard"] as Dictionary).is_empty(), "%s: 0 opaque gesture pixels in Play / HUD / Gift / BottomNav / 4 shortcuts %s" % [str(vp), str(m["hard"])])
		_ok((m["clip_out"] as Array).is_empty(), "%s: no frame clipped by the viewport/world clip (union %s)" % [str(vp), str(m["union"])])
		var lh := 0
		var rh := 0
		for key in m["helpers"]:
			if String(key).begins_with("left"):
				lh += 1
			else:
				rh += 1
		print("  WARN (decorative, non-blocking): %s helper overlap frames left %d / right %d; Scrubby draws in front of the baked helpers" % [str(vp), lh, rh])
		r[0].free()
		await process_frame
	_complete("screen_space_gates")

func _reduced() -> void:
	print("[Reduced Effects (AppState.effects, live)]")
	var app = _app()
	var r = await _home(VIEWPORTS[0], app)
	var hero = r[2]
	var conns: int = app.effects.changed.get_connections().size()
	_ok(hero.start_gesture("wave"), "gesture running")
	app.effects.set_reduced(true)
	_ok(hero.get_state()["gesture"] == "" and not hero.get_gesture_rect().visible and r[1].get_region("Art_scrubby").self_modulate.a == 1.0, "ON live: running gesture ends, static HOME-026")
	_run(hero, 60.0)
	_ok(hero.get_state()["counts"].get("bow", 0) == 0 and hero.get_state()["gesture"] == "" and hero.get_idle_squash() == Vector2.ONE and not hero.start_gesture("bow"), "ON: no gesture in 60 s, no idle motion, start refused")
	app.effects.set_reduced(false)
	hero.step(DT)
	var w: float = hero.get_state()["wait"]
	_ok(w >= Hero.INTERVAL_MIN - DT and w <= Hero.INTERVAL_MAX, "OFF live: fresh %.2f s interval (no catch-up)" % w)
	_run(hero, Hero.INTERVAL_MAX + 0.5)
	_ok(hero.get_state()["gesture"] != "" or hero.get_state()["counts"].size() > 1, "OFF: gestures resume")
	_ok(app.effects.changed.get_connections().size() == conns, "single canonical effects connection (%d)" % conns)
	r[0].free()
	await process_frame
	_ok(app.effects.changed.get_connections().size() == conns - 1, "connection released when Home is freed")
	_complete("reduced_effects")

func _modal() -> void:
	print("[modal suppression / resume]")
	var r = await _home(VIEWPORTS[0])
	var home = r[1]
	var hero = r[2]
	home.set_modal_active("settings", true)
	_ok(not hero.can_start_gesture() and not hero.start_gesture("wave"), "settings overlay: no new gesture")
	_run(hero, 40.0)
	_ok(hero.get_state()["counts"].is_empty(), "40 s under modal: 0 gestures")
	home.set_modal_active("settings", false)
	var p = home.open_popup("daily")
	_ok(not hero.can_start_gesture(), "DAILY popup: no new gesture")
	p.close_popup()
	hero.step(DT)
	var w: float = hero.get_state()["wait"]
	_ok(w >= Hero.INTERVAL_MIN - DT, "resume: fresh %.2f s interval" % w)
	# A gesture already running when a modal opens finishes cleanly (no snap).
	_run(hero, Hero.INTERVAL_MAX + 0.5)
	var running: String = hero.get_state()["gesture"]
	if running == "":
		hero.start_gesture("bow")
		running = "bow"
	home.set_modal_active("settings", true)
	var steps := 0
	while hero.get_state()["gesture"] != "" and steps < 200:
		hero.step(DT)
		steps += 1
	_ok(hero.get_state()["gesture"] == "" and steps > 0, "running %s finishes under the modal, then idle" % running)
	var before: Dictionary = hero.get_state()["counts"].duplicate()
	_run(hero, 30.0)
	_ok(hero.get_state()["counts"] == before, "and nothing new starts while it stays open")
	home.set_modal_active("settings", false)
	r[0].free()
	await process_frame
	_complete("modal")

func _route() -> void:
	print("[route visibility]")
	var r = await _home(VIEWPORTS[0])
	var home = r[1]
	var hero = r[2]
	hero.start_gesture("turn")
	home.visible = false
	hero.step(DT)
	_ok(hero.get_state()["gesture"] == "" and not hero.motion_allowed(), "Home hidden: inert, gesture dropped while invisible")
	_run(hero, 40.0)
	_ok(hero.get_state()["counts"].get("wave", 0) == 0 and hero.get_state()["gesture"] == "", "hidden 40 s: nothing starts")
	home.visible = true
	hero.step(DT)
	_ok(hero.get_state()["wait"] >= Hero.INTERVAL_MIN - DT, "shown: fresh %.2f s interval" % hero.get_state()["wait"])
	r[0].free()
	await process_frame
	_complete("route_visibility")

func _focus() -> void:
	print("[focus / pause]")
	var r = await _home(VIEWPORTS[0])
	var hero = r[2]
	for pair in [[NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_IN, "focus"], [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_RESUMED, "pause"]]:
		hero.start_gesture("full_turn" if pair[2] == "focus" else "wave")
		hero.notification(pair[0])
		hero.step(DT)
		_ok(hero.get_state()["gesture"] == "" and not hero.motion_allowed(), "%s lost: inert, static HOME-026" % pair[2])
		var before: Dictionary = hero.get_state()["counts"].duplicate()
		_run(hero, 40.0)
		_ok(hero.get_state()["counts"] == before, "%s lost 40 s: nothing starts" % pair[2])
		hero.notification(pair[1])
		hero.step(DT)
		_ok(hero.get_state()["wait"] >= Hero.INTERVAL_MIN - DT, "%s back: fresh %.2f s interval, no burst" % [pair[2], hero.get_state()["wait"]])
	r[0].free()
	await process_frame
	_complete("focus_pause")

func _count(n: Node) -> int:
	var c := 1
	for ch in n.get_children():
		c += _count(ch)
	return c

func _stability() -> void:
	print("[20x Home enter/leave]")
	var app = _app()
	var r = await _home(VIEWPORTS[0], app)
	var home = r[1]
	var hero = r[2]
	var nodes := _count(home)
	var conns: int = app.effects.changed.get_connections().size()
	var tweens := get_processed_tweens().size()
	for i in range(20):
		home.visible = false
		_run(hero, 0.5)
		home.visible = true
		_run(hero, 13.0)
	_ok(_count(home) == nodes and app.effects.changed.get_connections().size() == conns and get_processed_tweens().size() == tweens, "same Home hidden/shown 20x: nodes %d, effects conns %d, tweens %d unchanged" % [nodes, conns, tweens])
	r[0].free()
	await process_frame
	var base: int = app.effects.changed.get_connections().size()
	var objs := Performance.get_monitor(Performance.OBJECT_COUNT)
	for i in range(20):
		var q = await _home(VIEWPORTS[0], app)
		_run(q[2], 7.0)
		q[0].free()
		await process_frame
	await process_frame
	var objs_after := Performance.get_monitor(Performance.OBJECT_COUNT)
	_ok(app.effects.changed.get_connections().size() == base, "20x new Home free: effects connections back to %d" % base)
	_ok(objs_after - objs < 200, "20x Home create/free: object count growth %d (< 200)" % int(objs_after - objs))
	_complete("stability_20x")

func _presentation_only() -> void:
	print("[presentation-only truth]")
	var app = _app()
	var r = await _home(VIEWPORTS[0], app)
	var hero = r[2]
	var econ: Dictionary = app.economy.snapshot()
	var prog: Dictionary = app.progression.snapshot()
	var fx: Dictionary = app.effects.snapshot()
	var dirty: bool = app.is_dirty()
	_run(hero, 120.0)
	for g in COUNTS:
		hero.start_gesture(g)
		_run(hero, 2.0)
	_ok(app.economy.snapshot() == econ and app.progression.snapshot() == prog and app.effects.snapshot() == fx and app.is_dirty() == dirty, "2 min + 4 gestures: economy / progression / effects unchanged, nothing marked for save")
	_ok(r[1].get_region("HomeScrubbyHero").mouse_filter == Control.MOUSE_FILTER_IGNORE and hero.get_gesture_rect().mouse_filter == Control.MOUSE_FILTER_IGNORE, "hero + gesture layer never take input")
	r[0].free()
	await process_frame
	_complete("presentation_only")

func _buttons() -> void:
	print("[Home buttons immediate during gestures]")
	for vp in VIEWPORTS:
		var r = await _home(vp)
		var sub: SubViewport = r[0]
		var home = r[1]
		var hero = r[2]
		var got: Array = []
		home.play_requested.connect(func(): got.append("play"))
		home.shortcut_requested.connect(func(id): got.append(id))
		home.settings_requested.connect(func(): got.append("settings"))
		var top_ok := true
		for g in COUNTS:
			hero.start_gesture(g)
			_run(hero, 0.6)   # mid-gesture
			for n in ["PlayButton", "Shortcut_shop", "Shortcut_collection", "Shortcut_tasks", "Shortcut_daily", "Nav_settings", "ScrubBucksPlus", "HeartsPlus"]:
				var mv := InputEventMouseMotion.new()
				mv.position = _local(home, n).get_center()
				mv.global_position = mv.position
				sub.push_input(mv)
				await process_frame
				var hov: Control = sub.gui_get_hovered_control()
				var ctl: Control = home.get_region(n)
				top_ok = top_ok and hov != null and (hov == ctl or ctl.is_ancestor_of(hov))
			_run(hero, 2.0)
		hero.start_gesture("wave")
		for n in ["PlayButton", "Shortcut_daily", "Nav_settings"]:
			for pressed in [true, false]:
				var e := InputEventMouseButton.new()
				e.button_index = MOUSE_BUTTON_LEFT
				e.pressed = pressed
				e.position = _local(home, n).get_center()
				e.global_position = e.position
				sub.push_input(e)
				await process_frame
			home.close_top_popup()
		_ok(top_ok, "%s every live control stays the top hit during all 4 gestures" % str(vp))
		_ok(got == ["play", "daily", "settings"], "%s Play / DAILY / Settings fire immediately mid-gesture %s" % [str(vp), str(got)])
		sub.free()
		await process_frame
	_complete("buttons_usable")

func _complete(c: String) -> void:
	_completed[c] = true

func _ok_quiet(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: ", msg)

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
	print("m42_c003_scrubby_animation: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
