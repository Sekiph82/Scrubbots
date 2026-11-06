extends "res://tests/m49_touch_targets_text_stress.gd"
## M49 surface matrix (SB-M49-026..028, 031, 032) against the REAL app root (main.tscn) on
## throw-away saves, at the full viewport matrix of tests/m49_responsive_matrix.gd (8 sizes).
## Reuses the factory 115 checks (touch rects >= 88 + no overlap, no clipped / overflowing
## text) and adds what that suite does not walk:
##   v01 inventory: every PLAYER_EXPERIENCE_ASSET_MANIFEST surface is a walked row or an
##       explicitly recorded NOT_BUILT row (a new manifest surface fails this ledger)
##   v02 every walked surface (Home popups, Collection set / card / exchange, Robot detail,
##       acquisition popups, generic popups, ceremonies, packs, gameplay popups, Level Intro,
##       Results WON / LOST) on all 8 sizes: frame inside the screen, touch, text
##   v06 tracks (SB-M49-031): Results journey (10 nodes, no overlap) + Next Cleanup + Catch-Up
##       row, Events Weekly + First-Try, Tasks ScrubBox, Comeback Catch-Up on all 8 sizes;
##       CTAs stay >= 88.
## Long values, modal stacks, scroll screens and compact degradation: tests/m49_surface_stress.gd.
## Weekly / First-Try use an injected config (live events_v1.json schedules none yet).
##
## Run: godot --headless --path . -s res://tests/m49_surface_matrix.gd

const RespMatrix = preload("res://tests/m49_responsive_matrix.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const RewardedAdsScreen = preload("res://scripts/ui/daily/rewarded_ads_screen.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const Popups = preload("res://scripts/ui/popup/popups.gd")
const LevelIntroOverlay = preload("res://scripts/ui/level_intro_overlay.gd")
const ResponsiveLayout = preload("res://scripts/ui/responsive_layout.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")

const MATRIX: Array = RespMatrix.PHYSICAL
const NOTCH: Array = RespMatrix.NOTCH
const MANIFEST := "res://assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json"
const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]
const T0 := 1790000000
## Home-context surfaces this suite walks on top of factory 115's POPUPS.
const HOME_EXTRA := ["comeback", "rewarded_ads", "achievements", "notifications", "notification_permission",
	"collection_set", "card_detail", "cards_exchange", "robot_detail", "scrub_bucks", "insufficient_sb",
	"reward", "confirm", "network_error", "busy", "feedback", "daily_reward", "scrubbox",
	"ceremony_set_complete", "ceremony_master_complete", "ceremony_robot_unlock", "ceremony_gift_milestone",
	"ceremony_feature_unlock", "ceremony_world_unlock", "standard_pack", "premium_pack"]
## Manifest surface id -> walked rows, or "NOT_BUILT: why" (recorded, never invented).
const ROWS := {
	"gameplay_v02": ["gameplay"], "pause": ["pause"], "level_intro": ["level_intro"],
	"victory_results": ["results_WON"], "fail_retry": ["results_LOST"], "life_heart_refill": ["life"],
	"need_a_hand": ["need_a_hand"], "booster_acquire": ["booster_plus_one_slot", "booster_random", "booster_selector", "booster_tornado"],
	"speed_2x_acquire": ["speed_acquire"], "insufficient_sb": ["insufficient_sb", "scrub_bucks"], "shop": ["shop"],
	"collection_album": ["collection"], "collection_set_detail": ["collection_set"], "card_detail": ["card_detail"],
	"cards_exchange": ["cards_exchange"], "standard_pack_open": ["standard_pack"], "premium_pack_open": ["premium_pack"],
	"collection_set_complete": ["ceremony_set_complete"], "master_collection_complete": ["ceremony_master_complete"],
	"robots_main": ["robots"], "robot_detail_locked": ["robot_detail"], "robot_unlock": ["ceremony_robot_unlock"],
	"tasks": ["tasks", "scrubbox"], "daily": ["daily", "daily_reward"], "gift_bar": ["gift_bar"],
	"gift_meter_milestone": ["ceremony_gift_milestone"], "profile": ["profile"], "achievements": ["achievements"],
	"events_main": ["events"], "event_detail": ["events"], "ranks": ["leaderboard"], "comeback_summary": ["comeback"],
	"feature_unlock": ["ceremony_feature_unlock"], "world_unlock_transition": ["ceremony_world_unlock"],
	"account_cloud_sync_conflict": "NOT_BUILT: no account / cloud-conflict screen yet (SB-M49-030 queue row)",
	"generic_reward_confirmation": ["reward", "confirm", "feedback"], "generic_error_offline_loading": ["network_error", "busy"],
	"notification_education_settings": ["notifications", "notification_permission"],
	"friends_postlaunch": "NOT_BUILT: post-launch (manifest status MASTER_REQUIRED_POSTLAUNCH)",
	"home": ["home"], "settings": ["settings", "help"], "rewarded_ads": ["rewarded_ads"],
}

