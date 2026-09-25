extends Control
## HomeScreen — res://scenes/ui/home/home_screen.tscn (preload this script; AL-001).
##
## M42 production Home shell (SB-M42-002). Responsive native Godot Controls under the
## MASTER_UI_SYSTEM §6 tree — never a flattened interactive screenshot:
##
##   HomeScreen
##   ├── Background                (BG01; approved art layers bind here, SB-M42-017)
##   └── SafeAreaRoot
##       └── MarginContainer/Content
##           └── HomeLayout (VBox)
##               ├── TopCurrencyHUD
##               ├── GiftMeter
##               ├── MainWorldArea (Left / CenterScrubbyArea / Right)
##               ├── PlayButton
##               ├── WinStreakRewardTrack
##               └── BottomNav
##
## The screen owns NO durable truth. It reads the canonical AppState (bound by the app
## root) and only emits intents (play/settings/nav/shortcut); the app root and the
## canonical services decide what happens. A blocked (future-schema) save shows an
## explicit read-only state and disables PLAY.

signal play_requested
signal settings_requested
signal nav_requested(id: String)
signal shortcut_requested(id: String)

const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const SafeAreaRootScene = preload("res://scenes/components/ui/common/safe_area_root.tscn")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const ResponsiveLayout = preload("res://scripts/ui/responsive_layout.gd")
const UiValueChip = preload("res://scripts/ui/components/ui_value_chip.gd")
const UiProgressMeter = preload("res://scripts/ui/components/ui_progress_meter.gd")
const UiShortcutButton = preload("res://scripts/ui/components/ui_shortcut_button.gd")
const HomeViewModel = preload("res://scripts/ui/home/home_view_model.gd")
const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")
const HomePopup = preload("res://scripts/ui/home/home_popup.gd")

## Shortcuts with a V1 Home destination (popup). Others belong to later milestones and
## are shown disabled.
const LIVE_SHORTCUTS := ["gift_bar"]
## Friendly names for canonical reward-bundle keys (presentation only).
const REWARD_NAMES := {
	"scrub_bucks": "SB", "bot_parts": "Bot Parts", "standard_card_packs": "Card Pack",
	"premium_card_packs": "Premium Pack", "random_booster_charges": "Random Booster",
	"selected_booster_charges": "Booster of choice", "guaranteed_new_cards": "New Card",
}

## SB-M42-017: manifest slug -> Home node that may display it once owner-approved.
const LAYER_ART := {
	"home_bg_sky": "Layer_background.sky",
	"home_bg_city_far": "Layer_background.city_far",
	"home_bg_city_mid": "Layer_background.city_mid",
	"home_bg_street_foreground": "Layer_background.street_foreground",
	"home_platform_main": "Layer_central_world_and_environment",
	"scrubby_home_pose": "Layer_characters",
}
const ICON_ART := {
	"icon_currency_scrub_bucks": "ScrubBucksChip",
	"icon_currency_heart": "HeartsChip",
	"icon_shortcut_win_streak": "Shortcut_win_streak",
	"icon_shortcut_gift_bar": "Shortcut_gift_bar",
	"icon_shortcut_collection": "Shortcut_collection",
	"icon_shortcut_shop": "Shortcut_shop",
	"icon_shortcut_no_ads": "Shortcut_no_ads",
	"icon_shortcut_daily": "Shortcut_daily",
	"icon_shortcut_tasks": "Shortcut_tasks",
	"icon_shortcut_cards_exchange": "Shortcut_cards_exchange",
}

## Shortcut columns (SB-M42-010/012). Destinations belonging to later milestones are
## rendered disabled by refresh(), never faked.
const LEFT_SHORTCUTS := [["win_streak", "WIN STREAK"], ["gift_bar", "GIFTS"], ["collection", "COLLECTION"], ["shop", "SHOP"]]
const RIGHT_SHORTCUTS := [["daily", "DAILY"], ["tasks", "TASKS"], ["cards_exchange", "CARDS EXCHANGE"], ["no_ads", "NO ADS"]]
## Win Streak track positions 1..5+ (values are rendered live from WinStreakService).
const TRACK_POSITIONS := 5

## SB-M42-011: layered art regions recreating the owner Home art direction. Names follow
## assets/ui/HOME_ASSET_MANIFEST.json layer_order. Screen-wide layers sit behind the UI;
## world/character layers sit inside CenterScrubbyArea. Every layer is a decorative
## TextureRect that never receives input. The owner reference image itself is never
## loaded or shipped — layers stay empty until owner-approved assets bind (SB-M42-016/017).
const SCREEN_LAYERS := ["background.sky", "background.city_far", "background.city_mid", "background.street_foreground"]
const WORLD_LAYERS := ["central_world_and_environment", "characters"]

