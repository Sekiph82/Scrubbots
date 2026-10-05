extends SceneTree
## M43 master — Lane C005 meta ceremonies (SB-M43-068 onward; cases are added per child).
## Real AppState / EconomyServices / CollectionInventory / RewardGrantService / SaveService,
## real ModalStack + shipping MetaCeremonies + CeremonyPresenter, and the real app root
## (main.tscn) for the Home integration. Expected/completed case ledger.
##
## Run: godot --headless --path . -s res://tests/m43_master_c005_meta_ceremonies.gd

const AppState = preload("res://scripts/app/app_state.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const MetaUiState = preload("res://scripts/economy/meta_ui_state.gd")
const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const CeremonyPresenter = preload("res://scripts/ui/ceremony/ceremony_presenter.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")

const SIZE := Vector2i(1080, 1920)
## Presentation sources must never touch grant / spend / claim / progression authority.
const NO_AUTHORITY := ["grant(", ".claim(", "claim_", "add_card(", "credit(", "debit(", "add_copies(", "remove_copies(",
	".unlock(", "unlock_next_robot(", "set_active(", "record_win(", "exchange_", "open_standard(", "open_premium(", "commit_pack("]
const PRESENTATION_SOURCES := ["res://scripts/ui/ceremony/meta_ceremonies.gd", "res://scripts/ui/ceremony/ceremony_presenter.gd",
	"res://scripts/economy/ceremony_events.gd", "res://scripts/economy/meta_ui_state.gd"]

var EXPECTED_CASES := [
	"e01_meta_ui_strict", "e02_legacy_baseline", "e03_set_ceremony_truth", "e04_ack_once_reload",
	"e05_clear_not_acked", "e06_back_consumed", "e07_two_sets_order", "e08_reduced_same_truth",
	"e09_home_integration", "e10_no_authority_static",
	"e11_master_truth", "e12_master_once_order", "e13_master_legacy", "e14_master_reduced",
	"e15_roster_canonical", "e16_robot_ceremony_truth", "e17_equip_persists", "e18_keep_current",
	"e19_active_strict", "e20_unlock_next_order", "e21_unknown_robot_never_shown", "e22_robot_reduced",
	"e23_gift_queued_truth", "e24_gift_1000_fallback", "e25_gift_claimed_note", "e26_gift_all_five_once",
	"e27_results_handoff", "e28_results_no_event_no_hold",
	"e29_feature_builder_truth", "e30_feature_no_authority", "e31_world_builder_truth", "e32_world_no_authority",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack
var _root = null

func _initialize() -> void:
	await process_frame
	_mount()
	_e01_meta_ui_strict()
	_e02_legacy_baseline()
	await _e03_set_ceremony_truth()
	await _e04_ack_once_reload()
	await _e05_clear_not_acked()
	await _e06_back_consumed()
	await _e07_two_sets_order()
	await _e08_reduced_same_truth()
	await _e11_master_truth()
	await _e12_master_once_order()
	_e13_master_legacy()
	_e14_master_reduced()
	_e15_roster_canonical()
	await _e16_robot_ceremony_truth()
	await _e17_equip_persists()
	await _e18_keep_current()
	_e19_active_strict()
	_e20_unlock_next_order()
	await _e21_unknown_robot_never_shown()
	_e22_robot_reduced()
	_e29_feature_builder_truth()
	_e30_feature_no_authority()
	_e31_world_builder_truth()
	_e32_world_no_authority()
	await _e23_gift_queued_truth()
	_e24_gift_1000_fallback()
	await _e25_gift_claimed_note()
	await _e26_gift_all_five_once()
	_unmount()
	await _e09_home_integration()
	_e10_no_authority_static()
	await _e27_results_handoff()
	await _e28_results_no_event_no_hold()
	await _frames(3)
	_cleanup()
	_done()

# ------------------------------------------------------------------ SB-M43-068 ----

func _e01_meta_ui_strict() -> void:
	print("[e01 meta_ui section: present = strict, all-or-nothing]")
	var m := MetaUiState.new()
	m.mark_seen("set:3")
	var bad := [{}, {"version": 1}, {"seen": []}, {"version": 2, "seen": []}, {"version": 1, "seen": [""]},
		{"version": 1, "seen": ["a", "a"]}, {"version": 1, "seen": [3]}, {"version": 1, "seen": [], "x": 1},
		{"version": 1, "seen": "set:1"}, [], null, {"version": 1.5, "seen": []}]
	_ok(bad.all(func(v): return not m.import_snapshot(v)) and m.seen_keys() == ["set:3"], "12 malformed present sections rejected; state untouched")
	_ok(m.import_snapshot({"version": 1, "seen": ["master", "set:1"]}) and m.seen_keys() == ["master", "set:1"], "canonical section accepted")
	var app = _app("e01")
	var good: Dictionary = app.economy.snapshot()
	var live0 := _auth(app)
	var cand: Dictionary = good.duplicate(true)
	cand["meta_ui"] = {}
	_ok(not app.economy.import_snapshot(cand) and _auth(app) == live0, "economy import with present-empty meta_ui fails closed, live state unchanged")
	var save_cand = JSON.parse_string(FileAccess.get_file_as_string(app.save._path))
	save_cand["economy"]["meta_ui"] = {"version": 1}
	_ok(not app.save.validate_candidate(save_cand)["ok"], "SaveService rejects a candidate with malformed meta_ui")
	_complete("e01_meta_ui_strict")

func _e02_legacy_baseline() -> void:
	print("[e02 pre-ceremony save: committed events baselined as seen]")
	var app = _app("e02")
	_complete_set(app, 2)
	app.request_save()
	var path: String = app.save._path
	var cand = JSON.parse_string(FileAccess.get_file_as_string(path))
	cand["economy"].erase("meta_ui")
	_write(path, cand)
	var old = AppState.new(path)
	_ok(old.load_result["source"] == "primary" and old.economy.meta_ui.is_seen("set:2") and CeremonyEvents.pending(old.economy, old.economy.meta_ui).is_empty(), "legacy save loads; its completed set 2 is not replayed")
	_complete_set(old, 4)
	_ok(CeremonyEvents.pending(old.economy, old.economy.meta_ui).map(func(e): return e["key"]) == ["set:4"], "a NEW completion after load is pending")
	_complete("e02_legacy_baseline")

func _e03_set_ceremony_truth() -> void:
	print("[e03 set 9/9 ceremony shows the exact committed set + reward]")
	var app = _app("e03")
	var sb0: int = app.economy.wallet.scrub_bucks()
	_complete_set(app, 6)
	var cfg_row := _set_row(app, 6)
	var granted: int = app.economy.wallet.scrub_bucks() - sb0
	var pr = _presenter(app)
	var a0 := _auth(app)
	_ok(pr.drain("test"), "presenter opens the pending set ceremony")
	await _frames(2)
	var p = pr.current()
	var rows := _reward_rows(p)
	_ok(p.get_title() == UiText.t("CEREMONY_SET_TITLE") and _label(p, "SetName") == "Set 6 · %s" % cfg_row["name"] and _label(p, "Progress") == "9 / 9 cards", "title / set name / 9 / 9 from committed truth")
	_ok(rows == {"scrub_bucks": int(cfg_row["scrub_bucks"]), "bot_parts": int(cfg_row["bot_parts"])} and granted == int(cfg_row["scrub_bucks"]), "reward rows == config row == SB actually granted (%s)" % str(rows))
	var thumbs: Array = p.find_child("SetCards", true, false).get_children().map(func(t): return t.texture.resource_path)
	_ok(thumbs.size() == 9 and thumbs[0].ends_with("set_06/card_01.png") and thumbs[8].ends_with("set_06/card_09.png"), "nine canonical set-6 card arts")
	_ok(_auth(app) == a0, "presenting granted / saved nothing (economy + save bytes unchanged)")
	_close_cta(p)
	await _frames(2)
	_complete("e03_set_ceremony_truth")

func _e04_ack_once_reload() -> void:
	print("[e04 CTA acknowledges once; reload never replays]")
	var app = _app("e04")
	_complete_set(app, 5)
	var pr = _presenter(app)
	var acks: Array = []
	pr.ceremony_acknowledged.connect(func(k, _kind): acks.append(k))
	pr.drain("test")
	await _frames(2)
	var wallet0: Dictionary = app.economy.wallet.snapshot()
	_close_cta(pr.current())
	await _frames(2)
	_ok(acks == ["set:5"] and app.economy.meta_ui.is_seen("set:5") and not pr.is_presenting(), "acknowledged set:5 once, nothing else open")
	_ok(app.economy.wallet.snapshot() == wallet0, "acknowledging changed no wallet value")
	var re = AppState.new(app.save._path)
	var pr2 = _presenter(re)
	_ok(re.economy.meta_ui.is_seen("set:5") and not pr2.drain("reload") and pr2.pending().is_empty(), "after reload: seen persisted, nothing to present")
	_complete("e04_ack_once_reload")

func _e05_clear_not_acked() -> void:
	print("[e05 stack clear / route change never acknowledges]")
	var app = _app("e05")
	_complete_set(app, 7)
	var pr = _presenter(app)
	pr.drain("test")
	await _frames(2)
	_stack.clear("route_change")
	await _frames(2)
	_ok(not app.economy.meta_ui.is_seen("set:7") and pr.drain("again") and pr.current() != null, "cleared ceremony stays pending and is shown again")
	_close_cta(pr.current())
	await _frames(2)
	_complete("e05_clear_not_acked")

func _e06_back_consumed() -> void:
	print("[e06 Back is consumed, never dismisses]")
	var app = _app("e06")
	_complete_set(app, 8)
	var pr = _presenter(app)
	pr.drain("test")
	await _frames(2)
	var p = pr.current()
	_ok(_stack.handle_back() and p.is_open() and not app.economy.meta_ui.is_seen("set:8"), "Back consumed; ceremony still open; not acknowledged")
	_close_cta(p)
	await _frames(2)
	_complete("e06_back_consumed")

func _e07_two_sets_order() -> void:
	print("[e07 two completions -> two ceremonies, ascending]")
	var app = _app("e07")
	_complete_set(app, 9)
	_complete_set(app, 3)
	var pr = _presenter(app)
	var shown: Array = []
	pr.ceremony_shown.connect(func(k, _kind): shown.append(k))
	pr.drain("test")
	for _i in range(2):
		await _frames(2)
		if pr.current() != null:
			_close_cta(pr.current())
	await _frames(2)
	_ok(shown == ["set:3", "set:9"] and not pr.is_presenting(), "set 3 then set 9, one at a time %s" % str(shown))
	_complete("e07_two_sets_order")

func _e08_reduced_same_truth() -> void:
	print("[e08 Reduced Effects: same truth, no motion]")
	var ev := {"key": "set:1", "kind": "set_complete", "set": 1, "name": "Meet the Scrubbots", "rewards": {"scrub_bucks": 350, "bot_parts": 5}}
	var full = MetaCeremonies.build(ev, false)
	var red = MetaCeremonies.build(ev, true)
	_ok(_texts(full) == _texts(red), "identical labels FULL vs Reduced")
	_ok(full.find_child("HeroGlow", true, false).has_meta("spin") and not red.find_child("HeroGlow", true, false).has_meta("spin"), "glow turns only in FULL")
	full.free()
	red.free()
	_complete("e08_reduced_same_truth")

func _e09_home_integration() -> void:
	print("[e09 real app root: Home presents the pending ceremony]")
	var path := _uniq("e09")
	var seed = AppState.new(path)
	_complete_set(seed, 11)
	seed.request_save()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)
	var st = _root.get_modal_stack()
	var top = st.top()
	_ok(top != null and String(top.context.get("ceremony_key", "")) == "set:11", "Home opened the set-11 ceremony on the app ModalStack")
	if top != null:
		_close_cta(top)
	await _frames(6)
	_ok(st.depth() == 0 and _root.get_app_state().economy.meta_ui.is_seen("set:11"), "after CONTINUE: acknowledged and Home is clear")
	var re = AppState.new(path)
	_ok(re.economy.meta_ui.is_seen("set:11"), "acknowledgement durably saved through the canonical save")
	_root.free()
	_sub.free()
	_root = null
	_sub = null
	MainScript.boot_save_path_override = ""
	_complete("e09_home_integration")

func _e10_no_authority_static() -> void:
	print("[e10 presentation sources carry no grant authority]")
	var hits: Array = []
	for path in PRESENTATION_SOURCES:
		var src := _code_only(FileAccess.get_file_as_string(path))
		for w in NO_AUTHORITY:
			if src.contains(w):
				hits.append("%s:%s" % [path.get_file(), w])
	_ok(hits.is_empty(), "no grant / claim / spend / pack-open identifiers %s" % str(hits))
	_ok(_code_only("\tapp.economy.reward.grant(x)\n").contains("grant"), "sensitivity: an injected grant is visible to the scan")
	_complete("e10_no_authority_static")

# ------------------------------------------------------------------ SB-M43-069 ----

func _e11_master_truth() -> void:
	print("[e11 Master Collection ceremony = exact one-time +2500 SB +20 Bot Parts]")
	var app = _app("e11")
	for n in range(1, 15):
		_complete_set(app, n)
	var sb0: int = app.economy.wallet.scrub_bucks()
	var bp0: int = app.economy.wallet.bot_parts()
	_complete_set(app, 15)
	var cfg: Dictionary = app.economy.config.collection_config()["all_sets_complete"]
	var s15 := _set_row(app, 15)
	var master_ev: Array = CeremonyEvents.pending(app.economy, app.economy.meta_ui).filter(func(e): return e["kind"] == "master_complete")
	_ok(master_ev.size() == 1 and int(cfg["scrub_bucks"]) == 2500 and int(cfg["bot_parts"]) == 20, "one pending Master event; config = +2500 SB +20 Bot Parts")
	_ok(app.economy.wallet.scrub_bucks() - sb0 == int(s15["scrub_bucks"]) + 2500 and app.economy.wallet.bot_parts() - bp0 == int(s15["bot_parts"]) + 20, "real grant: last set reward + Master reward, once")
	var p = MetaCeremonies.build(master_ev[0], false)
	_stack.push(p)
	await _frames(2)
	_ok(p.get_title() == UiText.t("CEREMONY_MASTER_TITLE") and _label(p, "MasterProgress") == "All 15 sets complete" and _label(p, "OneTime") == UiText.t("CEREMONY_MASTER_ONCE"), "title / All 15 sets / one-time label")
	_ok(_reward_rows(p) == {"scrub_bucks": 2500, "bot_parts": 20}, "reward rows exactly +2500 SB +20 Bot Parts %s" % str(_reward_rows(p)))
	_close_cta(p)
	await _frames(2)
	_complete("e11_master_truth")

func _e12_master_once_order() -> void:
	print("[e12 15 sets then Master, each once; reload replays none]")
	var app = _app("e12")
	for n in range(1, 16):
		_complete_set(app, n)
	var pr = _presenter(app)
	var shown: Array = []
	pr.ceremony_shown.connect(func(k, _kind): shown.append(k))
	pr.drain("test")
	for _i in range(20):
		await _frames(1)
		if pr.current() != null:
			_close_cta(pr.current())
	await _frames(2)
	var want: Array = range(1, 16).map(func(n): return "set:%d" % n) + ["master"]
	_ok(shown == want, "16 ceremonies in order, Master last")
	_ok(app.economy.reward.snapshot()["applied"].count("collection_master") == 1, "Master grant applied exactly once (presenting never re-grants)")
	var re = AppState.new(app.save._path)
	_ok(CeremonyEvents.pending(re.economy, re.economy.meta_ui).is_empty(), "reload: nothing pending")
	_complete("e12_master_once_order")

func _e13_master_legacy() -> void:
	print("[e13 legacy save with Master already claimed: no replay]")
	var app = _app("e13")
	for n in range(1, 16):
		_complete_set(app, n)
	app.request_save()
	var cand = JSON.parse_string(FileAccess.get_file_as_string(app.save._path))
	cand["economy"].erase("meta_ui")
	_write(app.save._path, cand)
	var old = AppState.new(app.save._path)
	_ok(old.load_result["source"] == "primary" and old.economy.meta_ui.is_seen("master") and CeremonyEvents.pending(old.economy, old.economy.meta_ui).is_empty(), "Master + 15 sets baselined as seen")
	_complete("e13_master_legacy")

func _e14_master_reduced() -> void:
	print("[e14 Master Reduced: same truth, no motion]")
	var ev := {"key": "master", "kind": "master_complete", "sets": 15, "rewards": {"scrub_bucks": 2500, "bot_parts": 20}}
	var full = MetaCeremonies.build(ev, false)
	var red = MetaCeremonies.build(ev, true)
	_ok(_texts(full) == _texts(red) and not red.find_child("HeroGlow", true, false).has_meta("spin"), "identical labels; no glow turn in Reduced")
	full.free()
	red.free()
	_complete("e14_master_reduced")

# --------------------------------------------------------------- SB-M43-070/071 ----

func _e15_roster_canonical() -> void:
	print("[e15 canonical 10-robot roster == owner decision]")
	var r := RobotRoster.load_roster()
	var want := ["scrubby", "moppy", "bubbles", "spark", "squeegee", "dusty", "rinse", "polly", "clippy", "atlas"]
	_ok(r["ok"] and RobotRoster.ids() == want and r["unlock_cost"] == 250, "10 robots in owner order, cost 250")
	var md := FileAccess.get_file_as_string("res://coordination/OWNER_ROBOT_ROSTER_V01.md")
	var perk_ok := true
	for e in r["robots"]:
		var row := ""
		for line in md.split("\n"):
			var cells := line.split("|")
			if cells.size() >= 7 and cells[2].replace("*", "").strip_edges().to_lower() == String(e["id"]):
				row = cells[5].replace("*", "").strip_edges()
		perk_ok = perk_ok and row.begins_with(String(e["perk_name"]) + ":")
	_ok(perk_ok, "every perk name matches the owner table")
	var missing: Array = []
	for e in r["robots"]:
		for k in RobotRoster.ASSET_KEYS:
			if not ResourceLoader.exists(String(e["assets"][k])):
				missing.append("%s.%s" % [e["id"], k])
	_ok(missing.is_empty(), "every robot asset path exists %s" % str(missing))
	_ok(not RobotRoster.load_roster("res://data/config/__missing.json")["ok"], "missing roster fails closed")
	_complete("e15_roster_canonical")

func _e16_robot_ceremony_truth() -> void:
	print("[e16 Robot Unlock ceremony: canonical identity + live Bot Parts carryover]")
	var app = _app("e16")
	app.economy.wallet.credit(EconomyWallet.BOT_PARTS, 287)
	var r: Dictionary = app.actions.unlock_next_robot()
	_ok(r["ok"] and r["robot_id"] == "moppy" and app.economy.wallet.bot_parts() == 37, "unlock_next_robot spent exactly 250 (37 carry over)")
	var pr = _presenter(app)
	pr.drain("test")
	await _frames(2)
	var p = pr.current()
	var e := RobotRoster.entry("moppy")
	_ok(p != null and _label(p, "RobotName") == "MOPPY" and _label(p, "RobotRole") == e["role"] and _label(p, "PerkName") == e["perk_name"] and _label(p, "PerkText") == e["perk_text"], "name / role / perk from the canonical roster")
	_ok(p.find_child("HeroArt", true, false).texture.resource_path == e["assets"]["master"] and p.find_child("PerkIcon", true, false).texture.resource_path == e["perk_icon"], "canonical master art + perk icon")
	_ok(p.find_child("PartsLeft", true, false).get_node("Text").text == "Bot Parts left: 37", "Bot Parts carryover shown from the wallet")
	_ok(p.get_action_ids() == ["equip", "keep"] and p.get_action_button("equip").text == "EQUIP MOPPY", "EQUIP MOPPY / KEEP CURRENT")
	_close_cta(p)
	await _frames(2)
	_complete("e16_robot_ceremony_truth")

func _e17_equip_persists() -> void:
	print("[e17 EQUIP selects the new robot (persisted, spends nothing)]")
	var app = _app("e17")
	app.economy.wallet.credit(EconomyWallet.BOT_PARTS, 250)
	app.actions.unlock_next_robot()
	var pr = _presenter(app)
	pr.drain("test")
	await _frames(2)
	var parts0: int = app.economy.wallet.bot_parts()
	pr.current()._on_action("equip")
	await _frames(2)
	_ok(app.economy.robots.active_robot() == "moppy" and app.economy.wallet.bot_parts() == parts0 and app.economy.meta_ui.is_seen("robot:moppy"), "active = moppy, Bot Parts unchanged, ceremony acknowledged")
	var re = AppState.new(app.save._path)
	_ok(re.economy.robots.active_robot() == "moppy", "selection persisted through the canonical save")
	_complete("e17_equip_persists")

func _e18_keep_current() -> void:
	print("[e18 KEEP CURRENT changes nothing]")
	var app = _app("e18")
	app.economy.wallet.credit(EconomyWallet.BOT_PARTS, 250)
	app.actions.unlock_next_robot()
	var pr = _presenter(app)
	pr.drain("test")
	await _frames(2)
	pr.current()._on_action("keep")
	await _frames(2)
	_ok(app.economy.robots.active_robot() == "scrubby" and app.economy.meta_ui.is_seen("robot:moppy"), "still Scrubby; ceremony acknowledged")
	_complete("e18_keep_current")

func _e19_active_strict() -> void:
	print("[e19 active robot import: absent = initial, present must be unlocked]")
	var app = _app("e19")
	var good: Dictionary = app.economy.snapshot()
	var live0 := _auth(app)
	var bad := [["active", "moppy"], ["active", 3], ["active", ""]]
	var rejected := 0
	for b in bad:
		var c: Dictionary = good.duplicate(true)
		c["robots"][b[0]] = b[1]
		if not app.economy.import_snapshot(c) and _auth(app) == live0:
			rejected += 1
	var legacy: Dictionary = good.duplicate(true)
	legacy["robots"].erase("active")
	_ok(rejected == 3 and app.economy.import_snapshot(legacy) and app.economy.robots.active_robot() == "scrubby", "locked / non-string / empty active rejected; absent -> Scrubby")
	_ok(not app.economy.robots.set_active("atlas")["ok"] and app.economy.robots.active_robot() == "scrubby", "equipping a locked robot refused")
	_complete("e19_active_strict")

func _e20_unlock_next_order() -> void:
	print("[e20 unlock_next_robot follows canonical order; refuses without parts]")
	var app = _app("e20")
	var got: Array = []
	_ok(not app.actions.unlock_next_robot()["ok"] and app.economy.robots.unlocked_count() == 1, "0 Bot Parts: refused, nothing unlocked")
	for _i in range(9):
		app.economy.wallet.credit(EconomyWallet.BOT_PARTS, 250)
		got.append(app.actions.unlock_next_robot()["robot_id"])
	app.economy.wallet.credit(EconomyWallet.BOT_PARTS, 250)
	var last: Dictionary = app.actions.unlock_next_robot()
	_ok(got == RobotRoster.ids().slice(1) and not last["ok"] and last["reason"] == "all_unlocked" and app.economy.wallet.bot_parts() == 250, "moppy..atlas in order, then all_unlocked with no spend")
	_complete("e20_unlock_next_order")

func _e21_unknown_robot_never_shown() -> void:
	print("[e21 a non-roster robot id is never presented (nothing fabricated)]")
	var app = _app("e21")
	app.economy.wallet.credit(EconomyWallet.BOT_PARTS, 250)
	app.economy.robots.unlock("robot_2")
	var pr = _presenter(app)
	_ok(not pr.drain("test") and pr.pending().is_empty() and not app.economy.meta_ui.is_seen("robot:robot_2"), "no ceremony, event left pending (not dropped)")
	_complete("e21_unknown_robot_never_shown")

func _e22_robot_reduced() -> void:
	print("[e22 Robot Unlock Reduced: same truth, no motion]")
	var ev := {"key": "robot:atlas", "kind": "robot_unlock", "robot_id": "atlas", "parts_left": 12}
	var full = MetaCeremonies.build(ev, false)
	var red = MetaCeremonies.build(ev, true)
	_ok(_texts(full) == _texts(red) and full.find_child("HeroGlow", true, false).texture.resource_path.ends_with("robot_unlocked_burst.png") and not red.find_child("HeroGlow", true, false).has_meta("spin"), "identical labels; unlocked burst; no motion in Reduced")
	full.free()
	red.free()
	_complete("e22_robot_reduced")

# ------------------------------------------------------------------- SB-M43-074 ----

func _e23_gift_queued_truth() -> void:
	print("[e23 Gift milestone 10: exact queued bundle, claimed later in the Gift Bar]")
	var app = _app("e23")
	var newly: Array = app.economy.gift.add_streak_sb("e23_tx", 10)
	app.request_save()
	var a0 := _auth(app)
	var pr = _presenter(app)
	_ok(newly.size() == 1 and pr.drain("test"), "real Gift Meter crossing queued m10; ceremony opened")
	await _frames(2)
	var p = pr.current()
	_ok(p.get_title() == "GIFT METER 10!" and _label(p, "Milestone") == "Milestone 10 / 1,000", "title + milestone / cycle max")
	_ok(_reward_rows(p) == {"bot_parts": 1, "standard_card_packs": 1} and _label(p, "ClaimNote") == "Ready to claim in the Gift Bar.", "rows == config m10 bundle; claim-in-Gift-Bar copy")
	_ok(_auth(app) == a0 and app.economy.gift.claimable().size() == 1, "presenting granted nothing; occurrence still claimable")
	_close_cta(p)
	await _frames(2)
	_ok(app.economy.gift.claimable().size() == 1 and app.economy.meta_ui.is_seen("gift:" + String(newly[0]["id"])), "CONTINUE acknowledged only; reward still waits in the Gift Bar")
	_complete("e23_gift_queued_truth")

func _e24_gift_1000_fallback() -> void:
	print("[e24 Gift 1000: crate hero, fallback is a condition, not a reward]")
	var app = _app("e24")
	app.economy.gift.add_streak_sb("e24_tx", 1000)
	var ev: Array = CeremonyEvents.events(app.economy).filter(func(e): return e["kind"] == "gift_milestone" and e["milestone"] == 1000)
	var p = MetaCeremonies.build(ev[0], false)
	var rows := _reward_rows(p)
	_ok(p.find_child("HeroArt", true, false).texture.resource_path.ends_with("gift_meter_reward_crate.png"), "1000 uses the Gift Meter crate")
	_ok(rows == {"scrub_bucks": 500, "bot_parts": 4, "premium_card_packs": 1, "selected_booster_charges": 2, "guaranteed_new_cards": 1} and not rows.has("guaranteed_new_fallback_sb"), "rows == config bundle without the fallback %s" % str(rows))
	_ok(_label(p, "FallbackNote").contains("500 Scrub Bucks"), "fallback shown as its condition")
	p.free()
	_complete("e24_gift_1000_fallback")

func _e25_gift_claimed_note() -> void:
	print("[e25 already-claimed occurrence: honest copy, presenting never re-grants]")
	var app = _app("e25")
	var occ: Array = app.economy.gift.add_streak_sb("e25_tx", 50)
	var id50 := ""
	for o in occ:
		if int(o["milestone"]) == 50:
			id50 = String(o["id"])
	app.actions.claim_gift(id50)
	var a0 := _auth(app)
	var ev: Array = CeremonyEvents.events(app.economy).filter(func(e): return e["occurrence_id"] == id50)
	var p = MetaCeremonies.build(ev[0], false)
	_ok(_label(p, "ClaimNote") == "Already claimed from the Gift Bar." and _auth(app) == a0, "claimed copy; no authority change")
	p.free()
	_ok(app.economy.reward.snapshot()["applied"].count(id50) == 1, "the claim granted exactly once")
	_complete("e25_gift_claimed_note")

func _e26_gift_all_five_once() -> void:
	print("[e26 one big feed crosses 10/50/250/500/1000 -> five ceremonies once]")
	var app = _app("e26")
	app.economy.gift.add_streak_sb("e26_tx", 1000)
	var pr = _presenter(app)
	var shown: Array = []
	pr.ceremony_shown.connect(func(k, _kind): shown.append(k))
	pr.drain("test")
	for _i in range(8):
		await _frames(1)
		if pr.current() != null:
			_close_cta(pr.current())
	await _frames(2)
	_ok(shown == [10, 50, 250, 500, 1000].map(func(m): return "gift:gift_ms:c0:m%d" % m), "milestone order, each once %s" % str(shown))
	var re = AppState.new(app.save._path)
	_ok(CeremonyEvents.pending(re.economy, re.economy.meta_ui).is_empty() and re.economy.gift.claimable().size() == 5, "reload: none pending; all five still claimable in the Gift Bar")
	_complete("e26_gift_all_five_once")

# ------------------------------------------------------------------- SB-M43-013 ----

## Real app root: frontier level 1, a real WON terminal (host economy + save first). With the
## Gift Meter seeded at 9 through the real authority, the win's streak SB crosses milestone 10.
func _won_results(tag: String, seed_gift: int):
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := _uniq(tag)
	var seed = AppState.new(path)
	if seed_gift > 0:
		seed.economy.gift.add_streak_sb(tag + "_seed", seed_gift)
	seed.request_save()
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	_root.play_current_frontier()
	await _frames(4)
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)
	h.get_completion().terminal_reached.emit(&"WON", {})
	await _frames(2)
	return h