var _now := [T0]
var _day := [20000]
var _long := false        ## v03: long values on top of the pseudo-locale
var _walked: Dictionary = {}   ## surface -> sizes walked in v02
var _events_path := ""

func _initialize() -> void:
	EXPECTED_CASES = ["v01_inventory_rows", "v02_surface_matrix", "v06_tracks_matrix"]
	await _setup()
	_v01()
	print("[v02 every surface on the full 8-size matrix: frame inside, touch >= 88 no overlap, no clipped text; v06 track checks]")
	_baseline_pass = true
	for phys in MATRIX:
		await _walk(phys)
	_baseline_pass = false
	var missing: Array = []
	for row in _rows():
		if int(_walked.get(row, 0)) != MATRIX.size():
			missing.append("%s:%d" % [row, int(_walked.get(row, 0))])
	_ok(missing.is_empty(), "every inventory row walked on all %d sizes %s" % [MATRIX.size(), str(missing)])
	_complete("v02_surface_matrix")
	_complete("v06_tracks_matrix")
	_finish()

func _setup() -> void:
	AppStateScript.test_unlock_all = true
	await process_frame
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	MetaCeremonies.set_video = null      # the static emblem / world art: no decoder in a layout walk
	MetaCeremonies.region_video = null

func _finish() -> void:
	_shutdown()
	_cleanup()
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
	_done()

# ------------------------------------------------------------------ cases ----

func _v01() -> void:
	print("[v01 inventory: every manifest surface is a walked row or a recorded NOT_BUILT]")
	var m = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var ids: Array = m["surfaces"].map(func(s): return String(s["id"]))
	var unknown := ids.filter(func(i): return not ROWS.has(i))
	var stale := ROWS.keys().filter(func(i): return not ids.has(i))
	_ok(unknown.is_empty() and stale.is_empty(), "%d manifest surfaces, all classified; unknown %s stale %s" % [ids.size(), str(unknown), str(stale)])
	for id in ids:
		print("    row %s -> %s" % [id, str(ROWS.get(id, "?"))])
	_complete("v01_inventory_rows")

## Walked row names (factory 115 POPUPS + HOME_EXTRA + gameplay rows).
func _rows() -> Array:
	var out: Array = []
	for id in ROWS:
		if ROWS[id] is Array:
			for r in ROWS[id]:
				if not out.has(r):
					out.append(r)
	return out

