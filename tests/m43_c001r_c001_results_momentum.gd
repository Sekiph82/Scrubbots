extends SceneTree
## M43-C001R-C001 — Results momentum / 10-Level Cleaning Journey evidence
## (SB-M43-R01-001..008). SB-PHONE-2026-11-12-B (owner 2026-11-12) removed the Next Cleanup
## teaser and CLEAN NEXT; SB-PHONE-2026-11-12-E removed the WON Results itself: a win goes
## straight Home (its journey shows on the Home strip; the win's journey read model only feeds
## the journey_progress event). Real app root (main.tscn), real production catalog,
## real terminal WON (economy + progression + save commit in the host BEFORE Home), the
## real Home, and the ONE ResultsMomentum read authority.
##
## Run: godot --headless --path . -s res://tests/m43_c001r_c001_results_momentum.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const FeaturedCards = preload("res://scripts/collection/featured_cards.gd")
const ResultsMomentum = preload("res://scripts/progression/results_momentum.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const JourneyStrip = preload("res://scripts/ui/components/journey_strip.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const R = NavigationController.Route
const T0 := 1_900_000_000

var EXPECTED_CASES := [
	"w02_won_home_then_play", "t12_t14_ten_nodes_beats",
	"t15_nodes_no_input", "t16_home_frontier_1", "t17_home_frontier_6", "t18_win_journey_l9", "t19_win_journey_l10",
	"t20_home_frontier_11", "t21_injected_l11_cycle_transition", "t22_one_authority", "t23_save_reload",
	"t33_responsive", "t35_malformed_config", "no_manipulation_copy",
	"v02_home_strip_larger", "v02_beat_size_hierarchy", "v02_beat_colors",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [T0]
var _sub: SubViewport
var _root
var _cat
var _last := 0   ## last production catalog level (the catalog grows; nothing pins it to 10)

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	_cat = LevelCatalog.new()
	var loaded: bool = _cat.load_manifest().ok
	_last = _cat.size()
	var orders: Array = _cat.get_entries_ordered().map(func(e): return e.order)
	_ok(loaded and _last >= 10 and orders == range(1, _last + 1), "production catalog loads (%d entries, orders 1..%d)" % [_last, _last])
	await _won_home_cases()
	await _journey_cases()
	await _t21_injected()
	await _v02_cases()
	await _t22_t23()
	await _t33_responsive()
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
		# SB-POLISH-002: a fresh save's first win crosses Gift milestone 1, whose ceremony opens
		# over Results. Start with the meter at 1 and that ceremony seen, so a win
		# crosses no milestone (the barrier itself is covered by t30 / t31).
		var seed = AppState.new(path, func(): return _now[0])
		for o in seed.economy.gift.add_streak_sb("test_seed_m1", 1):
			seed.economy.meta_ui.mark_seen("gift:" + String(o["id"]))
		# SB-M44-026: a first clear of a featured level (L20+) grants a Featured Card whose ceremony
		# opens over Results too; commit it beforehand (seen), as m43_c001b does for L30.
		var fc: Dictionary = FeaturedCards.grant_milestone(seed.economy, frontier)
		if bool(fc["applied"]):
			seed.economy.meta_ui.mark_seen("featured_card:L%d:%s" % [frontier, fc["card"]])
		seed.request_save()
		seed.economy.dispose()
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

## Boot at frontier `level`, play it and commit a real terminal WON -> Home.
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

func _nav():
	return _root.get_navigation()

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _set_frontier(n: int) -> void:
	_app().progression.import_snapshot({"schema": "scrubbots.progression.v1", "current_level": n, "completed": range(1, n)})

## The win's journey read model (anchor = the won level), as main.gd's journey_progress reads it.
func _win_journey(level: int) -> Dictionary:
	return ResultsMomentum.results_model(_app(), level, _root.momentum_cfg)["journey"]

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

# ============================================= SB-PHONE-2026-11-12-E: win -> Home =====

func _won_home_cases() -> void:
	print("[w02 a win goes straight Home (no Results); Home PLAY starts the next level]")
	await _won(2)
	_ok(_nav().current() == R.HOME and not _root.get_results_screen().visible and _root.get_gameplay_host() == null, "WON L2 -> Home, no Results, no host")
	_ok(not _root.has_method("continue_from_results"), "no Continue intent or handler exists")
	_root.get_modal_stack().clear("t")
	var r: Dictionary = _root.play_current_frontier()
	await _settle()
	_ok(r.get("ok", false) and _nav().current() == R.GAMEPLAY and int(_root.get_gameplay_host().progression_level) == 3, "Home PLAY starts the next level (3)")
	_complete("w02_won_home_then_play")

# ================================================================ V02 ============

## V01 reference geometry (owner V02 asked for a materially larger Journey).
const V01_HOME_STRIP := Vector2(560, 58)
const V01_HOME_NODE := 39.4      ## 2 * min(58 * 0.34, 56 * 0.36)

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
	print("[V02 owner remediation: strip size, beat hierarchy]")
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
	_ok(bad.is_empty(), "all nodes inside their strip, neighbours never overlap %s" % str(bad))
	_complete("v02_beat_size_hierarchy")
	_ok(JourneyStrip.MINI_EDGE == Color(1.0, 0.55, 0.12) and JourneyStrip.BOSS_EDGE == Color(0.86, 0.13, 0.20) and JourneyStrip.BEAT_SCALE["mini_boss"] < JourneyStrip.BEAT_SCALE["boss"],
		"slot 5 orange / slot 10 red unchanged")
	_complete("v02_beat_colors")

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
	j = _win_journey(9)
	_ok(j["context"] == "results" and j["completed"] == 9 and j["nodes"][9]["state"] == "next", "win L9 journey: 1..9 complete, slot 10 next")
	_complete("t18_win_journey_l9")
	await _won(10)
	j = _win_journey(10)
	_ok(j["completed"] == 10 and j["nodes"].all(func(nd): return nd["state"] == "complete") and j["cycle"] == 1, "win L10 journey: 10/10 complete")
	_complete("t19_win_journey_l10")
	await _boot(11)
	j = _root.get_home().get_journey_strip().get_model()
	_ok(j["cycle"] == 2 and j["slot"] == 1 and j["completed"] == 0 and j["nodes"][0]["state"] == "current" and j["nodes"][0]["level"] == 11 and j["nodes"][9]["level"] == 20,
		"Home frontier 11: new cycle 2, slot 1 (L11) current, nodes 11..20")
	_ok(ResultsMomentum.cycle_of(10) == 1 and ResultsMomentum.slot_of(10) == 10 and ResultsMomentum.cycle_of(11) == 2 and ResultsMomentum.slot_of(11) == 1
		and ResultsMomentum.cycle_of(311) == 32 and ResultsMomentum.slot_of(311) == 1 and ResultsMomentum.slot_of(1000) == 10, "cycle math 10 / 11 / 311 / 1000")
	_complete("t20_home_frontier_11")

func _t21_injected() -> void:
	print("[21 injected Level %d content: %d -> next-cycle transition]" % [_last + 1, _last])
	await _boot(_last + 1)
	var stub := InjectedCatalog.new(_cat, _entry(2), _last + 1)
	var launch := GameplayLaunchResolver.resolve(_app(), stub)
	var cfg := ResultsMomentum.load_config()
	var rm := ResultsMomentum.results_model(_app(), _last, cfg)
	_ok(launch["ok"] and launch["level"] == _last + 1 and not rm.has("next")
		and rm["journey"]["completed"] == ResultsMomentum.slot_of(_last), "Results L%d + injected L%d: %d/10, no teaser model (test-only entry)" % [_last, _last + 1, ResultsMomentum.slot_of(_last)])
	var hj := ResultsMomentum.home_journey(_app(), cfg)
	_ok(hj["cycle"] == ResultsMomentum.cycle_of(_last + 1) and hj["slot"] == ResultsMomentum.slot_of(_last + 1) and hj["nodes"][hj["slot"] - 1]["state"] == "current",
		"next Home frontier %d: cycle %d slot %d current" % [_last + 1, hj["cycle"], hj["slot"]])
	_ok(not GameplayLaunchResolver.resolve(_app())["ok"], "production catalog itself still has no L%d (nothing hardcoded)" % (_last + 1))
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
	_ok(_win_journey(5) == ResultsMomentum.journey(_app().progression, "results", 5, cfg), "win journey = ResultsMomentum.journey(results, 5)")
	var hj: Dictionary = _root.get_home().get_journey_strip().get_model()
	_ok(_nav().current() == R.HOME and hj == ResultsMomentum.home_journey(_app(), cfg) and _root.get_home().get_journey_strip().get_script() == JourneyStrip
		and hj["slot"] == 6 and hj["completed"] == 5, "the Home the win lands on: strip = ResultsMomentum.home_journey (frontier 6), the JourneyStrip component")
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

func _t33_responsive() -> void:
	print("[33 responsive: Home strip]")
	for sz in [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 1920), Vector2i(1536, 2048)]:
		var bad: Array = []
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
		_ok(bad.is_empty(), "%dx%d: Home strip fits, no collisions %s" % [sz.x, sz.y, str(bad)])
	_complete("t33_responsive")

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
	_ok(_nav().current() == R.HOME and not _root.get_home().get_journey_strip().visible, "a win still goes Home (no strip), unaffected")
	_complete("t35_malformed_config")
	# Copy guard: momentum text carries only canonical facts.
	var banned := ["ALMOST", "LUCKY", "JACKPOT", "HURRY", "FREE", "REWARD", "GUARANTEE", "LAST CHANCE"]
	var texts: Array = []
	for key in ["HOME_PLAY", "RESULTS_HOME"]:
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