const BG01 := Color(0.125, 0.145, 0.2, 1.0)   ## Midnight Slate #202533.

var _app = null
var _built := false
var _nodes: Dictionary = {}   ## region name -> Control
## Last frontier resolution shown on the CTA (SB-M42-003). Read-only presentation copy.
var _launch: Dictionary = {}
## Last live projection rendered (SB-M42-015). A detached copy for tests/diagnostics —
## never read back as truth; every refresh re-reads the canonical services.
var _vm: Dictionary = {}
var _art = null
var _popups: Dictionary = {}   ## id -> HomePopup (presentation only)
var _tick: Timer

func _ready() -> void:
	_build()
	# SB-M42-015: live values (Heart regen timer) re-read once per second while visible.
	_tick = Timer.new()
	_tick.wait_time = 1.0
	_tick.timeout.connect(func():
		if is_visible_in_tree():
			refresh())
	add_child(_tick)
	_tick.start()
	resized.connect(_apply_layout_mode)
	_nodes["MainWorldArea"].resized.connect(_apply_layout_mode)
	_apply_layout_mode()
	if _art == null:
		set_art_binder(HomeArtBinder.new())
	refresh()

## Bind the canonical AppState (app root). Re-renders.
func bind(app_state) -> void:
	_app = app_state
	if _built:
		refresh()

## SB-M42-017: bind ONLY owner-approved art (HomeArtBinder gate). Unapproved slugs keep
## the native placeholder (null texture). Injectable for tests.
func set_art_binder(binder) -> void:
	_art = binder
	if not _built:
		return
	for slug in LAYER_ART:
		(_nodes[LAYER_ART[slug]] as TextureRect).texture = _art.texture(slug)
	for slug in ICON_ART:
		var n = _nodes[ICON_ART[slug]]
		var tex: Texture2D = _art.texture(slug)
		if n is Button:
			(n as Button).icon = tex
		else:
			n.set_icon(tex)

func get_art_binder():
	return _art

func get_app_state():
	return _app

func get_region(region: String) -> Control:
	return _nodes.get(region)

# ------------------------------------------------------------------ build ----

func _build() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = BG01
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_nodes["Background"] = bg
	for layer in SCREEN_LAYERS:
		bg.add_child(_art_layer(layer, TextureRect.STRETCH_KEEP_ASPECT_COVERED))

	var safe = SafeAreaRootScene.instantiate()
	safe.name = "SafeAreaRoot"
	add_child(safe)
	_nodes["SafeAreaRoot"] = safe
	var content: Control = safe.get_node("MarginContainer/Content")

	var layout := VBoxContainer.new()
	layout.name = "HomeLayout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	content.add_child(layout)
	_nodes["HomeLayout"] = layout

	for region in ["TopCurrencyHUD", "GiftMeter"]:
		var c := HBoxContainer.new()
		c.name = region
		c.add_theme_constant_override("separation", UiTokens.SPACE_SM)
		c.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
		layout.add_child(c)
		_nodes[region] = c

	var world := HBoxContainer.new()
	world.name = "MainWorldArea"
	world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	layout.add_child(world)
	_nodes["MainWorldArea"] = world
	for region in ["LeftShortcutColumn", "CenterScrubbyArea", "RightShortcutColumn"]:
		var c: Control
		if region == "CenterScrubbyArea":
			c = Control.new()
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", UiTokens.SPACE_SM)
			c = v
		c.name = region
		world.add_child(c)
		_nodes[region] = c

	var play := Button.new()
	play.name = "PlayButton"
	play.text = "PLAY"
	play.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN + UiTokens.SPACE_XL)
	play.add_theme_font_size_override("font_size", UiTokens.FONT_HERO)
	play.pressed.connect(func():
		if not play.disabled:
			play_requested.emit())
	layout.add_child(play)
	_nodes["PlayButton"] = play

	var status := Label.new()
	status.name = "StatusLabel"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	layout.add_child(status)
	_nodes["StatusLabel"] = status

	var track := HBoxContainer.new()
	track.name = "WinStreakRewardTrack"
	track.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	track.add_theme_constant_override("separation", UiTokens.SPACE_SM)
	layout.add_child(track)
	_nodes["WinStreakRewardTrack"] = track

	for layer in WORLD_LAYERS:
		_nodes["CenterScrubbyArea"].add_child(_art_layer(layer, TextureRect.STRETCH_KEEP_ASPECT_CENTERED))
	_build_hud(_nodes["TopCurrencyHUD"])
	_build_gift_meter(_nodes["GiftMeter"])
	_build_shortcuts(_nodes["LeftShortcutColumn"], LEFT_SHORTCUTS)
	_build_shortcuts(_nodes["RightShortcutColumn"], RIGHT_SHORTCUTS)
	_build_track(track)

	var nav := HBoxContainer.new()
	nav.name = "BottomNav"
	nav.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	nav.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	layout.add_child(nav)
	_nodes["BottomNav"] = nav
	_build_bottom_nav(nav)

