extends SceneTree
## SB-EV02-002..007 / 014 — Events V02 service evidence (no app root): the 24 definitions vs
## the owner catalog, 3..5 rotation over whole cycles, lifecycle + never-end-early, UTC / DST /
## offline clock, the per-event metric matrix (qualifying / non-qualifying / replay-safe
## receipts), event-only streak rollback, deterministic labelled rivals and teams, idempotent
## existing-currency claims under the worst-case 5-concurrent cap, save / migration.
##
## Run: godot --headless --path . -s res://tests/ev02_events_v02.gd

const EventsV02 = preload("res://scripts/economy/events_v02_service.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")

var EXPECTED_CASES := [
	"e01_definitions", "e02_rotation", "e03_lifecycle", "e04_utc_dst", "e05_offline_clock",
	"e06_metric_matrix", "e07_event_rules", "e08_rivals", "e09_economy", "e10_snapshot",
]

var _fail := 0
var _completed := {}
var _now := [0]
var _cat := {}
var _rt := {}

## Records grants like RewardGrantService (idempotent by tx) without wallet handlers.
class Ledger:
	var applied := {}
	var totals := {}
	func grant(tx: String, rewards: Dictionary) -> bool:
		if applied.has(tx):
			return false
		applied[tx] = rewards
		for k in rewards:
			totals[k] = int(totals.get(k, 0)) + int(rewards[k])
		return true
	func already_applied(tx: String) -> bool:
		return applied.has(tx)

func _initialize() -> void:
	_cat = JSON.parse_string(FileAccess.get_file_as_string(EventsV02.CATALOG))
	_rt = JSON.parse_string(FileAccess.get_file_as_string(EventsV02.PATH))
	_e01()
	_e02()
	_e03()
	_e04()
	_e05()
	_e06()
	_e07()
	_e08()
	_e09()
	_e10()
	_done()

func _svc(path: String = EventsV02.PATH):
	return EventsV02.new(func(): return _now[0], path)

func _epoch() -> int:
	return int(_rt["schedule"]["epoch_utc"])

## First cycle-0 instance of `id`.
func _inst_of(s, id: String) -> Dictionary:
	for x in s.scheduled(_epoch(), _epoch() + 672 * 3600):
		if x["id"] == id:
			return x
	return {}

func _receipt(n: int, won: bool, first: bool = true, boosters: int = 0, colors: Dictionary = {"C01": 300, "C04": 300, "C09": 300}) -> Dictionary:
	var total := 0
	for c in colors:
		total += int(colors[c])
	return {"receipt_id": "L%d:a1" % n, "level": n, "won": won, "first_attempt": first, "boosters_used": boosters,
		"cleaned_active_pixels": total, "cleaned_pixels_by_color": colors.duplicate(), "completed_at_utc": _now[0]}

# ------------------------------------------------------------------ cases ----

