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

const BG01 := Color(0.125, 0.145, 0.2, 1.0)   ## Midnight Slate #202533.

var _app = null
var _built := false
var _nodes: Dictionary = {}   ## region name -> Control
## Last frontier resolution shown on the CTA (SB-M42-003). Read-only presentation copy.
var _launch: Dictionary = {}

func _ready() -> void:
	_build()
	refresh()

## Bind the canonical AppState (app root). Re-renders.
func bind(app_state) -> void:
	_app = app_state
	if _built:
		refresh()

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

	var nav := HBoxContainer.new()
	nav.name = "BottomNav"
	nav.custom_minimum_size = Vector2(0, UiTokens.TOUCH_MIN)
	nav.add_theme_constant_override("separation", UiTokens.SPACE_XS)
	layout.add_child(nav)
	_nodes["BottomNav"] = nav
	_build_bottom_nav(nav)

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