func _end_app() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _e27_results_handoff() -> void:
	print("[e27 WON Results hands off to the committed Gift milestone ceremony]")
	var h = await _won_results("e27", 9)
	var res = _root.get_results_screen()
	var receipt: Dictionary = h.get_terminal_receipt()
	var follow: Array = receipt.get("follow_ups", []).map(func(f): return f["kind"])
	_ok(_root.get_navigation().route_name() == "RESULTS" and follow.has("gift_milestone"), "real WON committed; receipt follow-up = gift_milestone")
	_ok(res.has_ceremony_barrier() and res.get_primary_button().disabled and not res.get_next_cleanup_panel().visible, "ceremony barrier holds CLEAN NEXT + teaser")
	var a0: Dictionary = _root.get_app_state().economy.snapshot()
	res.finish_reveal()
	var top = null
	for _i in range(20):
		await _frames(1)
		top = _root.get_modal_stack().top()
		if top != null:
			break
	_ok(top != null and String(top.context.get("ceremony_key", "")) == "gift:gift_ms:c0:m10" and h.get_terminal_receipt() == receipt, "after the reward reveal: Gift 10 ceremony on top; receipt unchanged")
	var a1: Dictionary = _root.get_app_state().economy.snapshot()
	_ok(a1["reward"] == a0["reward"] and a1["gift"] == a0["gift"] and a1["collection"] == a0["collection"], "presenting granted nothing (wallet / applied ids / Gift / Collection unchanged)")
	_close_cta(top)
	await _frames(4)
	_ok(not res.has_ceremony_barrier() and not res.get_primary_button().disabled and res.get_next_cleanup_panel().visible, "barrier released: CLEAN NEXT + teaser back")
	_ok(_root.get_app_state().economy.meta_ui.is_seen("gift:gift_ms:c0:m10") and _root.get_app_state().economy.gift.claimable().size() == 1, "acknowledged; reward still waits in the Gift Bar")
	_end_app()
	_complete("e27_results_handoff")

