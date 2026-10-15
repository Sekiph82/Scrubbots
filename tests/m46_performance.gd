extends SceneTree
## M46 — Performance baselines at the production board ceiling, 59x59 = 3,481 cells
## (SB-M46-001..014). Deterministic, headless, LOCAL ONLY (owner Actions cost freeze 2026-10-15).
##
## Every number is DESKTOP CPU wall time (script + engine processing; headless = no GPU / draw
## cost) on the machine that runs this suite. Budgets are constants below. Rule of thumb: a
## 60 fps phone frame is 16.7 ms and a low-end phone is assumed up to ~4x slower, so the mean
## frame must stay <= 4 ms here and the frame p99 <= 16.7 ms (the max is reported, not gated:
## one-off spawn / retry hitches are listed separately). This is NOT 60 fps device evidence;
## phone numbers are not measured here (no device run) and stay an open M47 item.
##
##   p01 level parsing            real catalog levels + a 59x59 JSON
##   p02 BoardState               build / per-cell state write / counts / restore at 59x59
##   p03 renderer                 configure (colour + M50 symbol map) / one-cell repaint
##   p04 candidate index + access bind, per-clear sync, targetability of every candidate
##   p05 TargetSelector           select_and_reserve on a dense 16-colour 59x59 board
##   p06 routing                  production railway routes to reachable targets
##   p07 agents                   200 concurrent ScrubbotAgents advanced per frame
##   p08 effects                  cleaning FX stay under their cap during a full 59x59 level
##   p09 memory baseline          a 59x59 production host: build delta, free -> back to baseline
##   p10 59x59 memory             59x59 vs 20x20 host build delta
##   p11 per-frame allocation     no NET Object growth over idle frames or the level (churn: p15)
##   p15 UI idle churn            identical slot rebinds reuse their styleboxes (no per-tick
##                                allocation); the idle board magnifier does not process
##   p12 repeated restart         30 retries mid-level: nodes exact, objects / memory bounded
##   p13 long session             a COMPLETE 59x59 level (3,481 clears) through the real
##                                production host to WON; frame-time distribution
##   p14 high agent density       peak concurrent in-flight agents during p13
##
## Run: godot --headless --path . -s res://tests/m46_performance.gd

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardRenderer = preload("res://scripts/gameplay/board/board_renderer.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ColorSymbols = preload("res://scripts/ui/color_symbols.gd")
const RuntimePerfProbe = preload("res://scripts/debug/runtime_perf_probe.gd")
const BatchSlotView = preload("res://scripts/ui/batch_slot_view.gd")
const BoardMagnifier = preload("res://scripts/ui/board_magnifier.gd")

const N := 59
const DT := 1.0 / 60.0
## --- fixed budgets (desktop ms) ---
const FRAME_STEADY_MS := 4.0       # mean frame / per-frame steady work
const FRAME_SPIKE_MS := 16.7       # any single frame / one-off call
const PARSE_59_MS := 60.0
const BOARD_BUILD_MS := 10.0
const STATE_WRITE_US := 10.0
const RENDER_CONFIGURE_MS := 40.0
const RENDER_UPDATE_MS := 1.0
const INDEX_BIND_MS := 20.0
const INDEX_SYNC_US := 50.0
const SELECT_MEAN_MS := 2.0
const ROUTE_MEAN_MS := 2.0
const AGENTS := 200
const MAX_OBJECT_DRIFT := 64
const MAX_STATIC_MEM_DRIFT := 4 * 1024 * 1024
## Extra static memory a 59x59 host may need over a 20x20 one (board-size cost only). The
## first-run absolute cap (48 MB) was dropped: the host's ~57 MB is board-independent UI art.
const BOARD_SCALING_MEM_MB := 8.0
const RESTARTS := 30
## Over all RESTARTS together: < 1 leaked Object per 3 retries, ~8 KB per retry (a leaked board
## copy or image is ~14 KB, so a per-retry leak of either fails).
const RESTART_OBJECT_DRIFT := 8
const RESTART_STATIC_DRIFT := 256 * 1024
## A whole 59x59 level must finish inside this many simulated frames (bounded run).
const MAX_FRAMES := 60000

var EXPECTED_CASES := ["p01_parse", "p02_board_state", "p03_renderer", "p04_index_access", "p05_selector", "p06_routing",
	"p07_agents", "p08_effects", "p09_memory_baseline", "p10_memory_59", "p11_allocation", "p12_restart",
	"p13_long_session", "p14_agent_density", "p15_ui_idle_churn"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _v3 := PackedStringArray()
var _cids: Array = []
var _summary: Array = []

func _initialize() -> void:
	await process_frame
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_v3.append("#%sFF" % String(c["hex"]).trim_prefix("#").to_upper())
		_cids.append(String(c["id"]))
	# Headless sleeps this long every frame (no drawable window); 0 so frame wall time == work.
	var sleep_usec := OS.low_processor_usage_mode_sleep_usec
	OS.low_processor_usage_mode_sleep_usec = 0
	var t_idle := Time.get_ticks_usec()
	await _frames(60)
	var empty_ms := _ms(t_idle) / 60.0
	_ok(empty_ms < 2.0, "headless idle sleep disabled: empty frame %.3f ms (was %d us sleep)" % [empty_ms, sleep_usec])
	_ok(_mem()["static"] > 0, "static (CPU-side) memory monitor is live in this build")
	# Optional subset for local diagnosis: -- micro | memory | restart | level (ledger then FAILs).
	var only := OS.get_cmdline_user_args()
	var t0 := Time.get_ticks_msec()
	if only.is_empty() or only.has("micro"):
		_p01()
		_p02()
		_p03()
		var dense := _dense_board()
		_p04(dense)
		_p05(dense)
		_p06(dense)
		_p07(dense)
		await _p15()
		print("  [micro cases %d ms]" % (Time.get_ticks_msec() - t0))
	if only.is_empty() or only.has("memory"):
		await _p09_p10()
		print("  [memory cases %d ms]" % (Time.get_ticks_msec() - t0))
	if only.is_empty() or only.has("restart"):
		await _p12()
		print("  [restart case %d ms]" % (Time.get_ticks_msec() - t0))
	if only.is_empty() or only.has("level"):
		await _p13_p14_p08_p11()
		print("  [level case %d ms]" % (Time.get_ticks_msec() - t0))
	print("M46 SUMMARY:")
	for line in _summary:
		print("    " + line)
	OS.low_processor_usage_mode_sleep_usec = sleep_usec
	_cleanup()
	_done()

# ------------------------------------------------------------------- cases ----

func _p01() -> void:
	print("[p01 level parsing]")
	var cat = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/catalog/production_catalog_v1.json"))
	var worst := 0.0
	var ok := true
	for e in cat["entries"]:
		var t0 := Time.get_ticks_usec()
		var r = LevelLoader.load_from_path(String(e["level_path"]))
		worst = maxf(worst, _ms(t0))
		ok = ok and r.is_ok()
	var text := JSON.stringify(_stripe_level_dict())
	var t1 := Time.get_ticks_usec()
	var ok59 := true
	for _i in range(10):
		ok59 = ok59 and LevelLoader.load_from_text(text, "m46_59").is_ok()
	var ms59 := _ms(t1) / 10.0
	_ok(ok and ok59, "%d catalog levels + 59x59 JSON parse and validate" % cat["entries"].size())
	_ok(ms59 <= PARSE_59_MS, "59x59 parse + validate %.2f ms (<= %.0f); worst catalog level %.2f ms" % [ms59, PARSE_59_MS, worst])
	_summary.append("SB-M46-001 parse 59x59 %.2f ms, worst catalog %.2f ms" % [ms59, worst])
	_complete("p01_parse")

func _p02() -> void:
	print("[p02 BoardState]")
	var lvl = _level_from(_stripe_level_dict())
	var t0 := Time.get_ticks_usec()
	var b: BoardState
	for _i in range(10):
		b = BoardState.from_level_data(lvl)
	var build := _ms(t0) / 10.0
	t0 = Time.get_ticks_usec()
	for i in range(N * N):
		b.set_cell_state(i, BoardState.CellState.CLEARED)
	var write_us := float(Time.get_ticks_usec() - t0) / float(N * N)
	t0 = Time.get_ticks_usec()
	var counted := b.count_cells_by_state(BoardState.CellState.CLEARED)
	var copy := b.get_cell_states_copy()
	b.restore_all_active()
	var misc := _ms(t0)
	_ok(counted == N * N and copy.size() == N * N and b.count_cells_by_state(BoardState.CellState.ACTIVE) == N * N, "3,481-cell state round trip exact")
	_ok(build <= BOARD_BUILD_MS and write_us <= STATE_WRITE_US, "build %.2f ms (<= %.0f), state write %.2f us/cell (<= %.0f), count+copy+restore %.2f ms" % [build, BOARD_BUILD_MS, write_us, STATE_WRITE_US, misc])
	_summary.append("SB-M46-002 BoardState build %.2f ms, write %.2f us/cell, count+copy+restore %.2f ms" % [build, write_us, misc])
	_complete("p02_board_state")

func _p03() -> void:
	print("[p03 renderer]")
	var b := _dense_board()
	var r: BoardRenderer = BoardRenderer.new()
	get_root().add_child(r)
	# The M50 glyph atlas is a one-time process cost, pre-warmed at app boot (main.gd); it is
	# measured on its own so it is not hidden inside (or blamed on) the per-level configure.
	var ta := Time.get_ticks_usec()
	ColorSymbols.board_atlas()
	var atlas_ms := _ms(ta)
	var t0 := Time.get_ticks_usec()
	r.configure(b, _v3, Vector2(N * 13, N * 13))
	var first := _ms(t0)
	t0 = Time.get_ticks_usec()
	for _i in range(5):
		r.configure(b, _v3, Vector2(N * 13, N * 13))
	var relayout := _ms(t0) / 5.0
	var reps: Array = []
	for i in range(0, N * N, 17):
		b.set_cell_state(i, BoardState.CellState.CLEARED)
		var t1 := Time.get_ticks_usec()
		r.update_cells([i])
		reps.append(_ms(t1))
	var rs := _stats(reps)
	var worst: float = rs["max"]
	_ok(first <= RENDER_CONFIGURE_MS and relayout <= RENDER_CONFIGURE_MS, "level configure (incl. M50 symbol map) %.2f ms, relayout %.2f ms (<= %.0f)" % [first, relayout, RENDER_CONFIGURE_MS])
	_ok(atlas_ms <= 250.0, "one-time boot glyph atlas build %.1f ms (<= 250, pre-warmed at boot, not per level)" % atlas_ms)
	_ok(rs["p95"] <= RENDER_UPDATE_MS and r.get_child_count() == 0, "one-cell repaint p95 %.3f ms (<= %.1f), max %.3f ms, still ONE TextureRect" % [rs["p95"], RENDER_UPDATE_MS, worst])
	_summary.append("SB-M46-003 renderer configure %.2f ms, relayout %.2f ms, clear repaint worst %.3f ms; boot atlas %.1f ms" % [first, relayout, worst, atlas_ms])
	r.free()
	_complete("p03_renderer")

func _p04(b: BoardState) -> void:
	print("[p04 candidate index + access]")
	var t0 := Time.get_ticks_usec()
	var ci = ColorCandidateIndex.create()
	_ok(ci.bind(b), "index binds the dense 59x59 board")
	var bind_ms := _ms(t0)
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(b)
	var ta = ProductionTargetAccess.new(routing, raccess, b, _origin())
	var t1 := Time.get_ticks_usec()
	var cands := 0
	var reachable := 0
	for cid in ci.get_color_ids():
		for idx in ci.get_candidates(int(cid)):
			cands += 1
			reachable += 1 if ta.is_targetable(int(idx)) else 0
	var access_ms := _ms(t1)
	# Per-clear index sync: clear a cell, sync, restore, sync.
	var t2 := Time.get_ticks_usec()
	var syncs := 0
	for i in range(0, N * N, 7):
		b.set_cell_state(i, BoardState.CellState.CLEARED)
		ci.sync_cell(i)
		b.set_cell_state(i, BoardState.CellState.ACTIVE)
		ci.sync_cell(i)
		syncs += 2
	var sync_us := float(Time.get_ticks_usec() - t2) / float(syncs)
	_ok(bind_ms <= INDEX_BIND_MS and sync_us <= INDEX_SYNC_US, "index bind %.2f ms (<= %.0f), sync %.2f us/cell (<= %.0f)" % [bind_ms, INDEX_BIND_MS, sync_us, INDEX_SYNC_US])
	_ok(cands == N * N and reachable > 0 and reachable < cands, "targetability of all %d candidates: %d reachable, %.1f ms total (%.3f ms each)" % [cands, reachable, access_ms, access_ms / cands])
	_summary.append("SB-M46-004 index bind %.2f ms, sync %.2f us, access %.1f ms for %d candidates (%d reachable)" % [bind_ms, sync_us, access_ms, cands, reachable])
	_complete("p04_index_access")

func _p05(b: BoardState) -> void:
	print("[p05 TargetSelector]")
	var res = ReservationState.new()
	res.bind(b)
	var ci = ColorCandidateIndex.create()
	ci.bind(b)
	var sel = TargetSelector.create()
	sel.bind(b, ci, res)
	var ta = ProductionTargetAccess.new(ProductionRoutingSystem.new(), ProductionAccessQuery.new(b), b, _origin())
	var times: Array = []
	var got := 0
	var owner := 0
	for _round in range(6):
		for cid in ci.get_color_ids():
			var t0 := Time.get_ticks_usec()
			var idx: int = sel.select_and_reserve(int(cid), owner, ta)
			times.append(_ms(t0))
			owner += 1
			got += 1 if idx >= 0 else 0
	var st := _stats(times)
	_ok(got == times.size(), "%d / %d selections reserved a reachable exact target (every colour keeps reachable edge cells)" % [got, times.size()])
	_ok(st["mean"] <= SELECT_MEAN_MS and st["p95"] <= FRAME_SPIKE_MS, "select_and_reserve mean %.3f ms (<= %.1f), p95 %.3f ms (<= %.1f), max %.3f ms" % [st["mean"], SELECT_MEAN_MS, st["p95"], FRAME_SPIKE_MS, st["max"]])
	_summary.append("SB-M46-005 TargetSelector mean %.3f / p95 %.3f / max %.3f ms over %d calls" % [st["mean"], st["p95"], st["max"], times.size()])
	_complete("p05_selector")

func _p06(b: BoardState) -> void:
	print("[p06 routing]")
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(b)
	var ta = ProductionTargetAccess.new(routing, raccess, b, _origin())
	var ci = ColorCandidateIndex.create()
	ci.bind(b)
	var targets: Array = []
	for cid in ci.get_color_ids():
		for idx in ci.get_candidates(int(cid)):
			if ta.is_targetable(int(idx)):
				targets.append(int(idx))
	var times: Array = []
	var ok := 0
	for idx in targets:
		var req = RouteRequest.for_target(b, _origin(), idx)
		var t0 := Time.get_ticks_usec()
		var rr = routing.compute_route(req, b, raccess)
		times.append(_ms(t0))
		ok += 1 if rr.success else 0
	var st := _stats(times)
	_ok(ok == targets.size() and targets.size() > 0, "%d / %d routes to targetable cells succeed" % [ok, targets.size()])
	_ok(st["mean"] <= ROUTE_MEAN_MS and st["p95"] <= FRAME_SPIKE_MS, "compute_route mean %.3f ms (<= %.1f), p95 %.3f ms (<= %.1f), max %.3f ms" % [st["mean"], ROUTE_MEAN_MS, st["p95"], FRAME_SPIKE_MS, st["max"]])
	_summary.append("SB-M46-006 routing mean %.3f / p95 %.3f / max %.3f ms over %d routes" % [st["mean"], st["p95"], st["max"], times.size()])
	_complete("p06_routing")

func _p07(b: BoardState) -> void:
	print("[p07 agents]")
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(b)
	var ta = ProductionTargetAccess.new(routing, raccess, b, _origin())
	var ci = ColorCandidateIndex.create()
	ci.bind(b)
	var targets: Array = []
	for cid in ci.get_color_ids():
		for idx in ci.get_candidates(int(cid)):
			if ta.is_targetable(int(idx)):
				targets.append([int(idx), int(cid)])
	var layer := Node2D.new()
	get_root().add_child(layer)
	var agents: Array = []
	for i in range(AGENTS):
		var t: Array = targets[i % targets.size()]
		var req = RouteRequest.for_target(b, _origin(), t[0])
		var rr = routing.compute_route(req, b, raccess)
		var a: ScrubbotAgent = ScrubbotAgent.new()
		layer.add_child(a)
		a.set_process(false)
		if a.assign(i, t[1], req, rr):
			agents.append(a)
	var times: Array = []
	for _f in range(120):
		var t0 := Time.get_ticks_usec()
		for a in agents:
			if a.is_moving():
				a.advance(DT)
		times.append(_ms(t0))
	var st := _stats(times)
	_ok(agents.size() == AGENTS, "%d agents assigned real production routes" % agents.size())
	_ok(st["mean"] <= FRAME_STEADY_MS and st["max"] <= FRAME_SPIKE_MS, "%d agents advanced per frame: mean %.3f ms (<= %.1f), max %.3f ms" % [AGENTS, st["mean"], FRAME_STEADY_MS, st["max"]])
	_summary.append("SB-M46-007 %d agents advance mean %.3f / max %.3f ms per frame" % [AGENTS, st["mean"], st["max"]])
	layer.free()
	_complete("p07_agents")

func _p15() -> void:
	print("[p15 UI idle churn]")
	var sub := SubViewport.new()
	sub.size = Vector2i(400, 400)
	sub.disable_3d = true
	get_root().add_child(sub)
	var view = BatchSlotView.new()
	view.size = Vector2(120, 140)
	sub.add_child(view)
	await _frames(1)
	var snap := {"state": "ACTIVE", "occupied": true, "remaining_to_clear": 9, "committed": 2, "color_id": 0}
	var col := Color.html(_v3[0])
	view.bind_snapshot(snap, col)
	var sb0 = view.get_theme_stylebox("panel")
	for _i in range(100):
		view.bind_snapshot(snap.duplicate(true), col)
	var same: bool = view.get_theme_stylebox("panel") == sb0
	var changed := snap.duplicate(true)
	changed["committed"] = 3
	view.bind_snapshot(changed, col)
	var rebuilt: bool = view.get_theme_stylebox("panel") != sb0 and view.get_display_count() == 6
	_ok(same, "100 identical slot rebinds (the per-tick runtime sync) reuse the same housing stylebox: no per-tick allocation")
	_ok(rebuilt, "a changed snapshot still refreshes the slot (count 9-3 = %d)" % view.get_display_count())
	var b := _dense_board()
	var r: BoardRenderer = BoardRenderer.new()
	sub.add_child(r)
	r.configure(b, _v3, Vector2(N * 4, N * 4))
	var mag = BoardMagnifier.new()
	sub.add_child(mag)
	mag.bind(r)
	await _frames(3)
	var idle_off: bool = not mag.is_processing()
	mag.inspect_at(r.get_global_transform() * Vector2(20, 20))
	var on: bool = mag.is_processing() and mag.is_inspecting()
	mag.end_inspect()
	_ok(idle_off and on and not mag.is_processing(), "board magnifier: idle -> not processing; inspecting -> processing; released -> idle again")
	sub.free()
	_summary.append("SB-M46-011 UI churn: identical slot rebinds allocate nothing (stylebox reused); idle magnifier never processes")
	_complete("p15_ui_idle_churn")

func _p09_p10() -> void:
	print("[p09 / p10 memory]")
	await _frames(3)
	var base := _mem()
	var h20 = await _host(_stripe_level_dict(20), "m20")
	var m20 := _mem()
	_free_host(h20)
	await _frames(3)
	var after20 := _mem()
	var h59 = await _host(_stripe_level_dict(), "m59")
	var m59 := _mem()
	var nodes59: int = h59.find_children("*", "", true, false).size()
	_free_host(h59)
	await _frames(3)
	var after59 := _mem()
	# Warm 20x20 again (first-use caches already paid) for a like-for-like board-size comparison.
	var h20b = await _host(_stripe_level_dict(20), "m20b")
	var m20b := _mem()
	_free_host(h20b)
	await _frames(3)
	var d20: float = (m20["static"] - base["static"]) / 1048576.0
	var d59: float = (m59["static"] - after20["static"]) / 1048576.0
	var d20w: float = (m20b["static"] - after59["static"]) / 1048576.0
	print("    static MB: base %.1f, +20x20 host cold %.2f, +59x59 host %.2f, +20x20 host warm %.2f; objects +%d / +%d; 59x59 host nodes %d" % [
		base["static"] / 1048576.0, d20, d59, d20w, m20["objects"] - base["objects"], m59["objects"] - after20["objects"], nodes59])
	# Board size must not drive memory: 3,481 vs 400 cells is only a few small per-cell arrays and
	# two <= 59x59 textures. The absolute host figure (shell / UI textures, board-independent)
	# has no owner/device budget yet; it is reported, not gated.
	_ok(d59 - d20w <= BOARD_SCALING_MEM_MB, "59x59 vs warm 20x20 host: %+.2f MB (<= %.0f MB board-size cost); absolute 59x59 host %.2f MB reported" % [d59 - d20w, BOARD_SCALING_MEM_MB, d59])
	_ok(absi(after59["objects"] - after20["objects"]) <= MAX_OBJECT_DRIFT and after59["static"] - after20["static"] <= MAX_STATIC_MEM_DRIFT,
		"freeing the 59x59 host returns to baseline: objects %+d, static %+d B" % [after59["objects"] - after20["objects"], after59["static"] - after20["static"]])
	_ok(nodes59 < 400, "59x59 host is %d nodes total (no per-cell nodes; 3,481 cells)" % nodes59)
	_summary.append("SB-M46-009 memory: 20x20 host +%.2f MB, objects +%d; free -> objects %+d" % [d20, m20["objects"] - base["objects"], after20["objects"] - base["objects"]])
	_summary.append("SB-M46-010 59x59 host +%.2f MB static (warm 20x20 +%.2f MB -> board-size cost %+.2f MB), %d nodes, free -> objects %+d, static %+d B" % [d59, d20w, d59 - d20w, nodes59, after59["objects"] - after20["objects"], after59["static"] - after20["static"]])
	_complete("p09_memory_baseline")
	_complete("p10_memory_59")

func _p12() -> void:
	print("[p12 repeated restart]")
	var h = await _host(_stripe_level_dict(), "restart")
	h.get_runtime().set_speed_2x(true)
	# Warm-up attempt: play a little, retry once (first-use caches).
	await _play(h, 240)
	h.retry()
	await _play(h, 240)
	h.retry()
	await _frames(3)
	var n0: int = h.find_children("*", "", true, false).size()
	var m0 := _mem()
	var worst := 0.0
	for _i in range(RESTARTS):
		await _play(h, 120)
		var t0 := Time.get_ticks_usec()
		h.retry()
		worst = maxf(worst, _ms(t0))
	await _frames(3)
	var n1: int = h.find_children("*", "", true, false).size()
	var m1 := _mem()
	var b = h.get_board()
	_ok(b.count_cells_by_state(BoardState.CellState.ACTIVE) == N * N and h.get_dispatcher().get_active_count() == 0, "after %d mid-level retries: full board ACTIVE, zero agents in flight" % RESTARTS)
	_ok(n1 == n0, "host node count exact across %d retries (%d -> %d)" % [RESTARTS, n0, n1])
	_ok(m1["objects"] - m0["objects"] <= RESTART_OBJECT_DRIFT and m1["static"] - m0["static"] <= RESTART_STATIC_DRIFT,
		"objects %+d (<= %d over %d retries), static %+d B (<= %d)" % [m1["objects"] - m0["objects"], RESTART_OBJECT_DRIFT, RESTARTS, m1["static"] - m0["static"], RESTART_STATIC_DRIFT])
	_ok(worst <= FRAME_SPIKE_MS * 3.0, "retry() on 59x59 worst %.2f ms (one-off, <= %.1f)" % [worst, FRAME_SPIKE_MS * 3.0])
	_summary.append("SB-M46-012 %d retries: nodes %d -> %d, objects %+d, static %+d B, retry worst %.2f ms" % [RESTARTS, n0, n1, m1["objects"] - m0["objects"], m1["static"] - m0["static"], worst])
	_free_host(h)
	_complete("p12_restart")

func _p13_p14_p08_p11() -> void:
	print("[p13 / p14 / p08 / p11 full 59x59 level through the production host]")
	var h = await _host(_stripe_level_dict(), "full")
	var rt = h.get_runtime()
	rt.set_speed_2x(true)
	var fx = h.get_cleaning_fx()
	await _frames(3)
	# p11 idle: frames with nothing happening must not allocate Objects.
	var o0: int = _mem()["objects"]
	for _i in range(120):
		rt.tick(DT)
		await process_frame
	var idle_growth: int = _mem()["objects"] - o0
	var base := _mem()
	var times: Array = []
	var ticks: Array = []
	var peak_agents := 0
	var peak_fx := 0
	var frames := 0
	var comp = h.get_completion()
	var cap_frames := 3000 if OS.get_cmdline_user_args().has("quick") else MAX_FRAMES
	RuntimePerfProbe.reset()
	RuntimePerfProbe.enabled = true
	while frames < cap_frames and not comp.is_terminal():
		var t0 := Time.get_ticks_usec()
		_feed(h)
		rt.tick(DT)
		ticks.append(_ms(t0))
		await process_frame
		# Whole-frame wall time: tick + every node's processing + engine overhead. Headless
		# Godot normally sleeps low_processor_usage_mode_sleep_usec per iteration (no window can
		# draw); _initialize sets it to 0, so this is real CPU work (no rendering in headless).
		times.append(_ms(t0))
		frames += 1
		if frames % 3000 == 0:
			print("    ... frame %d, cleared %d" % [frames, h.get_board().count_cells_by_state(BoardState.CellState.CLEARED)])
		peak_agents = maxi(peak_agents, h.get_dispatcher().get_active_count())
		if fx != null:
			peak_fx = maxi(peak_fx, fx.get_active_count())
	RuntimePerfProbe.enabled = false
	var probe := RuntimePerfProbe.snapshot()
	for k in probe:
		print("    probe %s: %s" % [k, str(probe[k])])
	var tk := _stats(ticks)
	print("    gameplay tick (feed + runtime.tick) mean %.3f / p99 %.3f / max %.3f ms" % [tk["mean"], tk["p99"], tk["max"]])
	# Cleaning cues age on real frame time; wait (bounded) until the last one expires.
	var deadline := Time.get_ticks_msec() + 5000
	while fx != null and fx.get_active_count() > 0 and Time.get_ticks_msec() < deadline:
		await create_timer(0.05).timeout
	await _frames(3)
	var end := _mem()
	var st := _stats(times)
	var cleared: int = h.get_board().count_cells_by_state(BoardState.CellState.CLEARED)
	print("    %d frames (%.1f s simulated at 2x), frame ms mean %.3f / p95 %.3f / p99 %.3f / max %.3f; peak agents %d, peak fx %d" % [
		frames, frames * DT, st["mean"], st["p95"], st["p99"], st["max"], peak_agents, peak_fx])
	_ok(comp.is_won() and cleared == N * N, "COMPLETE 59x59 level WON: %d / %d cells cleared through the real host in %d frames" % [cleared, N * N, frames])
	_ok(st["mean"] <= FRAME_STEADY_MS, "whole-level frame mean %.3f ms (<= %.1f)" % [st["mean"], FRAME_STEADY_MS])
	_ok(st["p99"] <= FRAME_SPIKE_MS, "frame p99 %.3f ms (<= %.1f); max %.3f ms" % [st["p99"], FRAME_SPIKE_MS, st["max"]])
	_summary.append("SB-M46-013 full 59x59 level: %d frames, mean %.3f / p95 %.3f / p99 %.3f / max %.3f ms" % [frames, st["mean"], st["p95"], st["p99"], st["max"]])
	_complete("p13_long_session")
	# Expected ~20+ at 2x (1/6 s cadence x 5 lanes, ~3.5 s rail trips); 15 is a real density floor.
	_ok(peak_agents >= 15, "high density: %d agents in flight at peak (>= 15; 5 lanes, 2x)" % peak_agents)
	_summary.append("SB-M46-014 peak concurrent agents %d during the 59x59 level (frame budget above holds)" % peak_agents)
	_complete("p14_agent_density")
	var cap: int = fx._effective_cap() if fx != null else -1
	_ok(fx != null and peak_fx > 0 and (cap < 0 or peak_fx <= cap) and fx.get_active_count() == 0, "cleaning FX: peak %d active (cap %s), 0 after the level" % [peak_fx, str(cap)])
	_summary.append("SB-M46-008 effects peak %d active cues (cap %s) over 3,481 clears, 0 at end" % [peak_fx, str(cap)])
	_complete("p08_effects")
	_ok(idle_growth <= 0, "120 idle frames: Object count %+d (no growth)" % idle_growth)
	# One-sided: consumed supply batches are freed during the level, so the count may fall.
	_ok(h.get_dispatcher().get_active_count() == 0 and end["objects"] - base["objects"] <= MAX_OBJECT_DRIFT,
		"after 3,481 clears: 0 agents left, objects %+d vs level start (no growth beyond %d)" % [end["objects"] - base["objects"], MAX_OBJECT_DRIFT])
	_summary.append("SB-M46-011 idle frames +%d objects; level end vs start objects %+d, static %+d B" % [idle_growth, end["objects"] - base["objects"], end["static"] - base["static"]])
	_complete("p11_allocation")
	_free_host(h)

# ------------------------------------------------------------------ fixtures ----

## Vertical stripes of 8 canonical colours, every stripe touching the bottom row, so every
## colour always has a reachable cell (a level that can always progress).
func _stripe_level_dict(n: int = N) -> Dictionary:
	var pick := [0, 1, 2, 3, 6, 7, 9, 10]   # C01 C02 C03 C04 C07 C08 C10 C11
	var pal: Array = []
	for p in pick:
		pal.append(_v3[p])
	var cells: Array = []
	for y in range(n):
		for x in range(n):
			cells.append(mini(x * pick.size() / n, pick.size() - 1))
	return {"version": 1, "id": "m46_stripes_%d" % n, "name": "M46 Stripes", "difficulty": "TEST", "width": n, "height": n, "palette": pal, "cells": cells}

func _plan_for(level: Dictionary) -> Dictionary:
	var counts := {}
	for c in level["cells"]:
		counts[int(c)] = int(counts.get(int(c), 0)) + 1
	var pick := [0, 1, 2, 3, 6, 7, 9, 10]
	var cols: Array = [[], [], [], [], []]
	var n := 0
	for local in counts:
		var left: int = counts[local]
		while left > 0:
			var k := mini(30, left)
			cols[n % 5].append({"batchId": "M46B%04d" % n, "cid": _cids[pick[local]], "robots": k})
			left -= k
			n += 1
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": level["id"], "columnCount": 5, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}

## Dense 16-colour 59x59 board: most candidates are enclosed (worst case for selection).
func _dense_board() -> BoardState:
	var cells := PackedInt32Array()
	cells.resize(N * N)
	for y in range(N):
		for x in range(N):
			cells[y * N + x] = (x / 2 + y * 3) % 16
	return BoardState.from_level_data(LevelData.new(1, "m46_dense", "m46_dense", "TEST", N, N, _v3, cells))

func _level_from(d: Dictionary):
	return LevelLoader.load_from_text(JSON.stringify(d), "m46").level_data

func _origin() -> Vector2:
	return Vector2(float(N) * 0.5, float(N) + 4.0)

func _host(level: Dictionary, tag: String):
	var lp := _write("lvl_" + tag, JSON.stringify(level))
	var pp := _write("plan_" + tag, JSON.stringify(_plan_for(level)))
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = lp
	h.supply_plan_path = pp
	# A real portrait layout: slot origins come from the laid-out slot geometry, BELOW the
	# board (an unsized root puts them inside the board, where the debug interior planner and
	# no reachability prefilter apply — not a production situation).
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)
	_ok(h.build(), "host builds %s %s" % [level["id"], h.get_build_error()])
	h.get_runtime().set_process(false)
	await _frames(2)
	var o: Vector2 = h.get_origin_provider().origin_for_slot(0)
	_ok(o.y > float(level["height"]), "slot origin %s is below the %dx%d board (production layout)" % [str(o), level["width"], level["height"]])
	return h

func _free_host(h) -> void:
	if h != null and is_instance_valid(h):
		var sub = h.get_parent()
		sub.remove_child(h)
		h.free()
		sub.free()

## Keep every empty slot fed from the first non-exhausted Supply column (player taps).
func _feed(h) -> void:
	var empty := 0
	for s in h.get_slots().snapshot():
		if not s["occupied"]:
			empty += 1
	if empty == 0:
		return
	var ic = h.get_input_controller()
	for c in range(5):
		if empty == 0:
			break
		if ic.activate_front(c).get("ok", false):
			empty -= 1

func _play(h, frames: int) -> void:
	for _i in range(frames):
		_feed(h)
		h.get_runtime().tick(DT)
		await process_frame

# ------------------------------------------------------------------- helpers ----

func _mem() -> Dictionary:
	return {"static": int(Performance.get_monitor(Performance.MEMORY_STATIC)), "objects": int(Performance.get_monitor(Performance.OBJECT_COUNT))}

func _ms(t0: int) -> float:
	return float(Time.get_ticks_usec() - t0) / 1000.0

func _stats(a: Array) -> Dictionary:
	var s := a.duplicate()
	s.sort()
	var total := 0.0
	for v in s:
		total += float(v)
	var n := maxi(s.size(), 1)
	return {"mean": total / n, "p95": float(s[mini(int(n * 0.95), n - 1)]) if not s.is_empty() else 0.0,
		"p99": float(s[mini(int(n * 0.99), n - 1)]) if not s.is_empty() else 0.0, "max": float(s.back()) if not s.is_empty() else 0.0}

func _write(tag: String, text: String) -> String:
	# Fixed name per tag: a crashed run's leftovers are overwritten by the next run.
	var p := "user://m46_%s.json" % tag
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M46 performance evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
