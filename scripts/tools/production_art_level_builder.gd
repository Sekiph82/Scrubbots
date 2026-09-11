extends RefCounted
## ProductionArtLevelBuilder — preload this script
## (res://scripts/tools/production_art_level_builder.gd) rather than relying on
## global class_name lookup (AL-001 / ADR-009).
##
## M21 — the PRODUCTION-ART validation/normalization BRIDGE. It closes the
## M09-to-current-palette-contract gap WITHOUT rewriting the historical generic
## M09 importer:
##
##   LevelImporter (M09)          -> deterministic exact-pixel PNG -> LevelData,
##                                   preserving a FIRST-SEEN row-major local
##                                   palette. Generic, source-immutable, audited.
##                                   Its contract is unchanged by this class.
##   ProductionArtLevelBuilder    -> takes that raw first-seen LevelData and
##                                   produces a PRODUCTION-legal LevelData whose
##                                   local palette contains only canonical C01..C16
##                                   colors ACTUALLY used, ordered by ascending
##                                   global C-ID, with cell indices remapped
##                                   deterministically so the visible pixels are
##                                   byte-identical.
##
## This bridge is production-content-specific. It never mutates the generic M09
## importer semantics and never mutates the source PNG.
##
## Palette authority is the machine-readable
## `data/palettes/scrubbots_palette_v2.json` — never a parallel hardcoded table
## (docs/08_PIXEL_ART_PALETTE_RULES.md).
##
## Production-art rules enforced (docs/08_PIXEL_ART_PALETTE_RULES.md):
##   - off-palette logical color        -> REJECT (no nearest-color approximation)
##   - non-opaque (alpha != 255) cell   -> REJECT (canonical #RRGGBBFF == #RRGGBB)
##   - distinct used-color count        -> enforce the difficulty band
##   - final local palette              -> only used canonical colors, ascending C-ID
##   - determinism                      -> identical input yields identical output

const LevelData = preload("res://scripts/data/level_data.gd")
const LevelImporter = preload("res://scripts/tools/level_importer.gd")
const LevelValidator = preload("res://scripts/data/level_validator.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")
const DifficultyRules = preload("res://scripts/data/difficulty_rules.gd")

const BUILDER_VERSION := "M21-C001/v1"
const PALETTE_AUTHORITY_PATH := "res://data/palettes/scrubbots_palette_v2.json"

## M21 LEGACY compatibility color-count gate ONLY (see
## coordination/sessions/M21-C001/OWNER_DIFFICULTY_V1_SCOPE_NOTE.md). Under
## Difficulty V1 color count is a SCORE INPUT, not a difficulty-class law; the
## owner scope note explicitly permits the legacy validator as the M21
## compatibility gate because the approved Hazard Bot asset already fits it. This
## is NOT a future design law and is applied only when the palette authority still
## exposes no per-difficulty bands. Do not treat "5 colors => EASY" as design law.
const LEGACY_M21_DIFFICULTY_COLOR_BANDS := {
	"EASY": {"min": 3, "max": 5},
	"MEDIUM": {"min": 6, "max": 7},
	"HARD": {"min": 8, "max": 9},
	"VERY_HARD": {"min": 10, "max": 12},
}
## Fallback global used-color envelope if the authority omits usedColorEnvelopeV1.
const DEFAULT_USED_COLOR_ENVELOPE := {"min": 3, "max": 12}

## Pure normalization result (no file IO). errors empty == OK.
class NormalizeResult:
	var errors: Array[String] = []
	var level_data  # normalized LevelData or null
	var first_seen_cids: Array = []       # raw first-seen palette as C-IDs
	var normalized_cids: Array = []       # final ascending-C-ID palette
	var used_color_count: int = 0
	var cid_cell_counts: Dictionary = {}  # C-ID -> cell reference count

	func is_ok() -> bool:
		return errors.is_empty() and level_data != null

	func add_error(msg: String) -> void:
		errors.append(msg)

## Full build result (includes file IO planning like LevelImporter).
class BuildResult:
	var errors: Array[String] = []
	var normalize: NormalizeResult
	var level_json_text: String = ""
	var metadata_dict: Dictionary = {}
	var metadata_json_text: String = ""
	var output_written: bool = false
	var output_unchanged: bool = false
	var preview_written: bool = false
	var preview_unchanged: bool = false
	var metadata_written: bool = false
	var metadata_unchanged: bool = false

	func is_ok() -> bool:
		return errors.is_empty() and normalize != null and normalize.is_ok()

	func add_error(msg: String) -> void:
		errors.append(msg)

