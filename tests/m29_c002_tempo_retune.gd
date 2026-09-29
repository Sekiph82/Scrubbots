extends SceneTree
## M29-C002 V01 — gameplay tempo retune (SB-M29-010) focused suite.
##
## Owner authority: coordination/OWNER_SCRUBBOT_SIZE_AND_GAMEPLAY_TEMPO_V01.md §2.
##   NEW 1x = old 1.5x: travel 9 cells/s, cadence 1/3 s.
##   NEW 2x = 2 * NEW 1x: travel 18 cells/s, cadence 1/6 s.
## Factors stay 1.0 / 2.0; MAX_LANES_PER_FRAME stays 1; no Engine.time_scale.
##
## Sections (prompt "Required focused tests" 1..7 + performance evidence):
##   s1 canonical constants / single source      s5 1x vs 2x gameplay-truth equivalence
##   s2 effective travel (long real route)       s6 existing 2x authorities (paid/timed/M23)
##   s3 cadence timing probe + hitch + wake      s7 reset -> new 1x
##   s4 5/6-lane 30/60 FPS bounded-wave stress   s8 real host 32x32 full + 59x59 dense window
##
## Run: godot --headless --path . -s res://tests/m29_c002_tempo_retune.gd [-- <evidence_dir>]
## With an evidence dir it writes tempo_report.json, tempo_report.txt and
## real_host_trace_1x_2x.txt there. Exits 0 on success, 1 on any failure.

const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const GameplaySpeedAuthority = preload("res://scripts/gameplay/runtime/gameplay_speed_authority.gd")
const ProductionRuntimeController = preload("res://scripts/gameplay/runtime/production_runtime_controller.gd")
const AutoDispatchScheduler = preload("res://scripts/gameplay/dispatch/auto_dispatch_scheduler.gd")
const ScrubbotDispatcher = preload("res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")

const RP = preload("res://scripts/debug/runtime_perf_probe.gd")
const WINDOW_59 := 6.0   ## gameplay seconds per 59x59 dense window (see s8)
const V1_SPEED := 9.0
const V2_SPEED := 18.0
const V1_CADENCE := 1.0 / 3.0
const V2_CADENCE := 1.0 / 6.0
const DT60 := 1.0 / 60.0
const DT30 := 1.0 / 30.0
const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]  # C01..C06
const CIDS := ["C01", "C02", "C03", "C04", "C05", "C06"]

var _fail := 0
var _tmp: Array = []
var _now := [1_900_000_000]
var _report := {}
var _trace_lines: Array = []

## Duck-typed lane scheduler: records exactly what the controller asks of it, so the
## cadence clock and the one-lane-per-frame budget are measured, not assumed.
class LaneProbe:
	extends RefCounted
	var lanes_per_wave := 1
	var t := 0.0
	var pending := 0
	var begins: Array = []           # gameplay time of every begin_wave
	var overlap_begins := 0          # begin_wave while a wave still had lanes
	var lanes_this_frame := 0
	var max_lanes_per_frame := 0
	var begins_this_frame := 0
	var max_begins_per_frame := 0
	var queued: Array = []
	func step() -> Dictionary: return {"ok": false}
	func notify_placed() -> void: pass
	func has_pending_lanes() -> bool: return pending > 0
	func begin_wave() -> int:
		if pending > 0:
			overlap_begins += 1
		begins.append(t)
		begins_this_frame += 1
		pending = lanes_per_wave
		return pending
	func step_lane() -> Dictionary:
		lanes_this_frame += 1
		pending -= 1
		return {"ok": true}
	func queue_lane(slot) -> bool:
		queued.append(slot)
		pending += 1
		return true
	func frame_end() -> void:
		max_lanes_per_frame = maxi(max_lanes_per_frame, lanes_this_frame)
		max_begins_per_frame = maxi(max_begins_per_frame, begins_this_frame)
		lanes_this_frame = 0
		begins_this_frame = 0

func _initialize() -> void:
	await process_frame
	_s1_constants()
	_s2_travel()
	_s3_cadence()
	_s4_wave_stress()
	_s5_truth_equivalence()
	await _s6_authorities()
	_s7_reset()
	await _s8_real_host()
	_write_evidence()
	_cleanup()
	_done()

