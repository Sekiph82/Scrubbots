extends "res://tests/m46_rm004_residual_adversarial.gd"
## M46 RM005 — completion / LOSE proof and WON terminal-frame profile (V3-F01 / F02 / F07).
## Reuses the RM004 fixtures (59x59 stripes / VOID pockets, campaign hosts, booted app). Each
## group counts as complete only when it reached its end (no early coroutine/script exit PASS).
##
##   T1 59x59 still moment (p21 shape): the completion tick that classifies the quiescent board
##      (STALLED, never LOST) — worst tick, M27 call count, route probes, oracle time; an
##      off-frame booster proof running on a worker while the main thread classifies
##   T2 oracle equivalence: every result == a fresh pre-RM005 DeadlockClassifier
##      (SolvabilitySolver.full_progress_cascade) on campaign L1-L3 sweeps, 3/4/5 supply
##      columns, 5 and 6 slots, WAITING, VOID pockets, a searched DEADLOCK, a depth-5 STALLED,
##      max_visited / max_depth UNKNOWN_BOUND
##   T3 terminal latch: LOST only on a proven DEADLOCK, STALLED stays PLAYING, exactly one
##      terminal event / receipt / reward, pause freezes, Retry re-arms exactly once
##   T4 WON terminal tick cold vs warm (booted app): per-handler attribution, cached builtin
##      catalog == fresh validated catalog
##   T5 59x59 Retry 30x worst <= 50.1 ms (existing p12 bound)
##
## Run: godot --headless --path . -s res://tests/m46_rm005_terminal_frame_profile.gd

const RuntimePerfProbe = preload("res://scripts/debug/runtime_perf_probe.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")

const RM005_GROUPS := 5
## Desktop CPU bounds. Before RM005 the 59x59 still-moment tick was 1.4-3.3 s (V3-F01); the
## classifier itself now measures 26-48 ms. 400 ms still fails any return of the sibling cascade.
const STILL_TICK_MAX_MS := 400.0
## Warm WON terminal tick (economy + save + Results route): 10-17 ms here after RM005 (82.7 ms
## desktop before, V3-F02). A +100 ms terminal handler must fail it.
const TERMINAL_WARM_MAX_MS := 60.0
const RESOLVE_MAX_MS := 5.0

## Wraps the production classifier inside the real CompletionEvaluator: counts every M27 call
## and checks each result against a fresh pre-RM005 oracle on the same reconstructed state.
class OracleRecorder extends "res://scripts/gameplay/solver/deadlock_classifier.gd":
	var oracle_on := true
	var calls := 0
	var worst_ms := 0.0
	var oracle_ms := 0.0
	var statuses := {}
	var mismatches: Array = []
	var last := {}
	func classify_runtime(level, board, supply_engine, slots_engine, inflight_count: int = 0,
			config: Dictionary = {}) -> Dictionary:
		var st = ProofState.from_runtime(level, board, supply_engine, slots_engine)
		var t := Time.get_ticks_usec()
		var r: Dictionary = super(level, board, supply_engine, slots_engine, inflight_count, config)
		worst_ms = maxf(worst_ms, (Time.get_ticks_usec() - t) / 1000.0)
		calls += 1
		statuses[String(r["status"])] = int(statuses.get(String(r["status"]), 0)) + 1
		last = r
		if oracle_on and st != null:
			var o = load("res://scripts/gameplay/solver/deadlock_classifier.gd").new()
			o._solver.full_progress_cascade = true
			var to := Time.get_ticks_usec()
			var ro: Dictionary = o.classify(st, inflight_count, config)
			oracle_ms = maxf(oracle_ms, (Time.get_ticks_usec() - to) / 1000.0)
			if ro != r:
				mismatches.append([r, ro])
		return r

var _groups := 0
var _equiv := 0
var _equiv_bad: Array = []
var _equiv_status := {}

