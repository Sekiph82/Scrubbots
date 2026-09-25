extends SceneTree
## M42 Home OWNER REVISION V03 — focused evidence
## (coordination/OWNER_M42_HOME_VISUAL_REVISION_V03.md). Expected/completed case ledger
## (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_home_v03.gd

const AppState = preload("res://scripts/app/app_state.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const HomePresentationMap = preload("res://scripts/ui/home/home_presentation_map.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")

const MATRIX := [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1080, 2400), Vector2i(1440, 3200), Vector2i(1080, 1920), Vector2i(1536, 2048)]
## V02 reference sizes at 1080x2160 (from the V02 audited build): profile card ~622 px
## wide, portrait 118 px wide, PLAY 700x196 @ 104 px font, reward track panel ~206 px.
const V02_PROFILE_W := 600.0
const V02_PORTRAIT_W := 118.0
const V02_PLAY := Vector2(700, 196)
const V02_TRACK_H := 206.0

var EXPECTED_CASES := [
	"profile_card", "no_top_settings", "compact_captions", "city_background", "nav_flush",
	"one_platform", "idle_overlays_disabled", "side_cards_and_row", "play_cta", "reward_track",
	"popup_modals", "settings_modal_and_back", "hidden_controls_no_input", "viewport_matrix",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _paths: Dictionary = {}   ## HOME id -> res:// path

func _initialize() -> void:
	await process_frame
	for a in V.load_manifest()["assets"]:
		if a.has("path"):
			_paths[a["id"]] = "res://" + String(a["path"])
	var r = await _home(Vector2i(1080, 2160), "main")
	var home = r[1]
	_profile(home)
	_no_top_settings(home)
	_captions(home)
	_city(home)
	_nav_flush(home)
	_platform(home)
	await _idle(home)
	_row(home)
	_play(home)
	_track(home)
	await _popups(home, r[0])
	r[0].free()
	await _settings_and_back()
	await _no_input()
	await _matrix()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	_done()

func _home(size: Vector2i, tag: String, insets := [0, 0, 0, 0]) -> Array:
	var p := "user://m42_v03_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	var app = AppState.new(p)
	app.economy.gift.add_streak_sb("v03_gift", 12)
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	get_root().add_child(sub)
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	home.get_region("SafeAreaRoot").set_synthetic_insets(insets[0], insets[1], insets[2], insets[3])
	for _i in range(5):
		await process_frame
	return [sub, home]

func _textures_in(root: Node) -> Array:
	var out: Array = []
	for n in root.find_children("*", "", true, false):
		var t = null
		if n is TextureRect:
			t = n.texture
		elif n is Button:
			t = n.icon
		if t != null and (n as CanvasItem).is_visible_in_tree():
			out.append(t.resource_path)
	return out

func _profile(home) -> void:
	print("[profile card]")
	var card: Control = home.get_region("ProfileCard")
	var frame: Control = home.get_region("ProfileAvatarFrame")
	var portrait: Control = home.get_region("ProfilePortrait")
	_ok(card.size.x <= V02_PROFILE_W - 40.0 and card.size.x >= 440.0, "card narrower than V02 (%.0f < %.0f)" % [card.size.x, V02_PROFILE_W])
	_ok(card.size.y >= 150.0, "card height kept for the portrait (%.0f)" % card.size.y)
	_ok(portrait.size.x >= V02_PORTRAIT_W * 1.4, "portrait materially larger than V02 (%.0f vs %.0f)" % [portrait.size.x, V02_PORTRAIT_W])
	_ok(portrait.get_parent() == frame.get_parent() and portrait.get_index() > frame.get_index(), "portrait draws in front of the frame")
	var pr: Rect2 = portrait.get_global_rect()
	var fr: Rect2 = frame.get_global_rect()
	_ok(pr.position.y < fr.position.y - 40.0 and pr.position.y < card.get_global_rect().position.y, "portrait pops out above the frame and the card top")
	var clipped := false
	var n: Node = portrait.get_parent()
	while n != null and n != home:
		if n is Control and (n as Control).clip_contents:
			clipped = true
		n = n.get_parent()
	_ok(not clipped and pr.position.y >= 0.0, "no ancestor clips the portrait; it stays on screen")
	_ok(home.get_region("ProfileName").text == UiText.t("HOME_PLAYER_NAME_DEFAULT") and home.get_region("ProfileLevel").text == "1", "name live, level its own live badge value")
	_complete("profile_card")

func _no_top_settings(home) -> void:
	print("[no top settings]")
	_ok(home.get_region("MenuButton") == null, "top MenuButton removed")
	var entries: Array = []
	for b in home.find_children("*", "BaseButton", true, false):
		var nm := String(b.name).to_lower()
		if nm.find("settings") != -1 or nm.find("menu") != -1:
			entries.append(b)
	_ok(entries.size() == 1 and entries[0] == home.get_region("Nav_settings") and home.get_region("BottomNav").is_ancestor_of(entries[0]), "the only Settings entry is the bottom-nav SETTINGS tab")
	_complete("no_top_settings")

func _captions(home) -> void:
	print("[compact captions]")
	var parts: String = home.get_region("ProfileBotParts").caption.text
	var gift: String = home.get_region("GiftMeterBar").caption.text
	var ratio := RegEx.create_from_string("^[0-9,]+/[0-9,]+$")
	_ok(parts == "0/250" and ratio.search(parts) != null, "Bot Parts caption is only the live ratio (%s)" % parts)
	_ok(gift == "12/1,000" and ratio.search(gift) != null, "Gift Meter caption is only the live ratio (%s)" % gift)
	_ok(home.get_region("GiftEmblem").texture != null and home.get_region("GiftCrate").texture != null and home.get_region("GiftEmblem").is_visible_in_tree(), "HOME-051 / HOME-054 still presented")
	_complete("compact_captions")

func _city(home) -> void:
	print("[city background]")
	var far: Rect2 = home.get_region("Layer_background.city_far").get_global_rect()
	var mid: Rect2 = home.get_region("Layer_background.city_mid").get_global_rect()
	var arch: Rect2 = home.get_region("Art_arch").get_global_rect()
	var decor: Rect2 = home.get_region("Art_arch_decor").get_global_rect()
	var street: Rect2 = home.get_region("Layer_background.street_foreground").get_global_rect()
	var nav_top: float = home.get_region("BottomNav").get_global_rect().position.y
	var row_top: float = home.get_region("ActionRow").get_global_rect().position.y
	_ok(far.size.x > 0 and far.size.y > 300 and mid.size.x > 0 and mid.size.y > 300, "HOME-002/003 have large visible rects (%s / %s)" % [str(far.size), str(mid.size)])
	_ok(mid.position.x < arch.position.x - 100 and mid.end.x > arch.end.x + 100, "mid-city buildings extend left and right of the portal")
	_ok(far.position.y < decor.position.y and mid.position.y < arch.position.y + arch.size.y * 0.5, "city rises behind/above the portal crown")
	var aspect_ok: bool = absf(far.size.x / far.size.y - 2170.0 / 725.0) < 0.02 and absf(mid.size.x / mid.size.y - 2024.0 / 777.0) < 0.02 and absf(street.size.x / street.size.y - 1211.0 / 1299.0) < 0.02
	_ok(aspect_ok, "city/street layers keep their native proportions (no stretch)")
	var pave_top: float = street.end.y - street.size.y * 0.27
	_ok(street.end.y >= nav_top and street.end.y <= nav_top + 60.0, "street foreground bottom tied to the nav top (%.0f vs %.0f)" % [street.end.y, nav_top])
	_ok(pave_top <= row_top, "pavement rises above the SHOP | PLAY | CARDS row (%.0f <= %.0f)" % [pave_top, row_top])
	_complete("city_background")

func _nav_flush(home) -> void:
	print("[nav flush]")
	var vp: Vector2 = home.get_viewport_rect().size
	var nav: Control = home.get_region("BottomNav")
	_ok(absf(nav.get_global_rect().end.y - vp.y) < 1.0, "dock flush to the screen bottom (%.0f / %.0f)" % [nav.get_global_rect().end.y, vp.y])
	var sb: StyleBox = nav.get_theme_stylebox("panel")
	_ok(sb is StyleBoxFlat and (sb as StyleBoxFlat).expand_margin_bottom >= 300.0, "dock paints down through any bottom inset (no world strip below)")
	_ok(home.get_region("Nav_home").button_pressed and home.get_region("Nav_leaderboard").text == UiText.t("HOME_NAV_LEADERBOARD") and UiText.t("HOME_NAV_LEADERBOARD") == "RANKS", "HOME selected, RANKS wording kept")
	_complete("nav_flush")

func _platform(home) -> void:
	print("[one platform]")
	_ok(home.get_region("Art_platform_top") == null and not _textures_in(home).has(_paths["HOME-011"]), "HOME-011 not in the runtime composition")
	var plat: Rect2 = home.get_region("Art_platform_main").get_global_rect()
	var feet: float = home.get_region("Art_scrubby").get_global_rect().end.y
	_ok(absf(feet - (plat.position.y + plat.size.y * 0.40)) < 1.0 and feet < plat.position.y + plat.size.y * 0.5, "Scrubby's feet on HOME-010's top surface")
	_complete("one_platform")

func _idle(home) -> void:
	print("[idle overlays disabled]")
	var bad_paths := [_paths["HOME-031"], _paths["HOME-032"]]
	var seen := false
	for i in range(240):
		if i % 20 == 0:
			home._tick.timeout.emit()
		await process_frame
		for p in _textures_in(home):
			if bad_paths.has(p):
				seen = true
	_ok(not seen, "240 frames + 12 ticks of idle: HOME-031/032 never presented")
	_ok(home.get_region("ScrubbyBlink") == null and home.get_region("ScrubbyBrushArm") == null and not home.has_method("set_idle_state"), "no idle-overlay nodes or state switch exist")
	_complete("idle_overlays_disabled")

func _names(c: Node) -> Array:
	var out: Array = []
	for n in c.get_children():
		out.append(String(n.name))
	return out

func _row(home) -> void:
	print("[side cards and row]")
	_ok(_names(home.get_region("LeftShortcutColumn")) == ["Shortcut_win_streak", "Shortcut_gift_bar", "Shortcut_collection"], "left column = WIN STREAK / GIFTS / COLLECTION")
	_ok(_names(home.get_region("RightShortcutColumn")) == ["Shortcut_no_ads", "Shortcut_daily", "Shortcut_tasks"], "right column = NO ADS / DAILY / TASKS")
	_ok(_names(home.get_region("ActionRow")) == ["Shortcut_shop", "PlayButton", "Shortcut_cards_exchange"], "lower row = SHOP | PLAY | CARDS EXCHANGE")
	var shop: Rect2 = home.get_region("Shortcut_shop").get_global_rect()
	var play: Rect2 = home.get_region("PlayButton").get_global_rect()
	var cards: Rect2 = home.get_region("Shortcut_cards_exchange").get_global_rect()
	_ok(shop.end.x <= play.position.x and play.end.x <= cards.position.x and not shop.intersects(play) and not cards.intersects(play), "row order left→right without overlap")
	_ok(home.get_region("Shortcut_shop").disabled and not home.get_region("Shortcut_cards_exchange").disabled, "Shop stays future-disabled; Cards Exchange stays live")
	_ok(home.get_region("Shortcut_shop").text == "SHOP" and home.get_region("Shortcut_cards_exchange").text == "CARDS EXCHANGE" and shop.size.y >= 88 and cards.size.y >= 88, "full labels, >= 88 px")
	_complete("side_cards_and_row")

func _play(home) -> void:
	print("[play CTA]")
	var play: Button = home.get_region("PlayButton")
	_ok(play.size.x < V02_PLAY.x * 0.8 and play.size.y < V02_PLAY.y * 0.85, "PLAY smaller than V02 (%s)" % str(play.size))
	_ok(play.get_theme_font_size("font_size") < 104 and play.get_theme_font_size("font_size") >= 64, "PLAY font reduced but primary (%d)" % play.get_theme_font_size("font_size"))
	var sub: Label = home.get_region("PlaySubtitle")
	_ok(sub.text == UiText.t("HOME_START_LEVEL", [1]) and sub.get_theme_font_size("font_size") < play.get_theme_font_size("font_size") / 2, "live compact secondary subtitle")
	var tri: Control = home.get_region("PlayTriangle")
	_ok(tri != null and not (tri is TextureRect) and tri.get_parent() == play and play.get_global_rect().encloses(tri.get_global_rect()) and tri.mouse_filter == Control.MOUSE_FILTER_IGNORE, "native (non-texture) white play triangle inside the CTA")
	_ok(home.get_region("PlayIcon") == null and not _textures_in(home).has(_paths["HOME-078"]), "HOME-078 not presented")
	var row: Dictionary = {}
	for rr in home.get_presentation_accounting():
		row[rr["id"]] = rr
	_ok(row["HOME-078"]["mode"] == "OWNER_RETIRED" and row["HOME-087"]["mode"] == "OWNER_RETIRED" and row["HOME-011"]["mode"] == "OWNER_RETIRED" and row["HOME-031"]["mode"] == "OWNER_DISABLED" and row["HOME-032"]["mode"] == "OWNER_DISABLED", "accounting marks 011/078/087 OWNER_RETIRED and 031/032 OWNER_DISABLED")
	_complete("play_cta")

func _track(home) -> void:
	print("[reward track]")
	var track: Control = home.get_region("WinStreakRewardTrack")
	var vals: Array = []
	for i in range(1, 6):
		vals.append(home.get_region("TrackStep%d" % i).text)
	_ok(vals == ["1", "5", "10", "25", "100"], "values exactly 1/5/10/25/100 (%s)" % str(vals))
	var bad: Array = []
	for l in track.find_children("*", "Label", true, false):
		var t := String(l.text)
		if t.find("+") != -1 or t.to_upper().find("WIN") != -1 or t.find("SB") != -1:
			bad.append(t)
	_ok(bad.is_empty(), "no '+', no per-step WIN copy, no SB tag %s" % str(bad))
	var paths: Array = _textures_in(track)
	_ok(not paths.has(_paths["HOME-042"]) and not paths.has(_paths["HOME-087"]), "no per-step Scrub Bucks icons (HOME-087 retired)")
	var gifts := 0
	for i in range(1, 6):
		if home.get_region("TrackGift%d" % i).texture != null:
			gifts += 1
	_ok(gifts == 5, "five gift objects remain")
	_ok(track.size.y < V02_TRACK_H * 0.75, "track materially thinner than V02 (%.0f)" % track.size.y)
	_ok(home.get_region("TrackBadge").size.y <= track.size.y, "badge scaled to the thin track")
	_complete("reward_track")

const HIDDEN := ["LeftShortcutColumn", "RightShortcutColumn", "ActionRow", "WinStreakRewardTrack", "BottomNav"]

func _action_state(home) -> Dictionary:
	var d := {}
	for r in HIDDEN:
		d[r] = home.get_region(r).is_visible_in_tree()
	return d

func _all_hidden(home) -> bool:
	for r in HIDDEN:
		if home.get_region(r).is_visible_in_tree():
			return false
	return true

func _popups(home, sub: SubViewport) -> void:
	print("[popup modals]")
	var before := _action_state(home)
	var sizes_before: Dictionary = {}
	for n in ["Shortcut_gift_bar", "PlayButton", "BottomNav"]:
		sizes_before[n] = home.get_region(n).get_global_rect()
	_ok(not before.values().has(false) and not home.is_modal_active(), "baseline: all action regions visible, no modal")
	for id in ["gift_bar", "daily", "cards_exchange"]:
		var p = home.open_popup(id)
		await process_frame
		_ok(p.is_visible_in_tree() and home.is_modal_active() and _all_hidden(home), "%s open: popup visible, Home action controls hidden" % id)
		var leak: Array = []
		for b in home.find_children("*", "BaseButton", true, false):
			if (b as Control).is_visible_in_tree() and not p.is_ancestor_of(b):
				leak.append(b.name)
		_ok(leak.is_empty(), "%s open: only the popup's own buttons are visible %s" % [id, str(leak)])
		_ok(p.get_index() == home.get_child_count() - 1 and p.z_index >= 1, "%s renders above the Home background" % id)
		p.close_popup()
		for _i in range(3):
			await process_frame
		_ok(_action_state(home) == before and not home.is_modal_active(), "%s closed: exact Home controls restored" % id)
	for n in sizes_before:
		_ok(home.get_region(n).get_global_rect().is_equal_approx(sizes_before[n]), "%s geometry restored after modals" % n)
	# One modal at a time (no double-modal leakage).
	var g = home.open_popup("gift_bar")
	var d = home.open_popup("daily")
	await process_frame
	_ok(d.visible and not g.visible and _all_hidden(home), "opening a second popup closes the first")
	_ok(home.close_top_popup() and not home.is_modal_active() and not _action_state(home).values().has(false), "back closes the top modal and restores Home")
	_complete("popup_modals")

func _settings_and_back() -> void:
	print("[settings modal and back]")
	var path := "user://m42_v03_root_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame
	var home = root.get_home()
	var panel = root.get_settings_panel()
	var before := _action_state(home)
	home.get_region("Nav_settings").pressed.emit()
	await process_frame
	_ok(panel.visible and home.is_modal_active() and _all_hidden(home), "Settings (bottom nav) open: Home action controls hidden")
	_ok(panel.get_index() > home.get_index(), "Settings panel renders above Home")
	_ok(root.handle_back() != "" and not panel.visible and not home.is_modal_active(), "back closes Settings first")
	await process_frame
	_ok(_action_state(home) == before, "Settings closed: exact Home controls restored")
	home.open_popup("daily")
	await process_frame
	_ok(root.handle_back() == "close_popup" and not home.is_modal_active() and _action_state(home) == before, "back closes a Home popup first and restores Home")
	root.free()
	MainScript.boot_save_path_override = ""
	_complete("settings_modal_and_back")

func _click(sub: SubViewport, at: Vector2) -> void:
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		sub.push_input(ev)

func _no_input() -> void:
	print("[hidden controls no input]")
	var r = await _home(Vector2i(1080, 2160), "input")
	var sub: SubViewport = r[0]
	var home = r[1]
	var got: Array = []
	home.shortcut_requested.connect(func(id): got.append("sc:" + id))
	home.settings_requested.connect(func(): got.append("settings"))
	home.nav_requested.connect(func(id): got.append("nav:" + id))
	home.play_requested.connect(func(): got.append("play"))
	var targets := {
		"gifts": home.get_region("Shortcut_gift_bar").get_global_rect().get_center(),
		"cards": home.get_region("Shortcut_cards_exchange").get_global_rect().get_center(),
		"settings": home.get_region("Nav_settings").get_global_rect().get_center(),
	}
	_click(sub, targets["gifts"])
	await process_frame
	_ok(got.has("sc:gift_bar"), "sensitivity: a real click on GIFTS reaches the card without a modal (%s)" % str(got))
	home.close_top_popup()   # the click opened the Gifts popup; start clean
	await process_frame
	home.open_popup("daily")
	await process_frame
	got.clear()
	for k in targets:
		_click(sub, targets[k])
		await process_frame
	_ok(got.is_empty(), "with Daily open, clicks on hidden GIFTS / CARDS / SETTINGS reach nothing (%s)" % str(got))
	var focusable: Array = []
	for b in home.find_children("*", "BaseButton", true, false):
		if not home.get_popup("daily").is_ancestor_of(b) and (b as Control).is_visible_in_tree():
			focusable.append(b.name)
	_ok(focusable.is_empty(), "no Home button is visible/focusable behind the modal %s" % str(focusable))
	home.close_top_popup()
	sub.free()
	_complete("hidden_controls_no_input")

func _matrix() -> void:
	print("[viewport matrix]")
	for size in MATRIX:
		for insets in [[0, 0, 0, 0], [0, 132, 0, 96]]:
			var r = await _home(size, "mx", insets)
			var home = r[1]
			var safe := Rect2(Vector2(insets[0], insets[1]), Vector2(size) - Vector2(insets[0] + insets[2], insets[1] + insets[3]))
			var bad: Array = []
			for b in home.find_children("*", "BaseButton", true, false):
				var rr: Rect2 = (b as Control).get_global_rect()
				if rr.size.x < 87.5 or rr.size.y < 87.5 or not safe.grow(0.5).encloses(rr):
					bad.append(b.name)
			var shop: Rect2 = home.get_region("Shortcut_shop").get_global_rect()
			var play: Rect2 = home.get_region("PlayButton").get_global_rect()
			var cards: Rect2 = home.get_region("Shortcut_cards_exchange").get_global_rect()
			if shop.intersects(play) or cards.intersects(play):
				bad.append("row_overlap")
			var feet: float = home.get_region("Art_scrubby").get_global_rect().end.y
			var plat: Rect2 = home.get_region("Art_platform_main").get_global_rect()
			if feet < plat.position.y or feet > plat.get_center().y:
				bad.append("feet_off_platform")
			var nav: Rect2 = home.get_region("BottomNav").get_global_rect()
			if absf(nav.end.y - safe.end.y) > 1.0:
				bad.append("nav_not_at_safe_bottom")
			_ok(bad.is_empty(), "%s insets=%s: buttons >= 88 inside safe area, row clear, feet on platform, dock at bottom %s" % [str(size), str(insets), str(bad)])
			r[0].free()
			await process_frame
	_complete("viewport_matrix")

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: ", msg)
	else:
		_fail += 1
		print("  FAIL: ", msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: cases not completed: ", missing)
	print("m42_home_v03: %d/%d cases, %d failures" % [_completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
