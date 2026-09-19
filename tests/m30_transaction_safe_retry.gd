extends SceneTree
## M30-C001 V01 — transaction-safe Retry (SB-M30-007, audit §H/§I/§J/§K).
##
## The accepted M26 scheduler teardown is the FIRST destructive gate. This proves the gate's
## ALL-OR-NOTHING contract by forcing the gate to fail/defer/pend/fatal and asserting that
## NOTHING else is reset (no half-old/half-new attempt), then proves stale pre-retry callback
## safety on the real production host.
##
## Failure injection is at the gate BOUNDARY (a scheduler double whose reset contract fails).
## M26 itself is never weakened. The success path (full restore + exact same-supply snapshot
## equivalence) is proven end-to-end in m30_manual_playtest_smoke.
##
## Run: godot --headless --path . -s res://tests/m30_transaction_safe_retry.gd
## Exits 0 on success, 1 on any failure.

const RetryCoordinator = preload("res://scripts/gameplay/completion/retry_coordinator.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
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

# ---- restore-side spies: record if their (forbidden-on-fail) mutator was called ----------
class Spy:
	extends RefCounted
	var touched := false
	func reset() -> void: touched = true            # slots / supply
	func restore_all_active() -> void: touched = true  # board
	func rebuild() -> bool: touched = true; return true  # candidate index
	func refresh_all() -> void: touched = true          # renderer
	func reset_runtime() -> void: touched = true        # runtime
	func set_terminal_stopped(_v: bool) -> void: touched = true  # input
	func reset_attempt() -> void: touched = true        # completion

func _initialize() -> void:
	_test_gate_fail_closed_atomicity()
	_test_gate_success_calls_restore()
	await _test_stale_callback_safety()
	_done()

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
		var spies := _fresh_spies()
		var restored := [false]
		var ok: bool = RetryCoordinator.attempt(_bundle(sch, spies, func(): restored[0] = true))
		_ok(not ok, "FAIL-CLOSED[%s]: retry reports failure" % name)
		for key in ["slots", "supply", "board", "candidate_index", "renderer", "runtime", "input", "completion"]:
			_ok(not spies[key].touched, "FAIL-CLOSED[%s]: %s not reset (no partial attempt)" % [name, key])
		_ok(not restored[0], "FAIL-CLOSED[%s]: on_restored not invoked" % name)
		_ok(not sch.resumed, "FAIL-CLOSED[%s]: scheduler not resumed" % name)

# --- gate success drives the full in-place restore ---------------------------------------
func _test_gate_success_calls_restore() -> void:
	var sch = SchedulerDouble.new()   # all-clean contract
	var spies := _fresh_spies()
	var restored := [false]
	var ok: bool = RetryCoordinator.attempt(_bundle(sch, spies, func(): restored[0] = true))
	_ok(ok, "SUCCESS: clean gate -> retry succeeds")
	for key in ["slots", "supply", "board", "candidate_index", "renderer", "runtime", "input", "completion"]:
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

	# Play until at least one live scheduler assignment exists, capturing its owner id.
	var supply = host.get_supply()
	var slots = host.get_slots()
	var scheduler = host.get_scheduler()
	var dispatcher = host.get_dispatcher()
	var loop = host.get_clearing_loop()
	# The next owner id the dispatcher will mint == the id the first assignment carries
	# (monotonic, never recycled). Captured before play as a real pre-retry owner identity.
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

	# Retry to a fresh attempt.
	_ok(host.retry(), "stale: retry succeeds")
	var active_after: int = host.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)
	var cleared_before: int = loop.get_cleared_count()
	var events := [0]
	host.get_completion().terminal_reached.connect(func(_s, _d): events[0] += 1)

	# Fire a STALE authenticated-clear with the pre-retry owner id + a fabricated agent. The
	# scheduler must ignore an owner with no live assignment (monotonic ids never recycle) —
	# no quota change, no board mutation, no second terminal result.
	loop.authenticated_clear.emit(stale_owner, 0, 0, ScrubbotAgent.new())
	host.get_runtime().tick(1.0)
	_ok(scheduler.live_assignment_count() == 0, "stale: stale clear created no assignment")
	_ok(host.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == active_after, "stale: stale arrival cleared no new board cell")
	_ok(loop.get_cleared_count() == cleared_before, "stale: stale arrival did not advance the clear count")
	_ok(not host.get_completion().is_terminal(), "stale: stale callback emitted no second terminal result")
	_ok(events[0] == 0, "stale: no terminal event from the stale callback")
	sub.free()

func _fresh_spies() -> Dictionary:
	return {"slots": Spy.new(), "supply": Spy.new(), "board": Spy.new(),
		"candidate_index": Spy.new(), "renderer": Spy.new(), "runtime": Spy.new(),
		"input": Spy.new(), "completion": Spy.new()}

func _bundle(sch, spies: Dictionary, on_restored: Callable) -> Dictionary:
	return {"scheduler": sch, "slots": spies["slots"], "supply": spies["supply"],
		"board": spies["board"], "candidate_index": spies["candidate_index"],
		"renderer": spies["renderer"], "runtime": spies["runtime"], "input": spies["input"],
		"completion": spies["completion"], "on_restored": on_restored}

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M30 transaction-safe retry: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
