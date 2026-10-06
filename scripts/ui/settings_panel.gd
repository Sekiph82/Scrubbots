extends Control
## SettingsPanel — res://scenes/ui/settings_panel.tscn (preload this script; AL-001).
##
## M41-C001 V01 early audio/haptics Settings slice (SB-M41-001/002/003/004/006/007).
## Native responsive Godot Controls only (MASTER_UI_SYSTEM: touch >= 88 ref px, body 30,
## button 34, title 48). The panel holds NO settings state of its own: every control reads
## from and writes through the ONE canonical AppState (M40) —
##   Master / Music / SFX: ON/OFF toggle + 0..100% slider + current value label;
##   Haptics: ON/OFF toggle.
## Changes apply live (AudioServer bus / live HapticsController binding). Toggles persist
## immediately; a slider applies live while dragging and persists on drag end, on Close,
## and at the app lifecycle flush. The panel never touches gameplay state.
##
## M41-C002 (SB-M41-005): REDUCED EFFECTS toggle -> AppState.set_reduced_effects (canonical,
## persisted immediately, applied live to gameplay cleaning FX).

signal closed

const BasePopup = preload("res://scripts/ui/popup/base_popup.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")

const BUSES := ["master", "music", "sfx"]
const BUS_TITLES := {"master": "MASTER", "music": "MUSIC", "sfx": "SOUND FX"}

const TOUCH_MIN := 88
const FONT_BODY := 30
const FONT_BUTTON := 34
const FONT_TITLE := 48
const DIM := Color(0.0, 0.0, 0.0, 0.6)

var _app = null
var _toggles: Dictionary = {}    ## bus -> CheckButton
var _sliders: Dictionary = {}    ## bus -> HSlider
var _values: Dictionary = {}     ## bus -> Label
var _haptics_toggle: CheckButton
var _reduced_toggle: CheckButton
var _status: Label
var _built := false
var _frame = null

func _ready() -> void:
	_build()
	_sync_from_state()

## Bind the canonical AppState (main.gd / debug host). Re-syncs the controls.
func bind(app_state) -> void:
	_app = app_state
	if _built:
		_sync_from_state()

func _build() -> void:
	if _built:
		return
	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = HomeStyle.make_theme()

	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# 16 px side gutter at phone width; the panel is width-bounded on wide screens.
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var center := CenterContainer.new()
	margin.add_child(center)

	# M43-C015R (SB-M43-R15-002): the canonical M43 popup family. "Panel" keeps its role (the
	# bounded settings box) but now holds BasePopup's own FrameBox with the promoted large
	# cyan/white frame; inside: royal SETTINGS plaque + top-right X, cream setting cards, navy
	# text, themed switches / sliders, tan CLOSE. Presentation only (no state / behaviour change).
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	center.add_child(panel)
	_frame = BasePopup.FrameBox.new()
	_frame.name = "Frame"
	_frame.set_frame(BasePopup.FRAMES["large"])
	panel.add_child(_frame)
	_fit_frame()

	var col := VBoxContainer.new()
	col.name = "Body"
	col.add_theme_constant_override("separation", 16)
	_frame.set_body(col)

	var head := HBoxContainer.new()
	head.name = "Header"
	head.add_theme_constant_override("separation", 12)
	col.add_child(head)
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(TOUCH_MIN, 0)
	balance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(balance)
	var pill := PanelContainer.new()
	pill.name = "TitlePill"
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROYAL, BasePopup.ROYAL_EDGE, 5, 30, 6, 6), 24, 10))
	head.add_child(pill)
	var title := Label.new()
	title.name = "Title"
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	pill.add_child(title)
	var x := Button.new()
	x.name = "CloseX"
	x.text = "X"
	x.focus_mode = Control.FOCUS_NONE
	x.custom_minimum_size = Vector2(TOUCH_MIN, TOUCH_MIN)
	x.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for st in ["normal", "hover", "pressed", "disabled"]:
		x.add_theme_stylebox_override(st, HomeStyle.box(BasePopup.ROYAL, BasePopup.ROYAL_EDGE, 4, 44, 4, 3))
	x.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	x.add_theme_font_size_override("font_size", 38)
	x.pressed.connect(close_panel)
	head.add_child(x)

	for bus in BUSES:
		col.add_child(_card(_make_audio_row(bus)))

	_haptics_toggle = _make_toggle("VIBRATION")
	_haptics_toggle.name = "HapticsToggle"
	_haptics_toggle.toggled.connect(_on_haptics_toggled)
	col.add_child(_card(_haptics_toggle))

	_reduced_toggle = _make_toggle("REDUCED EFFECTS")
	_reduced_toggle.name = "ReducedEffectsToggle"
	_reduced_toggle.toggled.connect(_on_reduced_toggled)
	col.add_child(_card(_reduced_toggle))

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", FONT_BODY)
	_ink(_status)
	col.add_child(_status)

	var close := Button.new()
	close.name = "CloseButton"
	close.text = "CLOSE"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, TOUCH_MIN)
	close.add_theme_font_size_override("font_size", FONT_BUTTON)
	var tan := HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 4, 30, 4, 4)
	for st in ["normal", "hover", "pressed", "disabled"]:
		close.add_theme_stylebox_override(st, tan)
	close.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		close.add_theme_color_override(c, BasePopup.INK)
	close.add_theme_constant_override("outline_size", 0)
	close.pressed.connect(close_panel)
	col.add_child(close)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _frame != null:
		_fit_frame()

