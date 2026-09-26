extends SceneTree
## M52-C001-R01 runtime probe (debug/QA only). Runs the REAL production stack
## (AppState -> catalog -> resolver -> ProductionGameplayHost) for Level 2 Apple and
## records evidence for the R01 remediation. Same script is run before and after the
## change so the evidence is directly comparable.
##
##   blue  : place five C08 x30 batches (owner Apple clicks 1,2,3,1,2), run ONE cadence
##           wave, then cadence-by-cadence until the first authenticated clear; records
##           per-slot live assignments and player-visible counts over time.
##   speed : press the shipping 2x control with no entitlement; records speed + any
##           acquisition UI that opened.
##   perf  : natural fast play of Level 2 (click the next owner column whenever a slot is
##           empty) at fixed 60 Hz ticks, 1x or 2x; per-frame wall time + RuntimePerfProbe
##           section attribution of the worst frames.
##
## Usage: godot --headless --path . -s res://tools/r01_runtime_probe.gd -- <mode> <out.json> [2x]

const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const RuntimePerfProbe = preload("res://scripts/debug/runtime_perf_probe.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const DT := 1.0 / 60.0

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var mode: String = args[0]
	var out_path: String = args[1]
	var two := args.size() > 2 and args[2] == "2x"
	var h = _host_at_level_2()
	var ev := {"mode": mode, "git_head": _head(), "context": {"os": OS.get_name(), "cpu": OS.get_processor_name(),
		"cores": OS.get_processor_count(), "godot": Engine.get_version_info()["string"], "headless": true,
		"tick_dt": DT}}
	match mode:
		"blue":
			ev["result"] = _blue(h)
		"speed":
			ev["result"] = await _speed(h)
		"perf":
			ev["result"] = _perf(h, two)
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(ev, "\t") + "\n")
	f.close()
	print("R01_PROBE_DONE ", mode, " -> ", out_path)
	h.free()
	quit(0)

func _head() -> String:
	var o: Array = []
	OS.execute("git", ["rev-parse", "--short", "HEAD"], o)
	return String(o[0]).strip_edges() if o.size() > 0 else ""

func _host_at_level_2():
	var app = AppState.new("user://r01_probe_%d.save" % Time.get_ticks_usec())
	app.progression.record_win(1)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	get_root().add_child(h)
	if not h.build():
		push_error("host build failed: " + h.get_build_error())
	h.get_runtime().set_process(false)
	return h

func _slot_view(h) -> Array:
	var out: Array = []
	for s in h.get_slots().snapshot():
		out.append(null if not s["occupied"] else {"batch": s["batch_id"], "color": s["color_id"],
			"remaining": s["remaining_to_clear"], "committed": s["committed"],
			"displayed": maxi(int(s["remaining_to_clear"]) - int(s["committed"]), 0), "state": s["state"]})
	return out

func _assignments_by_slot(h) -> Dictionary:
	var out := {}
	for a in h.get_scheduler().assignment_snapshot():
		var k := str(int(a["slot"]))
		out[k] = int(out.get(k, 0)) + 1
	return out

func _blue(h) -> Dictionary:
	var input = h.get_input_controller()
	var placed: Array = []
	for c in [1, 2, 3, 1, 2]:
		placed.append(input.activate_front(c - 1).get("ok", false))
	var before := _slot_view(h)
	var runtime = h.get_runtime()
	var interval: float = runtime.get_speed_authority().cadence_interval()
	var timeline: Array = []
	var board = h.get_board()
	var active0: int = board.count_cells_by_state(0)
	# First wave: exactly one cadence event, then (post-R01) the lane frames of that wave.
	for i in range(1, 13):
		var frames := _one_cadence(h, runtime, interval)
		timeline.append({"cadence": i, "wave_frames": frames, "assignments_by_slot": _assignments_by_slot(h),
			"live": h.get_scheduler().live_assignment_count(), "slots": _slot_view(h),
			"cleared_so_far": active0 - board.count_cells_by_state(0)})
	var first_wave: Dictionary = timeline[0].duplicate(true)
	return {"placed_ok": placed, "cadence_interval": interval, "slots_before": before,
		"first_wave": first_wave, "timeline": timeline}