func _e28_results_no_event_no_hold() -> void:
	print("[e28 WON with no ceremony event: no hold]")
	var h = await _won_results("e28", 0)
	var res = _root.get_results_screen()
	res.finish_reveal()
	await _frames(4)
	_ok(not res.has_ceremony_barrier() and _root.get_modal_stack().depth() == 0 and not res.get_primary_button().disabled, "no barrier, no popup, CLEAN NEXT live")
	_end_app()
	_complete("e28_results_no_event_no_hold")

# --------------------------------------------------------------- SB-M43-072/073 ----

func _e29_feature_builder_truth() -> void:
	print("[e29 Feature Unlock builder: owner-accepted shell, explicit event only]")
	var ev := {"key": "feature:cards_exchange", "kind": "feature_unlock", "feature_id": "cards_exchange", "name": "CARDS EXCHANGE",
		"body": "Trade extra card copies for Scrub Bucks.", "icon": "res://assets/ui/final/home/shortcuts/icon_shortcut_cards_exchange.png"}
	var p = MetaCeremonies.build(ev, false)
	var r = MetaCeremonies.build(ev, true)
	_ok(p != null and p.get_title() == "NEW FEATURE!" and _label(p, "FeatureName") == "CARDS EXCHANGE" and p.find_child("NewBadge", true, false) != null and p.get_action_ids() == ["got_it"], "title / name / NEW badge / GOT IT")
	_ok(_texts(p) == _texts(r) and not r.find_child("HeroGlow", true, false).has_meta("spin"), "Reduced: same labels, no motion")
	var bad := [{"kind": "feature_unlock", "name": "", "icon": ev["icon"]}, {"kind": "feature_unlock", "name": "X", "icon": "res://nope.png"}]
	_ok(bad.all(func(b): return MetaCeremonies.build(b, false) == null), "no name / missing icon -> no ceremony (nothing invented)")
	p.free()
	r.free()
	_complete("e29_feature_builder_truth")

