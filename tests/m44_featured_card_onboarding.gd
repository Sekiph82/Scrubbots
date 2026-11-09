extends SceneTree
## SB-M44-026 + SB-M44-022..023 (OWNER_META_PROGRESSION_DESIGN_V01; owner 2026-11-03 L1 gate):
##   - data/config/featured_cards_v1.json schedules all 135 catalogue cards exactly once: Set 01 at
##     the owner levels 20..40, every other set at +0/+10/+20/+30/+40/+50/+60/+70/+90 from its owner
##     featured range start, catalogue order;
##   - first clear of L20 grants Scrubby, of L30 / L40 the first Set 01 card not owned yet (all owned
##     -> the row's fallback card as an ordinary duplicate), each exactly once across a duplicate
##     WON, relaunch and snapshot import; other levels grant nothing; the pack RNG is untouched;
##   - the granted card gets one Featured Card ceremony (canonical art / name);
##   - L1 onboarding: Collection / Card Packs / Tasks open, the first earned pack opens at once into
##     the First Collection Sprint, the pity line is hidden until a guarantee is due and then true;
##     Daily / Tasks claims and Events actions follow feature_unlocks_v1.json (Events L30).
## Never boots main.tscn: AppState on throw-away user:// saves + a ModalStack.
##
## Run: godot --headless --path . -s res://tests/m44_featured_card_onboarding.gd

const AppState = preload("res://scripts/app/app_state.gd")
const FeaturedCards = preload("res://scripts/collection/featured_cards.gd")
const FirstClearTransaction = preload("res://scripts/economy/first_clear_transaction.gd")
const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")
const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

## Owner table (OWNER_META_PROGRESSION_DESIGN_V01 §2): set -> featured range start.
const OWNER_RANGE_START := {1: 20, 2: 50, 3: 601, 4: 151, 5: 751, 6: 451, 7: 1801, 8: 901, 9: 301,
	10: 1201, 11: 1651, 12: 2401, 13: 1351, 14: 2251, 15: 2851}
const OWNER_SET01 := [[20, "Scrubby"], [22, "Bubbles"], [24, "Moppy"], [26, "Brushy"], [29, "Squeegee"],
	[32, "Spark"], [35, "Turbo Scrubby"], [38, "Captain Clean"], [40, "Scrubmaster X"]]
const OFFSETS := [0, 10, 20, 30, 40, 50, 60, 70, 90]

