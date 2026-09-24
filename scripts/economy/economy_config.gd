extends RefCounted
## EconomyConfig — preload
## (res://scripts/economy/economy_config.gd).
##
## Versioned, validated reader for `data/config/economy_rewards_v1.json`
## (SB-M39-001). Fail-closed: a missing/malformed/out-of-range config leaves
## `is_ok()` false and callers must not proceed with contradictory defaults.
##
## Strict schema (M39 V03, F-M39-V02-011): `schema_version` must be an EXACT
## integer (int or integral float only — 2.9 fails); every owner-locked section
## has explicit type/domain validation for the values M39 consumes.

const IntDomain = preload("res://scripts/economy/int_domain.gd")

const DEFAULT_PATH := "res://data/config/economy_rewards_v1.json"
const EXPECTED_SCHEMA_VERSION := 2
const DIFFICULTIES := ["EASY", "MEDIUM", "HARD", "VERY_HARD"]

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
	# Strict schema_version type/value (F-M39-V02-011). 2.9 must not slip through.
	var sv = IntDomain.exact_int(data.get("schema_version", null))
	if sv == null or sv != EXPECTED_SCHEMA_VERSION:
		_error = "unexpected schema_version (need exact %d)" % EXPECTED_SCHEMA_VERSION
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
	# Validate the exact owner-locked values M39 consumes (F-M39-V02-011).
	var ve := _validate_values(data)
	if not ve.is_empty():
		_error = ve
		return
	_data = data
	_ok = true

## Enforce exact type/domain for every owner-locked value M39 reads. Returns "" on
## success or a diagnostic reason on failure.
func _validate_values(data: Dictionary) -> String:
	# currency.starting_balance is non-negative int
	var start = IntDomain.nonneg_int(data.get("currency", {}).get("starting_balance", null))
	if start == null: return "currency.starting_balance must be a non-negative integer"
	# first_clear_sb entries for each difficulty are non-negative int
	var fc = data.get("first_clear_sb", {})
	for d in DIFFICULTIES:
		var v = IntDomain.nonneg_int(fc.get(d, null))
		if v == null: return "first_clear_sb.%s must be a non-negative integer" % d
	# win_streak table
	var ws = data.get("win_streak", {})
	var sbc = ws.get("sb_by_consecutive_win", {})
	for k in ["1", "2", "3", "4", "5_plus"]:
		var v = IntDomain.nonneg_int(sbc.get(k, null))
		if v == null: return "win_streak.sb_by_consecutive_win.%s must be a non-negative integer" % k
	var bpn = IntDomain.exact_int(ws.get("bot_parts_every_n_wins", null))
	if bpn == null or bpn < 1: return "win_streak.bot_parts_every_n_wins must be a positive integer"
	# gift_meter.cycle_max positive int
	var cm = IntDomain.exact_int(data.get("gift_meter", {}).get("cycle_max", null))
	if cm == null or cm < 1: return "gift_meter.cycle_max must be a positive integer"
	# bot_parts.robot_unlock_cost positive int
	var bp = data.get("bot_parts", {})
	var cost = IntDomain.exact_int(bp.get("robot_unlock_cost", null))
	if cost == null or cost < 1: return "bot_parts.robot_unlock_cost must be a positive integer"
	var initial = bp.get("initial_robot_id", null)
	if typeof(initial) != TYPE_STRING or String(initial).is_empty(): return "bot_parts.initial_robot_id must be a non-empty string"
	# hearts
	var h = data.get("hearts", {})
	var hmax = IntDomain.exact_int(h.get("max", null))
	if hmax == null or hmax < 1: return "hearts.max must be a positive integer"
	var reg = IntDomain.exact_int(h.get("regen_seconds", null))
	if reg == null or reg < 1: return "hearts.regen_seconds must be a positive integer"
	for k in ["plus_one_sb", "full_refill_sb_per_missing"]:
		var v = IntDomain.nonneg_int(h.get(k, null))
		if v == null: return "hearts.%s must be a non-negative integer" % k
	# speed_2x current-level price
	var sp = data.get("speed_2x", {})
	var slv = IntDomain.nonneg_int(sp.get("current_level_sb", null))
	if slv == null: return "speed_2x.current_level_sb must be a non-negative integer"
	var timed = sp.get("timed_products", null)
	if typeof(timed) != TYPE_ARRAY: return "speed_2x.timed_products must be an array"
	for p in timed:
		if typeof(p) != TYPE_DICTIONARY: return "speed_2x.timed_products entry must be an object"
		var secs = IntDomain.exact_int(p.get("seconds", null))
		var pr = IntDomain.nonneg_int(p.get("sb", null))
		if secs == null or secs < 1 or pr == null: return "speed_2x.timed_products entry must have positive-int seconds + non-neg int sb"
	# boosters: exactly the four canonical entries, each with a non-negative price_sb
	var boosters = data.get("boosters", {})
	for id in ["plus_one_slot", "random", "selector", "tornado"]:
		if not boosters.has(id): return "boosters.%s missing" % id
		var price = IntDomain.nonneg_int(boosters.get(id, {}).get("price_sb", null))
		if price == null: return "boosters.%s.price_sb must be a non-negative integer" % id
	return ""

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
