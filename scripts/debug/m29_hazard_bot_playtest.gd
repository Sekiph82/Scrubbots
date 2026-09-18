extends Control
## M29 Hazard Bot manual playtest. Preload/instantiate scene
## res://scenes/debug/m29_hazard_bot_playtest.tscn and run it in graphical Godot (F6).
##
## Hosts the REAL production stack (ProductionGameplayHost) around the accepted M28
## GameplayScreen on the real 20x20 Hazard Bot level with the deterministic M27-proven
## M23 candidate (seed 1 / 3 columns / preview depth 3). Desktop mouse (or touch) on a
## supply FRONT tile dispatches through real M23 -> M24 -> M25 -> M26 -> routing ->
## ScrubbotAgent -> M20 clearing. The bottom-right control toggles 1x <-> 2x; when the
## final M23 supply batch is transferred, gameplay auto-switches to 2x. Pause is the
## bottom-left control.
##
## M30 limitation: there is NO win/lose/result UI yet — the board simply clears out.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")

var _host

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_host = ProductionGameplayHost.new()
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_host)
	if not _host.is_built():
		push_error("M29 playtest failed to build: %s" % _host.get_build_error())

func get_host():
	return _host
