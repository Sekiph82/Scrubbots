extends RefCounted
## PlayerRecords — preload (res://scripts/economy/player_records.gd).
##
## M43-C010 / C010R (SB-M43-124, R10-004..007) — self-comparison mastery records fed only by
## committed progression terminals (the gameplay host's latched WON / LOST): best Win Streak,
## boosterless first clears (count + current/best run) and the first-try run (consecutive
## progression levels cleared on their first attempt). Presentation/meta only: nothing here
## changes difficulty, rewards or gameplay truth, and nothing is compared with other players.
## Economy section `records`: absent = all zero; present = strict.

const SNAPSHOT_VERSION := 1
const KEYS := ["best_win_streak", "boosterless_wins", "boosterless_run", "best_boosterless_run",
	"first_try_run", "best_first_try_run", "attempt_level", "attempts_on_level"]

var _v: Dictionary = {}

func _init() -> void:
	_reset()

func _reset() -> void:
	_v = {}
	for k in KEYS:
		_v[k] = 0

func get_value(key: String) -> int:
	return int(_v.get(key, 0))

func all() -> Dictionary:
	return _v.duplicate()

## A progression attempt reached a terminal. `won`: WON committed; `boosters_used`: committed
## booster actions this attempt; `streak`: Win Streak after the commit. Returns
## {first_try: bool} for event consumers (the attempt was the level's first).
func on_progression_terminal(level: int, won: bool, boosters_used: int, streak: int) -> Dictionary:
	if int(_v["attempt_level"]) != level:
		_v["attempt_level"] = level
		_v["attempts_on_level"] = 0
	_v["attempts_on_level"] = int(_v["attempts_on_level"]) + 1
	var first_try: bool = int(_v["attempts_on_level"]) == 1
	if won:
		_v["best_win_streak"] = maxi(int(_v["best_win_streak"]), streak)
		if boosters_used == 0:
			_v["boosterless_wins"] = int(_v["boosterless_wins"]) + 1
			_v["boosterless_run"] = int(_v["boosterless_run"]) + 1
			_v["best_boosterless_run"] = maxi(int(_v["best_boosterless_run"]), int(_v["boosterless_run"]))
		else:
			_v["boosterless_run"] = 0
		_v["first_try_run"] = int(_v["first_try_run"]) + 1 if first_try else 0
		_v["best_first_try_run"] = maxi(int(_v["best_first_try_run"]), int(_v["first_try_run"]))
	else:
		_v["first_try_run"] = 0
	return {"first_try": first_try}

func snapshot() -> Dictionary:
	var s := _v.duplicate()
	s["version"] = SNAPSHOT_VERSION
	return s

func import_snapshot(s) -> bool:
	if s == null:
		_reset()
		return true
	if typeof(s) != TYPE_DICTIONARY or not _is_int(s.get("version")) or int(s["version"]) != SNAPSHOT_VERSION:
		return false
	var nv := {}
	for k in KEYS:
		if not _is_int(s.get(k)) or int(s[k]) < 0:
			return false
		nv[k] = int(s[k])
	_v = nv
	return true

static func _is_int(v) -> bool:
	return (typeof(v) == TYPE_INT) or (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floor(v))
