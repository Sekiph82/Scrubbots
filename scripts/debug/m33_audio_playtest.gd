extends Control
## M33 Audio manual playtest. Open/instantiate res://scenes/debug/m33_audio_playtest.tscn
## and run it in graphical Godot (F6). Owner F6 audio listening gate — Claude cannot self-close M33.
##
## Hosts the REAL production stack (ProductionGameplayHost) on the 20x20 Hazard Bot level, so
## dispatch/cleaning/completion audio fires from the ACTUAL authoritative gameplay events
## (committed dispatch, authenticated clear, WON terminal) — not faked. Debug-only overlay
## controls (never shipped UI):
##   - AUTO-SOLVE: drain the solved candidate so real dispatch + clears fire continuously.
##   - SPEED 1x/2x: raise real event density; canonical one-shots keep normal pitch.
##   - RETRY: transaction-safe retry; a later fresh WON must play completion again.
##   - TEST DISPATCH / TEST CLEANING / TEST COMPLETION: isolated presentation seams.
##   - CLEANING STRESS: burst cleaning requests far beyond the voice cap to hear suppression.
##   - Master / Music / SFX sliders: live user volume; SAVE / RELOAD persist + reload.
## A live readout shows per-category voice diagnostics (requests / played / suppressed /
## active / peak / cap) and the current volumes.
##
## Owner F6 checklist (also in coordination/sessions/M33-C001/CLAUDE_LOG_V01.md):
##   1. dispatch.wav sounds once per real successful dispatch and is appropriate.
##   2. cleaning.wav sounds on committed cleaning and is not intolerable under density.
##   3. completion.wav plays once on WON.
##   4. no robot movement loop exists.
##   5. actual 1x and 2x remain listenable.
##   6. cleaning/dispatch overlap does not clip into an uncontrolled wall.
##   7. Master slider works.  8. SFX slider works.
##   9. Music slider changes/persists its bus value (no music track ships in M33).
##  10. settings survive save/reload.  11. Retry allows a fresh completion + no stale audio.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const GameplayAudioController = preload("res://scripts/audio/gameplay_audio_controller.gd")
const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")

var _host
var _status: Label
var _diag: Label
var _auto_solve := false
var _auto_btn: Button
var _speed_btn: Button
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _vol_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_host()
	_build_overlay()
	_sync_sliders_from_settings()

func _build_host() -> void:
	_host = ProductionGameplayHost.new()
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	if not _host.is_built():
		push_error("M33 playtest failed to build: %s" % _host.get_build_error())

func _build_overlay() -> void:
	var bar := VBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.add_theme_constant_override("separation", 6)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 32)
	_status.text = "PLAYING"
	bar.add_child(_status)

	_diag = Label.new()
	_diag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_diag.text = "audio diagnostics"
	bar.add_child(_diag)

	_vol_label = Label.new()
	_vol_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(_vol_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)
	_auto_btn = _make_button("AUTO-SOLVE", _on_auto_pressed)
	row.add_child(_auto_btn)
	_speed_btn = _make_button("SPEED 1x", _on_speed_pressed)
	row.add_child(_speed_btn)
	row.add_child(_make_button("RETRY", _on_retry_pressed))

	var row2 := HBoxContainer.new()
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	row2.add_theme_constant_override("separation", 8)
	bar.add_child(row2)
	row2.add_child(_make_button("TEST DISPATCH", _on_test_dispatch))
	row2.add_child(_make_button("TEST CLEANING", _on_test_cleaning))
	row2.add_child(_make_button("TEST COMPLETION", _on_test_completion))
	row2.add_child(_make_button("CLEANING STRESS", _on_stress))

	_master_slider = _add_slider(bar, "MASTER", _on_master_changed)
	_music_slider = _add_slider(bar, "MUSIC", _on_music_changed)
	_sfx_slider = _add_slider(bar, "SFX", _on_sfx_changed)

	var row3 := HBoxContainer.new()
	row3.alignment = BoxContainer.ALIGNMENT_CENTER
	row3.add_theme_constant_override("separation", 8)
	bar.add_child(row3)
	row3.add_child(_make_button("SAVE", _on_save))
	row3.add_child(_make_button("RELOAD", _on_reload))

