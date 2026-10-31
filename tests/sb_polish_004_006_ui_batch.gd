extends SceneTree
## SB-POLISH-004 / 005 / 006 — owner phone-playtest polish batch (2026-10-31), real app root
## (main.tscn) in a 1080x2160 SubViewport, real pointer events through the viewport GUI:
##   004 CLEAN NEXT answers the first tap: the finished board's top_level Supply HitAreas no longer
##       sit above Results (they were their own GUI roots and silently ate the tap);
##   005 Robots rows 1 (Scrubby, ACTIVE) and 2 (Moppy, UNLOCK) open their detail card on a row tap,
##       ACTIVE / UNLOCK buttons unchanged, a swipe opens nothing;
##   006 Home Scrub Bucks "+" opens the focused Scrub Bucks popup (balance + SB packs, honestly
##       UNAVAILABLE), MORE IN SHOP hands off to the full Shop.
##
## Run: godot --headless --path . -s res://tests/sb_polish_004_006_ui_batch.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const R := NavigationController.Route

var EXPECTED_CASES := [
	"p004_hit_areas_off_after_terminal", "p004_clean_next_first_tap", "p004_retry_restores_hit_areas",
	"p005_scrubby_row_detail", "p005_moppy_row_detail", "p005_buttons_unchanged", "p005_swipe_opens_nothing",
	"p006_sb_plus_focused_popup", "p006_more_in_shop",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	await _p004()
	await _p005()
	await _p006()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _p004() -> void:
	print("[p004 Results CLEAN NEXT: first tap, nothing above it]")
	await _boot("p004")
	var nav = _root.get_navigation()
	_root.play_current_frontier()
	await _frames(2)
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)
	_drain(h)
	await _frames(3)
	var res = _root.get_results_screen()
	res.finish_reveal()
	await _frames(3)
	var hits := _hit_areas(h)
	_ok(not hits.is_empty() and hits.all(func(c): return c.mouse_filter == Control.MOUSE_FILTER_IGNORE), "terminal: all %d top_level Supply HitAreas stop picking" % hits.size())
	_complete("p004_hit_areas_off_after_terminal")
	var b: Button = res.get_primary_button()
	var r: Rect2 = b.get_global_rect()
	var bad: Array = []
	for fx in [0.05, 0.25, 0.5, 0.75, 0.95]:
		for fy in [0.1, 0.5, 0.9]:
			var p := r.position + r.size * Vector2(fx, fy)
			_move(p)
			await process_frame
			if _sub.gui_get_hovered_control() != b:
				bad.append("%s->%s" % [str(p), str(_sub.gui_get_hovered_control())])
	_ok(nav.current() == R.RESULTS and not b.disabled and b.text == UiText.t("RESULTS_CLEAN_NEXT") and r.size.y >= UiTokens.TOUCH_MIN and r.size.x >= UiTokens.TOUCH_MIN,
		"CLEAN NEXT live, hit area %s >= %d px" % [str(r.size), UiTokens.TOUCH_MIN])
	_ok(bad.is_empty(), "15 points across CLEAN NEXT all pick the button itself %s" % str(bad))
	var t0: int = nav.transition_id()
	await _click(r.get_center())
	await _frames(2)
	_ok(nav.current() == R.GAMEPLAY and nav.transition_id() == t0 + 1 and int(_root.get_gameplay_host().progression_level) == 2, "ONE real tap -> next level (Level 2)")
	_complete("p004_clean_next_first_tap")
	var h2 = _root.get_gameplay_host()
	var hits2 := _hit_areas(h2)
	_ok(not hits2.is_empty() and hits2.all(func(c): return c.mouse_filter == Control.MOUSE_FILTER_STOP), "the new level's fronts pick again")
	var input = h2.get_input_controller()
	input.set_terminal_stopped(true)
	var off := hits2.all(func(c): return c.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	input.set_terminal_stopped(false)   # what Retry does for a fresh attempt
	_ok(off and hits2.all(func(c): return c.mouse_filter == Control.MOUSE_FILTER_STOP), "terminal -> IGNORE, retry -> STOP again")
	_complete("p004_retry_restores_hit_areas")

func _p005() -> void:
	print("[p005 Robots rows 1-2 open details; ACTIVE / UNLOCK unchanged]")
	await _boot("p005")
	var e = _eco()
	var p = RobotsScreen.open(_root.get_modal_stack(), _root.get_app_state(), _root.ceremonies)
	await _frames(3)
	await _click(_row_name("scrubby"))
	await _frames(2)
	var d = _top()
	_ok(_top_id() == "robot_detail" and d.find_child("PreviewArt", true, false).texture.resource_path == RobotRoster.entry("scrubby")["assets"]["master"]
		and d.find_child("Lock", true, false) == null and d.find_child("Required", true, false) == null, "tap Scrubby row -> unlocked detail (art, no lock, no Bot Parts need)")
	_ok(_label(d, "Perk").begins_with(String(RobotRoster.entry("scrubby")["perk_name"])) and _label(d, "Role") == String(RobotRoster.entry("scrubby")["role"]) and d.get_action_ids() == ["back"], "role + perk, BACK only")
	d._on_action("back")
	await _frames(2)
	_complete("p005_scrubby_row_detail")
	await _click(_row_name("moppy"))
	await _frames(2)
	d = _top()
	_ok(_top_id() == "robot_detail" and d.find_child("Lock", true, false) != null and _label(d, "Required") == UiText.t("ROBOTS_DETAIL_NEED", ["250", "0"]), "tap Moppy row -> locked detail, 250 Bot Parts needed")
	d._on_action("back")
	await _frames(2)
	_complete("p005_moppy_row_detail")
	_ok(_top() == p, "back on the roster")
	await _click(_center(p.get_action_button("robot:scrubby")))
	await _frames(2)
	_ok(_top() == p and e.robots.active_robot() == "scrubby" and p.get_action_button("robot:scrubby").text == UiText.t("ROBOTS_ACTIVE") and p.get_action_button("robot:scrubby").disabled, "ACTIVE button: still blocked, opens nothing")
	e.wallet.credit(EconomyWallet.BOT_PARTS, 300)
	RobotsScreen.refresh(p, e)
	await _frames(1)
	await _click(_center(p.get_action_button("robot:moppy")))
	await _frames(3)
	_ok(e.robots.is_unlocked("moppy") and e.wallet.bot_parts() == 50 and _top_id() == "ceremony_robot_unlock", "UNLOCK button: unlocks Moppy + ceremony, no detail card (got %s)" % _top_id())
	_complete("p005_buttons_unchanged")
	_top()._on_action("keep")
	await _frames(3)
	await create_timer(0.5).timeout
	_ok(_top() == p, "roster again after the ceremony")
	var a := _row_name("atlas")
	await _press_release(a, a + Vector2(0, -120))
	await _frames(2)
	_ok(_top() == p, "a swipe that starts on a row opens no detail")
	_complete("p005_swipe_opens_nothing")

func _p006() -> void:
	print("[p006 Home SB + -> focused Scrub Bucks popup -> MORE IN SHOP]")
	await _boot("p006")
	var e = _eco()
	var sb0: int = e.wallet.scrub_bucks()
	var tickets: Array = []
	_root.shop.shop_requested.connect(func(t): tickets.append(t))
	await _click(_center(_root.get_home().find_child("ScrubBucksPlus", true, false)))
	await _frames(2)
	var p = _top()
	_ok(_top_id() == "scrub_bucks" and _root.get_modal_stack().depth() == 1 and tickets.is_empty(), "SB + opens the focused popup, not the Shop")
	_ok(_label(p, "Balance") == UiText.t("ACQ_BALANCE", [UiText.num(sb0)]), "live SB balance '%s'" % _label(p, "Balance"))
	_ok(_label(p, "PackTitle") == UiText.t("SHOP_SB_PACKS") and _label(p, "PackDetail") == UiText.t("SHOP_STORE_LATER"), "only the SB pack offer, 'Available when the store opens.'")
	var pack: Button = p.get_action_button("sb_pack")
	_ok(pack.disabled and pack.text == UiText.t("SHOP_UNAVAILABLE") and p.get_action_ids() == ["sb_pack", "shop", "close"], "pack honestly UNAVAILABLE; actions %s" % str(p.get_action_ids()))
	await _click(_center(pack))
	await _frames(2)
	_ok(_top() == p and e.wallet.scrub_bucks() == sb0 and tickets.is_empty(), "tapping UNAVAILABLE does nothing (no purchase, no currency)")
	_complete("p006_sb_plus_focused_popup")
	await _click(_center(p.get_action_button("shop")))
	await _frames(3)
	_ok(_top_id() == "shop" and _root.get_modal_stack().ids() == ["shop"] and tickets.size() == 1 and String(tickets[0]["source"]) == "home_sb_plus", "MORE IN SHOP -> full Shop (source home_sb_plus), SB popup gone")
	_top().close("test")
	await _frames(2)
	_ok(_root.get_modal_stack().depth() == 0 and _root.shop.open_tickets().is_empty() and e.wallet.scrub_bucks() == sb0, "Shop closed: back on Home, ticket finished, SB unchanged")
	_complete("p006_more_in_shop")

# ------------------------------------------------------------------ helpers ----

## SB-POLISH-002 precedent: Gift Meter already at 1 with milestone 1 seen, so a Level 1 win
## crosses no milestone (no ceremony barrier holds CLEAN NEXT).
func _boot(tag: String) -> void:
	_shutdown()
	var path := "user://sbpolish004_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var seed = AppState.new(path)
	for o in seed.economy.gift.add_streak_sb("test_seed_m1", 1):
		seed.economy.meta_ui.mark_seen("gift:" + String(o["id"]))
	seed.request_save()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
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
	MainScript.boot_save_path_override = ""

func _hit_areas(h) -> Array:
	return h.find_children("HitArea", "Control", true, false)

func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	var scheduler = h.get_scheduler()
	for _i in range(80000):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(1.0)
		if h.get_completion().is_terminal():
			break
		if supply.is_exhausted() and scheduler.live_assignment_count() == 0 and not _any_moving(h.get_agent_layer()):
			runtime.tick(1.0)
			runtime.tick(1.0)
			break

func _any_moving(agent_layer) -> bool:
	if agent_layer == null:
		return false
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return true
	return false

func _move(pos: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	_sub.push_input(m)

func _button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	_sub.push_input(e)

func _click(pos: Vector2) -> void:
	await _press_release(pos, pos)

func _press_release(a: Vector2, b: Vector2) -> void:
	_move(a)
	_button(a, true)
	await process_frame
	if b != a:
		_move(b)
		await process_frame
	_button(b, false)
	await process_frame

func _center(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func _row_name(id: String) -> Vector2:
	return _center(_top().find_child("Robot_" + id, true, false).find_child("Name", true, false))

func _label(p, n: String) -> String:
	var l = p.find_child(n, true, false)
	return l.text if l is Label else ""

func _eco():
	return _root.get_app_state().economy

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

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
	print("SB-POLISH-004/005/006 UI batch evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
