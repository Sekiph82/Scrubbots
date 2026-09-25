extends Control
## HomeScreen — res://scenes/ui/home/home_screen.tscn (preload this script; AL-001).
##
## M42 production Home (SB-M42-002 shell; master-convergence V02 composition; owner
## revision V03 — coordination/OWNER_M42_HOME_VISUAL_REVISION_V03.md). Responsive native
## Godot Controls — never a flattened interactive screenshot:
##
##   HomeScreen (Home theme: bold face + navy outline)
##   ├── Background        sky / far city / mid city / street layers (decorative); the
##   │                     cities frame the portal, the street starts right above the dock
##   └── SafeAreaRoot/MarginContainer/Content/HomeLayout (VBox)
##       ├── TopCurrencyHUD      narrow profile card (pop-out portrait in front of its
##       │                       frame, name, rank badge + live level, Bot Parts N/250)
##       │                       · Scrub Bucks chip · Hearts chip  (no top Settings entry)
##       ├── GiftMeter           emblem · thick gold meter with only N/1000 · reward crate
##       ├── MainWorldArea       Left cards (3) · CenterScrubbyArea · Right cards (3)
##       │     CenterScrubbyArea/WorldStage (spans the whole MainWorldArea, behind cards):
##       │       Layer_central_world_and_environment  neon, arch, arch decor, area banner
##       │         (live title/number), puddles, props, ONE platform (HOME-010)
##       │       Layer_characters  helper bots, Scrubby (feet on HOME-010), foreground props
##       ├── ActionRow           SHOP | PLAY (native triangle + live subtitle) | CARDS EXCHANGE
##       ├── StatusLabel         (only when there is something to say)
##       ├── WinStreakRewardTrack thin track: badge + streak · progress · 5 gifts · 1/5/10/25/100
##       └── BottomNav           full-width dock flush to the screen bottom, 5 icon tabs
##
## Modal state (V03 K): while any Home popup or the Settings panel is open, every Home
## ACTION region is hidden (no draw, no input); closing restores them.
##
## Every approved ART entry is accounted in HomePresentationMap (STATIC / OWNER_RETIRED /
## OWNER_DISABLED). The screen owns NO durable truth: it reads the canonical AppState and
## only emits intents (play/settings/nav/shortcut). A blocked (future-schema) save shows an
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
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const HomePresentationMap = preload("res://scripts/ui/home/home_presentation_map.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

## Shortcuts with a V1 Home destination (popup). Others belong to later milestones and
## are shown disabled.
const LIVE_SHORTCUTS := ["gift_bar", "cards_exchange", "daily"]

## Shortcut columns (SB-M42-010/012; V03 G: 3 + 3). Destinations belonging to later
## milestones are rendered disabled by refresh(), never faked.
const LEFT_SHORTCUTS := [["win_streak", "HOME_SC_WIN_STREAK"], ["gift_bar", "HOME_SC_GIFT_BAR"], ["collection", "HOME_SC_COLLECTION"]]
const RIGHT_SHORTCUTS := [["no_ads", "HOME_SC_NO_ADS"], ["daily", "HOME_SC_DAILY"], ["tasks", "HOME_SC_TASKS"]]
## V03 G: lower action row SHOP | PLAY | CARDS EXCHANGE.
const ROW_SHORTCUTS := [["shop", "HOME_SC_SHOP"], ["cards_exchange", "HOME_SC_CARDS_EXCHANGE"]]
## Win Streak track positions 1..5+ (values are rendered live from WinStreakService).
const TRACK_POSITIONS := 5
## Home action regions hidden while a modal (popup / Settings) is open (V03 K).
const MODAL_HIDDEN_REGIONS := ["LeftShortcutColumn", "RightShortcutColumn", "ActionRow", "WinStreakRewardTrack", "BottomNav"]

## Layered art regions (SB-M42-011), named by assets/ui/HOME_ASSET_MANIFEST.json
## layer_order. The owner reference image itself is never loaded or shipped.
const SCREEN_LAYERS := ["background.sky", "background.city_far", "background.city_mid", "background.street_foreground"]
const WORLD_LAYERS := ["central_world_and_environment", "characters"]

## World-stage placement, in reference pixels of a 1080x1154 stage (scaled by the stage
## unit). [node, center-x fraction of stage width, bottom-y fraction of stage height,
## height px]. Order inside each group = draw order (back to front).
const WORLD_GROUP := [
	["Art_neon", 0.50, 0.86, 280],
	["Art_arch", 0.50, 0.83, 900],
	["Art_arch_decor", 0.50, 0.30, 330],
	["Art_puddles", 0.50, 1.03, 300],
	["Art_keep_clean_sign", 0.70, 0.84, 165],
	["Art_cleaning_equipment", 0.31, 0.87, 160],
	["Art_hose", 0.67, 1.00, 120],
	["Art_platform_main", 0.50, 1.00, 430],
	["Art_wet_floor_sign", 0.74, 0.99, 145],
]
const CHARACTER_GROUP := [
	["Art_helper_alt", 0.29, 0.82, 185],
	["Art_helper_floor", 0.25, 1.00, 210],
	["Art_helper_cart", 0.77, 1.00, 210],
	["Art_scrubby", 0.50, 0.78, 590],
	["Art_bucket", 0.37, 1.02, 120],
	["Art_foam", 0.63, 1.02, 100],
]
const STAGE_REF := Vector2(1080, 1154)
## HOME-010 geometry (fractions of the texture): visible centre of the top walking
## surface (Scrubby's feet) and the stone base line.
const PLATFORM_FEET_Y := 0.40
const PLATFORM_TOP_Y := 0.24

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
var _external_modals: Dictionary = {}   ## source id (e.g. "settings") -> true while open
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
	_nodes["HomeLayout"].resized.connect(_apply_layout_mode)
	_nodes["BottomNav"].resized.connect(_layout_background)
	_apply_layout_mode()
	if _art == null:
		set_art_binder(HomeArtBinder.new())
	refresh()

## Bind the canonical AppState (app root). Re-renders.
func bind(app_state) -> void:
	_app = app_state
	if _built:
		refresh()

## SB-M42-017: bind ONLY owner-approved art (HomeArtBinder gate) onto the nodes the
## HomePresentationMap names. OWNER_RETIRED / OWNER_DISABLED entries have no node and are
## never loaded. Unapproved slugs keep the native placeholder (null).
func set_art_binder(binder) -> void:
	_art = binder
	if not _built:
		return
	for id in HomePresentationMap.ENTRIES:
		var e: Dictionary = HomePresentationMap.ENTRIES[id]
		if (e["nodes"] as Array).is_empty():
			continue
		var tex: Texture2D = _art.texture(String(e["slug"]))
		for n in e["nodes"]:
			HomePresentationMap.apply(_nodes[n], String(e["slot"]), tex)
	_layout_world()

func get_art_binder():
	return _art

func get_app_state():
	return _app

func get_region(region: String) -> Control:
	return _nodes.get(region)

## Presentation accounting: one row per HomePresentationMap entry with the concrete
## node(s), whether each node presents a texture and is visible. Retired/disabled rows
## carry no nodes.
func get_presentation_accounting() -> Array:
	var out: Array = []
	for id in HomePresentationMap.ENTRIES:
		var e: Dictionary = HomePresentationMap.ENTRIES[id]
		var nodes: Array = []
		for n in e["nodes"]:
			var node = _nodes.get(n)
			var tex: Texture2D = HomePresentationMap.presented(node, String(e["slot"]))
			nodes.append({"name": n, "exists": node != null, "texture": tex, "visible": node != null and node.is_visible_in_tree()})
		out.append({"id": id, "slug": e["slug"], "mode": e["mode"], "reason": e.get("reason", ""), "reuse_of": e.get("reuse_of", ""), "nodes": nodes})
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
	shade.color = Color(0.02, 0.06, 0.16, 0.12)
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
	_side_margins(hud, 18, 84, 0)
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

	var row := HBoxContainer.new()
	row.name = "ActionRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	layout.add_child(_reg(row))
	_build_action_row(row)

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
	# V03 J: the dock paints down through any bottom safe-area inset to the screen edge,
	# so no world/street strip ever shows beneath it.
	dock.expand_margin_bottom = 600
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

## V03 A: NARROW profile card (width only) with a pop-out portrait — the approved frame
## sits behind, the larger portrait draws in front and rises above the frame and the card
## (nothing clips it). Live name, rank badge with live level, Bot Parts as N/250 only.
## Scrub Bucks + Hearts on the right. No top Settings/menu entry (bottom nav only).
const PROFILE_CARD_WIDTH_FRACTION := 0.50
func _build_hud(hud: MarginContainer) -> void:
	var row := HBoxContainer.new()
	row.name = "HudRow"
	row.add_theme_constant_override("separation", 14)
	hud.add_child(row)

	var card := PanelContainer.new()
	card.name = "ProfileCard"
	card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(HomeStyle.CARD, HomeStyle.EDGE, 4, 30, 10, 4), 10, 8))
	row.add_child(_reg(card))
	var cardrow := HBoxContainer.new()
	cardrow.add_theme_constant_override("separation", 8)
	card.add_child(cardrow)

	var avatar := Control.new()
	avatar.name = "ProfileAvatar"
	avatar.custom_minimum_size = Vector2(150, 150)
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	avatar.clip_contents = false
	cardrow.add_child(_reg(avatar))
	var frame := HomeStyle.art("ProfileAvatarFrame")
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar.add_child(_reg(frame))
	# In front of the frame, larger than it, bottom-aligned inside the ring and rising
	# above its top edge.
	var portrait := HomeStyle.art("ProfilePortrait")
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.offset_left = -16
	portrait.offset_right = 16
	portrait.offset_top = -86
	portrait.offset_bottom = -54
	avatar.add_child(_reg(portrait))

	var info := VBoxContainer.new()
	info.name = "ProfileInfo"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 2)
	cardrow.add_child(info)
	var name_label := HomeStyle.label("", 40)
	name_label.name = "ProfileName"
	name_label.clip_text = true
	info.add_child(_reg(name_label))
	var rank_title := HomeStyle.label("", 26, HomeStyle.EDGE)
	rank_title.name = "ProfileRankTitle"
	rank_title.visible = false   # shown only when a canonical rank/title exists
	info.add_child(_reg(rank_title))
	var lvl_row := HBoxContainer.new()
	lvl_row.add_theme_constant_override("separation", 6)
	info.add_child(lvl_row)
	var rank := HomeStyle.art("ProfileRankBadge")
	rank.custom_minimum_size = Vector2(70, 64)
	lvl_row.add_child(_reg(rank))
	var lvl := HomeStyle.label("", 28)
	lvl.name = "ProfileLevel"
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lvl.set_anchors_preset(Control.PRESET_FULL_RECT)
	rank.add_child(_reg(lvl))
	var parts := UiProgressMeter.new("ProfileBotParts")
	parts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parts.caption.add_theme_font_size_override("font_size", 26)
	parts.caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	HomeStyle.style_meter(parts.bar, HomeStyle.GREEN, 24)
	lvl_row.add_child(_reg(parts))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var right := VBoxContainer.new()
	right.name = "HudCurrencies"
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 10)
	row.add_child(right)
	for id in ["ScrubBucksChip", "HeartsChip"]:
		var chip := UiValueChip.new(id)
		chip.set_icon_size(72)
		chip.set_value_size(40)
		chip.custom_minimum_size = Vector2(300, UiTokens.TOUCH_MIN)
		chip.set_panel_style(HomeStyle.pad(HomeStyle.box(HomeStyle.NAVY, HomeStyle.GLOW, 4, 44, 8), 12, 2))
		right.add_child(_reg(chip))

