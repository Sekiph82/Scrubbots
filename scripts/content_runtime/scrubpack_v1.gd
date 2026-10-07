extends RefCounted
## ScrubpackV1 — preload (res://scripts/content_runtime/scrubpack_v1.gd).
##
## Read-only inspector for untrusted `.scrubpack` V1 bytes (CP04-005..008). Mirrors the
## Level Factory contract (LF main 16ee1f3: docs/content_platform/SCRUBPACK_V1_SPEC.md,
## scrubpack_spec.py, scrubpack_tools/inspection.py, payload_validation.py) and then
## re-validates every level with the CURRENT game validators.
##
## The ZIP central directory is parsed here directly (Godot's ZIPReader hides entry
## metadata, so it cannot prove "no symlink / encrypted / executable entry"). V1 is
## STORED-only, so member bytes are exact slices of the verified archive: nothing is
## decompressed, extracted, loaded as a Resource or executed.
##
## inspect(raw, pack_entry, expected_level_ids) -> {ok, reason, levels}
##   pack_entry: manifest pack record {pack_id, pack_version, sha256, byte_length}
##   levels: Array[{id, difficulty, width, height, files: {level, supply_plan, metadata}
##           -> PackedByteArray, sha256: {level, supply_plan, metadata}}] in pack order.

const StrictJson = preload("res://scripts/content_runtime/strict_json.gd")
const ContentManifestV1 = preload("res://scripts/content_runtime/content_manifest_v1.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ProductionLevelValidator = preload("res://scripts/data/production_level_validator.gd")
const DifficultyRules = preload("res://scripts/data/difficulty_rules.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")

const SCHEMA := "scrubbots.scrubpack.manifest.v1"
const VERSION := 1
const MEDIA_TYPE := "application/vnd.scrubbots.scrubpack+zip"
const MAX_ARCHIVE_BYTES := 256 * 1024 * 1024
const MAX_MEMBERS := 4096
const MAX_MEMBER_BYTES := 1_048_576
## LF payload_validation limits.
const PAYLOAD_DEPTH := 32
const PAYLOAD_ITEMS := 65_536
const PAYLOAD_STRING := 8_192

const ROLES := ["levelData", "supplyPlan", "metadata"]
const ROLE_FILE := {"levelData": "level.json", "supplyPlan": "supply-plan.json", "metadata": "metadata.json"}

const LEVEL_FIELDS := ["cells", "difficulty", "height", "id", "name", "palette", "version", "width"]
const SUPPLY_FIELDS := ["columnCount", "columns", "intendedColumnClicks", "levelId", "maxRobotsPerBatch",
	"ownerInput", "ownerInputSha256", "schema", "version", "visiblePreviewDepth"]
const METADATA_REQUIRED := ["builderVersion", "cellCount", "columnCount", "difficulty", "fileDigests", "height", "id",
	"schema", "version", "visiblePreviewDepth", "width"]
const METADATA_OPTIONAL := ["challengeScore", "sourceCandidateId", "sourceArtworkSha256", "sourceGridHash", "sourceLineage",
	"pipelineRunId", "loadCheck", "progression", "challengeVector", "sessionLoad", "dominantProfile", "frustrationRisk",
	"official_difficulty_v1", "noveltySignature"]

static var _re := {}

static func _rx(name: String) -> RegEx:
	if _re.is_empty():
		_re = {
			"member": RegEx.create_from_string("^levels/([A-Za-z0-9][A-Za-z0-9._-]{0,127})/(level|supply-plan|metadata)\\.json$"),
			"created": RegEx.create_from_string("^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:Z|[+-]\\d{2}:\\d{2})$"),
			"cid": RegEx.create_from_string("^C(?:0[1-9]|1[0-6])$"),
			"exec_key": RegEx.create_from_string("(?i)(?:script|expression|bytecode|plugin|addon|autoload|native.?code|module.?path|shader|resource|command|process|network|file.?operation|eval|exec)"),
			"exec_value": RegEx.create_from_string("(?i)(?:\\b(?:eval|exec|compile|__import__|load|preload)\\s*\\(|(?:res|user)://|\\$\\{|\\{\\{.*\\}\\}|\\.(?:gd|py|pyc|cs|js|exe|dll|so|dylib|pyd|wasm|jar|class|tscn|tres|res|scn|shader|gdshader)\\b)"),
		}
	return _re[name]

static func _full(name: String, v) -> bool:
	if typeof(v) != TYPE_STRING:
		return false
	var m := _rx(name).search(v)
	return m != null and m.get_start() == 0 and m.get_end() == String(v).length()

static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "levels": []}

