extends RefCounted
## FiveSlotBatchEngine — M24 production five-slot batch engine. Preload this script
## (res://scripts/gameplay/slots/five_slot_batch_engine.gd); do not rely on global
## class_name. Gameplay-domain ONLY: no Control/UI/Node, no target selection, no
## reservation/routing/dispatch/spawn, no solvability. It owns exactly five
## SlotBatchState slots plus the transactional handoff to the accepted M23
## BatchSupplyEngine and an opaque committed-work ledger for future M25/M26.
##
## Transaction serialization (M24 V02, F-M24-V01-STRICT-001): a single engine-owned
## `_busy` guard is held for the WHOLE supply-placement transaction (which may call
## external M23 code from begin_front_selection AND commit). While `_busy`, EVERY public
## M24 mutator — select_front_batch, commit_work, resolve_clear, rollback_work,
## set_claimable_work_available, pause, resume, reset — fails closed with zero state
## change. reset() never clears/reopens the guard while busy. A synchronous re-entrant
## callback from M23 therefore cannot cause slot/queue split-brain or stale-target
## placement.
##
## Owner-locked behavior (OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01):
## - exactly five slots, all EMPTY initially; slot count is not configurable;
## - the player selects an M23 supply COLUMN/front batch, never a destination slot;
## - an accepted batch is placed automatically into the RIGHTMOST currently EMPTY slot;
## - occupied slots never shift/reorder/compact; holes stay holes until filled;
## - all five occupied => atomic rejection, and M23 supply does NOT advance;
## - same-color batches remain independent identities (BLUE 8 / 14 / 12 coexist);
## - 0 <= committed <= remaining_to_clear <= initial_count; capacity = remaining-committed;
## - remaining_to_clear drops ONLY on authenticated resolve of a previously committed
##   live work identity; rollback reduces only committed;
## - completion requires remaining==0 AND committed==0, then the slot becomes EMPTY;
## - WAITING preserves the batch; an authoritative claimability notification resumes ACTIVE.
##
## M24 does NOT choose targets, reserve pixels, route, spawn robots, or claim
## solvability. Committed-work identities are opaque accounting only; they carry no
## target-selection authority. M25/M26 will connect real claim/dispatch/clear authority.

const SlotBatchState = preload("res://scripts/gameplay/slots/slot_batch_state.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")

const SLOT_COUNT := 5               # baseline attempt capacity (unchanged default)
const MAX_CAPACITY := 6             # temporary +1 Slot booster cap; never 7+
const INITIAL_SEQUENCE := 1

# Physical slots: `SLOT_COUNT` at baseline, grown to `MAX_CAPACITY` for the
# current attempt only when the +1 Slot booster activates. `_slots.size()` is the
# ONE authoritative active capacity every placement/full/rightmost-empty query
# honors (M39 V02, F-M39-001). reset() returns to the baseline five.
var _slots: Array = []              # active-capacity SlotBatchState (EMPTY or occupied)
var _next_sequence: int = INITIAL_SEQUENCE
var _live_work: Dictionary = {}     # work_id -> {"slot": int, "batch_id": String}
var _busy: bool = false             # re-entrancy guard for the external-collaborator path
var _paused: bool = false           # informational; M24 state is time-independent

func _init() -> void:
	for _i in range(SLOT_COUNT):
		_slots.append(SlotBatchState.make_empty())

# --------------------------------------------------------- read-only queries --

## Active capacity — the number of physical slots for the current attempt (5 or
## 6). This is the authoritative capacity the solver and runtime read.
func get_slot_count() -> int:
	return _slots.size()

func active_capacity() -> int:
	return _slots.size()

func _valid_index(i) -> bool:
	return typeof(i) == TYPE_INT and i >= 0 and i < _slots.size()

func is_empty(i) -> bool:
	return _valid_index(i) and _slots[i].is_empty()

func is_occupied(i) -> bool:
	return _valid_index(i) and _slots[i].is_occupied()

func get_state(i) -> String:
	return _slots[i].get_state() if _valid_index(i) else SlotBatchState.EMPTY

func get_batch_id(i) -> String:
	return _slots[i].get_batch_id() if _valid_index(i) else ""

func get_color_id(i) -> int:
	return _slots[i].get_color_id() if _valid_index(i) else -1