func _e01() -> void:
	print("[e01 24 definitions = owner catalog ids / metrics / durations / participants / exact V02 numbers; art per id]")
	var s = _svc()
	_ok(s.config_ok, "runtime config valid")
	var ids: Array = []
	for e in _cat["events"]:
		ids.append(e["id"])
		var d: Dictionary = s.def(e["id"])
		_ok(not d.is_empty() and d["metric"] == e["metric"] and int(d["duration_hours"]) == int(e["proposed_duration_hours"]), "%s: metric %s, %dh" % [e["id"], e["metric"], int(e["proposed_duration_hours"])])
		_ok(FileAccess.file_exists("res://assets/ui/final/events/heroes/%s.png" % e["id"]) and FileAccess.file_exists("res://assets/ui/final/events/icons/%s.png" % e["id"]), "%s: hero + icon art present" % e["id"])
	_ok(ids.size() == 24 and s.event_ids() == ids, "exactly the 24 catalog ids, catalog order")
	var rivals := {"scrub_sprint": 4, "first_brush_race": 4, "scrubbots_royale": 99, "golden_brush_championship": 7, "weekly_scrub_league": 19, "world_cleanup_cup": 20}
	for id in rivals:
		_ok(int(s.def(id)["rivals"]) == rivals[id], "%s: %d virtual rivals (+ player = %d entries)" % [id, rivals[id], rivals[id] + 1])
	var teams := {"scrub_squad_tournament": 10, "clean_team_treasure": 10, "scrub_relay": 5, "mega_stain_cleanup": 20}
	for id in teams:
		_ok(int(s.def(id)["team_size"]) == teams[id], "%s: team of %d" % [id, teams[id]])
	_ok(int(s.def("scrub_sprint")["goal"]) == 15 and s.def("first_brush_race")["goal_options"].map(func(g): return int(g)) == [3, 5], "Scrub Sprint 15 levels; First Brush Race 3 or 5 per instance")
	for pair in [["weekly_cleanup_challenge", [3, 7, 12, 20]], ["perfect_first_clean", [3, 5, 10]], ["sparkling_streak", [3, 5, 7, 10]], ["pure_scrub_challenge", [3, 5, 10]]]:
		_ok(s.def(pair[0])["milestones"].map(func(m): return int(m["target"])) == pair[1], "%s milestones %s" % pair)
	_ok(s.def("scrubbots_royale")["milestones"].size() == 5, "Royale: 5 stages")
	var bad := _rt.duplicate(true)
	bad["events"][0]["metric"] = "first_attempt_new_level_win"
	_ok(not _svc(_tmp_cfg(bad)).config_ok, "a metric that differs from the owner catalog fails the whole config closed")
	bad = _rt.duplicate(true)
	bad["events"].pop_back()
	_ok(not _svc(_tmp_cfg(bad)).config_ok, "a missing event fails closed")
	bad = _rt.duplicate(true)
	bad["events"][5]["milestones"][0]["reward"] = {"event_tokens": 10}
	_ok(not _svc(_tmp_cfg(bad)).config_ok, "a new (unapproved) currency fails closed")
	_complete("e01_definitions")

func _e02() -> void:
	print("[e02 rotation: 3..5 active every hour of 3 cycles, all 24 per 28-day cycle, never more than 5]")
	var s = _svc()
	var counts := {}
	var lo := 99
	var hi := 0
	var one_family := 0
	for h in range(0, 3 * 672):
		for m in [0, 37]:
			var t: int = _epoch() + h * 3600 + m * 60
			var act: Array = s.scheduled(t, t + 1)
			lo = mini(lo, act.size())
			hi = maxi(hi, act.size())
			counts[act.size()] = int(counts.get(act.size(), 0)) + 1
			var fam := {}
			for a in act:
				fam[s.def(a["id"])["family"]] = true
			one_family += 1 if fam.size() < 2 else 0
	_ok(lo == 3 and hi == 5 and counts.has(4), "active count min %d / max %d, distribution %s" % [lo, hi, str(counts)])
	_ok(one_family == 0, "every instant mixes at least two event families")
	for c in range(3):
		var cyc: Array = s.scheduled(_epoch() + c * 672 * 3600, _epoch() + (c + 1) * 672 * 3600)
		var ids := {}
		for x in cyc:
			ids[x["id"]] = int(ids.get(x["id"], 0)) + 1
			if c == 0:
				_ok(int(x["end"]) - int(x["start"]) == int(s.def(x["id"])["duration_hours"]) * 3600, "%s lasts its configured %dh" % [x["iid"], int(s.def(x["id"])["duration_hours"])])
		_ok(ids.size() == 24 and ids.values().max() == 1, "cycle %d: all 24 event types exactly once" % c)
	var before: Array = s.scheduled(_epoch() - 2 * 672 * 3600, _epoch() - 672 * 3600)
	_ok(before.size() == 24 and String(before[0]["iid"]).ends_with(":-2"), "the plan is defined for any UTC instant (cycle -2 has 24 instances)")
	_complete("e02_rotation")

