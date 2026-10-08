extends RefCounted
## LevelValidator — preload this script (res://scripts/data/level_validator.gd)
## rather than relying on global class_name lookup (see below).
## Validates a parsed level Dictionary (Level Data Spec Version 1, or Version 2
## with VOID cells — ADR-030) and, if
## valid, builds the resulting LevelData. Never assumes a fixed board size —
## every size-dependent check uses width * height generically. See
## docs/03_LEVEL_DATA_SPEC.md and ADR-008 in docs/05_TECH_DECISIONS.md.

## Referenced by explicit preload rather than global class_name lookup, so
## this script parses correctly in headless runs even before Godot has built
## its global script class cache (e.g. an editor has never opened the
## project on this machine).
const LevelData = preload("res://scripts/data/level_data.gd")
const LevelValidationResult = preload("res://scripts/data/level_validation_result.gd")

## label: identifier used in error messages when the dict has no usable
## "id" field yet (e.g. a filename), so failures are always traceable.
static func validate(data: Dictionary, label: String) -> LevelValidationResult:
	var result := LevelValidationResult.new()
	var level_label: String = str(data.get("id", label))
	var version_int: int = LevelData.FORMAT_VERSION

	if not data.has("version"):
		result.add_error("Level %s: missing required field 'version'" % level_label)
	else:
		var version_value = data["version"]
		if typeof(version_value) != TYPE_INT and typeof(version_value) != TYPE_FLOAT:
			result.add_error("Level %s: 'version' must be an integer, got %s" % [level_label, typeof(version_value)])
		elif int(version_value) != LevelData.FORMAT_VERSION and int(version_value) != LevelData.FORMAT_VERSION_VOID:
			result.add_error("Level %s: unsupported version %s (expected %d, or %d for levels with VOID cells)" % [level_label, str(version_value), LevelData.FORMAT_VERSION, LevelData.FORMAT_VERSION_VOID])
		else:
			version_int = int(version_value)

	var id_value: String = ""
	if not data.has("id") or String(data["id"]).is_empty():
		result.add_error("Level %s: missing or empty required field 'id'" % level_label)
	else:
		id_value = String(data["id"])

	var name_value: String = ""
	if not data.has("name") or String(data["name"]).is_empty():
		result.add_error("Level %s: missing or empty required field 'name'" % level_label)
	else:
		name_value = String(data["name"])

	var difficulty_value: String = ""
	if not data.has("difficulty") or String(data["difficulty"]).is_empty():
		result.add_error("Level %s: missing or empty required field 'difficulty'" % level_label)
	else:
		difficulty_value = String(data["difficulty"])

	var width: int = -1
	if not data.has("width"):
		result.add_error("Level %s: missing required field 'width'" % level_label)
	else:
		width = int(data["width"])
		if width <= 0:
			result.add_error("Level %s: width must be > 0, got %d" % [level_label, width])

	var height: int = -1
	if not data.has("height"):
		result.add_error("Level %s: missing required field 'height'" % level_label)
	else:
		height = int(data["height"])
		if height <= 0:
			result.add_error("Level %s: height must be > 0, got %d" % [level_label, height])

	var palette := PackedStringArray()
	if not data.has("palette"):
		result.add_error("Level %s: missing required field 'palette'" % level_label)
	else:
		var palette_raw = data["palette"]
		if typeof(palette_raw) != TYPE_ARRAY or palette_raw.is_empty():
			result.add_error("Level %s: 'palette' must be a non-empty array" % level_label)
		else:
			for entry in palette_raw:
				palette.append(String(entry))

	var cells := PackedInt32Array()
	if not data.has("cells"):
		result.add_error("Level %s: missing required field 'cells'" % level_label)
	elif width > 0 and height > 0:
		var cells_raw = data["cells"]
		if typeof(cells_raw) != TYPE_ARRAY:
			result.add_error("Level %s: 'cells' must be an array" % level_label)
		else:
			var expected_count: int = width * height
			if cells_raw.size() != expected_count:
				result.add_error(
					"Level %s: expected %d cell entries (width=%d * height=%d), found %d" %
					[level_label, expected_count, width, height, cells_raw.size()]
				)
			else:
				for i in cells_raw.size():
					var entry = cells_raw[i]
					# JSON numbers parse as float: accept only integral numbers. Strings and
					# fractional values (e.g. a "semi-transparent" partial id) fail closed.
					if (typeof(entry) != TYPE_INT and typeof(entry) != TYPE_FLOAT) or float(entry) != floorf(float(entry)):
						result.add_error("Level %s: cell %d value %s is not an integer palette id" % [level_label, i, str(entry)])
						cells.append(0)
					else:
						cells.append(int(entry))
				var void_count := 0
				if not palette.is_empty():
					for i in cells.size():
						var palette_id: int = cells[i]
						# ADR-030: VOID (-1) is legal only in a version-2 file.
						if palette_id == LevelData.VOID_CELL and version_int == LevelData.FORMAT_VERSION_VOID:
							void_count += 1
						elif palette_id == LevelData.VOID_CELL:
							result.add_error(
								"Level %s: VOID cell (-1) at cell %d requires version %d" %
								[level_label, i, LevelData.FORMAT_VERSION_VOID]
							)
						elif palette_id < 0 or palette_id >= palette.size():
							result.add_error(
								"Level %s: palette id %d at cell %d exceeds palette size %d" %
								[level_label, palette_id, i, palette.size()]
							)
					# One canonical encoding per level: version 2 exactly when VOID exists,
					# and VOID never replaces all of the artwork.
					if version_int == LevelData.FORMAT_VERSION_VOID and void_count == 0:
						result.add_error("Level %s: version %d requires at least one VOID cell (use version %d)" % [level_label, LevelData.FORMAT_VERSION_VOID, LevelData.FORMAT_VERSION])
					if void_count == cells.size():
						result.add_error("Level %s: every cell is VOID; a level needs artwork" % level_label)

	if not result.errors.is_empty():
		return result

	result.level_data = LevelData.new(
		version_int,
		id_value,
		name_value,
		difficulty_value,
		width,
		height,
		palette,
		cells
	)
	return result
