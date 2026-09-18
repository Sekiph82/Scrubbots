extends SceneTree
## M25-C001 V01 — rectangular + 59x59 scale evidence (SB-M25-031). Real production
## BoardState + targetability/routing. Five occupied slots, duplicate colors. Proves
## unique reservations, deterministic oldest-first order, bounded claim/reservation
## counts and reset cleanup; records performance sanity (no arbitrary threshold).
##
## Run: godot --headless --path . -s res://tests/m25_scale_evidence.gd

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

## Board w x h; only the bottom row (y=h-1) ACTIVE blue, rest CLEARED.
func _bottom_row_board(w, h):
	var pal := PackedStringArray(); for i in range(4): pal.append("#%02x%02x%02x" % [16+i,16+i,16+i])
	var cells := PackedInt32Array(); cells.resize(w*h); cells.fill(BLUE)
	var b = BoardState.from_level_data(LevelData.new(1,"m25s","m25s","TEST",w,h,pal,cells))
	for y in range(h - 1):
		for x in range(w):
			b.set_cell_state(y*w + x, BoardState.CellState.CLEARED)
	return b

## Five occupied blue slots (duplicate color) with descending capacity so oldest-first is
## observable; oldest = slot 4.
func _five_slots():
	var slots = FiveSlotBatchEngine.new()
	var sup = BatchSupplyEngine.create(5, 3)
	sup.load_columns([
		[ColorBatch.make("S0", BLUE, 100, 16)], [ColorBatch.make("S1", BLUE, 100, 16)],
		[ColorBatch.make("S2", BLUE, 100, 16)], [ColorBatch.make("S3", BLUE, 100, 16)],
		[ColorBatch.make("S4", BLUE, 100, 16)]])
	for c in range(5): slots.select_front_batch(sup, c)
	return slots

func _run(w, h, attempts, label):
	var board = _bottom_row_board(w, h)
	var res = ReservationState.new(); res.bind(board)
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, res)
	var access = ProductionTargetAccess.new(ProductionRoutingSystem.new(), ProductionAccessQuery.new(board), board, Vector2(w * 0.5, h + 1.5))
	var slots = _five_slots()
	var e = BatchTargetClaimEngine.new(); e.bind(board, slots, sel, res)
	var amap := {}
	for i in range(5): amap[i] = access
	var t0 := Time.get_ticks_msec()
	var targets := {}
	var accepted := 0
	var oldest_slot_ok := true
	for n in range(attempts):
		var r = e.claim_for_color(BLUE, amap)
		if not r["ok"]:
			break
		accepted += 1
		# oldest-first: slot 4 keeps claiming while it has capacity (100 >> attempts).
		if r["slot"] != 4: oldest_slot_ok = false
		if targets.has(r["target"]): _ok(false, "%s duplicate target %d" % [label, r["target"]])
		targets[r["target"]] = true
	var ms := Time.get_ticks_msec() - t0
	print("%s: cells=%d attempts=%d accepted=%d reservations=%d live=%d time=%dms" % [label, w*h, attempts, accepted, res.get_reservation_count(), e.live_claim_count(), ms])
	_ok(accepted == attempts, "%s all attempts accepted (bottom row has enough targets)" % label)
	_ok(oldest_slot_ok, "%s oldest slot 4 claimed all (FIFO)" % label)
	_ok(res.get_reservation_count() == accepted and e.live_claim_count() == accepted, "%s reservations == live claims == accepted (unique)" % label)
	# reset cleanup
	_ok(e.reset(), "%s reset ok" % label)
	_ok(e.live_claim_count() == 0 and res.get_reservation_count() == 0, "%s reset released all claims/reservations" % label)
	_ok(slots.get_committed(4) == 0, "%s M24 committed rolled back on reset" % label)

func _initialize() -> void:
	_run(40, 12, 12, "rect(40x12)")
	_run(59, 59, 12, "square(59x59)")
	_done()

func _ok(c, m):
	if c: print("  ok: %s" % m)
	else:
		_fail += 1
		print("  FAIL: %s" % m)

func _done():
	print("M25 scale evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
