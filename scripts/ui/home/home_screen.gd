extends Control
## HomeScreen — res://scenes/ui/home/home_screen.tscn (preload this script; AL-001).
##
## M42 production Home (SB-M42-002 shell; master-convergence V02 composition). Responsive
## native Godot Controls — never a flattened interactive screenshot:
##
##   HomeScreen (Home theme: bold face + navy outline)
##   ├── Background        sky / far city / mid city / street layers (decorative)
##   └── SafeAreaRoot/MarginContainer/Content/HomeLayout (VBox)
##       ├── TopCurrencyHUD      profile card (portrait+frame, name, rank badge+level,
##       │                       Bot Parts bar) · Scrub Bucks chip · Hearts chip · menu
##       ├── GiftMeter           emblem · thick gold meter + live caption · reward crate
##       ├── MainWorldArea       Left cards · CenterScrubbyArea · Right cards
##       │     CenterScrubbyArea/WorldStage (spans the whole MainWorldArea, behind cards):
##       │       Layer_central_world_and_environment  neon, arch, arch decor, area banner
##       │         (live title/number), puddles, props, platform main + platform top
##       │       Layer_characters  helper bots, Scrubby (+ blink / brush idle states),
##       │         foreground bucket + foam
##       ├── PlayButton          green hero CTA · live PLAY + frontier subtitle · play icon
##       ├── StatusLabel         (only when there is something to say)
##       ├── WinStreakRewardTrack badge + streak · progress line · 5 reward gifts + live SB
##       └── BottomNav           full-width dock, 5 framed icon tabs, raised HOME
##
## Every approved ART entry is accounted in HomePresentationMap (STATIC / STATE / REUSE).
## The screen owns NO durable truth: it reads the canonical AppState (bound by the app
## root) and only emits intents (play/settings/nav/shortcut). A blocked (future-schema)
## save shows an explicit read-only state and disables PLAY.

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
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const HomePresentationMap = preload("res://scripts/ui/home/home_presentation_map.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

## Shortcuts with a V1 Home destination (popup). Others belong to later milestones and
## are shown disabled.
const LIVE_SHORTCUTS := ["gift_bar", "cards_exchange", "daily"]

## Shortcut columns (SB-M42-010/012). Destinations belonging to later milestones are
## rendered disabled by refresh(), never faked.
const LEFT_SHORTCUTS := [["win_streak", "HOME_SC_WIN_STREAK"], ["gift_bar", "HOME_SC_GIFT_BAR"], ["collection", "HOME_SC_COLLECTION"], ["shop", "HOME_SC_SHOP"]]
const RIGHT_SHORTCUTS := [["no_ads", "HOME_SC_NO_ADS"], ["daily", "HOME_SC_DAILY"], ["tasks", "HOME_SC_TASKS"], ["cards_exchange", "HOME_SC_CARDS_EXCHANGE"]]
## Win Streak track positions 1..5+ (values are rendered live from WinStreakService).
const TRACK_POSITIONS := 5

## Layered art regions (SB-M42-011), named by assets/ui/HOME_ASSET_MANIFEST.json
## layer_order. The owner reference image itself is never loaded or shipped.
const SCREEN_LAYERS := ["background.sky", "background.city_far", "background.city_mid", "background.street_foreground"]
const WORLD_LAYERS := ["central_world_and_environment", "characters"]

## World-stage placement, in reference pixels of a 1080x1154 stage (scaled by the stage
## unit). [node, center-x fraction of stage width, bottom-y fraction of stage height,
## height px]. Order inside each group = draw order (back to front).
const WORLD_GROUP := [
	["Art_neon", 0.50, 0.86, 300],
	["Art_arch", 0.50, 0.83, 900],
	["Art_arch_decor", 0.50, 0.30, 330],
	["Art_puddles", 0.50, 1.03, 330],
	["Art_keep_clean_sign", 0.69, 0.80, 175],
	["Art_cleaning_equipment", 0.32, 0.84, 165],
	["Art_hose", 0.66, 0.99, 125],
	["Art_platform_main", 0.50, 1.01, 400],
	["Art_platform_top", 0.50, 0.745, 250],
	["Art_wet_floor_sign", 0.72, 0.97, 150],
]
const CHARACTER_GROUP := [
	["Art_helper_alt", 0.30, 0.79, 190],
	["Art_helper_floor", 0.27, 1.00, 215],
	["Art_helper_cart", 0.76, 1.00, 215],
	["Art_scrubby", 0.50, 0.785, 560],
	["Art_bucket", 0.39, 1.02, 125],
	["Art_foam", 0.61, 1.02, 105],
]
const STAGE_REF := Vector2(1080, 1154)

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
var _idle_t := 0.0
var _idle_state := ""

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
	_nodes["HomeLayout"].resized.connect(_apply_layout_mode)
	_nodes["Background"].resized.connect(_layout_background)
	_apply_layout_mode()
	if _art == null:
		set_art_binder(HomeArtBinder.new())
	refresh()

## Bind the canonical AppState (app root). Re-renders.
func bind(app_state) -> void:
	_app = app_state
	if _built:
		refresh()

## SB-M42-017 + V02: bind ONLY owner-approved art (HomeArtBinder gate) onto the nodes the
## HomePresentationMap names. Unapproved slugs keep the native placeholder (null).
func set_art_binder(binder) -> void:
	_art = binder
	if not _built:
		return
	for id in HomePresentationMap.ENTRIES:
		var e: Dictionary = HomePresentationMap.ENTRIES[id]
		var tex: Texture2D = _art.texture(String(e["slug"]))
		for n in e["nodes"]:
			HomePresentationMap.apply(_nodes[n], String(e["slot"]), tex)
	_layout_background()
	_layout_world()

func get_art_binder():
	return _art

func get_app_state():
	return _app

func get_region(region: String) -> Control:
	return _nodes.get(region)

## V02 presentation accounting: one row per HomePresentationMap entry with the concrete
## node(s), whether each node presents a texture, and whether it is visible in the
## normal composition (STATE nodes are only visible in their idle state).
func get_presentation_accounting() -> Array:
	var out: Array = []
	for id in HomePresentationMap.ENTRIES:
		var e: Dictionary = HomePresentationMap.ENTRIES[id]
		var nodes: Array = []
		for n in e["nodes"]:
			var node = _nodes.get(n)
			var tex: Texture2D = HomePresentationMap.presented(node, String(e["slot"]))
			nodes.append({"name": n, "exists": node != null, "texture": tex, "visible": node != null and node.is_visible_in_tree()})
		out.append({"id": id, "slug": e["slug"], "mode": e["mode"], "state": e.get("state", ""), "reuse_of": e.get("reuse_of", ""), "nodes": nodes})
	return out

# ------------------------------------------------------------------ build ----

func _build() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = HomeStyle.make_theme()

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = BG01
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_nodes["Background"] = bg
	for layer in SCREEN_LAYERS:
		var t := HomeStyle.art("Layer_" + layer.replace(".", "_"))
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED if layer == "background.sky" else TextureRect.STRETCH_SCALE
		bg.add_child(t)
		_nodes["Layer_" + layer] = t
	var shade := ColorRect.new()
	shade.name = "BackgroundShade"
	shade.color = Color(0.02, 0.06, 0.16, 0.18)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(shade)

	var safe = SafeAreaRootScene.instantiate()
	safe.name = "SafeAreaRoot"
	add_child(safe)
	_nodes["SafeAreaRoot"] = safe
	var content: Control = safe.get_node("MarginContainer/Content")

	var layout := VBoxContainer.new()
	layout.name = "HomeLayout"
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	content.add_child(layout)
	_nodes["HomeLayout"] = layout

	var hud := MarginContainer.new()
	hud.name = "TopCurrencyHUD"
	_side_margins(hud, 18, 14, 0)
	layout.add_child(hud)
	_nodes["TopCurrencyHUD"] = hud
	var gm := MarginContainer.new()
	gm.name = "GiftMeter"
	_side_margins(gm, 34, 0, 0)
	layout.add_child(gm)
	_nodes["GiftMeter"] = gm

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
			v.add_theme_constant_override("separation", UiTokens.SPACE_MD)
			v.alignment = BoxContainer.ALIGNMENT_CENTER
			v.z_index = 1   # cards draw in front of the world stage that spans behind them
			c = v
		c.name = region
		world.add_child(c)
		_nodes[region] = c
	_build_world(_nodes["CenterScrubbyArea"])

	_build_play(layout)

	var status := HomeStyle.label("", UiTokens.FONT_BODY)
	status.name = "StatusLabel"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.visible = false
	layout.add_child(status)
	_nodes["StatusLabel"] = status

	var track := MarginContainer.new()
	track.name = "WinStreakRewardTrack"
	_side_margins(track, 22, 0, 0)
	layout.add_child(track)
	_nodes["WinStreakRewardTrack"] = track

	_build_hud(hud)
	_build_gift_meter(gm)
	_build_shortcuts(_nodes["LeftShortcutColumn"], LEFT_SHORTCUTS)
	_build_shortcuts(_nodes["RightShortcutColumn"], RIGHT_SHORTCUTS)
	_build_track(track)

	var nav := PanelContainer.new()
	nav.name = "BottomNav"
	var dock := HomeStyle.box(HomeStyle.NAVY, HomeStyle.GLOW, 0, 0, 14)
	dock.border_width_top = 5
	dock.corner_radius_top_left = 34
	dock.corner_radius_top_right = 34
	HomeStyle.pad(dock, 14, 14)
	nav.add_theme_stylebox_override("panel", dock)
	layout.add_child(nav)
	_nodes["BottomNav"] = nav
	_build_bottom_nav(nav)

static func _side_margins(m: MarginContainer, h: int, top: int, bottom: int) -> void:
	m.add_theme_constant_override("margin_left", h)
	m.add_theme_constant_override("margin_right", h)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_bottom", bottom)

func _reg(n: Control) -> Control:
	_nodes[String(n.name)] = n
	return n

## Ordered art layer nodes (manifest layer_order minus the "ui" layer).
func get_art_layers() -> Array:
	var out: Array = []
	for layer in SCREEN_LAYERS + WORLD_LAYERS:
		out.append(_nodes["Layer_" + layer])
	return out

# ------------------------------------------------------------- top HUD ----

## Profile card (portrait inside the approved avatar frame, live name, rank badge with
## live level, live Bot Parts bar) + Scrub Bucks + Hearts + menu, as one HUD band.
func _build_hud(hud: MarginContainer) -> void:
	var row := HBoxContainer.new()
	row.name = "HudRow"
	row.add_theme_constant_override("separation", 14)
	hud.add_child(row)

	var card := PanelContainer.new()
	card.name = "ProfileCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(HomeStyle.CARD, HomeStyle.EDGE, 4, 30, 10, 4), 10, 8))
	row.add_child(_reg(card))
	var cardrow := HBoxContainer.new()
	cardrow.add_theme_constant_override("separation", 10)
	card.add_child(cardrow)

	var avatar := Control.new()
	avatar.name = "ProfileAvatar"
	avatar.custom_minimum_size = Vector2(150, 150)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cardrow.add_child(_reg(avatar))
	var portrait := HomeStyle.art("ProfilePortrait")
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = 16
	portrait.offset_top = 14
	portrait.offset_right = -16
	portrait.offset_bottom = -12
	avatar.add_child(_reg(portrait))
	var frame := HomeStyle.art("ProfileAvatarFrame")
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar.add_child(_reg(frame))

	var info := VBoxContainer.new()
	info.name = "ProfileInfo"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	cardrow.add_child(info)
	var name_label := HomeStyle.label("", 44)
	name_label.name = "ProfileName"
	info.add_child(_reg(name_label))
	var rank_title := HomeStyle.label("", 28, HomeStyle.EDGE)
	rank_title.name = "ProfileRankTitle"
	rank_title.visible = false   # shown only when a canonical rank/title exists
	info.add_child(_reg(rank_title))
	var lvl_row := HBoxContainer.new()
	lvl_row.add_theme_constant_override("separation", 8)
	info.add_child(lvl_row)
	var rank := HomeStyle.art("ProfileRankBadge")
	rank.custom_minimum_size = Vector2(76, 70)
	lvl_row.add_child(_reg(rank))
	var lvl := HomeStyle.label("", 30)
	lvl.name = "ProfileLevel"
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lvl.set_anchors_preset(Control.PRESET_FULL_RECT)
	rank.add_child(_reg(lvl))
	var parts := UiProgressMeter.new("ProfileBotParts")
	parts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parts.caption.add_theme_font_size_override("font_size", 24)
	HomeStyle.style_meter(parts.bar, HomeStyle.GREEN, 24)
	lvl_row.add_child(_reg(parts))

	var right := VBoxContainer.new()
	right.name = "HudCurrencies"
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	for id in ["ScrubBucksChip", "HeartsChip"]:
		var chip := UiValueChip.new(id)
		chip.set_icon_size(72)
		chip.set_value_size(40)
		chip.custom_minimum_size = Vector2(290, UiTokens.TOUCH_MIN)
		chip.set_panel_style(HomeStyle.pad(HomeStyle.box(HomeStyle.NAVY, HomeStyle.GLOW, 4, 44, 8), 12, 2))
		right.add_child(_reg(chip))

	var menu := Button.new()
	menu.name = "MenuButton"
	menu.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN + 16, UiTokens.TOUCH_MIN + 16)
	menu.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	menu.focus_mode = Control.FOCUS_NONE
	menu.tooltip_text = UiText.t("HOME_NAV_SETTINGS")
	HomeStyle.style_icon_button(menu)
	for i in range(3):
		var bar := ColorRect.new()
		bar.color = Color(1, 1, 1)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.set_anchors_preset(Control.PRESET_CENTER)
		bar.offset_left = -26
		bar.offset_right = 26
		bar.offset_top = -22 + i * 18
		bar.offset_bottom = -14 + i * 18
		menu.add_child(bar)
	# The menu opens the existing Settings overlay (same intent as the SETTINGS tab).
	menu.pressed.connect(func(): settings_requested.emit())
	row.add_child(_reg(menu))