# ================================================================ s1 constants ==
func _s1_constants() -> void:
	print("[s1 canonical constants / single source]")
	_ok(ScrubbotAgent.DEFAULT_SPEED == V1_SPEED, "ScrubbotAgent.DEFAULT_SPEED == 9.0 (%s)" % ScrubbotAgent.DEFAULT_SPEED)
	_ok(ScrubbotDispatcher.DEFAULT_SPEED == ScrubbotAgent.DEFAULT_SPEED, "dispatcher default resolves to the agent constant")
	_ok(AutoDispatchScheduler.DEFAULT_SPEED == ScrubbotAgent.DEFAULT_SPEED, "production scheduler default resolves to the agent constant")
	_ok(CompleteClearingLoop.DEFAULT_SPEED == ScrubbotAgent.DEFAULT_SPEED, "clearing-loop default resolves to the agent constant")
	var numeric := RegEx.create_from_string("const\\s+DEFAULT_SPEED\\s*:?=\\s*[0-9]")
	var stale := RegEx.create_from_string("DEFAULT_SPEED\\s*:?=\\s*6\\.0")
	for p in ["res://scripts/gameplay/dispatch/scrubbot_dispatcher.gd", "res://scripts/gameplay/dispatch/auto_dispatch_scheduler.gd",
			"res://scripts/gameplay/clearing/complete_clearing_loop.gd"]:
		var src := FileAccess.get_file_as_string(p)
		_ok(numeric.search(src) == null, "%s carries no independent numeric DEFAULT_SPEED" % p.get_file())
	var agent_src := FileAccess.get_file_as_string("res://scripts/gameplay/agents/scrubbot_agent.gd")
	_ok(numeric.search_all(agent_src).size() == 1 and stale.search(agent_src) == null, "agent holds the ONE numeric travel baseline; no stale 6.0")
	_ok(GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL == 1.0 / 3.0, "DEFAULT_BASE_INTERVAL is exactly 1.0/3.0 (%.17f)" % GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL)
	_ok(absf(GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL - 0.33) > 0.003, "not the rounded 0.33")
	_ok(GameplaySpeedAuthority.FACTOR_1X == 1.0 and GameplaySpeedAuthority.FACTOR_2X == 2.0, "factors stay 1.0 / 2.0")
	var sp = GameplaySpeedAuthority.new()
	_ok(sp.factor() == 1.0 and sp.cadence_interval() == V1_CADENCE, "default authority: 1x, cadence 1/3 s")
	sp.set_2x(true)
	_ok(sp.factor() == 2.0 and sp.cadence_interval() == V2_CADENCE, "2x: factor 2.0, cadence exactly 1/6 s (%.17f)" % sp.cadence_interval())
	_ok(ProductionRuntimeController.MAX_LANES_PER_FRAME == 1 and ProductionRuntimeController.MAX_STEPS_PER_FRAME == 1, "one lane / one wave per frame budget unchanged")
	var ts := RegEx.create_from_string("Engine\\.time_scale\\s*=[^=]")
	var ts_hits := 0
	for p in ["res://scripts/gameplay/runtime/gameplay_speed_authority.gd", "res://scripts/gameplay/runtime/production_runtime_controller.gd",
			"res://scripts/gameplay/runtime/production_gameplay_host.gd", "res://scripts/ui/production_input_controller.gd"]:
		ts_hits += ts.search_all(FileAccess.get_file_as_string(p)).size()
	_ok(ts_hits == 0 and Engine.time_scale == 1.0, "no Engine.time_scale assignment in the speed path; Engine.time_scale == 1")
	# Production host path resolves the same canonical values.
	var h = _host_level(2)
	_ok(h.base_cadence == V1_CADENCE and h.get_speed_authority().base_interval() == V1_CADENCE, "production host cadence base == 1/3 s")
	_ok(h.get_scheduler()._speed == V1_SPEED, "production scheduler dispatch speed == 9.0")
	_click(h, [1])
	h.get_scheduler().step()
	var a = _first_agent(h)
	_ok(a != null and a.speed == V1_SPEED, "production-dispatched agent carries speed 9.0")
	h.free()
	_report["constants"] = {"agent_default_speed": ScrubbotAgent.DEFAULT_SPEED, "dispatcher_default_speed": ScrubbotDispatcher.DEFAULT_SPEED,
		"scheduler_default_speed": AutoDispatchScheduler.DEFAULT_SPEED, "base_interval": GameplaySpeedAuthority.DEFAULT_BASE_INTERVAL,
		"factor_1x": GameplaySpeedAuthority.FACTOR_1X, "factor_2x": GameplaySpeedAuthority.FACTOR_2X,
		"max_lanes_per_frame": ProductionRuntimeController.MAX_LANES_PER_FRAME}

# =================================================================== s2 travel ==
func _s2_travel() -> void:
	print("[s2 effective travel on a long real route]")
	var board = BoardState.from_level_data(_stripe_level_data(59, 59, 6))
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var origin := Vector2(29.5, 63.0)
	var best := {}
	for x in [0, 29, 58]:
		var req = RouteRequest.for_target(board, origin, x)  # top row
		var route = routing.compute_route(req, board, raccess) if req != null else null
		if route != null and route.success:
			var probe = ScrubbotAgent.new()
			probe.assign(0, board.get_color_id(x), req, route)
			var ln: float = probe.get_route_length()
			probe.free()
			if best.is_empty() or ln > best["len"]:
				best = {"req": req, "route": route, "color": board.get_color_id(x), "len": ln}
	_ok(not best.is_empty() and best["len"] >= 60.0, "long deterministic 59x59 route found (%.1f cells)" % (best.get("len", 0.0)))
	if best.is_empty():
		return
	var rows := {}
	for fps in [60, 30]:
		var dt := 1.0 / float(fps)
		var r := _travel_rig()
		var rt = r["rt"]; var layer = r["layer"]; var speed = r["speed"]
		var a = _spawn(layer, best, 0)
		_ok(a.speed == V1_SPEED, "agent assigned with default speed -> 9.0")
		var d1 := _advance(rt, a, dt, fps)                # 1 s @1x
		speed.set_2x(true)
		var b = _spawn(layer, best, 1)                    # future agent after the switch
		var a0 := _dist(a)
		_ticks(rt, dt, fps)                               # 1 s @2x
		var d2_cur := _dist(a) - a0
		var d2_new := _dist(b)
		rt.set_user_paused(true)
		var pa := _dist(a); var pb := _dist(b)
		_ticks(rt, dt, fps)                               # 1 s paused
		var frozen := _dist(a) == pa and _dist(b) == pb
		rt.set_user_paused(false)
		var still_2x: bool = speed.is_2x()
		var ra := _dist(a)
		_ticks(rt, dt, fps / 2)                           # 0.5 s @2x after resume
		var d_resume := _dist(a) - ra
		speed.set_2x(false)
		var c = _spawn(layer, best, 2)
		_ticks(rt, dt, fps)
		var d_back := _dist(c)
		_ok(absf(d1 - V1_SPEED) < 1e-3, "%dfps: NEW 1x travels 9.0 cells in 1.0 s (%.4f)" % [fps, d1])
		_ok(absf(d2_new - V2_SPEED) < 1e-3, "%dfps: NEW 2x future agent travels 18.0 cells in 1.0 s (%.4f)" % [fps, d2_new])
		_ok(absf(d2_cur - V2_SPEED) < 1e-3, "%dfps: already-moving agent switches to 18 cells/s (%.4f)" % [fps, d2_cur])
		_ok(absf(d2_new / d1 - 2.0) < 1e-4, "%dfps: 2x/1x travel ratio == 2 (%.6f)" % [fps, d2_new / d1])
		_ok(frozen, "%dfps: user pause freezes every agent exactly" % fps)
		_ok(still_2x and absf(d_resume - V2_SPEED * 0.5) < 1e-3, "%dfps: resume keeps 2x (0.5 s -> %.4f cells)" % [fps, d_resume])
		_ok(absf(d_back - V1_SPEED) < 1e-3, "%dfps: back to 1x -> new agent 9.0 cells/s (%.4f)" % [fps, d_back])
		rows["%dfps" % fps] = {"cells_1s_1x": d1, "cells_1s_2x_new_agent": d2_new, "cells_1s_2x_moving_agent": d2_cur,
			"ratio": d2_new / d1, "paused_delta": _dist(a) - _dist(a), "resume_0_5s_2x": d_resume, "cells_1s_back_to_1x": d_back}
		layer.free(); rt.free()
	_report["travel"] = rows
	_report["travel_route_len_cells"] = best["len"]

