extends SceneTree
## M43 master — Lane C007R earned-pack pity (SB-M43-R07-001..006).
## Real AppState / CardPackService / CollectionInventory / PackCommitTransaction / SaveService.
## p03..p05 set the threshold through the test seam; p06 / p10 / p11 run the SHIPPED tuning
## (collection.pity: threshold 3, first_sprint_threshold 1; docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md).
##
## Run: godot --headless --path . -s res://tests/m43_master_c007r_pity.gd

const AppState = preload("res://scripts/app/app_state.gd")
const PackPity = preload("res://scripts/collection/pack_pity.gd")
const PackCommitTransaction = preload("res://scripts/collection/pack_commit_transaction.gd")
const RARE_PLUS := ["RARE", "EPIC", "LEGENDARY"]

var EXPECTED_CASES := ["p01_counter_rules", "p02_persist_strict_legacy", "p03_guarantee_missing_card", "p04_premium_card0_kept",
	"p05_no_missing_no_fabrication", "p06_shipped_threshold", "p07_rollback_with_c008", "p08_earned_only_static",
	"p09_rng_and_order_unchanged_when_not_due", "p10_first_sprint_set1", "p11_sprint_legible_ui"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_p01()
	_p02()
	_p03()
	_p04()
	_p05()
	_p06()
	_p07()
	_p08()
	_p09()
	_p10()
	_p11()
	_cleanup()
	_done()

func _app(tag: String, seed := 77):
	var app = AppState.new(_uniq(tag))
	app.economy.packs._rng.seed = seed
	app.request_save()
	return app

## Own every card except `keep_missing` (ids), through the real authority.
func _own_all_but(app, keep_missing: Array) -> void:
	for cid in app.economy.collection.all_card_ids():
		if not keep_missing.has(cid) and app.economy.collection.owned(cid) == 0:
			app.economy.collection.add_card(cid)

func _p01() -> void:
	print("[p01 no NEW card -> +1, any NEW card -> reset]")
	var app = _app("p01")
	var e = app.economy
	_own_set(app, 1)   # past the First Collection Sprint: plain any-set rule
	e.packs.open_standard()
	_ok(e.pack_pity.count() == 0, "first pack after Set 1 has NEW cards -> 0")
	_own_all_but(app, [])
	for _i in range(3):
		e.packs.open_standard()
	_ok(e.pack_pity.count() == 3, "three all-duplicate packs -> 3")
	var p := PackPity.new()
	p.on_opened(false)
	p.on_opened(false)
	p.on_opened(true)
	_ok(p.count() == 0, "a NEW card resets")
	_complete("p01_counter_rules")

func _p02() -> void:
	print("[p02 persisted, strict when present, 0 when absent]")
	var app = _app("p02")
	_own_all_but(app, [])
	app.economy.packs.open_standard()
	app.economy.packs.open_standard()
	app.request_save()
	var re = AppState.new(app.save._path)
	_ok(re.economy.pack_pity.count() == 2, "count survives reload / restart")
	var good: Dictionary = re.economy.snapshot()
	var bad := [{}, {"version": 1}, {"count": 2}, {"version": 2, "count": 2}, {"version": 1, "count": -1}, {"version": 1, "count": 1.5}, {"version": 1, "count": 2, "x": 0}, [], null]
	var rejected := 0
	for b in bad:
		var c: Dictionary = good.duplicate(true)
		c["pack_pity"] = b
		if not re.economy.import_snapshot(c) and re.economy.pack_pity.count() == 2:
			rejected += 1
	var legacy: Dictionary = good.duplicate(true)
	legacy.erase("pack_pity")
	_ok(rejected == bad.size() and re.economy.import_snapshot(legacy) and re.economy.pack_pity.count() == 0, "9 malformed sections rejected (state kept); absent -> 0")
	_complete("p02_persist_strict_legacy")

func _p03() -> void:
	print("[p03 threshold reached -> next earned pack contains a missing card, then reset]")
	var app = _app("p03")
	var e = app.economy
	_own_all_but(app, ["s9_c3", "s12_c1"])
	e.pack_pity.threshold_override = 2
	e.packs.open_standard()
	e.packs.open_standard()
	_ok(e.pack_pity.count() == 2 and e.pack_pity.guarantee_due(), "2 all-duplicate packs -> guarantee due")
	var drawn: Array = e.packs.open_standard()
	_ok(drawn.has("s9_c3") and e.collection.owned("s9_c3") == 1 and e.pack_pity.count() == 0, "pack contained the first missing card (%s); counter reset" % str(drawn))
	_complete("p03_guarantee_missing_card")

func _p04() -> void:
	print("[p04 Premium keeps card 0 Rare-or-better under the guarantee]")
	var app = _app("p04")
	var e = app.economy
	_own_all_but(app, ["s2_c0"])   # a COMMON missing card
	e.pack_pity.threshold_override = 1
	e.pack_pity.on_opened(false)   # one earlier all-duplicate earned pack
	var due: bool = e.pack_pity.guarantee_due()
	# Test seam: pick an RNG seed whose natural Premium draws do NOT include the missing card,
	# so the substitution itself is exercised.
	var natural: Array = []
	var rng := RandomNumberGenerator.new()
	for sd in range(1, 500):
		rng.seed = sd
		var probe := RandomNumberGenerator.new()
		probe.state = rng.state
		var rare: Array = e.packs._rare_or_better
		var ids: Array = e.packs._card_ids
		natural = [rare[probe.randi_range(0, rare.size() - 1)]]
		for _i in range(4):
			natural.append(ids[probe.randi_range(0, ids.size() - 1)])
		if not natural.has("s2_c0"):
			e.packs._rng.state = rng.state
			break
	var drawn: Array = e.packs.open_premium()
	_ok(due and drawn.size() == 5 and drawn.slice(0, 4) == natural.slice(0, 4) and drawn[4] == "s2_c0" and e.collection.card_rarity(drawn[0]) in RARE_PLUS, "5 cards, card 0 %s, missing COMMON placed at a later slot %s" % [e.collection.card_rarity(drawn[0]), str(drawn)])
	_complete("p04_premium_card0_kept")

func _p05() -> void:
	print("[p05 nothing missing -> no fabrication]")
	var app = _app("p05")
	var e = app.economy
	_own_all_but(app, [])
	e.pack_pity.threshold_override = 1
	e.packs.open_standard()
	var before: Dictionary = e.collection.snapshot()["owned"].duplicate()
	var drawn: Array = e.packs.open_standard()
	var added := 0
	for cid in drawn:
		added += 1
	var after: Dictionary = e.collection.snapshot()["owned"]
	var delta := 0
	for cid in after:
		delta += int(after[cid]) - int(before.get(cid, 0))
	_ok(delta == 3 and drawn.all(func(c): return int(before.get(c, 0)) >= 1) and e.pack_pity.count() == 2, "normal duplicate draws only; counter keeps counting; no extra card")
	_complete("p05_no_missing_no_fabrication")

func _p06() -> void:
	print("[p06 shipped config: threshold 3 -> 3 all-duplicate packs, then a guaranteed missing card]")
	var app = _app("p06")
	var e = app.economy
	var cfg: Dictionary = e.config.collection_config().get("pity", {})
	_ok(cfg.get("threshold") == 3 and cfg.get("first_sprint_threshold") == 1, "shipped pity config %s" % str(cfg))
	_own_all_but(app, ["s7_c7"])
	var due: Array = []
	for _i in range(3):
		due.append(e.pack_pity.guarantee_due(e.collection))
		e.packs.open_standard()
	_ok(e.pack_pity.threshold(e.collection) == 3 and due == [false, false, false] and e.pack_pity.count() == 3 and e.pack_pity.guarantee_due(e.collection), "3 all-duplicate packs -> due exactly at 3")
	var drawn: Array = e.packs.open_standard()
	_ok(drawn.has("s7_c7") and e.collection.owned("s7_c7") == 1 and e.pack_pity.count() == 0, "4th pack holds the missing card %s; counter reset" % str(drawn))
	_complete("p06_shipped_threshold")

func _p07() -> void:
	print("[p07 C008 rollback restores the pity counter exactly]")
	var app = _app("p07")
	_own_all_but(app, [])
	app.economy.packs.open_standard()
	app.request_save()
	var c0: int = app.economy.pack_pity.count()
	var r := PackCommitTransaction.commit(app.economy, "standard", "p07_tx", Callable(app, "request_save"), func(s): return s == "save")
	_ok(not r["ok"] and app.economy.pack_pity.count() == c0, "failed presented commit: counter back to %d" % c0)
	var ok: Dictionary = app.commit_pack("standard", "p07_tx2")
	_ok(ok["ok"] and app.economy.pack_pity.count() == c0 + 1 and AppState.new(app.save._path).economy.pack_pity.count() == c0 + 1, "successful commit counts once, durably")
	_complete("p07_rollback_with_c008")

func _p08() -> void:
	print("[p08 earned-only: no purchase / ad / reroll path reaches pity]")
	var hits: Array = []
	for path in ["res://scripts/ui/shop/shop_screen.gd", "res://scripts/economy/production_action_facade.gd", "res://scripts/economy/rewarded_grant_service.gd",
			"res://scripts/economy/rewarded_ad_provider.gd", "res://scripts/ui/popup/acquisition_flow.gd"]:
		var src := FileAccess.get_file_as_string(path)
		if src.contains("pack_pity") or src.contains("guarantee_due") or src.contains("on_opened"):
			hits.append(path.get_file())
	var pity_src := FileAccess.get_file_as_string("res://scripts/collection/pack_pity.gd")
	_ok(hits.is_empty() and not pity_src.contains("wallet") and not pity_src.contains("debit"), "no shop / facade / ad path touches pity; pity has no spend API %s" % str(hits))
	_complete("p08_earned_only_static")

func _p09() -> void:
	print("[p09 not due: identical RNG use and apply order]")
	var a = _app("p09a", 4242)
	var b = _app("p09b", 4242)
	b.economy.packs.pity = null   # pre-C007R behaviour
	_own_set(a, 1)
	_own_set(b, 1)
	var da: Array = a.economy.packs.open_premium() + a.economy.packs.open_standard()
	var db: Array = b.economy.packs.open_premium() + b.economy.packs.open_standard()
	_ok(da == db and a.economy.packs._rng.state == b.economy.packs._rng.state and a.economy.collection.snapshot() == b.economy.collection.snapshot(), "same draws, same RNG state, same Collection")
	_complete("p09_rng_and_order_unchanged_when_not_due")

func _p10() -> void:
	print("[p10 First Collection Sprint: while Set 1 is incomplete a pack without a NEW Set 1 card makes the next one guarantee it]")
	var app = _app("p10", 9001)
	var e = app.economy
	_ok(e.pack_pity.focus_set(e.collection) == 1 and e.pack_pity.threshold(e.collection) == 1, "fresh profile: sprint on Set 1, threshold 1")
	var guaranteed := 0
	var dud_then_none := 0
	var any_new_kept_count := false
	var counter_ok := true
	var n := 0
	while not e.collection.is_set_complete(1) and n < 60:
		var due: bool = e.pack_pity.guarantee_due(e.collection)
		var missing1: Array = e.collection.all_card_ids().filter(func(c): return e.collection.card_set(c) == 1 and e.collection.owned(c) == 0)
		var owned_any: Dictionary = e.collection.snapshot()["owned"].duplicate()
		var drawn: Array = e.packs.open_premium() if n % 4 == 3 else e.packs.open_standard()
		var got1 := drawn.any(func(c): return missing1.has(c))
		if due:
			guaranteed += 1
			if not got1:
				dud_then_none += 1
		# a NEW card of another set does not reset the sprint counter
		if not got1 and drawn.any(func(c): return e.collection.card_set(c) != 1 and not owned_any.has(c)) and e.pack_pity.count() > 0:
			any_new_kept_count = true
		if e.pack_pity.count() != (0 if got1 else 1):
			counter_ok = false
		n += 1
	_ok(e.collection.is_set_complete(1) and guaranteed > 0 and dud_then_none == 0, "Set 1 complete after %d packs; %d guaranteed packs all held a missing Set 1 card" % [n, guaranteed])
	_ok(counter_ok and any_new_kept_count, "counter: Set 1 card -> 0, otherwise 1 (never 2 at threshold 1); a NEW non-Set-1 card does not reset it")
	_ok(e.pack_pity.focus_set(e.collection) == 0 and e.pack_pity.threshold(e.collection) == 3, "after Set 1: plain rule, threshold 3")
	_complete("p10_first_sprint_set1")

func _p11() -> void:
	print("[p11 sprint guarantee is legible: Collection shows NEW CARD GUARANTEED NEXT PACK only when due]")
	var app = _app("p11")
	var e = app.economy
	var due0: bool = e.pack_pity.guaranteed_next(e.collection)
	_own_all_but(app, ["s1_c8"])
	e.pack_pity.on_opened(false)
	var due1: bool = e.pack_pity.guaranteed_next(e.collection)
	e.packs.open_standard()
	_ok(not due0 and due1 and e.collection.is_set_complete(1) and not e.pack_pity.guaranteed_next(e.collection), "fresh: not due; 1 Set-1 dud -> due; guaranteed pack completes Set 1 (s1_c8)")
	var src := FileAccess.get_file_as_string("res://scripts/ui/collection/collection_screen.gd")
	_ok(src.contains("guaranteed_next(e.collection)"), "Collection copy reads the sprint-aware due state")
	_complete("p11_sprint_legible_ui")

# ------------------------------------------------------------------ helpers ----

## Own every Set `n` card through the real authority (ends the First Collection Sprint for n = 1).
func _own_set(app, n: int) -> void:
	for cid in app.economy.collection.all_card_ids():
		if app.economy.collection.card_set(cid) == n and app.economy.collection.owned(cid) == 0:
			app.economy.collection.add_card(cid)

func _uniq(tag: String) -> String:
	var p := "user://m43master_c007r_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M43 master C007R pity evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