# ---------------------------------------------------------- Gift Meter ----

func _build_gift_meter(gm: MarginContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "GiftMeterPanel"
	panel.add_theme_stylebox_override("panel", HomeStyle.panel(HomeStyle.PANEL, HomeStyle.GLOW, 34, 12, 6))
	gm.add_child(_reg(panel))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var emblem := HomeStyle.art("GiftEmblem")
	emblem.custom_minimum_size = Vector2(100, 100)
	row.add_child(_reg(emblem))
	# V03 B: the live ratio sits over the thick meter; no long caption line.
	var meter := UiProgressMeter.new("GiftMeterBar")
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	HomeStyle.style_meter(meter.bar, HomeStyle.GOLD, 52)
	meter.caption.add_theme_font_size_override("font_size", 34)
	meter.caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter.caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meter.caption.reparent(meter.bar, false)
	meter.caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_child(_reg(meter))
	var crate := HomeStyle.art("GiftCrate")
	crate.custom_minimum_size = Vector2(100, 100)
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
		if spec[0] == "Art_arch_decor":
			# V03 D: the live title plate is set INTO the arch head (drawn over the stone,
			# under the leafy crown), not a free-floating capsule.
			var banner := PanelContainer.new()
			banner.name = "AreaBanner"
			banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var plate := HomeStyle.pad(HomeStyle.box(Color(0.04, 0.22, 0.28, 0.90), Color(0.36, 0.86, 0.78), 3, 18, 4, 3), 22, 2)
			banner.add_theme_stylebox_override("panel", plate)
			world_g.add_child(_reg(banner))
			var bcol := VBoxContainer.new()
			bcol.add_theme_constant_override("separation", -6)
			bcol.mouse_filter = Control.MOUSE_FILTER_IGNORE
			banner.add_child(bcol)
			var title := HomeStyle.label("", 40, Color(0.62, 1.0, 0.92))
			title.name = "AreaTitle"
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bcol.add_child(_reg(title))
			var number := HomeStyle.label("", 26, Color(0.80, 1.0, 0.95))
			number.name = "AreaNumber"
			number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bcol.add_child(_reg(number))
	var chars: Control = _nodes["Layer_characters"]
	for spec in CHARACTER_GROUP:
		chars.add_child(_reg(HomeStyle.art(spec[0])))

## Lay out every world node inside the stage that spans the whole MainWorldArea (behind
## the shortcut cards), then re-compose the screen background around it.
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
		var aspect := _aspect(n)
		var w := minf(h * aspect, W * 0.96)
		h = w / aspect
		n.size = Vector2(w, h)
		n.position = Vector2(W * float(spec[1]) - w * 0.5, H * float(spec[2]) - h)
	# ONE platform (HOME-010). The portal base stands on the same plane: it sits at the
	# platform's top rim, so the platform reads in front of / within the portal base.
	var plat: TextureRect = _nodes["Art_platform_main"]
	var arch: TextureRect = _nodes["Art_arch"]
	var arch_bottom := plat.position.y + plat.size.y * 0.50
	var arch_h := minf(arch_bottom - H * 0.04, 1000.0 * s * 1.25)
	arch.size = Vector2(arch_h * _aspect(arch), arch_h)
	if arch.size.x > W * 0.90:
		arch.size = Vector2(W * 0.90, W * 0.90 / _aspect(arch))
	arch.position = Vector2(W * 0.5 - arch.size.x * 0.5, arch_bottom - arch.size.y)
	var neon: TextureRect = _nodes["Art_neon"]
	neon.position.y = arch_bottom - neon.size.y - arch.size.y * 0.04
	var decor: TextureRect = _nodes["Art_arch_decor"]
	decor.size = Vector2(arch.size.x * 1.02, arch.size.x * 1.02 / _aspect(decor))
	decor.position = Vector2(arch.position.x + (arch.size.x - decor.size.x) * 0.5, arch.position.y - decor.size.y * 0.22)
	# Title plate set into the arch head, overlapping the lower edge of the crown.
	var banner: Control = _nodes["AreaBanner"]
	banner.size = Vector2.ZERO
	var bmin := banner.get_combined_minimum_size()
	banner.size = bmin
	banner.position = Vector2(W * 0.5 - bmin.x * 0.5, decor.position.y + decor.size.y * 0.62)
	# Scrubby's feet stand directly on the top walking surface of HOME-010.
	var sc: TextureRect = _nodes["Art_scrubby"]
	sc.position.y = plat.position.y + plat.size.y * PLATFORM_FEET_Y - sc.size.y
	_layout_background()

func _aspect(t: TextureRect) -> float:
	if t.texture != null and t.texture.get_height() > 0:
		return float(t.texture.get_width()) / float(t.texture.get_height())
	return 1.0

## V03 C: screen background composed AROUND the world: the mid city stands behind the
## portal (buildings left, right and above it), the far city rises behind it, the street
## foreground is raised so its pavement starts right above the nav dock and runs up to the
## platform base. Uniform scaling only (no stretched proportions).
func _layout_background() -> void:
	var bg: Control = _nodes.get("Background")
	var world: Control = _nodes.get("MainWorldArea")
	var nav: Control = _nodes.get("BottomNav")
	if bg == null or bg.size.x <= 0 or world == null or world.size.y <= 0:
		return
	var W := bg.size.x
	var H := bg.size.y
	var wr := Rect2(world.global_position - bg.global_position, world.size)
	var nav_top: float = (nav.global_position.y - bg.global_position.y) if nav != null and nav.is_visible_in_tree() else H
	var sky: TextureRect = _nodes["Layer_background.sky"]
	sky.position = Vector2.ZERO
	sky.size = bg.size
	# Street: pavement (bottom ~27% of HOME-004) spans nav top up to the platform base.
	var street: TextureRect = _nodes["Layer_background.street_foreground"]
	var pave := maxf(nav_top - (wr.end.y - wr.size.y * 0.06), 160.0)
	var sh := maxf(pave / 0.27, W / _aspect(street))
	street.size = Vector2(sh * _aspect(street), sh)
	street.position = Vector2((W - street.size.x) * 0.5, nav_top + 40.0 - sh)
	# Mid city: base behind the platform, wide enough to show buildings beside the portal.
	var mid: TextureRect = _nodes["Layer_background.city_mid"]
	var mh := maxf(wr.size.y * 0.72, W * 1.7 / _aspect(mid))
	mid.size = Vector2(mh * _aspect(mid), mh)
	mid.position = Vector2((W - mid.size.x) * 0.5, wr.end.y - wr.size.y * 0.10 - mh)
	# Far city: rises above/behind the portal crown.
	var far: TextureRect = _nodes["Layer_background.city_far"]
	var fh := mh * 1.35
	far.size = Vector2(fh * _aspect(far), fh)
	far.position = Vector2((W - far.size.x) * 0.5, mid.position.y + mh * 0.70 - fh)

# ------------------------------------------------------------ shortcuts ----

func _make_shortcut(spec: Array) -> UiShortcutButton:
	var b := UiShortcutButton.new(spec[0], UiText.t(spec[1]))
	HomeStyle.style_card_button(b)
	b.add_theme_font_size_override("font_size", 26)
	var id: String = spec[0]
	b.pressed.connect(func():
		shortcut_requested.emit(id)
		open_popup(id))
	_nodes["Shortcut_" + id] = b
	return b

func _build_shortcuts(column: VBoxContainer, specs: Array) -> void:
	for spec in specs:
		column.add_child(_make_shortcut(spec))

# ------------------------------------------------------ action row / Play ----

## V03 G/H: SHOP | PLAY | CARDS EXCHANGE. PLAY is a smaller green native CTA with a live
## label, a native white play triangle and a compact live frontier subtitle; the hit
## region is the visible CTA.
const PLAY_SIZE := Vector2(470, 150)
const ROW_CARD_SIZE := Vector2(214, 150)
func _build_action_row(row: HBoxContainer) -> void:
	var shop := _make_shortcut(ROW_SHORTCUTS[0])
	shop.custom_minimum_size = ROW_CARD_SIZE
	shop.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(shop)
	var play := Button.new()
	play.name = "PlayButton"
	play.text = UiText.t("HOME_PLAY")
	play.custom_minimum_size = PLAY_SIZE
	play.focus_mode = Control.FOCUS_NONE
	play.add_theme_font_size_override("font_size", 76)
	HomeStyle.style_play_button(play)
	play.add_theme_constant_override("outline_size", 12)
	for st in ["normal", "hover", "pressed", "disabled"]:
		var sb: StyleBoxFlat = play.get_theme_stylebox(st)
		sb.content_margin_bottom = 40
		sb.content_margin_right = 96
		sb.content_margin_left = 24
	play.pressed.connect(func():
		if not play.disabled:
			play_requested.emit())
	row.add_child(_reg(play))
	var tri := PlayTriangle.new()
	tri.name = "PlayTriangle"
	tri.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	tri.offset_left = -104
	tri.offset_right = -46
	tri.offset_top = -46
	tri.offset_bottom = 12
	play.add_child(_reg(tri))
	var sub := HomeStyle.label("", 28, HomeStyle.SUBTITLE, 8)
	sub.name = "PlaySubtitle"
	sub.add_theme_color_override("font_outline_color", HomeStyle.GREEN_EDGE)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sub.offset_top = -54
	sub.offset_bottom = -16
	play.add_child(_reg(sub))
	var cards := _make_shortcut(ROW_SHORTCUTS[1])
	cards.custom_minimum_size = ROW_CARD_SIZE
	cards.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(cards)

## Native white play triangle (no texture).
class PlayTriangle extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var pts := PackedVector2Array([r.position + Vector2(r.size.x * 0.12, 0), r.position + Vector2(r.size.x, r.size.y * 0.5), r.position + Vector2(r.size.x * 0.12, r.size.y)])
		draw_colored_polygon(pts, Color(1, 1, 1))
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

# ---------------------------------------------------- Win Streak track ----

## V03 I: thin track — badge with the live streak, progress line, five gift objects and
## ONLY the live SB value under each (1/5/10/25/100): no "+", no per-step currency icon,
## no per-step WIN copy. Current step highlighted, reached full, future dimmed.
func _build_track(track: MarginContainer) -> void:
	var panel := PanelContainer.new()
	panel.name = "TrackPanel"
	panel.add_theme_stylebox_override("panel", HomeStyle.panel(HomeStyle.PANEL, HomeStyle.GLOW, 28, 12, 4))
	track.add_child(_reg(panel))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var badge := HomeStyle.art("TrackBadge")
	badge.custom_minimum_size = Vector2(96, 96)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_reg(badge))
	var streak := HomeStyle.label("", 34)
	streak.name = "TrackStreakValue"
	streak.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	streak.set_anchors_preset(Control.PRESET_FULL_RECT)
	streak.offset_top = 8
	badge.add_child(_reg(streak))
	var area := Control.new()
	area.name = "TrackSteps"
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.custom_minimum_size = Vector2(0, 112)
	row.add_child(_reg(area))
	var line := ProgressBar.new()
	line.name = "TrackProgress"
	line.show_percentage = false
	line.max_value = TRACK_POSITIONS
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	HomeStyle.style_meter(line, Color(0.55, 0.95, 0.20), 14)
	line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	line.offset_top = 32
	line.offset_bottom = 46
	line.offset_left = 24
	line.offset_right = -24
	area.add_child(_reg(line))
	var steps := HBoxContainer.new()
	steps.set_anchors_preset(Control.PRESET_FULL_RECT)
	steps.add_theme_constant_override("separation", 4)
	steps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(steps)
	for i in range(TRACK_POSITIONS):
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_theme_constant_override("separation", -4)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		steps.add_child(col)
		var gift := HomeStyle.art("TrackGift%d" % (i + 1))
		gift.custom_minimum_size = Vector2(0, 76)
		col.add_child(_reg(gift))
		var value := HomeStyle.label("", 30)
		value.name = "TrackStep%d" % (i + 1)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(_reg(value))

