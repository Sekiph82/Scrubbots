extends SceneTree
## M46 — booster-proof scratch slot rebuild FIDELITY (CLAUDE_PEER_REVIEW R06 MAJOR-2, since M39).
## ProductionBoosterAdapter proves Random / Selector on scratch slots rebuilt from the live M24
## engine. The proof (ProofState.from_runtime + ProofKernel) reads each slot's REMAINING robots,
## its WAITING state and its placement SEQUENCE (dispatch order: ascending sequence). The rebuild
## must reproduce exactly that, and must place new batches AFTER every live one. (Peer review:
## under today's first-progress DeadlockClassifier gate the old mismatch could not change a
## verdict; exactness matters for any SOLVE / multi-clear gate built on the same scratch state.)
## Real L1 host, played with feeding to several still moments, at 5 and at 6 slots; plus the
## fail-closed path for a malformed slot and FiveSlotBatchEngine.free_slot_if_idle.
## Run: godot --headless --path . -s res://tests/m46_slot_rebuild.gd

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SlotBatchState = preload("res://scripts/gameplay/slots/slot_batch_state.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const ProductionBoosterAdapter = preload("res://scripts/economy/production_booster_adapter.gd")

const DT := 1.0 / 60.0
var _fail := 0
var _tmp: Array = []
var _waiting_seen := 0
var _runs_done := 0

func _initialize() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	await process_frame
	_runs_done = 0
	await _run(false)
	await _run(true)
	# A script error aborts a run silently; require both to reach their end.
	_ok(_runs_done == 2, "both runs (5 and 6 slots) completed")
	_ok(_waiting_seen > 0, "WAITING slots were present at still moments (%d), so their restoration is exercised" % _waiting_seen)
	_free_slot_if_idle()
	for p in _tmp:
		for f in [p, p + ".bak", p + ".tmp"]:   # AppState's atomic-save companions
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("M46 SLOT REBUILD: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

func _run(sixth: bool) -> void:
	print("[L1 still moments, %d slots]" % (6 if sixth else 5))
	var path := "user://m46_slot_rebuild_%d.save" % (6 if sixth else 5)
	_tmp.append(path)
	var app = AppState.new(path, Callable())
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)
	_ok(h.build(), "host builds L1")
	h.get_runtime().set_process(false)
	await process_frame
	if sixth:
		h.get_economy().wallet.credit("scrub_bucks", 100000)
		_ok(h.get_actions().plus_one_slot().get("ok", false) and h.get_slots().get_slot_count() == 6, "+1 Slot -> 6 slots")
	var a = h.get_booster_adapter()
	if not sixth:
		# Fail closed (full supply at the start): a malformed live slot (remaining 0) is never
		# silently proven as another state.
		var eng = FiveSlotBatchEngine.new()
		var occ = SlotBatchState.make_occupied("M46BAD", 0, 1, 1)
		occ._remaining_to_clear = 0
		eng._slots[0] = occ
		var bad = ProductionBoosterAdapter.new(a._level, a._board, a._supply, eng, null)
		var bid: String = String(a._current_cols()[0][0].get_batch_id())
		_ok(bad._scratch_slots_from_live() == null and bad.detached_copy() == null
			and not bad.propose_random_reorder().get("safe", false) and not bad.is_batch_eligible(bid)
			and bad.eligible_safe_batches().is_empty(),
			"malformed live slot -> scratch rebuild null; detached copy, Random and Selector all fail closed")
	var moments := 0
	var partial := 0
	var waiting := 0
	var exact := true
	var after_live := true
	for r in range(12):
		if h.get_completion().is_terminal():
			break
		# Play a little with taps, then let every robot arrive (a still moment).
		for _i in range(90):
			_feed(h)
			h.get_runtime().tick(DT)
			await process_frame
		for _i in range(6000):
			if h.get_scheduler().live_assignment_count() == 0:
				break
			h.get_runtime().tick(DT)
			await process_frame
		if h.get_scheduler().live_assignment_count() != 0 or h.get_completion().is_terminal():
			continue
		moments += 1
		var live_slots = h.get_slots()
		for s in live_slots.snapshot():
			if s["occupied"] and int(s["remaining_to_clear"]) < int(s["initial_count"]):
				partial += 1
			if s["state"] == SlotBatchState.WAITING:
				waiting += 1
		var scratch = a._scratch_slots_from_live()
		var lp = ProofState.from_runtime(a._level, a._board, a._supply, live_slots)
		var sp = ProofState.from_runtime(a._level, a._board, a._supply, scratch) if scratch != null else null
		var same: bool = sp != null and lp.slots == sp.slots and lp.capacity == sp.capacity
		if not same:
			print("    round %d: live %s\n             scratch %s" % [r, str(lp.slots), str(sp.slots if sp != null else null)])
		exact = exact and same
		# A batch the proof places must dispatch AFTER every live batch (ascending sequence).
		var max_seq := 0
		for i in range(live_slots.get_slot_count()):
			if live_slots.is_occupied(i):
				max_seq = maxi(max_seq, live_slots.get_placement_sequence(i))
		var nxt: bool = scratch != null and scratch._next_sequence > max_seq
		if not nxt:
			print("    round %d: scratch next sequence %s <= live max %d" % [r, str(scratch._next_sequence if scratch != null else null), max_seq])
		after_live = after_live and nxt
	print("    %d still moments, %d partly cleared slot(s), %d WAITING slot(s)" % [moments, partial, waiting])
	_waiting_seen += waiting
	_ok(moments >= 3 and partial > 0, "the run reaches still moments with partly cleared slots (the defect's trigger)")
	_ok(exact, "scratch rebuild == live slots as the proof reads them (remaining, WAITING state, sequence, capacity)")
	_ok(after_live, "a batch placed during the proof gets a later sequence than every live batch")
	_runs_done += 1
	sub.free()

## Selector rollback seam: an untouched ACTIVE slot frees; partial progress / WAITING never do.
func _free_slot_if_idle() -> void:
	print("[FiveSlotBatchEngine.free_slot_if_idle]")
	var eng = FiveSlotBatchEngine.new()
	eng._slots[4] = SlotBatchState.make_occupied("M46A", 1, 5, 1)
	var r: Dictionary = eng.free_slot_if_idle(4)
	_ok(r.get("ok", false) and eng.is_empty(4) and r["batch"]["count"] == 5, "untouched ACTIVE slot frees and returns its batch")
	var part = SlotBatchState.make_occupied("M46B", 1, 5, 2)
	part._remaining_to_clear = 3
	eng._slots[3] = part
	var w = SlotBatchState.make_occupied("M46C", 1, 5, 3)
	w.set_state(SlotBatchState.WAITING)
	eng._slots[2] = w
	_ok(not eng.free_slot_if_idle(3).get("ok", true) and eng.is_occupied(3)
		and not eng.free_slot_if_idle(2).get("ok", true) and eng.is_occupied(2),
		"partly cleared and WAITING slots are never freed")

## Keep empty slots fed from the first available Supply column (player taps).
func _feed(h) -> void:
	var ic = h.get_input_controller()
	for _k in range(6):
		if h.get_slots().rightmost_empty_index() == -1:
			return
		var placed := false
		for c in range(h.get_supply().get_column_count()):
			if ic.activate_front(c).get("ok", false):
				placed = true
				break
		if not placed:
			return

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)
