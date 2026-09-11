extends SceneTree
## Reproducible headless generator for the M21-C001 first real-art vertical slice.
## Runs the production-art bridge over the owner-approved immutable source PNG and
## writes the canonical Level Data, preview and metadata deterministically.
##
## Usage:
##   godot --headless --path . -s res://tools/build_m21_level.gd [-- --overwrite]
##
## Deterministic: a second run against identical committed artifacts reports
## UNCHANGED and produces no diff.

const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")

const SOURCE := "res://assets/art/levels/source/easy/scrubbots_m21_level_001_hazard_bot_20x20.png"
const LEVEL_ID := "m21_level_001_hazard_bot"
const DISPLAY_NAME := "Hazard Bot"
const DIFFICULTY := "EASY"
const OUTPUT := "res://data/levels/m21_level_001_hazard_bot.json"
const PREVIEW := "res://assets/art/levels/previews/m21_level_001_hazard_bot.png"
const METADATA := "res://data/levels/metadata/m21_level_001_hazard_bot.metadata.json"

func _initialize() -> void:
	var overwrite := OS.get_cmdline_user_args().has("--overwrite")
	# Ensure destination directories exist (never touches the source).
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/art/levels/previews"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data/levels/metadata"))

	var r = ProductionArtLevelBuilder.build(
		SOURCE, LEVEL_ID, DISPLAY_NAME, DIFFICULTY, OUTPUT, PREVIEW, METADATA, overwrite)
	if not r.is_ok():
		for e in r.errors:
			printerr("ERROR: %s" % e)
		quit(1)
		return

	print("LEVEL: ", "WRITTEN" if r.output_written else ("UNCHANGED" if r.output_unchanged else "?"), " ", OUTPUT)
	print("PREVIEW: ", "WRITTEN" if r.preview_written else ("UNCHANGED" if r.preview_unchanged else "?"), " ", PREVIEW)
	print("METADATA: ", "WRITTEN" if r.metadata_written else ("UNCHANGED" if r.metadata_unchanged else "?"), " ", METADATA)
	print("first_seen=", r.normalize.first_seen_cids)
	print("normalized=", r.normalize.normalized_cids)
	print("used_color_count=", r.normalize.used_color_count)
	print("cell_counts=", r.normalize.cid_cell_counts)
	quit(0)
