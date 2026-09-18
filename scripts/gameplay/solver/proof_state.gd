extends RefCounted
## ProofState — M27 Solvability/Deadlock Engine detached proof state (SB-M27-001..012).
## Preload this script (res://scripts/gameplay/solver/proof_state.gd); do not rely on
## global class_name.
##
## A ProofState is a PURE-DATA, UI-free, deterministic snapshot of exactly the
## gameplay truth that governs future behavior under the accepted M23/M24/M25/routing
## semantics — nothing more (SB-M27-001, audit §C):
##   - board ACTIVE/CLEARED mask (logical cell lifecycle, never rendered pixels);
##   - the M23 FIFO supply queues per column (front = index 0), hidden depth included as
##     data but NEVER surfaced through a player-facing API here;
##   - the five M24 slots (EMPTY, or an occupied batch with color/remaining/placement
##     sequence/lifecycle) — rightmost-empty placement pattern preserved by index;
##   - the monotonic next placement sequence.
##
## It holds an immutable reference to the source LevelData (shared, never mutated) so the
## static per-cell color map and dimensions can be reconstructed exactly. It carries NO
## live BoardState/engine, NO Node, NO instance id, NO timestamp — those are rebuilt on
## demand by ProofKernel. canonical_key() yields a deterministic dedup fingerprint that
## depends only on future-relevant truth (never Dictionary iteration order, instance ids
## or absolute sequence values — same-relative-order equivalent states collapse).

const LevelData = preload("res://scripts/data/level_data.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")

const SLOT_COUNT := 5
const ACTIVE_BYTE := 1
const CLEARED_BYTE := 0

# Immutable shared source level (color map + dimensions). Never mutated.
var level = null
# Per-cell ACTIVE(1)/CLEARED(0), row-major, length == level.get_cell_count().
var active: PackedByteArray = PackedByteArray()
# Array[column] of Array[{"id":String,"color":int,"count":int}] — FIFO, front at index 0.
var supply: Array = []
# Array[SLOT_COUNT] of null (EMPTY) or {"batch_id","color","remaining","seq","state"}.
var slots: Array = []
var next_seq: int = 1
var column_count: int = 0
var preview_depth: int = 3
var palette_size: int = 0

# --------------------------------------------------------------- construction --

## Build the INITIAL proof state for `level` + a loaded M23 BatchSupplyEngine candidate:
## every logical cell ACTIVE, five EMPTY slots, and the exact per-column FIFO supply from
## the engine's non-player-facing debug snapshot (the solver is allowed the full queue;
## the runtime player surface is not). Returns null on malformed input.
static func from_level_and_supply(p_level, supply_engine):
	if not (p_level is LevelData):
		return null
	if not (supply_engine is BatchSupplyEngine):
		return null
	var s = load("res://scripts/gameplay/solver/proof_state.gd").new()
	s.level = p_level
	var count: int = p_level.get_cell_count()
	if count <= 0:
		return null
	s.active = PackedByteArray()
	s.active.resize(count)
	s.active.fill(ACTIVE_BYTE)
	var dbg: Dictionary = supply_engine.debug_snapshot()
	s.column_count = int(dbg["column_count"])
	s.preview_depth = int(dbg["preview_depth"])
	s.palette_size = int(dbg["palette_size"])
	s.supply = []
	for col in dbg["columns"]:
		var q: Array = []
		for b in col:
			q.append({"id": String(b["batch_id"]), "color": int(b["color_id"]), "count": int(b["robot_count"])})
		s.supply.append(q)
	s.slots = []
	for _i in range(SLOT_COUNT):
		s.slots.append(null)
	s.next_seq = 1
	return s

## Build a proof state from LIVE runtime gameplay-domain engines for the read-only
## classifier (SB-M27-025..033). Reads the current BoardState ACTIVE/CLEARED mask, the M23
## supply queues (debug snapshot — never a player-facing surface), and the five M24 slots.
## committed live work is ignored (`remaining` is the accounting the classifier reasons
## over); the caller gates on M26 in-flight count separately, so a mid-flight committed
## count never reaches here. Returns null on malformed input.
static func from_runtime(p_level, board, supply_engine, slots_engine):
	if not (p_level is LevelData) or board == null or slots_engine == null:
		return null
	if not (supply_engine is BatchSupplyEngine):
		return null
	var s = load("res://scripts/gameplay/solver/proof_state.gd").new()
	s.level = p_level
	var count: int = board.get_cell_count()
	if count != p_level.get_cell_count():
		return null
	s.active = PackedByteArray()
	s.active.resize(count)
	for i in range(count):
		s.active[i] = ACTIVE_BYTE if board.get_cell_state(i) == 0 else CLEARED_BYTE
	var dbg: Dictionary = supply_engine.debug_snapshot()
	s.column_count = int(dbg["column_count"])
	s.preview_depth = int(dbg["preview_depth"])
	s.palette_size = int(dbg["palette_size"])
	s.supply = []
	for col in dbg["columns"]:
		var q: Array = []
		for b in col:
			q.append({"id": String(b["batch_id"]), "color": int(b["color_id"]), "count": int(b["robot_count"])})
		s.supply.append(q)
	s.slots = []
	var max_seq := 0
	for i in range(SLOT_COUNT):
		if not slots_engine.is_occupied(i):
			s.slots.append(null)
		else:
			var seq: int = slots_engine.get_placement_sequence(i)
			s.slots.append({"batch_id": slots_engine.get_batch_id(i), "color": slots_engine.get_color_id(i),
				"remaining": slots_engine.get_remaining(i), "seq": seq, "state": slots_engine.get_state(i)})
			max_seq = maxi(max_seq, seq)
	s.next_seq = max_seq + 1
	return s