func _e03() -> void:
	print("[e03 lifecycle upcoming -> active -> claimable -> ended/expired; joined windows survive config changes]")
	var s = _svc()
	var x := _inst_of(s, "weekly_cleanup_challenge")
	_now[0] = int(x["start"]) - 3600
	_ok(s.view(x["iid"])["phase"] == "upcoming" and not s.join(x["iid"], true)["ok"], "upcoming: previewed, cannot be joined")
	_now[0] = int(x["start"]) + 60
	_ok(s.view(x["iid"])["phase"] == "active", "active at start")
	_ok(not s.join(x["iid"], false)["ok"], "join refused while Events are locked")
	_ok(s.join(x["iid"], true)["ok"] and not s.join(x["iid"], true)["ok"], "join once")
	for n in range(31, 34):
		s.on_receipt(_receipt(n, true), true)
	var v: Dictionary = s.view(x["iid"])
	_ok(v["progress"] == 3 and v["steps"][0]["claimable"] and v["claimable"] == 1, "3 first clears -> milestone 3 claimable while active")
	# config changed mid-event (shorter duration, different lanes): the joined window is kept
	var alt := _rt.duplicate(true)
	for e in alt["events"]:
		if e["id"] == "weekly_cleanup_challenge":
			e["duration_hours"] = 168
	alt["schedule"]["epoch_utc"] = _epoch() + 86400
	s.load_config(_tmp_cfg(alt))
	_ok(s.config_ok and s.view(x["iid"])["end"] == x["end"] and s.view(x["iid"])["progress"] == 3, "a config change never moves / erases a joined instance's window or progress")
	s.load_config(EventsV02.PATH)
	_now[0] = int(x["end"]) + 60
	v = s.view(x["iid"])
	_ok(v["phase"] == "claimable" and v["claim_ends_in"] > 0, "ended with an unclaimed reward -> claimable for the grace period")
	_ok(s.list().any(func(l): return l["iid"] == x["iid"]), "claimable ended event stays listed")
	var led := Ledger.new()
	_ok(s.claim(x["iid"], "m0", led, true)["ok"], "claim inside the grace")
	_ok(s.view(x["iid"])["phase"] == "ended" and not s.list().any(func(l): return l["iid"] == x["iid"]), "nothing left -> ended, delisted")
	var y := _inst_of(s, "perfect_first_clean")
	_now[0] = int(y["start"]) + 60
	s.join(y["iid"], true)
	for n in range(40, 43):
		s.on_receipt(_receipt(n, true), true)
	_now[0] = int(y["end"]) + int(_rt["claim_grace_hours"]) * 3600 + 1
	_ok(s.view(y["iid"])["phase"] == "expired" and s.claim(y["iid"], "m0", led, true)["reason"] == "expired", "after the grace: expired, claim refused (configured forfeit, never silent)")
	_ok(not s.snapshot()["instances"].has(y["iid"]), "expired instances drop out of the save")
	_complete("e03_lifecycle")

func _e04() -> void:
	print("[e04 UTC scheduling: whole hours from the epoch, countdown continuous across a DST change]")
	var s = _svc()
	for x in s.scheduled(_epoch(), _epoch() + 672 * 3600):
		if (int(x["start"]) - _epoch()) % 3600 != 0:
			_ok(false, "%s starts off the hour grid" % x["iid"])
	var dst := 1806195600   # 2027-03-28 01:00 UTC (EU clocks go forward)
	var act: Array = s.scheduled(dst, dst + 1)
	var ok := true
	for x in act:
		var fresh = _svc()   # own high-water clock per sweep
		for dh in range(-3, 4):
			_now[0] = dst + dh * 3600
			var v: Dictionary = fresh.view(x["iid"])
			if v["phase"] == "active" and v["ends_in"] + _now[0] != int(x["end"]):
				ok = false
	_ok(ok and act.size() >= 3, "%d events active across the DST instant; ends_in + now == end (UTC seconds, no local wall clock)" % act.size())
	var src := FileAccess.get_file_as_string("res://scripts/economy/events_v02_service.gd")
	_ok(not src.contains("get_time_zone") and not src.contains("dict_from_system"), "service never reads the device time zone / local date")
	_complete("e04_utc_dst")