## One size: Home surfaces on a returning player (Comeback + Catch-Up live), then gameplay,
## its popups, Level Intro and Results WON / LOST.
func _walk(phys: Vector2i) -> void:
	var lv := _logical(phys)
	await _boot_returning("walk", lv)
	var app = _root.get_app_state()
	var stack = _root.get_modal_stack()
	_load_events(app)
	if _long:
		app.economy.wallet.credit("scrub_bucks", 9999999 - app.economy.wallet.scrub_bucks())
		app.economy.wallet.credit("bot_parts", 99999 - app.economy.wallet.bot_parts())
	var top = stack.top()
	_ok(top != null and String(top.popup_id) == "comeback", "%s: a returning player lands on Welcome Back" % str(phys))
	if top != null and String(top.popup_id) == "comeback":
		await _frames(2)
		_scan(phys, lv, "comeback", top)
		_track_comeback(phys, top)
	stack.clear("test")
	await _frames(2)
	_scan(phys, lv, "home", _root.get_home())
	_journey_ok(phys, "home", _root.get_home().get_journey_strip(), [_root.get_home().get_region("PlayButton").get_global_rect()])
	for d in POPUPS + HOME_EXTRA:
		if d == "comeback":
			continue
		if d == "life" and _long:   # empty Hearts: the refill timer shows
			while app.economy.hearts.consume():
				pass
		var p = await _open_any(d)
		if p == null:
			_ok(false, "%s %s did not open" % [str(phys), d])
		else:
			_scan(phys, lv, d, p)
			if d == "events":
				_track_events(phys, p)
			elif d == "tasks":
				_ok(p.find_child("ScrubBox", true, false) != null and _inside_vp(p.get_action_button("scrubbox").get_global_rect()), "%s: Tasks ScrubBox row + OPEN button inside" % str(phys))
		stack.clear("test")
		await _frames(2)
		if d == "life" and _long:
			while app.economy.hearts.hearts() < app.economy.hearts.max_hearts() and app.economy.hearts.grant_one():
				pass
	_root.play_current_frontier()
	await _frames(6)
	var host = _root.get_gameplay_host()
	if host == null:
		_ok(false, "%s: gameplay did not start" % str(phys))
		return
	host.get_runtime().set_process(false)
	_scan(phys, lv, "gameplay", host.get_screen(), _fronts(host.get_screen()))
	var pause = host.open_pause()
	await _frames(4)
	_scan(phys, lv, "pause", pause)
	host.modal_stack.clear("test")
	await _frames(2)
	var acq = _root.get_acquisition()
	for id in BOOSTERS:
		var bp = acq.open_booster(host, id)
		await _frames(4)
		_scan(phys, lv, "booster_" + id, bp)
		stack.clear("test")
		host.modal_stack.clear("test")
		await _frames(2)
	host.get_screen().get_speed_button().pressed.emit()
	await _frames(4)
	_scan(phys, lv, "speed_acquire", host.get_speed_acquisition_popup())
	stack.clear("test")
	host.modal_stack.clear("test")
	await _frames(2)
	var intro = LevelIntroOverlay.new()
	intro.level = 9999 if _long else 1
	intro.reduced = true
	host.add_child(intro)
	await _frames(3)
	_scan(phys, lv, "level_intro", intro)
	intro.free()
	var res = _root.get_results_screen()
	for status in ["WON", "LOST"]:
		res.visible = true
		var model: Dictionary = _root._results_model({"status": status, "level": 1, "attempt": 1})
		model["receipt"] = _receipt(status)
		res.show_model(model)
		await _frames(4)
		res.finish_reveal()
		await create_timer(0.5).timeout   # the CLEAN NEXT emphasis bump (0.40 s) settles
		_scan(phys, lv, "results_" + status, res)
		if status == "WON":
			_track_results(phys, lv, res, Rect2(Vector2.ZERO, Vector2(lv)))
		else:
			var nah = acq.open_need_a_hand({"show": true, "level": 1, "picks": [{"id": "tornado"}, {"id": "random"}]})
			await _frames(4)
			_scan(phys, lv, "need_a_hand", nah)
			stack.clear("test")
			await _frames(2)
	res.visible = false

## Measure one surface: popup frame (or the control) inside the screen + factory 115 touch +
## text checks. A null surface is a failure.
func _scan(phys: Vector2i, lv: Vector2i, surf: String, node, extra: Array = []) -> void:
	if node == null or not is_instance_valid(node):
		_ok(false, "%s %s: surface missing" % [str(phys), surf])
		return
	var bad: Array = []
	var r: Rect2 = node.get_frame_rect() if node.has_method("get_frame_rect") else (node as Control).get_global_rect()
	if not _inside_vp(r):
		bad.append("frame " + _rs(r))
	bad.append_array(_touch_bad(node, extra))
	bad.append_array(_text_bad(node, []))
	if not _long:
		_walked[surf] = int(_walked.get(surf, 0)) + 1
	_report(phys, lv, surf, bad)

