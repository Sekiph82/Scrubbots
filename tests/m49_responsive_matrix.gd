extends SceneTree
## M49 Responsive UI (SB-M49-001..028, 030, 031) — one cross-surface viewport matrix against the
## REAL app root (main.tscn) and the production GameplayScreen, in sized SubViewports that use
## the project's stretch result (canvas_items / expand on a 1080x2160 reference):
##   m01 layout classes · m02 Home · m03 gameplay L1 (5 slots) · m04 real-tap touch mapping
##   m05 +1 Slot sixth slot · m06 rectangular / 59x59 boards · m07 popups + deep links under a
##   notch · m08 Results journey / Next Cleanup.
## Pure measurement: no production source is changed by this suite.
##
## Run: godot --headless --path . -s res://tests/m49_responsive_matrix.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ResponsiveLayout = preload("res://scripts/ui/responsive_layout.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const SlotBatchState = preload("res://scripts/gameplay/slots/slot_batch_state.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const HelpTipsScreen = preload("res://scripts/ui/tutorial/help_tips_screen.gd")
const Shell = preload("res://scripts/ui/gameplay_shell_geometry.gd")

## Physical device sizes (portrait).
const PHYSICAL := [Vector2i(720, 1280), Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532),
	Vector2i(1080, 2400), Vector2i(1290, 2796), Vector2i(1440, 3200), Vector2i(1536, 2048)]
const NOTCH := [0, 132, 0, 96]   ## left, top, right, bottom synthetic safe insets
const TOUCH := float(UiTokens.TOUCH_MIN)
const EMU := InputEvent.DEVICE_ID_EMULATION

var EXPECTED_CASES := [
	"m01_layout_classes", "m02_home_matrix_notch", "m03_gameplay_matrix_notch", "m04_real_tap_mapping",
	"m05_sixth_slot_matrix", "m06_rect_and_max_boards", "m07_popups_deeplinks_notch", "m08_results_journey",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	MainScript.boot_opening_override = 0
	_m01()
	await _m02()
	await _m03()
	await _m04()
	await _m05()
	await _m06()
	await _m07()
	await _m08()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _m01() -> void:
	print("[m01 COMPACT / NORMAL / TALL classification + required-device list]")
	var want := {Vector2i(720, 1280): "COMPACT", Vector2i(1080, 1920): "COMPACT", Vector2i(1080, 2160): "NORMAL",
		Vector2i(1170, 2532): "TALL", Vector2i(1080, 2400): "TALL", Vector2i(1290, 2796): "TALL",
		Vector2i(1440, 3200): "TALL", Vector2i(1536, 2048): "COMPACT"}
	var bad: Array = []
	for phys in PHYSICAL:
		var m := _mode(ResponsiveLayout.get_layout_mode(Vector2(_logical(phys))))
		if m != String(want[phys]):
			bad.append("%s->%s" % [str(phys), m])
	_ok(bad.is_empty(), "layout class per device (16:9 / tablet COMPACT, 18:9 NORMAL, 19.5:9+ TALL) %s" % str(bad))
	var req_ok := true
	for v in [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400), Vector2i(1440, 3200)]:
		req_ok = req_ok and ResponsiveLayout.is_required_test_viewport(v)
	_ok(req_ok and not ResponsiveLayout.is_required_test_viewport(Vector2i(800, 600)), "required phone matrix 015-019 recognised")
	_complete("m01_layout_classes")

func _m02() -> void:
	print("[m02 Home: key controls inside the safe rect, >= 88 px, no overlap, with and without a notch]")
	for phys in PHYSICAL:
		for notch in [false, true]:
			var lv := _logical(phys)
			await _boot("m02", lv)
			var home = _root.get_home()
			if notch:
				home.get_region("SafeAreaRoot").set_synthetic_insets(NOTCH[0], NOTCH[1], NOTCH[2], NOTCH[3])
				await _frames(6)
			var safe := _safe_rect(lv, notch)
			var bad: Array = []
			for n in ["PlayButton", "Shortcut_shop", "Shortcut_collection", "Shortcut_tasks", "Shortcut_daily", "BottomNav", "TopCurrencyHUD", "GiftMeter"]:
				var c = home.get_region(n)
				if c == null or not (c as Control).is_visible_in_tree():
					bad.append(n + ":missing")
					continue
				var r: Rect2 = (c as Control).get_global_rect()
				if not _inside(r, safe):
					bad.append("%s:%s" % [n, _rs(r)])
				if (c is BaseButton) and r.size.y < TOUCH - 0.5:
					bad.append(n + "<88")
			var play: Rect2 = home.get_region("PlayButton").get_global_rect()
			for n in ["Shortcut_shop", "Shortcut_collection", "Shortcut_tasks", "Shortcut_daily"]:
				if play.intersects(home.get_region(n).get_global_rect()):
					bad.append("PLAY overlaps " + n)
			_ok(bad.is_empty(), "%s (logical %s)%s: Home ok %s" % [str(phys), str(lv), " notch" if notch else "", str(bad)])
	_complete("m02_home_matrix_notch")

