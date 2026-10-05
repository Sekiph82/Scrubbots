extends RefCounted
## EventService — preload (res://scripts/economy/event_service.gd).
##
## M43-C010 / C010R (SB-M43-128/129, R10-001..005) — EVENTS templates driven only by the
## versioned config data/config/events_v1.json (nothing is scheduled by code):
##   - Weekly Cleaning Event: a 7-day window; committed first-clear progression wins during the
##     window count automatically (no ads / spend / replays); fixed milestones grant only the
##     approved existing reward types through RewardGrantService (tx `event:<id>:<i>`, once).
##     Missing a day never resets progress. An event without an explicit
##     `unclaimed_on_expiry` policy ("forfeit" | "claim_after_end") is invalid and never listed.
##   - First-Try Cleanup: opt-in; `levels` qualifying progression levels in a row, each cleared
##     on its first attempt. A first-attempt loss resets only this run (never the campaign); no
##     Heart, continue or rewind is involved. The reward is fixed and shown before joining.
## No event currency exists. Economy section `events`: absent = nothing joined/claimed.

const PATH := "res://data/config/events_v1.json"
const SCHEMA := "scrubbots.events.v1"
const WEEK_S := 7 * 86400
const POLICIES := ["forfeit", "claim_after_end"]
const SNAPSHOT_VERSION := 1

var _clock: Callable
var _weekly: Array = []          ## validated weekly event defs
var _first_try = null            ## validated First-Try def or null
var _state := {}                 ## weekly id -> {progress:int, claimed:[int]}
var _ft := {}                    ## {id, joined, run, claimed}
var config_ok := false

func _init(clock: Callable = Callable(), path: String = PATH) -> void:
	_clock = clock if clock.is_valid() else func(): return int(Time.get_unix_time_from_system())
	load_config(path)

func now() -> int:
	return int(_clock.call())

## Loads + validates. An invalid entry is dropped (never listed); a malformed file lists nothing.
func load_config(path: String) -> void:
	_weekly = []
	_first_try = null
	config_ok = false
	if not FileAccess.file_exists(path):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA:
		return
	var types: Array = d.get("approved_reward_types", [])
	for e in d.get("weekly_events", []):
		if _valid_weekly(e, types):
			_weekly.append(e)
	var ft = d.get("first_try_cleanup")
	if typeof(ft) == TYPE_DICTIONARY and typeof(ft.get("id")) == TYPE_STRING and int(ft.get("levels", 0)) >= 1 and _valid_reward(ft.get("reward"), types):
		_first_try = ft
	config_ok = true

static func _valid_reward(r, types: Array) -> bool:
	if typeof(r) != TYPE_DICTIONARY or r.is_empty():
		return false
	for k in r:
		if not types.has(k) or (typeof(r[k]) != TYPE_INT and typeof(r[k]) != TYPE_FLOAT) or int(r[k]) <= 0 or float(r[k]) != float(int(r[k])):
			return false
	return true

static func _valid_weekly(e, types: Array) -> bool:
	if typeof(e) != TYPE_DICTIONARY or typeof(e.get("id")) != TYPE_STRING or String(e["id"]).is_empty():
		return false
	if typeof(e.get("start_ts")) != TYPE_FLOAT and typeof(e.get("start_ts")) != TYPE_INT:
		return false
	if not POLICIES.has(e.get("unclaimed_on_expiry")):
		return false
	var ms = e.get("milestones")
	if typeof(ms) != TYPE_ARRAY or ms.is_empty():
		return false
	var last := 0
	for m in ms:
		if typeof(m) != TYPE_DICTIONARY or int(m.get("target", 0)) <= last or not _valid_reward(m.get("reward"), types):
			return false
		last = int(m["target"])
	return true

# ------------------------------------------------------------- weekly ----

func _phase(e: Dictionary) -> String:
	var t := now()
	var start := int(e["start_ts"])
	if t < start:
		return "upcoming"
	if t < start + WEEK_S:
		return "active"
	return "ended"

## Events to list: active, upcoming, and ended ones that still hold a claimable reward.
func list() -> Array:
	var out: Array = []
	for e in _weekly:
		var v := view(String(e["id"]))
		if v["phase"] != "ended" or v["claimable"] > 0:
			out.append(v)
	return out

func view(id: String) -> Dictionary:
	for e in _weekly:
		if String(e["id"]) == id:
			var st: Dictionary = _state.get(id, {"progress": 0, "claimed": []})
			var phase := _phase(e)
			var ms: Array = []
			var claimable := 0
			for i in range(e["milestones"].size()):
				var m: Dictionary = e["milestones"][i]
				var reached: bool = int(st["progress"]) >= int(m["target"])
				var claimed: bool = (st["claimed"] as Array).has(i)
				var can: bool = reached and not claimed and (phase == "active" or (phase == "ended" and e["unclaimed_on_expiry"] == "claim_after_end"))
				if can:
					claimable += 1
				ms.append({"target": int(m["target"]), "reward": (m["reward"] as Dictionary).duplicate(), "reached": reached, "claimed": claimed, "claimable": can})
			return {"id": id, "kind": "weekly", "phase": phase, "progress": int(st["progress"]), "milestones": ms,
				"claimable": claimable, "ends_in": maxi(0, int(e["start_ts"]) + WEEK_S - now()), "starts_in": maxi(0, int(e["start_ts"]) - now()),
				"policy": String(e["unclaimed_on_expiry"])}
	return {}

