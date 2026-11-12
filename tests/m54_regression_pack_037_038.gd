extends SceneTree
## SB-M54-037 presentation-plugin one-shot / fail-open regression (gap cases only; the coverage
## map is in factory/jobs/137-plugin-regressions/build.md and TASKS.md). The REAL app root
## (main.tscn, 1080x2160 SubViewport, throw-away saves, injected clock / day) runs ONE scenario
## in five arms from the same seed save:
##   FULL      counting spy plugins
##   REDUCED   spies + Reduced Effects
##   ABSENT    adapter backends null (plugins missing)
##   DISABLED  no test seam; the GameFeelFlow + Spark autoloads are detached from the tree
##             before boot (= plugins disabled in the project), the adapter's own lookup finds none
##   THROWING  spy GFF + Spark whose every call raises (documented EXPECTED_FAULT_INJECTION)
## Scenario (each seam hit with its duplicate trigger):
##   terminal -> win      real Level 1 WON (SB-PHONE-2026-11-12-E: the win animation, no Results),
##                        then 3x duplicate WON + LOST terminal signals and a resize during it;
##                        Back -> Home, the reward flight runs to its end
##   popup refresh/reopen Set Complete ceremony, closed unacknowledged and re-drained, Home refresh
##   provider callbacks   rewarded Heart: verified delivery, then the same token delivered 2x more
##   acquisition          Heart +1 purchase
##   sweep                focus out / in, Home refresh, ceremony + pack re-drain
## Per arm: every seam reaches its end state; at most one adapter request per one-shot key; the
## sweep adds no request; after the ceilings no adapter-owned work and no Spark emitter is left.
## Across arms: authority truth (economy + progression) == FULL; ABSENT / DISABLED / THROWING
## make exactly FULL's requests, REDUCED a subset of them with zero plugin work; node / tween
## counts never exceed the plugin-free ABSENT arm; FULL's event count stays bounded.
## The rendered GFF / Spark check (SB-M54-038) is tests/m54_visual_regression_038.gd (windowed).
## Run: godot --headless --path . -s res://tests/m54_regression_pack_037_038.gd   (~1.5 min)

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const R = NavigationController.Route

class SpyGff extends RefCounted:
	var plays := 0
	func play(_n, _t, _o = {}) -> void:
		plays += 1
	func stop_all(_t = null) -> void:
		pass
	func get_effect_names() -> Array:
		return ["punch_scale"]

class SpySpark extends RefCounted:
	var presets := {"spark": {}, "pickup": {}, "confetti": {}}
	var bursts := 0
	func burst(_p, _o = {}) -> void:
		bursts += 1
	func at(_n, _o = {}) -> void:
		bursts += 1
	func clear() -> void:
		pass

class ThrowingGff extends SpyGff:
	func play(_n, _t, _o = {}) -> void:
		plays += 1
		var broken = null
		broken.explode()   # injected plugin failure (expected SCRIPT ERROR, see the test log)

class ThrowingSpark extends SpySpark:
	func burst(_p, _o = {}) -> void:
		bursts += 1
		var broken = null
		broken.explode()   # injected plugin failure (expected SCRIPT ERROR, see the test log)
	func at(_n, _o = {}) -> void:
		bursts += 1
		var broken = null
		broken.explode()

const ARMS := ["FULL", "REDUCED", "ABSENT", "DISABLED", "THROWING"]
## One-shot keys FULL must request exactly once (the feel ran on every seam).
const ONE_SHOT := ["c005f010:a1:L1", "win:a1:L1", "c005f006:set:1", "c005f009:rewarded:"]
const MAX_EVENTS := 40   ## bounded event count for the whole scenario (FULL)

