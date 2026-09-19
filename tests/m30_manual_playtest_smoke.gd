extends SceneTree
## M30-C001 V01 — manual production playtest smoke (SB-M30-005/006/008, audit §E/§F/§L).
##
## Drives the SAME real production stack the owner F6 scene uses (ProductionGameplayHost +
## real M28 GameplayScreen + real M23-M29 engines + real M30 completion authority), headless,
## on the real 20x20 Hazard Bot level, and proves the owner-visible outcomes end to end:
##   1. the known solved Hazard sequence -> WON exactly once;
##   2. a deterministic proven deadlock fixture (qa_supply_drop_last) -> LOST exactly once;
##   3. after a terminal result, new supply-front input is rejected (no M23/M24 mutation);
##   4. Retry restores the same board + exact same initial supply at 1x, PLAYING;
##   5. the restored attempt is playable (a fresh WON) — proving no stale-state corruption.
##
## Run: godot --headless --path . -s res://tests/m30_manual_playtest_smoke.gd
## Exits 0 on success, 1 on any failure.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const CompleteClearingLoop = preload("res://scripts/gameplay/clearing/complete_clearing_loop.gd")

const DT := 1.0
const MAX_TICKS := 80000

var _fail := 0

func _initialize() -> void:
	await _run()
	_done()

func _run() -> void:
	# ---- 1/3/4/5: solved Hazard -> WON exactly once, terminal blocks input, Retry, replay --
	var h = await _make_host(0)
	if h == null:
		return
	var events := [0]
	var last_status := [null]
	h.get_completion().terminal_reached.connect(func(s, _d): events[0] += 1; last_status[0] = s)

	# Snapshot the exact initial M23 supply BEFORE the first move (same-puzzle Retry proof).
	var initial_supply: Dictionary = h.get_supply().debug_snapshot()
	var initial_active: int = h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)

	_drain(h)
	_ok(h.get_completion().is_won(), "WON: solved Hazard sequence latches WON via the real completion authority")
	_ok(events[0] == 1, "WON: exactly one terminal event emitted")
	_ok(last_status[0] == CompletionEvaluator.WON, "WON: the terminal event is WON")
	_ok(h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == 0, "WON: board fully cleared")

	# E: terminal blocks new supply-front input with a deterministic terminal error, no mutation.
	var supply_before: Dictionary = h.get_supply().debug_snapshot()
	var rej: Dictionary = h.get_input_controller().activate_front(0)
	_ok(not rej.get("ok", false) and rej.get("error", "") == "terminal", "BLOCK: post-terminal front activation rejected with terminal error")
	_ok(h.get_input_controller().is_terminal_stopped(), "BLOCK: input controller is terminal-stopped")
	_ok(h.get_runtime().is_terminal_stopped(), "BLOCK: runtime is terminal-stopped (distinct from user pause)")
	_ok(not h.get_runtime().is_user_paused(), "BLOCK: terminal stop is NOT disguised as a user pause")
	_ok(h.get_supply().debug_snapshot() == supply_before, "BLOCK: rejected activation mutated no M23 supply")

	# F-M30-V01-003: after a full attempt the M20 observation counters are non-zero.
	_ok(h.get_clearing_loop().get_cleared_count() == initial_active, "OBS: after a full attempt M20 cleared_count == %d" % initial_active)
	_ok(h.get_clearing_loop().get_last_outcome() == CompleteClearingLoop.Outcome.CLEARED, "OBS: after a full attempt M20 last_outcome == CLEARED")

	# 4: Retry restores the same board + exact initial supply at 1x, PLAYING.
	_ok(h.retry(), "RETRY: transaction-safe retry succeeds after WON")
	_assert_fresh_attempt(h, initial_supply, initial_active, "RETRY(after WON)")
	# F-M30-V01-003: successful Retry zeros the M20 attempt-scoped observation state.
	_ok(h.get_clearing_loop().get_cleared_count() == 0, "OBS: Retry zeros M20 cleared_count")
	_ok(h.get_clearing_loop().get_last_outcome() == CompleteClearingLoop.Outcome.NONE, "OBS: Retry resets M20 last_outcome -> NONE")

	# 5: restored attempt is fully playable -> a fresh WON, exactly once more.
	_drain(h)
	_ok(h.get_completion().is_won(), "REPLAY: the restored attempt plays to a fresh WON")
	_ok(events[0] == 2, "REPLAY: fresh attempt latches a new terminal event exactly once")
	# F-M30-V01-003: the replay clear count belongs ONLY to the new attempt (not cumulative).
	_ok(h.get_clearing_loop().get_cleared_count() == initial_active, "OBS: replay M20 cleared_count == %d (new attempt only, not cumulative)" % initial_active)
	_free_host(h)

	# ---- 2: deterministic deadlock fixture -> LOST exactly once ---------------------------
	var hd = await _make_host(6)   # drop the drain-tail 6 batches -> unclearable residual
	if hd == null:
		return
	var levents := [0]
	var lstatus := [null]
	hd.get_completion().terminal_reached.connect(func(s, _d): levents[0] += 1; lstatus[0] = s)
	var dl_initial: Dictionary = hd.get_supply().debug_snapshot()
	var dl_active: int = hd.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)
	_drain(hd)
	_ok(hd.get_completion().is_lost(), "LOST: exhausted deadlock fixture latches LOST via the real M27 classifier")
	_ok(levents[0] == 1, "LOST: exactly one terminal event emitted")
	_ok(lstatus[0] == CompletionEvaluator.LOST, "LOST: the terminal event is LOST")
	_ok(hd.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) > 0, "LOST: board still has unclearable ACTIVE cells")
	var lrej: Dictionary = hd.get_input_controller().activate_front(0)
	_ok(lrej.get("error", "") == "terminal", "LOST: post-terminal input rejected with terminal error")
	# Retry restores the same (truncated) fixture supply + full board at 1x.
	_ok(hd.retry(), "LOST-RETRY: transaction-safe retry succeeds after LOST")
	_assert_fresh_attempt(hd, dl_initial, dl_active, "RETRY(after LOST)")
	_free_host(hd)

