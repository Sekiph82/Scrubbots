extends RefCounted
## HomeWorldCatalog — preload (res://scripts/ui/home/home_world_catalog.gd).
##
## M42 V04 data-driven Home world seam: world_id -> complete background asset (by
## approved manifest slug) + Scrubby placement contract, read from
## data/config/home_worlds_v1.json. No level-range mapping exists (owner-gated); Home
## always shows the catalog's default world until the owner defines one.

const PATH := "res://data/config/home_worlds_v1.json"

static func load_catalog(path: String = PATH) -> Dictionary:
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if typeof(d) == TYPE_DICTIONARY else {}

## World record for `world_id` ("" = default), with rects converted to Rect2/Vector2.
static func world(world_id: String = "", catalog: Dictionary = {}) -> Dictionary:
	var c: Dictionary = catalog if not catalog.is_empty() else load_catalog()
	var id: String = world_id if not world_id.is_empty() else String(c.get("default_world", ""))
	var w: Dictionary = (c.get("worlds", {}) as Dictionary).get(id, {})
	if w.is_empty():
		return {}
	var bots: Array = []
	for r in w.get("helper_bot_rects", []):
		bots.append(_rect(r))
	return {
		"id": id,
		"background_slug": String(w["background_slug"]),
		"canvas": Vector2(w["canvas"][0], w["canvas"][1]),
		"scrubby_feet_anchor": Vector2(w["scrubby_feet_anchor"][0], w["scrubby_feet_anchor"][1]),
		"scrubby_safe_box": _rect(w["scrubby_safe_box"]),
		"platform_top_rect": _rect(w["platform_top_rect"]),
		"baked_sign_rect": _rect(w["baked_sign_rect"]),
		"helper_bot_rects": bots,
	}

static func _rect(a) -> Rect2:
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
