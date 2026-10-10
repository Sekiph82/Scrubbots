extends RefCounted
## ContentManifestV1 — preload (res://scripts/content_runtime/content_manifest_v1.gd).
##
## Game-side mirror of the closed Level Factory contract `scrubbots.content.manifest.v1`
## (LF main 16ee1f3: content_pipeline/.../manifest_parser.py + manifest_v1.py +
## manifest_validation.py reference checks). Pure functions over explicit inputs; no
## network, clock or filesystem. parse() returns
##   {ok, reason, manifest, sha256}
## where manifest = {content_version, minimum_game_version, disabled_levels, schedules,
## packs: Array[{pack_id, pack_version, object_key, sha256, byte_length}] (declared order),
## levels: Array[{level_id, pack_id}] (DECLARED order — never re-sorted)}.

const StrictJson = preload("res://scripts/content_runtime/strict_json.gd")

const SCHEMA := "scrubbots.content.manifest.v1"
const SCHEMA_VERSION := 1
const MAX_BYTES := 1_048_576
const MAX_DEPTH := 32
const MAX_ITEMS := 4_096
const MAX_STRING := 16_384

const ROOT_FIELDS := ["content_version", "disabled_levels", "levels", "minimum_game_version", "packs", "schedules", "schema", "schema_version"]
const PACK_FIELDS := ["byte_length", "object_key", "pack_id", "pack_version", "sha256"]
const LEVEL_FIELDS := ["level_id", "pack_id"]

static var _re := {}

static func _rx(name: String) -> RegEx:
	if _re.is_empty():
		_re = {
			"pack_id": RegEx.create_from_string("^[a-z0-9][a-z0-9._-]{0,63}$"),
			"level_id": RegEx.create_from_string("^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$"),
			"game_version": RegEx.create_from_string("^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)$"),
			"object_key": RegEx.create_from_string("^packs/[a-z0-9][a-z0-9_-]{0,63}/[a-z0-9][a-z0-9._-]*(?:/[a-z0-9][a-z0-9._-]*)*\\.scrubpack$"),
			"sha256": RegEx.create_from_string("^[0-9a-f]{64}$"),
			"utc": RegEx.create_from_string("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"),
		}
	return _re[name]

## Python re.fullmatch semantics (PCRE `$` would also accept a trailing "\n").
static func full_match(name: String, v) -> bool:
	if typeof(v) != TYPE_STRING:
		return false
	var m := _rx(name).search(v)
	return m != null and m.get_start() == 0 and m.get_end() == String(v).length()

static func _declares_exact(levels: Array, level_id: String) -> bool:
	for l in levels:
		if l["level_id"] == level_id:
			return true
	return false

static func _keys_exact(d: Dictionary, keys: Array) -> bool:
	var k := d.keys()
	k.sort()
	return k == keys

static func _pos_int(v) -> bool:
	return typeof(v) == TYPE_INT and v >= 1

static func sha256_hex(b: PackedByteArray) -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(b)
	return h.finish().hex_encode()

static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "manifest": {}, "sha256": ""}

