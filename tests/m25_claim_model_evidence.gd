extends SceneTree
## M25-C001 V01 — claim-model / atomicity / uniqueness evidence. Uses the real
## production stack (BoardState + ColorCandidateIndex + ReservationState + TargetSelector
## + ProductionTargetAccess/ProductionRoutingSystem). Proves coherent bind, eligible-only
## claims, the atomic reservation+claim+M24-commit tuple, uniqueness, and remaining-vs-
## committed accounting.
##
## Run: godot --headless --path . -s res://tests/m25_claim_model_evidence.gd

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

var _fail := 0

func _board(w, h, palette_size, fill, active):
	var pal := PackedStringArray()
	for i in range(palette_size): pal.append("#%02x%02x%02x" % [16 + i, 16 + i, 16 + i])
	var cells := PackedInt32Array(); cells.resize(w * h); cells.fill(fill)
	var b = BoardState.from_level_data(LevelData.new(1, "m25", "m25", "TEST", w, h, pal, cells))
	var keep := {}
	for i in active: keep[i] = true
	for i in range(w * h):
		if not keep.has(i): b.set_cell_state(i, BoardState.CellState.CLEARED)
	return b

func _initialize() -> void:
	var BLUE := 0
	var board = _board(4, 4, 4, BLUE, [12, 13, 14, 15])  # bottom row ACTIVE
	var res = ReservationState.new(); res.bind(board)
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, res)
	var access = ProductionTargetAccess.new(ProductionRoutingSystem.new(), ProductionAccessQuery.new(board), board, Vector2(2.0, 5.5))

	var slots = FiveSlotBatchEngine.new()
	var sup = BatchSupplyEngine.create(3, 3)
	sup.load_columns([[ColorBatch.make("A", BLUE, 8, 16)], [], []])
	slots.select_front_batch(sup, 0)  # slot 4

	var e = BatchTargetClaimEngine.new()
	_ok(not e.claim_for_color(BLUE, {})["ok"], "unbound engine cannot claim")
	_ok(e.bind(board, slots, sel, res), "coherent bind succeeds")

	var amap := {4: access}
	var r0 := e.claim_for_color(BLUE, amap)
	print("claim0: ", r0)
	_ok(r0["ok"] and r0["target"] == 12, "first claim reserves bottom-left target 12 (TargetSelector order)")
	# Atomic tuple: reservation owner == claim owner, M24 committed == 1, remaining unchanged.
	_ok(res.get_owner(r0["target"]) == r0["owner_id"], "ReservationState owner == claim owner")
	_ok(res.get_target_for_owner(r0["owner_id"]) == r0["target"], "ReservationState target == claim target")
	_ok(slots.get_committed(4) == 1 and slots.get_remaining(4) == 8, "M24 committed==1, remaining unchanged")
	var r1 := e.claim_for_color(BLUE, amap)
	_ok(r1["target"] == 13, "second claim reserves next (target 13)")
	_ok(r0["target"] != r1["target"], "no two claims share a target")
	_ok(res.get_reservation_count() == 2 and e.live_claim_count() == 2, "reservation count == live claim count == 2")
	_ok(r0["claim_id"] != r1["claim_id"] and r0["owner_id"] != r1["owner_id"], "claim/owner identities unique")
	# Detached snapshot cannot mutate engine.
	var snap = e.claim_snapshot()
	snap[0]["target"] = -5
	_ok(e.claim_snapshot()[0]["target"] != -5, "detached snapshot cannot mutate engine")
	_done()

func _ok(c, m):
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done():
	print("M25 claim-model evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
