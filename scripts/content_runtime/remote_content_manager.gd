extends RefCounted
## RemoteContentManager — preload (res://scripts/content_runtime/remote_content_manager.gd).
##
## The ONE game-owned remote content authority (CP04/M15 + CP05/M16). Orchestration and
## state only; parsing/inspection live in ContentManifestV1 / ScrubpackV1, bytes move
## through an injected provider-neutral transport:
##   transport.fetch_manifest() -> {ok, reason, bytes}
##   transport.fetch_object(object_key, part_path, max_bytes) -> {ok, reason}
## (HttpsContentTransport in production; fakes in tests; either may be a coroutine).
##
## Everything it writes lives under `root` (production: user://content/); nothing is
## ever written to res://, loaded as a Resource or executed.
##
##   <root>registry_v1.json        active = last-known-good set (versioned registry)
##   <root>registry_v1.prev.json   the previous LKG, kept as rollback evidence
##   <root>registry_v1.json.tmp    candidate registry (renamed over the active one)
##   <root>packs/<pack_id>/<pack_version>-<sha256>/levels/<id>/{level,supply-plan,metadata}.json
##   <root>downloads/<tx>.part     in-flight download (never read before full verification)
##   <root>staging/<tx>/           materialized candidate pack before the rename into packs/
##
## Boot never touches the network: builtin content is always available; a valid cached
## LKG is exposed offline; any corrupt registry/cache falls back to builtin only.
## refresh() is one bounded transaction (no polling); a failure at any step leaves the
## active registry untouched and reports a diagnostic status.

signal content_changed
signal status_changed(status: String)

const ContentManifestV1 = preload("res://scripts/content_runtime/content_manifest_v1.gd")
const ScrubpackV1 = preload("res://scripts/content_runtime/scrubpack_v1.gd")
const StrictJson = preload("res://scripts/content_runtime/strict_json.gd")
const HttpsContentTransport = preload("res://scripts/content_runtime/https_content_transport.gd")

const CONFIG_PATH := "res://data/config/remote_content_runtime_v1.json"
const CONFIG_SCHEMA := "scrubbots.remote_content_runtime.v1"
const DEFAULT_ROOT := "user://content/"
const REGISTRY_SCHEMA := "scrubbots.content.registry.v1"
const REGISTRY_FILE := "registry_v1.json"
const REGISTRY_PREV := "registry_v1.prev.json"
const REGISTRY_TMP := "registry_v1.json.tmp"
const DEFAULT_MAX_CACHE_BYTES := 512 * 1024 * 1024
const ROLE_FILES := {"level": "level.json", "supply_plan": "supply-plan.json", "metadata": "metadata.json"}

const DISABLED := "disabled"
const IDLE := "idle"
const CHECKING := "checking"
const DOWNLOADING := "downloading"
const VALIDATING := "validating"
const UPDATED := "updated"
const OFFLINE_USING_CACHE := "offline_using_cache"
const FAILED_USING_CACHE := "failed_using_cache"

var root := DEFAULT_ROOT
var transport = null
var enabled := false
var config: Dictionary = {}
## Canonical app version (ProjectSettings application/config/version); tests inject it.
var game_version := ""
## Builtin catalog IDs (for collision checks); Callable() -> Array[String].
var builtin_ids: Callable = Callable()

var _registry: Dictionary = {}   ## structurally valid active registry ({} when none/corrupt)
var _active_ok := false          ## the active set is verified usable right now
var _status := DISABLED
var _reason := ""
var _refreshing := false

func _init(content_root: String = DEFAULT_ROOT, current_game_version = null, builtin_id_provider: Callable = Callable()) -> void:
	root = content_root if content_root.ends_with("/") else content_root + "/"
	game_version = String(ProjectSettings.get_setting("application/config/version", "")) if current_game_version == null else String(current_game_version)
	builtin_ids = builtin_id_provider
	config = load_config()
	enabled = bool(config.get("enabled", false)) and not String(config.get("manifest_url", "")).is_empty()
	_status = IDLE if enabled else DISABLED

