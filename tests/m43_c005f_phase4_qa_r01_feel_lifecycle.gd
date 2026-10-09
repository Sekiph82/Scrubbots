extends SceneTree
## M43-C005F-PHASE4-QA-R01 — MetaRewardFeel await lifecycle safety, through the REAL app
## (main.tscn, 1080x2160 SubViewport) and the real F008 Gift-milestone ceremony seam
## (CeremonyPresenter.ceremony_shown -> MetaRewardFeel waits for the popup HeroArt layout to
## settle -> FeedbackAdapter REWARD). The settle wait is the coroutine that used to resume on a
## freed coordinator ("Resumed function '_play()' after await, but class instance is gone").
##   l01: the app root (and with it MetaRewardFeel + the adapter) is freed mid-settle, after the
##        wait already resumed once (exactly the M55 lap-end condition that produced the warning);
##   l02: the ceremony popup (the target) closes mid-settle while the coordinator lives;
##   l03: a live target keeps the shipping behaviour: one keyed REWARD after the settle;
##   l04: static guard: the settle wait is a static coroutine holding only a weakref.
## The exact engine warning text is checked by an external log scan (QA-R01 log), since a
## script cannot observe engine error output.
## Run: godot --headless --path . -s res://tests/m43_c005f_phase4_qa_r01_feel_lifecycle.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppStateScript = preload("res://scripts/app/app_state.gd")

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
	var bursts: Array = []
	func burst(_pos, o = {}) -> void:
		bursts.append(int(o.get("amount", 0)))
	func at(_n, o = {}) -> void:
		bursts.append(int(o.get("amount", 0)))
	func clear() -> void:
		pass

var EXPECTED_CASES := ["l01_root_freed_mid_settle", "l02_popup_closed_mid_settle", "l03_live_target_unchanged", "l04_static_guard"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _gff: SpyGff
var _spark: SpySpark
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	await _l01(); await _l02(); await _l03()
	_l04()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var p := "user://c005f_p4qa_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	MainScript.boot_save_path_override = p
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(14)
	_gff = SpyGff.new()
	_spark = SpySpark.new()
	_root.feel.set_backends_for_test(_gff, _spark)

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

func _e():
	return _root.get_app_state().economy

## Committed truth the feel layer must never touch (wallet, Gift queue, rewards, packs).
func _truth(eco) -> String:
	var s: Dictionary = eco.snapshot()
	return JSON.stringify([s.get("reward"), s.get("gift"), s.get("pending_packs"), s.get("pack_receipts"), s.get("collection")])

## Reach a committed Gift milestone and present its ceremony. With `teardown` valid this
## reproduces the M55 lap-end condition that produced "Resumed function '_play()' after await,
## but class instance is gone": the ceremony popup keeps moving (a still-settling layout), so
## MetaRewardFeel's settle wait RESUMES and suspends again for MOVING_FRAMES frames; then, in the
## SAME process_frame emission and BEFORE that wait's queued resume, `teardown` runs (M55 freed
## the app root from its own frame callback the same way). A process_frame connection made
## before the ceremony is shown is called ahead of the per-frame await re-connections.
## Invalid `teardown` = a live, untouched target.
const MOVING_FRAMES := 2
func _milestone_ceremony(tag: String, teardown: Callable) -> Dictionary:
	await _boot(tag)
	_e().gift.add_streak_sb("streak:p4qa:" + tag, 10)
	_root.flush_lifecycle("test")
	var out := {"truth": _truth(_e()), "path": MainScript.boot_save_path_override, "shown": "", "done": false,
		"popup": null, "ticks": 0, "feel": weakref(_root.get_meta_reward_feel())}   # weak: must not keep it alive
	_root.get_ceremonies().ceremony_shown.connect(func(key, kind):
		out["shown"] = "%s:%s" % [kind, key]
		out["popup"] = _root.get_modal_stack().top())
	var tick := func():
		if out["popup"] == null or out["done"] or not teardown.is_valid():
			return
		out["ticks"] += 1
		if out["ticks"] <= MOVING_FRAMES:
			(out["popup"] as Control).position.x += 4.0   # the settle loop sees a moving rect
		else:
			out["done"] = true
			teardown.call()
	process_frame.connect(tick)
	_root.request_home_ceremonies()
	for _i in range(30):
		if not String(out["shown"]).is_empty() and (out["done"] or not teardown.is_valid()):
			break
		await process_frame
	process_frame.disconnect(tick)
	out.erase("popup")
	return out

# ------------------------------------------------------------------- cases ----

func _l01() -> void:
	print("[l01 app root freed while MetaRewardFeel waits for the target layout]")
	var nodes0 := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans0 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var o: Dictionary
	var free_root := func():
		_root.free()
		_sub.free()
		_root = null
		_sub = null
	o = await _milestone_ceremony("l01", free_root)
	_ok(bool(o["done"]), "teardown ran while the settle wait was suspended after %d moving frames" % MOVING_FRAMES)
	var feel_ref: WeakRef = o["feel"]
	await _frames(20)   # > SETTLE_FRAMES: any suspended settle wait would have resumed by now
	_ok(String(o["shown"]).begins_with("gift_milestone:"), "the Gift milestone ceremony was shown (%s)" % o["shown"])
	_ok(_root == null and feel_ref.get_ref() == null, "app root and MetaRewardFeel are gone (not kept alive)")
	_ok(_gff.plays.is_empty() and _spark.bursts.is_empty(), "no plugin work for the torn-down request (no late / duplicate dispatch)")
	_ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes0, "tree Node count back to the pre-boot value (%d)" % nodes0)
	_ok(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) <= orphans0, "no orphan helper / popup Node")
	var app2 = AppStateScript.new(String(o["path"]))
	_ok(_truth(app2.economy) == o["truth"], "persisted reward / Gift / pack truth unchanged")
	_ok(app2.economy.gift.claimable().size() == 1, "the milestone is still unclaimed (feel claims nothing)")
	_complete("l01_root_freed_mid_settle")

