extends Control
## Bootstrap/debug screen. Proves project config, script parsing, and scene
## loading work, and (Prompt 02) that the variable-size board/level-data
## core loads real fixtures. Still no gameplay/rendering here — see
## docs/04_ROADMAP.md.

const LevelLoader = preload("res://scripts/data/level_loader.gd")

func _ready() -> void:
	%GodotVersionLabel.text = "Godot %s" % Engine.get_version_info().string
	%BoardCoreLabel.text = _describe_board_core()

func _describe_board_core() -> String:
	var parts: PackedStringArray = []
	for path in ["res://data/levels/test_40x40.json", "res://data/levels/test_50x50.json"]:
		var result = LevelLoader.load_from_path(path)
		if result.is_ok():
			var level = result.level_data
			parts.append("%dx%d: %d" % [level.width, level.height, level.get_cell_count()])
		else:
			parts.append("%s: FAILED" % path)
	return "Board Core OK  |  " + "  |  ".join(parts)
