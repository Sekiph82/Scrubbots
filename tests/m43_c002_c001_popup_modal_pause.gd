extends SceneTree
## M43-C002-C001 — reusable popup / modal stack / canonical Pause foundation evidence.
## Real app root (main.tscn) + ProductionGameplayHost + GameplayScreen on a real level,
## the ONE app-level ModalStack, real routed pointer input (SubViewport.push_input) and
## the accepted M30 Retry / M39 Heart + Win Streak authorities.
##
## Run: godot --headless --path . -s res://tests/m43_c002_c001_popup_modal_pause.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const Popups = preload("res://scripts/ui/popup/popups.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const R = NavigationController.Route

var EXPECTED_CASES := [
	"base_popup_lifecycle", "stack_order", "only_top_input", "gameplay_input_blocked",
	"back_escape_no_leak", "rapid_duplicates", "focus_background", "generic_confirm",
	"reward_committed_only", "pause_from_real_control", "resume", "restart_pre_action",
	"restart_post_action", "home_pre_action", "home_post_action", "insufficient_sb_context",
	"busy_blocks_duplicates", "network_retry_cancel", "six_slot_survives", "no_accumulation",
	"responsive_matrix", "home_bridge", "frames_promoted_unchanged",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root
var _host

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	await _boot(2)
	await _base_popup_lifecycle()
	await _stack_order()
	await _only_top_input()
	await _gameplay_input_blocked()
	await _back_escape_no_leak()
	await _rapid_duplicates()
	await _focus_background()
	await _generic_confirm()
	await _reward_committed_only()
	await _pause_from_real_control()
	await _resume()
	await _restart_pre_action()
	await _restart_post_action()
	await _home_pre_action()
	await _home_post_action()
	await _insufficient_sb_context()
	await _busy_blocks_duplicates()
	await _network_retry_cancel()
	await _six_slot_survives()
	await _no_accumulation()
	await _responsive_matrix()
	await _home_bridge()
	_frames_promoted_unchanged()
	_shutdown()
	MainScript.boot_opening_override = -1
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _boot(level: int, size: Vector2i = Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m43c002_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _settle()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _stack() -> ModalStack:
	return _root.get_modal_stack()

func _eco():
	return _root.get_app_state().economy

func _settle() -> void:
	for _i in range(4):
		await process_frame

## Real routed tap (press + release) at a viewport position.
func _click(pos: Vector2) -> void:
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = pos
		e.global_position = pos
		_sub.push_input(e)
		await process_frame

func _center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

## First accepted real supply activation (arms WinStreak gameplay-start truth).
func _first_action() -> bool:
	for col in range(_host.get_supply().get_column_count()):
		if _host.get_input_controller().activate_front(col).get("ok", false):
			return true
	return false

func _set_streak(n: int) -> void:
	var snap: Dictionary = _eco().streak.snapshot()
	snap["streak"] = n
	_eco().streak.import_snapshot(snap)

func _set_hearts(n: int) -> void:
	_eco().hearts.import_snapshot({"hearts": n, "anchor": int(Time.get_unix_time_from_system())})

func _counter() -> Dictionary:
	return {"actions": [], "closed": [], "opened": 0}

func _watch(p, c: Dictionary) -> void:
	p.action_selected.connect(func(id, ctx): c["actions"].append([id, ctx]))
	p.closed.connect(func(r): c["closed"].append(r))
	p.opened.connect(func(): c["opened"] += 1)

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

# -------------------------------------------------------------------- cases ----

func _base_popup_lifecycle() -> void:
	print("[1 BasePopup lifecycle exactly once]")
	var p = Popups.confirm({"title": "T", "body": "B"})
	var c := _counter()
	_watch(p, c)
	_ok(not p.close("early"), "close before open is refused")
	_ok(_stack().push(p) and p.is_open() and c["opened"] == 1, "push opens once")
	_ok(not _stack().push(p), "second push of the same popup refused")
	await _settle()
	_ok(p.get_frame_texture_path().ends_with("popup_medium_frame.png") and p.get_title() == "T", "promoted frame + live title")
	_ok(p.close("x") and not p.close("y") and c["closed"] == ["x"] and c["opened"] == 1, "close emits exactly once")
	await _settle()
	_ok(not is_instance_valid(p) or p.is_queued_for_deletion() or p.get_parent() == null, "closed popup removed from the stack")
	_ok(not _stack().is_open() and not _host.get_runtime().is_user_paused(), "stack empty, modal hold released")
	var q = Popups.confirm({"title": "Q"})
	_stack().push(q)
	q.close("done")
	_ok(not _stack().push(q), "a closed popup can never be re-opened")
	_complete("base_popup_lifecycle")

func _stack_order() -> void:
	print("[2 stack order 2+ modals]")
	var a = Popups.confirm({"id": "a", "title": "A"})
	var b = Popups.confirm({"id": "b", "title": "B"})
	var c = Popups.confirm({"id": "c", "title": "C"})
	for p in [a, b, c]:
		_stack().push(p)
	_ok(_stack().ids() == ["a", "b", "c"] and _stack().top() == c and c.is_top() and not a.is_top() and not b.is_top(), "LIFO order, exactly one top")
	_stack().close_top()
	_ok(_stack().ids() == ["a", "b"] and b.is_top(), "closing top restores the next modal")
	b.close("x")
	_ok(_stack().ids() == ["a"] and a.is_top(), "next again")
	var d = Popups.confirm({"id": "d", "title": "D"})
	_stack().push(d)
	a.close("lower")   # closing a LOWER popup keeps the top owner
	_ok(_stack().ids() == ["d"] and d.is_top(), "closing a lower popup keeps the top")
	_stack().clear("t")
	_ok(_stack().depth() == 0, "clear empties the stack")
	await _settle()
	_complete("stack_order")

func _only_top_input() -> void:
	print("[3 only the top modal receives input]")
	var a = Popups.confirm({"id": "a", "title": "A"})
	var ca := _counter()
	_watch(a, ca)
	_stack().push(a)
	await _settle()
	var a_btn: Button = a.get_action_button("confirm")
	var a_pos := _center(a_btn)
	var b = Popups.confirm({"id": "b", "title": "B"})
	var cb := _counter()
	_watch(b, cb)
	_stack().push(b)
	await _settle()
	a_btn.pressed.emit()
	_ok(ca["actions"].is_empty() and a.is_open(), "lower popup rejects its own button signal")
	await _click(a_pos + Vector2(0, 300) if b.get_frame_rect().has_point(a_pos) else a_pos)
	_ok(ca["actions"].is_empty(), "routed tap never reaches the lower popup")
	await _click(_center(b.get_action_button("confirm")))
	_ok(cb["actions"].size() == 1 and cb["actions"][0][0] == "confirm", "routed tap on the top popup works (positive control)")
	await _settle()
	_ok(a.is_top(), "top restored to A")
	await _click(_center(a.get_action_button("cancel")))
	_ok(ca["closed"] == ["action:cancel"] and ca["actions"].size() == 1 and ca["actions"][0][0] == "cancel", "A receives input once it is top")
	await _settle()
	_complete("only_top_input")

func _gameplay_input_blocked() -> void:
	print("[4 gameplay behind a modal receives zero input]")
	var s = _host.get_screen()
	var sup0: Dictionary = _host.get_supply().debug_snapshot()
	var slots0: Array = _host.get_slots().snapshot()
	var p = _host.open_pause()
	await _settle()
	_ok(p != null and _host.get_runtime().is_user_paused() and _host.get_input_controller().is_modal_blocked(), "Pause holds runtime + input gate")
	# Real routed taps on every supply front, every booster, Pause and 2x.
	for hit in s.get_supply_panel().find_children("HitArea", "", true, false):
		await _click(_center(hit))
	for id in s.get_booster_ids():
		await _click(_center(s.get_booster_button(id)))
	await _click(_center(s.get_speed_button()))
	await _click(_center(s.get_pause_button()))
	var br: Rect2 = s.get_board_rect()
	await _click(br.get_center())
	_ok(_host.get_supply().debug_snapshot() == sup0 and _host.get_slots().snapshot() == slots0, "supply + slots unchanged by taps behind the modal")
	_ok(_host.last_booster_request.is_empty() and (_host.get_speed_acquisition_popup() == null or not _host.get_speed_acquisition_popup().visible), "no booster / 2x request reached the host")
	_ok(_stack().depth() == 1 and _stack().top() == p, "Pause / background controls did not stack a second modal")
	_ok(not _host.get_input_controller().activate_front(0).get("ok", true) and _host.request_booster("random").get("reason", "") == "modal_open", "programmatic paths rejected too")
	# Canonical pause semantics: agents do not move while the modal holds the runtime.
	p.get_action_button("resume").pressed.emit()
	await _settle()
	_first_action()
	for _i in range(8):
		_host.get_runtime().tick(0.05)
	var agents: Array = _host.get_agent_layer().get_children().filter(func(a): return a is ScrubbotAgent)
	var pos0: Array = agents.map(func(a): return a.position)
	var gen = Popups.confirm({"title": "Generic"})
	_stack().push(gen)
	for _i in range(20):
		_host.get_runtime().tick(0.05)
	_ok(not agents.is_empty() and agents.map(func(a): return a.position) == pos0, "agents frozen while a (non-Pause) modal is open")
	gen.close("t")
	_ok(not _host.get_runtime().is_user_paused() and not _host.get_input_controller().is_modal_blocked(), "closing releases the hold")
	await _settle()
	# The pure hold for tests below: restart with a fresh attempt at level 2.
	await _boot(2)
	_complete("gameplay_input_blocked")

func _back_escape_no_leak() -> void:
	print("[5 Back / Escape closes top only, never leaks]")
	var nav = _root.get_navigation()
	var p = _host.open_pause()
	await _settle()
	# Pre-action: with no modal, back WOULD exit to Home — so a leak would be visible.
	_ok(_root.handle_back() == "close_modal" and nav.current() == R.GAMEPLAY and not p.is_open(), "back closes Pause, gameplay stays")
	p = _host.open_pause()
	p.get_action_button("home").pressed.emit()
	await _settle()
	_ok(_stack().ids() == ["pause", "confirm_home"], "Pause + Home confirm stacked")
	_ok(_root.handle_back() == "close_modal" and _stack().ids() == ["pause"] and p.is_top(), "back closes ONLY the top confirm")
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	_sub.push_input(esc)
	await _settle()
	_ok(_stack().depth() == 0 and nav.current() == R.GAMEPLAY and _root.get_gameplay_host() == _host, "Escape closes Pause and does not exit gameplay")
	var busy = Popups.busy({})
	_stack().push(busy)
	await _settle()
	_ok(_root.handle_back() == "close_modal" and busy.is_open() and nav.current() == R.GAMEPLAY, "busy popup: back consumed, not closed, no leak")
	busy.close("t")
	await _settle()
	_ok(_eco().hearts.hearts() == 5 and nav.current() == R.GAMEPLAY, "no economy/route side effect")
	_complete("back_escape_no_leak")

func _rapid_duplicates() -> void:
	print("[6 rapid duplicate taps / open requests]")
	var first = _host.open_pause()
	var dup: Array = []
	for _i in range(5):
		dup.append(_host.open_pause())
		_host.get_screen().get_pause_button().pressed.emit()
	_ok(first != null and dup.all(func(x): return x == null) and _stack().depth() == 1, "5 extra open requests -> still one Pause")
	var c := _counter()
	_watch(first, c)
	for _i in range(3):
		first.get_action_button("resume").pressed.emit()
	_ok(c["actions"].size() == 1 and c["closed"].size() == 1 and not _host.get_runtime().is_user_paused(), "triple Resume -> one resume")
	await _settle()
	var p = _host.open_pause()
	for _i in range(3):
		p.get_action_button("restart").pressed.emit()
	_ok(_stack().ids() == ["pause", "confirm_restart"], "triple Restart -> one confirm")
	var conf = _stack().top()
	var cc := _counter()
	_watch(conf, cc)
	var retries := [0]
	_host.get_completion()   # touch
	var h0: int = _eco().hearts.hearts()
	for _i in range(3):
		conf.get_action_button("confirm").pressed.emit()
	_ok(cc["actions"].size() == 1 and _stack().depth() == 0 and _eco().hearts.hearts() == h0 and _host.last_pause_outcome == "restart", "triple confirm -> exactly one (pre-action, free) restart")
	await _settle()
	_complete("rapid_duplicates")

func _focus_background() -> void:
	print("[7 focus loss / background / resume: no duplicate callbacks]")
	var p = _host.open_pause()
	p.get_action_button("restart").pressed.emit()
	var conf = _stack().top()
	var c := _counter()
	_watch(conf, c)
	var rt = _host.get_runtime()
	for n in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT]:
		_root.propagate_notification(n)
	await _settle()
	_ok(rt.is_system_suspended() and rt.is_user_paused() and c["actions"].is_empty() and _stack().depth() == 2, "background: suspended, nothing fired, stack intact")
	for n in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN, Node.NOTIFICATION_WM_WINDOW_FOCUS_IN]:
		_root.propagate_notification(n)
	await _settle()
	_ok(not rt.is_system_suspended() and rt.is_user_paused() and c["actions"].is_empty() and _stack().depth() == 2, "resume: modal hold kept, nothing replayed")
	conf.get_action_button("cancel").pressed.emit()
	for n in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_IN]:
		_root.propagate_notification(n)
	await _settle()
	_ok(c["actions"].size() == 1 and c["actions"][0][0] == "cancel" and p.is_top() and not p.is_latched(), "cancel once; Pause re-armed; no replay")
	p.get_action_button("resume").pressed.emit()
	await _settle()
	# Pending transaction survives background and resolves exactly once.
	var busy = Popups.busy({"action_id": "buy"})
	_stack().push(busy)
	var tok: int = busy.get_pending_token()
	_root.propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	_root.propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	var res := [0]
	busy.pending_resolved.connect(func(_a, _r): res[0] += 1)
	_ok(tok > 0 and busy.resolve_pending(tok, {"ok": true}) and not busy.resolve_pending(tok, {"ok": true}) and res[0] == 1, "pending resolves exactly once across background")
	busy.close("t")
	await _settle()
	_complete("focus_background")