static func _u16(b: PackedByteArray, o: int) -> int:
	return b.decode_u16(o)

static func _u32(b: PackedByteArray, o: int) -> int:
	return b.decode_u32(o)

# ----------------------------------------------------------------- ZIP --

## Safe central-directory walk. Returns {ok, reason, names: Array[String], data: {name: PackedByteArray}}.
static func read_zip(raw: PackedByteArray) -> Dictionary:
	var fail := func(r: String) -> Dictionary: return {"ok": false, "reason": r, "names": [], "data": {}}
	var n := raw.size()
	if n > MAX_ARCHIVE_BYTES:
		return fail.call("PACK_TOO_LARGE")
	# EOCD must close the archive exactly: no archive comment, no trailing bytes (canonical builder).
	if n < 22 or _u32(raw, n - 22) != 0x06054b50:
		return fail.call("INVALID_ZIP")
	var eo := n - 22
	var entries := _u16(raw, eo + 10)
	var cd_size := _u32(raw, eo + 12)
	var cd_off := _u32(raw, eo + 16)
	if _u16(raw, eo + 4) != 0 or _u16(raw, eo + 6) != 0 or _u16(raw, eo + 8) != entries or _u16(raw, eo + 20) != 0:
		return fail.call("INVALID_ZIP")   # multi-disk / count mismatch / comment
	if entries == 0xFFFF or cd_size == 0xFFFFFFFF or cd_off == 0xFFFFFFFF:
		return fail.call("UNSUPPORTED_ZIP_METADATA")   # ZIP64 is not part of V1
	if entries == 0 or entries > MAX_MEMBERS:
		return fail.call("INVALID_MEMBER_LAYOUT")
	if cd_off + cd_size != eo:
		return fail.call("INVALID_ZIP")
	var names: Array = []
	var spans: Array = []
	var p := cd_off
	for _k in entries:
		if p + 46 > eo or _u32(raw, p) != 0x02014b50:
			return fail.call("INVALID_ZIP")
		var made_by := _u16(raw, p + 4)
		var flags := _u16(raw, p + 8)
		var method := _u16(raw, p + 10)
		var csize := _u32(raw, p + 20)
		var usize := _u32(raw, p + 24)
		var nlen := _u16(raw, p + 28)
		var xlen := _u16(raw, p + 30)
		var clen := _u16(raw, p + 32)
		var disk := _u16(raw, p + 34)
		var eattr := _u32(raw, p + 38)
		var loff := _u32(raw, p + 42)
		if p + 46 + nlen + xlen + clen > eo:
			return fail.call("INVALID_ZIP")
		var name_b := raw.slice(p + 46, p + 46 + nlen)
		for c in name_b:
			if c >= 0x80:
				return fail.call("INVALID_MEMBER_LAYOUT")
		var name := name_b.get_string_from_ascii()
		# LF _zip_entry_is_safe: regular, non-executable, unencrypted, STORED, bounded.
		var create_system := made_by >> 8
		var mode := (eattr >> 16) & 0xFFFF
		var kind := mode & 0xF000
		if flags & 0x1 or flags & 0x40 or method != 0 or csize != usize or usize > MAX_MEMBER_BYTES or disk != 0:
			return fail.call("UNSUPPORTED_ZIP_METADATA")
		if not (create_system in [0, 3]) or not (kind in [0, 0x8000]) or mode & 0x49:
			return fail.call("UNSUPPORTED_ZIP_METADATA")
		if create_system == 0 and (eattr & 0xFFFF) & (0x10 | 0x400):
			return fail.call("UNSUPPORTED_ZIP_METADATA")   # DOS directory / reparse point
		# Local header must agree with the central record (no shadow names / methods).
		if loff + 30 > cd_off or _u32(raw, loff) != 0x04034b50:
			return fail.call("INVALID_ZIP")
		var lflags := _u16(raw, loff + 6)
		var lnlen := _u16(raw, loff + 26)
		var lxlen := _u16(raw, loff + 28)
		if lflags & 0x1 or _u16(raw, loff + 8) != 0 or lnlen != nlen \
				or raw.slice(loff + 30, loff + 30 + lnlen) != name_b:
			return fail.call("INVALID_ZIP")
		var start := loff + 30 + lnlen + lxlen
		if start + usize > cd_off:
			return fail.call("INVALID_ZIP")
		names.append(name)
		spans.append([loff, start + usize, name, start])
		p += 46 + nlen + xlen + clen
	if p != eo:
		return fail.call("INVALID_ZIP")
	# Members may not overlap (one byte range per name).
	var by_off := spans.duplicate()
	by_off.sort_custom(func(a, b): return a[0] < b[0])
	for k in range(1, by_off.size()):
		if by_off[k][0] < by_off[k - 1][1]:
			return fail.call("INVALID_ZIP")
	var data := {}
	for s in spans:
		if data.has(s[2]):
			return fail.call("INVALID_MEMBER_LAYOUT")   # duplicate member name
		data[s[2]] = raw.slice(s[3], s[1])
	return {"ok": true, "reason": "OK", "names": names, "data": data}