func get_initial_count(i) -> int:
	return _slots[i].get_initial_count() if _valid_index(i) else 0

func get_remaining(i) -> int:
	return _slots[i].get_remaining_to_clear() if _valid_index(i) else 0

func get_committed(i) -> int:
	return _slots[i].get_committed() if _valid_index(i) else 0

func get_capacity(i) -> int:
	return _slots[i].get_capacity() if _valid_index(i) else 0

func get_placement_sequence(i) -> int:
	return _slots[i].get_placement_sequence() if _valid_index(i) else -1

func occupied_count() -> int:
	var n := 0
	for s in _slots:
		if s.is_occupied():
			n += 1
	return n

func is_full() -> bool:
	return occupied_count() == _slots.size()

## +1 Slot booster: grow to a temporary sixth slot for the CURRENT attempt only,
## at most once (5 -> 6). The new EMPTY slot is appended at the rightmost index.
## Fails closed (no change) while a placement transaction is busy, if already at
## MAX_CAPACITY, or if capacity is not the baseline five. reset() restores five.
func grow_to_sixth() -> bool:
	if _busy:
		return false
	if _slots.size() != SLOT_COUNT:
		return false
	_slots.append(SlotBatchState.make_empty())
	return true

func can_grow_to_sixth() -> bool:
	return not _busy and _slots.size() == SLOT_COUNT

func is_paused() -> bool:
	return _paused

func live_work_count() -> int:
	return _live_work.size()

## Detached per-slot snapshot array (index 0..4). Mutating returned dicts/array cannot
## mutate engine truth (each entry is a fresh plain Dictionary).
func snapshot() -> Array:
	var out: Array = []
	for s in _slots:
		out.append(s.to_dict())
	return out

## Index of the rightmost EMPTY slot, or -1 if all occupied. Honors the current
## active capacity (5 or 6).
func rightmost_empty_index() -> int:
	for i in range(_slots.size() - 1, -1, -1):
		if _slots[i].is_empty():
			return i
	return -1

# ----------------------------------------------- supply -> slot placement (WP02) --

## Player selects an M23 supply COLUMN/front batch (never a slot). On success the batch
## is placed in the rightmost EMPTY slot and exactly one M23 front is consumed. Atomic:
## there is no reachable state where M23 consumed but M24 failed to place, or vice
## versa — the only fallible cross-engine step is supply commit, and the post-commit
## placement is a single infallible array assignment. Returns a detached result dict.
func select_front_batch(supply_engine, column) -> Dictionary:
	if _busy:
		return {"ok": false, "error": "reentrant"}
	_busy = true
	var result := _select_front_batch_guarded(supply_engine, column)
	_busy = false
	return result

func _select_front_batch_guarded(supply_engine, column) -> Dictionary:
	if not (supply_engine is BatchSupplyEngine):
		return {"ok": false, "error": "bad_supply"}
	# Full-five rejection happens BEFORE any M23 interaction: supply is never touched.
	var target := rightmost_empty_index()
	if target == -1:
		return {"ok": false, "error": "slots_full"}
	# Begin the M23 two-phase selection (does NOT pop the queue).
	var tx = supply_engine.begin_front_selection(column)
	if tx == null:
		return {"ok": false, "error": "no_front"}
	# Validate the detached batch snapshot against the M24 state contract.
	var front = tx.get_front_batch()
	if front == null:
		supply_engine.cancel(tx)
		return {"ok": false, "error": "no_front_batch"}
	var batch_id = front.get_batch_id()
	var color_id = front.get_color_id()
	var count = front.get_robot_count()
	# Duplicate batch-id defense across occupied slots.
	if _batch_id_occupied(batch_id):
		supply_engine.cancel(tx)
		return {"ok": false, "error": "duplicate_batch_id"}
	# Pre-build the occupied slot state (non-committing). Fail-closed on malformed data.
	var placed = SlotBatchState.make_occupied(batch_id, color_id, count, _next_sequence)
	if placed == null:
		supply_engine.cancel(tx)
		return {"ok": false, "error": "malformed_batch"}
	# Commit is the LAST fallible step. If it fails, nothing was placed and supply is
	# left exactly as the engine reports (stale/consumed token is consumed by M23).
	if not supply_engine.commit(tx):
		return {"ok": false, "error": "supply_commit_failed"}
	# Infallible placement: single array assignment.
	_slots[target] = placed
	_next_sequence += 1
	return {"ok": true, "slot": target, "placement": placed.to_dict()}

