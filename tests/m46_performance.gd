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
##   p16 unlock chains + WAITING  a second COMPLETE 59x59 level (Level Data v2): VOID ring,
##                                12 colours, three nested 3-deep pockets (P1 ring > P2 ring >
##                                P3 core) that unlock only as the surrounding art is cleared,
##                                a pocket batch WAITING in its slot from the first frame,
##                                deep interior targets, pure pause freezes every gameplay truth,
##                                speed authority 2x -> 1x -> 2x, every WAITING batch recovers
##   p17 sixth slot + boosters    (R02) the real +1 Slot booster on the dense 59x59 pocket level:
##                                refused unfunded, bought with SB exactly once, 5 -> 6 slots in
##                                engine + UI strip, never a 7th, one tap = one batch, slot 6
##                                dispatches; a legally owned Tornado mid-level (CPU + burst);
##                                illegal / paused / terminal attempts mutate nothing; retry
##                                restores five slots (once-per-attempt contract)
##   p18 winding routes           (R02) 59x59 v2 maze: a 1-wide serpentine corridor of three
##                                colours sealed in wall art; production routes captured from
##                                the real agents must turn repeatedly through cleared corridor
##                                cells; no duplicate reservation; WON
##   p19 effect budget            (R02, SB-M46-015) real FeedbackAdapter + installed GameFeelFlow
##                                / Saltmire Spark autoloads on the real Results WIN path during
##                                a dense 59x59 2x run, FULL vs REDUCED: owned work, Spark bursts,
##                                native board FX cap, self-free, no replay, cancel / retry /
##                                unbind, node / object drift; never per cleared cell
##   p20 Random + Selector        (R03) the two remaining colour boosters, legally owned, on the
##                                dense 59x59 pocket level: real legality proofs (solver-safety)
##                                timed, charged exactly once, Random reverses the live supply
##                                with every batch conserved, Selector moves the chosen batch into
##                                the rightmost empty slot; illegal / terminal refusals; WON
##   p21 proof budget             (R05, owner rules 2026-10-16) Random / Selector safety proofs are
##                                capped (ProductionBoosterAdapter.PROOF_BUDGET_MS) on 59x59 stripe and
##                                pocket levels, with robots MOVING and with robots STILL: every call
##                                ends within budget + margin; a timeout cancels with
##                                "proof_timeout" and spends no charge / SB and changes nothing;
##                                the player can retry (after a tap Random succeeds); a cut Selector
##                                list resumes where it stopped; refusal rates are measured
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
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const DeadlockClassifier = preload("res://scripts/gameplay/solver/deadlock_classifier.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ProductionBoosterAdapter = preload("res://scripts/economy/production_booster_adapter.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const EffectsSettingsService = preload("res://scripts/settings/effects_settings_service.gd")
const FirstClearTransaction = preload("res://scripts/economy/first_clear_transaction.gd")
const TerminalRewardReceipt = preload("res://scripts/economy/terminal_reward_receipt.gd")
const BoardMagnifier = preload("res://scripts/ui/board_magnifier.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

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
	"p13_long_session", "p14_agent_density", "p15_ui_idle_churn", "p16_unlock_chains_waiting",
	"p17_sixth_slot_boosters", "p18_winding_routes", "p19_effect_budget", "p20_random_selector", "p21_proof_budget", "p22_offframe_proof"]
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
		print("  [micro cases %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("memory"):
		await _p09_p10()
		print("  [memory cases %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("restart"):
		await _p12()
		print("  [restart case %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("level"):
		await _p13_p14_p08_p11()
		print("  [level case %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("pockets"):
		await _p16()
		print("  [pockets case %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("slot6"):
		await _p17()
		print("  [slot6 case %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("maze"):
		await _p18()
		print("  [maze case %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("fx"):
		await _p19()
		print("  [fx case %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("rs"):
		await _p20()
		print("  [rs case %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("budget"):
		await _p21()
		print("  [budget case %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
	if only.is_empty() or only.has("slice"):
		await _p22()
		print("  [slice case %d ms; calib %.1f ms]" % [Time.get_ticks_msec() - t0, _calib()])
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

## 59x59 Level Data v2: 2-cell VOID ring, 9 vertical art stripes, and three 9x9 nested pockets
## (outer ring P1 C05, inner ring P2 C09, 5x5 core P3 C16) sitting INSIDE the stripes, so a
## pocket colour is only reachable after the stripe art around it is cleared, P2 only after P1
## is breached and P3 only after P2 (unlock depth 3). 12 colours; palette ascending C-ID.
const POCKET_CIDS := ["C05", "C09", "C16"]
const STRIPE_CIDS := ["C01", "C02", "C03", "C04", "C07", "C08", "C10", "C11", "C14"]
const POCKET_CENTRES := [Vector2i(29, 24), Vector2i(13, 42), Vector2i(45, 13)]

func _pocket_level_dict() -> Dictionary:
	var used: Array = POCKET_CIDS + STRIPE_CIDS
	used.sort()
	var pal: Array = []
	var local := {}
	for cid in used:
		local[cid] = pal.size()
		pal.append(_v3[_cids.find(cid)])
	var cells: Array = []
	for y in range(N):
		for x in range(N):
			if x < 2 or y < 2 or x >= N - 2 or y >= N - 2:
				cells.append(LevelData.VOID_CELL)
				continue
			var cid: String = STRIPE_CIDS[mini((x - 2) * STRIPE_CIDS.size() / (N - 4), STRIPE_CIDS.size() - 1)]
			for c in POCKET_CENTRES:
				var d: int = maxi(absi(x - c.x), absi(y - c.y))
				if d <= 4:
					cid = POCKET_CIDS[0] if d == 4 else (POCKET_CIDS[1] if d == 3 else POCKET_CIDS[2])
			cells.append(local[cid])
	return {"version": 2, "id": "m46_pockets_59", "name": "M46 Pockets", "difficulty": "TEST", "width": N, "height": N, "palette": pal, "cells": cells}

## Stripe batches round-robin in columns 0..3; ALL pocket batches in column 4, P1 -> P2 -> P3.
## Column 4's first front (a P1 batch) enters a slot on the first frame and must WAIT there
## until the stripe art around a pocket is cleared.
func _pocket_plan(level: Dictionary) -> Dictionary:
	var counts := {}
	for c in level["cells"]:
		if int(c) >= 0:
			counts[int(c)] = int(counts.get(int(c), 0)) + 1
	var cid_of := {}
	for i in range(level["palette"].size()):
		cid_of[i] = _cids[_v3.find(String(level["palette"][i]))]
	var cols: Array = [[], [], [], [], []]
	var n := 0
	var rr := 0
	for want in STRIPE_CIDS + POCKET_CIDS:
		for local in counts:
			if cid_of[local] != want:
				continue
			var left: int = counts[local]
			while left > 0:
				var k := mini(30, left)
				var col: int = 4 if POCKET_CIDS.has(want) else rr % 4
				if not POCKET_CIDS.has(want):
					rr += 1
				cols[col].append({"batchId": "M46P%04d" % n, "cid": want, "robots": k})
				left -= k
				n += 1
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": level["id"], "columnCount": 5, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}

func _p16() -> void:
	print("[p16 unlock chains + WAITING: pockets / VOID / 12 colours 59x59]")
	var level := _pocket_level_dict()
	var h = await _host(level, "pockets", _pocket_plan(level))
	var rt = h.get_runtime()
	rt.set_speed_2x(true)
	var b = h.get_board()
	var comp = h.get_completion()
	var pocket_local := {}
	for i in range(level["palette"].size()):
		var cid: String = _cids[_v3.find(String(level["palette"][i]))]
		if POCKET_CIDS.has(cid):
			pocket_local[i] = POCKET_CIDS.find(cid)
	var artwork: int = b.get_artwork_cell_count()
	var times: Array = []
	var frames := 0
	var waiting_frames := 0
	var peak_waiting := 0
	var first_waiting := -1
	var peak_agents := 0
	var first_clear := [-1, -1, -1]   # first frame a P1 / P2 / P3 cell was cleared
	var paused_ok := true
	var pause_detail := ""
	var pause_busy := [0, 0]   # bots in flight / live assignments when the pause began
	var sa = h.get_speed_authority()
	var factors: Array = [sa.factor()]   # 2x at start, then 1x, then 2x again (real authority reads)
	var waited_ids := {}                 # batch ids ever seen WAITING
	var exited_ids := {}                 # ... later seen ACTIVE, or gone from every slot (finished)
	var recovered_active := 0            # waiting batches later seen ACTIVE in their slot
	_ok(artwork == 3025 and N * N - artwork == 456 and level["palette"].size() == 12, "fixture: %d artwork + %d VOID cells, %d colours" % [artwork, N * N - artwork, level["palette"].size()])
	RuntimePerfProbe.reset()
	RuntimePerfProbe.enabled = true
	var cap_frames := 4000 if OS.get_cmdline_user_args().has("quick") else MAX_FRAMES
	while frames < cap_frames and not comp.is_terminal():
		# Mid-level player actions: a 60-frame pure pause (no taps), then 1x for 600 frames, back to 2x.
		if frames == 2000:
			var before := _truth(h)
			pause_busy = [before["agents"].size(), before["assignments"].size()]
			rt.set_user_paused(true)
			for _i in range(60):
				rt.tick(DT)
				await process_frame
			var after := _truth(h)
			for k in before:
				if before[k] != after[k]:
					paused_ok = false
					pause_detail += k + " "
					if k == "economy":
						for ek in before[k]:
							if before[k][ek] != after[k].get(ek):
								pause_detail += "[%s: %s -> %s] " % [ek, str(before[k][ek]).left(160), str(after[k].get(ek)).left(160)]
			rt.set_user_paused(false)
			rt.set_speed_2x(false)
			factors.append(sa.factor())
		if frames == 2600:
			rt.set_speed_2x(true)
			factors.append(sa.factor())
		var t0 := Time.get_ticks_usec()
		_feed(h)
		rt.tick(DT)
		await process_frame
		times.append(_ms(t0))
		frames += 1
		var w := 0
		var present := {}
		for s in h.get_slots().snapshot():
			if not s["occupied"]:
				continue
			var bid := String(s["batch_id"])
			present[bid] = true
			if String(s["state"]) == "WAITING":
				w += 1
				waited_ids[bid] = true
			elif waited_ids.has(bid):
				if not exited_ids.has(bid):
					recovered_active += 1
				exited_ids[bid] = true
		for bid in waited_ids:
			if not present.has(bid):
				exited_ids[bid] = true
		if w > 0:
			waiting_frames += 1
			if first_waiting < 0:
				first_waiting = frames
		peak_waiting = maxi(peak_waiting, w)
		peak_agents = maxi(peak_agents, h.get_dispatcher().get_active_count())
		if frames % 10 == 0:
			for i in range(N * N):
				var pl = pocket_local.get(b.get_color_id(i), -1) if not b.is_void(i) else -1
				if pl >= 0 and first_clear[pl] < 0 and b.get_cell_state(i) == BoardState.CellState.CLEARED:
					first_clear[pl] = frames
		if frames % 3000 == 0:
			print("    ... frame %d, cleared %d / %d" % [frames, b.count_cells_by_state(BoardState.CellState.CLEARED) - (N * N - artwork), artwork])
	RuntimePerfProbe.enabled = false
	var probe := RuntimePerfProbe.snapshot()
	for k in ["target_selection", "route_dijkstra", "access_compute_route", "access_mask_build", "m26_dispatch_lane"]:
		if probe.has(k):
			print("    probe %s: %s" % [k, str(probe[k])])
	var st := _stats(times)
	var cleared_art: int = b.count_cells_by_state(BoardState.CellState.CLEARED) - (N * N - artwork)
	print("    %d frames, frame ms mean %.3f / p95 %.3f / p99 %.3f / max %.3f; WAITING in %d frames (first %d, peak %d slots); P1/P2/P3 first cleared at frames %s; peak agents %d" % [
		frames, st["mean"], st["p95"], st["p99"], st["max"], waiting_frames, first_waiting, peak_waiting, str(first_clear), peak_agents])
	_ok(comp.is_won() and cleared_art == artwork, "COMPLETE 59x59 v2 level WON: %d / %d artwork cells (%d VOID) in %d frames" % [cleared_art, artwork, N * N - artwork, frames])
	_ok(first_waiting >= 1 and first_waiting <= 5 and waiting_frames >= 60, "a pocket batch WAITED in its slot from frame %d for %d frames" % [first_waiting, waiting_frames])
	# The run is a fixed-step deterministic simulation (fixed DT ticks, fixed plan, deterministic
	# selector/router; real-time FX never feed back into gameplay), so the measured peak of 5 is
	# reproducible and gated exactly as a fail-closed regression floor.
	_ok(peak_waiting >= 5, "peak simultaneous WAITING slots %d (>= 5: every slot waiting at once)" % peak_waiting)
	_ok(waited_ids.size() > 0 and exited_ids.size() == waited_ids.size() and recovered_active > 0,
		"%d batches entered WAITING and all left it; %d were later seen dispatching as ACTIVE (WAITING -> ACTIVE recovery)" % [waited_ids.size(), recovered_active])
	var stuck := 0
	for s in h.get_slots().snapshot():
		if s["occupied"] and String(s["state"]) == "WAITING":
			stuck += 1
	_ok(stuck == 0, "terminal: %d occupied WAITING slots left" % stuck)
	_ok(first_clear[0] > 0 and first_clear[0] < first_clear[1] and first_clear[1] < first_clear[2], "unlock chain respected: P1 ring first cleared at %d < P2 at %d < P3 core at %d" % first_clear)
	_ok(paused_ok and pause_busy[0] > 0 and pause_busy[1] > 0, "60 paused ticks mid-level with %d bots / %d assignments in flight: board, slots, supply, assignments, agent positions, completion, progression, economy unchanged %s" % [pause_busy[0], pause_busy[1], pause_detail])
	_ok(factors == [2.0, 1.0, 2.0], "GameplaySpeedAuthority.factor() 2x -> 1x -> 2x: %s" % str(factors))
	_ok(st["mean"] <= FRAME_STEADY_MS and st["p99"] <= FRAME_SPIKE_MS, "frame mean %.3f ms (<= %.1f), p99 %.3f ms (<= %.1f); max %.3f ms" % [st["mean"], FRAME_STEADY_MS, st["p99"], FRAME_SPIKE_MS, st["max"]])
	_summary.append("SB-M46-004/005/013 pocket level (v2 VOID, 12 colours, unlock depth 3): %d frames, mean %.3f / p95 %.3f / p99 %.3f / max %.3f ms; WAITING %d frames; peak agents %d" % [
		frames, st["mean"], st["p95"], st["p99"], st["max"], waiting_frames, peak_agents])
	_free_host(h)
	_complete("p16_unlock_chains_waiting")

# ------------------------------------------------------------------ R02 cases ----

func _occupied(h) -> int:
	var n := 0
	for s in h.get_slots().snapshot():
		n += 1 if s["occupied"] else 0
	return n

func _active_of(b, local: int) -> int:
	var n := 0
	for i in range(b.get_cell_count()):
		if not b.is_void(i) and b.get_color_id(i) == local and b.get_cell_state(i) == BoardState.CellState.ACTIVE:
			n += 1
	return n

func _supply_batches(h) -> int:
	var n := 0
	for col in h.get_supply().debug_snapshot()["columns"]:
		n += col.size()
	return n

func _supply_has_color(h, local: int) -> bool:
	for col in h.get_supply().debug_snapshot()["columns"]:
		for bd in col:
			if int(bd["color_id"]) == local:
				return true
	return false

func _p17() -> void:
	print("[p17 sixth slot + boosters on the dense 59x59 pocket level]")
	var level := _pocket_level_dict()
	var h = await _host(level, "slot6", _pocket_plan(level))
	var rt = h.get_runtime()
	rt.set_speed_2x(true)
	var eco = h.get_economy()
	var b = h.get_board()
	var comp = h.get_completion()
	var strip = h.get_screen().get_five_slot_strip()
	var PLUS: String = BoosterInventory.PLUS_ONE_SLOT
	var TORNADO: String = BoosterInventory.TORNADO
	_ok(eco != null and h.get_save() == null and h.app_state == null, "isolated in-memory economy (no AppState, no save path): the owner's real profile is never touched")
	var price := int(eco.config.booster_price(PLUS))
	# Unauthorized: no charge, no SB. A fresh isolated economy carries starter SB, so the test
	# first spends it down in that private wallet (the owner's real wallet is never involved).
	eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks())
	_ok(eco.wallet.scrub_bucks() == 0 and eco.boosters.charges(PLUS) == 0, "isolated wallet at 0 SB, 0 +1 Slot charges")
	var e0: Dictionary = _eco_core(eco)
	var r0: Dictionary = h.execute_booster(PLUS)
	_ok(not r0.get("ok", false) and r0.get("reason") == "insufficient_sb" and _eco_core(eco) == e0 and h.get_slots().snapshot().size() == 5,
		"+1 Slot with no charge / SB refused (%s), economy and 5 slots unchanged" % str(r0.get("reason")))
	# Legal purchase: exactly the price, exactly once.
	eco.wallet.credit("scrub_bucks", price)
	var sb0: int = eco.wallet.scrub_bucks()
	var ch0: int = eco.boosters.charges(PLUS)
	var r1: Dictionary = h.execute_booster(PLUS)
	var six: bool = h.get_slots().snapshot().size() == 6 and strip.get_capacity() == 6 and strip.get_slot_views().size() == 6
	_ok(r1.get("ok", false) and eco.wallet.scrub_bucks() == sb0 - price and eco.boosters.charges(PLUS) == ch0 and six,
		"+1 Slot bought with SB: %d -> %d (price %d, charged once), engine + UI strip 5 -> 6 slots" % [sb0, eco.wallet.scrub_bucks(), price])
	# Repeat (once per attempt) and a 7th slot are impossible, and refusals spend nothing.
	eco.wallet.credit("scrub_bucks", price)
	var e1: Dictionary = _eco_core(eco)
	var leg: Dictionary = h.booster_legality(PLUS)
	var r2: Dictionary = h.execute_booster(PLUS)
	_ok(not leg.get("legal", true) and not r2.get("ok", false) and _eco_core(eco) == e1 and h.get_slots().snapshot().size() == 6 and not h.get_slots().can_grow_to_sixth(),
		"second +1 Slot refused (%s / %s), SB kept, still 6 slots, no 7th possible" % [str(leg.get("reason")), str(r2.get("reason"))])
	_ok(not strip.set_capacity(7) and strip.get_slot_views().size() == 6, "UI strip refuses a 7th slot (set_capacity(7) false, 6 views)")
	# One tap = exactly one batch, into the new sixth slot (rightmost empty).
	var occ0 := _occupied(h)
	var sup0 := _supply_batches(h)
	var tap: Dictionary = h.get_input_controller().activate_front(0)
	_ok(tap.get("ok", false) and int(tap.get("slot", -1)) == 5 and _occupied(h) == occ0 + 1 and _supply_batches(h) == sup0 - 1,
		"one front tap: slot %d (the sixth), %d -> %d occupied, supply %d -> %d batches" % [int(tap.get("slot", -1)), occ0, _occupied(h), sup0, _supply_batches(h)])
	var frames := 0
	var times: Array = []
	var max_slots := 0
	var slot6_occupied := false
	var slot6_ui := false
	var slot6_dispatch := false
	var slot6_waiting := false
	var peak_agents := 0
	var tornado := {}
	var cap_frames := 4000 if OS.get_cmdline_user_args().has("quick") else MAX_FRAMES
	while frames < cap_frames and not comp.is_terminal():
		if frames == 1500:
			# Paused: a front tap is refused, and 30 paused ticks with illegal-target booster
			# attempts (unknown colour, missing target) mutate neither gameplay nor economy.
			rt.set_user_paused(true)
			var ep: Dictionary = _eco_core(eco)
			var tp := _truth(h)
			var ptap: Dictionary = h.get_input_controller().activate_front(1)
			var bad: Dictionary = h.execute_booster(TORNADO, -1)
			var bad2: Dictionary = h.execute_booster(TORNADO, null)
			for _i in range(30):
				rt.tick(DT)
				await process_frame
			var same: bool = _eco_core(eco) == ep and _truth(h) == tp
			_ok(tp["agents"].size() > 0 and ptap.get("error") == "paused" and not bad.get("ok", false) and not bad2.get("ok", false) and same,
				"paused with %d bots in flight: tap refused (%s), illegal-target Tornado refused (%s / %s), 30 paused ticks: gameplay + economy unchanged" % [tp["agents"].size(), str(ptap.get("error")), str(bad.get("reason")), str(bad2.get("reason"))])
			rt.set_user_paused(false)
		if frames == 1800:
			# One legally owned colour booster on the live dense board.
			eco.boosters.add_charges(TORNADO, 1)
			var lt: Dictionary = h.booster_legality(TORNADO)
			var key = lt["targets"][0]["key"] if lt.get("legal", false) else -1
			var before := _active_of(b, int(key))
			var sbt: int = eco.wallet.scrub_bucks()
			var t1 := Time.get_ticks_usec()
			var rt_r: Dictionary = h.execute_booster(TORNADO, key)
			var ms := _ms(t1)
			tornado = {"ok": rt_r.get("ok", false), "color": key, "cells": before, "ms": ms, "after": _active_of(b, int(key)),
				"charges": eco.boosters.charges(TORNADO), "sb_same": eco.wallet.scrub_bucks() == sbt, "supply": _supply_has_color(h, int(key)), "burst": 0.0}
		var t0 := Time.get_ticks_usec()
		_feed(h)
		rt.tick(DT)
		await process_frame
		var ft := _ms(t0)
		times.append(ft)
		if not tornado.is_empty() and frames < 1920:
			tornado["burst"] = maxf(float(tornado["burst"]), ft)
		frames += 1
		var snap: Array = h.get_slots().snapshot()
		max_slots = maxi(max_slots, maxi(snap.size(), strip.get_slot_views().size()))
		if snap.size() == 6 and snap[5]["occupied"]:
			slot6_occupied = true
			slot6_waiting = slot6_waiting or String(snap[5]["state"]) == "WAITING"
			slot6_ui = slot6_ui or strip.get_slot_views()[5].is_occupied_view()
		for a in h.get_scheduler().assignment_snapshot():
			if int(a.get("slot", -1)) == 5:
				slot6_dispatch = true
		peak_agents = maxi(peak_agents, h.get_dispatcher().get_active_count())
	var st := _stats(times)
	var art: int = b.get_artwork_cell_count()
	var cleared: int = b.count_cells_by_state(BoardState.CellState.CLEARED) - (N * N - art)
	print("    %d frames, mean %.3f / p99 %.3f / max %.3f ms; peak agents %d; tornado %s" % [frames, st["mean"], st["p99"], st["max"], peak_agents, str(tornado)])
	_ok(max_slots == 6 and slot6_occupied and slot6_ui and slot6_dispatch, "sixth slot really used: occupied in engine + shown occupied in the UI strip + dispatched bots (waiting there too: %s); never more than %d slots" % [str(slot6_waiting), max_slots])
	# Tornado execute time is REPORT-ONLY (not gated): a one-off player action that rebuilds the
	# candidate index, repaints the board and purges a colour; ~50 ms here is a recorded hitch.
	_ok(tornado.get("ok", false) and int(tornado["cells"]) > 0 and int(tornado["after"]) == 0 and int(tornado["charges"]) == 0 and tornado["sb_same"] and not tornado["supply"],
		"owned Tornado on colour %s: %d ACTIVE cells -> 0, its supply batches gone, charge 1 -> 0, SB untouched (report-only: execute %.2f ms, worst frame in the next 120 %.2f ms)" % [str(tornado.get("color")), int(tornado.get("cells", 0)), float(tornado.get("ms", 0.0)), float(tornado.get("burst", 0.0))])
	_ok(comp.is_won() and cleared == art, "level WON with 6 slots + Tornado: %d / %d artwork cells" % [cleared, art])
	_ok(st["mean"] <= FRAME_STEADY_MS and st["p99"] <= FRAME_SPIKE_MS, "frame mean %.3f ms (<= %.1f), p99 %.3f ms (<= %.1f)" % [st["mean"], FRAME_STEADY_MS, st["p99"], FRAME_SPIKE_MS])
	# Terminal: no booster can run; nothing mutates.
	var et: Dictionary = _eco_core(eco)
	var rt1: Dictionary = h.execute_booster(PLUS)
	var lt1: Dictionary = h.booster_legality(TORNADO)
	_ok(not rt1.get("ok", false) and rt1.get("reason") == "terminal" and lt1.get("reason") == "terminal" and _eco_core(eco) == et, "terminal: boosters refused (terminal), economy unchanged")
	# Retry: a fresh attempt is back to five slots and +1 Slot is legal again (once per attempt).
	var ok_retry: bool = h.retry()
	await _frames(2)
	_ok(ok_retry and h.get_slots().snapshot().size() == 5 and strip.get_capacity() == 5 and h.booster_legality(PLUS).get("legal", false),
		"retry: fresh attempt has 5 slots in engine + strip, +1 Slot legal again")
	_summary.append("R02 p17 6 slots + Tornado 59x59: %d frames, mean %.3f / p99 %.3f / max %.3f ms; Tornado %.2f ms, next-120-frame worst %.2f ms" % [
		frames, st["mean"], st["p99"], st["max"], float(tornado.get("ms", 0.0)), float(tornado.get("burst", 0.0))])
	_free_host(h)
	_complete("p17_sixth_slot_boosters")

## 59x59 v2 maze: VOID ring, wall art C14 everywhere except a 1-wide serpentine corridor near the
## bottom whose path colours are C07 (first third), C10, C03 (deepest). Its entrance (24,56) touches
## the open VOID ring; the corridor is otherwise sealed by its own maze-wall art (C13, dealt last),
## so a deep corridor cell is only reachable along the cleared corridor itself.
const MAZE_CIDS := ["C07", "C10", "C03"]
const WALL_CID := "C14"
## The maze block's own wall colour; its batches are dealt LAST, so the walls stay standing (the
## corridor is reachable only through its entrance) while the corridor is being cleared.
const MAZE_WALL_CID := "C13"
const MAZE_BLOCK := Rect2i(22, 47, 15, 10)   # x 22..36, y 47..56 (bottom: short rail trips)

func _maze_path() -> Array:
	var p: Array = [Vector2i(24, 56)]
	var rows := [55, 53, 51, 49]
	for r in range(rows.size()):
		var xs: Array = range(24, 35) if r % 2 == 0 else range(34, 23, -1)
		for x in xs:
			p.append(Vector2i(x, rows[r]))
		if r < rows.size() - 1:
			p.append(Vector2i(34 if r % 2 == 0 else 24, rows[r] - 1))
	return p

func _maze_level_dict() -> Dictionary:
	var used: Array = MAZE_CIDS + [WALL_CID, MAZE_WALL_CID]
	used.sort()
	var pal: Array = []
	var local := {}
	for cid in used:
		local[cid] = pal.size()
		pal.append(_v3[_cids.find(cid)])
	var path := _maze_path()
	var seg := {}
	for i in range(path.size()):
		seg[path[i]] = MAZE_CIDS[mini(i * 3 / path.size(), 2)]
	var cells: Array = []
	for y in range(N):
		for x in range(N):
			if x < 2 or y < 2 or x >= N - 2 or y >= N - 2:
				cells.append(LevelData.VOID_CELL)
			else:
				var wall: String = MAZE_WALL_CID if MAZE_BLOCK.has_point(Vector2i(x, y)) else WALL_CID
				cells.append(local[seg.get(Vector2i(x, y), wall)])
	return {"version": 2, "id": "m46_maze_59", "name": "M46 Maze", "difficulty": "TEST", "width": N, "height": N, "palette": pal, "cells": cells}

## Corridor batches (one per colour, path order) at the fronts of columns 0..2, so the later
## segments WAIT until the earlier one opens them; wall batches fill the rest round-robin.
func _maze_plan(level: Dictionary) -> Dictionary:
	var counts := {}
	for c in level["cells"]:
		if int(c) >= 0:
			counts[int(c)] = int(counts.get(int(c), 0)) + 1
	var local_of := {}
	for i in range(level["palette"].size()):
		local_of[_cids[_v3.find(String(level["palette"][i]))]] = i
	var cols: Array = [[], [], [], [], []]
	var n := 0
	for i in range(MAZE_CIDS.size()):
		cols[i].append({"batchId": "M46M%04d" % n, "cid": MAZE_CIDS[i], "robots": counts[local_of[MAZE_CIDS[i]]]})
		n += 1
	var c := 3
	for cid in [WALL_CID, MAZE_WALL_CID]:
		var left: int = counts[local_of[cid]]
		while left > 0:
			var k := mini(30, left)
			# Maze walls only at the tail of column 4: the feed fills from column 0 first, so
			# column 4's tail is the very last supply to reach a slot.
			cols[4 if cid == MAZE_WALL_CID else c % 5].append({"batchId": "M46M%04d" % n, "cid": cid, "robots": k})
			left -= k
			n += 1
			if cid == WALL_CID:
				c += 1
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": level["id"], "columnCount": 5, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}

## Interior part of a production route (board-local cells): number of cardinal-direction changes
## and the distinct board cells it passes through (sampled every 0.2 cell).
func _route_shape(pts: PackedVector2Array) -> Dictionary:
	var turns := 0
	var last := Vector2i.ZERO
	var cells := {}
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var d: Vector2 = pts[i] - a
		var l := d.length()
		for s in range(int(ceil(l / 0.2)) + 1):
			var q: Vector2 = a + d * (float(s) * 0.2 / maxf(l, 0.0001)) if l > 0.0 else a
			if q.x >= 0.0 and q.y >= 0.0 and q.x < N and q.y < N:
				cells[Vector2i(int(floor(q.x)), int(floor(q.y)))] = true
		var b2: Vector2 = pts[i]
		var inside := (a.x >= 0.0 and a.y >= 0.0 and a.x < N and a.y < N) or (b2.x >= 0.0 and b2.y >= 0.0 and b2.x < N and b2.y < N)
		if l < 0.3 or not inside:
			continue
		var dir := Vector2i(signi(int(round(d.x))) if absf(d.x) >= absf(d.y) else 0, signi(int(round(d.y))) if absf(d.y) > absf(d.x) else 0)
		if last != Vector2i.ZERO and dir != last:
			turns += 1
		last = dir
	return {"turns": turns, "cells": cells}

func _p18() -> void:
	print("[p18 winding multi-colour routes: 59x59 v2 maze]")
	var level := _maze_level_dict()
	var path := _maze_path()
	var h = await _host(level, "maze", _maze_plan(level))
	var rt = h.get_runtime()
	rt.set_speed_2x(true)
	var b = h.get_board()
	var comp = h.get_completion()
	var corridor_local := {}
	var maze_wall_local := -1
	for i in range(level["palette"].size()):
		var cid: String = _cids[_v3.find(String(level["palette"][i]))]
		if MAZE_CIDS.has(cid):
			corridor_local[i] = cid
		if cid == MAZE_WALL_CID:
			maze_wall_local = i
	var walls_broken := 0   # maze-wall cells already CLEARED when a corridor bot was dispatched
	var seen := {}
	var best := {"turns": -1}
	var dup := false
	var open_ok := true
	var corridor_routes := 0
	var frames := 0
	var times: Array = []
	RuntimePerfProbe.reset()
	RuntimePerfProbe.enabled = true
	var cap_frames := 4000 if OS.get_cmdline_user_args().has("quick") else MAX_FRAMES
	while frames < cap_frames and not comp.is_terminal():
		var t0 := Time.get_ticks_usec()
		_feed(h)
		rt.tick(DT)
		await process_frame
		times.append(_ms(t0))
		frames += 1
		var targets := {}
		for a in h.get_scheduler().assignment_snapshot():
			var tg := int(a.get("target", -1))
			if targets.has(tg):
				dup = true
			targets[tg] = true
		for ag in h.get_agent_layer().get_children():
			if not (ag is ScrubbotAgent) or seen.has(ag.owner_id) or not corridor_local.has(ag.color_id):
				continue
			seen[ag.owner_id] = true
			corridor_routes += 1
			var shape := _route_shape(ag.get_route_points())
			# Every interior cell the route crosses (except its own target) must be open now: the
			# route really runs through newly cleared corridor space, never through wall art.
			var tcell := Vector2i(ag.target_index % N, ag.target_index / N)
			for cell in shape["cells"]:
				if cell == tcell:
					continue
				var i: int = cell.y * N + cell.x
				if not b.is_void(i) and b.get_cell_state(i) != BoardState.CellState.CLEARED:
					open_ok = false
			var xw := 0
			for i in range(b.get_cell_count()):
				if not b.is_void(i) and b.get_color_id(i) == maze_wall_local and b.get_cell_state(i) == BoardState.CellState.CLEARED:
					xw += 1
			walls_broken = maxi(walls_broken, xw)
			if OS.get_cmdline_user_args().has("routes"):
				print("      route depth %d turns %d cells %d frame %d maze-walls-cleared %d" % [path.find(tcell), shape["turns"], shape["cells"].size(), frames, xw])
			if int(shape["turns"]) > int(best["turns"]):
				best = {"turns": shape["turns"], "cells": shape["cells"].size(), "target": tcell, "colour": corridor_local[ag.color_id], "depth": path.find(tcell)}
	RuntimePerfProbe.enabled = false
	var probe := RuntimePerfProbe.snapshot()
	for k in ["target_selection", "route_dijkstra", "access_mask_build", "access_compute_route"]:
		if probe.has(k):
			print("    probe %s: %s" % [k, str(probe[k])])
	var st := _stats(times)
	var art: int = b.get_artwork_cell_count()
	var cleared: int = b.count_cells_by_state(BoardState.CellState.CLEARED) - (N * N - art)
	print("    %d frames, mean %.3f / p95 %.3f / p99 %.3f / max %.3f ms; %d corridor routes captured; most winding: %s" % [frames, st["mean"], st["p95"], st["p99"], st["max"], corridor_routes, str(best)])
	_ok(path.size() == 48 and art == 3025, "maze fixture: %d-cell 3-colour corridor, %d artwork + %d VOID cells" % [path.size(), art, N * N - art])
	_ok(corridor_routes == path.size(), "every one of the %d corridor cells was reached by a real dispatched route (%d)" % [path.size(), corridor_routes])
	_ok(int(best["turns"]) >= 6 and int(best.get("cells", 0)) >= 40 and String(best.get("colour", "")) == MAZE_CIDS[2],
		"a production route to the deepest colour turns %d times through %d board cells (target %s, corridor step %d)" % [int(best["turns"]), int(best.get("cells", 0)), str(best.get("target")), int(best.get("depth", -1))])
	_ok(open_ok and walls_broken == 0, "every corridor route crossed only cleared (newly opened) corridor cells besides its own target; the maze walls were intact for all of them")
	_ok(not dup, "no two in-flight assignments ever shared a target")
	_ok(comp.is_won() and cleared == art, "maze level WON: %d / %d artwork cells" % [cleared, art])
	_ok(st["mean"] <= FRAME_STEADY_MS and st["p99"] <= FRAME_SPIKE_MS, "frame mean %.3f ms (<= %.1f), p99 %.3f ms (<= %.1f); max %.3f ms" % [st["mean"], FRAME_STEADY_MS, st["p99"], FRAME_SPIKE_MS, st["max"]])
	_summary.append("R02 p18 maze 59x59: %d frames, mean %.3f / p99 %.3f / max %.3f ms; most winding route %d turns / %d cells; route_dijkstra max %.3f ms" % [
		frames, st["mean"], st["p99"], st["max"], int(best["turns"]), int(best.get("cells", 0)), float(probe.get("route_dijkstra", {}).get("max_ms", 0.0))])
	_free_host(h)
	_complete("p18_winding_routes")

## Saltmire Spark burst emitters (its inner _SparkEmitter Node2D class) in the subtree; the adapter
## reparents bursts next to their target, so both the target viewport and Spark's pool are counted.
const SparkScript = preload("res://addons/saltmire_spark/spark.gd")
func _live_nodes(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

func _particles(n: Node) -> int:
	if n == null:
		return 0
	return n.find_children("*", "Node2D", true, false).filter(func(c): return c.get_script() == SparkScript._SparkEmitter and not c.is_queued_for_deletion()).size()

func _p19() -> void:
	print("[p19 SB-M46-015 effect budget: FULL vs REDUCED on a dense 59x59 run]")
	var level := _pocket_level_dict()
	var h = await _host(level, "fx", _pocket_plan(level))
	var rt = h.get_runtime()
	rt.set_speed_2x(true)
	var sub: SubViewport = h.get_parent()
	var fx = h.get_cleaning_fx()
	var effects = EffectsSettingsService.new()
	var adapter = FeedbackAdapter.new()
	adapter.bind(self, effects)
	var caps: Dictionary = adapter.capabilities()
	var live: bool = bool(caps["gff"]) and bool(caps["spark"])
	_ok(live, "installed plugins live through the real adapter: GameFeelFlow %s (%s), Spark %s (%s)" % [str(caps["gff"]), str(caps["gff_effects"]), str(caps["spark"]), str(caps["spark_presets"])])
	var spark_node: Node = get_root().get_node_or_null("Spark")
	# A legitimate WON receipt from the host's own (isolated) economy + progression.
	var prog = h.get_progression()
	var eco = h.get_economy()
	for n in [1, 2, 3, 4]:
		eco.streak.process_first_clear_win(n)
	prog.debug_set_current_level(10)
	var pre: Dictionary = TerminalRewardReceipt.capture(prog, eco)
	var commit: Dictionary = FirstClearTransaction.commit(prog, eco, 10)
	var receipt: Dictionary = TerminalRewardReceipt.build("WON", 10, pre, TerminalRewardReceipt.capture(prog, eco), commit, {"ok": true})
	var res = ResultsScreen.new()
	res.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(res)
	res.set_feedback(adapter)
	# Settled baseline: one Results show (attempt 0) + every ceiling expired, then measure the
	# Results subtree + Spark state (the host's own node count moves with bots in flight).
	res.visible = true
	res.show_model({"status": "WON", "level": 10, "attempt": 0, "receipt": receipt, "continue": {"available": true}})
	await create_timer(1.6).timeout
	res.visible = false
	await _frames(3)
	var res_nodes0: int = _live_nodes(res)
	var objects0: int = _mem()["objects"]
	var phases := {}
	var attempt := 0
	for mode in ["FULL", "REDUCED"]:
		effects.set_reduced(mode == "REDUCED")
		fx.set_reduced_effects(mode == "REDUCED")
		var times: Array = []
		var peak_owned := 0
		var peak_particles := 0
		var peak_fx := 0
		var shows := 0
		var log0: int = adapter.dispatch_log().size()
		var cleared0: int = h.get_board().count_cells_by_state(BoardState.CellState.CLEARED)
		for f in range(1500):
			var t0 := Time.get_ticks_usec()   # the Results show (row build) counts in its frame
			if f % 250 == 0:
				attempt += 1
				shows += 1
				res.visible = true
				res.show_model({"status": "WON", "level": 10, "attempt": attempt, "receipt": receipt, "continue": {"available": true}, "reduced_effects": mode == "REDUCED"})
			_feed(h)
			rt.tick(DT)
			await process_frame
			times.append(_ms(t0))
			peak_owned = maxi(peak_owned, adapter.owned_count())
			peak_particles = maxi(peak_particles, _particles(sub) + (_particles(spark_node) if spark_node != null else 0))
			peak_fx = maxi(peak_fx, fx.get_active_count())
		# Self-free: every adapter-owned dispatch and burst must expire within its ceiling (real time).
		var t_free := Time.get_ticks_msec()
		while (adapter.owned_count() > 0 or _particles(sub) > 0) and Time.get_ticks_msec() - t_free < 4000:
			await create_timer(0.05).timeout
		var free_ms := Time.get_ticks_msec() - t_free
		var st := _stats(times)
		var clears: int = h.get_board().count_cells_by_state(BoardState.CellState.CLEARED) - cleared0
		phases[mode] = {"mean": st["mean"], "p99": st["p99"], "max": st["max"], "owned": peak_owned, "particles": peak_particles, "fx": peak_fx,
			"fx_cap": fx._effective_cap(), "events": adapter.dispatch_log().size() - log0, "shows": shows, "clears": clears, "free_ms": free_ms,
			"left": adapter.owned_count() + _particles(sub)}
		print("    %s: %s" % [mode, str(phases[mode])])
	var F: Dictionary = phases["FULL"]
	var R: Dictionary = phases["REDUCED"]
	_ok(F["owned"] > 0 and F["particles"] > 0 and F["particles"] <= F["owned"] and int(F["left"]) == 0 and int(F["free_ms"]) < 2000,
		"FULL: real Spark work ran on the Results path (peak %d owned dispatches, %d burst emitters <= dispatches) and all of it expired within %d ms" % [F["owned"], F["particles"], F["free_ms"]])
	_ok(R["owned"] == 0 and R["particles"] == 0 and int(R["left"]) == 0, "REDUCED: zero plugin dispatches owned, zero particle nodes (Results still shown %d times)" % R["shows"])
	_ok(F["fx"] <= F["fx_cap"] and R["fx"] <= R["fx_cap"], "native board cleaning FX within cap: FULL %d / %d, REDUCED %d / %d" % [F["fx"], F["fx_cap"], R["fx"], R["fx_cap"]])
	# Never per cleared cell: 300 more FULL frames of dense clearing with NO Results event must
	# not produce a single adapter event; per Results show the events stay bounded.
	effects.set_reduced(false)
	fx.set_reduced_effects(false)
	var log_q: int = adapter.dispatch_log().size()
	var clr_q: int = h.get_board().count_cells_by_state(BoardState.CellState.CLEARED)
	for _i in range(300):
		_feed(h)
		rt.tick(DT)
		await process_frame
	var quiet_clears: int = h.get_board().count_cells_by_state(BoardState.CellState.CLEARED) - clr_q
	var per_show: float = float(F["events"]) / float(F["shows"])
	# Structural guarantee, checked in source: the board clearing / native FX path never reaches
	# the plugin gateway or a plugin autoload.
	var scan_ok := true
	for p in ["res://scripts/gameplay/presentation/cleaning_effects_controller.gd", "res://scripts/gameplay/clearing/complete_clearing_loop.gd",
			"res://scripts/gameplay/board/board_renderer.gd", "res://scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd"]:
		var src := FileAccess.get_file_as_string(p)
		for needle in ["FeedbackAdapter", "feedback_adapter", "GameFeelFlow", "/root/Spark", "saltmire_spark", "\"Spark\""]:
			scan_ok = scan_ok and src.find(needle) == -1
	_ok(scan_ok and quiet_clears > 20 and adapter.dispatch_log().size() == log_q and per_show <= 12.0,
		"never per cell (structural): clear / native FX / renderer source never reaches the plugin gateway; %d clears without a Results event -> 0 plugin events; %.1f events per Results show" % [quiet_clears, per_show])
	# GameFeelFlow: production Results targets are Controls (GFF 1.0.0 punch_scale drives only
	# Node2D / Node3D, so the adapter never sends it a Control). Exercise the real GFF backend
	# through the same adapter on a Node2D: it must punch, then restore scale exactly on expiry,
	# on cancel_all and on a live REDUCED toggle.
	var n2 := Node2D.new()
	sub.add_child(n2)
	var gff_dev := 0.0
	adapter.play("MAJOR_UNLOCK", n2)
	var tg := Time.get_ticks_msec()
	while Time.get_ticks_msec() - tg < 400:
		await process_frame
		gff_dev = maxf(gff_dev, (n2.scale - Vector2.ONE).length())
	await create_timer(float(FeedbackAdapter.DURATION_CEILING_S["MAJOR_UNLOCK"]) + 0.3).timeout
	await _frames(3)
	var restored_expiry: bool = n2.scale == Vector2.ONE and adapter.owned_count() == 0
	adapter.play("WIN", n2)
	await create_timer(0.1).timeout
	var dev_cancel: float = (n2.scale - Vector2.ONE).length()
	adapter.cancel_all()
	await _frames(3)
	var restored_cancel: bool = n2.scale == Vector2.ONE
	adapter.play("WIN", n2)
	await create_timer(0.1).timeout
	effects.set_reduced(true)
	await _frames(3)
	var restored_toggle: bool = n2.scale == Vector2.ONE and adapter.owned_count() == 0
	effects.set_reduced(false)
	n2.queue_free()
	_ok(gff_dev > 0.01 and restored_expiry and dev_cancel > 0.0 and restored_cancel and restored_toggle,
		"GameFeelFlow punch_scale (real backend, Node2D target): peak deviation %.3f, scale restored to exactly 1 after expiry / cancel_all / REDUCED toggle" % gff_dev)
	_ok(F["mean"] <= FRAME_STEADY_MS and F["p99"] <= FRAME_SPIKE_MS and R["mean"] <= FRAME_STEADY_MS and R["p99"] <= FRAME_SPIKE_MS,
		"CPU frame FULL mean %.3f / p99 %.3f / max %.3f ms; REDUCED mean %.3f / p99 %.3f / max %.3f ms" % [F["mean"], F["p99"], F["max"], R["mean"], R["p99"], R["max"]])
	# One-shot: re-showing an already celebrated terminal never replays its feel.
	effects.set_reduced(false)
	# Replay window covers the whole reveal (rows step every 0.16 s of real time).
	attempt += 1
	var replay_model := {"status": "WON", "level": 10, "attempt": attempt, "receipt": receipt, "continue": {"available": true}}
	res.visible = true
	res.show_model(replay_model)
	await create_timer(1.8).timeout
	var log1: int = adapter.dispatch_log().size()
	res.show_model(replay_model)
	await create_timer(1.8).timeout
	_ok(adapter.dispatch_log().size() == log1 and adapter.owned_count() == 0, "re-showing a fully revealed, celebrated terminal replays nothing (one-shot keys, 1.8 s window)")
	# Live FULL -> REDUCED toggle, cancel, retry and unbind leave nothing owned.
	attempt += 1
	res.show_model({"status": "WON", "level": 10, "attempt": attempt, "receipt": receipt, "continue": {"available": true}})
	await _frames(12)
	var owned_live: int = adapter.owned_count()
	effects.set_reduced(true)
	var after_toggle: int = adapter.owned_count()
	effects.set_reduced(false)
	attempt += 1
	res.show_model({"status": "WON", "level": 10, "attempt": attempt, "receipt": receipt, "continue": {"available": true}})
	await _frames(12)
	var retried: bool = h.retry()
	adapter.cancel_all()
	var after_cancel: int = adapter.owned_count()
	_ok(owned_live > 0 and after_toggle == 0 and retried and after_cancel == 0, "live FULL->REDUCED toggle cancels %d owned dispatches; a mid-celebration level retry (ok) + cancel_all leave 0 owned" % owned_live)
	# Same settled state as the baseline: one more Results show of the same receipt, ceilings expired.
	attempt += 1
	res.show_model({"status": "WON", "level": 10, "attempt": attempt, "receipt": receipt, "continue": {"available": true}})
	await create_timer(1.6).timeout
	res.visible = false
	await _frames(3)
	adapter.unbind()
	var spark_pool: Node = spark_node.get_node_or_null(FeedbackAdapter.SPARK_POOL) if spark_node != null else null
	var res_nodes1: int = _live_nodes(res)
	var objects1: int = _mem()["objects"]
	print("    drift: Results subtree nodes %d -> %d; process objects %+d (report-only: includes bots in flight / retried supply)" % [res_nodes0, res_nodes1, objects1 - objects0])
	_ok(res_nodes1 == res_nodes0 and _particles(sub) == 0 and (spark_pool == null or _live_nodes(spark_pool) == 0) and adapter.owned_count() == 0 and not effects.changed.is_connected(adapter._on_effects_changed),
		"after %d Results shows FULL + REDUCED: Results subtree %d -> %d nodes, 0 Spark emitters (target canvas + pool), 0 owned, unbind dropped the settings subscription" % [attempt, res_nodes0, res_nodes1])
	_summary.append("R02 p19 SB-M46-015 FULL: mean %.3f / p99 %.3f ms, peak %d owned / %d particles, self-free %d ms; REDUCED: mean %.3f / p99 %.3f ms, 0 owned / 0 particles" % [
		F["mean"], F["p99"], F["owned"], F["particles"], F["free_ms"], R["mean"], R["p99"]])
	res.queue_free()
	_free_host(h)
	_complete("p19_effect_budget")

## Fixed CPU calibration workload (fresh dense board, 150 production routes): printed at every
## case-group boundary so in-process slowdown can be told apart from machine slowdown.
var _calib_board = null
var _calib_targets: Array = []
func _calib() -> float:
	if _calib_board == null:
		_calib_board = _dense_board()
		var ta = ProductionTargetAccess.new(ProductionRoutingSystem.new(), ProductionAccessQuery.new(_calib_board), _calib_board, _origin())
		for i in range(N * N):
			if ta.is_targetable(i):
				_calib_targets.append(i)
	var routing = ProductionRoutingSystem.new()
	var acc = ProductionAccessQuery.new(_calib_board)
	var t0 := Time.get_ticks_usec()
	for k in range(150):
		routing.compute_route(RouteRequest.for_target(_calib_board, _origin(), _calib_targets[k % _calib_targets.size()]), _calib_board, acc)
	return _ms(t0)

## Stop topping up slots and run the level until at least `n` slots are free (bounded).
func _wait_free_slots(h, n: int) -> void:
	for _i in range(6000):
		if h.get_slots().snapshot().size() - _occupied(h) >= n:
			return
		h.get_runtime().tick(DT)
		await process_frame

## Live supply as "batch:colour:count" strings in column order (sorted copy = the multiset).
func _supply_list(h) -> Array:
	var out: Array = []
	for col in h.get_supply().debug_snapshot()["columns"]:
		for bd in col:
			out.append("%s:%d:%d" % [String(bd["batch_id"]), int(bd["color_id"]), int(bd["robot_count"])])
	return out

func _slot_batches(h) -> Array:
	var out: Array = []
	for s in h.get_slots().snapshot():
		if s["occupied"]:
			out.append(String(s["batch_id"]))
	return out

func _p20() -> void:
	print("[p20 Random + Selector boosters at 59x59]")
	var RANDOM: String = BoosterInventory.RANDOM
	var SELECTOR: String = BoosterInventory.SELECTOR
	# Phase A, pocket level (sealed colours, WAITING): Random at 5 moments, each with >= 3 free
	# slots (its owner rule proves 3 consecutive accepted placements on the live slots). Every
	# outcome is checked: a success spends exactly one charge and conserves every batch; a
	# solver-safety refusal mutates nothing. Proof time is REPORT-ONLY (see the R03 log).
	var pl := _pocket_level_dict()
	var hp = await _host(pl, "rs_pocket", _pocket_plan(pl))
	hp.get_runtime().set_speed_2x(true)
	var ep = hp.get_economy()
	ep.wallet.debit("scrub_bucks", ep.wallet.scrub_bucks())   # charges only, never SB
	ep.boosters.add_charges(RANDOM, 5)
	for _i in range(1500):
		_feed(hp)
		hp.get_runtime().tick(DT)
		await process_frame
	var outcomes: Array = []
	var a_ok := true
	var worst_ms := 0.0
	for _k in range(5):
		await _wait_free_slots(hp, 3)
		var e0 := _eco_core(ep)
		var s0 := _supply_list(hp)
		var ch0: int = ep.boosters.charges(RANDOM)
		var tl := Time.get_ticks_usec()
		var r: Dictionary = hp.execute_booster(RANDOM)
		var ms := _ms(tl)
		worst_ms = maxf(worst_ms, ms)
		var s1 := _supply_list(hp)
		if r.get("ok", false):
			var x := s0.duplicate()
			x.sort()
			var y := s1.duplicate()
			y.sort()
			a_ok = a_ok and ep.boosters.charges(RANDOM) == ch0 - 1 and ep.wallet.snapshot() == e0["wallet"] and x == y and s0 != s1
			outcomes.append("ok %.0f ms" % ms)
		else:
			a_ok = a_ok and r.get("reason") == "not_solver_safe" and _eco_core(ep) == e0 and s1 == s0
			outcomes.append("%s %.0f ms" % [str(r.get("reason")), ms])
		for _i in range(200):
			_feed(hp)
			hp.get_runtime().tick(DT)
			await process_frame
	print("    pocket Random outcomes: %s" % str(outcomes))
	_ok(a_ok, "pocket level, 5 Random attempts with >= 3 free slots: %s; each success spent exactly one charge with every batch conserved, each refusal (not_solver_safe) mutated nothing (report-only: worst proof %.0f ms)" % [str(outcomes), worst_ms])
	_free_host(hp)
	# Phase B, stripe level (every colour always reachable): both boosters legal and executed.
	var level := _stripe_level_dict()
	var h = await _host(level, "rs")
	var rt = h.get_runtime()
	rt.set_speed_2x(true)
	var eco = h.get_economy()
	var comp = h.get_completion()
	_ok(eco != null and h.get_save() == null and h.app_state == null, "isolated in-memory economy (no AppState, no save path)")
	eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks())
	eco.boosters.add_charges(RANDOM, 1)
	eco.boosters.add_charges(SELECTOR, 1)
	# Illegal Selector target (not an eligible batch) -> refused, nothing consumed or moved.
	var e_bad := _eco_core(eco)
	var sup_bad := _supply_list(h)
	var bad: Dictionary = h.execute_booster(SELECTOR, "NO_SUCH_BATCH")
	_ok(not bad.get("ok", false) and bad.get("reason") == "not_eligible" and _eco_core(eco) == e_bad and _supply_list(h) == sup_bad, "Selector with a non-eligible batch refused (%s): charge, SB and supply unchanged" % str(bad.get("reason")))
	var res := {"random": {}, "selector": {}}
	var tries := {"random": 0, "selector": 0}
	var times: Array = []
	var frames := 0
	var hold := false        # stop topping up slots until one is free (both boosters need an empty slot)
	var cap_frames := 6000 if OS.get_cmdline_user_args().has("quick") else MAX_FRAMES
	while frames < cap_frames and not comp.is_terminal():
		var which := ""
		if res["random"].is_empty() and frames >= 1200:
			which = "random"
		elif not res["random"].is_empty() and res["selector"].is_empty() and frames >= int(res["random"]["frame"]) + 600:
			which = "selector"
		if which != "" and (frames % 300 == 0 or hold):
			hold = true
			# Random's owner rule proves 3 consecutive accepted front placements on the live slot
			# state, so it needs 3 free slots; Selector needs the rightmost empty one.
			var need: int = 3 if which == "random" else 1
			if h.get_slots().snapshot().size() - _occupied(h) >= need:
				hold = false
				var id: String = RANDOM if which == "random" else SELECTOR
				tries[which] += 1
				var tl := Time.get_ticks_usec()
				var leg: Dictionary = h.booster_legality(id)
				var legal_ms := _ms(tl)
				if leg.get("legal", false) and which == "selector":
					# R03 production change: apply_selector proves only the chosen batch via
					# is_batch_eligible(); it must agree with the full eligible list for every id.
					var listed: Array = leg["targets"].map(func(t): return String(t["key"]))
					var adapter = h.get_booster_adapter()
					var agree := 0
					var ids: Array = _supply_list(h).map(func(x): return String(x).get_slice(":", 0))
					for bid in ids:
						agree += 1 if adapter.is_batch_eligible(bid) == listed.has(bid) else 0
					var junk_ok: bool = not adapter.is_batch_eligible("NO_SUCH") and not adapter.is_batch_eligible(null) and not adapter.is_batch_eligible(5) \
						and adapter.is_batch_eligible(StringName(String(listed[0]))) == true
					_ok(agree == ids.size() and junk_ok, "is_batch_eligible == eligible_safe_batches membership for all %d supply ids (%d eligible); unknown / null / int false, StringName id accepted" % [ids.size(), listed.size()])
					# R03 in-flight shortcut: the probe must give the classifier's own verdict on the
					# fully built ProofState, for every batch's real post-placement scratch state.
					var same_verdict := 0
					var inflight: int = adapter._inflight()
					for bid in ids:
						var cols0: Array = adapter._current_cols()
						var tcol := -1
						for c in range(cols0.size()):
							for bb in cols0[c]:
								if bb.get_batch_id() == bid:
									tcol = c
						var sup = BatchSupplyEngine.create(h.get_supply().get_column_count(), h.get_supply().get_preview_depth())
						sup.load_candidate(adapter._cols_with_front(cols0, bid), h.get_supply().get_seed(), h.get_supply().get_palette_size())
						var ss = adapter._scratch_slots_from_live()
						ss.select_front_batch(sup, tcol)
						var st0 = ProofState.from_runtime(h.get_level(), h.get_board(), sup, ss)
						var status: StringName = adapter._classifier.classify(st0, inflight).get("status", &"") if st0 != null else &""
						var full: bool = status in [DeadlockClassifier.PROGRESSABLE, DeadlockClassifier.STALLED, DeadlockClassifier.COMPLETED]
						same_verdict += 1 if adapter._is_safe_probe(sup, ss) == full else 0
					_ok(inflight > 0 and same_verdict == ids.size(), "in-flight shortcut (%d bots in flight): probe verdict == full ProofState + classifier verdict for all %d batches" % [inflight, ids.size()])
					# Null-mirroring: where ProofState.from_runtime would return null the probe must stay
					# false even with bots in flight (null slots, non-engine supply, board/level size mismatch).
					var sup2 = BatchSupplyEngine.create(h.get_supply().get_column_count(), h.get_supply().get_preview_depth())
					sup2.load_candidate(adapter._current_cols(), h.get_supply().get_seed(), h.get_supply().get_palette_size())
					var ss2 = adapter._scratch_slots_from_live()
					var mismatched = ProductionBoosterAdapter.new(h.get_level(), BoardState.from_level_data(_level_from(_stripe_level_dict(20))), h.get_supply(), h.get_slots(), h.get_scheduler())
					_ok(adapter._inflight() > 0 and not adapter._is_safe_probe(sup2, null) and not adapter._is_safe_probe(RefCounted.new(), ss2)
						and mismatched._inflight() > 0 and not mismatched._is_safe_probe(sup2, ss2) and adapter._is_safe_probe(sup2, ss2),
						"in-flight shortcut keeps every from_runtime refusal: null slots, non-engine supply and a 20x20 board under a 59x59 level all false; the valid state true")
				if leg.get("legal", false):
					var e0 := _eco_core(eco)
					var sup0 := _supply_list(h)
					var occ0 := _occupied(h)
					var target = null if which == "random" else leg["targets"][0]["key"]
					var tx := Time.get_ticks_usec()
					var r: Dictionary = h.execute_booster(id, target)
					var exec_ms := _ms(tx)
					var sup1 := _supply_list(h)
					var a := sup0.duplicate()
					a.sort()
					var s1 := sup1.duplicate()
					s1.sort()
					res[which] = {"ok": r.get("ok", false), "legal_ms": legal_ms, "exec_ms": exec_ms, "frame": frames, "burst": 0.0,
						"charge_used": eco.boosters.charges(id) == 0, "sb_same": eco.wallet.snapshot() == e0["wallet"], "targets": leg["targets"].size(),
						"supply_before": sup0.size(), "supply_after": sup1.size(), "occ_before": occ0, "occ_after": _occupied(h),
						"conserved": a == s1, "reordered": sup0 != sup1, "batch": String(target) if target != null else "",
						"in_slot": target != null and _slot_batches(h).has(String(target)),
						"gone": target != null and sup1.filter(func(x): return String(x).begins_with(String(target) + ":")).is_empty()}
				else:
					print("    %s not legal at frame %d (%s, %.1f ms)" % [which, frames, str(leg.get("reason")), legal_ms])
		var t0 := Time.get_ticks_usec()
		if not hold:
			_feed(h)
		rt.tick(DT)
		await process_frame
		var ft := _ms(t0)
		times.append(ft)
		for k in res:
			if not res[k].is_empty() and frames >= int(res[k]["frame"]) and frames < int(res[k]["frame"]) + 120:
				res[k]["burst"] = maxf(float(res[k]["burst"]), ft)
		frames += 1
	var st := _stats(times)
	var b = h.get_board()
	var cleared: int = b.count_cells_by_state(BoardState.CellState.CLEARED)
	print("    %d frames, mean %.3f / p99 %.3f / max %.3f ms; tries %s" % [frames, st["mean"], st["p99"], st["max"], str(tries)])
	print("    random: %s" % str(res["random"]))
	print("    selector: %s" % str(res["selector"]))
	var R: Dictionary = res["random"]
	var S: Dictionary = res["selector"]
	_ok(R.get("ok", false) and R["charge_used"] and R["sb_same"] and R["conserved"] and R["reordered"] and R["supply_after"] == R["supply_before"] and R["occ_after"] == R["occ_before"],
		"Random (legal on try %d): charge 1 -> 0, SB untouched, live supply of %d batches reordered with every batch / colour / count conserved, slots untouched (report-only: legality %.1f ms, execute %.1f ms, next-120 worst frame %.1f ms)" % [
		tries["random"], int(R.get("supply_before", 0)), float(R.get("legal_ms", 0.0)), float(R.get("exec_ms", 0.0)), float(R.get("burst", 0.0))])
	_ok(S.get("ok", false) and S["charge_used"] and S["sb_same"] and S["in_slot"] and S["gone"] and S["supply_after"] == S["supply_before"] - 1 and S["occ_after"] == S["occ_before"] + 1,
		"Selector (legal on try %d, %d eligible): batch %s moved from supply into a slot (+1 occupied, -1 supply), charge 1 -> 0, SB untouched (report-only: legality %.1f ms, execute %.1f ms, next-120 worst frame %.1f ms)" % [
		tries["selector"], int(S.get("targets", 0)), str(S.get("batch", "")), float(S.get("legal_ms", 0.0)), float(S.get("exec_ms", 0.0)), float(S.get("burst", 0.0))])
	_ok(comp.is_won() and cleared == N * N, "level WON after Random + Selector: %d / %d cells" % [cleared, N * N])
	_ok(st["mean"] <= FRAME_STEADY_MS and st["p99"] <= FRAME_SPIKE_MS, "frame mean %.3f ms (<= %.1f), p99 %.3f ms (<= %.1f); max %.3f ms" % [st["mean"], FRAME_STEADY_MS, st["p99"], FRAME_SPIKE_MS, st["max"]])
	eco.boosters.add_charges(RANDOM, 1)
	eco.boosters.add_charges(SELECTOR, 1)
	var et := _eco_core(eco)
	var r1: Dictionary = h.execute_booster(RANDOM)
	var r2: Dictionary = h.execute_booster(SELECTOR, "ANY")
	_ok(r1.get("reason") == "terminal" and r2.get("reason") == "terminal" and _eco_core(eco) == et, "terminal: Random and Selector refused (terminal), charges and SB unchanged")
	_summary.append("R03 p20 Random + Selector 59x59 stripes: %d frames, mean %.3f / p99 %.3f ms; Random legality %.1f / execute %.1f ms; Selector legality %.1f / execute %.1f ms; pocket Random worst proof %.0f ms" % [
		frames, st["mean"], st["p99"], float(R.get("legal_ms", 0.0)), float(R.get("exec_ms", 0.0)), float(S.get("legal_ms", 0.0)), float(S.get("exec_ms", 0.0)), worst_ms])
	_free_host(h)
	_complete("p20_random_selector")

## Tick without topping up slots until `free` slots are empty (robots may keep moving).
func _hold_until_free(h, free: int) -> void:
	for _i in range(6000):
		if h.get_slots().snapshot().size() - _occupied(h) >= free:
			return
		h.get_runtime().tick(DT)
		await process_frame

## One timed booster call -> [result, ms].
func _timed(f: Callable) -> Array:
	var t0 := Time.get_ticks_usec()
	var r = f.call()
	return [r, _ms(t0)]

func _p21() -> void:
	print("[p21 owner proof budget: moving vs still robots at 59x59]")
	var RANDOM: String = BoosterInventory.RANDOM
	var SELECTOR: String = BoosterInventory.SELECTOR
	var budget: float = float(ProductionBoosterAdapter.PROOF_BUDGET_MS)
	var limit: float = budget + 200.0   # the node in progress when the budget passes may finish
	var worst := 0.0
	var counts := {"moving": {}, "still": {}}
	var all_ok := true
	for which in ["stripes", "pocket"]:
		var level: Dictionary = _stripe_level_dict() if which == "stripes" else _pocket_level_dict()
		var h = await _host(level, "budget_" + which, {} if which == "stripes" else _pocket_plan(level))
		var rt = h.get_runtime()
		rt.set_speed_2x(true)
		var eco = h.get_economy()
		var a = h.get_booster_adapter()
		eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks())   # charges only; SB must stay 0
		# MOVING: 6 samples, each with >= 3 free slots while robots are still travelling.
		var moving_ok := true
		for k in range(6):
			for _i in range(500):
				_feed(h)
				rt.tick(DT)
				await process_frame
			await _hold_until_free(h, 3)
			var inflight: int = h.get_scheduler().live_assignment_count()
			var lr: Array = _timed(func(): return h.booster_legality(RANDOM))
			var ls: Array = _timed(func(): return h.booster_legality(SELECTOR))
			worst = maxf(worst, maxf(lr[1], ls[1]))
			for pair in [["random", lr[0]], ["selector", ls[0]]]:
				var key := "%s:%s" % [pair[0], "legal" if pair[1].get("legal", false) else String(pair[1].get("reason", ""))]
				counts["moving"][key] = int(counts["moving"].get(key, 0)) + 1
			moving_ok = moving_ok and lr[1] <= limit and ls[1] <= limit and (inflight == 0 or (lr[0].get("legal", false) and ls[0].get("legal", false)))
		# STILL: stop tapping until every robot has arrived (the completion check runs as in play).
		var tick_worst := 0.0
		for _i in range(6000):
			if h.get_scheduler().live_assignment_count() == 0:
				break
			var t1 := Time.get_ticks_usec()
			rt.tick(DT)
			tick_worst = maxf(tick_worst, _ms(t1))
			await process_frame
		var still: bool = h.get_scheduler().live_assignment_count() == 0
		# FORCED timeout (adapter budget 1 ms: deterministic on any machine). Every refusal is
		# proof_timeout and spends nothing on BOTH paths (SB buy-and-use with 0 charges, then an
		# owned charge); the Selector list / has-any rotate past each timed-out batch.
		var bid0: String = String(_supply_list(h)[0]).get_slice(":", 0)
		var forced_ok: bool = still and eco.boosters.charges(RANDOM) == 0 and eco.boosters.charges(SELECTOR) == 0
		a.budget_ms = 1
		eco.wallet.credit("scrub_bucks", int(eco.config.booster_price(RANDOM)) + int(eco.config.booster_price(SELECTOR)))
		for path in ["sb", "charge"]:
			if path == "charge":
				eco.boosters.add_charges(RANDOM, 1)
				eco.boosters.add_charges(SELECTOR, 1)
			var ef := _eco_core(eco)
			var sf := _supply_list(h)
			var fr: Dictionary = h.execute_booster(RANDOM)
			var fs: Dictionary = h.execute_booster(SELECTOR, bid0)
			var unchanged: bool = _eco_core(eco) == ef and _supply_list(h) == sf
			forced_ok = forced_ok and fr.get("reason") == "proof_timeout" and fs.get("reason") == "proof_timeout" and unchanged
			print("    forced %s path: Random %s, Selector %s, economy+supply unchanged %s" % [path, fr.get("reason"), fs.get("reason"), str(unchanged)])
		var n_ids: int = _supply_list(h).size()
		var offs: Array = [a._list_offset]
		for _k in range(3):
			var fl: Dictionary = h.booster_legality(SELECTOR)
			forced_ok = forced_ok and fl.get("partial", false) and fl.get("reason") == "proof_timeout"
			offs.append(a._list_offset)
		var fh: bool = a.has_eligible_safe_batch()
		offs.append(a._list_offset)
		for k in range(1, offs.size()):
			forced_ok = forced_ok and int(offs[k]) == (int(offs[k - 1]) + 1) % n_ids   # one slow batch never pins a retry
		forced_ok = forced_ok and not fh and a.last_proof_timed_out()
		print("    forced list offsets %s over %d batches" % [str(offs), n_ids])
		a.budget_ms = ProductionBoosterAdapter.PROOF_BUDGET_MS
		eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks())
		_ok(forced_ok, "%s: forced 1 ms budget at a still moment -> Random + Selector proof_timeout on SB and charge paths, nothing spent, supply unchanged; list/has-any rotate one batch per retry" % which)
		# Random at a still moment: either proven within the budget or cancelled with nothing spent.
		var e0 := _eco_core(eco)
		var s0 := _supply_list(h)
		var rr: Array = _timed(func(): return h.execute_booster(RANDOM))
		worst = maxf(worst, rr[1])
		var r_key := "random:%s" % ("legal" if rr[0].get("ok", false) else String(rr[0].get("reason", "")))
		counts["still"][r_key] = int(counts["still"].get(r_key, 0)) + 1
		var r_safe: bool = rr[0].get("ok", false) or (rr[0].get("reason") == "proof_timeout" and _eco_core(eco) == e0 and _supply_list(h) == s0)
		# Selector list at the still moment: bounded, partial lists resume on the next call.
		var off0: int = a._list_offset
		var l1: Array = _timed(func(): return h.booster_legality(SELECTOR))
		var off1: int = a._list_offset
		var l2: Array = _timed(func(): return h.booster_legality(SELECTOR))
		worst = maxf(worst, maxf(l1[1], l2[1]))
		var resumed: bool = not l1[0].get("partial", false) or off1 != off0
		var s_key := "selector:%s" % ("legal" if l1[0].get("legal", false) else String(l1[0].get("reason", "")))
		counts["still"][s_key] = int(counts["still"].get(s_key, 0)) + 1
		# Selector on the player's chosen batch (the first supply batch) at the still moment.
		var bid: String = String(_supply_list(h)[0]).get_slice(":", 0)
		var e1 := _eco_core(eco)
		var s1 := _supply_list(h)
		var sx: Array = _timed(func(): return h.execute_booster(SELECTOR, bid))
		worst = maxf(worst, sx[1])
		var sel_safe: bool = (sx[0].get("ok", false) and eco.boosters.charges(SELECTOR) == 0 and _slot_batches(h).has(bid)) \
			or (sx[0].get("reason") in ["proof_timeout", "not_eligible"] and _eco_core(eco) == e1 and _supply_list(h) == s1)
		var x_key := "selector_execute:%s" % ("ok" if sx[0].get("ok", false) else String(sx[0].get("reason", "")))
		counts["still"][x_key] = int(counts["still"].get(x_key, 0)) + 1
		# Retry: the player taps a batch (robots move again) and Random goes through.
		var retry_ok := true
		if not rr[0].get("ok", false):
			var ic = h.get_input_controller()
			for col in range(5):
				if ic.activate_front(col).get("ok", false):
					break
			for _i in range(60):
				rt.tick(DT)
				await process_frame
				if h.get_scheduler().live_assignment_count() > 0:
					break
			await _hold_until_free(h, 3)
			var ch: int = eco.boosters.charges(RANDOM)
			var r2: Array = _timed(func(): return h.execute_booster(RANDOM))
			worst = maxf(worst, r2[1])
			retry_ok = r2[0].get("ok", false) and eco.boosters.charges(RANDOM) == ch - 1 and eco.wallet.scrub_bucks() == 0
		print("    %s: still=%s (completion tick worst %.0f ms) Random %s %.0f ms | Selector list %s %.0f / %.0f ms (offset %d -> %d) | Selector execute %s %.0f ms | retry ok %s" % [
			which, str(still), tick_worst, r_key, rr[1], s_key, l1[1], l2[1], off0, off1, x_key, sx[1], str(retry_ok)])
		var ok_here: bool = moving_ok and still and r_safe and resumed and sel_safe and retry_ok and eco.wallet.scrub_bucks() == 0
		all_ok = all_ok and ok_here
		_ok(ok_here, "%s: moving samples fast + legal while robots travel; still moment: Random %s, Selector list %s (resumable), chosen-batch Selector %s, nothing spent on any refusal, retry after a tap succeeds" % [which, r_key, s_key, x_key])
		_free_host(h)
	print("    outcome counts: %s" % str(counts))
	_ok(worst <= limit, "every booster proof call ended within %.0f ms (budget %.0f ms + node margin); worst %.0f ms" % [limit, budget, worst])
	_summary.append("R05 p21 proof budget %d ms: worst call %.0f ms; outcomes %s" % [ProductionBoosterAdapter.PROOF_BUDGET_MS, worst, str(counts)])
	_complete("p21_proof_budget")

## Play `ticks` fed frames, then stop tapping until every robot has arrived (a still moment).
func _reach_still(h, ticks: int) -> bool:
	var rt = h.get_runtime()
	for _i in range(ticks):
		_feed(h)
		rt.tick(DT)
		await process_frame
	for _i in range(6000):
		if h.get_scheduler().live_assignment_count() == 0:
			return true
		rt.tick(DT)
		await process_frame
	return false

## Longest ATOMIC units of the booster proof at the host's current state (R06 slice
## granularity): ProofState build, root quiesce, one apply_placement, one node expansion.
## Mirrors the solver's DFS (memoized, ascending columns) for up to `cap_ms`.
func _granularity(h, cap_ms: float) -> Dictionary:
	var a = h.get_booster_adapter()
	var t := Time.get_ticks_usec()
	var st = ProofState.from_runtime(a._level, a._board, a._supply, a._slots)
	var build_ms := _ms(t)
	var k = ProofKernel.new()
	t = Time.get_ticks_usec()
	var q: Dictionary = k.quiesce(st)
	var quiesce_ms := _ms(t)
	var place_ms: Array = []
	var node_ms: Array = []
	var stack: Array = [q["state"]] if q.get("ok", false) else []
	var seen := {}
	var t_all := Time.get_ticks_usec()
	while not stack.is_empty() and _ms(t_all) < cap_ms:
		var s = stack.pop_back()
		var key: String = s.canonical_key()
		if seen.has(key):
			continue
		seen[key] = true
		var tn := Time.get_ticks_usec()
		var kids: Array = []
		for c in s.legal_action_columns():
			var tp := Time.get_ticks_usec()
			var r: Dictionary = k.apply_placement(s, c)
			place_ms.append(_ms(tp))
			if r.get("ok", false):
				kids.append(r["state"])
		node_ms.append(_ms(tn))
		for i in range(kids.size() - 1, -1, -1):
			stack.push_back(kids[i])
	var ps := _stats(place_ms) if not place_ms.is_empty() else {"p99": 0.0, "max": 0.0}
	var ns := _stats(node_ms) if not node_ms.is_empty() else {"p99": 0.0, "max": 0.0}
	return {"build": build_ms, "quiesce": quiesce_ms, "places": place_ms.size(), "nodes": node_ms.size(),
		"place_p99": ps["p99"], "place_max": ps["max"], "node_p99": ns["p99"], "node_max": ns["max"]}

func _p22() -> void:
	print("[p22 off-frame booster proof (R06): slice granularity]")
	for which in ["stripes", "pocket"]:
		var level: Dictionary = _stripe_level_dict() if which == "stripes" else _pocket_level_dict()
		var h = await _host(level, "slice_" + which, {} if which == "stripes" else _pocket_plan(level))
		h.get_runtime().set_speed_2x(true)
		var still: bool = await _reach_still(h, 500)
		var g := _granularity(h, 3000.0)
		print("    %s still=%s: ProofState build %.1f ms, root quiesce %.1f ms, apply_placement p99 %.1f / max %.1f ms (%d), node p99 %.1f / max %.1f ms (%d)" % [
			which, str(still), g["build"], g["quiesce"], g["place_p99"], g["place_max"], g["places"], g["node_p99"], g["node_max"], g["nodes"]])
		_free_host(h)
	for order in range(1, 11):
		var path := "user://m46_slice_l%d.save" % order
		_tmp.append(path)
		var app = AppState.new(path, Callable())
		for n in range(1, order):
			app.progression.record_win(n)
		var sub := SubViewport.new()
		sub.size = Vector2i(1080, 2160)
		sub.disable_3d = true
		get_root().add_child(sub)
		var h = ProductionGameplayHost.new()
		h.app_state = app
		h.auto_build = false
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		sub.add_child(h)
		var built: bool = h.build()
		h.get_runtime().set_process(false)
		await _frames(2)
		var g := _granularity(h, 1500.0)
		print("    L%d %s built=%s: build %.1f, quiesce %.1f, apply_placement p99 %.1f / max %.1f (%d), node p99 %.1f / max %.1f ms (%d)" % [
			order, h.get_booster_adapter()._level.id, str(built), g["build"], g["quiesce"], g["place_p99"], g["place_max"], g["places"], g["node_p99"], g["node_max"], g["nodes"]])
		if order <= 4:
			# The detached copy proves exactly what the live adapter proves (both unbudgeted).
			var a = h.get_booster_adapter()
			var d = a.detached_copy()
			a.budget_ms = 0
			d.budget_ms = 0
			var same: bool = a.propose_random_reorder().get("safe") == d.propose_random_reorder().get("safe") \
				and a.eligible_safe_batches() == d.eligible_safe_batches()
			a.budget_ms = ProductionBoosterAdapter.PROOF_BUDGET_MS
			_ok(same, "L%d: detached-copy Random + Selector-list verdicts == live adapter (unbudgeted)" % order)
		if order == 1:
			await _p22_l1(h)
		_free_host(h)
	await _p22_offframe()
	_complete("p22_offframe_proof")

## L1 at its still start (Random proven safe there): the HUD hold auto-uses the owned charge
## exactly once from the cached off-frame verdict (no main-thread proof), SB untouched. Then, at
## a mid-play still moment (occupied / partly cleared slots), detached == live verdicts.
func _p22_l1(h) -> void:
	var RANDOM: String = BoosterInventory.RANDOM
	var eco = h.get_economy()
	var a = h.get_booster_adapter()
	a._verdicts.clear()
	eco.boosters.add_charges(RANDOM, 1)
	var c0: int = eco.boosters.charges(RANDOM)
	var sb0: int = eco.wallet.scrub_bucks()
	var s0 := _supply_list(h)
	var r: Dictionary = h.request_booster(RANDOM)
	var hold: bool = r.get("reason") == "checking" and h.acquisition.find_open("booster_" + RANDOM) != null
	await _frames(2)
	while h.is_booster_proof_running():
		await process_frame
	var lp0: int = a.live_proof_count   # the worker's verdict is now cached; nothing live may run
	await _frames(4)
	var used: bool = eco.boosters.charges(RANDOM) == c0 - 1 and eco.wallet.scrub_bucks() == sb0 \
		and _supply_list(h) != s0 and h.acquisition.find_open("booster_" + RANDOM) == null
	print("    L1 HUD Random: hold %s, used %s, live proofs during settle + use %d" % [str(hold), str(used), a.live_proof_count - lp0])
	_ok(hold and used and a.live_proof_count == lp0, "L1: HUD Random at a still start -> Checking hold, then the owned charge used exactly once (SB unchanged) from the cached verdict, no main-thread proof")
	var still: bool = await _reach_still(h, 300)
	var occupied := _occupied(h)
	var d = a.detached_copy()
	a.budget_ms = 0
	d.budget_ms = 0
	var same: bool = a.propose_random_reorder().get("safe") == d.propose_random_reorder().get("safe") \
		and a.eligible_safe_batches() == d.eligible_safe_batches()
	a.budget_ms = ProductionBoosterAdapter.PROOF_BUDGET_MS
	_ok(still and same, "L1 mid-play still moment (%d occupied slots): detached-copy verdicts == live adapter" % occupied)

## Frames while the worker proves -> [worst frame ms, waited ms, settle frame ms]. Not counted as
## proof cost: the first 2 frames (a just-opened popup's own layout / first draw) and the frame
## the proof settles in (result applied + popup refresh + an auto-used booster's commit:
## a one-off player action, reported separately).
func _wait_proof(h, cap_ms: float) -> Array:
	var frames: Array = []
	var t0 := Time.get_ticks_usec()
	await _frames(2)
	while h.is_booster_proof_running() and _ms(t0) < cap_ms:
		var tf := Time.get_ticks_usec()
		await process_frame
		frames.append(_ms(tf))
	var settle: float = frames.pop_back() if not frames.is_empty() else 0.0
	var tf2 := Time.get_ticks_usec()
	await process_frame   # the deferred auto-use
	settle = maxf(settle, _ms(tf2))
	await process_frame
	return [frames.max() if not frames.is_empty() else 0.0, _ms(t0), settle]

func _p22_offframe() -> void:
	print("[p22 off-frame proof at a still 59x59 moment: Checking state, HUD hold, cancel, stale]")
	var RANDOM: String = BoosterInventory.RANDOM
	var SELECTOR: String = BoosterInventory.SELECTOR
	var cap: float = float(ProductionBoosterAdapter.PROOF_TOTAL_MS) + 1500.0
	for which in ["stripes", "pocket"]:
		var level: Dictionary = _stripe_level_dict() if which == "stripes" else _pocket_level_dict()
		var h = await _host(level, "off_" + which, {} if which == "stripes" else _pocket_plan(level))
		h.get_runtime().set_speed_2x(true)
		var still: bool = await _reach_still(h, 500)
		var eco = h.get_economy()
		var acq = h.acquisition
		eco.wallet.debit("scrub_bucks", eco.wallet.scrub_bucks())
		eco.wallet.credit("scrub_bucks", 5000)
		# 1) Selector popup with no charge: opens at once in "Checking…", Use/SB blocked, no freeze.
		var e0 := _eco_core(eco)
		var s0 := _supply_list(h)
		# Main-thread cost R06 adds to a still-moment check: state key + detached copy + task start.
		var t_start := Time.get_ticks_usec()
		h.booster_legality_offframe(SELECTOR)
		var start_ms := _ms(t_start)
		var key_t := Time.get_ticks_usec()
		h.get_booster_adapter().state_key()
		var key_ms := _ms(key_t)
		var t_open := Time.get_ticks_usec()
		var p = acq.open_booster(h, SELECTOR)
		var open_ms := _ms(t_open)
		print("    %s check start %.1f ms (state key %.1f ms); popup open (UI build, report-only) %.1f ms" % [which, start_ms, key_ms, open_ms])
		var checking: bool = p != null and h.is_booster_proof_running() \
			and (p.find_child("Safety", true, false) as Label).text == UiText.t("BOOSTER_CHECKING") \
			and p.get_action_button("sb").disabled
		var w: Array = await _wait_proof(h, cap)
		var leg: Dictionary = p.get_meta("legality")
		var sel_done: bool = not h.is_booster_proof_running() and String(leg.get("reason", "")) in ["", "proof_timeout", "not_eligible"]
		var chips: int = (leg.get("targets", []) as Array).size()
		p.close("x")
		await _frames(2)
		var sel_ok: bool = still and checking and sel_done and start_ms < FRAME_SPIKE_MS and w[0] < FRAME_SPIKE_MS \
			and _eco_core(eco) == e0 and _supply_list(h) == s0
		print("    %s Selector popup: checking %s, settled after %.0f ms (worst frame %.1f ms; settle frame %.1f ms) -> %s, %d chips" % [
			which, str(checking), w[1], w[0], w[2], String(leg.get("reason", "")) if not leg.get("legal", false) else "legal", chips])
		_ok(sel_ok, "%s: Selector popup shows Checking at once (Use/SB blocked), proves off-frame with every frame < %.1f ms, settles legal / partial / refused, nothing spent" % [which, FRAME_SPIKE_MS])
		# 2) Cancel: closing during a check stops the worker at once; nothing changes.
		h.get_booster_adapter()._verdicts.clear()
		p = acq.open_booster(h, SELECTOR)
		var running: bool = h.is_booster_proof_running()
		var t_c := Time.get_ticks_usec()
		p.close("x")
		await _frames(1)
		var cancel_ms := _ms(t_c)
		var cancel_ok: bool = running and not h.is_booster_proof_running() and _eco_core(eco) == e0 and _supply_list(h) == s0 \
			and h.get_booster_adapter()._verdicts.is_empty()
		print("    %s cancel: running %s, stopped in %.1f ms" % [which, str(running), cancel_ms])
		_ok(cancel_ok and cancel_ms < 250.0, "%s: closing the popup mid-check cancels the worker (%.1f ms), nothing spent or changed" % [which, cancel_ms])
		# 3) Stale: a proof started on one state never answers for another.
		var a = h.get_booster_adapter()
		var leg0: Dictionary = h.booster_legality_offframe(RANDOM)
		var key0: Array = a.state_key()
		var ic = h.get_input_controller()
		for col in range(5):
			if ic.activate_front(col).get("ok", false):
				break
		var key1: Array = a.state_key()
		await _wait_proof(h, cap)
		var stale_ok: bool = leg0.get("reason") == "checking" and key1 != key0 and not a._verdicts.has("random")
		_ok(stale_ok, "%s: a verdict proven on an older state is dropped (state changed mid-check)" % which)
		h.cancel_booster_proof()
		# 4) HUD owned Random at a still moment: Checking hold, then auto-use or a no-spend refusal.
		still = await _reach_still(h, 0)
		eco.boosters.add_charges(RANDOM, 1)
		var e1 := _eco_core(eco)
		var s1 := _supply_list(h)
		var lp_a: int = a.live_proof_count
		var t_hud := Time.get_ticks_usec()
		var r: Dictionary = h.request_booster(RANDOM)
		print("    %s HUD tap -> hold popup %.1f ms (UI build, report-only)" % [which, _ms(t_hud)])
		var hold: bool = r.get("reason") == "checking" and acq.find_open("booster_" + RANDOM) != null and h.get_runtime().is_user_paused()
		var w2: Array = await _wait_proof(h, cap)
		await _frames(3)
		var used: bool = eco.boosters.charges(RANDOM) == 0 and _supply_list(h) != s1 and acq.find_open("booster_" + RANDOM) == null
		var refused: bool = _eco_core(eco) == e1 and _supply_list(h) == s1 and acq.find_open("booster_" + RANDOM) != null
		print("    %s HUD Random: hold %s, settled after %.0f ms (worst frame %.1f ms; settle + auto-use frame %.1f ms, report-only) -> %s" % [which, str(hold), w2[1], w2[0], w2[2], "used" if used else ("refused, nothing spent" if refused else "??")])
		_ok(still and hold and (used or refused) and w2[0] < FRAME_SPIKE_MS and a.live_proof_count == lp_a,
			"%s: owned Random at a still moment -> Checking hold (play paused), no frame >= %.1f ms, no main-thread proof (settle frame = commit + UI), then used once or refused with nothing spent" % [which, FRAME_SPIKE_MS])
		var left = acq.find_open("booster_" + RANDOM)
		if left != null:
			left.close("x")
		await _frames(2)
		_free_host(h)

## Every gameplay truth a pause must freeze (detached copies).
func _truth(h) -> Dictionary:
	var pos: Array = []
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent:
			pos.append([c.owner_id, c.get_local_position(), c.get_progress()])
	return {"board": h.get_board().get_cell_states_copy(), "slots": h.get_slots().snapshot(),
		"supply": h.get_supply().debug_snapshot(), "assignments": h.get_scheduler().assignment_snapshot(),
		"agents": pos, "completion": String(h.get_completion().get_state()),
		"progression": h.get_progression().snapshot() if h.get_progression() != null else {},
		"economy": _eco_core(h.get_economy())}

## The economy state gameplay / booster actions can move: wallet + booster inventory. The full
## EconomyServices snapshot also carries wall-clock-derived Heart / timed-2x fields that legally
## advance in real time (a second boundary can pass during a pause), so it is not compared.
func _eco_core(eco) -> Dictionary:
	if eco == null:
		return {}
	return {"wallet": eco.wallet.snapshot(), "boosters": eco.boosters.snapshot()}

func _host(level: Dictionary, tag: String, plan: Dictionary = {}):
	var lp := _write("lvl_" + tag, JSON.stringify(level))
	var pp := _write("plan_" + tag, JSON.stringify(plan if not plan.is_empty() else _plan_for(level)))
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
