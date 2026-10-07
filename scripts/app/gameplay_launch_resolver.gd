extends RefCounted
## GameplayLaunchResolver — preload (res://scripts/app/gameplay_launch_resolver.gd).
##
## Production frontier -> content mapping (M40 V04, F-M40-V03-002). Resolves
## AppState.progression.current_level() through the canonical LevelCatalog: the
## entry whose explicit `order` equals the frontier level number. Since CP04
## (remote content runtime) the default catalog is AppState.playable_catalog():
## the builtin res:// catalog plus the verified active remote set appended after
## the highest builtin order (builtin 1..10, remote 11+). There is no
## fallback content — a frontier with no catalog entry is CONTENT_MISSING, so
## level-1 content can never run while being labelled/rewarded as level N.

const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

const CONTENT_MISSING := "CONTENT_MISSING"
const CATALOG_INVALID := "CATALOG_INVALID"
const APP_BLOCKED := "APP_BLOCKED"
const NO_APP_STATE := "NO_APP_STATE"

## catalog: optional pre-loaded LevelCatalog (tests); default loads the
## production manifest and fails closed on any validation error.
static func resolve(app_state, catalog = null) -> Dictionary:
	if app_state == null or app_state.progression == null:
		return {"ok": false, "reason": NO_APP_STATE}
	if app_state.is_blocked:
		return {"ok": false, "reason": APP_BLOCKED}
	var level := int(app_state.progression.current_level())
	var cat = catalog
	if cat == null:
		if app_state.has_method("playable_catalog"):
			cat = app_state.playable_catalog()
		else:
			cat = LevelCatalog.new()
			if not cat.load_manifest().ok:
				cat = null
		if cat == null:
			return {"ok": false, "reason": CATALOG_INVALID, "level": level}
	for e in cat.get_entries_ordered():
		if int(e.order) == level:
			return {"ok": true, "level": level, "entry_id": e.id,
				"level_path": e.level_path, "difficulty": e.difficulty,
				"supply_plan_path": e.supply_plan_path, "preview_path": e.preview_path}
	return {"ok": false, "reason": CONTENT_MISSING, "level": level}
