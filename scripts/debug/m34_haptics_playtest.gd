extends Control
## M34 haptics playtest scaffold. Real-device gate (SB-M34-006):
##   - Owner runs this scene on an authorized Android/iOS handset.
##   - Cleaning button fires the cleaning path (short buzz, throttle-limited).
##   - Completion button fires the WON-once path.
##   - Toggle disables all requests without touching gameplay.
##
## Presentation-only. Never spawns bots, never touches BoardState.

const HapticsController = preload("res://scripts/haptics/haptics_controller.gd")

var _hc: Node

func _ready() -> void:
	_hc = HapticsController.new()
	add_child(_hc)

	var root := VBoxContainer.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	add_child(root)

	var lbl := Label.new()
	lbl.text = "M34 Haptics Playtest — real-device gate (SB-M34-006)"
	root.add_child(lbl)

	var toggle := CheckButton.new()
	toggle.text = "Haptics enabled"
	toggle.button_pressed = true
	toggle.toggled.connect(func(v): _hc.set_enabled(v))
	root.add_child(toggle)

	var clean_btn := Button.new()
	clean_btn.text = "Request cleaning haptic"
	clean_btn.pressed.connect(func(): _hc.request_cleaning())
	root.add_child(clean_btn)

	var comp_btn := Button.new()
	comp_btn.text = "Request completion haptic (WON)"
	comp_btn.pressed.connect(func(): _hc.request_completion())
	root.add_child(comp_btn)

	var burst_btn := Button.new()
	burst_btn.text = "Burst 30 cleaning requests (spam probe)"
	burst_btn.pressed.connect(_burst)
	root.add_child(burst_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Retry (reset completion latch)"
	reset_btn.pressed.connect(func(): _hc.reset_for_new_attempt())
	root.add_child(reset_btn)

	var diag := Label.new()
	diag.name = "Diag"
	root.add_child(diag)

	# Refresh diagnostics label at low rate.
	var t := Timer.new()
	t.wait_time = 0.25
	t.autostart = true
	t.timeout.connect(func(): diag.text = _diag_text())
	add_child(t)

func _burst() -> void:
	for _i in range(30):
		_hc.request_cleaning()

func _diag_text() -> String:
	var c: Dictionary = _hc.get_diagnostics(0)   # CLEANING
	var w: Dictionary = _hc.get_diagnostics(1)   # COMPLETION
	return "cleaning: %s\ncompletion: %s\nplatform_calls=%d total_ms=%d enabled=%s" % [
		str(c), str(w), _hc.get_platform_call_count(), _hc.get_platform_total_ms(), str(_hc.is_enabled())
	]