# ----------------------------------------------------------- bottom nav ----

## Bottom navigation dock — the ONLY Settings entry on Home. Only HOME and SETTINGS have
## V1 destinations; the other tabs are shown disabled (later milestones) — never faked.
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
		b.custom_minimum_size = Vector2(0, 160)
		b.add_theme_font_size_override("font_size", 26)
		b.focus_mode = Control.FOCUS_NONE
		HomeStyle.style_nav_button(b, id == "home")
		for st in ["normal", "hover", "pressed", "disabled"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(st)
			sb.content_margin_top = 104
		var icon := HomeStyle.art("NavIcon_" + id)
		icon.set_anchors_preset(Control.PRESET_CENTER_TOP)
		icon.offset_left = -46
		icon.offset_right = 46
		icon.offset_top = 8
		icon.offset_bottom = 100
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
	var vw := get_viewport_rect().size.x
	(_nodes["ProfileCard"] as Control).custom_minimum_size.x = clampf(vw * PROFILE_CARD_WIDTH_FRACTION, 460.0, 620.0)
	_apply_shortcut_columns(mode)
	_layout_world.call_deferred()

## SB-M42-012: shortcut card width scales with the world width so the central world keeps
## >= CENTER_MIN_FRACTION; cards never drop below TOUCH_MIN; card height follows the
## available world height so the three cards frame the hero with an even rhythm.
const CENTER_MIN_FRACTION := 0.4
const COLUMN_CARDS := 3
func _apply_shortcut_columns(_mode: int) -> void:
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
	var col_w: float = clampf(width * (1.0 - CENTER_MIN_FRACTION) * 0.5 - UiTokens.SPACE_SM, UiTokens.TOUCH_MIN, 226.0)
	var card_h: float = clampf((height - (COLUMN_CARDS - 1) * UiTokens.SPACE_MD) / COLUMN_CARDS, UiTokens.TOUCH_MIN, 220.0)
	var vgap: int = int(clampf((height - COLUMN_CARDS * card_h) / (COLUMN_CARDS + 1), UiTokens.SPACE_XS, 64))
	for side in ["LeftShortcutColumn", "RightShortcutColumn"]:
		var col: VBoxContainer = _nodes[side]
		col.add_theme_constant_override("separation", vgap)
		for b in col.get_children():
			(b as Control).custom_minimum_size = Vector2(col_w, card_h)

func get_layout_mode() -> int:
	return ResponsiveLayout.get_layout_mode(get_viewport_rect().size)

# ------------------------------------------------------------- modal ----

## V03 K: deterministic modal state. `source` is an external overlay id (the app root
## passes "settings" for the Settings panel); Home popups drive it internally. While any
## source is active, every Home action region is hidden (not drawn, no pointer/keyboard
## input); when the last one closes they are restored exactly.
func set_modal_active(source: String, active: bool) -> void:
	if active:
		_external_modals[source] = true
	else:
		_external_modals.erase(source)
	_sync_modal()

func is_modal_active() -> bool:
	if not _external_modals.is_empty():
		return true
	for pid in _popups:
		if (_popups[pid] as Control).visible:
			return true
	return false

func _sync_modal() -> void:
	if not _built:
		return
	var modal := is_modal_active()
	for region in MODAL_HIDDEN_REGIONS:
		(_nodes[region] as Control).visible = not modal
	_apply_layout_mode()

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
	# SB-M42-019 / V03 A: Bot Parts toward the next 250-part robot (canonical
	# RobotUnlockService / wallet), never XP — shown ONLY as the live ratio. When a robot
	# is unlockable the bar turns gold (no extra copy).
	var parts: UiProgressMeter = _nodes["ProfileBotParts"]
	parts.set_progress(_vm["bot_parts"], _vm["bot_parts_target"],
		UiText.t("HOME_RATIO", [UiText.num(_vm["bot_parts"]), UiText.num(_vm["bot_parts_target"])]))
	HomeStyle.style_meter(parts.bar, HomeStyle.GOLD if _vm["robot_can_unlock"] else HomeStyle.GREEN, 24)
	# SB-M42-018: top currency is Scrub Bucks (banknote icon) with the live canonical
	# wallet balance. No coin/Star authority.
	var sb: UiValueChip = _nodes["ScrubBucksChip"]
	sb.set_tag(UiText.t("HOME_CURRENCY_SB"))
	sb.set_value(UiText.num(_vm["scrub_bucks"]))
	var hearts: UiValueChip = _nodes["HeartsChip"]
	hearts.set_value("%d/%d" % [_vm["hearts"], _vm["hearts_max"]])
	hearts.set_sub("" if _vm["hearts"] >= _vm["hearts_max"] else _mmss(_vm["heart_seconds_to_next"]))
	# SB-M42-020 / V03 B: canonical Gift Meter (fed only by Win Streak SB inside
	# GiftMeterService), shown only as the live N/1000 ratio. No event timer / Event Points.
	(_nodes["GiftMeterBar"] as UiProgressMeter).set_progress(_vm["gift_progress"], _vm["gift_cycle_max"],
		UiText.t("HOME_RATIO", [UiText.num(_vm["gift_progress"]), UiText.num(_vm["gift_cycle_max"])]))
	var gbadge: Label = _nodes["GiftClaimableBadge"]
	gbadge.text = str(_vm["gift_claimable"])
	gbadge.visible = _vm["gift_claimable"] > 0
	# Area plate: live/localizable title + number (presentational V1 defaults through the
	# localization seam; no area progression truth exists yet).
	(_nodes["AreaTitle"] as Label).text = UiText.t("HOME_AREA_TITLE")
	(_nodes["AreaNumber"] as Label).text = UiText.t("HOME_AREA_NUMBER", [1])
	# SB-M42-023: Win Streak SB track: position 1/2/3/4/5+ pays 1/5/10/25/100 SB
	# (WinStreakService, owner-locked). Current step gold, reached white, future dimmed.
	(_nodes["TrackStreakValue"] as Label).text = UiText.num(_vm["win_streak"])
	(_nodes["TrackProgress"] as ProgressBar).value = clampi(_vm["win_streak"], 0, TRACK_POSITIONS)
	for step in _vm["win_streak_track"]:
		var value: Label = _nodes["TrackStep%d" % step["position"]]
		value.text = UiText.num(step["sb"])
		value.add_theme_color_override("font_color", HomeStyle.GOLD if step["current"] else HomeStyle.TEXT)
		value.modulate.a = 1.0 if step["reached"] or step["current"] else 0.6
		var gift: Control = _nodes["TrackGift%d" % step["position"]]
		gift.modulate = Color(1, 1, 1, 1) if step["reached"] or step["current"] else Color(0.72, 0.78, 0.92, 0.80)
	(_nodes["Shortcut_win_streak"] as UiShortcutButton).set_badge(_vm["win_streak"])
	(_nodes["Shortcut_gift_bar"] as UiShortcutButton).set_badge(_vm["gift_claimable"])
	(_nodes["Shortcut_cards_exchange"] as UiShortcutButton).set_badge(_vm["cards_duplicates"])
	# SB-M42-024: Daily badge = 1 when today's login reward is claimable.
	(_nodes["Shortcut_daily"] as UiShortcutButton).set_badge(0 if _vm["daily_claimed_today"] else 1)
	for id in LEFT_SHORTCUTS + RIGHT_SHORTCUTS + ROW_SHORTCUTS:
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
		p.z_index = 2
		p.action_pressed.connect(_on_popup_action.bind(id))
		p.closed.connect(_sync_modal)
		add_child(p)
		_popups[id] = p
	# One Home modal at a time: opening one closes any other.
	for pid in _popups:
		if pid != id and (_popups[pid] as Control).visible:
			(_popups[pid] as Control).hide()
	var popup: HomePopup = _popups[id]
	move_child(popup, get_child_count() - 1)
	popup.show()
	_render_popup(id)
	_sync_modal()
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

## SB-M42-003: the ONE CTA launches only the canonical progression frontier. The button
## reads PLAY; the live subtitle carries the frontier: no completed level -> "LEVEL N";
## otherwise "CONTINUE · LEVEL N". A frontier without catalog content is shown honestly
## and disabled (no fallback, no picker).
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
