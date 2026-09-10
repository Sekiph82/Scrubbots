extends RefCounted
## M15ReservationDouble — TEST-ONLY configurable ReservationState stand-in for the
## M15-C002 strict-v2 second-stage boundary (F-M15-STRICT-004/005). Preload it
## (AL-001). Exposes the full reservation API the selector requires and behaves
## correctly by default, but every dynamic return can be forced malformed and
## reserve() can lie about (or skip) what it stored, so a test can prove the
## selector validates each collaborator return and proves exact ownership before
## returning a target.

const _NONE := -999999  ## sentinel for "no override"

var _board = null
var _t2o: Dictionary = {}   ## target_index -> owner_id
var _o2t: Dictionary = {}   ## owner_id -> target_index

## Forced malformed returns. When a *_force is non-null, that method returns it
## verbatim instead of its real value (used to inject wrong-typed returns).
var target_for_owner_force = null
var reserved_indices_force = null
var is_reserved_force = null
var reserve_force = null
var get_owner_force = null

## reserve() storage behaviour.
var do_store: bool = true            ## false -> reserve returns success but stores nothing
var store_target_override: int = _NONE  ## store this target index instead of idx
var store_owner_override: int = _NONE   ## store idx under this owner instead of owner_id
var on_reserve: Callable = Callable()   ## side effect run inside reserve() (drift injection)

func bind(board) -> bool:
	_board = board
	return true

func rebind(board) -> bool:
	_board = board
	_t2o.clear()
	_o2t.clear()
	return true

func is_bound_to(board) -> bool:
	return _board != null and _board == board

func get_reserved_indices():
	if reserved_indices_force != null:
		return reserved_indices_force
	var keys: Array = _t2o.keys()
	keys.sort()
	var out := PackedInt32Array()
	out.resize(keys.size())
	for i in keys.size():
		out[i] = keys[i]
	return out

func get_candidates(_c, _e):
	return []  # never used as candidate index; present only if duck-typed

func is_reserved(target_index: int):
	if is_reserved_force != null:
		return is_reserved_force
	return _t2o.has(target_index)

func get_owner(target_index: int):
	if get_owner_force != null:
		return get_owner_force
	return _t2o.get(target_index, -1)

func get_target_for_owner(owner_id: int):
	if target_for_owner_force != null:
		return target_for_owner_force
	return _o2t.get(owner_id, -1)

func reserve(target_index: int, owner_id: int):
	if on_reserve.is_valid():
		on_reserve.call(target_index, owner_id)
	if do_store:
		var t := target_index if store_target_override == _NONE else store_target_override
		var o := owner_id if store_owner_override == _NONE else store_owner_override
		_t2o[t] = o
		_o2t[o] = t
	if reserve_force != null:
		return reserve_force
	return true

func release(target_index: int, owner_id: int) -> bool:
	if not _t2o.has(target_index):
		return false
	if _t2o[target_index] != owner_id:
		return false
	_t2o.erase(target_index)
	_o2t.erase(owner_id)
	return true

func get_reservation_count() -> int:
	return _t2o.size()
