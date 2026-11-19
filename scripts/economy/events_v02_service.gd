extends RefCounted
## EventsV02Service — preload (res://scripts/economy/events_v02_service.gd).
##
## SB-EV02-002..007 — the 24 V02 events (docs/SCRUBBOTS_24_EVENTS_OWNER_PLAN_2026-11-13.md),
## driven only by data/config/events_v02_runtime.json and cross-checked against the spec
## catalog data/config/events_v02_catalog.json (ids, metrics). No live-ops server: the
## schedule is a deterministic UTC lane plan repeating every cycle (instance id
## `<event_id>:<cycle>`), 3..5 active at every instant, never ended early.
##   - Gameplay: NONE of its own. Progress comes only from committed normal-level receipts
##     (on_receipt, built by the gameplay host at its latched terminal), deduped by receipt id,
##     counted only for JOINED instances inside their window (no retroactive awards).
##   - Rivals / teammates are computer-controlled and labelled so: their scores are a pure
##     function of (instance id, entrant index, time) — offline-stable, never tied to spending.
##   - Rewards: existing types only, through RewardGrantService under
##     `event:<instance_id>:<reward_id>:<reward_policy_version>` (once, save-safe). Claims are
##     enabled only when the config asks for it AND the worst-case cycle total (every event at
##     its best result, five concurrent) fits `cycle_reward_cap`; otherwise preview only.
##   - Clock: a high-water mark stamped by every state change (receipt, join, claim); a clock moved
##     backwards never reopens a joined window or rewinds rivals. Reads never write it.
## The Level 30 gate is the caller's (`unlocked`, AppState.feature_unlocked("events")).
## SB-TF-07: add_ad_progress(iid) = +1 progress from a verified rewarded "event ad" (granted only by
## RewardedGrantService under event_ad:<iid>:<day>); joined + active instances, not quest / colors
## (their progress is derived). It never touches receipts, rewards or claims.
## Economy section `events_v02`: absent = fresh (older saves), present = strict.

const PATH := "res://data/config/events_v02_runtime.json"
const CATALOG := "res://data/config/events_v02_catalog.json"
const SCHEMA := "scrubbots.events.v02.runtime"
const SNAPSHOT_VERSION := 1
const RECEIPT_MEMORY := 64
const KINDS := ["milestones", "streak", "colors", "quest", "race", "ranking", "royale", "bracket", "team_milestones", "team_versus"]
const PROFILES := ["casual", "average", "strong", "expert"]
## Canonical robot roster ids (data/config/robot_roster_v1.json): rival + teammate avatars; display name = id.capitalize().
const ROBOTS := ["scrubby", "moppy", "bubbles", "spark", "squeegee", "dusty", "rinse", "polly", "clippy", "atlas"]
const COUNT_METRICS := ["first_clear_new_level", "virtual_team_qualifying_level_wins", "virtual_team_cleaning_points",
	"virtual_team_sequential_clears", "seasonal_qualifying_level_progress"]
const PIXEL_METRICS := ["cleaned_active_pixels", "cleaned_active_pixels_on_new_levels", "virtual_team_cleaned_active_pixels"]
const OPPONENT_BASE := 100   ## team_versus opponent entrant indices start here
const AD_EXCLUDED_KINDS := ["quest", "colors"]   ## SB-TF-07: derived progress, no event ad

var config_ok := false
var claims_enabled := false
var cap_report := {}         ## resource -> {"max": worst-case cycle total, "cap": int}
var _cfg := {}
var _defs := {}              ## event id -> def
var _ids: Array = []         ## catalog order
var _lanes: Array = []       ## [[{id, start_h, end_h}]]
var _clock: Callable
var _hw := 0
var _inst := {}              ## instance id -> saved record (joined instances)
var _receipts: Array = []    ## recent processed receipt ids
var _tutorial_seen: Array = []
var _cache := {}             ## rival step cache "iid#idx" -> {profile, steps:[[t, total]]}

func _init(clock: Callable = Callable(), path: String = PATH) -> void:
	_clock = clock if clock.is_valid() else func(): return int(Time.get_unix_time_from_system())
	load_config(path)

## Service time: the wall clock, never below the high-water mark. Read-only: views / lists never
## write state (a save taken around a pure read stays byte-identical).
func now() -> int:
	return maxi(_hw, int(_clock.call()))

## Records the current service time as the high-water mark; only state changes call this
## (receipt applied, join, claim), so a clock moved back never rewinds committed progress.
func _stamp() -> int:
	_hw = now()
	return _hw

# ---------------------------------------------------------------- config ----

