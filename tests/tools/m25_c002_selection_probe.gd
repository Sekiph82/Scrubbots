extends SceneTree
## M25-C002 V01 — per-lane target-selection instrumentation (INVESTIGATION ONLY, non-shipping).
##
## Reproduces the M29-C002 dense 59x59 hotspot on a REAL ProductionGameplayHost and records,
## PER LANE (one M25 claim_for_slot -> TargetSelector.select_and_reserve call), the full
## candidate scan: candidate count, rank of the winner, prefilter verdicts, is_targetable /
## compute_route calls, success/failure, per-probe and total time, board revision, origin,
## slot/batch/colour, and cross-lane repeats of the same failed (revision, origin, target).
##
## Instrumentation is transparent: a test-only TargetSelector subclass (ProbeSelector) is
## swapped into the claim engine and passes the SAME ProductionTargetAccess wrapped in a
## forwarding proxy. The proxy calls the real is_targetable() for every candidate the real
## selector asks about (same order, same verdict, same memo on the real access), so the
## selected target and every downstream consume_route / reservation are unchanged. A
## control run without the swap proves identical dispatch sequences (see `equivalence`).
##
## Run: godot --headless --path . -s res://tests/tools/m25_c002_selection_probe.gd -- <out_dir>

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const TargetSelectorScript = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const RP = preload("res://scripts/debug/runtime_perf_probe.gd")

const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const CIDS := ["C01", "C02", "C03", "C04", "C05", "C06"]
const WINDOW := 6.0


## Forwarding proxy. Classifies each asked candidate with the real access's own exact
## prefilter (_could_reach — pure except the revision-keyed mask cache it would build anyway),
## then forwards to the REAL is_targetable (same verdict, same memo on the real object).
class ProbeAccess:
	extends RefCounted
	var real
	var probes: Array = []
	func _init(r) -> void:
		real = r
	func is_targetable(idx: int) -> bool:
		var pre: bool = real._could_reach(idx)
		var t0 := Time.get_ticks_usec()
		var v: bool = real.is_targetable(idx)
		probes.append({"idx": idx, "pre": pre, "ok": v, "us": Time.get_ticks_usec() - t0})
		return v

class ProbeSelector:
	extends "res://scripts/gameplay/targeting/target_selector.gd"
	var rec: Dictionary = {}
	func select_and_reserve(color_id: int, owner_id: int, access_query) -> int:
		var board = _board
		var cand: Array = []
		if _candidate_index != null and _reservations != null:
			cand = _candidate_index.get_candidates(color_id, _reservations.get_reserved_indices())
			cand = TargetSelectorScript._priority_sorted(cand, board)
		var proxy = ProbeAccess.new(access_query)
		var rev: int = board.get_revision() if board != null else -1
		var origin: Vector2 = access_query._origin if access_query is ProductionTargetAccess else Vector2.ZERO
		var t0 := Time.get_ticks_usec()
		var r: int = super.select_and_reserve(color_id, owner_id, proxy)
		var total := Time.get_ticks_usec() - t0
		var lanes: Array = rec.get("lanes", [])
		lanes.append({"frame": int(rec.get("frame", 0)), "rev": rev, "origin": origin, "color": color_id,
			"owner": owner_id, "cand": cand, "probes": proxy.probes, "winner": r, "us": total,
			"slot": int(rec.get("slot", -1)), "batch": String(rec.get("batch", ""))})
		rec["lanes"] = lanes
		return r

var rec: Dictionary = {}
var _tmp: Array = []
var _out := {}
var _lines: Array = []

