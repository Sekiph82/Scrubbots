extends RefCounted
## DifficultyProgressionV1 — preload
## (res://scripts/difficulty/difficulty_progression_v1.gd).
##
## Versioned reader for the owner-locked cadence + target-curve model in
## `data/config/level_progression_v1.json`. Pure, deterministic, config-driven:
## given a 1-based campaign level number `n` it returns the canonical difficulty
## class, the campaign-age target Challenge Score, and the cadence role. It does
## NOT analyze a specific level's structure (that is ChallengeScoreModelV1) and
## it does NOT derive class from board dimensions (owner decision 2026-09-12).
##
## Model (from the locked config):
##   slot(n) = ((n-1) mod cadenceLength) + 1
##   k(n)    = floor((n-1) / cadenceLength)
##   P(k)    = 1 - exp(-k / tauCycles)          (saturating exponential)
##   target(n) = lane.base + lane.growth * P(k) + cadence[slot].modifier
##
## The class of slot s is the owner-locked repeating cadence (EASY/MEDIUM/HARD/
## VERY_HARD). Target rises with campaign age k but the class/role repeat, so a
## later EASY (e.g. level 311) is a richer relief lane than an early EASY
## (level 11) without ceasing to be relief relative to its local boss.

const DEFAULT_CONFIG_PATH := "res://data/config/level_progression_v1.json"
const EXPECTED_SCHEMA := "scrubbots-level-progression/v1"

var _loaded := false
var _error := ""
var _cadence_length := 10
var _tau := 20.0
var _cadence := []                 ## Array of {slot, class, modifier, role, noveltyTarget}
var _lanes := {}                   ## class -> {base, growth}
var _recovery_guards := []

func _init(config_path: String = DEFAULT_CONFIG_PATH) -> void:
	_load(config_path)

func _load(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_error = "cannot open %s (err %d)" % [path, FileAccess.get_open_error()]
		return
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		_error = "malformed JSON line %d: %s" % [json.get_error_line(), json.get_error_message()]
		return
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY or data.get("schema", "") != EXPECTED_SCHEMA:
		_error = "unexpected schema"
		return
	_cadence_length = int(data.get("cadenceLength", 10))
	var prog = data.get("progression", {})
	_tau = float(prog.get("tauCycles", 20.0))
	_cadence = data.get("cadence", [])
	var lanes_raw = data.get("lanes", {})
	for k in lanes_raw.keys():
		_lanes[k] = {"base": float(lanes_raw[k].get("base", 0.0)), "growth": float(lanes_raw[k].get("growth", 0.0))}
	_recovery_guards = data.get("recoveryGuards", [])
	# Validate cadence length matches declared array.
	if _cadence.size() != _cadence_length:
		_error = "cadence array size %d != cadenceLength %d" % [_cadence.size(), _cadence_length]
		return
	_loaded = true

func is_ok() -> bool:
	return _loaded

func get_error() -> String:
	return _error

func cadence_length() -> int:
	return _cadence_length

## 1-based slot index within the repeating cadence.
func slot_for(n: int) -> int:
	assert(n >= 1)
	return ((n - 1) % _cadence_length) + 1

## Campaign-age cycle index (0 for the first cadence, 1 for the second, ...).
func cycle_for(n: int) -> int:
	assert(n >= 1)
	return int(floor(float(n - 1) / float(_cadence_length)))

## Saturating exponential P(k) in [0,1).
func progression_p(k: int) -> float:
	return 1.0 - exp(-float(k) / _tau)

func class_for(n: int) -> String:
	var slot := slot_for(n)
	return String(_cadence[slot - 1].get("class", ""))

func role_for(n: int) -> String:
	var slot := slot_for(n)
	return String(_cadence[slot - 1].get("role", ""))

func modifier_for(n: int) -> float:
	var slot := slot_for(n)
	return float(_cadence[slot - 1].get("modifier", 0.0))

func novelty_target_for(n: int) -> float:
	var slot := slot_for(n)
	return float(_cadence[slot - 1].get("noveltyTarget", 0.0))

## Owner-locked campaign-age target Challenge Score for level n. Clamped 0..100.
func target_challenge_for(n: int) -> float:
	var cls := class_for(n)
	if not _lanes.has(cls):
		return 0.0
	var k := cycle_for(n)
	var p := progression_p(k)
	var lane = _lanes[cls]
	var target: float = lane.base + lane.growth * p + modifier_for(n)
	return clampf(target, 0.0, 100.0)

## Structured read model for one level number.
func describe(n: int) -> Dictionary:
	return {
		"level": n,
		"slot": slot_for(n),
		"cycle": cycle_for(n),
		"class": class_for(n),
		"role": role_for(n),
		"modifier": modifier_for(n),
		"p": progression_p(cycle_for(n)),
		"target_challenge": target_challenge_for(n),
		"novelty_target": novelty_target_for(n),
	}

func recovery_guards() -> Array:
	return _recovery_guards.duplicate(true)
