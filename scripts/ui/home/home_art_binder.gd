extends RefCounted
## HomeArtBinder — preload (res://scripts/ui/home/home_art_binder.gd).
##
## M42 (SB-M42-016/017) — the ONLY path by which Home art becomes visible. Asset
## lifecycle gate (docs/HOME_UI_ASSET_PLAN.md):
##   owner reference -> assets/ui/generated candidate -> owner review ->
##   assets/ui/final approved -> Godot bind.
## A texture is returned only when its HOME_ASSET_MANIFEST entry:
##   - validates (HomeAssetManifestValidator: no errors for the manifest as a whole),
##   - has status "APPROVED" set by the owner,
##   - records approved_sha256 and the file on disk still matches it,
##   - lives under assets/ui/final/ (generated candidates can never bind).
## Everything else returns null and the caller keeps its native placeholder. The binder
## never writes, promotes, renames or regenerates any asset.

const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")

var _manifest
var _valid := false
var _by_slug: Dictionary = {}

func _init(manifest = null) -> void:
	_manifest = manifest if manifest != null else V.load_manifest()
	_valid = V.validate(_manifest)["ok"] if _manifest != null else false
	if _valid:
		for a in _manifest["assets"]:
			_by_slug[String(a["slug"])] = a

func is_manifest_valid() -> bool:
	return _valid

## Lifecycle state of one slug: "APPROVED_BOUND", "NOT_APPROVED", "UNKNOWN",
## "HASH_MISMATCH", "NOT_FINAL", "MANIFEST_INVALID".
func state(slug: String) -> String:
	if not _valid:
		return "MANIFEST_INVALID"
	if not _by_slug.has(slug):
		return "UNKNOWN"
	var a: Dictionary = _by_slug[slug]
	if String(a.get("status", "")) != "APPROVED":
		return "NOT_APPROVED"
	var path := String(a.get("path", ""))
	if not path.begins_with(V.FINAL_ROOT):
		return "NOT_FINAL"
	if FileAccess.get_sha256("res://" + path) != String(a.get("approved_sha256", "")):
		return "HASH_MISMATCH"
	return "APPROVED_BOUND"

## Texture for an owner-approved asset, else null (keep native placeholder).
func texture(slug: String) -> Texture2D:
	if state(slug) != "APPROVED_BOUND":
		return null
	return load("res://" + String(_by_slug[slug]["path"])) as Texture2D

## Overwrite protection for tooling: false when `path` is an APPROVED final asset.
func can_write(path: String) -> bool:
	for a in _by_slug.values():
		if String(a.get("path", "")) == path and String(a.get("status", "")) == "APPROVED":
			return false
	return _valid

## Counts per lifecycle state over all ART entries (evidence / owner gate reporting).
func summary() -> Dictionary:
	var out := {}
	for slug in _by_slug:
		if _by_slug[slug].get("kind") == "ART":
			var st := state(slug)
			out[st] = int(out.get(st, 0)) + 1
	return out
