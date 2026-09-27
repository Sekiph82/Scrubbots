extends SceneTree
## M52-C001-R02 — dispatch-exhausted early slot release
## (OWNER_SLOT_RELEASE_ON_DISPATCH_EXHAUSTION_V01). Direct assertions against the REAL
## production stack: a batch whose last waiting Scrubby successfully dispatched leaves its
## PHYSICAL slot immediately (M24 draining ledger keyed by immutable batch_id); the slot is
## reusable at once; old arrivals resolve only the old batch and never touch the
## replacement batch in the same physical slot.
##
## Run: godot --headless --path . -s res://tests/m52_r02_early_slot_release.gd

const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")

const DT := 1.0 / 60.0
const C := ["C01", "C02", "C03", "C04", "C05"]

var _fail := 0
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_x1_release_and_reuse()
	_ui_empty_same_cycle()
	_multi_agent_release_and_reuse()
	_five_slots_retire_and_reuse()
	_stale_lane_never_acts_on_replacement()
	_rollback_before_spawn_keeps_slot()
	_retry_with_draining()
	_tornado_with_draining()
	_pause_focus_with_draining()
	_no_early_won()
	_plus_one_slot()
	_level2_blue_x30_unchanged()
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixture ------
## 20x20 stripe level: five vertical 4-wide stripes C01..C05 (80 cells each, all touching
## the bottom row => immediately targetable). TEST fixture only.
func _level() -> Dictionary:
	var cells: Array = []
	for y in range(20):
		for x in range(20):
			cells.append(x / 4)
	return {"version": 1, "id": "r02_stripes", "name": "R02 Stripes", "difficulty": "TEST",
		"width": 20, "height": 20, "palette": ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF"],
		"cells": cells}

## Plan whose column FRONTS are exactly `cols` ([[cid, n], ...] per column); remaining
## per-color totals are appended as <=30 filler batches to column 3 (exact conservation).
func _plan(cols: Array) -> Dictionary:
	var used := {}
	for col in cols:
		for b in col:
			used[b[0]] = int(used.get(b[0], 0)) + int(b[1])
	var all: Array = [cols[0].duplicate(), cols[1].duplicate(), cols[2].duplicate()]
	for cid in C:
		var left: int = 80 - int(used.get(cid, 0))
		while left > 0:
			var n: int = mini(30, left)
			all[2].append([cid, n])
			left -= n
	var out: Array = []
	var k := 0
	for col in all:
		var q: Array = []
		for b in col:
			k += 1
			q.append({"batchId": "R02B%03d" % k, "cid": b[0], "robots": b[1]})
		out.append(q)
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": "r02_stripes", "columnCount": 3,
		"visiblePreviewDepth": 3, "maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": out}

func _host(cols: Array):
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = _write("lvl", JSON.stringify(_level()))
	h.supply_plan_path = _write("plan", JSON.stringify(_plan(cols)))
	get_root().add_child(h)
	_ok(h.build(), "fixture host builds %s" % h.get_build_error())
	h.get_runtime().set_process(false)
	return h

func _click(h, col: int) -> Dictionary:
	return h.get_input_controller().activate_front(col - 1)

func _active(h) -> int:
	return h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)

func _cards(h) -> Array:
	return [h.get_scheduler().live_assignment_count(), h.get_dispatcher().get_active_count(),
		h.get_claim_engine().live_claim_count(), h.get_reservations().get_reservation_count(),
		h.get_slots().live_work_count()]

func _slot(h, i: int) -> Dictionary:
	return h.get_slots().snapshot()[i]

## Let in-flight agents arrive with NO new dispatch (scheduler paused).
func _drain_inflight(h, max_ticks: int = 6000) -> void:
	h.get_scheduler().pause()
	for i in range(max_ticks):
		if h.get_scheduler().live_assignment_count() == 0:
			break
		h.get_runtime().tick(DT)
	h.get_scheduler().resume()

