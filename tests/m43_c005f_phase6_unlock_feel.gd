extends SceneTree
## SB-M43-C005F-007 — Robot / Feature Unlock feel (MAJOR_UNLOCK). Everything runs in the REAL app
## (main.tscn, 1080x2160 SubViewport, test save paths) through the shipping CeremonyPresenter +
## MetaRewardFeel seams: one MAJOR_UNLOCK per shown robot / feature unlock ceremony, keyed
## c005f007:<ceremony key>, within the adapter ceiling, Reduced = zero plugin work, no authority.
## World Transition stays gated (no intent). Plugin work is observed through spy backends.
## Run: godot --headless --path . -s res://tests/m43_c005f_phase6_unlock_feel.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const MetaRewardFeel = preload("res://scripts/ui/feel/meta_reward_feel.gd")

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
	var bursts: Array = []   ## [amount, lifetime]
	func burst(_pos, o = {}) -> void:
		bursts.append([int(o.get("amount", 0)), float(o.get("lifetime", 0.0))])
	func at(_n, o = {}) -> void:
		bursts.append([int(o.get("amount", 0)), float(o.get("lifetime", 0.0))])
	func clear() -> void:
		pass

var EXPECTED_CASES := [
	"u01_robot_major_unlock_once", "u02_feature_major_unlock_once", "u03_reduced_zero_plugin_work",
	"u04_ceiling_not_exceeded", "u05_no_replay_refresh_equip_redrain", "u06_truth_unchanged",
	"u07_world_not_mapped", "u08_static_boundary",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _gff: SpyGff
var _spark: SpySpark

func _initialize() -> void:
	await process_frame
	await _u01(); await _u02(); await _u03(); await _u04(); await _u05(); await _u06(); await _u07()
	_u08()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _uniq(tag: String) -> String:
	var p := "user://c005f_p6_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

## Boot the real app root on `path` (a fresh test save unless seeded beforehand).
func _boot(path: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(14)
	_gff = SpyGff.new()
	_spark = SpySpark.new()
	_root.feel.set_backends_for_test(_gff, _spark)

## Real app with one unlocked (unseen) robot: Moppy, via the shipping facade.
func _boot_robot(tag: String) -> void:
	await _boot(_uniq(tag))
	_e().wallet.credit(EconomyWallet.BOT_PARTS, 250)
	_ok(bool(_app().actions.unlock_next_robot().get("ok", false)), "Moppy unlocked by the facade (setup)")

## Real app on a NEW FTUE profile at L3; the live frontier then reaches L4 (owner table:
## unlock:daily), so the ceremony is first shown after the spy backends are in place.
func _boot_feature(tag: String) -> void:
	var path := _uniq(tag)
	var seed = AppState.new(path)
	seed.bootstrap_new_profile()
	while seed.progression.current_level() < 3:
		seed.progression.record_win(seed.progression.current_level())
	seed.request_save()
	await _boot(path)
	_app().progression.record_win(3)
	_ok(_app().feature_unlocked("daily"), "frontier L4: Daily unlocked (setup)")

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

func _app():
	return _root.get_app_state()

func _e():
	return _app().economy

func _top():
	return _root.get_modal_stack().top()

func _log(child: String = "") -> Array:
	return _root.get_meta_reward_feel().feel_log().filter(func(r): return child.is_empty() or r[0] == child)

func _show() -> void:
	_root.request_home_ceremonies()
	await _frames(14)

func _press(id: String, p = null) -> void:
	var pp = p if p != null else _top()
	await create_timer(0.45).timeout   # popups re-arm their CTAs shortly after open
	pp.get_action_button(id).pressed.emit()
	await _frames(14)

## Authority truth: economy (wallet, robots, collection, reward ledgers, meta_ui), progression,
## feature unlock state. Section -> JSON, so a mismatch names its section.
func _truth() -> Dictionary:
	var out := {"progression": JSON.stringify(_app().progression.snapshot())}
	var s: Dictionary = _e().snapshot()
	s["hearts"].erase("anchor")              # wall-clock anchors, not authority truth
	s["speed"].erase("clock_high_water")
	for k in s:
		out["economy." + String(k)] = JSON.stringify(s[k])
	for id in _app().unlocks.cfg["unlocks"]:
		out["unlocked." + String(id)] = _app().feature_unlocked(id)
	return out

func _diff(a: Dictionary, b: Dictionary) -> Array:
	return a.keys().filter(func(k): return not b.has(k) or b[k] != a[k])

func _popup_id() -> String:
	return String(_top().popup_id) if _top() != null else ""

# -------------------------------------------------------------------- cases ----

func _u01() -> void:
	print("[u01 Robot Unlock ceremony: exactly one MAJOR_UNLOCK on the hero, key c005f007:robot:moppy]")
	await _boot_robot("u01")
	await _show()
	_ok(_popup_id() == "ceremony_robot_unlock", "shipping Robot Unlock ceremony on the app ModalStack (%s)" % _popup_id())
	_ok(_log("F007") == [["F007", "MAJOR_UNLOCK", "c005f007:robot:moppy", "HeroArt"]], "one MAJOR_UNLOCK request on HeroArt %s" % str(_log("F007")))
	_ok(_spark.bursts.size() == 1 and _spark.bursts[0][0] == 24 and _gff.plays.is_empty(), "one confetti burst of 24; GFF never on a Control %s" % str(_spark.bursts))
	_complete("u01_robot_major_unlock_once")

func _u02() -> void:
	print("[u02 Feature Unlock ceremony: exactly one MAJOR_UNLOCK, key c005f007:unlock:daily]")
	await _boot_feature("u02")
	await _show()
	_ok(_popup_id() == "ceremony_feature_unlock", "shipping Feature Unlock ceremony (%s)" % _popup_id())
	_ok(_log("F007") == [["F007", "MAJOR_UNLOCK", "c005f007:unlock:daily", "HeroArt"]], "one MAJOR_UNLOCK request on HeroArt %s" % str(_log("F007")))
	_ok(_spark.bursts.size() == 1 and _spark.bursts[0][0] == 24 and _gff.plays.is_empty(), "one confetti burst of 24 %s" % str(_spark.bursts))
	await _press("got_it")
	_ok(_e().meta_ui.is_seen("unlock:daily") and _log("F007").size() == 1, "acknowledged by its own CTA; still one request")
	_complete("u02_feature_major_unlock_once")

func _u03() -> void:
	print("[u03 Reduced: key consumed, zero plugin work, no settle, same popup content]")
	await _boot_robot("u03")
	_app().set_reduced_effects(true)
	await _show()
	var p = _top()
	var hero: Control = p.find_child("HeroArt", true, false)
	await create_timer(0.35).timeout
	_ok(_root.feel.has_played("c005f007:robot:moppy") and _log("F007").size() == 1, "presentation key consumed under Reduced")
	_ok(_spark.bursts.is_empty() and _gff.plays.is_empty() and _root.feel.owned_count() == 0, "zero plugin work")
	_ok(hero.scale == Vector2.ONE and p.get_action_ids() == ["equip", "keep"] and p.find_child("RobotName", true, false) != null, "static hero; EQUIP / KEEP and robot name unchanged")
	_app().set_reduced_effects(false)
	p.close("clear")
	await _frames(2)
	await _show()
	_ok(_log("F007").size() == 1 and _spark.bursts.is_empty(), "REDUCED -> FULL + re-show never replays it")
	await _boot_feature("u03f")
	_app().set_reduced_effects(true)
	await _show()
	await create_timer(0.35).timeout
	_ok(_root.feel.has_played("c005f007:unlock:daily") and _spark.bursts.is_empty() and _gff.plays.is_empty() and _root.feel.owned_count() == 0, "feature unlock: key consumed, zero plugin work")
	_ok(_top().get_action_ids() == ["got_it"] and _top().find_child("HeroArt", true, false).scale == Vector2.ONE, "feature popup static, GOT IT only")
	_complete("u03_reduced_zero_plugin_work")

func _u04() -> void:
	print("[u04 ceiling: <= 24 particles, <= 1.3 s, one particle group at a time, settle <= 1.12]")
	await _boot_robot("u04")
	_root.request_home_ceremonies()
	var hero: Control = null
	var max_owned := 0
	var max_scale := 1.0
	var t0 := Time.get_ticks_msec()
	var first_ms := -1
	var gone_ms := -1
	while Time.get_ticks_msec() - t0 < 2200:
		await process_frame
		if hero == null and _top() != null:
			hero = _top().find_child("HeroArt", true, false)
		var n: int = _root.feel.owned_count()
		max_owned = maxi(max_owned, n)
		if n > 0 and first_ms < 0:
			first_ms = Time.get_ticks_msec()
		if first_ms >= 0 and n == 0 and gone_ms < 0:
			gone_ms = Time.get_ticks_msec()
		if hero != null:
			max_scale = maxf(max_scale, hero.scale.x)
	var plan: Dictionary = _root.feel.dispatch_log().filter(func(r): return r[1] == "c005f007:robot:moppy")[0][2]
	_ok(int(plan["amount"]) <= FeedbackAdapter.PARTICLE_CEILING["MAJOR_UNLOCK"] and FeedbackAdapter.PARTICLE_CEILING["MAJOR_UNLOCK"] == 24, "plan amount %d <= 24" % int(plan["amount"]))
	_ok(_spark.bursts.size() == 1 and _spark.bursts[0][0] <= 24 and _spark.bursts[0][1] <= 1.3, "one burst, %d particles, lifetime %.2f s <= 1.3" % [_spark.bursts[0][0], _spark.bursts[0][1]])
	_ok(max_owned == 1, "one adapter-owned particle group at a time (max %d)" % max_owned)
	_ok(first_ms >= 0 and gone_ms >= 0 and gone_ms - first_ms <= 1400, "adapter work released within the 1.3 s ceiling (%d ms)" % (gone_ms - first_ms))
	var settle: Array = MetaRewardFeel.SETTLE["MAJOR_UNLOCK"]
	_ok(float(settle[0]) <= 1.12 and float(settle[1]) <= 1.3 and max_scale <= 1.1201 and max_scale > 1.0, "native settle peak %.3f <= 1.12, %.2f s" % [max_scale, float(settle[1])])
	_ok(hero != null and hero.scale.is_equal_approx(Vector2.ONE), "hero back at rest (no loop / spin of the hero)")
	_complete("u04_ceiling_not_exceeded")

func _u05() -> void:
	print("[u05 no replay: refresh, resize, re-drain, clear + re-show, EQUIP]")
	await _boot_robot("u05")
	await _show()
	var p = _top()
	_root.get_ceremonies().pending()
	_root.get_ceremonies().drain("home")
	_root.get_home().refresh()
	_sub.size = Vector2i(1536, 2048)
	await _frames(14)
	_sub.size = Vector2i(1080, 2160)
	await _frames(14)
	p.close("clear")
	await _frames(2)
	await _show()
	var shown: Array = _root.get_ceremonies().presented_log().filter(func(r): return r[0] == "robot:moppy")
	_ok(shown.size() == 2 and _log("F007").size() == 1 and _spark.bursts.size() == 1, "re-shown ceremony (2 presentations) celebrated once")
	await _press("equip")
	_ok(_e().robots.active_robot() == "moppy" and _e().meta_ui.is_seen("robot:moppy"), "EQUIP routed to the authority (active = moppy, acknowledged)")
	await _show()
	_root.get_home().refresh()
	await _frames(14)
	_ok(_log("F007").size() == 1 and _spark.bursts.size() == 1, "after equip + re-drain + refresh: still one request")
	_complete("u05_no_replay_refresh_equip_redrain")

func _u06() -> void:
	print("[u06 truth: wallet, roster / equipped, feature unlocks, reward ledgers identical around the feel]")
	await _boot_robot("u06")
	var before := _truth()
	var active0: String = _e().robots.active_robot()
	await _show()
	await create_timer(1.5).timeout
	_ok(_log("F007").size() == 1, "the feel ran")
	_ok(_diff(before, _truth()).is_empty() and _e().robots.active_robot() == active0, "robot ceremony feel: authority identical (active still %s) %s" % [active0, str(_diff(before, _truth()))])
	await _boot_feature("u06f")
	before = _truth()
	await _show()
	await create_timer(1.5).timeout
	_ok(_log("F007").size() == 1 and _diff(before, _truth()).is_empty(), "feature ceremony feel: authority identical %s" % str(_diff(before, _truth())))
	_complete("u06_truth_unchanged")

func _u07() -> void:
	print("[u07 World Transition: not mapped to any intent]")
	await _boot_robot("u07")
	await _show()
	var n: int = _root.feel.dispatch_log().size()
	_root.get_meta_reward_feel()._on_ceremony_shown("world:test", "world_unlock")
	_root.get_meta_reward_feel()._on_ceremony_shown("world:test", "world_transition")
	await _frames(14)
	_ok(_root.feel.dispatch_log().size() == n and _log().size() == 1, "world kinds request nothing")
	_ok(not _root.feel.has_played("c005f007:world:test") and _spark.bursts.size() == 1, "no world key consumed, no extra burst")
	_complete("u07_world_not_mapped")

const NO_AUTHORITY := [".grant(", "request_save", ".save(", "nav.", ".go(", "mark_seen", "equip", "unlock_next_robot",
	"feature_unlocked", "set_active", "credit(", "debit(", "spend", "set_reduced", "FileAccess", "ConfigFile",
	"camera", "flash", "time_scale", "world"]

func _u08() -> void:
	print("[u08 static boundary: the F007 branch only requests feel]")
	var src := FileAccess.get_file_as_string("res://scripts/ui/feel/meta_reward_feel.gd")
	var code := "\n".join(Array(src.split("\n")).filter(func(l): return not String(l).strip_edges().begins_with("#")))
	var hits: Array = NO_AUTHORITY.filter(func(w): return code.contains(w))
	_ok(hits.is_empty(), "no grant / spend / save / equip / unlock / world code %s" % str(hits))
	var lines: Array = Array(code.split("\n")).map(func(l): return String(l).strip_edges())
	var at := lines.find("\"robot_unlock\", \"feature_unlock\":")
	_ok(at >= 0 and lines[at + 1] == "_play(\"F007\", \"MAJOR_UNLOCK\", hero, \"c005f007:\" + key)" and lines[at + 2].ends_with(":"), "robot / feature branch = one _play(MAJOR_UNLOCK) call %s" % str(lines.slice(at, at + 3)))
	_ok(code.count(".play(") == 1, "its only effect call is FeedbackAdapter.play")
	_complete("u08_static_boundary")

# ------------------------------------------------------------------ harness ----

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
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
	print("M43 C005F phase6 unlock feel evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
