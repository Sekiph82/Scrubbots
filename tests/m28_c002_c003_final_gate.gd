extends SceneTree
## M28-C002-C003 — Gameplay V02 final popup-inclusive gate (SB-M28-C002-012 / 013 / 019).
## Real app root (main.tscn) with an injected wall clock, real frontier launch, real
## ProductionGameplayHost + GameplayScreen, the ONE app ModalStack / AcquisitionFlow.
## Every entry is driven through the VISIBLE Gameplay V02 controls with routed pointer
## input (SubViewport.push_input): booster row, 2x box, Pause box, popup buttons / chips /
## close X. Economy setup only through canonical services on a temp save.
##
## Run: godot --headless --path . -s res://tests/m28_c002_c003_final_gate.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const SpeedAcquisitionPopup = preload("res://scripts/ui/speed_acquisition_popup.gd")
const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const AcquisitionFlow = preload("res://scripts/ui/popup/acquisition_flow.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const T0 := 1_900_000_000
const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]
const MATRIX := [
	Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400),
	Vector2i(1440, 3200), Vector2i(1080, 1920), Vector2i(1536, 2048),
]

var EXPECTED_CASES := [
	"g01_plus_one_visible_acquire", "g02_target_visible_acquire", "g03_open_no_debit",
	"g04_close_cancel_no_mutation", "g05_supply_blocked", "g06_booster_row_blocked",
	"g07_sixth_slot_under_popup", "g08_speed_visible_acquire", "g09_speed_open_no_debit",
	"g10_speed_purchase_once", "g11_entitled_switch_free", "g12_timed_countdown_live",
	"g13_pause_visible", "g14_top_modal_only", "g15_no_click_through", "g16_rapid_taps",
	"g17_geometry_unchanged", "g18_no_accumulation", "charge_first", "sb_commit_canonical",
	"auto_2x_independent", "responsive_matrix",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [T0]
var _sub: SubViewport
var _root
var _host

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	await _boot(2)
	await _g01_plus_one_visible_acquire()
	await _g02_target_visible_acquire()
	await _g04_close_cancel_no_mutation()
	await _g05_g06_background_blocked()
	await _g15_no_click_through()
	await _g14_top_modal_only()
	await _g13_pause_visible()
	await _g17_geometry_unchanged()
	await _charge_first()
	await _g07_sixth_slot_under_popup()
	await _sb_commit_canonical()
	await _g08_speed_visible_acquire()
	await _g10_speed_purchase_once()
	await _g11_entitled_switch_free()
	await _g12_timed_countdown_live()
	await _auto_2x_independent()
	await _g16_rapid_taps()
	await _g18_no_accumulation()
	await _responsive_matrix()
	_shutdown()
	MainScript.boot_opening_override = -1
	MainScript.boot_clock_override = Callable()
	_cleanup()
	_done()

# ------------------------------------------------------------------ fixtures ----

func _boot(level: int, size: Vector2i = Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m28c003_%d.save" % Time.get_ticks_usec()
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
	_set_sb(5000)
	_host._refresh_hud()
	await _settle()

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null
	MainScript.boot_save_path_override = ""

func _eco():
	return _root.get_app_state().economy

func _stack():
	return _root.get_modal_stack()

func _acq():
	return _root.get_acquisition()

func _screen():
	return _host.get_screen()

func _settle() -> void:
	for _i in range(4):
		await process_frame

func _set_sb(n: int) -> void:
	var w = _eco().wallet
	var cur: int = w.scrub_bucks()
	if cur > n:
		w.debit("scrub_bucks", cur - n)
	elif cur < n:
		w.credit("scrub_bucks", n - cur)

func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	_sub.push_input(e)

## One routed mouse click (press + release on separate frames), then settle.
func _click(pos: Vector2) -> void:
	_mouse(pos, true)
	await process_frame
	_mouse(pos, false)
	await _settle()

func _click_c(c: Control) -> void:
	await _click(c.get_global_rect().get_center())

## n complete clicks inside ONE frame (the fastest possible physical double/triple tap).
func _rapid(pos: Vector2, n: int) -> void:
	for _i in range(n):
		_mouse(pos, true)
		_mouse(pos, false)
	await _settle()

func _touch(pos: Vector2, idx: int = 0) -> void:
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = idx
		e.pressed = pressed
		e.position = pos
		_sub.push_input(e)
		await process_frame
	await _settle()

## Visible booster control tap.
func _tap_booster(id: String) -> void:
	await _click_c(_screen().get_booster_button(id))

func _tap_speed() -> void:
	await _click_c(_screen().get_speed_button())

func _tap_pause() -> void:
	await _click_c(_screen().get_pause_button())

func _close_x(p) -> void:
	await _click_c(p.get_close_button())

func _chips(p) -> Array:
	var f = p.find_child("Targets", true, false)
	return [] if f == null else f.get_children().filter(func(c): return not c.is_queued_for_deletion())

## Full economy + gameplay truth (compared for "nothing mutated").
func _truth() -> Dictionary:
	return {"eco": _eco().snapshot(), "sb": _eco().wallet.scrub_bucks(),
		"supply": _host.get_supply().debug_snapshot(), "slots": _host.get_slots().snapshot(),
		"board_rev": _host.get_board().get_revision(), "cleared": _host.get_board().count_cells_by_state(1),
		"capacity": _screen().get_five_slot_strip().get_capacity(),
		"speed_2x": _host.get_speed_authority().is_2x()}

func _geometry() -> Dictionary:
	var s = _screen()
	var g := {"board": s.get_board_rect(), "strip": s.get_five_slot_strip_rect(), "supply": s.get_supply_panel_rect(),
		"boosters": s.get_booster_row_rect(), "pause": s.get_pause_rect(), "speed": s.get_speed_control_rect(),
		"shell": s.get_shell_rect(), "top": s.get_top_region_rect(), "connectors": s.get_connector_segments()}
	var views: Array = []
	for v in s.get_five_slot_strip().get_slot_views():
		views.append(v.get_global_rect())
	g["slot_views"] = views
	var fronts: Array = []
	for col in range(s.get_supply_panel().get_column_count()):
		fronts.append(s.get_supply_panel().get_column_row_panels(col)[0].get_global_rect())
	g["fronts"] = fronts
	for id in BOOSTERS:
		g["b_" + id] = s.get_booster_button(id).get_global_rect()
	return g

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

func _occupied() -> int:
	return _host.get_slots().snapshot().filter(func(s): return bool(s.get("occupied", false))).size()

# ============================================================ SB-M28-C002-012 ====

func _g01_plus_one_visible_acquire() -> void:
	print("[G1/G3 zero-charge +1 Slot visible tap -> canonical Booster Acquire, no debit]")
	var s = _screen()
	_ok(s.get_booster_ids() == BOOSTERS and s.get_booster_count() == 4, "exactly the four canonical boosters on the visible row")
	_ok(_host.get_modal_stack() == _stack(), "host uses the ONE app ModalStack")
	var t0 := _truth()
	var asked: Array = []
	_host.booster_acquire_requested.connect(func(id): asked.append(id))
	await _tap_booster("plus_one_slot")
	var p = _stack().top()
	_ok(_stack().ids() == ["booster_plus_one_slot"] and p is BasePopup and p == _acq().find_open("booster_plus_one_slot"),
		"visible +1 Slot tap -> booster_plus_one_slot on the shared ModalStack")
	_ok(_host.last_booster_request.get("reason") == "acquire_required" and asked == ["plus_one_slot"], "not a silent failure: reason acquire_required + acquire seam emitted once")
	_ok(p.find_child("Owned", true, false).text == UiText.t("BOOSTER_OWNED", [0])
		and p.get_action_button("sb").text == UiText.t("BOOSTER_USE_SB", [UiText.num(500)])
		and p.find_child("Balance", true, false).text == UiText.t("ACQ_BALANCE", [UiText.num(5000)])
		and p.find_child("Safety", true, false).text == "" and not p.get_action_button("sb").disabled,
		"live charge 0 / price 500 SB / balance 5,000 / legal (no safety line, SB CTA armed)")
	_ok(_truth() == t0, "opening spent nothing and mutated no economy/gameplay truth")
	_complete("g01_plus_one_visible_acquire")
	_complete("g03_open_no_debit")
	await _close_x(p)
	_ok(_stack().depth() == 0 and _truth() == t0, "close X: stack empty, truth unchanged")

func _g02_target_visible_acquire() -> void:
	print("[G2 zero-charge Selector / Tornado visible tap -> matching popup + owner-approved picker]")
	for id in ["selector", "tornado", "random"]:
		var t0 := _truth()
		await _tap_booster(id)
		var p = _stack().top()
		_ok(_stack().ids() == ["booster_" + id] and p.get_title() == UiText.t("BOOSTER_NAME_" + id.to_upper()), "%s: visible tap -> booster_%s" % [id, id])
		if id == "random":
			_ok(_chips(p).is_empty() and p.get_action_button("sb").text == UiText.t("BOOSTER_USE_SB", [UiText.num(350)]), "random: no picker, 350 SB")
		else:
			var leg: Dictionary = _host.booster_legality(id)
			var chips := _chips(p)
			var proof: Array = _host.get_booster_adapter().eligible_safe_batches() if id == "selector" else _host.get_booster_adapter().present_colors()
			var keys_ok := true
			for t in leg["targets"]:
				keys_ok = keys_ok and proof.has(t["key"])
			_ok(chips.size() == mini(leg["targets"].size(), AcquisitionFlow.MAX_TARGET_CHIPS) and chips.size() > 0 and keys_ok,
				"%s: %d picker chips, every key from the solver-safe adapter proof" % [id, chips.size()])
			_ok(p.get_action_button("sb").disabled and p.context["target"] == null, "%s: SB CTA waits for a target" % id)
			await _click_c(chips[0])
			_ok(p.context["target"] != null and not p.get_action_button("sb").disabled and (chips[0] as Button).button_pressed, "%s: routed chip tap selects target, CTA arms" % id)
			_ok(_truth() == t0, "%s: picking a target spends/mutates nothing" % id)
		await _close_x(p)
		_ok(_stack().depth() == 0 and _truth() == t0, "%s: close X -> no mutation" % id)
	_complete("g02_target_visible_acquire")

func _g04_close_cancel_no_mutation() -> void:
	print("[G4 close / Back / Escape without commit mutates nothing]")
	var t0 := _truth()
	var ways := ["x", "back", "escape", "x"]
	for i in range(BOOSTERS.size()):
		var id: String = BOOSTERS[i]
		await _tap_booster(id)
		var p = _stack().top()
		if not _chips(p).is_empty():
			await _click_c(_chips(p)[0])
		match ways[i]:
			"x":
				await _close_x(p)
			"back":
				_ok(_root.handle_back() == "close_modal", "%s: Android Back closes the popup" % id)
				await _settle()
			"escape":
				var esc := InputEventAction.new()
				esc.action = "ui_cancel"
				esc.pressed = true
				_sub.push_input(esc)
				await _settle()
		_ok(_stack().depth() == 0 and (not is_instance_valid(p) or not p.is_open()) and _truth() == t0 and not _host.get_runtime().is_user_paused(),
			"%s via %s: closed, runtime released, economy + gameplay identical" % [id, ways[i]])
	_complete("g04_close_cancel_no_mutation")

func _g05_g06_background_blocked() -> void:
	print("[G5/G6 background supply + booster row + 2x + Pause blocked under Booster Acquire]")
	var s = _screen()
	await _tap_booster("tornado")
	var p = _stack().top()
	var t0 := _truth()
	var req0: Dictionary = _host.last_booster_request.duplicate(true)
	_ok(_host.get_runtime().is_user_paused() and _host.get_input_controller().is_modal_blocked(), "modal hold: runtime paused + input gate closed")
	for hit in s.get_supply_panel().find_children("HitArea", "", true, false):
		await _click_c(hit)
		await _touch(hit.get_global_rect().get_center())
	_ok(_truth() == t0 and _stack().ids() == ["booster_tornado"], "every supply front (mouse + touch): zero activations")
	_complete("g05_supply_blocked")
	for id in BOOSTERS:
		await _tap_booster(id)
	await _tap_speed()
	await _tap_pause()
	await _click(s.get_board_rect().get_center())
	_ok(_host.last_booster_request == req0 and _stack().ids() == ["booster_tornado"] and p.is_top() and _truth() == t0,
		"booster row / 2x / Pause / board taps behind the modal: no request, no second modal, no mutation")
	_ok(_host.request_booster("random").get("reason") == "modal_open", "programmatic booster path also refused while modal")
	_complete("g06_booster_row_blocked")
	await _close_x(p)
	# Positive controls: the same routed input reaches gameplay once the modal is gone.
	var occ0 := _occupied()
	var hits: Array = s.get_supply_panel().find_children("HitArea", "", true, false)
	await _touch(hits[0].get_global_rect().get_center())
	var touched := _occupied() > occ0
	if not touched:
		await _click_c(hits[0])
	_ok(_occupied() > occ0, "after close the same supply front activates again (%s)" % ("touch" if touched else "mouse"))

func _g15_no_click_through() -> void:
	print("[G15 no click-through after close]")
	await _boot(2)
	var s = _screen()
	for id in ["plus_one_slot", "tornado"]:
		await _tap_booster(id)
		var p = _stack().top()
		var t0 := _truth()
		var req0: Dictionary = _host.last_booster_request.duplicate(true)
		var xpos: Vector2 = p.get_close_button().get_global_rect().get_center()
		_mouse(xpos, true)
		await process_frame
		_mouse(xpos, false)
		# The release that closed the popup and the following frames must not reach gameplay.
		_mouse(xpos, true)
		_mouse(xpos, false)
		await _settle()
		_ok(_stack().depth() == 0 and _truth() == t0 and _host.last_booster_request == req0 and not _host.get_input_controller().is_modal_blocked(),
			"%s: X close + follow-up tap at the same point: no gameplay/booster/2x/Pause side effect" % id)
	# Pause resume button: close by action, the tap does not leak.
	await _tap_pause()
	var pp = _host.get_pause_popup()
	var t1 := _truth()
	await _click_c(pp.get_action_button("resume"))
	_ok(_stack().depth() == 0 and _truth() == t1 and not _host.get_runtime().is_user_paused(), "Pause RESUME: closed, runtime resumed, no leaked tap")
	_complete("g15_no_click_through")

func _g14_top_modal_only() -> void:
	print("[G14 Pause / acquisition stacking: only the top modal owns input]")
	await _tap_pause()
	var pp = _host.get_pause_popup()
	await _click_c(pp.get_action_button("restart"))
	_ok(_stack().ids() == ["pause", "confirm_restart"] and not pp.is_top(), "Pause -> Restart confirm stacked")
	var t0 := _truth()
	# Routed taps on lower Pause controls that the top confirm frame does not cover land on the
	# top scrim; controls under the top frame are driven directly (the top-only guard).
	var top_frame: Rect2 = _stack().top().get_frame_rect()
	var routed := 0
	for b in [pp.get_action_button("resume"), pp.get_action_button("home"), pp.get_close_button()]:
		var c: Vector2 = b.get_global_rect().get_center()
		if top_frame.has_point(c):
			b.pressed.emit()
		else:
			routed += 1
			await _click(c)
	# Plus routed taps on the scrim outside the top frame (gameplay + lower popup area).
	for pt in [Vector2(40, 40), _screen().get_board_rect().get_center(), _screen().get_speed_button().get_global_rect().get_center()]:
		if not top_frame.has_point(pt):
			routed += 1
			await _click(pt)
	_ok(_stack().ids() == ["pause", "confirm_restart"] and _truth() == t0 and routed > 0, "lower Pause RESUME / HOME / X + %d routed scrim taps do nothing while the confirm is top" % routed)
	await _click_c(_stack().top().get_action_button("cancel"))
	_ok(_stack().ids() == ["pause"] and pp.is_top(), "Keep playing closes only the confirm; Pause is top again")
	await _click_c(pp.get_action_button("resume"))
	# Acquisition stack: Booster Acquire -> Insufficient SB (top) -> Back pops only the top.
	_set_sb(100)
	await _tap_booster("tornado")
	var bp = _stack().top()
	await _click_c(_chips(bp)[0])
	await _click_c(bp.get_action_button("sb"))
	var sb_after: int = _eco().wallet.scrub_bucks()
	_ok(_stack().ids() == ["booster_tornado", "insufficient_sb"] and sb_after == 100, "insufficient SB stacks on top; nothing spent")
	var t1 := _truth()
	await _click(bp.get_close_button().get_global_rect().get_center())
	_ok(_stack().ids() == ["booster_tornado", "insufficient_sb"] and _truth() == t1, "lower Booster Acquire X is not reachable")
	_ok(_root.handle_back() == "close_modal" and _stack().ids() == ["booster_tornado"] and bp.is_top(), "Back pops ONLY the top modal")
	await _close_x(bp)
	_set_sb(5000)
	_complete("g14_top_modal_only")

func _g13_pause_visible() -> void:
	print("[G13 Pause from the visible Pause control]")
	await _tap_pause()
	var pp = _host.get_pause_popup()
	_ok(pp != null and _stack().ids() == ["pause"] and _host.get_runtime().is_user_paused() and _screen().is_paused_visual(), "visible Pause tap -> canonical Pause popup, runtime held")
	await _click_c(pp.get_action_button("resume"))
	_ok(_stack().depth() == 0 and not _host.get_runtime().is_user_paused(), "RESUME tap -> closed + resumed")
	_complete("g13_pause_visible")

func _g17_geometry_unchanged() -> void:
	print("[G17 five-slot / supply / board / booster geometry unchanged by the popup integration]")
	var g0 := _geometry()
	var bad: Array = []
	for step in ["booster", "selector", "speed", "pause"]:
		match step:
			"booster":
				await _tap_booster("plus_one_slot")
			"selector":
				await _tap_booster("selector")
			"speed":
				await _tap_speed()
			"pause":
				await _tap_pause()
		if _geometry() != g0:
			bad.append(step + ":open")
		_stack().clear("t")
		await _settle()
		if _geometry() != g0:
			bad.append(step + ":closed")
	_ok(bad.is_empty() and _stack().depth() == 0, "board / strip / slot views / fronts / booster row / Pause / 2x / connectors identical while open and after close %s" % str(bad))
	_complete("g17_geometry_unchanged")

func _charge_first() -> void:
	print("[B6 owned charge stays charge-first]")
	await _boot(2)
	var sb0: int = _eco().wallet.scrub_bucks()
	_eco().boosters.add_charges("selector", 1)
	_host._refresh_hud()
	await _tap_booster("selector")
	var p = _stack().top()
	_ok(_stack().ids() == ["booster_selector"] and p.get_action_button("use").visible and not p.get_action_button("sb").visible
		and _eco().boosters.charges("selector") == 1, "owned Selector: same popup in USE mode (no purchase CTA), nothing consumed")
	await _close_x(p)
	_eco().boosters.add_charges("plus_one_slot", 1)
	_host._refresh_hud()
	await _tap_booster("plus_one_slot")
	_ok(_stack().depth() == 0 and _host.last_booster_request.get("ok", false) and _eco().boosters.charges("plus_one_slot") == 0
		and _eco().wallet.scrub_bucks() == sb0 and _screen().get_five_slot_strip().get_capacity() == 6,
		"owned +1 Slot: visible tap uses the charge directly (no popup, SB untouched), capacity 6")
	_complete("charge_first")

func _g07_sixth_slot_under_popup() -> void:
	print("[G7 temporary sixth slot intact with popups open]")
	var s = _screen()
	var clicks := 0
	while _host.get_slots().rightmost_empty_index() != -1 and clicks < 12:
		var any := false
		for col in range(_host.get_supply().get_column_count()):
			if _host.get_input_controller().activate_front(col).get("ok", false):
				any = true
				break
		clicks += 1
		if not any:
			break
	await _settle()
	var snap0: Array = _host.get_slots().snapshot()
	var views0: Array = s.get_five_slot_strip().get_slot_views().map(func(v): return v.get_global_rect())
	var ok := true
	for step in ["tornado", "plus_one_slot", "speed", "pause"]:
		if step == "speed":
			await _tap_speed()
		elif step == "pause":
			await _tap_pause()
		else:
			await _tap_booster(step)
		ok = ok and _stack().depth() == 1 and s.get_five_slot_strip().get_capacity() == 6 and _host.get_slots().snapshot() == snap0
		ok = ok and s.get_five_slot_strip().get_slot_views().map(func(v): return v.get_global_rect()) == views0
		ok = ok and s.get_booster_state("plus_one_slot")["state"] == "selected"
		_stack().clear("t")
		await _settle()
	_ok(ok and snap0.size() == 6 and _occupied() >= 5, "6 slots (%d occupied): capacity, slot truth and slot views identical under Booster/2x/Pause" % _occupied())
	await _tap_booster("plus_one_slot")
	var p = _stack().top()
	_ok(p.popup_id == "booster_plus_one_slot" and p.get_action_button("sb").disabled and p.find_child("Safety", true, false).text == UiText.t("BOOSTER_SAFETY_PLUS_ONE_SLOT"),
		"+1 Slot while active: acquisition shows the safety state, no second activation offered")
	await _close_x(p)
	_ok(s.get_five_slot_strip().get_capacity() == 6 and _host.get_slots().snapshot() == snap0, "after close: still 6 slots, same truth")
	_complete("g07_sixth_slot_under_popup")

func _sb_commit_canonical() -> void:
	print("[B9 SB commit goes through the canonical solver-safe authority, exactly once]")
	await _boot(2)
	var sb0: int = _eco().wallet.scrub_bucks()
	await _tap_booster("plus_one_slot")
	await _click_c(_stack().top().get_action_button("sb"))
	_ok(_eco().wallet.scrub_bucks() == sb0 - 500 and _screen().get_five_slot_strip().get_capacity() == 6 and _stack().depth() == 0
		and _acq().last_result.get("ok", false) and _host.last_booster_request.get("id") == "plus_one_slot", "+1 Slot SB tap: -500 once, capacity 6, closed")
	var colors0: int = _host.get_booster_adapter().present_colors().size()
	await _tap_booster("tornado")
	var p = _stack().top()
	await _click_c(_chips(p)[0])
	await _click_c(p.get_action_button("sb"))
	_ok(_eco().wallet.scrub_bucks() == sb0 - 1250 and _host.get_booster_adapter().present_colors().size() == colors0 - 1 and _stack().depth() == 0,
		"Tornado picked colour + SB tap: -750 once, that colour cleared via BoosterService")
	_complete("sb_commit_canonical")

# ============================================================ SB-M28-C002-013 ====

func _g08_speed_visible_acquire() -> void:
	print("[G8/G9 unentitled visible 2x tap -> canonical 2x Acquire, no debit]")
	await _boot(2)
	var t0 := _truth()
	await _tap_speed()
	var p = _host.get_speed_acquisition_popup()
	_ok(p != null and p.get_script() == SpeedAcquisitionPopup and _stack().ids() == ["speed_acquire"], "visible 2x tap -> speed_acquire on the shared ModalStack")
	_ok(not _host.get_speed_authority().is_2x() and _screen().get_speed_mode() == "off", "no silent free manual 2x")
	_ok(_truth() == t0, "opening debits nothing, mutates nothing")
	var ok: bool = p.get_offer_keys() == ["level", "timed_900", "timed_1800", "timed_3600"]
	for pair in [["level", "200"], ["timed_900", "300"], ["timed_1800", "500"], ["timed_3600", "750"]]:
		ok = ok and p.get_offer_button(pair[0]).text.find(pair[1] + " SB") != -1
	_ok(ok and not p.get_action_ids().has("watch"), "exactly current level 200 / 15m 300 / 30m 500 / 60m 750 SB; no rewarded 2x")
	_complete("g08_speed_visible_acquire")
	_complete("g09_speed_open_no_debit")
	# Background isolation under 2x Acquire.
	var s = _screen()
	for hit in s.get_supply_panel().find_children("HitArea", "", true, false):
		await _click_c(hit)
	await _tap_booster("random")
	await _tap_pause()
	_ok(_stack().ids() == ["speed_acquire"] and _truth() == t0, "supply / booster / Pause behind 2x Acquire: blocked")
	await _click_c(p.get_cancel_button())
	_ok(_stack().depth() == 0 and _truth() == t0 and not _host.get_runtime().is_user_paused(), "CANCEL: closed, nothing changed")

func _g10_speed_purchase_once() -> void:
	print("[G10 canonical 2x purchase debits exactly once and enables 2x immediately]")
	var sb0: int = _eco().wallet.scrub_bucks()
	await _tap_speed()
	var p = _host.get_speed_acquisition_popup()
	await _click_c(p.get_offer_button("level"))
	_ok(_eco().wallet.scrub_bucks() == sb0 - 200 and _host.get_speed_authority().is_2x() and _screen().get_speed_mode() == "level"
		and _stack().depth() == 0 and _host.last_speed_purchase_result.get("ok", false), "current-level tap: -200 once, 2x ON, popup closed")
	_complete("g10_speed_purchase_once")

func _g11_entitled_switch_free() -> void:
	print("[G11 entitled 1x/2x switching costs 0]")
	var sb1: int = _eco().wallet.scrub_bucks()
	var seq: Array = []
	for _i in range(6):
		await _tap_speed()
		seq.append(_host.get_speed_authority().is_2x())
	_ok(seq == [false, true, false, true, false, true] and _eco().wallet.scrub_bucks() == sb1 and _stack().depth() == 0, "6 visible taps: 1x/2x alternate, 0 SB, no popup")
	_complete("g11_entitled_switch_free")

func _g12_timed_countdown_live() -> void:
	print("[G12 timed countdown live from SpeedEntitlementService]")
	await _boot(2)
	var sb0: int = _eco().wallet.scrub_bucks()
	await _tap_speed()
	await _click_c(_host.get_speed_acquisition_popup().get_offer_button("timed_900"))
	var s = _screen()
	_ok(_eco().wallet.scrub_bucks() == sb0 - 300 and s.get_speed_mode() == "timed" and s.get_speed_label() == "15:00" and _host.get_speed_authority().is_2x(),
		"15m tap: -300 once, 2x ON, box shows 15:00")
	_now[0] += 75
	await create_timer(1.3).timeout   # the real HudTimer redraws; no manual refresh
	_ok(s.get_speed_label() == "13:45" and _eco().speed.timed_seconds_remaining() == 825, "+75 s wall clock -> HUD 13:45 via the live HUD timer")
	_now[0] -= 400
	await create_timer(1.3).timeout
	_ok(s.get_speed_label() == "13:45", "clock rollback: countdown frozen (M55 high-water)")
	_now[0] += 400
	await _tap_speed()
	await _tap_speed()
	_ok(_eco().wallet.scrub_bucks() == sb0 - 300 and _host.get_speed_authority().is_2x(), "timed entitlement: free 2x -> 1x -> 2x")
	_complete("g12_timed_countdown_live")

func _auto_2x_independent() -> void:
	print("[C8 free M23 automatic 2x stays acquisition-independent]")
	await _boot(2)
	var t0 := _truth()
	_host.get_runtime().set_speed_2x(true)
	_screen().set_speed_2x(true)
	await _tap_speed()
	_ok(_stack().depth() == 0 and _eco().snapshot() == t0["eco"] and _eco().wallet.scrub_bucks() == t0["sb"], "tap during free auto-2x: no popup, no spend, entitlement untouched")
	_complete("auto_2x_independent")

# ============================================================ cross-cutting =====

func _g16_rapid_taps() -> void:
	print("[G16 rapid mouse / touch taps]")
	await _boot(2)
	var s = _screen()
	var sb0: int = _eco().wallet.scrub_bucks()
	await _rapid(s.get_booster_button("tornado").get_global_rect().get_center(), 5)
	_ok(_stack().ids() == ["booster_tornado"], "5 same-frame taps on a zero-charge booster -> ONE popup")
	_stack().clear("t")
	await _settle()
	await _rapid(s.get_speed_button().get_global_rect().get_center(), 5)
	var p = _host.get_speed_acquisition_popup()
	_ok(_stack().ids() == ["speed_acquire"], "5 same-frame taps on unentitled 2x -> ONE popup")
	await _rapid(p.get_offer_button("timed_900").get_global_rect().get_center(), 5)
	_ok(_eco().wallet.scrub_bucks() == sb0 - 300 and _eco().speed.timed_seconds_remaining() == 900 and _stack().depth() == 0, "5 same-frame offer taps -> ONE 300 SB purchase")
	await _rapid(s.get_pause_button().get_global_rect().get_center(), 5)
	_ok(_stack().ids() == ["pause"], "5 same-frame Pause taps -> ONE Pause popup")
	_stack().clear("t")
	await _settle()
	await _tap_booster("plus_one_slot")
	var bp = _stack().top()
	await _rapid(bp.get_action_button("sb").get_global_rect().get_center(), 5)
	_ok(_eco().wallet.scrub_bucks() == sb0 - 800 and _screen().get_five_slot_strip().get_capacity() == 6, "5 same-frame +1 Slot SB taps -> ONE 500 SB activation")
	# Touch: under a modal zero, without a modal exactly one per gesture.
	await _tap_booster("random")
	var t0 := _truth()
	var hit = s.get_supply_panel().find_children("HitArea", "", true, false)[0]
	for i in range(3):
		await _touch(hit.get_global_rect().get_center(), i)
	_ok(_truth() == t0, "touch taps behind Booster Acquire: zero")
	_complete("g16_rapid_taps")
	_stack().clear("t")
	await _settle()

func _g18_no_accumulation() -> void:
	print("[G18 repeated visible popup cycles: no node / timer / signal accumulation]")
	await _boot(2)
	var s = _screen()
	await _settle()
	var n0 := _count(_root)
	var timers0: int = _root.find_children("*", "Timer", true, false).size()
	var c0 := [_stack().modal_changed.get_connections().size(), s.booster_pressed.get_connections().size(),
		s.get_speed_button().pressed.get_connections().size(), s.get_pause_button().pressed.get_connections().size(),
		_eco().rewarded.resolved.get_connections().size()]
	for _i in range(10):
		await _tap_booster("tornado")
		await _close_x(_stack().top())
		await _tap_booster("plus_one_slot")
		await _close_x(_stack().top())
		await _tap_speed()
		await _click_c(_host.get_speed_acquisition_popup().get_cancel_button())
		await _tap_pause()
		await _click_c(_host.get_pause_popup().get_action_button("resume"))
	await _settle()
	var c1 := [_stack().modal_changed.get_connections().size(), s.booster_pressed.get_connections().size(),
		s.get_speed_button().pressed.get_connections().size(), s.get_pause_button().pressed.get_connections().size(),
		_eco().rewarded.resolved.get_connections().size()]
	_ok(_count(_root) == n0 and _root.find_children("*", "Timer", true, false).size() == timers0 and c1 == c0 and _stack().depth() == 0,
		"40 open/close cycles: nodes %d -> %d, timers %d, connections %s" % [n0, _count(_root), timers0, str(c1)])
	_complete("g18_no_accumulation")

func _responsive_matrix() -> void:
	print("[H responsive: base / Booster Acquire / picker / Pause / 2x Acquire / sixth slot + popup]")
	for sz in MATRIX:
		await _boot(2, sz)
		var s = _screen()
		var vp := Rect2(Vector2.ZERO, Vector2(sz))
		var bad: Array = []
		# Base gameplay: controls inside the viewport, primary targets >= TOUCH_MIN.
		for c in [s.get_pause_button(), s.get_speed_button()] + BOOSTERS.map(func(id): return s.get_booster_button(id)):
			var r: Rect2 = c.get_global_rect()
			if not vp.encloses(r) or r.size.y < UiTokens.TOUCH_MIN or r.size.x < UiTokens.TOUCH_MIN:
				bad.append("base:%s %s" % [c.name, str(r)])
		for hit in s.get_supply_panel().find_children("HitArea", "", true, false):
			if hit.get_global_rect().size.y < UiTokens.TOUCH_MIN:
				bad.append("base:front")
		if s.get_board_rect().intersects(s.get_five_slot_strip_rect()) or s.get_five_slot_strip_rect().intersects(s.get_supply_panel_rect()) \
				or s.get_supply_panel_rect().intersects(s.get_booster_row_rect()):
			bad.append("base:overlap")
		var g0 := _geometry()
		await _tap_booster("plus_one_slot")
		_measure(_stack().top(), vp, bad, "booster_plus_one_slot")
		_stack().clear("t")
		await _settle()
		await _tap_booster("selector")
		_measure(_stack().top(), vp, bad, "booster_selector")
		_stack().clear("t")
		await _settle()
		await _tap_pause()
		_measure(_stack().top(), vp, bad, "pause")
		_stack().clear("t")
		await _settle()
		await _tap_speed()
		_measure(_stack().top(), vp, bad, "speed_acquire")
		_stack().clear("t")
		await _settle()
		if _geometry() != g0:
			bad.append("geometry_changed")
		# Sixth slot + popup.
		_eco().boosters.add_charges("plus_one_slot", 1)
		await _tap_booster("plus_one_slot")
		await _tap_booster("tornado")
		_measure(_stack().top(), vp, bad, "sixth+tornado")
		if s.get_five_slot_strip().get_capacity() != 6:
			bad.append("sixth:capacity")
		for v in s.get_five_slot_strip().get_slot_views():
			if not vp.encloses(v.get_global_rect()):
				bad.append("sixth:slot_clip")
		_ok(bad.is_empty(), "%dx%d: base + 5 popup states fit, no clipping/overlap, targets >= %d px %s" % [sz.x, sz.y, UiTokens.TOUCH_MIN, str(bad)])
	_complete("responsive_matrix")

func _measure(pp, vp: Rect2, bad: Array, want: String) -> void:
	if pp == null or not is_instance_valid(pp) or (want.find("+") == -1 and pp.popup_id != want):
		bad.append("missing:" + want)
		return
	var fits: bool = pp.text_fits() and vp.encloses(pp.get_frame_rect())
	if pp.get_hero().visible:
		fits = fits and vp.encloses(pp.get_hero().get_global_rect())
	for id in pp.get_action_ids():
		var btn: Button = pp.get_action_button(id)
		fits = fits and (not btn.visible or (btn.size.y >= UiTokens.TOUCH_MIN and vp.encloses(btn.get_global_rect())))
	fits = fits and pp.get_close_button().size.y >= UiTokens.TOUCH_MIN
	for chip in pp.find_children("Target_*", "Button", true, false):
		fits = fits and chip.size.y >= UiTokens.TOUCH_MIN and chip.size.x >= UiTokens.TOUCH_MIN and vp.encloses(chip.get_global_rect())
	if not fits:
		bad.append("%s frame=%s" % [want, str(pp.get_frame_rect())])

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
	print("M28-C002-C003 final popup-inclusive gate: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
