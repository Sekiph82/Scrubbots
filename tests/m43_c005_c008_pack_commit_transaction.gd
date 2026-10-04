extends SceneTree
## M43-C005-C008 (SB-M43-066) — atomic pack commit / presentation transaction.
## Real AppState (canonical SaveService + EconomyServices), real CardPackService,
## CollectionInventory and RewardGrantService; the real Standard / Premium ceremonies for
## reopen checks. Service draw order is predicted independently from a copy of the pack RNG.
## Test-only seams: setting the pack RNG state (deterministic draws), the
## PackCommitTransaction fault callable, SaveService.set_fault_injector.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c008_pack_commit_transaction.gd

const AppState = preload("res://scripts/app/app_state.gd")
const PackCommitTransaction = preload("res://scripts/collection/pack_commit_transaction.gd")
const PackReceiptLedger = preload("res://scripts/collection/pack_receipt_ledger.gd")
const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")
const StandardPackModel = preload("res://scripts/ui/ceremony/standard_pack_model.gd")
const PremiumPackModel = preload("res://scripts/ui/ceremony/premium_pack_model.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")

const RARE_PLUS := ["RARE", "EPIC", "LEGENDARY"]

var EXPECTED_CASES := [
	"t01_standard_commit", "t02_premium_commit", "t03_canonical_truth", "t04_new_dup_counts",
	"t05_repeat_sequential", "t06_invalid_tx", "t07_kind_collision", "t08_replay_10x",
	"t09_validators_accept", "t10_no_presentation_before_save", "t11_fault_after_draw",
	"t12_fault_after_ledger", "t13_fault_save", "t14_real_save_failure", "t15_reload",
	"t16_reopen_standard", "t17_reopen_premium", "t18_set_master_once", "t19_set_master_rollback",
	"t20_old_save_loads", "t21_malformed_import", "t22_partial_import", "t23_reentrancy",
	"t24_two_tx_sequential", "t25_bridge_static", "t26_sensitivity",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack

func _initialize() -> void:
	await process_frame
	_mount()
	_t01_standard_commit()
	_t02_premium_commit()
	_t03_canonical_truth()
	_t04_new_dup_counts()
	_t05_repeat_sequential()
	_t06_invalid_tx()
	_t07_kind_collision()
	_t08_replay_10x()
	_t09_validators_accept()
	_t10_no_presentation_before_save()
	_t11_fault_after_draw()
	_t12_fault_after_ledger()
	_t13_fault_save()
	_t14_real_save_failure()
	_t15_reload()
	await _t16_reopen("standard")
	await _t16_reopen("premium")
	_t18_set_master_once()
	_t19_set_master_rollback()
	_t20_old_save_loads()
	_t21_malformed_import()
	_t22_partial_import()
	_t23_reentrancy()
	_t24_two_tx_sequential()
	_t25_bridge_static()
	_t26_sensitivity()
	_unmount()
	await _frames(3)
	_cleanup()
	_done()

# ------------------------------------------------------------- commits ----

func _t01_standard_commit() -> void:
	print("[t01 Standard commit]")
	var app = _app("t01", 101)
	var want := _predict(app, "standard")
	var c0 := _counts(app)
	var r: Dictionary = app.commit_pack("standard", "tx_std_1")
	var ids: Array = r.get("receipt", {}).get("cards", []).map(func(c): return c["card_id"])
	_ok(r["ok"] and not r["replay"] and ids.size() == 3, "ok, new, exactly 3 rows")
	_ok(ids == want, "rows in actual CardPackService draw order %s" % str(ids))
	_ok(_delta(c0, _counts(app)) == 3, "Collection gained exactly 3 copies (applied once)")
	_complete("t01_standard_commit")

func _t02_premium_commit() -> void:
	print("[t02 Premium commit]")
	var app = _app("t02", 202)
	var want := _predict(app, "premium")
	var r: Dictionary = app.commit_pack("premium", "tx_prem_1")
	var cards: Array = r["receipt"]["cards"]
	_ok(r["ok"] and cards.size() == 5 and cards[0]["rarity"] in RARE_PLUS, "exactly 5 rows, card 0 %s" % cards[0]["rarity"])
	_ok(cards.map(func(c): return c["card_id"]) == want, "rows in service order (guaranteed draw first) %s" % str(want))
	_complete("t02_premium_commit")

func _t03_canonical_truth() -> void:
	print("[t03 canonical art / name / rarity + schema]")
	var app = _app("t03", 303)
	var r: Dictionary = app.commit_pack("premium", "tx_canon")
	var rc: Dictionary = r["receipt"]
	var ok := true
	for c in rc["cards"]:
		var e := CollectionCardCatalog.entry(c["card_id"])
		ok = ok and c["art"] == e["art"] and c["name"] == e["name"] and c["rarity"] == e["rarity"] and c["rarity"] == app.economy.collection.card_rarity(c["card_id"])
	_ok(ok, "every row: catalog art / name / rarity")
	_ok(rc["schema"] == PackReceiptLedger.SCHEMA and rc["tx_id"] == "tx_canon" and rc["presentation_id"] == "tx_canon" and rc["kind"] == "premium" and rc["status"] == "committed", "schema / tx / presentation id / kind / committed status present")
	_complete("t03_canonical_truth")

func _t04_new_dup_counts() -> void:
	print("[t04 NEW / DUPLICATE + copies_after from real before/after]")
	var app = _app("t04", 404)
	var first: Dictionary = app.commit_pack("standard", "tx_a")
	var dup_id: String = first["receipt"]["cards"][0]["card_id"]
	_force_pack(app, "standard", func(d): return d[0] == dup_id)   # next pack re-draws an owned card first
	var before := _counts(app)
	var r: Dictionary = app.commit_pack("standard", "tx_b")
	_ok(_rows_match_truth(app, before, r["receipt"]) and r["receipt"]["cards"][0]["card_id"] == dup_id and not r["receipt"]["cards"][0]["is_new"], "copies_after / NEW follow the real pre-commit counts; re-drawn owned card is DUPLICATE")
	_complete("t04_new_dup_counts")

func _t05_repeat_sequential() -> void:
	print("[t05 repeated card inside one pack]")
	var app = _app("t05", 505)
	_force_pack(app, "standard", func(d): return d[0] == d[1] and d[2] != d[0])
	var target: String = _predict(app, "standard")[0]
	var r: Dictionary = app.commit_pack("standard", "tx_rep")
	var rows: Array = r["receipt"]["cards"].slice(0, 2).map(func(c): return [c["card_id"], c["is_new"], c["copies_after"]])
	_ok(rows == [[target, true, 1], [target, false, 2]], "unowned card drawn twice in one pack: NEW 1, DUP 2 %s" % str(rows))
	_force_pack(app, "standard", func(d): return d[0] == target)
	var r2: Dictionary = app.commit_pack("standard", "tx_rep2")
	var row2: Array = [r2["receipt"]["cards"][0]["is_new"], r2["receipt"]["cards"][0]["copies_after"]]
	_ok(row2 == [false, 3] and app.economy.collection.owned(target) == r2["receipt"]["cards"].filter(func(c): return c["card_id"] == target).back()["copies_after"], "next pack re-draws it: DUP 3, live count == last copies_after")
	_complete("t05_repeat_sequential")

func _t06_invalid_tx() -> void:
	print("[t06 invalid tx id]")
	var app = _app("t06", 606)
	var a0 := _auth(app)
	var reasons: Array = []
	for tx in ["", " tx", "tx ", 42, null]:
		reasons.append(PackCommitTransaction.commit(app.economy, "standard", tx, Callable(app, "request_save"))["reason"])
	reasons.append(app.commit_pack("deluxe", "tx_ok")["reason"])
	_ok(reasons == ["tx_id", "tx_id", "tx_id", "tx_id", "tx_id", "kind"], "rejected %s" % str(reasons))
	_ok(_auth(app) == a0, "zero mutation: economy, Collection, RNG, ledger, save bytes")
	_complete("t06_invalid_tx")

func _t07_kind_collision() -> void:
	print("[t07 kind collision]")
	var app = _app("t07", 707)
	app.commit_pack("standard", "tx_k")
	var a0 := _auth(app)
	var r: Dictionary = app.commit_pack("premium", "tx_k")
	_ok(not r["ok"] and r["reason"] == "kind_collision" and _auth(app) == a0, "standard tx reused as premium: rejected, zero mutation %s" % str(_diff(a0, _auth(app))))
	app.commit_pack("premium", "tx_k2")
	var r2: Dictionary = app.commit_pack("standard", "tx_k2")
	_ok(not r2["ok"] and r2["reason"] == "kind_collision", "premium tx reused as standard: rejected")
	_complete("t07_kind_collision")

func _t08_replay_10x() -> void:
	print("[t08 same tx x10]")
	var app = _app("t08", 808)
	var first: Dictionary = app.commit_pack("premium", "tx_r")
	var a0 := _auth(app)
	var saves := [0]
	var counting := func():
		saves[0] += 1
		return app.request_save()
	var same := true
	for _i in range(10):
		var r := PackCommitTransaction.commit(app.economy, "premium", "tx_r", counting)
		same = same and r["ok"] and r["replay"] and r["receipt"] == first["receipt"] and r["model"] == first["model"]
	_ok(same, "10 replays: identical receipt + model")
	_ok(_auth(app) == a0 and saves[0] == 0, "no draw, no apply, no RNG advance, no save (%d saves)" % saves[0])
	_complete("t08_replay_10x")

func _t09_validators_accept() -> void:
	print("[t09 receipt models pass the shipping validators]")
	var app = _app("t09", 909)
	var s: Dictionary = app.commit_pack("standard", "tx_vs")
	var p: Dictionary = app.commit_pack("premium", "tx_vp")
	_ok(StandardPackModel.validate(s["model"])["ok"] and PremiumPackModel.validate(p["model"])["ok"], "StandardPackModel / PremiumPackModel accept the receipt models")
	var cs := StandardPackCeremony.create(s["model"])
	var cp := PremiumPackCeremony.create_premium(p["model"])
	_ok(cs["ok"] and cp["ok"], "ceremonies accept them")
	cs["popup"].free()
	cp["popup"].free()
	_ok(app.pack_presentation_model("tx_vs") == s["model"] and app.pack_receipt("tx_vp") == p["receipt"], "read API returns the same committed truth")
	_complete("t09_validators_accept")

func _t10_no_presentation_before_save() -> void:
	print("[t10 nothing released before the durable save]")
	var app = _app("t10", 1010)
	var seen := {}
	var probe := func():
		seen["model"] = app.pack_presentation_model("tx_ps")
		seen["receipt"] = app.pack_receipt("tx_ps")
		seen["nested"] = app.commit_pack("standard", "tx_ps")
		return app.request_save()
	var r := PackCommitTransaction.commit(app.economy, "standard", "tx_ps", probe)
	_ok(seen["model"].is_empty() and seen["receipt"].is_empty() and seen["nested"]["reason"] == "in_flight", "inside the save: no model, no receipt, nested commit refused")
	_ok(r["ok"] and not r["model"].is_empty(), "model released after the save succeeded")
	var bad := PackCommitTransaction.commit(app.economy, "standard", "tx_ps2", func(): return {"ok": false})
	_ok(not bad["ok"] and not bad.has("model") and not bad.has("receipt") and app.pack_presentation_model("tx_ps2").is_empty(), "failed save: no model anywhere")
	_complete("t10_no_presentation_before_save")

# ------------------------------------------------------------- rollback ----

func _rollback_case(stage: String, case_id: String) -> void:
	var app = _app(case_id, 1100 + stage.length())
	var a0 := _auth(app)
	var r := PackCommitTransaction.commit(app.economy, "premium", "tx_f", Callable(app, "request_save"), func(s): return s == stage)
	_ok(not r["ok"] and r["stage"] == stage and r["restored"] and not r.has("model"), "%s: rolled back, no model" % stage)
	_ok(_auth(app) == a0, "%s: economy, Collection, wallet, applied ids, RNG, ledger, save bytes == pre" % stage)
	var again: Dictionary = app.commit_pack("premium", "tx_f")
	_ok(again["ok"] and not again["replay"], "%s: same tx retried as a fresh commit" % stage)
	_complete(case_id)

func _t11_fault_after_draw() -> void:
	print("[t11 fault after draw]")
	_rollback_case("after_draw", "t11_fault_after_draw")

func _t12_fault_after_ledger() -> void:
	print("[t12 fault after ledger]")
	_rollback_case("after_ledger", "t12_fault_after_ledger")

func _t13_fault_save() -> void:
	print("[t13 fault at save]")
	_rollback_case("save", "t13_fault_save")

func _t14_real_save_failure() -> void:
	print("[t14 real SaveService failure]")
	for stage in ["temp_write", "temp_validate", "backup_rotate", "primary_replace"]:
		var app = _app("t14" + stage, 1414)
		var a0 := _auth(app)
		var pre_counts := _counts(app)
		app.save.set_fault_injector(func(s): return s == stage)
		var r: Dictionary = app.commit_pack("standard", "tx_sf")
		app.save.set_fault_injector(Callable())
		var a1 := _auth(app)
		a1["save"] = a0["save"]   # primary_replace rotates the old primary to backup on disk (M40 design)
		_ok(not r["ok"] and r["stage"] == "save" and r["restored"] and a1 == a0 and not r.has("model"), "%s: in-memory economy, Collection, wallet, ids, RNG, ledger == pre %s" % [stage, str(_diff(a0, a1))])
		var reload = AppState.new(_path_of(app))
		_ok(reload.pack_receipt("tx_sf").is_empty() and _counts(reload) == pre_counts and reload.economy.packs._rng.state == a0["rng"], "%s: reload (%s) has no receipt, pre cards, pre RNG" % [stage, reload.load_result["source"]])
	_complete("t14_real_save_failure")

# ------------------------------------------------------------- durability ----

func _t15_reload() -> void:
	print("[t15 reload]")
	var app = _app("t15", 1515)
	var r: Dictionary = app.commit_pack("premium", "tx_dur")
	var rng_after: int = app.economy.packs._rng.state
	var counts := _counts(app)
	var reload = AppState.new(_path_of(app))
	var rr: Dictionary = reload.pack_receipt("tx_dur")
	_ok(reload.load_result["source"] == "primary" and rr == r["receipt"] and reload.pack_presentation_model("tx_dur") == r["model"], "receipt + model identical after reload")
	_ok(JSON.stringify(rr) == JSON.stringify(r["receipt"]), "byte-identical receipt serialization")
	_ok(_counts(reload) == counts and reload.economy.packs._rng.state == rng_after, "Collection counts + RNG continuation persisted")
	var a0 := _auth(reload)
	var again: Dictionary = reload.commit_pack("premium", "tx_dur")
	_ok(again["replay"] and again["receipt"] == r["receipt"] and _auth(reload) == a0, "same tx after reload: replay, no duplicate cards")
	_complete("t15_reload")

func _t16_reopen(kind: String) -> void:
	print("[t16/17 reopen %s ceremony]" % kind)
	var first = _app("t16" + kind, 1616 + kind.length())
	var tx := "tx_open_" + kind
	var c0 := _counts(first)
	var committed: Dictionary = first.commit_pack(kind, tx)
	var path := _path_of(first)
	first = null   # crash window A: committed, never presented, graph destroyed
	var app = AppState.new(path)
	_ok(app.pack_presentation_model(tx) == committed["model"] and _delta(c0, _counts(app)) == committed["receipt"]["cards"].size(), "after reload: same model, Collection holds exactly one commit")
	var a0 := _auth(app)
	var replays: Array = []
	for run in range(2):
		var model: Dictionary = app.pack_presentation_model(tx)
		var c := StandardPackCeremony.create(model) if kind == "standard" else PremiumPackCeremony.create_premium(model)
		var p = c["popup"]
		_stack.push(p)
		await _frames(2)
		p.tap()
		replays.append(app.commit_pack(kind, tx)["replay"])   # duplicate callback while open
		await _until(p, "AWAIT_ROUTE")
		p.tap()
		await _until(p, "COMPLETE")
		await _frames(2)
		replays.append(app.commit_pack(kind, tx)["replay"])   # after close
	_ok(replays == [true, true, true, true], "duplicate commits while open / after close all replay")
	_ok(_auth(app) == a0, "two full open/close cycles: Collection, rewards, RNG, ledger, save bytes unchanged")
	_complete("t16_reopen_standard" if kind == "standard" else "t17_reopen_premium")

# ------------------------------------------------------------- set / master ----

## State: every card owned except `missing`; all other sets claimed (14). Drawing `missing`
## completes its set AND all 15 sets (master).
func _near_master(app, missing: String) -> void:
	for cid in app.economy.collection.all_card_ids():
		if cid != missing:
			app.economy.collection.add_card(cid)   # real path: grants the 14 completed set rewards
	_ok(app.economy.collection.completed_set_count() == 14 and not app.economy.reward.already_applied("collection_master"), "seeded near-master Collection (14/15 sets)")
	app.request_save()

func _t18_set_master_once() -> void:
	print("[t18 set + master exactly once]")
	var app = _app("t18", 1818)
	var missing := "s6_c8"
	_near_master(app, missing)
	var w0: Dictionary = app.economy.wallet.snapshot()
	_force_pack(app, "standard", func(d): return d[0] == missing)
	var r: Dictionary = app.commit_pack("standard", "tx_master")
	var applied: Array = app.economy.reward.snapshot()["applied"]
	var set_reward := _set_reward(app, 6)
	var master: Dictionary = app.economy.config.collection_config()["all_sets_complete"]
	var w1: Dictionary = app.economy.wallet.snapshot()
	var gained_sb: int = int(w1.get("scrub_bucks", 0)) - int(w0.get("scrub_bucks", 0))
	_ok(r["ok"] and app.economy.collection.is_set_complete(6) and applied.has("collection_set:6") and applied.has("collection_master"), "pack completed set 6 and the Master Collection")
	_ok(gained_sb == int(set_reward["scrub_bucks"]) + int(master["scrub_bucks"]), "wallet +%d SB = set 6 reward + master reward" % gained_sb)
	var a0 := _auth(app)
	app.commit_pack("standard", "tx_master")
	var reload = AppState.new(_path_of(app))
	var b0 := _auth(reload)
	reload.commit_pack("standard", "tx_master")
	_ok(_auth(app) == a0 and _auth(reload) == b0 and _auth(reload)["econ"]["collection"] == a0["econ"]["collection"], "replay and reload+replay: set/master not re-granted")
	var sb_before: int = reload.economy.wallet.scrub_bucks()
	var other: Dictionary = reload.commit_pack("premium", "tx_after")
	_ok(other["ok"] and reload.economy.wallet.scrub_bucks() == sb_before and reload.economy.reward.snapshot()["applied"].count("collection_master") == 1, "a later pack never re-grants set / master (SB unchanged)")
	_complete("t18_set_master_once")

func _t19_set_master_rollback() -> void:
	print("[t19 set + master rolled back on failure]")
	for stage in ["after_draw", "after_ledger", "save"]:
		var app = _app("t19" + stage, 1919)
		_near_master(app, "s6_c8")
		_force_pack(app, "standard", func(d): return d[0] == "s6_c8")
		var a0 := _auth(app)
		var r := PackCommitTransaction.commit(app.economy, "standard", "tx_m", Callable(app, "request_save"), func(s): return s == stage)
		var applied: Array = app.economy.reward.snapshot()["applied"]
		_ok(not r["ok"] and _auth(app) == a0 and not applied.has("collection_master") and not applied.has("collection_set:6") and not app.economy.collection.is_set_complete(6), "%s: card, set 6 reward, master reward, wallet, ids, RNG all restored" % stage)
	_complete("t19_set_master_rollback")

# ------------------------------------------------------------- save graph ----

func _t20_old_save_loads() -> void:
	print("[t20 pre-C008 save loads]")
	var app = _app("t20", 2020)
	var path := _path_of(app)
	var cand = JSON.parse_string(FileAccess.get_file_as_string(path))
	cand["economy"].erase("packs")
	cand["economy"].erase("pack_receipts")
	_write(path, cand)
	var old = AppState.new(path)
	_ok(old.load_result["source"] == "primary" and old.economy.pack_receipts.size() == 0, "save without packs / pack_receipts sections loads from primary; empty ledger")
	var r: Dictionary = old.commit_pack("standard", "tx_old")
	_ok(r["ok"] and AppState.new(path).pack_receipt("tx_old") == r["receipt"], "and can commit + persist afterwards")
	_complete("t20_old_save_loads")

func _t21_malformed_import() -> void:
	print("[t21 malformed C008 state fails closed]")
	var app = _app("t21", 2121)
	app.commit_pack("standard", "tx_s")
	app.commit_pack("premium", "tx_p")
	var good: Dictionary = app.economy.snapshot()
	var live0 := _auth(app)
	var cases := {
		"ledger_root": func(e): e["pack_receipts"] = [],
		"ledger_version": func(e): e["pack_receipts"]["version"] = 2,
		"empty_tx": func(e): e["pack_receipts"]["receipts"][0]["tx_id"] = "",
		"nonstring_tx": func(e): e["pack_receipts"]["receipts"][0]["tx_id"] = 7,
		"duplicate_tx": func(e): e["pack_receipts"]["receipts"].append(e["pack_receipts"]["receipts"][0].duplicate(true)),
		"unknown_kind": func(e): e["pack_receipts"]["receipts"][0]["kind"] = "mega",
		"wrong_count": func(e): e["pack_receipts"]["receipts"][0]["cards"].pop_back(),
		"premium_as_3": func(e): e["pack_receipts"]["receipts"][1]["cards"].resize(3),
		"unknown_card": func(e): e["pack_receipts"]["receipts"][0]["cards"][0]["card_id"] = "s99_c9",
		"art_mismatch": func(e): e["pack_receipts"]["receipts"][0]["cards"][0]["art"] = "res://x.png",
		"name_mismatch": func(e): e["pack_receipts"]["receipts"][0]["cards"][0]["name"] = "Fake",
		"rarity_mismatch": func(e): e["pack_receipts"]["receipts"][0]["cards"][0]["rarity"] = "MYTHIC",
		"premium_card0_common": func(e): e["pack_receipts"]["receipts"][1]["cards"][0] = _row("s1_c0", true, 1),
		"is_new_type": func(e): e["pack_receipts"]["receipts"][0]["cards"][0]["is_new"] = "yes",
		"copies_invalid": func(e): e["pack_receipts"]["receipts"][0]["cards"][0]["copies_after"] = 1.5,
		"copies_incoherent": func(e): e["pack_receipts"]["receipts"][0]["cards"] = [_row("s7_c1", true, 1), _row("s7_c1", false, 3), _row("s2_c0", true, 1)],
		"presentation_mismatch": func(e): e["pack_receipts"]["receipts"][0]["presentation_id"] = "other",
		"status_missing": func(e): e["pack_receipts"]["receipts"][0].erase("status"),
		"schema_wrong": func(e): e["pack_receipts"]["receipts"][0]["schema"] = "v0",
		"cards_missing": func(e): e["pack_receipts"]["receipts"][0].erase("cards"),
		"rng_type": func(e): e["packs"]["rng"]["hi"] = "12",
		"rng_range": func(e): e["packs"]["rng"]["lo"] = 4294967296,
		"rng_fraction": func(e): e["packs"]["rng"]["hi"] = 1.5,
		"rng_shape": func(e): e["packs"]["rng"]["extra"] = 1,
		"packs_root": func(e): e["packs"] = 5,
	}
	var rejected: Array = []
	var leaked: Array = []
	for name in cases:
		var bad: Dictionary = good.duplicate(true)
		cases[name].call(bad)
		if not app.economy.import_snapshot(bad):
			rejected.append(name)
		if _auth(app) != live0:
			leaked.append(name)
			app.economy.import_snapshot(good)
	_ok(rejected.size() == cases.size(), "all %d corruptions rejected (missing: %s)" % [cases.size(), str(cases.keys().filter(func(k): return not rejected.has(k)))])
	_ok(leaked.is_empty(), "every rejected import left the live state unchanged %s" % str(leaked))
	var cand = JSON.parse_string(FileAccess.get_file_as_string(_path_of(app)))
	cand["economy"]["pack_receipts"]["receipts"][0]["cards"][0]["copies_after"] = 99
	_ok(not app.save.validate_candidate(cand)["ok"], "SaveService rejects a save candidate with a corrupt receipt")
	_complete("t21_malformed_import")

func _t22_partial_import() -> void:
	print("[t22 import is all-or-nothing]")
	var app = _app("t22", 2222)
	app.commit_pack("standard", "tx_1")
	var snap: Dictionary = app.economy.snapshot()
	var other = _app("t22b", 2223)
	other.commit_pack("premium", "tx_x")
	var live0 := _auth(other)
	var bad: Dictionary = snap.duplicate(true)
	bad["pack_receipts"]["receipts"].append(snap["pack_receipts"]["receipts"][0].duplicate(true))
	bad["pack_receipts"]["receipts"][1]["tx_id"] = "tx_2"
	bad["pack_receipts"]["receipts"][1]["presentation_id"] = "tx_2"
	bad["pack_receipts"]["receipts"][1]["cards"][0]["copies_after"] = 7   # second receipt corrupt
	_ok(not other.economy.import_snapshot(bad) and _auth(other) == live0 and other.pack_receipt("tx_1").is_empty() and not other.pack_receipt("tx_x").is_empty(), "first valid receipt NOT imported when a later one is corrupt; prior live ledger kept")
	var led_before: Dictionary = other.economy.pack_receipts.snapshot()
	_ok(not other.economy.pack_receipts.import_snapshot(bad["pack_receipts"]) and other.economy.pack_receipts.snapshot() == led_before, "PackReceiptLedger.import_snapshot alone is all-or-nothing (no economy backup involved)")
	_complete("t22_partial_import")

func _t23_reentrancy() -> void:
	print("[t23 reentrancy]")
	var app = _app("t23", 2323)
	var c0 := _counts(app)
	var nested: Array = []
	var reenter := func():
		nested.append(PackCommitTransaction.commit(app.economy, "standard", "tx_re", Callable(app, "request_save"))["reason"])
		nested.append(app.commit_pack("standard", "tx_re")["reason"])
		nested.append(app.commit_pack("premium", "tx_other")["reason"])
		return app.request_save()
	var r := PackCommitTransaction.commit(app.economy, "standard", "tx_re", reenter)
	_ok(r["ok"] and nested == ["in_flight", "in_flight", "in_flight"] and _delta(c0, _counts(app)) == 3, "re-entrant same / other tx refused during commit; drew once")
	var later: Dictionary = app.commit_pack("premium", "tx_other")
	_ok(later["ok"] and not later["replay"], "the other tx commits normally afterwards")
	_complete("t23_reentrancy")

func _t24_two_tx_sequential() -> void:
	print("[t24 two tx ids]")
	var app = _app("t24", 2424)
	var c0 := _counts(app)
	var a: Dictionary = app.commit_pack("standard", "tx_A")
	var b: Dictionary = app.commit_pack("premium", "tx_B")
	_ok(a["ok"] and b["ok"] and _delta(c0, _counts(app)) == 8 and app.economy.pack_receipts.size() == 2 and a["receipt"] != b["receipt"], "independent receipts; 3 + 5 copies")
	_complete("t24_two_tx_sequential")

func _t25_bridge_static() -> void:
	print("[t25 no presentation path calls raw open]")
	var raw := RegEx.create_from_string("open_standard|open_premium|grant_guaranteed_new|packs\\.")
	var clean := true
	for path in ["res://scripts/collection/pack_receipt_ledger.gd", "res://scripts/ui/ceremony/standard_pack_ceremony.gd", "res://scripts/ui/ceremony/premium_pack_ceremony.gd", "res://scripts/ui/ceremony/standard_pack_model.gd", "res://scripts/ui/ceremony/premium_pack_model.gd"]:
		clean = clean and raw.search(_code_only(FileAccess.get_file_as_string(path))) == null
	var tx_src := _code_only(FileAccess.get_file_as_string("res://scripts/collection/pack_commit_transaction.gd"))
	_ok(clean, "ledger bridge, ceremonies and models never call the pack service")
	_ok(tx_src.count("open_standard()") == 1 and tx_src.count("open_premium()") == 1, "the coordinator is the single presented-pack draw site")
	_ok(raw.search("\tpacks.open_standard()\n") != null, "sensitivity: an injected raw open is flagged")
	var x = AppState.new("user://m43c005c008_seed_a.save")
	var y = AppState.new("user://m43c005c008_seed_b.save")
	_tmp.append_array(["user://m43c005c008_seed_a.save", "user://m43c005c008_seed_b.save"])
	var seeded := RegEx.create_from_string("\\bseed\\b")
	var prod_clean := true
	for path in ["res://scripts/app/app_state.gd", "res://scripts/collection/pack_commit_transaction.gd", "res://scripts/collection/pack_receipt_ledger.gd", "res://scripts/economy/economy_services.gd"]:
		prod_clean = prod_clean and seeded.search(_code_only(FileAccess.get_file_as_string(path))) == null
	_ok(prod_clean and x.economy.packs._rng.state != y.economy.packs._rng.state, "production graphs are OS-seeded (no fixed seed in source; two fresh graphs differ)")
	_complete("t25_bridge_static")

func _t26_sensitivity() -> void:
	print("[t26 comparator sensitivity]")
	var app = _app("t26", 2626)
	app.commit_pack("standard", "tx_z")
	var a0 := _auth(app)
	app.economy.packs.open_standard()   # a duplicate application
	_ok(_auth(app) != a0, "duplicate application of a pack is detected")
	var b = _app("t26b", 2627)
	var b0 := _auth(b)
	b.economy.packs._rng.randi()   # RNG advanced, nothing else
	_ok(_auth(b) != b0, "an RNG change alone is detected")
	_force_pack(b, "premium", func(d): return d.slice(1).all(func(x): return d.count(x) == 1))
	var want := _predict(b, "premium")
	var before := _counts(b)
	var r: Dictionary = b.commit_pack("premium", "tx_order")
	var swapped: Array = r["receipt"]["cards"].map(func(c): return c["card_id"])
	var tail: Array = swapped.slice(1)
	tail.reverse()
	_ok(swapped == want and [swapped[0]] + tail != want, "the service-order check (t01/t02) fails for reordered rows")
	var stale: Dictionary = r["receipt"].duplicate(true)
	stale["cards"][1]["copies_after"] = int(stale["cards"][1]["copies_after"]) + 1
	stale["cards"][1]["is_new"] = false
	_ok(_rows_match_truth(b, before, r["receipt"]) and not _rows_match_truth(b, before, stale), "the copies_after oracle (t04) flags a fabricated / stale count")
	var common0: Dictionary = r["receipt"].duplicate(true)
	common0["cards"][0] = _row("s1_c0", true, 1)
	_ok(PackReceiptLedger.validate_receipt(common0)["reason"] == "cards:card_0_not_rare_or_better", "Premium card 0 COMMON is rejected")
	_complete("t26_sensitivity")

# ------------------------------------------------------------- helpers ----

## Fresh AppState on its own save file with a deterministic pack RNG (test seam).
func _app(tag: String, seed: int):
	var path := "user://m43c005c008_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var app = AppState.new(path)
	app.economy.packs._rng.seed = seed
	app.request_save()
	return app

func _path_of(app) -> String:
	return String(app.save._path)

## Everything a pack commit could touch, plus the save bytes.
func _auth(app) -> Dictionary:
	var s: Dictionary = app.economy.snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	return {"econ": s, "rng": app.economy.packs._rng.state, "save": FileAccess.get_file_as_bytes(_path_of(app))}

## Diagnostic: names the differing authority sections (printed on failure only).
func _diff(a: Dictionary, b: Dictionary) -> Array:
	var out: Array = []
	for k in a["econ"]:
		if a["econ"][k] != b["econ"].get(k):
			out.append(k)
	if a["rng"] != b["rng"]:
		out.append("rng")
	if a["save"] != b["save"]:
		out.append("save_bytes")
	return out

func _counts(app) -> Dictionary:
	return app.economy.collection.snapshot()["owned"]

func _delta(a: Dictionary, b: Dictionary) -> int:
	var n := 0
	for k in b:
		n += int(b[k]) - int(a.get(k, 0))
	return n

## Independent prediction of CardPackService draw order from a copy of the pack RNG.
func _predict(app, kind: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.state = app.economy.packs._rng.state
	var ids: Array = app.economy.packs._card_ids
	var out: Array = []
	if kind == "premium":
		var rare: Array = app.economy.packs._rare_or_better
		out.append(rare[rng.randi_range(0, rare.size() - 1)])
	for _i in range(3 if kind == "standard" else 4):
		out.append(ids[rng.randi_range(0, ids.size() - 1)])
	return out

## Test seam: search RNG seeds until the next `kind` pack's predicted draws satisfy `pred`.
func _force_pack(app, kind: String, pred: Callable) -> void:
	var rng := RandomNumberGenerator.new()
	for s in range(1, 200000):
		rng.seed = s
		app.economy.packs._rng.state = rng.state
		if pred.call(_predict(app, kind)):
			return
	_ok(false, "could not force a %s pack" % kind)

## Independent NEW / copies_after oracle: walk rows from the pre-commit counts and require the
## live post-commit count to equal the last row of each card.
func _rows_match_truth(app, before: Dictionary, receipt: Dictionary) -> bool:
	var running := {}
	for c in receipt["cards"]:
		var n := int(running.get(c["card_id"], before.get(c["card_id"], 0))) + 1
		running[c["card_id"]] = n
		if c["copies_after"] != n or c["is_new"] != (n == 1):
			return false
	for cid in running:
		if app.economy.collection.owned(cid) != running[cid]:
			return false
	return true

func _row(cid: String, is_new: bool, copies: int) -> Dictionary:
	var e := CollectionCardCatalog.entry(cid)
	return {"card_id": cid, "art": e["art"], "name": e["name"], "rarity": e["rarity"], "is_new": is_new, "copies_after": copies}

func _set_reward(app, set_no: int) -> Dictionary:
	for e in app.economy.config.collection_config()["set_rewards"]:
		if int(e["set"]) == set_no:
			return e
	return {}

func _write(path: String, data) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()

func _until(p, phase_name: String) -> void:
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		if not is_instance_valid(p) or p.phase() == phase_name:
			return
		await process_frame
	_ok(false, "timed out waiting for %s" % phase_name)

func _code_only(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var i := line.find("#")
		out.append(line if i == -1 else line.substr(0, i))
	return "\n".join(out)

func _mount() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 1920)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_stack = ModalStack.new()
	_sub.add_child(_stack)

func _unmount() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.free()

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

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
	print("M43-C005-C008 pack commit transaction evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