## Non-secret runtime config; anything malformed => disabled ({} keeps builtin play).
static func load_config(path: String = CONFIG_PATH) -> Dictionary:
	var j := StrictJson.parse(FileAccess.get_file_as_bytes(path), 65536, 8, 64, 2048)
	var c = j["value"]
	if not j["ok"] or typeof(c) != TYPE_DICTIONARY or c.get("schema") != CONFIG_SCHEMA or c.get("version") != 1:
		return {}
	if typeof(c.get("enabled")) != TYPE_BOOL \
			or c.get("supported_manifest_schema") != ContentManifestV1.SCHEMA or c.get("supported_manifest_schema_version") != ContentManifestV1.SCHEMA_VERSION \
			or c.get("supported_scrubpack_schema") != ScrubpackV1.SCHEMA or c.get("supported_scrubpack_version") != ScrubpackV1.VERSION:
		return {}
	for k in ["manifest_url", "object_base_url"]:
		var u = c.get(k)
		if typeof(u) != TYPE_STRING or (not u.is_empty() and not HttpsContentTransport.is_safe_https_url(u)):
			return {}
	return c

## Production transport from the config (caller adds it to the scene tree). null when disabled.
func make_production_transport():
	if not enabled:
		return null
	return HttpsContentTransport.new(String(config["manifest_url"]), String(config.get("object_base_url", "")), float(config.get("timeout_seconds", 20)))

# ------------------------------------------------------------- status --

func status() -> Dictionary:
	return {"status": _status, "reason": _reason, "content_version": int(_registry.get("content_version", 0)) if _active_ok else 0,
		"remote_level_count": remote_levels().size(), "refreshing": _refreshing}

func _set_status(s: String, reason: String = "") -> void:
	_status = s
	_reason = reason
	status_changed.emit(s)

## Verified remote levels in manifest-declared order (empty unless the active set is usable).
## [{id, pack_id, level_path, supply_plan_path, metadata_path, difficulty, width, height}]
func remote_levels() -> Array:
	if not _active_ok:
		return []
	var out: Array = []
	for l in _registry["levels"]:
		var dir := level_dir(_pack_for(l["pack_id"]), l["level_id"])
		out.append({"id": l["level_id"], "pack_id": l["pack_id"], "level_path": dir + "level.json",
			"supply_plan_path": dir + "supply-plan.json", "metadata_path": dir + "metadata.json",
			"difficulty": l["difficulty"], "width": l["width"], "height": l["height"]})
	return out

func active_registry() -> Dictionary:
	return _registry.duplicate(true)

func is_active_usable() -> bool:
	return _active_ok

# --------------------------------------------------------------- paths --

func install_dir(pack: Dictionary) -> String:
	return root + "packs/%s/%d-%s/" % [pack["pack_id"], pack["pack_version"], pack["sha256"]]

func level_dir(pack: Dictionary, level_id: String) -> String:
	return install_dir(pack) + "levels/%s/" % level_id

func _pack_for(pack_id: String) -> Dictionary:
	for p in _registry.get("packs", []):
		if p["pack_id"] == pack_id:
			return p
	return {}

# ---------------------------------------------------------------- boot --

## Cold boot (no network): clean interrupted transactions, then validate the cached LKG.
func boot() -> void:
	if DirAccess.dir_exists_absolute(root):
		_rm_tree(root + "downloads/")
		_rm_tree(root + "staging/")
		DirAccess.remove_absolute(root + REGISTRY_TMP)
	_load_active()
	if _registry.is_empty() and not FileAccess.file_exists(root + REGISTRY_FILE):
		_prune_packs()   # orphans of an install interrupted before its first activation
	elif not _registry.is_empty():
		_prune_packs()

## Parse + verify the active registry. Sets _registry/_active_ok/_reason.
func _load_active() -> void:
	_registry = {}
	_active_ok = false
	var path := root + REGISTRY_FILE
	if not FileAccess.file_exists(path):
		return
	var reg := parse_registry(FileAccess.get_file_as_bytes(path))
	if reg.is_empty():
		_reason = "REGISTRY_CORRUPT"
		return
	_registry = reg
	var why := _verify_set(reg)
	_active_ok = why.is_empty()
	if not _active_ok:
		_reason = why