func _travel_rig() -> Dictionary:
	var speed = GameplaySpeedAuthority.new()
	var layer := Node2D.new(); get_root().add_child(layer)
	var rt = ProductionRuntimeController.new(); get_root().add_child(rt)
	rt.set_process(false)
	rt.bind(LaneProbe.new(), speed, layer)
	return {"rt": rt, "layer": layer, "speed": speed}

func _spawn(layer, best: Dictionary, owner: int):
	var a = ScrubbotAgent.new()
	layer.add_child(a)
	a.assign(owner, best["color"], best["req"], best["route"])
	return a

func _dist(a) -> float:
	return a.get_route_length() * a.get_progress()

func _advance(rt, a, dt: float, n: int) -> float:
	var s := _dist(a)
	_ticks(rt, dt, n)
	return _dist(a) - s

func _ticks(rt, dt: float, n: int) -> void:
	for i in range(n):
		rt.tick(dt)

# ================================================================== s3 cadence ==
func _s3_cadence() -> void:
	print("[s3 cadence timing probe]")
	var rows := {}
	for two in [false, true]:
		var p := _cadence_probe(1, two, 1.0 / 1200.0, 12.0)
		var want: float = V2_CADENCE if two else V1_CADENCE
		_ok(absf(p["mean"] - want) < 1e-4, "%s cadence mean period == %.6f s (%.6f)" % ["2x" if two else "1x", want, p["mean"]])
		_ok(p["min"] >= want - 1e-6 and p["max"] <= want + 1.0 / 1200.0 + 1e-6, "%s every period within one probe step of nominal [%.6f, %.6f]" % ["2x" if two else "1x", p["min"], p["max"]])
		_ok(p["max_begins_per_frame"] <= 1 and p["overlap"] == 0, "%s no duplicate same-frame wave, no overlap" % ("2x" if two else "1x"))
		rows["2x" if two else "1x"] = p
	_ok(absf(rows["1x"]["mean"] / rows["2x"]["mean"] - 2.0) < 1e-3, "cadence ratio 1x/2x == 2 (%.5f)" % (rows["1x"]["mean"] / rows["2x"]["mean"]))
	_report["cadence"] = rows
	# Hitch: one huge delta never replays several waves / lanes.
	for two in [false, true]:
		var speed = GameplaySpeedAuthority.new(); speed.set_2x(two)
		var probe := LaneProbe.new(); probe.lanes_per_wave = 6
		var layer := Node2D.new(); get_root().add_child(layer)
		var rt = ProductionRuntimeController.new(); get_root().add_child(rt); rt.set_process(false)
		rt.bind(probe, speed, layer)
		for i in range(120):
			probe.t += DT60; rt.tick(DT60); probe.frame_end()
		var b0 := probe.begins.size()
		probe.t += 5.0; rt.tick(5.0)
		var hitch_lanes := probe.lanes_this_frame
		probe.frame_end()
		var b1 := probe.begins.size()
		var acc: float = rt._accum
		var post_lanes := 0
		for i in range(12):
			probe.t += DT60; rt.tick(DT60); post_lanes = maxi(post_lanes, probe.lanes_this_frame); probe.frame_end()
		_ok(b1 - b0 <= 1 and hitch_lanes <= 1, "%s 5 s hitch: <= 1 new wave, <= 1 lane that frame (waves +%d, lanes %d)" % ["2x" if two else "1x", b1 - b0, hitch_lanes])
		_ok(acc <= speed.cadence_interval() + 1e-9, "%s hitch backlog clamped to one interval (%.4f)" % ["2x" if two else "1x", acc])
		_ok(post_lanes <= 1 and probe.overlap_begins == 0, "%s no catch-up burst after the hitch" % ("2x" if two else "1x"))
		layer.free(); rt.free()
	# Placement wake: immediate ONLY for the placed lane (real host).
	var h = _host_level(2)
	var rt = h.get_runtime(); var sch = h.get_scheduler()
	_click(h, [1])
	_ok(sch.pending_lane_count() == 1, "placement queues exactly one immediate lane")
	rt.tick(DT60)
	_ok(_assign_count(h) == 1 and _by_slot(h).keys() == [_slot_of_first(h)], "placed slot dispatched on the next frame (before any cadence event)")
	_click(h, [2])
	_ok(sch.pending_lane_count() == 1, "second placement queues only ITS lane (first slot not re-woken)")
	rt.tick(DT60)
	_ok(_assign_count(h) == 2 and _by_slot(h).values() == [1, 1], "second slot dispatched; first slot still one assignment")
	var t := 2.0 * DT60
	while t + DT60 < V1_CADENCE - 1e-9:
		rt.tick(DT60); t += DT60
	_ok(_assign_count(h) == 2, "no further dispatch before the 1/3 s cadence event")
	rt.tick(DT60); rt.tick(DT60); rt.tick(DT60)
	_ok(_assign_count(h) == 4, "cadence event at 1/3 s dispatches one lane per occupied slot (%d)" % _assign_count(h))
	h.free()

func _cadence_probe(lanes: int, two: bool, dt: float, seconds: float) -> Dictionary:
	var speed = GameplaySpeedAuthority.new(); speed.set_2x(two)
	var probe := LaneProbe.new(); probe.lanes_per_wave = lanes
	var layer := Node2D.new(); get_root().add_child(layer)
	var rt = ProductionRuntimeController.new(); get_root().add_child(rt); rt.set_process(false)
	rt.bind(probe, speed, layer)
	var max_acc := 0.0
	var n := int(round(seconds / dt))
	for i in range(n):
		probe.t += dt
		rt.tick(dt)
		probe.frame_end()
		max_acc = maxf(max_acc, rt._accum)
	var per: Array = []
	for i in range(1, probe.begins.size()):
		per.append(probe.begins[i] - probe.begins[i - 1])
	var mean := 0.0
	var mn := INF
	var mx := 0.0
	for v in per:
		mean += v; mn = minf(mn, v); mx = maxf(mx, v)
	mean /= maxf(1.0, float(per.size()))
	layer.free(); rt.free()
	return {"lanes": lanes, "factor": 2.0 if two else 1.0, "dt": dt, "nominal": speed.cadence_interval(), "waves": probe.begins.size(),
		"mean": mean, "min": mn, "max": mx, "max_lanes_per_frame": probe.max_lanes_per_frame,
		"max_begins_per_frame": probe.max_begins_per_frame, "overlap": probe.overlap_begins, "max_accum": max_acc}

