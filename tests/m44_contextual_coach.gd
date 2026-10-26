extends SceneTree
## M44 contextual coachmarks (SB-M44-005 / SB-M44-006) — event-triggered, one-shot FTUE entries
## against the REAL services and the REAL app root (main.tscn, temp save override):
##   - strict `contextual` config block; l3_rules no longer schedules WAITING / Hearts;
##   - first WAITING (real scheduler state) -> ctx_waiting on the five-slot strip, once;
##   - first WON / LOST Results -> ctx_result_won / ctx_result_lost once each, Heart sentence
##     from the committed receipt, pointer on RETRY; Retry press acknowledges;
##   - persistence across relaunch, Skip Tips, established profiles never, window-closed still;
##   - no economy / progression mutation; hidden under modals and the Results reveal.
##
## Run: godot --headless --path . -s res://tests/m44_contextual_coach.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const FtueConfig = preload("res://scripts/app/ftue_config.gd")
const FtueDirector = preload("res://scripts/app/ftue_director.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const HelpTipsScreen = preload("res://scripts/ui/tutorial/help_tips_screen.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")

const R := NavigationController.Route
const CTX := ["ctx_waiting", "ctx_result_won", "ctx_result_lost"]

var EXPECTED_CASES := [
	"c01_config_contextual_strict", "c02_director_contextual_rules", "c03_first_waiting_real_host",
	"c04_first_win_loss_results", "c05_persistence_and_skip", "c06_established_never",
	"c07_suppression_and_no_economy_mutation",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	MainScript.boot_ftue_override = 1
	MainScript.boot_opening_override = 0
	_c01()
	_c02()
	await _c03()
	await _c04()
	await _c05()
	await _c06()
	await _c07()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ config ----

func _c01() -> void:
	print("[c01 strict contextual block; l3_rules = l3_speed only]")
	var c: Dictionary = FtueConfig.load_config()
	_ok(bool(c.get("ok", false)), "shipped config valid %s" % str(c.get("reason", "")))
	var ids: Array = (c["contextual"] as Array).map(func(e): return String(e["id"]))
	var trig: Array = (c["contextual"] as Array).map(func(e): return String(e["trigger"]))
	_ok(ids == CTX and trig == ["slot_waiting", "result_won", "result_lost"], "three contextual entries %s %s" % [str(ids), str(trig)])
	var l3: Array = []
	for l in c["lessons"]:
		if String(l["id"]) == "l3_rules":
			l3 = (l["steps"] as Array).map(func(s): return String(s["id"]))
	_ok(l3 == ["l3_speed"], "l3_rules no longer schedules l3_waiting / l3_hearts %s" % str(l3))
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FtueConfig.PATH))
	var muts := {
		"missing id": func(d): d["contextual"][0].erase("id"),
		"duplicate ctx id": func(d): d["contextual"][1]["id"] = "ctx_waiting",
		"id clashes with a lesson step": func(d): d["contextual"][0]["id"] = "l3_speed",
		"unknown trigger": func(d): d["contextual"][0]["trigger"] = "first_store",
		"duplicate trigger": func(d): d["contextual"][1]["trigger"] = "slot_waiting",
		"bad target": func(d): d["contextual"][0]["target"] = "shop_offer",
		"missing target": func(d): d["contextual"][0].erase("target"),
		"unknown title key": func(d): d["contextual"][0]["title"] = "FTUE_NO_SUCH_KEY",
		"unknown body key": func(d): d["contextual"][2]["body"] = "FTUE_NO_SUCH_KEY",
		"block missing": func(d): d.erase("contextual"),
		"block not an array": func(d): d["contextual"] = {},
		"entry not a dict": func(d): d["contextual"][0] = "ctx_waiting",
	}
	var rej := 0
	for k in muts:
		var m: Dictionary = raw.duplicate(true)
		(muts[k] as Callable).call(m)
		var v: Dictionary = FtueConfig.validate(m)
		if not bool(v.get("ok", true)) and not v.has("lessons"):
			rej += 1
		else:
			print("    accepted mutation: " + String(k))
	_ok(rej == muts.size(), "%d/%d malformed contextual blocks reject the whole file" % [rej, muts.size()])
	_complete("c01_config_contextual_strict")