## Load the canonical palette authority. Returns a dict of lookup maps or null.
static func load_palette_authority():
	var f := FileAccess.open(PALETTE_AUTHORITY_PATH, FileAccess.READ)
	if f == null:
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("colors"):
		return null
	var rgb_to_cid := {}     # "r,g,b" -> "Cnn"
	var cid_to_index := {}   # "Cnn" -> global int index (0..15)
	var cid_to_hex := {}     # "Cnn" -> "#RRGGBBFF"
	for c in parsed["colors"]:
		var r := int(c["rgb"][0]); var g := int(c["rgb"][1]); var b := int(c["rgb"][2])
		var cid := String(c["id"])
		rgb_to_cid["%d,%d,%d" % [r, g, b]] = cid
		cid_to_index[cid] = int(c["index"])
		cid_to_hex[cid] = "#%02X%02X%02XFF" % [r, g, b]
	var rules := {}
	if parsed.has("productionRules"):
		rules = parsed["productionRules"]
	# Legacy per-difficulty color-count bands (present pre-Difficulty-V1). Under
	# Difficulty V1 (docs/12_ADR_DIFFICULTY_V1.md) these are removed from palette
	# truth and color count is a score INPUT, not a class gate.
	var bands := {}
	if rules.has("difficultyColorCountBands"):
		bands = rules["difficultyColorCountBands"]
	# Difficulty V1 global used-color envelope (3..12) — current design truth.
	var envelope := {}
	if rules.has("usedColorEnvelopeV1"):
		envelope = rules["usedColorEnvelopeV1"]
	return {"rgb_to_cid": rgb_to_cid, "cid_to_index": cid_to_index,
		"cid_to_hex": cid_to_hex, "bands": bands, "envelope": envelope}

