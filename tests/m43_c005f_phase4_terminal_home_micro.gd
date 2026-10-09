extends SceneTree
## M43-C005F-PHASE4 — Gameplay->Results bridge (SB-M43-C005F-010) + Home state-change micro feel
## (SB-M43-C005F-012). Everything runs in the REAL app (main.tscn, 1080x2160 SubViewport):
##   t*: F010 — Level 1 played to its REAL WON terminal (supply-plan clicks + runtime ticks, the
##       CompletionController latches it), LOST through the real completion signal (the M43-C004
##       pattern), duplicates / stale signals, plugins missing / throwing, Reduced, static guard;
##   h*: F012 — baseline, refresh / timer / resize / safe-area / modal / hide-show / content no-op,
##       real frontier + streak delta after a real WON, Bot Parts unlockable, Gift milestone owned
##       by F008, no replay, Reduced, plugins missing / throwing;
##   b*: boundary — static (no plugin / authority / durable state in the new feel code).
## Plugin work is observed through FeedbackAdapter's test seam (spy backends) and its log.
## Run: godot --headless --path . -s res://tests/m43_c005f_phase4_terminal_home_micro.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const R = NavigationController.Route

class SpyGff extends RefCounted:
	var plays: Array = []
	func play(n, t, _o = {}) -> void:
		plays.append([n, t])
	func stop_all(_t = null) -> void:
		pass
	func get_effect_names() -> Array:
		return ["punch_scale"]

class SpySpark extends RefCounted:
	var presets := {"spark": {}, "pickup": {}, "confetti": {}}
	var bursts: Array = []   ## particle amounts
	func burst(_pos, o = {}) -> void:
		bursts.append(int(o.get("amount", 0)))
	func at(_n, o = {}) -> void:
		bursts.append(int(o.get("amount", 0)))
	func clear() -> void:
		pass

class FaultySpark extends RefCounted:
	var presets := {"spark": {}, "pickup": {}, "confetti": {}}
	func burst(_p, _o = {}) -> void:
		var broken = null
		broken.explode()   # injected plugin failure (expected SCRIPT ERROR, see the test log)
	func at(_n, _o = {}) -> void:
		pass
	func clear() -> void:
		pass