# ---------------------------------------------------------- Gift Meter ----

func _build_gift_meter(gm: MarginContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "GiftMeterPanel"
	panel.add_theme_stylebox_override("panel", HomeStyle.panel(HomeStyle.PANEL, HomeStyle.GLOW, 34, 12, 8))
	gm.add_child(_reg(panel))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var emblem := HomeStyle.art("GiftEmblem")
	emblem.custom_minimum_size = Vector2(112, 112)
	row.add_child(_reg(emblem))
	var meter := UiProgressMeter.new("GiftMeterBar")
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meter.caption.add_theme_font_size_override("font_size", 30)
	meter.caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeStyle.style_meter(meter.bar, HomeStyle.GOLD, 44)
	row.add_child(_reg(meter))
	var crate := HomeStyle.art("GiftCrate")
	crate.custom_minimum_size = Vector2(112, 112)
	row.add_child(_reg(crate))
	var count := HomeStyle.label("", 28)
	count.name = "GiftClaimableBadge"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sb := HomeStyle.box(Color(0.95, 0.55, 0.05), Color(1, 1, 1), 3, 24, 0)
	count.add_theme_stylebox_override("normal", sb)
	count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count.offset_left = -48
	count.offset_top = -48
	count.offset_right = 4
	count.offset_bottom = 4
	crate.add_child(_reg(count))

# ---------------------------------------------------------- world stage ----

func _build_world(center: Control) -> void:
	center.clip_contents = false
	var stage := Control.new()
	stage.name = "WorldStage"
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_reg(stage))
	for group in WORLD_LAYERS:
		var g := Control.new()
		g.name = "Layer_" + group.replace(".", "_")
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(g)
		_nodes["Layer_" + group] = g
	var world_g: Control = _nodes["Layer_central_world_and_environment"]
	for spec in WORLD_GROUP:
		world_g.add_child(_reg(HomeStyle.art(spec[0])))
	var banner := PanelContainer.new()
	banner.name = "AreaBanner"
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(Color(0.05, 0.20, 0.30, 0.92), Color(0.30, 0.95, 0.85), 4, 40, 8), 28, 6))
	world_g.add_child(_reg(banner))
	var bcol := VBoxContainer.new()
	bcol.add_theme_constant_override("separation", 0)
	bcol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(bcol)
	var title := HomeStyle.label("", 50, Color(0.55, 1.0, 0.92))
	title.name = "AreaTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bcol.add_child(_reg(title))
	var number := HomeStyle.label("", 32, Color(0.75, 1.0, 0.95))
	number.name = "AreaNumber"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bcol.add_child(_reg(number))
	var chars: Control = _nodes["Layer_characters"]
	for spec in CHARACTER_GROUP:
		chars.add_child(_reg(HomeStyle.art(spec[0])))
		if spec[0] == "Art_scrubby":
			# STATE layers (HOME-031 blink / HOME-032 brush arm) ride on Scrubby.
			var blink := HomeStyle.art("ScrubbyBlink")
			blink.visible = false
			chars.add_child(_reg(blink))
			var arm := HomeStyle.art("ScrubbyBrushArm")
			arm.visible = false
			chars.add_child(_reg(arm))

