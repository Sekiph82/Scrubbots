extends Control
## HomeScreen — res://scenes/ui/home/home_screen.tscn (preload this script; AL-001).
##
## M42 production Home. V04 (coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_
## BACKGROUND.md) supersedes the earlier layered composition: the world is ONE complete
## owner-approved background per world (HomeWorldCatalog; World 01 = HOME-124, the owner
## plaza: sky, clouds, trees, tile floor; SB-HOME-BG-2026-11-16). The area name is native text.
## Only Scrubby is a separate runtime layer, placed by the world's canonical 1080x2160
## anchor contract. Everything else is native Godot UI:
##
##   HomeScreen (Home theme: bold face + navy outline)
##   ├── Background          world canvas (clipped above the ad slot)
##   │     ├── WorldBackground   HOME-124, uniform scale, never stretched
##   │     ├── WorldStill / WorldVideo   SB-POLISH-009 still + one gesture video; since
##   │     │                       SB-HOME-VIDEO-2026-11-17 Scrubby keyed on magenta (chroma key)
##   │     └── Layer_characters/Art_scrubby   feet on the tile floor
##   │                         └── HomeAreaLabel   native WHISPERING PARK / AREA n (sky band)
##   └── SafeAreaRoot/MarginContainer/Content/HomeLayout (VBox)
##       ├── TopCurrencyHUD      narrow profile card (portrait in front of its frame,
##       │                       bottom-anchored; Bot Parts icon badge + thick Bot Parts bar)
##       │                       · SettingsButton · Scrub Bucks chip + (+) · Hearts chip + (+)
##       ├── GiftMeter           emblem · thick gold meter with only N/next · crate
##       ├── ActionHost/HomeActionLayer   (hidden as ONE layer while a modal is open)
##       │     ├── WorldMargin/MainWorldArea   activity column | (world) | activity column
##       │     └── BottomActionStack   bottom-anchored (V05): PLAY · LEVEL N (+ StatusLabel pill)
##       └── AdBannerSlot        persistent 320x50 banner area scaled to the width, empty
##                               SDK seam, collapsed by the No Ads entitlement
##
## SB-TF-03 (owner 2026-11-18): no bottom nav and no win-streak strip; Robots / Ranks /
## Collection live in Profile, Notifications in Settings, the Shop opens only from the HUD (+)
## popups. The world columns hold small see-through ACTIVITY buttons (Rewarded Ads, Tasks,
## Daily, one per active Event) that hide themselves when there is nothing left to do today.
##
## V05 (coordination/OWNER_M42_HOME_POLISH_V05.md): the world transform is a pure
## function of the viewport + safe area and the frozen V04 reference geometry, so HUD /
## stack / ad-slot changes can never move HOME-120.
## V06 (coordination/OWNER_M42_HOME_POLISH_V06.md): ad slot 100 px, Scrubby 1.24x the V04
## fit with a soft dark HeroFocusShade behind him, panel glass 0.51, thinner currency
## pills with an in-pill glow '+', Heart count on the heart icon + regen clock in the pill.
##
## Every approved ART entry is accounted in HomePresentationMap. The screen owns NO
## durable truth: it reads the canonical AppState and only emits intents.