func _initialize() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	await process_frame
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_v3.append("#%sFF" % String(c["hex"]).trim_prefix("#").to_upper())
		_cids.append(String(c["id"]))
	await _t2_equivalence()
	await _t3_terminal_latch()
	await _t1_still_moment()
	await _t4_terminal_tick()
	await _t5_retry()
	_shutdown()
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for f in [p, p + ".bak", p + ".tmp"]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var pass_all: bool = _fail == 0 and _groups == RM005_GROUPS
	print("M46 RM005 TERMINAL FRAME: %s (%d/%d groups)" % ["PASS" if pass_all else "FAIL (%d fails)" % _fail, _groups, RM005_GROUPS])
	quit(0 if pass_all else 1)

# ------------------------------------------------------------------ helpers ----

func _recorder(h) -> OracleRecorder:
	var rec := OracleRecorder.new()
	h.get_completion_evaluator()._classifier = rec
	return rec

## One state, production classifier vs the pre-RM005 oracle (same config).
func _equiv_state(st, tag: String, config: Dictionary = {}) -> Dictionary:
	var r: Dictionary = DeadlockClassifier.new().classify(st, 0, config)
	var o = DeadlockClassifier.new()
	o._solver.full_progress_cascade = true
	var ro: Dictionary = o.classify(st, 0, config)
	_equiv += 1
	_equiv_status[String(r["status"])] = int(_equiv_status.get(String(r["status"]), 0)) + 1
	if r != ro:
		_equiv_bad.append("%s: %s vs oracle %s" % [tag, str(r), str(ro)])
	return r

func _equiv_host(h, tag: String, config: Dictionary = {}) -> Dictionary:
	return _equiv_state(ProofState.from_runtime(h.get_level(), h.get_board(), h.get_supply(), h.get_slots()), tag, config)

## 20x20 TEST level: ring C01 around a 5x6 C02 core (30 enclosed cells).
func _core_level() -> Dictionary:
	var cells: Array = []
	for y in range(20):
		for x in range(20):
			cells.append(1 if x >= 7 and x <= 11 and y >= 7 and y <= 12 else 0)
	return {"version": 1, "id": "m46rm005_core", "name": "RM005 Core", "difficulty": "TEST", "width": 20, "height": 20,
		"palette": [_v3[0], _v3[1]], "cells": cells}

## Core batches (C02 x2 robots) first in each column (`cores[i]` of them), then the C01 ring.
func _core_plan(cores: Array) -> Dictionary:
	var cols: Array = []
	var n := 0
	for k in cores:
		var q: Array = []
		for _j in range(k):
			q.append({"batchId": "RM5B%03d" % n, "cid": "C02", "robots": 2})
			n += 1
		cols.append(q)
	var left := 370
	var c := 0
	while left > 0:
		var k := mini(30, left)
		cols[c % cols.size()].append({"batchId": "RM5A%03d" % n, "cid": "C01", "robots": k})
		left -= k
		n += 1
		c += 1
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": "m46rm005_core", "columnCount": cores.size(),
		"visiblePreviewDepth": 3, "maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}

## Stripes level + plan over `ncols` supply columns (3/4/5 column coverage).
func _cols_plan(level: Dictionary, ncols: int) -> Dictionary:
	var p: Dictionary = _plan(level)
	var all: Array = []
	for q in p["columns"]:
		all.append_array(q)
	var cols: Array = []
	for _i in range(ncols):
		cols.append([])
	for i in range(all.size()):
		cols[i % ncols].append(all[i])
	p["columns"] = cols
	p["columnCount"] = ncols
	return p

func _small_stripes(n: int) -> Dictionary:
	var pal: Array = []
	for cid in ["C01", "C02", "C03", "C04"]:
		pal.append(_v3[_cids.find(cid)])
	var cells: Array = []
	for y in range(n):
		for x in range(n):
			cells.append(mini(x * 4 / n, 3))
	return {"version": 1, "id": "m46rm005_s%d" % n, "name": "RM005", "difficulty": "TEST", "width": n, "height": n, "palette": pal, "cells": cells}

