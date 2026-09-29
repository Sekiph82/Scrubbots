extends SceneTree
## M25-C004 V01 — real-host truth proof + work-count evidence for the exact-equivalent Railroad acceleration.
##
## Full laid-out 59x59 six-stripe level on a REAL ProductionGameplayHost (1080x2160 SubViewport, +1 slot, origins
## below the board), S1 prefilter enabled, driven to WON at 2x and 1x:
##   * "base" runs: the live routing instance's script is swapped to a RECORDING subclass of the FROZEN pre-S2 oracle;
##   * "opt"  runs: swapped to a RECORDING subclass of the optimized production routing;
##   every compute_route call (request origin/target + full result points) is logged, and the two runs must match
##   route-by-route, then dispatch target/colour sequence, authenticated clear sequence and final board.
##   * "shadow" run (2x): the optimized routing additionally re-runs the frozen oracle AND a work-counting replica on
##     the SAME live state for every route -> in-place point-for-point identity + per-route work counters.
## Both routing paths keep the M25-C003 S1 prefilter on. Result: 3481/3481, WON, zero duplicate claim/dispatch/clear,
## zero residue.
##
## Run: godot --headless --path . -s res://tests/m25_c004_host_truth.gd [-- <evidence.json>]

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const RP = preload("res://scripts/debug/runtime_perf_probe.gd")
const Baseline = preload("res://tests/support/m25_c004_railroad_baseline.gd")
const Counting = preload("res://tests/support/m25_c004_baseline_counting.gd")
const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const CIDS := ["C01", "C02", "C03", "C04", "C05", "C06"]

var _tmp: Array = []
var _fail := 0

## Recording subclass of the frozen oracle.
class RecBase:
	extends "res://tests/support/m25_c004_railroad_baseline.gd"
	var log: Array = []
	func compute_route(request, board, access_query) -> RefCounted:
		var r = super.compute_route(request, board, access_query)
		log.append([request.target_index, request.start_position, r.success, String(r.failure_reason), r.get_points().to_byte_array().hex_encode().hash()])
		return r

## Recording subclass of the optimized production routing.
class RecOpt:
	extends "res://scripts/gameplay/routing/production_routing_system.gd"
	var log: Array = []
	func compute_route(request, board, access_query) -> RefCounted:
		var r = super.compute_route(request, board, access_query)
		log.append([request.target_index, request.start_position, r.success, String(r.failure_reason), r.get_points().to_byte_array().hex_encode().hash()])
		return r

## Shadow: optimized result returned to the game; oracle + counting replica re-run on the identical live state.
class Shadow:
	extends "res://scripts/gameplay/routing/production_routing_system.gd"
	var oracle = null
	var counting = null
	var routes := 0
	var diffs := 0
	var count_diffs := 0
	var first_diffs: Array = []
	var opt_counts: Array = []      # per route: dict
	var base_counts: Array = []
	var k_steps: Array = []
	var layered := 0
	func compute_route(request, board, access_query) -> RefCounted:
		if oracle == null:
			oracle = load("res://tests/support/m25_c004_railroad_baseline.gd").new()
			counting = load("res://tests/support/m25_c004_baseline_counting.gd").new()
			collect_work_counts = true
		last_work_counts = {}
		var r = super.compute_route(request, board, access_query)
		var oc: Dictionary = last_work_counts.duplicate()
		var a = oracle.compute_route(request, board, access_query)
		var c = counting.compute_route(request, board, access_query)
		routes += 1
		var pr: PackedByteArray = r.get_points().to_byte_array()
		if a.success != r.success or String(a.failure_reason) != String(r.failure_reason) or a.target_index != r.target_index \
				or a.get_points().to_byte_array() != pr:
			diffs += 1
			if first_diffs.size() < 10:
				first_diffs.append("target %d origin %s" % [request.target_index, str(request.start_position)])
		if c.success != a.success or String(c.failure_reason) != String(a.failure_reason) or c.get_points().to_byte_array() != a.get_points().to_byte_array():
			count_diffs += 1
		if String(oc.get("path", "")) == "layered":
			layered += 1
			opt_counts.append(oc)
			base_counts.append(counting.wc.duplicate())
		return r

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var res := {}
	var runs := {}
	for two in [true, false]:
		var sp := "2x" if two else "1x"
		runs["base_" + sp] = await _full_run("base " + sp, "base", two)
		runs["opt_" + sp] = await _full_run("opt " + sp, "opt", two)
	var shadow_run := await _full_run("shadow 2x", "shadow", true)
	for two in ["2x", "1x"]:
		var b: Dictionary = runs["base_" + two]
		var o: Dictionary = runs["opt_" + two]
		for r in [b, o]:
			_ok(r["origins_below"], "%s: every slot origin finite and below the board" % r["tag"])
			_ok(r["won"] and r["clears"] == 3481 and r["dup_dispatch"] == 0 and r["dup_clear"] == 0 and r["residue"] == [0, 0, 0, 0],
				"%s: WON, 3481/3481 clears, no duplicate claim/dispatch/clear, zero residue" % r["tag"])
			_ok(r["max_route_per_lane"] <= 1, "%s: compute_route <= 1 per lane (max %d)" % [r["tag"], r["max_route_per_lane"]])
			_ok(r["max_lanes_per_frame"] <= 1, "%s: one lane per frame" % r["tag"])
		_ok(b["routes"].size() == o["routes"].size() and b["routes"] == o["routes"],
			"%s: every compute_route call (origin, target, success, reason, full point sequence) identical base vs opt (%d routes)" % [two, o["routes"].size()])
		_ok(b["dispatch"] == o["dispatch"], "%s: dispatch target/colour sequence identical (%d)" % [two, o["dispatch"].size()])
		_ok(b["clears_seq"] == o["clears_seq"], "%s: authenticated clear sequence identical (%d)" % [two, o["clears_seq"].size()])
		_ok(b["final"] == o["final"], "%s: identical final board" % two)
		var failed_routes := 0
		for L in o["routes"]:
			if not L[2]:
				failed_routes += 1
		_ok(failed_routes == 0, "%s: 0 failed route probes over the full level (got %d)" % [two, failed_routes])
	var sh = shadow_run["shadow"]
	_ok(sh["routes"] > 3000 and sh["diffs"] == 0 and sh["count_diffs"] == 0,
		"shadow: %d live routes, optimized == frozen oracle point-for-point (diffs %d), counting replica == oracle (diffs %d)" % [sh["routes"], sh["diffs"], sh["count_diffs"]])
	_ok(shadow_run["won"] and shadow_run["clears"] == 3481 and shadow_run["dup_dispatch"] == 0 and shadow_run["dup_clear"] == 0,
		"shadow run WON 3481/3481, no duplicates")
	_ok(shadow_run["dispatch"] == runs["opt_2x"]["dispatch"] and shadow_run["final"] == runs["opt_2x"]["final"], "shadow run == opt 2x dispatch and final board")
	res["runs"] = {}
	for k in runs:
		res["runs"][k] = _strip(runs[k])
	res["shadow"] = _strip(shadow_run)
	res["work_counts"] = _summarise_counts(sh)
	print("WORK %s" % JSON.stringify(res["work_counts"]))
	if args.size() > 0:
		var f := FileAccess.open(args[0], FileAccess.WRITE)
		f.store_string(JSON.stringify(res, "  "))
		f.close()
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	print("m25_c004_host_truth: %s (%d failed checks)" % ["PASS" if _fail == 0 else "FAIL", _fail])
	quit(0 if _fail == 0 else 1)