func load_config(path: String) -> void:
	config_ok = false
	claims_enabled = false
	_defs = {}
	_ids = []
	_lanes = []
	_cache = {}
	var d = _read(path)
	var cat = _read(CATALOG)
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA or typeof(cat) != TYPE_DICTIONARY:
		return
	var metrics := {}
	for e in cat.get("events", []):
		metrics[String(e["id"])] = String(e["metric"])
	var types: Array = d.get("approved_reward_types", [])
	if String(d.get("reward_policy_version", "")).is_empty() or int(d.get("claim_grace_hours", 0)) < 0:
		return
	for e in d.get("events", []):
		if typeof(e) != TYPE_DICTIONARY or not metrics.has(e.get("id")) or _defs.has(e.get("id")) or not _valid_def(e, types, metrics):
			return
		_defs[String(e["id"])] = e
	if _defs.size() != metrics.size():
		return
	var sch = d.get("schedule")
	if typeof(sch) != TYPE_DICTIONARY or int(sch.get("cycle_hours", 0)) <= 0:
		return
	var seen := {}
	for lane in sch.get("lanes", []):
		var h := 0
		var out: Array = []
		for slot in lane:
			var id := String(slot.get("id", ""))
			if not _defs.has(id) or seen.has(id) or int(slot.get("gap_hours", 0)) < 0:
				return
			seen[id] = true
			h += int(slot.get("gap_hours", 0))
			out.append({"id": id, "start_h": h, "end_h": h + int(_defs[id]["duration_hours"])})
			h += int(_defs[id]["duration_hours"])
		if h > int(sch["cycle_hours"]):
			return
		_lanes.append(out)
	if seen.size() != _defs.size():
		return
	for e in cat.get("events", []):
		_ids.append(String(e["id"]))
	_cfg = d
	config_ok = true
	cap_report = worst_case_cycle_rewards()
	var fits := true
	for k in cap_report:
		fits = fits and int(cap_report[k]["max"]) <= int(cap_report[k]["cap"])
	claims_enabled = bool(d.get("claims_enabled", false)) and fits

static func _read(path: String):
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

static func _valid_reward(r, types: Array) -> bool:
	if typeof(r) != TYPE_DICTIONARY or r.is_empty():
		return false
	for k in r:
		if not types.has(k) or not _is_int(r[k]) or int(r[k]) <= 0:
			return false
	return true

static func _valid_steps(list, key: String, types: Array) -> bool:
	if typeof(list) != TYPE_ARRAY or list.is_empty():
		return false
	var last := 0
	for m in list:
		if typeof(m) != TYPE_DICTIONARY or not _is_int(m.get(key)) or int(m[key]) <= last or not _valid_reward(m.get("reward"), types):
			return false
		last = int(m[key])
	return true

static func _valid_def(e: Dictionary, types: Array, metrics: Dictionary) -> bool:
	var kind := String(e.get("kind", ""))
	if not KINDS.has(kind) or String(e.get("metric", "")) != metrics[e["id"]] or int(e.get("duration_hours", 0)) <= 0:
		return false
	match kind:
		"race":
			var goal_ok: bool = int(e.get("goal", 0)) > 0 or (typeof(e.get("goal_options")) == TYPE_ARRAY and not e["goal_options"].is_empty())
			return goal_ok and int(e.get("rivals", 0)) > 0 and _valid_steps(e.get("place_rewards"), "place", types)
		"ranking":
			return int(e.get("rivals", 0)) > 0 and _valid_steps(e.get("rank_rewards"), "rank", types)
		"bracket":
			return int(e.get("rivals", 0)) == 7 and _valid_steps(e.get("result_rewards"), "rounds_won", types)
		"royale":
			return int(e.get("rivals", 0)) > 0 and _valid_steps(e.get("milestones"), "target", types)
		"team_milestones", "team_versus":
			if int(e.get("team_size", 0)) < 2 or int(e.get("min_player_contribution", 0)) < 1:
				return false
			if kind == "team_versus" and not _valid_reward(e.get("win_reward"), types):
				return false
		"colors":
			if int(e.get("target_colors", 0)) < 1 or int(e.get("pixels_per_color", 0)) < 1 or typeof(e.get("color_pool")) != TYPE_ARRAY or e["color_pool"].size() < int(e["target_colors"]):
				return false
	return _valid_steps(e.get("milestones"), "target", types)

func def(id: String) -> Dictionary:
	return _defs.get(id, {})

func event_ids() -> Array:
	return _ids.duplicate()

func policy_version() -> String:
	return String(_cfg.get("reward_policy_version", ""))

