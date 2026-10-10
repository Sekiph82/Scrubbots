extends SceneTree
## M47-FAMILY-APK-TOUCH-R01 — mobile UX: Supply single tap, popup list touch scroll, Rewarded Ads
## Home badge. Every input case goes through Godot's REAL GUI route:
##   - root-viewport cases use Input.parse_input_event() with the project's default
##     emulate_mouse_from_touch = true, i.e. the engine itself synthesizes the emulated mouse
##     events (device InputEvent.DEVICE_ID_EMULATION) BEFORE dispatching each ScreenTouch /
##     ScreenDrag - exactly what Android / iOS deliver (core/input/input.cpp, 4.7.2);
##   - sized SubViewport cases (phone / Flip / iPhone / tablets, safe-area insets, 3/4/5 supply
##     columns, 5/6 slots) push that same engine order with Viewport.push_input().
## Touch-drag scrolling needs DisplayServer.is_touchscreen_available(); headless Godot derives it
## from Input.emulate_touch_from_mouse, so the scroll cases switch that on (restored afterwards).
##   s*: Supply front single tap -> exactly one canonical placement (ProductionInputController)
##   c*: Collection album / Exchange / other popup lists: finger swipe scrolls, taps still work
##   r*: Rewarded Ads Home badge (HomeBadges.compute + RewardedAdsButton.set_badge)
## Run: godot --headless --path . -s res://tests/m47_touch_r01_mobile_ux.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")

const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const CIDS := ["C01", "C02", "C03", "C04", "C05", "C06"]
const EMU := InputEvent.DEVICE_ID_EMULATION