func _art_layer(layer: String, stretch: int) -> TextureRect:
	var t := TextureRect.new()
	t.name = "Layer_" + layer.replace(".", "_")
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = stretch
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nodes["Layer_" + layer] = t
	return t

## Ordered art layer nodes (manifest layer_order minus the "ui" layer).
func get_art_layers() -> Array:
	var out: Array = []
	for layer in SCREEN_LAYERS + WORLD_LAYERS:
		out.append(_nodes["Layer_" + layer])
	return out

## SB-M42-010: reusable live components; text is set only by refresh().
func _build_hud(hud: HBoxContainer) -> void:
	var profile := UiProgressMeter.new("ProfileBotParts")
	profile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(profile)
	_nodes["ProfileBotParts"] = profile
	for id in ["ScrubBucksChip", "HeartsChip"]:
		var chip := UiValueChip.new(id)
		hud.add_child(chip)
		_nodes[id] = chip

func _build_gift_meter(gm: HBoxContainer) -> void:
	var meter := UiProgressMeter.new("GiftMeterBar")
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gm.add_child(meter)
	_nodes["GiftMeterBar"] = meter

func _build_shortcuts(column: VBoxContainer, specs: Array) -> void:
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	for spec in specs:
		var b := UiShortcutButton.new(spec[0], spec[1])
		var id: String = spec[0]
		b.pressed.connect(func():
			shortcut_requested.emit(id)
			open_popup(id))
		column.add_child(b)
		_nodes["Shortcut_" + id] = b

func _build_track(track: HBoxContainer) -> void:
	for i in range(TRACK_POSITIONS):
		var node := UiValueChip.new("TrackStep%d" % (i + 1))
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.add_child(node)
		_nodes["TrackStep%d" % (i + 1)] = node

## Responsive spacing by layout mode (COMPACT/NORMAL/TALL). Presentation only.
func _apply_layout_mode() -> void:
	if not _built:
		return
	var mode := ResponsiveLayout.get_layout_mode(get_viewport_rect().size)
	var gap: int = UiTokens.SPACE_XS if mode == ResponsiveLayout.LayoutMode.COMPACT else (UiTokens.SPACE_LG if mode == ResponsiveLayout.LayoutMode.TALL else UiTokens.SPACE_SM)
	(_nodes["HomeLayout"] as VBoxContainer).add_theme_constant_override("separation", gap)
	_apply_shortcut_columns(mode)

## SB-M42-012: shortcut columns scale with the safe width so the central world area
## keeps >= CENTER_MIN_FRACTION of the width; buttons never drop below TOUCH_MIN.
## COMPACT (short/wide) packs the columns tighter vertically; TALL spreads them.
const CENTER_MIN_FRACTION := 0.4
func _apply_shortcut_columns(mode: int) -> void:
	var world: Control = _nodes["MainWorldArea"]
	var width: float = world.size.x if world.size.x > 0.0 else get_viewport_rect().size.x
	var col_w: float = clampf(width * (1.0 - CENTER_MIN_FRACTION) * 0.5 - UiTokens.SPACE_SM, UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN * 3)
	var vgap: int = UiTokens.SPACE_XS if mode == ResponsiveLayout.LayoutMode.COMPACT else (UiTokens.SPACE_LG if mode == ResponsiveLayout.LayoutMode.TALL else UiTokens.SPACE_SM)
	for side in ["LeftShortcutColumn", "RightShortcutColumn"]:
		var col: VBoxContainer = _nodes[side]
		col.add_theme_constant_override("separation", vgap)
		for b in col.get_children():
			(b as Control).custom_minimum_size = Vector2(col_w, UiTokens.TOUCH_MIN)