# ------------------------------------------------ B: x1 anti-cross-talk acceptance --
func _x1_release_and_reuse() -> void:
	print("[x1: last departure frees the physical slot; replacement is never touched]")
	var h = _host([[["C01", 1], ["C01", 1]], [["C02", 30]], [["C03", 30]]])
	var slots = h.get_slots()
	var r := _click(h, 1)
	var n: int = int(r["slot"])
	var a_id: String = slots.get_batch_id(n)
	var active0 := _active(h)
	var w: Dictionary = h.get_scheduler().step()
	_ok(w["ok"] and int(w["assigned"]) == 1 and w.get("retired", false), "A x1: its only Scrubby dispatched and M24 retired the batch")
	_ok(slots.is_empty(n) and _slot(h, n)["state"] == "EMPTY", "BEFORE A clears: physical slot %d is EMPTY" % n)
	_ok(_cards(h) == [1, 1, 1, 1, 1], "A still owns one live assignment/agent/claim/reservation/work %s" % str(_cards(h)))
	_ok(_active(h) == active0 and slots.is_draining(a_id) and slots.draining_count() == 1, "board ACTIVE unchanged; A is in the draining ledger")
	_ok(slots.rightmost_empty_index() == n, "rightmost_empty_index sees the released slot")
	var rb := _click(h, 1)
	_ok(rb.get("ok", false) and int(rb["slot"]) == n, "Batch B placed immediately into the SAME physical slot %d" % n)
	var b_id: String = slots.get_batch_id(n)
	var b_before: Dictionary = _slot(h, n)
	_ok(b_id != a_id and b_before["color_id"] == 0 and b_before["remaining_to_clear"] == 1 and b_before["committed"] == 0,
		"B has its own identity (%s != %s) and fresh counters" % [b_id, a_id])
	_drain_inflight(h)
	_ok(_active(h) == active0 - 1 and slots.draining_count() == 0, "A arrived and cleared exactly one cell; A left the draining ledger")
	var b_after: Dictionary = _slot(h, n)
	_ok(b_after == b_before and slots.get_batch_id(n) == b_id, "B remaining/committed/display/state/sequence unchanged; B still in slot %d" % n)
	_ok(_cards(h) == [0, 0, 0, 0, 0], "no claim/reservation/work identity survives or aliases B")
	h.free()

## F: the same runtime/state-sync cycle that dispatches the final Scrubby renders EMPTY.
func _ui_empty_same_cycle() -> void:
	print("[UI shows EMPTY on the same runtime cycle, before the clear]")
	var h = _host([[["C01", 1]], [["C02", 30]], [["C03", 30]]])
	var n: int = int(_click(h, 1)["slot"])
	var rt = h.get_runtime()
	var view = h.get_screen().get_five_slot_strip().get_slot_views()[n]
	_ok(view.is_occupied_view(), "slot view occupied (1 waiting) before the wave")
	var active0 := _active(h)
	rt.tick(rt.get_speed_authority().cadence_interval())   # cadence event + first lane + state sync
	_ok(h.get_scheduler().live_assignment_count() == 1 and _active(h) == active0, "final Scrubby in flight, nothing cleared yet")
	_ok(not view.is_occupied_view() and view.get_state() == "EMPTY", "slot view is EMPTY in that same cycle (no stale 0 tile)")
	h.free()

# ------------------------------------------------ multi-agent draining batch --
func _multi_agent_release_and_reuse() -> void:
	print("[multi-agent draining batch (x3) + same-color replacement]")
	var h = _host([[["C01", 3], ["C01", 5]], [["C02", 30]], [["C03", 30]]])
	var slots = h.get_slots()
	var n: int = int(_click(h, 1)["slot"])
	var a_id: String = slots.get_batch_id(n)
	var active0 := _active(h)
	var retired_at := -1
	for wave in range(3):
		var w: Dictionary = h.get_scheduler().step()
		if w.get("retired", false):
			retired_at = wave
		if wave < 2:
			_ok(slots.is_occupied(n) and slots.get_batch_id(n) == a_id, "wave %d: A still physical (capacity left)" % wave)
	_ok(retired_at == 2 and slots.is_empty(n) and _cards(h) == [3, 3, 3, 3, 3], "third departure retired A: slot EMPTY, 3 of A's Scrubbys in flight")
	_ok(slots.draining_snapshot()[0]["remaining_to_clear"] == 3 and slots.draining_snapshot()[0]["committed"] == 3, "draining A: remaining 3, committed 3")
	_ok(int(_click(h, 1)["slot"]) == n, "same-color Batch B (x5) reuses slot %d immediately" % n)
	var b_before: Dictionary = _slot(h, n)
	_drain_inflight(h)
	_ok(_active(h) == active0 - 3 and slots.draining_count() == 0, "all three A arrivals resolved against A only")
	_ok(_slot(h, n) == b_before and b_before["remaining_to_clear"] == 5 and b_before["committed"] == 0, "same-color B untouched (5 remaining, 0 committed)")
	h.free()

