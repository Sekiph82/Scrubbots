extends Control
## HomeScreen — res://scenes/ui/home/home_screen.tscn (preload this script; AL-001).
##
## M42 production Home. V04 (coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_
## BACKGROUND.md) supersedes the earlier layered composition: the world is ONE complete
## owner-approved background per world (HomeWorldCatalog; World 01 = HOME-120 with the
## city, portal, baked WHISPERING PARK / AREA 1 sign, platform, props and helper bots).
## Only Scrubby is a separate runtime layer, placed by the world's canonical 1080x2160
## anchor contract. Everything else is native Godot UI:
##
##   HomeScreen (Home theme: bold face + navy outline)
##   ├── Background          world canvas (clipped above the ad slot)
##   │     ├── WorldBackground   HOME-120, uniform scale, never stretched
##   │     └── Layer_characters/Art_scrubby   feet on the baked platform
##   └── SafeAreaRoot/MarginContainer/Content/HomeLayout (VBox)
##       ├── TopCurrencyHUD      narrow profile card (portrait in front of its frame,
##       │                       bottom-anchored; level badge + thick Bot Parts N/250 bar)
##       │                       · Scrub Bucks chip + (+) · Hearts chip + (+)
##       ├── GiftMeter           emblem · thick gold meter with only N/1000 · crate
##       ├── ActionHost/HomeActionLayer   (hidden as ONE layer while a modal is open)
##       │     ├── WorldMargin/MainWorldArea   SHOP, COLLECTION | (world) | TASKS, DAILY
##       │     ├── PlayButton          centred standalone CTA (+ compact StatusLabel pill)
##       │     ├── WinStreakRewardTrack  thin track: 5 gifts · 1/5/10/25/100
##       │     └── BottomNav           5 icon tabs, HOME selected
##       └── AdBannerSlot        persistent, empty integration seam for a future ad SDK;
##                               collapsible (future No-Ads entitlement)
##
## Every approved ART entry is accounted in HomePresentationMap. The screen owns NO
## durable truth: it reads the canonical AppState and only emits intents.

