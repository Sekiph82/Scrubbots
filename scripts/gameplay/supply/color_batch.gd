extends RefCounted
## ColorBatch — M23 Batch Supply gameplay-domain value. Preload this script
## (res://scripts/gameplay/supply/color_batch.gd); do not rely on global class_name.
##
## Owner contract (OWNER_BATCH_GAMEPLAY_CORE_DECISION_V01 §3/§4): a batch carries a
## stable unique `batch_id`, a runtime `color_id` (the SAME integer LevelData /
## BoardState palette ID that ColorCandidateIndex / TargetSelector already consume —
## never a presentation name/hex), and a strictly positive integer `robot_count`
## quota (matching logical pixels to clear). Fail-closed factory: invalid
## construction returns null rather than coercing bad input. Immutable by contract —
## values are only read through getters; queries hand back detached copies so a
## caller can never mutate an engine-owned batch.

const _Self = preload("res://scripts/gameplay/supply/color_batch.gd")

var _batch_id: String = ""
var _color_id: int = -1
var _robot_count: int = 0

## Fail-closed factory. Returns a valid ColorBatch, or null for ANY invalid input.
## `palette_size` (>=0) additionally bounds color_id < palette_size. bool/float/
## String/null/object are rejected (not coerced): TYPE_BOOL != TYPE_INT in Godot 4,
## and TYPE_FLOAT/STRING/etc. are rejected explicitly.
static func make(batch_id, color_id, robot_count, palette_size: int = -1) -> _Self:
	if typeof(batch_id) != TYPE_STRING or (batch_id as String).is_empty():
		return null
	if typeof(color_id) != TYPE_INT or color_id < 0:
		return null
	if palette_size >= 0 and color_id >= palette_size:
		return null
	if typeof(robot_count) != TYPE_INT or robot_count <= 0:
		return null
	var b := _Self.new()
	b._batch_id = batch_id
	b._color_id = color_id
	b._robot_count = robot_count
	return b

func get_batch_id() -> String:
	return _batch_id

func get_color_id() -> int:
	return _color_id

func get_robot_count() -> int:
	return _robot_count

## Detached deep copy — safe to hand to a caller.
func duplicate_batch() -> _Self:
	var b := _Self.new()
	b._batch_id = _batch_id
	b._color_id = _color_id
	b._robot_count = _robot_count
	return b

## Detached plain-data view for snapshots/save/replay/UI (no live reference).
func to_dict() -> Dictionary:
	return {"batch_id": _batch_id, "color_id": _color_id, "robot_count": _robot_count}