static func valid_member_names(names: Array) -> bool:
	var seen := {}
	for nm in names:
		if not (nm == "pack.json" or _full("member", nm)):
			return false
		var f := String(nm).to_lower()
		if seen.has(f):
			return false
		seen[f] = true
	return true

# ------------------------------------------------------------- inspect --

static func inspect(raw: PackedByteArray, pack_entry: Dictionary, expected_level_ids: Array) -> Dictionary:
	if raw.size() != int(pack_entry.get("byte_length", -1)):
		return _fail("PACK_BYTE_LENGTH_MISMATCH")
	if ContentManifestV1.sha256_hex(raw) != String(pack_entry.get("sha256", "")):
		return _fail("PACK_SHA256_MISMATCH")
	var z := read_zip(raw)
	if not z["ok"]:
		return _fail(z["reason"])
	var names: Array = z["names"]
	if not valid_member_names(names):
		return _fail("INVALID_MEMBER_LAYOUT")
	if names[0] != "pack.json":
		return _fail("INVALID_MEMBER_LAYOUT")
	var pj := StrictJson.parse(z["data"]["pack.json"], MAX_MEMBER_BYTES, PAYLOAD_DEPTH, PAYLOAD_ITEMS, PAYLOAD_STRING)
	if not pj["ok"]:
		return _fail("INVALID_MANIFEST")
	var m = pj["value"]
	if typeof(m) != TYPE_DICTIONARY or not m.has("schema") or not m.has("version") \
			or typeof(m["schema"]) != TYPE_STRING or typeof(m["version"]) != TYPE_INT or m["version"] <= 0:
		return _fail("INVALID_MANIFEST")
	if m["schema"] != SCHEMA or m["version"] != VERSION:
		return _fail("UNSUPPORTED_VERSION")
	var mk: Array = m.keys()
	mk.sort()
	if mk != ["createdAtUtc", "levelCount", "levels", "mediaType", "packId", "packVersion", "schema", "version"] \
			or m["mediaType"] != MEDIA_TYPE or not ContentManifestV1.full_match("pack_id", m["packId"]) \
			or typeof(m["packVersion"]) != TYPE_INT or m["packVersion"] < 1 or not _full("created", m["createdAtUtc"]) \
			or typeof(m["levels"]) != TYPE_ARRAY or typeof(m["levelCount"]) != TYPE_INT \
			or m["levelCount"] != m["levels"].size() or m["levels"].is_empty():
		return _fail("INVALID_MANIFEST")
	if m["packId"] != pack_entry.get("pack_id") or m["packVersion"] != pack_entry.get("pack_version"):
		return _fail("PACK_IDENTITY_MISMATCH")
	var expected_names := ["pack.json"]
	var digests := {}
	var ids: Array = []
	var fold := {}
	for lv in m["levels"]:
		if typeof(lv) != TYPE_DICTIONARY:
			return _fail("INVALID_MANIFEST")
		var lk: Array = lv.keys()
		lk.sort()
		if lk != ["files", "id", "sha256"] or not ContentManifestV1.full_match("level_id", lv["id"]) \
				or typeof(lv["files"]) != TYPE_DICTIONARY or typeof(lv["sha256"]) != TYPE_DICTIONARY:
			return _fail("INVALID_MANIFEST")
		var id: String = lv["id"]
		if fold.has(id.to_lower()):
			return _fail("INVALID_MANIFEST")
		fold[id.to_lower()] = true
		var fk: Array = lv["files"].keys()
		fk.sort()
		var sk: Array = lv["sha256"].keys()
		sk.sort()
		if fk != ["levelData", "metadata", "supplyPlan"] or sk != fk:
			return _fail("INVALID_MANIFEST")
		for role in ROLES:
			var path := "levels/%s/%s" % [id, ROLE_FILE[role]]
			if lv["files"][role] != path or not ContentManifestV1.full_match("sha256", lv["sha256"][role]):
				return _fail("INVALID_MANIFEST")
			expected_names.append(path)
			digests[path] = lv["sha256"][role]
		ids.append(id)
	var sorted_ids := ids.duplicate()
	sorted_ids.sort()   # String < is code-point order == LF ASCII byte order for these IDs
	if ids != sorted_ids:
		return _fail("INVALID_MANIFEST")
	if names != expected_names:
		return _fail("INVALID_MEMBER_LAYOUT")
	var want := expected_level_ids.duplicate()
	want.sort()
	if sorted_ids != want:
		return _fail("PACK_MEMBERSHIP_MISMATCH")
	for path in digests:
		if ContentManifestV1.sha256_hex(z["data"][path]) != digests[path]:
			return _fail("MEMBER_DIGEST_MISMATCH")
	var out: Array = []
	for id in ids:
		var files := {
			"level": z["data"]["levels/%s/level.json" % id],
			"supply_plan": z["data"]["levels/%s/supply-plan.json" % id],
			"metadata": z["data"]["levels/%s/metadata.json" % id],
		}
		var v := validate_level_triplet(id, files)
		if not v["ok"]:
			return _fail(v["reason"])
		var shas := {}
		for k in files:
			shas[k] = ContentManifestV1.sha256_hex(files[k])
		out.append({"id": id, "difficulty": v["difficulty"], "width": v["width"], "height": v["height"],
			"files": files, "sha256": shas})
	return {"ok": true, "reason": "OK", "levels": out}

