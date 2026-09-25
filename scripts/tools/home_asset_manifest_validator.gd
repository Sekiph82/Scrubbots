extends RefCounted
## HomeAssetManifestValidator — preload
## (res://scripts/tools/home_asset_manifest_validator.gd).
##
## M42 (SB-M42-013) — deterministic validation of assets/ui/HOME_ASSET_MANIFEST.json
## BEFORE any generation or binding. Pure: validate(manifest) never touches files except
## to hash an APPROVED asset for overwrite protection.
##
## Rules:
##   - schema_version 1, screen "home", assets array;
##   - ids HOME-NNN unique; slugs lowercase snake_case unique;
##   - kind in KINDS; implementation matches kind;
##   - generated ART: generation_required bool, path under assets/ui/final/, provider
##     order chatgpt_image_generation -> [magnific];
##   - LIVE / NATIVE / FX / THEME entries carry no image path (live text is never baked);
##   - duplicate final paths only for an explicit reuse (generation_required=false entry
##     reusing an earlier generated path);
##   - status in STATUSES; an APPROVED asset must record approved_sha256 and the file on
##     disk must still match it (no silent overwrite/regeneration of approved art);
##   - Economy V1: no Star / Event Points / profile-XP / coin authority in any slug, id
##     or path (a star-SHAPED FX is reported as a warning, not currency);
##   - required Economy V1 Home entries exist (Scrub Bucks icon, Bot Parts bar, Gift
##     Meter, Cards Exchange shortcut, Win Streak reward track).

const KINDS := ["ART", "LIVE", "FX", "NATIVE", "NATIVE_OR_9_SLICE", "FONT", "REUSE", "THEME"]
const STATUSES := ["PLANNED", "AWAITING_FONT_SELECTION", "CANDIDATE", "OWNER_REVIEW", "APPROVED", "REJECTED"]
const IMPLEMENTATION_BY_KIND := {
	"ART": ["generated_asset"],
	"LIVE": ["live_godot_ui"],
	"FX": ["godot_fx_or_small_texture"],
	"NATIVE": ["godot_native"],
	"NATIVE_OR_9_SLICE": ["godot_native"],
	"FONT": ["licensed_font_asset"],
	"REUSE": ["godot_native"],
	"THEME": ["godot_native"],
}
const PROVIDER_PRIMARY := "chatgpt_image_generation"
const PROVIDER_FALLBACK := ["magnific"]
const FINAL_ROOT := "assets/ui/final/"
const BANNED_TOKENS := ["star", "stars", "xp", "coin", "coins"]
const BANNED_COMPOUNDS := ["event_point", "eventpoint", "profile_xp", "star_currency", "star_exchange"]
const REQUIRED_SLUGS := [
	"icon_currency_scrub_bucks", "profile_bot_parts_bar_fill", "profile_bot_parts_values",
	"gift_meter_bar_fill", "gift_meter_progress_value", "gift_meter_next_milestone_value",
	"icon_shortcut_cards_exchange", "win_streak_reward_amounts", "reward_current_win_streak",
]

static func load_manifest(path: String = "res://assets/ui/HOME_ASSET_MANIFEST.json"):
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

