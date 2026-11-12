extends SceneTree
## M43-C005F-PHASE2 — pack feel on real shipping surfaces:
##   (w* / r*, the WON Results celebration and reward-row feel of SB-M43-C005F-003 / -004, were
##   removed with the WON Results by SB-PHONE-2026-11-12-E; the win animation's WIN and the Home
##   reward flight's REWARD pickups are covered by tests/sb_phone_2026_11_12_e_win_home.gd)
##   p*: SB-M43-C005F-005 Standard / Premium pack + card reveal feel;
##   g*: global — app wiring, static boundary, real plugins on a CanvasLayer / SubViewport.
## The REAL FeedbackAdapter is used everywhere; spy backends replace the plugins only where a
## call trace / fault must be observed (g03 uses the real GameFeelFlow + Spark autoloads).
##
## Run: godot --headless --path . -s res://tests/m43_c005f_phase2_results_pack_feel.gd

const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const EffectsSettingsService = preload("res://scripts/settings/effects_settings_service.gd")
const WinOverlay = preload("res://scripts/ui/win_overlay.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const StdFx = preload("res://tests/support/standard_pack_fixtures.gd")
const PremFx = preload("res://tests/support/premium_pack_fixtures.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")

const PLUGIN_WORDS := ["GameFeelFlow", "\"Spark\"", "/root/Spark", "Spark.", "GFF", "Saltmire", "punch_scale", "addons/"]
const FEEL_FILES := ["res://scripts/ui/win_overlay.gd", "res://scripts/ui/home/home_reward_flight.gd", "res://scripts/ui/ceremony/standard_pack_ceremony.gd",
	"res://scripts/ui/ceremony/premium_pack_ceremony.gd"]

class GffSpy extends Node:
	var calls: Array = []
	func play(effect, target, params = null) -> void:
		calls.append(["play", effect, target, params])
	func stop_all(node = null) -> void:
		calls.append(["stop_all", node])
	func get_effect_names() -> Array:
		return ["punch_scale"]

class SparkSpy extends Node:
	var calls: Array = []
	var fault := false
	var presets := {"spark": {"amount": 10, "lifetime": 0.45}, "pickup": {"amount": 12, "lifetime": 0.5}, "confetti": {"amount": 40, "lifetime": 0.9}}
	func burst(pos, opts = {}) -> void:
		calls.append({"kind": "burst", "pos": pos, "opts": opts, "frame": Engine.get_process_frames()})
		if fault:
			var broken = null
			broken.explode()   # injected plugin failure (expected SCRIPT ERROR, see test log)
	func at(node, opts = {}) -> void:
		calls.append({"kind": "at", "node": node, "opts": opts, "frame": Engine.get_process_frames()})
	func clear() -> void:
		calls.append({"kind": "clear"})

var EXPECTED_CASES := [
	"p01_standard_truth_and_landing_feel", "p02_premium_serialized_no_spam", "p03_new_duplicate_truth_unchanged",
	"p04_reopen_no_replay_no_reroll", "p05_reduced_zero_plugin_work", "p06_plugin_absent_or_throwing_pack_completes",
	"g01_app_wiring_one_adapter", "g02_static_boundary", "g03_real_plugins_on_popup_layer_and_subviewport",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack

func _initialize() -> void:
	await process_frame
	await _p01(); await _p02(); await _p03(); await _p04(); await _p05(); await _p06()
	await _g01(); _g02(); await _g03()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _feel(reduced := false, spies := true) -> Array:
	var fx := EffectsSettingsService.new()
	fx.set_reduced(reduced)
	var a := FeedbackAdapter.new()
	a.bind(self, fx)
	var g: GffSpy = null
	var s: SparkSpy = null
	if spies:
		g = GffSpy.new()
		s = SparkSpy.new()
		get_root().add_child(g)
		get_root().add_child(s)
		a.set_backends_for_test(g, s)
	return [a, fx, g, s]

func _drop(f: Array) -> void:
	f[0].unbind()
	for n in [f[2], f[3]]:
		if n != null and is_instance_valid(n):
			n.free()

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _wait(s: float) -> void:
	await create_timer(s, true, false, true).timeout

func _keys(a) -> Array:
	return a.dispatch_log().map(func(e): return [e[0], e[1]])

func _keys_of(a, intent: String) -> Array:
	return a.dispatch_log().filter(func(e): return e[0] == intent).map(func(e): return e[1])

func _uniq(tag: String) -> String:
	var p := "user://c005f_p2_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _mount_stack(size := Vector2i(1080, 1920)) -> void:
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_stack = ModalStack.new()
	_sub.add_child(_stack)
	_stack.set_synthetic_safe_insets(0, 96, 0, 64)

func _ceremony(model: Dictionary, premium: bool, reduced := false, f = null):
	var r: Dictionary = PremiumPackCeremony.create_premium(model, reduced) if premium else StandardPackCeremony.create(model, reduced)
	if not r["ok"]:
		_ok(false, "fixture rejected %s" % r["reason"])
		return null
	var p = r["popup"]
	p.video = null   # SB-VIDEO-003/004: native stages 1-3 (the video path is covered in c006 / c007)
	if f != null:
		p.bind_feedback(f[0])
	_stack.push(p)
	return p

func _until(p, phase_name: String) -> void:
	for _i in range(1200):
		if not is_instance_valid(p) or p.phase() == phase_name:
			return
		await process_frame
	_ok(false, "timed out waiting for %s" % phase_name)

func _card_info(p) -> Array:
	var out: Array = []
	for cv in p.get_card_views():
		out.append([cv.card["card_id"], cv.card["rarity"], cv.card["is_new"], cv.card["copies_after"],
			(cv.find_child("State", true, false).find_child("Text", true, false) as Label).text,
			(cv.find_child("Copies", true, false) as Label).text])
	return out

## Cards that should get a landing feel event: NEW or Rare-or-better, in model order.
func _eligible(model: Dictionary) -> Array:
	var out: Array = []
	for i in range(model["cards"].size()):
		var c: Dictionary = model["cards"][i]
		if bool(c["is_new"]) or String(c["rarity"]) != "COMMON":
			out.append(i)
	return out

func _code(path: String) -> String:
	var out := ""
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var i := line.find("#")
		out += (line if i == -1 else line.substr(0, i)) + "\n"
	return out

# ------------------------------------------------------- SB-M43-C005F-003 WON ----

func _p01() -> void:
	print("[p01 Standard: committed truth + owner grammar unchanged; feel only when a card has landed]")
	_mount_stack()
	var f := _feel()
	var model := StdFx.mixed("p01_std")
	var p = _ceremony(model, false, false, f)
	_ok(p.tap(), "Tap 1")
	var landed_ok := true
	var seen := 0
	for _i in range(1200):
		if p.phase() == "AWAIT_ROUTE":
			break
		if p.feel_log().size() > seen:
			var i: int = p.feel_log()[seen][0]
			landed_ok = landed_ok and is_equal_approx(p.get_card_views()[i].emerge, 1.0)
			seen = p.feel_log().size()
		await process_frame
	_ok(p.get_card_views().size() == 3 and p.frame_history() == [1, 2, 3, 4, 5, 6, 7, 8, 9] and not p.get_stage().visible and p.get_destinations_layer().visible, "3 cards, frames 01..09, pack gone, destinations shown")
	var expect: Array = _eligible(model)
	_ok(p.feel_log().map(func(e): return e[0]) == expect and p.feel_log().all(func(e): return e[1] == "REWARD" and e[2] == "p01_std:card%d:reveal" % e[0]), "REWARD for NEW / Rare-or-better cards only, model order %s" % str(p.feel_log()))
	_ok(landed_ok, "each event fired only after that card fully emerged into its slot")
	await _frames(2)
	var face_c: Vector2 = p.get_card_views()[expect[0]].get_badge().get_global_rect().get_center()
	var b: Array = f[3].calls.filter(func(c): return c["kind"] == "burst")
	_ok(b.size() == expect.size() and (b[0]["pos"] as Vector2).distance_to(face_c) < 4.0 and f[2].calls.is_empty(), "pickup at the card's NEW / DUPLICATE badge; no GFF call of any kind on card Controls")
	p.tap()
	await _until(p, "COMPLETE")
	await _frames(2)
	_ok(not is_instance_valid(p) or p.phase() == "COMPLETE", "Tap 2 routes and completes as before")
	_sub.free()
	_drop(f)
	_complete("p01_standard_truth_and_landing_feel")

func _p02() -> void:
	print("[p02 Premium: exactly 5, guarantee + 3+2 layout unchanged, bursts serialized]")
	_mount_stack()
	var f := _feel()
	var model := PremFx.all_new("p02_prem")
	var p = _ceremony(model, true, false, f)
	p.tap()
	await _until(p, "AWAIT_ROUTE")
	await _frames(2)
	var cards: Array = p.get_model()["cards"]
	_ok(cards.size() == 5 and String(cards[0]["rarity"]) != "COMMON" and cards.map(func(c): return c["card_id"]) == model["cards"].map(func(c): return c["card_id"]), "5 committed cards in draw order; card 0 Rare-or-better")
	var ys: Array = p.get_card_views().map(func(cv): return roundi(cv.slot_point().y))
	_ok(ys[0] == ys[1] and ys[1] == ys[2] and ys[3] == ys[4] and ys[3] > ys[0], "3 + 2 hold layout unchanged")
	var b: Array = f[3].calls.filter(func(c): return c["kind"] == "burst")
	var frames: Array = b.map(func(c): return int(c["frame"]))
	var distinct := {}
	for fr in frames:
		distinct[fr] = true
	_ok(b.size() == 5 and distinct.size() == 5 and b.all(func(c): return int(c["opts"]["amount"]) == 8), "all-NEW Premium: 5 REWARD bursts on 5 different frames (one per landing), never WIN / MAJOR_UNLOCK")
	_ok(p.feel_log().all(func(e): return e[1] == "REWARD"), "only the REWARD intent is used by the ceremony")
	_sub.free()
	_drop(f)
	_complete("p02_premium_serialized_no_spam")

func _p03() -> void:
	print("[p03 NEW / DUPLICATE / copies truth identical with and without feel]")
	var infos: Array = []
	for with_feel in [false, true]:
		_mount_stack()
		var f = _feel() if with_feel else null
		var p = _ceremony(PremFx.mixed("p03_%s" % str(with_feel)), true, false, f)
		p.tap()
		await _until(p, "AWAIT_ROUTE")
		infos.append(_card_info(p))
		_sub.free()
		if f != null:
			_drop(f)
	_ok(infos[0] == infos[1], "card ids / rarity / NEW / copies / badge / count text unchanged %s" % str(infos[1]))
	_complete("p03_new_duplicate_truth_unchanged")

func _p04() -> void:
	print("[p04 reopen / resume of the same committed presentation: no reroll, no replay]")
	_mount_stack()
	var f := _feel()
	var model := StdFx.all_new("p04_std")
	var p = _ceremony(model, false, false, f)
	p.tap()
	await _until(p, "AWAIT_ROUTE")
	var first: int = f[3].calls.size()
	var m1: Dictionary = p.get_model()
	_sub.free()
	_mount_stack()
	var p2 = _ceremony(model, false, false, f)   # same presentation_id reopened
	p2.tap()
	await _until(p2, "AWAIT_ROUTE")
	await _frames(2)
	_ok(first == 3 and f[3].calls.size() == first and p2.feel_log().is_empty(), "reopened presentation: 0 new feel events (keys consumed)")
	_ok(p2.get_model() == m1 and p2.phase() == "AWAIT_ROUTE", "same committed model (no reroll); flow unchanged")
	_sub.free()
	_drop(f)
	_complete("p04_reopen_no_replay_no_reroll")

func _p05() -> void:
	print("[p05 Reduced pack grammar: zero adapter / plugin work, same truth]")
	_mount_stack()
	var f := _feel(true)
	var p = _ceremony(PremFx.all_new("p05_prem"), true, true, f)
	p.tap()
	await _until(p, "AWAIT_ROUTE")
	await _frames(2)
	_ok(p.feel_log().is_empty() and f[0].dispatch_log().is_empty() and f[3].calls.is_empty(), "Reduced ceremony never calls the adapter")
	_ok(p.get_card_views().all(func(cv): return cv.get_glow() == null or is_equal_approx(cv.glow_alpha(), 0.5)), "static NEW glow truth retained")
	_sub.free()
	_drop(f)
	_complete("p05_reduced_zero_plugin_work")

func _p06() -> void:
	print("[p06 absent / throwing plugins: the pack flow still completes]")
	for mode in ["absent", "throwing"]:
		_mount_stack()
		var f := _feel()
		if mode == "absent":
			f[0].set_backends_for_test(null, null)
		else:
			f[3].fault = true
			print("  EXPECTED_FAULT_INJECTION: SCRIPT ERRORs ('explode' on null) follow, deliberately raised inside a spy plugin")
		var p = _ceremony(StdFx.all_new("p06_%s" % mode), false, false, f)
		var done := [false]
		p.presentation_completed.connect(func(_id): done[0] = true)
		p.tap()
		await _until(p, "AWAIT_ROUTE")
		p.tap()
		for _i in range(600):
			if done[0]:
				break
			await process_frame
		_ok(done[0], "%s plugins: Tap 1 -> hold -> Tap 2 -> complete" % mode)
		_sub.free()
		_drop(f)
	_complete("p06_plugin_absent_or_throwing_pack_completes")

# ------------------------------------------------------------------- global ----

func _g01() -> void:
	print("[g01 app root hands its ONE adapter to Home (reward flight)]")
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	MainScript.boot_save_path_override = _uniq("g01")
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(4)
	_ok(root.feel != null and root.get_home().get_reward_flight()._feel == root.feel, "Home reward flight bound to the app root's adapter")
	var users: Array = []
	for p in _gd("res://scripts"):
		if _code(p).contains("FeedbackAdapter.new()"):
			users.append(p)
	_ok(users == ["res://scripts/app/main.gd"], "still exactly one production adapter %s" % str(users))
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	_complete("g01_app_wiring_one_adapter")

func _g02() -> void:
	print("[g02 static: win animation / reward flight / ceremonies reach plugins only through the adapter]")
	var hits: Array = []
	for p in FEEL_FILES:
		var code := _code(p)
		for w in PLUGIN_WORDS + ["flash", "camera", "time_scale", "freeze", "shake", "\"WIN\"" if p.contains("ceremony") else "#none#", "MAJOR_UNLOCK", "MAJOR_REWARD"]:
			if code.contains(w):
				hits.append("%s:%s" % [p.get_file(), w])
	_ok(hits.is_empty(), "no plugin name / prohibited effect; ceremonies never use WIN / MAJOR_* %s" % str(hits))
	var all_clear: Array = _gd("res://scripts").filter(func(p): return _code(p).contains("Spark.clear") or _code(p).contains("spark.clear("))
	_ok(all_clear.is_empty(), "no global Spark clear anywhere %s" % str(all_clear))
	_complete("g02_static_boundary")

func _g03() -> void:
	print("[g03 REAL plugins: bursts land on the popup CanvasLayer / SubViewport and are freed]")
	var f := _feel(false, false)
	# Popup case: a real ModalStack (CanvasLayer) directly in the root viewport.
	_stack = ModalStack.new()
	get_root().add_child(_stack)
	var p = _ceremony(StdFx.all_new("g03_std"), false, false, f)
	p.tap()
	var on_layer := false
	for _i in range(1200):
		if p.phase() == "AWAIT_ROUTE":
			break
		for c in _stack.get_children():
			if c is Node2D and c.has_method("setup"):
				on_layer = true
		await process_frame
	_ok(p.feel_log().size() == 3 and on_layer, "3 real REWARD bursts reparented into the ModalStack CanvasLayer (drawn above the scrim)")
	await _wait(FeedbackAdapter.DURATION_CEILING_S["REWARD"] + 0.3)
	var left: Array = _stack.get_children().filter(func(c): return c is Node2D and c.has_method("setup") and not c.is_queued_for_deletion())
	_ok(left.is_empty() and f[0].owned_count() == 0, "bursts freed inside the REWARD ceiling")
	_stack.free()
	# SubViewport case: the win animation inside a SubViewport (Spark's pool lives in the root viewport).
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var res = WinOverlay.new()
	res.video = null
	res.feel = f[0]
	res.feel_key = "win:a9:L10"
	_sub.add_child(res)
	var in_sub := false
	for _i in range(30):
		await process_frame
		for c in _sub.get_children():
			if c is Node2D and c.has_method("setup"):
				in_sub = true
	_ok(in_sub, "WIN confetti reparented into the win animation's SubViewport canvas")
	res.free()
	_sub.free()
	f[0].unbind()
	_complete("g03_real_plugins_on_popup_layer_and_subviewport")

func _gd(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for fl in d.get_files():
		if fl.ends_with(".gd"):
			out.append(dir + "/" + fl)
	for s in d.get_directories():
		out.append_array(_gd(dir + "/" + s))
	return out

# ------------------------------------------------------------------- infra -----

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
	print("M43-C005F-PHASE2 results + pack feel: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
