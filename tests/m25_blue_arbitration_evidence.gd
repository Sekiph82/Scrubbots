extends SceneTree
## M25-C001 V01 — BLUE 8 / 14 / 12 arbitration + opening evidence (SB-M25-028..030).
## Real M23->M24 placement + real production targetability. Proves oldest-placement-first
## claims, capacity spill, no pre-ownership of a blocked pixel, opening-time assignment,
## and TargetSelector bottom-most/left-most order.
##
## Run: godot --headless --path . -s res://tests/m25_blue_arbitration_evidence.gd

const LevelData = preload("res://scripts/data/level_data.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const BatchTargetClaimEngine = preload("res://scripts/gameplay/targeting/batch_target_claim_engine.gd")

const BLUE := 0
var _fail := 0

func _blue_batches():
	# Real M23->M24: BLUE_8 -> slot4 (oldest), BLUE_14 -> slot3, BLUE_12 -> slot2.
	var slots = FiveSlotBatchEngine.new()
	var sup = BatchSupplyEngine.create(3, 3)
	sup.load_columns([
		[ColorBatch.make("BLUE_8", BLUE, 8, 16)],
		[ColorBatch.make("BLUE_14", BLUE, 14, 16)],
		[ColorBatch.make("BLUE_12", BLUE, 12, 16)]])
	slots.select_front_batch(sup, 0); slots.select_front_batch(sup, 1); slots.select_front_batch(sup, 2)
	return slots

func _stack(board, origin):
	var res = ReservationState.new(); res.bind(board)
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, res)
	var access = ProductionTargetAccess.new(ProductionRoutingSystem.new(), ProductionAccessQuery.new(board), board, origin)
	return {"res": res, "sel": sel, "access": access}

func _initialize() -> void:
	_oldest_first_and_order()
	_spill_when_capacity_zero()
	_blocked_then_opens()
	_done()

func _oldest_first_and_order() -> void:
	print("---- A: oldest-first + TargetSelector order ----")
	# 3x3, bottom row (6,7,8) ACTIVE blue, rest cleared.
	var pal := PackedStringArray(); for i in range(4): pal.append("#%02x%02x%02x" % [16+i,16+i,16+i])
	var cells := PackedInt32Array(); cells.resize(9); cells.fill(BLUE)
	var board = BoardState.from_level_data(LevelData.new(1,"b","b","TEST",3,3,pal,cells))
	for i in [0,1,2,3,4,5]: board.set_cell_state(i, BoardState.CellState.CLEARED)
	var st = _stack(board, Vector2(1.5, 4.5))
	var slots = _blue_batches()
	print("placement seq: BLUE_8(slot4)=%d BLUE_14(slot3)=%d BLUE_12(slot2)=%d" % [slots.get_placement_sequence(4), slots.get_placement_sequence(3), slots.get_placement_sequence(2)])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var amap := {4: st["access"], 3: st["access"], 2: st["access"]}
	var targets := []
	for n in range(3):
		var r = e.claim_for_color(BLUE, amap)
		targets.append(r["target"])
		print("  claim %d -> slot %d batch %s target %d coord %s owner %d" % [n, r["slot"], r["batch_id"], r["target"], str(r["coord"]), r["owner_id"]])
		_ok(r["slot"] == 4, "claim %d goes to oldest BLUE_8 (slot 4)" % n)
	_ok(targets == [6, 7, 8], "TargetSelector bottom-most then left-most order: 6,7,8")
	_ok(slots.get_committed(4) == 3 and slots.get_committed(3) == 0 and slots.get_committed(2) == 0, "only BLUE_8 committed; BLUE_14/12 untouched")
	_ok(st["res"].get_reservation_count() == 3 and e.live_claim_count() == 3, "3 reservations == 3 live claims (unique targets)")

func _spill_when_capacity_zero() -> void:
	print("---- B: capacity spill to next same-color batch ----")
	# 3x2, bottom row (3,4,5) blue targetable. OLD cap 2 (slot4), NEW (slot3).
	var pal := PackedStringArray(); for i in range(4): pal.append("#%02x%02x%02x" % [16+i,16+i,16+i])
	var cells := PackedInt32Array(); cells.resize(6); cells.fill(BLUE)
	var board = BoardState.from_level_data(LevelData.new(1,"b2","b2","TEST",3,2,pal,cells))
	for i in [0,1,2]: board.set_cell_state(i, BoardState.CellState.CLEARED)
	var st = _stack(board, Vector2(1.5, 3.5))
	var slots = FiveSlotBatchEngine.new()
	var sup = BatchSupplyEngine.create(3,3)
	sup.load_columns([[ColorBatch.make("OLD", BLUE, 2, 16)],[ColorBatch.make("NEW", BLUE, 5, 16)],[]])
	slots.select_front_batch(sup,0); slots.select_front_batch(sup,1)
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var amap := {4: st["access"], 3: st["access"]}
	var slot_seq := []
	for n in range(3):
		slot_seq.append(e.claim_for_color(BLUE, amap)["slot"])
	print("  claim slots: ", slot_seq)
	_ok(slot_seq == [4, 4, 3], "OLD (slot4) claims until capacity 0, then spills to NEW (slot3)")
	_ok(slots.get_committed(4) == 2 and slots.get_committed(3) == 1, "OLD committed 2 (full), NEW committed 1")

func _blocked_then_opens() -> void:
	print("---- C: no pre-ownership of blocked pixel; claimed at opening ----")
	# 3x3: center (index 4) blue, enclosed by ACTIVE color-1 cells -> unreachable.
	var pal := PackedStringArray(); for i in range(4): pal.append("#%02x%02x%02x" % [16+i,16+i,16+i])
	var cells := PackedInt32Array([1,1,1, 1,BLUE,1, 1,1,1])
	var board = BoardState.from_level_data(LevelData.new(1,"b3","b3","TEST",3,3,pal,cells))
	var st = _stack(board, Vector2(1.5, -1.5))
	var slots = FiveSlotBatchEngine.new()
	var sup = BatchSupplyEngine.create(3,3)
	sup.load_columns([[ColorBatch.make("B8", BLUE, 8, 16)],[ColorBatch.make("B14", BLUE, 14, 16)],[]])
	slots.select_front_batch(sup,0); slots.select_front_batch(sup,1)  # slot4 oldest, slot3
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var amap := {4: st["access"], 3: st["access"]}
	var rw := e.claim_for_color(BLUE, amap)
	print("  pre-opening claim: ", rw)
	_ok(not rw["ok"] and rw.get("waiting", false), "blocked blue not claimed -> WAITING")
	_ok(st["res"].get_reservation_count() == 0 and e.live_claim_count() == 0, "blocked target has no owner before opening")
	_ok(slots.get_state(4) == "WAITING", "oldest blue batch WAITING")
	# Authoritative opening: clear blocking neighbors so center becomes reachable.
	board.set_cell_state(1, BoardState.CellState.CLEARED)
	board.set_cell_state(7, BoardState.CellState.CLEARED)
	var ro := e.reconsider_color(BLUE, amap)
	print("  post-opening claim: ", ro)
	_ok(ro["ok"] and ro["target"] == 4, "center claimed only AFTER opening")
	_ok(ro["slot"] == 4 and ro["batch_id"] == "B8", "opened target goes to oldest capacity-bearing blue batch (B8)")
	_ok(slots.get_state(4) == "ACTIVE", "WAITING batch resumed ACTIVE")

func _ok(c, m):
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done():
	print("M25 BLUE arbitration/opening evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
