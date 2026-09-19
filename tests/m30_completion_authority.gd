extends SceneTree
## M30-C001 V01 — completion authority truth (SB-M30-001..004, audit §B/§C/§D/§E/§G).
##
## Proves the read-only CompletionEvaluator + CompletionController terminal policy WITHOUT
## duplicating M27 proof logic:
##   B WIN truth   — WON only when board ACTIVE==0 AND every authority quiescent; a live
##                   in-flight final transaction blocks an early WIN.
##   C LOSE truth  — LOST only from a REAL M27 DeadlockClassifier DEADLOCK at quiescence;
##                   WAITING/STALLED/PROGRESSABLE/UNKNOWN_BOUND/in-flight are never LOST.
##   D exact-once  — terminal latches at most once, one event, no WON<->LOST flip, Retry
##                   arms a fresh latch.
##   E blocking    — (covered end-to-end in m30_manual_playtest_smoke) here: terminal state
##                   makes on_tick/notify_event inert.
##   G event-gate  — the expensive proof is dirty/event-gated; idle ticks never re-run it.
##
## Run: godot --headless --path . -s res://tests/m30_completion_authority.gd
## Exits 0 on success, 1 on any failure.

const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const CompletionController = preload("res://scripts/gameplay/completion/completion_controller.gd")
const DeadlockClassifier = preload("res://scripts/gameplay/solver/deadlock_classifier.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")

var _fail := 0

# ---- lightweight engine count doubles (cheap-truth axis only; real classifier used live) --
class FakeCounter:
	extends RefCounted
	var n := 0
	var fatal := false
	func live_assignment_count() -> int: return n
	func get_active_count() -> int: return n
	func live_claim_count() -> int: return n
	func get_reservation_count() -> int: return n
	func live_work_count() -> int: return n
	func is_fatal() -> bool: return fatal

class FakeBoard:
	extends RefCounted
	var active := 0
	func count_cells_by_state(_s) -> int: return active

class StubClassifier:
	extends RefCounted
	var status
	var calls := 0
	func classify_runtime(_l, _b, _s, _sl, _if := 0, _c := {}) -> Dictionary:
		calls += 1
		return {"status": status, "reason": "stub"}

func _initialize() -> void:
	_test_win_truth()
	_test_cross_engine_consistency()
	_test_lose_mapping_no_duplication()
	_test_real_classifier_deadlock()
	_test_exact_once_latch()
	_test_event_driven_gate()
	_done()

# --- F-M30-V01-001: full cross-engine cardinality guard ----------------------------------
func _test_cross_engine_consistency() -> void:
	var ev = CompletionEvaluator.new()
	var bd = FakeBoard.new(); bd.active = 9   # non-empty so no WON short-circuit
	# Healthy all-equal-positive N -> legitimate in-flight, PLAYING (never ERROR).
	for n in [1, 2, 5]:
		var e := _counters(n, n, n, n, n)
		var r: Dictionary = ev.evaluate(bd, e[0], e[1], e[2], e[3], e[4], null, null, true)
		_ok(r["status"] == CompletionEvaluator.PLAYING and r["reason"] == "in_flight_work",
			"consistency: all five == %d -> legitimate in-flight PLAYING" % n)
	# Each single-axis drift (one authority off by one) -> ERROR, never LOST/indefinite PLAYING.
	var axes := ["scheduler", "dispatcher", "claim", "reservation", "M24 committed"]
	for i in range(5):
		var vals := [1, 1, 1, 1, 1]
		vals[i] = 2   # drift exactly one authority
		var e := _counters(vals[0], vals[1], vals[2], vals[3], vals[4])
		var r: Dictionary = ev.evaluate(bd, e[0], e[1], e[2], e[3], e[4], null, null, true)
		_ok(r["status"] == CompletionEvaluator.ERROR, "consistency: %s drift -> ERROR" % axes[i])
		_ok(r["status"] != CompletionEvaluator.LOST, "consistency: %s drift is NEVER LOST" % axes[i])
	# Orphan-from-zero drift examples from the audit (e.g. sched=0,disp=0,claim=1) -> ERROR,
	# not an indefinite PLAYING/in_flight_work.
	for i in range(5):
		var vals := [0, 0, 0, 0, 0]
		vals[i] = 1
		var e := _counters(vals[0], vals[1], vals[2], vals[3], vals[4])
		var r: Dictionary = ev.evaluate(bd, e[0], e[1], e[2], e[3], e[4], null, null, true)
		_ok(r["status"] == CompletionEvaluator.ERROR, "consistency: lone %s orphan -> ERROR (not indefinite PLAYING)" % axes[i])
	# All-zero is quiescent, not ERROR (routes to deadlock proof at a non-empty board).
	var z := _counters(0, 0, 0, 0, 0)
	var stub = StubClassifier.new(); stub.status = DeadlockClassifier.STALLED
	var evz = CompletionEvaluator.new(stub)
	var rz: Dictionary = evz.evaluate(bd, z[0], z[1], z[2], z[3], z[4], null, null, true)
	_ok(rz["status"] == CompletionEvaluator.PLAYING, "consistency: all-zero is quiescent (not ERROR)")

