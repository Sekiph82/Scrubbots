extends RefCounted
## Achievements — preload (res://scripts/progression/achievements.gd).
##
## M43-C010 (SB-M43-126) — data-driven achievement framework; SB-POLISH-007 (owner 2026-10-31)
## — 50 entries in data/config/achievements_v2.json, each paying its reward once.
## Every metric is a monotonic lifetime or personal-best value already owned by a canonical
## service (progression, Collection, robots, PlayerRecords, Gift Meter, the reward ledger), so
## completion is derived and never lost. A reward is claimed with CLAIM through
## RewardGrantService under tx achievement:<id>; "claimed" is read back from that persisted
## ledger (no save section of its own), so it can never pay twice, and an old save whose
## progress already meets a target shows CLAIM on load.

const PATH := "res://data/config/achievements_v2.json"
const SCHEMA := "scrubbots.achievements.v2"
const ICON_ROOT := "res://assets/ui/final/"
const METRICS := ["levels_completed", "sets_completed", "robots_unlocked", "cards_unique", "best_win_streak",
	"boosterless_wins", "best_boosterless_run", "best_first_try_run", "gifts_claimed", "gift_cycles",
	"daily_logins", "tasks_claimed"]
const TIERS := ["bronze", "silver", "gold", "platinum"]
## Existing reward types only (economy lock): SB, Bot Parts, Card / Premium Pack, Booster of
## choice, Mystery Booster.
const REWARDS := ["scrub_bucks", "bot_parts", "standard_card_packs", "premium_card_packs",
	"selected_booster_charges", "random_any_booster_charges"]
## Ledger-counted metrics: lifetime count of applied reward tx ids with this prefix.
const LEDGER_PREFIX := {"gifts_claimed": "gift_ms:", "daily_logins": "daily_login:", "tasks_claimed": "daily_task:"}

## Validated definitions; any malformed entry rejects the whole file (no partial list).
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
		if typeof(a.get("name")) != TYPE_STRING or typeof(a.get("desc")) != TYPE_STRING or not TIERS.has(a.get("tier")) or typeof(a.get("icon")) != TYPE_STRING:
			return []
		var r = a.get("reward")
		if typeof(r) != TYPE_DICTIONARY or r.is_empty():
			return []
		for k in r:
			if not REWARDS.has(k) or (typeof(r[k]) != TYPE_FLOAT and typeof(r[k]) != TYPE_INT) or int(r[k]) < 1 or float(r[k]) != float(int(r[k])):
				return []
		seen[a["id"]] = true
	return d["achievements"]

static func tx_id(id: String) -> String:
	return "achievement:" + id

## Live lifetime / personal-best stats from the canonical services (read-only).
static func stats(app) -> Dictionary:
	var e = app.economy
	var unique := 0
	for cid in e.collection.all_card_ids():
		if e.collection.owned(cid) > 0:
			unique += 1
	var out := {
		"levels_completed": int(app.progression.completed_count()),
		"sets_completed": int(e.collection.completed_set_count()),
		"robots_unlocked": int(e.robots.unlocked_count()),
		"cards_unique": unique,
		"best_win_streak": maxi(int(e.records.get_value("best_win_streak")), int(e.streak.streak())),
		"boosterless_wins": int(e.records.get_value("boosterless_wins")),
		"best_boosterless_run": int(e.records.get_value("best_boosterless_run")),
		"best_first_try_run": int(e.records.get_value("best_first_try_run")),
		"gift_cycles": int(e.gift.cycles_completed()),
	}
	for m in LEDGER_PREFIX:
		out[m] = 0
	for tx in e.reward.applied_ids():
		for m in LEDGER_PREFIX:
			if String(tx).begins_with(LEDGER_PREFIX[m]):
				out[m] += 1
	return out

## [{id, name, desc, metric, target, tier, icon, badge_number, reward, value, done, claimed,
## claimable}] in definition order.
static func evaluate(app, defs: Array = []) -> Array:
	var list := defs if not defs.is_empty() else load_defs()
	var s := stats(app)
	var out: Array = []
	for a in list:
		var v := int(s.get(String(a["metric"]), 0))
		var done := v >= int(a["target"])
		var claimed: bool = app.economy.reward.already_applied(tx_id(String(a["id"])))
		out.append({"id": String(a["id"]), "name": String(a["name"]), "desc": String(a["desc"]),
			"metric": String(a["metric"]), "target": int(a["target"]), "tier": String(a["tier"]),
			"icon": String(a["icon"]), "badge_number": bool(a.get("badge_number", false)),
			"reward": _int_reward(a["reward"]), "value": mini(v, int(a["target"])), "done": done,
			"claimed": claimed, "claimable": done and not claimed})
	return out

static func claimable_count(app) -> int:
	return evaluate(app).filter(func(a): return a["claimable"]).size()

## Grant one completed, unclaimed achievement's reward. {ok, reason?, id, reward, tx}.
## Called only by ProductionActionFacade.claim_achievement (the durable save boundary).
static func claim(app, id: String) -> Dictionary:
	for a in evaluate(app):
		if a["id"] != id:
			continue
		if a["claimed"]:
			return {"ok": false, "reason": "already_claimed", "id": id}
		if not a["done"]:
			return {"ok": false, "reason": "not_reached", "id": id}
		var tx := tx_id(id)
		if not app.economy.reward.grant(tx, a["reward"]):
			return {"ok": false, "reason": "grant_failed", "id": id}
		return {"ok": true, "id": id, "reward": a["reward"], "tx": tx}
	return {"ok": false, "reason": "not_found", "id": id}

static func _int_reward(r: Dictionary) -> Dictionary:
	var out := {}
	for k in r:
		out[k] = int(r[k])
	return out