## "" when the registry's whole set is usable by THIS game build right now.
func _verify_set(reg: Dictionary) -> String:
	var compat := ContentManifestV1.game_version_compatible(reg["minimum_game_version"], game_version)
	if compat != "COMPATIBLE":
		return "CACHE_" + compat
	var builtin := _builtin_fold()
	var revalidate: bool = reg["validated_game_version"] != game_version   # app update/downgrade
	for l in reg["levels"]:
		if builtin.has(String(l["level_id"]).to_lower()):
			return "CACHE_BUILTIN_ID_COLLISION"
		var pack := {}
		for p in reg["packs"]:
			if p["pack_id"] == l["pack_id"]:
				pack = p
		var dir := root + "packs/%s/%d-%s/levels/%s/" % [pack["pack_id"], pack["pack_version"], pack["sha256"], l["level_id"]]
		var files := {}
		for role in ROLE_FILES:
			var b := FileAccess.get_file_as_bytes(dir + ROLE_FILES[role])
			if b.is_empty() or ContentManifestV1.sha256_hex(b) != l["sha256"][role]:
				return "CACHE_FILE_MISSING_OR_CHANGED"
			files[role] = b
		if revalidate and not ScrubpackV1.validate_level_triplet(l["level_id"], files)["ok"]:
			return "CACHE_INVALID_FOR_GAME_VERSION"
	return ""

func _builtin_fold() -> Dictionary:
	var out := {}
	if builtin_ids.is_valid():
		for id in builtin_ids.call():
			out[String(id).to_lower()] = true
	return out

## Strict registry parse; {} on any defect.
static func parse_registry(raw: PackedByteArray) -> Dictionary:
	var j := StrictJson.parse(raw, 4 * 1_048_576, 8, 65536, 4096)
	var r = j["value"]
	if not j["ok"] or typeof(r) != TYPE_DICTIONARY:
		return {}
	var k: Array = r.keys()
	k.sort()
	if k != ["content_version", "levels", "manifest_sha256", "minimum_game_version", "packs", "schema", "validated_game_version", "version"] \
			or r["schema"] != REGISTRY_SCHEMA or r["version"] != 1 or typeof(r["content_version"]) != TYPE_INT or r["content_version"] < 1 \
			or not ContentManifestV1.full_match("sha256", r["manifest_sha256"]) \
			or ContentManifestV1.parse_game_version(r["minimum_game_version"]).is_empty() \
			or typeof(r["validated_game_version"]) != TYPE_STRING \
			or typeof(r["packs"]) != TYPE_ARRAY or typeof(r["levels"]) != TYPE_ARRAY:
		return {}
	var packs := {}
	for p in r["packs"]:
		if typeof(p) != TYPE_DICTIONARY:
			return {}
		var pk: Array = p.keys()
		pk.sort()
		if pk != ContentManifestV1.PACK_FIELDS or not ContentManifestV1.full_match("pack_id", p["pack_id"]) \
				or typeof(p["pack_version"]) != TYPE_INT or p["pack_version"] < 1 \
				or not ContentManifestV1.full_match("sha256", p["sha256"]) or packs.has(p["pack_id"]):
			return {}
		packs[p["pack_id"]] = true
	var ids := {}
	for l in r["levels"]:
		if typeof(l) != TYPE_DICTIONARY:
			return {}
		var lk: Array = l.keys()
		lk.sort()
		if lk != ["difficulty", "height", "level_id", "pack_id", "sha256", "width"] \
				or not ContentManifestV1.full_match("level_id", l["level_id"]) or not packs.has(l["pack_id"]) \
				or ids.has(String(l["level_id"]).to_lower()) or typeof(l["difficulty"]) != TYPE_STRING \
				or typeof(l["width"]) != TYPE_INT or typeof(l["height"]) != TYPE_INT or typeof(l["sha256"]) != TYPE_DICTIONARY:
			return {}
		var sk: Array = l["sha256"].keys()
		sk.sort()
		if sk != ["level", "metadata", "supply_plan"]:
			return {}
		for role in sk:
			if not ContentManifestV1.full_match("sha256", l["sha256"][role]):
				return {}
		ids[String(l["level_id"]).to_lower()] = true
	return r