func _generic_confirm() -> void:
	print("[8 generic confirm: once / cancel no side effect]")
	var sb0: int = _eco().wallet.scrub_bucks()
	var fired := [0]
	var tokens: Array = []
	var p = Popups.confirm({"title": "SPEND?", "body": "Costly action", "warning": true, "context": {"token": "tx-42", "price": 350}})
	p.action_selected.connect(func(id, ctx):
		if id == "confirm":
			fired[0] += 1
			tokens.append(ctx["token"]))
	_stack().push(p)
	await _settle()
	_ok(p.get_frame_kind() == "warning", "optional warning treatment uses the promoted warning frame")
	p.get_action_button("confirm").pressed.emit()
	p.get_action_button("confirm").pressed.emit()
	await _click(Vector2(10, 10))
	_ok(fired[0] == 1 and tokens == ["tx-42"], "confirm fires exactly once with its pending context token")
	await _settle()
	for how in ["cancel", "back", "close_button"]:
		var q = Popups.confirm({"title": "X", "context": {"token": how}})
		var c := _counter()
		_watch(q, c)
		_stack().push(q)
		await _settle()
		match how:
			"cancel": q.get_action_button("cancel").pressed.emit()
			"back": _root.handle_back()
			"close_button": await _click(_center(q.get_close_button()))
		_ok((not is_instance_valid(q) or not q.is_open()) and c["closed"].size() == 1 and not c["actions"].any(func(a): return a[0] == "confirm"), "%s: closed without confirm" % how)
		await _settle()
	_ok(_eco().wallet.scrub_bucks() == sb0 and _eco().hearts.hearts() == 5, "no economy side effect from confirm/cancel popups")
	_complete("generic_confirm")