var EXPECTED_CASES := [
	"s01_real_input_single_tap_one_placement", "s02_rapid_taps_each_one", "s03_multitouch_one", "s04_preview_rows_inert",
	"s05_desktop_mouse_and_long_hold", "s06_full_modal_reject_atomic", "s07_sizes_columns_slots_safe_area",
	"c01_album_swipe_from_view_and_row", "c02_album_reaches_master_and_reverses", "c03_taps_open_detail_drag_does_not",
	"c04_wheel_reopen_tablet", "c05_exchange_and_other_lists", "r01_badge_rules", "r02_badge_relaunch_and_blocked",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _root = null
var _sub: SubViewport = null
var _host = null
var _now := [1790000000]
var _day := [20000]
var _results: Array = []

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	MainScript.boot_opening_override = 0
	print("    root viewport %s, final transform %s, emulate_mouse_from_touch %s" % [str(get_root().get_visible_rect().size), str(get_root().get_final_transform()), str(Input.emulate_mouse_from_touch)])
	await _supply_root(); await _s07()
	await _collection(); await _c05()
	await _r01(); await _r02()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _uniq(tag: String) -> String:
	var p := "user://m47t_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _boot(tag: String, path := "") -> void:
	_shutdown()
	MainScript.boot_save_path_override = path if not path.is_empty() else _uniq(tag)
	_root = MainScene.instantiate()
	get_root().add_child(_root)   # root viewport: real Input -> Window -> Viewport GUI route
	await _frames(14)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _host != null and is_instance_valid(_host):
		_host.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

## Root-viewport canvas position -> window position (what the OS reports).
func _win(p: Vector2) -> Vector2:
	return get_root().get_final_transform() * p

func _parse(e: InputEvent) -> void:
	Input.parse_input_event(e)
	Input.flush_buffered_events()

## A real finger through the engine (Input synthesizes the emulated mouse itself).
func _touch(p: Vector2, pressed: bool, index := 0) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = _win(p)
	e.pressed = pressed
	_parse(e)

func _fdrag(p: Vector2, rel: Vector2, index := 0) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = _win(p)
	e.relative = get_root().get_final_transform().basis_xform(rel)
	e.screen_relative = e.relative
	_parse(e)

func _tap(p: Vector2, hold_frames := 1, index := 0) -> void:
	_touch(p, true, index)
	await _frames(hold_frames)
	_touch(p, false, index)
	await _frames(1)

## Finger swipe from p by total `delta` (canvas px) in `steps` drags, one per frame.
func _swipe(p: Vector2, delta: Vector2, steps := 12) -> void:
	_touch(p, true)
	await process_frame
	var cur := p
	for _i in range(steps):
		var d := delta / float(steps)
		cur += d
		_fdrag(cur, d)
		await process_frame
	_touch(cur, false)
	await _frames(2)

## Push one platform-ordered tap into a sized SubViewport (canvas coords): Godot's Input layer
## dispatches the emulated mouse button BEFORE its ScreenTouch (input.cpp), so the same order.
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

func _e():
	return _root.get_app_state().economy

func _ok_count() -> int:
	return _results.filter(func(r): return r[1]).size()

func _bind_results(h) -> void:
	_results = []
	h.get_input_controller().activation_result.connect(func(c, ok, err): _results.append([c, ok, err]))

# ------------------------------------------------------------- Supply (root) ----

func _supply_root() -> void:
	print("[s01-s06 Supply front single tap through the real Input route, production Level 1]")
	await _boot("s")
	_ok(Input.emulate_mouse_from_touch, "project default: touch emulates mouse (as on Android / iOS)")
	var r: Dictionary = _root.play_current_frontier()
	_ok(r.get("ok", false), "Home PLAY launches Level 1")
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)   # slots only fill (no dispatch) -> deterministic counting
	await _frames(6)
	var panel = h.get_screen().get_supply_panel()
	panel.refresh_hit_areas()
	await _frames(2)
	var slots = h.get_slots()
	_bind_results(h)
	var c0: Vector2 = panel.get_front_hit_rect(0).get_center()
	var right0: int = slots.rightmost_empty_index()
	await _tap(c0)
	print("    s01 single tap col0 at %s: activations %s, occupied %d" % [str(c0), str(_results), slots.occupied_count()])
	_ok(_ok_count() == 1 and slots.occupied_count() == 1 and slots.is_occupied(right0), "ONE stationary tap -> exactly one placement into the rightmost empty slot (%d)" % right0)
	_ok(panel.get_pending_column() == -1, "no gesture left pending after the tap")
	_complete("s01_real_input_single_tap_one_placement")
	# s02: three rapid taps (one frame each) on three fronts.
	for c in [1, 2, 0]:
		if panel.get_front_enabled(c):
			await _tap(panel.get_front_hit_rect(c).get_center())
	_ok(_ok_count() == 4 and slots.occupied_count() == 4, "rapid taps: each tap exactly one placement (%d ok, %d occupied)" % [_ok_count(), slots.occupied_count()])
	_complete("s02_rapid_taps_each_one")
	# s03: two fingers down on two fronts, release both -> the first gesture only.
	var occ: int = slots.occupied_count()
	var p0: Vector2 = panel.get_front_hit_rect(0).get_center()
	var p1: Vector2 = panel.get_front_hit_rect(1).get_center()
	_touch(p0, true, 0)
	await process_frame
	_touch(p1, true, 1)
	await process_frame
	_touch(p1, false, 1)
	await process_frame
	_touch(p0, false, 0)
	await _frames(2)
	_ok(slots.occupied_count() == occ + 1, "multitouch on two fronts: exactly one placement (%d -> %d)" % [occ, slots.occupied_count()])
	_complete("s03_multitouch_one")
	# s04: preview rows (1/2) are inert.
	occ = slots.occupied_count()
	for row in [1, 2]:
		var rp: Control = panel.get_column_row_panels(0)[row]
		await _tap(rp.get_global_rect().get_center())
	_ok(slots.occupied_count() == occ, "taps on preview rows 1/2: no placement")
	_complete("s04_preview_rows_inert")
	await _supply_root_part2()

func _supply_root_part2() -> void:
	print("[s05-s06 desktop mouse, long hold, full slots, modal: atomic]")
	await _boot("s2")
	_root.play_current_frontier()
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)
	await _frames(6)
	var panel = h.get_screen().get_supply_panel()
	panel.refresh_hit_areas()
	await _frames(2)
	var slots = h.get_slots()
	_bind_results(h)
	var p: Vector2 = panel.get_front_hit_rect(0).get_center()
	for pressed in [true, false]:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = _win(p)
		m.global_position = m.position
		m.pressed = pressed
		_parse(m)
		await process_frame
	_ok(slots.occupied_count() == 1, "desktop mouse click (real device id) -> one placement")
	await _tap(panel.get_front_hit_rect(1).get_center(), 40)   # ~0.6 s hold, no movement
	_ok(slots.occupied_count() == 2, "stationary long hold -> one placement (unchanged)")
	_complete("s05_desktop_mouse_and_long_hold")
	var guard := 0
	while not slots.is_full() and guard < 10:
		guard += 1
		for c in range(panel.get_column_count()):
			if panel.get_front_enabled(c) and not slots.is_full():
				await _tap(panel.get_front_hit_rect(c).get_center())
	var full_snap := JSON.stringify(slots.snapshot())
	var sup := JSON.stringify(h.get_supply().debug_snapshot())
	var n0 := _results.size()
	await _tap(panel.get_front_hit_rect(0).get_center())
	_ok(slots.is_full() and JSON.stringify(slots.snapshot()) == full_snap and JSON.stringify(h.get_supply().debug_snapshot()) == sup, "all slots full: tap rejected atomically (slots + supply unchanged)")
	_ok(_results.size() == n0 + 1 and not _results.back()[1], "the full-slot tap is one REJECTED activation (%s)" % str(_results.back()))
	h.get_input_controller().set_modal_blocked(true)
	var n1 := _ok_count()
	await _tap(panel.get_front_hit_rect(1).get_center())
	_ok(_ok_count() == n1, "modal-blocked: no placement")
	h.get_input_controller().set_modal_blocked(false)
	_complete("s06_full_modal_reject_atomic")