# ------------------------------------------------------------ payloads --

static func _parse_member(b: PackedByteArray) -> Dictionary:
	var r := StrictJson.parse(b, MAX_MEMBER_BYTES, PAYLOAD_DEPTH, PAYLOAD_ITEMS, PAYLOAD_STRING)
	if not r["ok"]:
		return r
	if typeof(r["value"]) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "WRONG_TOP_LEVEL_TYPE"}
	if has_executable_surface(r["value"]):
		return {"ok": false, "reason": "EXECUTABLE_CONTENT"}
	return r

## LF _contains_executable_surface: executable-looking keys or values anywhere in the tree.
static func has_executable_surface(v) -> bool:
	if typeof(v) == TYPE_DICTIONARY:
		for k in v:
			if _rx("exec_key").search(String(k)) != null or has_executable_surface(v[k]):
				return true
		return false
	if typeof(v) == TYPE_ARRAY:
		for x in v:
			if has_executable_surface(x):
				return true
		return false
	return typeof(v) == TYPE_STRING and _rx("exec_value").search(v) != null

static func _keys_ok(d: Dictionary, required: Array, optional: Array = []) -> bool:
	for k in required:
		if not d.has(k):
			return false
	for k in d:
		if not (k in required or k in optional):
			return false
	return true

static func _int(v) -> bool:
	return typeof(v) == TYPE_INT

static func _str(v) -> bool:
	return typeof(v) == TYPE_STRING and not String(v).is_empty()