func _e30_feature_no_authority() -> void:
	print("[e30 no feature-unlock authority: no event is ever derived]")
	var app = _app("e30")
	_complete_set(app, 1)
	_ok(not CeremonyEvents.events(app.economy).any(func(e): return e["kind"] == "feature_unlock" or e["kind"] == "world_unlock"), "CeremonyEvents emits no feature/world events")
	_complete("e30_feature_no_authority")

func _e31_world_builder_truth() -> void:
	print("[e31 World Transition builder: real registry art only]")
	var ev := {"key": "world:world_01", "kind": "world_unlock", "world_id": "world_01", "title": "WHISPERING PARK", "subtitle": "World 01",
		"art": "res://assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png"}
	var p = MetaCeremonies.build(ev, false)
	_ok(p != null and p.get_title() == "WHISPERING PARK" and p.find_child("WorldArt", true, false).texture.resource_path == ev["art"] and _label(p, "WorldSubtitle") == "World 01", "title / art / subtitle from the entry")
	_ok(MetaCeremonies.build({"kind": "world_unlock", "title": "", "art": ev["art"]}, false) == null and MetaCeremonies.build({"kind": "world_unlock", "title": "X", "art": "res://none.png"}, false) == null, "no title / missing art -> no ceremony")
	p.free()
	_complete("e31_world_builder_truth")

