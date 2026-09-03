extends SceneTree
## Headless CLI entrypoint for LevelBatchImporter (M09-C002).
## Usage:
##   godot --headless --path . -s res://tools/import_level_batch.gd -- \
##     --manifest <manifest.json> --catalog <catalog_dir> [--commit]
##
## Without --commit the run is validation-only: every check runs, nothing
## is written. With --commit, final artifacts are written only if the whole
## batch preflights clean (see scripts/tools/level_batch_importer.gd).
## Exit code is non-zero whenever the batch is not fully OK.

const LevelBatchImporter = preload("res://scripts/tools/level_batch_importer.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var parsed := _parse_args(args)

	if parsed.has("error"):
		printerr("ERROR: %s" % parsed.error)
		printerr("Usage: ... -- --manifest <manifest.json> --catalog <catalog_dir> [--commit]")
		quit(1)
		return

	var result := LevelBatchImporter.run_batch(parsed.manifest, parsed.catalog, parsed.get("commit", false))
	var report := result.to_report()
	print(JSON.stringify(report, "\t"))

	print("")
	print("BATCH %s: mode=%s committed=%s total=%d valid=%d invalid=%d written=%d unchanged=%d" % [
		"OK" if result.is_ok() else "FAILED",
		report.mode, report.committed,
		report.total_requested, report.valid_count, report.invalid_count,
		report.written_count, report.unchanged_count,
	])

	quit(0 if result.is_ok() else 1)

func _parse_args(args: PackedStringArray) -> Dictionary:
	var d := {}
	var i := 0
	while i < args.size():
		var arg: String = args[i]
		match arg:
			"--manifest":
				i += 1
				if i >= args.size(): return {"error": "--manifest requires a value"}
				d.manifest = args[i]
			"--catalog":
				i += 1
				if i >= args.size(): return {"error": "--catalog requires a value"}
				d.catalog = args[i]
			"--commit":
				d.commit = true
			_:
				return {"error": "Unknown argument: %s" % arg}
		i += 1

	for required in ["manifest", "catalog"]:
		if not d.has(required):
			return {"error": "Missing required argument: --%s" % required}
	return d