## Frame width: the BasePopup reference width, bounded by the 16 px phone gutter.
func _fit_frame() -> void:
	_frame.set_width(minf(BasePopup.FRAME_WIDTH, _ref_width() - 32.0))

func _ref_width() -> float:
	if size.x > 0.0:
		return size.x
	var vp := get_viewport()
	return vp.get_visible_rect().size.x if vp != null else 1080.0

## Cream setting card (BasePopup ROW family) around one control group.
func _card(inner: Control) -> Control:
	var card := PanelContainer.new()
	card.name = "Card_" + String(inner.name)
	card.add_theme_stylebox_override("panel", HomeStyle.pad(HomeStyle.box(BasePopup.ROW, BasePopup.ROW_EDGE, 4, 26, 4, 4), 20, 6))
	card.add_child(inner)
	return card

static func _ink(l: Control) -> void:
	l.add_theme_color_override("font_color", BasePopup.INK)
	l.add_theme_constant_override("outline_size", 0)

func _make_toggle(text: String) -> CheckButton:
	var t := CheckButton.new()
	t.text = text
	t.focus_mode = Control.FOCUS_NONE
	t.custom_minimum_size = Vector2(0, TOUCH_MIN)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("font_size", FONT_BUTTON)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.add_theme_color_override(c, BasePopup.INK)
	t.add_theme_color_override("font_disabled_color", Color(BasePopup.INK, 0.45))
	t.add_theme_constant_override("outline_size", 0)
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		t.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var icons := _switch_icons()
	t.add_theme_icon_override("checked", icons["on"])
	t.add_theme_icon_override("unchecked", icons["off"])
	t.add_theme_icon_override("checked_disabled", icons["on_disabled"])
	t.add_theme_icon_override("unchecked_disabled", icons["off_disabled"])
	return t

func _make_audio_row(bus: String) -> Control:
	var box := VBoxContainer.new()
	box.name = "Row_" + bus
	box.add_theme_constant_override("separation", 4)
	var t := _make_toggle(BUS_TITLES[bus])
	t.toggled.connect(_on_bus_toggled.bind(bus))
	box.add_child(t)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 16)
	box.add_child(line)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.custom_minimum_size = Vector2(0, TOUCH_MIN)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_slider(s)
	s.value_changed.connect(_on_slider_changed.bind(bus))
	s.drag_ended.connect(_on_slider_drag_ended.bind(bus))
	line.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(120, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_font_size_override("font_size", FONT_BODY)
	_ink(v)
	line.add_child(v)
	_toggles[bus] = t
	_sliders[bus] = s
	_values[bus] = v
	return box

## Themed slider: navy-edged light track, green fill, white grabber with a royal ring.
static func _style_slider(s: HSlider) -> void:
	var track := HomeStyle.box(Color(0.86, 0.90, 0.95), BasePopup.ROYAL_EDGE, 2, 12, 0)
	track.content_margin_top = 9
	track.content_margin_bottom = 9
	s.add_theme_stylebox_override("slider", track)
	var fill := HomeStyle.box(HomeStyle.GREEN, HomeStyle.GREEN_EDGE, 2, 12, 0)
	fill.content_margin_top = 9
	fill.content_margin_bottom = 9
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var icons := _switch_icons()
	s.add_theme_icon_override("grabber", icons["grabber"])
	s.add_theme_icon_override("grabber_highlight", icons["grabber"])
	s.add_theme_icon_override("grabber_disabled", icons["grabber_disabled"])

## Native switch / grabber textures (drawn once, no new art assets).
static var _icons_cache: Dictionary = {}
static func _switch_icons() -> Dictionary:
	if not _icons_cache.is_empty():
		return _icons_cache
	var grey := Color(0.62, 0.66, 0.72)
	_icons_cache = {
		"on": _switch(HomeStyle.GREEN, HomeStyle.GREEN_EDGE, true, 1.0),
		"off": _switch(grey, Color(0.40, 0.44, 0.50), false, 1.0),
		"on_disabled": _switch(HomeStyle.GREEN, HomeStyle.GREEN_EDGE, true, 0.45),
		"off_disabled": _switch(grey, Color(0.40, 0.44, 0.50), false, 0.45),
		"grabber": _knob(1.0),
		"grabber_disabled": _knob(0.45),
	}
	return _icons_cache

static func _switch(fill: Color, edge: Color, on: bool, alpha: float) -> ImageTexture:
	var w := 112
	var h := 60
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var r := h * 0.5
	var knob_c := Vector2(w - r, r) if on else Vector2(r, r)
	for y in range(h):
		for x in range(w):
			var p := Vector2(x + 0.5, y + 0.5)
			var q := Vector2(clampf(p.x, r, w - r), r)
			var d := p.distance_to(q)
			var c := Color(0, 0, 0, 0)
			if d <= r:
				c = edge if d > r - 4.0 else fill
				var kd := p.distance_to(knob_c)
				if kd <= r - 7.0:
					c = Color(1, 1, 1) if kd <= r - 9.0 else edge
				c.a = clampf(r - d + 0.5, 0.0, 1.0) * alpha
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

static func _knob(alpha: float) -> ImageTexture:
	var n := 52
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var r := n * 0.5
	for y in range(n):
		for x in range(n):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(r, r))
			var c := Color(0, 0, 0, 0)
			if d <= r:
				c = BasePopup.ROYAL_EDGE if d > r - 6.0 else Color(1, 1, 1)
				c.a = clampf(r - d + 0.5, 0.0, 1.0) * alpha
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------------ sync ----

