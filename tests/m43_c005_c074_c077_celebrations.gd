extends SceneTree
## M43 C005 — SB-M43-074 Gift milestone, SB-M43-075 Daily cycle + 3/3 Tasks celebrations,
## SB-M43-077 Reduced Effects equivalence (same labels / grants, no motion). Real AppState /
## EconomyServices / ProductionActionFacade / ModalStack / MetaCeremonies / CeremonyPresenter /
## DailyScreens; injected clock + local day, temp saves only.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c074_c077_celebrations.gd

const AppState = preload("res://scripts/app/app_state.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const CeremonyPresenter = preload("res://scripts/ui/ceremony/ceremony_presenter.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const CONFIG := "res://data/config/economy_rewards_v1.json"
const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]

var EXPECTED_CASES := [
	"c01_gift_full_vs_reduced", "c02_gift_present_grants_nothing", "c03_daily_cycle_days",
	"c04_all_tasks_scrubbox", "c05_reduced_collapse", "c06_no_stacking_no_seen",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack
var _cfg: Dictionary = {}
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	await process_frame
	_cfg = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 1920)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_stack = ModalStack.new()
	_sub.add_child(_stack)
	_c01_gift_full_vs_reduced()
	await _c02_gift_present_grants_nothing()
	await _c03_daily_cycle_days()
	await _c04_all_tasks_scrubbox()
	await _c05_reduced_collapse()
	await _c06_no_stacking_no_seen()
	_sub.free()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _c01_gift_full_vs_reduced() -> void:
	print("[c01 Gift milestones 10/50/250/500/1000: FULL == Reduced, rows == config bundle]")
	var app = _app("c01")
	app.economy.gift.add_streak_sb("c01_tx", 1000)
	var evs: Array = CeremonyEvents.events(app.economy).filter(func(e): return e["kind"] == "gift_milestone")
	_ok(evs.map(func(e): return int(e["milestone"])) == [10, 50, 250, 500, 1000], "five gift events 10/50/250/500/1000")
	for ev in evs:
		var m := int(ev["milestone"])
		var bundle: Dictionary = _cfg["gift_meter"]["milestones"][str(m)].duplicate()
		bundle.erase("guaranteed_new_fallback_sb")   # a condition note, not a reward row (e24)
		var full = MetaCeremonies.build(ev, false)
		var red = MetaCeremonies.build(ev, true)
		_ok(full != null and red != null and _texts(full) == _texts(red), "m%d: identical labels FULL vs Reduced" % m)
		_ok(_rows(full) == _num_dict(bundle) and _rows(red) == _num_dict(bundle), "m%d: rows == config bundle %s" % [m, str(_rows(red))])
		_ok(not red.find_child("HeroGlow", true, false).has_meta("spin") and full.find_child("HeroGlow", true, false).has_meta("spin"), "m%d: HeroGlow spin FULL only" % m)
		full.free()
		red.free()
	_complete("c01_gift_full_vs_reduced")

func _c02_gift_present_grants_nothing() -> void:
	print("[c02 Gift ceremony under Reduced Effects: grants nothing, exactly once]")
	var app = _app("c02")
	app.set_reduced_effects(true)
	var newly: Array = app.economy.gift.add_streak_sb("c02_tx", 10)
	app.request_save()
	var a0 := _auth(app)
	var pr = _presenter(app)
	_ok(pr.drain("test"), "ceremony opened")
	await _frames(2)
	var p = pr.current()
	_ok(p != null and not p.find_child("HeroGlow", true, false).has_meta("spin") and _rows(p) == {"bot_parts": 1, "standard_card_packs": 1}, "Reduced popup: no spin, config rows")
	p._on_action(p.get_action_ids()[0])
	await _frames(2)
	_ok(_auth(app) == a0 and app.economy.gift.claimable().size() == 1, "acknowledge granted nothing (wallet / boosters / packs / reward ledger); still claimable")
	_ok(app.economy.meta_ui.is_seen("gift:" + String(newly[0]["id"])), "acknowledged")
	var re = AppState.new(app.save._path)
	_ok(CeremonyEvents.pending(re.economy, re.economy.meta_ui).is_empty() and re.economy.gift.claimable().size() == 1, "reload: none pending (exactly once), still claimable")
	_complete("c02_gift_present_grants_nothing")