func _reward_committed_only() -> void:
	print("[9 reward/confirmation shows committed truth only]")
	_ok(Popups.reward({"rows": [{"text": "x"}]}) == null and Popups.reward({"committed": "yes"}) == null, "uncommitted spec is refused")
	# Caller commits a real action through the ONE facade, then shows its committed result.
	_set_hearts(4)
	_eco().wallet.credit("scrub_bucks", 500)
	var r: Dictionary = _host.get_actions().buy_heart()
	var sb1: int = _eco().wallet.scrub_bucks()
	var h1: int = _eco().hearts.hearts()
	_ok(r.get("ok", false) and h1 == 5, "caller-committed +1 Heart")
	var p = Popups.reward({"committed": true, "title": "HEART REFILLED",
		"rows": [{"text": "Hearts %d/5" % h1, "icon": "res://assets/ui/final/popups/failure/heart_large.png"}]})
	_stack().push(p)
	await _settle()
	_ok(p.get_frame_kind() == "reward" and p.find_child("Text", true, false).text == "Hearts 5/5", "promoted reward frame + committed live value")
	p.get_action_button("ok").pressed.emit()
	await _settle()
	_ok(_eco().wallet.scrub_bucks() == sb1 and _eco().hearts.hearts() == h1, "showing + acknowledging granted nothing more")
	_complete("reward_committed_only")