func _m03() -> void:
	print("[m03 gameplay L1: board, five slots, supply fronts, Pause/2x, boosters inside; >= 88 px controls]")
	for phys in PHYSICAL:
		for notch in [false, true]:
			var lv := _logical(phys)
			var host = await _play(lv)
			var s = host.get_screen()
			if notch:
				s.set_synthetic_safe_insets(NOTCH[0], NOTCH[1], NOTCH[2], NOTCH[3])
				await _frames(4)
			var safe := _safe_rect(lv, notch)
			var bad := _gameplay_geometry(s, safe, 5)
			_ok(bad.is_empty(), "%s (logical %s)%s: gameplay ok %s" % [str(phys), str(lv), " notch" if notch else "", str(bad)])
	_complete("m03_gameplay_matrix_notch")

func _m04() -> void:
	print("[m04 a real platform-ordered tap at each front centre places exactly that column]")
	for phys in [Vector2i(720, 1280), Vector2i(1080, 2160), Vector2i(1440, 3200)]:
		var lv := _logical(phys)
		var host = await _play(lv)
		var panel = host.get_screen().get_supply_panel()
		var results: Array = []
		host.get_input_controller().activation_result.connect(func(c, ok, _e): results.append([c, ok]))
		var mismatch: Array = []
		var tapped := 0
		for c in range(panel.get_column_count()):
			if not panel.get_front_enabled(c) or host.get_slots().rightmost_empty_index() == -1:
				continue
			var before := results.size()
			await _sub_tap(panel.get_front_hit_rect(c).get_center())
			tapped += 1
			var got: Array = results.slice(before)
			if got.size() != 1 or int(got[0][0]) != c or not bool(got[0][1]):
				mismatch.append("col%d->%s" % [c, str(got)])
		_ok(tapped >= 2 and mismatch.is_empty(), "%s (logical %s): %d taps, each placed its own column %s" % [str(phys), str(lv), tapped, str(mismatch)])
	_complete("m04_real_tap_mapping")

func _m05() -> void:
	print("[m05 +1 Slot: six slot views usable on every size]")
	for phys in PHYSICAL:
		var lv := _logical(phys)
		var host = await _play(lv)
		var ok_act: bool = host.activate_plus_one_slot()
		await _frames(4)
		var s = host.get_screen()
		var bad := _gameplay_geometry(s, _safe_rect(lv, false), 6)
		_ok(ok_act and s.get_shell_id().begins_with("6slot") and bad.is_empty(), "%s (logical %s): six slots ok, shell %s %s" % [str(phys), str(lv), s.get_shell_id(), str(bad)])
	_complete("m05_sixth_slot_matrix")