func _open_any(d: String):
	var app = _root.get_app_state()
	var stack = _root.get_modal_stack()
	var acq = _root.get_acquisition()
	var p = null
	app.economy.collection.add_card("s1_c0")   # Card Detail opens for an owned card only
	match d:
		"rewarded_ads", "achievements", "notifications", "notification_permission", "collection_set", "card_detail", "cards_exchange", "robot_detail":
			p = {"rewarded_ads": func(): return RewardedAdsScreen.open(stack, app),
				"achievements": func(): return ProfileScreens.open_achievements(stack, app),
				"notifications": func(): return ProfileScreens.open_notifications(stack, app),
				"notification_permission": func(): return ProfileScreens.open_notification_permission(stack, app),
				"collection_set": func(): return CollectionScreen.open_set(stack, app, 1),
				"card_detail": func(): return CollectionScreen.open_card(stack, app, "s1_c0"),
				"cards_exchange": func(): return CollectionScreen.open_exchange(stack, app),
				"robot_detail": func(): return RobotsScreen.open_detail(stack, app, "atlas")}[d].call()
		"scrub_bucks":
			p = acq.open_scrub_bucks("home")
		"insufficient_sb":
			var label := "SUPER-DELUXE MEGA ROBOT BUNDLE COLLECTION" if _long else "Tornado"
			p = acq.open_insufficient({"item_label": label, "price_sb": 9999999 if _long else 900, "balance_sb": 12})
		"reward", "confirm", "network_error", "busy", "feedback":
			p = _generic(d)
			if p != null and not stack.push(p):
				p.free()
				p = null
		"daily_reward":
			p = DailyScreens.open_daily_reward(stack, app, {"day": 5, "reward": _bundle()})
		"scrubbox":
			p = DailyScreens.open_scrubbox(stack, app, {"random_any_booster_charges": 99 if _long else 1})
		"standard_pack", "premium_pack":
			app.economy.pending_packs.enqueue("m49_%s_%d" % [d, Time.get_ticks_usec()], d.get_slice("_", 0), 1)
			_root.get_pack_presenter().drain()
		_:
			if d.begins_with("ceremony_"):
				p = MetaCeremonies.build(_ceremony(d.trim_prefix("ceremony_")), true)
				if p != null and not stack.push(p):
					p.free()
					p = null
			else:
				return await _open(d)
	await _frames(4)
	return stack.top() if p == null else p

func _generic(d: String):
	var long := "Please confirm this much longer than usual line of text" if _long else "Use one Tornado?"
	match d:
		"reward":
			return Popups.reward({"committed": true, "rows": [{"text": UiText.reward_text(_bundle())}, {"text": long}]})
		"confirm":
			return Popups.confirm({"title": "CONFIRM", "body": long})
		"network_error":
			return Popups.network_error({"surface": "store"})
		"busy":
			return Popups.busy({})
		"feedback":
			return Popups.feedback({"ok": false, "reason": long})
	return null

## Ceremony events in the builder's documented shapes (tests/m43_master_c005_meta_ceremonies).
func _ceremony(kind: String) -> Dictionary:
	match kind:
		"set_complete":
			return {"key": "set:1", "kind": kind, "set": 1, "name": "Meet the Scrubbots", "rewards": _bundle()}
		"master_complete":
			return {"key": "master", "kind": kind, "sets": 15, "rewards": _bundle()}
		"robot_unlock":
			return {"key": "robot:atlas", "kind": kind, "robot_id": "atlas", "parts_left": 12}
		"gift_milestone":
			var r := _bundle()
			r["guaranteed_new_fallback_sb"] = 500
			return {"key": "gift", "kind": kind, "milestone": 1000, "cycle_max": 1000, "rewards": r}
		"feature_unlock":
			return {"key": "feature:cards_exchange", "kind": kind, "feature_id": "cards_exchange", "name": "CARDS EXCHANGE",
				"body": "Trade extra card copies for Scrub Bucks.", "icon": "res://assets/ui/final/home/shortcuts/icon_shortcut_cards_exchange.png"}
		"world_unlock":
			return {"key": "world:world_01", "kind": kind, "world_id": "world_01", "title": "WHISPERING PARK", "subtitle": "World 01",
				"art": "res://assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png"}
	return {}