var EXPECTED_CASES := ["schedule_exact", "l20_scrubby_once", "l30_l40_unowned_set01", "all_owned_fallback",
	"other_levels_nothing", "ceremony", "l1_onboarding_sprint_pity", "data_driven_gates"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack = null

func _initialize() -> void:
	await process_frame
	_schedule_exact()
	_l20_scrubby_once()
	_l30_l40_unowned_set01()
	_all_owned_fallback()
	_other_levels_nothing()
	_ceremony()
	await _l1_onboarding_sprint_pity()
	_data_driven_gates()
	_unmount()
	_cleanup()
	_done()

func _schedule_exact() -> void:
	print("[schedule_exact: 135 cards once, Set 01 owner levels, other sets owner start + offsets]")
	var sched: Array = FeaturedCards.schedule()
	var cards: Array = sched.map(func(e): return String(e["card"]))
	var catalog: Array = CollectionCardCatalog.card_ids()
	var uniq := {}
	for c in cards:
		uniq[c] = true
	_ok(sched.size() == 135 and uniq.size() == 135 and catalog.size() == 135 and catalog.all(func(c): return uniq.has(c)), "135 entries, every catalogue card exactly once")
	var by_card := {}
	for e in sched:
		by_card[String(e["card"])] = int(e["level"])
	var s1_ok := true
	for k in range(9):
		var cid := "s1_c%d" % k
		s1_ok = s1_ok and by_card[cid] == OWNER_SET01[k][0] and String(CollectionCardCatalog.entry(cid)["name"]) == OWNER_SET01[k][1]
	_ok(s1_ok, "Set 01: 20 Scrubby .. 40 Scrubmaster X, owner levels and names")
	var other_ok := true
	for s in range(2, 16):
		for k in range(9):
			var cid := "s%d_c%d" % [s, k]
			other_ok = other_ok and by_card[cid] == OWNER_RANGE_START[s] + OFFSETS[k] and int(CollectionCardCatalog.entry(cid)["card"]) == k + 1
	_ok(other_ok, "Sets 02..15: owner range start + 0/10/20/30/40/50/60/70/90, catalogue order")
	var ranges_ok: bool = FeaturedCards.data()["set_ranges"].size() == 15
	for r in FeaturedCards.data()["set_ranges"]:
		ranges_ok = ranges_ok and OWNER_RANGE_START[int(r["set"])] == int(r["first"])
	_ok(ranges_ok, "set_ranges = owner featured range starts")
	var levels: Array = sched.map(func(e): return int(e["level"]))
	var sorted := levels.duplicate()
	sorted.sort()
	_ok(levels == sorted, "schedule ascending by level")
	var g: Array = FeaturedCards.data()["guarantees"]
	_ok(g.size() == 3 and int(g[0]["level"]) == 20 and g[0]["card"] == "s1_c0" and int(g[1]["level"]) == 30 and int(g[1]["set"]) == 1 and int(g[2]["level"]) == 40 and int(g[2]["set"]) == 1, "guarantees: L20 Scrubby, L30 / L40 Set 01")
	_complete("schedule_exact")

func _l20_scrubby_once() -> void:
	print("[l20_scrubby_once: first clear of L20 grants Scrubby once (dup WON, relaunch, import)]")
	var path := _path("l20")
	var a = AppState.new(path)
	var e = a.economy
	_walk_to(a, 20)
	var rng0: int = e.packs._rng.state
	var r: Dictionary = FirstClearTransaction.commit(a.progression, e, 20)
	_ok(bool(r["ok"]) and r["featured"] == {"applied": true, "card": "s1_c0"} and e.collection.owned("s1_c0") == 1, "L20 commit: Scrubby granted %s" % str(r.get("featured")))
	_ok(e.packs._rng.state == rng0 and e.pack_pity.count() == 0, "pack RNG / pity untouched by the guarantee")
	_ok(not bool(FirstClearTransaction.commit(a.progression, e, 20)["ok"]) and not bool(FeaturedCards.grant_milestone(e, 20)["applied"]) and e.collection.owned("s1_c0") == 1, "duplicate WON / direct regrant: nothing")
	_ok(bool(a.request_save()["ok"]), "saved")
	var b = AppState.new(path)
	_ok(b.economy.collection.owned("s1_c0") == 1 and not bool(FeaturedCards.grant_milestone(b.economy, 20)["applied"]) and b.economy.collection.owned("s1_c0") == 1, "relaunch: still 1, no regrant")
	var c = AppState.new(_path("l20_import"))
	_ok(c.economy.import_snapshot(e.snapshot()) and not bool(FeaturedCards.grant_milestone(c.economy, 20)["applied"]) and c.economy.collection.owned("s1_c0") == 1, "snapshot import into a fresh profile: no regrant")
	_complete("l20_scrubby_once")

func _l30_l40_unowned_set01() -> void:
	print("[l30_l40_unowned_set01: the first Set 01 card not owned yet, once each]")
	var a = AppState.new(_path("l30"))
	var e = a.economy
	for cid in ["s1_c0", "s1_c1", "s1_c3"]:
		e.collection.add_card(cid)
	_walk_to(a, 30)
	var r30: Dictionary = FirstClearTransaction.commit(a.progression, e, 30)
	_ok(bool(r30["ok"]) and r30["featured"]["card"] == "s1_c2" and e.collection.owned("s1_c2") == 1, "L30: s1_c2 (first missing) granted %s" % str(r30["featured"]))
	for cid in ["s1_c4", "s1_c5", "s1_c6", "s1_c8"]:
		e.collection.add_card(cid)
	var sb0: int = e.wallet.scrub_bucks()
	_walk_to(a, 40)
	var r40: Dictionary = FirstClearTransaction.commit(a.progression, e, 40)
	_ok(bool(r40["ok"]) and r40["featured"]["card"] == "s1_c7" and e.collection.is_set_complete(1), "L40: s1_c7 granted, Set 01 complete")
	_ok(e.reward.already_applied("collection_set:1") or e.collection.snapshot()["set_reward_claimed"].has(1), "Set 01 reward committed by the normal set rule")
	_ok(e.wallet.scrub_bucks() > sb0, "set reward + first-clear SB credited")
	_ok(FeaturedCards.milestone_cards(e.reward) == [{"level": 30, "card": "s1_c2"}, {"level": 40, "card": "s1_c7"}], "ledger holds exactly the two grants")
	_complete("l30_l40_unowned_set01")

func _all_owned_fallback() -> void:
	print("[all_owned_fallback: Set 01 complete -> the row's fallback card as a duplicate]")
	var a = AppState.new(_path("fallback"))
	var e = a.economy
	for k in range(9):
		e.collection.add_card("s1_c%d" % k)
	var claimed0: Array = e.collection.snapshot()["set_reward_claimed"].duplicate()
	_walk_to(a, 30)
	var r: Dictionary = FirstClearTransaction.commit(a.progression, e, 30)
	_ok(bool(r["ok"]) and r["featured"]["card"] == "s1_c4" and e.collection.owned("s1_c4") == 2, "L30: Squeegee duplicate (owned 2)")
	_ok(e.collection.snapshot()["set_reward_claimed"] == claimed0, "no second set reward")
	_complete("all_owned_fallback")

func _other_levels_nothing() -> void:
	print("[other_levels_nothing: featured-only levels grant no card]")
	var a = AppState.new(_path("other"))
	var e = a.economy
	_walk_to(a, 21)
	var col0: Dictionary = e.collection.snapshot()
	var ok := true
	for lvl in [21, 22, 23, 24, 25, 26, 27, 28, 29]:
		ok = ok and bool(FirstClearTransaction.commit(a.progression, e, lvl)["ok"])
	_ok(ok and e.collection.snapshot() == col0 and FeaturedCards.milestone_cards(e.reward).is_empty(), "L21..L29 (incl. featured L22 / L24 / L26 / L29): Collection unchanged")
	_complete("other_levels_nothing")

func _ceremony() -> void:
	print("[ceremony: one Featured Card ceremony per granted card, canonical art / name]")
	var path := _path("ceremony")
	var a = AppState.new(path)
	var e = a.economy
	_walk_to(a, 20)
	FirstClearTransaction.commit(a.progression, e, 20)
	var pend: Array = CeremonyEvents.pending(e, e.meta_ui).filter(func(x): return x["kind"] == "featured_card")
	_ok(pend.size() == 1 and pend[0]["key"] == "featured_card:L20:s1_c0" and int(pend[0]["level"]) == 20, "one pending featured_card event %s" % str(pend))
	var p = MetaCeremonies.build(pend[0]) if pend.size() == 1 else null
	var name_l: Label = p.find_child("CardName", true, false) if p != null else null
	var note: Label = p.find_child("CommittedNote", true, false) if p != null else null
	var art: TextureRect = p.find_child("HeroArt", true, false) if p != null else null
	_ok(name_l != null and name_l.text == "Scrubby" and note.text == UiText.t("CEREMONY_FEATURED_LEVEL", [20])
		and art.texture.resource_path == String(CollectionCardCatalog.entry("s1_c0")["art"]), "popup: Scrubby art + name + Level 20 line")
	if p != null:
		p.free()
	_ok(MetaCeremonies.build({"key": "featured_card:L20:s99_c0", "kind": "featured_card", "level": 20, "card": "s99_c0"}) == null, "unknown card: no ceremony")
	e.meta_ui.mark_seen(String(pend[0]["key"]))
	a.request_save()
	var b = AppState.new(path)
	_ok(CeremonyEvents.pending(b.economy, b.economy.meta_ui).filter(func(x): return x["kind"] == "featured_card").is_empty(), "acknowledged: not shown again after relaunch")
	_complete("ceremony")

func _l1_onboarding_sprint_pity() -> void:
	print("[l1_onboarding_sprint_pity: L1 Collection / packs, First Collection Sprint, pity hidden until due]")
	var a = AppState.new(_path("onboarding"))
	_ok(bool(a.bootstrap_new_profile()["ok"]) and a.progression.current_level() == 1, "fresh new profile at L1")
	_ok(["collection", "card_packs", "tasks", "daily"].all(func(id): return a.feature_unlocked(id)), "L1: Collection / Card Packs / Tasks / Daily open")
	var e = a.economy
	e.packs._rng.seed = 4242
	_ok(e.pack_pity.focus_set(e.collection) == 1 and e.pack_pity.threshold(e.collection) == 1, "First Collection Sprint on Set 01")
	_mount()
	_ok(not _album_pity_line(a), "fresh: no pity line in Collection")
	e.reward.grant("m44_onboard_first", {"standard_card_packs": 1})
	var id: String = e.pending_packs.front()["id"]
	var r: Dictionary = a.open_earned_pack(id)
	var set1_new: bool = (r["receipt"]["cards"] as Array).any(func(c): return bool(c["is_new"]) and e.collection.card_set(String(c["card_id"])) == 1)
	_ok(bool(r["ok"]), "first earned pack opens at L1")
	_ok(e.pack_pity.guarantee_due(e.collection) == (not set1_new), "counter follows the Set 01 sprint rule (Set 01 card in pack: %s)" % str(set1_new))
	# A dud (no new Set 01 card) makes the next pack guarantee one; only then the line shows.
	_own_all_but_set1(e)
	if not e.pack_pity.guarantee_due(e.collection):
		e.pack_pity.on_opened(false)
	_ok(e.pack_pity.guarantee_due(e.collection) and _album_pity_line(a), "due: Collection shows NEW CARD GUARANTEED NEXT PACK")
	var missing1: Array = e.collection.all_card_ids().filter(func(c): return e.collection.card_set(c) == 1 and e.collection.owned(c) == 0)
	e.reward.grant("m44_onboard_second", {"standard_card_packs": 1})
	var r2: Dictionary = a.open_earned_pack(e.pending_packs.entries()[-1]["id"])
	var got: Array = (r2["receipt"]["cards"] as Array).map(func(c): return String(c["card_id"]))
	_ok(bool(r2["ok"]) and got.any(func(c): return missing1.has(c)), "the line is true: the next pack held a missing Set 01 card %s" % str(got))
	_ok(not e.pack_pity.guarantee_due(e.collection) and not _album_pity_line(a), "after the guarantee: line hidden again")
	_complete("l1_onboarding_sprint_pity")

func _data_driven_gates() -> void:
	print("[data_driven_gates: Daily / Tasks claims and Events follow feature_unlocks_v1.json]")
	var a = AppState.new(_path("gates"))
	a.bootstrap_new_profile()
	_ok(a.feature_unlock_level("events") == 30 and not a.feature_unlocked("events"), "Events unlock at L30 (data), locked at L1")
	_ok(String(a.actions.join_first_try().get("reason", "")) == "locked", "First-Try Cleanup join refused while Events locked")
	a.unlocks.cfg["unlocks"]["daily"] = 4
	a.unlocks.cfg["unlocks"]["tasks"] = 12
	var econ0: Dictionary = a.economy.snapshot()
	var reasons := [a.actions.claim_daily_login(), a.actions.claim_daily_task(0), a.actions.claim_daily_all_tasks()].map(func(x): return String(x.get("reason", "")))
	_ok(reasons == ["locked", "locked", "locked"] and a.economy.snapshot() == econ0, "Daily L4 / Tasks L12 in data: claims refused, economy unchanged")
	a.unlocks.cfg["unlocks"]["daily"] = 1
	a.unlocks.cfg["unlocks"]["tasks"] = 1
	_ok(bool(a.actions.claim_daily_login()["ok"]), "shipped L1 gate: Daily claim commits")
	_walk_to(a, 30)
	_ok(a.feature_unlocked("events") and String(a.actions.join_first_try().get("reason", "")) != "locked", "L30: Events open")
	_complete("data_driven_gates")

# ------------------------------------------------------------------ helpers ----

func _album_pity_line(app) -> bool:
	var album = CollectionScreen.open_album(_stack, app, func(): pass)
	var shown: bool = (album.find_child("Summary", true, false) as Label).text.contains(UiText.t("COLLECTION_PITY_NEXT"))
	album.close()
	return shown

## Own every non-Set-01 card so a pack can only be new through Set 01 (Collection authority).
func _own_all_but_set1(e) -> void:
	for cid in e.collection.all_card_ids():
		if e.collection.card_set(cid) != 1 and e.collection.owned(cid) == 0:
			e.collection.add_card(cid)

func _walk_to(app, level: int) -> void:
	while app.progression.current_level() < level:
		app.progression.record_win(app.progression.current_level())

func _mount() -> void:
	_unmount()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 1920)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_stack = ModalStack.new()
	_sub.add_child(_stack)

func _unmount() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_sub = null
	_stack = null

func _path(tag: String) -> String:
	var p := "user://m44_featured_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp", ".json"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	for c in missing:
		print("  FAIL: case did not complete: %s" % c)
	_fail += missing.size()
	print("M44 FEATURED CARD ONBOARDING: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