func _batch_id_occupied(batch_id) -> bool:
	for s in _slots:
		if s.is_occupied() and s.get_batch_id() == batch_id:
			return true
	return false

# ------------------------------------------- opaque committed-work ledger (WP03) --

## Register one opaque live committed-work unit against an occupied slot. work_id must be
## a non-empty String, globally unique while live. Requires capacity > 0. Increases
## committed by exactly one; leaves remaining_to_clear unchanged. Accounting only — the
## work identity carries NO target/route/robot authority.
func commit_work(slot_index, work_id) -> bool:
	if _busy:
		return false
	if not _valid_index(slot_index):
		return false
	if typeof(work_id) != TYPE_STRING or (work_id as String).is_empty():
		return false
	if _live_work.has(work_id):
		return false
	var s = _slots[slot_index]
	if s.is_empty():
		return false
	if not s.apply_commit():
		return false
	_live_work[work_id] = {"slot": slot_index, "batch_id": s.get_batch_id()}
	return true

## Resolve one previously committed live work identity as an authenticated successful
## clear. Located by engine-owned slot/batch record (never caller-mutable fields):
## committed-1 AND remaining-1; then completion check may free the slot. Fails closed
## for unknown/stale/double identities.
func resolve_clear(work_id) -> bool:
	if _busy:
		return false
	if not _live_work.has(work_id):
		return false
	var rec: Dictionary = _live_work[work_id]
	var idx: int = rec["slot"]
	var s = _slots[idx]
	# Engine-owned identity check: the same occupied batch must still be there.
	if s.is_empty() or s.get_batch_id() != rec["batch_id"]:
		return false
	if not s.apply_resolve():
		return false
	_live_work.erase(work_id)
	if s.is_complete():
		_free_slot(idx)
	return true

## Roll back one previously committed live work identity: committed-1 only,
## remaining_to_clear unchanged. Fails closed for unknown/stale/double identities.
func rollback_work(work_id) -> bool:
	if _busy:
		return false
	if not _live_work.has(work_id):
		return false
	var rec: Dictionary = _live_work[work_id]
	var idx: int = rec["slot"]
	var s = _slots[idx]
	if s.is_empty() or s.get_batch_id() != rec["batch_id"]:
		return false
	if not s.apply_rollback():
		return false
	_live_work.erase(work_id)
	return true

## Read-only EXACT work-tuple binding query for the M25 claim layer (M25-C001 V03 seam).
## NON-MUTATING and policy-neutral. Returns true ONLY when work_id names a live committed
## identity whose engine-owned record is bound to the EXACT slot + batch_id the M25 ledger
## expects AND that slot still holds that exact batch. This is strictly stronger than "live
## and internally coherent somewhere": it rejects a work id that was externally rolled back
## from batch A and re-committed to a different batch B, because the M25 caller passes A's
## slot/batch and the redirected record now points at B. Adds no target/route/robot meaning
## and never exposes the mutable ledger. Lets M25 preflight all-or-nothing rollback/finalize/
## teardown against the exact claim tuple, never a merely-live foreign work id.
func is_work_bound_to(work_id, expected_slot, expected_batch_id) -> bool:
	if typeof(work_id) != TYPE_STRING or not _live_work.has(work_id):
		return false
	if typeof(expected_slot) != TYPE_INT or typeof(expected_batch_id) != TYPE_STRING:
		return false
	var rec: Dictionary = _live_work[work_id]
	# The M24 record itself must still name the exact expected slot + batch.
	if int(rec["slot"]) != expected_slot or String(rec["batch_id"]) != expected_batch_id:
		return false
	# And that exact slot must still be occupied by that exact batch (no free/refilled slot).
	if not _valid_index(expected_slot):
		return false
	var s = _slots[expected_slot]
	return not s.is_empty() and s.get_batch_id() == expected_batch_id

