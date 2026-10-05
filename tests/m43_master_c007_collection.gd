extends SceneTree
## M43 master — Lane C007 Collection / Cards Exchange (SB-M43-090..101).
## Real app root + real CollectionInventory / CardsExchangeService / RewardGrantService / facade / save.
##
## Run: godot --headless --path . -s res://tests/m43_master_c007_collection.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")
const HomeScreen = preload("res://scripts/ui/home/home_screen.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := [
	"k01_home_opens_album", "k02_album_truth", "k03_set_detail_states", "k04_card_detail_exchange_one",
	"k05_exchange_all_extras", "k06_cancel_changes_nothing", "k07_rapid_taps_single_exchange", "k08_values_table",
	"k09_no_art_leak_unowned", "k10_135_card_performance_touch", "k11_legacy_no_new_flood", "k12_exchange_inside_collection",
	"k13_pity_copy_only_when_due",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	await _k01()
	await _k02()
	await _k03()
	await _k04()
	await _k05()
	await _k06()
	await _k07()
	_k08()
	await _k09()
	await _k10()
	_k11()
	_k12()
	await _k13()
	_shutdown()
	_cleanup()
	_done()

func _k01() -> void:
	print("[k01 Home COLLECTION panel opens the album]")
	await _boot("k01")
	(_root.get_home().get_region("Shortcut_collection") as Button).pressed.emit()
	await _frames(2)
	_ok(_top_id() == "collection" and _top().find_child("Sets", true, false).get_child_count() == 16, "album with 15 set rows + Master row")
	_ok(_txt("Summary") == "0 / 135 cards · 0 / 15 sets complete", "fresh summary from the inventory")
	_complete("k01_home_opens_album")

func _k02() -> void:
	print("[k02 set progress, rarity burden, exact set reward + claim state]")
	await _boot("k02")
	var e = _eco()
	_complete_set(3)
	e.collection.add_card("s5_c0")
	e.collection.add_card("s5_c0")
	e.collection.add_card("s5_c7")
	var p = CollectionScreen.open_album(_root.get_modal_stack(), _root.get_app_state())
	await _frames(2)
	var s3 = p.find_child("Set_3", true, false)
	var s5 = p.find_child("Set_5", true, false)
	var r3 := _cfg_row(3)
	_ok(_lbl(s3, "Progress") == "9 / 9 cards" and _lbl(s3, "Reward") == "Set reward: +%s SB +%s Bot Parts  · CLAIMED" % [UiText.num(int(r3["scrub_bucks"])), UiText.num(int(r3["bot_parts"]))], "set 3: 9/9, exact config reward, CLAIMED")
	_ok(_lbl(s5, "Progress") == "2 / 9 cards" and _lbl(s5, "Reward").ends_with("· on completion"), "set 5: 2/9, reward not yet claimed")
	_ok(_lbl(s5, "Burden") == _burden(5), "rarity burden shown (%s)" % _lbl(s5, "Burden"))
	_ok(_txt("Summary") == "11 / 135 cards · 1 / 15 sets complete" and _lbl(p.find_child("MasterRow", true, false), "MasterText").contains("+2,500 SB +20 Bot Parts"), "summary + Master reward visible")
	_complete("k02_album_truth")

func _k03() -> void:
	print("[k03 set detail: owned / NEW / EXTRAS / not found; viewing clears NEW durably]")
	await _boot("k03")
	var e = _eco()
	e.collection.add_card("s2_c0")
	e.collection.add_card("s2_c0")
	e.collection.add_card("s2_c0")
	e.collection.add_card("s2_c4")
	_ok(CollectionScreen.unseen_cards(e) == ["s2_c0", "s2_c4"], "two owned cards not yet viewed")
	var p = CollectionScreen.open_set(_root.get_modal_stack(), _root.get_app_state(), 2)
	await _frames(2)
	var t0 = p.find_child("Tile_s2_c0", true, false)
	var t4 = p.find_child("Tile_s2_c4", true, false)
	var t1 = p.find_child("Tile_s2_c1", true, false)
	_ok(p.find_child("Cards", true, false).get_child_count() == 9 and _lbl(t0, "Name") == CollectionCardCatalog.entry("s2_c0")["name"] and _lbl(t0, "Count") == "Owned x3", "9 slots; owned card name + count")
	_ok(p.get_meta("newly_seen") == ["s2_c0", "s2_c4"] and e.meta_ui.is_seen("card:s2_c0"), "viewing marked both owned cards seen")
	_ok(_root.get_app_state().is_dirty(), "viewing only marks the canonical save dirty (no write per view)")
	_root.flush_lifecycle("application_paused")
	var re = AppState.new(MainScript.boot_save_path_override)
	_ok(re.economy.meta_ui.is_seen("card:s2_c4"), "seen marks persisted at the lifecycle flush")
	_ok(_lbl(t1, "Name") == UiText.t("COLLECTION_NOT_FOUND") and _lbl(t1, "Count") == "" and t1.find_child("Rarity", true, false).visible, "unowned: 'Not found yet', rarity still shown")
	p.close("test")
	await _frames(1)
	var p2 = CollectionScreen.open_set(_root.get_modal_stack(), _root.get_app_state(), 2)
	await _frames(2)
	var st0 = p2.find_child("Tile_s2_c0", true, false).find_child("State", true, false)
	var st4 = p2.find_child("Tile_s2_c4", true, false).find_child("State", true, false)
	_ok(st0.visible and st0.get_node("Text").text == "EXTRAS x2" and not st4.visible, "reopened: no NEW; 3 copies -> EXTRAS x2; single copy no badge")
	_complete("k03_set_detail_states")

func _k04() -> void:
	print("[k04 card detail: protected first copy; EXCHANGE 1 through the facade]")
	await _boot("k04")
	var e = _eco()
	for _i in range(3):
		e.collection.add_card("s1_c0")
	var p = CollectionScreen.open_card(_root.get_modal_stack(), _root.get_app_state(), "s1_c0")
	await _frames(2)
	_ok(_lbl(p, "Owned") == "Owned x3" and _lbl(p, "Extras") == "EXTRAS x2" and _lbl(p, "Value") == "25 SB per extra copy" and p.get_action_button("ex_all").text == "EXCHANGE 2 · 50 SB", "owned / extras / live value / button")
	var sb0: int = e.wallet.scrub_bucks()
	p._on_action("ex_one")
	await _frames(1)
	_tap("confirm")
	await _frames(2)
	_ok(e.wallet.scrub_bucks() == sb0 + 25 and e.collection.owned("s1_c0") == 2 and _top_id() == "feedback_success", "+25 SB, owned 3 -> 2, committed feedback")
	_top().close("test")
	await create_timer(0.5).timeout   # double-tap guard (rearm_soon) elapses
	p._on_action("ex_all")
	await _frames(1)
	_tap("confirm")
	await _frames(2)
	_top().close("test")
	await create_timer(0.5).timeout
	_ok(e.collection.owned("s1_c0") == 1 and p.get_action_button("ex_one").disabled and _lbl(p, "Extras") == UiText.t("COLLECTION_NO_EXTRAS"), "protected floor 1: nothing left to exchange, buttons blocked")
	var re = AppState.new(MainScript.boot_save_path_override)
	_ok(re.economy.collection.owned("s1_c0") == 1 and re.economy.wallet.scrub_bucks() == sb0 + 50, "committed through the canonical save")
	_complete("k04_card_detail_exchange_one")

func _k05() -> void:
	print("[k05 EXCHANGE ALL EXTRAS: total, atomic, empty state after]")
	await _boot("k05")
	var e = _eco()
	for cid in ["s1_c0", "s1_c0", "s1_c5", "s1_c5", "s1_c5", "s9_c8", "s9_c8"]:
		e.collection.add_card(cid)
	var want: int = 25 * 1 + int(e.exchange.card_value("s1_c5")) * 2 + int(e.exchange.card_value("s9_c8")) * 1
	var p = CollectionScreen.open_exchange(_root.get_modal_stack(), _root.get_app_state())
	await _frames(2)
	_ok(_lbl(p, "Total") == "Total: %s SB" % UiText.num(want) and p.find_child("Extras", true, false).get_child_count() == 3, "3 cards with extras; total %d" % want)
	var sb0: int = e.wallet.scrub_bucks()
	p._on_action("ex_all_extras")
	await _frames(1)
	_tap("confirm")
	await _frames(2)
	_top().close("test")
	await _frames(2)
	_ok(e.wallet.scrub_bucks() == sb0 + want and e.collection.owned("s1_c5") == 1 and e.collection.owned("s9_c8") == 1, "+total SB once, every first copy kept")
	_ok(p.find_child("Empty", true, false) != null and p.get_action_button("ex_all_extras").disabled, "empty state; button blocked")
	_complete("k05_exchange_all_extras")

func _k06() -> void:
	print("[k06 cancel changes nothing]")
	await _boot("k06")
	var e = _eco()
	e.collection.add_card("s4_c0")
	e.collection.add_card("s4_c0")
	var p = CollectionScreen.open_card(_root.get_modal_stack(), _root.get_app_state(), "s4_c0")
	await _frames(2)
	var sb0: int = e.wallet.scrub_bucks()
	p._on_action("ex_one")
	await _frames(1)
	_tap("cancel")
	await create_timer(0.5).timeout
	_ok(e.wallet.scrub_bucks() == sb0 and e.collection.owned("s4_c0") == 2 and _top() == p and not p.is_latched(), "nothing spent or removed; card detail usable")
	_complete("k06_cancel_changes_nothing")

func _k07() -> void:
	print("[k07 rapid taps: one exchange]")
	await _boot("k07")
	var e = _eco()
	for _i in range(4):
		e.collection.add_card("s6_c0")
	var p = CollectionScreen.open_card(_root.get_modal_stack(), _root.get_app_state(), "s6_c0")
	await _frames(2)
	for _i in range(5):
		p._on_action("ex_one")
	await _frames(1)
	_ok(_root.get_modal_stack().ids().count("collection_confirm") == 1, "one confirm for 5 taps")
	for _i in range(5):
		_tap("confirm")
	await _frames(2)
	_ok(e.collection.owned("s6_c0") == 3, "exactly one copy exchanged")
	_complete("k07_rapid_taps_single_exchange")

func _k08() -> void:
	print("[k08 exchange values = owner config 25 / 75 / 200 / 500]")
	var app = AppState.new(_uniq("k08"))
	var got := {}
	for cid in ["s1_c0", "s1_c4", "s1_c6", "s1_c8"]:
		got[app.economy.collection.card_rarity(cid)] = int(app.economy.exchange.card_value(cid))
	_ok(got == {"COMMON": 25, "RARE": 75, "EPIC": 200, "LEGENDARY": 500}, "values %s" % str(got))
	_complete("k08_values_table")

func _k09() -> void:
	print("[k09 unowned cards never leak art or names]")
	await _boot("k09")
	var p = CollectionScreen.open_set(_root.get_modal_stack(), _root.get_app_state(), 12)
	await _frames(2)
	var leak: Array = []
	for k in range(9):
		var t = p.find_child("Tile_s12_c%d" % k, true, false)
		if t.find_child("CardArt", true, false).texture.resource_path != CollectionScreen.ART["silhouette"] or _lbl(t, "Name") != UiText.t("COLLECTION_NOT_FOUND"):
			leak.append(k)
	_ok(leak.is_empty() and p.get_action_ids() == ["back"], "9 silhouettes, no names, no detail action %s" % str(leak))
	_ok(CollectionScreen.open_card(_root.get_modal_stack(), _root.get_app_state(), "s12_c3") == null, "card detail refused for an unowned card")
	_complete("k09_no_art_leak_unowned")

func _k10() -> void:
	print("[k10 135-card browse performance + touch targets]")
	await _boot("k10")
	var e = _eco()
	for cid in e.collection.all_card_ids():
		for _i in range(3):
			e.collection.add_card(cid)
	var t0 := Time.get_ticks_msec()
	var album = CollectionScreen.open_album(_root.get_modal_stack(), _root.get_app_state())
	await _frames(1)
	var max_nodes := 0
	var worst := [0, 0]   ## [cold pass (first texture loads), warm pass] microseconds
	for pass_i in range(2):
		for n in range(1, 16):
			var tb := Time.get_ticks_usec()
			var s = CollectionScreen.open_set(_root.get_modal_stack(), _root.get_app_state(), n)
			worst[pass_i] = maxi(worst[pass_i], Time.get_ticks_usec() - tb)
			await _frames(1)
			max_nodes = maxi(max_nodes, s.find_children("*", "", true, false).size())
			s.close("test")
			await _frames(1)
	var worst_us: int = worst[1]
	var ms := Time.get_ticks_msec() - t0
	var small: Array = []
	for b in album.find_children("*", "Button", true, false):
		if b.is_visible_in_tree() and b.size.y < 64.0:
			small.append(b.name)
	_ok(worst_us < 150000 and max_nodes < 400, "set-detail build: cold %d us (first card-art loads), warm %d us (budget 150 ms); peak nodes %d; 30 opens incl. app frame pacing %d ms" % [worst[0], worst_us, max_nodes, ms])
	_ok(small.is_empty() and album.find_child("SetList", true, false) is ScrollContainer, "touch targets >= 64 px; album scrolls %s" % str(small))
	var ex = CollectionScreen.open_exchange(_root.get_modal_stack(), _root.get_app_state())
	await _frames(1)
	_ok(ex.find_child("Extras", true, false).get_child_count() == 135, "duplicate-heavy inventory: 135 exchange rows")
	_complete("k10_135_card_performance_touch")

func _k11() -> void:
	print("[k11 old save: owned cards are not flagged NEW]")
	var path := _uniq("k11")
	var app = AppState.new(path)
	app.economy.collection.add_card("s7_c2")
	app.request_save()
	var cand = JSON.parse_string(FileAccess.get_file_as_string(path))
	cand["economy"].erase("meta_ui")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(cand))
	f.close()
	var old = AppState.new(path)
	_ok(old.load_result["source"] == "primary" and CollectionScreen.unseen_cards(old.economy).is_empty(), "baseline marks owned cards viewed")
	_complete("k11_legacy_no_new_flood")