## Lay out every world node from WORLD_GROUP / CHARACTER_GROUP inside the stage that
## spans the whole MainWorldArea (behind the shortcut cards).
func _layout_world() -> void:
	if not _built:
		return
	var world: Control = _nodes["MainWorldArea"]
	var center: Control = _nodes["CenterScrubbyArea"]
	var stage: Control = _nodes["WorldStage"]
	if world.size.x <= 0 or world.size.y <= 0:
		return
	stage.position = world.global_position - center.global_position
	stage.size = world.size
	for g in WORLD_LAYERS:
		var gc: Control = _nodes["Layer_" + g]
		gc.position = Vector2.ZERO
		gc.size = world.size
	var W := world.size.x
	var H := world.size.y
	var s := minf(W / STAGE_REF.x, H / STAGE_REF.y)
	for spec in WORLD_GROUP + CHARACTER_GROUP:
		var n: TextureRect = _nodes[spec[0]]
		var h: float = float(spec[3]) * s
		if spec[0] == "Art_arch":
			h = maxf(h, H * 0.80)
		var aspect := _aspect(n)
		var w := minf(h * aspect, W * 0.96)
		h = w / aspect
		n.size = Vector2(w, h)
		n.position = Vector2(W * float(spec[1]) - w * 0.5, H * float(spec[2]) - h)
	# The arch stands behind the platform: its base sits at the platform's middle on every
	# aspect (tall phones grow the arch, never leave the platform floating below it).
	var arch: TextureRect = _nodes["Art_arch"]
	var base_p: TextureRect = _nodes["Art_platform_main"]
	var arch_bottom := base_p.position.y + base_p.size.y * 0.35
	var arch_h := arch_bottom - H * 0.07
	arch.size = Vector2(arch_h * _aspect(arch), arch_h)
	if arch.size.x > W * 0.96:
		arch.size = Vector2(W * 0.96, W * 0.96 / _aspect(arch))
	arch.position = Vector2(W * 0.5 - arch.size.x * 0.5, arch_bottom - arch.size.y)
	var neon: TextureRect = _nodes["Art_neon"]
	neon.position.y = arch_bottom - neon.size.y - arch.size.y * 0.05
	# Arch decor crowns the arch; banner sits on the arch head.
	var decor: TextureRect = _nodes["Art_arch_decor"]
	decor.size = Vector2(arch.size.x * 1.02, arch.size.x * 1.02 / _aspect(decor))
	decor.position = Vector2(arch.position.x + (arch.size.x - decor.size.x) * 0.5, arch.position.y - decor.size.y * 0.18)
	var banner: Control = _nodes["AreaBanner"]
	banner.size = Vector2.ZERO
	var bmin := banner.get_combined_minimum_size()
	banner.size = bmin
	banner.position = Vector2(W * 0.5 - bmin.x * 0.5, arch.position.y + arch.size.y * 0.035)
	# Scrubby stands ON the platform top: feet at the top disc's visible center.
	var top: TextureRect = _nodes["Art_platform_top"]
	var main_p: TextureRect = _nodes["Art_platform_main"]
	top.size = Vector2(main_p.size.x * 0.94, main_p.size.x * 0.94 / _aspect(top))
	top.position = Vector2(W * 0.5 - top.size.x * 0.5, main_p.position.y - top.size.y * 0.30)
	var sc: TextureRect = _nodes["Art_scrubby"]
	var feet_y := top.position.y + top.size.y * 0.52
	sc.position.y = feet_y - sc.size.y
	var blink: TextureRect = _nodes["ScrubbyBlink"]
	blink.size = Vector2(sc.size.x * 0.46, sc.size.x * 0.46 / _aspect(blink))
	blink.position = sc.position + Vector2(sc.size.x * 0.285, sc.size.y * 0.195)
	var arm: TextureRect = _nodes["ScrubbyBrushArm"]
	arm.size = Vector2(sc.size.x * 0.55, sc.size.x * 0.55 / _aspect(arm))
	arm.position = sc.position + Vector2(sc.size.x * 0.60, sc.size.y * 0.30)