signal play_requested
signal settings_requested
signal nav_requested(id: String)
signal shortcut_requested(id: String)
## V04: HUD (+) buttons — intent only (no price/product/transaction is implemented here).
signal scrub_bucks_purchase_requested
signal hearts_purchase_requested

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
const HomeWorldCatalog = preload("res://scripts/ui/home/home_world_catalog.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

## Popups with a V1 Home destination. Only DAILY is a Home panel in V04; Gifts and Cards
## Exchange popups remain reachable through open_popup() as seams for their owning flows
## (automatic rewards / Collection).
const LIVE_SHORTCUTS := ["gift_bar", "cards_exchange", "daily"]

## V04: exactly four Home panels (left SHOP / COLLECTION, right TASKS / DAILY).
const LEFT_SHORTCUTS := [["shop", "HOME_SC_SHOP"], ["collection", "HOME_SC_COLLECTION"]]
const RIGHT_SHORTCUTS := [["tasks", "HOME_SC_TASKS"], ["daily", "HOME_SC_DAILY"]]
## Panel size system (one size for all four) and icon boxes. V03 drew each icon fitted
## into ~206x164 inside its card; TASKS/DAILY keep that exact box, SHOP/COLLECTION are
## enlarged 1.2x (owner V04 43-46). Icons stand on the label band and may rise above.
const PANEL_SIZE := Vector2(210, 156)
const V03_ICON_BOX := Vector2(206, 164)
const ICON_SCALE := {"shop": 1.2, "collection": 1.2, "tasks": 1.0, "daily": 1.0}
const PANEL_EDGE_MARGIN := 26
## Win Streak track positions 1..5+ (values are rendered live from WinStreakService).
const TRACK_POSITIONS := 5
## Ad slot reservation: a banner-proportion placeholder (width * 50/320) clamped to a
## sane band. Presentation reservation only — not a provider contract.
const AD_SLOT_RATIO := 50.0 / 320.0
const AD_SLOT_MIN_H := 100.0
const AD_SLOT_MAX_H := 180.0

## HOME-026 texture facts used by the World anchor contract (texture pixels of the
## 1158x1358 approved Scrubby): alpha>128 visible bbox and the soles' ground line (the
## brush bristles reach 16 px lower and rest on the platform).
const SCRUBBY_VISIBLE_BBOX := Rect2(27, 7, 1130, 1327)
const SCRUBBY_FEET_Y := 1318.0
## World canonical rows used to keep the composition readable: the owner's platform-top
## visual region (y 1240..1337, where Scrubby stands) must stay above the Play CTA (on
## short screens Play may overlap the lower stone steps); the baked sign's top should
## stay below the Gift Meter.
const PLATFORM_BOTTOM_Y := 1345.0
const SIGN_TOP_Y := 653.0

const BG01 := Color(0.125, 0.145, 0.2, 1.0)   ## Midnight Slate #202533.

var _app = null
var _built := false
var _nodes: Dictionary = {}   ## region name -> Control
var _launch: Dictionary = {}
var _vm: Dictionary = {}
var _art = null
var _popups: Dictionary = {}   ## id -> HomePopup (presentation only)
var _external_modals: Dictionary = {}   ## source id (e.g. "settings") -> true while open
var _tick: Timer
var _world: Dictionary = {}
## Current canonical->screen transform of the world (scale, offset) for tests/evidence.
var _world_scale := 1.0
var _world_offset := Vector2.ZERO
var _ad_slot_enabled := true

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
	_nodes["HomeLayout"].resized.connect(_apply_layout_mode)
	_nodes["PlayButton"].resized.connect(_queue_world)
	_apply_layout_mode()
	if _art == null:
		set_art_binder(HomeArtBinder.new())
	refresh()

func bind(app_state) -> void:
	_app = app_state
	if _built:
		refresh()

## SB-M42-017: bind ONLY owner-approved art (HomeArtBinder gate) onto the nodes the
## HomePresentationMap names. Retired/disabled entries have no node and are never loaded.
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
	for id in LEFT_SHORTCUTS + RIGHT_SHORTCUTS:
		var b: UiShortcutButton = _nodes["Shortcut_" + id[0]]
		b.set_icon_box(b.get_icon_box())
	_queue_world()

func get_art_binder():
	return _art

func get_app_state():
	return _app

func get_region(region: String) -> Control:
	return _nodes.get(region)

func get_world() -> Dictionary:
	return _world.duplicate(true)

## Canonical world point -> HomeScreen-local point (current layout).
func world_to_screen(p: Vector2) -> Vector2:
	return p * _world_scale + _world_offset

func get_world_transform() -> Dictionary:
	return {"scale": _world_scale, "offset": _world_offset}

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

## Ordered art layers: the single world background, then the character layer.
func get_art_layers() -> Array:
	return [_nodes["WorldBackground"], _nodes["Layer_characters"]]

# ------------------------------------------------------------------ build ----

func _build() -> void:
	if _built:
		return
	_built = true
	_world = HomeWorldCatalog.world()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = HomeStyle.make_theme()

	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = BG01
	bg.clip_contents = true
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_nodes["Background"] = bg
	var wb := HomeStyle.art("WorldBackground")
	wb.stretch_mode = TextureRect.STRETCH_SCALE   # sized to the texture aspect by _layout_world
	bg.add_child(_reg(wb))
	# Wide (tablet) canvases: mirrored continuation of the same world image fills the
	# narrow side bands beyond the 1:2 world instead of flat BG01 bars.
	for side in ["WorldEdgeLeft", "WorldEdgeRight"]:
		var edge := HomeStyle.art(side)
		edge.stretch_mode = TextureRect.STRETCH_SCALE
		edge.flip_h = true
		edge.visible = false
		bg.add_child(_reg(edge))
	var chars := Control.new()
	chars.name = "Layer_characters"
	chars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(chars)
	_nodes["Layer_characters"] = chars
	var sc := HomeStyle.art("Art_scrubby")
	sc.stretch_mode = TextureRect.STRETCH_SCALE   # sized to the texture aspect by _layout_world
	chars.add_child(_reg(sc))

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
	_side_margins(hud, 18, 64, 0)
	layout.add_child(_reg(hud))
	var gm := MarginContainer.new()
	gm.name = "GiftMeter"
	_side_margins(gm, 34, 0, 0)
	layout.add_child(_reg(gm))

	# One action layer hidden as a unit by the modal state; its host keeps the layout
	# slot so nothing else moves while a modal is open.
	var host := Control.new()
	host.name = "ActionHost"
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(_reg(host))
	var actions := VBoxContainer.new()
	actions.name = "HomeActionLayer"
	actions.set_anchors_preset(Control.PRESET_FULL_RECT)
	actions.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	host.add_child(_reg(actions))

	var wm := MarginContainer.new()
	wm.name = "WorldMargin"
	wm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side_margins(wm, PANEL_EDGE_MARGIN, PANEL_TOP, 0)
	actions.add_child(_reg(wm))
	var world := HBoxContainer.new()
	world.name = "MainWorldArea"
	world.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wm.add_child(_reg(world))
	for region in ["LeftShortcutColumn", "CenterScrubbyArea", "RightShortcutColumn"]:
		var c: Control
		if region == "CenterScrubbyArea":
			c = Control.new()
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			var v := VBoxContainer.new()
			v.add_theme_constant_override("separation", PANEL_GAP)   # room for the next icon's pop-out
			v.alignment = BoxContainer.ALIGNMENT_BEGIN
			c = v
		c.name = region
		world.add_child(_reg(c))

	_build_play(actions)
	var track := MarginContainer.new()
	track.name = "WinStreakRewardTrack"
	_side_margins(track, 22, 0, 0)
	actions.add_child(_reg(track))

	var nav := PanelContainer.new()
	nav.name = "BottomNav"
	var dock := HomeStyle.box(HomeStyle.NAVY, HomeStyle.GLOW, 0, 0, 14)
	dock.border_width_top = 5
	dock.corner_radius_top_left = 34
	dock.corner_radius_top_right = 34
	# Paints down through any bottom inset when the ad slot is collapsed (no world strip).
	dock.expand_margin_bottom = 600
	HomeStyle.pad(dock, 14, 14)
	nav.add_theme_stylebox_override("panel", dock)
	actions.add_child(_reg(nav))

	var ad := PanelContainer.new()
	ad.name = "AdBannerSlot"
	var adsb := HomeStyle.box(Color(0.03, 0.05, 0.10), Color(0.16, 0.26, 0.42), 0, 0, 0)
	adsb.border_width_top = 2
	adsb.expand_margin_bottom = 600   # covers the bottom inset down to the screen edge
	ad.add_theme_stylebox_override("panel", adsb)
	ad.mouse_filter = Control.MOUSE_FILTER_PASS
	layout.add_child(_reg(ad))
	var ad_mount := Control.new()
	ad_mount.name = "AdMount"   # the future ad SDK view attaches here; empty in V04
	ad_mount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ad.add_child(_reg(ad_mount))

	_build_hud(hud)
	_build_gift_meter(gm)
	_build_shortcuts(_nodes["LeftShortcutColumn"], LEFT_SHORTCUTS)
	_build_shortcuts(_nodes["RightShortcutColumn"], RIGHT_SHORTCUTS)
	_build_track(track)
	_build_bottom_nav(nav)

static func _side_margins(m: MarginContainer, h: int, top: int, bottom: int) -> void:
	m.add_theme_constant_override("margin_left", h)
	m.add_theme_constant_override("margin_right", h)
	m.add_theme_constant_override("margin_top", top)
	m.add_theme_constant_override("margin_bottom", bottom)

func _reg(n: Control) -> Control:
	_nodes[String(n.name)] = n
	return n

# ------------------------------------------------------------- top HUD ----

## Narrow profile card: the larger portrait stands in FRONT of the approved frame with its
## visible bottom resting on the ring's inner bottom (frame side/bottom segments stay
## visible) and pops out above the ring. Level badge + thick Bot Parts bar with the live
## N/250 ratio centred inside. No top Settings/menu entry (bottom nav only).
const PROFILE_CARD_WIDTH_FRACTION := 0.50
const AVATAR := 150.0
## HOME-034 ring inner bottom (fraction of the frame) and HOME-027 visible bbox rows
## (fractions of the 1254 px portrait texture).
const FRAME_INNER_BOTTOM := 0.83
const PORTRAIT_VIS_TOP := 189.0 / 1254.0
const PORTRAIT_VIS_BOTTOM := 1135.0 / 1254.0
const PORTRAIT_SCALE := 1.3
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
	avatar.custom_minimum_size = Vector2(AVATAR, AVATAR)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cardrow.add_child(_reg(avatar))
	var frame := HomeStyle.art("ProfileAvatarFrame")
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	avatar.add_child(_reg(frame))
	var p := AVATAR * PORTRAIT_SCALE
	var portrait := HomeStyle.art("ProfilePortrait")
	portrait.position = Vector2((AVATAR - p) * 0.5, AVATAR * FRAME_INNER_BOTTOM - PORTRAIT_VIS_BOTTOM * p)
	portrait.size = Vector2(p, p)
	avatar.add_child(_reg(portrait))

	var info := VBoxContainer.new()
	info.name = "ProfileInfo"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 4)
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
	lvl_row.name = "ProfileLevelRow"
	lvl_row.add_theme_constant_override("separation", -10)   # badge overlaps the bar end
	info.add_child(_reg(lvl_row))
	var rank := HomeStyle.art("ProfileRankBadge")
	rank.custom_minimum_size = Vector2(74, 68)
	rank.z_index = 1
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
	HomeStyle.style_meter(parts.bar, HomeStyle.GREEN, 42)
	_center_caption_in_bar(parts, 28)
	lvl_row.add_child(_reg(parts))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	var right := VBoxContainer.new()
	right.name = "HudCurrencies"
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 12)
	row.add_child(right)
	for spec in [["ScrubBucksChip", "ScrubBucksPlus", scrub_bucks_purchase_requested], ["HeartsChip", "HeartsPlus", hearts_purchase_requested]]:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 6)
		right.add_child(line)
		var chip := UiValueChip.new(spec[0])
		chip.set_icon_size(70)
		chip.set_icon_pop(1.4)   # icon drawn in front of / overhanging its chip panel
		chip.set_value_size(40)
		chip.custom_minimum_size = Vector2(250, UiTokens.TOUCH_MIN)
		var csb := HomeStyle.pad(HomeStyle.box(HomeStyle.NAVY, HomeStyle.GLOW, 4, 44, 8), 14, 2)
		csb.content_margin_left = 18
		chip.set_panel_style(csb)
		line.add_child(_reg(chip))
		var plus := Button.new()
		plus.name = spec[1]
		plus.text = "+"
		plus.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN)
		plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		plus.focus_mode = Control.FOCUS_NONE
		plus.add_theme_font_size_override("font_size", 60)
		for st in ["normal", "hover", "pressed"]:
			var s := HomeStyle.box(HomeStyle.GREEN if st != "pressed" else HomeStyle.GREEN_PRESSED, HomeStyle.GREEN_EDGE, 4, 44, 6, 4)
			s.content_margin_bottom = 8
			plus.add_theme_stylebox_override(st, s)
		plus.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		plus.add_theme_constant_override("outline_size", 10)
		plus.add_theme_color_override("font_outline_color", HomeStyle.GREEN_EDGE)
		var sig: Signal = spec[2]
		plus.pressed.connect(func(): sig.emit())
		line.add_child(_reg(plus))

