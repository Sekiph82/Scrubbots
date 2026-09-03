extends RefCounted
## LevelBatchImporter — deterministic batch layer over the M09-C001-audited
## single-image LevelImporter. Adds manifest-driven batch import/validation
## and duplicate level-ID protection (M09-C002, SB-M09-018..020).
##
## Reuses LevelImporter unchanged for every per-item concern (PNG-only gate,
## exact-pixel conversion, palette/cell semantics, difficulty legality,
## reconstruction, path-alias detection, overwrite/unchanged preflight).
## This file adds only what a single item cannot know on its own: manifest
## parsing, whole-batch preflight-before-any-write ordering, cross-item path
## safety, and catalog duplicate-ID scanning.
##
## Manifest schema (deterministic JSON):
##   { "items": [ { "source": "...", "id": "...", "name": "...",
##                  "difficulty": "...", "output": "...",
##                  "preview": "..." (optional), "metadata": "..." (optional),
##                  "overwrite": false (optional) }, ... ] }
## `items` must be a non-empty array; item order is preserved throughout
## (batch processing order, report order) — no other ordering is used.
##
## Prepare/validate-then-commit architecture:
##   1. Every item is preflighted via LevelImporter.run_import(dry_run=true)
##      (this alone runs every M09-C001 validation/safety check, including
##      per-item path aliasing) plus batch-only checks: duplicate IDs within
##      the manifest, duplicate/aliased destinations across items, a source
##      in one item aliasing a destination in another, and duplicate/
##      malformed IDs found while scanning the existing catalog directory.
##   2. Final artifacts for the WHOLE batch are written only if every item
##      and every batch-only check passed preflight. A failing later item
##      prevents any earlier item's final artifacts from being committed.
##   3. Validation-only mode simply stops after step 1 — every check still
##      runs, nothing is ever written (dry_run=true never reaches a physical
##      write call in LevelImporter.run_import()).
##
## Non-transactional limitation: preflight is a full logical check against
## catalog state as observed at batch start. The commit pass then re-invokes
## the audited single importer per item in manifest order. If preflight
## passed but a rare OS-level write failure occurs partway through the
## commit pass (disk full, permissions changed mid-run, etc.), items already
## written before that point remain written — there is no filesystem
## transaction/rollback. This is a real, documented limitation, not a
## claimed guarantee.

const LevelImporter = preload("res://scripts/tools/level_importer.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")

const REQUIRED_ITEM_FIELDS := ["source", "id", "name", "difficulty", "output"]

## One manifest item's outcome inside a batch run.
class BatchItemResult:
	var index: int = -1
	var id: String = ""
	var source: String = ""
	var output: String = ""
	var request = null  # LevelImporter.ImportRequest, or null if never built
	var import_result = null  # LevelImporter.ImportResult, or null if never run
	var batch_errors: Array[String] = []  # duplicate-ID / cross-item path findings

	func all_errors() -> Array[String]:
		var out: Array[String] = []
		out.append_array(batch_errors)
		if import_result != null:
			out.append_array(import_result.errors)
		return out

	func is_ok() -> bool:
		return batch_errors.is_empty() and import_result != null and import_result.is_ok()

## Full batch run result.
class BatchResult:
	var manifest_errors: Array[String] = []
	var items: Array = []  # BatchItemResult, manifest order
	var catalog_malformed: Array[Dictionary] = []      # {path, errors}
	var catalog_duplicate_ids: Array[Dictionary] = []  # {id, paths}
	var validation_only: bool = true
	var committed: bool = false

	func is_ok() -> bool:
		if not manifest_errors.is_empty():
			return false
		for item in items:
			if not item.is_ok():
				return false
		return true

	func total_requested() -> int:
		return items.size()

	func valid_count() -> int:
		var n := 0
		for item in items:
			if item.is_ok():
				n += 1
		return n

	func invalid_count() -> int:
		return items.size() - valid_count()

	func written_count() -> int:
		var n := 0
		for item in items:
			if item.import_result != null and item.import_result.output_written:
				n += 1
		return n

	func unchanged_count() -> int:
		var n := 0
		for item in items:
			if item.import_result != null and item.import_result.output_unchanged:
				n += 1
		return n

	## Deterministic structured report (stable key/array order) suitable for
	## CLI JSON output and test assertions.
	func to_report() -> Dictionary:
		var items_report: Array = []
		for item in items:
			items_report.append({
				"index": item.index,
				"id": item.id,
				"source": item.source,
				"output": item.output,
				"ok": item.is_ok(),
				"errors": item.all_errors(),
				"written": item.import_result.output_written if item.import_result != null else false,
				"unchanged": item.import_result.output_unchanged if item.import_result != null else false,
			})
		return {
			"mode": "validation_only" if validation_only else "commit",
			"committed": committed,
			"ok": is_ok(),
			"total_requested": total_requested(),
			"valid_count": valid_count(),
			"invalid_count": invalid_count(),
			"written_count": written_count(),
			"unchanged_count": unchanged_count(),
			"manifest_errors": manifest_errors,
			"catalog_malformed": catalog_malformed,
			"catalog_duplicate_ids": catalog_duplicate_ids,
			"items": items_report,
		}

