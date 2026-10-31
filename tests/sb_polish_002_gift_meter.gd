extends SceneTree
## SB-POLISH-002 — Gift Meter next-milestone cycle 1/5/10/25/100/250/500/1000, scaling gifts,
## schema-3 save migration (legacy 50) and clean reward text (no raw REWARD_ keys).
## Real EconomyConfig / GiftMeterService / AppState / Home scene / Gift Bar popup.
##
## Run: godot --headless --path . -s res://tests/sb_polish_002_gift_meter.gd

const AppState = preload("res://scripts/app/app_state.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const GiftProgressModel = preload("res://scripts/economy/gift_progress_model.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const CONFIG := "res://data/config/economy_rewards_v1.json"
const CYCLE := [1, 5, 10, 25, 100, 250, 500, 1000]
const REWARD_KEYS := ["bot_parts", "scrub_bucks", "standard_card_packs", "premium_card_packs", "random_any_booster_charges",
	"selected_booster_charges", "guaranteed_new_cards", "guaranteed_new_fallback_sb"]
const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]
## Owner table (spec / OWNER_ECONOMY_REWARDS_V01 §4.3).
const TABLE := {
	1: {"scrub_bucks": 25},
	5: {"bot_parts": 1, "scrub_bucks": 50},
	10: {"bot_parts": 1, "scrub_bucks": 50, "standard_card_packs": 1},
	25: {"bot_parts": 1, "scrub_bucks": 100, "random_any_booster_charges": 1},
	100: {"bot_parts": 1, "scrub_bucks": 150, "standard_card_packs": 1},
	250: {"bot_parts": 2, "scrub_bucks": 200, "selected_booster_charges": 1, "standard_card_packs": 1},
	500: {"bot_parts": 2, "scrub_bucks": 300, "selected_booster_charges": 1, "standard_card_packs": 1},
	1000: {"bot_parts": 2, "scrub_bucks": 600, "selected_booster_charges": 2, "premium_card_packs": 1, "guaranteed_new_cards": 1, "guaranteed_new_fallback_sb": 500},
}

