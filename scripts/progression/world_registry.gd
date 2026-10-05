extends RefCounted
## WorldRegistry — preload (res://scripts/progression/world_registry.gd).
##
## M43-C011 (SB-M43-137/139/141/142) — data-driven world registry over
## data/config/home_worlds_v1.json: world id -> background slug, title, unlock condition and
## optional reward. The current world is DERIVED from progression truth every time (never
## stored), so Home can never desynchronize from the campaign. A world only takes part in
## progression when the owner-approved data gives it a level range {first, last}; until then
## (SB-M43-136 open) the default world is current and no other world is listed as playable.
## Presentation/meta only: no solver, difficulty or level data is read or written here.

const PATH := "res://data/config/home_worlds_v1.json"

static func load_worlds(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "default": "", "worlds": {}}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY or typeof(d.get("worlds")) != TYPE_DICTIONARY or not d["worlds"].has(d.get("default_world", "")):
		return {"ok": false, "default": "", "worlds": {}}
	return {"ok": true, "default": String(d["default_world"]), "worlds": d["worlds"]}

## Ranged worlds in ascending first level ([] while no owner range exists). Overlapping or
## malformed ranges fail closed to [] (the default world stays current).
static func ranged(data: Dictionary) -> Array:
	var out: Array = []
	for id in data["worlds"]:
		var r = data["worlds"][id].get("range")
		if r == null:
			continue
		if typeof(r) != TYPE_DICTIONARY or int(r.get("first", 0)) < 1 or int(r.get("last", 0)) < int(r.get("first", 0)):
			return []
		out.append({"id": String(id), "first": int(r["first"]), "last": int(r["last"])})
	out.sort_custom(func(a, b): return a["first"] < b["first"])
	for i in range(1, out.size()):
		if out[i]["first"] <= out[i - 1]["last"]:
			return []
	return out

## Current world for a progression frontier (pure). The default when no range covers it.
static func current_world(frontier: int, data: Dictionary = {}) -> String:
	var d := data if not data.is_empty() else load_worlds()
	for w in ranged(d):
		if frontier >= int(w["first"]) and frontier <= int(w["last"]):
			return String(w["id"])
	return String(d["default"])

## "locked" | "current" | "completed" for each world (default-only data: default = current).
static func states(frontier: int, data: Dictionary = {}) -> Dictionary:
	var d := data if not data.is_empty() else load_worlds()
	var cur := current_world(frontier, d)
	var out := {}
	var rs := ranged(d)
	for id in d["worlds"]:
		out[String(id)] = "locked"
	for w in rs:
		out[w["id"]] = "completed" if frontier > int(w["last"]) else ("current" if w["id"] == cur else "locked")
	out[cur] = "current"
	return out