func _host_plan(level: Dictionary, plan: Dictionary, tag: String):
	var h = ProductionGameplayHost.new()
	h.level_path = _write("lvl5_" + tag, JSON.stringify(level))
	h.supply_plan_path = _write("plan5_" + tag, JSON.stringify(plan))
	_host_in(h)
	_ok(h.build(), "%s host builds %s" % [tag, h.get_build_error()])
	h.get_runtime().set_process(false)
	await _frames(2)
	return h

## Fill every empty slot from the first placeable column (player taps).
func _feed_all(h) -> void:
	for _i in range(h.get_slots().get_slot_count()):
		if _empty_slots(h) == 0 or not _tap(h):
			return

## Plays round by round: 1-3 player taps, then run to the next still moment and compare that
## quiescent state against the oracle. Returns the still moments compared.
func _sweep(h, tag: String, rounds: int) -> int:
	var seen := 0
	h.get_runtime().set_speed_2x(true)
	for i in range(rounds):
		if h.get_completion().is_terminal():
			break
		for _k in range(1 + i % 3):
			_tap(h)
		for j in range(4000):
			if h.get_scheduler().live_assignment_count() == 0 and j > 0:
				break
			h.get_runtime().tick(DT)
			if j % 16 == 0:
				await process_frame
		if h.get_completion().is_terminal():
			break
		_equiv_host(h, "%s@%d" % [tag, i])
		seen += 1
	return seen

# ------------------------------------------------------------------- T2 -------