func _l02() -> void:
	print("[l02 ceremony popup (the feel target) closes mid-settle; coordinator lives]")
	var close_top := func():
		var top = _root.get_modal_stack().top()
		if top != null:
			top.close("action:continue")
	var o: Dictionary = await _milestone_ceremony("l02", close_top)
	_ok(bool(o["done"]), "popup closed while the settle wait was suspended after %d moving frames" % MOVING_FRAMES)
	await _frames(20)
	var key := "c005f008:" + String(o["shown"]).trim_prefix("gift_milestone:")
	_ok(String(o["shown"]).begins_with("gift_milestone:"), "ceremony shown then closed before its layout settled")
	_ok(_root.get_meta_reward_feel().feel_log().is_empty() and not _root.feel.has_played(key), "no feel request for the vanished target (%s)" % key)
	_ok(_gff.plays.is_empty() and _spark.bursts.is_empty() and _root.feel.owned_count() == 0, "zero plugin work, nothing owned")
	_ok(_truth(_e()) == o["truth"], "reward / Gift / pack truth unchanged")
	_complete("l02_popup_closed_mid_settle")

func _l03() -> void:
	print("[l03 live target: unchanged shipping behaviour (one keyed REWARD after the settle)]")
	var o: Dictionary = await _milestone_ceremony("l03", Callable())
	await _frames(20)
	var key := "c005f008:" + String(o["shown"]).trim_prefix("gift_milestone:")
	var log: Array = _root.get_meta_reward_feel().feel_log()
	_ok(log == [["F008", "REWARD", key, "HeroArt"]], "one F008 REWARD on HeroArt with the ceremony key %s" % str(log))
	_ok(_spark.bursts == [8], "one 8-particle pickup burst (REWARD budget) %s" % str(_spark.bursts))
	await _frames(40)
	_ok(_root.get_meta_reward_feel().feel_log().size() == 1 and _spark.bursts.size() == 1, "no replay")
	_ok(_truth(_e()) == o["truth"], "reward / Gift / pack truth unchanged")
	_complete("l03_live_target_unchanged")

func _l04() -> void:
	print("[l04 static guard: no await on a MetaRewardFeel instance method]")
	var src := FileAccess.get_file_as_string("res://scripts/ui/feel/meta_reward_feel.gd")
	var awaits: Array = []
	var current := ""
	for line in src.split("\n"):
		if line.begins_with("func ") or line.begins_with("static func "):
			current = line
		elif line.strip_edges().begins_with("await ") or line.contains(" await "):
			awaits.append(current)
	_ok(not awaits.is_empty() and awaits.all(func(f): return String(f).begins_with("static func ")), "every await sits in a static func %s" % str(awaits))
	_ok(src.contains("weakref(self)") and src.contains(".get_ref()"), "the settle coroutine reaches the coordinator only through a weakref")
	_complete("l04_static_guard")

# -------------------------------------------------------------------- infra ----

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
	print("M43-C005F-PHASE4-QA-R01 feel lifecycle: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
