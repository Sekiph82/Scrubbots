extends SceneTree
## M25-C001 V01 — rollback / authenticated-clear finalization / reset+leak evidence
## (SB-M25-019..024, 032). Real production stack.
##
## Run: godot --headless --path . -s res://tests/m25_rollback_finalize_reset_evidence.gd

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

func _board(w, h, active):
	var pal := PackedStringArray(); for i in range(4): pal.append("#%02x%02x%02x" % [16+i,16+i,16+i])
	var cells := PackedInt32Array(); cells.resize(w*h); cells.fill(BLUE)
	var b = BoardState.from_level_data(LevelData.new(1,"m25","m25","TEST",w,h,pal,cells))
	var keep := {}; for i in active: keep[i] = true
	for i in range(w*h):
		if not keep.has(i): b.set_cell_state(i, BoardState.CellState.CLEARED)
	return b

func _stack(board, origin):
	var res = ReservationState.new(); res.bind(board)
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, res)
	var access = ProductionTargetAccess.new(ProductionRoutingSystem.new(), ProductionAccessQuery.new(board), board, origin)
	return {"res": res, "sel": sel, "access": access}

func _slots(specs):
	var slots = FiveSlotBatchEngine.new()
	var cols := []
	for s in specs: cols.append([ColorBatch.make(s[0], s[1], s[2], 16)])
	while cols.size() < 3: cols.append([])
	var sup = BatchSupplyEngine.create(cols.size(), 3); sup.load_columns(cols)
	for c in range(specs.size()): slots.select_front_batch(sup, c)
	return slots

func _initialize() -> void:
	_rollback()
	_finalize()
	_reset_leak()
	_done()

func _rollback() -> void:
	print("---- rollback (pre-spawn) ----")
	var board = _board(3, 1, [0,1,2])
	var st = _stack(board, Vector2(1.5, -1.5))
	var slots = _slots([["B", BLUE, 5]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var r := e.claim_for_color(BLUE, {4: st["access"]})
	print("  claim: ", r)
	_ok(slots.get_committed(4) == 1, "committed 1 after claim")
	_ok(not e.rollback_claim("random"), "random rollback fails closed")
	_ok(e.rollback_claim(r["claim_id"]), "exact rollback ok")
	_ok(slots.get_committed(4) == 0 and slots.get_remaining(4) == 5, "committed-1, remaining unchanged")
	_ok(st["res"].get_owner(r["target"]) == -1 and e.live_claim_count() == 0, "reservation released, ledger cleared")
	_ok(not e.rollback_claim(r["claim_id"]), "double rollback fails closed")

func _finalize() -> void:
	print("---- authenticated-clear finalization ----")
	var board = _board(3, 1, [0,1,2])
	var st = _stack(board, Vector2(1.5, -1.5))
	var slots = _slots([["B", BLUE, 5]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var r := e.claim_for_color(BLUE, {4: st["access"]})
	_ok(not e.finalize_clear(r["claim_id"]), "finalize before clear fails closed (ACTIVE + reserved)")
	# authoritative clear pipeline: resolve reservation + set cell CLEARED.
	st["res"].resolve_arrival(r["target"], r["owner_id"])
	board.set_cell_state(r["target"], BoardState.CellState.CLEARED)
	_ok(e.finalize_clear(r["claim_id"]), "finalize succeeds after authenticated clear")
	_ok(slots.get_remaining(4) == 4 and slots.get_committed(4) == 0, "remaining AND committed each -1 via M24")
	_ok(not e.finalize_clear(r["claim_id"]), "double finalize fails closed")
	_ok(not e.finalize_clear("ghost"), "random finalize fails closed")

func _reset_leak() -> void:
	print("---- reset / leak / unrelated owner survival ----")
	var board = _board(4, 4, [12,13,14,15])
	var st = _stack(board, Vector2(2.0, 5.5))
	var slots = _slots([["A", BLUE, 8], ["B", BLUE, 8]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var amap := {4: st["access"], 3: st["access"]}
	for n in range(3): e.claim_for_color(BLUE, amap)
	_ok(e.live_claim_count() == 3, "3 live claims created")
	# An unrelated ReservationState owner (not an M25 claim).
	st["res"].reserve(15, 555555)  # 15 is ACTIVE and currently unclaimed
	var live_before := e.live_claim_count()
	var committed_before := slots.get_committed(4)
	_ok(committed_before >= 1, "committed reflects live claims")
	_ok(e.reset(), "reset ok")
	_ok(e.live_claim_count() == 0, "all M25 claims cleared")
	_ok(slots.get_committed(4) == 0, "pre-clear M24 committed rolled back by reset")
	_ok(st["res"].get_owner(15) == 555555, "unrelated ReservationState owner survives reset")
	# no M25-owned reservation left
	var leaked := false
	for idx in [12, 13, 14]:
		if st["res"].get_owner(idx) != -1: leaked = true
	_ok(not leaked, "no M25-owned reservation leaked after reset")
	_ok(e.reset(), "repeated reset safe")

func _ok(c, m):
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done():
	print("M25 rollback/finalize/reset evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