# ------------------------------------------------------------- refresh --

## One bounded refresh transaction. Concurrent calls are refused while one runs.
## Returns {ok, reason, changed}.
func refresh() -> Dictionary:
	if _refreshing:
		return {"ok": false, "reason": "REFRESH_IN_PROGRESS", "changed": false}
	if not enabled or transport == null:
		_set_status(DISABLED, "REMOTE_DISABLED")
		return {"ok": false, "reason": "REMOTE_DISABLED", "changed": false}
	_refreshing = true
	_set_status(CHECKING)
	var tx := "%d_%d" % [Time.get_ticks_usec(), randi()]
	var r: Dictionary = await _refresh_tx(tx)
	_rm_tree(root + "staging/%s/" % tx)
	DirAccess.remove_absolute(root + "downloads/%s.part" % tx)
	_refreshing = false
	if r["ok"]:
		_set_status(UPDATED if r["changed"] else IDLE, r["reason"])
		if r["changed"]:
			content_changed.emit()
	else:
		_set_status(OFFLINE_USING_CACHE if String(r["reason"]).begins_with("TRANSPORT_") else FAILED_USING_CACHE, r["reason"])
	return r

func _no(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "changed": false}

func _refresh_tx(tx: String) -> Dictionary:
	if ContentManifestV1.parse_game_version(game_version).is_empty():
		return _no("GAME_VERSION_UNAVAILABLE")
	var f: Dictionary = await transport.fetch_manifest()
	if not f.get("ok", false):
		return _no(String(f.get("reason", "TRANSPORT_FAILED")))
	var raw: PackedByteArray = f.get("bytes", PackedByteArray())
	if raw.size() > int(config.get("max_manifest_bytes", ContentManifestV1.MAX_BYTES)):
		return _no("MANIFEST_TOO_LARGE")
	var pr := ContentManifestV1.parse(raw)
	if not pr["ok"]:
		return _no(pr["reason"])
	var m: Dictionary = pr["manifest"]
	var compat := ContentManifestV1.game_version_compatible(m["minimum_game_version"], game_version)
	if compat != "COMPATIBLE":
		return _no(compat)
	var active_cv := int(_registry.get("content_version", 0))
	if m["content_version"] < active_cv:
		return _no("CONTENT_VERSION_NOT_INCREASED")
	if m["content_version"] == active_cv:
		if pr["sha256"] != _registry["manifest_sha256"]:
			return _no("MANIFEST_MUTATION")
		if _active_ok:
			return {"ok": true, "reason": "UP_TO_DATE", "changed": false}
		# Same manifest, broken local set (partial cache / app update): repair below.
	# CP06 owns disable/schedule semantics; until then they are never silently ignored.
	if not m["disabled_levels"].is_empty() or not m["schedules"].is_empty():
		return _no("UNSUPPORTED_RUNTIME_SEMANTICS")
	# V1 campaign-order policy: no builtin override, and an activated sequence is append-only.
	var builtin := _builtin_fold()
	for l in m["levels"]:
		if builtin.has(String(l["level_id"]).to_lower()):
			return _no("BUILTIN_ID_COLLISION")
	var old: Array = _registry.get("levels", [])
	if old.size() > m["levels"].size():
		return _no("REMOTE_SEQUENCE_NOT_APPEND_ONLY")
	for i in old.size():
		if old[i]["level_id"] != m["levels"][i]["level_id"] or old[i]["pack_id"] != m["levels"][i]["pack_id"]:
			return _no("REMOTE_SEQUENCE_NOT_APPEND_ONLY")

	# CP05-007 cache policy: the installed cache is exactly the active set (older/unreferenced
	# packs are pruned after each verified commit); a candidate set larger than the cap is refused.
	var total := 0
	for p in m["packs"]:
		total += int(p["byte_length"])
	if total > int(config.get("max_cache_bytes", DEFAULT_MAX_CACHE_BYTES)):
		return _no("CACHE_LIMIT_EXCEEDED")
	# Missing-pack diff against the verified active cache (exact 5-field identity).
	var level_records := {}
	var to_install: Array = []
	for p in m["packs"]:
		var reuse := _reusable_levels(p)
		if reuse.is_empty():
			to_install.append(p)
		else:
			for rec in reuse:
				level_records[rec["level_id"]] = rec
	for p in to_install:
		_set_status(DOWNLOADING, p["pack_id"])
		var r: Dictionary = await _download_and_stage(tx, p, m["pack_members"][String(p["pack_id"]).to_lower()])
		if not r["ok"]:
			return r
		for rec in r["levels"]:
			level_records[rec["level_id"]] = rec

	# Candidate registry in manifest-declared level order.
	var levels: Array = []
	for l in m["levels"]:
		var rec: Dictionary = level_records.get(l["level_id"], {})
		if rec.is_empty() or rec["pack_id"] != l["pack_id"]:
			return _no("PACK_MEMBERSHIP_MISMATCH")
		levels.append(rec)
	var packs: Array = []
	for p in m["packs"]:
		packs.append({"pack_id": p["pack_id"], "pack_version": p["pack_version"], "object_key": p["object_key"],
			"sha256": p["sha256"], "byte_length": p["byte_length"]})
	var candidate := {"schema": REGISTRY_SCHEMA, "version": 1, "content_version": m["content_version"],
		"manifest_sha256": pr["sha256"], "minimum_game_version": m["minimum_game_version"],
		"validated_game_version": game_version, "packs": packs, "levels": levels}
	var why := _verify_set(candidate)
	if not why.is_empty():
		return _no("CANDIDATE_" + why)
	return _activate(candidate)