func _c03_daily_cycle_days() -> void:
	print("[c03 Daily cycle D1..D5: popup == config reward == granted; open grants nothing]")
	var app = _daily_app("c03")
	var eco = app.economy
	for day in range(1, 6):
		var want: Dictionary = _cfg["daily"]["login_rewards"][str(day)]
		var sb0: int = eco.wallet.scrub_bucks()
		var ch0 := _charges(eco)
		var sel0: int = eco.boosters.pending_selected()
		var r: Dictionary = app.actions.claim_daily_login()
		_ok(bool(r["ok"]) and int(r["day"]) == day and JSON.stringify(r["reward"]) == JSON.stringify(want), "D%d: real claim ok, day + reward == config" % day)
		_ok(eco.wallet.scrub_bucks() - sb0 == int(want.get("scrub_bucks", 0)) and _charges(eco) - ch0 == int(want.get("random_any_booster_charges", 0)) and eco.boosters.pending_selected() - sel0 == int(want.get("selected_booster_charges", 0)) and eco.reward.already_applied("daily_login:%d" % _day[0]), "D%d: wallet / booster delta == config reward (shown == granted)" % day)
		var a0 := _auth(app)
		var p = DailyScreens.open_daily_reward(_stack, app, r)
		await _frames(2)
		_ok(p != null and _label(p, "RewardText") == UiText.reward_text(want) and p.get_title() == UiText.t("DAILY_DAY", [day]), "D%d: popup title + reward text == config" % day)
		var streak := _label(p, "Streak")
		_ok(streak == (UiText.t("DAILY_CYCLE_DONE") if day == 5 else UiText.t("DAILY_CONSECUTIVE", [UiText.num(day)])), "D%d: %s copy" % [day, "cycle-done" if day == 5 else "streak"])
		_ok(_auth(app) == a0, "D%d: opening the popup granted nothing" % day)
		p._on_action("ok")
		await _frames(2)
		_day[0] += 1
		_now[0] += 86400
	_complete("c03_daily_cycle_days")

func _c04_all_tasks_scrubbox() -> void:
	print("[c04 3/3 Tasks: ScrubBox == config charges, once, only after a successful claim]")
	var app = _daily_app("c04")
	var eco = app.economy
	var cfg_n := int(_cfg["daily"]["all_tasks_random_any_booster_charges"])
	var r0: Dictionary = app.actions.claim_daily_all_tasks()
	_ok(not bool(r0["ok"]) and _charges(eco) == 0 and _stack.depth() == 0, "not all done: not claimable; no popup, no grant")
	for i in range(3):
		eco.daily.mark_task_done(i)
	var ch0 := _charges(eco)
	var r: Dictionary = app.actions.claim_daily_all_tasks()
	_ok(bool(r["ok"]) and int(r["random_any_booster_charges"]) == cfg_n and _charges(eco) - ch0 == cfg_n, "3/3: committed result == config, charges granted")
	var a0 := _auth(app)
	var p = DailyScreens.open_scrubbox(_stack, app, r)
	await _frames(2)
	_ok(p != null and _label(p, "RewardText") == UiText.reward_text({"random_any_booster_charges": cfg_n}), "ScrubBox shows the committed config amount")
	_ok(_auth(app) == a0, "opening the ScrubBox granted nothing")
	p._on_action("ok")
	await _frames(2)
	var again: Dictionary = app.actions.claim_daily_all_tasks()
	_ok(not bool(again["ok"]) and _charges(eco) - ch0 == cfg_n and _stack.depth() == 0, "second claim refused; no extra grant; no popup")
	_complete("c04_all_tasks_scrubbox")