## Put a meter's live caption inside (centred over) its bar.
static func _center_caption_in_bar(meter: UiProgressMeter, font: int) -> void:
	meter.caption.add_theme_font_size_override("font_size", font)
	meter.caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter.caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meter.caption.clip_text = false
	meter.caption.reparent(meter.bar, false)
	meter.caption.set_anchors_preset(Control.PRESET_FULL_RECT)

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
	emblem.custom_minimum_size = Vector2(112, 112)
	row.add_child(_reg(emblem))
	# Live ratio over the thick meter; no long caption, no event timer / Event Points.
	var meter := UiProgressMeter.new("GiftMeterBar")
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	HomeStyle.style_meter(meter.bar, HomeStyle.GOLD, 52)
	_center_caption_in_bar(meter, 34)
	row.add_child(_reg(meter))
	var crate := HomeStyle.art("GiftCrate")
	crate.custom_minimum_size = Vector2(112, 112)
	row.add_child(_reg(crate))
	var count := HomeStyle.label("", 28)
	count.name = "GiftClaimableBadge"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.add_theme_stylebox_override("normal", HomeStyle.box(Color(0.95, 0.55, 0.05), Color(1, 1, 1), 3, 24, 0))
	count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count.offset_left = -48
	count.offset_top = -48
	count.offset_right = 4
	count.offset_bottom = 4
	crate.add_child(_reg(count))

