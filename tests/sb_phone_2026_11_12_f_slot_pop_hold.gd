extends SceneTree
## SB-PHONE-2026-11-12-F (owner 2026-11-12): a slot whose batch is used up takes no new supply
## pick until its finish pop (BoosterVfx pop_batch: lift + burst + stars, preset C 1.60 s) is
## over; other empty slots stay usable. Direct assertions on the REAL production host stack
## (input gate -> M24 placement), driven by the runtime clock at a fixed 1/60 s:
##   - finished slot is EMPTY truth but rejects picks during the pop, takes them right after;
##     the hold ends on the same tick the pop leaves the overlay (never longer than shown);
##   - another empty slot takes a pick during the pop;
##   - every empty slot finishing -> "slots_full": no spawn, supply untouched, nothing queued;
##   - Reduced Effects: no pop -> no hold; switched on mid-pop -> hold released;
##   - cannot stick: pause / terminal stop keep the clock running, reset() clears holds;
##   - +1 Slot: the sixth slot holds the same way.
## Run: godot --headless --path . -s res://tests/sb_phone_2026_11_12_f_slot_pop_hold.gd

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")

const DT := 1.0 / 60.0
const C := ["C01", "C02", "C03", "C04", "C05"]

var _fail := 0
var _cases := 0
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_hold_then_accept()
	_other_slot_usable()
	_all_finishing_no_spawn()
	_reduced_effects()
	_cannot_stick()
	_sixth_slot()
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	print("SB-PHONE-2026-11-12-F SLOT POP HOLD: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _cases - _fail, _cases, _fail])
	quit(0 if _fail == 0 else 1)

# ------------------------------------------------------------------ fixture ------
## 20x20 stripes C01..C05 (80 cells each, all touching the bottom row). TEST fixture only.
func _level() -> Dictionary:
	var cells: Array = []
	for y in range(20):
		for x in range(20):
			cells.append(x / 4)
	return {"version": 1, "id": "f_stripes", "name": "F Stripes", "difficulty": "TEST",
		"width": 20, "height": 20, "palette": ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF"],
		"cells": cells}

## Column fronts are `cols` ([[cid, n], ...]); per-colour remainders go to column 3 (conservation).
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
			q.append({"batchId": "FB%03d" % k, "cid": b[0], "robots": b[1]})
		out.append(q)
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": "f_stripes", "columnCount": 3,
		"visiblePreviewDepth": 3, "maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": out}

func _write(tag: String, text: String) -> String:
	var p := "user://sbf_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

## Many x1 batches in every column so a slot finishes one wave after its pick.
func _host():
	var ones: Array = []
	for cid in C:
		ones.append([cid, 1])
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = _write("lvl", JSON.stringify(_level()))
	h.supply_plan_path = _write("plan", JSON.stringify(_plan([ones, ones.duplicate(), ones.duplicate()])))
	get_root().add_child(h)
	_ok(h.build(), "fixture host builds %s" % h.get_build_error())
	h.get_runtime().set_process(false)
	h.get_screen().get_booster_vfx().set_process(false)   # stepped in lock-step with the runtime
	return h

func _click(h, col: int) -> Dictionary:
	return h.get_input_controller().activate_front(col - 1)

## One frame: runtime clock + the pop overlay, same delta (as on a phone).
func _tick(h) -> void:
	h.get_runtime().tick(DT)
	h.get_screen().get_booster_vfx()._process(DT)

## Tick until `slot` is finish-held (its batch finished and its pop started). Returns ticks.
func _until_held(h, slot: int, cap: int = 600) -> int:
	for i in range(cap):
		if h.get_slots().is_finish_held(slot):
			return i
		_tick(h)
	return -1

# ------------------------------------------------------------------ cases --------
func _hold_then_accept() -> void:
	print("[finished slot rejects picks during its pop, accepts right after]")
	var h = _host()
	var slots = h.get_slots()
	var vfx = h.get_screen().get_booster_vfx()
	var pop: float = vfx.pop_duration()
	_ok(is_equal_approx(pop, 1.60), "default pop preset C = 1.60 s (%.2f)" % pop)
	var r := _click(h, 1)
	_ok(r.get("ok", false) and int(r["slot"]) == 4, "first pick lands in the rightmost slot 4")
	_ok(_until_held(h, 4) >= 0, "slot 4's x1 batch finished: slot held")
	_ok(slots.is_empty(4) and vfx.pop_count() == 1, "held slot is EMPTY truth and its pop is playing")
	_ok(slots.rightmost_empty_index() == 3, "placement skips the held slot (rightmost free = 3)")
	var supply_before: Array = h.get_supply().player_snapshot()
	var n := 0
	var rejected_all := true
	while slots.is_finish_held(4) and n < 200:
		_tick(h)
		n += 1
		if slots.is_finish_held(4) and (slots.rightmost_empty_index() == 4 or vfx.pop_count() == 0):
			rejected_all = false
	_ok(rejected_all, "slot 4 never offered for a pick while held, and never held without its pop on screen")
	_ok(absf(n * DT - pop) <= DT + 0.0001, "hold lasted %d ticks = %.3f s (pop %.2f s)" % [n, n * DT, pop])
	_ok(vfx.pop_count() == 0, "hold released on the same tick the pop left the overlay")
	_ok(h.get_supply().player_snapshot() == supply_before, "no pick consumed while waiting")
	var r2 := _click(h, 2)
	_ok(r2.get("ok", false) and int(r2["slot"]) == 4, "right after the pop slot 4 takes the pick")
	h.free()