## Assert a fully coherent fresh attempt: same initial supply snapshot, full ACTIVE board,
## empty slots, zero claims/reservations/agents/assignments/committed work, speed 1x,
## PLAYING, input enabled.
func _assert_fresh_attempt(h, initial_supply: Dictionary, initial_active: int, tag: String) -> void:
	_ok(h.get_supply().debug_snapshot() == initial_supply, "%s: exact same initial M23 supply snapshot restored" % tag)
	_ok(h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == initial_active, "%s: board restored to full ACTIVE" % tag)
	_ok(h.get_slots().occupied_count() == 0, "%s: five slots empty" % tag)
	_ok(h.get_slots().live_work_count() == 0, "%s: zero committed work" % tag)
	_ok(h.get_claim_engine().live_claim_count() == 0, "%s: zero M25 claims" % tag)
	_ok(h.get_reservations().get_reservation_count() == 0, "%s: zero reservations" % tag)
	_ok(h.get_scheduler().live_assignment_count() == 0, "%s: zero scheduler assignments" % tag)
	_ok(h.get_dispatcher().get_active_count() == 0, "%s: zero live agents" % tag)
	_ok(not h.get_runtime().is_2x(), "%s: speed authority = 1x" % tag)
	_ok(not h.get_runtime().is_terminal_stopped(), "%s: runtime terminal stop cleared" % tag)
	_ok(not h.get_input_controller().is_terminal_stopped(), "%s: input unblocked" % tag)
	_ok(h.get_completion().is_playing(), "%s: terminal result = PLAYING" % tag)

## Deterministic col0->col1->col2 front-to-back drain through the REAL input gate + runtime.
## Places the lowest-index non-empty column's front whenever a slot is free, then ticks until
## every column is exhausted and gameplay is fully quiescent.
func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	var scheduler = h.get_scheduler()
	var agent_layer = h.get_agent_layer()
	for _i in range(MAX_TICKS):
		if slots.rightmost_empty_index() != -1:
			for col in range(h.get_supply().get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(DT)
		if supply.is_exhausted() and scheduler.live_assignment_count() == 0 and not _any_moving(agent_layer):
			# Give the completion authority one settled quiescent tick to latch.
			runtime.tick(DT)
			if h.get_completion().is_terminal():
				break
			# Not yet terminal (still PLAYING) — one extra settle then stop.
			runtime.tick(DT)
			break

func _make_host(drop: int):
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.qa_supply_drop_last = drop
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "production host built (drop=%d) (%s)" % [drop, host.get_build_error()])
	if not ok:
		return null
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
	print("M30 manual playtest smoke: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