func _initialize() -> void:
	await process_frame
	var runs: Array = []
	# (1) The M29-C002 harness shape: fixture host added headless WITHOUT a sized viewport /
	#     relayout, so SlotOriginProvider maps unlaid slot anchors to board-local y = 0.
	runs.append(await _run(59, 6, true, 60, false, true, false, "UNLAID 59x59 6 slots 2x 60fps (M29-C002 harness shape)"))
	# (2) Real production geometry: 1080x2160 SubViewport + relayout (M29 Hazard smoke shape).
	runs.append(await _run(59, 6, true, 60, false, true, true, "LAID-OUT 59x59 6 slots 2x 60fps"))
	runs.append(await _run(59, 6, false, 60, false, true, true, "LAID-OUT 59x59 6 slots 1x 60fps"))
	runs.append(await _run(59, 6, true, 60, true, true, true, "LAID-OUT 59x59 6 slots 2x 60fps HISTORICAL-TEMPO"))
	runs.append(await _run(59, 6, true, 30, false, true, true, "LAID-OUT 59x59 6 slots 2x 30fps"))
	runs.append(await _run(59, 5, true, 60, false, true, true, "LAID-OUT 59x59 5 slots 2x 60fps"))
	runs.append(await _run(32, 6, true, 60, false, true, true, "LAID-OUT 32x32 6 slots 2x 60fps CONTROL"))
	runs.append(await _run(32, 6, true, 60, false, true, false, "UNLAID 32x32 6 slots 2x 60fps CONTROL"))
	# Whole level to terminal on real geometry (distribution over every lane of the level).
	runs.append(await _run(59, 6, true, 60, false, true, true, "LAID-OUT 59x59 6 slots 2x 60fps FULL LEVEL", 0.0))
	# Transparency proof: identical dispatch sequence with and without the probe swap.
	var ctl := await _run(59, 6, true, 60, false, false, true, "LAID-OUT 59x59 6 slots 2x 60fps UNINSTRUMENTED")
	var same: bool = runs[1]["dispatch"] == ctl["dispatch"]
	var ctl_full := await _run(59, 6, true, 60, false, false, true, "LAID-OUT 59x59 6 slots 2x 60fps FULL LEVEL UNINSTRUMENTED", 0.0)
	var full_i: Dictionary = runs[runs.size() - 1]
	_out["equivalence_full_level"] = {"identical_dispatch_sequence": full_i["dispatch"] == ctl_full["dispatch"],
		"dispatches": ctl_full["dispatch"].size()}
	_lines.append("EQUIVALENCE full level instrumented vs uninstrumented dispatch sequence identical: %s (%d vs %d)" % [
		full_i["dispatch"] == ctl_full["dispatch"], full_i["dispatch"].size(), ctl_full["dispatch"].size()])
	runs.append(ctl_full)
	_out["equivalence"] = {"instrumented_dispatch_count": runs[1]["dispatch"].size(),
		"uninstrumented_dispatch_count": ctl["dispatch"].size(), "identical_dispatch_sequence": same}
	_lines.append("EQUIVALENCE laid-out instrumented vs uninstrumented dispatch sequence identical: %s (%d vs %d)" % [
		same, runs[1]["dispatch"].size(), ctl["dispatch"].size()])
	print(_lines[_lines.size() - 1])
	var summaries: Array = []
	for r in runs:
		summaries.append(r["summary"])
	_out["runs"] = summaries
	_write()
	_cleanup()
	quit(0)

func _run(w: int, slots_n: int, two: bool, fps: int, legacy: bool, instrument: bool, laid_out: bool, tag: String, window: float = WINDOW) -> Dictionary:
	rec = {"lanes": []}   # fresh dict per run, shared by reference with the ProbeSelector
	var dt := 1.0 / float(fps)
	var lvl := _stripe_level(w, 6, "m25c002_%d_%d" % [w, Time.get_ticks_usec()])
	var h = await _host(lvl, _plan(lvl), 0.5 if legacy else -1.0, laid_out)
	if legacy:
		h.get_scheduler()._speed = 6.0
	if slots_n == 6:
		h.get_economy().boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
		h.activate_plus_one_slot()
		if laid_out:
			await _settle(h)
	h.get_runtime().set_process(false)
	h.get_runtime().reset_runtime()
	if instrument:
		var ps = ProbeSelector.new()
		ps.rec = rec
		if not ps.bind(h.get_board(), h.get_candidate_index(), h.get_reservations()):
			push_error("probe selector bind failed")
		h.get_claim_engine()._selector = ps
	var origins: Array = []
	for i in range(slots_n):
		origins.append(h.get_origin_provider().origin_for_slot(i))
	var rt = h.get_runtime()
	var sch = h.get_scheduler()
	rt.set_speed_2x(two)
	var dispatch: Array = []
	h.get_dispatcher().assignment_dispatched.connect(func(_o, t, c, _a): dispatch.append([t, c]))
	var frames := 0
	var col := 0
	var guard := 0
	var max_frames := int(round(window * fps)) if window > 0.0 else fps * 1200
	RP.reset()
	RP.enabled = not instrument   # uninstrumented runs: real production target_selection timing
	var frame_us: Array = []
	while frames < max_frames and guard < 100000 and not h.get_completion().is_terminal():
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
		# Lane about to be serviced (same skip rule as AutoDispatchScheduler.step_lane).
		rec["frame"] = frames
		rec["slot"] = -1
		rec["batch"] = ""
		for lane in sch._wave_lanes:
			var s: int = int(lane["slot"])
			if h.get_slots().is_occupied(s) and h.get_slots().get_batch_id(s) == lane["batch_id"] \
					and h.get_slots().get_capacity(s) > 0 and not sch.is_slot_waiting(s):
				rec["slot"] = s
				rec["batch"] = lane["batch_id"]
				break
		var t0 := Time.get_ticks_usec()
		rt.tick(dt)
		frame_us.append(Time.get_ticks_usec() - t0)
		frames += 1
	RP.enabled = false
	var summary := _summarize(tag, w, h, rec["lanes"], frame_us)
	summary["state"] = String(h.get_completion().get_state())
	if not instrument:
		var snap: Dictionary = RP.snapshot()
		summary["perfprobe"] = {}
		for k in ["target_selection", "m25_claim", "m26_dispatch_lane", "access_compute_route", "access_validate", "route_sources",
				"route_dijkstra", "route_validate", "dispatcher_spawn", "agent_drive_arrival", "completion_on_tick", "ui_snapshot_sync"]:
			summary["perfprobe"][k] = snap.get(k, {})
		for k in summary["perfprobe"]:
			_lines.insert(_lines.size() - 1, "RuntimePerfProbe (uninstrumented) %s %s" % [k, JSON.stringify(summary["perfprobe"][k])])
	summary["slot_origins"] = origins.map(func(o): return [snappedf(o.x, 0.01), snappedf(o.y, 0.01)])
	summary["clears"] = h.get_clearing_loop().get_cleared_count()
	summary["dispatches"] = dispatch.size()
	_lines.insert(_lines.size() - 1, "slot origins %s (board %dx%d; inside-board start iff 0<=x<%d and 0<=y<%d) dispatches=%d clears=%d" % [
		str(summary["slot_origins"]), w, w, w, w, dispatch.size(), summary["clears"]])
	var holder = h.get_meta("sub") if h.has_meta("sub") else h
	holder.free()
	return {"summary": summary, "dispatch": dispatch}

