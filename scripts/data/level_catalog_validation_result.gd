extends RefCounted
## LevelCatalogValidationResult — preload
## (res://scripts/data/level_catalog_validation_result.gd).
## Deterministic fail-closed batch validation result.

var ok: bool = true
var errors: PackedStringArray = PackedStringArray()
var entry_errors: Dictionary = {}   ## id (String) -> PackedStringArray

func add_error(msg: String) -> void:
	ok = false
	errors.append(msg)

func add_entry_error(id: String, msg: String) -> void:
	ok = false
	if not entry_errors.has(id):
		entry_errors[id] = PackedStringArray()
	entry_errors[id].append(msg)

func merge_prefixed(id: String, other) -> void:
	# other is either a LevelValidationResult or ProductionValidationResult.
	if other == null:
		return
	if "errors" in other:
		for e in other.errors:
			add_entry_error(id, String(e))

func summary() -> String:
	if ok:
		return "ok"
	var lines: PackedStringArray = PackedStringArray()
	for e in errors:
		lines.append(String(e))
	for k in entry_errors.keys():
		for e in entry_errors[k]:
			lines.append("[%s] %s" % [k, e])
	return ", ".join(lines)