func _aspect(t: TextureRect) -> float:
	if t.texture != null and t.texture.get_height() > 0:
		return float(t.texture.get_width()) / float(t.texture.get_height())
	return 1.0

## Screen-wide background layers: sky covers, cities sit in the mid band, the street
## fills the lower part — no dead sky band behind the world.
func _layout_background() -> void:
	var bg: Control = _nodes.get("Background")
	if bg == null or bg.size.x <= 0:
		return
	var W := bg.size.x
	var H := bg.size.y
	var sky: TextureRect = _nodes["Layer_background.sky"]
	sky.position = Vector2.ZERO
	sky.size = bg.size
	var far: TextureRect = _nodes["Layer_background.city_far"]
	var fw := W * 2.2
	far.size = Vector2(fw, fw / _aspect(far))
	far.position = Vector2((W - fw) * 0.5, H * 0.50 - far.size.y)
	var mid: TextureRect = _nodes["Layer_background.city_mid"]
	var mw := W * 2.0
	mid.size = Vector2(mw, mw / _aspect(mid))
	mid.position = Vector2((W - mw) * 0.5, H * 0.60 - mid.size.y)
	var street: TextureRect = _nodes["Layer_background.street_foreground"]
	var sh := H * 0.52
	var sw := maxf(W, sh * _aspect(street))
	street.size = Vector2(sw, sw / _aspect(street))
	street.position = Vector2((W - sw) * 0.5, H - street.size.y)

