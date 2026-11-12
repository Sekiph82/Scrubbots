extends "res://tests/m49_surface_matrix.gd"
## M49 surface stress (SB-M49-027, 028, 032): the long / stack / scroll / compact half of
## tests/m49_surface_matrix.gd (split to keep each suite near 5 min; same walk and helpers):
##   v03 long values (SB-M49-027): an English baseline walk, then the same walk with the
##       pseudo-locale (+40%), 7-digit balances, empty Hearts (refill timer), long item labels,
##       big reward bundles: no clip / overflow beyond the English design overhangs; then the
##       same walk in the REAL Turkish table (SB-M51-005/009, UiText.locale = "tr")
##   v04 modal stacks + back (SB-M49-028): popup over popup, the top owns the screen and input,
##       Esc (ui_cancel) / back closes the top only, in LIFO order, then Home stays put
##   v05 scroll screens (SB-M49-028): every ScrollContainer on Collection / Set / Shop / Events /
##       Robots / Tasks / Daily / Gift / Achievements / Help / Profile / Ads / Exchange scrolls
##       when its content is taller, and its first and last rows are fully reachable
##   v07 compact degradation (SB-M49-032): COMPACT sizes under a synthetic notch: journeys stay
##       one info-only row (no buttons / focus: never a level-select grid), the event track
##       scrolls, Events / Comeback / Tasks / ScrubBox / Results stay inside the safe rect.
##
## Run: godot --headless --path . -s res://tests/m49_surface_stress.gd

const COMPACT := [Vector2i(720, 1280), Vector2i(1080, 1920), Vector2i(1536, 2048)]
const LONG_SIZES := [Vector2i(720, 1280), Vector2i(1080, 2400)]
const STACK_SIZES := [Vector2i(720, 1280), Vector2i(1440, 3200), Vector2i(1536, 2048)]

func _initialize() -> void:
	EXPECTED_CASES = ["v03_long_values", "v04_modal_stack_back", "v05_scroll_screens", "v07_compact_degradation"]
	await _setup()
	print("[v03 long values: English baseline, then pseudo-locale +40%, 7-digit balances, long timers / labels, big bundles]")
	_baseline_pass = true
	for phys in LONG_SIZES:
		await _walk(phys)
	_baseline_pass = false
	_scanned = 0
	_stressed = 0
	UiText.pseudo = true
	_long = true
	for phys in LONG_SIZES:
		await _walk(phys)
	_long = false
	UiText.pseudo = false
	# Numbers, names and data copy carry no marker; a third of all measured text is keyed copy.
	_ok(_scanned > 1000 and _stressed * 3 > _scanned, "%d text controls measured, %d carry the pseudo stress copy" % [_scanned, _stressed])
	_scanned = 0
	UiText.locale = "tr"
	for phys in LONG_SIZES:
		await _walk(phys)
	UiText.locale = "en"
	_ok(_scanned > 1000, "%d text controls measured in the Turkish table" % _scanned)
	_complete("v03_long_values")
	await _v04()
	await _v05()
	await _v07()
	_finish()

func _title() -> String:
	return "M49 surface stress"

# ------------------------------------------------------ v04 modal stacks ----