func _five_slots_retire_and_reuse() -> void:
	print("[five slots each retire and are reused while older agents fly]")
	var h = _host([[["C01", 1], ["C04", 1], ["C02", 1], ["C05", 1]], [["C02", 1], ["C05", 1], ["C03", 1], ["C01", 1]], [["C03", 1], ["C04", 1], ["C05", 1]]])
	var slots = h.get_slots()
	for c in [1, 2, 3, 1, 2]:
		_click(h, c)
	_ok(slots.occupied_count() == 5, "five x1 batches occupy all five slots")
	var w: Dictionary = h.get_scheduler().step()
	_ok(int(w["assigned"]) == 5 and slots.occupied_count() == 0 and slots.draining_count() == 5, "one wave: five departures, all five slots EMPTY, five draining batches")
	var ok_place := true
	for c in [3, 1, 2, 3, 1]:
		ok_place = ok_place and _click(h, c).get("ok", false)
	_ok(ok_place and slots.occupied_count() == 5, "five replacement batches placed while the five old Scrubbys fly")
	var before: Array = slots.snapshot()
	_drain_inflight(h)
	_ok(slots.draining_count() == 0 and slots.snapshot() == before, "all old arrivals resolved; every replacement batch unchanged")
	_ok(_cards(h) == [0, 0, 0, 0, 0], "cardinalities all zero afterwards")
	h.free()

## E: a lane queued for batch X never dispatches a replacement batch in the same slot.
func _stale_lane_never_acts_on_replacement() -> void:
	print("[stale wave lane cannot act on a replacement batch]")
	var h = _host([[["C01", 4], ["C04", 2]], [["C02", 4]], [["C03", 4]]])
	var slots = h.get_slots()
	var sch = h.get_scheduler()
	var n: int = int(_click(h, 1)["slot"])
	_click(h, 2)
	_ok(sch.pending_lane_count() == 2, "two lanes queued (placement wakes), each pinned to its batch id")
	var purged: Dictionary = slots.purge_uncommitted_slot(n)
	_ok(purged.get("ok", false) and slots.is_empty(n), "lane's original batch removed from slot %d before its lane ran" % n)
	# Place the replacement straight through M24 (same seam the input uses) WITHOUT a new
	# placement lane, so only the stale lane pinned to the old batch could act on slot n.
	_ok(int(slots.select_front_batch(h.get_supply(), 0).get("slot", -1)) == n, "replacement batch placed into slot %d mid-wave" % n)
	var repl_id: String = slots.get_batch_id(n)
	while sch.has_pending_lanes():
		sch.step_lane()
	_ok(slots.get_batch_id(n) == repl_id and _slot(h, n)["committed"] == 0, "the old lane did NOT dispatch from the replacement batch")
	_ok(sch.live_assignment_count() == 1, "only the other slot's pinned lane dispatched")
	h.free()

