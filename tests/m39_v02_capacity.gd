extends SceneTree
## M39-C001 V02 Phase A — live 5/6 slot capacity + capacity-aware proof state.
## Run: godot --headless --path . -s res://tests/m39_v02_capacity.gd

const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")

var _fail := 0

func _initialize() -> void:
	_engine_capacity()
	_proof_state_capacity_key()
	_done()

func _engine_capacity() -> void:
	print("[engine capacity]")
	var e = FiveSlotBatchEngine.new()
	_ok(e.get_slot_count() == 5, "baseline capacity 5")
	_ok(e.active_capacity() == 5, "active_capacity 5")
	# rightmost empty is index 4 at baseline.
	_ok(e.rightmost_empty_index() == 4, "baseline rightmost empty index 4")
	# Grow to sixth.
	_ok(e.grow_to_sixth(), "grow_to_sixth succeeds from 5")
	_ok(e.get_slot_count() == 6 and e.active_capacity() == 6, "capacity now 6")
	_ok(e.rightmost_empty_index() == 5, "sixth slot is the rightmost empty (index 5)")
	# Never 7+: a second grow fails.
	_ok(not e.grow_to_sixth(), "cannot grow past 6 (never 7+)")
	_ok(e.get_slot_count() == 6, "still 6 after refused grow")
	_ok(not e.can_grow_to_sixth(), "can_grow_to_sixth false at 6")
	# is_full honors capacity 6.
	_ok(not e.is_full(), "6-capacity engine not full while empty")
	# Reset returns to baseline five (new attempt).
	_ok(e.reset(), "reset ok")
	_ok(e.get_slot_count() == 5, "reset returns to baseline 5")
	_ok(e.can_grow_to_sixth(), "+1 slot re-armed after reset")

func _proof_state_capacity_key() -> void:
	print("[proof state capacity key]")
	var r = LevelLoader.load_from_path("res://data/levels/m21_level_001_hazard_bot.json")
	_ok(r.is_ok(), "M21 level loads")
	var level = r.level_data
	var supply = BatchSupplyEngine.create(3, 3)
	_ok(supply != null, "supply engine created")
	var ps5 = ProofState.from_level_and_supply(level, supply)
	_ok(ps5 != null and ps5.capacity == 5, "initial proof state capacity 5")
	# Same state, capacity 6 (a temporary sixth slot) must have a DIFFERENT key.
	var ps6 = ps5.duplicate_state()
	ps6.capacity = 6
	ps6.slots.append(null)   # the sixth (empty) slot
	_ok(ps5.canonical_key() != ps6.canonical_key(), "5-slot and 6-slot states have distinct canonical keys")
	# duplicate carries capacity.
	var ps6b = ps6.duplicate_state()
	_ok(ps6b.capacity == 6, "duplicate_state carries capacity")
	_ok(ps6b.canonical_key() == ps6.canonical_key(), "duplicate of a 6-slot state matches its key")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 V02 capacity evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