# ---------------------------------------------------------- world canvas ----

func _queue_world() -> void:
	_layout_world.call_deferred()

## Place the single world background and Scrubby. Uniform scale s + offset map the
## canonical 1080x2160 world onto the canvas above the ad slot:
##   s covers the canvas width and height, the baked platform's bottom stays above the
##   Play CTA, the baked sign's top stays below the Gift Meter (wide/tablet screens then
##   show BG01 at the far sides rather than hiding the sign or the platform).
func _layout_world() -> void:
	if not _built or _world.is_empty() or size.x <= 0.0:
		return
	var bg: Control = _nodes["Background"]
	var ad: Control = _nodes["AdBannerSlot"]
	var canvas_h: float = (ad.global_position.y - global_position.y) if ad.is_visible_in_tree() else size.y
	bg.position = Vector2.ZERO
	bg.size = Vector2(size.x, canvas_h)
	(_nodes["Layer_characters"] as Control).size = bg.size
	var C: Vector2 = _world["canvas"]
	var play: Control = _nodes["PlayButton"]
	var gift: Control = _nodes["GiftMeter"]
	var P: float = (play.global_position.y - global_position.y - 8.0) if play.is_visible_in_tree() else canvas_h
	var G: float = gift.global_position.y - global_position.y + gift.size.y + 8.0
	var s: float = maxf(size.x / C.x, canvas_h / C.y)
	# Keep the platform above Play: oy = P - PLATFORM_BOTTOM_Y*s (when that is above).
	var oy: float = minf(0.0, P - PLATFORM_BOTTOM_Y * s)
	# The world must still reach the canvas bottom.
	if C.y * s + oy < canvas_h:
		s = maxf(s, (canvas_h - P) / (C.y - PLATFORM_BOTTOM_Y))
		oy = minf(0.0, P - PLATFORM_BOTTOM_Y * s)
	# Keep the baked sign below the Gift Meter when that forces a smaller scale.
	if SIGN_TOP_Y * s + oy < G and P - G > 0.0:
		var s_sign := (P - G) / (PLATFORM_BOTTOM_Y - SIGN_TOP_Y)
		if s_sign < s:
			s = maxf(s_sign, canvas_h / C.y)
			oy = minf(0.0, P - PLATFORM_BOTTOM_Y * s)
	var ox: float = (size.x - C.x * s) * 0.5
	_world_scale = s
	_world_offset = Vector2(ox, oy)
	var wb: TextureRect = _nodes["WorldBackground"]
	wb.position = _world_offset
	wb.size = C * s
	for side in ["WorldEdgeLeft", "WorldEdgeRight"]:
		var edge: TextureRect = _nodes[side]
		edge.texture = wb.texture
		edge.size = wb.size
		edge.position = _world_offset + Vector2(-wb.size.x if side == "WorldEdgeLeft" else wb.size.x, 0.0)
		edge.visible = ox > 0.5 and wb.texture != null
	# Scrubby: fit the visible bbox into the safe box (keeping aspect), centre it on the
	# anchor X, put the visible soles on the anchor Y.
	var sc: TextureRect = _nodes["Art_scrubby"]
	var tex := sc.texture
	var tex_size := Vector2(1158, 1358) if tex == null else Vector2(tex.get_width(), tex.get_height())
	var box: Rect2 = _world["scrubby_safe_box"]
	var feet: Vector2 = _world["scrubby_feet_anchor"]
	var vis := SCRUBBY_VISIBLE_BBOX
	var k: float = minf(box.size.x / vis.size.x, (feet.y - box.position.y) / (SCRUBBY_FEET_Y - vis.position.y))
	var canon_pos := Vector2(feet.x - (vis.position.x + vis.size.x * 0.5) * k, feet.y - SCRUBBY_FEET_Y * k)
	sc.position = world_to_screen(canon_pos)
	sc.size = tex_size * k * s
	_avoid_helper_bots()