func _e05() -> void:
	print("[e05 offline / clock tampering: high-water clock, rivals stable offline and after reload]")
	var s = _svc()
	var x := _inst_of(s, "weekly_scrub_league")
	_now[0] = int(x["start"]) + 2 * 86400
	s.join(x["iid"], true)
	var rec: Dictionary = s._record(x["iid"])
	var before: Array = s.view(x["iid"])["standings"].map(func(r): return r["score"])
	_now[0] = int(x["start"]) + 3600   # clock moved back two days
	_ok(s.now() == int(x["start"]) + 2 * 86400 and s.view(x["iid"])["standings"].map(func(r): return r["score"]) == before, "clock moved back: time and rival scores do not rewind")
	_now[0] = int(x["start"]) + 5 * 86400   # offline three days
	var after: Dictionary = s.view(x["iid"])
	var fresh = _svc()
	fresh.import_snapshot(s.snapshot())
	_ok(fresh.view(x["iid"])["standings"] == after["standings"], "offline progress: a reloaded save computes the identical standings")
	var mono := true
	for i in range(1, 20):
		var last := -1
		for h in range(0, 168, 6):
			var sc: int = s.rival_score(rec, i, int(x["start"]) + h * 3600)[0]
			mono = mono and sc >= last
			last = sc
	_ok(mono, "every rival score is non-decreasing over the window (no impossible movement)")
	# SB-EV02 CI fix (factory 175): reads never write; only a state change stamps the high-water.
	var snap0: Dictionary = s.snapshot()
	_now[0] += 3600
	s.list()
	s.view(x["iid"])
	s.active_count()
	s.claimable_count()
	_ok(s.snapshot() == snap0, "list / view / counts at a later clock leave the save byte-identical")
	s.on_receipt(_receipt(950, true), true)
	_ok(int(s.snapshot()["hw"]) == _now[0], "an applied receipt stamps the high-water mark")
	var end_past := _inst_of(s, "scrub_sprint")
	_now[0] = int(end_past["end"]) + 10
	_ok(s.view(end_past["iid"])["phase"] != "active" and not s.join(end_past["iid"], true)["ok"], "an ended instance cannot be joined late")
	_complete("e05_offline_clock")

func _e06() -> void:
	print("[e06 24-event metric matrix: qualifying win / non-first-try win / booster win / loss / replayed receipt / locked / not joined]")
	# expected increments per receipt kind: [first-try boosterless win, retry win, booster win, loss]
	var px := 900
	var expect := {
		"first_clear_new_level": [1, 1, 1, 0], "first_attempt_new_level_win": [1, 0, 1, 0],
		"cleaned_active_pixels_on_new_levels": [px, px, px, 0], "cleaned_active_pixels": [px, px, px, 0],
		"win_without_booster_usage": [1, 1, 0, 0], "virtual_team_qualifying_level_wins": [1, 1, 1, 0],
		"virtual_team_cleaning_points": [1, 1, 1, 0], "virtual_team_sequential_clears": [1, 1, 1, 0],
		"virtual_team_cleaned_active_pixels": [px, px, px, 0], "seasonal_qualifying_level_progress": [1, 1, 1, 0],
		"first_clear_new_level_cleanup_score": [175, 125, 150, 0],
	}
	for e in _cat["events"]:
		var id := String(e["id"])
		var s = _svc()
		var x := _inst_of(s, id)
		_now[0] = int(x["start"]) + 60
		s.on_receipt(_receipt(1, true), true)
		_ok(s.view(x["iid"])["progress"] == 0, "%s: a receipt before joining never counts (no retroactive award)" % id)
		s.join(x["iid"], true)
		var kind := String(s.def(id)["kind"])
		if kind == "quest" or kind == "colors" or kind == "streak":
			continue   # e07 covers these rules
		var seq := [_receipt(2, true, true, 0), _receipt(3, true, false, 0), _receipt(4, true, true, 2), _receipt(5, false, true, 0)]
		var ok := true
		var got: Array = []
		for i in range(4):
			var p0: int = s.view(x["iid"])["progress"]
			s.on_receipt(seq[i], true)
			got.append(int(s.view(x["iid"])["progress"]) - p0)
		ok = got == expect[e["metric"]]
		var p1: int = s.view(x["iid"])["progress"]
		s.on_receipt(seq[0], true)
		s.on_receipt(_receipt(6, true), false)
		var bad := _receipt(7, true)
		bad["cleaned_active_pixels"] = 1
		s.on_receipt(bad, true)
		_ok(ok and s.view(x["iid"])["progress"] == p1, "%s (%s): increments %s; replayed receipt, locked Events and an unreconciled receipt add nothing" % [id, e["metric"], str(got)])
	_complete("e06_metric_matrix")

