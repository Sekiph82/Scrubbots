extends SceneTree
## M39-C001 V04 Phase A (F-M39-V03-001) — Tornado with selected-color IN-FLIGHT
## work on the REAL production host. Proves the targeted M26/M25/M24/M19 cancel
## seam: same-color in-flight success, unrelated colors untouched, no global
## reset, and exact full pre-state + no charge on a fault at every stage.
## Run: godot --headless --path . -s res://tests/m39_v04_tornado_inflight.gd

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

const DT := 1.0
const MAX_TICKS := 80000
const FAULTS := ["tornado_guard", "tornado_cancel_one", "tornado_claims", "tornado_board",
	"tornado_slots", "tornado_supply", "tornado_finalize"]

var _fail := 0

func _initialize() -> void:
	await _inflight_fault_and_success()
	await _drift_fails_closed()
	await _arrived_fails_closed()
	_done()

# Drive the real runtime with a tiny dt (agents dispatched, not yet arrived)
# until at least two colors have live in-flight assignments at once.
func _load_inflight(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	for _i in range(20000):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(0.02)
		var colors := {}
		for a in h.get_scheduler().assignment_snapshot():
			colors[int(a["color"])] = true
		if colors.size() >= 2:
			return

func _pick_color(h) -> int:
	# Prefer a color with >=2 in-flight assignments while another color is also live.
	var counts := {}
	for a in h.get_scheduler().assignment_snapshot():
		counts[int(a["color"])] = int(counts.get(int(a["color"]), 0)) + 1
	var best := -1
	for c in counts:
		if best == -1 or int(counts[c]) > int(counts[best]):
			best = c
	return best

func _snap(h) -> Dictionary:
	var board = h.get_board()
	var cells: Array = []
	for i in range(board.get_cell_count()):
		cells.append(board.get_cell_state(i))
	var agents: Array = []
	for a in h.get_scheduler().assignment_snapshot():
		var ag = a["agent"]
		agents.append([a["claim_id"], is_instance_valid(ag) and ag.is_inside_tree(),
			h.get_dispatcher().get_agent_for_owner(int(h.get_claim_engine().get_claim(a["claim_id"]).get("owner_id", -1))) == ag])
	var assigns: Array = []
	for a in h.get_scheduler().assignment_snapshot():
		assigns.append([a["claim_id"], a["slot"], a["color"], a["target"]])
	return {
		"cells": cells,
		"slots": h.get_slots().snapshot(),
		"work": h.get_slots().live_work_count(),
		"supply": h.get_supply().debug_snapshot(),
		"claims": h.get_claim_engine().claim_snapshot(),
		"reserved": Array(h.get_reservations().get_reserved_indices()),
		"assigns": assigns,
		"agents": agents,
		"active": h.get_dispatcher().get_active_count(),
	}

func _inflight_fault_and_success() -> void:
	print("[tornado with selected-color in-flight: faults + success]")
	var h = await _make_host()
	if h == null:
		return
	_load_inflight(h)
	var sched = h.get_scheduler()
	var color := _pick_color(h)
	var sel_n = sched.color_assignment_owners(color).size()
	_ok(sel_n >= 1, "selected color %d has %d in-flight assignment(s)" % [color, sel_n])
	var unrelated: Array = []
	for a in sched.assignment_snapshot():
		if int(a["color"]) != color:
			unrelated.append(a)
	_ok(unrelated.size() >= 1, "unrelated colors also in flight (%d)" % unrelated.size())
	_ok(sched.preflight_color_cancel(color), "exact-identity preflight passes on coherent state")

	var econ = h.get_economy()
	var adapter = h.get_booster_adapter()
	var bs = h.get_booster_service()
	econ.boosters.add_charges(BoosterInventory.TORNADO, 10)
	var sb0 = econ.wallet.scrub_bucks()
	var pre = _snap(h)
	for stage in FAULTS:
		adapter.set_fault_injector(func(s): return s == stage)
		var ch = econ.boosters.charges(BoosterInventory.TORNADO)
		var r = bs.apply_tornado(adapter, color)
		_ok(not r["ok"], "%s: tornado fails" % stage)
		_ok(econ.boosters.charges(BoosterInventory.TORNADO) == ch, "%s: no charge consumed" % stage)
		_ok(econ.wallet.scrub_bucks() == sb0, "%s: no SB loss" % stage)
		var post = _snap(h)
		for k in pre:
			_ok(post[k] == pre[k], "%s: exact pre-state restored [%s]" % [stage, k])
	adapter.set_fault_injector(Callable())

	# Success with same-color in flight.
	var sel_agents: Array = []
	for o in sched.color_assignment_owners(color):
		sel_agents.append(sched.get_assignment(o)["agent"])
	var unrelated_agents: Array = []
	for a in unrelated:
		unrelated_agents.append(a["agent"])
	var gen_before = sched._generation
	var disp_gen_before = h.get_dispatcher()._generation
	var r2 = bs.apply_tornado(adapter, color)
	_ok(r2["ok"], "tornado COMMITS with selected-color in-flight work")
	_ok(econ.boosters.charges(BoosterInventory.TORNADO) == 9, "exactly one charge consumed")
	_ok(sched._generation == gen_before and h.get_dispatcher()._generation == disp_gen_before,
		"no global scheduler/dispatcher reset (generations unchanged)")
	_ok(sched.color_assignment_owners(color).is_empty(), "no selected-color assignment remains")
	for c in h.get_claim_engine().claim_snapshot():
		_ok(int(c["color_id"]) != color, "no selected-color claim remains (%s)" % c["claim_id"])
	var board = h.get_board()
	var n_active := 0
	for i in range(board.get_cell_count()):
		if board.get_cell_state(i) == BoardState.CellState.ACTIVE and board.get_color_id(i) == color:
			n_active += 1
	_ok(n_active == 0, "selected-color ACTIVE cells cleared")
	var slot_left := false
	for si in range(h.get_slots().get_slot_count()):
		if h.get_slots().is_occupied(si) and h.get_slots().get_color_id(si) == color:
			slot_left = true
	_ok(not slot_left, "selected-color slots removed")
	var sup_left := false
	for col in h.get_supply().debug_snapshot()["columns"]:
		for b in col:
			if int(b["color_id"]) == color:
				sup_left = true
	_ok(not sup_left, "selected-color supply removed")
	for ag in sel_agents:
		_ok(not is_instance_valid(ag) or ag.is_queued_for_deletion(), "selected-color agent cancelled/freed")
	# Unrelated colors' live work stays exactly intact.
	var after: Array = sched.assignment_snapshot()
	_ok(after.size() == unrelated.size(), "unrelated assignment count preserved (%d)" % after.size())
	for i in range(min(after.size(), unrelated.size())):
		var a = after[i]
		var u = unrelated[i]
		_ok(a["claim_id"] == u["claim_id"] and a["target"] == u["target"] and a["agent"] == u["agent"],
			"unrelated assignment %s intact" % u["claim_id"])
		_ok(h.get_reservations().get_owner(int(a["target"])) != -1, "unrelated reservation intact %s" % u["claim_id"])
	for ag in unrelated_agents:
		_ok(is_instance_valid(ag) and ag.is_inside_tree() and not ag.is_queued_for_deletion(), "unrelated agent alive")
	_ok(h.get_slots().live_work_count() == unrelated.size(), "M24 live work == unrelated claims only")
	_ok(h.get_reservations().get_reservation_count() == unrelated.size(), "reservations == unrelated only")

	# Game continues cleanly afterward (no ghost/double-clear): drive to terminal.
	_drain(h)
	_ok(h.get_completion().is_terminal(), "post-tornado attempt reaches terminal")
	_ok(h.get_reservations().get_reservation_count() == 0, "no leaked reservation at terminal")
	_free_host(h)

func _drift_fails_closed() -> void:
	print("[identity drift -> fail closed, no charge]")
	var h = await _make_host()
	if h == null:
		return
	_load_inflight(h)
	var sched = h.get_scheduler()
	var color := _pick_color(h)
	var owner = sched.color_assignment_owners(color)[0]
	var a = sched.get_assignment(owner)
	# Drift: release the reservation pair behind M25's back.
	h.get_reservations().release(int(a["target"]), int(owner))
	_ok(not sched.preflight_color_cancel(color), "preflight rejects reservation drift")
	var econ = h.get_economy()
	econ.boosters.add_charges(BoosterInventory.TORNADO, 1)
	var pre = _snap(h)
	var r = h.get_booster_service().apply_tornado(h.get_booster_adapter(), color)
	_ok(not r["ok"], "tornado fails closed on drift")
	_ok(econ.boosters.charges(BoosterInventory.TORNADO) == 1, "drift: no charge consumed")
	var post = _snap(h)
	for k in pre:
		_ok(post[k] == pre[k], "drift: zero mutation [%s]" % k)
	_free_host(h)

func _arrived_fails_closed() -> void:
	print("[arrived (pending-clear) selected-color agent -> fail closed]")
	var h = await _make_host()
	if h == null:
		return
	_load_inflight(h)
	var sched = h.get_scheduler()
	var color := _pick_color(h)
	var owner = sched.color_assignment_owners(color)[0]
	# Mark the dispatcher entry arrived (arrival pending authenticated clear).
	h.get_dispatcher()._active[owner]["arrived"] = true
	_ok(not sched.preflight_color_cancel(color), "preflight rejects arrived/pending-clear agent")
	_ok(not h.get_dispatcher().cancel_owner(owner, sched.get_assignment(owner)["agent"]), "cancel_owner refuses arrived")
	h.get_dispatcher()._active[owner]["arrived"] = false
	_ok(not h.get_dispatcher().cancel_owner(owner, null), "cancel_owner refuses mismatched agent")
	_free_host(h)

# --- host driver ---

func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	for _i in range(MAX_TICKS):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(DT)
		if h.get_completion().is_terminal():
			break

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
	_ok(ok, "production host built (%s)" % host.get_build_error())
	if not ok:
		return null
	await process_frame
	await process_frame
	host.get_screen().relayout()
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

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 V04 tornado in-flight evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