# ------------------------------------------------- Supply (sized SubViewports) ----

func _stripe_level(w: int) -> Dictionary:
	var cells: Array = []
	for y in range(w):
		for x in range(w):
			cells.append(x * 6 / w)
	return {"version": 1, "id": "m47t_%d" % Time.get_ticks_usec(), "name": "m47t", "difficulty": "TEST", "width": w, "height": w, "palette": HEX, "cells": cells}

func _plan(lvl: Dictionary, columns: int) -> Dictionary:
	var totals := {}
	for c in lvl["cells"]:
		totals[int(c)] = int(totals.get(int(c), 0)) + 1
	var batches: Array = []
	var more := true
	while more:
		more = false
		for c in range(6):
			if int(totals.get(c, 0)) > 0:
				var n := mini(30, int(totals[c]))
				totals[c] = int(totals[c]) - n
				batches.append({"batchId": "T%03d" % batches.size(), "cid": CIDS[c], "robots": n})
				more = true
	var cols: Array = []
	for _i in range(columns):
		cols.append([])
	for i in range(batches.size()):
		cols[i % columns].append(batches[i])
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "columnCount": columns, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols, "levelId": lvl["id"]}

func _write(tag: String, text: String) -> String:
	var p := "user://m47t_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _s07() -> void:
	print("[s07 sizes x supply columns x 5/6 slots x safe areas: one tap -> one placement per front]")
	var matrix := [
		[Vector2i(1080, 2160), 3, 5, Vector4i(0, 0, 0, 0), "phone 1080x2160"],
		[Vector2i(1080, 2640), 4, 5, Vector4i(0, 96, 0, 48), "Samsung Flip-like 1080x2640 + insets"],
		[Vector2i(1170, 2532), 5, 5, Vector4i(0, 141, 0, 102), "iPhone-like 1170x2532 + notch insets"],
		[Vector2i(1536, 2048), 3, 6, Vector4i(0, 40, 0, 40), "iPad-like 1536x2048, +1 Slot (6)"],
		[Vector2i(1600, 2560), 5, 6, Vector4i(0, 64, 0, 32), "Android tablet 1600x2560, +1 Slot (6)"],
		[Vector2i(1080, 2400), 4, 6, Vector4i(0, 80, 0, 40), "phone 1080x2400, +1 Slot (6)"],
	]
	var bad: Array = []
	for m in matrix:
		_shutdown()
		_sub = SubViewport.new()
		_sub.size = m[0]
		_sub.disable_3d = true
		get_root().add_child(_sub)
		var lvl := _stripe_level(32)
		var h = ProductionGameplayHost.new()
		h.auto_build = false
		h.level_path = _write("lvl", JSON.stringify(lvl))
		h.supply_plan_path = _write("plan", JSON.stringify(_plan(lvl, int(m[1]))))
		h.set_anchors_preset(Control.PRESET_FULL_RECT)
		_sub.add_child(h)
		_host = h
		await _frames(2)
		h.build()
		await _frames(2)
		var ins: Vector4i = m[3]
		h.get_screen().set_synthetic_safe_insets(ins.x, ins.y, ins.z, ins.w)
		if int(m[2]) == 6:
			h.get_economy().boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
			h.activate_plus_one_slot()
		await _frames(2)
		h.get_screen().relayout()
		await _frames(3)
		h.get_runtime().set_process(false)
		var panel = h.get_screen().get_supply_panel()
		panel.refresh_hit_areas()
		await _frames(2)
		var slots = h.get_slots()
		_bind_results(h)
		var cols: int = panel.get_column_count()
		var placed := 0
		for c in range(cols):
			var before: int = slots.occupied_count()
			var right: int = slots.rightmost_empty_index()
			await _sub_tap(panel.get_front_hit_rect(c).get_center())
			if slots.occupied_count() == before + 1 and slots.is_occupied(right):
				placed += 1
		var line := "%s: %d columns, %d slots -> %d/%d single taps placed exactly one batch" % [m[4], cols, slots.active_capacity(), placed, cols]
		print("    " + line)
		if cols != int(m[1]) or slots.active_capacity() != int(m[2]) or placed != cols:
			bad.append(line)
	_ok(bad.is_empty(), "every size / column count / slot count / safe-area: one tap = one placement %s" % str(bad))
	_shutdown()
	_complete("s07_sizes_columns_slots_safe_area")