var EXPECTED_CASES := [
	"p02_config", "p03_next_milestone", "p04_multi_cross_rollover", "p05_claim_bundles", "p06_migration_a",
	"p07_migration_b", "p08_invalid_snapshots", "p09_home_ratio", "p10_gift_bar_rows", "p11_reward_text_all_bundles",
	"p12_unknown_key",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _cfg: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_cfg = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	_p02_config()
	_p03_next_milestone()
	_p04_multi_cross_rollover()
	_p05_claim_bundles()
	_p06_migration_a()
	_p07_migration_b()
	_p08_invalid_snapshots()
	await _p09_home_ratio()
	await _p10_gift_bar_rows()
	_p11_reward_text_all_bundles()
	_p12_unknown_key()
	_cleanup()
	_done()

func _p02_config() -> void:
	print("[p02 config: schema 3, eight milestones, owner table, legacy 50]")
	var c = EconomyConfig.new()
	_ok(c.is_ok(), "schema 3 config loads %s" % c.get_error())
	_ok(c.gift_meter_milestones() == CYCLE, "milestone keys exactly %s (%s)" % [str(CYCLE), str(c.gift_meter_milestones())])
	var bp := 0
	var sb := 0
	var bad_keys: Array = []
	var table_ok := true
	for m in CYCLE:
		var b: Dictionary = c.gift_meter_milestone(m)
		bp += int(b.get("bot_parts", 0))
		sb += int(b.get("scrub_bucks", 0))
		table_ok = table_ok and _num(b) == _num(TABLE[m])
		for k in b:
			if not REWARD_KEYS.has(k):
				bad_keys.append(k)
	_ok(bp == 10 and sb == 1475, "full cycle sums: %d Bot Parts (10), %d SB (1475)" % [bp, sb])
	_ok(table_ok, "every bundle equals the owner table")
	_ok(bad_keys.is_empty(), "only existing reward keys %s" % str(bad_keys))
	_ok(_num(c.gift_meter_legacy_milestone(50)) == _num({"bot_parts": 1, "random_any_booster_charges": 1}) and c.gift_meter_milestone(50).is_empty(), "legacy 50 = 1 Bot Part + 1 Mystery Booster, not in the live cycle")
	_ok(GiftMeterService.new().full_cycle_bot_parts(c) == 10, "full_cycle_bot_parts() == 10")
	var v2: Dictionary = _cfg.duplicate(true)
	v2["schema_version"] = 2
	_ok(not _load(v2, "v2").is_ok(), "schema_version 2 rejected")
	var leg: Dictionary = _cfg.duplicate(true)
	leg["gift_meter"]["legacy_milestones"]["50"]["random_booster_charges"] = 1
	_ok(not _load(leg, "legacy_key").is_ok(), "legacy random_booster_charges key rejected (legacy table too)")
	for k in ["0", "1001", "x"]:
		var bad: Dictionary = _cfg.duplicate(true)
		bad["gift_meter"]["milestones"][k] = {"scrub_bucks": 1}
		_ok(not _load(bad, "key_" + k).is_ok(), "milestone key %s rejected (must be positive int <= cycle_max)" % k)
	_complete("p02_config")

func _p03_next_milestone() -> void:
	print("[p03 fresh service: next milestone walks the cycle]")
	var g = GiftMeterService.new()
	_ok(g.cycle_progress() == 0 and GiftProgressModel.next_milestone(0) == 1, "fresh: progress 0, next 1")
	var newly: Array = g.add_streak_sb("a", 1)
	_ok(newly.size() == 1 and int(newly[0]["milestone"]) == 1 and g.cycle_progress() == 1 and GiftProgressModel.next_milestone(1) == 5, "+1 queues m1 once; progress 1, next 5")
	var steps := [[5, 10], [10, 25], [25, 100], [100, 250], [250, 500], [500, 1000]]
	var bad: Array = []
	for st in steps:
		var n: Array = g.add_streak_sb("to_%d" % st[0], st[0] - g.cycle_progress())
		if g.cycle_progress() != st[0] or GiftProgressModel.next_milestone(g.cycle_progress()) != st[1] or n.size() != 1 or int(n[0]["milestone"]) != st[0]:
			bad.append(st)
	_ok(bad.is_empty(), "5->10, 10->25, 25->100, 100->250, 250->500, 500->1000, one occurrence each %s" % str(bad))
	_complete("p03_next_milestone")

func _p04_multi_cross_rollover() -> void:
	print("[p04 one feed crosses many once; overflow rolls; duplicate tx no-op]")
	var g = GiftMeterService.new()
	var n: Array = g.add_streak_sb("big", 1000)
	_ok(n.map(func(o): return int(o["milestone"])) == CYCLE and g.cycles_completed() == 1 and g.cycle_progress() == 0, "1000 from 0 queues all 8 once, completes the cycle")
	var h = GiftMeterService.new()
	h.add_streak_sb("a", 998)
	var q0: int = h.gift_bar_queue().size()
	var r: Array = h.add_streak_sb("b", 5)
	_ok(r.map(func(o): return o["id"]) == ["gift_ms:c0:m1000", "gift_ms:c1:m1"] and h.cycles_completed() == 1 and h.cycle_progress() == 3, "998 + 5: m1000 queued, cycle 1 at 3 with c1:m1 queued")
	_ok(h.add_streak_sb("b", 5).is_empty() and h.gift_bar_queue().size() == q0 + 2 and h.cycle_progress() == 3, "duplicate tx id queues nothing")
	_complete("p04_multi_cross_rollover")

func _p05_claim_bundles() -> void:
	print("[p05 each claim grants exactly its bundle once]")
	var app = AppState.new(_uniq("p05"))
	var e = app.economy
	e.gift.add_streak_sb("p05", 1000)
	var bad: Array = []
	for m in CYCLE:
		var b: Dictionary = TABLE[m]
		var id := "gift_ms:c0:m%d" % m
		var s0 := _state(e)
		var r: Dictionary = app.actions.claim_gift(id)
		var s1 := _state(e)
		var want := [int(b.get("scrub_bucks", 0)), int(b.get("bot_parts", 0)), int(b.get("standard_card_packs", 0)), int(b.get("premium_card_packs", 0)),
			int(b.get("random_any_booster_charges", 0)), int(b.get("selected_booster_charges", 0)), int(b.get("guaranteed_new_cards", 0))]
		var got: Array = []
		for i in range(s0.size()):
			got.append(s1[i] - s0[i])
		if not bool(r.get("ok", false)) or got != want:
			bad.append([m, got, want])
		var again: Dictionary = app.actions.claim_gift(id)
		if bool(again.get("ok", true)) or String(again.get("reason", "")) != "already_claimed" or _state(e) != s1:
			bad.append([m, "second claim", again])
	_ok(bad.is_empty(), "8 claims == table deltas (SB, BP, packs, premium, mystery, choice, new card); re-claim already_claimed + unchanged %s" % str(bad))
	_complete("p05_claim_bundles")

func _p06_migration_a() -> void:
	print("[p06 migration A: old 898 save keeps claims, backfills current-cycle 1/5/25/100]")
	var g = GiftMeterService.new()
	var old := _old_snapshot(898, 0, [["gift_ms:c0:m10", 0, 10, true], ["gift_ms:c0:m50", 0, 50, true], ["gift_ms:c0:m250", 0, 250, false], ["gift_ms:c0:m500", 0, 500, false]])
	_ok(g.import_snapshot(old), "old snapshot imports")
	var q: Array = g.gift_bar_queue()
	var ids: Array = q.map(func(o): return o["id"])
	_ok(ids == ["gift_ms:c0:m10", "gift_ms:c0:m50", "gift_ms:c0:m250", "gift_ms:c0:m500", "gift_ms:c0:m1", "gift_ms:c0:m5", "gift_ms:c0:m25", "gift_ms:c0:m100"], "queue gains c0:m1/m5/m25/m100 %s" % str(ids))
	_ok(q.map(func(o): return o["claimed"]) == [true, true, false, false, false, false, false, false], "claimed flags preserved, backfill unclaimed")
	var uniq := {}
	for i in ids:
		uniq[i] = true
	_ok(uniq.size() == ids.size(), "no duplicate ids")
	_ok(g.cycle_progress() == 898 and g.total_progress() == 898 and UiText.t("HOME_RATIO", [UiText.num(g.cycle_progress()), UiText.num(GiftProgressModel.next_milestone(g.cycle_progress()))]) == "898/1,000", "progress 898 shows 898/1,000")
	_complete("p06_migration_a")

func _p07_migration_b() -> void:
	print("[p07 migration B: legacy 50 pays the legacy bundle; idempotent; past cycle not backfilled]")
	var app = AppState.new(_uniq("p07"))
	var e = app.economy
	var old := _old_snapshot(60, 0, [["gift_ms:c0:m10", 0, 10, false], ["gift_ms:c0:m50", 0, 50, false]])
	_ok(e.gift.import_snapshot(old), "old unclaimed m10 / m50 imports")
	var s0 := _state(e)
	_ok(bool(app.actions.claim_gift("gift_ms:c0:m50").get("ok", false)), "legacy m50 claimable")
	var s1 := _state(e)
	_ok(_delta(s0, s1) == [0, 1, 0, 0, 1, 0, 0], "m50 paid 1 Bot Part + 1 Mystery Booster %s" % str(_delta(s0, s1)))
	_ok(app.actions.claim_gift("gift_ms:c0:m50").get("reason", "") == "already_claimed" and _state(e) == s1, "legacy m50 pays once")
	_ok(bool(app.actions.claim_gift("gift_ms:c0:m10").get("ok", false)) and _delta(s1, _state(e)) == [50, 1, 1, 0, 0, 0, 0], "old m10 pays the NEW m10 bundle")
	var snap: Dictionary = e.gift.snapshot()
	var g2 = GiftMeterService.new()
	_ok(g2.import_snapshot(snap) and g2.gift_bar_queue() == e.gift.gift_bar_queue(), "re-importing the migrated snapshot is a no-op")
	var g3 = GiftMeterService.new()
	_ok(g3.import_snapshot(_old_snapshot(0, 1, [["gift_ms:c0:m10", 0, 10, false]])) and g3.gift_bar_queue().size() == 1, "past cycle (c0, cycles_completed 1, progress 0): no backfill")
	var g4 = GiftMeterService.new()
	_ok(g4.import_snapshot(_old_snapshot(7, 1, [["gift_ms:c0:m50", 0, 50, false]])) and g4.gift_bar_queue().map(func(o): return o["id"]) == ["gift_ms:c0:m50", "gift_ms:c1:m1", "gift_ms:c1:m5"], "progress 7 in cycle 1: only c1 backfilled, never c0")
	_complete("p07_migration_b")

func _p08_invalid_snapshots() -> void:
	print("[p08 invalid snapshots fail closed]")
	var cases := {
		"milestone 7": _old_snapshot(10, 0, [["gift_ms:c0:m7", 0, 7, false]]),
		"duplicate id": _old_snapshot(10, 0, [["gift_ms:c0:m10", 0, 10, false], ["gift_ms:c0:m10", 0, 10, true]]),
		"fractional progress": {"cycle_progress": 1.5, "total_progress": 1.5, "cycles_completed": 0, "gift_bar_queue": [], "applied": []},
		"total mismatch": {"cycle_progress": 10, "total_progress": 11, "cycles_completed": 0, "gift_bar_queue": [], "applied": []},
	}
	for k in cases:
		var g = GiftMeterService.new()
		g.add_streak_sb("keep", 3)
		var before: Dictionary = g.snapshot()
		_ok(not g.import_snapshot(cases[k]) and g.snapshot() == before, "%s rejected, state untouched" % k)
	_complete("p08_invalid_snapshots")

func _p09_home_ratio() -> void:
	print("[p09 Home bar: progress / next milestone, fill = progress / next]")
	var bad: Array = []
	for c in [[0, "0/1", 1], [7, "7/10", 10], [61, "61/100", 100], [330, "330/500", 500], [898, "898/1,000", 1000]]:
		var sub := SubViewport.new()
		sub.size = Vector2i(1080, 2160)
		sub.disable_3d = true
		get_root().add_child(sub)
		var app = AppState.new(_uniq("p09_%d" % c[0]))
		if c[0] > 0:
			app.economy.gift.add_streak_sb("seed", c[0])
		var home = HomeScreenScene.instantiate()
		sub.add_child(home)
		home.bind(app)
		for _i in range(2):
			await process_frame
		home.refresh()
		var meter = home.get_region("GiftMeterBar")
		var ov = home.get_region("GiftTickOverlay")
		var txt: String = meter.caption.text
		if txt != c[1] or not is_equal_approx(meter.bar.value / meter.bar.max_value, float(c[0]) / float(c[2])) or home.get_view_model()["gift_next_milestone"] != c[2] \
				or (c[2] < 1000 and txt.contains("/1,000")) or int(ov.get_model()["cycle_max"]) != c[2]:
			bad.append([c, txt, meter.bar.value, meter.bar.max_value])
		sub.free()
	_ok(bad.is_empty(), "0/1, 7/10, 61/100, 330/500, 898/1,000; fill = progress/next; overlay on the 0..next scale %s" % str(bad))
	_complete("p09_home_ratio")

func _p10_gift_bar_rows() -> void:
	print("[p10 Gift Bar popup: clean rows for every queued and legacy occurrence]")
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 1920)
	sub.disable_3d = true
	get_root().add_child(sub)
	var stack = ModalStack.new()
	sub.add_child(stack)
	var app = AppState.new(_uniq("p10"))
	_ok(app.economy.gift.import_snapshot(_old_snapshot(999, 1, [["gift_ms:c0:m1000", 0, 1000, false], ["gift_ms:c0:m50", 0, 50, false]])), "fixture: c0 m1000 + legacy m50 + c1 backfill 1..500")
	var p = DailyScreens.open_gift_bar(stack, app)
	await process_frame
	var rows: Array = p.find_child("Gifts", true, false).find_children("Text", "Label", true, false).map(func(l): return l.text)
	var dirty: Array = rows.filter(func(t): return t.contains("REWARD_") or t.contains("_"))
	_ok(rows.size() == 9 and dirty.is_empty(), "9 rows, none with REWARD_ or _ %s" % str(dirty))
	var r1000: Array = rows.filter(func(t): return t.begins_with("GIFT 1,000 "))
	_ok(r1000.size() == 1 and r1000[0].contains("SB if no new card x500") and r1000[0].contains("New Card x1"), "1000 row shows the fallback as clean text %s" % str(r1000))
	_ok(rows.has("GIFT 50 · Bot Parts x1, Mystery Booster x1"), "legacy 50 row = legacy bundle")
	var prog: String = (p.find_child("Progress", true, false) as Label).text
	_ok(prog == "Gift Meter 999/1,000", "header = progress / next milestone (%s)" % prog)
	sub.free()
	_complete("p10_gift_bar_rows")