# ---------------------------------------------------------------- director ----

func _c02() -> void:
	print("[c02 director: eligibility, one-shot, Heart sentence from the receipt]")
	var a = _app(_path("c02"))
	a.bootstrap_new_profile()
	var d = FtueDirector.new(a)
	_ok(d.contextual_active() and String(d.contextual_step("slot_waiting").get("id", "")) == "ctx_waiting", "new profile: first WAITING -> ctx_waiting")
	_ok(d.contextual_step("").is_empty() and d.contextual_step("nope").is_empty(), "no trigger / unknown trigger: nothing")
	_ok(d.contextual_trigger("ctx_result_lost") == "result_lost" and d.contextual_trigger("l3_speed") == "", "trigger lookup")
	_ok(d.acknowledge("ctx_waiting") and d.contextual_step("slot_waiting").is_empty() and not d.acknowledge("ctx_waiting"), "acknowledged once, never again")
	_ok(String(d.contextual_step("result_won").get("id", "")) == "ctx_result_won" and String(d.contextual_step("result_lost").get("id", "")) == "ctx_result_lost", "win / loss entries independent of WAITING")
	a.economy.ftue.close()
	_ok(not d.tips_active() and String(d.contextual_step("result_lost").get("id", "")) == "ctx_result_lost", "window closed (frontier > L3): contextual still due")
	var st: Dictionary = d.contextual_step("result_lost")
	var lost := String(d.step_copy(st, {"receipt": {"hearts": {"before": 5, "after": 4}}})["body"])
	var kept := String(d.step_copy(st, {"receipt": {"hearts": {"before": 0, "after": 0}}})["body"])
	_ok(lost.begins_with(UiText.t("FTUE_CTX_HEART_LOST")) and lost.contains("RETRY") and lost.contains("refill"), "lost Heart: '%s'" % lost)
	_ok(kept.begins_with(UiText.t("FTUE_CTX_HEART_KEPT")) and not kept.contains("cost 1 Heart"), "no Heart lost: '%s'" % kept)
	var won := String(d.step_copy(d.contextual_step("result_won"))["body"])
	_ok(won.contains("never costs a Heart") and won.contains("Win Streak") and not won.contains("SB"), "win copy: no Heart cost, Win Streak, no invented numbers")
	_ok(a.economy.ftue.skip() and not d.contextual_active() and d.contextual_step("result_won").is_empty(), "Skip Tips suppresses contextual entries")
	var est = _app(_path("c02e"))
	var de = FtueDirector.new(est)
	_ok(not de.contextual_active() and ["slot_waiting", "result_won", "result_lost"].all(func(t): return de.contextual_step(t).is_empty()), "established profile: never")
	_ok(not de.acknowledge("ctx_waiting") and est.economy.ftue.seen_steps().is_empty(), "established: nothing marked seen")
	_complete("c02_director_contextual_rules")

# -------------------------------------------------------------- real app root ----