## Panels must not cover the baked helper bots. When a panel overlaps a bot's mapped
## rect: 1) that column's gap tightens (never below the icon pop-out clearance); 2) if
## that is not enough (short/wide screens), the column shifts inward just past the bot
## (panels stay clear of Scrubby's visible rect). The top margin stays fixed so enlarged
## icons never reach the Gift Meter. _apply_layout_mode restores the defaults on resize.
const PANEL_GAP := 72
## Clears the tallest pop-out (SHOP/COLLECTION icon box 197 px on a 110 px icon floor).
const PANEL_TOP := 92
## Clears the TASKS/DAILY pop-out (164 px icon on a 110 px floor) between panels.
const PANEL_GAP_MIN := 58
func _avoid_helper_bots() -> void:
	for side in ["LeftShortcutColumn", "RightShortcutColumn"]:
		var col: VBoxContainer = _nodes[side]
		var sep: int = col.get_theme_constant("separation")
		var over := 0.0
		var shift := 0.0
		for b in col.get_children():
			var r: Rect2 = (b as Control).get_global_rect()
			r.position -= global_position
			for bot in _world["helper_bot_rects"]:
				var br := Rect2(world_to_screen(bot.position), bot.size * _world_scale)
				if r.intersects(br):
					over = maxf(over, r.end.y - br.position.y + 8.0)
					shift = maxf(shift, (r.end.x - br.position.x + 8.0) if side == "RightShortcutColumn" else (br.end.x - r.position.x + 8.0))
		if over <= 0.0:
			continue
		var new_sep: int = maxi(PANEL_GAP_MIN, sep - int(ceil(over)))
		col.add_theme_constant_override("separation", new_sep)
		if over - float(sep - new_sep) > 0.0:
			col.custom_minimum_size.x = PANEL_SIZE.x + ceilf(shift)