## Worst case per cycle: every event once (each appears once per cycle) at its best result —
## all milestones plus the largest place / rank / result reward per resource and the team win.
func worst_case_cycle_rewards() -> Dictionary:
	var total := {}
	var cap: Dictionary = _cfg.get("cycle_reward_cap", {})
	for k in _cfg.get("approved_reward_types", []):
		total[k] = {"max": 0, "cap": int(cap.get(k, 0))}
	for id in _defs:
		var e: Dictionary = _defs[id]
		var bags: Array = []
		for m in e.get("milestones", []):
			bags.append(m["reward"])
		if e.has("win_reward"):
			bags.append(e["win_reward"])
		for key in ["place_rewards", "rank_rewards", "result_rewards"]:
			if e.has(key):
				var best := {}
				for r in e[key]:
					for k in r["reward"]:
						best[k] = maxi(int(best.get(k, 0)), int(r["reward"][k]))
				bags.append(best)
		for b in bags:
			for k in b:
				total[k]["max"] = int(total[k]["max"]) + int(b[k])
	return total

# -------------------------------------------------------------- schedule ----

## Scheduled instances overlapping [t0, t1): [{iid, id, start, end, cycle}].
func scheduled(t0: int, t1: int) -> Array:
	var out: Array = []
	if not config_ok:
		return out
	var sch: Dictionary = _cfg["schedule"]
	var cyc := int(sch["cycle_hours"]) * 3600
	var epoch := int(sch["epoch_utc"])
	for c in range(floori(float(t0 - epoch) / cyc), floori(float(t1 - 1 - epoch) / cyc) + 1):
		var base := epoch + c * cyc
		for lane in _lanes:
			for slot in lane:
				var s: int = base + int(slot["start_h"]) * 3600
				var en: int = base + int(slot["end_h"]) * 3600
				if s < t1 and en > t0:
					out.append({"iid": "%s:%d" % [slot["id"], c], "id": slot["id"], "start": s, "end": en, "cycle": c})
	return out

func active_count() -> int:
	var t := now()
	return scheduled(t, t + 1).size()

## The instance record: saved (joined) or freshly derived from the schedule. {} = unknown.
func _record(iid: String) -> Dictionary:
	if _inst.has(iid):
		return _inst[iid]
	var parts := iid.split(":")
	if parts.size() != 2 or not _defs.has(parts[0]) or not parts[1].is_valid_int():
		return {}
	var sch: Dictionary = _cfg["schedule"]
	var base := int(sch["epoch_utc"]) + int(parts[1]) * int(sch["cycle_hours"]) * 3600
	for s in scheduled(base, base + int(sch["cycle_hours"]) * 3600):
		if s["iid"] == iid:
			return _fresh(s)
	return {}

func _fresh(s: Dictionary) -> Dictionary:
	var e: Dictionary = _defs[s["id"]]
	var rng := RandomNumberGenerator.new()
	rng.seed = String(s["iid"]).hash()
	var params := {}
	match String(e["kind"]):
		"race":
			params["goal"] = int(e["goal"]) if e.has("goal") else int(e["goal_options"][rng.randi() % e["goal_options"].size()])
		"colors":
			var pool: Array = e["color_pool"].duplicate()
			var pick: Array = []
			while pick.size() < int(e["target_colors"]):
				pick.append(pool.pop_at(rng.randi() % pool.size()))
			params["colors"] = pick
	if s["id"] == "seasonal_scrub_festival":
		params["variant"] = String(_cfg.get("seasonal_variants", {}).get(str(Time.get_datetime_dict_from_unix_time(int(s["start"]))["month"]), "summer"))
	return {"iid": s["iid"], "id": s["id"], "start": int(s["start"]), "end": int(s["end"]), "params": params,
		"joined_at": 0, "progress": 0, "best": 0, "reach_t": 0, "finish_t": 0, "log": [], "colors": {}, "objectives": [], "claimed": []}

# ------------------------------------------------------------- receipts ----

## A committed normal-level progression terminal from the gameplay host. Ignored before the
## Events unlock, when malformed, or when its receipt id was already applied. Returns the
## instance ids it advanced.
func on_receipt(r: Dictionary, unlocked: bool) -> Array:
	var changed: Array = []
	if not config_ok or not unlocked or not valid_receipt(r) or _receipts.has(r["receipt_id"]):
		return changed
	_receipts.append(String(r["receipt_id"]))
	while _receipts.size() > RECEIPT_MEMORY:
		_receipts.pop_front()
	var t := _stamp()
	for iid in _inst:
		var rec: Dictionary = _inst[iid]
		if t < int(rec["start"]) or t >= int(rec["end"]):
			continue
		if _apply(rec, r, t):
			changed.append(iid)
	for iid in _inst:   # Master Cleaner Quest: other events' unlocked rewards, once per instance
		var q: Dictionary = _inst[iid]
		if _defs[q["id"]]["kind"] != "quest" or t < int(q["start"]) or t >= int(q["end"]):
			continue
		for oid in _inst:
			var o: Dictionary = _inst[oid]
			if oid != iid and _defs[o["id"]]["kind"] != "quest" and not (q["objectives"] as Array).has(oid) and int(o["end"]) > int(q["start"]) and _objective_met(o, t):
				(q["objectives"] as Array).append(oid)
				q["progress"] = (q["objectives"] as Array).size()
				if not changed.has(iid):
					changed.append(iid)
	return changed