func _process(delta: float) -> void:
	# Idle character states (presentation only): blink every ~4 s, brush-arm scrub every
	# ~9 s. STATE entries of HomePresentationMap.
	if not _built or not is_visible_in_tree():
		return
	_idle_t += delta
	var phase := fmod(_idle_t, 9.0)
	set_idle_state("idle_scrub" if phase > 7.8 else ("idle_blink" if fmod(_idle_t, 4.0) > 3.82 else ""))

## Show exactly one idle state layer ("idle_blink" / "idle_scrub" / "" = none).
func set_idle_state(state: String) -> void:
	if state == _idle_state:
		return
	_idle_state = state
	(_nodes["ScrubbyBlink"] as Control).visible = state == "idle_blink"
	(_nodes["ScrubbyBrushArm"] as Control).visible = state == "idle_scrub"

func get_idle_state() -> String:
	return _idle_state

# ------------------------------------------------------------ shortcuts ----

func _build_shortcuts(column: VBoxContainer, specs: Array) -> void:
	for spec in specs:
		var b := UiShortcutButton.new(spec[0], UiText.t(spec[1]))
		HomeStyle.style_card_button(b)
		b.add_theme_font_size_override("font_size", 26)
		var id: String = spec[0]
		b.pressed.connect(func():
			shortcut_requested.emit(id)
			open_popup(id))
		column.add_child(b)
		_nodes["Shortcut_" + id] = b

# ------------------------------------------------------------- Play CTA ----

## Dominant green native CTA: live PLAY label, live frontier subtitle and the approved
## play icon (HOME-078) inside the same Button; the hit region is the visible CTA.
func _build_play(layout: VBoxContainer) -> void:
	var play := Button.new()
	play.name = "PlayButton"
	play.text = UiText.t("HOME_PLAY")
	play.custom_minimum_size = Vector2(700, 196)
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.focus_mode = Control.FOCUS_NONE
	play.add_theme_font_size_override("font_size", 104)
	HomeStyle.style_play_button(play)
	play.add_theme_constant_override("outline_size", 16)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb: StyleBoxFlat = play.get_theme_stylebox(st)
		sb.content_margin_bottom = 58
		sb.content_margin_right = 150
	play.pressed.connect(func():
		if not play.disabled:
			play_requested.emit())
	layout.add_child(_reg(play))
	var icon := HomeStyle.art("PlayIcon")
	icon.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	icon.offset_left = -170
	icon.offset_right = -40
	icon.offset_top = -80
	icon.offset_bottom = 34
	play.add_child(_reg(icon))
	var sub := HomeStyle.label("", 38, HomeStyle.SUBTITLE, 10)
	sub.name = "PlaySubtitle"
	sub.add_theme_color_override("font_outline_color", HomeStyle.GREEN_EDGE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sub.offset_top = -74
	sub.offset_bottom = -22
	play.add_child(_reg(sub))

# ---------------------------------------------------- Win Streak track ----

func _build_track(track: MarginContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "TrackPanel"
	panel.add_theme_stylebox_override("panel", HomeStyle.panel(HomeStyle.PANEL, HomeStyle.GLOW, 34, 14, 8))
	track.add_child(_reg(panel))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var badge := HomeStyle.art("TrackBadge")
	badge.custom_minimum_size = Vector2(132, 132)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_reg(badge))
	var streak := HomeStyle.label("", 44)
	streak.name = "TrackStreakValue"
	streak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	streak.set_anchors_preset(Control.PRESET_FULL_RECT)
	streak.offset_top = 10
	badge.add_child(_reg(streak))
	var area := Control.new()
	area.name = "TrackSteps"
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_reg(area))
	var line := ProgressBar.new()
	line.name = "TrackProgress"
	line.show_percentage = false
	line.max_value = TRACK_POSITIONS
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HomeStyle.style_meter(line, Color(0.55, 0.95, 0.20), 18)
	line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	line.offset_top = 46
	line.offset_bottom = 64
	line.offset_left = 20
	line.offset_right = -20
	area.add_child(_reg(line))
	var steps := HBoxContainer.new()
	steps.set_anchors_preset(Control.PRESET_FULL_RECT)
	steps.add_theme_constant_override("separation", 4)
	steps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(steps)
	area.custom_minimum_size = Vector2(0, 190)
	for i in range(TRACK_POSITIONS):
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", 0)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		steps.add_child(col)
		var gift := HomeStyle.art("TrackGift%d" % (i + 1))
		gift.custom_minimum_size = Vector2(0, 104)
		col.add_child(_reg(gift))
		var chip := UiValueChip.new("TrackStep%d" % (i + 1))
		chip.set_icon_size(46)
		chip.set_value_size(32)
		chip.custom_minimum_size = Vector2(0, 80)
		chip.set_panel_style(StyleBoxEmpty.new())
		chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		chip.sub_label.add_theme_font_size_override("font_size", 22)
		col.add_child(_reg(chip))