## Scrubby's canonical visible rect / feet line (for tests and evidence).
func get_scrubby_canonical() -> Dictionary:
	var box: Rect2 = _world["scrubby_safe_box"]
	var feet: Vector2 = _world["scrubby_feet_anchor"]
	var vis := SCRUBBY_VISIBLE_BBOX
	var k: float = minf(box.size.x / vis.size.x, (feet.y - box.position.y) / (SCRUBBY_FEET_Y - vis.position.y))
	var origin := Vector2(feet.x - (vis.position.x + vis.size.x * 0.5) * k, feet.y - SCRUBBY_FEET_Y * k)
	return {"k": k, "visible_rect": Rect2(origin + vis.position * k, vis.size * k), "feet_y": origin.y + SCRUBBY_FEET_Y * k, "center_x": origin.x + (vis.position.x + vis.size.x * 0.5) * k}

# ------------------------------------------------------------ shortcuts ----

func _build_shortcuts(column: VBoxContainer, specs: Array) -> void:
	for spec in specs:
		var b := UiShortcutButton.new(spec[0], UiText.t(spec[1]))
		HomeStyle.style_light_panel(b, int(PANEL_SIZE.y) - UiShortcutButton.LABEL_BAND)
		b.add_theme_font_size_override("font_size", 28)
		b.custom_minimum_size = PANEL_SIZE
		# Panels hug the column's inner edge, so a widened column shifts them inward.
		b.size_flags_horizontal = Control.SIZE_SHRINK_END if column.name == "LeftShortcutColumn" else Control.SIZE_SHRINK_BEGIN
		b.set_icon_box(V03_ICON_BOX * float(ICON_SCALE[spec[0]]))
		var id: String = spec[0]
		b.pressed.connect(func():
			shortcut_requested.emit(id)
			open_popup(id))
		column.add_child(b)
		_nodes["Shortcut_" + id] = b
		_nodes["ShortcutIcon_" + id] = b.icon_rect