func _rollback_before_spawn_keeps_slot() -> void:
	print("[rollback before a successful spawn does NOT release the slot]")
	var h = _host([[["C01", 1]], [["C02", 30]], [["C03", 30]]])
	var slots = h.get_slots()
	var n: int = int(_click(h, 1)["slot"])
	var origin: Vector2 = h.get_origin_provider().origin_for_slot(n)
	var access = ProductionTargetAccess.new(ProductionRoutingSystem.new(), ProductionAccessQuery.new(h.get_board()), h.get_board(), origin)
	var c: Dictionary = h.get_claim_engine().claim_for_slot(n, access)
	_ok(c["ok"] and slots.get_capacity(n) == 0 and slots.is_occupied(n) and slots.draining_count() == 0, "claim committed (capacity 0) but no dispatch: slot stays occupied")
	_ok(h.get_claim_engine().rollback_claim(c["claim_id"]) and slots.get_capacity(n) == 1 and slots.is_occupied(n), "rollback restores capacity 1 in the same physical slot")
	# Scheduler dispatch-failure path: an unroutable origin rolls the claim back, no release.
	var r: Dictionary = h.get_slots().confirm_departed("no_such_work")
	_ok(not r.get("ok", true), "confirm_departed fails closed for an unknown work id")
	h.free()

# ------------------------------------------------------ D: Retry / Tornado --
func _retry_with_draining() -> void:
	print("[Retry with draining + replacement batches = clean reset]")
	var h = _host([[["C01", 1], ["C01", 2]], [["C02", 30]], [["C03", 30]]])
	var slots = h.get_slots()
	_click(h, 1)
	h.get_scheduler().step()
	_click(h, 1)
	h.get_scheduler().step()
	_ok(slots.draining_count() >= 1 and h.get_scheduler().live_assignment_count() >= 2, "draining batch + replacement in flight before Retry")
	_ok(h.retry(), "Retry succeeds")
	_ok(_cards(h) == [0, 0, 0, 0, 0] and slots.draining_count() == 0 and slots.occupied_count() == 0 \
		and slots.get_slot_count() == 5 and _active(h) == h.get_board().get_cell_count(), "zero ghosts: no draining, no work, empty five slots, full board")
	h.free()

func _tornado_with_draining() -> void:
	print("[Tornado with draining selected-color batches: atomic + coherent]")
	for fault in ["tornado_slots", "tornado_supply", "tornado_finalize", ""]:
		var h = _host([[["C01", 1], ["C01", 4]], [["C02", 30]], [["C03", 30]]])
		var slots = h.get_slots()
		_click(h, 1)
		h.get_scheduler().step()                       # A C01 x1 -> draining
		_click(h, 1)                                   # B C01 x4 reuses the slot
		h.get_scheduler().step()                       # B dispatches one
		_click(h, 2)                                   # unrelated C02 batch
		var pre_slots: Array = slots.snapshot()
		var pre_drain: Array = slots.draining_snapshot()
		var pre_cards := _cards(h)
		var pre_active := _active(h)
		h.get_economy().boosters.add_charges(BoosterInventory.TORNADO, 1)
		var adapter = h.get_booster_adapter()
		adapter.set_fault_injector(func(s): return s == fault)
		var r: Dictionary = h.get_actions().tornado(0)
		adapter.set_fault_injector(Callable())
		var ev = CompletionEvaluator.new()
		var coherent: bool = not ev.has_fatal_inconsistency(h.get_scheduler(), h.get_dispatcher(), h.get_claim_engine(), h.get_reservations(), slots)
		if fault != "":
			_ok(not r.get("ok", false) and slots.snapshot() == pre_slots and slots.draining_snapshot() == pre_drain and _cards(h) == pre_cards and _active(h) == pre_active and coherent,
				"fault at %s: exact pre-state restored (slots, draining ledger, 5 cardinalities, board)" % fault)
		else:
			_ok(r.get("ok", false) and slots.draining_count() == 0 and h.get_scheduler().color_assignment_owners(0).is_empty() and coherent,
				"Tornado commits: draining C01 purged, no C01 work survives, cardinalities coherent %s" % str(_cards(h)))
			var c02_ok := false
			for s in slots.snapshot():
				if s["occupied"] and s["color_id"] == 1:
					c02_ok = s["remaining_to_clear"] == 30
			_ok(c02_ok, "unrelated C02 batch untouched")
		h.free()