## A reward bundle: the Gift 1000 shape, or 6-7 digit amounts for v03.
func _bundle() -> Dictionary:
	if _long:
		return {"scrub_bucks": 999999, "bot_parts": 9999, "premium_card_packs": 99, "selected_booster_charges": 99, "guaranteed_new_cards": 9}
	return {"scrub_bucks": 600, "bot_parts": 2, "premium_card_packs": 1, "selected_booster_charges": 2, "guaranteed_new_cards": 1}

## The fullest committed receipt shape Results shows: every reward-row kind incl. Catch-Up
## and the Gift follow-up (WON), Hearts + ended streak (LOST). Presentation input only.
func _receipt(status: String) -> Dictionary:
	var n := 999999 if _long else 50
	if status == "LOST":
		return {"status": "LOST", "hearts": {"before": 5, "after": 4}, "streak": {"before": 999 if _long else 4, "after": 0}}
	return {"status": "WON", "reveal_queue": [{"kind": "first_clear_sb", "amount": n}, {"kind": "win_streak_sb", "streak": 999 if _long else 5, "amount": n},
		{"kind": "bot_parts", "amount": n}, {"kind": "gift_meter", "to": 950, "cycle_max": 1000}, {"kind": "collection_cards", "amount": 99 if _long else 1},
		{"kind": "catchup", "step": 3, "steps": 3, "reward": {"scrub_bucks": n, "bot_parts": 1}}], "follow_ups": [{"kind": "gift_milestone"}]}

## Weekly (active, 6 milestones) + upcoming Weekly + First-Try Cleanup, through the canonical
## EventService loader. v03 uses big reward bundles.
func _load_events(app) -> void:
	var rw := {"scrub_bucks": 999999, "bot_parts": 9999, "premium_card_packs": 99} if _long else {"scrub_bucks": 50}
	var ms: Array = []
	for t in [1, 3, 5, 10, 20, 40]:
		ms.append({"target": t, "reward": rw})
	var cfg := {"schema": "scrubbots.events.v1", "version": 1, "approved_reward_types": ["scrub_bucks", "bot_parts", "premium_card_packs", "selected_booster_charges"],
		"weekly_events": [{"id": "wk1", "start_ts": _now[0] - 3600, "unclaimed_on_expiry": "forfeit", "milestones": ms},
			{"id": "wk2", "start_ts": _now[0] + 6 * 86400, "unclaimed_on_expiry": "forfeit", "milestones": [{"target": 1, "reward": rw}]}],
		"first_try_cleanup": {"id": "ft1", "levels": 99 if _long else 5, "reward": {"premium_card_packs": 1, "selected_booster_charges": 2}}}
	_events_path = "user://m49_sm_events_%d.json" % Time.get_ticks_usec()
	_tmp.append(_events_path)
	var f := FileAccess.open(_events_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(cfg))
	f.close()
	app.economy.events.load_config(_events_path)
	app.economy.events.on_progression_terminal(true, false)

## Fresh save at T0, then relaunched 49 h later: the shipped Comeback window + Catch-Up track.
func _boot_returning(tag: String, lv: Vector2i) -> void:
	_now[0] = T0
	_day[0] = 20000
	await _boot(tag, lv)
	var path: String = MainScript.boot_save_path_override
	_root.get_app_state().request_save()
	_root.flush_lifecycle("test")
	_now[0] += 49 * 3600
	_day[0] += 2
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = lv
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

# ----------------------------------------------------------- track checks ----

