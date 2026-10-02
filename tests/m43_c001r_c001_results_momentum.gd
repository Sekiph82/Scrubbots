extends SceneTree
## M43-C001R-C001 — Results momentum / Next Cleanup / 10-Level Cleaning Journey evidence
## (SB-M43-R01-001..008). Real app root (main.tscn), real production catalog and previews,
## real terminal WON (economy + progression + save commit in the host BEFORE Results), the
## real Home, and the ONE ResultsMomentum read authority.
##
## Run: godot --headless --path . -s res://tests/m43_c001r_c001_results_momentum.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ResultsMomentum = preload("res://scripts/progression/results_momentum.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const JourneyStrip = preload("res://scripts/ui/components/journey_strip.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const R = NavigationController.Route
const T0 := 1_900_000_000

var EXPECTED_CASES := [
	"t01_next_resolves_frontier", "t02_exact_preview", "t03_crop_deterministic", "t04_crop_in_bounds",
	"t05_fraction_config", "t06_no_full_preview", "t07_difficulty_canonical", "t08_color_count_canonical",
	"t09_missing_frontier_honest", "t10_missing_preview_no_borrow", "t11_level10_no_l11", "t12_t14_ten_nodes_beats",
	"t15_nodes_no_input", "t16_home_frontier_1", "t17_home_frontier_6", "t18_results_l9", "t19_results_l10",
	"t20_home_frontier_11", "t21_injected_l11_cycle_transition", "t22_one_authority", "t23_save_reload",
	"t24_receipt_economy_identical", "t25_row_order", "t26_clean_next_route", "t27_rapid_taps", "t28_stale_attempt",
	"t29_zero_heart", "t30_barrier_holds", "t31_barrier_release_same", "t32_reduced_effects", "t33_responsive",
	"t34_no_accumulation", "t35_malformed_config", "no_manipulation_copy",
	"v02_home_strip_larger", "v02_results_strip_not_smaller", "v02_beat_size_hierarchy", "v02_beat_colors",
	"v02_single_coming_soon", "v02_available_copy_unchanged",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [T0]
var _sub: SubViewport
var _root
var _cat

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	_cat = LevelCatalog.new()
	_ok(_cat.load_manifest().ok and _cat.size() == 10, "production catalog loads (10 entries)")
	await _next_cleanup_cases()
	_crop_cases()
	await _missing_cases()
	await _journey_cases()
	await _t21_injected()
	await _v02_cases()
	await _t22_t23()
	await _corridor_cases()
	await _barrier_cases()
	await _t32_reduced()
	await _t33_responsive()
	await _t34_no_accumulation()
	await _t35_malformed()
	_shutdown()
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _boot(frontier: int, size: Vector2i = Vector2i(1080, 2160), path: String = "") -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	if path.is_empty():
		path = "user://m43c001r_%d.save" % Time.get_ticks_usec()
		_tmp.append(path)
		MainScript.boot_save_path_override = path
		_root = MainScene.instantiate()
		_sub.add_child(_root)
		await process_frame
		_set_frontier(frontier)
		_app().economy.hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})
	else:
		MainScript.boot_save_path_override = path
		_root = MainScene.instantiate()
		_sub.add_child(_root)
		await process_frame
	_root.get_home().refresh()
	await _settle()

## Boot at frontier `level`, play it and commit a real terminal WON -> Results.
func _won(level: int, size: Vector2i = Vector2i(1080, 2160), reduced := false) -> void:
	await _boot(level, size)
	if reduced:
		_app().set_reduced_effects(true)
	_root.play_current_frontier()
	await _settle()
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)
	h.get_completion().terminal_reached.emit(&"WON", {})
	await _settle()

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _app():
	return _root.get_app_state()

func _res():
	return _root.get_results_screen()

func _nav():
	return _root.get_navigation()

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _set_frontier(n: int) -> void:
	_app().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": n, "completed": range(1, n)})

func _momentum() -> Dictionary:
	return _res().get_model().get("momentum", {})

func _entry(order: int):
	for e in _cat.get_entries_ordered():
		if e.order == order:
			return e
	return null

func _econ_snap() -> Dictionary:
	return {"eco": _app().economy.snapshot(), "prog": _app().progression.snapshot()}