signal play_requested
signal settings_requested
signal shortcut_requested(id: String)
## V04: HUD (+) buttons — intent only (no price/product/transaction is implemented here).
signal scrub_bucks_purchase_requested
signal hearts_purchase_requested
## SB-PHONE-2026-11-12-E: a win's reward flight ended (or landed at once under Reduced Effects).
signal reward_flight_finished(key: String)

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
const HomeScrubbyHero = preload("res://scripts/ui/home/home_scrubby_hero.gd")
const ResultsMomentum = preload("res://scripts/progression/results_momentum.gd")
const JourneyStrip = preload("res://scripts/ui/components/journey_strip.gd")
const GiftProgressModel = preload("res://scripts/economy/gift_progress_model.gd")
const GiftTickOverlay = preload("res://scripts/ui/components/gift_tick_overlay.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const WorldService = preload("res://scripts/progression/world_service.gd")
const HomeBadges = preload("res://scripts/ui/home/home_badges.gd")
const HomeMicroFeel = preload("res://scripts/ui/feel/home_micro_feel.gd")
const HomeRewardFlight = preload("res://scripts/ui/home/home_reward_flight.gd")
const EventsV02Ui = preload("res://scripts/ui/events/events_v02_ui.gd")
## M42-C003 V03 pinned gesture frame set (HOME_ASSET_MANIFEST animation_sets).
const HERO_ANIMATION_SET := "home_scrubby_gestures_v03"
## SB-HOME-VIDEO-2026-11-17: the owner Flow videos with Scrubby keyed out of the old park onto
## magenta (HOME_ASSET_MANIFEST video_sets); when bound they replace the frame set (fallback).
const HERO_VIDEO_SET := "home_scrubby_videos_keyed_v2"
const CHROMA_KEY := preload("res://scripts/ui/feel/chroma_key_magenta.gdshader")
const UiText = preload("res://scripts/ui/ui_text.gd")

## Popups with a V1 Home destination. Only DAILY is a Home panel in V04; Gifts and Cards
## Exchange popups remain reachable through open_popup() as seams for their owning flows
## (automatic rewards / Collection).
const LIVE_SHORTCUTS := ["gift_bar", "cards_exchange", "daily"]

## SB-TF-03: the fixed activity buttons (one Event button per active event follows them).
const ACTIVITY_FIXED := [["rewarded_ads", "HOME_SC_REWARDED_ADS"], ["tasks", "HOME_SC_TASKS"], ["daily", "HOME_SC_DAILY"]]
## Deterministic placement: the visible fixed buttons stack top-down in the LEFT column; the
## visible Event buttons (first-active order of EventsV02Service.list()) fill the RIGHT column
## first, then the free LEFT slots. At most ACTIVITY_PER_COLUMN per column, so ACTIVITY_MAX in
## all (further events are not shown). Hidden buttons leave the column, so the rest close up.
const ACTIVITY_PER_COLUMN := 4
const ACTIVITY_MAX := 8
## SB-M44-031: Home entry -> feature id (owned by HomeBadges, which also derives SB-M44-013 NEW).
const GATED_ENTRIES := HomeBadges.GATED_ENTRIES
## One panel size for every activity button. SB-TF-03 ("30% smaller"): 0.7x the V06 210x156
## panel, the V03 206x164 icon box, its label band and font. Icons stand on the label band and
## may rise above the panel.
const PANEL_SCALE := 0.7
const PANEL_SIZE := Vector2(147, 109)
## SB-TF-03 panel glass: half the V06 body alpha 0.51 (outline and label stay opaque).
const PANEL_ALPHA := 0.255
const PANEL_BORDER := 3
const V03_ICON_BOX := Vector2(206, 164)
const PANEL_LABEL_BAND := 34   # 0.7 x 46, +2 so a 20 px label line still fits the 109 px panel
const PANEL_FONT := 20
const PANEL_EDGE_MARGIN := 26
## SB-TF-03 banner area: the standard 320x50 banner scaled to the viewport width, clamped
## 72..112. Explicit reservation only — never EXPAND/FILL, not a provider contract.
const AD_SLOT_RATIO := 50.0 / 320.0
const AD_SLOT_MIN_H := 72.0
const AD_SLOT_MAX_H := 112.0

## V05 world-transform lock. The V04 transform was derived from the V04 layout; these
## are that layout's measured reference values (commit a8b953e, per layout mode
## COMPACT/NORMAL/TALL): the bottom stack height above the ad slot (PLAY top -> ad top),
## the Gift Meter bottom below the safe top, and the V04 ad reservation rule. The world
## transform is computed from them + the viewport/safe area only.
const V04_REF_STACK := {0: 477.0, 1: 501.0, 2: 525.0}
const V04_REF_GIFT_BOTTOM := {0: 398.0, 1: 406.0, 2: 414.0}
const V04_REF_AD_RATIO := 50.0 / 320.0
const V04_REF_AD_MIN := 100.0
const V04_REF_AD_MAX := 180.0
## Hero scale relative to the V04 safe-box fit, applied about the visible soles
## (V05 1.15; V06 1.24; M42-C002 owner lock 1.612 = 1.24 x 1.30 — never scaled down per
## viewport; coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V01.md).
const SCRUBBY_SCALE := 1.612
## V06 HeroFocusShade (world canvas px; re-based for the owner-selected 940x1672 Home
## background, M28-C002-C003-R01 V02): soft dark radial dimmer behind Scrubby's torso,
## starting below the area label band (bottom y 545), peak alpha 0.20 fading to 0.
const HERO_SHADE_RECT := Rect2(260, 600, 420, 690)
const HERO_SHADE_ALPHA := 0.20

## HOME-026 texture facts used by the World anchor contract (texture pixels of the
## 1158x1358 approved Scrubby): alpha>128 visible bbox and the soles' ground line (the
## brush bristles reach 16 px lower and rest on the platform).
const SCRUBBY_VISIBLE_BBOX := Rect2(27, 7, 1130, 1327)
const SCRUBBY_FEET_Y := 1318.0
## World canonical rows (in the world canvas: the owner-selected 940x1672 Home background)
## used to keep the composition readable: the platform row where Scrubby stands (feet y
## 1240, dais floor 1180..1400) must stay above the Play CTA (on short screens Play may
## overlap the lower stone steps); the area label band's top (area_label_rect) should stay below the Gift Meter.
const PLATFORM_BOTTOM_Y := 1260.0
## SB-HOME-BG-2026-11-16 native area label fonts (px; _layout_area_label shrinks them to fit).
const AREA_TITLE_PX := 64
const AREA_NUMBER_PX := 40
const SIGN_TOP_Y := 405.0

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
## M43-C001R validated momentum config (the app root shares its own; else loaded once).
var _momentum_cfg: Dictionary = {}
## M43-C005F-PHASE4 (F012): ephemeral state-change micro feel (presentation only, never saved).
var _micro = HomeMicroFeel.new()
## SB-PHONE-2026-11-12-E: a win's committed rewards flying into the HUD (presentation only).
var _flight = null
var _feel_adapter = null

func _ready() -> void:
	_flight = HomeRewardFlight.new(self)
	_flight.completed.connect(func(k): reward_flight_finished.emit(k))
	_flight.bind_feel(_feel_adapter)
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
	for col in ["LeftShortcutColumn", "RightShortcutColumn"]:
		_nodes[col].resized.connect(_layout_area_label)
	_apply_layout_mode()
	if _art == null:
		set_art_binder(HomeArtBinder.new())
	if _app != null:
		_nodes["HomeScrubbyHero"].bind_effects(_app.effects if "effects" in _app else null)
	refresh()
	# MAINT-HOME-EXPORT-ASSET-GATE-C001: opt-in exported-runtime proof (inert unless the
	# app is started with the user argument --home-asset-diagnostics).
	if OS.get_cmdline_user_args().has("--home-asset-diagnostics"):
		print("HOME_ASSET_DIAG " + JSON.stringify(get_asset_diagnostics()))

func bind(app_state) -> void:
	_app = app_state
	if _built:
		_nodes["HomeScrubbyHero"].bind_effects(app_state.effects if app_state != null and "effects" in app_state else null)
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
	_nodes["ProfilePortrait"].remove_meta("binder_tex")   # M43-C008: re-captured by _render_values
	for spec in ACTIVITY_FIXED:
		var b: UiShortcutButton = _nodes[_activity_node(spec[0])]
		b.set_icon_box(b.get_icon_box())
	_nodes["HomeScrubbyHero"].set_frames(_art.animation_set(HERO_ANIMATION_SET) if _art.has_method("animation_set") else {})
	_nodes["HomeScrubbyHero"].set_video(_nodes["WorldStill"], _nodes["WorldVideo"], _art.video_set(HERO_VIDEO_SET) if _art.has_method("video_set") else {})
	# The focus shade sits above the video layer, so it would dim the keyed Scrubby: video mode drops it.
	_nodes["HeroFocusShade"].visible = not _nodes["HomeScrubbyHero"].has_video()
	_queue_world()

func get_art_binder():
	return _art

## Binding evidence (tests + the opt-in exported-runtime diagnostic): integrity mode,
## feature tags, manifest validity, which mapped Home nodes show approved art, and the
## HomeScrubbyHero frame set.
func get_asset_diagnostics() -> Dictionary:
	var nodes := {}
	var unbound: Array = []
	var bound := 0
	for row in get_presentation_accounting():
		for n in row["nodes"]:
			var ok: bool = n["texture"] != null
			nodes[n["name"]] = ok
			if ok:
				bound += 1
			else:
				unbound.append(n["name"])
	var hero = _nodes["HomeScrubbyHero"]
	var counts := {}
	if hero.has_frames():
		for g in hero.get_set()["textures"]:
			counts[g] = (hero.get_set()["textures"][g] as Array).size()
	return {"mode": _art.get_mode() if _art != null and _art.has_method("get_mode") else "",
		"features": {"template": OS.has_feature("template"), "editor": OS.has_feature("editor"),
			"web": OS.has_feature("web"), "debug": OS.has_feature("debug")},
		"manifest_valid": _art != null and _art.is_manifest_valid(),
		"bound_nodes": bound, "unbound_nodes": unbound, "nodes": nodes,
		"hero_has_frames": hero.has_frames(), "animation_counts": counts,
		"hero_video_streams": hero.get_streams().keys(),
		# Packaging facts: is the raw source PNG in this build, and would the strict
		# source gate pass here (false in an export = why PACKAGED_RUNTIME exists).
		"raw_source_png_present": FileAccess.file_exists("res://assets/ui/final/characters/scrubby/scrubby_home_pose.png"),
		"strict_mode_valid_here": HomeArtBinder.V.validate(HomeArtBinder.V.load_manifest(), "res://", HomeArtBinder.V.SOURCE_TREE_STRICT)["ok"]}

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
	# SB-HOME-VIDEO-2026-11-17: keyed still + video (Scrubby on magenta) over WorldBackground.
	var key := ShaderMaterial.new()
	key.shader = CHROMA_KEY
	var still := HomeStyle.art("WorldStill")
	still.stretch_mode = TextureRect.STRETCH_SCALE
	still.material = key
	still.visible = false
	bg.add_child(_reg(still))
	var video := VideoStreamPlayer.new()
	video.name = "WorldVideo"
	video.expand = true
	video.material = key
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video.visible = false
	bg.add_child(_reg(video))
	# Wide (tablet) canvases: mirrored continuation of the same world image fills the
	# narrow side bands beyond the 1:2 world instead of flat BG01 bars.
	for side in ["WorldEdgeLeft", "WorldEdgeRight"]:
		var edge := HomeStyle.art(side)
		edge.stretch_mode = TextureRect.STRETCH_SCALE
		edge.flip_h = true
		edge.visible = false
		bg.add_child(_reg(edge))
	# SB-TF-03: without the opaque bottom nav, the canvas may reach below the V04-locked world
	# image (the banner area is shorter than the V04 reservation): the floor continues mirrored.
	var below := HomeStyle.art("WorldEdgeBottom")
	below.stretch_mode = TextureRect.STRETCH_SCALE
	below.flip_v = true
	below.visible = false
	bg.add_child(_reg(below))
	var chars := Control.new()
	chars.name = "Layer_characters"
	chars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(chars)
	_nodes["Layer_characters"] = chars
	# V06: native radial dimmer (GradientTexture2D) above the world, behind Scrubby.
	var shade := TextureRect.new()
	shade.name = "HeroFocusShade"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.texture = make_hero_shade_texture()
	chars.add_child(_reg(shade))
	var sc := HomeStyle.art("Art_scrubby")
	sc.stretch_mode = TextureRect.STRETCH_SCALE   # sized to the texture aspect by _layout_world
	chars.add_child(_reg(sc))
	# M42-C003 V03: presentation-only hero animation (idle + gestures) over Art_scrubby.
	var hero := HomeScrubbyHero.new()
	hero.set_home_rect(sc)
	chars.add_child(_reg(hero))
	_nodes["Art_scrubby_gesture"] = hero.get_gesture_rect()
	# SB-HOME-BG-2026-11-16: native area name in the sky band (world name / HOME_AREA_NUMBER).
	var area := Control.new()
	area.name = "HomeAreaLabel"
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chars.add_child(_reg(area))
	for spec in [["HomeAreaTitle", AREA_TITLE_PX, HomeStyle.TEXT], ["HomeAreaNumber", AREA_NUMBER_PX, HomeStyle.SUBTITLE]]:
		var l := HomeStyle.label("", spec[1], spec[2], 12)
		l.name = spec[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.clip_text = true   # placed and font-fitted by _layout_area_label
		area.add_child(_reg(l))

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
	_side_margins(hud, 18, 32, 0)
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

	# V05: PLAY as ONE bottom-anchored stack directly above the ad slot; the world margin
	# above absorbs all free height, so a shorter ad slot lowers the stack by exactly the
	# released amount.
	var stack := VBoxContainer.new()
	stack.name = "BottomActionStack"
	stack.size_flags_vertical = Control.SIZE_SHRINK_END
	stack.add_theme_constant_override("separation", UiTokens.SPACE_MD)
	actions.add_child(_reg(stack))
	_build_play(stack)

	var ad := PanelContainer.new()
	ad.name = "AdBannerSlot"
	var adsb := HomeStyle.box(Color(0.03, 0.05, 0.10), Color(0.16, 0.26, 0.42), 0, 0, 0)
	adsb.border_width_top = 2
	adsb.expand_margin_bottom = 600   # covers the bottom inset down to the screen edge
	ad.add_theme_stylebox_override("panel", adsb)
	ad.mouse_filter = Control.MOUSE_FILTER_PASS
	ad.size_flags_vertical = Control.SIZE_SHRINK_END   # fixed reservation, never EXPAND/FILL
	layout.add_child(_reg(ad))
	var ad_mount := Control.new()
	ad_mount.name = "AdMount"   # the future ad SDK view attaches here; empty in V04
	ad_mount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ad.add_child(_reg(ad_mount))

	_build_hud(hud)
	_build_gift_meter(gm)
	_build_activity()

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
## visible) and pops out above the ring. Bot Parts icon badge + thick Bot Parts bar with the
## live N/250 ratio centred inside. SB-TF-03: the Settings icon sits between the card and the
## currency widgets (the only Settings entry on Home).
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
	# M43-C010 (SB-M43-124): the profile card opens Profile (invisible hit area over the card).
	var hit := Button.new()
	hit.name = "ProfileButton"
	hit.accessibility_name = UiText.t("PROFILE_TITLE")
	hit.flat = true
	hit.focus_mode = Control.FOCUS_ACCESSIBILITY
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	hit.pressed.connect(func(): _shortcut_pressed("profile"))
	card.add_child(_reg(hit))

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
	# SB-POLISH-007: claimable achievement rewards (HomeBadges), the nav tabs' red pill, on the
	# avatar corner (a plain Control, so the pill keeps its anchors inside the card).
	avatar.add_child(_reg(_badge_label("ProfileBadge")))

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
	# SB-TF-03: the badge shows the Bot Parts icon (the approved art the reward flight uses),
	# not the level (PLAY carries the level now).
	var parts_icon := HomeStyle.art("ProfileBotPartsIcon")
	parts_icon.texture = load(HomeRewardFlight.ICONS["bot_parts"])
	parts_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	parts_icon.offset_left = 12
	parts_icon.offset_top = 10
	parts_icon.offset_right = -12
	parts_icon.offset_bottom = -12
	rank.add_child(_reg(parts_icon))
	var parts := UiProgressMeter.new("ProfileBotParts")
	parts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	HomeStyle.style_meter(parts.bar, HomeStyle.GREEN, 42)
	_center_caption_in_bar(parts, 28)
	lvl_row.add_child(_reg(parts))

	# SB-TF-03: Settings icon (former bottom-nav art) centred between the card and the currencies.
	for i in range(2):
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(spacer)
		if i == 0:
			row.add_child(_reg(_build_settings_button()))

	var right := VBoxContainer.new()
	right.name = "HudCurrencies"
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 26)   # icon overhangs never touch
	row.add_child(right)
	# V05: assembled master-style widgets — oversized foreground icon (left), dark-blue
	# pill with the large live value, bright-green circular (+) attached on the right and
	# overlapping the pill end. Icon and (+) draw above the pill.
	for spec in [["ScrubBucksChip", "ScrubBucksPlus", scrub_bucks_purchase_requested], ["HeartsChip", "HeartsPlus", hearts_purchase_requested]]:
		var line := HBoxContainer.new()
		line.name = spec[0].replace("Chip", "Widget")
		# The (+) hit target overlaps the pill so its glyph sits INSIDE the pill's right end.
		line.add_theme_constant_override("separation", -CURRENCY_PLUS_OVERLAP)
		right.add_child(_reg(line))
		var chip := UiValueChip.new(spec[0])
		chip.set_icon_size(CURRENCY_ICON_FOOTPRINT)
		chip.set_icon_pop(CURRENCY_ICON_POP)   # drawn 110 px, overhanging the pill
		chip.set_value_size(40)
		chip.custom_minimum_size = Vector2(CURRENCY_PILL_W, CURRENCY_PILL_H)
		chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var csb := HomeStyle.box(Color(0.035, 0.090, 0.230), HomeStyle.GLOW, 4, int(CURRENCY_PILL_H / 2), 8)
		csb.content_margin_left = 10
		csb.content_margin_right = PLUS_GLYPH_INSET + PLUS_GLYPH * 0.5 + 12.0
		csb.content_margin_top = 0
		csb.content_margin_bottom = 0
		chip.set_panel_style(csb)
		chip.value_label.add_theme_constant_override("outline_size", 12)
		line.add_child(_reg(chip))
		# Transparent >= 88x88 hit target centred on a native glow '+' glyph (owner plus
		# reference: bold white plus, dark navy outline, cyan outer glow, no circle).
		var plus := Button.new()
		plus.name = spec[1]
		plus.accessibility_name = UiText.t("A11Y_GET_SCRUB_BUCKS" if spec[1] == "ScrubBucksPlus" else "A11Y_GET_HEARTS")
		plus.flat = true
		plus.custom_minimum_size = Vector2(UiTokens.TOUCH_MIN, UiTokens.TOUCH_MIN)
		plus.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		plus.focus_mode = Control.FOCUS_ACCESSIBILITY
		for st in ["normal", "hover", "pressed", "disabled", "focus"]:
			plus.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var glyph := PlusGlyph.new()
		glyph.name = spec[1] + "Glyph"
		glyph.set_anchors_preset(Control.PRESET_CENTER)
		glyph.offset_left = -PLUS_GLYPH * 0.5
		glyph.offset_right = PLUS_GLYPH * 0.5
		glyph.offset_top = -PLUS_GLYPH * 0.5
		glyph.offset_bottom = PLUS_GLYPH * 0.5
		plus.add_child(_reg(glyph))
		plus.button_down.connect(func(): glyph.modulate = Color(0.85, 0.85, 0.85))
		plus.button_up.connect(func(): glyph.modulate = Color(1, 1, 1))
		var sig: Signal = spec[2]
		plus.pressed.connect(func(): sig.emit())
		line.add_child(_reg(plus))
	# V06: the live Heart count sits on the heart icon itself (white, navy outline).
	var hicon: TextureRect = (_nodes["HeartsChip"] as UiValueChip).icon
	var hcount := HomeStyle.label("", 48, Color(1, 1, 1), 14)
	hcount.name = "HeartsCount"
	hcount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hcount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hcount.set_anchors_preset(Control.PRESET_FULL_RECT)
	hcount.offset_top = -4
	hicon.add_child(_reg(hcount))

const SETTINGS_SIZE := 100.0
func _build_settings_button() -> Button:
	var b := Button.new()
	b.name = "SettingsButton"
	b.accessibility_name = UiText.t("SETTINGS_TITLE")
	b.flat = true
	b.custom_minimum_size = Vector2(SETTINGS_SIZE, SETTINGS_SIZE)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_ACCESSIBILITY
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var icon := HomeStyle.art("SettingsIcon")
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(_reg(icon))
	b.button_down.connect(func(): icon.modulate = Color(0.85, 0.85, 0.85))
	b.button_up.connect(func(): icon.modulate = Color(1, 1, 1))
	b.pressed.connect(func(): settings_requested.emit())
	return b

## Currency widget geometry (1080x2160 reference px). V06: pill 84 -> 68 (-20%), icon
## unchanged (110), '+' glyph 52 px inside the pill's right end (centre PLUS_GLYPH_INSET +
## glyph/2 from the pill edge) with a transparent 88x88 hit target centred on it.
const CURRENCY_ICON_FOOTPRINT := 64
const CURRENCY_ICON_POP := 1.71875   # 64 x 1.71875 = 110 px drawn (unchanged)
const CURRENCY_PILL_W := 282.0
const CURRENCY_PILL_H := 68.0
const PLUS_GLYPH := 52.0
const PLUS_GLYPH_INSET := 14.0
const CURRENCY_PLUS_OVERLAP := 44 + 40   # hit half-width + glyph centre inset (14 + 26)

## Native plus glyph: cyan outer glow, dark navy outline, bold white plus. Transparent
## background; never receives input (the parent Button is the hit target).
class PlusGlyph extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _bar_rects(r: Rect2, thick: float) -> Array:
		var c := r.get_center()
		return [Rect2(c.x - r.size.x * 0.5, c.y - thick * 0.5, r.size.x, thick), Rect2(c.x - thick * 0.5, c.y - r.size.y * 0.5, thick, r.size.y)]
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var inner := r.grow(-size.x * 0.12)
		var thick := size.x * 0.26
		# soft cyan outer glow: concentric translucent discs (no hard square edge)
		var c := r.get_center()
		for i in range(8):
			var rad := size.x * (0.62 - float(i) * 0.035)
			draw_circle(c, rad, Color(0.30, 0.90, 1.0, 0.035 + float(i) * 0.006))
		# dark navy outline
		for b in _bar_rects(inner.grow(5.0), thick + 10.0):
			draw_rect(b, Color(0.035, 0.086, 0.216), true)
		# bold white plus
		for b in _bar_rects(inner, thick):
			draw_rect(b, Color(1, 1, 1), true)
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

## Put a meter's live caption inside (centred over) its bar.
static func _center_caption_in_bar(meter: UiProgressMeter, font: int) -> void:
	meter.caption.add_theme_font_size_override("font_size", font)
	meter.caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	meter.caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meter.caption.clip_text = false
	meter.caption.reparent(meter.bar, false)
	meter.caption.set_anchors_preset(Control.PRESET_FULL_RECT)

# ---------------------------------------------------------- Gift Meter ----

## V05 master Gift Bar grammar: a substantial navy chassis with a cyan edge and an
## inset gold progress bar carrying the live N/1000; the HOME-051 emblem and HOME-054
## crate are large foreground objects overhanging both chassis ends. No timer tab, no
## Event Points, no NEXT GIFT caption.
const GIFT_ASSEMBLY_H := 128.0
const GIFT_OBJECT := 132.0
const GIFT_CHASSIS_H := 88.0
const GIFT_CHASSIS_INSET := 64.0
const GIFT_BAR_H := 54
func _build_gift_meter(gm: MarginContainer) -> void:
	var panel := Control.new()
	panel.name = "GiftMeterPanel"
	panel.custom_minimum_size = Vector2(0, GIFT_ASSEMBLY_H)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gm.add_child(_reg(panel))
	var chassis := PanelContainer.new()
	chassis.name = "GiftMeterChassis"
	chassis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var csb := HomeStyle.box(Color(0.035, 0.090, 0.230), HomeStyle.GLOW, 4, int(GIFT_CHASSIS_H / 2), 10)
	# The gold bar starts/ends just past the overhanging emblem / crate.
	csb.content_margin_left = GIFT_OBJECT - GIFT_CHASSIS_INSET + 6.0
	csb.content_margin_right = GIFT_OBJECT - GIFT_CHASSIS_INSET + 6.0
	csb.content_margin_top = (GIFT_CHASSIS_H - GIFT_BAR_H) * 0.5
	csb.content_margin_bottom = (GIFT_CHASSIS_H - GIFT_BAR_H) * 0.5
	chassis.add_theme_stylebox_override("panel", csb)
	chassis.set_anchors_preset(Control.PRESET_FULL_RECT)
	chassis.offset_left = GIFT_CHASSIS_INSET
	chassis.offset_right = -GIFT_CHASSIS_INSET
	chassis.offset_top = (GIFT_ASSEMBLY_H - GIFT_CHASSIS_H) * 0.5
	chassis.offset_bottom = -(GIFT_ASSEMBLY_H - GIFT_CHASSIS_H) * 0.5
	panel.add_child(_reg(chassis))
	# Live ratio inside the gold bar; no long caption, no event timer / Event Points.
	var meter := UiProgressMeter.new("GiftMeterBar")
	meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	HomeStyle.style_meter(meter.bar, HomeStyle.GOLD, GIFT_BAR_H)
	(meter.bar.get_theme_stylebox("background") as StyleBoxFlat).bg_color = Color(0.012, 0.035, 0.110)
	_center_caption_in_bar(meter, 38)
	meter.caption.add_theme_constant_override("outline_size", 12)
	chassis.add_child(_reg(meter))
	# M43-C009 (SB-M43-118): the whole Gift Meter assembly is the Gift Bar entry (invisible
	# hit area; the owner-approved meter art is unchanged). Hidden with the other Home
	# controls while a modal is open.
	var hit := Button.new()
	hit.name = "GiftMeterButton"
	hit.accessibility_name = UiText.t("GIFTS_TITLE")
	hit.flat = true
	hit.focus_mode = Control.FOCUS_ACCESSIBILITY
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	hit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit.pressed.connect(func(): _shortcut_pressed("gift_bar"))
	panel.add_child(_reg(hit))
	# M43-C005R: micro-progress marks inside the SAME bar (no geometry / caption change).
	var ticks := GiftTickOverlay.new()
	ticks.avoid_label = meter.caption
	meter.bar.add_child(_reg(ticks))
	var emblem := HomeStyle.art("GiftEmblem")
	emblem.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	emblem.offset_left = 0
	emblem.offset_right = GIFT_OBJECT
	emblem.offset_top = -GIFT_OBJECT * 0.5
	emblem.offset_bottom = GIFT_OBJECT * 0.5
	panel.add_child(_reg(emblem))
	var crate := HomeStyle.art("GiftCrate")
	crate.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	crate.offset_left = -GIFT_OBJECT
	crate.offset_right = 0
	crate.offset_top = -GIFT_OBJECT * 0.5
	crate.offset_bottom = GIFT_OBJECT * 0.5
	panel.add_child(_reg(crate))
	# SB-GIFT-METER-48H: time left in the cycle's 48 h window, under the bar between emblem
	# and crate; hidden at 0 progress (no window).
	var left := HomeStyle.label("", 20, HomeStyle.TEXT, 6)
	left.name = "GiftWindowLeft"
	left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	left.offset_left = -80
	left.offset_right = 80
	left.offset_top = -26
	left.offset_bottom = 0
	panel.add_child(_reg(left))
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

## World transform (V05 lock): a PURE function of the viewport size, the safe-area top /
## bottom and the frozen V04 reference geometry — never of the live HUD, stack or ad
## slot. It reproduces the audited V04 transform: s covers the V04 canvas (viewport above
## the V04 ad reservation), the baked platform-top region stays above the V04 PLAY line,
## the area label band stays below the V04 Gift Meter line (wide/tablet screens then show a
## mirrored continuation at the far sides).
static func compute_world_transform(vp: Vector2, safe_top: float, safe_bottom: float, canvas: Vector2 = Vector2(940, 1672)) -> Dictionary:
	var mode: int = ResponsiveLayout.get_layout_mode(vp)
	var ad_ref: float = roundf(clampf(vp.x * V04_REF_AD_RATIO, V04_REF_AD_MIN, V04_REF_AD_MAX))   # V04 layout rounded it
	var canvas_h: float = safe_bottom - ad_ref
	var P: float = canvas_h - float(V04_REF_STACK[mode]) - 8.0
	var G: float = safe_top + float(V04_REF_GIFT_BOTTOM[mode]) + 8.0
	var s: float = maxf(vp.x / canvas.x, canvas_h / canvas.y)
	var oy: float = minf(0.0, P - PLATFORM_BOTTOM_Y * s)
	if canvas.y * s + oy < canvas_h:
		s = maxf(s, (canvas_h - P) / (canvas.y - PLATFORM_BOTTOM_Y))
		oy = minf(0.0, P - PLATFORM_BOTTOM_Y * s)
	if SIGN_TOP_Y * s + oy < G and P - G > 0.0:
		var s_sign := (P - G) / (PLATFORM_BOTTOM_Y - SIGN_TOP_Y)
		if s_sign < s:
			s = maxf(s_sign, canvas_h / canvas.y)
			oy = minf(0.0, P - PLATFORM_BOTTOM_Y * s)
	return {"scale": s, "offset": Vector2((vp.x - canvas.x * s) * 0.5, oy)}

## Place the single world background and Scrubby. The visible world canvas is clipped at
## the live ad-slot top (or the screen bottom when collapsed); only that clip moves.
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
	var margin: MarginContainer = (_nodes["SafeAreaRoot"] as Node).get_node("MarginContainer")
	var safe_top: float = margin.get_theme_constant("margin_top")
	var safe_bottom: float = size.y - margin.get_theme_constant("margin_bottom")
	var t := compute_world_transform(size, safe_top, safe_bottom, C)
	var s: float = t["scale"]
	var ox: float = (t["offset"] as Vector2).x
	_world_scale = s
	_world_offset = t["offset"]
	var wb: TextureRect = _nodes["WorldBackground"]
	wb.position = _world_offset
	wb.size = C * s
	for n in ["WorldStill", "WorldVideo"]:
		(_nodes[n] as Control).position = wb.position
		(_nodes[n] as Control).size = wb.size
	for side in ["WorldEdgeLeft", "WorldEdgeRight"]:
		var edge: TextureRect = _nodes[side]
		edge.texture = wb.texture
		edge.size = wb.size
		edge.position = _world_offset + Vector2(-wb.size.x if side == "WorldEdgeLeft" else wb.size.x, 0.0)
		edge.visible = ox > 0.5 and wb.texture != null
	var below: TextureRect = _nodes["WorldEdgeBottom"]
	below.texture = wb.texture
	below.size = wb.size
	below.position = Vector2(wb.position.x, wb.position.y + wb.size.y)
	below.visible = below.position.y < canvas_h - 0.5 and wb.texture != null
	# Scrubby: V04 safe-box fit x 1.15 (V05), scaled about the visible soles: centre X on
	# the anchor, visible soles on the anchor Y.
	var sc: TextureRect = _nodes["Art_scrubby"]
	var tex := sc.texture
	var tex_size := Vector2(1158, 1358) if tex == null else Vector2(tex.get_width(), tex.get_height())
	var c := get_scrubby_canonical()
	sc.position = world_to_screen(c["origin"])
	sc.size = tex_size * float(c["k"]) * s
	_nodes["HomeScrubbyHero"].set_base(sc.position, sc.size, tex_size)
	var shade: Control = _nodes["HeroFocusShade"]
	shade.position = world_to_screen(HERO_SHADE_RECT.position)
	shade.size = HERO_SHADE_RECT.size * s
	_avoid_helper_bots()
	_layout_area_label()

## New area text (locale / world change) refits at the label's current width.
func _set_area_text(n: String, text: String) -> void:
	var l: Label = _nodes[n]
	if l.text != text:
		l.text = text
		_layout_area_label()

## The area label sits in the sky: from the world's area_label_rect top (never above the Gift
## Meter) down to Scrubby's head, between the shortcut columns and inside the rect's width.
## Both fonts shrink together to the height, then each to the width (HomeStyle.fit_font).
func _layout_area_label() -> void:
	if _world.is_empty():
		return
	var band: Rect2 = _world["area_label_rect"]
	var p := world_to_screen(band.position)
	var e := world_to_screen(band.end)
	var left: Rect2 = (_nodes["LeftShortcutColumn"] as Control).get_global_rect()
	var right: Rect2 = (_nodes["RightShortcutColumn"] as Control).get_global_rect()
	var gift: Rect2 = (_nodes["GiftMeter"] as Control).get_global_rect()
	var hero_top: float = world_to_screen((get_scrubby_canonical()["visible_rect"] as Rect2).position).y
	var x0 := maxf(p.x, left.end.x - global_position.x + 8.0)
	var x1 := minf(e.x, right.position.x - global_position.x - 8.0)
	var y0 := maxf(p.y, gift.end.y - global_position.y + 8.0)
	var y1 := hero_top - 8.0
	var box := Rect2(x0, y0, maxf(0.0, x1 - x0), maxf(0.0, y1 - y0))
	var area: Control = _nodes["HomeAreaLabel"]
	var labels := [[_nodes["HomeAreaTitle"], AREA_TITLE_PX], [_nodes["HomeAreaNumber"], AREA_NUMBER_PX]]
	# Font metrics, not Label minimum sizes (those refresh a frame after a size override).
	var natural := 0.0
	for l in labels:
		natural += (l[0] as Label).get_theme_font("font").get_height(l[1])
	var k := minf(1.0, box.size.y / maxf(natural, 1.0))
	# Short 16:9 screens with a deep notch leave no sky between the meter and Scrubby's head:
	# the label hides there rather than shrink below 60% or overlap him.
	area.visible = k >= 0.6
	area.position = box.position
	area.size = box.size
	if not area.visible:
		return
	var heights: Array = []
	var total := 0.0
	for l in labels:
		HomeStyle.fit_font(l[0], int(l[1] * k), box.size.x)
		heights.append((l[0] as Label).get_theme_font("font").get_height((l[0] as Label).get_theme_font_size("font_size")))
		total += heights[-1]
	var y := (box.size.y - total) * 0.5
	for i in labels.size():
		var l: Label = labels[i][0]
		l.position = Vector2(0.0, y)
		l.size = Vector2(box.size.x, heights[i])
		y += heights[i]

## Panels must not cover the baked helper bots. When a panel overlaps a bot's mapped
## rect: 1) that column's gap tightens (never below the icon pop-out clearance); 2) if
## that is not enough (short/wide screens), the column shifts inward just past the bot
## (panels stay clear of Scrubby's visible rect). The top margin stays fixed so enlarged
## icons never reach the Gift Meter. _apply_layout_mode restores the defaults on resize.
## SB-TF-03: the V06 gaps x PANEL_SCALE (icon pop-out: a 115 px icon on a 77 px floor = 38 px).
const PANEL_GAP := 50
const PANEL_TOP := 64
const PANEL_GAP_MIN := 38
func _avoid_helper_bots() -> void:
	for side in ["LeftShortcutColumn", "RightShortcutColumn"]:
		var col: VBoxContainer = _nodes[side]
		var sep: int = col.get_theme_constant("separation")
		var over := 0.0
		var shift := 0.0
		for b in col.get_children():
			if not (b as Control).visible:
				continue
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

## Feathered navy radial gradient: peak HERO_SHADE_ALPHA at the centre, eased to 0 at
## the ellipse edge (several stops -> no visible edge). Ellipse = the texture rect.
static func make_hero_shade_texture() -> GradientTexture2D:
	var g := Gradient.new()
	var navy := Color(0.012, 0.024, 0.070)
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in range(9):
		var t := float(i) / 8.0
		offs.append(t)
		# smooth (cosine) falloff from peak to 0
		cols.append(Color(navy.r, navy.g, navy.b, HERO_SHADE_ALPHA * (0.5 + 0.5 * cos(PI * t))))
	g.offsets = offs
	g.colors = cols
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex

## Scrubby's canonical placement (for layout, tests and evidence). k_v04 = the V04
## safe-box fit; k = k_v04 * SCRUBBY_SCALE, anchored at the visible soles.
func get_scrubby_canonical() -> Dictionary:
	var box: Rect2 = _world["scrubby_safe_box"]
	var feet: Vector2 = _world["scrubby_feet_anchor"]
	var vis := SCRUBBY_VISIBLE_BBOX
	var k_v04: float = minf(box.size.x / vis.size.x, (feet.y - box.position.y) / (SCRUBBY_FEET_Y - vis.position.y))
	var k: float = k_v04 * SCRUBBY_SCALE
	var origin := Vector2(feet.x - (vis.position.x + vis.size.x * 0.5) * k, feet.y - SCRUBBY_FEET_Y * k)
	return {"k": k, "k_v04": k_v04, "origin": origin, "visible_rect": Rect2(origin + vis.position * k, vis.size * k), "feet_y": origin.y + SCRUBBY_FEET_Y * k, "center_x": origin.x + (vis.position.x + vis.size.x * 0.5) * k}

# ------------------------------------------------------------ shortcuts ----

## SB-TF-03 activity button: the UiShortcutButton glass panel (HomeStyle.style_light_panel) at
## 0.7x size / icon box / label band / font and half the glass alpha. Intent only:
## shortcut_requested(id) (an Event button: "event:<instance id>").
func _make_activity_button(id: String, label: String) -> UiShortcutButton:
	var b := UiShortcutButton.new(id, label)
	b.label_band = PANEL_LABEL_BAND
	HomeStyle.style_light_panel(b, int(PANEL_SIZE.y) - PANEL_LABEL_BAND, PANEL_ALPHA, PANEL_BORDER)
	b.add_theme_font_size_override("font_size", PANEL_FONT)
	b.autowrap_mode = TextServer.AUTOWRAP_OFF   # one line; never wraps under the icon
	b.clip_text = true
	b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	b.custom_minimum_size = PANEL_SIZE
	b.set_icon_box(V03_ICON_BOX * PANEL_SCALE)
	return b

## Label fitted to the 0.7x panel: one line from PANEL_FONT down to PANEL_FONT_MIN (long locales /
## event names); still wider at the floor, it wraps to two lines in the label band (never cut).
const PANEL_FONT_MIN := 10
func _fit_label(b: Button) -> void:
	var avail: float = PANEL_SIZE.x - b.get_theme_stylebox("normal").get_minimum_size().x
	var fs := PANEL_FONT
	while fs > PANEL_FONT_MIN and b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
		fs -= 1
	b.add_theme_font_size_override("font_size", fs)
	var wide: bool = b.get_theme_font("font").get_string_size(b.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wide else TextServer.AUTOWRAP_OFF
	b.clip_text = not wide
	b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING if wide else TextServer.OVERRUN_TRIM_ELLIPSIS
	if wide:
		var st: StyleBoxFlat = b.get_theme_stylebox("normal")
		var lines := int(ceil(b.get_theme_font("font").get_multiline_string_size(b.text, HORIZONTAL_ALIGNMENT_CENTER, avail, fs, 2).y))
		for state in ["normal", "hover", "pressed", "disabled"]:
			(b.get_theme_stylebox(state) as StyleBoxFlat).content_margin_top = maxf(0.0, PANEL_SIZE.y - st.content_margin_bottom - lines)
		b.label_band = int(PANEL_SIZE.y - st.content_margin_top)   # the icon stands on the taller label
		b.set_icon_box(b.get_icon_box())

## The node name of a fixed activity button (Rewarded Ads keeps its M43-C015R name).
static func _activity_node(id: String) -> String:
	return "RewardedAdsButton" if id == "rewarded_ads" else "Shortcut_" + id

func _build_activity() -> void:
	var col: VBoxContainer = _nodes["LeftShortcutColumn"]
	for spec in ACTIVITY_FIXED:
		var id: String = spec[0]
		var b := _make_activity_button(id, UiText.t(spec[1]))
		b.name = _activity_node(id)
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		if id == "rewarded_ads":
			b.disabled = true   # until the app registers the destination
		b.pressed.connect(func():
			if not b.disabled:
				_shortcut_pressed(id))
		col.add_child(_reg(b))
		_nodes["ShortcutIcon_" + id] = b.icon_rect
		_fit_label(b)   # SB-M49-022: longer locales shrink, never widen

## SB-TF-03 auto-hide: true when the fixed activity `id` has nothing left to do today (a day
## rollover re-shows it). Locked entries keep their locked button.
func _activity_done(id: String) -> bool:
	if _app == null or _app.economy == null or _app.is_blocked or _locked(id):
		return false
	var e = _app.economy
	match id:
		"tasks":
			if not "orders" in e or e.orders == null:
				return false
			for o in e.orders.orders():
				if not o["claimed"]:
					return false
			return e.daily.all_tasks_bonus_claimed()
		"daily":
			return e.daily.claimed_today()
		"rewarded_ads":
			var rd = e.rewarded_daily
			return rd != null and rd.is_configured() and rd.current_slot() > rd.SLOTS
	return false

## Active Event instances with a reward not yet claimed, first-active order ([] while locked).
func _active_events() -> Array:
	if _app == null or _app.economy == null or _app.is_blocked or not _app.feature_unlocked("events") or not "events_v02" in _app.economy:
		return []
	return _app.economy.events_v02.list().filter(func(v): return v["phase"] == "active" and (v["steps"] as Array).any(func(s): return not s["claimed"]))

## Show / hide the activity buttons and lay them out (ACTIVITY_* placement rule). Event buttons
## are created / freed only when the shown set changes.
func _sync_activity() -> void:
	var left: Array = []
	for spec in ACTIVITY_FIXED:
		var b: UiShortcutButton = _nodes[_activity_node(spec[0])]
		b.visible = not _activity_done(spec[0])
		if b.visible:
			left.append(b)
	var events := _active_events().slice(0, ACTIVITY_MAX - left.size())
	var want := {}
	for v in events:
		want["Shortcut_event_" + String(v["id"])] = v
	for n in _event_buttons.keys():
		if not want.has(n):
			var old: Node = _event_buttons[n]
			if old.get_parent() != null:
				old.get_parent().remove_child(old)
			old.queue_free()
			_event_buttons.erase(n)
			_nodes.erase(n)
	var right: Array = []
	for n in want:
		var v: Dictionary = want[n]
		if not _event_buttons.has(n):
			var eid := String(v["id"])
			var b := _make_activity_button("event_" + eid, EventsV02Ui.title(eid))
			b.set_icon_texture(EventsV02Ui.art_texture(EventsV02Ui.ICON % eid))
			b.pressed.connect(func(): _shortcut_pressed("event:" + String(b.get_meta("iid"))))
			_event_buttons[n] = b
			_nodes[n] = b
		var eb: UiShortcutButton = _event_buttons[n]
		eb.set_meta("iid", String(v["iid"]))
		var claim := int(v["claimable"])
		eb.set_badge_text(str(claim) if claim > 0 else (UiText.t("HOME_BADGE_NEW") if HomeBadges.new_features(_app).has("events") else ""))
		if right.size() < ACTIVITY_PER_COLUMN:
			right.append(eb)
		else:
			left.append(eb)
	for pair in [["LeftShortcutColumn", left], ["RightShortcutColumn", right]]:
		var col: VBoxContainer = _nodes[pair[0]]
		var i := 0
		for b in pair[1]:
			if b.get_parent() != col:
				if b.get_parent() != null:
					b.get_parent().remove_child(b)
				col.add_child(b)
				_fit_label(b)
			b.size_flags_horizontal = Control.SIZE_SHRINK_END if pair[0] == "LeftShortcutColumn" else Control.SIZE_SHRINK_BEGIN
			col.move_child(b, i)
			i += 1

## The activity buttons currently shown, per column (tests / evidence).
func get_activity_layout() -> Dictionary:
	var out := {}
	for side in ["LeftShortcutColumn", "RightShortcutColumn"]:
		out[side] = (_nodes[side] as Node).get_children().filter(func(b): return (b as Control).visible).map(func(b): return String(b.name))
	return out

# ------------------------------------------------------------- Play CTA ----

## Centred standalone CTA (V03 size): live PLAY, native white triangle, compact live
## frontier subtitle. The status pill floats just above the button (no layout change).
const PLAY_SIZE := Vector2(470, 150)
const JOURNEY_SIZE := Vector2(720, 84)   ## V02 owner remediation: larger (V01 560x58)
const JOURNEY_GAP := 6.0
func _build_play(parent: VBoxContainer) -> void:
	var play := Button.new()
	play.name = "PlayButton"
	play.text = UiText.t("HOME_PLAY")
	play.custom_minimum_size = PLAY_SIZE
	play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play.focus_mode = Control.FOCUS_ACCESSIBILITY
	play.add_theme_font_size_override("font_size", 76)
	HomeStyle.style_play_button(play)
	HomeStyle.style_play_label_navy(play)
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
	# M43-C001R (SB-M43-R01-005..007): compact non-interactive 10-Level Cleaning Journey,
	# attached ABOVE the PLAY button like the status pill, so it takes no layout slot and
	# moves nothing in the accepted Home stack. The status pill rides above it when shown.
	var strip := JourneyStrip.new()
	strip.name = "HomeJourneyStrip"
	strip.backplate = true
	strip.custom_minimum_size = Vector2(0, 0)
	strip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	strip.offset_left = -JOURNEY_SIZE.x * 0.5
	strip.offset_right = JOURNEY_SIZE.x * 0.5
	strip.offset_top = -JOURNEY_SIZE.y - JOURNEY_GAP
	strip.offset_bottom = -JOURNEY_GAP
	strip.visible = false
	play.add_child(_reg(strip))

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

# ---------------------------------------------------------------- badges ----

## Red top-right count pill (hidden until it has text).
func _badge_label(n: String) -> Label:
	var nb := Label.new()
	nb.name = n
	nb.visible = false
	nb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nb.add_theme_font_size_override("font_size", 24)
	nb.add_theme_color_override("font_color", Color(1, 1, 1))
	nb.add_theme_stylebox_override("normal", HomeStyle.box(Color(0.86, 0.12, 0.12), Color(0.5, 0.05, 0.05), 3, 18, 0))
	nb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	nb.offset_left = -58
	nb.offset_right = -10
	nb.offset_top = 6
	nb.offset_bottom = 42
	nb.grow_horizontal = Control.GROW_DIRECTION_BEGIN   # SB-M44-013 "NEW" pill grows inward
	return nb

# ------------------------------------------------------------ ad slot ----

## SB-TF-03 persistent banner area below PLAY. Empty integration seam: the ad SDK view is
## attached to get_ad_mount(); the No Ads entitlement (AdService.allowed("banner") false, wired
## by main.gd) collapses it with set_ad_slot_enabled(false). No fake content.
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
	(_nodes["BottomActionStack"] as VBoxContainer).add_theme_constant_override("separation", gap)
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
const MODAL_HIDDEN := ["HomeActionLayer", "ScrubBucksPlus", "HeartsPlus", "GiftMeterButton", "ProfileButton", "SettingsButton"]
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
	_nodes["HomeScrubbyHero"].set_modal(modal)
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
	_render_journey(status)
	_render_values()
	if _flight != null and _flight.is_running():
		_flight.reapply()   # the HUD keeps counting from the pre-win values
	# F012: only a VISIBLE render is compared (a hidden refresh keeps the last seen baseline).
	if is_visible_in_tree():
		_micro.observe(_vm, {"frontier": _nodes["HomeJourneyStrip"] if _nodes["HomeJourneyStrip"].visible else play,
			"bot_parts": _nodes["ProfileBotParts"]})

func _render_values() -> void:
	_vm = HomeViewModel.build(_app)
	if not _vm.get("ok", false):
		return
	(_nodes["ProfileName"] as Label).text = UiText.t("HOME_PLAYER_NAME_DEFAULT")
	# M43-C008 (SB-M43-108): the active robot's name + approved portrait (Scrubby keeps the
	# owner-approved Home binding; another robot uses its own portrait, Scrubby on missing art).
	var active: String = _app.economy.robots.active_robot() if "economy" in _app and _app.economy != null else ""
	var pr := _nodes["ProfilePortrait"] as TextureRect
	if not pr.has_meta("binder_tex"):
		pr.set_meta("binder_tex", pr.texture)
	if not active.is_empty() and active != String(RobotRoster.load_roster()["initial_robot_id"]):
		(_nodes["ProfileName"] as Label).text = String(RobotRoster.entry(active).get("name", UiText.t("HOME_PLAYER_NAME_DEFAULT")))
		pr.texture = load(RobotRoster.asset(active, "portrait"))
	else:
		pr.texture = pr.get_meta("binder_tex")
	var w := WorldService.world_for_level(int(_vm["level"]))
	# Owner 2026-11-17: the title is the current world's name (same source as the world ceremony).
	_set_area_text("HomeAreaTitle", UiText.t("HOME_AREA_WORLD", [UiText.caps(UiText.data("WORLD_NAME_%d" % int(w["number"]), String(w["name"])))]) if not w.is_empty() else "")
	_set_area_text("HomeAreaNumber", UiText.t("HOME_AREA_NUMBER", [int(w["number"])]) if not w.is_empty() else "")
	# Bot Parts toward the next 250-part robot (canonical wallet / RobotUnlockService),
	# never XP — only the live ratio, centred in the bar; gold bar when unlockable.
	var parts: UiProgressMeter = _nodes["ProfileBotParts"]
	parts.set_progress(_vm["bot_parts"], _vm["bot_parts_target"],
		UiText.t("HOME_RATIO", [UiText.num(_vm["bot_parts"]), UiText.num(_vm["bot_parts_target"])]))
	HomeStyle.style_meter(parts.bar, HomeStyle.GOLD if _vm["robot_can_unlock"] else HomeStyle.GREEN, 42)
	var sb: UiValueChip = _nodes["ScrubBucksChip"]
	sb.set_tag(UiText.t("HOME_CURRENCY_SB"))
	sb.set_value(UiText.num(_vm["scrub_bucks"]))
	# V06: count on the heart icon; the pill shows the regen clock
	# (HeartService.seconds_to_next()) only below max; at max it reads FULL (owner 2026-11-12).
	var hearts: UiValueChip = _nodes["HeartsChip"]
	(_nodes["HeartsCount"] as Label).text = str(_vm["hearts"])
	var full: bool = _vm["hearts"] >= _vm["hearts_max"]
	hearts.set_value(UiText.t("LIFE_REFILL_FULL") if full else _mmss(_vm["heart_seconds_to_next"]))
	hearts.set_sub("")
	# SB-POLISH-002: the bar fills towards the NEXT milestone (0/1, 1/5, ... 500/1,000). The
	# overlay gets the same 0..next scale, so it draws only the current gap's micro-ticks.
	var gnext := int(_vm["gift_next_milestone"])
	(_nodes["GiftMeterBar"] as UiProgressMeter).set_progress(_vm["gift_progress"], gnext,
		UiText.t("HOME_RATIO", [UiText.num(_vm["gift_progress"]), UiText.num(gnext)]))
	var gm := GiftProgressModel.build(int(_vm["gift_progress"]), int(_vm["gift_cycle_max"]))
	gm["cycle_max"] = gnext
	(_nodes["GiftTickOverlay"] as GiftTickOverlay).set_model(gm, [], "effects" in _app and _app.effects != null and _app.effects.is_reduced())
	var gleft := int(_vm["gift_window_seconds_left"])
	(_nodes["GiftWindowLeft"] as Label).visible = gleft > 0
	(_nodes["GiftWindowLeft"] as Label).text = UiText.time_left(gleft)
	var gbadge: Label = _nodes["GiftClaimableBadge"]
	gbadge.text = str(_vm["gift_claimable"])
	gbadge.visible = _vm["gift_claimable"] > 0
	# SB-M42-024: Daily badge = 1 when today's login reward is claimable.
	var counts := {"daily": 0 if _vm["daily_claimed_today"] or _locked("daily") else 1}
	# M43-C010 (SB-M43-134): Tasks shortcut; SB-TF-03: the profile card carries the Profile
	# destinations' attention (claimable achievements + unseen robots + new collection cards).
	if "orders" in _app.economy and _app.economy.orders != null:
		var bd := HomeBadges.compute(_app)
		counts["tasks"] = 0 if _locked("tasks") else int(bd["tasks"])
		var profile_n: int = int(bd["achievements"])
		for cid in ["robots", "collection"]:
			profile_n += 0 if _locked(cid) else int(bd[cid])
		var pb: Label = _nodes["ProfileBadge"]
		# SB-M44-013: a newly unlocked Profile destination shows NEW here until visited there.
		var fresh_profile: bool = HomeBadges.new_features(_app).any(func(f): return ["robots", "collection", "leaderboard"].has(f))
		pb.text = str(profile_n) if profile_n > 0 else (UiText.t("HOME_BADGE_NEW") if fresh_profile else "")
		pb.visible = not pb.text.is_empty()
		# M47-TOUCH-R01: red "1" while the next sequential Rewarded Ads reward is actionable (only
		# when the app serves that destination).
		(_nodes["RewardedAdsButton"] as UiShortcutButton).set_badge(int(bd["rewarded_ads"]) if _app_shortcuts.has("rewarded_ads") else 0)
	# SB-M44-013: a newly unlocked, unvisited entry shows "NEW" unless it has a real count.
	var fresh := HomeBadges.new_features(_app)
	var badge_text := func(bid: String) -> String:
		var c := int(counts.get(bid, 0))
		return str(c) if c > 0 else (UiText.t("HOME_BADGE_NEW") if fresh.has(bid) else "")
	for sid in ["tasks", "daily"]:
		(_nodes["Shortcut_" + sid] as UiShortcutButton).set_badge_text(badge_text.call(sid))
	for sid in ["tasks", "daily"]:
		var sc: Button = _nodes["Shortcut_" + sid]
		sc.disabled = _locked(sid) or not (LIVE_SHORTCUTS.has(sid) or _app_shortcuts.has(sid))
		sc.tooltip_text = _unlock_text(sid) if _locked(sid) else ""
		sc.accessibility_description = sc.tooltip_text
	(_nodes["RewardedAdsButton"] as Button).disabled = not _app_shortcuts.has("rewarded_ads")
	_sync_activity()
	for pid in _popups:
		if (_popups[pid] as Control).visible:
			_render_popup(pid)


# ------------------------------------------------------------- popups ----

## M43: shortcuts the app root opens as app-level destinations (set by main.gd). A standalone
## Home (tests / tools without the app root) keeps its M42 popups.
var _app_shortcuts: Array = []
## SB-TF-03: node name -> the live Event activity button.
var _event_buttons: Dictionary = {}

## SB-M44-031: true while the Home entry `id` is behind the owner unlock table.
func _locked(id: String) -> bool:
	if id.begins_with("event:"):
		id = "events"
	return GATED_ENTRIES.has(id) and _app != null and not _app.feature_unlocked(GATED_ENTRIES[id])

func _unlock_text(id: String) -> String:
	return UiText.t("HOME_UNLOCKS_AT_LEVEL", [_app.feature_unlock_level(GATED_ENTRIES[id])])

func set_app_shortcuts(ids: Array) -> void:
	_app_shortcuts = ids.duplicate()
	refresh()

func _shortcut_pressed(id: String) -> void:
	if _locked(id):
		return
	_mark_visited("events" if id.begins_with("event:") else id)
	shortcut_requested.emit(id)
	if not _app_shortcuts.has(id):
		open_popup(id)

## SB-M44-013: the first press of a NEW entry acknowledges it (meta_ui presentation ledger,
## canonical save, same path as the ceremony / What's New acknowledgements).
func _mark_visited(id: String) -> void:
	if not HomeBadges.new_features(_app).has(id):
		return
	if _app.economy.meta_ui.mark_seen(HomeBadges.visited_key(GATED_ENTRIES[id])):
		_app.request_save()
	refresh()

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
		var rewards: Dictionary = GiftProgressModel.GiftMeterService.milestone_rewards(int(occ["milestone"]), _app.economy.config)
		rows.append({"text": UiText.t("GIFTS_ROW", [UiText.num(int(occ["milestone"])), UiText.reward_text(rewards)]),
			"action_id": String(occ["id"]), "action_text": UiText.t("POPUP_CLAIM"), "action_enabled": not _app.is_blocked})
	var note := ""
	if rows.is_empty():
		note = UiText.t("GIFTS_EMPTY")
	elif _app.is_blocked:
		note = UiText.t("GIFTS_READ_ONLY")
	# M43-C005R: the same normalized Gift Meter model Home / Results use (presentation only).
	var gm := GiftProgressModel.from_service(_app.economy.gift)
	var progress := UiText.t("GIFTS_PROGRESS", [UiText.num(gm["progress"]), UiText.num(gm["next"])])
	popup.set_content(UiText.t("GIFTS_TITLE"), rows, progress if note.is_empty() else note + "\n" + progress)

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
			rows.append({"text": UiText.tn("CARDS_ROW", n, [cid, UiText.num(n), UiText.num(v)])})
	var note := UiText.t("CARDS_EMPTY") if rows.is_empty() else UiText.tn("CARDS_NOTE", int(_vm.get("cards_duplicates", 0)), [UiText.num(int(_vm.get("cards_duplicates", 0))), UiText.num(total_sb)])
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
	popup.set_content(UiText.t("DAILY_TITLE"), rows, UiText.tn("DAILY_STREAK", int(d.display_streak()), [UiText.num(int(d.display_streak()))]))

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

## M43-C005F-PHASE4 (F012): bind the app's feel adapter (null = no micro feel). Presentation only.
func set_feedback(adapter) -> void:
	_micro.bind(adapter)
	_feel_adapter = adapter
	if _flight != null:
		_flight.bind_feel(adapter)

# ------------------------------------------------- SB-PHONE-2026-11-12-E reward flight --

## Fly one win's committed rewards (its TerminalRewardReceipt) into the HUD, once per `key`.
## False = not built, already played, or nothing to show. Reduced Effects lands at once.
func play_reward_flight(receipt: Dictionary, key: String) -> bool:
	if not _built or _flight == null:
		return false
	return _flight.play(receipt, key, _app != null and "effects" in _app and _app.effects != null and _app.effects.is_reduced())

func is_reward_flight_running() -> bool:
	return _flight != null and _flight.is_running()

func get_reward_flight():
	return _flight

## One counted HUD value of the flight (`v` between the pre-win and the live value).
func show_hud_value(kind: String, v: float) -> void:
	if not _built or not _vm.get("ok", false):
		return
	var n := int(round(v))
	match kind:
		"scrub_bucks":
			(_nodes["ScrubBucksChip"] as UiValueChip).set_value(UiText.num(n))
		"bot_parts":
			(_nodes["ProfileBotParts"] as UiProgressMeter).set_progress(n, _vm["bot_parts_target"],
				UiText.t("HOME_RATIO", [UiText.num(n), UiText.num(_vm["bot_parts_target"])]))
		"gift_meter":
			var gnext := GiftProgressModel.next_milestone(n)
			(_nodes["GiftMeterBar"] as UiProgressMeter).set_progress(n, gnext, UiText.t("HOME_RATIO", [UiText.num(n), UiText.num(gnext)]))
			var gm := GiftProgressModel.build(n, int(_vm["gift_cycle_max"]))
			gm["cycle_max"] = gnext
			(_nodes["GiftTickOverlay"] as GiftTickOverlay).set_model(gm, [], _app.effects.is_reduced())

## Home hidden (PLAY, route change): a running flight lands its final state at once.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not visible and _flight != null:
		_flight.finish()

func get_micro_feel():
	return _micro

func get_view_model() -> Dictionary:
	return _vm.duplicate(true)

## SB-M42-003: the ONE CTA launches only the canonical progression frontier. SB-TF-03: the
## button reads "PLAY · LEVEL N" (N = the level PLAY launches), font-fitted to the button; the
## live subtitle still carries the frontier: no completed level -> "LEVEL N"; otherwise
## "CONTINUE · LEVEL N". A frontier without catalog content is shown honestly and disabled
## (no fallback, no picker).
const PLAY_FONT := 76
const PLAY_FONT_MIN := 30
func _render_play(play: Button, status: Label) -> void:
	_launch = GameplayLaunchResolver.resolve(_app)
	var level := int(_launch.get("level", _app.progression.current_level()))
	var first_time: bool = _app.progression.completed_count() == 0
	var text := UiText.t("HOME_PLAY_LEVEL", [level])
	if play.text != text:
		var avail: float = PLAY_SIZE.x - play.get_theme_stylebox("normal").get_minimum_size().x - 2.0 * play.get_theme_constant("outline_size")
		var fs := PLAY_FONT
		while fs > PLAY_FONT_MIN and play.get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
			fs -= 1
		play.add_theme_font_size_override("font_size", fs)   # before the text: never a wider frame
		play.text = text
	(_nodes["PlaySubtitle"] as Label).text = UiText.t("HOME_START_LEVEL", [level]) if first_time else UiText.t("HOME_CONTINUE_LEVEL", [level])
	if _launch.get("ok", false):
		play.disabled = false
		status.text = ""
		# CP06: truthful, non-rewarding notice after a disabled-level skip (no ceremony).
		var notice = _app.get("skip_notice")
		if typeof(notice) == TYPE_ARRAY and not notice.is_empty():
			var nums := PackedStringArray()
			for n in notice:
				nums.append(str(n))
			status.text = UiText.t("HOME_LEVEL_SKIPPED", [", ".join(nums), level])
	elif _launch.get("reason", "") == GameplayLaunchResolver.CONTENT_MISSING:
		play.disabled = true
		status.text = UiText.t("HOME_LEVEL_COMING_SOON", [level])
	else:
		play.disabled = true
		status.text = UiText.t("HOME_LEVELS_UNAVAILABLE", [String(_launch.get("reason", ""))])

## M43-C001R: the shared ResultsMomentum journey for the current frontier (Home semantics).
func set_momentum_config(cfg: Dictionary) -> void:
	_momentum_cfg = cfg.duplicate(true)
	if _built:
		refresh()

func _render_journey(status: Label) -> void:
	if _momentum_cfg.is_empty():
		_momentum_cfg = ResultsMomentum.load_config()
	var strip = _nodes["HomeJourneyStrip"]
	var j: Dictionary = ResultsMomentum.home_journey(_app, _momentum_cfg) if _app != null and not _app.is_blocked else {"ok": false}
	strip.set_model(j)
	status.offset_top = -8.0 - (JOURNEY_SIZE.y + JOURNEY_GAP if strip.visible else 0.0)
	status.offset_bottom = status.offset_top

func get_journey_strip():
	return _nodes.get("HomeJourneyStrip")

func get_launch_preview() -> Dictionary:
	return _launch.duplicate(true)
