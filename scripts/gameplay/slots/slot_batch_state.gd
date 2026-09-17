extends RefCounted
## SlotBatchState — M24 Five-Slot Batch Engine per-slot gameplay-domain state. Preload
## this script (res://scripts/gameplay/slots/slot_batch_state.gd); do not rely on global
## class_name. Pure data/accounting — NO Control/UI/Node, NO target selection, NO
## reservation/routing/dispatch/spawn, NO BoardState truth.
##
## A slot is either EMPTY (no batch identity/color/count/work) or occupied
## (ACTIVE|WAITING) carrying exactly one M23 batch identity plus its accounting:
##   batch_id, canonical color_id, initial_count, remaining_to_clear, committed,
##   placement_sequence, lifecycle state.
##
## Invariant enforced on every mutation: 0 <= committed <= remaining_to_clear <=
## initial_count. Capacity = remaining_to_clear - committed. All mutators fail closed
## (return false, no change) rather than violate the invariant. Historical
## slot_state.gd / slot_system.gd (direct-color M21/M22) are untouched by this class.

const EMPTY := "EMPTY"
const ACTIVE := "ACTIVE"
const WAITING := "WAITING"

var _state: String = EMPTY
var _batch_id: String = ""
var _color_id: int = -1
var _initial_count: int = 0
var _remaining_to_clear: int = 0
var _committed: int = 0
var _placement_sequence: int = -1

## An EMPTY slot with no stale batch truth.
static func make_empty() -> RefCounted:
	return load("res://scripts/gameplay/slots/slot_batch_state.gd").new()

## Fail-closed factory for a freshly placed occupied slot (ACTIVE, committed 0,
## remaining == initial). Returns null for ANY malformed input.
static func make_occupied(batch_id, color_id, initial_count, placement_sequence) -> RefCounted:
	if typeof(batch_id) != TYPE_STRING or (batch_id as String).is_empty():
		return null
	if typeof(color_id) != TYPE_INT or color_id < 0:
		return null
	if typeof(initial_count) != TYPE_INT or initial_count <= 0:
		return null
	if typeof(placement_sequence) != TYPE_INT or placement_sequence < 0:
		return null
	var s = load("res://scripts/gameplay/slots/slot_batch_state.gd").new()
	s._state = ACTIVE
	s._batch_id = batch_id
	s._color_id = color_id
	s._initial_count = initial_count
	s._remaining_to_clear = initial_count
	s._committed = 0
	s._placement_sequence = placement_sequence
	return s

func is_empty() -> bool:
	return _state == EMPTY

func is_occupied() -> bool:
	return _state != EMPTY

func get_state() -> String:
	return _state

func get_batch_id() -> String:
	return _batch_id

func get_color_id() -> int:
	return _color_id

func get_initial_count() -> int:
	return _initial_count

func get_remaining_to_clear() -> int:
	return _remaining_to_clear

func get_committed() -> int:
	return _committed

func get_placement_sequence() -> int:
	return _placement_sequence

## Dispatch capacity: remaining work not yet committed. 0 for EMPTY.
func get_capacity() -> int:
	if _state == EMPTY:
		return 0
	return _remaining_to_clear - _committed

## Register one committed live work unit. Fails closed unless occupied with capacity.
func apply_commit() -> bool:
	if _state == EMPTY:
		return false
	if _remaining_to_clear - _committed <= 0:
		return false
	_committed += 1
	return _invariant_ok()

## Resolve one committed unit as an authenticated successful clear: committed-1 AND
## remaining-1. Fails closed unless there is a live committed unit.
func apply_resolve() -> bool:
	if _state == EMPTY or _committed <= 0 or _remaining_to_clear <= 0:
		return false
	_committed -= 1
	_remaining_to_clear -= 1
	return _invariant_ok()

## Roll back one committed unit: committed-1 only, remaining unchanged.
func apply_rollback() -> bool:
	if _state == EMPTY or _committed <= 0:
		return false
	_committed -= 1
	return _invariant_ok()

## A batch is complete only at remaining == 0 AND committed == 0.
func is_complete() -> bool:
	return _state != EMPTY and _remaining_to_clear == 0 and _committed == 0

func set_state(new_state: String) -> void:
	_state = new_state

## Detached plain-data view — safe to hand to a caller; mutating it cannot mutate the
## engine's state.
func to_dict() -> Dictionary:
	if _state == EMPTY:
		return {"state": EMPTY, "occupied": false, "batch_id": "", "color_id": -1,
			"initial_count": 0, "remaining_to_clear": 0, "committed": 0,
			"capacity": 0, "placement_sequence": -1}
	return {"state": _state, "occupied": true, "batch_id": _batch_id, "color_id": _color_id,
		"initial_count": _initial_count, "remaining_to_clear": _remaining_to_clear,
		"committed": _committed, "capacity": _remaining_to_clear - _committed,
		"placement_sequence": _placement_sequence}

func _invariant_ok() -> bool:
	return 0 <= _committed and _committed <= _remaining_to_clear \
		and _remaining_to_clear <= _initial_count