## Receipt contract (host-built): ids/types strict, per-colour pixels reconcile to the total.
static func valid_receipt(r) -> bool:
	if typeof(r) != TYPE_DICTIONARY or typeof(r.get("receipt_id")) != TYPE_STRING or String(r["receipt_id"]).is_empty():
		return false
	for k in ["level", "boosters_used", "cleaned_active_pixels", "completed_at_utc"]:
		if not _is_int(r.get(k)) or int(r[k]) < 0:
			return false
	if typeof(r.get("won")) != TYPE_BOOL or typeof(r.get("first_attempt")) != TYPE_BOOL or typeof(r.get("cleaned_pixels_by_color")) != TYPE_DICTIONARY:
		return false
	var sum := 0
	for c in r["cleaned_pixels_by_color"]:
		if typeof(c) != TYPE_STRING or not _is_int(r["cleaned_pixels_by_color"][c]) or int(r["cleaned_pixels_by_color"][c]) < 0:
			return false
		sum += int(r["cleaned_pixels_by_color"][c])
	return sum == int(r["cleaned_active_pixels"])

## What one receipt adds to `metric` (0 for a loss: only committed first clears of new levels count).
static func metric_amount(metric: String, r: Dictionary) -> int:
	if not bool(r["won"]):
		return 0
	if COUNT_METRICS.has(metric):
		return 1
	if PIXEL_METRICS.has(metric):
		return int(r["cleaned_active_pixels"])
	match metric:
		"first_attempt_new_level_win":
			return 1 if r["first_attempt"] else 0
		"win_without_booster_usage":
			return 1 if int(r["boosters_used"]) == 0 else 0
		"first_clear_new_level_cleanup_score":
			return 100 + (50 if r["first_attempt"] else 0) + (25 if int(r["boosters_used"]) == 0 else 0)
	return 0

func _apply(rec: Dictionary, r: Dictionary, t: int) -> bool:
	var e: Dictionary = _defs[rec["id"]]
	match String(e["kind"]):
		"quest":
			return false
		"streak":
			if r["won"]:
				rec["progress"] = int(rec["progress"]) + 1
				rec["best"] = maxi(int(rec["best"]), int(rec["progress"]))
			else:   # event-only rollback to the last checkpoint reached by this run
				var cp := 0
				for m in e["milestones"]:
					if int(m["target"]) <= int(rec["progress"]):
						cp = int(m["target"])
				rec["progress"] = cp
			return true
		"colors":
			if not r["won"]:
				return false
			for c in rec["params"]["colors"]:
				rec["colors"][c] = int(rec["colors"].get(c, 0)) + int(r["cleaned_pixels_by_color"].get(c, 0))
			var done := 0
			for c in rec["params"]["colors"]:
				done += 1 if int(rec["colors"].get(c, 0)) >= int(e["pixels_per_color"]) else 0
			rec["progress"] = done
			return true
	var a := metric_amount(String(e["metric"]), r)
	if a <= 0:
		return false
	_add(rec, e, a, t)
	return true

## The generic progress tail (receipts and the event ad).
func _add(rec: Dictionary, e: Dictionary, a: int, t: int) -> void:
	rec["progress"] = int(rec["progress"]) + a
	if e["kind"] == "streak":
		rec["best"] = maxi(int(rec["best"]), int(rec["progress"]))
	rec["reach_t"] = t
	(rec["log"] as Array).append(t)
	if e["kind"] == "race" and int(rec["finish_t"]) == 0 and int(rec["progress"]) >= int(rec["params"]["goal"]):
		rec["finish_t"] = t

## SB-TF-07: why instance `iid` cannot take an event ad right now ("" = it can).
func ad_refusal(iid: String) -> String:
	var rec := _record(iid) if config_ok else {}
	if rec.is_empty():
		return "not_found"
	if int(rec["joined_at"]) <= 0:
		return "not_joined"
	var t := now()
	if t < int(rec["start"]) or t >= int(rec["end"]):
		return "not_active"
	if AD_EXCLUDED_KINDS.has(_defs[rec["id"]]["kind"]):
		return "ineligible_kind"
	return ""