# ------------------------------------------------------------- Play CTA ----

## Centred standalone CTA (V03 size): live PLAY, native white triangle, compact live
## frontier subtitle. The status pill floats just above the button (no layout change).
const PLAY_SIZE := Vector2(470, 150)
func _build_play(parent: VBoxContainer) -> void:
	var play := Button.new()
	play.name = "PlayButton"
	play.text = UiText.t("HOME_PLAY")
	play.custom_minimum_size = PLAY_SIZE
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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
	parent.add_child(_reg(play))
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
	var status := HomeStyle.label("", 24)
	status.name = "StatusLabel"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_stylebox_override("normal", HomeStyle.pad(HomeStyle.box(Color(0.02, 0.06, 0.16, 0.82), HomeStyle.GLOW, 2, 18, 0), 16, 2))
	status.set_anchors_preset(Control.PRESET_CENTER_TOP)
	status.grow_horizontal = Control.GROW_DIRECTION_BOTH
	status.grow_vertical = Control.GROW_DIRECTION_BEGIN
	status.offset_top = -8
	status.offset_bottom = -8
	status.visible = false
	play.add_child(_reg(status))

## Native white play triangle (no texture).
class PlayTriangle extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_colored_polygon(PackedVector2Array([r.position + Vector2(r.size.x * 0.12, 0), r.position + Vector2(r.size.x, r.size.y * 0.5), r.position + Vector2(r.size.x * 0.12, r.size.y)]), Color(1, 1, 1))
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

# ---------------------------------------------------- Win Streak track ----

## Thin track: badge with the live streak, progress line, five gift objects and ONLY
## the live SB value under each (1/5/10/25/100). Current step gold, reached full,
## future dimmed.
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
		b.custom_minimum_size = Vector2(0, 150)
		b.add_theme_font_size_override("font_size", 26)
		b.focus_mode = Control.FOCUS_NONE
		HomeStyle.style_nav_button(b, id == "home")
		for st in ["normal", "hover", "pressed", "disabled"]:
			var sb: StyleBoxFlat = b.get_theme_stylebox(st)
			sb.content_margin_top = 96
		var icon := HomeStyle.art("NavIcon_" + id)
		icon.set_anchors_preset(Control.PRESET_CENTER_TOP)
		icon.offset_left = -44
		icon.offset_right = 44
		icon.offset_top = 6
		icon.offset_bottom = 94
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

# ------------------------------------------------------------ ad slot ----

## V04 persistent ad slot below the nav. Empty integration seam: a future ad SDK view is
## attached to get_ad_mount(); a future No-Ads entitlement collapses the slot with
## set_ad_slot_enabled(false). No provider, no fake content.
func set_ad_slot_enabled(enabled: bool) -> void:
	_ad_slot_enabled = enabled
	(_nodes["AdBannerSlot"] as Control).visible = enabled
	_apply_layout_mode()

func is_ad_slot_enabled() -> bool:
	return _ad_slot_enabled

func get_ad_mount() -> Control:
	return _nodes["AdMount"]

# ------------------------------------------------------------ responsive ----

func _apply_layout_mode() -> void:
	if not _built:
		return
	var vp := get_viewport_rect().size
	var mode := ResponsiveLayout.get_layout_mode(vp)
	var gap: int = UiTokens.SPACE_SM if mode == ResponsiveLayout.LayoutMode.COMPACT else (UiTokens.SPACE_LG if mode == ResponsiveLayout.LayoutMode.TALL else UiTokens.SPACE_MD)
	(_nodes["HomeLayout"] as VBoxContainer).add_theme_constant_override("separation", gap)
	(_nodes["HomeActionLayer"] as VBoxContainer).add_theme_constant_override("separation", gap)
	(_nodes["ProfileCard"] as Control).custom_minimum_size.x = clampf(vp.x * PROFILE_CARD_WIDTH_FRACTION, 460.0, 620.0)
	(_nodes["AdBannerSlot"] as Control).custom_minimum_size.y = clampf(vp.x * AD_SLOT_RATIO, AD_SLOT_MIN_H, AD_SLOT_MAX_H)
	(_nodes["WorldMargin"] as MarginContainer).add_theme_constant_override("margin_top", PANEL_TOP)
	for side in ["LeftShortcutColumn", "RightShortcutColumn"]:
		(_nodes[side] as VBoxContainer).add_theme_constant_override("separation", PANEL_GAP)
		(_nodes[side] as Control).custom_minimum_size.x = PANEL_SIZE.x
	# The host reserves the action layer's minimum so the layout never overlaps.
	(_nodes["ActionHost"] as Control).custom_minimum_size.y = (_nodes["HomeActionLayer"] as Control).get_combined_minimum_size().y
	_queue_world()

