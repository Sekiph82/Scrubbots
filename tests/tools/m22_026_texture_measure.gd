extends SceneTree
## SB-M22-026 step 2 — runtime on-screen size of every res://assets/ui/final/ texture on Home,
## Gameplay (5 and 6 slots), Results (won / failed), Shop and Collection at 1080x2400 and the
## 1536x2048 tablet. Step 4 adds Daily/Tasks, Rewarded Ads, Profile/Events/Achievements, Help,
## Settings, Robots detail, every meta ceremony, the pack ceremonies, Need a Hand / Insufficient /
## booster popups, Results reward/robot variants, Shop sub-pages and the FTUE coachmarks; screens
## with no final/ texture to open (RANKS, opening video) are listed in `skipped`. Real main.tscn in a SubViewport at the m49 logical size, throw-away
## user:// saves only. Physical px = logical rect x phys/logical (m49 `_logical`).
## Output JSON: {"scenarios": {scenario: {path: {max_side_px, max_w, max_h, source_w, source_h,
## size_limit, visible, outside_home}}}, "loaded_mib": {scenario: MiB}, "merged": {path: max_side_px}}.
## Run: godot --headless --path . -s res://tests/tools/m22_026_texture_measure.gd -- --out=<file>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")
const RewardedAdsScreen = preload("res://scripts/ui/daily/rewarded_ads_screen.gd")
const ProfileScreens = preload("res://scripts/ui/profile/profile_screens.gd")
const HelpTipsScreen = preload("res://scripts/ui/tutorial/help_tips_screen.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const ShopScreen = preload("res://scripts/ui/shop/shop_screen.gd")
const Popups = preload("res://scripts/ui/popup/popups.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const StdFx = preload("res://tests/support/standard_pack_fixtures.gd")
const PremFx = preload("res://tests/support/premium_pack_fixtures.gd")

const F := "res://assets/ui/final/"
const MIB := 1024.0 * 1024.0
const PHYSICAL := [Vector2i(1080, 2400), Vector2i(1536, 2048)]
## robots and life (Heart popup) are extra: they draw robot poses / heart art also seen above.
const SCENARIOS := ["home", "gameplay_5slot", "gameplay_6slot", "results_won", "results_failed", "shop",
	"collection", "robots", "life",
	# step 4
	"daily", "rewarded_ads", "profile", "help", "settings", "robot_detail", "ceremonies", "robot_unlock",
	"packs", "need_a_hand", "insufficient", "booster_popups", "results_variants", "shop_pages",
	"coachmarks", "ranks", "opening"]
const BOOSTERS := ["plus_one_slot", "random", "selector", "tornado"]

var _sub: SubViewport
var _root
var _scale := 1.0
var _tmp: Array = []
var _report := {}          ## scenario -> path -> entry
var _loaded := {}          ## scenario -> path -> resident bytes
var _skipped := {}         ## scenario -> reason

func _initialize() -> void:
	var out := "user://m22_026_measure.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	MainScript.boot_opening_override = 0
	for phys in PHYSICAL:
		for s in SCENARIOS:
			var key := "%s@%dx%d" % [s, phys.x, phys.y]
			_report[key] = {}
			_loaded[key] = {}
			await call("_" + s, key, phys)
			_shutdown()
	MainScript.boot_opening_override = -1
	_cleanup()
	var merged := {}
	var mib := {}
	for key in _report:
		var bytes := 0
		for p in _loaded[key]:
			bytes += int(_loaded[key][p])
		mib[key] = snappedf(bytes / MIB, 0.01)
		for p in _report[key]:
			merged[p] = maxi(int(merged.get(p, 0)), int(_report[key][p]["max_side_px"]))
		var zero: int = (_report[key] as Dictionary).values().filter(func(e): return e["max_side_px"] == 0).size()
		print("%-28s %3d textures (%d size 0)  %7.2f MiB loaded%s" % [key, _report[key].size(), zero, mib[key],
			("  SKIPPED: " + _skipped[key]) if _skipped.has(key) else ""])
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"scenarios": _report, "loaded_mib": mib, "skipped": _skipped, "merged": merged}, "\t", true))
	f.close()
	print("wrote ", out)
	print("M22-026 MEASURE: DONE (%d scenarios, %d textures)" % [_report.size(), merged.size()])
	quit(0)