## SB-TF-07: +1 progress for a verified event ad (EconomyServices' event_ad_progress handler).
## No-op (false) once the instance is no longer eligible (e.g. the window ended during the ad).
func add_ad_progress(iid: String) -> bool:
	if not ad_refusal(iid).is_empty():
		return false
	var rec: Dictionary = _inst[iid]
	_add(rec, _defs[rec["id"]], 1, _stamp())
	return true

## Master Cleaner Quest objective: another joined event earned a reward step (rank-only events:
## the player scored in it).
func _objective_met(o: Dictionary, t: int) -> bool:
	if ["ranking", "bracket"].has(_defs[o["id"]]["kind"]):
		return int(o["progress"]) > 0
	for s in _steps(o, t):
		if s["reached"]:
			return true
	return false

# --------------------------------------------------------------- rivals ----

## Deterministic computer-controlled entrant: profile + increment times inside the window.
func _rival(rec: Dictionary, idx: int) -> Dictionary:
	var key := "%s#%d" % [rec["iid"], idx]
	if _cache.has(key):
		return _cache[key]
	var rv: Dictionary = _cfg["rivals"]
	var metric := String(_defs[rec["id"]]["metric"])
	var rng := RandomNumberGenerator.new()
	rng.seed = key.hash()
	var prof: String = PROFILES[rng.randi() % PROFILES.size()]
	var rate := float(rv["profiles"][prof]) * (float(rv["first_attempt_rate_factor"]) if metric == "first_attempt_new_level_win" else 1.0)
	var t := float(rec["start"])
	var total := 0
	var steps: Array = []
	# ponytail: uniform random gaps, no day/night rhythm; add a diurnal curve if rivals look too even.
	while true:
		t += 86400.0 / rate * (0.5 + rng.randf())
		if t >= float(rec["end"]):
			break
		if PIXEL_METRICS.has(metric):
			total += rng.randi_range(int(rv["pixels_per_level"][0]), int(rv["pixels_per_level"][1]))
		elif metric == "first_clear_new_level_cleanup_score":
			total += 100 + (50 if rng.randf() < 0.5 else 0) + (25 if rng.randf() < 0.6 else 0)
		else:
			total += 1
		steps.append([int(t), total])
	var off := absi(String(rec["iid"]).hash()) % ROBOTS.size()
	var r := {"profile": prof, "steps": steps, "robot": ROBOTS[(idx + off) % ROBOTS.size()],
		"name": "%s %d" % [String(ROBOTS[(idx + off) % ROBOTS.size()]).capitalize(), idx % OPPONENT_BASE + 1]}
	_cache[key] = r
	return r

## Rival score and the time it was reached, at time t: [score, reach_t].
func rival_score(rec: Dictionary, idx: int, t: int) -> Array:
	var score := 0
	var at := 0
	for s in _rival(rec, idx)["steps"]:
		if int(s[0]) > t:
			break
		score = int(s[1])
		at = int(s[0])
	return [score, at]

func _rival_count_in(rec: Dictionary, idx: int, a: int, b: int) -> Array:
	var n := 0
	var at := 0
	for s in _rival(rec, idx)["steps"]:
		if int(s[0]) >= a and int(s[0]) < b:
			n += 1
			at = int(s[0])
	return [n, at]

## The 8-entrant bracket (entrant 0 = player) up to time t: rounds of [a, b, score_a, score_b,
## winner (-1 = round still running)], player rounds won, and whether the result is final.
## Tie: the entrant who reached the score first; nobody scored: the player never wins a 0-0,
## two rivals -> the lower index.
func bracket(rec: Dictionary, t: int) -> Dictionary:
	var L := (int(rec["end"]) - int(rec["start"])) / 3
	var alive: Array = range(8)
	var rounds: Array = []
	var won := 0
	var out := false
	var final := false
	for r in range(3):
		var a0 := int(rec["start"]) + r * L
		var b0 := a0 + L
		if t < a0:
			break
		var pairs: Array = []
		var next: Array = []
		for k in range(alive.size() / 2):
			var x: int = alive[2 * k]
			var y: int = alive[2 * k + 1]
			var sx := _entrant_in(rec, x, a0, b0)
			var sy := _entrant_in(rec, y, a0, b0)
			var w := -1
			if t >= b0:
				if sx[0] != sy[0]:
					w = x if sx[0] > sy[0] else y
				elif sx[0] > 0:
					w = x if sx[1] <= sy[1] else y
				else:
					w = y if x == 0 else x
				next.append(w)
				if x == 0 or y == 0:
					if w == 0:
						won += 1
					else:
						out = true
			pairs.append([x, y, sx[0], sy[0], w])
		rounds.append(pairs)
		if t < b0 or out:
			final = out
			break
		alive = next
		if r == 2:
			final = true
	return {"rounds": rounds, "won": won, "out": out, "final": final}

