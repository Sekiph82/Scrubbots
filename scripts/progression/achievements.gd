extends RefCounted
## Achievements — preload (res://scripts/progression/achievements.gd).
##
## M43-C010 (SB-M43-126) — data-driven achievement framework (data/config/achievements_v1.json).
## Read-only: every metric is a monotonic lifetime or personal-best value already owned by
## a canonical service (progression, Collection, robots, PlayerRecords), so completion is
## derived and can never be lost or double-granted. No reward is attached (owner policy
## pending); achievements never touch gameplay truth.

const PATH := "res://data/config/achievements_v1.json"
const SCHEMA := "scrubbots.achievements.v1"
const METRICS := ["levels_completed", "sets_completed", "robots_unlocked", "cards_unique", "best_win_streak",
	"boosterless_wins", "best_boosterless_run", "best_first_try_run"]

static func load_defs(path: String = PATH) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA or typeof(d.get("achievements")) != TYPE_ARRAY:
		return []
	var seen := {}
	for a in d["achievements"]:
		if typeof(a) != TYPE_DICTIONARY or typeof(a.get("id")) != TYPE_STRING or seen.has(a["id"]) or not METRICS.has(a.get("metric")) or int(a.get("target", 0)) < 1:
			return []
		seen[a["id"]] = true
	return d["achievements"]

## Live lifetime / personal-best stats from the canonical services (read-only).
static func stats(app) -> Dictionary:
	var e = app.economy
	var unique := 0
	for cid in e.collection.all_card_ids():
		if e.collection.owned(cid) > 0:
			unique += 1
	return {
		"levels_completed": int(app.progression.completed_count()),
		"sets_completed": int(e.collection.completed_set_count()),
		"robots_unlocked": int(e.robots.unlocked_count()),
		"cards_unique": unique,
		"best_win_streak": maxi(int(e.records.get_value("best_win_streak")), int(e.streak.streak())),
		"boosterless_wins": int(e.records.get_value("boosterless_wins")),
		"best_boosterless_run": int(e.records.get_value("best_boosterless_run")),
		"best_first_try_run": int(e.records.get_value("best_first_try_run")),
	}

## [{id, metric, target, value, done}] in definition order.
static func evaluate(app, defs: Array = []) -> Array:
	var list := defs if not defs.is_empty() else load_defs()
	var s := stats(app)
	var out: Array = []
	for a in list:
		var v := int(s.get(String(a["metric"]), 0))
		out.append({"id": String(a["id"]), "metric": String(a["metric"]), "target": int(a["target"]),
			"value": mini(v, int(a["target"])), "done": v >= int(a["target"])})
	return out