func _make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

func _add_slider(parent: VBoxContainer, name_text: String, cb: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = name_text
	lbl.custom_minimum_size = Vector2(80, 0)
	row.add_child(lbl)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.01
	s.value = 1.0
	s.custom_minimum_size = Vector2(320, 0)
	s.value_changed.connect(cb)
	row.add_child(s)
	return s

func _settings():
	return _host.get_audio_settings() if (_host != null and is_instance_valid(_host) and _host.is_built()) else null

func _audio():
	return _host.get_audio_controller() if (_host != null and is_instance_valid(_host) and _host.is_built()) else null

func _sync_sliders_from_settings() -> void:
	var s = _settings()
	if s == null:
		return
	_master_slider.set_value_no_signal(s.get_master_volume())
	_music_slider.set_value_no_signal(s.get_music_volume())
	_sfx_slider.set_value_no_signal(s.get_sfx_volume())

func _process(_delta: float) -> void:
	if _host == null or not is_instance_valid(_host) or not _host.is_built():
		return
	_status.text = String(_host.get_completion().get_state())
	var ac = _audio()
	if ac != null:
		var d: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.DISPATCH)
		var c: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.CLEANING)
		var w: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)
		_diag.text = "DISPATCH %s\nCLEANING %s\nCOMPLETION %s" % [_fmt(d), _fmt(c), _fmt(w)]
	var s = _settings()
	if s != null:
		_vol_label.text = "vol  master %.2f | music %.2f | sfx %.2f" % [s.get_master_volume(), s.get_music_volume(), s.get_sfx_volume()]
	if _auto_solve and _host.get_completion().is_playing():
		var slots = _host.get_slots()
		var supply = _host.get_supply()
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					_host.get_input_controller().activate_front(col)
					break

func _fmt(d: Dictionary) -> String:
	if d.is_empty():
		return "-"
	return "req %d played %d supp %d active %d peak %d cap %d" % [d["requests"], d["played"], d["suppressed"], d["active"], d["peak"], d["cap"]]

func _on_auto_pressed() -> void:
	_auto_solve = not _auto_solve
	_auto_btn.text = "AUTO-SOLVE: ON" if _auto_solve else "AUTO-SOLVE"

func _on_speed_pressed() -> void:
	var two: bool = _host.get_runtime().toggle_speed()
	_host.get_screen().set_speed_2x(two)
	_speed_btn.text = "SPEED 2x" if two else "SPEED 1x"

func _on_retry_pressed() -> void:
	if _host != null and is_instance_valid(_host) and _host.is_built():
		_host.retry()
		_auto_solve = false
		_auto_btn.text = "AUTO-SOLVE"
		_speed_btn.text = "SPEED 1x"

func _on_test_dispatch() -> void:
	var ac = _audio()
	if ac != null:
		ac.request_dispatch()

func _on_test_cleaning() -> void:
	var ac = _audio()
	if ac != null:
		ac.request_cleaning()

func _on_test_completion() -> void:
	var ac = _audio()
	if ac != null:
		ac.request_completion()

## Presentation-only density stress: burst cleaning requests far beyond the cap. Does not
## clear cells or touch gameplay truth — only exercises the voice cap + suppression audibly.
func _on_stress() -> void:
	var ac = _audio()
	if ac == null:
		return
	for _i in range(48):
		ac.request_cleaning()

func _on_master_changed(v: float) -> void:
	var s = _settings()
	if s != null:
		s.set_master_volume(v)

func _on_music_changed(v: float) -> void:
	var s = _settings()
	if s != null:
		s.set_music_volume(v)

func _on_sfx_changed(v: float) -> void:
	var s = _settings()
	if s != null:
		s.set_sfx_volume(v)

func _on_save() -> void:
	var s = _settings()
	if s != null:
		s.save()

func _on_reload() -> void:
	var s = _settings()
	if s != null:
		s.load()
		_sync_sliders_from_settings()

func get_host():
	return _host