# ============================================================= s4 wave stress ==
func _s4_wave_stress() -> void:
	print("[s4 5/6-lane bounded-wave stress at 30/60 FPS]")
	var rows: Array = []
	for fps in [60, 30]:
		for lanes in [5, 6]:
			for two in [false, true]:
				var dt := 1.0 / float(fps)
				var p := _cadence_probe(lanes, two, dt, 20.0)
				var nominal: float = p["nominal"]
				var service := float(lanes) * dt
				var tag := "%dfps %dlanes %s" % [fps, lanes, "2x" if two else "1x"]
				_ok(p["max_lanes_per_frame"] == 1, "%s: one lane per frame" % tag)
				_ok(p["overlap"] == 0 and p["max_begins_per_frame"] <= 1, "%s: no overlapping / duplicate wave" % tag)
				_ok(p["max_accum"] <= nominal + 1e-9, "%s: cadence backlog bounded by one interval (%.4f)" % [tag, p["max_accum"]])
				# Expected throughput: nominal cadence unless one wave's service time is longer.
				var expect := maxf(nominal, service)
				_ok(absf(p["mean"] - expect) <= dt + 1e-6, "%s: wave period %.4f s (expected ~%.4f)" % [tag, p["mean"], expect])
				_ok(p["min"] >= minf(nominal, service) - dt - 1e-6, "%s: never faster than the cadence allows" % tag)
				if fps == 60 and two:
					_ok(service < nominal, "%s: full wave serviced (%.3f s) before next nominal 2x event (%.4f s)" % [tag, service, nominal])
				if fps == 30 and lanes == 6 and two:
					_ok(p["mean"] > nominal and absf(p["mean"] - 0.2) < 0.01, "30fps 6 lanes 2x: wave-service limited to ~0.20 s (%.4f) — accepted" % p["mean"])
				p["fps"] = fps
				p["service_time"] = service
				p["service_limited"] = service > nominal + 1e-9
				rows.append(p)
	_report["wave_stress_probe"] = rows

# ================================================================ s5 equivalence ==
func _s5_truth_equivalence() -> void:
	print("[s5 1x vs 2x gameplay-truth equivalence]")
	# Tempo-normalised: 2x driven at dt/2 must replay the 1x run event-for-event (same
	# targets, order, clears, accounting per frame) in half the gameplay time.
	var r1 := _truth_run(false, DT60, true)
	var r2 := _truth_run(true, DT60 * 0.5, true)
	_ok(r1["won"] and r2["won"], "both runs WON (1x %s / 2x %s)" % [r1["state"], r2["state"]])
	_ok(r1["dispatch"] == r2["dispatch"] and r1["dispatch"].size() > 0, "identical assignment order / targets / colors (%d assignments)" % r1["dispatch"].size())
	_ok(r1["clears"] == r2["clears"], "identical authenticated clear identity + order (%d clears)" % r1["clears"].size())
	_ok(r1["slot_hash"] == r2["slot_hash"], "identical per-frame slot remaining/committed accounting")
	_ok(r1["final"] == r2["final"], "identical final board state")
	_ok(r1["frames"] == r2["frames"] and absf(r2["seconds"] * 2.0 - r1["seconds"]) < 1e-6, "same frame count; 2x gameplay duration exactly half (%.3f s vs %.3f s)" % [r2["seconds"], r1["seconds"]])
	_ok(r1["residue"] == [0, 0, 0, 0] and r2["residue"] == [0, 0, 0, 0], "zero claims/reservations/agents/live work after both runs")
	# Same 60 FPS clock at both speeds: timing differs, gameplay truth end-state identical.
	var f1 := _truth_run(false, DT60, false)
	var f2 := _truth_run(true, DT60, false)
	var c1: Array = f1["clears"].duplicate(); c1.sort()
	var c2: Array = f2["clears"].duplicate(); c2.sort()
	_ok(f1["won"] and f2["won"] and f1["final"] == f2["final"] and c1 == c2, "same 60 FPS clock: both WON, same cleared-cell set, same final board")
	_ok(f1["residue"] == [0, 0, 0, 0] and f2["residue"] == [0, 0, 0, 0], "same 60 FPS clock: reservation/claim cleanup complete at both speeds")
	_ok(f2["seconds"] < f1["seconds"], "2x completes sooner in gameplay time (%.2f s vs %.2f s)" % [f2["seconds"], f1["seconds"]])
	_report["truth_equivalence"] = {
		"normalised": {"assignments": r1["dispatch"].size(), "clears": r1["clears"].size(), "frames": r1["frames"],
			"seconds_1x": r1["seconds"], "seconds_2x": r2["seconds"], "identical_dispatch": r1["dispatch"] == r2["dispatch"],
			"identical_clears": r1["clears"] == r2["clears"], "identical_slot_accounting": r1["slot_hash"] == r2["slot_hash"]},
		"same_60fps_clock": {"seconds_1x": f1["seconds"], "seconds_2x": f2["seconds"], "same_order": f1["clears"] == f2["clears"],
			"same_cleared_set": c1 == c2, "won_1x": f1["won"], "won_2x": f2["won"]}}
	_trace_lines.append("# Real-host trace, level 2 (production Apple), same 60 FPS clock")
	for pair in [["1x", f1], ["2x", f2]]:
		_trace_lines.append("## %s: WON=%s gameplay_seconds=%.3f frames=%d assignments=%d clears=%d" % [pair[0], pair[1]["won"],
			pair[1]["seconds"], pair[1]["frames"], pair[1]["dispatch"].size(), pair[1]["clears"].size()])
		_trace_lines.append("first 12 dispatches [t_s, target, color]: %s" % str(pair[1]["dispatch_t"].slice(0, 12)))
		_trace_lines.append("first 12 clears     [t_s, target, color]: %s" % str(pair[1]["clears_t"].slice(0, 12)))

