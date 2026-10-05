extends RefCounted
## DailyOrders — preload (res://scripts/economy/daily_orders.gd).
##
## M43-C009 / C009R (SB-M43-112, R09-001..004) — Daily Scrub Orders: the content of the three
## canonical daily tasks. DailyService stays the authority for the local day, task completion,
## the 75/100/125 SB task grants and the all-3 bonus; this service only decides WHICH order
## each task index is today and counts ordinary-play progress toward it.
##   - pool: data/config/daily_scrub_orders_v1.json (versioned; fails closed to an empty pool);
##   - one order per tier index 0/1/2 = easy/normal/stretch, picked deterministically from
##     (pool version, local day, tier) among the orders eligible for the current frontier;
##   - generated once per local day and persisted, so a relaunch never rerolls; a clock
##     rollback (today < stored day) neither regenerates nor counts progress;
##   - progress comes only from committed progression wins (never from losses, purchases,
##     ads or Hearts), and reaching a target marks the DailyService task done.
## Economy section `daily_orders`: absent = nothing generated yet; present = strict.

const PATH := "res://data/config/daily_scrub_orders_v1.json"
const SCHEMA := "scrubbots.daily_scrub_orders.v1"
const TIERS := ["easy", "normal", "stretch"]
const METRICS := ["levels_won", "levels_won_no_booster", "levels_won_min_class", "cells_cleared"]
const CLASS_RANK := {"EASY": 0, "MEDIUM": 1, "HARD": 2, "VERY_HARD": 3}
const SNAPSHOT_VERSION := 1

var _daily
var _pool: Array = []
var _version := 0
var _context: Callable = Callable()   ## -> {frontier:int, playable_ahead:int, class_for:Callable}
var _day := -1
var _ids: Array = ["", "", ""]
var _progress: Array = [0, 0, 0]

func _init(daily, path: String = PATH) -> void:
	_daily = daily
	var r := load_pool(path)
	_pool = r["archetypes"]
	_version = int(r["version"])

## {ok, version, archetypes}. Any malformed entry rejects the whole file (no partial pool).
static func load_pool(path: String = PATH) -> Dictionary:
	var bad := {"ok": false, "version": 0, "archetypes": []}
	if not FileAccess.file_exists(path):
		return bad
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA or typeof(d.get("archetypes")) != TYPE_ARRAY:
		return bad
	var seen := {}
	var out: Array = []
	for a in d["archetypes"]:
		if typeof(a) != TYPE_DICTIONARY or typeof(a.get("id")) != TYPE_STRING or String(a["id"]).is_empty() or seen.has(a["id"]):
			return bad
		if not TIERS.has(a.get("tier")) or not METRICS.has(a.get("metric")):
			return bad
		var t = a.get("target")
		if typeof(t) != TYPE_FLOAT and typeof(t) != TYPE_INT or int(t) < 1 or float(t) != float(int(t)):
			return bad
		if a["metric"] == "levels_won_min_class" and (not CLASS_RANK.has(a.get("min_class")) or int(a.get("within_levels", 0)) < 1):
			return bad
		seen[a["id"]] = true
		var e: Dictionary = (a as Dictionary).duplicate()
		e["target"] = int(t)
		out.append(e)
	for tier in TIERS:
		if not out.any(func(e): return e["tier"] == tier):
			return bad
	return {"ok": true, "version": int(d.get("version", 0)), "archetypes": out}

## AppState binds the read-only frontier context used for eligibility.
func bind_context(provider: Callable) -> void:
	_context = provider

func archetype(id: String) -> Dictionary:
	for a in _pool:
		if a["id"] == id:
			return a.duplicate()
	return {}

## Today's three orders [{index, id, tier, metric, target, progress, done, claimed, available}].
func orders() -> Array:
	_ensure_today()
	var out: Array = []
	for i in range(TIERS.size()):
		var a := archetype(String(_ids[i]))
		var done: bool = _daily.is_task_done(i)
		var target := int(a.get("target", 0))
		out.append({"index": i, "id": String(_ids[i]), "tier": TIERS[i], "metric": String(a.get("metric", "")),
			"min_class": String(a.get("min_class", "")), "target": target,
			"progress": target if done else mini(int(_progress[i]), target), "available": not a.is_empty(),
			"done": done, "claimed": _daily.task_claimed(i)})
	return out