## Pure production-art validation + palette normalization from a raw first-seen
## LevelData (as produced by the generic M09 importer). Never touches disk except
## reading the palette authority. Never mutates `raw`.
static func normalize_from_level_data(raw, difficulty: String) -> NormalizeResult:
	var result := NormalizeResult.new()
	var auth = load_palette_authority()
	if auth == null:
		result.add_error("Could not load palette authority %s" % PALETTE_AUTHORITY_PATH)
		return result
	if raw == null:
		result.add_error("raw LevelData is null")
		return result

	var rgb_to_cid: Dictionary = auth["rgb_to_cid"]
	var cid_to_index: Dictionary = auth["cid_to_index"]
	var cid_to_hex: Dictionary = auth["cid_to_hex"]

	# --- map each first-seen palette entry to a canonical C-ID (fail closed) ---
	var raw_index_to_cid := {}   # old palette index -> C-ID
	for i in raw.palette.size():
		var hex: String = raw.palette[i]
		var rgba = _parse_hex_rgba(hex)
		if rgba == null:
			result.add_error("Palette entry %d '%s' is not a valid #RRGGBB[AA] color" % [i, hex])
			continue
		# Canonical #RRGGBBFF is opaque-equivalent to #RRGGBB. Any other alpha is
		# rejected (no admission of semi-transparent production logical colors).
		if rgba[3] != 255:
			result.add_error("Palette entry %d '%s' has alpha %d; production logical cells must be alpha 255" % [i, hex, rgba[3]])
			continue
		var key := "%d,%d,%d" % [rgba[0], rgba[1], rgba[2]]
		if not rgb_to_cid.has(key):
			# No nearest-color approximation — off-palette is a hard reject.
			result.add_error("Palette entry %d '%s' (RGB %s) is off-palette; not one of C01..C16" % [i, hex, key])
			continue
		result.first_seen_cids.append(rgb_to_cid[key])
		raw_index_to_cid[i] = rgb_to_cid[key]
	if not result.errors.is_empty():
		return result

	# --- distinct used colors are computed from CELLS, not palette length ---
	var cid_counts := {}
	for old_idx in raw.cells:
		if not raw_index_to_cid.has(old_idx):
			result.add_error("Cell references unknown palette index %d" % old_idx)
			return result
		var cid: String = raw_index_to_cid[old_idx]
		cid_counts[cid] = int(cid_counts.get(cid, 0)) + 1
	result.cid_cell_counts = cid_counts
	var used_cids: Array = cid_counts.keys()
	result.used_color_count = used_cids.size()

	# --- enforce Difficulty V1 global used-color envelope (current design truth) ---
	var envelope: Dictionary = auth["envelope"] if not auth["envelope"].is_empty() else DEFAULT_USED_COLOR_ENVELOPE
	var emin := int(envelope["min"]); var emax := int(envelope["max"])
	if result.used_color_count < emin or result.used_color_count > emax:
		result.add_error("Distinct used-color count %d outside V1 used-color envelope %d..%d" % [result.used_color_count, emin, emax])
		return result

	# --- enforce the M21 LEGACY per-difficulty color-count compatibility gate ---
	# (compat only; see LEGACY_M21_DIFFICULTY_COLOR_BANDS). Prefer authority bands
	# if still present, else the documented legacy compat constant.
	var bands: Dictionary = auth["bands"] if not auth["bands"].is_empty() else LEGACY_M21_DIFFICULTY_COLOR_BANDS
	if not bands.has(difficulty):
		result.add_error("Difficulty '%s' has no legacy color-count compatibility band" % difficulty)
		return result
	var band: Dictionary = bands[difficulty]
	var bmin := int(band["min"]); var bmax := int(band["max"])
	if result.used_color_count < bmin or result.used_color_count > bmax:
		result.add_error("Distinct used-color count %d outside legacy %s compat band %d..%d" % [result.used_color_count, difficulty, bmin, bmax])
		return result

	# --- normalize local palette to ascending global C-ID order ---
	used_cids.sort_custom(func(a, b): return int(cid_to_index[a]) < int(cid_to_index[b]))
	result.normalized_cids = used_cids
	var norm_palette := PackedStringArray()
	var cid_to_new_index := {}
	for i in used_cids.size():
		var cid: String = used_cids[i]
		cid_to_new_index[cid] = i
		norm_palette.append(cid_to_hex[cid])

	# --- remap cells deterministically (visual pixels unchanged) ---
	var new_cells := PackedInt32Array()
	new_cells.resize(raw.cells.size())
	for i in raw.cells.size():
		new_cells[i] = cid_to_new_index[raw_index_to_cid[raw.cells[i]]]

	var normalized := LevelData.new(
		LevelData.FORMAT_VERSION, raw.id, raw.display_name, raw.difficulty,
		raw.width, raw.height, norm_palette, new_cells)

	# --- structural + production validation of the normalized result ---
	var struct := LevelValidator.validate(_level_to_dict(normalized), normalized.id)
	if not struct.is_ok():
		result.add_error("Normalized level failed structural validation: %s" % str(struct.errors))
		return result
	if DifficultyRules.is_production_difficulty(normalized.difficulty):
		var prod := ProductionLevelValidator.validate(normalized)
		if not prod.is_ok():
			result.add_error("Normalized level failed production validation: %s" % str(prod.errors))
			return result

	# --- final local palette invariant: only used canonical colors, ascending ---
	var palette_check := _validate_canonical_palette(normalized.palette, auth)
	if not palette_check.is_empty():
		result.add_error(palette_check)
		return result

	# --- reconstruction equality: remap must not change visible pixels ---
	var raw_img = LevelImporter.reconstruct_image(raw)
	var norm_img = LevelImporter.reconstruct_image(normalized)
	if raw_img == null or norm_img == null:
		result.add_error("Reconstruction failed during normalization equality check")
		return result
	if raw_img.get_data() != norm_img.get_data():
		result.add_error("Palette remap changed visible pixels (reconstruction mismatch)")
		return result

	result.level_data = normalized
	return result

