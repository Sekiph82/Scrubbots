extends SceneTree
## Headless CLI entrypoint for LevelImporter.
## Usage:
##   godot --headless --path . -s res://tools/import_level.gd -- \
##     --source <png> --id <level_id> --name <display_name> \
##     --difficulty <TEST|EASY|MEDIUM|HARD|VERY_HARD> --output <json_path> \
##     [--preview <png_path>] [--metadata <json_path>] [--overwrite]

const LevelImporter = preload("res://scripts/tools/level_importer.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var parsed := _parse_args(args)

	if parsed.has("error"):
		printerr("ERROR: %s" % parsed.error)
		printerr("Usage: ... -- --source <png> --id <id> --name <name> --difficulty <diff> --output <json> [--preview <png>] [--metadata <json>] [--overwrite]")
		quit(1)
		return

	var request := LevelImporter.ImportRequest.new(
		parsed.source, parsed.id, parsed.name, parsed.difficulty,
		parsed.output, parsed.get("preview", ""), parsed.get("metadata", ""),
		parsed.get("overwrite", false)
	)

	var result := LevelImporter.run_import(request)
	if not result.is_ok():
		for err in result.errors:
			printerr("ERROR: %s" % err)
		quit(1)
		return

	if result.output_unchanged:
		print("UNCHANGED: %s (content identical)" % request.output_path)
	elif result.output_written:
		print("WRITTEN: %s" % request.output_path)
	if result.preview_unchanged:
		print("PREVIEW UNCHANGED: %s" % request.preview_path)
	elif result.preview_written:
		print("PREVIEW: %s" % request.preview_path)
	if result.metadata_unchanged:
		print("METADATA UNCHANGED: %s" % request.metadata_path)
	elif result.metadata_written:
		print("METADATA: %s" % request.metadata_path)
	print("OK: %dx%d, %d colors, %d cells, difficulty=%s" % [
		result.level_data.width, result.level_data.height,
		result.level_data.palette.size(), result.level_data.get_cell_count(),
		result.level_data.difficulty])
	quit(0)

func _parse_args(args: PackedStringArray) -> Dictionary:
	var d := {}
	var i := 0
	while i < args.size():
		var arg: String = args[i]
		match arg:
			"--source":
				i += 1
				if i >= args.size(): return {"error": "--source requires a value"}
				d.source = args[i]
			"--id":
				i += 1
				if i >= args.size(): return {"error": "--id requires a value"}
				d.id = args[i]
			"--name":
				i += 1
				if i >= args.size(): return {"error": "--name requires a value"}
				d.name = args[i]
			"--difficulty":
				i += 1
				if i >= args.size(): return {"error": "--difficulty requires a value"}
				d.difficulty = args[i]
			"--output":
				i += 1
				if i >= args.size(): return {"error": "--output requires a value"}
				d.output = args[i]
			"--preview":
				i += 1
				if i >= args.size(): return {"error": "--preview requires a value"}
				d.preview = args[i]
			"--metadata":
				i += 1
				if i >= args.size(): return {"error": "--metadata requires a value"}
				d.metadata = args[i]
			"--overwrite":
				d.overwrite = true
			_:
				return {"error": "Unknown argument: %s" % arg}
		i += 1

	for required in ["source", "id", "name", "difficulty", "output"]:
		if not d.has(required):
			return {"error": "Missing required argument: --%s" % required}
	return d
