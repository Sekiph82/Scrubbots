extends SceneTree
## SB-M54-038 GameFeelFlow / Saltmire Spark runtime visual regression pack. The REAL app root
## (main.tscn, 1080x2160 SubViewport, throw-away saves, injected clock / day) with the INSTALLED
## plugins (no test backends) renders three representative effects in three arms:
##   win  real Level 1 WON -> Results WIN confetti on the robot slot (Control target, Spark)
##   set  Set Complete ceremony -> REWARD pickup on the popup HeroArt (Spark moved into the
##        ModalStack CanvasLayer: it must render above the scrim)
##   gff  a Node2D probe (magenta square on its own CanvasLayer) -> MAJOR_REWARD: GFF
##        punch_scale + Spark confetti (no shipping GFF target exists: GFF only drives Node2D)
## arms: FULL, REDUCED (Reduced Effects), DISABLED (GameFeelFlow + Spark autoloads detached).
## Each capture freezes the tree (paused), renders A (bursts shown) and B (the effect's own
## bursts hidden) and A again; ink = pixels where A != B near the target. Checked against the
## committed baseline numbers below (coarse, with tolerance; no image baselines in git):
##   FULL: ink pixel count inside its band, ink centred on the target, probe punched (bbox grew);
##   REDUCED / DISABLED: no burst, no ink, probe bbox unchanged;
##   every arm: B's coarse 8-bin luminance histogram within HIST_TOL of the committed one;
##   frozen frame: A == A again (the capture itself is deterministic);
##   after the ceilings: every burst freed in its tier duration, no emitter left, probe scale 1
##   and its rendered bbox == before, Results / hero scale 1; no one-shot key twice and authority
##   truth identical in every arm (the harness triggers no extra grant / event).
## Needs a rendering driver: run WITHOUT --headless; headless prints NOT_RUN and exits 1.
## `-- --evidence=<abs dir>` also writes the A frames as PNG; `-- --rebaseline` prints the
## measured numbers to paste into BASE (owner gate only when visible behaviour changes on purpose).
## Run: godot --path . -s res://tests/m54_visual_regression_038.gd   (windowed, ~1 min, local only)

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")

const ARMS := ["FULL", "REDUCED", "DISABLED"]
const CAPTURE_FRAMES := 6     ## frames between the effect's request and its capture
const HIST_TOL := 0.06        ## L1 distance of the 8-bin luminance histograms (sum of |a-b|)
const CENTRE_TOL := 40.0      ## px between the ink bbox centre and the target centre
const REGION := 360           ## half-size of the ink window around the target (px)
## Committed baseline: FULL ink band [min, max] px and B histogram per effect + arm.
const BASE := {
	"win:FULL": {"ink": [910, 2913], "hist": [0.408, 0.142, 0.091, 0.041, 0.014, 0.007, 0.007, 0.291]},
	"win:REDUCED": {"hist": [0.565, 0.083, 0.075, 0.047, 0.022, 0.045, 0.017, 0.146]},
	"win:DISABLED": {"hist": [0.408, 0.142, 0.091, 0.041, 0.014, 0.008, 0.006, 0.292]},
	"set:FULL": {"ink": [171, 548], "hist": [0.275, 0.212, 0.148, 0.045, 0.033, 0.045, 0.028, 0.213]},
	"set:REDUCED": {"hist": [0.287, 0.217, 0.147, 0.042, 0.033, 0.048, 0.032, 0.194]},
	"set:DISABLED": {"hist": [0.275, 0.213, 0.148, 0.044, 0.034, 0.045, 0.028, 0.213]},
	"gff:FULL": {"ink": [835, 2673], "hist": [0.192, 0.15, 0.16, 0.128, 0.112, 0.1, 0.085, 0.074]},
	"gff:REDUCED": {"hist": [0.192, 0.15, 0.16, 0.128, 0.112, 0.1, 0.085, 0.074]},
	"gff:DISABLED": {"hist": [0.192, 0.15, 0.16, 0.128, 0.112, 0.1, 0.085, 0.074]},
}

