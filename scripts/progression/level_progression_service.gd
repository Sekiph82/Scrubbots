extends RefCounted
## LevelProgressionService — preload
## (res://scripts/progression/level_progression_service.gd).
##
## Authoritative owner of campaign progression state:
##   - current progression level number (1-based frontier);
##   - idempotent first-clear completion set keyed by stable level number;
##   - read model for cadence class / target Challenge via M36 Difficulty V1.
##
## It is NOT UI, NOT economy, NOT the save serializer. It exposes a versioned
## snapshot()/import_snapshot() seam that M40 consumes; it never writes its own
## save file. Replay is explicitly non-advancing: replaying a completed level and
## winning again neither advances the frontier nor re-fires first-clear truth.
##
## Completion callbacks are idempotent and reject stale/invalid input, so a
## duplicate/reentrant WON callback cannot advance progression twice.

const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")

const SNAPSHOT_SCHEMA := "scrubbots.progression.v1"

var _current_level: int = 1
var _completed: Dictionary = {}     ## level_number(int) -> true (first-clear set).
var _progression: DifficultyProgressionV1

func _init(progression_model = null) -> void:
	_progression = progression_model if progression_model != null else DifficultyProgressionV1.new()

# ------------------------------------------------------ current level ----

func current_level() -> int:
	return _current_level

## Debug/test-only selection seam (SB-M37-006). Clearly NON-shipping: only used
## by tests/dev tools to jump the frontier. Rejects invalid numbers. A shipping
## level-select flow is OWNER_REQUIRED and intentionally absent.
func debug_set_current_level(n: int) -> bool:
	if n < 1:
		return false
	_current_level = n
	return true

# ------------------------------------------------------ completion ----

## Record a first-clear WON for a level number. Returns true only if this call
## caused a NEW first-clear (idempotent). Duplicate/stale/invalid calls return
## false and never advance the frontier.
##
## is_replay: when true the caller loaded a previously completed level for
## replay — completion must not advance progression or first-clear truth.
func record_win(level_number: int, is_replay: bool = false) -> bool:
	if level_number < 1:
		return false
	if is_replay:
		return false
	if _completed.has(level_number):
		return false
	# First clear.
	_completed[level_number] = true
	# Advance the frontier only when clearing the current frontier level.
	if level_number == _current_level:
		_current_level += 1
	return true

func is_completed(level_number: int) -> bool:
	return _completed.has(level_number)

func completed_count() -> int:
	return _completed.size()

# ------------------------------------------------------ difficulty read ----

func class_for(n: int) -> String:
	return _progression.class_for(n)

func target_challenge_for(n: int) -> float:
	return _progression.target_challenge_for(n)

func describe(n: int) -> Dictionary:
	return _progression.describe(n)

# ------------------------------------------------------ snapshot / import ----

## Immutable versioned snapshot for M40 persistence.
func snapshot() -> Dictionary:
	var completed_list: Array = []
	for k in _completed.keys():
		completed_list.append(k)
	completed_list.sort()
	return {
		"schema": SNAPSHOT_SCHEMA,
		"current_level": _current_level,
		"completed": completed_list,
	}

## Import a versioned snapshot. Fail-closed: a malformed/incompatible snapshot
## leaves current state untouched and returns false so M40 can fall back to a
## last-known-good or new-player default without a partial apply.
func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	if s.get("schema", "") != SNAPSHOT_SCHEMA:
		return false
	var cur = s.get("current_level", null)
	if typeof(cur) != TYPE_INT and typeof(cur) != TYPE_FLOAT:
		return false
	var cur_i := int(cur)
	if cur_i < 1:
		return false
	var completed_raw = s.get("completed", null)
	if typeof(completed_raw) != TYPE_ARRAY:
		return false
	var new_completed: Dictionary = {}
	for v in completed_raw:
		if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
			return false
		var iv := int(v)
		if iv < 1:
			return false
		new_completed[iv] = true
	# All-or-nothing apply.
	_current_level = cur_i
	_completed = new_completed
	return true