## Deterministic real-host run of production level 2 to completion. Placement follows the
## level's intendedColumnClicks as soon as a slot is free. `pin` keeps the selected speed
## held for the whole run (the free M23 auto-2x is exercised separately in s6) so the 1x
## and 2x runs stay comparable.
func _truth_run(two: bool, dt: float, pin: bool) -> Dictionary:
	var h = _host_level(2)
	var rt = h.get_runtime()
	rt.set_speed_2x(two)
	var clicks: Array = SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]["intendedColumnClicks"]
	var dispatch: Array = []; var dispatch_t: Array = []
	var clears: Array = []; var clears_t: Array = []
	var clock := [0.0]
	h.get_dispatcher().assignment_dispatched.connect(func(_o, t, c, _a):
		dispatch.append([t, c]); dispatch_t.append([snappedf(clock[0], 0.001), t, c]))
	h.get_clearing_loop().authenticated_clear.connect(func(_o, t, c, _a):
		clears.append([t, c]); clears_t.append([snappedf(clock[0], 0.001), t, c]))
	var slot_hash := []
	var i := 0
	var frames := 0
	while frames < 400000 and not h.get_completion().is_terminal():
		if i < clicks.size() and h.get_slots().rightmost_empty_index() != -1:
			if h.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
				i += 1
				continue
		if pin and rt.is_2x() != two:
			rt.set_speed_2x(two)
		rt.tick(dt)
		clock[0] += dt
		frames += 1
		slot_hash.append(str(h.get_slots().snapshot()).hash())
	var final: Array = []
	var b = h.get_board()
	for k in range(b.get_width() * b.get_height()):
		final.append(b.get_cell_state(k))
	var out := {"won": h.get_completion().is_won(), "state": String(h.get_completion().get_state()), "dispatch": dispatch,
		"clears": clears, "dispatch_t": dispatch_t, "clears_t": clears_t, "slot_hash": slot_hash, "final": final,
		"frames": frames, "seconds": clock[0],
		"residue": [h.get_claim_engine().live_claim_count(), h.get_reservations().get_reservation_count(),
			h.get_dispatcher().get_active_count(), h.get_slots().live_work_count()]}
	h.free()
	return out

# ============================================================== s6 authorities ==
func _s6_authorities() -> void:
	print("[s6 existing 2x authorities on the new baseline]")
	var rows := {}
	var path := _uniq("auth")
	var app = AppState.new(path, func(): return _now[0])
	app.progression.record_win(1)
	var h = _host_app(app)
	var eco = h.get_economy()
	_ok(eco.config.speed_current_level_sb() == 200, "current-level 2x price unchanged (200 SB)")
	var prices := {}
	for p in eco.config.speed_timed_products():
		prices[int(p["seconds"])] = int(p["sb"])
	_ok(prices == {900: 300, 1800: 500, 3600: 750}, "timed 2x durations/prices unchanged %s" % str(prices))
	_ok(_eff(h) == V1_SPEED, "fresh attempt, no entitlement: 9 cells/s")
	# 1) paid current-level 2x via the real acquisition popup.
	eco.wallet.credit(EconomyWallet.SCRUB_BUCKS, 5000)
	h.get_screen().get_speed_button().pressed.emit()
	h.get_speed_acquisition_popup().get_offer_button("level").pressed.emit()
	rows["current_level_2x"] = _eff(h)
	_ok(h.get_speed_authority().is_2x() and rows["current_level_2x"] == V2_SPEED, "paid current-level 2x -> 18 cells/s (%.3f)" % rows["current_level_2x"])
	h.free()
	# 2) timed 2x purchase, then new level / retry / relaunch start at 2x.
	h = _host_app(app)
	h.get_screen().get_speed_button().pressed.emit()   # current-level entitled: toggles
	if h.get_speed_authority().is_2x():
		h.get_screen().get_speed_button().pressed.emit()
	_ok(eco.speed.purchase_timed(900)["ok"], "15m timed 2x bought (300 SB)")
	h.free()
	app.progression.record_win(2)
	h = _host_app(app)
	rows["timed_new_level"] = _eff(h)
	_ok(h.progression_level == 3 and h.get_speed_authority().is_2x() and rows["timed_new_level"] == V2_SPEED, "timed 2x: new level starts at 18 cells/s (%.3f)" % rows["timed_new_level"])
	h.get_screen().get_speed_button().pressed.emit()
	rows["timed_manual_1x"] = _eff(h)
	_ok(not h.get_speed_authority().is_2x() and rows["timed_manual_1x"] == V1_SPEED, "manual 1x during timed entitlement -> 9 cells/s (%.3f)" % rows["timed_manual_1x"])
	_ok(h.retry(), "retry restores a fresh attempt")
	rows["timed_retry"] = _eff(h)
	_ok(h.get_speed_authority().is_2x() and rows["timed_retry"] == V2_SPEED, "retry re-applies timed default 2x -> 18 cells/s (%.3f)" % rows["timed_retry"])
	h.free()
	_ok(app.flush().get("ok", false), "durable save flushed before relaunch")
	var app2 = AppState.new(path, func(): return _now[0])
	var h2 = _host_app(app2)
	rows["timed_relaunch"] = _eff(h2)
	_ok(h2.get_speed_authority().is_2x() and rows["timed_relaunch"] == V2_SPEED, "relaunch auto-starts timed 2x -> 18 cells/s (%.3f)" % rows["timed_relaunch"])
	# 3) expiry mid-level -> 1x (no M23 exhaustion).
	_now[0] += 1000
	h2._refresh_hud()
	rows["timed_expired"] = _eff(h2)
	_ok(not h2.get_speed_authority().is_2x() and rows["timed_expired"] == V1_SPEED, "timed expiry mid-level -> 9 cells/s (%.3f)" % rows["timed_expired"])
	h2.free()
	# 4) expiry while M23 free auto-2x owns 2x -> stays 18.
	_ok(app2.economy.speed.purchase_timed(900)["ok"], "second timed purchase for the M23-overlap case")
	var h3 = _host_app(app2)
	_drain_supply(h3)
	_ok(h3.get_supply().is_exhausted() and h3.get_speed_authority().is_2x(), "supply exhausted under timed 2x")
	_now[0] += 1000
	h3._refresh_hud()
	rows["timed_expired_m23_owns"] = _eff(h3)
	_ok(h3.get_speed_authority().is_2x() and rows["timed_expired_m23_owns"] == V2_SPEED, "timed expiry while M23 auto-2x owns speed -> stays 18 cells/s (%.3f)" % rows["timed_expired_m23_owns"])
	h3.free()
	# 5) M23 supply exhaustion free auto-2x, no entitlement, nothing spent.
	var app3 = AppState.new(_uniq("m23"), func(): return _now[0])
	app3.progression.record_win(1)
	var h4 = _host_app(app3)
	var sb0: int = app3.economy.wallet.scrub_bucks()
	_ok(not app3.economy.speed.is_manual_2x_entitled(2) and not h4.get_speed_authority().is_2x(), "no entitlement, 1x")
	_drain_supply(h4)
	rows["m23_auto_2x"] = _eff(h4)
	_ok(h4.get_speed_authority().is_2x() and rows["m23_auto_2x"] == V2_SPEED and app3.economy.wallet.scrub_bucks() == sb0,
		"M23 supply-exhausted auto-2x -> 18 cells/s, free (%.3f)" % rows["m23_auto_2x"])
	h4.free()
	await process_frame
	_report["authorities_effective_cells_per_s"] = rows

