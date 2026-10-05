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

const SIZE := Vector2i(1080, 1920)
## Presentation sources must never touch grant / spend / claim / progression authority.
const NO_AUTHORITY := ["grant(", ".claim(", "claim_", "add_card(", "credit(", "debit(", "add_copies(", "remove_copies(",
	"unlock(", "record_win(", "exchange_", "open_standard(", "open_premium(", "commit_pack(", "wallet."]
const PRESENTATION_SOURCES := ["res://scripts/ui/ceremony/meta_ceremonies.gd", "res://scripts/ui/ceremony/ceremony_presenter.gd",
	"res://scripts/economy/ceremony_events.gd", "res://scripts/economy/meta_ui_state.gd"]

var EXPECTED_CASES := [
	"e01_meta_ui_strict", "e02_legacy_baseline", "e03_set_ceremony_truth", "e04_ack_once_reload",
	"e05_clear_not_acked", "e06_back_consumed", "e07_two_sets_order", "e08_reduced_same_truth",
	"e09_home_integration", "e10_no_authority_static",
	"e11_master_truth", "e12_master_once_order", "e13_master_legacy", "e14_master_reduced",
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
	_unmount()
	await _e09_home_integration()
	_e10_no_authority_static()
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
