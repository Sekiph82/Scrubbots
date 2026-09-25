extends SceneTree
## M42-C001 — production Home evidence (SB-M42-002 and later Home tasks append cases).
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_home.gd

const AppState = preload("res://scripts/app/app_state.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")

const REQUIRED_VIEWPORTS := [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400), Vector2i(1440, 3200)]

var EXPECTED_CASES := [
	"home_shell_tree", "home_in_real_root", "home_blocked_state",
	"play_cta_fresh", "continue_cta_frontier",
	"settings_single_authority", "components_viewport_matrix", "layered_art_regions",
	"shortcut_columns_responsive", "live_binding", "approved_art_only", "scrub_bucks_chip",
	"bot_parts_progress", "gift_meter_semantics", "gift_bar_claims", "cards_exchange_presentation",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	await _home_shell_tree()
	await _home_in_real_root()
	await _home_blocked_state()
	await _play_cta_fresh()
	await _continue_cta_frontier()
	await _settings_single_authority()
	await _components_viewport_matrix()
	await _layered_art_regions()
	await _shortcut_columns_responsive()
	await _live_binding()
	await _approved_art_only()
	await _scrub_bucks_chip()
	await _bot_parts_progress()
	await _gift_meter_semantics()
	await _gift_bar_claims()
	await _cards_exchange_presentation()
	_cleanup()
	_done()

func _home_shell_tree() -> void:
	print("[home shell tree]")
	var app = AppState.new(_uniq("shell"))
	var sub := _sub(Vector2i(1080, 2160))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	await process_frame
	await process_frame
	_ok(home.get_node_or_null("SafeAreaRoot/MarginContainer/Content/HomeLayout") != null, "SafeAreaRoot -> MarginContainer -> Content -> HomeLayout")
	var layout: Control = home.get_region("HomeLayout")
	var names: Array = []
	for c in layout.get_children():
		names.append(String(c.name))
	_ok(names == ["TopCurrencyHUD", "GiftMeter", "MainWorldArea", "PlayButton", "StatusLabel", "WinStreakRewardTrack", "BottomNav"], "MASTER_UI §6 region order %s" % str(names))
	var world_names: Array = []
	for c in home.get_region("MainWorldArea").get_children():
		world_names.append(String(c.name))
	_ok(world_names == ["LeftShortcutColumn", "CenterScrubbyArea", "RightShortcutColumn"], "MainWorldArea left/center/right")
	_ok(home.get_region("PlayButton") is Button and not home.get_region("PlayButton").disabled, "live PLAY button enabled for a healthy save")
	var full_textures := 0
	for n in home.find_children("*", "TextureRect", true, false):
		if (n as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			full_textures += 1
	_ok(full_textures == 0, "no interactive bitmap (no input-receiving TextureRect)")
	_ok(home.get_region("Nav_settings").name == "SettingsButton" and not home.get_region("Nav_settings").disabled, "bottom-nav SETTINGS live")
	_ok(home.get_region("Nav_events").disabled and home.get_region("Nav_robots").disabled and home.get_region("Nav_leaderboard").disabled, "later-milestone tabs disabled, not faked")
	sub.free()
	_complete("home_shell_tree")

func _home_in_real_root() -> void:
	print("[home in real root]")
	var root = await _boot_main(_uniq("root"))
	var home = root.get_home()
	_ok(home != null and home.get_app_state() == root.get_app_state(), "real root Home bound to the ONE canonical AppState")
	_ok(home.visible and root.get_navigation().current() == NavigationController.Route.HOME, "Home visible at route HOME")
	_ok(root.find_child("GodotVersionLabel", true, false) == null and root.find_child("BoardCoreLabel", true, false) == null, "pre-M42 debug label shell removed")
	var settings_btn: Button = root.find_child("SettingsButton", true, false)
	settings_btn.pressed.emit()
	_ok(root.get_navigation().is_settings_open() and root.get_settings_panel().visible, "Home SETTINGS opens the canonical Settings overlay")
	_ok(root.get_settings_panel().get_index() > home.get_index(), "Settings overlay drawn above Home")
	_shutdown(root)
	_complete("home_in_real_root")

func _home_blocked_state() -> void:
	print("[home blocked state]")
	var path := _uniq("blocked")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema": "scrubbots.save", "version": 999}))
	f.close()
	var before := FileAccess.get_file_as_string(path)
	var root = await _boot_main(path)
	var home = root.get_home()
	_ok(root.is_blocked() and home.get_region("PlayButton").disabled, "blocked save: PLAY disabled")
	_ok(String(home.get_region("StatusLabel").text).find("newer version") != -1, "blocked save: explicit read-only message")
	home.get_region("PlayButton").pressed.emit()
	_ok(root.get_navigation().current() == NavigationController.Route.HOME and root.get_gameplay_host() == null, "blocked: no gameplay")
	_shutdown(root)
	_ok(FileAccess.get_file_as_string(path) == before, "blocked future-schema save untouched")
	_complete("home_blocked_state")

func _play_cta_fresh() -> void:
	print("[play cta fresh]")
	var root = await _boot_main(_uniq("play"))
	var home = root.get_home()
	var play: Button = home.get_region("PlayButton")
	_ok(play.text == "PLAY" and not play.disabled, "fresh save: live CTA 'PLAY'")
	_ok(home.get_launch_preview().get("level") == 1 and home.get_launch_preview().get("ok"), "CTA previews canonical frontier level 1")
	play.pressed.emit()
	await process_frame
	var host = root.get_gameplay_host()
	_ok(root.get_navigation().current() == NavigationController.Route.GAMEPLAY, "PLAY -> GAMEPLAY")
	_ok(host != null and host.is_built() and host.app_state == root.get_app_state(), "host built with the same AppState")
	_ok(host != null and host.progression_level == 1 and root.last_launch["launch"]["entry_id"] == "m21_level_001_hazard_bot", "launched exactly the frontier entry")
	_ok(not home.visible, "Home hidden during gameplay")
	var pickers: int = root.find_children("*", "OptionButton", true, false).size() + root.find_children("*", "ItemList", true, false).size()
	_ok(pickers == 0, "no level picker control anywhere")
	_shutdown(root)
	_complete("play_cta_fresh")

func _continue_cta_frontier() -> void:
	print("[continue cta frontier]")
	var path := _uniq("cont")
	var app = AppState.new(path)
	_ok(app.progression.record_win(1), "record level-1 win")
	app.request_save()
	var root = await _boot_main(path)
	var home = root.get_home()
	var play: Button = home.get_region("PlayButton")
	_ok(play.text == "CONTINUE · LEVEL 2", "CTA shows CONTINUE · LEVEL 2 (%s)" % play.text)
	_ok(play.disabled and String(home.get_region("StatusLabel").text).find("coming soon") != -1, "frontier without content: disabled + honest message")
	play.pressed.emit()
	var r: Dictionary = root.play_current_frontier()
	_ok(not r.get("ok", true) and r.get("reason") == "CONTENT_MISSING", "direct launch refuses CONTENT_MISSING")
	_ok(root.get_gameplay_host() == null and root.get_navigation().current() == NavigationController.Route.HOME, "no gameplay, still HOME (never falls back to level 1)")
	_shutdown(root)
	_complete("continue_cta_frontier")

## SB-M42-004: Home Settings reuses the ONE M41 panel bound to the ONE AppState.
func _settings_single_authority() -> void:
	print("[settings single authority]")
	var path := _uniq("settings")
	var root = await _boot_main(path)
	var app = root.get_app_state()
	var btn: Button = root.get_home().get_region("Nav_settings")
	var panel = root.get_settings_panel()
	for _i in range(3):
		btn.pressed.emit()
		panel.close_panel()
	btn.pressed.emit()
	_ok(root.find_children("*", "", true, false).filter(func(n): return n.get_script() == panel.get_script()).size() == 1, "exactly one SettingsPanel instance after repeated opens")
	_ok(panel.visible and root.get_navigation().is_settings_open(), "Home SETTINGS opens it")
	panel.get_toggle("music").button_pressed = false
	panel.get_reduced_effects_toggle().button_pressed = true
	_ok(not app.audio.is_music_enabled() and app.effects.is_reduced(), "changes land in the canonical AppState services")
	panel.close_panel()
	var p2 = AppState.new(path)
	_ok(not p2.audio.is_music_enabled() and p2.effects.is_reduced(), "persisted through the canonical save (no side authority)")
	_ok(root.get_navigation().current() == NavigationController.Route.HOME and not root.get_navigation().is_settings_open(), "closing returns to Home")
	_ok(app.progression.current_level() == 1 and app.economy.wallet.scrub_bucks() == p2.economy.wallet.scrub_bucks(), "no unrelated side effects (progression/economy unchanged)")
	root.get_home().get_region("PlayButton").pressed.emit()
	root.open_settings()
	_ok(not root.get_navigation().is_settings_open() and not panel.visible, "Settings cannot open during gameplay")
	_shutdown(root)
	_complete("settings_single_authority")

## SB-M42-010: reusable components inside the safe area across the required viewport
## matrix (+16:9 and tablet portrait), touch >= 88, regions never overlap.
func _components_viewport_matrix() -> void:
	print("[components viewport matrix]")
	var app = AppState.new(_uniq("vp"))
	var sizes: Array = REQUIRED_VIEWPORTS + [Vector2i(1080, 1920), Vector2i(1536, 2048)]
	for size in sizes:
		for insets in [[0, 0, 0, 0], [0, 132, 0, 96]]:
			var sub := _sub(size)
			var home = HomeScreenScene.instantiate()
			sub.add_child(home)
			home.bind(app)
			await process_frame
			home.get_region("SafeAreaRoot").set_synthetic_insets(insets[0], insets[1], insets[2], insets[3])
			await process_frame
			await process_frame
			var safe := Rect2(Vector2(insets[0], insets[1]), Vector2(size) - Vector2(insets[0] + insets[2], insets[1] + insets[3]))
			var tag := "%s insets=%s" % [str(size), str(insets)]
			var small: Array = []
			var outside: Array = []
			for b in home.find_children("*", "BaseButton", true, false):
				var r: Rect2 = (b as Control).get_global_rect()
				if r.size.y < 88.0 - 0.5 or r.size.x < 88.0 - 0.5:
					small.append(String(b.name))
				if not safe.grow(0.5).encloses(r):
					outside.append(String(b.name))
			_ok(home.find_children("*", "BaseButton", true, false).size() >= 14, "%s: >= 14 live buttons measured (8 shortcuts + PLAY + 5 nav)" % tag)
			_ok(small.is_empty(), "%s: every button >= 88x88 %s" % [tag, str(small)])
			_ok(outside.is_empty(), "%s: every button inside safe area %s" % [tag, str(outside)])
			var prev_end := -1.0
			var overlap := false
			for c in home.get_region("HomeLayout").get_children():
				var r2: Rect2 = (c as Control).get_global_rect()
				if r2.position.y < prev_end - 0.5:
					overlap = true
				prev_end = r2.end.y
			_ok(not overlap and prev_end <= safe.end.y + 0.5, "%s: regions stacked without overlap, inside safe bottom" % tag)
			var world: Rect2 = home.get_region("MainWorldArea").get_global_rect()
			for col in ["LeftShortcutColumn", "RightShortcutColumn"]:
				for b in home.get_region(col).get_children():
					if not world.grow(0.5).encloses((b as Control).get_global_rect()):
						outside.append(String(b.name))
			_ok(outside.is_empty(), "%s: shortcuts fit inside MainWorldArea" % tag)
			sub.free()
	# Components are live Labels / native bars (no baked text textures).
	var sub2 := _sub(Vector2i(1080, 2160))
	var h2 = HomeScreenScene.instantiate()
	sub2.add_child(h2)
	h2.bind(app)
	await process_frame
	_ok(h2.get_region("ScrubBucksChip").value_label is Label and h2.get_region("GiftMeterBar").bar is ProgressBar and h2.get_region("Shortcut_daily") is Button, "live Label / native ProgressBar / Button components")
	sub2.free()
	_complete("components_viewport_matrix")

## SB-M42-011: layered canonical regions, reference never shipped as one bitmap.
func _layered_art_regions() -> void:
	print("[layered art regions]")
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/HOME_ASSET_MANIFEST.json"))
	var order: Array = manifest["layer_order"]
	var sub := _sub(Vector2i(1080, 2160))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(AppState.new(_uniq("layers")))
	await process_frame
	var layers: Array = home.get_art_layers()
	var names: Array = []
	for l in layers:
		names.append(String(l.name).trim_prefix("Layer_"))
	var expected: Array = []
	for o in order:
		if o != "ui":
			expected.append(String(o).replace(".", "_"))
	_ok(names == expected, "art layers follow manifest layer_order %s" % str(names))
	var all_ignore := true
	for l in layers:
		all_ignore = all_ignore and (l as Control).mouse_filter == Control.MOUSE_FILTER_IGNORE
	_ok(all_ignore, "every art layer is decorative (ignores input)")
	_ok(home.get_region("Background").get_index() < home.get_region("SafeAreaRoot").get_index(), "screen art layers draw behind all UI")
	_ok(layers[4].get_parent() == home.get_region("CenterScrubbyArea") and layers[5].get_parent() == home.get_region("CenterScrubbyArea"), "world/character layers live in CenterScrubbyArea between the shortcut columns")
	var ref_hits: Array = []
	for f in ["res://scripts/ui/home/home_screen.gd", "res://scenes/ui/home/home_screen.tscn", "res://scripts/app/main.gd", "res://scenes/app/main.tscn"]:
		if FileAccess.get_file_as_string(f).find("main screen.png") != -1 or FileAccess.get_file_as_string(f).find("_owner_inbox") != -1:
			ref_hits.append(f)
	_ok(ref_hits.is_empty(), "owner reference screenshot never loaded by Home/app %s" % str(ref_hits))
	var bound := 0
	for l in layers:
		if (l as TextureRect).texture != null:
			bound += 1
	_ok(bound == 0, "no art bound before owner approval (SB-M42-016/017 gate)")
	sub.free()
	_complete("layered_art_regions")

## SB-M42-012: shortcut columns flank the center world area without collision.
func _shortcut_columns_responsive() -> void:
	print("[shortcut columns responsive]")
	var app = AppState.new(_uniq("cols"))
	for size in REQUIRED_VIEWPORTS + [Vector2i(1080, 1920), Vector2i(1536, 2048)]:
		var sub := _sub(size)
		var home = HomeScreenScene.instantiate()
		sub.add_child(home)
		home.bind(app)
		for _i in range(4):
			await process_frame
		var tag := str(size)
		var world: Rect2 = home.get_region("MainWorldArea").get_global_rect()
		var center: Rect2 = home.get_region("CenterScrubbyArea").get_global_rect()
		var left: Rect2 = home.get_region("LeftShortcutColumn").get_global_rect()
		var right: Rect2 = home.get_region("RightShortcutColumn").get_global_rect()
		var play: Rect2 = home.get_region("PlayButton").get_global_rect()
		_ok(center.size.x >= world.size.x * 0.4 - 1.0, "%s: center world keeps >= 40%% width (%.0f/%.0f)" % [tag, center.size.x, world.size.x])
		_ok(left.end.x <= center.position.x + 0.5 and right.position.x >= center.end.x - 0.5, "%s: columns left/right of center, no overlap" % tag)
		_ok(left.end.y <= play.position.y + 0.5 and right.end.y <= play.position.y + 0.5, "%s: columns end above the PLAY CTA" % tag)
		var min_w := 99999.0
		for side in ["LeftShortcutColumn", "RightShortcutColumn"]:
			for b in home.get_region(side).get_children():
				min_w = minf(min_w, (b as Control).size.x)
		_ok(min_w >= 88.0 - 0.5, "%s: shortcut width >= 88 (%.0f)" % [tag, min_w])
		sub.free()
	_complete("shortcut_columns_responsive")

const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")
var _now := 1790000000

## SB-M42-015: every Home value is a live projection of canonical services; Home never
## writes state and never keeps its own copy.
func _live_binding() -> void:
	print("[live binding]")
	var clock := func(): return _now
	var app = AppState.new(_uniq("live"), clock, LocalCalendar.offset_provider(clock, 0))
	var sub := _sub(Vector2i(1080, 2160))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	await process_frame
	var e = app.economy
	var before: Dictionary = e.snapshot()
	var prog_before: Dictionary = app.progression.snapshot()
	for _i in range(3):
		home.refresh()
	_ok(e.snapshot() == before and app.progression.snapshot() == prog_before, "refresh never mutates economy/progression")
	var vm: Dictionary = home.get_view_model()
	_ok(vm["scrub_bucks"] == e.wallet.scrub_bucks() and home.get_region("ScrubBucksChip").value_label.text.replace(",", "") == str(e.wallet.scrub_bucks()), "SB chip == wallet")
	e.wallet.credit("scrub_bucks", 1234)
	e.wallet.credit("bot_parts", 37)
	e.hearts.consume()
	e.gift.add_streak_sb("t_live_1", 25)
	home.refresh()
	vm = home.get_view_model()
	_ok(home.get_region("ScrubBucksChip").value_label.text.replace(",", "") == str(e.wallet.scrub_bucks()), "SB chip follows the wallet live")
	_ok(vm["bot_parts"] == e.wallet.bot_parts() and home.get_region("ProfileBotParts").caption.text.find("%d/%d" % [e.wallet.bot_parts(), e.robots.unlock_cost()]) != -1, "Bot Parts N/%d follows the wallet" % e.robots.unlock_cost())
	_ok(home.get_region("HeartsChip").value_label.text == "%d/%d" % [e.hearts.hearts(), e.hearts.max_hearts()] and home.get_region("HeartsChip").sub_label.visible, "Hearts count + live regen timer shown when not full")
	_now += 60
	home.refresh()
	_ok(home.get_region("HeartsChip").sub_label.text == "29:00", "Heart timer counts down from wall clock (%s)" % home.get_region("HeartsChip").sub_label.text)
	_ok(vm["gift_progress"] == e.gift.cycle_progress() and vm["gift_claimable"] == e.gift.claimable().size(), "Gift Meter progress / claimable follow GiftMeterService")
	_ok(home.get_region("Shortcut_gift_bar").badge.visible and home.get_region("Shortcut_gift_bar").badge.text == str(e.gift.claimable().size()), "Gift shortcut badge = live claimable count")
	var props: Array = []
	for pr in home.get_script().get_script_property_list():
		props.append(pr["name"])
	_ok(not props.has("scrub_bucks") and not props.has("hearts") and not props.has("bot_parts"), "Home script declares no balance fields of its own")
	sub.free()
	_complete("live_binding")

const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")
const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")

## SB-M42-017: only owner-approved art binds; pending candidates keep native placeholders.
func _approved_art_only() -> void:
	print("[approved art only]")
	var app = AppState.new(_uniq("art"))
	var sub := _sub(Vector2i(1080, 2160))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	await process_frame
	var bound := 0
	for l in home.get_art_layers():
		if l.texture != null:
			bound += 1
	for id in ["Shortcut_daily", "Shortcut_cards_exchange"]:
		if home.get_region(id).icon != null:
			bound += 1
	_ok(bound == 0 and home.get_region("ScrubBucksChip").icon.texture == null, "production manifest (nothing approved): no art bound, native placeholders")
	# Owner-approval simulation on an in-memory manifest copy (repo manifest untouched).
	var m = V.load_manifest()
	var approve := ["home_bg_sky", "scrubby_home_pose", "icon_currency_scrub_bucks", "icon_shortcut_daily"]
	for a in m["assets"]:
		if approve.has(a["slug"]):
			a["status"] = "APPROVED"
			a["approved_sha256"] = FileAccess.get_sha256("res://" + a["path"])
	home.set_art_binder(HomeArtBinder.new(m))
	await process_frame
	_ok(home.get_region("Layer_background.sky").texture != null and home.get_region("Layer_characters").texture != null, "approved sky + Scrubby bind to their layers")
	_ok(home.get_region("Layer_background.city_far").texture == null and home.get_region("Layer_central_world_and_environment").texture == null, "unapproved layers stay empty")
	_ok(home.get_region("ScrubBucksChip").icon.texture != null and home.get_region("Shortcut_daily").icon != null and home.get_region("Shortcut_shop").icon == null, "approved icons bind; unapproved do not")
	var outside: Array = []
	var safe := Rect2(Vector2.ZERO, Vector2(1080, 2160))
	for b in home.find_children("*", "BaseButton", true, false):
		if not safe.grow(0.5).encloses((b as Control).get_global_rect()) or (b as Control).size.y < 87.5:
			outside.append(b.name)
	_ok(outside.is_empty(), "with art bound, controls still inside viewport and >= 88 px %s" % str(outside))
	_ok(FileAccess.get_file_as_string("res://assets/ui/HOME_ASSET_MANIFEST.json").find("APPROVED\"") == -1, "repository manifest still has no APPROVED entry (never self-approved)")
	sub.free()
	_complete("approved_art_only")

## SB-M42-018: Scrub Bucks semantics; no coin/Star authority anywhere in Home.
func _scrub_bucks_chip() -> void:
	print("[scrub bucks chip]")
	var app = AppState.new(_uniq("sb"))
	var sub := _sub(Vector2i(1080, 2160))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	await process_frame
	var chip = home.get_region("ScrubBucksChip")
	var w = app.economy.wallet
	_ok(chip.tag.visible and chip.tag.text == "SB" and chip.icon.texture == null, "unapproved banknote icon -> native 'SB' tag")
	w.credit("scrub_bucks", 1234567 - w.scrub_bucks())
	home.refresh()
	_ok(chip.value_label.text == "1,234,567", "live canonical balance, grouped (%s)" % chip.value_label.text)
	app.economy.hearts.consume()
	app.economy.hearts.purchase_plus_one()
	home.refresh()
	_ok(chip.value_label.text.replace(",", "") == str(w.scrub_bucks()), "balance follows canonical spend")
	var m = V.load_manifest()
	for a in m["assets"]:
		if a["slug"] == "icon_currency_scrub_bucks":
			a["status"] = "APPROVED"
			a["approved_sha256"] = FileAccess.get_sha256("res://" + a["path"])
	home.set_art_binder(HomeArtBinder.new(m))
	_ok(chip.icon.texture != null and not chip.tag.visible, "approved banknote icon replaces the tag")
	var src := FileAccess.get_file_as_string("res://scripts/ui/home/home_screen.gd") + FileAccess.get_file_as_string("res://scripts/ui/home/home_view_model.gd")
	var code := ""
	for line in src.split("
"):
		var i := line.find("#")
		code += (line if i == -1 else line.substr(0, i)).to_lower() + "
"
	var banned := RegEx.create_from_string("\\b(coins?|stars?|event_points?|profile_xp|xp)\\b")
	var hit = banned.search(code)
	_ok(hit == null, "Home code has no coin / Star / Event Points / XP authority (%s)" % ("" if hit == null else hit.get_string()))
	sub.free()
	_complete("scrub_bucks_chip")

## SB-M42-019: profile bar = Bot Parts toward the next robot (N/250), not XP.
func _bot_parts_progress() -> void:
	print("[bot parts progress]")
	var app = AppState.new(_uniq("parts"))
	var sub := _sub(Vector2i(1080, 2160))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	await process_frame
	var e = app.economy
	var meter = home.get_region("ProfileBotParts")
	var cost: int = e.robots.unlock_cost()
	_ok(cost == 250, "owner economy robot unlock cost 250 (%d)" % cost)
	for want in [0, 184, 249, 250, 310]:
		e.wallet.credit("bot_parts", want - e.wallet.bot_parts()) if want > e.wallet.bot_parts() else e.wallet.debit("bot_parts", e.wallet.bot_parts() - want)
		home.refresh()
		var ready: bool = want >= cost
		_ok(meter.caption.text.find("BOT PARTS %d/250" % want) != -1 and meter.caption.text.find("ROBOT READY") != -1 == ready, "%d parts -> '%s'" % [want, meter.caption.text])
		_ok(is_equal_approx(meter.bar.value, minf(want, cost)) and is_equal_approx(meter.bar.max_value, cost), "%d parts -> bar %s/%s" % [want, meter.bar.value, meter.bar.max_value])
	var r: Dictionary = e.robots.unlock("robot_02")
	home.refresh()
	_ok(r.get("ok", false) and meter.caption.text.find("BOT PARTS %d/250" % e.wallet.bot_parts()) != -1, "after a canonical unlock the bar shows the carried-over parts (%s)" % meter.caption.text)
	_ok(meter.caption.text.to_lower().find("xp") == -1, "no XP wording")
	sub.free()
	_complete("bot_parts_progress")

## SB-M42-020: Gift Meter progress/next milestone from canonical GiftMeterService,
## advanced only by Win Streak SB; no event timer / Event Points.
func _gift_meter_semantics() -> void:
	print("[gift meter semantics]")
	var app = AppState.new(_uniq("gift"))
	var sub := _sub(Vector2i(1080, 2160))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	await process_frame
	var e = app.economy
	var meter = home.get_region("GiftMeterBar")
	_ok(meter.caption.text == "GIFT METER 0/1000 · NEXT GIFT AT 10", "fresh: 0/1000, next 10 (%s)" % meter.caption.text)
	e.wallet.credit("scrub_bucks", 5000)
	home.refresh()
	_ok(meter.caption.text.begins_with("GIFT METER 0/"), "non-streak SB (wallet credit) does not move the Gift Meter")
	var r: Dictionary = e.streak.process_first_clear_win(1)
	home.refresh()
	_ok(r.get("applied", false) and e.gift.cycle_progress() == 1 and meter.caption.text == "GIFT METER 1/1000 · NEXT GIFT AT 10", "Win Streak SB (+1) advances it (%s)" % meter.caption.text)
	e.gift.add_streak_sb("t_gm_2", 60)
	home.refresh()
	_ok(meter.caption.text == "GIFT METER 61/1000 · NEXT GIFT AT 250" and is_equal_approx(meter.bar.value, 61.0), "crossing 10 and 50 -> next 250 (%s)" % meter.caption.text)
	var gm_nodes := 0
	for n in home.get_region("GiftMeter").find_children("*", "Label", true, false):
		var t := String(n.text).to_lower()
		if t.find(":") != -1 or t.find("event") != -1 or t.find("point") != -1:
			gm_nodes += 1
	_ok(gm_nodes == 0, "no timer / event wording in the Gift Meter region")
	sub.free()
	_complete("gift_meter_semantics")

## SB-M42-021: Gift Bar lists canonical queued milestone rewards; CLAIM goes through the
## canonical facade (idempotent, saved); Home never mints.
func _gift_bar_claims() -> void:
	print("[gift bar claims]")
	var path := _uniq("giftbar")
	var root = await _boot_main(path)
	var app = root.get_app_state()
	var home = root.get_home()
	var e = app.economy
	e.gift.add_streak_sb("t_gb_1", 60)   # crosses 10 and 50
	home.refresh()
	var sc = home.get_region("Shortcut_gift_bar")
	_ok(not sc.disabled and sc.badge.visible and sc.badge.text == "2", "Gift shortcut live with claimable badge 2")
	sc.pressed.emit()
	var popup = home.get_popup("gift_bar")
	_ok(popup != null and popup.visible and popup.get_row_count() == 2, "Gift Bar popup lists 2 queued milestones")
	var occ: Dictionary = e.gift.claimable()[0]
	var reward: Dictionary = e.config.gift_meter_milestone(int(occ["milestone"]))
	var sb0: int = e.wallet.scrub_bucks()
	var parts0: int = e.wallet.bot_parts()
	var btn: Button = popup.get_action_button(String(occ["id"]))
	btn.pressed.emit()
	_ok(e.wallet.scrub_bucks() == sb0 + int(reward.get("scrub_bucks", 0)) and e.wallet.bot_parts() == parts0 + int(reward.get("bot_parts", 0)), "CLAIM grants exactly the configured milestone reward %s" % str(reward))
	_ok(e.gift.claimable().size() == 1 and popup.get_row_count() == 1 and sc.badge.text == "1", "claimed row gone, badge 1")
	btn.pressed.emit()
	var again: Dictionary = app.actions.claim_gift(String(occ["id"]))
	_ok(not again.get("ok", true) and e.wallet.scrub_bucks() == sb0 + int(reward.get("scrub_bucks", 0)), "second claim of the same occurrence refused, no double reward")
	_ok(AppState.new(path).economy.gift.claimable().size() == 1, "claim persisted canonically")
	_ok(root.handle_back() == "close_popup" and not popup.visible and root.get_navigation().current() == NavigationController.Route.HOME, "back closes the popup first")
	_shutdown(root)
	var src := FileAccess.get_file_as_string("res://scripts/ui/home/home_screen.gd")
	_ok(src.find("wallet.credit") == -1 and src.find("reward.grant") == -1, "Home code never credits/grants directly")
	_complete("gift_bar_claims")

## SB-M42-022: Cards Exchange = live duplicate count/value, presentation only.
func _cards_exchange_presentation() -> void:
	print("[cards exchange presentation]")
	var app = AppState.new(_uniq("cards"))
	var sub := _sub(Vector2i(1080, 2160))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	await process_frame
	var e = app.economy
	var sc = home.get_region("Shortcut_cards_exchange")
	_ok(not sc.disabled and not sc.badge.visible and sc.text == "CARDS EXCHANGE", "CARDS EXCHANGE shortcut live, no badge without duplicates")
	var ids: Array = e.collection.all_card_ids()
	e.collection.add_copies(ids[0], 3)
	e.collection.add_copies(ids[5], 2)
	home.refresh()
	var want := 0
	var want_sb := 0
	for cid in ids:
		want += e.exchange.exchangeable(cid)
		want_sb += e.exchange.exchangeable(cid) * e.exchange.card_value(cid)
	_ok(want > 0 and sc.badge.text == str(want), "badge = live exchangeable duplicate count %d" % want)
	var snap: Dictionary = e.snapshot()
	sc.pressed.emit()
	var popup = home.get_popup("cards_exchange")
	_ok(popup.visible and popup.get_row_count() == 2 and popup.get_note().find("%d SB" % want_sb) != -1, "popup lists duplicate cards and their canonical SB value (%s)" % popup.get_note())
	_ok(popup.find_children("Action_*", "", true, false).is_empty(), "no exchange execution button (presentation only)")
	_ok(e.snapshot() == snap, "opening Cards Exchange mutates nothing")
	_ok(popup.get_title() == "CARDS EXCHANGE" and popup.get_note().to_lower().find("star") == -1, "no Star balance/semantics")
	sub.free()
	_complete("cards_exchange_presentation")

# ---------------------------------------------------------------- helpers ----

func _boot_main(path: String):
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	return root

func _shutdown(root) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	MainScript.boot_save_path_override = ""

func _sub(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	return sub

func _uniq(tag: String) -> String:
	var p := "user://m42home_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	for c in missing:
		print("  FAIL: sub-test did not complete: %s" % c)
	_fail += missing.size()
	print("M42 home cases completed: %d/%d" % [EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size()])
	print("M42 home evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
