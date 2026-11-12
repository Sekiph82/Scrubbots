extends SceneTree
## SB-M43-C005F-015 — end-to-end GameFeelFlow / Saltmire Spark feel validation. Every path runs
## in the REAL app (main.tscn, 1080x2160 SubViewport, throw-away test saves) through the shipping
## seams, together with the owner Flow videos those paths play (win animation WIN, Gift milestone,
## Set Complete, Standard / Premium pack openings, Home world video):
##   won   gameplay (real Level 1 WON, native cleaning cues) -> F010 bridge -> the win animation
##         (WIN confetti + WIN video; SB-PHONE-2026-11-12-E, no Results), skipped by Back ->
##         HOME -> reward flight (REWARD pickups) + Home state change (F012 MICRO) -> Gift
##         milestone ceremony on Home (its own video: one decoder at a time)
##   gift  Gift milestone ceremonies 1..1000 -> Gift claims 10 + 1000 -> Standard + Premium pack
##   meta  Set Complete + Master Collection ceremonies
##   robot Robot Unlock at L25 (MAJOR_UNLOCK) -> EQUIP
##   acq   acquisition confirmation: Life Heart +1 (SMALL) + full refill (REWARD)
## Each path runs in five arms from the SAME seed save: OFF (plugins absent = disabled fallback),
## FULL (counting spy plugins), REDUCED (spies), FAULT (spy Spark throws on every burst) and REAL
## (the installed plugins). Per arm: the path completes; the authority truth (economy +
## progression) equals the OFF arm (presentation never changes economy); every plugin call came
## through the one FeedbackAdapter (spies count it, the real autoloads see zero work in spy arms);
## REDUCED = zero plugin calls; one-shot keys never repeat (no double effect with the videos);
## resize / background-foreground / refresh / re-drain replay nothing; after the ceilings no
## adapter work, Spark emitter or extra node / tween is left; at most one video decoder plays.
## The owner phone visual gate is NOT automated here (pending owner phone review).
## Run: godot --headless --path . -s res://tests/m43_c005f_015_e2e_feel.gd   (~5 min, local only)

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")

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
	var calls := 0
	func burst(_p, _o = {}) -> void:
		calls += 1
		var broken = null
		broken.explode()   # injected plugin failure (expected SCRIPT ERROR, see the test log)
	func at(_n, _o = {}) -> void:
		pass
	func clear() -> void:
		pass

const PATHS := ["won", "gift", "meta", "robot", "acq"]
const ARMS := ["OFF", "FULL", "REDUCED", "FAULT", "REAL"]
## Key prefixes the FULL arm must request on each path (the feel actually ran end to end).
const EXPECT := {
	"won": ["c005f010:a1:L1", "win:a1:L1", "win:a1:L1:Fly_scrub_bucks"],
	"gift": ["c005f008:gift:", "c005f008:gift_claim:", ":card0:reveal"],
	"meta": ["c005f006:set:1", "c005f006:master"],
	"robot": ["c005f007:robot:moppy"],
	"acq": [],
}
## Paths whose FULL arm must show an owner Flow video while the feel runs.
const VIDEO_PATHS := ["won", "gift", "meta"]

var EXPECTED_CASES: Array = []

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _gff: SpyGff
var _spark
var _now := [1790000000]
var _day := [20000]
## per-frame probes
var _players: Array = []      ## WeakRef VideoStreamPlayer
var _emitters: Array = []     ## WeakRef Spark emitters (added under the real SaltmireSparkPool)
var _max_playing := 0
var _max_owned_reduced := 0
var _gff_real_started := 0

func _initialize() -> void:
	for p in PATHS:
		EXPECTED_CASES.append("p_%s" % p)
	EXPECTED_CASES.append("s01_static_single_adapter")
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	node_added.connect(_on_node_added)
	process_frame.connect(_probe)
	var gff_real = get_root().get_node_or_null("GameFeelFlow")
	if gff_real != null:
		gff_real.effect_started.connect(func(_n): _gff_real_started += 1)
	_ok(gff_real != null and get_root().get_node_or_null("Spark") != null, "both installed plugin autoloads present (REAL arm uses them)")
	var only := OS.get_cmdline_user_args()   # debugging: `-- won gift` runs those paths only
	for p in PATHS:
		if only.is_empty() or only.has(p):
			await _run_path(p)
	_s01()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ probes ----