func _t2_equivalence() -> void:
	print("[T2 production classifier == fresh pre-RM005 oracle]")
	var f0 := _fail
	# Campaign L1..L3: the real CompletionEvaluator path (recorder) + direct still-moment sweeps.
	for order in [1, 2, 3]:
		var h = await _host_level(order)
		var rec := _recorder(h)
		var seen: int = await _sweep(h, "L%d" % order, 400)
		print("    L%d: %d still states compared, %d evaluator M27 calls %s, terminal %s" % [order, seen, rec.calls, str(rec.statuses), String(h.get_completion().get_state())])
		_ok(rec.mismatches.is_empty(), "L%d: every evaluator M27 result == oracle (%d calls)" % [order, rec.calls])
		_free(h)
	# 6 slots: L2 start with the sixth slot grown (capacity 6 state + kernel).
	var h6 = await _host_level(2)
	_ok(h6.get_slots().grow_to_sixth(), "L2 sixth slot grown")
	var r6 := _equiv_host(h6, "L2 6-slot start")
	await _sweep(h6, "L2x6", 60)
	_free(h6)
	# 3 / 4 / 5 supply columns.
	for nc in [3, 4, 5]:
		var lv := _small_stripes(24)
		var hc = await _host_plan(lv, _cols_plan(lv, nc), "cols%d" % nc)
		await _sweep(hc, "cols%d" % nc, 60)
		_free(hc)
	# Searched DEADLOCK (every column starts with 5 enclosed core batches), depth-5 STALLED
	# (4/5/6 core fronts), 6-slot STALLED, and the two UNKNOWN_BOUND exits.
	var hd = await _host_plan(_core_level(), _core_plan([5, 5, 5]), "core555")
	var rd := _equiv_host(hd, "core 5/5/5")
	var rb1 := _equiv_host(hd, "core max_visited 1", {"max_visited": 1})
	var rb2 := _equiv_host(hd, "core max_depth 2", {"max_depth": 2})
	_ok(hd.get_slots().grow_to_sixth(), "core sixth slot grown")
	var rd6 := _equiv_host(hd, "core 5/5/5 6-slot")
	_free(hd)
	var hs = await _host_plan(_core_level(), _core_plan([4, 5, 6]), "core456")
	var rs := _equiv_host(hs, "core 4/5/6")
	_free(hs)
	print("    core 5/5/5: %s %s visited %d memo %d | max_visited 1: %s %s | max_depth 2: %s %s | 6 slots: %s depth %d" % [
		rd["status"], rd["reason"], rd["visited"], rd["memo_hits"], rb1["status"], rb1["reason"], rb2["status"], rb2["reason"], rd6["status"], rd6["max_depth_reached"]])
	print("    core 4/5/6: %s depth %d visited %d memo %d; L2 6-slot start %s" % [rs["status"], rs["max_depth_reached"], rs["visited"], rs["memo_hits"], r6["status"]])
	_ok(rd["status"] == DeadlockClassifier.DEADLOCK and int(rd["visited"]) > 20 and int(rd["memo_hits"]) > 0, "searched DEADLOCK (visited %d, memo %d)" % [rd["visited"], rd["memo_hits"]])
	_ok(rs["status"] == DeadlockClassifier.STALLED and int(rs["max_depth_reached"]) == 5, "depth-5 STALLED through non-progress children")
	_ok(rd6["status"] == DeadlockClassifier.STALLED, "6-slot capacity turns the 5/5/5 DEADLOCK into STALLED")
	_ok(rb1["reason"] == "max_visited_exhausted" and rb2["reason"] == "depth_bound_exhausted" and rb1["status"] == DeadlockClassifier.UNKNOWN_BOUND and rb2["status"] == DeadlockClassifier.UNKNOWN_BOUND, "UNKNOWN_BOUND via max_visited and max_depth")
	# 59x59 VOID pockets: the start state (pocket batch fronts, WAITING after the first wave)
	# and the genuine LOSE fixture (five enclosed P1 batches WAITING).
	var level := _pocket_level()
	var hp = await _host_file(level, "rm5_pocket")
	for _k in range(5):
		_tap(hp, 4)
	for _f in range(3):
		hp.get_runtime().tick(DT)
	var waiting := 0
	for i in range(hp.get_slots().get_slot_count()):
		waiting += 1 if hp.get_slots().get_state(i) == SlotBatchState.WAITING else 0
	var rp := _equiv_host(hp, "59x59 pocket lose")
	print("    59x59 pockets: 5 enclosed P1 batches in 5 slots (%d WAITING after the first waves) -> %s %s" % [waiting, rp["status"], rp["reason"]])
	_ok(_empty_slots(hp) == 0 and waiting >= 1 and rp["status"] == DeadlockClassifier.DEADLOCK, "59x59 VOID pocket LOSE state is a proven DEADLOCK")
	_free(hp)
	print("    %d states compared %s; mismatches %d %s" % [_equiv, str(_equiv_status), _equiv_bad.size(), str(_equiv_bad.slice(0, 3))])
	_ok(_equiv_bad.is_empty() and _equiv >= 50 and _equiv_status.has("STALLED") and _equiv_status.has("DEADLOCK") and _equiv_status.has("UNKNOWN_BOUND") and _equiv_status.has("PROGRESSABLE"),
		"every classification == oracle across STALLED / DEADLOCK / UNKNOWN_BOUND / PROGRESSABLE")
	if _fail == f0:
		_groups += 1

# ------------------------------------------------------------------- T3 -------