func get_layout_mode() -> int:
	return ResponsiveLayout.get_layout_mode(get_viewport_rect().size)

# ------------------------------------------------------------- modal ----

## Deterministic modal state (V03 K, V04 79): while any Home popup or an external source
## (the app root passes "settings") is open, the single HomeActionLayer and the HUD (+)
## buttons are hidden (not drawn; no pointer/keyboard input). The ActionHost keeps its
## layout slot, so closing restores exactly the previous Home.
const MODAL_HIDDEN := ["HomeActionLayer", "ScrubBucksPlus", "HeartsPlus"]
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
	for region in MODAL_HIDDEN:
		(_nodes[region] as Control).visible = not modal
	_queue_world()

# ---------------------------------------------------------------- refresh ----

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

func _render_values() -> void:
	_vm = HomeViewModel.build(_app)
	if not _vm.get("ok", false):
		return
	(_nodes["ProfileName"] as Label).text = UiText.t("HOME_PLAYER_NAME_DEFAULT")
	(_nodes["ProfileLevel"] as Label).text = UiText.num(_vm["level"])
	# Bot Parts toward the next 250-part robot (canonical wallet / RobotUnlockService),
	# never XP — only the live ratio, centred in the bar; gold bar when unlockable.
	var parts: UiProgressMeter = _nodes["ProfileBotParts"]
	parts.set_progress(_vm["bot_parts"], _vm["bot_parts_target"],
		UiText.t("HOME_RATIO", [UiText.num(_vm["bot_parts"]), UiText.num(_vm["bot_parts_target"])]))
	HomeStyle.style_meter(parts.bar, HomeStyle.GOLD if _vm["robot_can_unlock"] else HomeStyle.GREEN, 42)
	var sb: UiValueChip = _nodes["ScrubBucksChip"]
	sb.set_tag(UiText.t("HOME_CURRENCY_SB"))
	sb.set_value(UiText.num(_vm["scrub_bucks"]))
	var hearts: UiValueChip = _nodes["HeartsChip"]
	hearts.set_value("%d/%d" % [_vm["hearts"], _vm["hearts_max"]])
	hearts.set_sub("" if _vm["hearts"] >= _vm["hearts_max"] else _mmss(_vm["heart_seconds_to_next"]))
	(_nodes["GiftMeterBar"] as UiProgressMeter).set_progress(_vm["gift_progress"], _vm["gift_cycle_max"],
		UiText.t("HOME_RATIO", [UiText.num(_vm["gift_progress"]), UiText.num(_vm["gift_cycle_max"])]))
	var gbadge: Label = _nodes["GiftClaimableBadge"]
	gbadge.text = str(_vm["gift_claimable"])
	gbadge.visible = _vm["gift_claimable"] > 0
	(_nodes["TrackStreakValue"] as Label).text = UiText.num(_vm["win_streak"])
	(_nodes["TrackProgress"] as ProgressBar).value = clampi(_vm["win_streak"], 0, TRACK_POSITIONS)
	for step in _vm["win_streak_track"]:
		var value: Label = _nodes["TrackStep%d" % step["position"]]
		value.text = UiText.num(step["sb"])
		value.add_theme_color_override("font_color", HomeStyle.GOLD if step["current"] else HomeStyle.TEXT)
		value.modulate.a = 1.0 if step["reached"] or step["current"] else 0.6
		var gift: Control = _nodes["TrackGift%d" % step["position"]]
		gift.modulate = Color(1, 1, 1, 1) if step["reached"] or step["current"] else Color(0.72, 0.78, 0.92, 0.80)
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
