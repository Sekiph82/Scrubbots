extends SceneTree
## M25-C003 before/after timing probe (test-only, non-shipping). Runs the laid-out 59x59
## six-stripe full level to WON on the UNMODIFIED production path (no selector swap, no
## new-API use) so the same file runs on the pre-C003 and post-C003 code.
## Run: godot --headless --path . -s res://tests/tools/m25_c003_timing_probe.gd -- <out.json> <label>

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const RP = preload("res://scripts/debug/runtime_perf_probe.gd")
const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const CIDS := ["C01", "C02", "C03", "C04", "C05", "C06"]

var _tmp: Array = []
var _fail := 0

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var res := {"label": args[1] if args.size() > 1 else "", "engine": Engine.get_version_info()["string"]}
	for two in [true, false]:
		var r := await _full_run("production %s" % ("2x" if two else "1x"), "none", two)
		res["2x" if two else "1x"] = {"origins": r["origins"], "origins_below": r["origins_below"], "won": r["won"],
			"clears": r["clears"], "max_route_per_lane": r["max_route_per_lane"], "timing": r["timing"],
			"dispatch_hash": str(r["dispatch"]).hash()}
		print("%s %s" % [res["label"], JSON.stringify(res["2x" if two else "1x"])])
	if args.size() > 0:
		var f := FileAccess.open(args[0], FileAccess.WRITE)
		f.store_string(JSON.stringify(res, "  "))
		f.close()
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	quit(0)

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)

func _full_run(tag: String, mode: String, two: bool) -> Dictionary:
	var lvl := _stripe_level(59, 6, "m25c003_59_%s_%d" % [mode, Time.get_ticks_usec()])
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
	var cs = null
	var rt = h.get_runtime()
	var sch = h.get_scheduler()
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
	var sel_ms: Array = []
	var scan_ms: Array = []
	var route_ms: Array = []
	var dij_ms: Array = []
	var frame_ms: Array = []
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
		RP.take_frame()
		var t0 := Time.get_ticks_usec()
		rt.tick(1.0 / 60.0)
		frame_ms.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		var f: Dictionary = RP.take_frame()
		frames += 1
		max_route = maxi(max_route, _rp_count("access_compute_route") - rc0)
		max_lanes = maxi(max_lanes, _rp_count("m26_dispatch_lane") - lc0)
		if f.has("target_selection"):
			var sel := float(f["target_selection"]) / 1000.0
			var rte := float(f.get("access_compute_route", 0)) / 1000.0
			var val := float(f.get("access_validate", 0)) / 1000.0
			sel_ms.append(sel)
			scan_ms.append(maxf(0.0, sel - rte - val))
			if f.has("access_compute_route"):
				route_ms.append(rte)
				dij_ms.append(float(f.get("route_dijkstra", 0)) / 1000.0)
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
		"dispatch": dispatch, "clears_seq": clears, "final": final,
		"timing": {"note": "RuntimePerfProbe per frame (one lane per frame); instrumentation adds overhead in counting/baseline modes",
			"lanes": sel_ms.size(), "target_selection_ms": _dist(sel_ms), "scan_excl_route_ms": _dist(scan_ms),
			"winner_route_ms": _dist(route_ms), "route_dijkstra_ms": _dist(dij_ms), "frame_ms": _dist(frame_ms)}}
	h.get_meta("sub").free()
	return out

func _rp_count(section: String) -> int:
	var a = RP._acc.get(section, null)
	return int(a[0]) if a != null else 0

func _dist(a: Array) -> Dictionary:
	if a.is_empty():
		return {"n": 0}
	var s := a.duplicate()
	s.sort()
	var sum := 0.0
	for v in s:
		sum += float(v)
	return {"n": s.size(), "p50": snappedf(s[s.size() / 2], 0.001), "p90": snappedf(s[int(s.size() * 0.9)], 0.001),
		"p99": snappedf(s[int(s.size() * 0.99)], 0.001), "max": snappedf(s[s.size() - 1], 0.001), "mean": snappedf(sum / s.size(), 0.001)}

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

## Real production slot geometry: 1080x2160 SubViewport, settle, build, relayout, settle.
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
	var p := "user://m25c003_%d.json" % Time.get_ticks_usec()
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p