func _c03() -> void:
	print("[c03 first WAITING on a real host: ctx_waiting on the slot strip, once]")
	await _boot("c03")
	var app = _root.get_app_state()
	var cm = _root.get_coachmarks()
	var lvl := await _play_until_waiting(true)
	_ok(lvl > 0, "found a real WAITING lane on level %d" % lvl)
	var host = _root.get_gameplay_host()
	_ok(app.economy.ftue.closed and not app.economy.ftue.tips_active(), "frontier > L3: the scheduled window is closed")
	var econ0 := _econ(app)
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "ctx_waiting" and cm.get_target() == host.get_screen().get_five_slot_strip_rect() and cm.get_pointer().visible, "ctx_waiting shown with the pointer on the real slot strip")
	_ok(cm.get_body_label().text == UiText.t("FTUE_CTX_WAIT_BODY") and cm.get_got_it_button().visible and cm.get_skip_button().visible, "copy + GOT IT / SKIP TIPS")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(app.economy.ftue.seen_steps().has("ctx_waiting") and not cm.is_showing() and _any_waiting(host), "GOT IT: seen; still WAITING but not shown again")
	_ok(_econ(app) == econ0, "showing / acknowledging changed no economy / progression")
	await _play_until_waiting(false)
	_root.refresh_coachmark()
	_ok(_any_waiting(_root.get_gameplay_host()) and not cm.is_showing(), "WAITING recurs on another attempt: not re-shown")
	await _boot("c03b")
	app = _root.get_app_state()
	cm = _root.get_coachmarks()
	await _play_until_waiting(true)
	_root.refresh_coachmark()
	var shown: bool = cm.get_step_id() == "ctx_waiting"
	_nav().go(R.HOME)   # the player leaves the WAITING situation without GOT IT
	await _frames(2)
	_ok(shown and app.economy.ftue.seen_steps().has("ctx_waiting") and not cm.is_showing(), "leaving the WAITING state acknowledges the shown entry")
	_complete("c03_first_waiting_real_host")

func _c04() -> void:
	print("[c04 first LOST / WON Results: once each, receipt-true Heart sentence, Retry acknowledges]")
	await _boot("c04")
	var app = _root.get_app_state()
	var cm = _root.get_coachmarks()
	var res = _root.get_results_screen()
	await _play(4)
	_root.refresh_coachmark()
	_ok(not cm.is_showing(), "gameplay start, nothing waiting: nothing contextual")
	_first_action()
	await _lose()
	var rc: Dictionary = res.get_model().get("receipt", {})
	var hl: bool = int(rc["hearts"]["after"]) < int(rc["hearts"]["before"])
	_root.refresh_coachmark()
	_ok(_nav().current() == R.RESULTS and cm.get_step_id() == "ctx_result_lost", "first LOST: ctx_result_lost")
	_ok(hl and cm.get_body_label().text.begins_with(UiText.t("FTUE_CTX_HEART_LOST")), "receipt lost a Heart (%s) and the copy says so" % str(rc["hearts"]))
	_ok(cm.get_target() == res.get_primary_button().get_global_rect() and cm.get_target().has_area(), "pointer on the real RETRY button")
	var econ0 := _econ(app)
	res.get_primary_button().pressed.emit()   # the real action: RETRY
	await _frames(3)
	_root.refresh_coachmark()
	_ok(_nav().current() == R.GAMEPLAY and app.economy.ftue.seen_steps().has("ctx_result_lost"), "pressing RETRY acknowledged ctx_result_lost")
	_ok(_econ(app) == econ0, "the coachmark added no economy change to the Retry itself")
	_first_action()
	await _lose()
	_root.refresh_coachmark()
	_ok(_nav().current() == R.RESULTS and not cm.is_showing(), "second LOST: not re-shown")
	_root.get_modal_stack().clear("t")
	_root.retry_from_results()
	await _frames(3)
	_first_action()
	await _win()
	_root.refresh_coachmark()
	_ok(_nav().current() == R.RESULTS and cm.get_step_id() == "ctx_result_won", "first WON (after a seen loss): ctx_result_won, independent")
	_ok(not cm.get_pointer().visible and cm.get_body_label().text == UiText.t("FTUE_CTX_WON_BODY"), "won copy, no pointer")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(app.economy.ftue.seen_steps().has("ctx_result_won") and not cm.is_showing(), "GOT IT acknowledged the win entry")
	await _play(app.progression.current_level())
	_first_action()
	await _win()
	_root.refresh_coachmark()
	_ok(_nav().current() == R.RESULTS and not cm.is_showing(), "second WON: not re-shown")
	_complete("c04_first_win_loss_results")