## Deep, detached copy. The LevelData reference is shared (immutable); every mutable
## container is duplicated so search branches never alias.
func duplicate_state():
	var s = load("res://scripts/gameplay/solver/proof_state.gd").new()
	s.level = level
	s.active = active.duplicate()
	s.column_count = column_count
	s.preview_depth = preview_depth
	s.palette_size = palette_size
	s.next_seq = next_seq
	s.supply = []
	for q in supply:
		var nq: Array = []
		for b in q:
			nq.append({"id": b["id"], "color": b["color"], "count": b["count"]})
		s.supply.append(nq)
	s.slots = []
	for sd in slots:
		if sd == null:
			s.slots.append(null)
		else:
			s.slots.append({"batch_id": sd["batch_id"], "color": sd["color"],
				"remaining": sd["remaining"], "seq": sd["seq"], "state": sd["state"]})
	return s

# ------------------------------------------------------------- read-only query --

func cell_count() -> int:
	return active.size()

func active_count() -> int:
	var n := 0
	for b in active:
		if b == ACTIVE_BYTE:
			n += 1
	return n

func is_board_clear() -> bool:
	for b in active:
		if b == ACTIVE_BYTE:
			return false
	return true

func occupied_slot_count() -> int:
	var n := 0
	for sd in slots:
		if sd != null:
			n += 1
	return n

func has_empty_slot() -> bool:
	for sd in slots:
		if sd == null:
			return true
	return false

func is_supply_exhausted() -> bool:
	for q in supply:
		if not q.is_empty():
			return false
	return true

## SOLVED completion (audit §E, master prompt): every logical target cleared AND no
## occupied slot remains AND supply exhausted. Conservation guarantees these coincide,
## but all three are asserted for rigor.
func is_solved() -> bool:
	return is_board_clear() and occupied_slot_count() == 0 and is_supply_exhausted()

## Columns whose front batch is a LEGAL player action right now: a non-empty front AND at
## least one EMPTY slot (rightmost-empty placement target). Deterministic ascending order.
## When all five slots are occupied NO column is a legal placement (full-slot rejection,
## supply unchanged) — exactly the runtime rule.
func legal_action_columns() -> Array:
	var out: Array = []
	if not has_empty_slot():
		return out
	for c in range(supply.size()):
		if not supply[c].is_empty():
			out.append(c)
	return out

# ------------------------------------------------------ canonical dedup key -----

## Deterministic canonical fingerprint of ONLY future-relevant gameplay truth (audit §C).
## Board mask + per-column (color,count) FIFO + per-slot (color,remaining,seq-RANK). Slot
## placement sequences are normalized to their ascending rank among occupied slots, so two
## states identical in board+supply+slot-contents+relative-order collapse to one key
## regardless of absolute sequence history. No instance ids, no timestamps, no Dictionary
## iteration order, no rendered pixels.
func canonical_key() -> String:
	var parts: PackedStringArray = PackedStringArray()
	# Board mask as a compact run over cells (ACTIVE=1/CLEARED=0).
	var board_chars: PackedByteArray = PackedByteArray()
	board_chars.resize(active.size())
	for i in range(active.size()):
		board_chars[i] = 49 if active[i] == ACTIVE_BYTE else 48  # '1' / '0'
	parts.append(board_chars.get_string_from_ascii())
	# Supply queues.
	var sup: PackedStringArray = PackedStringArray()
	for q in supply:
		var entries: PackedStringArray = PackedStringArray()
		for b in q:
			entries.append("%d,%d" % [int(b["color"]), int(b["count"])])
		sup.append("[" + ";".join(entries) + "]")
	parts.append("|".join(sup))
	# Slot placement-sequence rank normalization.
	var seqs: Array = []
	for sd in slots:
		if sd != null:
			seqs.append(int(sd["seq"]))
	seqs.sort()
	var rank_of: Dictionary = {}
	for r in range(seqs.size()):
		rank_of[seqs[r]] = r
	var slot_strs: PackedStringArray = PackedStringArray()
	for sd in slots:
		if sd == null:
			slot_strs.append("E")
		else:
			slot_strs.append("%d,%d,%d" % [int(sd["color"]), int(sd["remaining"]), int(rank_of[int(sd["seq"])])])
	parts.append(",".join(slot_strs))
	return "".join(parts)

## Detached debug/QA view (never a player-facing surface). Includes hidden supply depth on
## purpose — this dictionary is tooling only.
func debug_view() -> Dictionary:
	return {"active_count": active_count(), "occupied_slots": occupied_slot_count(),
		"supply_remaining": _supply_counts(), "key_len": canonical_key().length()}

func _supply_counts() -> Array:
	var out: Array = []
	for q in supply:
		out.append(q.size())
	return out