func _click(pos: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = pos
		e.global_position = pos
		_sub.push_input(e)
		await process_frame

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

## Non-disclosure probe: every TextureRect under `n` that draws a level preview, and
## whether it shows MORE than the owner envelope (full texture, or an atlas region > 25%).
func _preview_leaks(n: Node) -> Array:
	var leaks: Array = []
	for t in n.find_children("*", "TextureRect", true, false):
		var tex = t.texture
		if tex == null or not t.is_visible_in_tree():
			continue
		if tex is AtlasTexture:
			var a: Texture2D = tex.atlas
			if a != null and a.resource_path.begins_with("res://assets/art/levels/previews/"):
				var frac: float = (tex.region.size.x * tex.region.size.y) / float(a.get_width() * a.get_height())
				if frac > 0.25:
					leaks.append("%s region %.2f" % [t.name, frac])
		elif String(tex.resource_path).begins_with("res://assets/art/levels/previews/"):
			leaks.append("%s full %s" % [t.name, tex.resource_path])
	return leaks

# ======================================================== Next Cleanup ===========

func _next_cleanup_cases() -> void:
	print("[01-02 / 07-08 Next Cleanup = canonical frontier truth]")
	await _won(2)
	var n: Dictionary = _momentum().get("next", {})
	var launch := GameplayLaunchResolver.resolve(_app())
	var e3 = _entry(3)
	_ok(_nav().current() == R.RESULTS and _app().progression.current_level() == 3 and n["available"] and n["level"] == 3
		and n["entry_id"] == launch["entry_id"] and n["entry_id"] == e3.id, "WON L2 -> teaser = frontier L3 (%s), same entry as the Continue resolver" % n["entry_id"])
	_complete("t01_next_resolves_frontier")
	var tex = _res().get_teaser_image().texture
	_ok(n["preview_path"] == e3.preview_path and tex is AtlasTexture and tex.atlas.resource_path == e3.preview_path, "teaser binds exactly %s (cropped AtlasTexture)" % e3.preview_path)
	_complete("t02_exact_preview")
	var facts: String = _res().find_child("NextFacts", true, false).text
	_ok(n["difficulty"] == e3.difficulty and e3.difficulty == _app().progression.class_for(3)
		and facts.begins_with(UiText.t("DIFFICULTY_" + e3.difficulty)), "difficulty %s = catalog/LevelData token = cadence class; shown '%s'" % [e3.difficulty, facts])
	_complete("t07_difficulty_canonical")
	var md = JSON.parse_string(FileAccess.get_file_as_string(e3.metadata_path))
	var lvl = LevelLoader.load_from_path(e3.level_path).level_data
	_ok(n["color_count"] == lvl.palette.size() and n["color_count"] == int(md["usedColorCount"]) and facts.find(str(n["color_count"])) != -1,
		"colour count %d = LevelData palette = metadata usedColorCount" % n["color_count"])
	_complete("t08_color_count_canonical")

func _crop_cases() -> void:
	print("[03-05 crop determinism / bounds / fraction]")
	var cfg := ResultsMomentum.load_config()
	_ok(cfg["ok"] and is_equal_approx(cfg["fraction"], 0.20) and cfg["fraction_min"] >= 0.15 and cfg["fraction_max"] <= 0.25, "config V1 fraction 0.20 within 0.15..0.25")
	var det := true
	var bounds := true
	var frac_ok := true
	var rows: Array = []
	for e in _cat.get_entries_ordered():
		var img: Image = (load(e.preview_path) as Texture2D).get_image()
		var a := ResultsMomentum.crop_rect(img, e.id, cfg["fraction"])
		var b := ResultsMomentum.crop_rect((load(e.preview_path) as Texture2D).get_image(), e.id, cfg["fraction"])
		det = det and a == b
		bounds = bounds and Rect2i(0, 0, img.get_width(), img.get_height()).encloses(a)
		var f := float(a.size.x * a.size.y) / float(img.get_width() * img.get_height())
		frac_ok = frac_ok and f >= 0.15 and f <= 0.25
		rows.append("%s %dx%d crop=%s frac=%.3f" % [e.id, img.get_width(), img.get_height(), str(a), f])
	for r in rows:
		print("    " + r)
	var nc1 := ResultsMomentum.next_cleanup({"ok": true, "level": 3, "entry_id": _entry(3).id, "difficulty": "MEDIUM", "level_path": _entry(3).level_path, "preview_path": _entry(3).preview_path}, cfg)
	var nc2 := ResultsMomentum.next_cleanup({"ok": true, "level": 3, "entry_id": _entry(3).id, "difficulty": "MEDIUM", "level_path": _entry(3).level_path, "preview_path": _entry(3).preview_path}, cfg)
	_ok(det and nc1 == nc2, "same stable id + image -> same crop (10 levels, and the read model)")
	_complete("t03_crop_deterministic")
	_ok(bounds, "every crop inside its texture bounds")
	_complete("t04_crop_in_bounds")
	_ok(frac_ok, "every real crop shows 15..25% of its preview")
	_complete("t05_fraction_config")

# ======================================================= missing content =========

func _missing_cases() -> void:
	print("[09-11 missing frontier / preview]")
	await _won(10)
	var n: Dictionary = _momentum().get("next", {})
	var res = _res()
	_ok(not n["available"] and n["level"] == 11 and n["reason"] == GameplayLaunchResolver.CONTENT_MISSING and res.get_teaser_image().texture == null
		and res.find_child("TeaserUnavailable", true, false).visible and res.find_child("NextFacts", true, false).text == UiText.t("NEXT_CLEANUP_SOON"),
		"frontier L11 absent: honest coming-soon, no image")
	_complete("t09_missing_frontier_honest")
	_ok(res.get_primary_button().text == UiText.t("RESULTS_CLEAN_NEXT") and res.get_primary_button().disabled and _root.continue_from_results().get("reason") == "no_next_content"
		and _nav().current() == R.RESULTS, "Level 10 production: CLEAN NEXT disabled, cannot launch a fake L11")
	_ok(not res.get_home_button().disabled, "Home stays usable")
	_complete("t11_level10_no_l11")
	var cfg := ResultsMomentum.load_config()
	var base := {"ok": true, "level": 3, "entry_id": "x", "difficulty": "MEDIUM", "level_path": _entry(3).level_path}
	var no_path := ResultsMomentum.next_cleanup(base.merged({"preview_path": ""}), cfg)
	var bad_path := ResultsMomentum.next_cleanup(base.merged({"preview_path": "res://assets/art/levels/previews/does_not_exist.png"}), cfg)
	_ok(no_path["available"] and not no_path["image_ok"] and not bad_path["image_ok"] and bad_path["crop"] == Rect2i(), "missing / unknown preview -> no image (no fallback)")
	var m: Dictionary = res.get_model()
	m["status"] = "WON"
	m["momentum"] = {"ok": true, "journey": _momentum().get("journey"), "next": bad_path}
	res.show_model(m)
	_ok(res.get_teaser_image().texture == null and res.find_child("TeaserUnavailable", true, false).visible and _preview_leaks(res).is_empty(), "UI: no preview art from any other level")
	var own := true
	for e in _cat.get_entries_ordered():
		var nc := ResultsMomentum.next_cleanup({"ok": true, "level": e.order, "entry_id": e.id, "difficulty": e.difficulty, "level_path": e.level_path, "preview_path": e.preview_path}, cfg)
		own = own and nc["preview_path"] == e.preview_path
	_ok(own, "every level's teaser path is its own catalog preview")
	_complete("t10_missing_preview_no_borrow")

# ================================================================ V02 ============

## V01 reference geometry (owner V02 asked for a materially larger Journey).
const V01_HOME_STRIP := Vector2(560, 58)
const V01_HOME_NODE := 39.4      ## 2 * min(58 * 0.34, 56 * 0.36)
const V01_RESULTS_H := 56.0
const V01_RESULTS_NODE := 38.0

func _nodes_ok(strip) -> Array:
	var bad: Array = []
	var r: Array = strip.node_rects()
	var box := Rect2(Vector2.ZERO, strip.size)
	for i in range(r.size()):
		var drawn: Rect2 = (r[i] as Rect2).grow(JourneyStrip.RIM)   # diamond / ring rim
		if not box.grow(0.5).encloses(drawn):
			bad.append("node %d outside strip" % (i + 1))
		if i < r.size() - 1 and drawn.intersects((r[i + 1] as Rect2).grow(JourneyStrip.RIM)):
			bad.append("nodes %d/%d overlap" % [i + 1, i + 2])
	return bad

func _v02_cases() -> void:
	print("[V02 owner remediation: strip size, beat hierarchy, single coming-soon]")
	await _boot(6)
	var strip = _root.get_home().get_journey_strip()
	var r: Array = strip.node_rects()
	_ok(strip.size.x >= V01_HOME_STRIP.x * 1.2 and strip.size.y >= V01_HOME_STRIP.y * 1.3, "Home strip %s vs V01 %s (>= +20%% wide, +30%% tall)" % [str(strip.size), str(V01_HOME_STRIP)])
	_ok(r[0].size.x >= V01_HOME_NODE * 1.15 and r[6].size.x >= V01_HOME_NODE * 1.15, "ordinary node %.1f px vs V01 %.1f px" % [r[0].size.x, V01_HOME_NODE])
	_ok(strip.get_parent() == _root.get_home().get_region("PlayButton") and strip.get_global_rect().end.y <= _root.get_home().get_region("PlayButton").get_global_rect().position.y, "Home strip still directly above PLAY")
	_complete("v02_home_strip_larger")
	var mini: float = r[4].size.x
	var boss: float = r[9].size.x
	_ok(mini >= r[0].size.x * 1.25 and mini >= r[6].size.x * 1.25, "mini-boss %.1f px > ordinary complete %.1f / future %.1f" % [mini, r[0].size.x, r[6].size.x])
	_ok(boss >= mini * 1.15, "boss %.1f px > mini-boss %.1f px" % [boss, mini])
	_ok(r[5].size.x < mini, "current ordinary node (%.1f) never outranks a beat" % r[5].size.x)
	var bad := _nodes_ok(strip)
	await _boot(10)
	var r10: Array = _root.get_home().get_journey_strip().node_rects()
	_ok(r10[9].size.x > r10[4].size.x and r10[4].size.x > r10[0].size.x, "Home frontier 10 (boss current): boss > mini > ordinary")
	bad.append_array(_nodes_ok(_root.get_home().get_journey_strip()))
	await _won(9)
	var rs = _res().get_journey_strip()
	var rr: Array = rs.node_rects()
	_ok(rs.size.y >= V01_RESULTS_H and rr[0].size.x >= V01_RESULTS_NODE, "Results strip %s, ordinary node %.1f px (V01 h 56 / %.0f px)" % [str(rs.size), rr[0].size.x, V01_RESULTS_NODE])
	_complete("v02_results_strip_not_smaller")
	_ok(rr[4].size.x >= rr[0].size.x * 1.25 and rr[9].size.x >= rr[4].size.x * 1.15, "Results: mini-boss > ordinary, boss > mini-boss")
	bad.append_array(_nodes_ok(rs))
	_ok(bad.is_empty(), "all nodes inside their strip, neighbours never overlap %s" % str(bad))
	_complete("v02_beat_size_hierarchy")
	_ok(JourneyStrip.MINI_EDGE == Color(1.0, 0.55, 0.12) and JourneyStrip.BOSS_EDGE == Color(0.86, 0.13, 0.20) and JourneyStrip.BEAT_SCALE["mini_boss"] < JourneyStrip.BEAT_SCALE["boss"],
		"slot 5 orange / slot 10 red unchanged")
	_complete("v02_beat_colors")
	await _won(10)
	var res = _res()
	var soon: Array = res.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree() and l.text.to_lower().find("coming soon") != -1)
	_ok(soon.size() == 1 and soon[0].name == "NextFacts" and soon[0].text == UiText.t("NEXT_CLEANUP_SOON"), "L10: exactly one coming-soon message, in the Next Cleanup card %s" % str(soon.map(func(l): return l.name)))
	_ok(not res.get_note_label().visible and res.get_note_label().text.is_empty(), "older duplicate note above CLEAN NEXT is suppressed")
	_ok(res.get_primary_button().disabled and res.get_primary_button().text == UiText.t("RESULTS_CLEAN_NEXT") and not res.get_home_button().disabled
		and res.get_model()["continue"]["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "CLEAN NEXT disabled, Home usable, CONTENT_MISSING truth unchanged")
	var m: Dictionary = res.get_model()
	m.erase("momentum")   # no Next Cleanup card (e.g. malformed config) -> the honest note returns
	res.show_model(m)
	_ok(res.get_note_label().visible and res.get_note_label().text == UiText.t("RESULTS_NEXT_UNAVAILABLE", [11]), "without the card, the unavailable note is still shown (scoped suppression)")
	_complete("v02_single_coming_soon")
	await _won(4)
	res = _res()
	_ok(not res.get_note_label().visible and res.find_child("NextFacts", true, false).text == UiText.t("NEXT_CLEANUP_FACTS", [UiText.t("DIFFICULTY_HARD"), 10])
		and not res.get_primary_button().disabled, "available-next Results copy unchanged (no note, HARD · 10 colours, CLEAN NEXT live)")
	_complete("v02_available_copy_unchanged")

# ================================================================ journey ========

func _journey_cases() -> void:
	print("[12-20 Cleaning Journey]")
	var cfg := ResultsMomentum.load_config()
	await _boot(1)
	var j: Dictionary = _root.get_home().get_journey_strip().get_model()
	_ok(j["ok"] and j["nodes"].size() == 10 and _root.get_home().get_journey_strip().node_rects().size() == 10, "exactly 10 nodes (model + drawn)")
	var beats: Array = j["nodes"].map(func(nd): return nd["beat"])
	_ok(beats.count("mini_boss") == 1 and j["nodes"][4]["beat"] == "mini_boss", "slot 5 = mini-boss beat")
	_ok(beats.count("boss") == 1 and j["nodes"][9]["beat"] == "boss", "slot 10 = cycle-boss beat")
	var classes: Array = j["nodes"].map(func(nd): return nd["class"])
	var want: Array = range(1, 11).map(func(l): return _app().progression.class_for(l))
	_ok(classes == want and classes[4] == "HARD" and classes[9] == "VERY_HARD", "node classes from progression cadence %s" % str(classes))
	_complete("t12_t14_ten_nodes_beats")
	var strip = _root.get_home().get_journey_strip()
	var nav0: int = _nav().transition_id()
	var p0: Dictionary = _app().progression.snapshot()
	for r in strip.node_rects():
		await _click(strip.get_global_transform() * (r as Rect2).get_center())
	_ok(strip.mouse_filter == Control.MOUSE_FILTER_IGNORE and strip.focus_mode == Control.FOCUS_NONE and strip.get_child_count() == 0
		and strip.find_children("*", "BaseButton", true, false).is_empty(), "strip: one drawn Control, ignores mouse, no focus, no buttons")
	_ok(_nav().transition_id() == nav0 and _app().progression.snapshot() == p0 and _nav().current() == R.HOME, "clicking every node: no navigation / skip / unlock")
	_complete("t15_nodes_no_input")
	_ok(j["cycle"] == 1 and j["slot"] == 1 and j["completed"] == 0 and j["nodes"][0]["state"] == "current"
		and j["nodes"].slice(1).all(func(nd): return nd["state"] == "future"), "Home frontier 1: slot 1 current, nothing complete")
	_complete("t16_home_frontier_1")
	await _boot(6)
	j = _root.get_home().get_journey_strip().get_model()
	_ok(j["completed"] == 5 and j["nodes"].slice(0, 5).all(func(nd): return nd["state"] == "complete") and j["nodes"][5]["state"] == "current"
		and j["nodes"].slice(6).all(func(nd): return nd["state"] == "future"), "Home frontier 6: 1..5 complete, 6 current")
	_complete("t17_home_frontier_6")
	await _won(9)
	j = _momentum()["journey"]
	var n: Dictionary = _momentum()["next"]
	_ok(j["context"] == "results" and j["completed"] == 9 and j["nodes"][9]["state"] == "next" and n["level"] == 10 and n["available"] and n["entry_id"] == _entry(10).id,
		"Results L9: 1..9 complete, slot 10 next, teaser L10 (boss)")
	_ok(_res().find_child("JourneyCaption", true, false).text == UiText.t("JOURNEY_CAPTION", [9, 10]), "caption 9/10")
	_complete("t18_results_l9")
	await _won(10)
	j = _momentum()["journey"]
	_ok(j["completed"] == 10 and j["nodes"].all(func(nd): return nd["state"] == "complete") and j["cycle"] == 1, "Results L10: 10/10 complete")
	_complete("t19_results_l10")
	await _boot(11)
	j = _root.get_home().get_journey_strip().get_model()
	_ok(j["cycle"] == 2 and j["slot"] == 1 and j["completed"] == 0 and j["nodes"][0]["state"] == "current" and j["nodes"][0]["level"] == 11 and j["nodes"][9]["level"] == 20,
		"Home frontier 11: new cycle 2, slot 1 (L11) current, nodes 11..20")
	_ok(ResultsMomentum.cycle_of(10) == 1 and ResultsMomentum.slot_of(10) == 10 and ResultsMomentum.cycle_of(11) == 2 and ResultsMomentum.slot_of(11) == 1
		and ResultsMomentum.cycle_of(311) == 32 and ResultsMomentum.slot_of(311) == 1 and ResultsMomentum.slot_of(1000) == 10, "cycle math 10 / 11 / 311 / 1000")
	_complete("t20_home_frontier_11")

func _t21_injected() -> void:
	print("[21 injected Level 11 content: 10 -> next-cycle transition]")
	await _boot(11)
	var stub := InjectedCatalog.new(_cat, _entry(2), 11)
	var launch := GameplayLaunchResolver.resolve(_app(), stub)
	var cfg := ResultsMomentum.load_config()
	var rm := ResultsMomentum.results_model(_app(), 10, launch, cfg)
	_ok(launch["ok"] and launch["level"] == 11 and rm["next"]["available"] and rm["next"]["entry_id"] == "test_injected_l11" and rm["next"]["image_ok"]
		and rm["journey"]["completed"] == 10, "Results L10 + injected L11: 10/10, teaser L11 available (test-only entry)")
	var hj := ResultsMomentum.home_journey(_app(), cfg)
	_ok(hj["cycle"] == 2 and hj["slot"] == 1 and hj["nodes"][0]["state"] == "current", "next Home frontier 11: cycle 2 slot 1 current")
	_ok(not GameplayLaunchResolver.resolve(_app())["ok"], "production catalog itself still has no L11 (nothing hardcoded)")
	_complete("t21_injected_l11_cycle_transition")

class InjectedCatalog extends RefCounted:
	var _entries: Array = []
	func _init(cat, source, order: int) -> void:
		_entries = cat.get_entries_ordered()
		var e = source.duplicate()
		e.id = "test_injected_l11"
		e.order = order
		_entries.append(e)
	func get_entries_ordered() -> Array:
		return _entries

func _t22_t23() -> void:
	print("[22-23 one authority / save-reload continuity]")
	await _won(5)
	var cfg: Dictionary = _root.momentum_cfg
	var rj: Dictionary = _momentum()["journey"]
	_ok(rj == ResultsMomentum.journey(_app().progression, "results", 5, cfg) and _res().get_journey_strip().get_model() == rj, "Results strip = ResultsMomentum.journey(results, 5)")
	_res().get_home_button().pressed.emit()
	await _settle()
	var hj: Dictionary = _root.get_home().get_journey_strip().get_model()
	_ok(hj == ResultsMomentum.home_journey(_app(), cfg) and _root.get_home().get_journey_strip().get_script() == _res().get_journey_strip().get_script()
		and hj["slot"] == 6 and hj["completed"] == 5, "Home strip = ResultsMomentum.home_journey (frontier 6); same JourneyStrip component")
	_complete("t22_one_authority")
	var path: String = MainScript.boot_save_path_override
	_app().flush()
	var app2 := AppState.new(path, func(): return _now[0])
	var j2 := ResultsMomentum.home_journey(app2, cfg)
	_ok(j2 == hj, "relaunch from the saved progression reproduces the same journey")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	_ok(typeof(saved) == TYPE_DICTIONARY and JSON.stringify(saved).find("journey") == -1 and JSON.stringify(saved).find("momentum") == -1, "save file holds no journey / momentum state")
	app2.economy.dispose()
	_complete("t23_save_reload")

# ============================================================== corridor =========

func _corridor_cases() -> void:
	print("[24-29 corridor / CLEAN NEXT]")
	await _won(3)
	var res = _res()
	var host = _root.get_gameplay_host()
	var rc0: Dictionary = host.get_terminal_receipt()
	var e0 := _econ_snap()
	for _i in range(3):
		res.show_model(res.get_model())
		res.finish_reveal()
	res.set_ceremony_barrier("t", true)
	res.set_ceremony_barrier("t", false)
	_root.get_home().refresh()
	await _settle()
	_ok(host.get_terminal_receipt() == rc0 and _econ_snap() == e0, "receipt + economy + progression identical after repeated teaser/journey rendering")
	_complete("t24_receipt_economy_identical")
	_ok(res.shown_row_texts() == ResultsScreen.reward_lines(rc0) and res.get_reward_lines_node().get_index() < res.get_momentum_section().get_index()
		and res.get_momentum_section().get_index() < res.get_primary_button().get_index(), "rows = receipt order; rows -> journey/teaser -> CLEAN NEXT -> Home")
	_complete("t25_row_order")
	var attempt: int = int(res.get_payload()["attempt"])
	_ok(_root.continue_from_results(attempt - 1).get("reason") == "stale_results" and _nav().current() == R.RESULTS, "stale Results attempt cannot launch")
	_complete("t28_stale_attempt")
	_app().economy.hearts.import_snapshot({"hearts": 0, "anchor": _now[0]})
	var t0: int = _nav().transition_id()
	res.get_primary_button().pressed.emit()
	await _settle()
	_ok(_root.get_modal_stack().ids() == ["life"] and _nav().current() == R.RESULTS and _nav().transition_id() == t0, "0 Hearts: CLEAN NEXT opens Life, launches nothing")
	_complete("t29_zero_heart")
	_root.get_modal_stack().clear("t")
	_app().economy.hearts.import_snapshot({"hearts": 5, "anchor": _now[0]})
	await _settle()
	_ok(res.get_primary_button().text == UiText.t("RESULTS_CLEAN_NEXT") and not res.get_primary_button().disabled
		and res.continue_requested.is_connected(_root.continue_from_results), "CLEAN NEXT is the existing Continue intent (continue_requested -> continue_from_results)")
	t0 = _nav().transition_id()
	for _i in range(5):
		res.get_primary_button().pressed.emit()
	await _settle()
	_ok(_nav().current() == R.GAMEPLAY and _nav().transition_id() == t0 + 1 and _root.get_gameplay_host().progression_level == 4, "5 rapid CLEAN NEXT taps -> exactly one launch, Level 4")
	_complete("t26_clean_next_route")
	_complete("t27_rapid_taps")

func _barrier_cases() -> void:
	print("[30-31 ceremony barrier seam]")
	await _won(4)
	var res = _res()
	res.finish_reveal()
	var region: Rect2 = res.get_teaser_image().texture.region
	var e0 := _econ_snap()
	res.set_ceremony_barrier("future_c005", true)
	var t0: int = _nav().transition_id()
	res.get_primary_button().pressed.emit()
	await _settle()
	_ok(res.has_ceremony_barrier() and not res.get_next_cleanup_panel().is_visible_in_tree() and res.get_primary_button().disabled
		and _nav().transition_id() == t0 and _nav().current() == R.RESULTS, "barrier: teaser + CLEAN NEXT held, tap does nothing")
	_ok(res.get_journey_strip().is_visible_in_tree() and not res.get_home_button().disabled, "journey summary + Home stay available")
	_complete("t30_barrier_holds")
	res.set_ceremony_barrier("future_c005", false)
	await _settle()
	_ok(not res.has_ceremony_barrier() and res.get_next_cleanup_panel().is_visible_in_tree() and res.get_teaser_image().texture.region == region
		and not res.get_primary_button().disabled and _econ_snap() == e0, "release: same resolved teaser, CLEAN NEXT live, no state change")
	res.set_ceremony_barrier("a", true)
	res.set_ceremony_barrier("b", true)
	res.set_ceremony_barrier("a", false)
	_ok(res.get_primary_button().disabled, "held while any barrier remains")
	res.set_ceremony_barrier("b", false)
	_complete("t31_barrier_release_same")

func _t32_reduced() -> void:
	print("[06 / 32 non-disclosure across the reveal; Reduced Effects]")
	await _won(2)
	var res = _res()
	var leaks: Array = []
	var revealed := false
	for _i in range(120):   # every frame of the normal reveal
		leaks.append_array(_preview_leaks(_root))
		revealed = revealed or res.is_revealing()
		await process_frame
	leaks.append_array(_preview_leaks(_root))
	var normal_model: Dictionary = _momentum()
	await _won(2, Vector2i(1080, 2160), true)
	res = _res()
	_ok(not res.is_revealing() and res.get_momentum_section().modulate.a == 1.0 and res.get_next_cleanup_panel().is_visible_in_tree(), "Reduced Effects: final momentum content immediately")
	_ok(_momentum()["journey"] == normal_model["journey"] and _momentum()["next"] == normal_model["next"], "Reduced Effects: identical journey / teaser truth")
	for _i in range(10):
		leaks.append_array(_preview_leaks(_root))
		await process_frame
	_ok(revealed and leaks.is_empty(), "no frame (normal reveal or Reduced) draws more than the crop %s" % str(leaks))
	# Sensitivity: the probe must flag a planted full preview and an over-large region.
	var plant := TextureRect.new()
	plant.texture = load(_entry(3).preview_path)
	res.get_panel().add_child(plant)
	var at := AtlasTexture.new()
	at.atlas = load(_entry(3).preview_path)
	at.region = Rect2(0, 0, 30, 30)
	var plant2 := TextureRect.new()
	plant2.texture = at
	res.get_panel().add_child(plant2)
	_ok(_preview_leaks(res).size() == 2, "probe sensitivity: a full preview and a 30x30 region are both flagged")
	plant.free()
	plant2.free()
	_complete("t06_no_full_preview")
	_complete("t32_reduced_effects")

func _t33_responsive() -> void:
	print("[33 responsive: Results + Home]")
	for sz in [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 1920), Vector2i(1536, 2048)]:
		var bad: Array = []
		for lvl in [4, 10]:
			await _won(lvl, sz)
			var res = _res()
			res.finish_reveal()
			await _settle()
			var vp := Rect2(Vector2.ZERO, Vector2(sz))
			var panel: Rect2 = res.get_panel().get_global_rect()
			for c in [res.get_panel(), res.get_robot(), res.get_primary_button(), res.get_home_button()]:
				if not vp.encloses(c.get_global_rect()):
					bad.append("L%d %s" % [lvl, c.name])
			for c in [res.get_journey_strip(), res.get_next_cleanup_panel()]:
				if not panel.encloses(c.get_global_rect()):
					bad.append("L%d %s outside panel" % [lvl, c.name])
			for l in res.get_momentum_section().find_children("*", "Label", true, false):
				if l.is_visible_in_tree() and l.get_minimum_size().y > l.size.y + 0.5:
					bad.append("L%d clipped %s" % [lvl, l.name])
			if res.get_primary_button().size.y < UiTokens.TOUCH_MIN or res.get_home_button().size.y < UiTokens.TOUCH_MIN:
				bad.append("touch")
		await _boot(6, sz)
		var home = _root.get_home()
		var strip: Rect2 = home.get_journey_strip().get_global_rect()
		var safe: Rect2 = home.get_region("SafeAreaRoot").get_global_rect()
		if not safe.grow(0.5).encloses(strip):
			bad.append("home strip outside safe area")
		for region in ["PlayButton", "TrackPanel", "BottomNav", "GiftMeter", "AdBannerSlot", "TopCurrencyHUD", "Shortcut_shop", "Shortcut_collection", "Shortcut_tasks", "Shortcut_daily"]:
			var rr: Rect2 = home.get_region(region).get_global_rect()
			if rr.intersects(strip):
				bad.append("home strip x " + region)
		_ok(bad.is_empty(), "%dx%d: Results (L4 teaser, L10 coming soon) + Home strip fit, no collisions %s" % [sz.x, sz.y, str(bad)])
	_complete("t33_responsive")

func _t34_no_accumulation() -> void:
	print("[34 repeated show / hide / refresh]")
	await _won(2)
	var res = _res()
	var home = _root.get_home()
	var model: Dictionary = res.get_model()
	res.finish_reveal()
	await _settle()
	var n0 := _count(_root)
	var timers: int = _root.find_children("*", "Timer", true, false).size()
	var c0: int = res.continue_requested.get_connections().size()
	for _i in range(20):
		res.visible = false
		res.visible = true
		res.show_model(model)
		res.set_ceremony_barrier("x", true)
		res.set_ceremony_barrier("x", false)
		res.finish_reveal()
		home.refresh()
		await process_frame
	await _settle()
	_ok(_count(_root) == n0 and _root.find_children("*", "Timer", true, false).size() == timers and res.continue_requested.get_connections().size() == c0,
		"20 cycles: nodes %d -> %d, timers / connections stable" % [n0, _count(_root)])
	_complete("t34_no_accumulation")

func _t35_malformed() -> void:
	print("[35 malformed momentum config fails closed]")
	var bad_cases := {
		"fraction_0_5": {"teaser": {"visible_area_fraction": 0.5}},
		"fraction_0_10": {"teaser": {"visible_area_fraction": 0.10}},
		"envelope_widened": {"teaser": {"visible_area_fraction_max": 0.4}},
		"cycle_9": {"journey": {"cycle_length": 9}},
		"boss_slot_7": {"journey": {"boss_slot": 7}},
		"mode_full": {"teaser": {"reveal_mode": "full"}},
		"nan": {"teaser": {"visible_area_fraction": "NaN"}},
	}
	var base = JSON.parse_string(FileAccess.get_file_as_string(ResultsMomentum.DEFAULT_CONFIG))
	var all_closed := true
	for k in bad_cases:
		var d = base.duplicate(true)
		for sec in bad_cases[k]:
			d[sec].merge(bad_cases[k][sec], true)
		var p := "user://m43c001r_bad_%s.json" % k
		var f := FileAccess.open(p, FileAccess.WRITE)
		f.store_string(JSON.stringify(d))
		f.close()
		_tmp.append(p)
		all_closed = all_closed and not ResultsMomentum.load_config(p)["ok"]
	all_closed = all_closed and not ResultsMomentum.load_config("res://data/config/missing_results_momentum.json")["ok"]
	_ok(all_closed, "fraction 0.5 / 0.10 / widened envelope / cycle 9 / boss 7 / mode full / NaN / missing -> fail closed")
	await _boot(4)
	_root.set_momentum_config(ResultsMomentum.load_config("user://m43c001r_bad_fraction_0_5.json"))
	await _settle()
	_ok(not _root.get_home().get_journey_strip().visible and not _root.get_home().get_region("PlayButton").disabled, "Home: no strip, PLAY still works")
	_root.play_current_frontier()
	await _settle()
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)
	h.get_completion().terminal_reached.emit(&"WON", {})
	await _settle()
	_ok(_nav().current() == R.RESULTS and not _res().get_momentum_section().visible and _preview_leaks(_res()).is_empty() and not _res().get_primary_button().disabled, "Results: no momentum section, CLEAN NEXT still live")
	_res().get_primary_button().pressed.emit()
	await _settle()
	_ok(_nav().current() == R.GAMEPLAY and _root.get_gameplay_host().progression_level == 5, "ordinary Continue navigation unaffected")
	_complete("t35_malformed_config")
	# Copy guard: momentum text carries only canonical facts.
	var banned := ["ALMOST", "LUCKY", "JACKPOT", "HURRY", "FREE", "REWARD", "GUARANTEE", "LAST CHANCE"]
	var texts: Array = []
	for key in ["JOURNEY_CAPTION", "NEXT_CLEANUP_TITLE", "NEXT_CLEANUP_LEVEL", "NEXT_CLEANUP_FACTS", "NEXT_CLEANUP_SOON", "RESULTS_CLEAN_NEXT"]:
		texts.append(UiText.EN[key].to_upper())
	var hit := banned.filter(func(b): return " ".join(texts).find(b) != -1)
	_ok(hit.is_empty(), "no near-miss / urgency / reward-promise copy %s" % str(hit))
	_complete("no_manipulation_copy")

# ------------------------------------------------------------------ helpers ----

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M43-C001R-C001 results momentum evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