func _pause_from_real_control() -> void:
	print("[10 Pause opens from the real Gameplay V02 Pause control]")
	var s = _host.get_screen()
	await _click(_center(s.get_pause_button()))
	var p = _host.get_pause_popup()
	_ok(p != null and _stack().ids() == ["pause"] and s.is_paused_visual(), "routed tap on the baked Pause box opens Pause")
	var lvl: Label = p.find_child("LevelContext", true, false)
	_ok(lvl != null and lvl.text == UiText.t("RESULTS_LEVEL", [2]), "live level context: %s" % (lvl.text if lvl else "?"))
	_ok(p.get_action_ids() == ["resume", "restart", "home"] and p.get_action_button("resume").custom_minimum_size.y >= 112, "Resume (primary) / Restart / Home")
	await _click(_center(p.get_action_button("resume")))
	_ok(_host.get_pause_popup() == null and not _host.get_runtime().is_user_paused(), "routed Resume closes")
	await _settle()
	_complete("pause_from_real_control")

func _resume() -> void:
	print("[11 Resume resumes only what Pause suspended]")
	var rt = _host.get_runtime()
	rt.notify_focus_lost()
	var p = _host.open_pause()
	p.get_action_button("resume").pressed.emit()
	_ok(rt.is_system_suspended() and rt.is_paused() and not rt.is_user_paused(), "system suspension survives Resume")
	rt.notify_focus_gained()
	_ok(not rt.is_paused() and _host.last_pause_outcome == "resume" and not _host.get_screen().is_paused_visual(), "then fully live")
	await _settle()
	_complete("resume")