## Effective travel rate (cells / gameplay second) of a live production agent: dispatch if
## none is moving, hold the scheduler, then measure 3 frames of real runtime travel.
func _eff(h) -> float:
	var rt = h.get_runtime()
	var a = _moving_agent(h)
	if a == null:
		for c in [1, 2, 3]:
			if h.get_slots().rightmost_empty_index() != -1:
				h.get_input_controller().activate_front(c - 1)
		var g := 0
		while _moving_agent(h) == null and g < 200:
			rt.tick(DT60); g += 1
		a = _moving_agent(h)
	if a == null:
		return -1.0
	h.get_scheduler().pause()
	var d0 := _dist(a)
	var n := 3
	while n > 0:
		rt.tick(DT60); n -= 1
	var rate := (_dist(a) - d0) / (3.0 * DT60)
	h.get_scheduler().resume()
	return snappedf(rate, 0.001)

func _moving_agent(h):
	var best = null
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent and c.is_moving() and c.get_route_length() * (1.0 - c.get_progress()) > 1.0:
			if best == null or c.get_progress() < best.get_progress():
				best = c
	return best

func _drain_supply(h) -> void:
	var clicks: Array = SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]["intendedColumnClicks"]
	var i := 0
	var g := 0
	while not h.get_supply().is_exhausted() and g < 200000:
		g += 1
		if i < clicks.size() and h.get_slots().rightmost_empty_index() != -1:
			if h.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
				i += 1
				continue
		h.get_runtime().tick(DT60)

# ==================================================================== s7 reset ==
func _s7_reset() -> void:
	print("[s7 reset without timed entitlement -> new 1x]")
	var h = _host_level(2)
	var rt = h.get_runtime()
	rt.set_speed_2x(true)
	_ok(_eff(h) == V2_SPEED, "pre-reset 2x runs at 18 cells/s")
	_ok(h.retry(), "retry (full reset) succeeds")
	var sp = h.get_speed_authority()
	_ok(sp.factor() == 1.0 and sp.cadence_interval() == V1_CADENCE, "reset: factor 1.0, cadence 1/3 s")
	var e := _eff(h)
	_ok(e == V1_SPEED, "reset: fresh agents travel 9 cells/s (%.3f)" % e)
	_report["reset"] = {"factor": sp.factor(), "cadence": sp.cadence_interval(), "cells_per_s": e}
	h.free()

# ======================================================= s8 real-host 59x59 ==
## M25-C003 S0: every s8 host is a REAL laid-out 1080x2160 production host, and every slot
## origin is asserted finite and below the board before measurement (the V01 s8 helper ran
## unlaid hosts whose slot anchors mapped to board-local y = 0 — see M25-C002 findings).
func _s8_real_host() -> void:
	print("[s8 real LAID-OUT host: 32x32 full completion + 59x59 dense window, 5/6 slots, 1x/2x, 30/60 FPS]")
	var full: Array = []
	for slots_n in [5, 6]:
		for two in [false, true]:
			for fps in [60, 30]:
				full.append(await _run_fixture(32, slots_n, two, fps, 0.0, false))
	_report["real_host_32x32_full_completion"] = full
	var dense: Array = []
	for cfg in [[5, false, 60], [5, true, 60], [6, false, 60], [6, true, 60], [6, false, 30], [6, true, 30]]:
		dense.append(await _run_fixture(59, cfg[0], cfg[1], cfg[2], WINDOW_59, false))
	# Same harness at the HISTORICAL tempo (6 cells/s, 0.5 s base) for cost attribution only.
	for two in [false, true]:
		dense.append(await _run_fixture(59, 6, two, 60, WINDOW_59, true))
	_report["real_host_59x59_dense_window"] = dense
	var new2: Dictionary = dense[3]
	var old2: Dictionary = dense[7]
	_ok(new2["route_ms_per_probe"] <= old2["route_ms_per_probe"] * 1.5 + 0.2,
		"59x59: per-route-probe cost unchanged by tempo (new %.3f ms vs historical %.3f ms)" % [new2["route_ms_per_probe"], old2["route_ms_per_probe"]])