func _e07() -> void:
	print("[e07 event rules: streak checkpoints, colors, quest, race / royale / bracket / ranking / teams]")
	var s = _svc()
	var x := _inst_of(s, "sparkling_streak")
	_now[0] = int(x["start"]) + 60
	s.join(x["iid"], true)
	var n := 100
	for i in range(6):
		n += 1
		s.on_receipt(_receipt(n, true), true)
	n += 1
	s.on_receipt(_receipt(n, false), true)
	var v: Dictionary = s.view(x["iid"])
	_ok(v["progress"] == 5 and v["best"] == 6 and v["steps"][1]["reached"] and not v["steps"][2]["reached"], "6 wins then a loss: run back to checkpoint 5, best 6 kept (event-only rollback)")
	n += 1
	s.on_receipt(_receipt(n, false), true)
	_ok(s.view(x["iid"])["progress"] == 5, "a second loss stays at the checkpoint")
	var c := _inst_of(s, "color_scrub_rush")
	_now[0] = int(c["start"]) + 60
	s.join(c["iid"], true)
	var targets: Array = s.view(c["iid"])["params"]["colors"]
	_ok(targets.size() == 3 and targets[0] != targets[1], "Color Scrub Rush: 3 distinct target colors %s (deterministic per instance)" % str(targets))
	n += 1
	s.on_receipt(_receipt(n, true, true, 0, {targets[0]: 300, targets[1]: 150, "C99": 500}), true)
	v = s.view(c["iid"])
	_ok(v["progress"] == 1 and v["colors"][targets[1]] == 150, "only cleaned pixels of each target color count (1/3 colors complete)")
	var q := _inst_of(s, "master_cleaner_quest")
	_now[0] = int(q["start"]) + 60
	var s2 = _svc()
	s2.join(q["iid"], true)
	var others: Array = s2.scheduled(_now[0], _now[0] + 1).filter(func(o): return o["id"] != "master_cleaner_quest")
	for o in others:
		s2.join(o["iid"], true)
	for i in range(12):
		s2.on_receipt(_receipt(200 + i, true), true)
	v = s2.view(q["iid"])
	_ok(v["objectives"] >= 2 and v["objectives"] <= others.size() and v["steps"][0]["reached"], "Master Cleaner Quest: %d other events' reward steps counted once each (%d joined)" % [v["objectives"], others.size()])
	var obj: int = v["objectives"]
	s2.on_receipt(_receipt(300, true), true)
	_ok(s2.view(q["iid"])["objectives"] == obj, "no double counting on later receipts")
	# race
	var r := _inst_of(s, "first_brush_race")
	var goal: int = s.view(r["iid"])["params"]["goal"]
	_ok([3, 5].has(goal) and s.view(r["iid"])["entrants"] == 5, "First Brush Race goal %d (3 or 5), 5 entrants" % goal)
	var sp := _inst_of(s, "scrub_sprint")
	_now[0] = int(sp["start"]) + 60
	var s3 = _svc()
	s3.join(sp["iid"], true)
	for i in range(15):
		s3.on_receipt(_receipt(400 + i, true), true)
	v = s3.view(sp["iid"])
	_ok(v["steps"][0]["reached"] and v["steps"][0]["value"] == 1 and v["steps"][0]["claimable"], "Scrub Sprint: 15 first clears in the first minute -> place 1, claimable at finish")
	var ro := _inst_of(s, "scrubbots_royale")
	_now[0] = int(ro["end"]) - 60
	v = s.view(ro["iid"])
	_ok(v["entrants"] == 100 and v["standings"].size() == 100 and v["stage_counts"].size() == 5, "Royale: 100 entrants (player + 99), 5 stages, survivors %s" % str(v["stage_counts"]))
	var dec := true
	for i in range(1, 5):
		dec = dec and v["stage_counts"][i] <= v["stage_counts"][i - 1]
	_ok(dec, "fewer entrants clear each later stage")
	var gb := _inst_of(s, "golden_brush_championship")
	_now[0] = int(gb["end"]) + 60
	var s4 = _svc()
	v = s4.view(gb["iid"])
	var b: Dictionary = v["bracket"]
	_ok(v["entrants"] == 8 and b["rounds"].size() == 1 and b["rounds"][0].size() == 4 and b["out"] and b["final"], "Championship 8 entrants; a player who never scored loses the quarter-final 0-0 (bracket 8->4)")
	_now[0] = int(gb["start"]) + 60
	var s5 = _svc()
	s5.join(gb["iid"], true)
	var L := (int(gb["end"]) - int(gb["start"])) / 3
	for rd in range(3):
		_now[0] = int(gb["start"]) + rd * L + 60
		for i in range(40):
			s5.on_receipt(_receipt(500 + rd * 100 + i, true), true)
	_now[0] = int(gb["end"]) + 60
	b = s5.view(gb["iid"])["bracket"]
	_ok(b["rounds"].size() == 3 and b["rounds"][1].size() == 2 and b["rounds"][2].size() == 1 and b["won"] == 3 and b["final"], "40 wins per round -> 8->4->2->1 champion (3 rounds won)")
	_ok(s5.view(gb["iid"])["steps"][0]["claimable"], "champion result claimable")
	for id in ["weekly_scrub_league", "world_cleanup_cup"]:
		var lg := _inst_of(s, id)
		_now[0] = int(lg["start"]) + 3600
		_ok(s.view(lg["iid"])["standings"].size() == int(s.def(id)["rivals"]) + 1, "%s: %d ranked entries" % [id, int(s.def(id)["rivals"]) + 1])
	for id in ["scrub_squad_tournament", "clean_team_treasure", "scrub_relay", "mega_stain_cleanup"]:
		var tm := _inst_of(s, id)
		_now[0] = int(tm["end"]) - 60
		var s6 = _svc()
		var tv: Dictionary = s6.view(tm["iid"])
		var size := int(s6.def(id)["team_size"])
		_ok(tv["team_size"] == size and tv["team_total"] > 0 and not tv["steps"].any(func(st): return st["reached"]), "%s: %d-member virtual team scores %d, but nothing is reached without the player's own contribution" % [id, size, tv["team_total"]])
	_complete("e07_event_rules")