## Level records of an already installed, byte-verified pack with the exact same identity.
func _reusable_levels(p: Dictionary) -> Array:
	var same := false
	for q in _registry.get("packs", []):
		if q == {"pack_id": p["pack_id"], "pack_version": p["pack_version"], "object_key": p["object_key"],
				"sha256": p["sha256"], "byte_length": p["byte_length"]}:
			same = true
	if not same:
		return []
	var out: Array = []
	for l in _registry["levels"]:
		if l["pack_id"] != p["pack_id"]:
			continue
		for role in ROLE_FILES:
			var b := FileAccess.get_file_as_bytes(level_dir(p, l["level_id"]) + ROLE_FILES[role])
			if b.is_empty() or ContentManifestV1.sha256_hex(b) != l["sha256"][role]:
				return []
		out.append(l.duplicate(true))
	return out

func _download_and_stage(tx: String, p: Dictionary, members: Array) -> Dictionary:
	var max_pack := mini(int(config.get("max_pack_bytes", ScrubpackV1.MAX_ARCHIVE_BYTES)), ScrubpackV1.MAX_ARCHIVE_BYTES)
	if p["byte_length"] > max_pack:
		return _no("PACK_TOO_LARGE")
	DirAccess.make_dir_recursive_absolute(root + "downloads/")
	var part := root + "downloads/%s.part" % tx
	DirAccess.remove_absolute(part)
	var d: Dictionary = await transport.fetch_object(p["object_key"], part, int(p["byte_length"]))
	if not d.get("ok", false):
		return _no(String(d.get("reason", "TRANSPORT_FAILED")))
	var fa := FileAccess.open(part, FileAccess.READ)
	if fa == null or fa.get_length() != p["byte_length"]:
		return _no("PACK_BYTE_LENGTH_MISMATCH")
	var raw := fa.get_buffer(fa.get_length())
	fa.close()
	DirAccess.remove_absolute(part)
	_set_status(VALIDATING, p["pack_id"])
	var insp := ScrubpackV1.inspect(raw, p, members)
	if not insp["ok"]:
		return _no(insp["reason"])
	# Materialize only the approved JSON members into staging, then rename into packs/.
	var stage := root + "staging/%s/pack/" % tx
	var records: Array = []
	for lv in insp["levels"]:
		var dir := stage + "levels/%s/" % lv["id"]
		DirAccess.make_dir_recursive_absolute(dir)
		for role in ROLE_FILES:
			var w := FileAccess.open(dir + ROLE_FILES[role], FileAccess.WRITE)
			if w == null:
				return _no("INSTALL_WRITE_FAILED")
			w.store_buffer(lv["files"][role])
			w.close()
		records.append({"level_id": lv["id"], "pack_id": p["pack_id"], "difficulty": lv["difficulty"],
			"width": lv["width"], "height": lv["height"], "sha256": lv["sha256"]})
	var final := install_dir(p)
	_rm_tree(final)   # never referenced by a usable set (identity differs or it failed verification)
	DirAccess.make_dir_recursive_absolute(final.trim_suffix("/").get_base_dir())
	if DirAccess.rename_absolute(stage.trim_suffix("/"), final.trim_suffix("/")) != OK:
		return _no("INSTALL_RENAME_FAILED")
	return {"ok": true, "reason": "OK", "changed": false, "levels": records}