## Full production-art build: reuse the audited generic importer for exact-pixel
## extraction, then normalize, then plan/write final JSON + preview + metadata.
static func build(source_path: String, level_id: String, display_name: String,
		difficulty: String, output_path: String, preview_path: String,
		metadata_path: String, overwrite: bool = false) -> BuildResult:
	var result := BuildResult.new()

	# --- fail-closed path aliasing (source immutability) ---
	var alias := _check_aliases(source_path, [output_path, preview_path, metadata_path])
	if not alias.is_empty():
		result.add_error(alias)
		return result

	# --- reuse the audited generic importer (dry_run: extract, do not write) ---
	# dry_run guarantees no write; overwrite=true keeps the importer's own output
	# preflight from comparing its FIRST-SEEN serialization against our already-
	# committed NORMALIZED file (different content by design). Our own destination
	# planning below owns the real overwrite/unchanged semantics.
	var import_req := LevelImporter.ImportRequest.new(
		source_path, level_id, display_name, difficulty,
		output_path, "", "", true, true)
	var import_res := LevelImporter.run_import(import_req)
	if not import_res.is_ok():
		result.add_error("Generic importer extraction failed: %s" % str(import_res.errors))
		return result

	# --- production-art normalization ---
	var norm := normalize_from_level_data(import_res.level_data, difficulty)
	result.normalize = norm
	if not norm.is_ok():
		result.add_error("Production-art normalization failed: %s" % str(norm.errors))
		return result
	var level = norm.level_data

	# --- serialize deterministically (tab indent, trailing newline) ---
	result.level_json_text = _serialize_json(_level_to_dict(level))

	# --- preview image from FINAL level data (no source shortcut) ---
	var preview_img = LevelImporter.reconstruct_image(level)
	if preview_img == null:
		result.add_error("Preview reconstruction from final level data failed")
		return result

	# --- metadata / provenance ---
	result.metadata_dict = _build_metadata(source_path, level, norm, output_path, preview_path)
	result.metadata_json_text = _serialize_json(result.metadata_dict)

	# --- plan all destinations before writing any (fail closed on conflict) ---
	var out_plan := _plan_text(output_path, result.level_json_text, overwrite)
	if out_plan == "error":
		result.add_error("Output '%s' exists with different content and overwrite=false" % output_path)
		return result
	var prev_plan := _plan_image(preview_path, preview_img, overwrite)
	if prev_plan == "error":
		result.add_error("Preview '%s' exists with different content and overwrite=false" % preview_path)
		return result
	var meta_plan := _plan_text(metadata_path, result.metadata_json_text, overwrite)
	if meta_plan == "error":
		result.add_error("Metadata '%s' exists with different content and overwrite=false" % metadata_path)
		return result

	# --- write (or note unchanged) ---
	if out_plan == "write":
		if _write_text(output_path, result.level_json_text) != OK:
			result.add_error("Could not write output '%s'" % output_path)
			return result
		result.output_written = true
	else:
		result.output_unchanged = true

	if prev_plan == "write":
		if preview_img.save_png(preview_path) != OK:
			result.add_error("Could not write preview '%s'" % preview_path)
			return result
		result.preview_written = true
	else:
		result.preview_unchanged = true

	if meta_plan == "write":
		if _write_text(metadata_path, result.metadata_json_text) != OK:
			result.add_error("Could not write metadata '%s'" % metadata_path)
			return result
		result.metadata_written = true
	else:
		result.metadata_unchanged = true

	return result

# ----------------------------------------------------------------- helpers ----

## Parse "#RRGGBB" or "#RRGGBBAA" -> [r,g,b,a] ints, or null if malformed.
static func _parse_hex_rgba(hex: String):
	if typeof(hex) != TYPE_STRING or not hex.begins_with("#"):
		return null
	var body := hex.substr(1)
	if body.length() != 6 and body.length() != 8:
		return null
	for ch in body:
		if not ("0123456789abcdefABCDEF".contains(ch)):
			return null
	var r: int = body.substr(0, 2).hex_to_int()
	var g: int = body.substr(2, 2).hex_to_int()
	var b: int = body.substr(4, 2).hex_to_int()
	var a: int = body.substr(6, 2).hex_to_int() if body.length() == 8 else 255
	return [r, g, b, a]