func _e32_world_no_authority() -> void:
	print("[e32 world builder never touches progression]")
	var src := _code_only(FileAccess.get_file_as_string("res://scripts/ui/ceremony/meta_ceremonies.gd"))
	_ok(RegEx.create_from_string("\\bprogression\\.|current_level\\(|record_win\\(|class_for\\(|difficulty\\.").search(src) == null, "ceremony source calls no progression / difficulty API")
	_complete("e32_world_no_authority")

# ------------------------------------------------------------------ helpers ----

func _app(tag: String):
	var app = AppState.new(_uniq(tag))
	app.request_save()
	return app

## Complete Collection set n through the REAL authority (add_card -> set reward exactly once).
func _complete_set(app, n: int) -> void:
	for k in range(9):
		var cid := "s%d_c%d" % [n, k]
		if app.economy.collection.owned(cid) == 0:
			app.economy.collection.add_card(cid)

func _set_row(app, n: int) -> Dictionary:
	for e in app.economy.config.collection_config()["set_rewards"]:
		if int(e["set"]) == n:
			return e
	return {}

func _presenter(app):
	var pr = CeremonyPresenter.new()
	pr.bind(_stack, app)
	return pr

func _reward_rows(p) -> Dictionary:
	var out := {}
	var rows = p.find_child("RewardRows", true, false)
	if rows != null:
		for r in rows.get_children():
			out[String(r.get_meta("reward_key"))] = int(r.get_meta("amount"))
	return out

func _label(p, n: String) -> String:
	var l = p.find_child(n, true, false)
	return l.text if l is Label else ""

func _texts(p) -> Array:
	return p.find_children("*", "Label", true, false).map(func(l): return l.text)

func _close_cta(p) -> void:
	if p != null and is_instance_valid(p):
		p._on_action(p.get_action_ids()[0])

func _auth(app) -> Dictionary:
	var s: Dictionary = app.economy.snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	return {"econ": s, "save": FileAccess.get_file_as_bytes(app.save._path)}

func _write(path: String, data) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()

func _mount() -> void:
	_sub = SubViewport.new()
	_sub.size = SIZE
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_stack = ModalStack.new()
	_sub.add_child(_stack)

func _unmount() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_sub = null

func _code_only(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var i := line.find("#")
		out.append(line if i == -1 else line.substr(0, i))
	return "\n".join(out)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _uniq(tag: String) -> String:
	var p := "user://m43master_c005_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M43 master C005 meta ceremonies evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