func _t3_terminal_latch() -> void:
	print("[T3 terminal latch: LOST only on DEADLOCK, exactly once]")
	var f0 := _fail
	# STALLED stays PLAYING; tapping the reachable ring batch makes progress.
	var hs = await _host_plan(_core_level(), _core_plan([4, 5, 6]), "t3_stalled")
	var rec := _recorder(hs)
	for _k in range(4):
		_tap(hs, 0)
	await _still(hs)
	for _i in range(30):
		hs.get_runtime().tick(DT)
	var stalled_playing: bool = String(hs.get_completion().get_state()) == "PLAYING" and String(rec.last.get("status", "")) == "STALLED"
	_ok(stalled_playing, "four WAITING core batches + a reachable ring front: STALLED, completion PLAYING (%s)" % str(rec.statuses))
	_tap(hs, 0)
	await _busy(hs, 0)
	_ok(String(hs.get_completion().get_state()) == "PLAYING", "the ring placement keeps the attempt PLAYING")
	_free(hs)
	# Genuine LOSE through the real runtime: exactly one terminal event; later ticks never re-emit.
	var hd = await _host_plan(_core_level(), _core_plan([5, 5, 5]), "t3_lost")
	rec = _recorder(hd)
	var emits: Array = []
	hd.get_completion().terminal_reached.connect(func(s, _d): emits.append(String(s)))
	for _k in range(5):
		_tap(hd, _k % 3)
	for _i in range(200):
		hd.get_runtime().tick(DT)
	var lost: bool = String(hd.get_completion().get_state()) == "LOST"
	print("    LOSE fixture: completion %s, emits %s, M27 calls %d %s" % [String(hd.get_completion().get_state()), str(emits), rec.calls, str(rec.statuses)])
	_ok(lost and emits == ["LOST"] and String(rec.last.get("status", "")) == "DEADLOCK" and rec.mismatches.is_empty(), "LOST latched once, only on a proven DEADLOCK == oracle")
	# Retry re-arms exactly one new terminal; pause freezes evaluation.
	_ok(hd.retry(), "retry after LOST")
	await _frames(2)
	hd.get_runtime().set_user_paused(true)
	for _k in range(5):
		_tap(hd, _k % 3)
	for _i in range(120):
		hd.get_runtime().tick(DT)
	var paused_playing: bool = String(hd.get_completion().get_state()) == "PLAYING"
	hd.get_runtime().set_user_paused(false)
	for _i in range(200):
		hd.get_runtime().tick(DT)
	print("    retry: paused %s, resumed -> %s, emits %s" % [str(paused_playing), String(hd.get_completion().get_state()), str(emits)])
	_ok(paused_playing and emits == ["LOST", "LOST"], "pause freezes the verdict; the retried attempt latches exactly one more LOST")
	_free(hd)
	# WON L1: exactly one event, one receipt, one reward; extra ticks change nothing.
	var hw = await _host_level(1)
	rec = _recorder(hw)
	var wins: Array = []
	hw.get_completion().terminal_reached.connect(func(s, _d): wins.append(String(s)))
	var eco = hw.get_economy()
	var sb0: int = eco.wallet.scrub_bucks()
	var won: bool = await _play_to_terminal(hw)
	var rc1: Dictionary = hw.get_terminal_receipt().duplicate(true)
	var sb1: int = eco.wallet.scrub_bucks()
	for _i in range(120):
		hw.get_runtime().tick(DT)
	await _frames(2)
	print("    L1 WON: emits %s, SB %d -> %d, M27 calls %d %s" % [str(wins), sb0, sb1, rec.calls, str(rec.statuses)])
	_ok(won and wins == ["WON"] and sb1 > sb0 and eco.wallet.scrub_bucks() == sb1 and hw.get_terminal_receipt() == rc1 and rec.mismatches.is_empty(),
		"L1 WON: one terminal event, one reward, receipt stable, no LOSE verdict on the way")
	_free(hw)
	if _fail == f0:
		_groups += 1

# ------------------------------------------------------------------- T1 -------