func _usable() -> bool:
	return _app != null and not _app.is_blocked

## Pull every control from canonical state without re-emitting change signals.
func _sync_from_state() -> void:
	if not _built:
		return
	var usable := _usable()
	for bus in BUSES:
		var on := true
		var vol := 1.0
		if _app != null:
			on = _bus_enabled(bus)
			vol = _bus_volume(bus)
		(_toggles[bus] as CheckButton).set_pressed_no_signal(on)
		(_sliders[bus] as HSlider).set_value_no_signal(vol)
		(_toggles[bus] as CheckButton).disabled = not usable
		(_sliders[bus] as HSlider).editable = usable and on
		_update_value_label(bus)
	_haptics_toggle.set_pressed_no_signal(_app.haptics.is_enabled() if _app != null else true)
	_haptics_toggle.disabled = not usable
	_reduced_toggle.set_pressed_no_signal(_app.effects.is_reduced() if _app != null else false)
	_reduced_toggle.disabled = not usable
	if _app == null:
		_status.text = "Settings unavailable"
	elif _app.is_blocked:
		_status.text = "Save blocked: settings are read-only"
	else:
		_status.text = ""

func _bus_volume(bus: String) -> float:
	match bus:
		"master": return _app.audio.get_master_volume()
		"music": return _app.audio.get_music_volume()
		_: return _app.audio.get_sfx_volume()

func _bus_enabled(bus: String) -> bool:
	match bus:
		"master": return _app.audio.is_master_enabled()
		"music": return _app.audio.is_music_enabled()
		_: return _app.audio.is_sfx_enabled()

func _update_value_label(bus: String) -> void:
	var on: bool = (_toggles[bus] as CheckButton).button_pressed
	var pct := int(round((_sliders[bus] as HSlider).value * 100.0))
	(_values[bus] as Label).text = ("%d%%" % pct) if on else "OFF"

# ------------------------------------------------------------- handlers ----

func _on_bus_toggled(on: bool, bus: String) -> void:
	if not _usable():
		_sync_from_state()
		return
	_app.set_audio_enabled(bus, on)
	(_sliders[bus] as HSlider).editable = on
	_update_value_label(bus)

func _on_slider_changed(value: float, bus: String) -> void:
	if not _usable():
		_sync_from_state()
		return
	_app.set_audio_volume(bus, value, false)   # live apply; persisted on drag end / close
	_update_value_label(bus)

func _on_slider_drag_ended(value_changed: bool, _bus: String) -> void:
	if value_changed and _usable():
		_app.flush_if_dirty()

func _on_haptics_toggled(on: bool) -> void:
	if not _usable():
		_sync_from_state()
		return
	_app.set_haptics_enabled(on)

func _on_reduced_toggled(on: bool) -> void:
	if not _usable():
		_sync_from_state()
		return
	_app.set_reduced_effects(on)

## Persist any pending slider change and hide the panel.
func close_panel() -> void:
	if _usable():
		_app.flush_if_dirty()
	hide()
	closed.emit()

## Re-sync and show (e.g. from a Settings button).
func open_panel() -> void:
	_sync_from_state()
	show()

# ---------------------------------------------------------- test accessors ----

func get_toggle(bus: String) -> CheckButton:
	return _toggles.get(bus)

func get_slider(bus: String) -> HSlider:
	return _sliders.get(bus)

func get_value_label(bus: String) -> Label:
	return _values.get(bus)

func get_haptics_toggle() -> CheckButton:
	return _haptics_toggle

func get_reduced_effects_toggle() -> CheckButton:
	return _reduced_toggle
