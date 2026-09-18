extends SceneTree
## M25-C001 V03 — exact M24 work-tuple binding evidence. Directly proves closure of
## F-M25-V02-STRICT-001: a live M25 claim's M24 work identity must be bound to the EXACT
## ledger tuple (claim id + slot + batch_id), not merely live/coherent somewhere else in
## FiveSlotBatchEngine. Uses two occupied same-color batches (distinct ids) so color
## equality cannot hide a redirected work id.
##
## Run: godot --headless --path . -s res://tests/m25_v03_exact_work_binding_evidence.gd

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
	var pal := PackedStringArray()
	for i in range(4): pal.append("#%02x%02x%02x" % [16+i, 16+i, 16+i])
	var cells := PackedInt32Array(); cells.resize(w*h); cells.fill(BLUE)
	var b = BoardState.from_level_data(LevelData.new(1, "m25v03", "m25v03", "TEST", w, h, pal, cells))
	var keep := {}
	for i in active: keep[i] = true
	for i in range(w*h):
		if not keep.has(i): b.set_cell_state(i, BoardState.CellState.CLEARED)
	return b

func _stack(board, origin):
	var res = ReservationState.new(); res.bind(board)
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, res)
	var access = ProductionTargetAccess.new(ProductionRoutingSystem.new(), ProductionAccessQuery.new(board), board, origin)
	return {"res": res, "sel": sel, "access": access}

# Place [id,color,count] batches oldest-first (slot 4,3,...). Returns FiveSlotBatchEngine.
func _slots(specs):
	var slots = FiveSlotBatchEngine.new()
	var cols := []
	for s in specs: cols.append([ColorBatch.make(s[0], s[1], s[2], 16)])
	while cols.size() < 3: cols.append([])
	var sup = BatchSupplyEngine.create(cols.size(), 3); sup.load_columns(cols)
	for c in range(specs.size()): slots.select_front_batch(sup, c)
	return slots

func _initialize() -> void:
	_seam_direct()
	_redirected_work_rollback_and_finalize()
	_redirected_work_reset()
	_done()

# The M24 seam itself: true only for the exact bound tuple, false for a redirected id.
func _seam_direct() -> void:
	print("---- is_work_bound_to seam ----")
	var slots = _slots([["A", BLUE, 8], ["B", BLUE, 8]])  # A@slot4, B@slot3
	_ok(slots.commit_work(4, "W1"), "commit W1 to A@slot4")
	_ok(slots.is_work_bound_to("W1", 4, "A"), "seam: W1 bound to exact slot4/A")
	_ok(not slots.is_work_bound_to("W1", 3, "A"), "seam: wrong slot rejected")
	_ok(not slots.is_work_bound_to("W1", 4, "B"), "seam: wrong batch_id rejected")
	_ok(not slots.is_work_bound_to("GHOST", 4, "A"), "seam: unknown work id rejected")
	# Redirect W1 from A to B and confirm the seam rejects the stale A tuple.
	_ok(slots.rollback_work("W1"), "external rollback W1 from A")
	_ok(slots.commit_work(3, "W1"), "external re-commit W1 to B@slot3 (internally coherent for B)")
	_ok(not slots.is_work_bound_to("W1", 4, "A"), "seam: redirected W1 NOT bound to original slot4/A")
	_ok(slots.is_work_bound_to("W1", 3, "B"), "seam: W1 now exactly bound to slot3/B")

# Full engine adversarial redirect: rollback_claim + finalize_clear must fail closed.
func _redirected_work_rollback_and_finalize() -> void:
	print("---- redirected work: rollback_claim + finalize_clear fail closed ----")
	var board = _board(4, 4, [12, 13, 14, 15])
	var st = _stack(board, Vector2(2.0, 5.5))
	var slots = _slots([["A", BLUE, 8], ["B", BLUE, 8]])  # A@slot4 (older), B@slot3
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var amap := {4: st["access"], 3: st["access"]}
	var c := e.claim_for_color(BLUE, amap)   # C -> A@slot4
	_ok(c["ok"] and c["slot"] == 4 and c["batch_id"] == "A", "claim C belongs to batch A@slot4")
	var cid = c["claim_id"]; var ct = int(c["target"]); var co = int(c["owner_id"])
	# Externally redirect the SAME work id from A to B.
	_ok(slots.rollback_work(cid), "external rollback_work(C) from A")
	_ok(slots.commit_work(3, cid), "external commit_work(B@slot3, C) — internally coherent for B")
	var b_committed_before = slots.get_committed(3)
	var b_remaining_before = slots.get_remaining(3)
	# rollback_claim(C) must fail closed: M25 ledger says slot4/A but M24 record now slot3/B.
	_ok(not e.rollback_claim(cid), "rollback_claim(C) fails closed against redirected work")
	_ok(slots.get_committed(3) == b_committed_before, "B committed unchanged by failed rollback")
	_ok(st["res"].get_owner(ct) == co, "C reservation pair intact after failed rollback")
	_ok(e.live_claim_count() == 1 and e.get_claim(cid).size() > 0, "M25 ledger entry for C intact")
	# Stage authenticated-clear prerequisites, then finalize_clear(C) must ALSO fail closed.
	st["res"].resolve_arrival(ct, co)
	board.set_cell_state(ct, BoardState.CellState.CLEARED)
	_ok(not e.finalize_clear(cid), "finalize_clear(C) fails closed against redirected work")
	_ok(slots.get_committed(3) == b_committed_before, "B committed NOT decremented by failed finalize")
	_ok(slots.get_remaining(3) == b_remaining_before, "B remaining NOT decremented by failed finalize")
	_ok(e.live_claim_count() == 1, "M25 ledger entry for C still intact after failed finalize")

# Redirected work + a healthy sibling claim: reset must fail closed before mutating either.
func _redirected_work_reset() -> void:
	print("---- redirected work: reset fails closed, healthy sibling untouched ----")
	var board = _board(4, 4, [12, 13, 14, 15])
	var st = _stack(board, Vector2(2.0, 5.5))
	var slots = _slots([["A", BLUE, 8], ["B", BLUE, 8]])  # A@slot4 (older), B@slot3
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var amap := {4: st["access"], 3: st["access"]}
	var c := e.claim_for_color(BLUE, amap)   # C -> A (target 12)
	var d := e.claim_for_color(BLUE, amap)   # D -> A (target 13), healthy sibling
	_ok(c["slot"] == 4 and d["slot"] == 4, "C and D both on A@slot4")
	var cid = c["claim_id"]; var did = d["claim_id"]
	# Redirect only C.
	slots.rollback_work(cid); slots.commit_work(3, cid)
	var a_committed_before = slots.get_committed(4)   # D's work still on A
	var b_committed_before = slots.get_committed(3)   # redirected C on B
	_ok(not e.reset(), "reset fails closed with one redirected tuple")
	_ok(e.live_claim_count() == 2, "no ledger entry erased by refused reset")
	_ok(slots.get_committed(4) == a_committed_before, "healthy D's batch A committed untouched")
	_ok(slots.get_committed(3) == b_committed_before, "redirected batch B committed untouched")
	_ok(st["res"].get_owner(int(d["target"])) == int(d["owner_id"]), "healthy D reservation untouched")
	_ok(st["res"].get_owner(int(c["target"])) == int(c["owner_id"]), "C reservation untouched by refused reset")

func _ok(cnd, m):
	if cnd: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done():
	print("M25 V03 exact-work-binding evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