func _pause_focus_with_draining() -> void:
	print("[pause/focus with draining agents]")
	var h = _host([[["C01", 1]], [["C02", 30]], [["C03", 30]]])
	var rt = h.get_runtime()
	_click(h, 1)
	h.get_scheduler().step()
	var pos := _positions(h)
	rt.set_user_paused(true)
	for i in range(120):
		rt.tick(DT)
	_ok(_positions(h) == pos and h.get_slots().draining_count() == 1, "paused: draining agent frozen, ledger intact")
	rt.set_user_paused(false)
	rt.notify_focus_lost()
	for i in range(120):
		rt.tick(DT)
	_ok(_positions(h) == pos, "focus lost: draining agent frozen")
	rt.notify_focus_gained()
	h.get_scheduler().pause()
	for i in range(3000):
		rt.tick(DT)
		if h.get_slots().draining_count() == 0:
			break
	_ok(h.get_slots().draining_count() == 0 and not h.get_completion().is_error(), "resumed: draining batch resolved, no ERROR")
	h.free()

func _positions(h) -> Array:
	var out: Array = []
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent:
			out.append(c.position)
	return out

## Freeing the final visible slot early must never cause an early WON.
func _no_early_won() -> void:
	print("[no early WON while a draining batch is in flight]")
	var h = _host([[["C01", 1]], [["C02", 30]], [["C03", 30]]])
	_click(h, 1)
	h.get_scheduler().step()
	var ev = CompletionEvaluator.new()
	_ok(h.get_slots().occupied_count() == 0 and not ev.is_quiescent(h.get_scheduler(), h.get_dispatcher(), h.get_claim_engine(), h.get_reservations(), h.get_slots()),
		"all physical slots EMPTY but not quiescent (draining work in flight)")
	_ok(h.get_completion().on_tick() == CompletionEvaluator.PLAYING, "completion stays PLAYING")
	h.free()

func _plus_one_slot() -> void:
	print("[+1 Slot: six lanes retire/reuse; Retry returns to five]")
	var h = _host([[["C01", 1], ["C04", 1], ["C02", 1]], [["C02", 1], ["C05", 1], ["C03", 1]], [["C03", 1], ["C04", 1]]])
	h.get_economy().boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
	_ok(h.activate_plus_one_slot(), "+1 Slot active")
	for c in [1, 2, 3, 1, 2, 3]:
		_click(h, c)
	var w: Dictionary = h.get_scheduler().step()
	_ok(int(w["assigned"]) == 6 and h.get_slots().occupied_count() == 0 and h.get_slots().draining_count() == 6, "six x1 lanes dispatched and retired; six slots EMPTY")
	_ok(_click(h, 1).get("ok", false) and h.get_slots().occupied_count() == 1, "a released slot is reusable under +1 Slot")
	_ok(h.retry() and h.get_slots().get_slot_count() == 5 and h.get_slots().draining_count() == 0, "Retry returns to five slots with no draining ledger")
	h.free()

## R01 rule preserved: five BLUE x30 lanes do not retire (capacity remains).
func _level2_blue_x30_unchanged() -> void:
	print("[R01 five BLUE x30 unchanged: no early release while Scrubbys still wait]")
	var app = AppState.new(_uniq("l2"))
	app.progression.record_win(1)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	get_root().add_child(h)
	h.build()
	h.get_runtime().set_process(false)
	for c in [1, 2, 3, 1, 2]:
		_click(h, c)
	var w: Dictionary = h.get_scheduler().step()
	var disp: Array = []
	for s in h.get_slots().snapshot():
		disp.append(int(s["remaining_to_clear"]) - int(s["committed"]))
	_ok(int(w["assigned"]) == 5 and disp == [29, 29, 29, 29, 29] and h.get_slots().occupied_count() == 5 and h.get_slots().draining_count() == 0,
		"five lanes, displays 29, all five still physical")
	h.free()

# ------------------------------------------------------------------- infra -----
func _write(tag: String, text: String) -> String:
	var p := "user://r02_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _uniq(tag: String) -> String:
	var p := "user://r02_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	if _fail == 0:
		print("M52 R02 EARLY SLOT RELEASE: PASS")
		quit(0)
	else:
		print("M52 R02 EARLY SLOT RELEASE: FAIL (%d)" % _fail)
		quit(1)