func get_layout_mode() -> int:
	return ResponsiveLayout.get_layout_mode(get_viewport_rect().size)

## Bottom navigation. Only HOME and SETTINGS have V1 destinations; the other tabs are
## shown disabled (their screens belong to later milestones) — never faked.
func _build_bottom_nav(nav: HBoxContainer) -> void:
	for spec in [["events", "EVENTS"], ["robots", "ROBOTS"], ["home", "HOME"], ["leaderboard", "RANKS"], ["settings", "SETTINGS"]]:
		var b := Button.new()
		b.name = "SettingsButton" if spec[0] == "settings" else "Nav_" + spec[0]
		b.text = spec[1]
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
		b.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
		b.clip_text = true
		b.focus_mode = Control.FOCUS_NONE
		var id: String = spec[0]
		match id:
			"settings":
				b.pressed.connect(func(): settings_requested.emit())
			"home":
				b.toggle_mode = true
				b.button_pressed = true
				b.disabled = true   # already here
			_:
				b.disabled = true
				b.tooltip_text = "Coming later"
		b.pressed.connect(func(): nav_requested.emit(id))
		nav.add_child(b)
		_nodes["Nav_" + id] = b

# ---------------------------------------------------------------- refresh ----

## Re-read canonical state into the live controls. Never mutates state.
func refresh() -> void:
	if not _built:
		return
	var play: Button = _nodes["PlayButton"]
	var status: Label = _nodes["StatusLabel"]
	if _app == null:
		play.disabled = true
		status.text = "Loading..."
	elif _app.is_blocked:
		play.disabled = true
		status.text = "Save data is from a newer version. Update the game to continue."
	else:
		_render_play(play, status)
	_render_values()

## SB-M42-015: bind every live Home value from the canonical services (via the pure
## HomeViewModel). Home stores nothing but the last rendered copy.
func _render_values() -> void:
	_vm = HomeViewModel.build(_app)
	if not _vm.get("ok", false):
		return
	# SB-M42-019: the profile bar is Bot Parts toward the next 250-part robot (canonical
	# RobotUnlockService / wallet), never XP. At >= target the bar is full and READY.
	var parts_text := "BOT PARTS %d/%d" % [_vm["bot_parts"], _vm["bot_parts_target"]]
	if _vm["robot_can_unlock"]:
		parts_text += " · ROBOT READY"
	(_nodes["ProfileBotParts"] as UiProgressMeter).set_progress(_vm["bot_parts"], _vm["bot_parts_target"],
		"LEVEL %d · %s" % [_vm["level"], parts_text])
	# SB-M42-018: top currency is Scrub Bucks (banknote icon once approved; native "SB"
	# tag meanwhile) with the live canonical wallet balance. No coin/Star authority.
	var sb: UiValueChip = _nodes["ScrubBucksChip"]
	sb.set_tag("SB")
	sb.set_value(_group_digits(_vm["scrub_bucks"]))
	var hearts: UiValueChip = _nodes["HeartsChip"]
	hearts.set_value("%d/%d" % [_vm["hearts"], _vm["hearts_max"]])
	hearts.set_sub("" if _vm["hearts"] >= _vm["hearts_max"] else _mmss(_vm["heart_seconds_to_next"]))
	# SB-M42-020: the former event bar is the canonical Gift Meter (fed only by Win Streak
	# SB inside GiftMeterService) with live progress + next milestone (10/50/250/500/1000).
	# There is no event timer and no Event Points.
	var next_text := ("NEXT GIFT AT %d" % _vm["gift_next_milestone"]) if _vm["gift_next_milestone"] > 0 else "CYCLE COMPLETE"
	(_nodes["GiftMeterBar"] as UiProgressMeter).set_progress(_vm["gift_progress"], _vm["gift_cycle_max"],
		"GIFT METER %d/%d · %s" % [_vm["gift_progress"], _vm["gift_cycle_max"], next_text])
	for step in _vm["win_streak_track"]:
		var chip: UiValueChip = _nodes["TrackStep%d" % step["position"]]
		chip.set_value("+%d" % step["sb"])
		chip.set_sub(("%d+" % step["position"]) if step["position"] == HomeViewModel.TRACK_POSITIONS else str(step["position"]))
	(_nodes["Shortcut_win_streak"] as UiShortcutButton).set_badge(_vm["win_streak"])
	(_nodes["Shortcut_gift_bar"] as UiShortcutButton).set_badge(_vm["gift_claimable"])
	(_nodes["Shortcut_cards_exchange"] as UiShortcutButton).set_badge(_vm["cards_duplicates"])
	(_nodes["Shortcut_daily"] as UiShortcutButton).set_badge(_vm["daily_cycle_day"])
	for id in LEFT_SHORTCUTS + RIGHT_SHORTCUTS:
		(_nodes["Shortcut_" + id[0]] as Button).disabled = not LIVE_SHORTCUTS.has(id[0])
	for pid in _popups:
		if (_popups[pid] as Control).visible:
			_render_popup(pid)