func _m06() -> void:
	print("[m06 rectangular and 59x59 boards keep their aspect inside the board region]")
	_shutdown()
	for phys in [Vector2i(1080, 1920), Vector2i(1440, 3200)]:
		for wh in [Vector2i(24, 40), Vector2i(40, 24), Vector2i(59, 59)]:
			_sub = SubViewport.new()
			_sub.disable_3d = true
			_sub.size = _logical(phys)
			get_root().add_child(_sub)
			var screen = GameplayScreen.new()
			_sub.add_child(screen)
			# Size the standalone screen to the viewport (anchors alone keep it 0x0 when the
			# SubViewport size was set BEFORE the child was added - run 38746625415 diagnostic).
			screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var level = BoardDebugFixtures.make_level(wh.x, wh.y)
			var board = BoardDebugFixtures.make_board(wh.x, wh.y)
			var supply = BatchSupplyGenerator.generate(level, 3, 3, 4242)
			var slots: Array = []
			for _i in range(5):
				slots.append(SlotBatchState.make_empty().to_dict())
			screen.configure(board, level.palette, slots, supply.player_snapshot() if supply != null else [])
			await _frames(2)
			screen.relayout()
			await _frames(1)
			var br: Rect2 = screen.get_board_rect()
			var region: Rect2 = screen.get_board_region_rect()
			# Authoritative containment reference (same as m28_c002_c002_static_shell): the baked
			# rail loop of the selected shell, in global coordinates.
			var sid: String = screen.get_shell_id() if not screen.get_shell_id().is_empty() else GameplayScreen.FALLBACK_SHELL
			var rail: Rect2 = screen.ref_rect_to_global(Shell.rail_rect(sid))
			var vp := Rect2(Vector2.ZERO, Vector2(_sub.size))
			# Peer review D1: measure what is DRAWN (renderer size x presentation scale at the
			# presentation's global origin), not get_board_rect() (which is w x h by construction).
			var pres = screen.get_presentation()
			var rnd: Control = pres.get_renderer()
			var drawn := Rect2(pres.global_position, rnd.size * pres.scale)
			var aspect: float = drawn.size.x / maxf(drawn.size.y, 1.0)
			var want: float = float(wh.x) / float(wh.y)
			var clear: bool = not drawn.intersects(screen.get_five_slot_strip_rect()) and not drawn.intersects(screen.get_supply_panel_rect())
			# Peer review D2: containment in the baked rail AND BoardRegion are hard assertions.
			_ok(drawn.has_area() and absf(aspect - want) < 0.02 and _inside(drawn, rail) and _inside(drawn, region) and _inside(drawn, vp) and clear,
				"%s %dx%d: drawn aspect %.3f (want %.3f); inside rail + BoardRegion + viewport; clear of slots / supply | drawn %s rail %s" % [str(phys), wh.x, wh.y, aspect, want, _rs(drawn), _rs(rail)])
			_sub.free()
			_sub = null
	_complete("m06_rect_and_max_boards")

func _m07() -> void:
	print("[m07 popups + notification deep links stay inside the safe rect under a notch]")
	for phys in [Vector2i(720, 1280), Vector2i(1440, 3200), Vector2i(1536, 2048)]:
		var lv := _logical(phys)
		await _boot("m07", lv)
		var stack = _root.get_modal_stack()
		stack.set_synthetic_safe_insets(NOTCH[0], NOTCH[1], NOTCH[2], NOTCH[3])
		var safe := _safe_rect(lv, true)
		var bad: Array = []
		for d in ["tasks", "daily", "gift_bar", "shop", "collection", "robots", "events", "profile"]:
			stack.clear("test")
			await _frames(1)
			var got: String = _root.open_deep_link(d)
			await _frames(4)
			var top = stack.top()
			if got != d:
				bad.append("%s:routed to %s" % [d, got])   # peer review D4
			if top == null:
				bad.append(d + ":no popup (" + got + ")")
				continue
			if not _inside(top.get_frame_rect(), safe):
				bad.append("%s:%s" % [d, _rs(top.get_frame_rect())])
		stack.clear("test")
		await _frames(1)
		var hp = HelpTipsScreen.open(stack, _root.get_app_state())
		await _frames(4)
		if hp == null or not _inside(hp.get_frame_rect(), safe):
			bad.append("help_tips")
		stack.clear("test")
		_ok(bad.is_empty(), "%s (logical %s) notch: every popup frame inside the safe rect %s" % [str(phys), str(lv), str(bad)])
	_complete("m07_popups_deeplinks_notch")

func _m08() -> void:
	print("[m08 Results WON: CLEAN NEXT >= 88 px inside; journey strip inside]")
	for phys in [Vector2i(720, 1280), Vector2i(1080, 2160), Vector2i(1440, 3200)]:
		var lv := _logical(phys)
		await _boot("m08", lv)
		var res = _root.get_results_screen()
		res.visible = true
		res.show_model(_root._results_model({"status": "WON", "level": 1, "attempt": 1}))
		await _frames(6)
		var vp := Rect2(Vector2.ZERO, Vector2(lv))
		var b: Button = res.get_primary_button()
		var br: Rect2 = b.get_global_rect()
		var j = res.get_journey_strip()
		var j_ok: bool = j == null or not (j as Control).is_visible_in_tree() or _inside((j as Control).get_global_rect(), vp)
		_ok(_inside(br, vp) and br.size.y >= TOUCH - 0.5 and j_ok, "%s (logical %s): CTA %s; journey inside when shown" % [str(phys), str(lv), _rs(br)])
		# Peer review D3: visibility is RECORDED (rows 031/032 stay partial until asserted).
		var nc = res.get_next_cleanup_panel()
		print("    diag: journey visible=%s next_cleanup visible=%s" % [str(j != null and (j as Control).is_visible_in_tree()), str(nc != null and nc.is_visible_in_tree())])
	_complete("m08_results_journey")