func _c05() -> void:
	print("[c05 persisted across relaunch; Skip Tips before the first occurrence = none]")
	var p := _path("c05_save")
	await _boot("c05", p)
	var cm = _root.get_coachmarks()
	await _play(4)
	await _lose()
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "ctx_result_lost", "loss entry shown")
	cm.get_got_it_button().pressed.emit()
	_ok(bool(_root.get_app_state().request_save().get("ok", false)), "saved")
	await _boot("c05b", p)
	var app = _root.get_app_state()
	cm = _root.get_coachmarks()
	_ok(app.economy.ftue.is_new_profile() and app.economy.ftue.seen_steps().has("ctx_result_lost"), "relaunch: still seen")
	await _play(4)
	await _lose()
	_root.refresh_coachmark()
	_ok(_nav().current() == R.RESULTS and not cm.is_showing(), "relaunch + LOST: not shown again")
	await _boot("c05s")
	app = _root.get_app_state()
	cm = _root.get_coachmarks()
	_ok(_root.get_ftue().skip_tips() and app.economy.ftue.skipped, "Skip Tips at L1 (before any occurrence)")
	await _play(4)
	await _lose()
	_root.refresh_coachmark()
	var no_lost: bool = not cm.is_showing()
	_root.get_modal_stack().clear("t")
	_root.retry_from_results()
	await _frames(3)
	await _win()
	_root.refresh_coachmark()
	var no_won: bool = not cm.is_showing()
	var w := await _play_until_waiting(false)
	_root.refresh_coachmark()
	_ok(no_lost and no_won and w > 0 and not cm.is_showing() and app.economy.ftue.seen_steps().all(func(s): return not CTX.has(s)), "skipped: no WAITING / win / loss coachmark")
	_complete("c05_persistence_and_skip")

func _c06() -> void:
	print("[c06 established (pre-M44) profile: WAITING, win, loss -> nothing, seen stays empty]")
	await _boot("c06")
	var app = _root.get_app_state()
	var cm = _root.get_coachmarks()
	_ok(app.economy.ftue.import_snapshot(null) and not app.economy.ftue.is_new_profile(), "loaded as a pre-M44 (established) save")
	var w := await _play_until_waiting(false)
	_root.refresh_coachmark()
	var a: bool = w > 0 and not cm.is_showing()
	_first_action()
	await _lose()
	_root.refresh_coachmark()
	var b: bool = _nav().current() == R.RESULTS and not cm.is_showing()
	_root.get_modal_stack().clear("t")
	_root.retry_from_results()
	await _frames(3)
	await _win()
	_root.refresh_coachmark()
	var c: bool = _nav().current() == R.RESULTS and not cm.is_showing()
	_ok(a and b and c, "WAITING %s / loss %s / win %s: no contextual coachmark" % [a, b, c])
	_ok(app.economy.ftue.seen_steps().is_empty() and cm.shown_log().all(func(id): return not CTX.has(id)), "seen empty, no contextual entry ever shown %s" % str(cm.shown_log()))
	_complete("c06_established_never")

func _c07() -> void:
	print("[c07 modal / Results reveal suppress; economy byte-identical]")
	await _boot("c07")
	var app = _root.get_app_state()
	var cm = _root.get_coachmarks()
	var res = _root.get_results_screen()
	await _play(4)
	_first_action()
	await _lose()
	HelpTipsScreen.open(_root.get_modal_stack(), app)
	_root.refresh_coachmark()
	_ok(_root.get_modal_stack().depth() > 0 and not cm.is_showing(), "a modal over Results: hidden")
	_root.get_modal_stack().clear("t")
	var econ0 := _econ(app)
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "ctx_result_lost", "modal closed: shown")
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	_ok(_econ(app) == econ0, "show + GOT IT: economy (minus ftue) and progression byte-identical")
	_root.retry_from_results()
	await _frames(3)
	_first_action()
	await _win(false)
	_root.refresh_coachmark()
	var revealing: bool = res.is_revealing()
	_ok(revealing and not cm.is_showing(), "WON reveal still running: hidden (revealing=%s)" % revealing)
	res.finish_reveal()
	if res.has_ceremony_barrier():
		_root.refresh_coachmark()
		_ok(not cm.is_showing(), "ceremony barrier held: hidden")
		res.set_ceremony_barrier("meta_ceremonies", false)
	_root.get_modal_stack().clear("t")
	_root.refresh_coachmark()
	_ok(cm.get_step_id() == "ctx_result_won", "reveal done: shown")
	_complete("c07_suppression_and_no_economy_mutation")

