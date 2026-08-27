extends RefCounted
## LevelImporter — deterministic exact-pixel PNG → Level Data V1 converter.
## Preload: res://scripts/tools/level_importer.gd
##
## One source RGBA pixel = one logical cell. No resize/resample/interpolation.
## Palette order: deterministic first-seen during row-major scan.
## Canonical cell index: y * width + x (matches BoardState/LevelData).

const LevelData = preload("res://scripts/data/level_data.gd")
const LevelValidator = preload("res://scripts/data/level_validator.gd")
const LevelValidationResult = preload("res://scripts/data/level_validation_result.gd")
const DifficultyRules = preload("res://scripts/data/difficulty_rules.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")

const IMPORTER_VERSION := "M09-C001/v1"

## Import request — all parameters for one import operation.
class ImportRequest:
	var source_path: String
	var level_id: String
	var display_name: String
	var difficulty: String
	var output_path: String
	var preview_path: String
	var metadata_path: String
	var overwrite: bool

	func _init(
		p_source: String, p_id: String, p_name: String, p_difficulty: String,
		p_output: String, p_preview: String = "", p_metadata: String = "",
		p_overwrite: bool = false
	) -> void:
		source_path = p_source
		level_id = p_id
		display_name = p_name
		difficulty = p_difficulty
		output_path = p_output
		preview_path = p_preview
		metadata_path = p_metadata
		overwrite = p_overwrite

## Import result — success/failure plus generated data.
class ImportResult:
	var errors: Array[String] = []
	var level_data  # LevelData or null
	var level_json_text: String = ""
	var metadata_dict: Dictionary = {}
	var output_written: bool = false
	var output_unchanged: bool = false
	var preview_written: bool = false
	var metadata_written: bool = false

	func is_ok() -> bool:
		return errors.is_empty() and level_data != null

	func add_error(msg: String) -> void:
		errors.append(msg)

## Run a full import: load PNG → extract palette/cells → produce LevelData →
## write JSON + optional preview + optional metadata sidecar.
static func run_import(request: ImportRequest) -> ImportResult:
	var result := ImportResult.new()

	# --- validate request fields ---
	if request.level_id.is_empty():
		result.add_error("level_id must not be empty")
		return result
	if request.display_name.is_empty():
		result.add_error("display_name must not be empty")
		return result
	if request.difficulty.is_empty():
		result.add_error("difficulty must not be empty")
		return result
	if request.output_path.is_empty():
		result.add_error("output_path must not be empty")
		return result

	# --- validate difficulty ---
	if request.difficulty != DifficultyRules.TEST_DIFFICULTY and not DifficultyRules.is_production_difficulty(request.difficulty):
		result.add_error("Unknown difficulty '%s'. Use TEST or one of: %s" % [
			request.difficulty, ", ".join(DifficultyRules.production_difficulty_ids())])
		return result

	# --- load source image ---
	var img := Image.new()
	var load_err := img.load(request.source_path)
	if load_err != OK:
		result.add_error("Could not load source image '%s' (error %d)" % [request.source_path, load_err])
		return result

	if img.get_width() <= 0 or img.get_height() <= 0:
		result.add_error("Source image has invalid dimensions %dx%d" % [img.get_width(), img.get_height()])
		return result

	# --- convert to RGBA8 once (no spatial transform) ---
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

	var w := img.get_width()
	var h := img.get_height()

	# --- validate dimensions against difficulty band ---
	if DifficultyRules.is_production_difficulty(request.difficulty):
		if not DifficultyRules.is_within_band(request.difficulty, w, h):
			var band = DifficultyRules.get_band(request.difficulty)
			result.add_error(
				"Source dimensions %dx%d outside %s band (%d..%d)" % [
					w, h, request.difficulty, band.min, band.max])
			return result

	# --- extract palette and cells (deterministic first-seen row-major) ---
	var palette := PackedStringArray()
	var color_to_id := {}
	var cells := PackedInt32Array()
	cells.resize(w * h)

	for y in h:
		for x in w:
			var pixel := img.get_pixel(x, y)
			var key := _color_to_hex(pixel)
			if not color_to_id.has(key):
				color_to_id[key] = palette.size()
				palette.append(key)
			cells[y * w + x] = color_to_id[key]

	# --- build LevelData ---
	var level := LevelData.new(
		LevelData.FORMAT_VERSION,
		request.level_id,
		request.display_name,
		request.difficulty,
		w, h,
		palette,
		cells
	)
	result.level_data = level

	# --- structural validation ---
	var json_dict := _level_to_dict(level)
	var validation := LevelValidator.validate(json_dict, request.level_id)
	if not validation.is_ok():
		result.add_error("Generated level data failed structural validation: %s" % str(validation.errors))
		result.level_data = null
		return result

	# --- production validation if applicable ---
	if DifficultyRules.is_production_difficulty(request.difficulty):
		var prod_result := ProductionLevelValidator.validate(level)
		if not prod_result.is_ok():
			result.add_error("Generated level data failed production validation: %s" % str(prod_result.errors))
			result.level_data = null
			return result

	# --- serialize JSON deterministically ---
	result.level_json_text = _serialize_json(json_dict)

	# --- write output (with overwrite safety) ---
	if not request.overwrite and FileAccess.file_exists(request.output_path):
		var existing := FileAccess.get_file_as_string(request.output_path)
		if existing == result.level_json_text:
			result.output_unchanged = true
			result.output_written = false
		else:
			result.add_error("Output file '%s' already exists and overwrite=false" % request.output_path)
			return result
	else:
		var write_err := _write_text(request.output_path, result.level_json_text)
		if write_err != OK:
			result.add_error("Could not write output '%s' (error %d)" % [request.output_path, write_err])
			return result
		result.output_written = true

	# --- preview (reconstruct from level data, not source) ---
	if not request.preview_path.is_empty():
		var preview_img := reconstruct_image(level)
		if preview_img == null:
			result.add_error("Reconstruction failed for preview")
			return result
		var save_err := preview_img.save_png(request.preview_path)
		if save_err != OK:
			result.add_error("Could not save preview '%s' (error %d)" % [request.preview_path, save_err])
			return result
		result.preview_written = true

	# --- metadata sidecar ---
	if not request.metadata_path.is_empty():
		result.metadata_dict = _build_metadata(request, level, palette.size())
		var meta_json := _serialize_json(result.metadata_dict)
		var meta_err := _write_text(request.metadata_path, meta_json)
		if meta_err != OK:
			result.add_error("Could not write metadata '%s' (error %d)" % [request.metadata_path, meta_err])
			return result
		result.metadata_written = true

	return result

