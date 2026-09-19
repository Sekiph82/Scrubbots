extends Control
## M30 Win/Lose/Retry manual playtest. Preload/instantiate scene
## res://scenes/debug/m30_win_lose_playtest.tscn and run it in graphical Godot (F6).
##
## Hosts the REAL production stack (ProductionGameplayHost) around the accepted M28
## GameplayScreen on the real 20x20 Hazard Bot level with the deterministic M27-proven M23
## candidate (seed 1 / 3 columns / preview 3), plus the real M30 completion authority
## (CompletionEvaluator + CompletionController) and its transaction-safe Retry.
##
## Minimal native debug result UI (no branded result-screen art — owner boundary §8):
##   - a RESULT label at the top: PLAYING / WON / LOST / ERROR;
##   - AUTO-SOLVE: while on, places the lowest-index non-empty supply column's front as soon
##     as a slot is free — the known solved Hazard drain -> WON exactly once. (Manual taps on
##     the supply front tiles still work exactly as in the M29 scene.)
##   - DEADLOCK DEMO: rebuilds the SAME stack with a residual-deficient supply fixture
##     (qa_supply_drop_last) and auto-drains it -> a REAL M27-proven DEADLOCK -> LOST once.
##   - RETRY: transaction-safe same-puzzle retry -> same board + exact initial supply at 1x.
##
## F6 manual checklist (also in coordination/sessions/M30-C001/CLAUDE_LOG_V01.md):
##   1. Press AUTO-SOLVE, watch the board clear -> RESULT shows WON (once).
##   2. Tap a supply front tile -> nothing happens (terminal blocks input).
##   3. Press RETRY -> full artwork + full supply restored, speed 1x, RESULT = PLAYING.
##   4. Press DEADLOCK DEMO -> board partly clears then RESULT shows LOST (once).
##   5. Press RETRY -> restored, playable again.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")

## How many drain-tail batches the DEADLOCK DEMO drops so the level becomes a proven
## end-of-supply deadlock. 6 leaves an unclearable residual on the 20x20 Hazard board.
const DEADLOCK_DROP := 6

var _host
var _result_label: Label
var _auto_solve := false
var _auto_btn: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_host(0)
	_build_overlay()

func _build_host(drop: int) -> void:
	if _host != null and is_instance_valid(_host):
		_host.queue_free()
	_host = ProductionGameplayHost.new()
	_host.qa_supply_drop_last = drop
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	# Keep the M30 overlay on top of the freshly (re)added host.
	if _result_label != null and is_instance_valid(_result_label):
		move_child(_result_label.get_parent(), get_child_count() - 1)
	if not _host.is_built():
		push_error("M30 playtest failed to build: %s" % _host.get_build_error())
		return
	_host.get_completion().terminal_reached.connect(_on_terminal)
	_auto_solve = false
	_sync_auto_btn()

func _build_overlay() -> void:
	var bar := VBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.add_theme_constant_override("separation", 6)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	_result_label = Label.new()
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.add_theme_font_size_override("font_size", 40)
	_result_label.text = "PLAYING"
	bar.add_child(_result_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	_auto_btn = _make_button("AUTO-SOLVE", _on_auto_pressed)
	row.add_child(_auto_btn)
	row.add_child(_make_button("DEADLOCK DEMO", _on_deadlock_pressed))
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
	# Live result readout (the completion authority latches on the host's own runtime clock).
	var st := String(_host.get_completion().get_state())
	if _result_label != null and _result_label.text != st:
		_result_label.text = st
	# AUTO-SOLVE rides the real runtime cadence: place the next front as soon as a slot frees.
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
	_sync_auto_btn()

func _sync_auto_btn() -> void:
	if _auto_btn != null:
		_auto_btn.text = "AUTO-SOLVE: ON" if _auto_solve else "AUTO-SOLVE"

func _on_deadlock_pressed() -> void:
	_build_host(DEADLOCK_DROP)
	_auto_solve = true
	_sync_auto_btn()

func _on_retry_pressed() -> void:
	if _host != null and is_instance_valid(_host) and _host.is_built():
		_host.retry()
		_auto_solve = false
		_sync_auto_btn()

func _on_terminal(status, _detail) -> void:
	if _result_label != null:
		_result_label.text = String(status)
	_auto_solve = false
	_sync_auto_btn()

func get_host():
	return _host