func _other_slot_usable() -> void:
	print("[another empty slot takes a pick during the pop]")
	var h = _host()
	var slots = h.get_slots()
	_click(h, 1)
	_ok(_until_held(h, 4) >= 0, "slot 4 held")
	var r := _click(h, 2)
	_ok(r.get("ok", false) and int(r["slot"]) == 3, "pick during the pop lands in slot 3 at once")
	_ok(slots.is_finish_held(4) and slots.is_empty(4), "slot 4 still held and EMPTY")
	h.free()

func _all_finishing_no_spawn() -> void:
	print("[every empty slot finishing -> no spawn, nothing queued]")
	var h = _host()
	var slots = h.get_slots()
	for c in [1, 2, 3, 1, 2]:
		_click(h, c)
	_ok(slots.occupied_count() == 5, "five x1 batches fill all five slots")
	var all_held := false
	for i in range(600):
		var held := 0
		for k in range(5):
			if slots.is_finish_held(k):
				held += 1
		if held == 5:
			all_held = true
			break
		_tick(h)
	_ok(all_held and slots.occupied_count() == 0, "all five slots EMPTY and finishing")
	var supply_before: Array = h.get_supply().player_snapshot()
	var live: int = h.get_scheduler().live_assignment_count()
	var agents: int = h.get_dispatcher().get_active_count()
	var r := _click(h, 3)
	_ok(not r.get("ok", true) and r.get("error", "") == "slots_full", "pick rejected as no free slot (%s)" % str(r))
	_ok(h.get_supply().player_snapshot() == supply_before and slots.occupied_count() == 0, "supply and slots untouched")
	_ok(h.get_scheduler().live_assignment_count() <= live and h.get_dispatcher().get_active_count() <= agents, "no spawn from the rejected pick")
	for i in range(120):
		_tick(h)
	_ok(not slots.has_finish_hold() and slots.occupied_count() == 0, "nothing queued: after the pops the slots are just free")
	var r2 := _click(h, 3)
	_ok(r2.get("ok", false) and int(r2["slot"]) == 4, "next pick lands in slot 4")
	h.free()

func _reduced_effects() -> void:
	print("[Reduced Effects: no pop -> no hold; switched on mid-pop -> released]")
	var h = _host()
	var slots = h.get_slots()
	var scr = h.get_screen()
	scr.set_reduced_effects(true)
	_click(h, 1)
	var freed := false
	for i in range(600):
		_tick(h)
		if slots.is_empty(4):
			freed = true
			break
	_ok(freed and not slots.is_finish_held(4) and scr.get_booster_vfx().pop_count() == 0, "batch finished with no pop and no hold")
	var r := _click(h, 2)
	_ok(r.get("ok", false) and int(r["slot"]) == 4, "slot 4 takes the next pick at once")
	h.free()
	var h2 = _host()
	_click(h2, 1)
	_ok(_until_held(h2, 4) >= 0, "Reduced off: slot 4 held")
	h2.get_screen().set_reduced_effects(true)
	_tick(h2)
	_ok(not h2.get_slots().has_finish_hold(), "Reduced switched on mid-pop: pop removed, hold released next tick")
	h2.free()

func _cannot_stick() -> void:
	print("[the hold cannot stick: pause, terminal stop, reset]")
	var h = _host()
	var slots = h.get_slots()
	var rt = h.get_runtime()
	_click(h, 1)
	_ok(_until_held(h, 4) >= 0, "slot 4 held")
	rt.set_user_paused(true)
	for i in range(100):
		_tick(h)
	_ok(not slots.has_finish_hold(), "paused: the pop keeps playing, the hold runs out with it")
	_ok(_click(h, 2).get("error", "") == "paused", "pause still blocks picks itself")
	rt.set_user_paused(false)
	_ok(int(_click(h, 2).get("slot", -1)) == 4, "unpaused: slot 4 takes the pick")
	_ok(_until_held(h, 4) >= 0, "slot 4 held again")
	rt.set_terminal_stopped(true)
	for i in range(100):
		_tick(h)
	_ok(not slots.has_finish_hold(), "terminal stop: hold still runs out")
	h.free()
	var e = FiveSlotBatchEngine.new()
	e.hold_finished_slot(2, 1.6)
	_ok(e.is_finish_held(2) and e.rightmost_empty_index() == 4, "engine: held slot 2, free 4")
	e.reset()
	_ok(not e.has_finish_hold(), "reset() (Retry / new attempt) clears every hold")
	e.hold_finished_slot(9, 1.6)
	e.hold_finished_slot(1, 0.0)
	_ok(not e.has_finish_hold(), "no hold for an invalid slot or a zero-length pop")

func _sixth_slot() -> void:
	print("[+1 Slot: the sixth slot holds the same way]")
	var h = _host()
	var slots = h.get_slots()
	_ok(slots.grow_to_sixth() and h.get_screen().get_five_slot_strip().set_capacity(6), "grown to six slots")
	h.get_screen().refresh_slot_snapshot(slots.snapshot())
	var r := _click(h, 1)
	_ok(r.get("ok", false) and int(r["slot"]) == 5, "pick lands in the sixth slot (index 5)")
	_ok(_until_held(h, 5) >= 0, "sixth slot held after its batch")
	_ok(int(_click(h, 2).get("slot", -1)) == 4, "pick during the pop lands in slot 4")
	for i in range(100):
		_tick(h)
	_ok(not slots.is_finish_held(5) and int(_click(h, 3).get("slot", -1)) == 5, "after the pop the sixth slot takes picks again")
	h.free()
	var e = FiveSlotBatchEngine.new()
	e.grow_to_sixth()
	e.hold_finished_slot(5, 1.6)
	_ok(e.rollback_grow_to_sixth() and not e.has_finish_hold(), "rolling back the sixth slot drops its hold")

func _ok(cond: bool, msg: String) -> void:
	_cases += 1
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