## Returns {ok: bool, errors: Array[String], warnings: Array[String], reuse: Dictionary}.
static func validate(m, project_root: String = "res://") -> Dictionary:
	var errors: Array = []
	var warnings: Array = []
	var reuse := {}
	if typeof(m) != TYPE_DICTIONARY:
		return {"ok": false, "errors": ["manifest is not an object"], "warnings": [], "reuse": {}}
	if m.get("schema_version") != 1 and m.get("schema_version") != 1.0:
		errors.append("schema_version must be 1")
	if m.get("screen") != "home":
		errors.append("screen must be 'home'")
	var assets = m.get("assets")
	if typeof(assets) != TYPE_ARRAY or assets.is_empty():
		errors.append("assets must be a non-empty array")
		return {"ok": false, "errors": errors, "warnings": warnings, "reuse": reuse}
	var ids := {}
	var slugs := {}
	var paths := {}
	var snake := RegEx.create_from_string("^[a-z0-9]+(_[a-z0-9]+)*$")
	var idre := RegEx.create_from_string("^HOME-[0-9]{3}$")
	for a in assets:
		if typeof(a) != TYPE_DICTIONARY:
			errors.append("asset entry is not an object")
			continue
		var id := str(a.get("id", ""))
		var slug := str(a.get("slug", ""))
		var kind := str(a.get("kind", ""))
		var impl := str(a.get("implementation", ""))
		var status := str(a.get("status", ""))
		var path = a.get("path", null)
		var tag := "%s/%s" % [id, slug]
		if idre.search(id) == null:
			errors.append("%s: bad id" % tag)
		elif ids.has(id):
			errors.append("%s: duplicate id" % tag)
		ids[id] = true
		if snake.search(slug) == null:
			errors.append("%s: slug must be lowercase snake_case" % tag)
		elif slugs.has(slug):
			errors.append("%s: duplicate slug" % tag)
		slugs[slug] = true
		if not KINDS.has(kind):
			errors.append("%s: unknown kind '%s'" % [tag, kind])
		elif not (IMPLEMENTATION_BY_KIND[kind] as Array).has(impl):
			errors.append("%s: implementation '%s' invalid for kind %s" % [tag, impl, kind])
		if not STATUSES.has(status):
			errors.append("%s: unknown status '%s'" % [tag, status])
		# Economy V1 banned authority.
		for field in [id.to_lower(), slug, str(path).to_lower() if path != null else ""]:
			var norm: String = field.replace("/", "_").replace(".", "_").replace("-", "_")
			for comp in BANNED_COMPOUNDS:
				if norm.find(comp) != -1:
					errors.append("%s: banned Economy V1 token '%s'" % [tag, comp])
			for part in norm.split("_"):
				if BANNED_TOKENS.has(part):
					if kind == "FX" and part in ["star", "stars"]:
						warnings.append("%s: star-shaped FX (decorative, not Star currency)" % tag)
					else:
						errors.append("%s: banned Economy V1 token '%s'" % [tag, part])
		if kind == "ART":
			if typeof(a.get("generation_required")) != TYPE_BOOL:
				errors.append("%s: generation_required must be bool" % tag)
			if typeof(path) != TYPE_STRING or not String(path).begins_with(FINAL_ROOT) or not String(path).ends_with(".png"):
				errors.append("%s: ART path must be a .png under %s" % [tag, FINAL_ROOT])
			if a.get("generation_required") == true:
				if a.get("provider") != PROVIDER_PRIMARY:
					errors.append("%s: provider must be %s" % [tag, PROVIDER_PRIMARY])
				if a.get("fallback_providers") != PROVIDER_FALLBACK:
					errors.append("%s: fallback_providers must be %s" % [tag, str(PROVIDER_FALLBACK)])
			if typeof(path) == TYPE_STRING:
				if paths.has(path):
					if a.get("generation_required") == false:
						reuse[id] = paths[path]
					else:
						errors.append("%s: duplicate final path %s (not a declared reuse)" % [tag, path])
				else:
					paths[path] = id
		elif kind in ["LIVE", "NATIVE", "FX", "THEME", "REUSE", "NATIVE_OR_9_SLICE"]:
			if path != null:
				errors.append("%s: %s entries must not carry an image path (no baked live text)" % [tag, kind])
		if status == "APPROVED":
			var want := str(a.get("approved_sha256", ""))
			if want.length() != 64:
				errors.append("%s: APPROVED requires approved_sha256" % tag)
			elif typeof(path) == TYPE_STRING:
				var got := FileAccess.get_sha256(project_root + String(path))
				if got != want:
					errors.append("%s: approved asset changed on disk (sha256 %s != %s)" % [tag, got, want])
	for req in REQUIRED_SLUGS:
		if not slugs.has(req):
			errors.append("missing required Economy V1 Home entry '%s'" % req)
	return {"ok": errors.is_empty(), "errors": errors, "warnings": warnings, "reuse": reuse}
