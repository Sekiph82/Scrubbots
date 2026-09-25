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

const BUSES := ["master", "music", "sfx"]
const BUS_TITLES := {"master": "MASTER", "music": "MUSIC", "sfx": "SOUND FX"}

const TOUCH_MIN := 88
const FONT_BODY := 30
const FONT_BUTTON := 34
const FONT_TITLE := 48
const BG := Color(0.125, 0.145, 0.2, 1.0)        ## BG01 Midnight Slate #202533.
const DIM := Color(0.0, 0.0, 0.0, 0.6)

var _app = null
var _toggles: Dictionary = {}    ## bus -> CheckButton
var _sliders: Dictionary = {}    ## bus -> HSlider
var _values: Dictionary = {}     ## bus -> Label
var _haptics_toggle: CheckButton
var _reduced_toggle: CheckButton
var _status: Label
var _built := false

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

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(minf(960.0, _ref_width() - 32.0), 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = BG
	sb.set_corner_radius_all(28)
	sb.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 24)
	panel.add_child(col)

	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", FONT_TITLE)
	col.add_child(title)

	for bus in BUSES:
		col.add_child(_make_audio_row(bus))

	_haptics_toggle = _make_toggle("VIBRATION")
	_haptics_toggle.name = "HapticsToggle"
	_haptics_toggle.toggled.connect(_on_haptics_toggled)
	col.add_child(_haptics_toggle)

	_reduced_toggle = _make_toggle("REDUCED EFFECTS")
	_reduced_toggle.name = "ReducedEffectsToggle"
	_reduced_toggle.toggled.connect(_on_reduced_toggled)
	col.add_child(_reduced_toggle)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", FONT_BODY)
	col.add_child(_status)

	var close := Button.new()
	close.name = "CloseButton"
	close.text = "CLOSE"
	close.custom_minimum_size = Vector2(0, TOUCH_MIN)
	close.add_theme_font_size_override("font_size", FONT_BUTTON)
	close.pressed.connect(close_panel)
	col.add_child(close)

func _ref_width() -> float:
	var vp := get_viewport()
	return vp.get_visible_rect().size.x if vp != null else 1080.0

func _make_toggle(text: String) -> CheckButton:
	var t := CheckButton.new()
	t.text = text
	t.custom_minimum_size = Vector2(0, TOUCH_MIN)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("font_size", FONT_BUTTON)
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
	s.value_changed.connect(_on_slider_changed.bind(bus))
	s.drag_ended.connect(_on_slider_drag_ended.bind(bus))
	line.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(120, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_font_size_override("font_size", FONT_BODY)
	line.add_child(v)
	_toggles[bus] = t
	_sliders[bus] = s
	_values[bus] = v
	return box

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