## Real ProductionGameplayHost on a w x w 6-colour stripe TEST fixture. window_s == 0 runs to
## terminal (expects WON); otherwise a bounded gameplay window. `legacy` rebinds the host to
## the historical 0.5 s / 6 cells/s tempo for same-harness cost comparison only.
func _run_fixture(w: int, slots_n: int, two: bool, fps: int, window_s: float, legacy: bool) -> Dictionary:
	var tag := "%dx%d %d slots %s %dfps%s" % [w, w, slots_n, "2x" if two else "1x", fps, " HISTORICAL-TEMPO" if legacy else ""]
	var dt := 1.0 / float(fps)
	var lvl := _stripe_level_dict(w, w, 6, "m29c002_%d_%d_%s_%d_%s" % [w, slots_n, "2x" if two else "1x", fps, "old" if legacy else "new"])
	var h = await _host_fixture(lvl, _stripe_plan(lvl), 0.5 if legacy else -1.0)
	if not h.is_built():
		return {"tag": tag, "built": false}
	if legacy:
		h.get_scheduler()._speed = 6.0
	if slots_n == 6:
		h.get_economy().boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
		_ok(h.activate_plus_one_slot() and h.get_slots().active_capacity() == 6, "%s: +1 Slot active (6 lanes)" % tag)
		await _settle(h)
	h.get_runtime().set_process(false)
	h.get_runtime().reset_runtime()   # zero the cadence phase picked up during layout frames
	var origins: Array = []
	var below := true
	for i in range(h.get_slots().active_capacity()):
		var o: Vector2 = h.get_origin_provider().origin_for_slot(i)
		origins.append([snappedf(o.x, 0.01), snappedf(o.y, 0.01)])
		below = below and is_finite(o.x) and is_finite(o.y) and o.y >= float(h.get_board().get_height())
	_ok(below, "%s: every slot origin finite and below the board %s" % [tag, str(origins)])
	RP.enabled = true
	RP.reset()
	var rt = h.get_runtime()
	var sch = h.get_scheduler()
	rt.set_speed_2x(two)
	var per_frame := [0]
	var live_targets := {}
	var dup_dispatch := [0]
	var cleared := {}
	var dup_clear := [0]
	h.get_dispatcher().assignment_dispatched.connect(func(_o, t, _c, _a):
		per_frame[0] += 1
		if live_targets.has(t): dup_dispatch[0] += 1
		live_targets[t] = true)
	h.get_clearing_loop().authenticated_clear.connect(func(_o, t, _c, _a):
		live_targets.erase(t)
		if cleared.has(t): dup_clear[0] += 1
		cleared[t] = true)
	var ev = CompletionEvaluator.new()
	var col := 0
	var frames := 0
	var max_assign_frame := 0
	var max_pending := 0
	var max_accum := 0.0
	var fatal := false
	var card_bad := 0
	var usec: Array = []
	var gameplay := 0.0
	var guard := 0
	var max_frames := int(round(window_s * fps)) if window_s > 0.0 else fps * 900
	while not h.get_completion().is_terminal() and frames < max_frames and guard < 2000000:
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
			rt.set_speed_2x(false)   # hold 1x through M23 exhaustion so 1x stress stays 1x
		per_frame[0] = 0
		var t0 := Time.get_ticks_usec()
		rt.tick(dt)
		usec.append(Time.get_ticks_usec() - t0)
		frames += 1
		gameplay += dt
		max_assign_frame = maxi(max_assign_frame, per_frame[0])
		max_pending = maxi(max_pending, sch.pending_lane_count())
		max_accum = maxf(max_accum, rt._accum)
		if frames % 30 == 0:
			var cards: Array = ev.transaction_cardinalities(sch, h.get_dispatcher(), h.get_claim_engine(), h.get_reservations(), h.get_slots())
			if cards.size() > 0 and cards.min() != cards.max():
				card_bad += 1
			fatal = fatal or ev.has_fatal_inconsistency(sch, h.get_dispatcher(), h.get_claim_engine(), h.get_reservations(), h.get_slots())
	usec.sort()
	var sum := 0
	for u in usec:
		sum += u
	var interval: float = h.get_speed_authority().cadence_interval()
	var probe: Dictionary = RP.snapshot()
	RP.enabled = false
	var route: Dictionary = probe.get("access_compute_route", {"count": 0, "total_ms": 0.0})
	var sel: Dictionary = probe.get("target_selection", {"count": 0, "max_ms": 0.0})
	var out := {"tag": tag, "size": w, "slots": slots_n, "speed": "2x" if two else "1x", "fps": fps, "built": true,
		"historical_tempo": legacy, "window_s": window_s, "laid_out": true, "slot_origins": origins, "origins_below_board": below,
		"lanes_serviced": int(probe.get("m26_dispatch_lane", {}).get("count", 0)), "route_probes": int(route["count"]),
		"route_ms_per_probe": snappedf(float(route["total_ms"]) / maxf(1.0, float(route["count"])), 0.001),
		"target_selection_max_ms": snappedf(float(sel.get("max_ms", 0.0)), 0.01),
		"state": String(h.get_completion().get_state()), "frames": frames, "gameplay_seconds": snappedf(gameplay, 0.001),
		"clears": cleared.size(), "cells": w * w, "max_assignments_per_frame": max_assign_frame,
		"max_pending_lanes": max_pending, "max_accum_s": snappedf(max_accum, 0.0001), "cadence_interval_s": interval,
		"dup_dispatch": dup_dispatch[0], "dup_clear": dup_clear[0], "cardinality_mismatch_samples": card_bad, "fatal": fatal,
		"tick_ms_mean": snappedf(float(sum) / maxf(1.0, float(usec.size())) / 1000.0, 0.001),
		"tick_ms_p99": snappedf(float(usec[int(usec.size() * 0.99)]) / 1000.0, 0.001) if usec.size() > 0 else 0.0,
		"tick_ms_max": snappedf(float(usec[usec.size() - 1]) / 1000.0, 0.001) if usec.size() > 0 else 0.0,
		"residue": [h.get_claim_engine().live_claim_count(), h.get_reservations().get_reservation_count(),
			h.get_dispatcher().get_active_count(), h.get_slots().live_work_count()]}
	print("  %s" % JSON.stringify(out))
	if window_s <= 0.0:
		_ok(h.get_completion().is_won() and cleared.size() == w * w, "%s: WON, every cell cleared exactly once (%d)" % [tag, cleared.size()])
		_ok(out["residue"] == [0, 0, 0, 0], "%s: zero residue at completion" % tag)
	else:
		_ok(not h.get_completion().is_lost() and not h.get_completion().is_error(), "%s: no LOST/ERROR in window (%s)" % [tag, out["state"]])
	_ok(max_assign_frame <= 1, "%s: <= 1 new assignment per frame (%d)" % [tag, max_assign_frame])
	_ok(max_pending <= slots_n, "%s: pending lanes bounded by slot count (%d)" % [tag, max_pending])
	_ok(max_accum <= interval + 1e-9, "%s: cadence backlog <= one interval" % tag)
	_ok(dup_dispatch[0] == 0 and dup_clear[0] == 0, "%s: no duplicate claim/dispatch or clear" % tag)
	_ok(card_bad == 0 and not fatal, "%s: transaction cardinalities consistent, no fatal inconsistency" % tag)
	h.get_meta("sub").free()
	return out

# ================================================================== helpers ====
func _host_level(order: int):
	var app = AppState.new(_uniq("lvl%d" % order), func(): return _now[0])
	for n in range(1, order):
		app.progression.record_win(n)
	return _host_app(app)

func _host_app(app):
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	get_root().add_child(h)
	_ok(h.build(), "host builds level %d %s" % [h.progression_level, h.get_build_error()])
	h.get_runtime().set_process(false)
	return h