func _restart_pre_action() -> void:
	print("[12 Restart before the first action: no invented loss]")
	await _boot(2)
	_set_streak(3)
	var p = _host.open_pause()
	p.get_action_button("restart").pressed.emit()
	var conf = _stack().top()
	_ok(conf.popup_id == "confirm_restart" and conf.find_child("ConsequenceFree", true, false) != null
		and conf.find_child("ConsequenceHeart", true, false) == null and conf.get_frame_kind() == "medium", "confirm states NO loss (medium frame)")
	var n0: int = _host.get_board().count_cells_by_state(0)
	conf.get_action_button("confirm").pressed.emit()
	await _settle()
	_ok(_eco().hearts.hearts() == 5 and _eco().streak.streak() == 3 and _stack().depth() == 0 and not _host.get_runtime().is_user_paused()
		and _host.get_board().count_cells_by_state(0) == n0, "real Retry: hearts 5, streak 3 kept, stack empty, live")
	_complete("restart_pre_action")

func _restart_post_action() -> void:
	print("[13 Restart after gameplay began: M30/M39 truth]")
	_set_streak(3)
	_ok(_first_action(), "first real supply action")
	var pre: Dictionary = _host.attempt_consequence()
	_ok(pre["gameplay_started"] and pre["heart_loss"] and pre["hearts_before"] == 5 and pre["hearts_after"] == 4 and pre["streak_reset"] and pre["streak_before"] == 3, "consequence read from WinStreak/Heart authority")
	var p = _host.open_pause()
	p.get_action_button("restart").pressed.emit()
	var conf = _stack().top()
	var hl: Label = conf.find_child("ConsequenceHeart", true, false)
	var sl: Label = conf.find_child("ConsequenceStreak", true, false)
	_ok(conf.get_frame_kind() == "warning" and hl != null and hl.text == UiText.t("CONSEQ_HEART", [5, 4]) and sl != null and sl.text == UiText.t("CONSEQ_STREAK", [3]), "warning confirm: '%s' / '%s'" % [hl.text if hl else "?", sl.text if sl else "?"])
	conf.get_action_button("confirm").pressed.emit()
	await _settle()
	_ok(_eco().hearts.hearts() == pre["hearts_after"] and _eco().streak.streak() == 0 and not _eco().streak.gameplay_started(), "real Retry applied exactly the previewed loss")
	# NB-001 (C002 audit): real assertion — every slot unoccupied, board fully ACTIVE again.
	var b = _host.get_board()
	_ok(_host.get_slots().snapshot().all(func(sl2): return not bool(sl2["occupied"])) and _host.get_slots().snapshot().size() == 5
		and b.count_cells_by_state(0) == b.get_width() * b.get_height(), "fresh attempt: 5 empty slots, board fully ACTIVE")
	# Zero-Heart edge: consume() fails closed, so no Heart line is promised.
	_first_action()
	_set_hearts(0)
	var z: Dictionary = _host.attempt_consequence()
	var zc = Popups.attempt_confirm("restart", z)
	_ok(z["gameplay_started"] and not z["heart_loss"] and zc.find_child("ConsequenceHeart", true, false) == null, "0 Hearts: no Heart loss is claimed")
	zc.free()
	_set_hearts(5)
	await _settle()
	_complete("restart_post_action")

