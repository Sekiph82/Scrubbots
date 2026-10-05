extends RefCounted
## ReturnService — preload (res://scripts/economy/return_service.gd).
##
## M43-C012 / C012R (SB-M43-143/144, R12-001..003) — absence detection + Comeback Catch-Up.
##   - `last_active_ts` + a monotonic high-water mark; a return counts as a genuine absence only
##     when now - last_active >= absence_s (owner-approved initial candidate 48 h, versioned in
##     data/config/comeback_v1.json). A clock rollback below the high-water mark never counts.
##   - Each genuine return opens ONE return window (id = the absence start ts). The comeback
##     summary is shown once per window; it only points at already-claimable state.
##   - Catch-Up Track: offered once per window ONLY when the config defines a reward sequence of
##     approved existing reward types (none is configured yet -> never offered). Three
##     qualifying first-clear progression wins advance it; each step grants once (tx
##     `catchup:<window>:<step>`); it expires deterministically at window + expire_s. It never
##     touches Daily login state, events or level economy.
## Economy section `return`: absent = fresh (no window); present = strict.

const PATH := "res://data/config/comeback_v1.json"
const SCHEMA := "scrubbots.comeback.v1"
const SNAPSHOT_VERSION := 1

var _clock: Callable
var absence_s := 48 * 3600
var expire_s := 7 * 86400
var _steps: Array = []                 ## [{wins, reward}] validated; [] = Catch-Up disabled
var _last := 0                         ## last active ts
var _high := 0                         ## highest ts ever seen
var _window := 0                       ## current return window id (absence start ts) or 0
var _window_ts := 0                    ## when the window opened
var _summary_shown := 0                ## window id whose summary was shown
var _catchup := {}                     ## {window, wins, claimed:[step]}

func _init(clock: Callable = Callable(), path: String = PATH) -> void:
	_clock = clock if clock.is_valid() else func(): return int(Time.get_unix_time_from_system())
	load_config(path)

func load_config(path: String) -> void:
	_steps = []
	if not FileAccess.file_exists(path):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA:
		return
	absence_s = maxi(3600, int(d.get("absence_hours", 48)) * 3600)
	expire_s = maxi(86400, int(d.get("catchup_expire_days", 7)) * 86400)
	var types: Array = d.get("approved_reward_types", [])
	var steps = d.get("catchup_steps")
	if typeof(steps) != TYPE_ARRAY:
		return
	var last := 0
	var out: Array = []
	for st in steps:
		if typeof(st) != TYPE_DICTIONARY or int(st.get("wins", 0)) <= last or typeof(st.get("reward")) != TYPE_DICTIONARY or st["reward"].is_empty():
			return
		for k in st["reward"]:
			if not types.has(k) or int(st["reward"][k]) <= 0:
				return
		last = int(st["wins"])
		out.append(st)
	if last > 3:
		return   # owner row: three qualifying wins at most
	_steps = out

func now() -> int:
	return int(_clock.call())

## App became active (boot / resume). Opens a return window on a genuine absence.
func on_active() -> Dictionary:
	var t := now()
	var opened := false
	if t >= _high:
		if _last > 0 and t - _last >= absence_s and _window != _last:
			_window = _last
			_window_ts = t
			opened = true
			if not _steps.is_empty() and _catchup.get("window", 0) != _window:
				_catchup = {"window": _window, "wins": 0, "claimed": []}
		_last = t
		_high = t
	return {"opened": opened, "window": _window}

## Lifecycle flush (pause / focus out / close): the player was active until now.
func touch() -> void:
	var t := now()
	if t >= _high:
		_last = t
		_high = t

func summary_due() -> bool:
	return _window != 0 and _summary_shown != _window and now() < _window_ts + expire_s

func mark_summary_shown() -> void:
	_summary_shown = _window

func catchup() -> Dictionary:
	if _steps.is_empty() or _catchup.is_empty() or int(_catchup["window"]) != _window:
		return {}
	# A clock behind the high-water mark (rollback) freezes the track like an expiry.
	var expired: bool = now() >= _window_ts + expire_s or now() < _high
	var steps: Array = []
	for i in range(_steps.size()):
		var reached: bool = int(_catchup["wins"]) >= int(_steps[i]["wins"])
		var claimed: bool = (_catchup["claimed"] as Array).has(i)
		steps.append({"wins": int(_steps[i]["wins"]), "reward": (_steps[i]["reward"] as Dictionary).duplicate(), "reached": reached, "claimed": claimed, "claimable": reached and not claimed and not expired})
	return {"window": _window, "wins": int(_catchup["wins"]), "steps": steps, "expired": expired}

## A committed first-clear progression win (never a replay / loss / purchase).
func on_first_clear_win() -> void:
	var c := catchup()
	if c.is_empty() or c["expired"]:
		return
	_catchup["wins"] = mini(int(_catchup["wins"]) + 1, int(_steps[_steps.size() - 1]["wins"]))

func claim_catchup(step: int, reward_service) -> Dictionary:
	var c := catchup()
	if c.is_empty() or step < 0 or step >= c["steps"].size() or not c["steps"][step]["claimable"]:
		return {"ok": false, "reason": "not_claimable"}
	var tx := "catchup:%d:%d" % [_window, step]
	if not reward_service.grant(tx, c["steps"][step]["reward"]) and not reward_service.already_applied(tx):
		return {"ok": false, "reason": "grant_failed"}
	(_catchup["claimed"] as Array).append(step)
	return {"ok": true, "reward": c["steps"][step]["reward"]}

func snapshot() -> Dictionary:
	return {"version": SNAPSHOT_VERSION, "last": _last, "high": _high, "window": _window, "window_ts": _window_ts,
		"summary_shown": _summary_shown, "catchup": _catchup.duplicate(true)}

func import_snapshot(s) -> bool:
	if s == null:
		_last = 0; _high = 0; _window = 0; _window_ts = 0; _summary_shown = 0; _catchup = {}
		return true
	if typeof(s) != TYPE_DICTIONARY or int(s.get("version", -1)) != SNAPSHOT_VERSION:
		return false
	for k in ["last", "high", "window", "window_ts", "summary_shown"]:
		if not _is_int(s.get(k)) or int(s[k]) < 0:
			return false
	if int(s["high"]) < int(s["last"]):
		return false
	var c = s.get("catchup")
	if typeof(c) != TYPE_DICTIONARY:
		return false
	if not c.is_empty():
		if not _is_int(c.get("window")) or not _is_int(c.get("wins")) or int(c["wins"]) < 0 or typeof(c.get("claimed")) != TYPE_ARRAY:
			return false
		c = {"window": int(c["window"]), "wins": int(c["wins"]), "claimed": c["claimed"].map(func(v): return int(v))}
	_last = int(s["last"]); _high = int(s["high"]); _window = int(s["window"]); _window_ts = int(s["window_ts"])
	_summary_shown = int(s["summary_shown"]); _catchup = c
	return true

static func _is_int(v) -> bool:
	return (typeof(v) == TYPE_INT) or (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floor(v))
