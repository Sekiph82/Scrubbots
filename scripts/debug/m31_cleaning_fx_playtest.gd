extends Control
## M31 Cleaning-Effects manual playtest. Open/instantiate
## res://scenes/debug/m31_cleaning_fx_playtest.tscn and run it in graphical Godot (F6).
##
## Hosts the REAL production stack (ProductionGameplayHost) on the 20x20 Hazard Bot level,
## so cleaning cues appear on ACTUAL authenticated clears from the accepted M20 path — no
## faked gameplay. Debug-only overlay controls (never shipped UI):
##   - AUTO-SOLVE: drain the solved candidate so real clears fire continuously.
##   - FX ON/OFF: CleaningEffectsController.set_effects_enabled.
##   - REDUCED ON/OFF: CleaningEffectsController.set_reduced_effects.
##   - SPEED 1x/2x: exercise higher event density.
##   - BURST: request many PRESENTATION-ONLY cues at once (does NOT clear cells) to stress
##     visual density + the concurrency cap without mutating gameplay truth.
##   - RETRY: transaction-safe retry; must leave zero stale cues.
## A live readout shows active / peak / suppressed effect counts.
##
## F6 checklist (also in coordination/sessions/M31-C001/CLAUDE_LOG_V01.md):
##   1. AUTO-SOLVE on -> cues appear centered on the pixels that actually clear.
##   2. Cue reads as a clean puff/sparkle, not a reward explosion; normal density is calm.
##   3. BURST -> board does not become a flashing cloud; active count never exceeds the cap.
##   4. FX OFF -> no new cues, board keeps clearing. REDUCED -> lighter, shorter cue.
##   5. SPEED 2x -> still acceptable. RETRY -> no stale cue remains; counts reset.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")

var _host
var _status: Label
var _diag: Label
var _auto_solve := false
var _auto_btn: Button
var _fx_btn: Button
var _reduced_btn: Button
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
		push_error("M31 playtest failed to build: %s" % _host.get_build_error())

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
	_diag.text = "active 0 | peak 0 | suppressed 0"
	bar.add_child(_diag)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	bar.add_child(row)

	_auto_btn = _make_button("AUTO-SOLVE", _on_auto_pressed)
	row.add_child(_auto_btn)
	_fx_btn = _make_button("FX: ON", _on_fx_pressed)
	row.add_child(_fx_btn)
	_reduced_btn = _make_button("REDUCED: OFF", _on_reduced_pressed)
	row.add_child(_reduced_btn)
	_speed_btn = _make_button("SPEED 1x", _on_speed_pressed)
	row.add_child(_speed_btn)
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
	var fx = _host.get_cleaning_fx()
	if fx != null:
		_diag.text = "active %d | peak %d | suppressed %d" % [
			fx.get_active_count(), fx.get_peak_active(), fx.get_suppressed_count()]
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

func _on_fx_pressed() -> void:
	var fx = _host.get_cleaning_fx()
	if fx == null:
		return
	var on: bool = not fx.is_effects_enabled()
	fx.set_effects_enabled(on)
	_fx_btn.text = "FX: ON" if on else "FX: OFF"

func _on_reduced_pressed() -> void:
	var fx = _host.get_cleaning_fx()
	if fx == null:
		return
	var on: bool = not fx.is_reduced_effects()
	fx.set_reduced_effects(on)
	_reduced_btn.text = "REDUCED: ON" if on else "REDUCED: OFF"

func _on_speed_pressed() -> void:
	var two: bool = _host.get_runtime().toggle_speed()
	_host.get_screen().set_speed_2x(two)
	_speed_btn.text = "SPEED 2x" if two else "SPEED 1x"

## PRESENTATION-ONLY density stress: request a burst of cues at random board cells. Does
## not clear any cell or touch gameplay truth — only exercises the cap + visual density.
func _on_burst_pressed() -> void:
	var fx = _host.get_cleaning_fx()
	var board = _host.get_board()
	if fx == null or board == null:
		return
	var count: int = board.get_cell_count()
	for _i in range(60):
		fx.request_effect(randi() % count)

func _on_retry_pressed() -> void:
	if _host != null and is_instance_valid(_host) and _host.is_built():
		_host.retry()
		_auto_solve = false
		_auto_btn.text = "AUTO-SOLVE"
		_speed_btn.text = "SPEED 1x"

func get_host():
	return _host