## Tornado reconciliation seam (M39 V02). Frees an UNTOUCHED occupied slot (ACTIVE,
## committed==0, remaining==initial, no live work) to EMPTY and returns the captured
## batch so the caller can restore it exactly on rollback. Fails closed (returns
## {"ok": false}) for a busy engine, invalid index, empty slot, or any slot with
## committed work / partial progress / WAITING state — so a purge never silently
## drops in-flight or partially-cleared work.
func free_slot_if_idle(index) -> Dictionary:
	if _busy or not _valid_index(index):
		return {"ok": false}
	var s = _slots[index]
	if s.is_empty():
		return {"ok": false}
	if s.get_state() != SlotBatchState.ACTIVE:
		return {"ok": false}
	if s.get_committed() != 0 or s.get_remaining() != s.get_initial_count():
		return {"ok": false}
	# Drop any live work keyed to this slot (there is none when committed==0, but
	# stay defensive) and empty it.
	var captured := {"batch_id": s.get_batch_id(), "color": s.get_color_id(),
		"count": s.get_initial_count(), "seq": s.get_placement_sequence()}
	_free_slot(index)
	return {"ok": true, "batch": captured}

## Rollback companion to free_slot_if_idle: re-occupy an EMPTY slot with a
## previously-captured untouched batch, restoring exact prior state. Fails closed
## for a busy engine, invalid/occupied index, or malformed capture.
func restore_idle_slot(index, batch: Dictionary) -> bool:
	if _busy or not _valid_index(index):
		return false
	if not _slots[index].is_empty():
		return false
	var placed = SlotBatchState.make_occupied(batch.get("batch_id"), batch.get("color"),
		batch.get("count"), batch.get("seq"))
	if placed == null:
		return false
	_slots[index] = placed
	return true

func _free_slot(idx: int) -> void:
	# Return to exact EMPTY truth; drop any live work still keyed to this slot. Neighbors
	# are never shifted/compacted.
	for wid in _live_work.keys():
		if int(_live_work[wid]["slot"]) == idx:
			_live_work.erase(wid)
	_slots[idx] = SlotBatchState.make_empty()

# --------------------------------------------- WAITING / ACTIVE state machine (WP03) --

## Authoritative claimability notification seam (supplied by the future M25 claim layer).
## available=false may move an occupied ACTIVE batch with capacity to WAITING;
## available=true resumes a WAITING batch to ACTIVE automatically (no player
## re-selection). EMPTY/completed slots cannot transition. Never mutates counters or the
## M23 supply. Returns true only when a legal transition/state confirmation occurred.
func set_claimable_work_available(slot_index, available) -> bool:
	if _busy:
		return false
	if not _valid_index(slot_index):
		return false
	if typeof(available) != TYPE_BOOL:
		return false
	var s = _slots[slot_index]
	if s.is_empty():
		return false
	if available:
		if s.get_state() == SlotBatchState.WAITING:
			s.set_state(SlotBatchState.ACTIVE)
			return true
		return s.get_state() == SlotBatchState.ACTIVE  # already active — no-op success
	else:
		if s.get_state() == SlotBatchState.ACTIVE and s.get_capacity() > 0:
			s.set_state(SlotBatchState.WAITING)
			return true
		return false

# --------------------------------------------------------- pause / reset (WP04) --

## Pause/resume are no-ops on slot/batch/counter/ordering state: all M24 state is
## time-independent. Provided as an explicit persisted seam so a session-level pause can
## record intent without mutating engine truth.
func pause() -> void:
	if _busy:
		return
	_paused = true

func resume() -> void:
	if _busy:
		return
	_paused = false

## Reset M24 to its own initial production state: five EMPTY slots, cleared live work
## identities, placement sequence back to INITIAL_SEQUENCE, cleared WAITING/ACTIVE and
## pending-transaction guard. Pre-reset work identities/snapshots cannot mutate engine
## truth afterward. M24 reset does NOT own or reset M23 supply — a session-level caller
## must reset both explicitly if desired. Fails closed (returns false, mutates nothing,
## and critically does NOT touch the `_busy` guard) if invoked re-entrantly while a
## placement transaction is active. Ordinary (non-busy) reset returns true.
func reset() -> bool:
	if _busy:
		return false
	_slots = []
	for _i in range(SLOT_COUNT):   # new attempt returns to the baseline five
		_slots.append(SlotBatchState.make_empty())
	_live_work.clear()
	_next_sequence = INITIAL_SEQUENCE
	_paused = false
	return true