static func parse(raw: PackedByteArray) -> Dictionary:
	var j := StrictJson.parse(raw, MAX_BYTES, MAX_DEPTH, MAX_ITEMS, MAX_STRING)
	if not j["ok"]:
		return _fail("MANIFEST_" + String(j["reason"]))
	var v = j["value"]
	if typeof(v) != TYPE_DICTIONARY:
		return _fail("MANIFEST_ROOT_NOT_OBJECT")
	if not _keys_exact(v, ROOT_FIELDS):
		return _fail("MANIFEST_INVALID_ROOT_FIELDS")
	if v["schema"] != SCHEMA:
		return _fail("MANIFEST_UNSUPPORTED_SCHEMA")
	if typeof(v["schema_version"]) != TYPE_INT or v["schema_version"] != SCHEMA_VERSION:
		return _fail("MANIFEST_UNSUPPORTED_SCHEMA_VERSION")
	if not _pos_int(v["content_version"]):
		return _fail("MANIFEST_INVALID_CONTENT_VERSION")
	if not full_match("game_version", v["minimum_game_version"]):
		return _fail("MANIFEST_INVALID_MINIMUM_GAME_VERSION")
	for k in ["packs", "levels", "disabled_levels", "schedules"]:
		if typeof(v[k]) != TYPE_ARRAY:
			return _fail("MANIFEST_INVALID_MANIFEST")
	var packs: Array = []
	var pack_fold := {}
	var keys := {}
	for p in v["packs"]:
		if typeof(p) != TYPE_DICTIONARY or not _keys_exact(p, PACK_FIELDS):
			return _fail("MANIFEST_INVALID_PACK_FIELDS")
		if not full_match("pack_id", p["pack_id"]) or not _pos_int(p["pack_version"]) \
				or not full_match("object_key", p["object_key"]) or not full_match("sha256", p["sha256"]) \
				or not _pos_int(p["byte_length"]):
			return _fail("MANIFEST_INVALID_PACK")
		var f := String(p["pack_id"]).to_lower()
		if pack_fold.has(f):
			return _fail("MANIFEST_DUPLICATE_PACK_ID")
		if keys.has(p["object_key"]):
			return _fail("MANIFEST_DUPLICATE_OBJECT_KEY")
		pack_fold[f] = true
		keys[p["object_key"]] = true
		packs.append(p.duplicate())
	var levels: Array = []
	var level_fold := {}
	var members := {}
	for l in v["levels"]:
		if typeof(l) != TYPE_DICTIONARY or not _keys_exact(l, LEVEL_FIELDS):
			return _fail("MANIFEST_INVALID_LEVEL_FIELDS")
		if not full_match("level_id", l["level_id"]) or not full_match("pack_id", l["pack_id"]):
			return _fail("MANIFEST_INVALID_LEVEL")
		var lf := String(l["level_id"]).to_lower()
		if level_fold.has(lf):
			return _fail("MANIFEST_DUPLICATE_LEVEL_ID")
		level_fold[lf] = true
		var pf := String(l["pack_id"]).to_lower()
		if not pack_fold.has(pf):
			return _fail("MANIFEST_LEVEL_PACK_NOT_DECLARED")
		if not members.has(pf):
			members[pf] = []
		members[pf].append(l["level_id"])
		levels.append(l.duplicate())
	for pf in pack_fold:
		if not members.has(pf):
			return _fail("MANIFEST_PACK_WITHOUT_LEVELS")   # LF: pack membership must equal its levels (>= 1)
	var disabled_fold := {}
	for d in v["disabled_levels"]:
		if not full_match("level_id", d) or disabled_fold.has(String(d).to_lower()):
			return _fail("MANIFEST_INVALID_DISABLED_LEVELS")
		# CP06: a disabled ID must be the EXACT declared spelling of one of this manifest's
		# levels (the LF publisher writes the declared spelling); unknown / case-variant fails closed.
		if not _declares_exact(levels, d):
			return _fail("MANIFEST_DISABLED_LEVEL_NOT_DECLARED")
		disabled_fold[String(d).to_lower()] = true
	var sched_targets := {}
	for sc in v["schedules"]:
		if typeof(sc) != TYPE_DICTIONARY:
			return _fail("MANIFEST_INVALID_SCHEDULES")
		var sk: Array = sc.keys()
		sk.sort()
		if sk != ["not_before", "target_id", "target_kind"] and sk != ["not_after", "not_before", "target_id", "target_kind"]:
			return _fail("MANIFEST_INVALID_SCHEDULES")
		if not (sc["target_kind"] in ["pack", "level"]) or not full_match("pack_id" if sc["target_kind"] == "pack" else "level_id", sc["target_id"]) \
				or not full_match("utc", sc["not_before"]) or (sc.get("not_after") != null and not full_match("utc", sc["not_after"])):
			return _fail("MANIFEST_INVALID_SCHEDULES")
		var t := "%s:%s" % [sc["target_kind"], String(sc["target_id"]).to_lower()]
		if sched_targets.has(t):
			return _fail("MANIFEST_INVALID_SCHEDULES")
		sched_targets[t] = true
	# ponytail: schedule window calendar validity / not_after > not_before is not re-checked here;
	# any non-empty schedules array is refused by the runtime until CP06 owns scheduling.
	var m := {"content_version": v["content_version"], "minimum_game_version": v["minimum_game_version"],
		"disabled_levels": v["disabled_levels"].duplicate(), "schedules": v["schedules"].duplicate(true),
		"packs": packs, "levels": levels, "pack_members": members}
	return {"ok": true, "reason": "OK", "manifest": m, "sha256": sha256_hex(raw)}

## Strict MAJOR.MINOR.PATCH -> [a, b, c]; [] when malformed.
static func parse_game_version(v) -> Array:
	if not full_match("game_version", v):
		return []
	var parts := String(v).split(".")
	for p in parts:
		if p.length() > 9:
			return []   # keeps the triplet inside int range; still a strict canonical grammar
	return [parts[0].to_int(), parts[1].to_int(), parts[2].to_int()]

## LF check_game_version_compatibility: equal/newer current is compatible.
static func game_version_compatible(minimum: String, current: String) -> String:
	var mn := parse_game_version(minimum)
	if mn.is_empty():
		return "INVALID_MINIMUM_GAME_VERSION"
	var cur := parse_game_version(current)
	if cur.is_empty():
		return "INVALID_CURRENT_GAME_VERSION"
	for k in 3:
		if cur[k] != mn[k]:
			return "COMPATIBLE" if cur[k] > mn[k] else "GAME_VERSION_TOO_OLD"
	return "COMPATIBLE"