## One cadence event: tick(interval) fires the wave; then 60 Hz frames while the wave
## still has queued lanes (post-R01 lane servicing). Returns frames spent on the wave.
func _one_cadence(h, runtime, interval: float) -> int:
	runtime.tick(interval)
	var frames := 1
	var sch = h.get_scheduler()
	while sch.has_method("has_pending_lanes") and sch.has_pending_lanes() and frames < 12:
		runtime.tick(DT)
		frames += 1
	return frames

func _speed(h) -> Dictionary:
	var screen = h.get_screen()
	var before_2x: bool = h.get_speed_authority().is_2x()
	var sb0: int = h.get_economy().wallet.scrub_bucks() if h.get_economy() != null else -1
	var popups_before := _visible_popups(h)
	screen.get_speed_button().pressed.emit()
	await process_frame
	return {"entitled": h.get_economy().speed.is_manual_2x_entitled(h.progression_level),
		"speed_before_2x": before_2x, "speed_after_2x": h.get_speed_authority().is_2x(),
		"button_text": screen.get_speed_button().text, "sb_before": sb0,
		"sb_after": h.get_economy().wallet.scrub_bucks(), "popups_before": popups_before,
		"popups_after": _visible_popups(h)}

func _visible_popups(h) -> Array:
	var out: Array = []
	for n in get_root().find_children("*", "Control", true, false):
		if n.visible and n.is_visible_in_tree() and (n is PopupPanel or n is AcceptDialog or String(n.name).findn("2x") != -1 or String(n.name).findn("Acquisition") != -1):
			out.append(String(n.name))
	return out

func _perf(h, two: bool) -> Dictionary:
	var runtime = h.get_runtime()
	if two:
		runtime.set_speed_2x(true)
	var plan: Dictionary = SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]
	var clicks: Array = plan["intendedColumnClicks"]
	var input = h.get_input_controller()
	var slots = h.get_slots()
	var next := 0
	var frames: Array = []
	RuntimePerfProbe.reset()
	RuntimePerfProbe.enabled = true
	var max_ticks := 60 * 60 * 20
	var t := 0
	while t < max_ticks and not h.get_completion().is_terminal():
		var t0 := Time.get_ticks_usec()
		if next < clicks.size() and slots.rightmost_empty_index() != -1:
			var r: Dictionary = input.activate_front(int(clicks[next]) - 1)
			if r.get("ok", false):
				next += 1
		runtime.tick(DT)
		var us := Time.get_ticks_usec() - t0
		frames.append({"t": t, "ms": us / 1000.0, "sections": RuntimePerfProbe.take_frame(),
			"live": h.get_scheduler().live_assignment_count(), "agents": _moving(h)})
		t += 1
	RuntimePerfProbe.enabled = false
	var ms: Array = frames.map(func(f): return f["ms"])
	var sorted_ms: Array = ms.duplicate()
	sorted_ms.sort()
	var worst: Array = frames.duplicate()
	worst.sort_custom(func(a, b): return a["ms"] > b["ms"])
	var over: Callable = func(th): return ms.filter(func(x): return x > th).size()
	var peak_live := 0
	var peak_agents := 0
	for f in frames:
		peak_live = maxi(peak_live, int(f["live"]))
		peak_agents = maxi(peak_agents, int(f["agents"]))
	return {"speed": "2x" if two else "1x", "ticks": frames.size(), "sim_seconds": frames.size() * DT,
		"terminal": String(h.get_completion().get_state()), "clicks_applied": next,
		"frame_ms": {"p50": sorted_ms[sorted_ms.size() / 2], "p95": sorted_ms[int(sorted_ms.size() * 0.95)],
			"p99": sorted_ms[int(sorted_ms.size() * 0.99)], "max": sorted_ms[-1],
			"total_s": ms.reduce(func(a, b): return a + b, 0.0) / 1000.0},
		"frames_over_ms": {"16.7": over.call(16.7), "33": over.call(33.0), "50": over.call(50.0), "100": over.call(100.0)},
		"peak_live_assignments": peak_live, "peak_moving_agents": peak_agents,
		"sections": RuntimePerfProbe.snapshot(), "worst_frames": worst.slice(0, 12)}

func _moving(h) -> int:
	var n := 0
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent and c.is_moving():
			n += 1
	return n