func _settle(h) -> void:
	await process_frame
	await process_frame
	h.get_screen().relayout()
	await process_frame
	await process_frame

func _summarize(tag: String, w: int, h, lanes: Array, frame_us: Array) -> Dictionary:
	var probes_per_lane: Array = []
	var routes_per_lane: Array = []
	var sel_ms: Array = []
	var fail_routes := 0
	var ok_routes := 0
	var pre_rej := 0
	var route_us_total := 0
	var route_us_max := 0
	var fail_perimeter := 0
	var fail_interior := 0
	var fail_reason := {}
	var failed_keys := {}
	var repeat_same_rev_origin := 0
	var repeat_same_rev_any_origin := 0
	var verdict_by_rev_idx := {}
	var origin_disagree := 0
	var no_target_lanes := 0
	var winner_ranks: Array = []
	var rej_ms_per_lane: Array = []
	var overhead_ms_per_lane: Array = []
	var us_per_rejected: Array = []
	var cand_counts: Array = []
	var bh: int = h.get_board().get_height()
	var inside_lanes := 0
	for L in lanes:
		var o: Vector2 = L["origin"]
		if floor(o.x) >= 0 and floor(o.y) >= 0 and floor(o.x) < w and floor(o.y) < bh:
			inside_lanes += 1
		var n_route := 0
		for p in L["probes"]:
			if not p["pre"]:
				pre_rej += 1
				continue
			n_route += 1
			route_us_total += int(p["us"])
			route_us_max = maxi(route_us_max, int(p["us"]))
			var key_ri := "%d|%d" % [L["rev"], p["idx"]]
			if verdict_by_rev_idx.has(key_ri) and verdict_by_rev_idx[key_ri] != p["ok"]:
				origin_disagree += 1
			verdict_by_rev_idx[key_ri] = p["ok"]
			if p["ok"]:
				ok_routes += 1
			else:
				fail_routes += 1
				var pos: Vector2i = Vector2i(p["idx"] % w, p["idx"] / w)
				var perim: bool = pos.x == 0 or pos.y == 0 or pos.x == w - 1 or pos.y == bh - 1
				if perim: fail_perimeter += 1
				else: fail_interior += 1
				var k := "%d|%s|%d" % [L["rev"], str(L["origin"]), p["idx"]]
				if failed_keys.has(k): repeat_same_rev_origin += 1
				failed_keys[k] = true
				if failed_keys.has("any|" + key_ri): repeat_same_rev_any_origin += 1
				failed_keys["any|" + key_ri] = true
		var rej_us := 0
		var all_us := 0
		for p in L["probes"]:
			all_us += int(p["us"])
			if not p["pre"]:
				rej_us += int(p["us"])
		rej_ms_per_lane.append(float(rej_us) / 1000.0)
		overhead_ms_per_lane.append(float(int(L["us"]) - all_us) / 1000.0)
		var n_rej: int = L["probes"].size() - n_route
		if n_rej > 0:
			us_per_rejected.append(float(rej_us) / float(n_rej))
		probes_per_lane.append(L["probes"].size())
		routes_per_lane.append(n_route)
		sel_ms.append(float(L["us"]) / 1000.0)
		cand_counts.append(L["cand"].size())
		if L["winner"] == -1:
			no_target_lanes += 1
			winner_ranks.append(-1)
		else:
			winner_ranks.append(L["cand"].find(L["winner"]))
	var worst := _worst_lanes(lanes, w, bh, 5)
	var s := {"tag": tag, "lanes": lanes.size(), "no_target_lanes": no_target_lanes, "inside_board_origin_lanes": inside_lanes,
		"candidates_per_lane": _dist(cand_counts), "is_targetable_calls_per_lane": _dist(probes_per_lane),
		"compute_route_calls_per_lane": _dist(routes_per_lane), "selection_ms_per_lane": _distf(sel_ms),
		"winner_rank": _dist(winner_ranks.filter(func(v): return v >= 0)),
		"prefilter_rejected_total": pre_rej, "route_ok_total": ok_routes, "route_fail_total": fail_routes,
		"route_fail_perimeter": fail_perimeter, "route_fail_interior": fail_interior,
		"route_ms_mean": snappedf(float(route_us_total) / maxf(1.0, float(ok_routes + fail_routes)) / 1000.0, 0.001),
		"route_ms_max": snappedf(float(route_us_max) / 1000.0, 0.001),
		"failed_probe_repeats_same_rev_same_origin": repeat_same_rev_origin,
		"failed_probe_repeats_same_rev_any_origin": repeat_same_rev_any_origin,
		"verdict_disagreements_same_rev_idx_different_origin": origin_disagree,
		"distinct_revisions_seen": _distinct(lanes.map(func(L): return L["rev"])),
		"distinct_origins_seen": _distinct(lanes.map(func(L): return str(L["origin"]))),
		"frame_ms": _distf(frame_us.map(func(u): return float(u) / 1000.0)),
		"prefilter_rejected_is_targetable_ms_per_lane": _distf(rej_ms_per_lane),
		"selector_loop_overhead_ms_per_lane_incl_proxy": _distf(overhead_ms_per_lane),
		"us_per_prefilter_rejected_call": _distf(us_per_rejected),
		"worst_lanes": worst}
	_lines.append("## %s" % tag)
	_lines.append("lanes=%d inside-board-origin lanes=%d no_target=%d candidates/lane %s" % [s["lanes"], inside_lanes, no_target_lanes, str(s["candidates_per_lane"])])
	_lines.append("is_targetable/lane %s" % str(s["is_targetable_calls_per_lane"]))
	_lines.append("compute_route/lane %s" % str(s["compute_route_calls_per_lane"]))
	_lines.append("selection_ms/lane %s" % str(s["selection_ms_per_lane"]))
	_lines.append("winner rank %s" % str(s["winner_rank"]))
	_lines.append("prefilter rejected=%d route ok=%d fail=%d (perimeter %d / interior %d) route_ms mean=%.3f max=%.3f" % [pre_rej, ok_routes, fail_routes, fail_perimeter, fail_interior, s["route_ms_mean"], s["route_ms_max"]])
	_lines.append("failed repeats same(rev,origin,idx)=%d same(rev,idx) any origin=%d; verdict disagreements across origins=%d; distinct revs=%d origins=%d" % [
		repeat_same_rev_origin, repeat_same_rev_any_origin, origin_disagree, s["distinct_revisions_seen"], s["distinct_origins_seen"]])
	_lines.append("frame_ms %s" % str(s["frame_ms"]))
	_lines.append("prefilter-rejected is_targetable ms/lane %s | us per rejected call %s | selector loop + proxy overhead ms/lane %s" % [
		str(s["prefilter_rejected_is_targetable_ms_per_lane"]), str(s["us_per_prefilter_rejected_call"]), str(s["selector_loop_overhead_ms_per_lane_incl_proxy"])])
	for wl in worst:
		_lines.append("  worst lane: %s" % JSON.stringify(wl))
	_lines.append("")
	print(_lines.slice(_lines.size() - 12).reduce(func(a, b): return a + "\n" + b, ""))
	return s

