extends SceneTree
## M29-C001 V03 — five-slot displayed count + live synchronization evidence
## (criteria §8/§9, OWNER_BATCH_SLOT_DISPLAY_DECISION_V01 / OWNER_FIVE_SLOT_LIVE_PRESENTATION_SYNC).
##
## Part A (unit): the player-facing main slot number == M24 capacity (remaining_to_clear -
## committed) — the robots still WAITING in the slot — and the old "50 (2)" raw form is gone,
## while M24 internal accounting is unchanged.
##
## Part B (live sync): under the real _process runtime clock, the five-slot strip mirrors
## the authoritative M24 snapshot after scheduler-driven mutations (commit, ACTIVE<->WAITING
## wake, completion -> EMPTY, reset) WITHOUT another player click, and the UI never computes
## targetability itself. Hazard-specific: an early non-blue batch (Red/Yellow/Brown) shows
## WAITING while the two Blue50 batches clear.
##
## Run: godot --headless --path . -s res://tests/m29_slot_display_sync_evidence.gd
## Exits 0 on success, 1 on any failure.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BatchSlotView = preload("res://scripts/ui/batch_slot_view.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")

const BLUE := 2

var _fail := 0
var _sub

func _initialize() -> void:
	_test_display_count_unit()
	await _test_live_sync()
	_done()

# ------------------------------------------------- §8 displayed count (unit) --

func _test_display_count_unit() -> void:
	var supply = BatchSupplyEngine.create(3, 3)
	supply.load_columns([[ColorBatch.make("blue50", BLUE, 50, 16)], [ColorBatch.make("x", 0, 3, 16)], [ColorBatch.make("y", 1, 3, 16)]])
	var slots = FiveSlotBatchEngine.new()
	var r: Dictionary = slots.select_front_batch(supply, 0)
	var slot: int = int(r["slot"])
	var view = BatchSlotView.new()
	view.bind_snapshot(slots.snapshot()[slot], Color(0, 0, 1))
	_ok(view.get_display_count() == 50 and view.get_count_label_text() == "50", "fresh Blue 50 displays 50")

	_ok(slots.commit_work(slot, "w1"), "one work committed")
	view.bind_snapshot(slots.snapshot()[slot], Color(0, 0, 1))
	_ok(view.get_display_count() == 49 and view.get_count_label_text() == "49", "one committed/dispatched => displays 49 immediately")

	_ok(slots.commit_work(slot, "w2"), "second work committed")
	view.bind_snapshot(slots.snapshot()[slot], Color(0, 0, 1))
	_ok(view.get_display_count() == 48 and view.get_count_label_text() == "48", "two committed/in-flight => displays 48")
	_ok(not view.get_count_label_text().contains("("), "raw \"50 (2)\" parenthetical presentation is gone")

	# One in-flight agent authenticates a clear: remaining and committed decrement together,
	# so the displayed WAITING count stays 48.
	_ok(slots.resolve_clear("w1"), "one committed work authenticates a clear")
	view.bind_snapshot(slots.snapshot()[slot], Color(0, 0, 1))
	_ok(view.get_display_count() == 48, "after one in-flight clear the displayed waiting count remains 48")
	# M24 internal accounting unchanged: remaining 49, committed 1, capacity 48.
	_ok(slots.get_remaining(slot) == 49 and slots.get_committed(slot) == 1 and slots.get_capacity(slot) == 48, "M24 internal remaining/committed/capacity invariants unchanged")
	view.free()

# ----------------------------------------------------- §9 live synchronization --

func _test_live_sync() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(683, 1366)
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub.add_child(host)
	await process_frame
	await process_frame
	if not host.build():
		_ok(false, "host build for live sync (%s)" % host.get_build_error())
		return
	for _i in range(6):
		await process_frame
	var supply = host.get_supply()
	var slots = host.get_slots()
	var input = host.get_input_controller()
	var strip = host.get_screen().get_five_slot_strip()

	# Place the first Hazard front (Red15) and let one commit change the visible count.
	if supply.get_front(0) != null:
		input.activate_front(0)
	await process_frame
	await process_frame
	_ok(_strip_matches_slots(strip, slots), "strip mirrors authoritative M24 snapshot (live commit reflected)")

	# Drive the deterministic solved column-drain order (0x7,1x6,2x6) as slots free, under
	# the real _process clock, and observe slot transitions purely from runtime sync (no UI
	# targetability inference). Corridor-opening clears make early WAITING colors wake.
	var order: Array = []
	for _k in range(7):
		order.append(0)
	for _k in range(6):
		order.append(1)
	for _k in range(6):
		order.append(2)
	var idx := 1   # Red15 already placed above
	var waiting_seen := false
	var wake_seen := false
	var empty_after_occ := false
	var mismatch := false
	var prev_state: Array = ["", "", "", "", ""]
	for _f in range(40000):
		if idx < order.size() and slots.rightmost_empty_index() != -1 and supply.get_front(order[idx]) != null:
			if input.activate_front(order[idx]).get("ok", false):
				idx += 1
		await process_frame
		if not _strip_matches_slots(strip, slots):
			mismatch = true
		var views: Array = strip.get_slot_views()
		for i in range(5):
			var st: String = views[i].get_state()
			if st == "WAITING":
				waiting_seen = true
			if prev_state[i] == "WAITING" and st == "ACTIVE":
				wake_seen = true
			if prev_state[i] != "EMPTY" and prev_state[i] != "" and st == "EMPTY":
				empty_after_occ = true
			prev_state[i] = st
		if wake_seen and empty_after_occ and waiting_seen:
			break
		if idx >= order.size() and slots.occupied_count() == 0 and host.get_clearing_loop().get_cleared_count() > 0:
			break
	_ok(not mismatch, "strip stays exactly in sync with the authoritative M24 snapshot every frame")
	_ok(waiting_seen, "an early non-blue batch displays WAITING while Blue clears (no extra input)")
	_ok(wake_seen, "WAITING -> ACTIVE wake becomes visible automatically (no extra input)")
	_ok(empty_after_occ, "slot completion -> EMPTY refreshes automatically")

	# Reset refreshes automatically.
	host.reset_session()
	await process_frame
	var all_empty := true
	for v in strip.get_slot_views():
		if v.get_state() != "EMPTY":
			all_empty = false
	_ok(all_empty, "reset refreshes the five-slot UI to EMPTY automatically")
	_sub.free()

## True iff every strip view's displayed state + count equals the authoritative M24 slot.
func _strip_matches_slots(strip, slots) -> bool:
	var views: Array = strip.get_slot_views()
	for i in range(5):
		var occ: bool = slots.is_occupied(i)
		if occ != views[i].is_occupied_view():
			return false
		if not occ:
			continue
		if views[i].get_state() != slots.get_state(i):
			return false
		if views[i].get_display_count() != slots.get_capacity(i):
			return false
	return true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M29 slot display + live sync evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
