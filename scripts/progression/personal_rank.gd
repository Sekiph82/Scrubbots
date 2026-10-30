extends RefCounted
## PersonalRank — preload (res://scripts/progression/personal_rank.gd).
##
## SB-M43-122 (owner 2026-10-31, "personal rank"): the player's own rank ladder
## (data/config/personal_ranks_v1.json). Pure and read-only: the rank is derived from
## campaign levels cleared on every read, never saved, never compared with other players
## and grants nothing. A malformed table fails closed (no tiers, empty result).

const PATH := "res://data/config/personal_ranks_v1.json"
const SCHEMA := "scrubbots.personal_ranks.v1"
const METRIC := "campaign_levels_cleared"

## Validated ascending tiers, or [] when the file is missing / malformed.
static func load_tiers(path: String = PATH) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(path)) != OK:
		return []
	var d = j.data
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA or d.get("metric") != METRIC or typeof(d.get("tiers")) != TYPE_ARRAY or d["tiers"].is_empty():
		return []
	var out: Array = []
	var seen := {}
	for t in d["tiers"]:
		if typeof(t) != TYPE_DICTIONARY or typeof(t.get("id")) != TYPE_STRING or seen.has(t["id"]) or typeof(t.get("name_key")) != TYPE_STRING:
			return []
		var m = t.get("min_cleared")
		if (typeof(m) != TYPE_FLOAT and typeof(m) != TYPE_INT) or float(m) != floorf(float(m)):
			return []
		if (out.is_empty() and int(m) != 0) or (not out.is_empty() and int(m) <= int(out[-1]["min_cleared"])):
			return []
		seen[t["id"]] = true
		out.append({"id": t["id"], "name_key": t["name_key"], "min_cleared": int(m)})
	return out

## Rank for `n` cleared levels (negative clamps to 0): {index, id, name_key, min_cleared,
## next_id ("" at the top), next_min (-1 at the top), into, span}. into / span = progress
## inside the current tier; the top tier has no span (span 0, into = levels past it).
## {} when the table is invalid.
static func for_cleared(n: int, path: String = PATH) -> Dictionary:
	var tiers := load_tiers(path)
	if tiers.is_empty():
		return {}
	n = maxi(0, n)
	var i := 0
	while i + 1 < tiers.size() and n >= int(tiers[i + 1]["min_cleared"]):
		i += 1
	var t: Dictionary = tiers[i]
	var r := {"index": i, "id": t["id"], "name_key": t["name_key"], "min_cleared": t["min_cleared"],
		"next_id": "", "next_min": -1, "into": n - int(t["min_cleared"]), "span": 0}
	if i + 1 < tiers.size():
		r["next_id"] = tiers[i + 1]["id"]
		r["next_min"] = tiers[i + 1]["min_cleared"]
		r["span"] = int(r["next_min"]) - int(t["min_cleared"])
	return r