func _k12() -> void:
	print("[k12 Cards Exchange lives inside Collection, not on Home]")
	var ids: Array = (HomeScreen.LEFT_SHORTCUTS + HomeScreen.RIGHT_SHORTCUTS).map(func(s): return s[0])
	var src := FileAccess.get_file_as_string("res://scripts/ui/collection/collection_screen.gd")
	_ok(not ids.has("cards_exchange") and src.contains("static func open_exchange") and not src.contains("remove_copies(") and not src.contains("wallet."), "no Home exchange shortcut; exchange opened from the album; UI never edits counts/balances")
	_complete("k12_exchange_inside_collection")

func _k13() -> void:
	print("[k13 NEW CARD GUARANTEED NEXT PACK only when a configured guarantee is due]")
	await _boot("k13")
	var e = _eco()
	var p = CollectionScreen.open_album(_root.get_modal_stack(), _root.get_app_state())
	await _frames(1)
	var off: bool = not _txt("Summary").contains(UiText.t("COLLECTION_PITY_NEXT"))
	p.close("test")
	await _frames(1)
	e.pack_pity.threshold_override = 1   # test seam only
	e.pack_pity.on_opened(false)
	p = CollectionScreen.open_album(_root.get_modal_stack(), _root.get_app_state())
	await _frames(1)
	_ok(off and _txt("Summary").contains(UiText.t("COLLECTION_PITY_NEXT")), "absent with the shipped (no) threshold; stated when due")
	_complete("k13_pity_copy_only_when_due")

