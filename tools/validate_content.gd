extends SceneTree
## SB-M59-007 content validator (release gate): the shipped production catalog must load
## (manifest structure, every level file, metadata, preview, supply plan + its engine; see
## LevelCatalog.load_manifest) and every entry must revalidate (LevelLoader + TEST rejection +
## ProductionLevelValidator + square shell; LevelCatalog.validate_all). Fail closed.
##
## Run: godot --headless --path . -s res://tools/validate_content.gd
## Last line: CONTENT_VALIDATION PASS|FAIL (<entries> entries, <problems> problems); exit 0 only on PASS.

const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

func _initialize() -> void:
	var cat = LevelCatalog.new()
	var problems := 0
	for r in [cat.load_manifest(), cat.validate_all()]:
		for msg in r.errors:
			print("FAIL catalog: %s" % msg)
			problems += 1
		for id in r.entry_errors:
			for msg in r.entry_errors[id]:
				print("FAIL %s: %s" % [id, msg])
				problems += 1
		if not r.ok and problems == 0:
			print("FAIL catalog: not ok without a message")
			problems += 1
	if cat.size() == 0:
		print("FAIL catalog: no entries")
		problems += 1
	print("CONTENT_VALIDATION %s (%d entries, %d problems)" % ["PASS" if problems == 0 else "FAIL", cat.size(), problems])
	quit(0 if problems == 0 else 1)