func _ok(cond: bool, msg: String) -> void:
	print("  %s: %s" % ["ok" if cond else "FAIL", msg])
	if not cond:
		_fail += 1

func _strip(r: Dictionary) -> Dictionary:
	var o := r.duplicate()
	for k in ["dispatch", "clears_seq", "final", "routes", "shadow_obj"]:
		o.erase(k)
	o["dispatches"] = r["dispatch"].size()
	o["route_calls"] = r["routes"].size()
	if r.has("shadow_obj"):
		o["shadow"] = r["shadow_obj"]
	return o

func _dist(a: Array) -> Dictionary:
	if a.is_empty():
		return {"n": 0}
	var s := a.duplicate()
	s.sort()
	var sum := 0.0
	for v in s:
		sum += float(v)
	return {"n": s.size(), "mean": snappedf(sum / s.size(), 0.01), "p50": s[s.size() / 2], "p99": s[int(s.size() * 0.99)], "max": s[s.size() - 1]}

func _summarise_counts(sh: Dictionary) -> Dictionary:
	var out := {"routes_layered": sh["layered"]}
	var opt: Array = sh["opt_counts"]
	var base: Array = sh["base_counts"]
	for key in ["pops", "pushes", "stale_pops", "neighbor_checks", "state_reads", "relaxations", "max_heap", "sources"]:
		out["baseline_" + key] = _dist(base.map(func(d): return d.get(key, 0)))
	for key in ["k_steps", "rev_expanded", "rev_neighbor_checks", "rev_reached", "critical_sources", "sweep_cells", "chain_cells", "snapshots"]:
		out["optimized_" + key] = _dist(opt.map(func(d): return d.get(key, 0)))
	var ratio: Array = []
	for i in range(opt.size()):
		var bp: int = int(base[i].get("pops", 0))
		var op: int = int(opt[i].get("rev_expanded", 0)) + int(opt[i].get("sweep_cells", 0))
		ratio.append(snappedf(float(bp) / float(maxi(1, op)), 0.1))
	out["pop_ratio_baseline_over_optimized"] = _dist(ratio)
	return out