func _home_pre_action() -> void:
	print("[14 Home before the first action: no-cost exit]")
	await _boot(2)
	_set_streak(2)
	var nav = _root.get_navigation()
	var p = _host.open_pause()
	p.get_action_button("home").pressed.emit()
	var conf = _stack().top()
	_ok(conf.popup_id == "confirm_home" and conf.find_child("ConsequenceFree", true, false) != null, "confirm states no loss")
	conf.get_action_button("confirm").pressed.emit()
	await _settle()
	_ok(nav.current() == R.HOME and _root.get_gameplay_host() == null and _stack().depth() == 0, "HOME, host released, stack empty")
	_ok(_eco().hearts.hearts() == 5 and _eco().streak.streak() == 2, "no Heart / streak consequence")
	_complete("home_pre_action")

func _home_post_action() -> void:
	print("[15 Home after gameplay began: loss semantics]")
	await _boot(2)
	_set_streak(4)
	var nav = _root.get_navigation()
	_first_action()
	var p = _host.open_pause()
	p.get_action_button("home").pressed.emit()
	var conf = _stack().top()
	_ok(conf.find_child("ConsequenceHeart", true, false) != null and conf.find_child("ConsequenceStreak", true, false) != null, "confirm states -1 Heart + streak reset")
	conf.get_action_button("cancel").pressed.emit()
	_ok(nav.current() == R.GAMEPLAY and p.is_top() and not p.is_latched() and _eco().hearts.hearts() == 5 and _eco().streak.streak() == 4, "cancel: nothing changes, Pause re-armed")
	p.get_action_button("home").pressed.emit()
	_stack().top().get_action_button("confirm").pressed.emit()
	await _settle()
	_ok(nav.current() == R.HOME and _eco().hearts.hearts() == 4 and _eco().streak.streak() == 0 and not _eco().streak.gameplay_started(), "HOME with -1 Heart and streak 0")
	_ok(not _eco().capacity.plus_one_active(), "attempt-scoped capacity ended")
	_complete("home_post_action")

func _insufficient_sb_context() -> void:
	print("[16 insufficient SB preserves pending context]")
	await _boot(2)
	var pending := {"pending_id": "acq-7", "kind": "booster", "item": "tornado", "resume": "booster_acquire"}
	var sb0: int = _eco().wallet.scrub_bucks()
	var got: Array = []
	var p = Popups.insufficient_sb({"item_label": "Tornado", "price_sb": 750, "balance_sb": sb0, "pending": pending})
	p.action_selected.connect(func(id, ctx): got.append([id, ctx]))
	_stack().push(p)
	await _settle()
	pending["item"] = "mutated"
	p.get_action_button("shop").pressed.emit()
	_ok(got.size() == 1 and got[0][0] == "shop" and got[0][1]["pending"]["pending_id"] == "acq-7" and got[0][1]["pending"]["item"] == "tornado", "Shop route hands back the detached pending context")
	got[0][1]["pending"]["item"] = "caller-edit"
	_ok(p.context["pending"]["item"] == "tornado", "handed context is a copy")
	var q = Popups.insufficient_sb({"item_label": "Tornado", "price_sb": 750, "balance_sb": sb0, "pending": pending})
	var c := _counter()
	_watch(q, c)
	_stack().push(q)
	q.get_action_button("cancel").pressed.emit()
	_ok(c["actions"].size() == 1 and c["actions"][0][0] == "cancel" and _eco().wallet.scrub_bucks() == sb0, "cancel: clean, nothing spent")
	await _settle()
	_complete("insufficient_sb_context")