# --------------------------------------------------------------- Collection ----

## Controls inside a scroll list that STOP mouse/touch (they swallow the drag before the scroll).
static func stop_controls(scroll: Node) -> Array:
	return scroll.find_children("*", "Control", true, false).filter(func(c): return c.mouse_filter == Control.MOUSE_FILTER_STOP)

func _open_album():
	_root._on_home_shortcut("collection")
	await _frames(10)
	return _root.get_modal_stack().top()

func _collection() -> void:
	print("[c01-c04 Collection album: finger swipe scrolls, taps still open, wheel, reopen]")
	await _boot("c")
	Input.emulate_touch_from_mouse = true   # headless: makes DisplayServer.is_touchscreen_available() true
	var p = await _open_album()
	var scroll: ScrollContainer = p.find_child("SetList", true, false)
	var bar := scroll.get_v_scroll_bar()
	print("    album list: visible h %.0f, content max %.0f, STOP controls inside %d %s" % [scroll.size.y, bar.max_value - bar.page, stop_controls(scroll).size(),
		str(stop_controls(scroll).slice(0, 4).map(func(c): return "%s(%s)" % [c.name, c.get_class()]))])
	var view: Control = p.find_child("Set_2", true, false).find_children("*", "BaseButton", true, false)[0]
	var title: Control = p.find_child("Set_2", true, false).find_child("Title", true, false)
	var v0 := scroll.scroll_vertical
	await _swipe(view.get_global_rect().get_center(), Vector2(0, -360))
	var v1 := scroll.scroll_vertical
	await _swipe(title.get_global_rect().get_center(), Vector2(0, -360))
	var v2 := scroll.scroll_vertical
	print("    swipe up from VIEW: %d -> %d; from row title: %d -> %d" % [v0, v1, v1, v2])
	_ok(v1 > v0 + 100, "finger swipe up starting ON a row's VIEW button scrolls the list down (%d -> %d)" % [v0, v1])
	_ok(v2 > v1 + 100, "finger swipe up starting on a row's text scrolls the list down (%d -> %d)" % [v1, v2])
	_complete("c01_album_swipe_from_view_and_row")
	# c02: keep swiping to the end: Master row visible; then swipe down back to the top.
	var t0 := Time.get_ticks_usec()
	var frames0 := Engine.get_process_frames()
	var guard := 0
	while scroll.scroll_vertical < int(bar.max_value - bar.page) - 1 and guard < 20:
		guard += 1
		await _swipe(scroll.get_global_rect().get_center() + Vector2(-200, 150), Vector2(0, -500))
	var per_frame := float(Time.get_ticks_usec() - t0) / 1000.0 / float(maxi(Engine.get_process_frames() - frames0, 1))
	var master: Control = p.find_child("MasterRow", true, false)
	var visible := scroll.get_global_rect().grow(1).encloses(master.get_global_rect())
	_ok(scroll.scroll_vertical >= int(bar.max_value - bar.page) - 1 and visible, "swiping reaches the end: all 15 sets passed, Master row fully visible (%d swipes, %.2f ms/frame)" % [guard, per_frame])
	var vb := scroll.scroll_vertical
	await _swipe(scroll.get_global_rect().get_center(), Vector2(0, 600))
	_ok(scroll.scroll_vertical < vb - 200, "finger swipe down scrolls back up (%d -> %d)" % [vb, scroll.scroll_vertical])
	_complete("c02_album_reaches_master_and_reverses")
	# c03: a stationary tap on VIEW opens that set; a drag that starts on VIEW does not.
	scroll.scroll_vertical = 0
	await _frames(2)
	view = p.find_child("Set_1", true, false).find_children("*", "BaseButton", true, false)[0]
	await _swipe(view.get_global_rect().get_center(), Vector2(0, -200), 8)
	_ok(_root.get_modal_stack().top() == p, "a swipe that starts on VIEW opens nothing")
	scroll.scroll_vertical = 0
	await _frames(3)
	await _tap(view.get_global_rect().get_center(), 2)
	await _frames(8)
	var top = _root.get_modal_stack().top()
	_ok(top != p and String(top.popup_id).begins_with("collection"), "a stationary tap on VIEW opens the set detail (%s)" % String(top.popup_id))
	_complete("c03_taps_open_detail_drag_does_not")
	# c04: desktop wheel still scrolls; reopen 3x still scrolls; tablet-sized SubViewport.
	_root.get_modal_stack().clear("t")
	await _frames(4)
	var reopen_ok := true
	for _i in range(3):
		p = await _open_album()
		scroll = p.find_child("SetList", true, false)
		var a := scroll.scroll_vertical
		await _swipe(scroll.get_global_rect().get_center(), Vector2(0, -400))
		reopen_ok = reopen_ok and scroll.scroll_vertical > a + 100
		var w := InputEventMouseButton.new()
		w.button_index = MOUSE_BUTTON_WHEEL_DOWN
		w.pressed = true
		w.position = _win(scroll.get_global_rect().get_center())
		w.global_position = w.position
		var b := scroll.scroll_vertical
		_parse(w)
		await _frames(2)
		reopen_ok = reopen_ok and scroll.scroll_vertical > b
		_root.get_modal_stack().clear("t")
		await _frames(4)
	_ok(reopen_ok, "3x open / swipe / mouse wheel / close: every open scrolls by finger and by wheel")
	Input.emulate_touch_from_mouse = false
	_complete("c04_wheel_reopen_tablet")