# ------------------------------------------------------------------ helpers ----

## Play frontier levels until the real runtime leaves a placed lane WAITING. reset: start at
## L4; otherwise continue after the level last used (a fresh attempt).
var _wait_from := 4

func _play_until_waiting(reset: bool) -> int:
	if reset:
		_wait_from = 4
	for n in range(_wait_from, 14):
		await _play(n)
		var h = _root.get_gameplay_host()
		if h == null or not h.is_built():
			continue
		# Real play: fill empty slots from the fronts and tick the real runtime until the
		# scheduler itself reports a lane WAITING (no forced stall, no state injection).
		var rt = h.get_runtime()
		for _i in range(20000):
			if h.get_completion().is_terminal():
				break
			if h.get_slots().rightmost_empty_index() >= 0:
				for col in range(h.get_supply().get_column_count()):
					if h.get_input_controller().activate_front(col).get("ok", false):
						break
			rt.tick(1.0 / 30.0)
			if _any_waiting(h):
				_wait_from = n + 1
				return n
	return -1

func _any_waiting(h) -> bool:
	for s in range(h.get_slots().get_slot_count()):
		if h.get_scheduler().is_slot_waiting(s):
			return true
	return false

func _first_action() -> bool:
	var h = _root.get_gameplay_host()
	for col in range(h.get_supply().get_column_count()):
		if h.get_input_controller().activate_front(col).get("ok", false):
			return true
	return false

## One authoritative terminal through the real completion signal (host economy + save first,
## then the app root's Results route).
func _lose() -> void:
	_root.get_gameplay_host().get_completion().terminal_reached.emit(&"LOST", {})
	await _frames(3)

func _win(finish := true) -> void:
	_root.get_gameplay_host().get_completion().terminal_reached.emit(&"WON", {})
	await _frames(3)
	if finish:
		_root.get_results_screen().finish_reveal()
		if _root.get_results_screen().has_ceremony_barrier():
			_root.get_results_screen().set_ceremony_barrier("meta_ceremonies", false)
		_root.get_modal_stack().clear("t")
		await _frames(1)

## Economy (minus the ftue presentation section) + progression, as one string.
func _econ(app) -> String:
	var s: Dictionary = app.economy.snapshot()
	s.erase("ftue")
	return JSON.stringify([s, app.progression.snapshot()])

func _nav():
	return _root.get_navigation()

func _path(tag: String) -> String:
	var p := "user://m44_ctx_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _app(path: String):
	return AppState.new(path, MainScript.boot_clock_override, MainScript.boot_local_day_override)

func _boot(tag: String, path := "") -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path if not path.is_empty() else _path("boot_" + tag)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _play(level: int) -> void:
	_root.get_modal_stack().clear("test")
	var nav = _root.get_navigation()
	if nav.current() != R.HOME:
		nav.go(R.HOME)
		await _frames(2)
	_root.get_modal_stack().clear("test")
	# record_win keeps the frontier saveable (a debug_set_current_level fixture never saves).
	var prog = _root.get_app_state().progression
	while prog.current_level() < level:
		prog.record_win(prog.current_level())
	if prog.current_level() != level:
		prog.debug_set_current_level(level)
	# SB-M43-072: the walk's Feature Unlock ceremonies (own suite) are already shown here.
	for e in _root.get_ceremonies().feature_events():
		_root.get_app_state().economy.meta_ui.mark_seen(String(e["key"]))
	_root.get_ftue().settle()
	_root.play_current_frontier()
	await _frames(6)
	_root.get_modal_stack().clear("test")
	var h = _root.get_gameplay_host()
	if h != null:
		h.get_runtime().set_process(false)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	MainScript.boot_ftue_override = -1
	MainScript.boot_opening_override = -1
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
	print("M44 CONTEXTUAL COACH: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