## The N most expensive lanes with full per-lane attribution + a failure anatomy sample.
func _worst_lanes(lanes: Array, w: int, bh: int, n: int) -> Array:
	var idxs: Array = range(lanes.size())
	idxs.sort_custom(func(a, b): return lanes[a]["us"] > lanes[b]["us"])
	var out: Array = []
	for i in idxs.slice(0, n):
		var L: Dictionary = lanes[i]
		var routes: Array = L["probes"].filter(func(p): return p["pre"])
		var fails: Array = routes.filter(func(p): return not p["ok"])
		var rows := {}
		for p in fails:
			rows[p["idx"] / w] = int(rows.get(p["idx"] / w, 0)) + 1
		var first_fails: Array = []
		for p in fails.slice(0, 6):
			first_fails.append([p["idx"] % w, p["idx"] / w])
		var us_sum := 0
		var us_max := 0
		for p in routes:
			us_sum += int(p["us"]); us_max = maxi(us_max, int(p["us"]))
		out.append({"frame": L["frame"], "rev": L["rev"], "slot": L["slot"], "batch": L["batch"], "color": L["color"],
			"origin": [snappedf(L["origin"].x, 0.01), snappedf(L["origin"].y, 0.01)], "candidates": L["cand"].size(),
			"skipped_before_first_probe_or_unasked": L["cand"].size() - L["probes"].size(),
			"is_targetable": L["probes"].size(), "prefilter_rejected": L["probes"].size() - routes.size(),
			"compute_route": routes.size(), "route_ok": routes.size() - fails.size(), "route_fail": fails.size(),
			"winner": L["winner"], "winner_xy": [L["winner"] % w, L["winner"] / w] if L["winner"] >= 0 else [],
			"winner_rank": L["cand"].find(L["winner"]) if L["winner"] >= 0 else -1,
			"selection_ms": snappedf(float(L["us"]) / 1000.0, 0.01), "route_ms_total": snappedf(float(us_sum) / 1000.0, 0.01),
			"route_ms_max": snappedf(float(us_max) / 1000.0, 0.01), "failed_rows_hist": rows, "first_failed_xy": first_fails})
	return out