func _v04() -> void:
	print("[v04 popup over popup: top owns input, back / Esc closes the top only (LIFO), Home stays]")
	for phys in STACK_SIZES:
		var lv := _logical(phys)
		await _boot("v04", lv)
		var app = _root.get_app_state()
		var stack = _root.get_modal_stack()
		stack.clear("test")
		await _frames(2)
		app.economy.collection.add_card("s1_c0")   # Card Detail opens for an owned card only
		var chains := [
			[func(): return CollectionScreen.open_album(stack, app), func(): return CollectionScreen.open_set(stack, app, 1),
				func(): return CollectionScreen.open_card(stack, app, "s1_c0")],
			[func(): return RobotsScreen.open(stack, app), func(): return RobotsScreen.open_detail(stack, app, "atlas")],
			[func(): return DailyScreens.open_tasks(stack, app), func(): return DailyScreens.open_scrubbox(stack, app, {"random_any_booster_charges": 1})],
			[func(): return ProfileScreens.open_notifications(stack, app), func(): return ProfileScreens.open_notification_permission(stack, app)],
			[func(): return ProfileScreens.open_profile(stack, app), func(): return ProfileScreens.open_achievements(stack, app)],
		]
		for chain in chains:
			var opened: Array = []
			var bad: Array = []
			for f in chain:
				var p = f.call()
				await _frames(3)
				if p == null or stack.top() != p:
					bad.append("open %d" % opened.size())
					break
				opened.append(String(p.popup_id))
				var vp := Rect2(Vector2.ZERO, Vector2(lv))
				if not p.get_global_rect().encloses(vp) or p.mouse_filter != Control.MOUSE_FILTER_STOP or not _inside(p.get_frame_rect(), vp):
					bad.append("%s does not own the screen" % p.popup_id)
			if stack.ids() != opened:
				bad.append("ids %s" % str(stack.ids()))
			# Back through the real input path (Esc = ui_cancel) once, then handle_back(): the
			# top closes each time, never a lower popup.
			var expect := opened.duplicate()
			var esc := InputEventAction.new()
			esc.action = "ui_cancel"
			esc.pressed = true
			_sub.push_input(esc)
			await _frames(3)
			expect.pop_back()
			if stack.ids() != expect:
				bad.append("Esc -> %s" % str(stack.ids()))
			while bad.is_empty() and not expect.is_empty():
				_root.handle_back()
				await _frames(3)
				expect.pop_back()
				if stack.ids() != expect:
					bad.append("back -> %s" % str(stack.ids()))
			var after: String = _root.handle_back()
			if stack.depth() != 0 or _root.get_navigation().current() != NavigationController.Route.HOME or not _root.is_inside_tree():
				bad.append("after back on Home: %s" % after)
			_ok(bad.is_empty(), "%s (logical %s) %s: stacked, back LIFO %s" % [str(phys), str(lv), str(opened), str(bad)])
			stack.clear("test")
			await _frames(2)
	_complete("v04_modal_stack_back")

# ------------------------------------------------------- v05 scroll screens ----

func _v05() -> void:
	print("[v05 scroll screens: scroll when taller, first and last rows fully reachable]")
	for phys in STACK_SIZES:
		var lv := _logical(phys)
		await _boot_returning("v05", lv)
		var app = _root.get_app_state()
		var stack = _root.get_modal_stack()
		_load_events(app)
		stack.clear("test")
		await _frames(2)
		for d in ["collection", "collection_set", "shop", "events", "robots", "tasks", "daily", "gift_bar", "achievements", "help", "profile", "rewarded_ads", "cards_exchange"]:
			var p = await _open_any(d)
			if p == null:
				_ok(false, "%s %s did not open" % [str(phys), d])
				continue
			var bad: Array = []
			var scrolls: Array = p.find_children("*", "ScrollContainer", true, false).filter(func(s): return (s as Control).is_visible_in_tree())
			for s in scrolls:
				bad.append_array(await _scroll_bad(s))
			_ok(bad.is_empty(), "%s (logical %s) %s: %d scroll area(s) reach first + last row %s" % [str(phys), str(lv), d, scrolls.size(), str(bad)])
			stack.clear("test")
			await _frames(2)
	_complete("v05_scroll_screens")

## One ScrollContainer: inside the screen; content taller -> vertical scrolling enabled and the
## first / last row fully inside the visible area at scroll 0 / max; otherwise all of it shows.
func _scroll_bad(s: ScrollContainer) -> Array:
	var bad: Array = []
	var sr := s.get_global_rect()
	if not _inside_vp(sr):
		bad.append("%s off-screen %s" % [s.name, _rs(sr)])
	var content: Control = null
	for c in s.get_children():
		if c is Control and not (c is ScrollBar) and (c as Control).visible:
			content = c
	if content == null:
		return bad
	var rows := content.get_children().filter(func(c): return c is Control and (c as Control).visible and (c as Control).size.y > 0.0)
	if rows.is_empty():
		return bad
	var taller: bool = content.size.y > s.size.y + 1.0
	if taller and s.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED:
		bad.append("%s taller (%d > %d) but cannot scroll" % [s.name, int(content.size.y), int(s.size.y)])
	var view := sr.grow(1.0)
	s.scroll_vertical = 0
	await _frames(2)
	var first: Rect2 = (rows[0] as Control).get_global_rect()
	if not view.encloses(Rect2(first.position, Vector2(first.size.x, minf(first.size.y, sr.size.y)))):
		bad.append("%s first row %s outside %s" % [s.name, _rs(first), _rs(sr)])
	s.scroll_vertical = int(content.size.y)
	await _frames(2)
	var last: Rect2 = (rows.back() as Control).get_global_rect()
	if not view.encloses(Rect2(Vector2(last.position.x, maxf(last.position.y, last.end.y - sr.size.y)), Vector2(last.size.x, minf(last.size.y, sr.size.y)))):
		bad.append("%s last row %s clipped in %s (scroll %d, taller %s)" % [s.name, _rs(last), _rs(sr), s.scroll_vertical, str(taller)])
	s.scroll_vertical = 0
	return bad