func _entrant_in(rec: Dictionary, idx: int, a: int, b: int) -> Array:
	if idx != 0:
		return _rival_count_in(rec, idx, a, b)
	var n := 0
	var at := 0
	for x in rec["log"]:
		if int(x) >= a and int(x) < b:
			n += 1
			at = int(x)
	return [n, at]

## Final / live rank among player + rivals: higher score first; equal scores -> reached first.
func rank(rec: Dictionary, t: int) -> int:
	var p := int(rec["progress"])
	var n := 1
	for i in range(1, int(_defs[rec["id"]]["rivals"]) + 1):
		var s := rival_score(rec, i, t)
		if s[0] > p or (s[0] == p and p > 0 and s[1] < int(rec["reach_t"])) or (s[0] == p and p == 0):
			n += 1
	return n

## Race place: 1 + rivals that crossed the goal strictly before the player did.
func place(rec: Dictionary) -> int:
	var n := 1
	var goal := int(rec["params"]["goal"])
	for i in range(1, int(_defs[rec["id"]]["rivals"]) + 1):
		var steps: Array = _rival(rec, i)["steps"]
		if steps.size() >= goal and int(steps[goal - 1][0]) < int(rec["finish_t"]):
			n += 1
	return n

## Team members' total (virtual teammates idx 1..size-1) or the opponent team (OPPONENT_BASE..).
func team_score(rec: Dictionary, t: int, opponent: bool) -> int:
	var size := int(_defs[rec["id"]]["team_size"])
	var total := 0 if opponent else int(rec["progress"])
	for i in range(1, size + (1 if opponent else 0)):
		total += rival_score(rec, i + (OPPONENT_BASE - 1 if opponent else 0), t)[0]
	return total

## Entrant presentation (name, canonical robot, profile) for index idx.
func entrant(rec: Dictionary, idx: int) -> Dictionary:
	var r := _rival(rec, idx)
	return {"name": r["name"], "robot": r["robot"], "profile": r["profile"]}

# --------------------------------------------------------------- rewards ----

## Reward steps of a record at time t: [{rid, label_value, reward, reached, payable}].
func _steps(rec: Dictionary, t: int) -> Array:
	var e: Dictionary = _defs[rec["id"]]
	var kind := String(e["kind"])
	var ended := t >= int(rec["end"])
	var out: Array = []
	match kind:
		"race":
			var reward := {}
			var p := place(rec) if int(rec["finish_t"]) > 0 else 0
			for pr in e["place_rewards"]:
				if p > 0 and p <= int(pr["place"]):
					reward = pr["reward"]
					break
			out.append({"rid": "place", "value": p, "reward": reward if p > 0 else e["place_rewards"][0]["reward"], "reached": p > 0, "payable": true})
		"ranking":
			var rk := rank(rec, mini(t, int(rec["end"])))
			var reward := {}
			for rr in e["rank_rewards"]:
				if rk <= int(rr["rank"]):
					reward = rr["reward"]
					break
			out.append({"rid": "rank", "value": rk, "reward": reward if not reward.is_empty() else e["rank_rewards"][-1]["reward"], "reached": ended and int(rec["progress"]) > 0 and not reward.is_empty(), "payable": ended})
		"bracket":
			var b := bracket(rec, t)
			var reward := {}
			for rr in e["result_rewards"]:
				if int(b["won"]) >= int(rr["rounds_won"]):
					reward = rr["reward"]
			out.append({"rid": "result", "value": int(b["won"]), "reward": reward if not reward.is_empty() else e["result_rewards"][0]["reward"], "reached": bool(b["final"]) and int(b["won"]) >= 1, "payable": bool(b["final"])})
		_:
			var score := int(rec["best"]) if kind == "streak" else int(rec["progress"])
			var team_ok := true
			if kind == "team_milestones":
				score = team_score(rec, mini(t, int(rec["end"])), false)
				team_ok = int(rec["progress"]) >= int(e["min_player_contribution"])
			for i in range(e["milestones"].size()):
				var m: Dictionary = e["milestones"][i]
				out.append({"rid": "m%d" % i, "value": int(m["target"]), "reward": m["reward"], "reached": score >= int(m["target"]) and team_ok, "payable": true})
			if kind == "team_versus":
				var own := team_score(rec, mini(t, int(rec["end"])), false)
				var opp := team_score(rec, mini(t, int(rec["end"])), true)
				out.append({"rid": "win", "value": own, "reward": e["win_reward"], "reached": ended and own > opp and int(rec["progress"]) >= int(e["min_player_contribution"]), "payable": ended})
	return out