func _e08() -> void:
	print("[e08 rivals: deterministic, labelled canonical robots, unique names, independent of the player]")
	var a = _svc()
	var b = _svc()
	var x := _inst_of(a, "scrubbots_royale")
	_now[0] = int(x["start"]) + 30 * 3600
	_ok(a.view(x["iid"])["standings"] == b.view(x["iid"])["standings"], "same instance -> identical standings in two services")
	var rec: Dictionary = a._record(x["iid"])
	var names := {}
	var robots_ok := true
	for i in range(1, 100):
		var en: Dictionary = a.entrant(rec, i)
		names[en["name"]] = true
		robots_ok = robots_ok and EventsV02.ROBOTS.has(en["robot"]) and EventsV02.PROFILES.has(en["profile"])
	_ok(names.size() == 99 and robots_ok, "99 rivals: unique display names, canonical robot avatars, casual/average/strong/expert profiles")
	var y := _inst_of(a, "scrubbots_royale")
	var c = _svc()
	c.join(y["iid"], true)
	var before: Array = c.view(y["iid"])["standings"].filter(func(r): return not r["player"])
	for i in range(10):
		c.on_receipt(_receipt(600 + i, true, true, i % 3), true)
	var after: Array = c.view(y["iid"])["standings"].filter(func(r): return not r["player"])
	var sc := func(arr): return arr.map(func(r): return [r["idx"], r["score"]])
	var sb: Array = sc.call(before)
	var sa: Array = sc.call(after)
	sb.sort()
	sa.sort()
	_ok(sb == sa, "player wins / booster use never move rival scores")
	var src := FileAccess.get_file_as_string("res://scripts/economy/events_v02_service.gd")
	_ok(not src.contains("wallet") and not src.contains("purchase") and not src.contains("store") and not src.contains("debit"), "no spend / store input can reach rival or event progress")
	var next_cycle: Dictionary = a._record(String(x["iid"]).replace(":0", ":1"))
	var diff := 0
	for i in range(1, 100):
		diff += 1 if a.entrant(next_cycle, i)["profile"] != a.entrant(rec, i)["profile"] else 0
	_ok(diff > 0, "the next Royale instance draws its own rival profiles (%d of 99 differ)" % diff)
	_complete("e08_rivals")