func _counters(a: int, b: int, c: int, d: int, e: int) -> Array:
	var s = FakeCounter.new(); s.n = a
	var di = FakeCounter.new(); di.n = b
	var cl = FakeCounter.new(); cl.n = c
	var rv = FakeCounter.new(); rv.n = d
	var sl = FakeCounter.new(); sl.n = e
	return [s, di, cl, rv, sl]

# --- B: WIN truth ------------------------------------------------------------------------
func _test_win_truth() -> void:
	var ev = CompletionEvaluator.new()
	var sch = FakeCounter.new(); var disp = FakeCounter.new(); var clm = FakeCounter.new()
	var res = FakeCounter.new(); var slt = FakeCounter.new(); var bd = FakeBoard.new()
	# All quiescent + board empty -> WON.
	bd.active = 0
	_ok(ev.is_won(bd, sch, disp, clm, res, slt), "WIN: board ACTIVE==0 + all authorities quiescent -> won")
	var r0: Dictionary = ev.evaluate(bd, sch, disp, clm, res, slt, null, null, true)
	_ok(r0["status"] == CompletionEvaluator.WON, "WIN: evaluate latches WON at cleared+quiescent")
	# Board empty but a final robot still in flight (dispatcher active) -> NOT won (no early WIN).
	disp.n = 1
	_ok(not ev.is_won(bd, sch, disp, clm, res, slt), "WIN: cleared board but a live in-flight robot -> NOT won (no early WIN)")
	var r1: Dictionary = ev.evaluate(bd, sch, disp, clm, res, slt, null, null, true)
	_ok(r1["status"] == CompletionEvaluator.ERROR, "WIN: dispatcher/scheduler count divergence -> fail-closed ERROR (not WON/LOST)")
	disp.n = 0
	# Board non-empty but every authority quiescent, dispatcher matches -> not WON.
	bd.active = 5
	_ok(not ev.is_won(bd, sch, disp, clm, res, slt), "WIN: non-empty board is never WON")
	# Each authority independently blocks WIN.
	for setter in ["sch", "clm", "res", "slt"]:
		bd.active = 0
		sch.n = 0; clm.n = 0; res.n = 0; slt.n = 0
		match setter:
			"sch": sch.n = 1
			"clm": clm.n = 1
			"res": res.n = 1
			"slt": slt.n = 1
		# scheduler count must still equal dispatcher count to isolate the quiescence axis
		# from the cross-engine ERROR guard: mirror onto dispatcher for the scheduler case.
		disp.n = sch.n
		_ok(not ev.is_won(bd, sch, disp, clm, res, slt), "WIN: %s live work blocks WON" % setter)
	sch.n = 0; disp.n = 0; clm.n = 0; res.n = 0; slt.n = 0
	# Fatal M26 bookkeeping at a cleared board -> ERROR, never WON.
	sch.fatal = true
	var rf: Dictionary = ev.evaluate(bd, sch, disp, clm, res, slt, null, null, true)
	_ok(rf["status"] == CompletionEvaluator.ERROR, "WIN: M26 fatal at cleared board -> ERROR (fail closed, not WON)")

