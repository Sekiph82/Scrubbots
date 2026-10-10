extends SceneTree
## M43-C005F-PHASE5 — SB-M43-C005F-011 CleaningEffectsController x Saltmire Spark A/B gate.
## Arm A = the untouched production M31 wiring. Arm B = tests/support/cleaning_spark_ab_arm.gd
## (evidence-only): the same controller + at most one FeedbackAdapter SMALL `spark` accent per
## ACCEPTED native cue, GameFeelFlow absent, real installed Saltmire Spark. Real stack only:
## main.tscn -> ProductionGameplayHost (BoardState, CompleteClearingLoop, CleaningEffectsController,
## CleaningFxLayer) for production Level 1, and a real laid-out ProductionGameplayHost on a 59x59
## 6-colour stripe TEST fixture (the M29-C002 s8 harness) for the dense load.
##   u*: authority / idempotency      r*: Reduced          t*: Retry / reset
##   f*: failure safety               i*: truth invariance l*: 59x59 cap / load / drain
##   s*: static boundary
## Plugin work is counted on the installed plugin (emitters) or a counting spy where stated.
## Run: godot --headless --path . -s res://tests/m43_c005f_phase5_cleaning_spark_ab.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const CleaningEffectsController = preload("res://scripts/gameplay/presentation/cleaning_effects_controller.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const AbArm = preload("res://tests/support/cleaning_spark_ab_arm.gd")

const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const CIDS := ["C01", "C02", "C03", "C04", "C05", "C06"]
const DT := 1.0 / 60.0

class SpySpark extends RefCounted:
	var presets := {"spark": {"amount": 14}, "pickup": {}, "confetti": {}}
	var bursts: Array = []
	func burst(_p, o = {}) -> void:
		bursts.append(int(o.get("amount", 0)))
	func at(_n, o = {}) -> void:
		bursts.append(int(o.get("amount", 0)))
	func clear() -> void:
		pass

class FaultySpark extends RefCounted:
	var presets := {"spark": {}, "pickup": {}, "confetti": {}}
	var calls := 0
	func burst(_p, _o = {}) -> void:
		pass
	func at(_n, _o = {}) -> void:
		calls += 1
		if calls == 1:
			var broken = null
			broken.explode()   # injected plugin failure (expected: exactly ONE SCRIPT ERROR, see log)
	func clear() -> void:
		pass