# ------------------------------------------------------------------ scenarios ----

func _home(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	_walk(key)
	var hero = _root.get_home().get_region("HomeScrubbyHero")
	hero.set_process(false)
	var anim: Dictionary = hero.get_set()
	for g in anim.get("textures", {}):
		if not hero.start_gesture(g):
			_skipped[key] = "gesture %s did not start" % g
			continue
		var dt := 1.0 / float(anim["fps"])
		hero.step(dt * 0.5)   # mid-frame sampling, so float steps never skip a frame index
		for _i in (anim["textures"][g] as Array).size():
			await process_frame
			_walk(key)
			hero.step(dt)
		hero.step(1.0)

func _gameplay_5slot(key: String, phys: Vector2i) -> void:
	await _play(key, phys)
	_walk(key)

func _gameplay_6slot(key: String, phys: Vector2i) -> void:
	var h = await _play(key, phys)
	if not h.activate_plus_one_slot():
		_skipped[key] = "activate_plus_one_slot refused"
	await _frames(4)
	_walk(key)

func _results_won(key: String, phys: Vector2i) -> void:
	await _results(key, phys, &"WON")

func _results_failed(key: String, phys: Vector2i) -> void:
	await _results(key, phys, &"LOST")

func _results(key: String, phys: Vector2i, status: StringName) -> void:
	var h = await _play(key, phys)
	h.get_completion().terminal_reached.emit(status, {})
	var res = _root.get_results_screen()
	res.finish_reveal()
	await _frames(8)
	if _root.get_navigation().route_name() != "RESULTS":
		_skipped[key] = "route %s, not RESULTS" % _root.get_navigation().route_name()
	_walk(key)

func _shop(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	_root.get_acquisition().open_shop({"source": "measure"})
	await _frames(6)
	_walk(key)

## Album, set detail, card detail of every owned card (and one not found) and Cards Exchange:
## each card seen anywhere is also seen at its largest (detail) size.
func _collection(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	var app = _root.get_app_state()
	var owned := ["s2_c0", "s2_c4", "s2_c8", "s3_c1"]
	for k in range(9):
		owned.append("s1_c%d" % k)
	for cid in owned:
		app.economy.collection.add_card(cid)
	var st = _root.get_modal_stack()
	CollectionScreen.open_album(st, app)
	await _frames(6)
	_walk(key)
	for n in [1, 2, 3]:
		CollectionScreen.open_set(st, app, n)
		await _frames(6)
		_walk(key)
		st.top().close("measure")
	for cid in owned + ["s2_c1"]:
		CollectionScreen.open_card(st, app, cid)
		await _frames(4)
		_walk(key)
		st.top().close("measure")
	await _frames(2)
	CollectionScreen.open_exchange(st, app)
	await _frames(6)
	_walk(key)

func _robots(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	RobotsScreen.open(_root.get_modal_stack(), _root.get_app_state(), _root.ceremonies)
	await _frames(6)
	_walk(key)

func _life(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	_root.get_acquisition().open_life("measure")
	await _frames(6)
	_walk(key)

# ------------------------------------------------------------- step 4 scenarios ----

func _daily(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	var st = _root.get_modal_stack()
	var app = _root.get_app_state()
	for open in [func(): return DailyScreens.open_daily(st, app),
			func(): return DailyScreens.open_daily_reward(st, app, {"day": 1, "reward": {"scrub_bucks": 50}}),
			func(): return DailyScreens.open_daily_reward(st, app, {"day": 5, "reward": {"standard_card_packs": 1}}),
			func(): return DailyScreens.open_tasks(st, app),
			func(): return DailyScreens.open_scrubbox(st, app, {"random_any_booster_charges": 1}),
			func(): return DailyScreens.open_gift_bar(st, app)]:
		await _popup(key, open.call())

func _rewarded_ads(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	await _popup(key, RewardedAdsScreen.open(_root.get_modal_stack(), _root.get_app_state()))

func _profile(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	var st = _root.get_modal_stack()
	var app = _root.get_app_state()
	for open in [ProfileScreens.open_profile, ProfileScreens.open_achievements, ProfileScreens.open_events,
			ProfileScreens.open_comeback, ProfileScreens.open_notifications]:
		await _popup(key, open.call(st, app))

func _help(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	await _popup(key, HelpTipsScreen.open(_root.get_modal_stack(), _root.get_app_state()))

func _settings(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	_root.open_settings()
	await _frames(6)
	if not _root.get_settings_panel().visible:
		_note(key, "settings panel did not open")
	_walk(key)

## Every locked roster robot (an unlocked robot has no detail popup).
func _robot_detail(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	for id in RobotRoster.ids():
		var p = RobotsScreen.open_detail(_root.get_modal_stack(), _root.get_app_state(), id)
		if p == null:
			_note(key, "%s unlocked: no detail popup" % id)
			continue
		await _popup(key, p)

## Set / Master / every Gift Meter milestone (config bundles) / What's New feature / world.
func _ceremonies(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	var cfg = _root.get_app_state().economy.config
	var col: Dictionary = cfg.collection_config()
	var set1: Dictionary = CeremonyEvents._set_entry(col, 1)
	var master: Dictionary = col.get("all_sets_complete", {})
	var events := [
		{"key": "set:1", "kind": "set_complete", "set": 1, "name": String(set1.get("name", "")),
			"rewards": {"scrub_bucks": int(set1.get("scrub_bucks", 0)), "bot_parts": int(set1.get("bot_parts", 0))}},
		{"key": "master", "kind": "master_complete", "sets": int(master.get("required_completed_sets", 0)),
			"rewards": {"scrub_bucks": int(master.get("scrub_bucks", 0)), "bot_parts": int(master.get("bot_parts", 0))}},
	]
	for m in [10, 50, 250, 500, 1000]:
		events.append({"key": "gift:%d" % m, "kind": "gift_milestone", "milestone": m, "cycle": 1, "claimed": false,
			"cycle_max": int(cfg.gift_meter_cycle_max()), "rewards": (cfg.gift_meter_milestone(m) as Dictionary).duplicate(true)})
	var ftue = _root.get_ftue()
	for e in ftue.config()["whats_new"]:
		events.append(ftue.whats_new_event(e))
	# The one real Home world registry entry (home_worlds_v1) and its approved Home art.
	var worlds: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/home_worlds_v1.json"))
	var wid := String(worlds["default_world"])
	events.append({"key": "world:" + wid, "kind": "world_unlock", "world_id": wid,
		"title": String(worlds["worlds"][wid]["baked_title"]), "art": F + "home/background/home_background.png"})
	for ev in events:
		var p = MetaCeremonies.build(ev)
		if p == null:
			_note(key, "%s: builder refused the fixture" % ev["key"])
			continue
		await _popup(key, p, true)

func _robot_unlock(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	for id in RobotRoster.ids():
		var p = MetaCeremonies.build({"key": "robot:" + id, "kind": "robot_unlock", "robot_id": id, "parts_left": 37})
		if p == null:
			_note(key, "robot %s: builder refused" % id)
			continue
		await _popup(key, p, true)

## Standard and Premium opening: every pack frame, then the cards + destinations (AWAIT_ROUTE).
func _packs(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	for made in [StandardPackCeremony.create(StdFx.mixed()), PremiumPackCeremony.create_premium(PremFx.mixed())]:
		if not made["ok"]:
			_note(key, "pack model refused: " + String(made["reason"]))
			continue
		var p = made["popup"]
		_root.get_modal_stack().push(p)
		await _frames(4)
		for i in range(1, StandardPackCeremony.PACK_FRAMES.size() + 1):
			p.pack_frame = i
			await _frames(1)
			_walk(key)
		p.tap()
		var until := Time.get_ticks_msec() + 15000   # the opening runs on real-time tweens
		while p.phase() != "AWAIT_ROUTE" and Time.get_ticks_msec() < until:
			await process_frame
		if p.phase() != "AWAIT_ROUTE":
			_note(key, "%s stuck in %s" % [p.popup_id, p.phase()])
		_walk(key)
		_root.get_modal_stack().clear("measure")
		await _frames(2)

## Over the Fail screen, as in production; both booster pairs so all four cards are seen.
func _need_a_hand(key: String, phys: Vector2i) -> void:
	await _results(key, phys, &"LOST")
	for pair in [["tornado", "random"], ["selector", "plus_one_slot"]]:
		await _popup(key, _root.get_acquisition().open_need_a_hand({"show": true, "level": 1,
			"picks": pair.map(func(id): return {"id": id})}))

func _insufficient(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	await _popup(key, _root.get_acquisition().open_insufficient({"item_label": "Heart", "price_sb": 500, "balance_sb": 0, "source": "measure"}))

func _booster_popups(key: String, phys: Vector2i) -> void:
	var h = await _play(key, phys)
	for id in BOOSTERS:
		await _popup(key, _root.get_acquisition().open_booster(h, id))

## Won with every reward row kind + gift follow-up, lost with hearts + streak rows, each with the
## victory / help pose of every roster robot.
func _results_variants(key: String, phys: Vector2i) -> void:
	await _results(key, phys, &"WON")
	var res = _root.get_results_screen()
	var base: Dictionary = res.get_model()
	var won := {"status": "WON", "reveal_queue": [{"kind": "first_clear_sb", "amount": 10},
		{"kind": "win_streak_sb", "streak": 3, "amount": 10}, {"kind": "bot_parts", "amount": 1},
		{"kind": "gift_meter", "to": 20, "cycle_max": 1000}, {"kind": "collection_cards", "amount": 1}],
		"follow_ups": [{"kind": "gift_milestone"}]}
	var lost := {"status": "LOST", "hearts": {"before": 5, "after": 4}, "streak": {"before": 3, "after": 0}}
	for receipt in [won, lost]:
		for id in RobotRoster.ids():
			var m := base.duplicate(true)
			m["status"] = receipt["status"]
			m["receipt"] = receipt
			m["robot_id"] = id
			res.show_model(m)
			res.finish_reveal()
			await _frames(3)
			_walk(key)

## The Shop is one list (no tabs): the list plus its purchase confirm and feedback popups.
func _shop_pages(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	_root.get_acquisition().open_shop({"source": "measure"})
	await _frames(6)
	_walk(key)
	var shop = ShopScreen.of(_root.get_modal_stack().top())
	if shop == null:
		_note(key, "shop did not open")
		return
	shop._on_action("buy:heart_plus_one", {})   # opens the confirm only; nothing is bought
	await _frames(4)
	_walk(key)
	await _popup(key, Popups.feedback({"ok": true, "reason": "", "text": "measure"}), true)

## Every FTUE step on its real target (Home shortcuts / Play, then gameplay controls).
func _coachmarks(key: String, phys: Vector2i) -> void:
	await _quiet(key, phys)
	_root._coach_timer.stop()
	var ftue = _root.get_ftue()
	var host = null
	for lesson in ftue.config()["lessons"]:
		if lesson["surface"] == "gameplay" and host == null:
			host = await _play(key, phys)
			_root._coach_timer.stop()
			ftue = _root.get_ftue()
		for step in lesson["steps"]:
			var copy: Dictionary = ftue.step_copy(step)
			_root.get_coachmarks().show_step(String(step["id"]), String(copy["title"]), String(copy["body"]),
				_root._coach_target(String(step.get("target", "")), step, host))
			await _frames(2)
			_walk(key)

func _ranks(key: String, _phys: Vector2i) -> void:
	_note(key, "RANKS not served (BottomNav waits for the SB-M43-131 owner policy)")

func _opening(key: String, _phys: Vector2i) -> void:
	_note(key, "opening cinematic is a video (assets/brand/opening/*.ogv), no final/ texture")

# ------------------------------------------------------------------ measure ----

func _walk(key: String) -> void:
	var home: Node = _root.get_home() if _root != null else null
	var stack: Array = [_sub]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children(true))
		var texs: Array = []
		var sz := Vector2.ZERO
		if n is TextureRect or n is NinePatchRect:
			texs = [n.texture]
			sz = (n as Control).get_global_rect().size
		elif n is TextureButton:
			texs = [n.texture_normal, n.texture_pressed, n.texture_hover, n.texture_disabled, n.texture_focused]
			sz = (n as Control).get_global_rect().size
		elif n is Sprite2D and n.texture != null:
			texs = [n.texture]
			sz = n.texture.get_size() * (n as Sprite2D).get_global_transform().get_scale().abs()
		for t in texs:
			_record(key, t, sz.abs() * _scale, (n as CanvasItem).is_visible_in_tree(), not (home != null and home.is_ancestor_of(n)))

## own: drawn outside the Home layer (step 4 per-screen lists leave out Home under a popup).
func _record(key: String, t: Texture2D, sz: Vector2, shown: bool, own: bool) -> void:
	if t is AtlasTexture:
		t = (t as AtlasTexture).atlas
	if t == null or not t.resource_path.begins_with(F):
		return
	var p := t.resource_path.trim_prefix(F)
	_loaded[key][p] = t.get_width() * t.get_height() * 4
	var e: Dictionary = _report[key].get(p, {})
	if e.is_empty():
		var src := _png_size(t.resource_path)
		e = {"max_side_px": 0, "max_w": 0, "max_h": 0, "source_w": src.x, "source_h": src.y,
			"size_limit": _size_limit(t.resource_path), "visible": false, "outside_home": false}
		_report[key][p] = e
	e["visible"] = e["visible"] or shown
	e["outside_home"] = e["outside_home"] or own
	if sz.x <= 0.0 or sz.y <= 0.0:
		return   # loaded, size 0
	e["max_w"] = maxi(e["max_w"], ceili(sz.x))
	e["max_h"] = maxi(e["max_h"], ceili(sz.y))
	e["max_side_px"] = maxi(e["max_w"], e["max_h"])

## Source PNG dimensions from the IHDR header (big-endian width/height at bytes 16..23).
static func _png_size(path: String) -> Vector2i:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return Vector2i.ZERO
	f.big_endian = true
	f.seek(16)
	var w := f.get_32()
	return Vector2i(w, f.get_32())

static func _size_limit(path: String) -> int:
	var c := ConfigFile.new()
	if c.load(path + ".import") != OK:
		return 0
	return int(c.get_value("params", "process/size_limit", 0))

# ------------------------------------------------------------------ fixture ----

func _boot(tag: String, phys: Vector2i) -> void:
	_shutdown()
	var lv := _logical(phys)
	_scale = float(phys.x) / float(lv.x)
	_sub = SubViewport.new()
	_sub.size = lv
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m22_026_measure_%s_%d.save" % [tag.replace("@", "_"), Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

## Boot and close whatever Home opened on launch.
func _quiet(key: String, phys: Vector2i) -> void:
	await _boot(key, phys)
	_root.get_modal_stack().clear("measure")
	await _frames(2)

## Walk one opened popup (null = could not open: noted), then close it.
func _popup(key: String, p, push := false) -> void:
	if p == null:
		_note(key, "a popup did not open")
		return
	if push and not _root.get_modal_stack().push(p):
		p.free()
		_note(key, "push refused")
		return
	await _frames(6)
	_walk(key)
	_root.get_modal_stack().clear("measure")
	await _frames(2)

func _note(key: String, why: String) -> void:
	_skipped[key] = (String(_skipped[key]) + "; " if _skipped.has(key) else "") + why

func _play(key: String, phys: Vector2i):
	await _boot(key, phys)
	_root.get_modal_stack().clear("measure")
	_root.play_current_frontier()
	await _frames(6)
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)
	return h

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null
	MainScript.boot_save_path_override = ""

## Same as tests/m49_responsive_matrix.gd `_logical`.
static func _logical(phys: Vector2i) -> Vector2i:
	var ratio := float(phys.x) / float(phys.y)
	if ratio >= 0.5:
		return Vector2i(int(round(2160.0 * ratio)), 2160)
	return Vector2i(1080, int(round(1080.0 / ratio)))

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