# --- C: LOSE mapping via injected classifier (no M27 duplication) ------------------------
func _test_lose_mapping_no_duplication() -> void:
	var sch = FakeCounter.new(); var disp = FakeCounter.new(); var clm = FakeCounter.new()
	var res = FakeCounter.new(); var slt = FakeCounter.new(); var bd = FakeBoard.new()
	bd.active = 4   # quiescent but board not empty -> the only path that may LOSE
	for pair in [[DeadlockClassifier.PROGRESSABLE, false], [DeadlockClassifier.STALLED, false],
			[DeadlockClassifier.UNKNOWN_BOUND, false], [DeadlockClassifier.DEADLOCK, true]]:
		var stub = StubClassifier.new(); stub.status = pair[0]
		var ev = CompletionEvaluator.new(stub)
		var r: Dictionary = ev.evaluate(bd, sch, disp, clm, res, slt, null, null, true)
		var expect_lost: bool = pair[1]
		var got_lost: bool = r["status"] == CompletionEvaluator.LOST
		_ok(got_lost == expect_lost, "LOSE map: %s -> %s" % [pair[0], ("LOST" if expect_lost else "PLAYING")])
		if not expect_lost:
			_ok(r["status"] == CompletionEvaluator.PLAYING, "LOSE map: %s stays PLAYING (never LOST)" % pair[0])
	# Healthy in-flight (all five cardinalities equal-positive) never reaches the proof ->
	# PLAYING, classifier untouched.
	var stub2 = StubClassifier.new(); stub2.status = DeadlockClassifier.DEADLOCK
	var ev2 = CompletionEvaluator.new(stub2)
	sch.n = 1; disp.n = 1; clm.n = 1; res.n = 1; slt.n = 1
	var ri: Dictionary = ev2.evaluate(bd, sch, disp, clm, res, slt, null, null, true)
	_ok(ri["status"] == CompletionEvaluator.PLAYING, "LOSE: a healthy in-flight transaction is never LOST (classifier not consulted)")
	_ok(stub2.calls == 0, "LOSE: no proof runs while in-flight work exists")

# --- C: real M27 DeadlockClassifier proves a real DEADLOCK -> LOST -----------------------
func _test_real_classifier_deadlock() -> void:
	var sch = FakeCounter.new(); var disp = FakeCounter.new(); var clm = FakeCounter.new()
	var res = FakeCounter.new()
	# Real 2x2 single-colour board, all ACTIVE; real EMPTY supply; real empty slots. The real
	# FiveSlotBatchEngine doubles as the quiescence source (live_work_count()==0) AND the
	# ProofState slots source (is_occupied()) the real M27 classifier reconstructs from.
	var cells := PackedInt32Array([0, 0, 0, 0])
	var lvl = LevelData.new(1, "m30_dl", "m30_dl", "TEST", 2, 2, PackedStringArray(["#101010"]), cells)
	var board = BoardState.from_level_data(lvl)
	var empty_supply = BatchSupplyEngine.create(3, 3)
	empty_supply.load_columns([[], [], []])
	var slots = FiveSlotBatchEngine.new()
	var ev = CompletionEvaluator.new()   # REAL M27 classifier
	var r: Dictionary = ev.evaluate(board, sch, disp, clm, res, slots, lvl, empty_supply, true)
	_ok(r["status"] == CompletionEvaluator.LOST, "LOSE: real M27 proves empty-supply/non-empty-board DEADLOCK -> LOST")
	_ok(r.get("classifier", {}).get("status", &"") == DeadlockClassifier.DEADLOCK, "LOSE: LOST carries the real DEADLOCK classifier result")
	# Same board WITH matching supply -> STALLED (future placement) -> PLAYING (never LOST).
	var ok_supply = BatchSupplyEngine.create(3, 3)
	ok_supply.load_columns([[ColorBatch.make("B0", 0, 4, 1)], [], []])
	var r2: Dictionary = ev.evaluate(board, sch, disp, clm, res, slots, lvl, ok_supply, true)
	_ok(r2["status"] == CompletionEvaluator.PLAYING, "LOSE: a legal future placement (STALLED) is never LOST")