## Validates one level's three members: LF payload contracts + cross-file identity +
## the current game's LevelValidator / ProductionLevelValidator / square-shell gate /
## SupplyPlanLoader conservation. Returns {ok, reason, difficulty, width, height}.
static func validate_level_triplet(id: String, files: Dictionary) -> Dictionary:
	var fail := func(r: String) -> Dictionary: return {"ok": false, "reason": r}
	var lr := _parse_member(files["level"])
	if not lr["ok"]:
		return fail.call("LEVEL_" + lr["reason"])
	var lv: Dictionary = lr["value"]
	if not _keys_ok(lv, LEVEL_FIELDS):
		return fail.call("LEVEL_UNKNOWN_OR_MISSING_FIELD")
	var w = lv["width"]
	var h = lv["height"]
	var pal = lv["palette"]
	var cells = lv["cells"]
	if not (_int(lv["version"]) and lv["version"] == 1 and _str(lv["id"]) and _str(lv["name"]) and _str(lv["difficulty"])
			and _int(w) and w >= 20 and w <= 59 and _int(h) and h >= 20 and h <= 59
			and typeof(pal) == TYPE_ARRAY and pal.size() >= 1 and pal.size() <= 256
			and typeof(cells) == TYPE_ARRAY and cells.size() == w * h):
		return fail.call("LEVEL_INVALID_PAYLOAD")
	var seen := {}
	for c in pal:
		if not _str(c) or seen.has(c):
			return fail.call("LEVEL_INVALID_PAYLOAD")
		seen[c] = true
	for c in cells:
		if not _int(c) or c < 0 or c >= pal.size():
			return fail.call("LEVEL_INVALID_PAYLOAD")
	if lv["id"] != id:
		return fail.call("LEVEL_IDENTITY_MISMATCH")
	# Current game authority: the exact loader the gameplay host will run later.
	var ld = LevelLoader.load_from_text(files["level"].get_string_from_utf8(), "remote:" + id)
	if not ld.is_ok():
		return fail.call("LEVEL_DATA_INVALID")
	var level = ld.level_data
	if level.difficulty == DifficultyRules.TEST_DIFFICULTY or not ProductionLevelValidator.validate(level).is_ok():
		return fail.call("LEVEL_NOT_PRODUCTION")
	if not LevelCatalog.square_shell_error(level.width, level.height).is_empty():
		return fail.call("LEVEL_NOT_PRODUCTION")

	var sr := _parse_member(files["supply_plan"])
	if not sr["ok"]:
		return fail.call("SUPPLY_" + sr["reason"])
	var sp: Dictionary = sr["value"]
	if not _keys_ok(sp, SUPPLY_FIELDS):
		return fail.call("SUPPLY_UNKNOWN_OR_MISSING_FIELD")
	var cc = sp["columnCount"]
	if not (sp["schema"] == SupplyPlanLoader.SCHEMA and _int(sp["version"]) and sp["version"] == 1 and _str(sp["levelId"])
			and _str(sp["ownerInput"]) and ContentManifestV1.full_match("sha256", sp["ownerInputSha256"])
			and _int(cc) and cc in [3, 4, 5] and _int(sp["visiblePreviewDepth"]) and sp["visiblePreviewDepth"] == 3
			and _int(sp["maxRobotsPerBatch"]) and sp["maxRobotsPerBatch"] > 0
			and typeof(sp["intendedColumnClicks"]) == TYPE_ARRAY and typeof(sp["columns"]) == TYPE_ARRAY and sp["columns"].size() == cc):
		return fail.call("SUPPLY_INVALID_PAYLOAD")
	for click in sp["intendedColumnClicks"]:
		if not _int(click):
			return fail.call("SUPPLY_INVALID_PAYLOAD")
	var batch_ids := {}
	for col in sp["columns"]:
		if typeof(col) != TYPE_ARRAY or col.is_empty():
			return fail.call("SUPPLY_INVALID_PAYLOAD")
		for bt in col:
			if typeof(bt) != TYPE_DICTIONARY or not _keys_ok(bt, ["batchId", "cid", "robots"]) or not _str(bt["batchId"]) \
					or batch_ids.has(bt["batchId"]) or not _full("cid", bt["cid"]) or not _int(bt["robots"]) \
					or bt["robots"] < 1 or bt["robots"] > sp["maxRobotsPerBatch"]:
				return fail.call("SUPPLY_INVALID_PAYLOAD")
			batch_ids[bt["batchId"]] = true
	if sp["levelId"] != id:
		return fail.call("SUPPLY_IDENTITY_MISMATCH")
	# Same parse path as the runtime's SupplyPlanLoader.load_plan (Godot JSON), then the exact engine build.
	var godot_plan = JSON.parse_string(files["supply_plan"].get_string_from_utf8())
	if typeof(godot_plan) != TYPE_DICTIONARY:
		return fail.call("SUPPLY_PLAN_INVALID")
	var eng := SupplyPlanLoader.build_engine(godot_plan, level)
	if not eng["ok"]:
		return fail.call("SUPPLY_PLAN_INVALID")

	var mr := _parse_member(files["metadata"])
	if not mr["ok"]:
		return fail.call("METADATA_" + mr["reason"])
	var md: Dictionary = mr["value"]
	if not _keys_ok(md, METADATA_REQUIRED, METADATA_OPTIONAL):
		return fail.call("METADATA_UNKNOWN_OR_MISSING_FIELD")
	if not (md["schema"] == "scrubbots.level.metadata.v1" and _int(md["version"]) and md["version"] == 1
			and _str(md["builderVersion"]) and _str(md["id"]) and _int(md["width"]) and md["width"] >= 1 and md["width"] <= 256
			and _int(md["height"]) and md["height"] >= 1 and md["height"] <= 256 and _int(md["cellCount"])
			and md["cellCount"] == md["width"] * md["height"] and typeof(md["difficulty"]) == TYPE_STRING
			and _int(md["columnCount"]) and md["columnCount"] in [3, 4, 5] and _int(md["visiblePreviewDepth"])
			and md["visiblePreviewDepth"] == 3 and typeof(md["fileDigests"]) == TYPE_DICTIONARY):
		return fail.call("METADATA_INVALID_PAYLOAD")
	if md["id"] != id or md["width"] != w or md["height"] != h or md["columnCount"] != cc:
		return fail.call("METADATA_IDENTITY_MISMATCH")
	return {"ok": true, "reason": "OK", "difficulty": String(level.difficulty), "width": int(level.width), "height": int(level.height)}
