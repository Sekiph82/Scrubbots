extends RefCounted
## M19CollabDouble — TEST-ONLY flexible RefCounted collaborator. Preload it
## (AL-001). Implements the union of the narrow dispatcher collaborator seams so
## a single instance can stand in for ANY slot (selector / reservations /
## routing_system / routing_access / select_access) in a fully-coherent bundle.
##
## Every coherence method (is_bound_to / is_coherent_with) reports true and fires
## an optional `on_check` hook first, so a test can inject recursion or reset from
## exactly one coherence seam (F-M19-STRICT-003.A). Counters make the absence of
## downstream side effects directly observable.

var on_check: Callable = Callable()
var select_calls: int = 0
var reserve_calls: int = 0
var compute_calls: int = 0

func _fire() -> void:
	if on_check.is_valid():
		on_check.call()

# coherence seams (fire the hook, report coherent)
func is_bound_to(_a, _b = null) -> bool:
	_fire()
	return true

func is_coherent_with(_a, _b, _c) -> bool:
	_fire()
	return true

# selector seam
func select_and_reserve(_color: int, _owner: int, _access) -> int:
	select_calls += 1
	return -1

# reservation seam
func reserve(_t: int, _o: int) -> bool:
	reserve_calls += 1
	return false
func release(_t: int, _o: int) -> bool:
	return false
func release_for_owner(_o: int) -> bool:
	return false
func get_target_for_owner(_o: int) -> int:
	return -1
func get_owner(_t: int) -> int:
	return -1
func is_reserved(_t: int) -> bool:
	return false
func get_reserved_indices() -> PackedInt32Array:
	return PackedInt32Array()
func get_reservation_count() -> int:
	return 0

# routing_system seam
func compute_route(_req, _board, _acc):
	compute_calls += 1
	return null

# routing_access seam
func is_segment_traversable(_a: Vector2, _b: Vector2, _i: int) -> bool:
	return true

# select_access seam
func is_targetable(_i: int) -> bool:
	return false
func set_origin(_o: Vector2) -> void:
	pass
func consume_route(_i: int):
	return null