## Run one batch: parse manifest, scan catalog_root once, preflight the
## whole batch, then (if commit==true and preflight passed) write every
## item's final artifacts. If commit==false this is validation-only and
## nothing is ever written.
static func run_batch(manifest_path: String, catalog_root: String, commit: bool) -> BatchResult:
	var result := BatchResult.new()
	result.validation_only = not commit

	# ---- 1. manifest parse ----
	if not FileAccess.file_exists(manifest_path):
		result.manifest_errors.append("Manifest '%s' does not exist" % manifest_path)
		return result
	var mf := FileAccess.open(manifest_path, FileAccess.READ)
	if mf == null:
		result.manifest_errors.append("Manifest '%s' could not be opened (error %d)" % [manifest_path, FileAccess.get_open_error()])
		return result
	var text := mf.get_as_text()
	mf.close()

	var json := JSON.new()
	var parse_err := json.parse(text)
	if parse_err != OK:
		result.manifest_errors.append(
			"Manifest '%s' malformed JSON at line %d: %s" % [manifest_path, json.get_error_line(), json.get_error_message()])
		return result
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY or not data.has("items") or typeof(data["items"]) != TYPE_ARRAY:
		result.manifest_errors.append("Manifest '%s' must be an object with an 'items' array" % manifest_path)
		return result
	var raw_items: Array = data["items"]
	if raw_items.is_empty():
		result.manifest_errors.append("Manifest '%s' has an empty 'items' array" % manifest_path)
		return result

	# ---- 2. build one BatchItemResult + ImportRequest per manifest item, in order ----
	for i in raw_items.size():
		var raw = raw_items[i]
		var item := BatchItemResult.new()
		item.index = i
		result.items.append(item)

		if typeof(raw) != TYPE_DICTIONARY:
			item.batch_errors.append("Item %d is not an object" % i)
			continue

		var missing: Array[String] = []
		for field in REQUIRED_ITEM_FIELDS:
			if not raw.has(field) or typeof(raw[field]) != TYPE_STRING or String(raw[field]).is_empty():
				missing.append(field)
		if not missing.is_empty():
			item.batch_errors.append("Item %d missing required field(s): %s" % [i, ", ".join(missing)])
			continue

		item.id = raw["id"]
		item.source = raw["source"]
		item.output = raw["output"]
		var preview: String = raw.get("preview", "")
		var metadata: String = raw.get("metadata", "")
		var overwrite: bool = raw.get("overwrite", false)
		item.request = LevelImporter.ImportRequest.new(
			item.source, item.id, raw["name"], raw["difficulty"],
			item.output, preview, metadata, overwrite, true  # dry_run=true for preflight
		)

	# ---- 3. duplicate ID within batch ----
	var id_to_indices := {}
	for item in result.items:
		if item.request == null:
			continue
		if not id_to_indices.has(item.id):
			id_to_indices[item.id] = []
		id_to_indices[item.id].append(item.index)
	var batch_ids := id_to_indices.keys()
	batch_ids.sort()
	for id in batch_ids:
		var idxs: Array = id_to_indices[id]
		if idxs.size() > 1:
			for idx in idxs:
				result.items[idx].batch_errors.append(
					"Duplicate id '%s' within batch (items %s)" % [id, str(idxs)])

	# ---- 4. catalog scan (once per run, not per item) ----
	var id_to_catalog_paths := {}
	var dir := DirAccess.open(catalog_root)
	if dir != null:
		var json_files: Array[String] = []
		dir.list_dir_begin()
		var fname := dir.get_next()
		while not fname.is_empty():
			if not dir.current_is_dir() and fname.to_lower().ends_with(".json"):
				json_files.append(fname)
			fname = dir.get_next()
		dir.list_dir_end()
		json_files.sort()
		for jf in json_files:
			var full_path: String = catalog_root.path_join(jf)
			var load_res := LevelLoader.load_from_path(full_path)
			if not load_res.is_ok():
				result.catalog_malformed.append({"path": full_path, "errors": load_res.errors})
				continue
			var lvl_id: String = load_res.level_data.id
			if not id_to_catalog_paths.has(lvl_id):
				id_to_catalog_paths[lvl_id] = []
			id_to_catalog_paths[lvl_id].append(full_path)

	var catalog_ids := id_to_catalog_paths.keys()
	catalog_ids.sort()
	for id in catalog_ids:
		var paths: Array = id_to_catalog_paths[id]
		if paths.size() > 1:
			paths.sort()
			result.catalog_duplicate_ids.append({"id": id, "paths": paths})

	# ---- 5. duplicate ID against catalog / same-entry re-import semantics ----
	for item in result.items:
		if item.request == null:
			continue
		if not id_to_catalog_paths.has(item.id):
			continue
		var existing_paths: Array = id_to_catalog_paths[item.id]
		if existing_paths.size() > 1:
			item.batch_errors.append(
				"id '%s' is ambiguous in the existing catalog (%d files declare it — see catalog duplicate report)" % [item.id, existing_paths.size()])
			continue
		var existing_path: String = existing_paths[0]
		var canon_existing := LevelImporter._canonical_path(existing_path)
		var canon_requested := LevelImporter._canonical_path(item.output)
		if canon_existing != canon_requested:
			item.batch_errors.append(
				"id '%s' already belongs to a different catalog file '%s' (requested output '%s') — a different file cannot claim an existing level id; overwrite does not authorize this" % [item.id, existing_path, item.output])
		# else: same physical catalog entry — allowed re-import, governed by
		# LevelImporter's own overwrite/unchanged preflight in step 7.

	# ---- 6. cross-item path safety (destination-destination, source-destination) ----
	# ponytail: O(n^2) pairwise compare — fine for realistic manifest sizes;
	# switch to a canonical-path hash index if batches ever grow very large.
	var entries: Array = []
	for item in result.items:
		if item.request == null:
			continue
		var req = item.request
		entries.append({"index": item.index, "role": "source", "path": req.source_path, "canonical": LevelImporter._canonical_path(req.source_path)})
		entries.append({"index": item.index, "role": "output", "path": req.output_path, "canonical": LevelImporter._canonical_path(req.output_path)})
		if not req.preview_path.is_empty():
			entries.append({"index": item.index, "role": "preview", "path": req.preview_path, "canonical": LevelImporter._canonical_path(req.preview_path)})
		if not req.metadata_path.is_empty():
			entries.append({"index": item.index, "role": "metadata", "path": req.metadata_path, "canonical": LevelImporter._canonical_path(req.metadata_path)})

	var destinations: Array = entries.filter(func(e): return e["role"] != "source")
	var sources: Array = entries.filter(func(e): return e["role"] == "source")

	for a in range(destinations.size()):
		for b in range(a + 1, destinations.size()):
			var da = destinations[a]
			var db = destinations[b]
			if da["canonical"] == db["canonical"]:
				var msg := "item %d %s aliases item %d %s ('%s')" % [da["index"], da["role"], db["index"], db["role"], da["path"]]
				result.items[da["index"]].batch_errors.append(msg)
				if db["index"] != da["index"]:
					result.items[db["index"]].batch_errors.append(msg)

	for s in sources:
		for d in destinations:
			if s["canonical"] == d["canonical"]:
				var msg := "item %d source aliases item %d %s ('%s') — source must remain immutable" % [s["index"], d["index"], d["role"], s["path"]]
				result.items[s["index"]].batch_errors.append(msg)
				if d["index"] != s["index"]:
					result.items[d["index"]].batch_errors.append(msg)

	# ---- 7. per-item preflight (reuses the audited single importer, dry_run=true) ----
	for item in result.items:
		if item.request == null:
			continue
		item.import_result = LevelImporter.run_import(item.request)

	# ---- 8. commit pass: only if requested AND the whole batch preflighted clean ----
	var preflight_ok := result.is_ok()
	if commit and preflight_ok:
		for item in result.items:
			if item.request == null:
				continue
			var r = item.request
			var commit_req = LevelImporter.ImportRequest.new(
				r.source_path, r.level_id, r.display_name, r.difficulty,
				r.output_path, r.preview_path, r.metadata_path, r.overwrite, false
			)
			item.import_result = LevelImporter.run_import(commit_req)
		result.committed = true

	return result