func _on_node_added(n: Node) -> void:
	if n is VideoStreamPlayer:
		_players.append(weakref(n))
	elif n.get_parent() != null and n.get_parent().name == FeedbackAdapter.SPARK_POOL:
		_emitters.append(weakref(n))

func _probe() -> void:
	var playing := 0
	for w in _players:
		var v = w.get_ref()
		if v != null and v.is_inside_tree() and v.is_playing():
			playing += 1
	if playing > _max_playing and playing > 1:
		print("  decoders > 1: ", _players.filter(func(w): return w.get_ref() != null and w.get_ref().is_inside_tree() and w.get_ref().is_playing()).map(func(w): return str(w.get_ref().get_path()) + " " + w.get_ref().stream.resource_path))
	_max_playing = maxi(_max_playing, playing)
	if _root != null and is_instance_valid(_root) and _root.feel != null and _root.feel.reduced():
		_max_owned_reduced = maxi(_max_owned_reduced, _root.feel.owned_count())

func _live_emitters() -> int:
	return _emitters.filter(func(w): return w.get_ref() != null).size()

# ------------------------------------------------------------------ runner ----

func _run_path(path: String) -> void:
	print("[p_%s end-to-end path x %s]" % [path, str(ARMS)])
	var seed := _uniq(path + "_seed")
	var s = AppState.new(seed, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(bool(s.request_save().get("ok", false)), "%s: seed save written (one pack RNG / profile for every arm)" % path)
	var bytes := FileAccess.get_file_as_bytes(seed)
	var res := {}
	for arm in ARMS:
		res[arm] = await _run_arm(path, arm, bytes)
	var off: Dictionary = res["OFF"]
	var full: Dictionary = res["FULL"]
	for arm in ARMS:
		var r: Dictionary = res[arm]
		_ok(r["done"], "%s/%s: path completed %s" % [path, arm, r["why"]])
		_ok(r["truth"] == off["truth"], "%s/%s: authority truth == OFF (presentation changed nothing) %s" % [path, arm, str(_diff(off["truth"], r["truth"]))])
		_ok(r["max_playing"] <= 1, "%s/%s: at most one video decoder playing (max %d)" % [path, arm, r["max_playing"]])
		_ok(r["dup_keys"].is_empty(), "%s/%s: no one-shot key requested twice %s" % [path, arm, str(r["dup_keys"])])
		_ok(r["replayed"].is_empty(), "%s/%s: resize / focus out-in / refresh / re-drain replay nothing %s" % [path, arm, str(r["replayed"])])
		_ok(r["owned_after"] == 0 and r["emitters_after"] == 0, "%s/%s: after the ceilings: no adapter-owned work (%d), no live Spark emitter (%d)" % [path, arm, r["owned_after"], r["emitters_after"]])
		_ok(r["nodes"] == off["nodes"] and r["tweens"] <= off["tweens"], "%s/%s: no node / tween growth vs OFF (nodes %d vs %d, tweens %d vs %d)" % [path, arm, r["nodes"], off["nodes"], r["tweens"], off["tweens"]])
		if arm != "REAL":
			_ok(r["real_emitters"] == 0 and r["real_gff"] == 0, "%s/%s: installed plugins saw zero calls (all work went through the adapter's backends)" % [path, arm])
	# FULL: the feel ran, through the adapter only, within the ceilings.
	for pre in EXPECT[path]:
		_ok(full["keys"].any(func(k): return String(k).contains(pre)), "%s/FULL: requested %s" % [path, pre])
	_ok(not full["log"].is_empty(), "%s/FULL: %d adapter requests" % [path, full["log"].size()])
	_ok(full["spy_bursts"] == full["planned_bursts"], "%s/FULL: spy Spark bursts == adapter plans with particles %s" % [path, str(full["spy_bursts"])])
	_ok(full["spy_gff"] == 0, "%s/FULL: GFF never driven (every target is a Control)" % path)
	if VIDEO_PATHS.has(path):
		_ok(full["max_playing"] == 1, "%s/FULL: owner Flow video played alongside the feel (one decoder)" % path)
	# REDUCED: identities consumed, zero plugin work.
	var red: Dictionary = res["REDUCED"]
	_ok(red["spy_bursts"].is_empty() and red["spy_gff"] == 0 and red["max_owned"] == 0, "%s/REDUCED: zero plugin calls, zero adapter-owned work" % path)
	_ok(red["log"].all(func(e): return full["log"].has(e)), "%s/REDUCED: every request is a FULL request (nothing extra) %d/%d" % [path, red["log"].size(), full["log"].size()])
	# FAULT / REAL / OFF: the same requests as FULL (failures stay inside the adapter's dispatch).
	for arm in ["FAULT", "REAL", "OFF"]:
		_ok(_sorted(res[arm]["log"]) == _sorted(full["log"]), "%s/%s: same adapter requests as FULL" % [path, arm])
	_ok(res["FAULT"]["faults"] == full["spy_bursts"].size(), "%s/FAULT: every burst threw (%d injected) and the path still completed" % [path, res["FAULT"]["faults"]])
	_ok(res["REAL"]["real_emitters"] == full["spy_bursts"].size(), "%s/REAL: installed Spark spawned %d bursts (== FULL), all freed" % [path, res["REAL"]["real_emitters"]])
	_complete("p_" + path)

func _run_arm(path: String, arm: String, seed_bytes: PackedByteArray) -> Dictionary:
	var save := _uniq("%s_%s" % [path, arm])
	var f := FileAccess.open(save, FileAccess.WRITE)
	f.store_buffer(seed_bytes)
	f.close()
	_shutdown()
	_players.clear()
	_emitters.clear()
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
	_gff = SpyGff.new()
	_spark = SpySpark.new()
	match arm:
		"OFF":
			_root.feel.set_backends_for_test(null, null)
		"FULL", "REDUCED":
			_root.feel.set_backends_for_test(_gff, _spark)
		"FAULT":
			_spark = FaultySpark.new()
			_root.feel.set_backends_for_test(_gff, _spark)
			print("  EXPECTED_FAULT_INJECTION: %s/FAULT: every Spark burst raises one SCRIPT ERROR ('explode' on null) inside a spy plugin" % path)
	_app().set_reduced_effects(arm == "REDUCED")
	_max_playing = 0
	_max_owned_reduced = 0
	_gff_real_started = 0
	var why := ""
	match path:
		"won": why = await _path_won()
		"gift": why = await _path_gift()
		"meta": why = await _path_meta()
		"robot": why = await _path_robot()
		"acq": why = await _path_acq()
	var log0: int = _root.feel.dispatch_log().size()
	# Idempotency: resize, background / foreground, Home refresh, ceremony re-drain.
	_sub.size = Vector2i(1536, 2048)
	await _frames(10)
	_sub.size = Vector2i(1080, 2160)
	_root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _frames(4)
	_root.propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_root.get_home().refresh()
	_root.request_home_ceremonies()
	await _frames(14)
	var replayed: Array = _root.feel.dispatch_log().slice(log0).map(func(e): return [e[0], e[1]])
	await create_timer(1.5).timeout   # > every DURATION_CEILING_S
	await _frames(4)
	var log: Array = _root.feel.dispatch_log().map(func(e): return [e[0], e[1]])
	var keys: Array = log.map(func(e): return e[1]).filter(func(k): return not String(k).is_empty())
	var dup: Array = []
	for k in keys:
		if keys.count(k) > 1 and not dup.has(k):
			dup.append(k)
	var planned: Array = []
	for e in _root.feel.dispatch_log():
		if int(e[2]["amount"]) > 0:
			planned.append(int(e[2]["amount"]))
	var r := {
		"done": why.is_empty(), "why": why, "truth": _truth(), "log": log, "keys": keys, "dup_keys": dup,
		"replayed": replayed, "max_playing": _max_playing, "max_owned": _max_owned_reduced,
		"owned_after": _root.feel.owned_count(), "emitters_after": _live_emitters(),
		"real_emitters": _emitters.size(), "real_gff": _gff_real_started,
		"nodes": _sub.find_children("*", "", true, false).size(), "tweens": get_processed_tweens().size(),
		"spy_bursts": _sorted(_spark.bursts) if _spark is SpySpark else [], "spy_gff": _gff.plays.size(),
		"planned_bursts": _sorted(planned), "faults": _spark.calls if _spark is FaultySpark else 0,
	}
	print("  %s/%s: %d requests, %d bursts, max decoders %d, nodes %d, tweens %d%s" % [path, arm, log.size(), r["spy_bursts"].size(), _max_playing, r["nodes"], r["tweens"], "" if why.is_empty() else " INCOMPLETE " + why])
	return r

# ------------------------------------------------------------------- paths ----
## Each returns "" when the path reached its end state, else what was missing.

func _path_won() -> String:
	var launch: Dictionary = _root.play_current_frontier()
	if not launch.get("ok", false):
		return "launch " + str(launch)
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
	# Same driver as tests/m43_c005f_phase4_terminal_home_micro.gd: owner supply-plan clicks +
	# runtime ticks until the CompletionController latches the terminal itself.
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
		if guard % 50 == 0 and not host.get_completion().is_terminal() and _root.feel.dispatch_log().size() > 0:
			return "adapter requests during clearing " + str(_root.feel.dispatch_log().map(func(e): return e[1]))
	# Cleaning comparison: production cleaning stays native (CleaningEffectsController cues);
	# while the cells cleared the adapter got nothing (checked above, before the terminal).
	if not _app().effects.is_reduced() and host._cleaning_fx.get_peak_active() == 0:
		return "no native cleaning cue observed"
	if String(host.get_completion().get_state()) != "WON":
		return "terminal " + String(host.get_completion().get_state())
	await _frames(20)
	if _root.get_results_screen().visible or _root.get_win_overlay() == null:
		return "win animation not shown (or Results shown)"
	await create_timer(0.5).timeout
	_root.handle_back()   # skip the rest of the win animation -> Home
	await _frames(2)
	if _root.get_navigation().route_name() != "HOME":
		return "not Home after the win animation"
	var t0 := Time.get_ticks_msec()
	while _root.get_home().is_reward_flight_running() and Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	await _frames(14)
	return await _drain_ceremonies()

func _path_gift() -> String:
	var occ: Array = _e().gift.add_streak_sb("streak:e2e:gift", 1000)
	var by := {}
	for o in occ:
		by[int(o["milestone"])] = String(o["id"])
	_root.request_home_ceremonies()
	await _frames(14)
	var why: String = await _drain_ceremonies()
	if not why.is_empty():
		return why
	for m in [10, 1000]:
		if not by.has(m):
			return "milestone %d not reached" % m
		if not (_top() != null and String(_top().popup_id) == "gift_bar"):
			_root._on_home_shortcut("gift_bar")
			await _frames(4)
		await create_timer(0.45).timeout
		_top().get_action_button("gift:" + by[m]).pressed.emit()
		await _frames(4)
		var p = _top()
		var want := "standard_pack" if m == 10 else "premium_pack"
		if p == null or String(p.popup_id) != want:
			return "gift %d: %s not opened (%s)" % [m, want, String(p.popup_id) if p != null else "none"]
		why = await _drive_pack(p)
		if not why.is_empty():
			return why
	if _e().pending_packs.size() != 0:
		return "packs left pending"
	_top().close("test")
	await _frames(14)
	return await _drain_ceremonies()

func _path_meta() -> String:
	for n in range(1, 16):
		for k in range(9):
			var cid := "s%d_c%d" % [n, k]
			if _e().collection.owned(cid) == 0:
				_e().collection.add_card(cid)
	for n in range(2, 16):
		_e().meta_ui.mark_seen("set:%d" % n)
	_root.request_home_ceremonies()
	await _frames(14)
	var shown: Array = []
	var why: String = await _drain_ceremonies(shown)
	if not why.is_empty():
		return why
	if not (shown.has("ceremony_set_complete") and shown.has("ceremony_master_complete")):
		return "ceremonies shown " + str(shown)
	return ""

func _path_robot() -> String:
	while _app().progression.current_level() < _app().feature_unlock_level("robots"):
		_app().progression.record_win(_app().progression.current_level())
	_e().wallet.credit(EconomyWallet.BOT_PARTS, 250)
	if not bool(_app().actions.unlock_next_robot().get("ok", false)):
		return "unlock_next_robot refused"
	_root.request_home_ceremonies()
	await _frames(14)
	var shown: Array = []
	var why: String = await _drain_ceremonies(shown)
	if not why.is_empty():
		return why
	if not shown.has("ceremony_robot_unlock") or _e().robots.active_robot() != "moppy":
		return "robot unlock / equip missing %s active=%s" % [str(shown), _e().robots.active_robot()]
	return ""

func _path_acq() -> String:
	_e().wallet.credit("scrub_bucks", 20000)
	for _i in range(3):
		_e().hearts.consume()
	var p = _root.open_life("e2e")
	await _frames(2)
	var h0: int = _e().hearts.hearts()
	await create_timer(0.45).timeout
	p.get_action_button("heart_plus_one").pressed.emit()
	await _frames(14)
	if _e().hearts.hearts() != h0 + 1:
		return "Heart +1 not committed"
	await create_timer(0.45).timeout
	p.get_action_button("heart_refill").pressed.emit()
	await _frames(14)
	if _e().hearts.hearts() != _e().hearts.max_hearts():
		return "refill not committed"
	p.close("test")
	await _frames(14)
	return await _drain_ceremonies()

## Acknowledge every ceremony the app shows, by its first CTA (Continue / Got it / Equip).
func _drain_ceremonies(shown: Array = []) -> String:
	for _i in range(40):
		var p = _top()
		if p == null:
			return ""
		var id := String(p.popup_id)
		if not id.begins_with("ceremony_"):
			return "unexpected popup " + id
		shown.append(id)
		await create_timer(0.45).timeout
		p.get_action_button(p.get_action_ids()[0]).pressed.emit()
		await _frames(14)
	return "ceremony drain did not end"

## Real taps on a pack ceremony: open (video in FULL), skip the video after ~0.5 s like a
## player, wait for the reveal, route, until closed.
func _drive_pack(p) -> String:
	var opening := 0
	for _f in range(3000):
		if not is_instance_valid(p) or p.is_closed():
			await _frames(3)
			return ""
		match p.phase():
			"IDLE", "AWAIT_ROUTE":
				p.tap()
			"OPENING":
				if p.get_video_player() != null:
					opening += 1
					if opening == 30:
						p.tap()
		await process_frame
	return "pack ceremony did not close (%s)" % p.phase()

# ------------------------------------------------------------------ static ----

func _s01() -> void:
	print("[s01 static: one adapter instance, plugin names only inside it]")
	var hits: Array = []
	for path in _gd_files("res://scripts"):
		if path.ends_with("feedback_adapter.gd"):
			continue
		var src := FileAccess.get_file_as_string(path).replace("res://addons/game_feel_flow/LICENSE", "").replace("res://addons/saltmire_spark/LICENSE.txt", "")   # SB-M59 Credits shows the plugin licence texts
		if src.contains("GameFeelFlow") or src.contains("\"Spark\"") or src.contains("/root/Spark") or src.contains("addons/saltmire_spark") or src.contains("addons/game_feel_flow"):
			hits.append(path)
	_ok(hits.is_empty() and FileAccess.get_file_as_string("res://scripts/app/main.gd").count("FeedbackAdapter.new()") == 1, "plugins reachable only through the single FeedbackAdapter %s" % str(hits))
	_complete("s01_static_single_adapter")

func _gd_files(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_gd_files(dir + "/" + sub))
	return out

# ------------------------------------------------------------------ helpers ----

func _uniq(tag: String) -> String:
	var p := "user://c005f_015_%s_%d.save" % [tag, Time.get_ticks_usec()]
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

func _app():
	return _root.get_app_state()

func _e():
	return _app().economy

func _top():
	return _root.get_modal_stack().top()

## Authority truth: economy + progression, section -> JSON (wall-clock anchors excluded).
func _truth() -> Dictionary:
	var out := {"progression": JSON.stringify(_app().progression.snapshot())}
	var s: Dictionary = _e().snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	for k in s:
		out["economy." + String(k)] = JSON.stringify(s[k])
	return out

func _diff(a: Dictionary, b: Dictionary) -> Array:
	return a.keys().filter(func(k): return not b.has(k) or b[k] != a[k])

static func _sorted(a: Array) -> Array:
	var c := a.map(func(x): return str(x))
	c.sort()
	return c

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
	print("M43 C005F-015 e2e feel evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