func _p11_reward_text_all_bundles() -> void:
	print("[p11 reward_text over every config bundle; every key has a REWARD_ label]")
	var bundles: Array = []
	for t in [_cfg["gift_meter"]["milestones"], _cfg["gift_meter"]["legacy_milestones"], _cfg["daily"]["login_rewards"]]:
		bundles.append_array(t.values())
	var rd = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/rewarded_daily_v1.json"))
	for s in rd.get("slots", []):
		bundles.append(s["reward"])
	bundles.append(_cfg["collection"]["set_complete"])
	var bad: Array = []
	var missing: Array = []
	for b in bundles:
		var txt := UiText.reward_text(b)
		if txt.is_empty() or txt.contains("REWARD_") or txt.contains("_"):
			bad.append(txt)
		for k in b:
			if not UiText.EN.has("REWARD_" + String(k)):
				missing.append(k)
	_ok(bundles.size() >= 19 and bad.is_empty(), "%d bundles render clean %s" % [bundles.size(), str(bad)])
	_ok(missing.is_empty(), "every config reward key has a UiText REWARD_<key> label %s" % str(missing))
	_complete("p11_reward_text_all_bundles")

func _p12_unknown_key() -> void:
	print("[p12 unknown key degrades to a title-cased label]")
	var t := UiText.reward_text({"foo_bar": 2})
	_ok(t == "Foo Bar x2" and not t.contains("_") and not t.contains("REWARD_"), "foo_bar -> %s" % t)
	_complete("p12_unknown_key")