var EXPECTED_CASES := ["u01_one_clear_one_cue_one_accent", "u02_invalid_index_zero", "u03_cap_suppressed_zero_spark",
	"u04_only_authenticated_source", "r01_reduced_native_puff_zero_spark", "t01_retry_clears_both_then_new_attempt",
	"f01_spark_missing", "f02_spark_throws", "f03_adapter_detached_midrun", "i01_level1_truth_identical",
	"i02_retry_truth_identical", "l01_59x59_1x_2x_bounded_drain", "s01_static_boundary"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	await _u01_u04(); await _r01(); await _t01(); await _f01_f03()
	await _i01(); await _i02(); await _l01()
	_s01()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _spark_autoload():
	return get_root().get_node_or_null("Spark")

## A dedicated evidence adapter: GameFeelFlow ABSENT, Spark = the installed plugin (or a spy).
func _adapter(spark, effects = null):
	var f = FeedbackAdapter.new()
	f.bind(self, effects)
	f.set_backends_for_test(null, spark)
	return f

func _boot_app(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var p := "user://c005f_p5_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	MainScript.boot_save_path_override = p
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(14)

func _launch_level1():
	var r: Dictionary = _root.play_current_frontier()
	if not r.get("ok", false):
		_ok(false, "Level 1 launches (%s)" % str(r))
		return null
	# The driver is the ONLY gameplay clock (M29 harness rule): stop the runtime's own real-time
	# _process BEFORE any frame passes, so no wall-clock delta ever advances gameplay.
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)
	await _frames(4)
	h.get_runtime().reset_runtime()
	return h

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

## Live Saltmire Spark emitters anywhere in the tree (the plugin's own pool + reparented ones).
func _emitters() -> int:
	return get_root().find_children("*", "Node2D", true, false).filter(func(n): return "_age" in n and "_parts" in n).size()

## Frame-paced deterministic drive: one gameplay tick of DT per frame (2x via the runtime speed
## authority), greedy front activation exactly like tests/m55_long_session.gd. Records the
## authenticated clear sequence as [tick, target]. Stops at terminal or after max_ticks.
func _drive(h, max_ticks: int, two := false, stats := {}) -> Dictionary:
	var rt = h.get_runtime()
	rt.set_speed_2x(two)
	var seq: Array = []
	var tick := [0]
	var rec := func(_o, t, _c, _a): seq.append([tick[0], t])
	h.get_clearing_loop().authenticated_clear.connect(rec)
	var clicks: Array = []
	if not String(h.supply_plan_path).is_empty():
		clicks = SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]["intendedColumnClicks"]
	var ci := 0
	var fx = h.get_cleaning_fx()
	var peak_native := 0
	var peak_emit := 0
	var t0 := Time.get_ticks_usec()
	while tick[0] < max_ticks and not h.get_completion().is_terminal():
		if h.get_slots().rightmost_empty_index() != -1 and not h.get_supply().is_exhausted():
			if not clicks.is_empty():
				if ci < clicks.size() and h.get_input_controller().activate_front(int(clicks[ci]) - 1).get("ok", false):
					ci += 1
			else:
				for col in range(h.get_supply().get_column_count()):
					if h.get_input_controller().activate_front(col).get("ok", false):
						break
		rt.tick(DT)
		tick[0] += 1
		await process_frame
		peak_native = maxi(peak_native, fx.get_active_count())
		if stats.get("emitters", false):
			peak_emit = maxi(peak_emit, _emitters())
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	h.get_clearing_loop().authenticated_clear.disconnect(rec)
	return {"seq": seq, "ticks": tick[0], "ms": ms, "peak_native": peak_native, "peak_emit": peak_emit,
		"terminal": String(h.get_completion().get_state())}

## Gameplay truth (never presentation): board cells, slots, supply, terminal, progression/economy.
func _truth(h) -> Dictionary:
	var b = h.get_board()
	var cells := PackedByteArray(b.get_cell_states_copy())
	var out := {"cells": Marshalls.raw_to_base64(cells), "slots": JSON.stringify(h.get_slots().snapshot()),
		"supply": JSON.stringify(h.get_supply().debug_snapshot()), "terminal": String(h.get_completion().get_state())}
	if _root != null and is_instance_valid(_root):
		var snap: Dictionary = _root.get_app_state().economy.snapshot()
		snap.erase("packs")   # per-save pack RNG seed: drawn at save creation, not gameplay truth
		out["economy"] = JSON.stringify(snap)
		out["progress"] = _root.get_app_state().progression.completed_count()
	return out

# ---- 59x59 real laid-out host fixture (the M29-C002 s8 harness) ----

func _write(tag: String, text: String) -> String:
	var p := "user://c005f_p5_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _stripe_level_dict(w: int, k: int, id: String) -> Dictionary:
	var cells: Array = []
	for y in range(w):
		for x in range(w):
			cells.append(x * k / w)
	return {"version": 1, "id": id, "name": id, "difficulty": "TEST", "width": w, "height": w, "palette": HEX.slice(0, k), "cells": cells}

func _stripe_plan(lvl: Dictionary) -> Dictionary:
	var totals := {}
	for c in lvl["cells"]:
		totals[int(c)] = int(totals.get(int(c), 0)) + 1
	var batches: Array = []
	var left := totals.duplicate()
	var more := true
	while more:
		more = false
		for c in range(lvl["palette"].size()):
			if int(left.get(c, 0)) > 0:
				var n := mini(30, int(left[c]))
				left[c] = int(left[c]) - n
				batches.append([CIDS[c], n])
				more = true
	var cols := [[], [], []]
	for i in range(batches.size()):
		cols[i % 3].append({"batchId": "T%03d" % i, "cid": batches[i][0], "robots": batches[i][1]})
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "columnCount": 3, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols, "levelId": lvl["id"]}