# ----------------------------------------------------------- bottom nav ----

## Bottom navigation dock. Only HOME and SETTINGS have V1 destinations; the other tabs are
## shown disabled (their screens belong to later milestones) — never faked.
func _build_bottom_nav(nav: PanelContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	nav.add_child(row)
	for spec in [["events", "HOME_NAV_EVENTS"], ["robots", "HOME_NAV_ROBOTS"], ["home", "HOME_NAV_HOME"], ["leaderboard", "HOME_NAV_LEADERBOARD"], ["settings", "HOME_NAV_SETTINGS"]]:
		var b := Button.new()
		var id: String = spec[0]
		b.name = "SettingsButton" if id == "settings" else "Nav_" + id
		b.text = UiText.t(spec[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 176)
		b.add_theme_font_size_override("font_size", 26)
		b.focus_mode = Control.FOCUS_NONE
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		HomeStyle.style_nav_button(b, id == "home")
		for st in ["normal", "hover", "pressed", "disabled"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(st)
			sb.content_margin_top = 116
		var icon := HomeStyle.art("NavIcon_" + id)
		icon.set_anchors_preset(Control.PRESET_CENTER_TOP)
		icon.offset_left = -50
		icon.offset_right = 50
		icon.offset_top = 10
		icon.offset_bottom = 110
		b.add_child(_reg(icon))
		match id:
			"settings":
				b.pressed.connect(func(): settings_requested.emit())
			"home":
				b.toggle_mode = true
				b.button_pressed = true
				b.disabled = true   # already here
			_:
				b.disabled = true
				b.tooltip_text = UiText.t("HOME_COMING_LATER")
		b.pressed.connect(func(): nav_requested.emit(id))
		row.add_child(b)
		_nodes["Nav_" + id] = b

# ------------------------------------------------------------ responsive ----

## Responsive spacing by layout mode (COMPACT/NORMAL/TALL). Presentation only.
func _apply_layout_mode() -> void:
	if not _built:
		return
	var mode := ResponsiveLayout.get_layout_mode(get_viewport_rect().size)
	var gap: int = UiTokens.SPACE_SM if mode == ResponsiveLayout.LayoutMode.COMPACT else (UiTokens.SPACE_LG if mode == ResponsiveLayout.LayoutMode.TALL else UiTokens.SPACE_MD)
	(_nodes["HomeLayout"] as VBoxContainer).add_theme_constant_override("separation", gap)
	_apply_shortcut_columns(mode)
	_layout_background()
	_layout_world.call_deferred()

## SB-M42-012: shortcut card width scales with the world width so the central world keeps
## >= CENTER_MIN_FRACTION; cards never drop below TOUCH_MIN; card height follows the
## available world height so the four cards frame the hero with an even rhythm.
const CENTER_MIN_FRACTION := 0.4
func _apply_shortcut_columns(mode: int) -> void:
	var world: Control = _nodes["MainWorldArea"]
	var width: float = world.size.x if world.size.x > 0.0 else get_viewport_rect().size.x
	# Height available to the world = layout height minus the other regions (never the
	# world's own size, which the card minimums feed back into).
	var layout: VBoxContainer = _nodes["HomeLayout"]
	var height: float = layout.size.y if layout.size.y > 0.0 else get_viewport_rect().size.y
	var sep: int = layout.get_theme_constant("separation")
	for c in layout.get_children():
		if c != world and (c as Control).visible:
			height -= (c as Control).get_combined_minimum_size().y + sep
	var col_w: float = clampf(width * (1.0 - CENTER_MIN_FRACTION) * 0.5 - UiTokens.SPACE_SM, UiTokens.TOUCH_MIN, 236.0)
	var card_h: float = clampf((height - 3 * UiTokens.SPACE_MD) / 4.0, UiTokens.TOUCH_MIN, 214.0)
	var vgap: int = int(clampf((height - 4 * card_h) / 5.0, UiTokens.SPACE_XS, 48))
	for side in ["LeftShortcutColumn", "RightShortcutColumn"]:
		var col: VBoxContainer = _nodes[side]
		col.add_theme_constant_override("separation", vgap)
		for b in col.get_children():
			(b as Control).custom_minimum_size = Vector2(col_w, card_h)

func get_layout_mode() -> int:
	return ResponsiveLayout.get_layout_mode(get_viewport_rect().size)

# ---------------------------------------------------------------- refresh ----

## Re-read canonical state into the live controls. Never mutates state.
func refresh() -> void:
	if not _built:
		return
	var play: Button = _nodes["PlayButton"]
	var status: Label = _nodes["StatusLabel"]
	if _app == null:
		play.disabled = true
		status.text = UiText.t("HOME_LOADING")
	elif _app.is_blocked:
		play.disabled = true
		status.text = UiText.t("HOME_SAVE_BLOCKED")
		(_nodes["PlaySubtitle"] as Label).text = ""
	else:
		_render_play(play, status)
	status.visible = not status.text.is_empty()
	_render_values()

## SB-M42-015: bind every live Home value from the canonical services (via the pure
## HomeViewModel). Home stores nothing but the last rendered copy.
func _render_values() -> void:
	_vm = HomeViewModel.build(_app)
	if not _vm.get("ok", false):
		return
	# Profile: presentational display name through the localization seam (no canonical
	# player-profile name exists yet); rank/title stays hidden until a canonical one exists.
	(_nodes["ProfileName"] as Label).text = UiText.t("HOME_PLAYER_NAME_DEFAULT")
	(_nodes["ProfileLevel"] as Label).text = UiText.num(_vm["level"])
	# SB-M42-019: the profile bar is Bot Parts toward the next 250-part robot (canonical
	# RobotUnlockService / wallet), never XP. At >= target the bar is full and READY.
	var parts_text := UiText.t("HOME_BOT_PARTS", [UiText.num(_vm["bot_parts"]), UiText.num(_vm["bot_parts_target"])])
	if _vm["robot_can_unlock"]:
		parts_text += UiText.t("HOME_ROBOT_READY")
	(_nodes["ProfileBotParts"] as UiProgressMeter).set_progress(_vm["bot_parts"], _vm["bot_parts_target"],
		UiText.t("HOME_PROFILE_LINE", [_vm["level"], parts_text]))
	# SB-M42-018: top currency is Scrub Bucks (banknote icon once approved; native "SB"
	# tag meanwhile) with the live canonical wallet balance. No coin/Star authority.
	var sb: UiValueChip = _nodes["ScrubBucksChip"]
	sb.set_tag(UiText.t("HOME_CURRENCY_SB"))
	sb.set_value(UiText.num(_vm["scrub_bucks"]))
	var hearts: UiValueChip = _nodes["HeartsChip"]
	hearts.set_value("%d/%d" % [_vm["hearts"], _vm["hearts_max"]])
	hearts.set_sub("" if _vm["hearts"] >= _vm["hearts_max"] else _mmss(_vm["heart_seconds_to_next"]))
	# SB-M42-020: the former event bar is the canonical Gift Meter (fed only by Win Streak
	# SB inside GiftMeterService) with live progress + next milestone (10/50/250/500/1000).
	# There is no event timer and no Event Points.
	var next_text := UiText.t("HOME_GIFT_NEXT", [UiText.num(_vm["gift_next_milestone"])]) if _vm["gift_next_milestone"] > 0 else UiText.t("HOME_GIFT_CYCLE_COMPLETE")
	(_nodes["GiftMeterBar"] as UiProgressMeter).set_progress(_vm["gift_progress"], _vm["gift_cycle_max"],
		UiText.t("HOME_GIFT_METER", [UiText.num(_vm["gift_progress"]), UiText.num(_vm["gift_cycle_max"]), next_text]))
	var gbadge: Label = _nodes["GiftClaimableBadge"]
	gbadge.text = str(_vm["gift_claimable"])
	gbadge.visible = _vm["gift_claimable"] > 0
	# Area banner: live/localizable title + number (presentational V1 defaults through
	# the localization seam; no area progression truth exists yet).
	(_nodes["AreaTitle"] as Label).text = UiText.t("HOME_AREA_TITLE")
	(_nodes["AreaNumber"] as Label).text = UiText.t("HOME_AREA_NUMBER", [1])
	# SB-M42-023: the Win Streak Scrub Bucks reward track: position 1/2/3/4/5+ pays
	# 1/5/10/25/100 SB (WinStreakService, owner-locked). Reached steps are fully opaque,
	# the current step is marked, future steps are dimmed. Not Stars.
	(_nodes["TrackStreakValue"] as Label).text = UiText.num(_vm["win_streak"])
	(_nodes["TrackProgress"] as ProgressBar).value = clampi(_vm["win_streak"], 0, TRACK_POSITIONS)
	for step in _vm["win_streak_track"]:
		var chip: UiValueChip = _nodes["TrackStep%d" % step["position"]]
		chip.set_tag(UiText.t("HOME_CURRENCY_SB"))
		chip.set_value(UiText.t("HOME_TRACK_AMOUNT", [UiText.num(step["sb"])]))
		var pos_text: String = ("%d+" % step["position"]) if step["position"] == HomeViewModel.TRACK_POSITIONS else str(step["position"])
		chip.set_sub(UiText.t("HOME_TRACK_WIN_NOW" if step["current"] else "HOME_TRACK_WIN", [pos_text]))
		chip.modulate.a = 1.0 if step["reached"] else 0.62
		var gift: Control = _nodes["TrackGift%d" % step["position"]]
		gift.modulate = Color(1, 1, 1, 1) if step["reached"] else Color(0.72, 0.78, 0.92, 0.80)
		gift.scale = Vector2.ONE
	(_nodes["Shortcut_win_streak"] as UiShortcutButton).set_badge(_vm["win_streak"])
	(_nodes["Shortcut_gift_bar"] as UiShortcutButton).set_badge(_vm["gift_claimable"])
	(_nodes["Shortcut_cards_exchange"] as UiShortcutButton).set_badge(_vm["cards_duplicates"])
	# SB-M42-024: Daily badge = 1 when today's login reward is claimable.
	(_nodes["Shortcut_daily"] as UiShortcutButton).set_badge(0 if _vm["daily_claimed_today"] else 1)
	for id in LEFT_SHORTCUTS + RIGHT_SHORTCUTS:
		(_nodes["Shortcut_" + id[0]] as Button).disabled = not LIVE_SHORTCUTS.has(id[0])
	for pid in _popups:
		if (_popups[pid] as Control).visible:
			_render_popup(pid)


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
		"cards_exchange":
			_render_cards_exchange(popup)
		"daily":
			_render_daily(popup)

## SB-M42-021: queued Gift Meter milestone rewards from GiftMeterService.claimable();
## CLAIM goes through the canonical action facade (idempotent by occurrence id, saves).
func _render_gift_bar(popup: HomePopup) -> void:
	var rows: Array = []
	for occ in _app.economy.gift.claimable():
		var rewards: Dictionary = _app.economy.config.gift_meter_milestone(int(occ["milestone"]))
		rows.append({"text": UiText.t("GIFTS_ROW", [UiText.num(int(occ["milestone"])), UiText.reward_text(rewards)]),
			"action_id": String(occ["id"]), "action_text": UiText.t("POPUP_CLAIM"), "action_enabled": not _app.is_blocked})
	var note := ""
	if rows.is_empty():
		note = UiText.t("GIFTS_EMPTY")
	elif _app.is_blocked:
		note = UiText.t("GIFTS_READ_ONLY")
	popup.set_content(UiText.t("GIFTS_TITLE"), rows, note)

## SB-M42-022: former Star Exchange = Cards Exchange. Presentation/navigation only:
## live duplicate-card count and their canonical SB value (CardsExchangeService), no
## Star balance and no exchange execution (the exchange flow belongs to the Collection
## milestone; no transaction rules are invented here).
func _render_cards_exchange(popup: HomePopup) -> void:
	var rows: Array = []
	var total_sb := 0
	var ex = _app.economy.exchange
	for cid in _app.economy.collection.all_card_ids():
		var n: int = ex.exchangeable(cid)
		if n > 0:
			var v: int = n * int(ex.card_value(cid))
			total_sb += v
			rows.append({"text": UiText.t("CARDS_ROW", [cid, UiText.num(n), UiText.num(v)])})
	var note := UiText.t("CARDS_EMPTY") if rows.is_empty() else UiText.t("CARDS_NOTE", [UiText.num(int(_vm.get("cards_duplicates", 0))), UiText.num(total_sb)])
	popup.set_content(UiText.t("CARDS_TITLE"), rows, note)

## SB-M42-024: Daily consecutive-login count, 5-day cycle and each day's configured
## reward (incl. booster charges) from DailyService; CLAIM goes through the canonical
## facade (local-calendar rules, atomic grant, saved). Home owns no calendar logic.
func _render_daily(popup: HomePopup) -> void:
	var d = _app.economy.daily
	var claimed: bool = d.claimed_today()
	var next_day: int = d.next_claim_cycle_day()
	var rows: Array = []
	for day in range(1, 6):
		var state := ""
		if claimed and day == next_day:
			state = UiText.t("DAILY_CLAIMED_TODAY")
		elif not claimed and day == next_day:
			state = UiText.t("DAILY_TODAY")
		var row := {"text": UiText.t("DAILY_ROW", [day, UiText.reward_text(d.login_reward_for(day)), state])}
		if not claimed and day == next_day:
			row["action_id"] = "login"
			row["action_text"] = UiText.t("POPUP_CLAIM")
			row["action_enabled"] = not _app.is_blocked
		rows.append(row)
	popup.set_content(UiText.t("DAILY_TITLE"), rows, UiText.t("DAILY_STREAK", [UiText.num(int(d.streak()))]))

func _on_popup_action(action_id: String, popup_id: String) -> void:
	if _app == null or _app.is_blocked:
		return
	match popup_id:
		"gift_bar":
			_app.actions.claim_gift(action_id)
		"daily":
			if action_id == "login":
				_app.actions.claim_daily_login()
	refresh()

static func _mmss(seconds: int) -> String:
	return "%02d:%02d" % [seconds / 60, seconds % 60]

func get_view_model() -> Dictionary:
	return _vm.duplicate(true)

## SB-M42-003: the ONE CTA launches only the canonical progression frontier. V02: the
## button always reads PLAY (hero label); the live subtitle carries the frontier:
## no completed level -> "LEVEL N"; otherwise "CONTINUE · LEVEL N". A frontier without
## catalog content is shown honestly and disabled (no fallback, no picker).
func _render_play(play: Button, status: Label) -> void:
	_launch = GameplayLaunchResolver.resolve(_app)
	var level := int(_launch.get("level", _app.progression.current_level()))
	var first_time: bool = _app.progression.completed_count() == 0
	play.text = UiText.t("HOME_PLAY")
	(_nodes["PlaySubtitle"] as Label).text = UiText.t("HOME_START_LEVEL", [level]) if first_time else UiText.t("HOME_CONTINUE_LEVEL", [level])
	if _launch.get("ok", false):
		play.disabled = false
		status.text = ""
	elif _launch.get("reason", "") == GameplayLaunchResolver.CONTENT_MISSING:
		play.disabled = true
		status.text = UiText.t("HOME_LEVEL_COMING_SOON", [level])
	else:
		play.disabled = true
		status.text = UiText.t("HOME_LEVELS_UNAVAILABLE", [String(_launch.get("reason", ""))])

func get_launch_preview() -> Dictionary:
	return _launch.duplicate(true)