var EXPECTED_CASES := [
	"t01_real_won_one_results_one_small", "t02_lost_no_bridge_no_win", "t03_duplicate_stale_no_second_bridge",
	"t04_plugins_missing_results_once", "t05_plugin_throws_results_once", "t06_reduced_zero_plugin_work",
	"t07_static_no_delay_before_navigation", "t08_results_win_count_unchanged",
	"h01_first_render_baseline", "h02_refresh_x10_zero", "h03_heart_timer_zero", "h04_layout_modal_hide_content_zero",
	"h05_real_frontier_streak_delta", "h06_bot_parts_unlockable_one", "h07_gift_milestone_no_duplicate",
	"h08_same_state_no_replay", "h09_reduced_delta_visible_zero_work", "h10_plugins_missing_throwing_home_ok",
	"b01_static_boundary",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _gff: SpyGff
var _spark: SpySpark
var _routes: Array = []
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	var base: Dictionary = await _t01()
	await _t02(); await _t03(); await _t04(base); await _t05(base); await _t06(base)
	_t07()
	await _h01(); await _h02(); await _h03(); await _h04(); await _h06(); await _h07(); await _h09(); await _h10()
	_b01()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _uniq(tag: String) -> String:
	var p := "user://c005f_p4_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _uniq(tag)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(14)
	_gff = SpyGff.new()
	_spark = SpySpark.new()
	_root.feel.set_backends_for_test(_gff, _spark)
	_routes = []
	_nav().route_changed.connect(func(_f, to, _p): _routes.append(to))

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

func _nav():
	return _root.get_navigation()

func _e():
	return _root.get_app_state().economy

func _home():
	return _root.get_home()

func _micro() -> Array:
	return _home().get_micro_feel().feel_log()

func _adapter_log(prefix: String = "", intent: String = "") -> Array:
	return _root.feel.dispatch_log().filter(func(r): return String(r[1]).begins_with(prefix) and (intent.is_empty() or r[0] == intent))

func _results_count() -> int:
	return _routes.count(R.RESULTS)

## Drive the launched Level 1 to its REAL terminal (owner supply plan clicks + runtime ticks;
## the M30 CompletionController latches WON itself). Same driver as tests/m55_long_session.gd.
func _drive_real_won() -> String:
	var host = _root.get_gameplay_host()
	var clicks: Array = []
	if not String(host.supply_plan_path).is_empty():
		clicks = SupplyPlanLoader.load_plan(host.supply_plan_path)["plan"]["intendedColumnClicks"]
	var rt = host.get_runtime()
	rt.set_process(false)
	var input = host.get_input_controller()
	var slots = host.get_slots()
	var i := 0
	var frames := 0
	while frames < 200000 and not host.get_completion().is_terminal():
		if slots.rightmost_empty_index() != -1:
			if not clicks.is_empty():
				if i < clicks.size() and input.activate_front(int(clicks[i]) - 1).get("ok", false):
					i += 1
			else:
				for col in range(host.get_supply().get_column_count()):
					if input.activate_front(col).get("ok", false):
						break
		rt.tick(1.0)
		frames += 1
	await _frames(12)
	return String(host.get_completion().get_state())

## Boot, PLAY Level 1, drive it to the real WON. Returns the committed truth for comparison.
func _won_run(tag: String) -> Dictionary:
	await _boot(tag)
	var launch: Dictionary = _root.play_current_frontier()
	if not launch.get("ok", false):
		_ok(false, "%s: Home PLAY launches Level 1 (%s)" % [tag, str(launch)])
		return {}
	var st := await _drive_real_won()
	var rc: Dictionary = _root.get_gameplay_host().get_terminal_receipt()
	return {"status": st, "receipt": rc, "econ": _econ(), "results": _results_count(),
		"saved": bool(rc.get("saved", false)), "progress": _root.get_app_state().progression.completed_count()}

## Economy snapshot minus the per-save pack RNG seed (drawn when a new save is created, so it
## differs between boots; it is not part of any terminal's committed truth).
func _econ() -> String:
	var snap: Dictionary = _e().snapshot()
	snap.erase("packs")
	return JSON.stringify(snap)

## Receipt without per-run identity (attempt-independent comparison across boots).
static func _truth(t: Dictionary) -> Array:
	return [t.get("status"), t.get("receipt"), t.get("econ"), t.get("saved"), t.get("progress")]

# --------------------------------------------------------------------- F010 ----

func _t01() -> Dictionary:
	print("[t01 F010 real WON: committed receipt, ONE Results route, at most ONE SMALL bridge]")
	var t := await _won_run("t01")
	_ok(t.get("status") == "WON" and t.get("saved") and t.get("progress") == 1, "real terminal WON latched by CompletionController, receipt saved, frontier advanced")
	_ok(t.get("results") == 1 and _nav().current() == R.RESULTS, "exactly one navigation to Results")
	var b := _adapter_log("c005f010:")
	_ok(b.size() == 1 and b[0][0] == "SMALL" and b[0][1] == "c005f010:a1:L1", "one SMALL bridge keyed by the terminal attempt %s" % str(b.map(func(r): return [r[0], r[1]])))
	var portrait = _root.get_gameplay_host().get_screen().get_profile_portrait()
	_ok(portrait != null and portrait.is_visible_in_tree() and _root.get_results_screen().visible, "target = HUD robot portrait, under the shown Results")
	_ok(_spark.bursts.count(4) == 1, "SMALL = one 4-particle Spark burst (bursts %s)" % str(_spark.bursts))
	_complete("t01_real_won_one_results_one_small")
	print("[t08 F003 WIN count unchanged: the bridge adds no WIN / confetti]")
	await _frames(20)
	var win := _adapter_log("", "WIN")
	_ok(win.size() == 1 and win[0][1] == "results:WON:a1:L1:win", "exactly one WIN (F003 Results) %s" % str(win.map(func(r): return r[1])))
	_ok(_spark.bursts.count(18) == 1 and _adapter_log("c005f010:").all(func(r): return r[0] != "WIN"), "one 18-particle WIN confetti; bridge is not a WIN")
	_complete("t08_results_win_count_unchanged")
	await _h05_after_real_won()
	return t

func _t02() -> void:
	print("[t02 F010 LOST: same authority, one Results, no bridge, no WIN]")
	await _boot("t02")
	_root.play_current_frontier()
	await _frames(2)
	var host = _root.get_gameplay_host()
	for col in range(host.get_supply().get_column_count()):
		if host.get_input_controller().activate_front(col).get("ok", false):
			break
	host.get_completion().terminal_reached.emit(&"LOST", {})
	await _frames(14)
	_ok(_results_count() == 1 and String(_nav().last_payload().get("status", "")) == "LOST", "one Results (LOST)")
	_ok(String(host.get_terminal_receipt().get("status", "")) == "LOST", "committed LOST receipt")
	_ok(_adapter_log("c005f010:").is_empty() and _adapter_log("", "WIN").is_empty(), "no bridge and no WIN on a loss")
	_complete("t02_lost_no_bridge_no_win")

func _t03() -> void:
	print("[t03 F010 duplicate / stale terminal signal, Results re-show: no second bridge]")
	await _won_run("t03")
	var host = _root.get_gameplay_host()
	var rc: Dictionary = host.get_terminal_receipt()
	for _i in range(3):
		host.get_completion().terminal_reached.emit(&"WON", {})
		host.get_completion().terminal_reached.emit(&"LOST", {})
	_root._on_route_changed(R.GAMEPLAY, R.RESULTS, _nav().last_payload())   # Results re-show
	_root.get_results_screen().show_model(_root.get_results_screen().get_model())
	await _frames(14)
	_ok(_results_count() == 1, "still exactly one Results transition")
	_ok(_adapter_log("c005f010:").size() == 1 and _adapter_log("", "WIN").size() == 1, "still one bridge, one WIN")
	_ok(host.get_terminal_receipt() == rc, "receipt unchanged")
	_complete("t03_duplicate_stale_no_second_bridge")

func _t04(base: Dictionary) -> void:
	print("[t04 F010 plugins missing: Results once, same committed truth]")
	var t := await _won_run_with(null, null, false, "t04")
	_ok(t.get("results") == 1 and _nav().current() == R.RESULTS, "Results reached once")
	_ok(_truth(t) == _truth(base), "receipt / economy / save / progression identical to the spied run")
	_ok(_adapter_log("c005f010:").size() == 1, "bridge accepted as a no-op")
	_complete("t04_plugins_missing_results_once")

func _t05(base: Dictionary) -> void:
	print("[t05 F010 plugin throws: Results once, same committed truth (expected injected SCRIPT ERRORs: one per Spark burst)]")
	var t := await _won_run_with(SpyGff.new(), FaultySpark.new(), false, "t05")
	await _frames(10)
	_ok(t.get("results") == 1 and _nav().current() == R.RESULTS and _root.get_results_screen().visible, "Results reached once, still shown")
	_ok(_truth(t) == _truth(base), "receipt / economy / save / progression identical to the spied run")
	_ok(_root.get_gameplay_host() != null and _root.get_gameplay_host().get_completion().is_terminal(), "gameplay host terminal, not stuck")
	_complete("t05_plugin_throws_results_once")

func _t06(base: Dictionary) -> void:
	print("[t06 F010 Reduced: zero plugin work, Results once]")
	var t := await _won_run_with(SpyGff.new(), SpySpark.new(), true, "t06")
	await _frames(20)
	_ok(t.get("results") == 1 and _nav().current() == R.RESULTS, "Results reached once")
	_ok(_gff.plays.is_empty() and _spark.bursts.is_empty() and _root.feel.owned_count() == 0, "zero plugin work")
	_ok(_truth(t) == _truth(base), "same committed truth as FULL")
	_complete("t06_reduced_zero_plugin_work")

## A WON run with specific backends (null = plugin absent) and Reduced Effects state.
func _won_run_with(gff, spark, reduced: bool, tag: String) -> Dictionary:
	await _boot(tag)
	_gff = gff if gff != null else SpyGff.new()
	_spark = spark if spark is SpySpark else SpySpark.new()
	_root.feel.set_backends_for_test(gff, spark)
	_root.get_app_state().set_reduced_effects(reduced)
	if not _root.play_current_frontier().get("ok", false):
		_ok(false, tag + ": launch")
		return {}
	var st := await _drive_real_won()
	var rc: Dictionary = _root.get_gameplay_host().get_terminal_receipt()
	_root.get_app_state().set_reduced_effects(false)   # identical effects snapshot for comparison
	var t := {"status": st, "receipt": rc, "econ": _econ(), "results": _results_count(),
		"saved": bool(rc.get("saved", false)), "progress": _root.get_app_state().progression.completed_count()}
	_root.get_app_state().set_reduced_effects(reduced)
	return t

func _t07() -> void:
	print("[t07 F010 static: nothing sits between the terminal authority and nav.on_gameplay_terminal]")
	var src := _code("res://scripts/app/main.gd")
	var bind := _func_body(src, "func _bind_terminal(")
	var bridge := _func_body(src, "func _terminal_bridge(")
	_ok(bind.contains("terminal_reached.connect") and bind.contains("nav.on_gameplay_terminal(") and bind.find("nav.on_gameplay_terminal(") < bind.find("_terminal_bridge("), "bridge runs only after nav accepted the terminal")
	for bad in ["await", "create_timer", "call_deferred", "timeout", "Tween", "process_frame"]:
		_ok(not bind.contains(bad) and not bridge.contains(bad), "no '%s' in the terminal binding / bridge" % bad)
	_ok(bridge.contains("feel.play(\"SMALL\"") and bridge.count("feel.play(") == 1 and not bridge.contains("nav.go") and not bridge.contains("on_gameplay_terminal"), "bridge = one SMALL adapter request, no navigation")
	_complete("t07_static_no_delay_before_navigation")

# --------------------------------------------------------------------- F012 ----

## Real WON (from t01) -> Results Home: one frontier MICRO on the Journey strip, then the streak.
func _h05_after_real_won() -> void:
	print("[h05 F012 real frontier + Win Streak delta after the real WON (Results -> Home)]")
	var before := _micro().size()
	_ok(before == 0, "nothing answered while Home was hidden (gameplay / Results)")
	_root.get_results_screen().get_home_button().pressed.emit()
	await _frames(2)
	_ok(_nav().current() == R.HOME, "Results -> Home")
	var m := _micro()
	_ok(m.size() == 1 and m[0] == ["frontier", "HomeJourneyStrip"], "dominant delta answered at once on the Journey strip %s" % str(m))
	var strip = _home().get_journey_strip()
	await _frames(3)
	_ok(strip.scale.x > 1.0 and strip.scale.x <= 1.06 + 0.001, "native MICRO bump on the strip (scale %.3f)" % strip.scale.x)
	await create_timer(0.9).timeout
	m = _micro()
	var modal: bool = _home().is_modal_active()
	_ok(m.size() == 2 and m[1] == ["win_streak", "TrackGift1"] or (modal and m.size() == 1), "second delta (streak) serialized on the current track gift %s (modal %s)" % [str(m), str(modal)])
	_ok(strip.scale == Vector2.ONE, "strip restored to scale 1")
	var micro: Array = _root.feel.dispatch_log().filter(func(r): return r[0] == "MICRO" and String(r[1]).is_empty())
	_ok(micro.size() == m.size(), "MICRO only, no Spark particles for Home (%d)" % micro.size())
	_complete("h05_real_frontier_streak_delta")
	print("[h08 F012 same state rendered again: no replay]")
	for _i in range(6):
		_home().refresh()
	_root.get_modal_stack().modal_changed.emit(false)
	await create_timer(0.5).timeout
	_ok(_micro().size() == m.size(), "no replay after 6 refreshes + modal close")
	_complete("h08_same_state_no_replay")

func _home_boot(tag: String) -> void:
	await _boot(tag)
	await _frames(4)

func _h01() -> void:
	print("[h01 F012 first render = baseline only]")
	await _home_boot("h01")
	_ok(_home().get_micro_feel().has_baseline() and _micro().is_empty(), "baseline captured, zero feedback")
	_ok(_root.feel.dispatch_log().is_empty(), "no adapter request at all on cold boot")
	_complete("h01_first_render_baseline")

func _h02() -> void:
	print("[h02 F012 unchanged refresh x10: zero]")
	for _i in range(10):
		_home().refresh()
	await _frames(4)
	_ok(_micro().is_empty() and _root.feel.dispatch_log().is_empty(), "zero feedback")
	_complete("h02_refresh_x10_zero")

func _h03() -> void:
	print("[h03 F012 Heart timer ticks: zero]")
	_e().hearts.consume()
	_home().refresh()
	for s in range(5):
		_now[0] += 1
		_home().refresh()
	await create_timer(2.2).timeout   # the real 1 s Home timer fires twice
	_ok(_micro().is_empty(), "Heart count / regen clock changes never answer")
	_complete("h03_heart_timer_zero")

func _h04() -> void:
	print("[h04 F012 resize / safe-area / modal / hide-show / identical content refresh: zero]")
	_sub.size = Vector2i(1536, 2048)
	await _frames(6)
	_sub.size = Vector2i(1080, 2160)
	await _frames(6)
	var safe = _home().find_child("SafeAreaRoot", true, false)
	if safe != null and safe.has_method("set_synthetic_insets"):
		safe.set_synthetic_insets(0, 96, 0, 64)
		await _frames(4)
		safe.clear_synthetic_insets()
	_root._on_home_shortcut("shop")
	await _frames(6)
	_root.get_modal_stack().clear("t")
	await _frames(6)
	_home().visible = false
	_home().refresh()
	_home().visible = true
	_home().refresh()
	var content = _root.get_app_state().content
	if content != null and content.has_signal("content_changed"):
		content.content_changed.emit()
	_home().refresh()   # the main.gd content_changed seam (refresh) with identical state
	await _frames(6)
	_ok(safe != null, "Home SafeAreaRoot found")
	_ok(_micro().is_empty(), "zero feedback")
	_complete("h04_layout_modal_hide_content_zero")

func _h06() -> void:
	print("[h06 F012 Bot Parts become unlockable: one bounded event]")
	await _home_boot("h06")
	var need: int = int(_e().robots.next_robot_progress().get("cost", 0)) - _e().wallet.bot_parts()
	_e().wallet.credit("bot_parts", need)
	_home().refresh()
	await _frames(2)
	_ok(_micro() == [["bot_parts", "ProfileBotParts"]], "one MICRO on the Bot Parts meter %s" % str(_micro()))
	_e().wallet.credit("bot_parts", 10)   # still unlockable: no new crossing
	_home().refresh()
	await create_timer(0.5).timeout
	_ok(_micro().size() == 1, "no second event while it stays unlockable")
	_complete("h06_bot_parts_unlockable_one")

func _h07() -> void:
	print("[h07 F012 Gift milestone (owned by F008): Home adds no duplicate REWARD / major effect]")
	await _home_boot("h07")
	_e().gift.add_streak_sb("streak:p4:h07", 50)
	_home().refresh()
	_root.request_home_ceremonies()
	await _frames(14)
	var shown := 0
	for _i in range(4):   # 10 and 50 milestones: one F008 ceremony each
		var top = _root.get_modal_stack().top()
		if top == null or not String(top.popup_id).begins_with("ceremony_gift"):
			break
		shown += 1
		await create_timer(0.5).timeout
		top.close("action:continue")
		await _frames(14)
	for _i in range(5):
		_home().refresh()
	await create_timer(0.5).timeout
	_ok(shown == 2, "the Gift milestone ceremonies (F008) were presented (%d)" % shown)
	_ok(_micro().is_empty(), "Home answered nothing for Gift progress / claimable badge")
	var big: Array = _root.feel.dispatch_log().filter(func(r): return ["REWARD", "MAJOR_REWARD", "WIN", "MAJOR_UNLOCK"].has(r[0]))
	_ok(big.size() == shown and big.all(func(r): return String(r[1]).begins_with("c005f008:gift:")), "only F008's own keyed milestone events, one per ceremony %s" % str(big.map(func(r): return [r[0], r[1]])))
	_ok(_root.feel.dispatch_log().filter(func(r): return String(r[1]).is_empty()).is_empty(), "no keyless (Home) event at all")
	_complete("h07_gift_milestone_no_duplicate")

func _h09() -> void:
	print("[h09 F012 Reduced: delta visible, zero plugin work, no native pulse]")
	await _home_boot("h09")
	_root.get_app_state().set_reduced_effects(true)
	await _frames(2)
	_e().streak.process_first_clear_win(1)
	_home().refresh()
	var track = _home().get_region("TrackGift1")
	await _frames(4)
	_ok((_home().get_region("TrackStreakValue") as Label).text == "1", "streak value rendered")
	_ok(_micro().size() == 1 and _micro()[0][0] == "win_streak", "delta observed once")
	_ok(_gff.plays.is_empty() and _spark.bursts.is_empty() and _root.feel.owned_count() == 0, "zero plugin work")
	_ok(track.scale == Vector2.ONE, "no native pulse")
	_root.get_app_state().set_reduced_effects(false)
	_complete("h09_reduced_delta_visible_zero_work")

func _h10() -> void:
	print("[h10 F012 plugins missing / throwing: Home values correct, navigation unaffected]")
	for faulty in [false, true]:
		await _home_boot("h10_%s" % ("faulty" if faulty else "missing"))
		_root.feel.set_backends_for_test(SpyGff.new() if faulty else null, FaultySpark.new() if faulty else null)
		_e().streak.process_first_clear_win(1)
		_e().streak.process_first_clear_win(2)
		_home().refresh()
		await _frames(6)
		_ok((_home().get_region("TrackStreakValue") as Label).text == "2" and _micro().size() == 1, "%s: value correct, one event" % ("throwing" if faulty else "missing"))
		var r: Dictionary = _root.play_current_frontier()
		_ok(r.get("ok", false) and _nav().current() == R.GAMEPLAY, "%s: PLAY still navigates" % ("throwing" if faulty else "missing"))
	_complete("h10_plugins_missing_throwing_home_ok")

# ----------------------------------------------------------------- boundary ----

func _b01() -> void:
	print("[b01 boundary: adapter-only plugin access, no authority / durable state in Phase 4 feel code]")
	var micro := _code("res://scripts/ui/feel/home_micro_feel.gd")
	for bad in ["GameFeelFlow", "Spark", "get_node(\"/root", "actions.", "economy", "wallet", "progression", "save", "flush",
			"FileAccess", "ConfigFile", "user://", "nav.", "go(", "emit(", "camera", "flash", "freeze", "time_scale", "clear()"]:
		_ok(not micro.contains(bad), "home_micro_feel.gd has no '%s'" % bad)
	var bridge := _func_body(_code("res://scripts/app/main.gd"), "func _terminal_bridge(")
	for bad in ["GameFeelFlow", "Spark.", "economy", "save", "actions.", "nav.go", "on_gameplay_terminal"]:
		_ok(not bridge.contains(bad), "_terminal_bridge has no '%s'" % bad)
	var home := _code("res://scripts/ui/home/home_screen.gd")
	_ok(home.contains("_micro.observe(") and not home.contains("GameFeelFlow") and not home.contains("Spark"), "HomeScreen reaches feel only through HomeMicroFeel -> FeedbackAdapter")
	_complete("b01_static_boundary")

func _code(path: String) -> String:
	var out := ""
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var s := line.strip_edges()
		if not s.begins_with("#"):
			out += line + "\n"
	return out

static func _func_body(src: String, head: String) -> String:
	var i := src.find(head)
	if i < 0:
		return ""
	var j := src.find("\nfunc ", i + head.length())
	return src.substr(i, (j if j > 0 else src.length()) - i)

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
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

func _complete(c: String) -> void:
	_completed[c] = true

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	if not missing.is_empty():
		_fail += missing.size()
		print("  FAIL: cases not completed %s" % str(missing))
	print("M43-C005F-PHASE4 terminal bridge + Home micro feel: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