func _host_59(tag: String):
	_shutdown()
	var lvl := _stripe_level_dict(59, 6, "c005f_p5_59_%s" % tag)
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = _write("lvl", JSON.stringify(lvl))
	h.supply_plan_path = _write("plan", JSON.stringify(_stripe_plan(lvl)))
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub.add_child(h)
	await _frames(2)
	_ok(h.build(), "59x59 laid-out fixture host builds %s" % h.get_build_error())
	await _frames(2)
	h.get_screen().relayout()
	await _frames(2)
	h.get_runtime().set_process(false)
	h.get_runtime().reset_runtime()
	return h

# ------------------------------------------------------------------- cases ----

func _u01_u04() -> void:
	print("[u01-u04 authority / idempotency on production Level 1 (real host, real Spark)]")
	await _boot_app("u")
	var h = await _launch_level1()
	var arm = AbArm.new()
	var feel = _adapter(_spark_autoload(), _root.get_app_state().effects)
	_ok(arm.attach(h, feel), "B arm attached to the live host")
	var fx = h.get_cleaning_fx()
	var b = h.get_board()
	# u01: one direct native request = one cue + one SMALL accent on that cue.
	var idx: int = b.get_cell_count() / 2
	var log0: int = feel.dispatch_log().size()
	_ok(arm.request(idx), "one native cue accepted")
	_ok(arm.spark_requests == 1 and feel.dispatch_log().size() == log0 + 1 and feel.dispatch_log()[-1][0] == "SMALL", "exactly one SMALL accent for it")
	var layer = h.get_screen().get_presentation().get_cleaning_fx_layer()
	var cue: Node2D = layer.get_child(layer.get_child_count() - 1)
	var pos: Vector2i = b.get_cell_position(idx)
	_ok(cue.position.is_equal_approx(Vector2(pos.x + 0.5, pos.y + 0.5)), "accent target = the native cue at the exact cell centre %s" % str(cue.position))
	await _frames(2)
	_ok(_emitters() == 1, "the installed Spark plugin spawned exactly one burst (%d)" % _emitters())
	# u02: invalid index.
	var s0: int = arm.spark_requests
	_ok(not arm.request(b.get_cell_count() + 50) and not arm.request(-1) and arm.spark_requests == s0, "invalid index: zero native, zero Spark")
	_complete("u02_invalid_index_zero")
	# u03: saturate the M31 cap in one frame: the 25th native cue is suppressed -> no accent.
	fx.clear_all()
	feel.cancel_all()
	var s1: int = arm.spark_requests
	var sup0: int = fx.get_suppressed_count()
	for k in range(CleaningEffectsController.MAX_ACTIVE_EFFECTS + 6):
		arm.request(k)
	_ok(fx.get_active_count() == CleaningEffectsController.MAX_ACTIVE_EFFECTS and fx.get_suppressed_count() - sup0 == 6, "native cap 24 holds, 6 suppressed")
	_ok(arm.spark_requests - s1 == CleaningEffectsController.MAX_ACTIVE_EFFECTS, "Spark requests (%d) == accepted native cues (24), suppressed -> zero" % (arm.spark_requests - s1))
	_complete("u03_cap_suppressed_zero_spark")
	fx.clear_all()
	feel.cancel_all()
	await _frames(40)
	# u01 / u04 over real play: every authenticated clear -> at most one native cue -> at most one accent.
	var seen := [0]
	h.get_clearing_loop().authenticated_clear.connect(func(_o, _t, _c, _a): seen[0] += 1)
	var a0 := [arm.authenticated, arm.native_accepted, arm.native_rejected, arm.spark_requests]
	var d := await _drive(h, 900)
	var na: int = arm.native_accepted - a0[1]
	var nr: int = arm.native_rejected - a0[2]
	var sr: int = arm.spark_requests - a0[3]
	print("    real play 900 ticks: authenticated %d, native accepted %d / rejected %d, Spark requests %d, peak native %d, peak owned %d" % [seen[0], na, nr, sr, d["peak_native"], arm.peak_owned])
	_ok(seen[0] > 0 and arm.authenticated - a0[0] == seen[0] and na + nr == seen[0], "each authenticated clear -> exactly one native request (%d)" % seen[0])
	_ok(sr == na and sr <= seen[0], "Spark requests == accepted native cues <= authenticated clears")
	_ok(d["peak_native"] <= CleaningEffectsController.MAX_ACTIVE_EFFECTS, "native cap respected in play (peak %d)" % d["peak_native"])
	_complete("u01_one_clear_one_cue_one_accent")
	# u04: the arm's only source is authenticated_clear (a dispatch / reservation / claim never reaches it).
	var src := FileAccess.get_file_as_string("res://tests/support/cleaning_spark_ab_arm.gd")
	var connects := src.count(".connect(")
	_ok(connects == 2 and src.contains("authenticated_clear.connect(_on_authenticated_clear)") and src.contains("authenticated_clear.connect(_fx._on_authenticated_clear)"),
		"the arm connects ONLY to CompleteClearingLoop.authenticated_clear (B wrapper / restoring A)")
	_ok(not src.contains("assignment_dispatched") and not src.contains("reserv") and not src.contains("claim"), "no dispatch / reservation / claim event can reach the accent")
	_complete("u04_only_authenticated_source")
	arm.detach()