var EXPECTED_CASES := ["v01_full", "v02_reduced", "v03_disabled", "v04_cross_arm"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _emitters: Array = []   ## WeakRef Spark emitters
var _evidence := ""
var _rebaseline := false
var _measured: Dictionary = {}
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	if DisplayServer.get_name() == "headless":
		print("M54 visual regression 038: NOT_RUN (needs a rendering driver; run without --headless)")
		quit(1)
		return
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--evidence="):
			_evidence = String(a).trim_prefix("--evidence=")
		elif a == "--rebaseline":
			_rebaseline = true
	AppState.test_unlock_all = true
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	MainScript.boot_opening_override = 0
	node_added.connect(_on_node_added)
	var seed := _uniq("seed")
	var s = AppState.new(seed, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(bool(s.request_save().get("ok", false)), "seed save written (same profile for every arm)")
	var bytes := FileAccess.get_file_as_bytes(seed)
	var res := {}
	for i in range(ARMS.size()):
		var arm: String = ARMS[i]
		print("[%s %s: win / set / gff rendered]" % [EXPECTED_CASES[i], arm])
		res[arm] = await _run_arm(arm, bytes)
		_complete(EXPECTED_CASES[i])
	print("[v04_cross_arm authority truth and one-shot keys]")
	for arm in ARMS:
		_ok(res[arm]["truth"] == res["FULL"]["truth"], "%s: authority truth == FULL (the harness changed nothing)" % arm)
		_ok(res[arm]["dup"].is_empty(), "%s: no one-shot key requested twice %s" % [arm, str(res[arm]["dup"])])
	_complete("v04_cross_arm")
	if _rebaseline:
		print("REBASELINE const BASE := ", JSON.stringify(_measured, "\t"))
	_shutdown()
	AppState.test_unlock_all = false
	_cleanup()
	_done()

func _on_node_added(n: Node) -> void:
	if n.get_parent() != null and n.get_parent().name == FeedbackAdapter.SPARK_POOL:
		_emitters.append(weakref(n))

# ------------------------------------------------------------------ runner ----

func _run_arm(arm: String, seed_bytes: PackedByteArray) -> Dictionary:
	var save := _uniq(arm)
	var f := FileAccess.open(save, FileAccess.WRITE)
	f.store_buffer(seed_bytes)
	f.close()
	_shutdown()
	_emitters.clear()
	var detached: Array = []
	if arm == "DISABLED":
		for n in [FeedbackAdapter.GFF_AUTOLOAD, FeedbackAdapter.SPARK_AUTOLOAD]:
			var node := get_root().get_node_or_null(n)
			if node != null:
				get_root().remove_child(node)
				detached.append(node)
	await _frames(2)
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = save
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(14)
	_root.get_app_state().set_reduced_effects(arm == "REDUCED")
	var caps: Dictionary = _root.feel.capabilities()
	_ok((caps["gff"] and caps["spark"]) == (arm != "DISABLED"), "%s: installed plugins %s" % [arm, "found" if arm != "DISABLED" else "absent"])
	await _fx_win(arm)
	await _fx_set(arm)
	await _fx_gff(arm)
	await create_timer(1.5).timeout   # > every DURATION_CEILING_S
	_ok(_live() == 0 and _root.feel.owned_count() == 0, "%s: no Spark emitter / adapter-owned work left (%d emitters seen)" % [arm, _emitters.size()])
	var log: Array = _root.feel.dispatch_log().map(func(e): return String(e[1])).filter(func(k): return not k.is_empty())
	var r := {"truth": _truth(), "dup": log.filter(func(k): return log.count(k) > 1)}
	_shutdown()
	for node in detached:
		get_root().add_child(node)
	return r

## Real Level 1 WON -> Results; the WIN confetti on the robot slot.
func _fx_win(arm: String) -> void:
	var n0 := _emitters.size()
	if not _root.play_current_frontier().get("ok", false):
		_ok(false, "%s/win: launch" % arm)
		return
	var host = _root.get_gameplay_host()
	var clicks: Array = []
	if not String(host.supply_plan_path).is_empty():
		clicks = SupplyPlanLoader.load_plan(host.supply_plan_path)["plan"]["intendedColumnClicks"]
	var rt = host.get_runtime()
	rt.set_process(false)
	var input = host.get_input_controller()
	var slots = host.get_slots()
	var i := 0
	var guard := 0
	# Same driver as tests/m43_c005f_phase4_terminal_home_micro.gd (supply-plan clicks + ticks).
	while guard < 200000 and not host.get_completion().is_terminal():
		if slots.rightmost_empty_index() != -1:
			if not clicks.is_empty():
				if i < clicks.size() and input.activate_front(int(clicks[i]) - 1).get("ok", false):
					i += 1
			else:
				for col in range(host.get_supply().get_column_count()):
					if input.activate_front(col).get("ok", false):
						break
		rt.tick(1.0)
		guard += 1
	var res = _root.get_results_screen()
	var slot: Control = res.get_robot().get_parent()
	await _effect(arm, n0, "win", "results:WON:a1:L1:win", "WIN", slot)
	_ok(is_equal_approx(res.get_emblem().scale.x, 1.0) and slot.scale == Vector2.ONE, "%s/win: Results emblem / robot slot back to scale 1" % arm)
	for _f in range(900):
		if not res._reveal.is_active():
			break
		await process_frame
	res.get_home_button().pressed.emit()
	await _frames(14)
	await _drain()

## Set Complete ceremony; the REWARD pickup on its HeroArt, inside the ModalStack layer.
func _fx_set(arm: String) -> void:
	var e = _root.get_app_state().economy
	for k in range(9):
		if e.collection.owned("s1_c%d" % k) == 0:
			e.collection.add_card("s1_c%d" % k)
	var n0 := _emitters.size()
	_root.request_home_ceremonies()
	await _frames(4)
	var p = _root.get_modal_stack().top()
	if p == null or String(p.popup_id) != "ceremony_set_complete":
		_ok(false, "%s/set: ceremony shown" % arm)
		return
	var hero: Control = p.find_child("HeroArt", true, false)
	await _effect(arm, n0, "set", "c005f006:set:1", "REWARD", hero)
	_ok(hero.scale == Vector2.ONE, "%s/set: hero back to scale 1" % arm)
	await _drain()

## Node2D probe on its own CanvasLayer: GFF punch_scale + Spark confetti (MAJOR_REWARD).
func _fx_gff(arm: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	var probe := Sprite2D.new()
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 1))
	probe.texture = ImageTexture.create_from_image(img)
	probe.position = Vector2(540, 420)
	layer.add_child(probe)
	_sub.add_child(layer)
	await _frames(4)
	var before := await _probe_bbox()
	var n0 := _emitters.size()
	_ok(_root.feel.play("MAJOR_REWARD", probe, "m54_038:gff"), "%s/gff: MAJOR_REWARD accepted" % arm)
	var mid := await _effect(arm, n0, "gff", "m54_038:gff", "MAJOR_REWARD", probe)
	var after := await _probe_bbox()
	if arm == "FULL":
		_ok(mid.get("probe", Rect2i()).size.x > before.size.x, "FULL/gff: GFF punch_scale rendered (probe bbox %s -> %s)" % [str(before), str(mid.get("probe"))])
	else:
		_ok(mid.get("probe", Rect2i()) == before, "%s/gff: no punch (probe bbox %s unchanged)" % [arm, str(before)])
	_ok(probe.scale == Vector2.ONE and after == before, "%s/gff: probe restored: scale 1, rendered bbox %s == before %s" % [arm, str(after), str(before)])
	layer.free()

## Wait for `key` (bursts counted from emitter n0), capture CAPTURE_FRAMES later, check against BASE, then the ceiling.
func _effect(arm: String, n0: int, tag: String, key: String, intent: String, target: CanvasItem) -> Dictionary:
	for _f in range(900):
		if _root.feel.has_played(key):
			break
		await process_frame
	_ok(_root.feel.has_played(key), "%s/%s: %s requested" % [arm, tag, key])
	await _frames(CAPTURE_FRAMES)
	var centre: Vector2 = (target as Control).get_global_rect().get_center() if target is Control else (target as Node2D).global_position
	var mine: Array = []
	for i in range(n0, _emitters.size()):
		var em = _emitters[i].get_ref()
		if em != null and (em as Node2D).global_position.distance_to(centre) < 4.0:
			mine.append(em)
	var c := await _capture(tag, arm, mine, centre)
	var b: Dictionary = BASE["%s:%s" % [tag, arm]]
	_measured["%s:%s" % [tag, arm]] = {"hist": c["hist"]} if arm != "FULL" else {"ink": [c["ink"], c["ink"]], "hist": c["hist"]}
	_ok(c["noise"] == 0, "%s/%s: frozen capture is deterministic (A vs A again: %d px)" % [arm, tag, c["noise"]])
	_ok(_hist_dist(c["hist"], b["hist"]) <= HIST_TOL, "%s/%s: frame histogram within %.2f of baseline (%.3f)" % [arm, tag, HIST_TOL, _hist_dist(c["hist"], b["hist"])])
	if arm == "FULL":
		var band: Array = b["ink"]
		_ok(mine.size() == 1, "FULL/%s: one burst at the target centre %s (%d)" % [tag, str(centre), mine.size()])
		_ok(c["ink"] >= band[0] and c["ink"] <= band[1], "FULL/%s: ink %d px in baseline band %s" % [tag, c["ink"], str(band)])
		_ok(c["bbox"].has_area() and Vector2(c["bbox"].get_center()).distance_to(centre) <= CENTRE_TOL, "FULL/%s: ink bbox %s centred on the target %s (rendered above its layer)" % [tag, str(c["bbox"]), str(centre)])
	else:
		_ok(_emitters.size() == n0 and c["ink"] == 0, "%s/%s: no burst, no ink" % [arm, tag])
	await create_timer(float(FeedbackAdapter.DURATION_CEILING_S[intent]) + 0.15).timeout
	_ok(mine.all(func(em): return not is_instance_valid(em)), "%s/%s: its burst freed within the %s ceiling %.1f s" % [arm, tag, intent, FeedbackAdapter.DURATION_CEILING_S[intent]])
	return c

## Freeze, render A / B (`mine` hidden) / A again; measure the window around `centre`.
func _capture(tag: String, arm: String, mine: Array, centre: Vector2) -> Dictionary:
	paused = true
	var a := await _snap()
	for em in mine:
		em.visible = false
	var b := await _snap()
	for em in mine:
		em.visible = true
	var a2 := await _snap()
	var probe := _bbox_of(b, Color(1, 0, 1))
	paused = false
	if not _evidence.is_empty():
		a.save_png(_evidence.path_join("m54_038_%s_%s.png" % [tag, arm]))
	var win := Rect2i(Vector2i(centre) - Vector2i(REGION, REGION), Vector2i(REGION * 2, REGION * 2)).intersection(Rect2i(Vector2i.ZERO, a.get_size()))
	var ink := 0
	var noise := 0
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for y in range(win.position.y, win.end.y):
		for x in range(win.position.x, win.end.x):
			var pa := a.get_pixel(x, y)
			if _differs(pa, a2.get_pixel(x, y)):
				noise += 1
			if _differs(pa, b.get_pixel(x, y)):
				ink += 1
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	var bbox := Rect2i(lo, hi - lo + Vector2i.ONE) if ink > 0 else Rect2i()
	print("  %s/%s: ink %d px bbox %s noise %d" % [arm, tag, ink, str(bbox), noise])
	return {"ink": ink, "bbox": bbox, "noise": noise, "hist": _hist(b), "probe": probe}

func _snap() -> Image:
	await _frames(3)
	return _sub.get_texture().get_image()

func _probe_bbox() -> Rect2i:
	var img := await _snap()
	return _bbox_of(img, Color(1, 0, 1))

## Bounding box of the (exactly) magenta probe pixels.
static func _bbox_of(img: Image, c: Color) -> Rect2i:
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for y in range(0, 900):
		for x in range(200, 880):
			var p := img.get_pixel(x, y)
			if p.r > 0.97 and p.g < 0.03 and p.b > 0.97:
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	return Rect2i(lo, hi - lo + Vector2i.ONE) if hi.x >= 0 else Rect2i()

static func _differs(p: Color, q: Color) -> bool:
	return maxf(maxf(absf(p.r - q.r), absf(p.g - q.g)), absf(p.b - q.b)) > 0.08

## Coarse 8-bin luminance histogram (fractions) of a 108x216 downscale.
static func _hist(img: Image) -> Array:
	var s := img.duplicate() as Image
	s.resize(108, 216, Image.INTERPOLATE_BILINEAR)
	var h := [0, 0, 0, 0, 0, 0, 0, 0]
	for y in range(216):
		for x in range(108):
			h[mini(int(s.get_pixel(x, y).get_luminance() * 8.0), 7)] += 1
	return h.map(func(v): return snappedf(float(v) / (108.0 * 216.0), 0.001))

static func _hist_dist(a: Array, b: Array) -> float:
	if a.size() != b.size():
		return INF
	var d := 0.0
	for i in range(a.size()):
		d += absf(float(a[i]) - float(b[i]))
	return d

func _live() -> int:
	return _emitters.filter(func(w): return w.get_ref() != null).size()

## Acknowledge every ceremony the app shows, by its first CTA.
func _drain() -> void:
	for _i in range(40):
		var p = _root.get_modal_stack().top()
		if p == null or not String(p.popup_id).begins_with("ceremony_"):
			return
		await create_timer(0.45).timeout
		p.get_action_button(p.get_action_ids()[0]).pressed.emit()
		await _frames(14)

# ------------------------------------------------------------------ helpers ----

## Authority truth: economy + progression (wall-clock anchors excluded).
func _truth() -> Dictionary:
	var app = _root.get_app_state()
	var out := {"progression": JSON.stringify(app.progression.snapshot())}
	var s: Dictionary = app.economy.snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	for k in s:
		out["economy." + String(k)] = JSON.stringify(s[k])
	return out

func _uniq(tag: String) -> String:
	var p := "user://m54_038_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	MainScript.boot_opening_override = -1
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))

func _ok(c: bool, msg: String) -> void:
	if c:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(id: String) -> void:
	_completed[id] = true

func _done() -> void:
	var missing := EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	for m in missing:
		_fail += 1
		print("  FAIL: case did not complete: " + m)
	print("M54 visual regression 038: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
