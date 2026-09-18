extends RefCounted
## M26 test double: deterministic slot-origin provider. Maps slot_index -> a fixed
## board-local Vector2 origin. Mirrors the read-only seam AutoDispatchScheduler
## consumes (origin_for_slot). A slot with no configured origin returns the shared
## default (used by adversarial "wrong slot origin" cases when set non-finite).

var _by_slot: Dictionary = {}
var _default: Vector2 = Vector2(-1.5, 10.0)

func _init(by_slot: Dictionary = {}, default_origin: Vector2 = Vector2(-1.5, 10.0)) -> void:
	_by_slot = by_slot.duplicate()
	_default = default_origin

func set_origin(slot_index: int, origin: Vector2) -> void:
	_by_slot[slot_index] = origin

func origin_for_slot(slot_index: int) -> Vector2:
	if _by_slot.has(slot_index):
		return _by_slot[slot_index]
	return _default