## 1234567 -> "1,234,567" (moved behind the localization seam in SB-M42-025).
static func _group_digits(n: int) -> String:
	var neg := n < 0
	var d := str(absi(n))
	var out := ""
	while d.length() > 3:
		out = "," + d.substr(d.length() - 3) + out
		d = d.substr(0, d.length() - 3)
	return ("-" if neg else "") + d + out


# ------------------------------------------------------------- popups ----

## Open the Home popup for a live shortcut. Returns the popup or null.
func open_popup(id: String):
	if not LIVE_SHORTCUTS.has(id) or _app == null:
		return null
	if not _popups.has(id):
		var p := HomePopup.new(id)
		p.action_pressed.connect(_on_popup_action.bind(id))
		add_child(p)
		_popups[id] = p
	var popup: HomePopup = _popups[id]
	move_child(popup, get_child_count() - 1)
	popup.show()
	_render_popup(id)
	return popup

func get_popup(id: String):
	return _popups.get(id)

## Close the topmost visible popup (back navigation). True when one was closed.
func close_top_popup() -> bool:
	for pid in _popups:
		if (_popups[pid] as Control).visible:
			(_popups[pid] as HomePopup).close_popup()
			return true
	return false

func _render_popup(id: String) -> void:
	var popup: HomePopup = _popups[id]
	match id:
		"gift_bar":
			_render_gift_bar(popup)

## SB-M42-021: queued Gift Meter milestone rewards from GiftMeterService.claimable();
## CLAIM goes through the canonical action facade (idempotent by occurrence id, saves).
func _render_gift_bar(popup: HomePopup) -> void:
	var rows: Array = []
	for occ in _app.economy.gift.claimable():
		var rewards: Dictionary = _app.economy.config.gift_meter_milestone(int(occ["milestone"]))
		rows.append({"text": "GIFT %d · %s" % [int(occ["milestone"]), _reward_text(rewards)],
			"action_id": String(occ["id"]), "action_text": "CLAIM", "action_enabled": not _app.is_blocked})
	var note := ""
	if rows.is_empty():
		note = "No gifts to claim. Win levels in a row to fill the Gift Meter."
	elif _app.is_blocked:
		note = "Claims are unavailable while the save is read-only."
	popup.set_content("GIFTS", rows, note)

func _on_popup_action(action_id: String, popup_id: String) -> void:
	if _app == null or _app.is_blocked:
		return
	match popup_id:
		"gift_bar":
			_app.actions.claim_gift(action_id)
	refresh()

static func _reward_text(rewards: Dictionary) -> String:
	var parts: Array = []
	var keys: Array = rewards.keys()
	keys.sort()
	for k in keys:
		if int(rewards[k]) > 0:
			parts.append("%s x%d" % [REWARD_NAMES.get(k, k), int(rewards[k])])
	return ", ".join(parts)

static func _mmss(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func get_view_model() -> Dictionary:
	return _vm.duplicate(true)

## SB-M42-003: the ONE CTA launches only the canonical progression frontier.
##   no completed level -> "PLAY"; otherwise "CONTINUE · LEVEL N".
## A frontier without catalog content is shown honestly and disabled (never falls back
## to other content, never offers a picker).
func _render_play(play: Button, status: Label) -> void:
	_launch = GameplayLaunchResolver.resolve(_app)
	var level := int(_launch.get("level", _app.progression.current_level()))
	var first_time: bool = _app.progression.completed_count() == 0
	play.text = "PLAY" if first_time else "CONTINUE · LEVEL %d" % level
	if _launch.get("ok", false):
		play.disabled = false
		status.text = ""
	elif _launch.get("reason", "") == GameplayLaunchResolver.CONTENT_MISSING:
		play.disabled = true
		status.text = "Level %d is coming soon." % level
	else:
		play.disabled = true
		status.text = "Levels unavailable (%s)." % String(_launch.get("reason", ""))

func get_launch_preview() -> Dictionary:
	return _launch.duplicate(true)