func _grace() -> int:
	return int(_cfg.get("claim_grace_hours", 0)) * 3600

func _phase(rec: Dictionary, t: int, unclaimed: int) -> String:
	if t < int(rec["start"]):
		return "upcoming"
	if t < int(rec["end"]):
		return "active"
	if t >= int(rec["end"]) + _grace():
		return "expired"
	return "claimable" if unclaimed > 0 else "ended"

## Read-only view of one instance for UI / tests ({} = unknown instance).
func view(iid: String) -> Dictionary:
	var rec := _record(iid)
	if rec.is_empty():
		return {}
	var t := now()
	var e: Dictionary = _defs[rec["id"]]
	var joined := int(rec["joined_at"]) > 0
	var steps := _steps(rec, t)
	var unclaimed := 0
	for s in steps:
		s["claimed"] = (rec["claimed"] as Array).has(s["rid"])
		s["claimable"] = joined and s["reached"] and s["payable"] and not s["claimed"] and t < int(rec["end"]) + _grace()
		unclaimed += 1 if s["claimable"] else 0
	var v := {"iid": iid, "id": rec["id"], "kind": e["kind"], "family": e["family"], "metric": e["metric"],
		"phase": _phase(rec, t, unclaimed), "start": int(rec["start"]), "end": int(rec["end"]),
		"starts_in": maxi(0, int(rec["start"]) - t), "ends_in": maxi(0, int(rec["end"]) - t),
		"claim_ends_in": maxi(0, int(rec["end"]) + _grace() - t), "joined": joined,
		"progress": int(rec["progress"]), "best": int(rec["best"]), "params": (rec["params"] as Dictionary).duplicate(true),
		"steps": steps, "claimable": unclaimed if claims_enabled else 0, "claims_enabled": claims_enabled,
		"colors": (rec["colors"] as Dictionary).duplicate(), "objectives": (rec["objectives"] as Array).size()}
	match String(e["kind"]):
		"race", "ranking", "royale":
			var tt := mini(t, int(rec["end"]))
			var rows: Array = [{"idx": 0, "player": true, "score": int(rec["progress"])}]
			for i in range(1, int(e["rivals"]) + 1):
				var s := rival_score(rec, i, tt)
				rows.append({"idx": i, "player": false, "score": s[0], "at": s[1]})
			rows.sort_custom(func(a, b): return a["score"] > b["score"] or (a["score"] == b["score"] and a["idx"] < b["idx"]))
			v["standings"] = rows
			v["entrants"] = int(e["rivals"]) + 1
			if e["kind"] == "ranking":
				v["rank"] = rank(rec, tt)
			if e["kind"] == "royale":
				var stages: Array = []
				for m in e["milestones"]:
					var n := 1 if int(rec["progress"]) >= int(m["target"]) else 0
					for row in rows:
						n += 1 if not row["player"] and int(row["score"]) >= int(m["target"]) else 0
					stages.append(n)
				v["stage_counts"] = stages
		"bracket":
			v["bracket"] = bracket(rec, t)
			v["entrants"] = 8
		"team_milestones", "team_versus":
			v["team_total"] = team_score(rec, mini(t, int(rec["end"])), false)
			v["team_size"] = int(e["team_size"])
			v["min_player_contribution"] = int(e["min_player_contribution"])
			if e["kind"] == "team_versus":
				v["opponent_total"] = team_score(rec, mini(t, int(rec["end"])), true)
	return v

## Events to show (unlocked callers only): active instances, ended ones with a reward still
## claimable, then upcoming previews; joined instances keep their saved window even if the
## config changed.
func list() -> Array:
	var t := now()
	var ids: Array = []
	for s in scheduled(t - _grace(), t + int(_cfg.get("schedule", {}).get("upcoming_preview_hours", 0)) * 3600):
		ids.append(s["iid"])
	for iid in _inst:
		if not ids.has(iid):
			ids.append(iid)
	var out: Array = []
	for iid in ids:
		var v := view(iid)
		if not v.is_empty() and ["active", "claimable", "upcoming"].has(v["phase"]):
			out.append(v)
	var order := {"active": 0, "claimable": 1, "upcoming": 2}
	out.sort_custom(func(a, b): return order[a["phase"]] < order[b["phase"]] or (a["phase"] == b["phase"] and (a["end"] if a["phase"] != "upcoming" else a["start"]) < (b["end"] if b["phase"] != "upcoming" else b["start"])))
	return out

