extends RefCounted
## RouteNonBoolAccessQueryDouble — M16 adversarial test double. Preload it (AL-001).
##
## It satisfies the access seam SHAPE (has is_segment_traversable/3) but returns a
## non-bool `verdict_value` (int/string/null) so tests can prove the validator
## fails closed on a malformed verdict type instead of trusting a truthy value.
## `call_count` proves whether the validator queried at all.

## The non-bool value returned for every segment (e.g. 1, "yes", null).
var verdict_value = 1
var call_count: int = 0

func is_segment_traversable(_from_position: Vector2, _to_position: Vector2, _target_index: int):
	call_count += 1
	return verdict_value