func _host_fixture(level_dict: Dictionary, plan: Dictionary, base_cadence: float = -1.0):
	var lp := _write("lvl", JSON.stringify(level_dict))
	plan["levelId"] = level_dict["id"]
	var pp := _write("plan", JSON.stringify(plan))
	var h = ProductionGameplayHost.new()
	if base_cadence > 0.0:
		h.base_cadence = base_cadence
	h.auto_build = false
	h.level_path = lp
	h.supply_plan_path = pp
	# Real production slot geometry (M25-C003 S0): sized viewport, settle, build, relayout.
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
	_ok(h.build(), "laid-out fixture host builds %s" % h.get_build_error())
	await _settle(h)
	h.get_runtime().set_process(false)
	return h

func _settle(h) -> void:
	await process_frame
	await process_frame
	h.get_screen().relayout()
	await process_frame
	await process_frame

## TEST fixture: w x h, `k` vertical stripes of C01..Ck (every stripe touches the edges).
func _stripe_level_dict(w: int, hgt: int, k: int, id: String) -> Dictionary:
	var cells: Array = []
	for y in range(hgt):
		for x in range(w):
			cells.append(x * k / w)
	return {"version": 1, "id": id, "name": id, "difficulty": "TEST", "width": w, "height": hgt,
		"palette": HEX.slice(0, k), "cells": cells}

func _stripe_level_data(w: int, hgt: int, k: int):
	var d := _stripe_level_dict(w, hgt, k, "m29c002_route")
	return LevelData.new(1, d["id"], d["name"], "TEST", w, hgt, PackedStringArray(d["palette"]), PackedInt32Array(d["cells"]))

## Round-robin 30-robot batches per color over three columns; exact per-color totals.
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
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}

func _click(h, cols: Array) -> bool:
	var ok := true
	for c in cols:
		ok = ok and h.get_input_controller().activate_front(int(c) - 1).get("ok", false)
	return ok

func _first_agent(h):
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent:
			return c
	return null

func _assign_count(h) -> int:
	return h.get_scheduler().assignment_snapshot().size()

func _by_slot(h) -> Dictionary:
	var out := {}
	for a in h.get_scheduler().assignment_snapshot():
		out[int(a["slot"])] = int(out.get(int(a["slot"]), 0)) + 1
	return out

func _slot_of_first(h) -> int:
	var snap: Array = h.get_scheduler().assignment_snapshot()
	return int(snap[0]["slot"]) if snap.size() > 0 else -1

func _write(tag: String, text: String) -> String:
	var p := "user://m29c002_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _uniq(tag: String) -> String:
	var p := "user://m29c002_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _write_evidence() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		return
	var dir: String = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	_report["suite"] = "tests/m29_c002_tempo_retune.gd"
	_report["engine"] = Engine.get_version_info()["string"]
	_report["failures"] = _fail
	var f := FileAccess.open(dir.path_join("tempo_report.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_report, "  "))
	f.close()
	var lines: Array = ["M29-C002 tempo measurement report (generated by tests/m29_c002_tempo_retune.gd)", ""]
	var tr: Dictionary = _report.get("travel", {})
	for k in tr:
		lines.append("travel %s: 1x %.4f cells/1s | 2x new agent %.4f | 2x moving agent %.4f | ratio %.5f" % [k,
			tr[k]["cells_1s_1x"], tr[k]["cells_1s_2x_new_agent"], tr[k]["cells_1s_2x_moving_agent"], tr[k]["ratio"]])
	var cd: Dictionary = _report.get("cadence", {})
	for k in cd:
		lines.append("cadence %s: nominal %.6f s, measured mean %.6f s (min %.6f max %.6f), waves %d" % [k, cd[k]["nominal"], cd[k]["mean"], cd[k]["min"], cd[k]["max"], cd[k]["waves"]])
	lines.append("")
	lines.append("wave stress probe (20 s gameplay each):")
	lines.append("fps lanes speed | nominal  service  mean_period  max_lanes/frame overlap max_backlog service_limited")
	for r in _report.get("wave_stress_probe", []):
		lines.append("%3d %5d %5s | %.4f  %.4f   %.4f       %d               %d       %.4f      %s" % [r["fps"], r["lanes"],
			"2x" if r["factor"] == 2.0 else "1x", r["nominal"], r["service_time"], r["mean"], r["max_lanes_per_frame"], r["overlap"], r["max_accum"], r["service_limited"]])
	lines.append("")
	for sec in [["real-host 32x32 full completion (1024 cells, 6-colour stripe TEST fixture):", "real_host_32x32_full_completion"],
			["real LAID-OUT host 59x59 dense window (3481 cells, 6-colour wide-stripe, %.0f s gameplay; origins below board):" % WINDOW_59, "real_host_59x59_dense_window"]]:
		lines.append(sec[0])
		for r in _report.get(sec[1], []):
			lines.append("%s: %s frames=%d gameplay=%.2fs clears=%d lanes=%d max_assign/frame=%d max_pending=%d max_backlog=%.4f dup_dispatch=%d dup_clear=%d route_ms/probe=%.3f sel_max_ms=%.1f tick_ms mean=%.3f p99=%.3f max=%.3f" % [
				r["tag"], r.get("state", "?"), r.get("frames", 0), r.get("gameplay_seconds", 0.0), r.get("clears", 0), r.get("lanes_serviced", 0),
				r.get("max_assignments_per_frame", 0), r.get("max_pending_lanes", 0), r.get("max_accum_s", 0.0), r.get("dup_dispatch", 0), r.get("dup_clear", 0),
				r.get("route_ms_per_probe", 0.0), r.get("target_selection_max_ms", 0.0), r.get("tick_ms_mean", 0.0), r.get("tick_ms_p99", 0.0), r.get("tick_ms_max", 0.0)])
		lines.append("")
	lines.append("")
	lines.append("authorities (effective cells/s): %s" % JSON.stringify(_report.get("authorities_effective_cells_per_s", {})))
	lines.append("reset: %s" % JSON.stringify(_report.get("reset", {})))
	lines.append("truth equivalence: %s" % JSON.stringify(_report.get("truth_equivalence", {})))
	lines.append("")
	lines.append("failures: %d" % _fail)
	f = FileAccess.open(dir.path_join("tempo_report.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	f = FileAccess.open(dir.path_join("real_host_trace_1x_2x.txt"), FileAccess.WRITE)
	f.store_string("\n".join(_trace_lines) + "\n")
	f.close()

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M29-C002 TEMPO RETUNE: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
