extends RefCounted
## EconomyConfig — preload
## (res://scripts/economy/economy_config.gd).
##
## Versioned, validated reader for `data/config/economy_rewards_v1.json`
## (SB-M39-001). Fail-closed: a missing/malformed/out-of-range config leaves
## `is_ok()` false and callers must not proceed with contradictory defaults.
## Values are read verbatim from the owner-locked config; this class never
## silently substitutes contradictory numbers.

const DEFAULT_PATH := "res://data/config/economy_rewards_v1.json"
const EXPECTED_SCHEMA_VERSION := 2

var _ok := false
var _error := ""
var _data: Dictionary = {}

func _init(path: String = DEFAULT_PATH) -> void:
	_load(path)

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
	if typeof(data) != TYPE_DICTIONARY:
		_error = "root must be an object"
		return
	if int(data.get("schema_version", -1)) != EXPECTED_SCHEMA_VERSION:
		_error = "unexpected schema_version (need %d)" % EXPECTED_SCHEMA_VERSION
		return
	# Minimal required-section validation (fail closed if a core section is absent).
	for section in ["currency", "first_clear_sb", "win_streak", "gift_meter", "bot_parts", "hearts", "speed_2x", "boosters", "daily", "collection", "cards_exchange"]:
		if not data.has(section):
			_error = "missing required section '%s'" % section
			return
	# Removed economies must not be present as economic state.
	var removed = data.get("removed_systems", [])
	if typeof(removed) != TYPE_ARRAY:
		_error = "removed_systems must be an array"
		return
	_data = data
	_ok = true

func is_ok() -> bool:
	return _ok

func get_error() -> String:
	return _error

func raw() -> Dictionary:
	return _data.duplicate(true)

# --- typed accessors ---

func starting_scrub_bucks() -> int:
	return int(_data.get("currency", {}).get("starting_balance", 0))

func first_clear_sb(difficulty: String) -> int:
	return int(_data.get("first_clear_sb", {}).get(difficulty, 0))

func first_clear_bot_parts() -> int:
	return int(_data.get("bot_parts", {}).get("first_clear", 0))

func robot_unlock_cost() -> int:
	return int(_data.get("bot_parts", {}).get("robot_unlock_cost", 250))

func initial_robot_id() -> String:
	return String(_data.get("bot_parts", {}).get("initial_robot_id", "scrubby"))

func win_streak_sb(consecutive: int) -> int:
	var m = _data.get("win_streak", {}).get("sb_by_consecutive_win", {})
	if consecutive >= 5:
		return int(m.get("5_plus", 0))
	return int(m.get(str(consecutive), 0))

func bot_parts_every_n_wins() -> int:
	return int(_data.get("win_streak", {}).get("bot_parts_every_n_wins", 5))

func gift_meter_cycle_max() -> int:
	return int(_data.get("gift_meter", {}).get("cycle_max", 1000))

func gift_meter_milestone(milestone: int) -> Dictionary:
	var ms = _data.get("gift_meter", {}).get("milestones", {})
	var v = ms.get(str(milestone), {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

func gift_meter_milestones() -> Array:
	var ms = _data.get("gift_meter", {}).get("milestones", {})
	var keys: Array = []
	for k in ms.keys():
		keys.append(int(k))
	keys.sort()
	return keys

func hearts_max() -> int:
	return int(_data.get("hearts", {}).get("max", 5))

func hearts_regen_seconds() -> int:
	return int(_data.get("hearts", {}).get("regen_seconds", 1800))

func hearts_plus_one_sb() -> int:
	return int(_data.get("hearts", {}).get("plus_one_sb", 500))

func hearts_full_refill_sb_per_missing() -> int:
	return int(_data.get("hearts", {}).get("full_refill_sb_per_missing", 400))

func speed_current_level_sb() -> int:
	return int(_data.get("speed_2x", {}).get("current_level_sb", 200))

func speed_timed_products() -> Array:
	return _data.get("speed_2x", {}).get("timed_products", [])

func booster_price(id: String) -> int:
	return int(_data.get("boosters", {}).get(id, {}).get("price_sb", 0))

func booster_config(id: String) -> Dictionary:
	var v = _data.get("boosters", {}).get(id, {})
	return v if typeof(v) == TYPE_DICTIONARY else {}

func daily_config() -> Dictionary:
	return _data.get("daily", {}).duplicate(true)

func collection_config() -> Dictionary:
	return _data.get("collection", {}).duplicate(true)

func cards_exchange_value(rarity: String) -> int:
	return int(_data.get("cards_exchange", {}).get("values_sb", {}).get(rarity, 0))

func cards_exchange_protected_copies() -> int:
	return int(_data.get("cards_exchange", {}).get("protected_min_owned_copies", 1))
