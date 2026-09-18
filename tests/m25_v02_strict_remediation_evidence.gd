extends SceneTree
## M25-C001 V02 — strict remediation evidence. Directly proves closure of
## F-M25-V01-STRICT-001..005 on the real production stack (BoardState + ReservationState +
## TargetSelector + ProductionTargetAccess/ProductionRoutingSystem + FiveSlotBatchEngine).
##
##   001 identity non-reuse / owner-collision non-stall
##   002 commit-failure exact WAITING lifecycle rollback
##   003 transaction-safe rollback_claim (reservation drift + M24 work drift)
##   004 transaction-safe reset (one incoherent tuple -> no false clean success)
##   004 strict production access category/coherence (generic + foreign-board rejected)
##   005 session-stable binding (live-claim rebind rejected, original bundle usable)
##
## Run: godot --headless --path . -s res://tests/m25_v02_strict_remediation_evidence.gd

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
const FailingCommit = preload("res://tests/support/m25_failing_commit_batches.gd")

const BLUE := 0
var _fail := 0

# Board of size w*h filled BLUE, only `active` indices ACTIVE (rest CLEARED).
func _board(w, h, active):
	var pal := PackedStringArray()
	for i in range(4): pal.append("#%02x%02x%02x" % [16+i, 16+i, 16+i])
	var cells := PackedInt32Array(); cells.resize(w*h); cells.fill(BLUE)
	var b = BoardState.from_level_data(LevelData.new(1, "m25v02", "m25v02", "TEST", w, h, pal, cells))
	var keep := {}
	for i in active: keep[i] = true
	for i in range(w*h):
		if not keep.has(i): b.set_cell_state(i, BoardState.CellState.CLEARED)
	return b

# Board straight from an explicit per-cell color array (for enclosed-target fixtures).
func _board_cells(w, h, cells_arr):
	var pal := PackedStringArray()
	for i in range(4): pal.append("#%02x%02x%02x" % [16+i, 16+i, 16+i])
	var cells := PackedInt32Array(cells_arr)
	return BoardState.from_level_data(LevelData.new(1, "m25v02", "m25v02", "TEST", w, h, pal, cells))

func _stack(board, origin):
	var res = ReservationState.new(); res.bind(board)
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, res)
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var access = ProductionTargetAccess.new(routing, raccess, board, origin)
	return {"res": res, "sel": sel, "routing": routing, "raccess": raccess, "access": access}

func _slots(specs, engine = null):
	var slots = engine if engine != null else FiveSlotBatchEngine.new()
	var cols := []
	for s in specs: cols.append([ColorBatch.make(s[0], s[1], s[2], 16)])
	while cols.size() < 3: cols.append([])
	var sup = BatchSupplyEngine.create(cols.size(), 3); sup.load_columns(cols)
	for c in range(specs.size()): slots.select_front_batch(sup, c)
	return slots

func _initialize() -> void:
	_identity_non_reuse()
	_owner_zero_no_stall()
	_commit_failure_waiting_restore()
	_rollback_reservation_drift()
	_rollback_m24_work_drift()
	_rollback_healthy_still_works()
	_reset_incoherent_tuple()
	_reset_multiple_healthy()
	_access_category_strictness()
	_session_stable_binding()
	_done()