func _t1_still_moment() -> void:
	print("[T1 59x59 still moment: quiescent completion tick (V3-F01)]")
	var f0 := _fail
	for which in ["stripes", "pocket"]:
		var level: Dictionary = _stripe_level() if which == "stripes" else _pocket_level()
		var h = await _host_file(level, "rm5_" + which)
		var rec := _recorder(h)
		rec.oracle_on = false
		var rt = h.get_runtime()
		rt.set_speed_2x(true)
		for _k in range(6):
			for _i in range(500):
				_feed_all(h)
				rt.tick(DT)
				if _i % 4 == 0:
					await process_frame
			for _i in range(6000):
				if _empty_slots(h) >= 3:
					break
				rt.tick(DT)
		var calls0 := rec.calls
		var tick_worst := 0.0
		var ticks := 0
		for _i in range(8000):
			if h.get_scheduler().live_assignment_count() == 0:
				break
			var t := Time.get_ticks_usec()
			rt.tick(DT)
			tick_worst = maxf(tick_worst, _ms(t))
			ticks += 1
			if _i % 4 == 0:
				await process_frame
		for _i in range(3):
			var t := Time.get_ticks_usec()
			rt.tick(DT)
			tick_worst = maxf(tick_worst, _ms(t))
		var still: bool = h.get_scheduler().live_assignment_count() == 0
		var st = ProofState.from_runtime(h.get_level(), h.get_board(), h.get_supply(), h.get_slots())
		# Counted attribution on the same quiescent state: production vs oracle.
		var probes := {}
		for mode in ["rm005", "oracle"]:
			var c = DeadlockClassifier.new()
			c._solver.full_progress_cascade = mode == "oracle"
			RuntimePerfProbe.reset()
			RuntimePerfProbe.enabled = true
			var t := Time.get_ticks_usec()
			var r: Dictionary = c.classify(st, 0)
			var ms := _ms(t)
			RuntimePerfProbe.enabled = false
			var snap: Dictionary = RuntimePerfProbe.snapshot()
			probes[mode] = {"r": r, "ms": ms, "routes": int(snap.get("access_compute_route", {}).get("count", 0)),
				"masks": int(snap.get("access_mask_build", {}).get("count", 0))}
		# An off-frame booster proof on a worker while the main thread classifies the same state.
		var eco = h.get_economy()
		var worker_ok := true
		if eco != null:
			eco.boosters.add_charges(RANDOM, 1)
			h.request_booster(RANDOM)
			var r_main: Dictionary = DeadlockClassifier.new().classify(st, 0)
			await _wait_worker(h)
			worker_ok = r_main == probes["rm005"]["r"] and not h.is_booster_proof_running()
		var p: Dictionary = probes["rm005"]
		var o: Dictionary = probes["oracle"]
		print("    %s: still=%s after %d ticks, completion tick worst %.1f ms, M27 calls %d (%d at the still moment) %s, M27 worst %.1f ms" % [
			which, str(still), ticks, tick_worst, rec.calls, rec.calls - calls0, str(rec.statuses), rec.worst_ms])
		print("      same state: %s %s visited %d frontier %d | RM005 %.1f ms, %d route probes, %d masks | oracle %.1f ms, %d route probes, %d masks | worker %s" % [
			p["r"]["status"], p["r"]["reason"], p["r"]["visited"], p["r"]["frontier_peak"], p["ms"], p["routes"], p["masks"], o["ms"], o["routes"], o["masks"], str(worker_ok)])
		_ok(still and String(h.get_completion().get_state()) == "PLAYING" and String(p["r"]["status"]) != "DEADLOCK", "%s: still moment is not a LOSE (completion PLAYING)" % which)
		_ok(p["r"] == o["r"] and rec.calls > calls0 and rec.last == p["r"], "%s: the still-moment completion verdict and counters == oracle" % which)
		_ok(tick_worst <= STILL_TICK_MAX_MS, "%s: completion tick worst %.1f ms <= %.0f ms (pre-RM005 1.4-3.3 s)" % [which, tick_worst, STILL_TICK_MAX_MS])
		_ok(p["routes"] <= int(p["r"]["visited"]) * 6 and o["routes"] >= 3 * maxi(1, p["routes"]), "%s: sibling cascades skipped (%d vs %d route probes)" % [which, p["routes"], o["routes"]])
		_ok(worker_ok, "%s: off-frame proof on a worker + main-thread classification of the same state agree; worker settled" % which)
		_free(h)
	if _fail == f0:
		_groups += 1

# ------------------------------------------------------------------- T4 -------

var _rows: Array = []

func _wrap_terminal(h) -> void:
	_rows.clear()
	if h.has_meta("rm005_wrapped"):
		return
	h.set_meta("rm005_wrapped", true)
	var c = h.get_completion()
	var conns: Array = c.get_signal_connection_list("terminal_reached")
	for k in conns:
		c.terminal_reached.disconnect(k["callable"])
	for k in conns:
		var cb: Callable = k["callable"]
		var o = cb.get_object()
		var name := "%s.%s" % [o.get_script().resource_path.get_file() if o != null and o.get_script() != null else "?", cb.get_method()]
		c.terminal_reached.connect(func(s, d):
			var t := Time.get_ticks_usec()
			cb.call(s, d)
			_rows.append("%s %.2f" % [name, _ms(t)]))