## Journey: 10 info-only nodes in one row inside the strip, no node overlap, never over `avoid`.
func _journey_ok(phys: Vector2i, where: String, j, avoid: Array) -> void:
	if j == null or not (j as Control).is_visible_in_tree():
		_ok(false, "%s %s journey not shown" % [str(phys), where])
		return
	var jr: Rect2 = (j as Control).get_global_rect()
	var rects: Array = j.node_rects().map(func(r): return Rect2(r.position + jr.position, r.size))
	var bad: Array = []
	if rects.size() != 10:
		bad.append("nodes=%d" % rects.size())
	for i in range(rects.size()):
		var r: Rect2 = rects[i]
		if not _inside(r, jr) or not _inside_vp(r):
			bad.append("node%d %s" % [i, _rs(r)])
		if absf(r.get_center().y - jr.get_center().y) > 0.5:
			bad.append("node%d off the row" % i)
		if r.size.y < 24.0:
			bad.append("node%d %dpx" % [i, int(r.size.y)])
		if i > 0 and (rects[i - 1] as Rect2).intersects(r):
			bad.append("nodes %d/%d overlap" % [i - 1, i])
	for a in avoid:
		if jr.intersects(a):
			bad.append("over " + _rs(a))
	if j.mouse_filter != Control.MOUSE_FILTER_IGNORE or j.focus_mode != Control.FOCUS_NONE or j.get_child_count() > 0:
		bad.append("interactive")
	_ok(bad.is_empty(), "%s %s journey: one row of 10 info-only nodes inside %s %s" % [str(phys), where, _rs(jr), str(bad)])

func _track_results(phys: Vector2i, lv: Vector2i, res, safe: Rect2) -> void:
	_journey_ok(phys, "results", res.get_journey_strip(), [])
	var bad: Array = []
	var nc: Control = res.get_next_cleanup_panel()
	if not nc.is_visible_in_tree() or not _inside(nc.get_global_rect(), safe):
		bad.append("next_cleanup %s" % _rs(nc.get_global_rect()))
	for b in [res.get_primary_button(), res.get_home_button()]:
		var r: Rect2 = (b as Control).get_global_rect()
		if not _inside(r, safe) or r.size.x < TOUCH - 0.5 or r.size.y < TOUCH - 0.5:
			bad.append("%s %s" % [b.name, _rs(r)])
	var stack: Control = res.find_child("Stack", true, false)
	if not _inside(stack.get_global_rect(), safe):
		bad.append("content %s" % _rs(stack.get_global_rect()))
	if not res.shown_row_texts().any(func(t): return String(t).contains(UiText.t("RESULTS_CATCHUP", ["", "", ""]).get_slice(" ", 0))):
		bad.append("no Catch-Up row %s" % str(res.shown_row_texts()))
	_ok(bad.is_empty(), "%s Results WON: Next Cleanup, CTAs >= 88, Catch-Up row, content inside %s %s" % [str(phys), _rs(safe), str(bad)])

func _track_events(phys: Vector2i, p) -> void:
	var bad: Array = []
	for n in ["Event_wk1", "Event_wk2", "FirstTry"]:
		var c = p.find_child(n, true, false)
		if c == null:
			bad.append(n + " missing")
	var ft: Button = p.get_action_button("ft_join")
	if ft == null or ft.get_global_rect().size.y < TOUCH - 0.5:
		bad.append("ft_join")
	_ok(bad.is_empty(), "%s Events: Weekly active + upcoming + First-Try cards, JOIN >= 88 %s" % [str(phys), str(bad)])

func _track_comeback(phys: Vector2i, p) -> void:
	var row = p.find_child("CatchUp", true, false)
	var pips: Array = [0, 1, 2].map(func(i): return p.find_child("Pip_%d" % i, true, false))
	var ok: bool = row != null and pips.all(func(pp): return pp != null and _inside_vp((pp as Control).get_global_rect()))
	_ok(ok, "%s Comeback: Catch-Up row + 3 pips inside the screen" % str(phys))

func _inside_vp(r: Rect2) -> bool:
	return _inside(r, Rect2(Vector2.ZERO, Vector2(_sub.size)))

static func _inside(inner: Rect2, outer: Rect2) -> bool:
	return RespMatrix._inside(inner, outer)

func _title() -> String:
	return "M49 surface matrix"

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("%s evidence: %s (%d/%d cases, %d fail)" % [_title(), "PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