func claimable_count() -> int:
	var n := 0
	for v in list():
		n += int(v["claimable"])
	return n

# ---------------------------------------------------------------- actions ----

func join(iid: String, unlocked: bool) -> Dictionary:
	if not unlocked:
		return {"ok": false, "reason": "locked"}
	var rec := _record(iid)
	if rec.is_empty():
		return {"ok": false, "reason": "not_found"}
	if int(rec["joined_at"]) > 0:
		return {"ok": false, "reason": "already_joined"}
	var t := now()
	if t < int(rec["start"]) or t >= int(rec["end"]):
		return {"ok": false, "reason": "not_active"}
	rec["joined_at"] = _stamp()
	_inst[iid] = rec
	return {"ok": true}

func claim(iid: String, rid: String, reward_service, unlocked: bool) -> Dictionary:
	if not unlocked:
		return {"ok": false, "reason": "locked"}
	if not claims_enabled:
		return {"ok": false, "reason": "claims_disabled"}
	var v := view(iid)
	if v.is_empty() or not _inst.has(iid):
		return {"ok": false, "reason": "not_found"}
	for s in v["steps"]:
		if s["rid"] != rid:
			continue
		if not s["claimable"]:
			return {"ok": false, "reason": "already_claimed" if s["claimed"] else ("expired" if v["phase"] == "expired" else "not_reached")}
		var tx := "event:%s:%s:%s" % [iid, rid, policy_version()]
		if not reward_service.grant(tx, s["reward"]) and not reward_service.already_applied(tx):
			return {"ok": false, "reason": "grant_failed"}
		_stamp()
		(_inst[iid]["claimed"] as Array).append(rid)
		return {"ok": true, "reward": (s["reward"] as Dictionary).duplicate(), "tx": tx}
	return {"ok": false, "reason": "not_found"}

func tutorial_seen(event_id: String) -> bool:
	return _tutorial_seen.has(event_id)

func mark_tutorial_seen(event_id: String) -> void:
	if _defs.has(event_id) and not _tutorial_seen.has(event_id):
		_tutorial_seen.append(event_id)

# -------------------------------------------------------------- snapshot ----

const REC_INTS := ["start", "end", "joined_at", "progress", "best", "reach_t", "finish_t"]

func snapshot() -> Dictionary:
	var keep := {}
	var t := maxi(_hw, int(_clock.call()))
	for iid in _inst:   # expired instances drop out of the save
		if int(_inst[iid]["end"]) + _grace() > t:
			keep[iid] = _inst[iid].duplicate(true)
	return {"version": SNAPSHOT_VERSION, "hw": _hw, "instances": keep, "receipts": _receipts.duplicate(), "tutorial_seen": _tutorial_seen.duplicate()}

func import_snapshot(s) -> bool:
	if s == null:
		_hw = 0
		_inst = {}
		_receipts = []
		_tutorial_seen = []
		return true
	if typeof(s) != TYPE_DICTIONARY or not _is_int(s.get("version")) or int(s["version"]) != SNAPSHOT_VERSION or not _is_int(s.get("hw")):
		return false
	if typeof(s.get("instances")) != TYPE_DICTIONARY or typeof(s.get("receipts")) != TYPE_ARRAY or typeof(s.get("tutorial_seen")) != TYPE_ARRAY:
		return false
	var inst := {}
	for iid in s["instances"]:
		var r = s["instances"][iid]
		if typeof(iid) != TYPE_STRING or typeof(r) != TYPE_DICTIONARY or typeof(r.get("id")) != TYPE_STRING or r.get("iid") != iid:
			return false
		for k in REC_INTS:
			if not _is_int(r.get(k)) or int(r[k]) < 0:
				return false
		for k in ["params", "colors"]:
			if typeof(r.get(k)) != TYPE_DICTIONARY:
				return false
		for k in ["log", "objectives", "claimed"]:
			if typeof(r.get(k)) != TYPE_ARRAY:
				return false
		var rec: Dictionary = r.duplicate(true)
		for k in REC_INTS:
			rec[k] = int(rec[k])
		rec["log"] = rec["log"].map(func(x): return int(x))
		inst[iid] = rec
	for x in s["receipts"] + s["tutorial_seen"]:
		if typeof(x) != TYPE_STRING:
			return false
	_hw = int(s["hw"])
	_inst = inst
	_receipts = s["receipts"].duplicate()
	_tutorial_seen = s["tutorial_seen"].duplicate()
	_cache = {}
	return true

static func _is_int(v) -> bool:
	return (typeof(v) == TYPE_INT) or (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floor(v))