# --------------------------------------------------------------- full run ----
func _full_run(tag: String, mode: String, two: bool) -> Dictionary:
	var lvl := _stripe_level(59, 6, "m25c004_59_%s_%d" % [mode, Time.get_ticks_usec()])
	var h = await _laid_out_host(lvl, _plan(lvl))
	h.get_economy().boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
	h.activate_plus_one_slot()
	await _settle(h)
	h.get_runtime().set_process(false)
	h.get_runtime().reset_runtime()
	var origins: Array = []
	var below := true
	for i in range(h.get_slots().active_capacity()):
		var o: Vector2 = h.get_origin_provider().origin_for_slot(i)
		origins.append([snappedf(o.x, 0.01), snappedf(o.y, 0.01)])
		below = below and is_finite(o.x) and is_finite(o.y) and o.y >= float(h.get_board().get_height())
	var routing = h.get_scheduler()._routing_system
	match mode:
		"base":
			routing.set_script(RecBase)
		"opt":
			routing.set_script(RecOpt)
		"shadow":
			routing.set_script(Shadow)
	var rt = h.get_runtime()
	rt.set_speed_2x(two)
	var dispatch: Array = []
	var clears: Array = []
	var live := {}
	var cleared := {}
	var dup := [0, 0]
	h.get_dispatcher().assignment_dispatched.connect(func(_o, t, c, _a):
		if live.has(t): dup[0] += 1
		live[t] = true
		dispatch.append([t, c]))
	h.get_clearing_loop().authenticated_clear.connect(func(_o, t, c, _a):
		live.erase(t)
		if cleared.has(t): dup[1] += 1
		cleared[t] = true
		clears.append([t, c]))
	RP.reset()
	RP.enabled = true
	var col := 0
	var frames := 0
	var guard := 0
	var max_route := 0
	var max_lanes := 0
	while not h.get_completion().is_terminal() and frames < 60 * 1200 and guard < 3000000:
		guard += 1
		if h.get_slots().rightmost_empty_index() != -1 and not h.get_supply().is_exhausted():
			var placed := false
			for k in range(3):
				if h.get_input_controller().activate_front((col + k) % 3).get("ok", false):
					col = (col + k + 1) % 3
					placed = true
					break
			if placed:
				continue
		if not two and rt.is_2x():
			rt.set_speed_2x(false)
		var rc0: int = _rp_count("access_compute_route")
		var lc0: int = _rp_count("m26_dispatch_lane")
		rt.tick(1.0 / 60.0)
		frames += 1
		max_route = maxi(max_route, _rp_count("access_compute_route") - rc0)
		max_lanes = maxi(max_lanes, _rp_count("m26_dispatch_lane") - lc0)
	RP.enabled = false
	var final: Array = []
	var b = h.get_board()
	for k in range(b.get_width() * b.get_height()):
		final.append(b.get_cell_state(k))
	var out := {"tag": tag, "speed": "2x" if two else "1x", "origins": origins, "origins_below": below,
		"won": h.get_completion().is_won(), "clears": cleared.size(), "dup_dispatch": dup[0], "dup_clear": dup[1],
		"residue": [h.get_claim_engine().live_claim_count(), h.get_reservations().get_reservation_count(),
			h.get_dispatcher().get_active_count(), h.get_slots().live_work_count()],
		"frames": frames, "max_route_per_lane": max_route, "max_lanes_per_frame": max_lanes,
		"dispatch": dispatch, "clears_seq": clears, "final": final, "routes": []}
	if mode == "base" or mode == "opt":
		out["routes"] = routing.log
	if mode == "shadow":
		out["shadow"] = {"routes": routing.routes, "diffs": routing.diffs, "count_diffs": routing.count_diffs,
			"layered": routing.layered, "opt_counts": routing.opt_counts, "base_counts": routing.base_counts}
		out["shadow_obj"] = {"routes": routing.routes, "diffs": routing.diffs, "count_diffs": routing.count_diffs, "layered": routing.layered, "first_diffs": routing.first_diffs}
		out["routes"] = []
	print("  %s: won=%s clears=%d frames=%d routes=%d" % [tag, str(out["won"]), out["clears"], frames, (routing.log.size() if (mode == "base" or mode == "opt") else routing.routes if mode == "shadow" else 0)])
	h.get_meta("sub").free()
	return out

func _rp_count(section: String) -> int:
	var a = RP._acc.get(section, null)
	return int(a[0]) if a != null else 0

func _stripe_level(w: int, k: int, id: String) -> Dictionary:
	var cells: Array = []
	for y in range(w):
		for x in range(w):
			cells.append(x * k / w)
	return {"version": 1, "id": id, "name": id, "difficulty": "TEST", "width": w, "height": w,
		"palette": HEX.slice(0, k), "cells": cells}

func _plan(lvl: Dictionary) -> Dictionary:
	var left := {}
	for c in lvl["cells"]:
		left[int(c)] = int(left.get(int(c), 0)) + 1
	var batches: Array = []
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

func _laid_out_host(lvl: Dictionary, plan: Dictionary):
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = _write_tmp(JSON.stringify(lvl))
	h.supply_plan_path = _write_tmp(JSON.stringify(plan))
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)
	h.set_meta("sub", sub)
	await process_frame
	await process_frame
	_ok(h.build(), "laid-out host builds %s" % h.get_build_error())
	await _settle(h)
	h.get_runtime().set_process(false)
	return h

func _settle(h) -> void:
	await process_frame
	await process_frame
	h.get_screen().relayout()
	await process_frame
	await process_frame

func _write_tmp(text: String) -> String:
	var p := "user://m25c004_%d.json" % Time.get_ticks_usec()
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p
