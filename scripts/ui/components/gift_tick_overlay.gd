extends Control
## GiftTickOverlay — preload (res://scripts/ui/components/gift_tick_overlay.gd).
##
## M43-C005R (SB-M43-R05-001) — presentation-only micro-progress marks drawn INSIDE an existing
## Gift Meter ProgressBar (full-rect child; changes no geometry, caption or value). From a
## GiftProgressModel it marks the canonical milestone positions and splits the CURRENT
## milestone gap into micro-ticks; reached ticks are lit. A newly reached tick pulses once in
## FULL effects; Reduced Effects shows the static state. Mints / claims nothing.

const MILESTONE_COLOR := Color(1, 1, 1, 0.85)
const TICK_LIT := Color(0.42, 0.22, 0.0, 0.85)   ## dark amber: reads on the gold fill
const TICK_DIM := Color(1, 1, 1, 0.28)
const PULSE_S := 0.35

var _model: Dictionary = {}
var _milestones: Array = []
var _pulse := 0.0
var _pulse_tick := -1
var _tween: Tween

func _init() -> void:
	name = "GiftTickOverlay"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

## Apply a model. `reduced` = no pulse. A pulse happens only when ticks_reached increases
## within the same segment (a refresh with unchanged state never re-pulses).
func set_model(model: Dictionary, milestones: Array, reduced: bool) -> void:
	var before := int(_model.get("ticks_reached", -1))
	var same_segment := int(_model.get("prev", -1)) == int(model.get("prev", -2))
	_model = model.duplicate()
	_milestones = milestones.duplicate()
	if not reduced and same_segment and int(model.get("ticks_reached", 0)) > before and before >= 0 and is_inside_tree():
		_pulse_tick = int(model["ticks_reached"]) - 1
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		_tween.tween_method(func(v): _pulse = v; queue_redraw(), 1.0, 0.0, PULSE_S)
	queue_redraw()

func get_model() -> Dictionary:
	return _model.duplicate()

func is_pulsing() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()

## Tick x positions (local) of the current segment's inner micro-ticks, for tests/evidence.
func tick_positions() -> Array:
	var out: Array = []
	if _model.is_empty() or size.x <= 0.0:
		return out
	var cm := float(_model["cycle_max"])
	var a := float(_model["prev"]) / cm * size.x
	var b := float(_model["next"]) / cm * size.x
	for i in range(1, int(_model["ticks"])):
		out.append(a + (b - a) * float(i) / float(_model["ticks"]))
	return out

func _draw() -> void:
	if _model.is_empty() or size.x <= 0.0:
		return
	var h := size.y
	var cm := float(_model["cycle_max"])
	for m in _milestones:
		if int(m) > 0 and int(m) < int(cm):
			var x := float(m) / cm * size.x
			# Edge notches only: the owner-locked centred caption is never crossed.
			draw_line(Vector2(x, 2), Vector2(x, h * 0.24), MILESTONE_COLOR, 3.0)
			draw_line(Vector2(x, h * 0.76), Vector2(x, h - 2), MILESTONE_COLOR, 3.0)
	var ticks := tick_positions()
	var reached := int(_model["ticks_reached"])
	for i in range(ticks.size()):
		var lit := i < reached
		var c: Color = TICK_LIT if lit else TICK_DIM
		var w := 3.0 if lit else 2.0
		if i == _pulse_tick and _pulse > 0.0:
			c = c.lerp(Color(1, 1, 1, 1), _pulse * 0.8)
			w += 3.0 * _pulse
		draw_line(Vector2(ticks[i], h * 0.78), Vector2(ticks[i], h - 3), c, w)