var EXPECTED_CASES := ["m037_arm_full", "m037_arm_reduced", "m037_arm_absent", "m037_arm_disabled",
	"m037_arm_throwing", "m037_cross_arm"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _routes: Array = []
var _emitters: Array = []   ## WeakRef Spark emitters (DISABLED arm: none may exist)
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	AppState.test_unlock_all = true   # SB-M44-032: Life rewarded / ceremonies on an L1 fixture save
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	node_added.connect(_on_node_added)
	var seed := _uniq("seed")
	var s = AppState.new(seed, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(bool(s.request_save().get("ok", false)), "seed save written (one profile / pack RNG for every arm)")
	var bytes := FileAccess.get_file_as_bytes(seed)
	var res := {}
	for arm in ARMS:
		print("[m037_arm_%s one scenario, every seam + its duplicate trigger]" % arm.to_lower())
		res[arm] = await _run_arm(arm, bytes)
		_check_arm(arm, res[arm])
		_complete("m037_arm_" + arm.to_lower())
	_cross(res)
	_shutdown()
	AppState.test_unlock_all = false
	_cleanup()
	_done()

# ------------------------------------------------------------------ runner ----

func _on_node_added(n: Node) -> void:
	if n.get_parent() != null and n.get_parent().name == FeedbackAdapter.SPARK_POOL:
		_emitters.append(weakref(n))

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
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = save
	MainScript.boot_win_animation_override = 1
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	MainScript.boot_win_animation_override = -1
	await _frames(14)
	var gff = SpyGff.new()
	var spark = SpySpark.new()
	match arm:
		"FULL", "REDUCED":
			_root.feel.set_backends_for_test(gff, spark)
		"ABSENT":
			_root.feel.set_backends_for_test(null, null)
		"THROWING":
			gff = ThrowingGff.new()
			spark = ThrowingSpark.new()
			_root.feel.set_backends_for_test(gff, spark)
			print("  EXPECTED_FAULT_INJECTION: THROWING: every spy plugin call raises one SCRIPT ERROR ('explode' on null)")
	_root.get_app_state().set_reduced_effects(arm == "REDUCED")
	_routes = []
	_root.get_navigation().route_changed.connect(func(_f, to, _p): _routes.append(to))
	var r := {"why": [], "caps": _root.feel.capabilities()}
	await _terminal_results(r)
	await _popup_reopen(r)
	await _provider_dup(r)
	await _acquisition(r)
	var log0: int = _root.feel.dispatch_log().size()
	_root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _frames(4)
	_root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_root.get_home().refresh()
	_root.request_home_ceremonies()
	_root.request_earned_packs()
	await _frames(14)
	r["sweep"] = _root.feel.dispatch_log().size() - log0
	await create_timer(1.5).timeout   # > every DURATION_CEILING_S
	await _frames(4)
	var log: Array = _root.feel.dispatch_log().map(func(e): return [e[0], _norm(String(e[1]))])
	var keys: Array = log.map(func(e): return e[1]).filter(func(k): return not String(k).is_empty())
	r["log"] = log
	r["dup"] = keys.filter(func(k): return keys.count(k) > 1)
	r["keys"] = keys
	r["truth"] = _truth()
	r["owned"] = _root.feel.owned_count()
	r["emitters"] = _emitters.filter(func(w): return w.get_ref() != null).size()
	r["emitters_seen"] = _emitters.size()
	r["plugin_calls"] = gff.plays + spark.bursts if arm != "ABSENT" and arm != "DISABLED" else 0
	r["planned"] = _root.feel.dispatch_log().filter(func(e): return int(e[2]["amount"]) > 0).size()
	r["nodes"] = _sub.find_children("*", "", true, false).size()
	r["tweens"] = get_processed_tweens().size()
	print("  %s: %d requests, %d plugin calls, nodes %d, tweens %d %s" % [arm, log.size(), r["plugin_calls"], r["nodes"], r["tweens"], str(r["why"])])
	_shutdown()
	for node in detached:
		get_root().add_child(node)
	return r

## Real Level 1 WON -> the win animation (no Results); duplicate / stale terminals + a resize replay
## nothing; Back -> Home, the reward flight runs to its end, then the ceremonies drain.
func _terminal_results(r: Dictionary) -> void:
	if not _root.play_current_frontier().get("ok", false):
		r["why"].append("launch")
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
	if String(host.get_completion().get_state()) != "WON":
		r["why"].append("terminal " + String(host.get_completion().get_state()))
		return
	await _frames(14)
	var rc: Dictionary = host.get_terminal_receipt()
	var n0: int = _root.feel.dispatch_log().size()
	for _k in range(3):
		host.get_completion().terminal_reached.emit(&"WON", {})
		host.get_completion().terminal_reached.emit(&"LOST", {})
	_sub.size = Vector2i(1536, 2048)
	await _frames(6)
	_sub.size = Vector2i(1080, 2160)
	await _frames(14)
	r["win_anim"] = _routes.count(R.RESULTS) == 0
	r["terminal_replay"] = _root.feel.dispatch_log().size() - n0
	r["receipt_same"] = host.get_terminal_receipt() == rc and bool(rc.get("saved", false))
	_root.handle_back()
	var t0 := Time.get_ticks_msec()
	while _root.get_home().is_reward_flight_running() and Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	await _frames(14)
	r["win_anim"] = r["win_anim"] and _routes.count(R.HOME) == 1 and _routes.count(R.RESULTS) == 0
	var why := await _drain_ceremonies()
	if not why.is_empty():
		r["why"].append(why)

## Set Complete shown, closed without acknowledgement, re-drained: shown twice, celebrated once.
func _popup_reopen(r: Dictionary) -> void:
	var e = _root.get_app_state().economy
	for k in range(9):
		if e.collection.owned("s1_c%d" % k) == 0:
			e.collection.add_card("s1_c%d" % k)
	_root.request_home_ceremonies()
	await _frames(14)
	var p = _top()
	if p == null or String(p.popup_id) != "ceremony_set_complete":
		r["why"].append("set ceremony not shown")
		return
	await create_timer(0.5).timeout   # MetaRewardFeel waits for the hero layout to settle
	p.close("clear")
	await _frames(2)
	_root.get_home().refresh()
	_root.request_home_ceremonies()
	await _frames(14)
	await create_timer(0.5).timeout
	r["set_shown"] = _root.get_ceremonies().presented_log().filter(func(x): return x[0] == "set:1").size()
	var why := await _drain_ceremonies()
	if not why.is_empty():
		r["why"].append(why)
	r["set_acked"] = e.meta_ui.seen_keys().has("set:1")

## Rewarded Heart: one verified grant; the same provider callback twice more is refused.
func _provider_dup(r: Dictionary) -> void:
	var e = _root.get_app_state().economy
	var prov = ProviderDouble.new()
	e.rewarded.set_provider(prov)
	e.hearts.consume()
	e.hearts.consume()
	var h0: int = e.hearts.hearts()
	var p = _root.open_life("m037")
	await _frames(2)
	await create_timer(0.45).timeout
	p.get_action_button("watch").pressed.emit()
	await _frames(4)
	var tk: String = prov.last_token()
	var first: Dictionary = prov.deliver(tk, {"outcome": "completed", "verified": true})
	await _frames(14)
	var d1: Dictionary = prov.deliver(tk, {"outcome": "completed", "verified": true})
	var d2: Dictionary = prov.deliver(tk, {"outcome": "completed", "verified": true})
	await _frames(14)
	r["rewarded"] = [bool(first.get("ok", false)), bool(d1.get("ok", false)), bool(d2.get("ok", false)), e.hearts.hearts() - h0]
	r["life_popup"] = p

## Heart +1 purchase on the still-open Life popup: one committed Heart.
func _acquisition(r: Dictionary) -> void:
	var e = _root.get_app_state().economy
	var p = r["life_popup"]
	r.erase("life_popup")
	e.wallet.credit("scrub_bucks", 20000)
	var h0: int = e.hearts.hearts()
	await create_timer(0.45).timeout
	p.get_action_button("heart_plus_one").pressed.emit()
	await _frames(14)
	r["heart_buy"] = e.hearts.hearts() - h0
	p.close("test")
	await _frames(14)

# ------------------------------------------------------------------ checks ----

func _check_arm(arm: String, r: Dictionary) -> void:
	_ok(r["why"].is_empty(), "%s: every seam reached its end state %s" % [arm, str(r["why"])])
	_ok(r.get("win_anim", false) and r.get("terminal_replay", -1) == 0 and r.get("receipt_same", false), "%s: win animation then one Home route, no Results; 3x duplicate WON / LOST + resize: 0 new requests, receipt unchanged and saved" % arm)
	_ok(r.get("set_shown", 0) == 2 and r.get("set_acked", false), "%s: Set Complete presented twice (reopen), acknowledged once" % arm)
	_ok(r.get("rewarded", []) == [true, false, false, 1], "%s: rewarded verified once, duplicate provider callbacks x2 refused, +1 Heart %s" % [arm, str(r.get("rewarded"))])
	_ok(r.get("heart_buy", 0) == 1, "%s: Heart +1 purchase committed exactly" % arm)
	_ok(r["dup"].is_empty(), "%s: no one-shot key requested twice %s" % [arm, str(r["dup"])])
	_ok(r["sweep"] == 0, "%s: focus out / in, Home refresh, ceremony + pack re-drain: 0 new requests" % arm)
	_ok(r["owned"] == 0 and r["emitters"] == 0, "%s: after the ceilings: no adapter-owned work (%d), no live Spark emitter (%d)" % [arm, r["owned"], r["emitters"]])
	match arm:
		"FULL":
			for k in ONE_SHOT:
				_ok(r["keys"].filter(func(x): return String(x) == k or (k.ends_with(":") and String(x).begins_with(k))).size() == 1, "FULL: %s requested exactly once" % k)
			_ok(r["log"].size() <= MAX_EVENTS and r["plugin_calls"] == r["planned"] and r["planned"] > 0, "FULL: %d requests (<= %d), plugin calls %d == planned dispatches %d" % [r["log"].size(), MAX_EVENTS, r["plugin_calls"], r["planned"]])
		"REDUCED":
			_ok(r["plugin_calls"] == 0, "REDUCED: zero plugin calls")
		"THROWING":
			_ok(r["plugin_calls"] == r["planned"] and r["planned"] > 0, "THROWING: %d injected throws (one per planned dispatch), every seam still completed" % r["plugin_calls"])
		"DISABLED":
			_ok(not r["caps"]["gff"] and not r["caps"]["spark"] and r["emitters_seen"] == 0, "DISABLED: adapter finds no plugin autoload; no Spark emitter ever spawned")

func _cross(res: Dictionary) -> void:
	print("[m037_cross_arm authority truth, requests, nodes across the five arms]")
	var full: Dictionary = res["FULL"]
	var base: Dictionary = res["ABSENT"]
	for arm in ARMS:
		var r: Dictionary = res[arm]
		_ok(r["truth"] == full["truth"], "%s: authority truth == FULL %s" % [arm, str(_diff(full["truth"], r["truth"]))])
		_ok(r["nodes"] <= base["nodes"] and r["tweens"] <= base["tweens"], "%s: nodes %d / tweens %d <= plugin-free ABSENT %d / %d" % [arm, r["nodes"], r["tweens"], base["nodes"], base["tweens"]])
		if arm == "REDUCED":
			_ok(r["log"].all(func(x): return full["log"].has(x)) and not r["log"].is_empty(), "REDUCED: every request is a FULL request (%d of %d)" % [r["log"].size(), full["log"].size()])
		elif arm != "FULL":
			_ok(_sorted(r["log"]) == _sorted(full["log"]), "%s: exactly FULL's requests (%d)" % [arm, r["log"].size()])
	_complete("m037_cross_arm")

# ------------------------------------------------------------------ helpers ----

## Acknowledge every ceremony the app shows, by its first CTA (Continue / Got it / Equip).
func _drain_ceremonies() -> String:
	for _i in range(40):
		var p = _top()
		if p == null:
			return ""
		if not String(p.popup_id).begins_with("ceremony_"):
			return "unexpected popup " + String(p.popup_id)
		await create_timer(0.45).timeout
		p.get_action_button(p.get_action_ids()[0]).pressed.emit()
		await _frames(14)
	return "ceremony drain did not end"

## Rewarded tokens embed the wall clock: compare them by kind only.
static func _norm(k: String) -> String:
	var i := k.find("c005f009:rewarded:")
	return k if i == -1 else k.substr(0, i + 18)

## Authority truth: economy + progression, section -> JSON (wall-clock anchors and the wall-clock
## part of rewarded tokens excluded).
func _truth() -> Dictionary:
	var app = _root.get_app_state()
	var out := {"progression": JSON.stringify(app.progression.snapshot())}
	var s: Dictionary = app.economy.snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	var rw := RegEx.create_from_string("rw_([a-z_]+)_[0-9]+_")
	for k in s:
		out["economy." + String(k)] = rw.sub(JSON.stringify(s[k]), "rw_$1_", true)
	return out

func _diff(a: Dictionary, b: Dictionary) -> Array:
	return a.keys().filter(func(k): return not b.has(k) or b[k] != a[k])

static func _sorted(a: Array) -> Array:
	var c := a.map(func(x): return str(x))
	c.sort()
	return c

func _top():
	return _root.get_modal_stack().top()

func _uniq(tag: String) -> String:
	var p := "user://m54_037_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M54 regression pack 037-038: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