# ------------------------------------------------------------------ helpers ----

## [SB, Bot Parts, standard packs, premium packs, mystery charges, choice pending, owned cards].
func _state(e) -> Array:
	var owned := 0
	for cid in e.collection.all_card_ids():
		owned += e.collection.owned(cid)
	return [e.wallet.scrub_bucks(), e.wallet.bot_parts(), e.pending_packs.count_of("standard"), e.pending_packs.count_of("premium"),
		BOOSTERS.reduce(func(s, b): return s + e.boosters.charges(b), 0), e.boosters.pending_selected(), owned]

func _delta(a: Array, b: Array) -> Array:
	var out: Array = []
	for i in range(a.size()):
		out.append(b[i] - a[i])
	return out

func _old_snapshot(cp: int, cc: int, q: Array) -> Dictionary:
	return {"cycle_progress": cp, "total_progress": cc * 1000 + cp, "cycles_completed": cc, "applied": ["old_tx"],
		"gift_bar_queue": q.map(func(o): return {"id": o[0], "cycle": o[1], "milestone": o[2], "claimed": o[3]})}

func _num(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[String(k)] = int(d[k])
	return out

func _load(data: Dictionary, tag: String):
	var path := "user://sb_polish_002_%s_%d.json" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	return EconomyConfig.new(path)

func _uniq(tag: String) -> String:
	var p := "user://sb_polish_002_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("SB-POLISH-002 gift meter evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