func _r01() -> void:
	print("[r01 Reduced: native reduced puff remains; zero Saltmire Spark]")
	await _boot_app("r")
	_root.get_app_state().set_reduced_effects(true)
	var h = await _launch_level1()
	var spy := SpySpark.new()
	var arm = AbArm.new()
	var feel = _adapter(spy, _root.get_app_state().effects)
	arm.attach(h, feel)
	var fx = h.get_cleaning_fx()
	_ok(fx.is_reduced_effects() and feel.reduced(), "controller + adapter both Reduced (canonical setting)")
	_ok(arm.request(5), "native reduced cue accepted")
	var layer = h.get_screen().get_presentation().get_cleaning_fx_layer()
	var cue: Node2D = layer.get_child(layer.get_child_count() - 1)
	_ok(cue.get_child_count() == 1, "reduced cue = the single puff sprite (no sparkle)")
	var d := await _drive(h, 600)
	await _frames(4)
	_ok(arm.native_accepted > 1 and arm.spark_requests == 0 and spy.bursts.is_empty() and feel.owned_count() == 0, "Reduced: %d native cues, zero Spark requests / bursts" % arm.native_accepted)
	_ok(d["peak_native"] <= CleaningEffectsController.REDUCED_MAX_ACTIVE, "Reduced native cap 8 respected (peak %d)" % d["peak_native"])
	arm.detach()
	_complete("r01_reduced_native_puff_zero_spark")

func _t01() -> void:
	print("[t01 Retry: active native cues + Spark accents both cleared; next attempt normal]")
	await _boot_app("t")
	var h = await _launch_level1()
	var arm = AbArm.new()
	var feel = _adapter(_spark_autoload(), _root.get_app_state().effects)
	arm.attach(h, feel)
	var fx = h.get_cleaning_fx()
	for k in range(10):
		arm.request(k * 3)
	await _frames(2)
	var em0 := _emitters()
	_ok(fx.get_active_count() == 10 and feel.owned_count() == 10 and em0 == 10, "before Retry: 10 native cues, 10 owned accents, %d live emitters" % em0)
	_ok(h.retry(), "transaction-safe Retry succeeds")
	arm.on_attempt_reset()
	await _frames(2)
	_ok(fx.get_active_count() == 0 and feel.owned_count() == 0 and _emitters() == 0, "after Retry: zero native cues, zero owned accents, zero emitters (%d/%d/%d)" % [fx.get_active_count(), feel.owned_count(), _emitters()])
	var s0: int = arm.spark_requests
	var d := await _drive(h, 300)
	_ok(not d["seq"].is_empty() and arm.spark_requests > s0, "new attempt: clears produce native cues + accents again (%d)" % (arm.spark_requests - s0))
	arm.detach()
	await _frames(40)
	_ok(feel.owned_count() == 0 and _emitters() == 0, "no stale emitter / adapter ownership afterwards")
	_complete("t01_retry_clears_both_then_new_attempt")