func _busy_blocks_duplicates() -> void:
	print("[17 busy blocks duplicate transaction actions]")
	var p = Popups.network_error({"surface": "store"})
	var c := _counter()
	_watch(p, c)
	_stack().push(p)
	await _settle()
	var btn: Button = p.get_action_button("retry")
	btn.pressed.emit()
	var tok: int = p.begin_pending("retry")
	for _i in range(3):
		btn.pressed.emit()
	await _click(_center(btn))
	_ok(c["actions"].size() == 1 and tok > 0 and p.is_busy() and btn.disabled and p.begin_pending("retry") == 0, "one unresolved transaction; duplicate taps / second begin refused")
	_ok(not p.request_back() and _root.handle_back() == "close_modal" and p.is_open(), "busy: back consumed, not closed")
	_ok(not p.resolve_pending(tok + 99, {"ok": true}) and p.is_busy(), "stale token ignored")
	_ok(p.resolve_pending(tok, {"ok": false, "reason": "offline"}) and not p.resolve_pending(tok, {"ok": true}) and not p.is_busy() and not btn.disabled, "resolve once -> usable again")
	p.close("t")
	# Timeout restores a deterministic usable state; a late callback is ignored.
	var b = Popups.busy({"timeout_s": 0.05})
	var outcome: Array = []
	b.pending_resolved.connect(func(a, r): outcome.append([a, r]))
	_stack().push(b)
	var bt: int = b.get_pending_token()
	await create_timer(0.2).timeout
	_ok(outcome.size() == 1 and outcome[0][1]["reason"] == "timeout" and not b.is_busy(), "timeout -> failure, not busy")
	_ok(not b.resolve_pending(bt, {"ok": true}) and outcome.size() == 1, "late success after timeout ignored")
	b.close("t")
	await _settle()
	_complete("busy_blocks_duplicates")

func _network_retry_cancel() -> void:
	print("[18 network/error: retry / recover / cancel deterministic]")
	for surf in Popups.NETWORK_SURFACES:
		var n = Popups.network_error({"surface": surf})
		_ok(n.popup_id == "network_" + surf and not UiText.t("NETWORK_BODY_" + surf.to_upper()).begins_with("NETWORK_"), "%s surface has live copy" % surf)
		n.free()
	var attempts := [0]
	var p = Popups.network_error({"surface": "rewarded_ad", "context": {"placement": "life"}})
	var c := _counter()
	_watch(p, c)
	p.action_selected.connect(func(id, _ctx):
		if id == "retry":
			attempts[0] += 1
			var t: int = p.begin_pending("retry")
			# Caller's external result: fail first, succeed second.
			p.resolve_pending(t, {"ok": attempts[0] >= 2})
	)
	p.pending_resolved.connect(func(_a, r):
		if r.get("ok", false):
			p.close("recovered"))
	_stack().push(p)
	await _settle()
	p.get_action_button("retry").pressed.emit()
	_ok(attempts[0] == 1 and p.is_open() and not p.is_busy() and not p.get_action_button("retry").disabled, "failed retry -> usable again")
	p.get_action_button("retry").pressed.emit()
	_ok(attempts[0] == 2 and c["closed"] == ["recovered"], "second retry recovers and closes")
	var q = Popups.network_error({"surface": "cloud"})
	var cq := _counter()
	_watch(q, cq)
	_stack().push(q)
	q.get_action_button("cancel").pressed.emit()
	_ok(cq["actions"].size() == 1 and cq["actions"][0][0] == "cancel" and cq["closed"] == ["action:cancel"], "cancel closes deterministically")
	# Generic success/failure feedback displays the caller-committed result only.
	var sb0: int = _eco().wallet.scrub_bucks()
	var okp = Popups.feedback({"ok": true, "text": "Timed 2x active"})
	var badp = Popups.feedback({"ok": false, "reason": "insufficient_sb"})
	_ok(okp.get_frame_kind() == "reward" and okp.get_content().get_node("Body").text == "Timed 2x active"
		and badp.get_frame_kind() == "warning" and badp.get_content().get_node("Body").text == UiText.t("FEEDBACK_REASON", ["insufficient_sb"]), "success/failure feedback shows the committed result")
	_stack().push(okp)
	okp.get_action_button("ok").pressed.emit()
	badp.free()
	_ok(_eco().wallet.scrub_bucks() == sb0 and _stack().depth() == 0, "feedback grants nothing")
	await _settle()
	_complete("network_retry_cancel")

func _six_slot_survives() -> void:
	print("[19 +1 Slot six-shell state survives the popup stack]")
	var s = _host.get_screen()
	_eco().boosters.add_charges("plus_one_slot", 1)
	_host.request_booster("plus_one_slot")
	await _settle()
	var shell0: String = s.get_shell_id()
	var snap0: Array = _host.get_slots().snapshot()
	var cap0: int = s.get_five_slot_strip().get_capacity()
	_ok(shell0.begins_with("6slot") and cap0 == 6, "six-slot shell active (%s)" % shell0)
	var p = _host.open_pause()
	p.get_action_button("restart").pressed.emit()
	await _settle()
	_stack().top().get_action_button("cancel").pressed.emit()
	var g = Popups.confirm({"title": "X"})
	_stack().push(g)
	await _settle()
	_stack().clear("t")
	await _settle()
	_ok(s.get_shell_id() == shell0 and s.get_five_slot_strip().get_capacity() == 6 and _host.get_slots().snapshot() == snap0
		and _eco().capacity.plus_one_active() and s.get_shell_error() == "", "shell / strip / engine / capacity unchanged")
	_complete("six_slot_survives")

