extends Control
## Bootstrap screen. Proves project config, script parsing, and scene loading work.
## Prompt 01 scope only — no gameplay here.

func _ready() -> void:
	%GodotVersionLabel.text = "Godot %s" % Engine.get_version_info().string