# -------------------------------------------------- v07 compact degradation ----

func _v07() -> void:
	print("[v07 compact sizes under a notch: tracks inside the safe rect, journey one info row, event track scrolls]")
	for phys in COMPACT:
		var lv := _logical(phys)
		_ok(ResponsiveLayout.get_layout_mode(Vector2(lv)) == ResponsiveLayout.LayoutMode.COMPACT, "%s is a COMPACT layout" % str(phys))
		await _boot_returning("v07", lv)
		var app = _root.get_app_state()
		var stack = _root.get_modal_stack()
		_load_events(app)
		stack.clear("test")
		stack.set_synthetic_safe_insets(NOTCH[0], NOTCH[1], NOTCH[2], NOTCH[3])
		var safe := Rect2(Vector2(NOTCH[0], NOTCH[1]), Vector2(lv) - Vector2(NOTCH[0] + NOTCH[2], NOTCH[1] + NOTCH[3]))
		var home = _root.get_home()
		home.get_region("SafeAreaRoot").set_synthetic_insets(NOTCH[0], NOTCH[1], NOTCH[2], NOTCH[3])
		await _frames(6)
		var hj = home.get_journey_strip()
		_journey_ok(phys, "home notch", hj, [home.get_region("PlayButton").get_global_rect()])
		_ok(_inside((hj as Control).get_global_rect(), safe), "%s home journey inside the notch safe rect" % str(phys))
		for d in ["events", "comeback", "tasks", "scrubbox"]:
			var p = ProfileScreens.open_comeback(stack, app) if d == "comeback" else await _open_any(d)
			await _frames(4)
			if p == null:
				_ok(false, "%s %s did not open" % [str(phys), d])
				continue
			var bad: Array = []
			if not _inside(p.get_frame_rect(), safe):
				bad.append("frame %s" % _rs(p.get_frame_rect()))
			bad.append_array(_touch_bad(p, []))
			bad.append_array(_text_bad(p, []))
			if d == "events":
				var es: ScrollContainer = p.find_child("EventScroll", true, false)
				if es.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED or es.get_v_scroll_bar().max_value <= es.size.y:
					bad.append("event track does not scroll (%d / %d)" % [int(es.get_v_scroll_bar().max_value), int(es.size.y)])
				bad.append_array(await _scroll_bad(es))
			_ok(bad.is_empty(), "%s (logical %s) notch %s: inside the safe rect, touch + text ok %s" % [str(phys), str(lv), d, str(bad)])
			stack.clear("test")
			await _frames(2)
		_root.play_current_frontier()
		await _frames(6)
		var host = _root.get_gameplay_host()
		host.get_runtime().set_process(false)
		var res = _root.get_results_screen()
		res.visible = true
		# SB-PHONE-2026-11-12-E: only a LOST shows Results (a win goes Home).
		var model: Dictionary = _root._results_model({"status": "LOST", "level": 1, "attempt": 1})
		model["receipt"] = _receipt("LOST")
		res.show_model(model)
		await _frames(4)
		var rbad: Array = []
		for b in [res.get_primary_button(), res.get_home_button()]:
			var r: Rect2 = (b as Control).get_global_rect()
			if not _inside(r, safe) or r.size.y < TOUCH - 0.5:
				rbad.append("%s %s" % [b.name, _rs(r)])
		_ok(rbad.is_empty(), "%s Results LOST: RETRY + HOME inside the notch safe rect, >= 88 px %s" % [str(phys), str(rbad)])
		res.visible = false
	_complete("v07_compact_degradation")