func _f01_f03() -> void:
	print("[f01-f03 Spark missing / throwing / adapter detached mid-run: gameplay + native M31 unchanged]")
	var base := await _level1_run("fA", null, 900)
	var missing := await _level1_run("fM", "missing", 900)
	_ok(missing["seq"] == base["seq"] and missing["truth"] == base["truth"] and missing["native"] == base["native"], "Spark missing: same clear sequence, truth and native cue count (%d)" % base["native"])
	_complete("f01_spark_missing")
	print("  EXPECTED_FAULT_INJECTION: one SCRIPT ERROR ('explode' on null) follows, deliberately raised inside a spy Spark plugin")
	var faulty := await _level1_run("fF", "faulty", 900)
	_ok(faulty["seq"] == base["seq"] and faulty["truth"] == base["truth"] and faulty["native"] == base["native"], "Spark throws: same clear sequence, truth and native cue count")
	_complete("f02_spark_throws")
	var det := await _level1_run("fD", "detach", 900)
	_ok(det["seq"] == base["seq"] and det["truth"] == base["truth"] and det["native"] == base["native"] and det["owned_after"] == 0, "arm detached mid-run: same truth, native unchanged, adapter drained")
	_complete("f03_adapter_detached_midrun")

## One bounded Level 1 run: arm A (mode null) or B with the given Spark mode.
func _level1_run(tag: String, mode, ticks: int) -> Dictionary:
	await _boot_app(tag)
	var h = await _launch_level1()
	var arm = null
	var feel = null
	if mode != null:
		var spark = null
		if mode == "faulty":
			spark = FaultySpark.new()
		elif mode != "missing":
			spark = _spark_autoload()
		feel = _adapter(spark, _root.get_app_state().effects)
		arm = AbArm.new()
		arm.attach(h, feel)
	var d: Dictionary
	if mode == "detach":
		var d1 := await _drive(h, ticks / 2)
		arm.detach()
		var d2 := await _drive(h, ticks - ticks / 2)
		d = {"seq": d1["seq"] + d2["seq"].map(func(e): return [int(e[0]) + int(d1["ticks"]), e[1]])}   # second drive counts ticks from 0
	else:
		d = await _drive(h, ticks)
	await _frames(40)
	var out := {"seq": d["seq"], "truth": _truth(h), "native": _native_total(h, d["seq"].size()), "owned_after": feel.owned_count() if feel != null else 0}
	if arm != null and arm.is_attached():
		arm.detach()
	return out

## Native cues accepted = authenticated clears - suppressed (the controller's own counters).
func _native_total(h, clears: int) -> int:
	return clears - h.get_cleaning_fx().get_suppressed_count()

func _i01() -> void:
	print("[i01 Level 1 to its terminal: A vs B identical gameplay truth]")
	var a := await _full_level1("iA", false)
	var b := await _full_level1("iB", true)
	print("    A: %d clears in %d ticks, terminal %s; B: %d clears, %d Spark requests (accepted native %d, suppressed %d)" % [a["seq"].size(), a["ticks"], a["truth"]["terminal"],
		b["seq"].size(), b["spark"], b["native"], b["suppressed"]])
	_ok(a["truth"]["terminal"] == "WON" and a["truth"]["progress"] == 1, "A: real Level 1 WON, progression committed")
	_ok(b["seq"] == a["seq"], "identical authenticated clear sequence incl. tick timing (%d clears)" % a["seq"].size())
	_ok(b["truth"] == a["truth"], "identical BoardState, slots, supply, terminal, progression, economy")
	_ok(b["ticks"] == a["ticks"], "identical tick count to terminal (%d)" % a["ticks"])
	_ok(b["spark"] == b["native"] and b["native"] + b["suppressed"] == b["seq"].size(), "B: Spark requests == accepted native cues; accepted + suppressed == clears")
	_complete("i01_level1_truth_identical")

