extends SceneTree
## M39-C003 (SB-M39-054) — random-any-booster reward semantics
## (coordination/OWNER_RANDOM_ANY_BOOSTER_REWARD_CORRECTION_V01.md).
## A "random booster" META reward = one charge of ONE booster picked uniformly from all four
## canonical boosters, stable per (reward tx, ordinal); the gameplay booster RANDOM is unchanged.
## Run: godot --headless --path . -s res://tests/m39_c003_random_any_booster_rewards.gd

const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const Picker = preload("res://scripts/economy/random_booster_reward_picker.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const RANDOM_ICON := "res://assets/ui/final/boosters/random.png"
const GIFT_ICON := "res://assets/ui/final/rewards/gift_box.png"
const CHOICE_ICON := "res://assets/ui/final/rewards/booster_of_choice.png"

var _fail := 0
var _t := [1_000_000]

func _clock() -> int:
	return _t[0]

func _mk() -> EconomyServices:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	return EconomyServices.new(EconomyConfig.DEFAULT_PATH, Callable(self, "_clock"), rng)

func _counts(e) -> Dictionary:
	var d := {}
	for b in BoosterInventory.BOOSTERS:
		d[b] = e.boosters.charges(b)
	return d

func _total(e) -> int:
	return _counts(e).values().reduce(func(s, v): return s + v, 0)

## Ids whose counter changed between two _counts() snapshots -> {id: delta}.
func _delta(a: Dictionary, b: Dictionary) -> Dictionary:
	var d := {}
	for k in b:
		if b[k] != a[k]:
			d[k] = b[k] - a[k]
	return d

func _initialize() -> void:
	_a_pool()
	_b_algorithm()
	_c_replay()
	_d_idempotency()
	_d2_n_charges()
	_e_gift_50()
	_f_daily_d3()
	_g_all_tasks()
	_h_selected_protected()
	_i_named_random_intact()
	_j_presentation()
	_k_config_and_save()
	_done()

# A — every canonical booster reachable, nothing else ever selected.
func _a_pool() -> void:
	print("[A pool: exactly BoosterInventory.BOOSTERS, all four reachable]")
	_ok(BoosterInventory.BOOSTERS == ["plus_one_slot", "random", "selector", "tornado"], "pool is the four canonical boosters, no fifth")
	var seen := {}
	var unknown := 0
	for i in range(400):
		var id := Picker.pick("gift_ms:c%d:m50" % i, 0)
		seen[id] = int(seen.get(id, 0)) + 1
		if not BoosterInventory.BOOSTERS.has(id):
			unknown += 1
	_ok(unknown == 0, "no unknown booster id over 400 tx ids")
	_ok(seen.size() == 4, "all four reachable: %s" % str(seen))
	print("  evidence: distribution over 400 gift_ms:c<i>:m50 tx ids = %s" % str(seen))

# B — SHA-256-derived u32 modulo exact pool size 4.
func _b_algorithm() -> void:
	print("[B algorithm: SHA-256 u32 mod 4, independent of fixture order]")
	var tx := "daily_login:20000"
	var h := ("%s|random_any_booster|%d" % [tx, 0]).sha256_buffer()
	var u := (h[0] << 24) | (h[1] << 16) | (h[2] << 8) | h[3]
	_ok(Picker.index(tx, 0) == u % 4, "index == u32(sha256(key)[0..3]) %% 4")
	_ok(u >= 0 and u < 4294967296 and 4294967296 % 4 == 0, "u32 domain is a multiple of 4 -> each index exactly equally likely")
	var idx := {}
	for i in range(64):
		idx[Picker.index("t%d" % i, 0)] = true
	var keys := idx.keys()
	keys.sort()
	_ok(keys == [0, 1, 2, 3], "every index 0..3 is produced")
	# Known-answer vector: pins the cross-platform derivation (SHA-256 is platform independent).
	var kat := "%s|random_any_booster|0" % "gift_ms:c0:m50"
	print("  evidence: key '%s' sha256=%s -> %s" % [kat, kat.sha256_text().substr(0, 16), Picker.pick("gift_ms:c0:m50", 0)])
	_ok(kat.sha256_text().substr(0, 8).hex_to_int() % 4 == Picker.index("gift_ms:c0:m50", 0), "independent hex path agrees with the picker")
	# No mutable RNG consumed: the global RNG state is untouched by many picks.
	seed(777)
	var before := randi()
	seed(777)
	for i in range(100):
		Picker.pick("x%d" % i, i)
	_ok(randi() == before, "no global RNG consumed")

# C — same tx + ordinal => same booster, across calls and across a fresh service graph.
func _c_replay() -> void:
	print("[C stable replay]")
	var x := Picker.pick("gift_ms:c3:m50", 0)
	_ok(Picker.pick("gift_ms:c3:m50", 0) == x and Picker.pick("gift_ms:c3:m50", 0) == x, "repeat derivation stable (%s)" % x)
	var a = _mk()
	var c0 := _counts(a)
	a.reward.grant("replay_tx", {Picker.RESOURCE: 1})
	var got_a := _delta(c0, _counts(a))
	var b = _mk()   # "relaunch": new graph, same tx
	var c1 := _counts(b)
	b.reward.grant("replay_tx", {Picker.RESOURCE: 1})
	var got_b := _delta(c1, _counts(b))
	_ok(got_a == got_b and got_a == {Picker.pick("replay_tx", 0): 1}, "fresh EconomyServices with same tx -> same booster %s" % str(got_a))
	a.dispose()
	b.dispose()

# D — +1 exactly, one counter, duplicate is +0 and cannot reroll.
func _d_idempotency() -> void:
	print("[D grant idempotency]")
	var e = _mk()
	var c0 := _counts(e)
	_ok(e.reward.grant("T", {Picker.RESOURCE: 1}), "first grant applies")
	var c1 := _counts(e)
	var d := _delta(c0, c1)
	_ok(_total(e) == 1 and d.size() == 1 and d.values()[0] == 1, "total +1, exactly one counter +1: %s" % str(d))
	_ok(not e.reward.grant("T", {Picker.RESOURCE: 1}) and _counts(e) == c1, "duplicate T grants nothing, no reroll")
	# Legacy alias routes to the SAME random-any behaviour (never RANDOM-only).
	var c2 := _counts(e)
	e.reward.grant("legacy_T2", {Picker.LEGACY_RESOURCE: 1})
	_ok(_delta(c2, _counts(e)) == {Picker.pick("legacy_T2", 0): 1}, "legacy alias = random-any pick")
	var alias_ids := {}
	for i in range(40):
		var ci := _counts(e)
		e.reward.grant("legacy:%d" % i, {Picker.LEGACY_RESOURCE: 1})
		alias_ids[_delta(ci, _counts(e)).keys()[0]] = true
	_ok(alias_ids.size() == 4, "legacy alias reaches all four (never only RANDOM): %s" % str(alias_ids.keys()))
	e.dispose()

func _d2_n_charges() -> void:
	print("[D n>1: one independent pick per ordinal, repeats allowed]")
	var e = _mk()
	var expect := {}
	for b in BoosterInventory.BOOSTERS:
		expect[b] = 0
	for i in range(7):
		expect[Picker.pick("multi", i)] += 1
	e.reward.grant("multi", {Picker.RESOURCE: 7})
	_ok(_total(e) == 7 and _counts(e) == expect, "7 charges = 7 ordinal picks %s" % str(expect))
	e.dispose()

# E — Gift Meter 50: +1 Bot Part, +1 random-any booster, exactly once; varies by cycle.
func _e_gift_50() -> void:
	print("[E Gift Meter 50]")
	var e = _mk()
	var m50: Dictionary = e.config.gift_meter_milestone(50)   # JSON numbers are floats
	_ok(m50.size() == 2 and int(m50.get("bot_parts", 0)) == 1 and int(m50.get(Picker.RESOURCE, 0)) == 1, "config m50 = 1 Bot Part + 1 random-any booster")
	var picks := {}
	for cycle in range(12):
		e.gift.add_streak_sb("feed:%d" % cycle, 1000)
		var occ := "gift_ms:c%d:m50" % cycle
		var bp0: int = e.wallet.bot_parts()
		var c0 := _counts(e)
		var r: Dictionary = e.gift.claim(occ, e.reward, e.config)
		var d := _delta(c0, _counts(e))
		_ok(r["ok"] and e.wallet.bot_parts() == bp0 + 1 and d.size() == 1 and d.values()[0] == 1 and d.has(Picker.pick(occ, 0)),
			"%s: +1 Bot Part, +1 %s" % [occ, str(d.keys())])
		var c1 := _counts(e)
		_ok(not e.gift.claim(occ, e.reward, e.config)["ok"] and _counts(e) == c1 and e.wallet.bot_parts() == bp0 + 1, "%s: second claim refused, nothing re-granted" % occ)
		picks[occ] = d.keys()[0]
		print("  evidence: %s before=%s after=%s selected=%s" % [occ, str(c0), str(c1), d.keys()[0]])
	var distinct := {}
	for v in picks.values():
		distinct[v] = true
	_ok(distinct.size() > 1 and distinct.keys() != ["random"], "Gift 50 is NOT always RANDOM across cycles: %s" % str(distinct.keys()))
	_ok(picks.values().has("random") and picks.values().any(func(v): return v != "random"), "both a RANDOM case and a non-RANDOM case observed")
	e.dispose()

# F — Daily login D3.
func _f_daily_d3() -> void:
	print("[F Daily D3]")
	var e = _mk()
	var d3: Dictionary = e.daily.login_reward_for(3)
	_ok(d3.size() == 1 and int(d3.get(Picker.RESOURCE, 0)) == 1, "config D3 = 1 random-any booster")
	_t[0] = 86400 * 20000 + 3600
	for day in [1, 2]:
		_ok(e.daily.claim_login()["day"] == day, "D%d claimed" % day)
		_t[0] += 86400
	var c0 := _counts(e)
	var r: Dictionary = e.daily.claim_login()
	var d := _delta(c0, _counts(e))
	_ok(r["ok"] and r["day"] == 3 and d.size() == 1 and d.values()[0] == 1 and d.has(Picker.pick(r["tx"], 0)), "D3 (%s): exactly one random-any charge %s" % [r["tx"], str(d)])
	var c1 := _counts(e)
	_ok(not e.daily.claim_login()["ok"] and _counts(e) == c1, "same-day duplicate grants nothing")
	print("  evidence: %s selected=%s" % [r["tx"], d.keys()[0]])
	e.dispose()

# G — all three tasks / ScrubBox.
func _g_all_tasks() -> void:
	print("[G 3/3 tasks ScrubBox]")
	var e = _mk()
	_ok(int(e.config.daily_config().get("all_tasks_random_any_booster_charges", 0)) == 1 and not e.config.daily_config().has("all_tasks_random_booster_charges"), "config uses the unambiguous all-tasks key, amount 1")
	var seen := {}
	for k in range(6):
		_t[0] = 86400 * (20100 + k) + 3600
		for i in range(3):
			e.daily.mark_task_done(i)
		var c0 := _counts(e)
		var r: Dictionary = e.daily.claim_all_tasks_bonus()
		var d := _delta(c0, _counts(e))
		_ok(r["ok"] and int(r.get(Picker.RESOURCE, 0)) == 1 and d.size() == 1 and d.values()[0] == 1 and d.has(Picker.pick(r["tx"], 0)), "%s: exactly one random-any charge %s" % [r["tx"], str(d)])
		var c1 := _counts(e)
		_ok(not e.daily.claim_all_tasks_bonus()["ok"] and _counts(e) == c1, "%s: duplicate grants nothing" % r["tx"])
		seen[r["tx"]] = d.keys()[0]
	print("  evidence: ScrubBox picks %s" % str(seen))
	e.dispose()

# H — Booster of your choice untouched.
func _h_selected_protected() -> void:
	print("[H selected-booster rewards unchanged]")
	var e = _mk()
	_ok(int(e.config.gift_meter_milestone(500).get("selected_booster_charges", 0)) == 1 and int(e.config.gift_meter_milestone(1000).get("selected_booster_charges", 0)) >= 1 and int(e.daily.login_reward_for(5).get("selected_booster_charges", 0)) == 1, "Gift 500/1000 + D5 still selected_booster_charges")
	for m in [500, 1000]:
		_ok(not e.config.gift_meter_milestone(m).has(Picker.RESOURCE), "Gift %d has no random-any reward" % m)
	e.gift.add_streak_sb("feed", 1000)
	var c0 := _counts(e)
	var p0: int = e.boosters.pending_selected()
	_ok(e.gift.claim("gift_ms:c0:m500", e.reward, e.config)["ok"], "Gift 500 claim")
	_ok(e.boosters.pending_selected() == p0 + 1 and _counts(e) == c0, "500 -> pending_selected +1, no charge auto-picked")
	var p1: int = e.boosters.pending_selected()
	_ok(e.gift.claim("gift_ms:c0:m1000", e.reward, e.config)["ok"], "Gift 1000 claim")
	_ok(e.boosters.pending_selected() == p1 + int(e.config.gift_meter_milestone(1000)["selected_booster_charges"]) and _counts(e) == c0, "1000 -> pending_selected, no charge auto-picked")
	var c1 := _counts(e)
	e.reward.grant("sel_only", {"selected_booster_charges": 1})
	_ok(_counts(e) == c1, "selected_booster_charges never runs a random selection")
	e.dispose()

# I — the gameplay booster RANDOM is unchanged.
func _i_named_random_intact() -> void:
	print("[I named RANDOM booster intact]")
	var e = _mk()
	_ok(BoosterInventory.RANDOM == "random" and BoosterInventory.BOOSTERS.has("random"), "RANDOM id unchanged, still in the pool")
	_ok(e.config.booster_price("random") == 350 and int(e.config.booster_config("random").get("min_solver_safe_moves", 0)) == 3, "RANDOM price/config unchanged")
	e.wallet.credit("scrub_bucks", 1000)
	_ok(e.boosters.buy_charge("random").get("ok", false) and e.boosters.charges("random") == 1, "RANDOM still purchasable by id")
	_ok(UiText.t("REWARD_random_any_booster_charges") != "Random" and UiText.t("REWARD_random_any_booster_charges").find("Random") == -1, "reward wording never names the RANDOM booster")
	e.dispose()

# J — presentation.
func _j_presentation() -> void:
	print("[J presentation]")
	_ok(not MetaCeremonies.REWARD_ROWS.has(Picker.LEGACY_RESOURCE) and MetaCeremonies.REWARD_ROWS.has(Picker.RESOURCE), "ceremony rows bind the canonical key")
	var spec: Array = MetaCeremonies.REWARD_ROWS[Picker.RESOURCE]
	_ok(MetaCeremonies.ART[spec[0]] == GIFT_ICON and MetaCeremonies.ART.values().count(RANDOM_ICON) == 0, "generic row icon = neutral gift box, RANDOM icon not bound by ceremonies")
	_ok(UiText.t(spec[1], ["1"]) == "+1 Mystery Booster", "ceremony row text: %s" % UiText.t(spec[1], ["1"]))
	_ok(UiText.reward_text({Picker.RESOURCE: 1}) == "Mystery Booster x1" and UiText.reward_text({Picker.LEGACY_RESOURCE: 1}) == "Mystery Booster x1", "Daily / list wording: Mystery Booster")
	_ok(UiText.reward_text({"selected_booster_charges": 1}) == "Booster of choice x1" and MetaCeremonies.ART[MetaCeremonies.REWARD_ROWS["selected_booster_charges"][0]] == CHOICE_ICON, "Booster-of-choice wording/art unchanged")
	var cfg := EconomyConfig.new()
	var p = MetaCeremonies.gift_milestone({"milestone": 50, "cycle_max": 1000, "rewards": cfg.gift_meter_milestone(50), "key": "gift:gift_ms:c0:m50"}, true)
	var row = p.find_child("Row_" + Picker.RESOURCE, true, false)
	var icon = row.find_child("Icon", true, false) if row != null else null
	var txt = row.find_child("Text", true, false) if row != null else null
	_ok(row != null and icon.texture.resource_path == GIFT_ICON and txt.text == "+1 Mystery Booster", "Gift 50 ceremony row: gift-box icon + '+1 Mystery Booster'")
	print("  evidence: Gift 50 ceremony row icon=%s text='%s'" % [icon.texture.resource_path if icon else "-", txt.text if txt else "-"])
	p.free()
	var ds := FileAccess.get_file_as_string("res://scripts/ui/daily/daily_screens.gd")
	_ok(ds.find("boosters/random.png") == -1 and ds.find("icon.texture = load(ART[\"gift\"])") != -1, "ScrubBox reward icon is the neutral gift art, not the RANDOM booster")

# K — config validation + save shape.
func _k_config_and_save() -> void:
	print("[K config law + backward-safe save shape]")
	var raw: Dictionary = EconomyConfig.new().raw()
	for key in ["random_booster_charges"]:
		var bad := raw.duplicate(true)
		bad["gift_meter"]["milestones"]["50"] = {"bot_parts": 1, key: 1}
		var path := "user://m39_c003_bad_cfg.json"
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(bad))
		f.close()
		var c := EconomyConfig.new(path)
		_ok(not c.is_ok() and c.get_error().find("random_booster_charges") != -1, "canonical config refuses the legacy key (%s)" % c.get_error())
	var bad2 := raw.duplicate(true)
	bad2["daily"]["all_tasks_random_booster_charges"] = 1
	var p2 := "user://m39_c003_bad_cfg2.json"
	var f2 := FileAccess.open(p2, FileAccess.WRITE)
	f2.store_string(JSON.stringify(bad2))
	f2.close()
	_ok(not EconomyConfig.new(p2).is_ok(), "legacy all-tasks key refused")
	_ok(EconomyConfig.new().is_ok(), "shipping config valid")
	# Older save: four counters + pending import unchanged; no new persisted section.
	var e = _mk()
	var old := {"plus_one_slot": 2, "random": 3, "selector": 0, "tornado": 1, "_pending_selected": 1}
	_ok(e.boosters.import_snapshot(old) and e.boosters.snapshot() == old, "old booster snapshot imports byte-identical")
	e.reward.grant("save_tx", {Picker.RESOURCE: 1})
	var snap: Dictionary = e.snapshot()
	var re = _mk()
	_ok(re.import_snapshot(snap) and re.boosters.snapshot() == e.boosters.snapshot(), "granted pick persists via normal BoosterInventory state")
	var c0 := _counts(re)
	_ok(not re.reward.grant("save_tx", {Picker.RESOURCE: 1}) and _counts(re) == c0, "relaunch: same tx cannot re-grant or reroll")
	_ok(not snap.has("random_any") and snap["boosters"].keys().size() == 5, "no selection ledger added to the save")
	e.dispose()
	re.dispose()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39-C003 random-any booster: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