# ------------------------------------------------------------------ helpers ----

func _complete_set(n: int) -> void:
	for k in range(9):
		var cid := "s%d_c%d" % [n, k]
		if _eco().collection.owned(cid) == 0:
			_eco().collection.add_card(cid)

func _cfg_row(n: int) -> Dictionary:
	for r in _eco().config.collection_config()["set_rewards"]:
		if int(r["set"]) == n:
			return r
	return {}

func _burden(n: int) -> String:
	var b := {}
	for k in range(9):
		var cid := "s%d_c%d" % [n, k]
		var r: String = _eco().collection.card_rarity(cid)
		var x: Array = b.get(r, [0, 0])
		x[1] += 1
		if _eco().collection.owned(cid) > 0:
			x[0] += 1
		b[r] = x
	var parts: Array = []
	for r in ["COMMON", "RARE", "EPIC", "LEGENDARY"]:
		if b.has(r):
			parts.append("%s %d/%d" % [r.substr(0, 1), b[r][0], b[r][1]])
	return " · ".join(parts)

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := _uniq(tag)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _eco():
	return _root.get_app_state().economy

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _tap(id: String) -> void:
	var t = _top()
	if t != null:
		t._on_action(id)

func _txt(n: String) -> String:
	var l = _top().find_child(n, true, false)
	return l.text if l is Label else ""

func _lbl(node: Node, n: String) -> String:
	var l = node.find_child(n, true, false)
	return l.text if l is Label else ""

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _uniq(tag: String) -> String:
	var p := "user://m43master_c007_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
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
	print("M43 master C007 Collection evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