func _t4_terminal_tick() -> void:
	print("[T4 WON terminal tick: cold vs warm attribution (V3-F02)]")
	var f0 := _fail
	await _boot_play(1)
	var app = _root.get_app_state()
	# Cached builtin catalog == a fresh validated load; resolve no longer re-validates.
	var fresh := LevelCatalog.new()
	var fresh_ok: bool = fresh.load_manifest().ok
	var ids_fresh: Array = fresh.get_entries_ordered().map(func(e): return [e.id, e.order, e.level_path, e.supply_plan_path, e.difficulty, e.preview_path])
	var cat_a = app.playable_catalog()
	var cat_b = app.playable_catalog()
	var ids_a: Array = cat_a.get_entries_ordered().map(func(e): return [e.id, e.order, e.level_path, e.supply_plan_path, e.difficulty, e.preview_path])
	var res_ms: Array = []
	for _i in range(5):
		var t := Time.get_ticks_usec()
		GameplayLaunchResolver.resolve(app)
		res_ms.append(_ms(t))
	var rs := _stats(res_ms)
	print("    builtin catalog cached: %d entries, resolve mean %.2f / max %.2f ms" % [ids_a.size(), rs["mean"], rs["max"]])
	_ok(fresh_ok and ids_a.slice(0, ids_fresh.size()) == ids_fresh and cat_a != cat_b and app._builtin_catalog != null and rs["max"] <= RESOLVE_MAX_MS,
		"playable_catalog over the cached builtin == fresh validated catalog; resolve <= %.0f ms" % RESOLVE_MAX_MS)
	_wrap_terminal(_host)
	var cold := await _play_and_time_terminal(_host)
	var cold_rows := _rows.duplicate()
	_root.retry_from_results()
	await _frames(6)
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)
	_root.get_modal_stack().clear("t")
	_wrap_terminal(_host)
	var warm := await _play_and_time_terminal(_host)
	for row in [["cold", cold, cold_rows], ["warm", warm, _rows]]:
		var x: Dictionary = row[1]
		print("    L1 %s: terminal tick %.2f ms (handlers %s), Results route frame %d %.2f ms, frame max %.2f / mean %.2f" % [
			row[0], x["terminal_tick"], str(row[2]), x["at"], x["show_frame"], x["max"], x["mean"]])
	_ok(cold["won"] and warm["won"] and cold["shown"] and warm["shown"], "both L1 attempts WON and showed Results")
	_ok(warm["terminal_tick"] <= TERMINAL_WARM_MAX_MS, "warm WON terminal tick %.2f ms <= %.0f ms (pre-RM005 82.7 ms desktop)" % [warm["terminal_tick"], TERMINAL_WARM_MAX_MS])
	_shutdown()
	if _fail == f0:
		_groups += 1

# ------------------------------------------------------------------- T5 -------

func _t5_retry() -> void:
	print("[T5 59x59 Retry x30 (p12 bound 50.1 ms, V3-F07)]")
	var f0 := _fail
	var h = await _host_file(_stripe_level(), "rm5_retry")
	h.get_runtime().set_speed_2x(true)
	for _i in range(240):
		h.get_runtime().tick(DT)
		_tap(h)
	h.retry()
	var ms: Array = []
	for _k in range(30):
		for _i in range(120):
			h.get_runtime().tick(DT)
			_tap(h)
			if _i % 8 == 0:
				await process_frame
		var t := Time.get_ticks_usec()
		h.retry()
		ms.append(_ms(t))
	var s := _stats(ms)
	print("    30 retries: mean %.2f, p95 %.2f, worst %.2f ms" % [s["mean"], s["p95"], s["max"]])
	_ok(s["n"] == 30 and s["max"] <= 50.1, "30 retries worst %.2f ms <= 50.1 (unchanged bound)" % s["max"])
	_free(h)
	if _fail == f0:
		_groups += 1