# --- D: exact-once terminal latch --------------------------------------------------------
func _test_exact_once_latch() -> void:
	var stub = StubClassifier.new(); stub.status = DeadlockClassifier.DEADLOCK
	var ev = CompletionEvaluator.new(stub)
	var sch = FakeCounter.new(); var disp = FakeCounter.new(); var clm = FakeCounter.new()
	var res = FakeCounter.new(); var slt = FakeCounter.new(); var bd = FakeBoard.new()
	bd.active = 4
	var dummy = RefCounted.new()   # stub classifier ignores level/supply; bind only needs non-null
	var ctrl = CompletionController.new()
	_ok(ctrl.bind(ev, bd, sch, disp, clm, res, slt, dummy, dummy), "exact-once: controller binds")
	_ok(ctrl.get_state() == CompletionEvaluator.PLAYING, "exact-once: begins PLAYING")
	var events := [0]
	ctrl.terminal_reached.connect(func(_s, _d): events[0] += 1)
	ctrl.on_tick()
	_ok(ctrl.is_lost(), "exact-once: latches LOST at quiescence + DEADLOCK")
	_ok(events[0] == 1, "exact-once: exactly one terminal event emitted")
	# Further ticks/events cannot emit a second event or flip the result.
	ctrl.notify_event(); ctrl.on_tick(); ctrl.on_tick()
	stub.status = DeadlockClassifier.PROGRESSABLE  # even if truth "changed", terminal is frozen
	ctrl.on_tick()
	_ok(events[0] == 1, "exact-once: later ticks/events emit no duplicate terminal event")
	_ok(ctrl.is_lost(), "exact-once: terminal result never flips (LOST stays LOST)")
	# Retry arms a fresh latch.
	ctrl.reset_attempt()
	_ok(ctrl.get_state() == CompletionEvaluator.PLAYING, "exact-once: reset_attempt restores PLAYING")
	stub.status = DeadlockClassifier.DEADLOCK
	ctrl.on_tick()
	_ok(ctrl.is_lost() and events[0] == 2, "exact-once: fresh attempt latches again exactly once")

# --- G: dirty/event-driven proof gate ----------------------------------------------------
func _test_event_driven_gate() -> void:
	var stub = StubClassifier.new(); stub.status = DeadlockClassifier.STALLED  # non-terminal
	var ev = CompletionEvaluator.new(stub)
	var sch = FakeCounter.new(); var disp = FakeCounter.new(); var clm = FakeCounter.new()
	var res = FakeCounter.new(); var slt = FakeCounter.new(); var bd = FakeBoard.new()
	bd.active = 4   # quiescent, non-empty -> proof would run only if dirty
	var dummy = RefCounted.new()
	var ctrl = CompletionController.new()
	ctrl.bind(ev, bd, sch, disp, clm, res, slt, dummy, dummy)
	# First tick is dirty (fresh attempt) -> one proof.
	ctrl.on_tick()
	_ok(stub.calls == 1, "gate: first quiescent tick runs the proof once")
	# Many idle ticks with NO event -> no further proof (dirty cleared by the non-terminal proof).
	for _i in range(50):
		ctrl.on_tick()
	_ok(stub.calls == 1, "gate: 50 idle ticks with no event never re-run the proof")
	# A meaningful event re-arms exactly one proof.
	ctrl.notify_event()
	ctrl.on_tick(); ctrl.on_tick()
	_ok(stub.calls == 2, "gate: one event re-arms exactly one proof, not per-frame")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M30 completion authority: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
