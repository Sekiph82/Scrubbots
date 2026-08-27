extends SceneTree

const LevelImporter = preload("res://scripts/tools/level_importer.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 4:
		printerr("Usage: -- <width> <height> <colors> <output_path>")
		quit(1)
		return
	var w := int(args[0])
	var h := int(args[1])
	var colors := int(args[2])
	var out_path: String = args[3]
	var img := LevelImporter.generate_test_png(w, h, colors, true, false)
	var err := img.save_png(out_path)
	if err != OK:
		printerr("Failed to save: %s (error %d)" % [out_path, err])
		quit(1)
		return
	print("Generated %dx%d fixture with %d colors: %s" % [w, h, colors, out_path])
	quit(0)