func _c05() -> void:
	print("[c05 Exchange + other popup lists: no STOP control swallows the drag; swipe scrolls]")
	await _boot("c5")
	Input.emulate_touch_from_mouse = true
	var e = _e()
	for cid in e.collection.all_card_ids().slice(0, 40):
		e.collection.add_card(cid)
		e.collection.add_card(cid)   # duplicates -> a long Exchange list
	var app = _root.get_app_state()
	var stack = _root.get_modal_stack()
	var CollectionScreen = load("res://scripts/ui/collection/collection_screen.gd")
	var RobotsScreen = load("res://scripts/ui/robots/robots_screen.gd")
	var DailyScreens = load("res://scripts/ui/daily/daily_screens.gd")
	var ProfileScreens = load("res://scripts/ui/profile/profile_screens.gd")
	var openers := {
		"ExtraList": func(): return CollectionScreen.open_exchange(stack, app),
		"RobotList": func(): return RobotsScreen.open(stack, app),
		"GiftList": func(): return DailyScreens.open_gift_bar(stack, app),
		"AchievementList": func(): return ProfileScreens.open_achievements(stack, app),
		"ShopList": func(): _root.get_acquisition().open_shop({"source": "m47t"}); return stack.top(),
	}
	var bad: Array = []
	for list_name in openers:
		stack.clear("t")
		await _frames(4)
		var p = openers[list_name].call()
		await _frames(10)
		var scroll: ScrollContainer = p.find_child(list_name, true, false) if p != null else null
		if scroll == null:
			bad.append("%s: not found" % list_name)
			continue
		var stops := stop_controls(scroll).size()
		var bar := scroll.get_v_scroll_bar()
		var room := int(bar.max_value - bar.page)
		var a := scroll.scroll_vertical
		if room > 20:
			var btn = scroll.find_children("*", "BaseButton", true, false)
			var start: Vector2 = btn[0].get_global_rect().get_center() if not btn.is_empty() else scroll.get_global_rect().get_center()
			await _swipe(start, Vector2(0, -300))
		var moved := scroll.scroll_vertical - a
		print("    %s: STOP controls %d, scroll room %d px, swipe moved %d px" % [list_name, stops, room, moved])
		if stops != 0 or (room > 20 and moved <= 0):
			bad.append("%s stops=%d room=%d moved=%d" % [list_name, stops, room, moved])
	Input.emulate_touch_from_mouse = false
	_ok(bad.is_empty(), "Exchange, Robots, Gift Bar, Achievements, Shop lists: touch-scrollable, no STOP control inside %s" % str(bad))
	_complete("c05_exchange_and_other_lists")

