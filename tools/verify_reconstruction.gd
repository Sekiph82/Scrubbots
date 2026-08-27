extends SceneTree

const LevelImporter = preload("res://scripts/tools/level_importer.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("Usage: -- <source_png> <level_json>")
		quit(1)
		return
	var source_path: String = args[0]
	var level_path: String = args[1]

	var src := Image.new()
	var err := src.load(source_path)
	if err != OK:
		printerr("Could not load source: %s" % source_path)
		quit(1)
		return
	if src.get_format() != Image.FORMAT_RGBA8:
		src.convert(Image.FORMAT_RGBA8)

	var result := LevelLoader.load_from_path(level_path)
	if not result.is_ok():
		printerr("Could not load level: %s — %s" % [level_path, str(result.errors)])
		quit(1)
		return

	var recon := LevelImporter.reconstruct_image(result.level_data)
	if recon == null:
		printerr("Reconstruction failed")
		quit(1)
		return

	if recon.get_width() != src.get_width() or recon.get_height() != src.get_height():
		printerr("FAIL: dimensions differ src=%dx%d recon=%dx%d" % [
			src.get_width(), src.get_height(), recon.get_width(), recon.get_height()])
		quit(1)
		return

	var src_data := src.get_data()
	var recon_data := recon.get_data()
	if src_data == recon_data:
		print("PASS: raw RGBA8 bytes match (%d bytes, %dx%d)" % [
			src_data.size(), src.get_width(), src.get_height()])
		quit(0)
	else:
		printerr("FAIL: raw RGBA8 bytes differ (%d vs %d bytes)" % [src_data.size(), recon_data.size()])
		quit(1)
