extends Control
## M32 Scrubbot-Visual manual playtest. Open/instantiate
## res://scenes/debug/m32_scrubbot_visual_playtest.tscn and run it in graphical Godot (F6).
##
## Hosts the REAL production stack (ProductionGameplayHost) on the 20x20 Hazard Bot level,
## so canonical Scrubby bots travel and disappear on ACTUAL authenticated clears from the
## accepted M20 path — no faked gameplay. Debug-only overlay controls (never shipped UI):
##   - AUTO-SOLVE: drain the solved candidate so real dispatch/clears fire continuously.
##   - SPEED 1x/2x: exercise higher travel + event density (bob/echo readability at 2x).
##   - FX ON/OFF: toggle the M31 cleaning puff/sparkle to compare M31/M32 coexistence.
##   - ECHO ON/OFF: toggle the M32 disappearance echo alone.
##   - BURST: request many PRESENTATION-ONLY echoes at once (does NOT clear cells) to stress
##     visual density + the echo concurrency cap without mutating gameplay truth.
##   - RETRY: transaction-safe retry; must leave zero stale bot / echo.
## A live readout shows agent, echo (active/peak/suppressed) and cleaning-cue counts.
##
## F6 checklist (also in coordination/sessions/M32-C001/CLAUDE_LOG_V01.md):
##   1. Scrubby is the correct canonical character at an appropriate gameplay scale.
##   2. Motion follows the route exactly and reads cleanly (no path drift from the bob).
##   3. Blink/brush/travel animation is restrained (V01 = bob/lean/squash body motion).
##   4. Arrival/disappearance echo is visible but is NOT a reward explosion.
##   5. M31 puff/sparkle still reads correctly and coexists with the echo.
##   6. 1x and 2x are both acceptable; high-density BURST stays readable and capped.
##   7. RETRY leaves no stale bot or echo. No debug circle is visible in normal play.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")

var _host
var _status: Label
var _diag: Label
var _auto_solve := false
var _auto_btn: Button
var _fx_btn: Button
var _echo_btn: Button
var _speed_btn: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_host()
	_build_overlay()

func _build_host() -> void:
	_host = ProductionGameplayHost.new()
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	if not _host.is_built():
		push_error("M32 playtest failed to build: %s" % _host.get_build_error())

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
	_diag.text = "agents 0 | echo 0/0/0 | cues 0"
	bar.add_child(_diag)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)

	_auto_btn = _make_button("AUTO-SOLVE", _on_auto_pressed)
	row.add_child(_auto_btn)
	_speed_btn = _make_button("SPEED 1x", _on_speed_pressed)
	row.add_child(_speed_btn)
	_fx_btn = _make_button("FX: ON", _on_fx_pressed)
	row.add_child(_fx_btn)
	_echo_btn = _make_button("ECHO: ON", _on_echo_pressed)
	row.add_child(_echo_btn)
	row.add_child(_make_button("BURST", _on_burst_pressed))
	row.add_child(_make_button("RETRY", _on_retry_pressed))

func _make_button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	return b

func _process(_delta: float) -> void:
	if _host == null or not is_instance_valid(_host) or not _host.is_built():
		return
	_status.text = String(_host.get_completion().get_state())
	var echo = _host.get_retire_echo()
	var fx = _host.get_cleaning_fx()
	var agents := 0
	var layer = _host.get_agent_layer()
	if layer != null and is_instance_valid(layer):
		agents = layer.get_child_count()
	var echo_txt := "-"
	if echo != null:
		echo_txt = "%d/%d/%d" % [echo.get_active_count(), echo.get_peak_active(), echo.get_suppressed_count()]
	var cues := 0
	if fx != null:
		cues = fx.get_active_count()
	_diag.text = "agents %d | echo %s | cues %d" % [agents, echo_txt, cues]
	if _auto_solve and _host.get_completion().is_playing():
		var slots = _host.get_slots()
		var supply = _host.get_supply()
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					_host.get_input_controller().activate_front(col)
					break

func _on_auto_pressed() -> void:
	_auto_solve = not _auto_solve
	_auto_btn.text = "AUTO-SOLVE: ON" if _auto_solve else "AUTO-SOLVE"

func _on_speed_pressed() -> void:
	var two: bool = _host.get_runtime().toggle_speed()
	_host.get_screen().set_speed_2x(two)
	_speed_btn.text = "SPEED 2x" if two else "SPEED 1x"

func _on_fx_pressed() -> void:
	var fx = _host.get_cleaning_fx()
	if fx == null:
		return
	var on: bool = not fx.is_effects_enabled()
	fx.set_effects_enabled(on)
	_fx_btn.text = "FX: ON" if on else "FX: OFF"

func _on_echo_pressed() -> void:
	var echo = _host.get_retire_echo()
	if echo == null:
		return
	var on: bool = not echo.is_enabled()
	echo.set_enabled(on)
	_echo_btn.text = "ECHO: ON" if on else "ECHO: OFF"

## PRESENTATION-ONLY density stress: request a burst of echoes at random board cells. Does
## not clear any cell or touch gameplay truth — only exercises the cap + visual density.
func _on_burst_pressed() -> void:
	var echo = _host.get_retire_echo()
	var board = _host.get_board()
	if echo == null or board == null:
		return
	var count: int = board.get_cell_count()
	for _i in range(48):
		echo.request_echo(randi() % count)

func _on_retry_pressed() -> void:
	if _host != null and is_instance_valid(_host) and _host.is_built():
		_host.retry()
		_auto_solve = false
		_auto_btn.text = "AUTO-SOLVE"
		_speed_btn.text = "SPEED 1x"

func get_host():
	return _host