## Commit boundary: the candidate is fully installed + verified; swap the registry pointer.
func _activate(candidate: Dictionary) -> Dictionary:
	var tmp := root + REGISTRY_TMP
	var w := FileAccess.open(tmp, FileAccess.WRITE)
	if w == null:
		return _no("REGISTRY_WRITE_FAILED")
	w.store_string(JSON.stringify(candidate, "\t", true))
	w.close()
	if parse_registry(FileAccess.get_file_as_bytes(tmp)) != candidate:
		DirAccess.remove_absolute(tmp)
		return _no("REGISTRY_WRITE_FAILED")
	var active := root + REGISTRY_FILE
	if FileAccess.file_exists(active):
		DirAccess.copy_absolute(active, root + REGISTRY_PREV)
	if DirAccess.rename_absolute(tmp, active) != OK:
		DirAccess.remove_absolute(tmp)
		return _no("REGISTRY_ACTIVATE_FAILED")
	_load_active()
	if not _active_ok:
		# Should be unreachable (verified before commit); restore the previous LKG pointer.
		if FileAccess.file_exists(root + REGISTRY_PREV):
			DirAccess.copy_absolute(root + REGISTRY_PREV, active)
		_load_active()
		return _no("ACTIVATION_VERIFY_FAILED")
	_prune_packs()
	return {"ok": true, "reason": "ACTIVATED", "changed": true}

# ------------------------------------------------------------ retention --

## Removes installed pack dirs the ACTIVE registry does not reference. Only called once the
## active set is known (after a verified commit, or at boot with a parseable registry /
## no registry at all), so the active LKG is never pruned.
func _prune_packs() -> void:
	var keep := {}
	for p in _registry.get("packs", []):
		keep[install_dir(p)] = true
	var packs_root := root + "packs/"
	if not DirAccess.dir_exists_absolute(packs_root):
		return
	for pid in DirAccess.get_directories_at(packs_root):
		for ver in DirAccess.get_directories_at(packs_root + pid):
			var d := packs_root + "%s/%s/" % [pid, ver]
			if not keep.has(d):
				_rm_tree(d)
		if DirAccess.get_directories_at(packs_root + pid).is_empty():
			DirAccess.remove_absolute(packs_root + pid)

## Recursive delete confined to `root` (no traversal, never outside the content root).
func _rm_tree(dir: String) -> void:
	if not dir.begins_with(root) or dir.contains("..") or dir == root or not DirAccess.dir_exists_absolute(dir):
		return
	var base := dir if dir.ends_with("/") else dir + "/"
	for f in DirAccess.get_files_at(base):
		DirAccess.remove_absolute(base + f)
	for d in DirAccess.get_directories_at(base):
		_rm_tree(base + d + "/")
	DirAccess.remove_absolute(base)