func _e09() -> void:
	print("[e09 economy: existing currencies only, worst-case 5-concurrent cycle under the cap, idempotent claims]")
	var s = _svc()
	var cap: Dictionary = s.cap_report
	var types: Array = _rt["approved_reward_types"]
	_ok(cap.keys().all(func(k): return types.has(k)) and types.size() == 6, "only the 6 approved existing reward types %s" % str(types))
	var fits := true
	for k in cap:
		fits = fits and int(cap[k]["max"]) <= int(cap[k]["cap"])
	_ok(fits and s.claims_enabled, "worst case (every event at its best, 3..5 concurrent, one 28-day cycle) within the cap %s" % str(cap))
	var totals := {}
	for rate in [2, 10, 40]:
		totals[rate] = _simulate(rate)
		var under := true
		for k in totals[rate]:
			under = under and int(totals[rate][k]) <= int(cap[k]["cap"])
		_ok(under, "%d levels/day player joining everything for a full cycle earns %s (<= cap)" % [rate, str(totals[rate])])
	_ok(int(totals[40].get("scrub_bucks", 0)) > int(totals[2].get("scrub_bucks", 0)), "more play earns more (casual %d SB < high volume %d SB)" % [int(totals[2].get("scrub_bucks", 0)), int(totals[40].get("scrub_bucks", 0))])
	var x := _inst_of(s, "robot_parts_recovery")
	_now[0] = int(x["start"]) + 60
	s.join(x["iid"], true)
	for i in range(3):
		s.on_receipt(_receipt(700 + i, true), true)
	var real := RewardGrantService.new()
	var r1: Dictionary = s.claim(x["iid"], "m0", real, true)
	var r2: Dictionary = s.claim(x["iid"], "m0", real, true)
	_ok(r1["ok"] and r1["tx"] == "event:%s:m0:%s" % [x["iid"], _rt["reward_policy_version"]] and real.wallet().bot_parts() == 1, "claim grants 1 Bot Part once through RewardGrantService (%s)" % r1.get("tx", ""))
	_ok(not r2["ok"] and r2["reason"] == "already_claimed" and real.wallet().bot_parts() == 1, "second claim refused")
	var snap: Dictionary = s.snapshot()
	snap["instances"][x["iid"]]["claimed"] = []   # a stale / imported save that lost the claim mark
	var s2 = _svc()
	s2.import_snapshot(snap)
	var r3: Dictionary = s2.claim(x["iid"], "m0", real, true)
	_ok(r3["ok"] and real.wallet().bot_parts() == 1, "a save that lost the claim mark re-marks it, the reward ledger never pays twice")
	_ok(not s.claim(x["iid"], "m1", real, true)["ok"] and not s.claim(x["iid"], "m0", real, false)["ok"], "unreached / locked claims refused")
	var over := _rt.duplicate(true)
	over["cycle_reward_cap"]["scrub_bucks"] = 100
	var s3 = _svc(_tmp_cfg(over))
	_ok(s3.config_ok and not s3.claims_enabled, "a reward table over the cap -> claims disabled (preview only)")
	s3.join(x["iid"], true)
	for i in range(3):
		s3.on_receipt(_receipt(800 + i, true), true)
	_ok(s3.claim(x["iid"], "m0", real, true)["reason"] == "claims_disabled" and s3.view(x["iid"])["claimable"] == 0, "nothing claimable while disabled")
	real.release_handlers()
	_complete("e09_economy")