func _no_accumulation() -> void:
	print("[20 no node / signal / timer accumulation]")
	await _settle()
	var n_root := _count(_root)
	var n_stack := _count(_stack())
	var conn: int = _stack().modal_changed.get_connections().size()
	var pconn: int = _host.get_screen().get_pause_button().pressed.get_connections().size()
	var timers: int = _root.find_children("*", "Timer", true, false).size()
	for _i in range(10):
		var p = _host.open_pause()
		p.get_action_button("restart").pressed.emit()
		_stack().top().get_action_button("cancel").pressed.emit()
		p.get_action_button("home").pressed.emit()
		_root.handle_back()
		p.get_action_button("resume").pressed.emit()
		var b = Popups.busy({"timeout_s": 5.0})
		_stack().push(b)
		b.close("t")
		await _settle()
	await _settle()
	_ok(_count(_root) == n_root and _count(_stack()) == n_stack, "nodes stable (%d -> %d, stack %d -> %d)" % [n_root, _count(_root), n_stack, _count(_stack())])
	_ok(_stack().modal_changed.get_connections().size() == conn and _host.get_screen().get_pause_button().pressed.get_connections().size() == pconn, "signal connections stable")
	_ok(_root.find_children("*", "Timer", true, false).size() == timers, "timers stable")
	# Host release disconnects from the shared stack.
	_root.get_navigation()
	_host.open_pause().get_action_button("home").pressed.emit()
	_stack().top().get_action_button("confirm").pressed.emit()
	await _settle()
	_ok(_stack().modal_changed.get_connections().size() == conn - 1 and _stack().depth() == 0, "released host leaves no stack connection")
	_complete("no_accumulation")

func _responsive_matrix() -> void:
	print("[H responsive phone / tablet]")
	for sz in [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 1920), Vector2i(1536, 2048)]:
		await _boot(2, sz)
		_stack().set_synthetic_safe_insets(0, 96, 0, 64)
		_first_action()
		var p = _host.open_pause()
		await _settle()
		p.get_action_button("home").pressed.emit()
		await _settle()
		var conf = _stack().top()
		var vp := Rect2(Vector2(0, 96), Vector2(_sub.size) - Vector2(0, 160))
		var ok := true
		for pp in [p, conf]:
			ok = ok and pp.text_fits() and vp.encloses(pp.get_frame_rect())
			for id in pp.get_action_ids():
				ok = ok and pp.get_action_button(id).size.y >= UiTokens.TOUCH_MIN
			ok = ok and (not pp.get_close_button().visible or pp.get_close_button().size.y >= UiTokens.TOUCH_MIN)
		_ok(ok, "%dx%d: Pause + loss confirm fit inside safe area, targets >= %d px" % [sz.x, sz.y, UiTokens.TOUCH_MIN])
	_complete("responsive_matrix")

func _home_bridge() -> void:
	print("[home bridge: Home input hidden while a stacked popup is open]")
	await _boot(2)
	var nav = _root.get_navigation()
	_host.open_pause().get_action_button("home").pressed.emit()
	_stack().top().get_action_button("confirm").pressed.emit()
	await _settle()
	var home = _root.get_home()
	_ok(nav.current() == R.HOME and not home.is_modal_active(), "Home live")
	var p = Popups.confirm({"title": "On Home"})
	_stack().push(p)
	_ok(home.is_modal_active(), "stack popup -> Home action layer hidden")
	_ok(_root.handle_back() == "close_modal" and not home.is_modal_active() and nav.current() == R.HOME, "back closes it, Home restored")
	await _settle()
	_complete("home_bridge")

func _frames_promoted_unchanged() -> void:
	print("[frames: promoted art only, untouched]")
	var out := OS.execute("git", ["diff", "--quiet", "HEAD", "--", "assets/ui/final/common/frames"])
	_ok(out == 0, "git diff on promoted popup frames is empty")
	for k in BasePopup.FRAMES:
		_ok(ResourceLoader.exists(BasePopup.FRAMES[k]["path"]), "%s frame exists" % k)
	_complete("frames_promoted_unchanged")

# ------------------------------------------------------------------ helpers ----

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
	print("M43-C002-C001 popup / modal / Pause foundation evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
