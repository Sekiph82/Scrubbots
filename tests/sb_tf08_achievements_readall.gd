extends SceneTree
## SB-TF-08 (owner 2026-11-18) — Achievements open with earned entries on top (claimable, then
## claimed, then in progress; catalogue order inside each group; no live re-sort on CLAIM), and
## the Collection album's READ ALL marks every owned unseen card seen in one durable facade save
## (NEW badges, Profile Collection badge and the Home profile badge sum clear; nothing else moves).
## Real app root (main.tscn) on temp saves, injected clock + local day.
##
## Run: godot --headless --path . -s res://tests/sb_tf08_achievements_readall.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const Achievements = preload("res://scripts/progression/achievements.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTextTr = preload("res://scripts/ui/ui_text_tr.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const NEW_CARDS := ["s1_c0", "s1_c1", "s2_c0"]

var EXPECTED_CASES := [
	"t01_sort_helper", "t02_popup_order", "t03_scroll_top", "t04_claim_in_place",
	"t05_readall_visibility", "t06_readall_press", "t07_readall_scope", "t08_idempotent",
	"t09_persistence_rollback", "t10_profile_home_badges", "t11_readall_reappears", "t12_layout_en_tr",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	preload("res://scripts/app/app_state.gd").test_unlock_all = true
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	_t01()
	await _t02_t03_t04()
	await _t05()
	await _t06_t07_t08()
	await _t09()
	await _t10()
	await _t11()
	await _t12()
	UiText.locale = "en"
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _t01() -> void:
	print("[t01 sort_for_display: claimable -> claimed -> in progress, stable, input untouched]")
	var mk := func(id: String, done: bool, claimed: bool): return {"id": id, "done": done, "claimed": claimed, "claimable": done and not claimed}
	var src: Array = [mk.call("a", false, false), mk.call("b", true, true), mk.call("c", true, false), mk.call("d", false, false),
		mk.call("e", true, true), mk.call("f", true, false)]
	var before := src.duplicate(true)
	var out: Array = Achievements.sort_for_display(src)
	_ok(out.map(func(a): return a["id"]) == ["c", "f", "b", "e", "a", "d"], "mixed -> %s" % str(out.map(func(a): return a["id"])))
	_ok(src == before, "input list not mutated")
	_ok(Achievements.sort_for_display([]).is_empty(), "empty list -> empty")
	var prog: Array = [mk.call("x", false, false), mk.call("y", false, false), mk.call("z", false, false)]
	_ok(Achievements.sort_for_display(prog).map(func(a): return a["id"]) == ["x", "y", "z"], "all in progress -> catalogue order")
	_complete("t01_sort_helper")

func _t02_t03_t04() -> void:
	print("[t02 real popup: late claimable first, claimed next, early in-progress last]")
	await _boot("t02")
	var app = _root.get_app_state()
	var e = app.economy
	e.collection.add_card("s1_c0")                                       # first_discovery (#13) done
	_ok(bool(app.actions.claim_achievement(app, "first_discovery").get("ok", false)), "fixture: first_discovery claimed")
	_ok(e.reward.grant("gift_ms:tf08", {"scrub_bucks": 1}) and e.reward.grant("daily_task:tf08", {"scrub_bucks": 1}), "fixture: gift_hunter (#42) + first_order (#47) reached")
	var ev: Array = Achievements.evaluate(app)
	var cat_ids: Array = ev.map(func(a): return a["id"])
	var state := {}
	for a in ev:
		state[a["id"]] = a
	_ok(state["gift_hunter"]["claimable"] and state["first_order"]["claimable"] and state["first_discovery"]["claimed"] and not state["clean_start"]["done"],
		"fixture states: gift_hunter / first_order claimable, first_discovery claimed, clean_start (#0) in progress")
	_ok(cat_ids == Achievements.load_defs().map(func(a): return a["id"]), "evaluate() still catalogue order")
	var p = ProfileScreens.open_achievements(_root.get_modal_stack(), app)
	await _frames(3)
	var scroll: ScrollContainer = p.find_child("AchievementList", true, false)
	var list: VBoxContainer = scroll.get_child(0)
	var shown: Array = list.get_children().filter(func(c): return String(c.name).begins_with("Ach_")).map(func(c): return String(c.name).substr(4))
	var want: Array = Achievements.sort_for_display(ev).map(func(a): return a["id"])
	_ok(shown == want and shown.size() == 50, "VBox order == sort_for_display (%d cards)" % shown.size())
	var groups: Array = shown.map(func(id): return 0 if state[id]["claimable"] else (1 if state[id]["done"] else 2))
	var sorted_groups := groups.duplicate()
	sorted_groups.sort()
	_ok(groups == sorted_groups and groups[0] == 0, "groups claimable / claimed / in progress contiguous in that order")
	_ok(shown.find("gift_hunter") < shown.find("first_discovery") and shown.find("first_discovery") < shown.find("clean_start"),
		"gift_hunter (%d) before first_discovery (%d) before clean_start (%d)" % [shown.find("gift_hunter"), shown.find("first_discovery"), shown.find("clean_start")])
	_complete("t02_popup_order")

	print("[t03 AchievementList opens at scroll 0 with 50 entries]")
	var bar := scroll.get_v_scroll_bar()
	_ok(scroll.scroll_vertical == 0 and bar.max_value > bar.page, "scroll_vertical %d with a scrollable list (max %.0f > page %.0f)" % [scroll.scroll_vertical, bar.max_value, bar.page])
	_complete("t03_scroll_top")

	print("[t04 CLAIM in the open popup: grants once, COMPLETED pill in place, no reorder]")
	var placed := {}
	for c in list.get_children():
		placed[c.name] = [c.get_parent(), c.get_index()]
	var before := int(HomeBadges.compute(app)["achievements"])
	var sb0: int = e.wallet.scrub_bucks()
	_tap("ach:gift_hunter")
	await _frames(2)
	var card: Control = list.get_node("Ach_gift_hunter")
	_ok(e.reward.already_applied(Achievements.tx_id("gift_hunter")) and e.wallet.scrub_bucks() == sb0 + 100, "reward granted once (+100 SB)")
	_ok(p.get_action_button("ach:gift_hunter") == null and card.find_child("Pill", true, false) != null, "CLAIM gone, COMPLETED pill shown")
	_ok(int(HomeBadges.compute(app)["achievements"]) == before - 1, "achievements badge %d -> %d" % [before, int(HomeBadges.compute(app)["achievements"])])
	var moved: Array = list.get_children().filter(func(c): return placed[c.name] != [c.get_parent(), c.get_index()])
	_ok(moved.is_empty() and list.get_child_count() == placed.size(), "no card re-parented or reordered %s" % str(moved))
	_ok(not bool(app.actions.claim_achievement(app, "gift_hunter").get("ok", true)), "second claim refused")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_complete("t04_claim_in_place")

func _t05() -> void:
	print("[t05 READ ALL hidden with no unread card; shown with 3 unread in 2 sets + NEW counts]")
	await _boot("t05")
	var app = _root.get_app_state()
	var e = app.economy
	_ok(CollectionScreen.unseen_cards(e).is_empty(), "fresh profile: no unread card")
	var p = CollectionScreen.open_album(_root.get_modal_stack(), app)
	await _frames(2)
	var ra: Button = p.find_child("ReadAll", true, false)
	_ok(ra != null and ra == p.get_action_button("read_all") and not ra.is_visible_in_tree(), "ReadAll exists (action read_all), hidden")
	p.close()
	await _frames(2)
	_seed_new_cards(e)
	p = CollectionScreen.open_album(_root.get_modal_stack(), app)
	await _frames(2)
	ra = p.find_child("ReadAll", true, false)
	_ok(ra.is_visible_in_tree(), "3 unread cards -> ReadAll visible")
	_ok(_badge(p, 1) == "2" and _badge(p, 2) == "1" and _visible_badges(p) == 2, "Set 1 NEW 2, Set 2 NEW 1, no other set badge")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_complete("t05_readall_visibility")

func _t06_t07_t08() -> void:
	print("[t06 press READ ALL: every unread seen, badges + button hidden, collection badge 0]")
	await _boot("t06")
	var app = _root.get_app_state()
	var e = app.economy
	_seed_new_cards(e)
	var p = CollectionScreen.open_album(_root.get_modal_stack(), app)
	await _frames(2)
	var pre: Dictionary = e.snapshot()
	var badges_pre := HomeBadges.compute(app)
	var calls := []
	app.actions.action_committed.connect(func(a, r): calls.append([a, r]))
	_tap("read_all")
	await _frames(2)
	_ok(calls.size() == 1 and calls[0][0] == "mark_all_cards_seen" and int(calls[0][1]["marked"]) == 3, "one facade commit, marked 3 %s" % str(calls))
	_ok(CollectionScreen.unseen_cards(e).is_empty() and NEW_CARDS.all(func(c): return e.meta_ui.is_seen("card:" + c)), "all 3 cards seen")
	_ok(_visible_badges(p) == 0 and not (p.find_child("ReadAll", true, false) as Button).is_visible_in_tree(), "every NewBadge + ReadAll hidden")
	_ok(not p.is_latched() and p.is_open(), "album re-armed, still open")
	var badges_post := HomeBadges.compute(app)
	_ok(int(badges_post["collection"]) == 0, "HomeBadges collection 0")
	var others := true
	for k in badges_pre:
		if k != "collection" and badges_pre[k] != badges_post[k]:
			others = false
	_ok(others, "no other badge changed %s -> %s" % [str(badges_pre), str(badges_post)])
	_complete("t06_readall_press")

	print("[t07 READ ALL changes only meta_ui.seen; an unowned card stays unmarked]")
	var post: Dictionary = e.snapshot()
	var a := pre.duplicate(true)
	var b := post.duplicate(true)
	var seen_pre: Array = a["meta_ui"]["seen"]
	var seen_post: Array = b["meta_ui"]["seen"]
	a.erase("meta_ui")
	b.erase("meta_ui")
	_ok(JSON.stringify(a) == JSON.stringify(b), "economy snapshot identical outside meta_ui (wallet, bot parts, packs, collection, tx ids)")
	var added: Array = seen_post.filter(func(k): return not seen_pre.has(k))
	added.sort()
	_ok(added == ["card:s1_c0", "card:s1_c1", "card:s2_c0"] and seen_pre.all(func(k): return seen_post.has(k)), "seen gained exactly the 3 card keys %s" % str(added))
	_ok(e.collection.owned("s3_c0") == 0 and not e.meta_ui.is_seen("card:s3_c0"), "unowned s3_c0 not marked")
	_complete("t07_readall_scope")

	print("[t08 idempotent: second call marks 0]")
	var r2: Dictionary = app.actions.mark_all_cards_seen()
	_ok(bool(r2["ok"]) and int(r2["marked"]) == 0, "second call %s" % str(r2))
	_ok(JSON.stringify(e.snapshot()) == JSON.stringify(post), "state unchanged")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_complete("t08_idempotent")

func _t09() -> void:
	print("[t09 persistence: snapshot import + disk reload keep the marks; save failure rolls back]")
	await _boot("t09")
	var app = _root.get_app_state()
	var e = app.economy
	_seed_new_cards(e)
	var r: Dictionary = app.actions.mark_all_cards_seen()
	_ok(bool(r["ok"]) and int(r["marked"]) == 3 and bool(r["save"].get("ok", false)), "committed + saved %s" % str(r.get("save")))
	var snap: Dictionary = e.snapshot()
	_ok(NEW_CARDS.all(func(c): return (snap["meta_ui"]["seen"] as Array).has("card:" + c)), "meta_ui snapshot has every card key")
	var fresh = EconomyServices.new()
	_ok(fresh.import_snapshot(snap.duplicate(true)) and NEW_CARDS.all(func(c): return fresh.meta_ui.is_seen("card:" + c)) and CollectionScreen.unseen_cards(fresh).is_empty(), "new EconomyServices import: still seen")
	fresh.dispose()
	var path: String = _tmp[-1]
	var reload = preload("res://scripts/app/app_state.gd").new(path, MainScript.boot_clock_override, MainScript.boot_local_day_override)
	_ok(NEW_CARDS.all(func(c): return reload.economy.meta_ui.is_seen("card:" + c)) and int(HomeBadges.compute(reload)["collection"]) == 0, "reload from disk: seen, collection badge 0")
	reload.economy.dispose()
	# Save failure: the facade restores the pre-action snapshot, cards stay unread.
	await _boot("t09b")
	app = _root.get_app_state()
	e = app.economy
	_seed_new_cards(e)
	var pre := JSON.stringify(e.snapshot())
	app.save.set_fault_injector(func(stage): return stage == "temp_write")
	var rf: Dictionary = app.actions.mark_all_cards_seen()
	app.save.set_fault_injector(Callable())
	_ok(not bool(rf["ok"]) and String(rf["reason"]) == "save_failed" and bool(rf["restored"]), "save failed -> refused + restored %s" % str(rf))
	_ok(JSON.stringify(e.snapshot()) == pre and CollectionScreen.unseen_cards(e).size() == 3 and int(HomeBadges.compute(app)["collection"]) == 3, "exact pre-state, 3 cards still unread")
	_complete("t09_persistence_rollback")

func _t10() -> void:
	print("[t10 Profile: Collection badge 3 -> Read all -> close -> hidden; Home profile badge drops 3]")
	await _boot("t10")
	var app = _root.get_app_state()
	var e = app.economy
	var h = _root.get_home()
	_seed_new_cards(e)
	h.refresh()
	await _frames(2)
	var bd := HomeBadges.compute(app)
	var rest := int(bd["achievements"]) + int(bd["robots"]) + int(bd["daily"])   # SB-TF-11: + today's login reward
	var pb: Label = h.get_region("ProfileBadge")
	_ok(int(bd["collection"]) == 3 and pb.visible and pb.text == str(rest + 3), "Home profile badge counts 3 cards (%s)" % pb.text)
	(h.get_region("ProfileButton") as Button).pressed.emit()
	await _frames(2)
	var badge: Label = _top().get_action_button("collection").get_node("CollectionBadge")
	_ok(badge.visible and badge.text == "3", "Profile CollectionBadge 3")
	_tap("collection")
	await _frames(2)
	_ok(_top_id() == "collection", "album open")
	_tap("read_all")
	await _frames(2)
	_top().close()
	await _frames(2)
	_ok(_top_id() == "profile" and not badge.visible, "back on Profile: CollectionBadge hidden")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_ok(int(HomeBadges.compute(app)["collection"]) == 0 and pb.text == ("" if rest == 0 else str(rest)), "Home profile badge no longer counts cards ('%s')" % pb.text)
	_complete("t10_profile_home_badges")

func _t11() -> void:
	print("[t11 a later new card brings READ ALL back on the album refresh]")
	await _boot("t11")
	var app = _root.get_app_state()
	var e = app.economy
	_seed_new_cards(e)
	var p = CollectionScreen.open_album(_root.get_modal_stack(), app)
	await _frames(2)
	_tap("read_all")
	await _frames(2)
	var ra: Button = p.find_child("ReadAll", true, false)
	_ok(not ra.is_visible_in_tree(), "hidden after Read all")
	e.collection.add_card("s4_c2")
	CollectionScreen._refresh_album(p, e)
	await _frames(1)
	_ok(ra.is_visible_in_tree() and _badge(p, 4) == "1", "new card -> ReadAll visible again, Set 4 NEW 1")
	# The real path: another popup closes and the album is back on top.
	_tap("read_all")
	await _frames(2)
	e.collection.add_card("s5_c0")
	var c = CollectionScreen.open_exchange(_root.get_modal_stack(), app)
	await _frames(2)
	c.close()
	await _frames(2)
	_ok(_top() == p and ra.is_visible_in_tree() and _badge(p, 5) == "1", "back on top (top_changed) -> ReadAll re-evaluated, visible")
	_root.get_modal_stack().clear("test")
	await _frames(2)
	_complete("t11_readall_reappears")

func _t12() -> void:
	print("[t12 READ ALL >= TOUCH_MIN, inside the popup interior, label fits; EN + TR keys]")
	_ok(UiText.t("COLLECTION_READ_ALL") == "READ ALL" and UiTextTr.TR.get("COLLECTION_READ_ALL") == "TÜMÜNÜ OKU", "EN 'READ ALL' / TR 'TÜMÜNÜ OKU'")
	for loc in ["en", "tr"]:
		UiText.locale = loc
		await _boot("t12_" + loc)
		var app = _root.get_app_state()
		_seed_new_cards(app.economy)
		var p = CollectionScreen.open_album(_root.get_modal_stack(), app)
		await _frames(3)
		var ra: Button = p.find_child("ReadAll", true, false)
		var r := ra.get_global_rect()
		var inner: Rect2 = (p.get_content() as Control).get_global_rect()
		var tw: float = ra.get_theme_font("font").get_string_size(ra.text, HORIZONTAL_ALIGNMENT_LEFT, -1, ra.get_theme_font_size("font_size")).x
		var avail: float = r.size.x - ra.get_theme_stylebox("normal").get_minimum_size().x
		_ok(ra.text == UiText.t("COLLECTION_READ_ALL") and r.size.y >= UiTokens.TOUCH_MIN, "%s '%s' height %.0f >= %d" % [loc, ra.text, r.size.y, UiTokens.TOUCH_MIN])
		_ok(inner.encloses(r) and p.get_frame_rect().encloses(r), "%s rect %s inside content %s" % [loc, str(r), str(inner)])
		_ok(tw <= avail + 0.5 and ra.get_combined_minimum_size().x <= r.size.x + 0.5, "%s label %.0f fits %.0f (min %.0f <= %.0f)" % [loc, tw, avail, ra.get_combined_minimum_size().x, r.size.x])
		var row: Rect2 = (p.find_child("PackRow", true, false) as Control).get_global_rect()
		_ok(row.end.y <= r.position.y and (p.find_child("SetList", true, false) as Control).get_global_rect().position.y >= r.end.y, "%s header row below PackRow, above SetList" % loc)
		var fr: Rect2 = p.get_frame_rect()
		_ok(p.text_fits() and Rect2(Vector2.ZERO, Vector2(_sub.size)).encloses(fr), "%s every label fits, frame %s on screen" % [loc, str(fr)])
		_tap("read_all")
		await _frames(3)
		_ok(absf(p.get_frame_rect().size.y - fr.size.y) <= 1.0, "%s frame height unchanged when READ ALL hides (%.0f -> %.0f)" % [loc, fr.size.y, p.get_frame_rect().size.y])
		_root.get_modal_stack().clear("test")
		await _frames(2)
	UiText.locale = "en"
	_complete("t12_layout_en_tr")

# ---------------------------------------------------------------- helpers ----

func _seed_new_cards(e) -> void:
	for c in NEW_CARDS:
		e.collection.add_card(c)

func _badge(p, n: int) -> String:
	var l: Label = p.find_child("Set_%d" % n, true, false).find_child("NewBadge", true, false)
	return l.text if l.visible else ""

func _visible_badges(p) -> int:
	return p.find_children("NewBadge", "", true, false).filter(func(l): return l.visible).size()

func _boot(tag: String, size := Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://sb_tf08_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	_root.get_modal_stack().clear("test")   # FTUE / ceremonies never sit over the cases
	await _frames(2)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _tap(id: String) -> void:
	var t = _top()
	if t != null:
		t._on_action(id)

func _frames(n: int) -> void:
	if _root != null and is_instance_valid(_root) and _root.get_home() != null:
		_root.get_home().refresh()
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
		for side in ["_analytics.json", "_cloud.json"]:
			var s: String = String(p).get_basename() + side
			if FileAccess.file_exists(s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(s))

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
	print("SB-TF-08 achievements order + collection read all evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