# ------------------------------------------------------------- Rewarded badge ----

func _badge() -> Dictionary:
	var b = _root.get_home().get_region("RewardedAdsButton").badge
	return {"visible": b.visible, "text": b.text}

func _r01() -> void:
	print("[r01 Rewarded Ads Home badge: '1' exactly when the next sequential reward is actionable]")
	await _boot("r")
	var rd = _e().rewarded_daily
	var home = _root.get_home()
	home.refresh()
	_ok(rd.slot_state(1) == "ready_free" and _badge() == {"visible": true, "text": "1"}, "fresh day, slot 1 ready_free: badge shows 1 (%s)" % str(_badge()))
	_ok(int(HomeBadges.compute(_root.get_app_state()).get("rewarded_ads", -1)) == 1, "HomeBadges.compute()['rewarded_ads'] == 1")
	var r: Dictionary = rd.claim_free()
	home.refresh()
	_ok(r.get("ok", false) and rd.slot_state(2) == "ad_unavailable" and not _badge()["visible"], "slot 1 claimed, slot 2 needs an ad, no provider: badge hidden (%s)" % rd.slot_state(2))
	var prov = ProviderDouble.new()
	_e().rewarded.set_provider(prov)
	home.refresh()
	_ok(rd.slot_state(2) == "ready_ad" and _badge() == {"visible": true, "text": "1"}, "provider available, slot 2 ready_ad: badge shows 1")
	_ok(rd.states().filter(func(s): return s.begins_with("ready")).size() == 1, "only ONE sequential frontier is actionable (not five): %s" % str(rd.states()))
	prov.available = false
	home.refresh()
	_ok(not _badge()["visible"], "provider becomes unavailable: badge hidden")
	prov.available = true
	var st: Dictionary = rd.start_ad(2, "tok-m47t")
	home.refresh()
	_ok(st.get("ok", false) and rd.slot_state(2) == "pending" and not _badge()["visible"], "ad in flight (pending): badge hidden (%s)" % rd.slot_state(2))
	prov.deliver_last({"outcome": "completed", "verified": true})
	home.refresh()
	_ok(rd.is_claimed(2) and rd.slot_state(3) == "ready_ad" and _badge()["text"] == "1" and _badge()["visible"], "after the verified grant the next slot is actionable: badge 1 again")
	for slot in [3, 4, 5]:
		rd.start_ad(slot, "tok-m47t-%d" % slot)
		prov.deliver_last({"outcome": "completed", "verified": true})
	home.refresh()
	_ok(rd.states() == ["claimed", "claimed", "claimed", "claimed", "claimed"] and not _badge()["visible"], "all five claimed: badge hidden")
	_day[0] += 1
	home.refresh()
	_ok(rd.slot_state(1) == "ready_free" and _badge()["visible"], "new local day: slot 1 ready_free again, badge 1")
	_day[0] -= 2
	home.refresh()
	_ok(rd.rollback_locked() and not _badge()["visible"], "clock rollback (locked_rollback): badge hidden")
	_day[0] += 1
	_complete("r01_badge_rules")

func _r02() -> void:
	print("[r02 badge after relaunch (same save) and when the app is blocked]")
	var path := _uniq("r2")
	await _boot("r2", path)
	_e().rewarded_daily.claim_free()
	_root.flush_lifecycle("test")
	await _boot("r2", path)   # relaunch on the same save, no provider
	_root.get_home().refresh()
	_ok(_e().rewarded_daily.is_claimed(1) and not _badge()["visible"], "relaunch: slot 1 still claimed, no provider -> badge hidden")
	_e().rewarded.set_provider(ProviderDouble.new())
	_root.get_home().refresh()
	_ok(_badge() == {"visible": true, "text": "1"}, "relaunch + provider: slot 2 actionable -> badge 1")
	_ok(int(HomeBadges.compute(null).get("rewarded_ads", -1)) == 0, "no app / blocked app: rewarded_ads count 0")
	_complete("r02_badge_relaunch_and_blocked")

# -------------------------------------------------------------------- infra ----

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	Input.emulate_touch_from_mouse = false
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

func _complete(c: String) -> void:
	_completed[c] = true

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	if not missing.is_empty():
		_fail += missing.size()
		print("  FAIL: cases not completed %s" % str(missing))
	print("M47-FAMILY-APK-TOUCH-R01 mobile UX: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
