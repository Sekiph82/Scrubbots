extends RefCounted
## LevelLoader — preload this script (res://scripts/data/level_loader.gd)
## rather than relying on global class_name lookup; see level_validator.gd.
## Reads a Level Data Spec Version 1 JSON file from disk and produces a
## validated LevelData (or a list of specific validation errors). Never
## crashes on malformed input. See docs/03_LEVEL_DATA_SPEC.md.

## See level_validator.gd for why explicit preload is used instead of
## relying on the global script class cache.
const LevelValidator = preload("res://scripts/data/level_validator.gd")
const LevelValidationResult = preload("res://scripts/data/level_validation_result.gd")

static func load_from_path(path: String) -> LevelValidationResult:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var result := LevelValidationResult.new()
		result.add_error("Level %s: could not open file (error %d)" % [path, FileAccess.get_open_error()])
		return result

	var text := file.get_as_text()
	file.close()
	return load_from_text(text, path)

static func load_from_text(text: String, label: String) -> LevelValidationResult:
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		var result := LevelValidationResult.new()
		result.add_error(
			"Level %s: malformed JSON at line %d: %s" %
			[label, json.get_error_line(), json.get_error_message()]
		)
		return result

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		var result := LevelValidationResult.new()
		result.add_error("Level %s: root JSON value must be an object" % label)
		return result

	return LevelValidator.validate(data, label)