## One cycle of play at `rate` first clears per day; joins and claims everything it can.
func _simulate(rate: int) -> Dictionary:
	var s = _svc()
	var led := Ledger.new()
	var colors := {}
	for i in range(1, 17):
		colors["C%02d" % i] = 60
	var step := 86400 / rate
	var n := 0
	var t := _epoch()
	while t < _epoch() + (672 + 80) * 3600:
		_now[0] = t
		if t < _epoch() + 672 * 3600:
			for a in s.scheduled(t, t + 1):
				if a["iid"].ends_with(":0"):
					s.join(a["iid"], true)
			n += 1
			s.on_receipt(_receipt(10000 + n, true, n % 3 != 0, 1 if n % 4 == 0 else 0, colors), true)
		for v in s.list():
			for st in v["steps"]:
				if st["claimable"]:
					s.claim(v["iid"], st["rid"], led, true)
		t += step
	return led.totals

func _e10() -> void:
	print("[e10 save: absent section = fresh, strict import, round trip]")
	var s = _svc()
	_ok(s.import_snapshot(null) and s.snapshot()["instances"].is_empty(), "absent section (older save) -> fresh")
	var x := _inst_of(s, "stain_busters")
	_now[0] = int(x["start"]) + 60
	s.join(x["iid"], true)
	s.on_receipt(_receipt(900, true), true)
	s.mark_tutorial_seen("stain_busters")
	var snap: Dictionary = JSON.parse_string(JSON.stringify(s.snapshot()))   # through JSON like the save file
	var s2 = _svc()
	_ok(s2.import_snapshot(snap) and s2.view(x["iid"]) == s.view(x["iid"]) and s2.tutorial_seen("stain_busters"), "JSON round trip keeps instances, progress and tutorial flags")
	s2.on_receipt(_receipt(900, true), true)
	_ok(s2.view(x["iid"])["progress"] == 900, "receipt ids survive a reload (no recount after restart)")
	for bad in [{"version": 2}, {"version": 1, "hw": 0, "instances": [], "receipts": [], "tutorial_seen": []},
			{"version": 1, "hw": 0, "instances": {"a:0": {"iid": "a:0", "id": "a"}}, "receipts": [], "tutorial_seen": []}]:
		_ok(not s2.import_snapshot(bad), "malformed section refused %s" % JSON.stringify(bad).left(60))
	_complete("e10_snapshot")

# ---------------------------------------------------------------- helpers ----

func _tmp_cfg(d: Dictionary) -> String:
	var p := "user://ev02_cfg_%d.json" % Time.get_ticks_usec()
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(JSON.stringify(d))
	f.close()
	return p

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(id: String) -> void:
	_completed[id] = true

func _done() -> void:
	var dir := DirAccess.open("user://")
	if dir != null:
		for f in dir.get_files():
			if f.begins_with("ev02_cfg_"):
				dir.remove(f)
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("EV02 events service evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