## Reconstruct an RGBA8 Image from LevelData alone (no source shortcut).
static func reconstruct_image(level) -> Image:
	var colors: Array[Color] = []
	for hex in level.palette:
		if not Color.html_is_valid(hex):
			return null
		colors.append(Color.html(hex))

	var img := Image.create(level.width, level.height, false, Image.FORMAT_RGBA8)
	for y in level.height:
		for x in level.width:
			var idx: int = y * level.width + x
			var pid: int = level.cells[idx]
			if pid < 0 or pid >= colors.size():
				return null
			img.set_pixel(x, y, colors[pid])
	return img

## Auto-detect difficulty from dimensions. Returns difficulty string or empty
## string if ambiguous/out-of-band.
static func auto_difficulty(width: int, height: int) -> String:
	for diff_id in DifficultyRules.production_difficulty_ids():
		if DifficultyRules.is_within_band(diff_id, width, height):
			return diff_id
	return ""

## Generate a test PNG fixture deterministically in memory.
static func generate_test_png(width: int, height: int, color_count: int = 4, include_transparent: bool = true, include_semitransparent: bool = false) -> Image:
	var img := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var colors: Array[Color] = []
	if include_transparent:
		colors.append(Color(0, 0, 0, 0))
	if include_semitransparent:
		colors.append(Color(1.0, 0.5, 0.0, 0.5))
	var opaque_needed := color_count - colors.size()
	for i in opaque_needed:
		var hue := float(i) / float(opaque_needed) if opaque_needed > 1 else 0.0
		colors.append(Color.from_hsv(hue, 0.8, 0.9, 1.0))
	for y in height:
		for x in width:
			var idx := (y * width + x) % colors.size()
			img.set_pixel(x, y, colors[idx])
	return img

# --- private helpers ---

static func _color_to_hex(c: Color) -> String:
	var r := int(round(c.r8))
	var g := int(round(c.g8))
	var b := int(round(c.b8))
	var a := int(round(c.a8))
	return "#%02X%02X%02X%02X" % [r, g, b, a]

static func _level_to_dict(level) -> Dictionary:
	var palette_arr: Array = []
	for entry in level.palette:
		palette_arr.append(entry)
	var cells_arr: Array = []
	for c in level.cells:
		cells_arr.append(c)
	return {
		"version": level.version,
		"id": level.id,
		"name": level.display_name,
		"difficulty": level.difficulty,
		"width": level.width,
		"height": level.height,
		"palette": palette_arr,
		"cells": cells_arr,
	}

static func _serialize_json(dict) -> String:
	return JSON.stringify(dict, "\t") + "\n"

static func _write_text(path: String, text: String) -> int:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.close()
	return OK

static func _build_metadata(request: ImportRequest, level, palette_count: int) -> Dictionary:
	return {
		"importerVersion": IMPORTER_VERSION,
		"sourcePath": request.source_path,
		"sourceWidth": level.width,
		"sourceHeight": level.height,
		"paletteCount": palette_count,
		"difficulty": request.difficulty,
		"outputLevelId": request.level_id,
		"outputPath": request.output_path,
	}
