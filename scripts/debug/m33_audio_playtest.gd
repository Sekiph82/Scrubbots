extends Control
## M33 V02 audio manual playtest. Open
## res://scenes/debug/m33_audio_playtest.tscn and run it in graphical Godot (F6).
## Owner F6 re-listening gate (M33 V02) — Claude cannot self-close it.
##
## Hosts the REAL production stack (ProductionGameplayHost) on the 20x20 Hazard Bot level with
## an injected canonical AppState on an ISOLATED debug save path (never the real player save),
## so cleaning/completion audio fires from the ACTUAL authoritative events. Debug-only controls:
##   - AUTO-SOLVE: drain the solved candidate so real clears fire continuously.
##   - SPEED 1x/2x: raise real event density; canonical one-shots keep normal pitch.
##   - RETRY: transaction-safe retry; stale cleaning/completion voices are stopped.
##   - TEST CLEANING / TEST COMPLETION: isolated presentation seams.
##   - CLEANING STRESS: burst cleaning requests far beyond the voice cap.
##   - MUSIC TEST TONE: DEBUG-ONLY quiet generated sine loop on the Music bus so the Music
##     bus can be heard before an owner-approved track exists. Not a music asset.
## A live readout shows per-category voice diagnostics and the music controller status.
##
## Owner F6 checklist (also in coordination/sessions/M33-C001/CLAUDE_LOG_V02.md):
##   1. NO sound on robot dispatch.
##   2. cleaning uses the dispatch.wav sound, short, with no tail after the pixel is gone.
##   3. completion.wav plays once on WON; LOST plays nothing.
##   4. no robot movement loop.
##   5. 1x and 2x auto-solve are listenable, not an audio wall.
##   6. Music status shows OWNER_MUSIC_SELECTION_REQUIRED until a track is approved.
##   7. Retry leaves no stale cleaning/completion tail.

const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const GameplayAudioController = preload("res://scripts/audio/gameplay_audio_controller.gd")

## Isolated debug save: the playtest never touches the real player save.
const DEBUG_SAVE_PATH := "user://debug_m33_m41_playtest_save.dat"

var _host
var _status: Label
var _diag: Label
var _auto_solve := false
var _auto_btn: Button
var _speed_btn: Button
var _vol_label: Label
var _app

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_app = AppState.new(DEBUG_SAVE_PATH)
	_build_host()
	_build_overlay()

func _build_host() -> void:
	_host = ProductionGameplayHost.new()
	_host.app_state = _app
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
	row2.add_child(_make_button("TEST CLEANING", _on_test_cleaning))
	row2.add_child(_make_button("TEST COMPLETION", _on_test_completion))
	row2.add_child(_make_button("CLEANING STRESS", _on_stress))

	var row3 := HBoxContainer.new()
	row3.alignment = BoxContainer.ALIGNMENT_CENTER
	row3.add_theme_constant_override("separation", 8)
	bar.add_child(row3)
	row3.add_child(_make_button("MUSIC TEST TONE", _on_test_tone))

func _make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

func _settings():
	return _host.get_audio_settings() if (_host != null and is_instance_valid(_host) and _host.is_built()) else null

func _audio():
	return _host.get_audio_controller() if (_host != null and is_instance_valid(_host) and _host.is_built()) else null

func _process(_delta: float) -> void:
	if _host == null or not is_instance_valid(_host) or not _host.is_built():
		return
	_status.text = String(_host.get_completion().get_state())
	var ac = _audio()
	if ac != null:
		var c: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.CLEANING)
		var w: Dictionary = ac.get_diagnostics(GameplayAudioController.Category.COMPLETION)
		var m = _host.get_music_controller()
		_diag.text = "DISPATCH none (owner V02)\nCLEANING %s\nCOMPLETION %s\nMUSIC %s" % [_fmt(c), _fmt(w), String(m.get_status()) if m != null else "-"]
	var s = _settings()
	if s != null:
		_vol_label.text = "master %.2f | music %.2f | sfx %.2f | vibration %s" % [
			s.get_master_volume(), s.get_music_volume(), s.get_sfx_volume(), _onoff(_app.haptics.is_enabled())]
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
	return "req %d played %d supp %d cut %d active %d peak %d cap %d" % [d["requests"], d["played"], d["suppressed"], d["cut"], d["active"], d["peak"], d["cap"]]

func _onoff(v: bool) -> String:
	return "on" if v else "OFF"

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

## DEBUG-ONLY: a quiet generated 220 Hz sine loop on the Music bus (not a music asset) so the
## owner can hear Music vs SFX settings before a real track is approved.
func _on_test_tone() -> void:
	var m = _host.get_music_controller() if (_host != null and _host.is_built()) else null
	if m == null:
		return
	var rate := 22050
	var frames := rate   # 1 s loop, whole number of 220 Hz cycles.
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in range(frames):
		data.encode_s16(i * 2, int(sin(TAU * 220.0 * float(i) / float(rate)) * 3000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	m.set_track(w)
	m.start()

func _exit_tree() -> void:
	if _app != null:
		_app.flush()

func get_host():
	return _host