## Empty string == OK; otherwise an error message. Confirms the palette is exactly
## a subset of canonical C-IDs, ascending by global index, no duplicates.
static func _validate_canonical_palette(palette: PackedStringArray, auth) -> String:
	var rgb_to_cid: Dictionary = auth["rgb_to_cid"]
	var cid_to_index: Dictionary = auth["cid_to_index"]
	var last_index := -1
	var seen := {}
	for i in palette.size():
		var rgba = _parse_hex_rgba(palette[i])
		if rgba == null or rgba[3] != 255:
			return "Final palette entry %d '%s' is not opaque canonical hex" % [i, palette[i]]
		var key := "%d,%d,%d" % [rgba[0], rgba[1], rgba[2]]
		if not rgb_to_cid.has(key):
			return "Final palette entry %d '%s' is off-palette" % [i, palette[i]]
		var cid: String = rgb_to_cid[key]
		if seen.has(cid):
			return "Final palette has duplicate canonical color %s" % cid
		seen[cid] = true
		var gidx := int(cid_to_index[cid])
		if gidx <= last_index:
			return "Final palette not ascending by global C-ID at entry %d (%s)" % [i, cid]
		last_index = gidx
	return ""

static func _check_aliases(source: String, dests: Array) -> String:
	var src := _canon(source)
	var seen := {}
	for d in dests:
		if String(d).is_empty():
			continue
		var cd := _canon(d)
		if cd == src:
			return "Destination '%s' aliases immutable source" % d
		if seen.has(cd):
			return "Destination '%s' aliases another destination" % d
		seen[cd] = true
	return ""

static func _canon(p: String) -> String:
	if p.is_empty():
		return ""
	var r := p.replace("\\", "/")
	if r.begins_with("res://") or r.begins_with("user://"):
		r = ProjectSettings.globalize_path(r)
	elif not r.is_absolute_path():
		r = ProjectSettings.globalize_path("res://" + r)
	r = r.simplify_path()
	if OS.get_name() == "Windows":
		r = r.to_lower()
	return r

## "write" | "unchanged" | "error"
static func _plan_text(path: String, text: String, overwrite: bool) -> String:
	if path.is_empty():
		return "unchanged"
	if not FileAccess.file_exists(path):
		return "write"
	if overwrite:
		return "write"
	return "unchanged" if FileAccess.get_file_as_string(path) == text else "error"

static func _plan_image(path: String, img: Image, overwrite: bool) -> String:
	if path.is_empty():
		return "unchanged"
	if not FileAccess.file_exists(path):
		return "write"
	if overwrite:
		return "write"
	var existing := Image.new()
	if existing.load(path) != OK:
		return "error"
	if existing.get_format() != Image.FORMAT_RGBA8:
		existing.convert(Image.FORMAT_RGBA8)
	var same := existing.get_width() == img.get_width() and existing.get_height() == img.get_height() \
		and existing.get_data() == img.get_data()
	return "unchanged" if same else "error"

static func _build_metadata(source_path: String, level, norm: NormalizeResult, output_path: String, preview_path: String) -> Dictionary:
	var counts := {}
	for cid in norm.cid_cell_counts:
		counts[cid] = int(norm.cid_cell_counts[cid])
	return {
		"builderVersion": BUILDER_VERSION,
		"sourcePath": source_path,
		"sourceGitBlobSha1": _git_blob_sha1_file(source_path),
		"sourceSha256": _sha256_file(source_path),
		"width": level.width,
		"height": level.height,
		"cellCount": level.get_cell_count(),
		"difficulty": level.difficulty,
		"paletteAuthority": PALETTE_AUTHORITY_PATH,
		"firstSeenColorOrder": norm.first_seen_cids,
		"normalizedColorOrder": norm.normalized_cids,
		"usedColorCount": norm.used_color_count,
		"cellReferenceCounts": counts,
		"outputPath": output_path,
		"previewPath": preview_path,
	}

static func _level_to_dict(level) -> Dictionary:
	var palette_arr: Array = []
	for entry in level.palette:
		palette_arr.append(entry)
	var cells_arr: Array = []
	for c in level.cells:
		cells_arr.append(c)
	return {
		"version": level.version, "id": level.id, "name": level.display_name,
		"difficulty": level.difficulty, "width": level.width, "height": level.height,
		"palette": palette_arr, "cells": cells_arr,
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

static func _sha256_file(path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(path)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()

## Git blob SHA1 = sha1("blob " + size + "\0" + content).
static func _git_blob_sha1_file(path: String) -> String:
	var bytes := FileAccess.get_file_as_bytes(path)
	var header := ("blob %d" % bytes.size()).to_utf8_buffer()
	header.append(0)
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA1)
	ctx.update(header)
	ctx.update(bytes)
	return ctx.finish().hex_encode()
