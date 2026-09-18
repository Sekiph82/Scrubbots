extends SceneTree
## M29-C001 V01 — REAL Hazard Bot production-runtime smoke (audit §M/§I/§K/§L).
##
## Builds the FULL production stack via ProductionGameplayHost around the real M28
## GameplayScreen on the real 20x20 Hazard Bot level with the deterministic M27-proven
## M23 candidate (seed 1 / 3 columns / preview 3). It then REPLAYS the M27-solved
## front-selection order through the SAME production path the manual scene uses —
## supply-front activation through the M29 input gate, automatic M26 cadence + agent
## travel through the M29 runtime controller, real M20 authenticated clears — driving the
## real board to full completion.
##
## Proves end-to-end: real authenticated clears through the accepted chain; exact board
## conservation to a fully cleared board; automatic M23-exhausted -> 2x on the final
## real transfer (owner rule §3); and gameplay-truth equivalence at 1x vs 2x (identical
## clears / final board / supply consumption — speed changes duration only).
##
## Run: godot --headless --path . -s res://tests/m29_hazard_bot_runtime_smoke.gd
## Exits 0 on success, 1 on any failure.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")

const LEVEL := "res://data/levels/m21_level_001_hazard_bot.json"
const DT := 1.0
const MAX_TICKS := 60000

var _fail := 0

func _initialize() -> void:
	await _run()
	_done()

func _run() -> void:
	# Solve once for the deterministic front-selection order (the intended play order).
	var order := _solved_order()
	_ok(order.size() > 0, "M27 solver produced a deterministic front-selection order (%d decisions)" % order.size())
	if order.is_empty():
		return

	# --- primary run at 1x -----------------------------------------------------------
	var h1 = await _make_host()
	if h1 == null:
		return
	var r1 := _play_solved(h1, order)
	_ok(r1["clears"] > 0, "1x: production run authenticated real clears (%d)" % r1["clears"])
	_ok(r1["board_cleared"] == r1["clears"], "1x: exact board conservation (cleared cells == authenticated clears)")
	_ok(r1["final_active"] == 0, "1x: real Hazard Bot board fully cleared via the production path")
	_ok(h1.get_supply().is_exhausted(), "1x: all M23 supply consumed through the production gate")
	_ok(h1.get_runtime().is_2x(), "1x-run: automatic 2x engaged after the final M23 batch transferred (owner rule §3)")

	var h1b = await _make_host()
	var r1b := _play_solved(h1b, order)
	_ok(r1b["sequence"] == r1["sequence"], "deterministic: two 1x runs reproduce identical clear sequence")
	_free_host(h1b)

	# --- equivalent run forced to 2x from the start ----------------------------------
	var h2 = await _make_host()
	h2.get_runtime().set_speed_2x(true)
	var r2 := _play_solved(h2, order)
	_ok(r2["clears"] == r1["clears"], "2x: same total clears as 1x (%d == %d)" % [r2["clears"], r1["clears"]])
	_ok(r2["final_active"] == 0 and r1["final_active"] == 0, "2x: identical fully-cleared final board")
	_ok(h2.get_supply().is_exhausted(), "2x: same supply fully consumed")
	_ok(r2["ticks"] <= r1["ticks"], "2x completes in no more ticks than 1x (speed = duration only: %d <= %d)" % [r2["ticks"], r1["ticks"]])

	# --- reset -> 1x -----------------------------------------------------------------
	h2.get_runtime().reset_runtime()
	_ok(not h2.get_runtime().is_2x(), "reset/new session restores 1x")

	_free_host(h1)
	_free_host(h2)

func _solved_order() -> Array:
	var res = LevelLoader.load_from_path(LEVEL)
	if not res.is_ok():
		return []
	var lvl = res.level_data
	var eng = BatchSupplyGenerator.generate(lvl, 3, 3, 1)
	if eng == null:
		return []
	var ps = ProofState.from_level_and_supply(lvl, eng)
	var solver = SolvabilitySolver.new()
	var r: Dictionary = solver.solve(ps, {"max_visited": 200000, "max_depth": 400})
	if r.get("status", "") != SolvabilitySolver.SOLVED:
		return []
	var cols: Array = []
	for a in r["trace"]:
		cols.append(int(a["column"]))
	return cols

func _make_host():
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "production host built on real Hazard Bot (%s)" % host.get_build_error())
	if not ok:
		return null
	await process_frame
	await process_frame
	host.get_runtime().set_process(false)
	host.set_meta("sub", sub)
	return host

func _free_host(host) -> void:
	if host == null:
		return
	var sub = host.get_meta("sub") if host.has_meta("sub") else null
	if sub != null and is_instance_valid(sub):
		sub.free()

## Replay the M27-solved front order through the real input gate + runtime. Each solved
## decision is placed as soon as a slot is free (waiting = ticking for clears to free one);
## after all placements, keep ticking until the last in-flight robot clears.
func _play_solved(host, order: Array) -> Dictionary:
	var board = host.get_board()
	var supply = host.get_supply()
	var slots = host.get_slots()
	var input = host.get_input_controller()
	var runtime = host.get_runtime()
	var scheduler = host.get_scheduler()
	var loop = host.get_clearing_loop()
	var agent_layer = host.get_agent_layer()
	var initial_active: int = board.count_cells_by_state(BoardState.CellState.ACTIVE)

	var seq: Array = []
	var recorder := func(_o, target_index, _c, _a): seq.append(target_index)
	loop.authenticated_clear.connect(recorder)

	var idx := 0
	var ticks := 0
	for _i in range(MAX_TICKS):
		ticks += 1
		# Place the next solved decision if a slot is free.
		if idx < order.size() and slots.rightmost_empty_index() != -1:
			var col: int = order[idx]
			if supply.get_front(col) != null:
				if input.activate_front(col).get("ok", false):
					idx += 1
		runtime.tick(DT)
		if idx >= order.size() and scheduler.live_assignment_count() == 0 and not _any_moving(agent_layer):
			break

	loop.authenticated_clear.disconnect(recorder)
	var final_active: int = board.count_cells_by_state(BoardState.CellState.ACTIVE)
	return {
		"clears": loop.get_cleared_count(),
		"board_cleared": initial_active - final_active,
		"final_active": final_active,
		"ticks": ticks,
		"sequence": seq,
	}

func _any_moving(agent_layer) -> bool:
	if agent_layer == null:
		return false
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return true
	return false

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M29 Hazard Bot runtime smoke: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