func claim_weekly(id: String, index: int, reward_service) -> Dictionary:
	var v := view(id)
	if v.is_empty() or index < 0 or index >= v["milestones"].size():
		return {"ok": false, "reason": "not_found"}
	if not bool(v["milestones"][index]["claimable"]):
		return {"ok": false, "reason": "already_claimed" if v["milestones"][index]["claimed"] else ("expired" if v["phase"] == "ended" else "not_reached")}
	var tx := "event:%s:%d" % [id, index]
	if not reward_service.grant(tx, v["milestones"][index]["reward"]) and not reward_service.already_applied(tx):
		return {"ok": false, "reason": "grant_failed"}
	var st: Dictionary = _state.get(id, {"progress": 0, "claimed": []})
	(st["claimed"] as Array).append(index)
	_state[id] = st
	return {"ok": true, "reward": v["milestones"][index]["reward"]}

# ------------------------------------------------------------ First-Try ----

func first_try() -> Dictionary:
	if _first_try == null:
		return {}
	var id := String(_first_try["id"])
	var mine: bool = String(_ft.get("id", "")) == id
	var run := int(_ft.get("run", 0)) if mine else 0
	var levels := int(_first_try["levels"])
	return {"id": id, "levels": levels, "reward": (_first_try["reward"] as Dictionary).duplicate(),
		"joined": mine and bool(_ft.get("joined", false)), "run": mini(run, levels),
		"complete": run >= levels, "claimed": mine and bool(_ft.get("claimed", false))}

func join_first_try() -> Dictionary:
	var f := first_try()
	if f.is_empty():
		return {"ok": false, "reason": "no_event"}
	if f["joined"]:
		return {"ok": false, "reason": "already_joined"}
	_ft = {"id": f["id"], "joined": true, "run": 0, "claimed": false}
	return {"ok": true}

func claim_first_try(reward_service) -> Dictionary:
	var f := first_try()
	if f.is_empty() or not f["joined"] or not f["complete"] or f["claimed"]:
		return {"ok": false, "reason": "not_claimable"}
	var tx := "event:first_try:%s" % f["id"]
	if not reward_service.grant(tx, f["reward"]) and not reward_service.already_applied(tx):
		return {"ok": false, "reason": "grant_failed"}
	_ft["claimed"] = true
	return {"ok": true, "reward": f["reward"]}

# ---------------------------------------------------------- play signal ----

## A committed progression terminal (the host's latched WON / LOST). `first_try` from
## PlayerRecords. Replays never reach this (non-progression attempts are not reported).
func on_progression_terminal(won: bool, first_try_attempt: bool) -> void:
	if won:
		for e in _weekly:
			if _phase(e) == "active":
				var st: Dictionary = _state.get(String(e["id"]), {"progress": 0, "claimed": []})
				st["progress"] = int(st["progress"]) + 1
				_state[String(e["id"])] = st
	var f := first_try()
	if not f.is_empty() and f["joined"] and not f["complete"] and first_try_attempt:
		_ft["run"] = int(_ft["run"]) + 1 if won else 0

func claimable_count() -> int:
	var n := 0
	for v in list():
		n += int(v["claimable"])
	var f := first_try()
	if not f.is_empty() and f["joined"] and f["complete"] and not f["claimed"]:
		n += 1
	return n

func snapshot() -> Dictionary:
	return {"version": SNAPSHOT_VERSION, "weekly": _state.duplicate(true), "first_try": _ft.duplicate()}

func import_snapshot(s) -> bool:
	if s == null:
		_state = {}
		_ft = {}
		return true
	if typeof(s) != TYPE_DICTIONARY or int(s.get("version", -1)) != SNAPSHOT_VERSION or typeof(s.get("weekly")) != TYPE_DICTIONARY or typeof(s.get("first_try")) != TYPE_DICTIONARY:
		return false
	var nw := {}
	for id in s["weekly"]:
		var st = s["weekly"][id]
		if typeof(id) != TYPE_STRING or typeof(st) != TYPE_DICTIONARY or not _is_int(st.get("progress")) or int(st["progress"]) < 0 or typeof(st.get("claimed")) != TYPE_ARRAY:
			return false
		var cl: Array = []
		for c in st["claimed"]:
			if not _is_int(c) or int(c) < 0 or cl.has(int(c)):
				return false
			cl.append(int(c))
		nw[id] = {"progress": int(st["progress"]), "claimed": cl}
	var ft: Dictionary = s["first_try"]
	if not ft.is_empty():
		if typeof(ft.get("id")) != TYPE_STRING or typeof(ft.get("joined")) != TYPE_BOOL or typeof(ft.get("claimed")) != TYPE_BOOL or not _is_int(ft.get("run")) or int(ft["run"]) < 0:
			return false
		ft = {"id": String(ft["id"]), "joined": ft["joined"], "run": int(ft["run"]), "claimed": ft["claimed"]}
	_state = nw
	_ft = ft
	return true

static func _is_int(v) -> bool:
	return (typeof(v) == TYPE_INT) or (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floor(v))