func _c05_reduced_collapse() -> void:
	print("[c05 Reduced Effects: Daily + ScrubBox popups identical labels, no motion nodes, same grants]")
	var full_t := {}
	var red_t := {}
	var grants := {}
	for mode in ["full", "reduced"]:
		var app = _daily_app("c05" + mode)
		if mode == "reduced":
			app.set_reduced_effects(true)
		_ok(app.effects.is_reduced() == (mode == "reduced"), "%s: Reduced flag" % mode)
		var sb0: int = app.economy.wallet.scrub_bucks()
		var r: Dictionary = app.actions.claim_daily_login()
		var d = DailyScreens.open_daily_reward(_stack, app, r)
		await _frames(2)
		(red_t if mode == "reduced" else full_t)["daily"] = _texts(d)
		_ok(_no_motion(d), "%s: Daily popup has no animation / particle / spin nodes" % mode)
		d._on_action("ok")
		await _frames(2)
		for i in range(3):
			app.economy.daily.mark_task_done(i)
		var ch0 := _charges(app.economy)
		var r2: Dictionary = app.actions.claim_daily_all_tasks()
		var s = DailyScreens.open_scrubbox(_stack, app, r2)
		await _frames(2)
		(red_t if mode == "reduced" else full_t)["box"] = _texts(s)
		_ok(_no_motion(s), "%s: ScrubBox popup has no animation / particle / spin nodes" % mode)
		s._on_action("ok")
		await _frames(2)
		grants[mode] = [app.economy.wallet.scrub_bucks() - sb0, _charges(app.economy) - ch0]
	_ok(full_t["daily"] == red_t["daily"] and full_t["box"] == red_t["box"] and not full_t["daily"].is_empty(), "labels identical FULL vs Reduced")
	_ok(grants["full"] == grants["reduced"], "grants identical FULL vs Reduced %s" % str(grants))
	_complete("c05_reduced_collapse")

func _c06_no_stacking_no_seen() -> void:
	print("[c06 presenter never stacks; Daily/ScrubBox are player-initiated and mark nothing seen]")
	var app = _daily_app("c06")
	app.economy.gift.add_streak_sb("c06_tx", 50)
	var pr = _presenter(app)
	_ok(pr.drain("test"), "first ceremony opened")
	await _frames(2)
	var first = pr.current()
	_ok(not pr.drain("again") and _stack.depth() == 1 and pr.current() == first, "drain while one is showing opens no second")
	var seen0: Array = app.economy.meta_ui.seen_keys().duplicate()
	var r: Dictionary = app.actions.claim_daily_login()
	var d = DailyScreens.open_daily_reward(_stack, app, r)
	await _frames(2)
	d._on_action("ok")
	await _frames(2)
	for i in range(3):
		app.economy.daily.mark_task_done(i)
	var s = DailyScreens.open_scrubbox(_stack, app, app.actions.claim_daily_all_tasks())
	await _frames(2)
	s._on_action("ok")
	await _frames(2)
	_ok(app.economy.meta_ui.seen_keys() == seen0, "Daily / ScrubBox popups marked no MetaUiState key seen")
	first._on_action(first.get_action_ids()[0])
	await _frames(2)
	_complete("c06_no_stacking_no_seen")

# ------------------------------------------------------------------ helpers ----

func _uniq(tag: String) -> String:
	var p := "user://m43c005_c074_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _app(tag: String):
	var app = AppState.new(_uniq(tag))
	app.request_save()
	return app

func _daily_app(tag: String):
	var app = AppState.new(_uniq(tag), func(): return _now[0], func(): return _day[0])
	app.request_save()
	return app

func _presenter(app):
	var pr = CeremonyPresenter.new()
	pr.bind(_stack, app)
	return pr

func _rows(p) -> Dictionary:
	var out := {}
	var rows = p.find_child("RewardRows", true, false)
	if rows != null:
		for r in rows.get_children():
			out[String(r.get_meta("reward_key"))] = int(r.get_meta("amount"))
	return out

func _num_dict(d: Dictionary) -> Dictionary:
	var out := {}
	for k in d:
		out[String(k)] = int(d[k])
	return out

func _label(p, n: String) -> String:
	var l = p.find_child(n, true, false)
	return l.text if l is Label else ""

func _texts(p) -> Array:
	return p.find_children("*", "Label", true, false).map(func(l): return l.text)

func _charges(eco) -> int:
	return BOOSTERS.reduce(func(s, b): return s + eco.boosters.charges(b), 0)

## No animation / particle nodes and no spin meta anywhere in the popup tree.
func _no_motion(p) -> bool:
	for c in p.find_children("*", "", true, false):
		if c is AnimationPlayer or c is AnimatedSprite2D or c is GPUParticles2D or c is CPUParticles2D or c.has_meta("spin"):
			return false
	return not p.has_meta("spin")

func _auth(app) -> Dictionary:
	var s: Dictionary = app.economy.snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	s.erase("meta_ui")
	return s

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
	print("M43 C005 gift/daily/tasks celebrations evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