# ------------------------------------------------------------------ helpers ----

## The canvas size the stretch policy (1080x2160, canvas_items / expand) gives a device.
static func _logical(phys: Vector2i) -> Vector2i:
	var ratio := float(phys.x) / float(phys.y)
	if ratio >= 0.5:
		return Vector2i(int(round(2160.0 * ratio)), 2160)
	return Vector2i(1080, int(round(1080.0 / ratio)))

static func _mode(m: int) -> String:
	match m:
		ResponsiveLayout.LayoutMode.COMPACT: return "COMPACT"
		ResponsiveLayout.LayoutMode.TALL: return "TALL"
	return "NORMAL"

func _safe_rect(lv: Vector2i, notch: bool) -> Rect2:
	var r := Rect2(Vector2.ZERO, Vector2(lv))
	if notch:
		r = Rect2(Vector2(NOTCH[0], NOTCH[1]), Vector2(lv) - Vector2(NOTCH[0] + NOTCH[2], NOTCH[1] + NOTCH[3]))
	return r

static func _inside(inner: Rect2, outer: Rect2) -> bool:
	return inner.has_area() and inner.position.x >= outer.position.x - 1.0 and inner.position.y >= outer.position.y - 1.0 \
		and inner.end.x <= outer.end.x + 1.0 and inner.end.y <= outer.end.y + 1.0

static func _rs(r: Rect2) -> String:
	return "[%d,%d %dx%d]" % [int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]

## Shared gameplay checks: board, `slots` slot views, supply fronts, Pause/2x, boosters.
func _gameplay_geometry(s, safe: Rect2, slots: int) -> Array:
	var bad: Array = []
	var board: Rect2 = s.get_board_rect()
	if not _inside(board, safe):
		bad.append("board:" + _rs(board))
	var views: Array = s.get_five_slot_strip().get_slot_views()
	if views.size() != slots:
		bad.append("slot_views=%d" % views.size())
	var vr: Array = []
	for v in views:
		var r: Rect2 = (v as Control).get_global_rect()
		vr.append(r)
		if not _inside(r, safe):
			bad.append("slot:" + _rs(r))
	for i in range(vr.size()):
		for k in range(i + 1, vr.size()):
			if (vr[i] as Rect2).intersects(vr[k]):
				bad.append("slots %d/%d overlap" % [i, k])
	var panel = s.get_supply_panel()
	var fr: Array = []
	for c in range(panel.get_column_count()):
		var r: Rect2 = panel.get_front_hit_rect(c)
		fr.append(r)
		if not _inside(r, safe):
			bad.append("front%d:%s" % [c, _rs(r)])
	for i in range(fr.size()):
		for k in range(i + 1, fr.size()):
			if (fr[i] as Rect2).intersects(fr[k]):
				bad.append("fronts %d/%d overlap" % [i, k])
	var vp_w: float = safe.end.x
	for b in [s.get_pause_button(), s.get_speed_button()]:
		var r: Rect2 = (b as Control).get_global_rect()
		if not _inside(r, safe) or r.get_center().x < vp_w * 0.5 or r.get_center().y > safe.position.y + safe.size.y * 0.25:
			bad.append("%s:%s" % [b.name, _rs(r)])
	for id in ["plus_one_slot", "random", "selector", "tornado"]:
		var r: Rect2 = s.get_booster_button(id).get_global_rect()
		if not _inside(r, safe) or r.size.y < TOUCH - 0.5 or r.size.x < TOUCH - 0.5:
			bad.append("booster_%s:%s" % [id, _rs(r)])
	return bad

func _boot(tag: String, size: Vector2i) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m49_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

func _play(lv: Vector2i):
	await _boot("play", lv)
	_root.get_modal_stack().clear("test")
	_root.play_current_frontier()
	await _frames(6)
	var h = _root.get_gameplay_host()
	if h != null:
		h.get_runtime().set_process(false)
	return h

## One platform-ordered tap into the sized SubViewport (same order as tests/m47_touch_r01).
func _sub_tap(p: Vector2) -> void:
	for pressed in [true, false]:
		var m := InputEventMouseButton.new()
		m.device = EMU
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = p
		m.global_position = p
		m.pressed = pressed
		_sub.push_input(m, true)
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.position = p
		t.pressed = pressed
		_sub.push_input(t, true)
		await process_frame

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
	print("M49 responsive matrix evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
