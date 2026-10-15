extends CanvasLayer
## GameplayDebugOverlay — preload (res://scripts/debug/gameplay_debug_overlay.gd).
##
## M45 (SB-M45-001, -015, -018) — DEVELOPER-ONLY HUD over one ProductionGameplayHost: the
## GameplayDebugModel text plus toggles for target markers / routes / grid (the
## GameplayDebugLayer it attaches to the board presentation) and the existing cleaning-effects
## switch (CleaningEffectsController.set_effects_enabled, presentation only). Refreshes on a
## 0.25 s timer, never per frame. Owns no gameplay / economy / save truth.
##
## Release gate (SB-M45-018): is_allowed() is false in any exported template build, where the
## overlay frees itself. Only the developer harness scenes/debug/m45_debug_gameplay.tscn
## creates it; nothing in the shipping app (main.tscn) does.

const GameplayDebugModel = preload("res://scripts/debug/gameplay_debug_model.gd")
const GameplayDebugLayer = preload("res://scripts/debug/gameplay_debug_layer.gd")

const LAYER := 90
const REFRESH_S := 0.25

var meta: Dictionary = {}
var _host = null
var _layer = null
var _panel: PanelContainer
var _text: Label
var _toggles: Dictionary = {}   ## id -> CheckButton
var _timer: Timer
var _last_model: Dictionary = {}

## Pure gate: `features` = Callable(name:String) -> bool (OS.has_feature in production).
static func is_allowed(features: Callable = Callable()) -> bool:
	var f: Callable = features if features.is_valid() else Callable(OS, "has_feature")
	return not bool(f.call("template"))

func _init() -> void:
	name = "GameplayDebugOverlay"
	layer = LAYER
	_panel = PanelContainer.new()
	_panel.name = "DebugPanel"
	_panel.position = Vector2(8, 8)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.7)
	sb.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	_text = Label.new()
	_text.name = "DebugText"
	_text.add_theme_font_size_override("font_size", 22)
	v.add_child(_text)
	for id in ["targets", "routes", "grid", "effects"]:
		var t := CheckButton.new()
		t.name = "Toggle_" + id
		t.text = id.to_upper()
		t.button_pressed = true
		t.focus_mode = Control.FOCUS_NONE
		t.toggled.connect(_on_toggle.bind(id))
		v.add_child(t)
		_toggles[id] = t
	_timer = Timer.new()
	_timer.wait_time = REFRESH_S
	_timer.ignore_time_scale = true
	_timer.timeout.connect(refresh)
	add_child(_timer)

func _ready() -> void:
	if not is_allowed():
		queue_free()
		return
	_timer.start()

## Attach to a built host: the board layer goes into its presentation (same space as agents).
func bind(host, entry_meta: Dictionary = {}) -> void:
	_host = host
	meta = entry_meta.duplicate()
	if _layer != null and is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null
	var pres = host.get_screen().get_presentation() if host != null and is_instance_valid(host) and host.is_built() else null
	if pres != null:
		_layer = GameplayDebugLayer.new()
		pres.add_child(_layer)
		_layer.bind(host)
	if host != null and is_instance_valid(host) and host.is_built() and host.get_cleaning_fx() != null:
		_toggles["effects"].set_pressed_no_signal(host.get_cleaning_fx().is_effects_enabled())
	refresh()

func refresh() -> void:
	_last_model = GameplayDebugModel.capture(_host, meta)
	_text.text = GameplayDebugModel.to_text(_last_model)
	if _layer != null and is_instance_valid(_layer):
		_layer.refresh()

func _on_toggle(on: bool, id: String) -> void:
	if id == "effects":
		if _host != null and is_instance_valid(_host) and _host.is_built() and _host.get_cleaning_fx() != null:
			_host.get_cleaning_fx().set_effects_enabled(on)
	elif _layer != null and is_instance_valid(_layer):
		_layer.set("show_" + id, on)
		_layer.refresh()

func get_model() -> Dictionary:
	return _last_model.duplicate()

func get_debug_layer():
	return _layer

func get_toggle(id: String) -> CheckButton:
	return _toggles.get(id)

func get_text() -> String:
	return _text.text