# -- 001: stale pre-reset claim id / owner id can never act on a post-reset claim ----------
func _identity_non_reuse() -> void:
	print("---- 001 identity non-reuse across reset ----")
	var board = _board(3, 1, [0, 1, 2])
	var st = _stack(board, Vector2(1.5, -1.5))
	var slots = _slots([["A", BLUE, 5]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var a := e.claim_for_color(BLUE, {4: st["access"]})
	var stale_id = a["claim_id"]; var stale_owner = a["owner_id"]
	_ok(e.reset(), "reset ok after claim A")
	var b := e.claim_for_color(BLUE, {4: st["access"]})
	_ok(b["ok"], "post-reset claim B created")
	_ok(b["claim_id"] != stale_id, "post-reset claim id NOT recycled (%s vs %s)" % [b["claim_id"], stale_id])
	_ok(b["owner_id"] != stale_owner, "post-reset owner id NOT recycled (%d vs %d)" % [b["owner_id"], stale_owner])
	# Stale A handle cannot mutate B.
	_ok(not e.rollback_claim(stale_id), "stale pre-reset claim id cannot roll back")
	_ok(not e.finalize_clear(stale_id), "stale pre-reset claim id cannot finalize")
	_ok(e.live_claim_count() == 1 and e.get_claim(b["claim_id"]).size() > 0, "claim B untouched by stale-id attempts")

# -- 001: unrelated live owner (incl. 0) must not stall a valid claim ----------------------
func _owner_zero_no_stall() -> void:
	print("---- 001 unrelated owner 0 does not stall ----")
	var board = _board(4, 4, [12, 13, 14, 15])
	var st = _stack(board, Vector2(2.0, 5.5))
	var slots = _slots([["A", BLUE, 8]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	# Unrelated reservation grabs owner id 0 (M25's next candidate in a fresh engine).
	_ok(st["res"].reserve(15, 0), "unrelated owner 0 pre-reserves target 15")
	var r := e.claim_for_color(BLUE, {4: st["access"]})
	_ok(r["ok"] and r["target"] == 12, "valid claim still succeeds (target 12) despite owner-0 collision")
	_ok(r["owner_id"] != 0, "M25 minted a different unused owner id (%d)" % r["owner_id"])
	_ok(st["res"].get_owner(15) == 0, "unrelated owner-0 reservation survives unchanged")

# -- 002: WAITING -> opens -> forced M24 commit failure -> exact WAITING restored ----------
func _commit_failure_waiting_restore() -> void:
	print("---- 002 commit-failure exact WAITING lifecycle rollback ----")
	# 3x3, only the enclosed center (index 4) is BLUE; the ring is non-blue ACTIVE. The blue
	# target is unreachable until we clear a path, so the batch goes WAITING first.
	var board = _board_cells(3, 3, [1,1,1, 1,0,1, 1,1,1])
	var st = _stack(board, Vector2(1.5, -1.5))
	var failing = FailingCommit.new()
	var slots = _slots([["FC", BLUE, 4]], failing)
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var amap := {4: st["access"]}
	var w := e.claim_for_color(BLUE, amap)
	_ok(not w["ok"] and w.get("waiting", false), "enclosed blue -> no claim, WAITING")
	_ok(slots.get_state(4) == "WAITING", "batch is WAITING before target opens")
	# Open a path to the center (clear index 1 top-center and 7 bottom-center).
	board.set_cell_state(1, BoardState.CellState.CLEARED)
	board.set_cell_state(7, BoardState.CellState.CLEARED)
	var rem_before = slots.get_remaining(4)
	var c := e.claim_for_color(BLUE, amap)
	_ok(not c["ok"] and c["error"] == "commit_failed", "target now reachable but M24 commit forced to fail")
	_ok(slots.get_state(4) == "WAITING", "exact WAITING lifecycle prestate restored after commit failure")
	_ok(slots.get_remaining(4) == rem_before, "remaining unchanged after failed attempt")
	_ok(slots.get_committed(4) == 0, "committed unchanged (0) after failed attempt")
	_ok(st["res"].get_reservation_count() == 0, "exact new reservation released")
	_ok(e.live_claim_count() == 0, "no M25 ledger entry published")

# -- 003: rollback fails closed when the reservation pair has drifted ----------------------
func _rollback_reservation_drift() -> void:
	print("---- 003 rollback_claim reservation drift fails safe ----")
	var board = _board(3, 1, [0, 1, 2])
	var st = _stack(board, Vector2(1.5, -1.5))
	var slots = _slots([["A", BLUE, 5]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var r := e.claim_for_color(BLUE, {4: st["access"]})
	# Drift A: reservation externally resolved (pair absent).
	st["res"].resolve_arrival(r["target"], r["owner_id"])
	_ok(not e.rollback_claim(r["claim_id"]), "rollback fails closed when reservation pair absent")
	_ok(slots.get_committed(4) == 1, "M24 committed NOT mutated by failed rollback")
	_ok(e.live_claim_count() == 1, "ledger entry NOT erased by failed rollback")
	# Drift B: target now owned by a foreign owner.
	st["res"].reserve(r["target"], 424242)
	_ok(not e.rollback_claim(r["claim_id"]), "rollback fails closed when target reserved by foreign owner")
	_ok(slots.get_committed(4) == 1 and e.live_claim_count() == 1, "still no half-cleanup after foreign-owner drift")
	_ok(st["res"].get_owner(r["target"]) == 424242, "foreign owner untouched by failed rollback")

# -- 003: rollback fails closed when the M24 work identity has drifted ---------------------
func _rollback_m24_work_drift() -> void:
	print("---- 003 rollback_claim M24 work drift fails safe ----")
	var board = _board(3, 1, [0, 1, 2])
	var st = _stack(board, Vector2(1.5, -1.5))
	var slots = _slots([["A", BLUE, 5]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var r := e.claim_for_color(BLUE, {4: st["access"]})
	# Drift: M24 work rolled back externally (work identity now stale/absent).
	_ok(slots.rollback_work(r["claim_id"]), "external M24 rollback drifts the work identity")
	_ok(not e.rollback_claim(r["claim_id"]), "rollback fails closed when M24 work identity absent")
	_ok(st["res"].get_owner(r["target"]) == r["owner_id"], "reservation NOT released by failed rollback (no half-cleanup)")
	_ok(e.live_claim_count() == 1, "ledger entry NOT erased by failed rollback")

func _rollback_healthy_still_works() -> void:
	print("---- 003 healthy rollback still exact ----")
	var board = _board(3, 1, [0, 1, 2])
	var st = _stack(board, Vector2(1.5, -1.5))
	var slots = _slots([["A", BLUE, 5]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var r := e.claim_for_color(BLUE, {4: st["access"]})
	_ok(e.rollback_claim(r["claim_id"]), "healthy rollback ok")
	_ok(slots.get_committed(4) == 0 and slots.get_remaining(4) == 5, "committed-1, remaining unchanged")
	_ok(st["res"].get_owner(r["target"]) == -1 and e.live_claim_count() == 0, "exact reservation released, ledger cleared")

# -- 004: reset must not falsely report clean success over one incoherent tuple ------------
func _reset_incoherent_tuple() -> void:
	print("---- 004 reset with incoherent tuple fails safe ----")
	var board = _board(4, 4, [12, 13, 14, 15])
	var st = _stack(board, Vector2(2.0, 5.5))
	var slots = _slots([["A", BLUE, 8]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var amap := {4: st["access"]}
	var r0 := e.claim_for_color(BLUE, amap)
	var r1 := e.claim_for_color(BLUE, amap)
	_ok(e.live_claim_count() == 2, "two live claims")
	# Drift one tuple's reservation (foreign owner) so reset cannot clean it coherently.
	st["res"].resolve_arrival(r1["target"], r1["owner_id"])
	st["res"].reserve(r1["target"], 999001)
	var committed_before = slots.get_committed(4)
	_ok(not e.reset(), "reset refuses (returns false) when a live tuple is incoherent")
	_ok(e.live_claim_count() == 2, "ledger NOT silently cleared on refused reset")
	_ok(slots.get_committed(4) == committed_before, "no M24 mutation on refused reset")
	_ok(st["res"].get_owner(r0["target"]) == r0["owner_id"], "healthy tuple's reservation untouched by refused reset")
	_ok(st["res"].get_owner(r1["target"]) == 999001, "foreign owner untouched by refused reset")

func _reset_multiple_healthy() -> void:
	print("---- 004 reset with multiple healthy claims + unrelated owner ----")
	var board = _board(4, 4, [12, 13, 14, 15])
	var st = _stack(board, Vector2(2.0, 5.5))
	var slots = _slots([["A", BLUE, 8], ["B", BLUE, 8]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	var amap := {4: st["access"], 3: st["access"]}
	for n in range(3): e.claim_for_color(BLUE, amap)
	_ok(e.live_claim_count() == 3, "3 live claims")
	_ok(st["res"].reserve(15, 777001), "unrelated owner reserved")
	_ok(e.reset(), "reset ok with all-healthy tuples")
	_ok(e.live_claim_count() == 0 and slots.get_committed(4) == 0, "all M25 claims cleaned, committed rolled back")
	_ok(st["res"].get_owner(15) == 777001, "unrelated owner survives healthy reset")

# -- 004 (STRICT-004): strict production access category / board coherence -----------------
func _access_category_strictness() -> void:
	print("---- 004 strict production access category/coherence ----")
	var board = _board(4, 4, [12, 13, 14, 15])
	var st = _stack(board, Vector2(2.0, 5.5))
	var slots = _slots([["A", BLUE, 8]])
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, st["sel"], st["res"])
	# Generic all-true RefCounted (method-compatible) must be rejected.
	var generic = _AllTrueAccess.new()
	var g := e.claim_for_color(BLUE, {4: generic})
	_ok(g["error"] == "bad_access", "generic all-true RefCounted access rejected")
	# null / missing slot access rejected.
	_ok(e.claim_for_color(BLUE, {})["error"] == "bad_access", "missing/null access rejected")
	# Foreign-board ProductionTargetAccess rejected.
	var other = _board(4, 4, [12, 13, 14, 15])
	var st2 = _stack(other, Vector2(2.0, 5.5))
	var f := e.claim_for_color(BLUE, {4: st2["access"]})
	_ok(f["error"] == "foreign_board_access", "foreign-board ProductionTargetAccess rejected")
	# No reservation / M24 mutation from any rejection.
	_ok(st["res"].get_reservation_count() == 0 and slots.get_committed(4) == 0 and e.live_claim_count() == 0,
		"no reservation/M24/ledger mutation on any access rejection")
	# Real coherent access still accepted.
	_ok(e.claim_for_color(BLUE, {4: st["access"]})["ok"], "real coherent ProductionTargetAccess accepted")

# -- 005: session-stable binding — live-claim rebind rejected, original stays usable -------
func _session_stable_binding() -> void:
	print("---- 005 session-stable binding ----")
	var board = _board(3, 1, [0, 1, 2])
	var st = _stack(board, Vector2(1.5, -1.5))
	var slots = _slots([["A", BLUE, 5]])
	var e = BatchTargetClaimEngine.new()
	_ok(e.bind(board, slots, st["sel"], st["res"]), "first coherent bind ok")
	var r := e.claim_for_color(BLUE, {4: st["access"]})
	_ok(r["ok"], "live claim created")
	# Second coherent same-bundle bind must fail closed (no migration).
	_ok(not e.bind(board, slots, st["sel"], st["res"]), "second same-bundle bind rejected")
	# Coherent FOREIGN bundle bind must fail closed while a live claim exists.
	var other = _board(3, 1, [0, 1, 2])
	var st2 = _stack(other, Vector2(1.5, -1.5))
	var slots2 = _slots([["Z", BLUE, 5]])
	_ok(not e.bind(other, slots2, st2["sel"], st2["res"]), "foreign-bundle bind rejected with live claim")
	# Original bundle still authoritative: the original live claim remains rollback-capable.
	_ok(e.rollback_claim(r["claim_id"]), "original live claim still rollback-capable on original bundle")
	_ok(slots.get_committed(4) == 0 and st["res"].get_owner(r["target"]) == -1, "rollback hit the ORIGINAL bundle exactly")

# All-true generic access double (NOT a ProductionTargetAccess) — must be rejected.
class _AllTrueAccess extends RefCounted:
	func is_targetable(_index: int) -> bool:
		return true

func _ok(c, m):
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done():
	print("M25 V02 strict-remediation evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
