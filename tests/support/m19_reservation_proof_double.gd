extends RefCounted
## M19ReservationProofDouble — TEST-ONLY ReservationState-compatible stand-in for
## the dispatcher's own reservation layer (V05 malformed-ownership-proof + boundary
## bracketing). Preload it (AL-001). Real storage for reserve/release/
## release_for_owner/get_reserved_indices, plus per-call FORCE overrides and hooks
## on get_target_for_owner / get_owner so a test can inject a malformed return,
## reset, or dependency drift at an exact ownership-callback ordinal. is_bound_to
## reports coherent (true) — the RETURN CONTRACT is under test, not coherence.

var _board = null
var _t2o: Dictionary = {}
var _o2t: Dictionary = {}

var owner_query_calls: int = 0   ## get_target_for_owner invocation counter
var get_owner_calls: int = 0     ## get_owner invocation counter

## Forced returns applied when the invocation ordinal matches (-1 = never force).
var tfo_force = null
var tfo_force_at: int = -1
var owner_force = null
var owner_force_at: int = -1

## Side-effect hooks (fire with the current call ordinal) for reset/drift injection.
var on_owner_query: Callable = Callable()
var on_get_owner: Callable = Callable()

func bind(board) -> bool:
	_board = board
	return true

func is_bound_to(board) -> bool:
	return _board != null and _board == board

func reserve(target_index: int, owner_id: int) -> bool:
	if _t2o.has(target_index):
		return false
	if _o2t.has(owner_id):
		return false
	_t2o[target_index] = owner_id
	_o2t[owner_id] = target_index
	return true

func release(target_index: int, owner_id: int) -> bool:
	if _t2o.get(target_index, -999) != owner_id:
		return false
	_t2o.erase(target_index)
	_o2t.erase(owner_id)
	return true

func release_for_owner(owner_id: int) -> bool:
	if not _o2t.has(owner_id):
		return false
	var t: int = _o2t[owner_id]
	_t2o.erase(t)
	_o2t.erase(owner_id)
	return true

func get_target_for_owner(owner_id: int):
	owner_query_calls += 1
	if on_owner_query.is_valid():
		on_owner_query.call(owner_query_calls)
	if tfo_force_at == owner_query_calls:
		return tfo_force
	return _o2t.get(owner_id, -1)

func get_owner(target_index: int):
	get_owner_calls += 1
	if on_get_owner.is_valid():
		on_get_owner.call(get_owner_calls)
	if owner_force_at == get_owner_calls:
		return owner_force
	return _t2o.get(target_index, -1)

func get_reserved_indices() -> PackedInt32Array:
	var keys: Array = _t2o.keys()
	keys.sort()
	var out := PackedInt32Array()
	out.resize(keys.size())
	for i in keys.size():
		out[i] = keys[i]
	return out

func get_reservation_count() -> int:
	return _t2o.size()