func _full_level1(tag: String, with_b: bool) -> Dictionary:
	await _boot_app(tag)
	var h = await _launch_level1()
	var arm = null
	if with_b:
		arm = AbArm.new()
		arm.attach(h, _adapter(_spark_autoload(), _root.get_app_state().effects))
	var d := await _drive(h, 60 * 60 * 20)
	await _frames(20)
	var out := {"seq": d["seq"], "ticks": d["ticks"], "truth": _truth(h), "spark": arm.spark_requests if arm else 0,
		"native": arm.native_accepted if arm else 0, "suppressed": h.get_cleaning_fx().get_suppressed_count()}
	if arm != null:
		arm.detach()
	return out

func _i02() -> void:
	print("[i02 Retry truth: play, Retry, play again - A vs B identical]")
	var a := await _retry_run("rA", false)
	var b := await _retry_run("rB", true)
	_ok(a["ok"] and b["ok"], "Retry succeeded in both arms")
	_ok(b["seq1"] == a["seq1"] and b["seq2"] == a["seq2"] and b["truth"] == a["truth"], "identical pre-Retry / post-Retry clear sequences and final truth")
	_complete("i02_retry_truth_identical")

func _retry_run(tag: String, with_b: bool) -> Dictionary:
	await _boot_app(tag)
	var h = await _launch_level1()
	var arm = null
	if with_b:
		arm = AbArm.new()
		arm.attach(h, _adapter(_spark_autoload(), _root.get_app_state().effects))
	var d1 := await _drive(h, 600)
	var ok: bool = h.retry()
	if arm != null:
		arm.on_attempt_reset()
	var d2 := await _drive(h, 600)
	var out := {"ok": ok, "seq1": d1["seq"], "seq2": d2["seq"], "truth": _truth(h)}
	if arm != null:
		arm.detach()
	return out

func _l01() -> void:
	print("[l01 59x59 real host dense window, 1x and 2x: A vs B bounded, drained, same truth]")
	_shutdown()
	await _frames(4)
	for two in [false, true]:
		var tag := "2x" if two else "1x"
		var nodes0 := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var orph0 := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		var a := await _dense("A" + tag, false, two)
		var b := await _dense("B" + tag, true, two)
		print("    59x59 %s A: clears %d, native peak %d, suppressed %d, %.3f ms/frame | B: Spark req %d (native accepted %d), peak owned %d, peak emitters %d, %.3f ms/frame, drain %d ms" % [tag,
			a["seq"].size(), a["peak_native"], a["suppressed"], a["ms"] / a["ticks"], b["spark"], b["native"], b["peak_owned"], b["peak_emit"], b["ms"] / b["ticks"], b["drain_ms"]])
		_ok(a["peak_native"] <= CleaningEffectsController.MAX_ACTIVE_EFFECTS and b["peak_native"] <= CleaningEffectsController.MAX_ACTIVE_EFFECTS, "%s: native cap 24 holds in A and B" % tag)
		_ok(b["seq"] == a["seq"] and b["truth"] == a["truth"], "%s: identical clear sequence (%d) and gameplay truth" % [tag, a["seq"].size()])
		_ok(b["spark"] == b["native"] and b["native"] <= b["seq"].size(), "%s: Spark requests == accepted native cues <= clears" % tag)
		_ok(b["peak_emit"] <= b["peak_owned"] and b["peak_owned"] <= b["spark"], "%s: emitters <= owned dispatches <= requests (one burst per accent)" % tag)
		_ok(b["owned_after"] == 0 and b["emit_after"] == 0, "%s: B drains to zero owned / zero emitters" % tag)
		_shutdown()
		await _frames(4)
		_ok(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == nodes0, "%s: tree Node count back to the pre-run value (%d)" % [tag, nodes0])
		_ok(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) <= orph0, "%s: no orphan growth" % tag)
	_complete("l01_59x59_1x_2x_bounded_drain")

