extends SceneTree
## SB-M43-072 — Feature Unlock ceremony driven by the owner unlock table (feature_unlocks_v1.json):
## a NEW FTUE profile whose frontier reaches a table level (> 1) is shown ONE "NEW FEATURE!"
## ceremony per presentable feature (existing promoted icon), once, key "unlock:<id>", through
## the shipping CeremonyPresenter + MetaCeremonies.feature_unlock. Real AppState / SaveService /
## ModalStack, and the real app root (main.tscn, test save path) for the Results hand-off.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c072_feature_unlock_ceremony.gd

const AppState = preload("res://scripts/app/app_state.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const CeremonyPresenter = preload("res://scripts/ui/ceremony/ceremony_presenter.gd")
const FtueDirector = preload("res://scripts/app/ftue_director.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const SIZE := Vector2i(1080, 1920)
const SHORTCUTS := "res://assets/ui/final/home/shortcuts/"

var EXPECTED_CASES := ["a_daily_at_l4", "b_several_ascending", "c_ack_once_no_grant", "d_grandfather_and_l1",
	"e_no_icon_skipped", "f_reduced_same_labels", "g_save_failure_pending", "h_keys_distinct", "i_results_handoff"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack
var _root = null

func _initialize() -> void:
	await process_frame
	_mount()
	await _a_daily_at_l4()
	await _b_several_ascending()
	await _c_ack_once_no_grant()
	_d_grandfather_and_l1()
	_e_no_icon_skipped()
	_f_reduced_same_labels()
	await _g_save_failure_pending()
	await _h_keys_distinct()
	_unmount()
	await _i_results_handoff()
	await _frames(3)
	_cleanup()
	_done()

func _a_daily_at_l4() -> void:
	print("[a fresh profile: nothing below L4, exactly unlock:daily at L4]")
	var app = _fresh("a")
	_walk(app, 3)
	var pr = _presenter(app)
	_ok(pr.feature_events().is_empty() and _keys(pr.pending()).is_empty(), "L3: no feature event")
	_walk(app, 4)
	_ok(_keys(pr.pending()) == ["unlock:daily"], "L4: exactly one unlock:daily pending %s" % str(_keys(pr.pending())))
	_ok(pr.drain("test"), "presenter opens it")
	await _frames(2)
	var p = pr.current()
	var hero = p.find_child("HeroArt", true, false)
	_ok(p.get_title() == "NEW FEATURE!" and _label(p, "FeatureName") == UiText.t("FEATURE_DAILY_NAME") and _label(p, "FeatureBody") == UiText.t("FEATURE_DAILY_BODY"), "title NEW FEATURE! + UiText name / body")
	_ok(p.get_action_ids() == ["got_it"], "got_it is the only action")
	_ok(hero.texture.resource_path == SHORTCUTS + "icon_shortcut_daily.png", "icon = existing Daily shortcut asset")
	_ok(String(p.context["ceremony_key"]) == "unlock:daily" and String(p.context["kind"]) == "feature_unlock", "key unlock:daily, kind feature_unlock")
	_close_cta(p)
	await _frames(2)
	_complete("a_daily_at_l4")

func _b_several_ascending() -> void:
	print("[b several table levels at once: one ceremony per feature, ascending, one at a time]")
	var app = _fresh("b")
	_complete_set(app, 1)
	_walk(app, 21)
	var pr = _presenter(app)
	var want := ["set:1", "unlock:daily", "unlock:shop", "unlock:tasks", "unlock:collection"]
	_ok(_keys(pr.pending()) == want, "pending = set first, then features by table level %s" % str(_keys(pr.pending())))
	var one_at_a_time := true
	pr.drain("test")
	for _i in range(want.size()):
		await _frames(1)
		one_at_a_time = one_at_a_time and _stack.depth() == 1
		_close_cta(pr.current())
	await _frames(2)
	_ok(pr.presented_log().map(func(l): return l[0]) == want and one_at_a_time, "presented in order, one popup on the stack at a time")
	_ok(not pr.is_presenting() and pr.pending().is_empty() and _stack.depth() == 0, "nothing left")
	_complete("b_several_ascending")

func _c_ack_once_no_grant() -> void:
	print("[c CTA acknowledges once; reload / export-import never replays; nothing granted]")
	var app = _fresh("c")
	_walk(app, 8)
	app.request_save()
	var pr = _presenter(app)
	var acks: Array = []
	pr.ceremony_acknowledged.connect(func(k, _kind): acks.append(k))
	var e0 := _econ(app)
	var u0 := _unlocked(app)
	pr.drain("test")
	await _frames(2)
	_ok(_econ(app) == e0, "presenting: wallet / hearts / boosters / collection / robots byte-identical")
	_close_cta(pr.current())
	await _frames(2)
	_ok(acks == ["unlock:daily"] and _keys(pr.pending()) == ["unlock:shop"], "acked once; second pending() omits it")
	_close_cta(pr.current())
	await _frames(2)
	_ok(acks == ["unlock:daily", "unlock:shop"] and pr.pending().is_empty(), "shop acked; nothing pending")
	_ok(_econ(app) == e0 and _unlocked(app) == u0 and app.progression.current_level() == 8, "after: economy, unlock state and frontier unchanged")
	var re = AppState.new(app.save._path)
	var pr2 = _presenter(re)
	_ok(re.economy.meta_ui.is_seen("unlock:daily") and pr2.pending().is_empty() and not pr2.drain("reload"), "reload: nothing replayed")
	var imp = AppState.new(_uniq("c_imp"))
	imp.bootstrap_new_profile()
	_ok(imp.economy.import_snapshot(JSON.parse_string(JSON.stringify(app.economy.snapshot()))) and imp.progression.import_snapshot(JSON.parse_string(JSON.stringify(app.progression.snapshot()))), "economy + progression export / import")
	_ok(imp.progression.current_level() == 8 and _presenter(imp).pending().is_empty(), "imported save: nothing replayed")
	_complete("c_ack_once_no_grant")

func _d_grandfather_and_l1() -> void:
	print("[d grandfathered save: no feature events; L1 features never]")
	var est = AppState.new(_uniq("d_est"))
	est.request_save()
	_walk(est, 25)
	var pr = _presenter(est)
	_ok(not est.economy.ftue.is_new_profile() and pr.feature_events().is_empty() and pr.pending().is_empty(), "established save at L25: zero feature events")
	var fresh = _fresh("d")
	var pf = _presenter(fresh)
	_ok(fresh.feature_unlocked("hearts") and fresh.feature_unlocked("gift_bar") and pf.feature_events().is_empty(), "fresh L1: hearts / gift_bar unlocked, zero events")
	_walk(fresh, 40)
	_ok(not _keys(pf.feature_events()).has("unlock:hearts") and not _keys(pf.feature_events()).has("unlock:gift_bar"), "fresh L40: still none for hearts / gift_bar")
	_complete("d_grandfather_and_l1")

func _e_no_icon_skipped() -> void:
	print("[e feature without a promoted icon: no event, no error]")
	var app = _fresh("e")
	_walk(app, 40)
	var pr = _presenter(app)
	var derived := _keys(pr.feature_events())
	var shown := _keys(pr.pending())
	_ok(derived.has("unlock:robots") and derived.has("unlock:ranks") and derived.has("unlock:tornado"), "robots / ranks / tornado unlocked (derived)")
	_ok(shown == ["unlock:daily", "unlock:shop", "unlock:tasks", "unlock:collection"], "only icon-backed features presentable %s" % str(shown))
	var robots: Dictionary = pr.feature_events().filter(func(e): return e["key"] == "unlock:robots")[0]
	_ok(String(robots["icon"]).is_empty() and MetaCeremonies.build(robots, false) == null, "robots: empty icon -> builder null (no art invented)")
	_complete("e_no_icon_skipped")

func _f_reduced_same_labels() -> void:
	print("[f Reduced Effects: same labels, no motion]")
	var app = _fresh("f")
	_walk(app, 4)
	var pr = _presenter(app)
	var ev: Dictionary = pr.pending()[0]
	var full = MetaCeremonies.build(ev, false)
	app.effects.set_reduced(true)
	var red = MetaCeremonies.build(pr.pending()[0], true)
	_ok(_texts(full) == _texts(red) and not _texts(red).is_empty(), "identical label texts %s" % str(_texts(red)))
	_ok(full.find_child("HeroGlow", true, false).has_meta("spin") and not red.find_child("HeroGlow", true, false).has_meta("spin"), "Reduced: no spin meta on HeroGlow")
	full.free()
	red.free()
	_complete("f_reduced_same_labels")

func _g_save_failure_pending() -> void:
	print("[g save failure on acknowledge: stays pending, no loop this session]")
	var app = _fresh("g")
	_walk(app, 4)
	app.request_save()
	var pr = _presenter(app)
	app.save.set_fault_injector(func(stage): return stage == "temp_write")
	pr.drain("test")
	await _frames(2)
	_close_cta(pr.current())
	await _frames(2)
	_ok(not app.economy.meta_ui.is_seen("unlock:daily"), "seen mark rolled back")
	_ok(not pr.is_presenting() and pr.pending().is_empty() and _stack.depth() == 0 and not pr.drain("again"), "no re-open loop in this session")
	app.save.set_fault_injector(Callable())
	var re = AppState.new(app.save._path)
	_ok(_keys(_presenter(re).pending()) == ["unlock:daily"], "next launch: still pending")
	_complete("g_save_failure_pending")

func _h_keys_distinct() -> void:
	print("[h unlock: keys never collide with feature_visited: / What's New keys]")
	var app = _fresh("h")
	_walk(app, 8)
	var meta = app.economy.meta_ui
	var wn := FtueDirector.whats_new_key({"feature_id": "daily", "version": 1})
	meta.mark_seen(HomeBadges.visited_key("daily"))
	meta.mark_seen(wn)
	var pr = _presenter(app)
	_ok(_keys(pr.pending()).has("unlock:daily"), "visited / What's New marks do not hide unlock:daily")
	var before: Array = meta.seen_keys()
	pr.drain("test")
	await _frames(2)
	_close_cta(pr.current())
	await _frames(2)
	var added: Array = meta.seen_keys().filter(func(k): return not before.has(k))
	_ok(added == ["unlock:daily"], "acknowledging marks only unlock:daily %s" % str(added))
	_ok(HomeBadges.new_features(app).has("shop") and not meta.is_seen(HomeBadges.visited_key("shop")) and not meta.is_seen(FtueDirector.whats_new_key({"feature_id": "shop", "version": 1})), "shop: NEW pill and What's New untouched by the ceremony keys")
	_ok(not CeremonyPresenter.feature_key("daily").begins_with("feature"), "unlock: prefix distinct from feature: / feature_visited:")
	_close_cta(pr.current())
	await _frames(2)
	_complete("h_keys_distinct")

func _i_results_handoff() -> void:
	print("[i real app root: winning L3 hands off to the Daily ceremony; coachmark hidden under it]")
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := _uniq("i")
	var seed = AppState.new(path)
	seed.bootstrap_new_profile()
	_walk(seed, 3)
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
	var res = _root.get_results_screen()
	_ok(_root.get_navigation().route_name() == "RESULTS" and res.has_ceremony_barrier(), "WON L3 -> frontier 4: Results ceremony barrier holds")
	res.finish_reveal()
	var top = null
	for _i in range(20):
		await _frames(1)
		top = _root.get_modal_stack().top()
		if top != null:
			break
	_ok(top != null and String(top.context.get("ceremony_key", "")) == "unlock:daily" and _root.get_modal_stack().depth() == 1, "after the reveal: the Daily feature ceremony alone on top")
	_ok(not _root.get_coachmarks().is_showing(), "no coachmark over the ceremony")
	_close_cta(top)
	await _frames(4)
	_ok(not res.has_ceremony_barrier() and _root.get_app_state().economy.meta_ui.is_seen("unlock:daily"), "acknowledged; barrier released")
	_ok(AppState.new(path).economy.meta_ui.is_seen("unlock:daily"), "durably saved")
	if _root != null and is_instance_valid(_root):
		_root.free()
	_unmount()
	_root = null
	MainScript.boot_save_path_override = ""
	_complete("i_results_handoff")

# ------------------------------------------------------------------ helpers ----

func _fresh(tag: String):
	var app = AppState.new(_uniq(tag))
	app.bootstrap_new_profile()
	return app

func _walk(app, frontier: int) -> void:
	while app.progression.current_level() < frontier:
		app.progression.record_win(app.progression.current_level())

func _complete_set(app, n: int) -> void:
	for k in range(9):
		var cid := "s%d_c%d" % [n, k]
		if app.economy.collection.owned(cid) == 0:
			app.economy.collection.add_card(cid)

func _presenter(app):
	var pr = CeremonyPresenter.new()
	pr.bind(_stack, app)
	return pr

func _keys(list: Array) -> Array:
	return list.map(func(e): return String(e["key"]))

## Everything in the economy snapshot except the presentation ledger (and wall-clock anchors).
func _econ(app) -> String:
	var s: Dictionary = app.economy.snapshot()
	s.erase("meta_ui")
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	return JSON.stringify(s)

func _unlocked(app) -> Dictionary:
	var out := {}
	for id in app.unlocks.cfg["unlocks"]:
		out[id] = app.feature_unlocked(id)
	return out

func _label(p, n: String) -> String:
	var l = p.find_child(n, true, false)
	return l.text if l is Label else ""

func _texts(p) -> Array:
	return p.find_children("*", "Label", true, false).map(func(l): return l.text)

func _close_cta(p) -> void:
	if p != null and is_instance_valid(p):
		p._on_action(p.get_action_ids()[0])

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

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _uniq(tag: String) -> String:
	var p := "user://m43_c072_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M43 C005 feature unlock ceremony evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
