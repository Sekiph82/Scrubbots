extends RefCounted
## FtueConfig — preload (res://scripts/app/ftue_config.gd).
##
## M44 (SB-M44-001/010/011/016) — strict reader of the versioned, data-driven onboarding file
## data/config/ftue_onboarding_v1.json (owner V03 values): the new-profile starter booster
## charges, the first-day Welcome task, the compulsory tutorial window (<= L3) and its lesson
## steps and the once-per-version What's New entries. Feature unlock gating is NOT here: it is
## the owner table data/config/feature_unlocks_v1.json (scripts/progression/feature_unlocks.gd).
## Any malformed field rejects the WHOLE file (ok:false) — a broken config means no starter
## grant and no tips (fail closed), never a partial or invented onboarding.

const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

const PATH := "res://data/config/ftue_onboarding_v1.json"
const SCHEMA := "scrubbots.ftue_onboarding.v1"
const VERSION := 1
## Owner V03: the entire compulsory tutorial fits L1..L3 at most.
const OWNER_MAX_TUTORIAL_LEVEL := 3
const SURFACES := ["home", "gameplay"]
const TARGETS := ["", "shortcut:daily", "shortcut:tasks", "play", "supply_front", "supply_preview", "slots", "board", "boosters", "speed"]
const WHEN := ["daily_claimable", "tasks_claimable"]
const COMPLETE_ON := ["shortcut:daily", "shortcut:tasks", "play", "supply_placed"]

static func load_config(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _bad("missing")
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return validate(d)

static func validate(d) -> Dictionary:
	if typeof(d) != TYPE_DICTIONARY or str(d.get("schema")) != SCHEMA or not _int_eq(d.get("version"), VERSION):
		return _bad("schema")
	var sc = d.get("starter_booster_charges")
	if typeof(sc) != TYPE_DICTIONARY or sc.size() != BoosterInventory.BOOSTERS.size():
		return _bad("starter_booster_charges")
	var starter := {}
	for id in BoosterInventory.BOOSTERS:
		if not sc.has(id) or not _is_int(sc[id]) or int(sc[id]) < 0:
			return _bad("starter_booster_charges")
		starter[id] = int(sc[id])
	var w = d.get("first_day_welcome_task")
	if typeof(w) != TYPE_DICTIONARY or not _int_eq(w.get("task_index"), 0) or not _is_int(w.get("scrub_bucks")) or int(w["scrub_bucks"]) < 1:
		return _bad("first_day_welcome_task")
	var mx = d.get("max_tutorial_level")
	if not _is_int(mx) or int(mx) < 1 or int(mx) > OWNER_MAX_TUTORIAL_LEVEL:
		return _bad("max_tutorial_level")
	var whats_new: Array = []
	if typeof(d.get("whats_new")) != TYPE_ARRAY:
		return _bad("whats_new")
	for e in d["whats_new"]:
		if typeof(e) != TYPE_DICTIONARY or not _str(e.get("feature_id")) or not _is_int(e.get("version")) or int(e["version"]) < 1 \
				or not _str(e.get("name")) or not _str(e.get("body")) or not _str(e.get("icon")):
			return _bad("whats_new")
		whats_new.append((e as Dictionary).duplicate(true))
	var lessons: Array = []
	var lesson_ids := {}
	var step_ids := {}
	if typeof(d.get("lessons")) != TYPE_ARRAY:
		return _bad("lessons")
	for l in d["lessons"]:
		if typeof(l) != TYPE_DICTIONARY or not _str(l.get("id")) or lesson_ids.has(l["id"]) or not SURFACES.has(l.get("surface")):
			return _bad("lesson")
		if not _is_int(l.get("level")) or int(l["level"]) < 1 or int(l["level"]) > int(mx):
			return _bad("lesson_level")   # never a lesson beyond the compulsory window (L4+)
		if l["surface"] == "gameplay" and not _str(l.get("level_id")):
			return _bad("lesson_level_id")
		if typeof(l.get("steps")) != TYPE_ARRAY or (l["steps"] as Array).is_empty():
			return _bad("lesson_steps")
		lesson_ids[l["id"]] = true
		var steps: Array = []
		for s in l["steps"]:
			if typeof(s) != TYPE_DICTIONARY or not _str(s.get("id")) or step_ids.has(s["id"]):
				return _bad("step_id")
			if typeof(s.get("target", "")) != TYPE_STRING or not TARGETS.has(s.get("target", "")):
				return _bad("step_target")
			if s.has("when") and not WHEN.has(s["when"]):
				return _bad("step_when")
			if s.has("complete_on") and not COMPLETE_ON.has(s["complete_on"]):
				return _bad("step_complete_on")
			if not _str(s.get("title")) or not _str(s.get("body")):
				return _bad("step_copy")
			if s.has("boosters"):
				if typeof(s["boosters"]) != TYPE_ARRAY or (s["boosters"] as Array).is_empty():
					return _bad("step_boosters")
				for b in s["boosters"]:
					if not BoosterInventory.BOOSTERS.has(b):
						return _bad("step_boosters")
			step_ids[s["id"]] = true
			var st: Dictionary = (s as Dictionary).duplicate(true)
			st["lesson"] = String(l["id"])
			st["target"] = String(s.get("target", ""))
			steps.append(st)
		lessons.append({"id": String(l["id"]), "surface": String(l["surface"]), "level": int(l["level"]),
			"level_id": String(l.get("level_id", "")), "steps": steps})
	return {"ok": true, "reason": "", "version": VERSION, "starter_booster_charges": starter,
		"welcome_task_index": 0, "welcome_sb": int(w["scrub_bucks"]), "max_tutorial_level": int(mx),
		"whats_new": whats_new, "lessons": lessons}

static func _bad(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}

static func _str(v) -> bool:
	return typeof(v) == TYPE_STRING and not String(v).is_empty()

static func _is_int(v) -> bool:
	return typeof(v) == TYPE_INT or (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floor(v))

static func _int_eq(v, n: int) -> bool:
	return _is_int(v) and int(v) == n
