extends RefCounted
## RobotRoster — preload (res://scripts/progression/robot_roster.gd).
##
## M43 master (SB-M43-070 onward) — read-only loader for the canonical 10-robot roster
## (data/config/robot_roster_v1.json, restating coordination/OWNER_ROBOT_ROSTER_V01.md).
## Identity / display data only: name, role, canonical 20% meta perk text + icon and the
## per-robot asset family. It applies no perk and owns no unlock / Bot Parts truth
## (RobotUnlockService does). Fails closed: a malformed file yields an empty roster.

const PATH := "res://data/config/robot_roster_v1.json"
const SCHEMA := "scrubbots.robot_roster.v1"
const COUNT := 10
const ASSET_KEYS := ["master", "portrait", "home_pose", "gameplay", "profile_portrait", "help_pose", "victory_pose"]

static var _cache: Dictionary = {}

## {ok, reason, robots:[entry...]} (order 1..10). Cached after the first successful load.
static func load_roster(path: String = PATH) -> Dictionary:
	if path == PATH and not _cache.is_empty():
		return _cache
	var r := _load(path)
	if path == PATH and r["ok"]:
		_cache = r
	return r

static func _load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _fail("missing")
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA:
		return _fail("schema")
	var list = d.get("robots")
	if typeof(list) != TYPE_ARRAY or list.size() != COUNT:
		return _fail("count")
	var seen := {}
	for i in range(list.size()):
		var e = list[i]
		if typeof(e) != TYPE_DICTIONARY or int(e.get("order", -1)) != i + 1:
			return _fail("order")
		var id = e.get("id")
		if typeof(id) != TYPE_STRING or String(id).is_empty() or seen.has(id):
			return _fail("id")
		seen[id] = true
		for k in ["name", "role", "perk_name", "perk_text"]:
			if typeof(e.get(k)) != TYPE_STRING or String(e[k]).is_empty():
				return _fail("text_" + k)
		var a = e.get("assets")
		if typeof(a) != TYPE_DICTIONARY:
			return _fail("assets")
		for k in ASSET_KEYS:
			if typeof(a.get(k)) != TYPE_STRING or not String(a[k]).begins_with("res://"):
				return _fail("asset_" + k)
	if String(list[0]["id"]) != String(d.get("initial_robot_id", "")):
		return _fail("initial")
	return {"ok": true, "reason": "", "robots": list, "initial_robot_id": String(d["initial_robot_id"]),
		"unlock_cost": int(d.get("unlock_cost_bot_parts", 0))}

static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "robots": [], "initial_robot_id": "", "unlock_cost": 0}

static func ids() -> Array:
	return load_roster()["robots"].map(func(e): return String(e["id"]))

## Roster entry for `id` ({} when unknown).
static func entry(id: String) -> Dictionary:
	for e in load_roster()["robots"]:
		if String(e["id"]) == id:
			return (e as Dictionary).duplicate(true)
	return {}

## An asset path for `id`, falling back to Scrubby's when the robot's own file is missing
## (a missing presentation asset never breaks a screen; SB-M43-111).
static func asset(id: String, key: String) -> String:
	var e := entry(id)
	var p := String((e.get("assets", {}) as Dictionary).get(key, ""))
	if not p.is_empty() and ResourceLoader.exists(p):
		return p
	var s := entry(String(load_roster()["initial_robot_id"]))
	return String((s.get("assets", {}) as Dictionary).get(key, ""))

## First robot in canonical order that `robots` (RobotUnlockService) has not unlocked, or "".
static func next_locked(robots) -> String:
	for id in ids():
		if not robots.is_unlocked(id):
			return id
	return ""
