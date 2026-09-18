extends SceneTree
## M29-C001 V02 — REAL Hazard Bot production-runtime smoke (audit §5), now driven with
## the ACTUAL visible laid-out slot origins (F-M29-V01-STRICT-001 fix).
##
## Builds the FULL production stack via ProductionGameplayHost around the real M28
## GameplayScreen on the real 20x20 Hazard Bot level with the deterministic M27-proven
## M23 candidate (seed 1 / 3 columns / preview 3), settles the responsive layout so the
## SlotOriginProvider derives each route origin from the real visible slot top-center
## (FiveSlotStrip.get_slot_anchor_global -> BoardPresentation.global_to_board_local), then
## replays the deterministic solved column-drain order through the SAME production path
## the manual scene uses — supply-front activation, automatic M26 cadence + agent travel,
## real M20 authenticated clears.
##
## Proves end-to-end with the EXACT visible origins: 400 authenticated clears; final
## ACTIVE = 0; no ghost robot; no duplicate live target; M23 fully exhausted; automatic
## 2x after the final real transfer; and 1x/2x gameplay-truth equivalence.
##
## Run: godot --headless --path . -s res://tests/m29_hazard_bot_runtime_smoke.gd
## Exits 0 on success, 1 on any failure.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const DT := 1.0
const MAX_TICKS := 80000

var _fail := 0

func _initialize() -> void:
	await _run()
	_done()

## Deterministic Hazard Bot solved column-drain order (0-based). The seed-1/3-col
## candidate distributes 19 batches round-robin (col0=7, col1=6, col2=6); draining each
## column front-to-back in turn is a proven-solvable order under the actual visible
## origins. Owner-facing 1-based form: 1×7, 2×6, 3×6.
func _order() -> Array:
	var o: Array = []
	for _i in range(7):
		o.append(0)
	for _i in range(6):
		o.append(1)
	for _i in range(6):
		o.append(2)
	return o

func _run() -> void:
	var order := _order()

	# --- primary run at 1x -----------------------------------------------------------
	var h1 = await _make_host()
	if h1 == null:
		return
	var r1 := _play(h1, order)
	_ok(r1["clears"] == 400, "1x: 400 authenticated real clears via the visible-origin production path (%d)" % r1["clears"])
	_ok(r1["board_cleared"] == r1["clears"], "1x: exact board conservation (cleared cells == authenticated clears)")
	_ok(r1["final_active"] == 0, "1x: real Hazard Bot board fully cleared (final ACTIVE = 0)")
	_ok(h1.get_supply().is_exhausted(), "1x: all M23 supply consumed through the production gate")
	_ok(h1.get_runtime().is_2x(), "1x-run: automatic 2x engaged after the final M23 transfer (owner rule §3)")
	_ok(not r1["ghost"], "1x: no ghost robot (dispatcher active == scheduler live claims every tick)")
	_ok(not r1["dup"], "1x: no duplicate live target across scheduler claims")

	var h1b = await _make_host()
	var r1b := _play(h1b, order)
	_ok(r1b["sequence"] == r1["sequence"], "deterministic: two 1x runs reproduce identical clear sequence")
	_free_host(h1b)

	# --- equivalent run forced to 2x from the start ----------------------------------
	var h2 = await _make_host()
	h2.get_runtime().set_speed_2x(true)
	var r2 := _play(h2, order)
	_ok(r2["clears"] == r1["clears"], "2x: same total clears as 1x (%d == %d)" % [r2["clears"], r1["clears"]])
	_ok(r2["final_active"] == 0, "2x: identical fully-cleared final board")
	_ok(h2.get_supply().is_exhausted(), "2x: same supply fully consumed")
	_ok(r2["ticks"] <= r1["ticks"], "2x completes in no more ticks than 1x (speed = duration only: %d <= %d)" % [r2["ticks"], r1["ticks"]])

	# --- reset -> 1x -----------------------------------------------------------------
	h2.get_runtime().reset_runtime()
	_ok(not h2.get_runtime().is_2x(), "reset/new session restores 1x")

	_free_host(h1)
	_free_host(h2)

func _make_host():
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "production host built on real Hazard Bot (%s)" % host.get_build_error())
	if not ok:
		return null
	# Settle the responsive layout so the visible slot anchors (and thus the routing
	# origins) resolve to real board-local geometry before play.
	await process_frame
	await process_frame
	host.get_screen().relayout()
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

## Replay the solved column-drain order through the real input gate + runtime with the
## actual visible origins. Each decision is placed as soon as a slot is free; after all
## placements, keep ticking until the last in-flight robot clears. Tracks ghost/dup
## invariants and the authenticated-clear target sequence.
func _play(host, order: Array) -> Dictionary:
	var board = host.get_board()
	var supply = host.get_supply()
	var slots = host.get_slots()
	var input = host.get_input_controller()
	var runtime = host.get_runtime()
	var scheduler = host.get_scheduler()
	var dispatcher = host.get_dispatcher()
	var loop = host.get_clearing_loop()
	var agent_layer = host.get_agent_layer()
	var initial_active: int = board.count_cells_by_state(BoardState.CellState.ACTIVE)

	var seq: Array = []
	var recorder := func(_o, target_index, _c, _a): seq.append(target_index)
	loop.authenticated_clear.connect(recorder)

	var idx := 0
	var ticks := 0
	var ghost := false
	var dup := false
	for _i in range(MAX_TICKS):
		ticks += 1
		if idx < order.size() and slots.rightmost_empty_index() != -1:
			var col: int = order[idx]
			if supply.get_front(col) != null:
				if input.activate_front(col).get("ok", false):
					idx += 1
		runtime.tick(DT)
		if dispatcher.get_active_count() != scheduler.live_assignment_count():
			ghost = true
		if _has_duplicate_targets(scheduler):
			dup = true
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
		"ghost": ghost,
		"dup": dup,
	}

func _has_duplicate_targets(scheduler) -> bool:
	var seen := {}
	for rec in scheduler.assignment_snapshot():
		var t := int(rec["target"])
		if seen.has(t):
			return true
		seen[t] = true
	return false

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