func _dist(a: Array) -> Dictionary:
	if a.is_empty():
		return {"n": 0}
	var s := a.duplicate(); s.sort()
	var sum := 0
	for v in s: sum += int(v)
	return {"n": s.size(), "min": s[0], "p50": s[s.size() / 2], "p90": s[int(s.size() * 0.9)], "max": s[s.size() - 1],
		"mean": snappedf(float(sum) / float(s.size()), 0.1)}

func _distf(a: Array) -> Dictionary:
	if a.is_empty():
		return {"n": 0}
	var s := a.duplicate(); s.sort()
	var sum := 0.0
	for v in s: sum += float(v)
	return {"n": s.size(), "min": snappedf(s[0], 0.01), "p50": snappedf(s[s.size() / 2], 0.01), "p90": snappedf(s[int(s.size() * 0.9)], 0.01),
		"p99": snappedf(s[int(s.size() * 0.99)], 0.01), "max": snappedf(s[s.size() - 1], 0.01), "mean": snappedf(sum / float(s.size()), 0.01)}

func _distinct(a: Array) -> int:
	var d := {}
	for v in a: d[v] = true
	return d.size()

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

func _host(lvl: Dictionary, plan: Dictionary, base_cadence: float, laid_out: bool):
	var lp := _write_tmp(JSON.stringify(lvl))
	var pp := _write_tmp(JSON.stringify(plan))
	var h = ProductionGameplayHost.new()
	if base_cadence > 0.0:
		h.base_cadence = base_cadence
	h.auto_build = false
	h.level_path = lp
	h.supply_plan_path = pp
	if laid_out:
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
	else:
		get_root().add_child(h)
	if not h.build():
		push_error("build failed %s" % h.get_build_error())
	if laid_out:
		await _settle(h)
	h.get_runtime().set_process(false)
	return h

func _write_tmp(text: String) -> String:
	var p := "user://m25c002_%d.json" % Time.get_ticks_usec()
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _write() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		return
	var dir: String = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	_out["tool"] = "tests/tools/m25_c002_selection_probe.gd"
	_out["engine"] = Engine.get_version_info()["string"]
	var f := FileAccess.open(dir.path_join("selection_probe_report.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_out, "  "))
	f.close()
	f = FileAccess.open(dir.path_join("selection_probe_report.txt"), FileAccess.WRITE)
	f.store_string("M25-C002 per-lane target-selection probe (tests/tools/m25_c002_selection_probe.gd)\n\n" + "\n".join(_lines) + "\n")
	f.close()

func _cleanup() -> void:
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