## Count one committed progression win: {level, difficulty, boosters_used, cells}. Returns
## the task indices that became done by this call.
func on_level_won(info: Dictionary) -> Array:
	if not _ensure_today():
		return []
	var newly: Array = []
	for i in range(TIERS.size()):
		var a := archetype(String(_ids[i]))
		if a.is_empty() or _daily.is_task_done(i):
			continue
		var add := 0
		match String(a["metric"]):
			"levels_won":
				add = 1
			"levels_won_no_booster":
				add = 1 if int(info.get("boosters_used", 0)) == 0 else 0
			"levels_won_min_class":
				add = 1 if int(CLASS_RANK.get(String(info.get("difficulty", "")), -1)) >= int(CLASS_RANK[a["min_class"]]) else 0
			"cells_cleared":
				add = maxi(0, int(info.get("cells", 0)))
		if add <= 0:
			continue
		_progress[i] = mini(int(_progress[i]) + add, int(a["target"]))
		if int(_progress[i]) >= int(a["target"]):
			_daily.mark_task_done(i)
			newly.append(i)
	return newly

## Regenerate on a new local day (forward only). False when the clock is behind the stored day.
func _ensure_today() -> bool:
	var today: int = _daily.local_day()
	if today < _day:
		return false
	if today > _day:
		_day = today
		_ids = generate(today, _ctx())
		_progress = [0, 0, 0]
	return true

func _ctx() -> Dictionary:
	return _context.call() if _context.is_valid() else {}

## Deterministic pick per tier among eligible orders (sorted by id), seeded by version/day/tier.
func generate(day: int, ctx: Dictionary) -> Array:
	var ids: Array = []
	for t in range(TIERS.size()):
		var el: Array = _pool.filter(func(a): return a["tier"] == TIERS[t] and eligible(a, ctx))
		el.sort_custom(func(x, y): return String(x["id"]) < String(y["id"]))
		ids.append("" if el.is_empty() else String(el[("%d:%d:%d" % [_version, day, t]).hash() % el.size()]["id"]))
	return ids

## Never offer an order the player cannot finish with the content they can play next.
func eligible(a: Dictionary, ctx: Dictionary) -> bool:
	var ahead := int(ctx.get("playable_ahead", 0))
	match String(a["metric"]):
		"levels_won", "levels_won_no_booster":
			return ahead >= int(a["target"])
		"cells_cleared":
			return ahead >= 3
		"levels_won_min_class":
			var cf: Callable = ctx.get("class_for", Callable())
			if not cf.is_valid():
				return false
			var frontier := int(ctx.get("frontier", 1))
			for n in range(frontier, frontier + mini(int(a["within_levels"]), ahead)):
				if int(CLASS_RANK.get(String(cf.call(n)), -1)) >= int(CLASS_RANK[a["min_class"]]):
					return true
			return false
	return false

func snapshot() -> Dictionary:
	return {"version": SNAPSHOT_VERSION, "day": _day, "ids": _ids.duplicate(), "progress": _progress.duplicate()}

func import_snapshot(s) -> bool:
	if s == null:
		_day = -1
		_ids = ["", "", ""]
		_progress = [0, 0, 0]
		return true
	if typeof(s) != TYPE_DICTIONARY or not _is_int(s.get("version")) or int(s["version"]) != SNAPSHOT_VERSION or not _is_int(s.get("day")) or int(s["day"]) < -1:
		return false
	var ids = s.get("ids")
	var pr = s.get("progress")
	if typeof(ids) != TYPE_ARRAY or typeof(pr) != TYPE_ARRAY or ids.size() != 3 or pr.size() != 3:
		return false
	for i in range(3):
		if typeof(ids[i]) != TYPE_STRING or (not String(ids[i]).is_empty() and archetype(String(ids[i])).is_empty()):
			return false
		if not _is_int(pr[i]) or int(pr[i]) < 0:
			return false
		if not String(ids[i]).is_empty() and int(pr[i]) > int(archetype(String(ids[i]))["target"]):
			return false
	_day = int(s["day"])
	_ids = ids.duplicate()
	_progress = pr.map(func(v): return int(v))
	return true

static func _is_int(v) -> bool:
	return (typeof(v) == TYPE_INT) or (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floor(v))