func _dense(tag: String, with_b: bool, two: bool) -> Dictionary:
	var h = await _host_59(tag)
	var arm = null
	var feel = null
	if with_b:
		feel = _adapter(_spark_autoload())
		arm = AbArm.new()
		arm.attach(h, feel)
	var d := await _drive(h, 360, two, {"emitters": true})   # 6 s of gameplay frames
	var out := {"seq": d["seq"], "ticks": d["ticks"], "ms": d["ms"], "peak_native": d["peak_native"], "peak_emit": d["peak_emit"],
		"suppressed": h.get_cleaning_fx().get_suppressed_count(), "truth": _truth(h)}
	if arm != null:
		out["spark"] = arm.spark_requests
		out["native"] = arm.native_accepted
		out["peak_owned"] = arm.peak_owned
		var t0 := Time.get_ticks_msec()
		while (feel.owned_count() > 0 or _emitters() > 0) and Time.get_ticks_msec() - t0 < 5000:
			await process_frame
		out["drain_ms"] = Time.get_ticks_msec() - t0
		out["owned_after"] = feel.owned_count()
		out["emit_after"] = _emitters()
		arm.detach()
	return out

func _s01() -> void:
	print("[s01 static boundary: adapter-only Spark, no per-cell GFF, no shipping B wiring]")
	var arm := FileAccess.get_file_as_string("res://tests/support/cleaning_spark_ab_arm.gd")
	for bad in ["Spark.", ".burst(", ".at(", ".clear()", "GameFeelFlow", "camera", "flash", "freeze", "time_scale"]:
		_ok(not _code(arm).contains(bad), "B arm has no '%s'" % bad)
	_ok(_code(arm).contains("_feel.play(\"SMALL\"") and _code(arm).count("_feel.play(") == 1, "B arm: one SMALL FeedbackAdapter request is its only plugin path")
	for path in ["res://scripts/gameplay/presentation/cleaning_effects_controller.gd", "res://scripts/gameplay/runtime/production_gameplay_host.gd",
			"res://scripts/gameplay/board/board_presentation.gd"]:
		var src := _code(FileAccess.get_file_as_string(path))
		_ok(not src.contains("Spark") and not src.contains("FeedbackAdapter") and not src.contains("cleaning_spark_ab_arm"), "%s: native-only, no Spark / adapter / B-arm wiring" % path.get_file())
	var c := FileAccess.get_file_as_string("res://scripts/gameplay/presentation/cleaning_effects_controller.gd")
	_ok(c.contains("const MAX_ACTIVE_EFFECTS := 24") and c.contains("const REDUCED_MAX_ACTIVE := 8") and c.contains("const NORMAL_LIFETIME := 0.30") and c.contains("const REDUCED_LIFETIME := 0.18"), "M31 caps / lifetimes unchanged")
	var hits: Array = []
	for f in _gd_files("res://scripts"):
		if f.contains("feedback_adapter.gd"):
			continue
		if _code(FileAccess.get_file_as_string(f)).contains("cleaning_spark_ab_arm"):
			hits.append(f)
	_ok(hits.is_empty(), "no production script references the evidence-only B arm %s" % str(hits))
	_complete("s01_static_boundary")

func _code(src: String) -> String:
	var out := ""
	for line in src.split("\n"):
		if not line.strip_edges().begins_with("#"):
			out += line + "\n"
	return out

func _gd_files(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for sd in d.get_directories():
		out += _gd_files(dir + "/" + sd)
	return out

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
	print("M43-C005F-PHASE5 cleaning Spark A/B: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
