extends SceneTree
## M30-C001 V02 — transaction-safe Retry (SB-M30-007 + F-M30-V01-002, audit §H/§I/§J/§K + V02 §2/§3).
##
## The accepted M26 scheduler teardown is the FIRST destructive gate, now guarded by a full
## restore-bundle PREFLIGHT and a REQUIRED candidate-rebuild postcondition:
##   - a malformed/missing/incoherent restore dependency fails BEFORE scheduler.reset (zero
##     scheduler.reset calls, nothing mutated);
##   - after a clean gate + board restore, candidate_index.rebuild() must return true AND stay
##     bound to the exact board AND repopulate the full ACTIVE board, or Retry returns false;
##   - every gate-failure mode still fails closed all-or-nothing;
##   - stale pre-retry callbacks cannot mutate the new attempt.
##
## Failure injection is at the boundary (doubles); M26/M13 are never weakened. The real
## end-to-end fresh attempt (incl. M20 observation reset) is proven in m30_manual_playtest_smoke.
##
## Run: godot --headless --path . -s res://tests/m30_transaction_safe_retry.gd
## Exits 0 on success, 1 on any failure.

const RetryCoordinator = preload("res://scripts/gameplay/completion/retry_coordinator.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

var _fail := 0

# ---- gate double: models each M26 reset failure/defer/pend/fatal mode --------------------
class SchedulerDouble:
	extends RefCounted
	var reset_returns := true
	var pending := false
	var succeeded := true
	var fatal := false
	var resumed := false
	var reset_calls := 0
	func reset() -> bool:
		reset_calls += 1
		return reset_returns
	func is_reset_pending() -> bool: return pending
	func last_reset_succeeded() -> bool: return succeeded
	func is_fatal() -> bool: return fatal
	func resume() -> void: resumed = true

# ---- restore-side spy: full preflight method surface + a touched flag --------------------
class Spy:
	extends RefCounted
	var touched := false
	func reset() -> void: touched = true                       # slots / supply
	func reset_runtime() -> void: touched = true               # runtime
	func set_terminal_stopped(_v: bool) -> void: touched = true # input
	func reset_attempt() -> void: touched = true               # completion
	func reset_attempt_observation() -> void: touched = true    # clearing loop

# ---- candidate-index double whose rebuild() fails after a valid preflight -----------------
class RebuildFailIndex:
	extends RefCounted
	var _board
	var rebuild_calls := 0
	func _init(board): _board = board
	func is_bound_to(b) -> bool: return b == _board
	func rebuild() -> bool: rebuild_calls += 1; return false
	func count_candidates(_c) -> int: return 0
	func get_color_ids() -> Array: return []

func _initialize() -> void:
	_test_gate_fail_closed_atomicity()
	_test_preflight_fails_before_teardown()
	_test_rebuild_failure_never_returns_true()
	_test_gate_success_restores()
	await _test_stale_callback_safety()
	_done()

# --- real board + real candidate index; spies for the simple restore collaborators --------
func _real_board(active_cells: int = 4):
	var cells := PackedInt32Array(); cells.resize(active_cells); cells.fill(0)
	var lvl = LevelData.new(1, "m30_retry", "m30_retry", "TEST", active_cells, 1,
		PackedStringArray(["#101010"]), cells)
	return BoardState.from_level_data(lvl)

func _bundle(sch, board, ci, spies: Dictionary, on_restored, renderer = null) -> Dictionary:
	var b := {"scheduler": sch, "slots": spies["slots"], "supply": spies["supply"],
		"board": board, "candidate_index": ci, "runtime": spies["runtime"],
		"input": spies["input"], "completion": spies["completion"],
		"clearing_loop": spies["clearing_loop"], "on_restored": on_restored}
	if renderer != null:
		b["renderer"] = renderer
	return b

func _fresh_spies() -> Dictionary:
	return {"slots": Spy.new(), "supply": Spy.new(), "runtime": Spy.new(),
		"input": Spy.new(), "completion": Spy.new(), "clearing_loop": Spy.new()}

func _all_untouched(spies: Dictionary) -> bool:
	for k in spies.keys():
		if spies[k].touched:
			return false
	return true

# --- H: every gate-failure mode fails closed with zero restore side effects ---------------
func _test_gate_fail_closed_atomicity() -> void:
	var modes := {
		"reset()==false": func(s): s.reset_returns = false,
		"reset pending/deferred": func(s): s.pending = true,
		"prior teardown failed": func(s): s.succeeded = false,
		"fatal bookkeeping": func(s): s.fatal = true,
	}
	for name in modes.keys():
		var sch = SchedulerDouble.new()
		modes[name].call(sch)
		var board = _real_board()
		board.set_cell_state(0, BoardState.CellState.CLEARED)   # detectable pre-retry mutation
		var ci = ColorCandidateIndex.create(); ci.bind(board)
		var spies := _fresh_spies()
		var restored := [false]
		var ok: bool = RetryCoordinator.attempt(_bundle(sch, board, ci, spies, func(): restored[0] = true))
		_ok(not ok, "FAIL-CLOSED[%s]: retry reports failure" % name)
		_ok(_all_untouched(spies), "FAIL-CLOSED[%s]: no restore collaborator touched" % name)
		_ok(board.get_cell_state(0) == BoardState.CellState.CLEARED, "FAIL-CLOSED[%s]: board not restored" % name)
		_ok(not restored[0], "FAIL-CLOSED[%s]: on_restored not invoked" % name)
		_ok(not sch.resumed, "FAIL-CLOSED[%s]: scheduler not resumed" % name)

# --- F-M30-V01-002: preflight rejects a bad restore bundle BEFORE scheduler.reset ---------
func _test_preflight_fails_before_teardown() -> void:
	var board = _real_board()
	var other = _real_board()
	var ci_ok = ColorCandidateIndex.create(); ci_ok.bind(board)
	var ci_wrong = ColorCandidateIndex.create(); ci_wrong.bind(other)

	# (a) candidate index bound to a DIFFERENT board.
	var ba := _bundle(SchedulerDouble.new(), board, ci_wrong, _fresh_spies(), Callable())
	_assert_preflight_rejects("candidate index bound to wrong board", ba)

	# (b) missing required method on a restore collaborator (input lacks set_terminal_stopped).
	var bb := _bundle(SchedulerDouble.new(), board, ci_ok, _fresh_spies(), Callable())
	bb["input"] = RefCounted.new()
	_assert_preflight_rejects("restore collaborator missing required method", bb)

	# (c) supplied renderer not bound to the exact board.
	var bc := _bundle(SchedulerDouble.new(), board, ci_ok, _fresh_spies(), Callable(), _WrongRenderer.new(other))
	_assert_preflight_rejects("supplied renderer not bound to board", bc)

	# (d) supplied-but-invalid restore callback (a non-null, invalid Callable).
	var bd := _bundle(SchedulerDouble.new(), board, ci_ok, _fresh_spies(), _dead_callable())
	_assert_preflight_rejects("invalid restore callback", bd)

func _dead_callable() -> Callable:
	# A non-null Callable bound to a freed object -> is_valid() == false.
	var tmp = RefCounted.new()
	return Callable(tmp, "nonexistent_method")

class _WrongRenderer:
	extends RefCounted
	var _b
	func _init(b): _b = b
	func refresh_all() -> void: pass
	func is_bound_to(b) -> bool: return b == _b

func _assert_preflight_rejects(name: String, bundle: Dictionary) -> void:
	var sch = bundle["scheduler"]
	var spies := {"slots": bundle["slots"], "supply": bundle["supply"], "runtime": bundle["runtime"],
		"input": bundle["input"], "completion": bundle["completion"], "clearing_loop": bundle["clearing_loop"]}
	var ok: bool = RetryCoordinator.attempt(bundle)
	_ok(not ok, "PREFLIGHT[%s]: retry reports failure" % name)
	_ok(sch.reset_calls == 0, "PREFLIGHT[%s]: scheduler.reset called ZERO times (before teardown)" % name)
	# Only spies that expose a touched flag are checked (a swapped-in RefCounted double has none).
	for k in spies.keys():
		if spies[k] is Spy:
			_ok(not spies[k].touched, "PREFLIGHT[%s]: %s not mutated" % [name, k])

# --- F-M30-V01-002 §3: rebuild failure after the gate never returns Retry success ---------
func _test_rebuild_failure_never_returns_true() -> void:
	var sch = SchedulerDouble.new()   # clean gate
	var board = _real_board()
	var ci = RebuildFailIndex.new(board)   # passes preflight (bound), fails rebuild()
	var spies := _fresh_spies()
	var ok: bool = RetryCoordinator.attempt(_bundle(sch, board, ci, spies, Callable()))
	_ok(not ok, "REBUILD-FAIL: retry returns false when candidate rebuild fails")
	_ok(sch.reset_calls == 1, "REBUILD-FAIL: the M26 gate WAS reached (preflight passed)")
	_ok(ci.rebuild_calls == 1, "REBUILD-FAIL: rebuild() was attempted and its false result honored")
	# Post-gate collaborators BEFORE the rebuild check ran (slots/supply reset); runtime/input/
	# completion AFTER the check did NOT (no false fresh-attempt).
	_ok(spies["runtime"].touched == false, "REBUILD-FAIL: runtime NOT reset on rebuild failure")
	_ok(spies["completion"].touched == false, "REBUILD-FAIL: completion NOT reset to PLAYING on rebuild failure")
	_ok(spies["input"].touched == false, "REBUILD-FAIL: input NOT unblocked on rebuild failure")

# --- clean gate + coherent real candidate rebuild -> full restore, returns true -----------
func _test_gate_success_restores() -> void:
	var sch = SchedulerDouble.new()
	var board = _real_board()
	board.set_cell_state(0, BoardState.CellState.CLEARED)   # simulate a partly-cleared attempt
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var spies := _fresh_spies()
	var restored := [false]
	var ok: bool = RetryCoordinator.attempt(_bundle(sch, board, ci, spies, func(): restored[0] = true))
	_ok(ok, "SUCCESS: clean gate + coherent rebuild -> retry succeeds")
	_ok(board.count_cells_by_state(BoardState.CellState.ACTIVE) == board.get_cell_count(), "SUCCESS: board restored to full ACTIVE")
	var total := 0
	for c in ci.get_color_ids():
		total += ci.count_candidates(c)
	_ok(total == board.get_cell_count(), "SUCCESS: candidate index repopulated for the full ACTIVE board")
	_ok(ci.is_bound_to(board), "SUCCESS: candidate index still bound to the exact board")
	for key in ["slots", "supply", "runtime", "input", "completion", "clearing_loop"]:
		_ok(spies[key].touched, "SUCCESS: %s restored" % key)
	_ok(sch.resumed, "SUCCESS: scheduler resumed after teardown")
	_ok(restored[0], "SUCCESS: on_restored invoked once")

# --- K: stale pre-retry callback cannot mutate the new attempt or emit a second result ----
func _test_stale_callback_safety() -> void:
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
	if not host.build():
		_ok(false, "stale: host build")
		sub.free(); return
	await process_frame
	await process_frame
	host.get_screen().relayout()
	await process_frame
	await process_frame
	host.get_runtime().set_process(false)

	var supply = host.get_supply()
	var slots = host.get_slots()
	var scheduler = host.get_scheduler()
	var dispatcher = host.get_dispatcher()
	var loop = host.get_clearing_loop()
	var stale_owner: int = dispatcher.peek_next_owner_id()
	var got_live := false
	for _i in range(4000):
		if slots.rightmost_empty_index() != -1 and supply.get_front(0) != null:
			host.get_input_controller().activate_front(0)
		host.get_runtime().tick(1.0)
		if scheduler.live_assignment_count() > 0:
			got_live = true
			break
	_ok(got_live and stale_owner >= 0, "stale: captured a live pre-retry assignment owner id (%d)" % stale_owner)

	_ok(host.retry(), "stale: retry succeeds")
	var active_after: int = host.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)
	var cleared_before: int = loop.get_cleared_count()
	var events := [0]
	host.get_completion().terminal_reached.connect(func(_s, _d): events[0] += 1)

	var stale_agent = ScrubbotAgent.new()
	loop.authenticated_clear.emit(stale_owner, 0, 0, stale_agent)
	host.get_runtime().tick(1.0)
	_ok(scheduler.live_assignment_count() == 0, "stale: stale clear created no assignment")
	_ok(host.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == active_after, "stale: stale arrival cleared no new board cell")
	_ok(loop.get_cleared_count() == cleared_before, "stale: stale arrival did not advance the clear count")
	_ok(not host.get_completion().is_terminal(), "stale: stale callback emitted no second terminal result")
	_ok(events[0] == 0, "stale: no terminal event from the stale callback")
	stale_agent.free()
	sub.free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M30 transaction-safe retry: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
