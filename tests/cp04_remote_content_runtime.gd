extends SceneTree
## CP04/M15 — remote content runtime: manifest fetch/validation, pack download/integrity,
## Scrubpack V1 payload safety, V1 campaign order and the gameplay catalog bridge.
## Deterministic: injected FakeTransport + locally built canonical packs (no network).
## Every test root lives under user://cp04_* and is removed at the end.
##
## Run: godot --headless --path . -s res://tests/cp04_remote_content_runtime.gd

const F = preload("res://tests/support/scrubpack_fixture.gd")
const StrictJson = preload("res://scripts/content_runtime/strict_json.gd")
const ContentManifestV1 = preload("res://scripts/content_runtime/content_manifest_v1.gd")
const ScrubpackV1 = preload("res://scripts/content_runtime/scrubpack_v1.gd")
const RCM = preload("res://scripts/content_runtime/remote_content_manager.gd")
const Https = preload("res://scripts/content_runtime/https_content_transport.gd")
const Composite = preload("res://scripts/content_runtime/composite_level_catalog.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")

var EXPECTED := ["c01_https_only", "c02_manifest_valid_declared_order", "c03_duplicate_keys", "c04_unknown_fields",
	"c05_nonfinite_and_limits", "c06_schema_version", "c07_game_version_gate", "c08_monotonic_and_mutation",
	"c09_missing_pack_diff", "c10_byte_length", "c11_pack_sha", "c12_zip_member_contract", "c13_member_sha",
	"c14_pack_schema", "c15_executable_json", "c16_level_data", "c17_production_validator", "c18_supply_plan",
	"c19_identity_binding", "c20_builtin_collision", "c21_declared_order_no_numeric_sort", "c22_append_only_successor",
	"c23_reorder_removal_rejected", "c24_disabled_schedules_retain_lkg", "c25_resolver_builtin_then_remote",
	"c26_missing_remote_frontier", "c27_orders_context_composite", "c28_install_never_mutates_save"]

var _fail := 0
var _done := {}
var _roots: Array = []
var _builtin_ids: Array = []
var _builtin_max := 0

func _initialize() -> void:
	await process_frame
	var cat := LevelCatalog.new()
	cat.load_manifest()
	for e in cat.get_entries_ordered():
		_builtin_ids.append(e.id)
		_builtin_max = maxi(_builtin_max, e.order)
	await _c01(); _c02(); _c03(); _c04(); _c05(); _c06()
	await _c07(); await _c08(); await _c09(); await _c10(); await _c11()
	_c12(); _c13(); _c14(); _c15(); _c16(); _c17(); _c18(); _c19()
	await _c20(); await _c21(); await _c22(); await _c23(); await _c24()
	await _c25(); await _c26(); await _c27(); await _c28()
	for r in _roots:
		_rm(r)
	var missing := EXPECTED.filter(func(c): return not _done.has(c))
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: cases not completed: %s" % str(missing))
	print("CP04 remote content runtime evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _done.size(), EXPECTED.size(), _fail])
	quit(0 if _fail == 0 else 1)

# --------------------------------------------------------------- helpers --

func _ok(c: bool, msg: String) -> void:
	if c:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _case(id: String) -> void:
	_done[id] = true

func _root(tag: String) -> String:
	var r := "user://cp04_%s_%d/" % [tag, Time.get_ticks_usec()]
	_roots.append(r)
	return r

func _empty(dir: String) -> bool:
	return not DirAccess.dir_exists_absolute(dir) or (DirAccess.get_files_at(dir).is_empty() and DirAccess.get_directories_at(dir).is_empty())

func _rm(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + f)
	for d in DirAccess.get_directories_at(dir):
		_rm(dir + d + "/")
	DirAccess.remove_absolute(dir)

func _mgr(root: String, t, version := "1.0.0") -> RCM:
	var m := RCM.new(root, version, func(): return _builtin_ids)
	m.enabled = true
	m.transport = t
	m.boot()
	return m

## {id: builtin source} -> {id: files}
func _levels(spec: Dictionary) -> Dictionary:
	var out := {}
	for id in spec:
		out[id] = F.level_files(id, spec[id])
	return out

func _pack(pack_id: String, ver: int, spec: Dictionary) -> Dictionary:
	return {"pack_id": pack_id, "pack_version": ver, "bytes": F.build_pack(pack_id, ver, _levels(spec))}

func _bytes(v) -> PackedByteArray:
	return (v if typeof(v) == TYPE_STRING else JSON.stringify(v)).to_utf8_buffer()

func _parse_reason(v) -> String:
	return String(ContentManifestV1.parse(_bytes(v))["reason"])

func _base_manifest() -> Dictionary:
	var p := _pack("fam-a", 1, {"fam_l011": "level_002_apple"})
	return F.manifest(1, [p], [["fam_l011", "fam-a"]])

## Inspect a forged archive against a manifest entry that matches ITS bytes, so only the
## archive contract (not the whole-pack hash) decides.
func _inspect(b: PackedByteArray, ids: Array, pack_id := "fam-a", ver := 1) -> String:
	var entry := {"pack_id": pack_id, "pack_version": ver, "sha256": ContentManifestV1.sha256_hex(b), "byte_length": b.size()}
	return String(ScrubpackV1.inspect(b, entry, ids)["reason"])

func _activate(root: String, packs: Array, levels: Array, cv := 1) -> Array:
	var t := F.FakeTransport.new()
	t.set_manifest(F.manifest(cv, packs, levels), packs)
	var m := _mgr(root, t)
	var r: Dictionary = await m.refresh()
	return [m, t, r]

# ----------------------------------------------------------------- cases --

func _c01() -> void:
	print("[c01 HTTPS-only transport/config; no credentials; redirects never followed]")
	for u in ["http://cdn.example/m.json", "ftp://x/y", "https://", "https://user:pw@cdn.example/m.json",
			"https://cdn.example/m.json?token=1", "https://cdn.example/a b", "HTTPS://cdn.example/m"]:
		_ok(not Https.is_safe_https_url(u), "rejected url %s" % u)
	_ok(Https.is_safe_https_url("https://cdn.example/content/manifest.json"), "plain https url accepted")
	var t := Https.new("http://cdn.example/m.json", "https://cdn.example")
	var r: Dictionary = await t.fetch_manifest()   # rejected before any HTTPRequest exists
	_ok(not r["ok"] and r["reason"] == "TRANSPORT_URL_REJECTED", "transport refuses plain HTTP manifest")
	t.free()
	var src := FileAccess.get_file_as_string("res://scripts/content_runtime/https_content_transport.gd")
	_ok(src.contains("req.max_redirects = 0") and not src.contains("Authorization") and not src.contains("set_tls"), "no redirect following, no auth header, default certificate-validating TLS")
	var cfg := RCM.load_config()
	_ok(cfg.get("enabled") == false and cfg.get("manifest_url") == "", "shipped config: endpoint unconfigured -> remote disabled")
	var m := RCM.new(_root("c01"), "1.0.0")
	_ok(not m.enabled and m.make_production_transport() == null and m.status()["status"] == RCM.DISABLED, "unconfigured endpoint: no transport, status disabled")
	var bad := {"schema": RCM.CONFIG_SCHEMA, "version": 1, "enabled": true, "manifest_url": "http://x/m.json", "object_base_url": "",
		"supported_manifest_schema": ContentManifestV1.SCHEMA, "supported_manifest_schema_version": 1,
		"supported_scrubpack_schema": ScrubpackV1.SCHEMA, "supported_scrubpack_version": 1}
	var p := "user://cp04_cfg_%d.json" % Time.get_ticks_usec()
	var f := FileAccess.open(p, FileAccess.WRITE); f.store_string(JSON.stringify(bad)); f.close()
	_ok(RCM.load_config(p).is_empty(), "config with a plain-HTTP endpoint is rejected (remote stays disabled)")
	DirAccess.remove_absolute(p)
	_case("c01_https_only")

func _c02() -> void:
	print("[c02 valid manifest parses; levels keep declared order]")
	var m := _base_manifest()
	m["levels"] = [{"level_id": "zz_9", "pack_id": "fam-a"}, {"level_id": "aa_10", "pack_id": "fam-a"}, {"level_id": "fam_l011", "pack_id": "fam-a"}]
	var r := ContentManifestV1.parse(_bytes(m))
	_ok(r["ok"] and r["manifest"]["levels"].map(func(l): return l["level_id"]) == ["zz_9", "aa_10", "fam_l011"], "declared level order preserved (%s)" % r["reason"])
	_ok(r["sha256"] == ContentManifestV1.sha256_hex(_bytes(m)), "manifest digest = SHA-256 of the exact bytes")
	var minimal := FileAccess.get_file_as_string("res://tests/fixtures/remote_content/content-manifest-minimal.json")
	_ok(ContentManifestV1.parse(minimal.to_utf8_buffer())["ok"], "LF canonical minimal V1 fixture parses")
	_case("c02_manifest_valid_declared_order")

func _c03() -> void:
	print("[c03 duplicate JSON keys rejected (never last-wins)]")
	var good := JSON.stringify(_base_manifest())
	_ok(_parse_reason(good.replace("{\"content_version\":1", "{\"content_version\":1,\"content_version\":2")) == "MANIFEST_DUPLICATE_KEY", "duplicate root key")
	_ok(_parse_reason(good.replace("\"pack_version\":1", "\"pack_version\":1,\"pack_version\":1")) == "MANIFEST_DUPLICATE_KEY", "duplicate nested key")
	var sj := StrictJson.parse("{\"a\":1,\"a\":1}".to_utf8_buffer(), 100, 4, 10, 10)
	_ok(not sj["ok"] and sj["reason"] == "DUPLICATE_KEY", "strict reader: equal-value duplicate still rejected")
	_case("c03_duplicate_keys")

func _c04() -> void:
	print("[c04 unknown fields rejected at root / pack / level]")
	var m := _base_manifest(); m["extra"] = 1
	_ok(_parse_reason(m) == "MANIFEST_INVALID_ROOT_FIELDS", "unknown root field")
	m = _base_manifest(); m["packs"][0]["url"] = "https://x"
	_ok(_parse_reason(m) == "MANIFEST_INVALID_PACK_FIELDS", "unknown pack field")
	m = _base_manifest(); m["levels"][0]["order"] = 11
	_ok(_parse_reason(m) == "MANIFEST_INVALID_LEVEL_FIELDS", "unknown level field (no order inference field)")
	m = _base_manifest(); m.erase("schedules")
	_ok(_parse_reason(m) == "MANIFEST_INVALID_ROOT_FIELDS", "missing root field")
	_case("c04_unknown_fields")

func _c05() -> void:
	print("[c05 non-finite numbers, limits, UTF-8 and exact-grammar rejection]")
	var good := JSON.stringify(_base_manifest())
	_ok(_parse_reason(good.replace("\"content_version\":1", "\"content_version\":1e999")) == "MANIFEST_NON_FINITE_NUMBER", "1e999 rejected")
	_ok(_parse_reason(good.replace("\"content_version\":1", "\"content_version\":NaN")) == "MANIFEST_INVALID_JSON", "NaN literal rejected")
	_ok(_parse_reason(good.replace("\"content_version\":1", "\"content_version\":1.0")) == "MANIFEST_INVALID_CONTENT_VERSION", "1.0 is not an integer")
	_ok(_parse_reason(good.replace("\"content_version\":1", "\"content_version\":99999999999999999999")) == "MANIFEST_LIMIT_EXCEEDED", "integer overflow fails closed")
	var deep := "[".repeat(33) + "]".repeat(33)
	_ok(not StrictJson.parse(deep.to_utf8_buffer(), 1 << 20, 32, 4096, 16384)["ok"], "nesting depth 33 > 32 rejected")
	var m := _base_manifest()
	var many: Array = []
	for i in 4097:
		many.append({"level_id": "x%d" % i, "pack_id": "fam-a"})
	m["levels"] = many
	_ok(_parse_reason(m) == "MANIFEST_LIMIT_EXCEEDED", "4097 items > 4096 rejected")
	m = _base_manifest(); m["minimum_game_version"] = "1".repeat(16385)
	_ok(_parse_reason(m) == "MANIFEST_STRING_TOO_LONG", "string > 16384 code points rejected")
	var big := PackedByteArray(); big.resize(ContentManifestV1.MAX_BYTES + 1); big.fill(0x20)
	_ok(ContentManifestV1.parse(big)["reason"] == "MANIFEST_TOO_LARGE", "> 1 MiB rejected")
	var bad := _bytes(good); bad.insert(2, 0xC0)
	_ok(ContentManifestV1.parse(bad)["reason"] == "MANIFEST_INVALID_UTF8", "overlong UTF-8 rejected")
	var bom := PackedByteArray([0xEF, 0xBB, 0xBF]); bom.append_array(_bytes(good))
	_ok(ContentManifestV1.parse(bom)["reason"] == "MANIFEST_INVALID_JSON", "UTF-8 BOM rejected")
	_ok(not StrictJson.parse("\"\\ud800\"".to_utf8_buffer(), 100, 4, 4, 100)["ok"], "lone surrogate escape rejected")
	_ok(StrictJson.parse(PackedByteArray([0x7B, 0x7D, 0x00, 0x5B]), 100, 4, 4, 100)["reason"] == "INVALID_JSON", "raw NUL byte (Godot would truncate) rejected")
	m = _base_manifest(); m["packs"][0]["pack_id"] = "fam-a\n"
	_ok(not ContentManifestV1.parse(_bytes(m))["ok"], "trailing newline in an ID is not a full match")
	m = _base_manifest(); m["packs"][0]["sha256"] = m["packs"][0]["sha256"].to_upper()
	_ok(_parse_reason(m) == "MANIFEST_INVALID_PACK", "uppercase SHA-256 rejected")
	for key in ["https://cdn/x.scrubpack", "/packs/a/b.scrubpack", "packs/a/../b.scrubpack", "packs\\a\\b.scrubpack", "packs/A/b.scrubpack", "packs/a/b.zip"]:
		m = _base_manifest(); m["packs"][0]["object_key"] = key
		_ok(_parse_reason(m) == "MANIFEST_INVALID_PACK", "object_key rejected: %s" % key)
	for gv in ["1.0", "01.0.0", " 1.0.0", "1.0.0-beta", "v1.0.0"]:
		m = _base_manifest(); m["minimum_game_version"] = gv
		_ok(_parse_reason(m) == "MANIFEST_INVALID_MINIMUM_GAME_VERSION", "minimum_game_version rejected: '%s'" % gv)
	m = _base_manifest(); m["levels"].append({"level_id": "FAM_L011", "pack_id": "fam-a"})
	_ok(_parse_reason(m) == "MANIFEST_DUPLICATE_LEVEL_ID", "casefold-colliding level IDs rejected")
	m = _base_manifest(); m["packs"].append(m["packs"][0].duplicate()); m["packs"][1]["object_key"] = "packs/fam-a/other.scrubpack"
	_ok(_parse_reason(m) == "MANIFEST_DUPLICATE_PACK_ID", "duplicate logical pack ID rejected")
	m = _base_manifest(); m["levels"][0]["pack_id"] = "nope"
	_ok(_parse_reason(m) == "MANIFEST_LEVEL_PACK_NOT_DECLARED", "level referencing an undeclared pack rejected")
	_case("c05_nonfinite_and_limits")

func _c06() -> void:
	print("[c06 schema / version identity]")
	var m := _base_manifest(); m["schema"] = "scrubbots.content.manifest.v2"
	_ok(_parse_reason(m) == "MANIFEST_UNSUPPORTED_SCHEMA", "unknown schema")
	m = _base_manifest(); m["schema_version"] = 2
	_ok(_parse_reason(m) == "MANIFEST_UNSUPPORTED_SCHEMA_VERSION", "schema_version 2")
	_ok(_parse_reason(JSON.stringify(_base_manifest()).replace("\"schema_version\":1", "\"schema_version\":1.0")) == "MANIFEST_UNSUPPORTED_SCHEMA_VERSION", "schema_version 1.0 (float) rejected")
	_case("c06_schema_version")

func _c07() -> void:
	print("[c07 app version gate: canonical ProjectSettings version; too old / malformed fail closed]")
	_ok(String(ProjectSettings.get_setting("application/config/version", "")) == "", "repo has no application/config/version yet (family APK task sets it)")
	var m0 := RCM.new(_root("c07a"))
	_ok(m0.game_version == "", "production reads the canonical setting (absent -> empty)")
	var p := _pack("fam-a", 1, {"fam_l011": "level_002_apple"})
	var t := F.FakeTransport.new()
	t.set_manifest(F.manifest(1, [p], [["fam_l011", "fam-a"]], "2.0.0"), [p])
	for v in ["", "1.0", "1.0.0.0", "01.2.3"]:
		var mg := _mgr(_root("c07v"), t, v)
		var r: Dictionary = await mg.refresh()
		_ok(not r["ok"] and r["reason"] == "GAME_VERSION_UNAVAILABLE" and mg.remote_levels().is_empty(), "current version '%s' -> fail closed, builtin only" % v)
	var old := _mgr(_root("c07b"), t, "1.9.9")
	var r2: Dictionary = await old.refresh()
	_ok(not r2["ok"] and r2["reason"] == "GAME_VERSION_TOO_OLD" and t.object_calls.is_empty(), "app below minimum -> rejected before any pack download")
	var ok := _mgr(_root("c07c"), t, "2.0.0")
	var r3: Dictionary = await ok.refresh()
	_ok(r3["ok"] and ok.remote_levels().size() == 1, "equal version accepted")
	_ok(ContentManifestV1.game_version_compatible("1.10.0", "1.9.0") == "GAME_VERSION_TOO_OLD" and ContentManifestV1.game_version_compatible("1.9.0", "1.10.0") == "COMPATIBLE", "numeric (not lexical) triplet compare")
	_case("c07_game_version_gate")

func _c08() -> void:
	print("[c08 monotonic content_version; same version + different bytes = mutation]")
	var root := _root("c08")
	var a := _pack("fam-a", 1, {"fam_l011": "level_002_apple"})
	var res := await _activate(root, [a], [["fam_l011", "fam-a"]], 2)
	var m: RCM = res[0]
	var t = res[1]
	_ok(res[2]["ok"] and m.status()["content_version"] == 2, "v2 activated")
	var reg_before := FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE)
	t.set_manifest(F.manifest(1, [a], [["fam_l011", "fam-a"]]), [a])
	var r: Dictionary = await m.refresh()
	_ok(not r["ok"] and r["reason"] == "CONTENT_VERSION_NOT_INCREASED", "lower version rejected (no downgrade)")
	var same := F.manifest(2, [a], [["fam_l011", "fam-a"]])
	t.manifest_bytes = JSON.stringify(same, "\t").to_utf8_buffer()   # same content, different bytes
	r = await m.refresh()
	_ok(not r["ok"] and r["reason"] == "MANIFEST_MUTATION", "same version with different manifest bytes = mutation")
	t.set_manifest(same, [a])
	var calls: int = t.object_calls.size()
	r = await m.refresh()
	_ok(r["ok"] and r["reason"] == "UP_TO_DATE" and t.object_calls.size() == calls, "identical manifest: up to date, nothing downloaded")
	_ok(FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE) == reg_before, "rejections never touched the active registry")
	_case("c08_monotonic_and_mutation")

func _c09() -> void:
	print("[c09 missing-pack diff by exact identity; no redundant download]")
	var root := _root("c09")
	var a := _pack("fam-a", 1, {"fam_l011": "level_002_apple"})
	var res := await _activate(root, [a], [["fam_l011", "fam-a"]])
	var m: RCM = res[0]
	var t = res[1]
	var b := _pack("fam-b", 1, {"fam_l012": "level_003_palm_tree"})
	var man := F.manifest(2, [a, b], [["fam_l011", "fam-a"], ["fam_l012", "fam-b"]])
	t.set_manifest(man, [a, b])
	t.object_calls.clear()
	var r: Dictionary = await m.refresh()
	_ok(r["ok"] and t.object_calls == [man["packs"][1]["object_key"]], "only the new pack was downloaded (%s)" % str(t.object_calls))
	var a2 := _pack("fam-a", 2, {"fam_l011": "level_002_apple"})
	man = F.manifest(3, [a2, b], [["fam_l011", "fam-a"], ["fam_l012", "fam-b"]])
	t.set_manifest(man, [a2, b])
	t.object_calls.clear()
	r = await m.refresh()
	_ok(r["ok"] and t.object_calls == [man["packs"][0]["object_key"]], "pack_version bump = different identity -> re-downloaded; unchanged pack reused")
	_case("c09_missing_pack_diff")

func _c10() -> void:
	print("[c10 exact byte_length]")
	var root := _root("c10")
	var a := _pack("fam-a", 1, {"fam_l011": "level_002_apple"})
	var man := F.manifest(1, [a], [["fam_l011", "fam-a"]])
	man["packs"][0]["byte_length"] += 1
	var t := F.FakeTransport.new()
	t.set_manifest(man, [a])
	var m := _mgr(root, t)
	var r: Dictionary = await m.refresh()
	_ok(not r["ok"] and r["reason"] == "PACK_BYTE_LENGTH_MISMATCH" and m.remote_levels().is_empty(), "short archive -> PACK_BYTE_LENGTH_MISMATCH")
	man["packs"][0]["byte_length"] -= 2
	t.set_manifest(man, [a])
	r = await m.refresh()
	_ok(not r["ok"] and r["reason"] == "TRANSPORT_TOO_LARGE", "oversized body capped at the declared byte_length")
	_ok(_empty(root + "downloads/") and _empty(root + "staging/"), "no .part / staging residue")
	_case("c10_byte_length")

func _c11() -> void:
	print("[c11 whole-pack SHA-256]")
	var a := _pack("fam-a", 1, {"fam_l011": "level_002_apple"})
	var man := F.manifest(1, [a], [["fam_l011", "fam-a"]])
	var t := F.FakeTransport.new()
	t.set_manifest(man, [a])
	var tampered: PackedByteArray = a["bytes"].duplicate()
	tampered[tampered.size() - 30] ^= 0x01
	t.corrupt_objects[man["packs"][0]["object_key"]] = tampered
	var m := _mgr(_root("c11"), t)
	var r: Dictionary = await m.refresh()
	_ok(not r["ok"] and r["reason"] == "PACK_SHA256_MISMATCH" and m.remote_levels().is_empty(), "one flipped byte -> PACK_SHA256_MISMATCH, nothing installed")
	_case("c11_pack_sha")

func _c12() -> void:
	print("[c12 ZIP member contract: paths, duplicates, entry metadata]")
	var lv := _levels({"fam_l011": "level_002_apple"})
	var ids := ["fam_l011"]
	_ok(_inspect(F.build_pack("fam-a", 1, lv), ids) == "OK", "canonical pack accepted")
	var add := func(name: String) -> Callable:
		return func(e): return e + [[name, "{}".to_utf8_buffer()]]
	for name in ["levels/../x/level.json", "/pack.json", "levels\\fam_l011\\level.json", "C:/pack.json", "//server/share/pack.json",
			"levels/fam_l011/level.gd", "levels/fam_l011/extra.json", "notes.txt", "levels/fam_l011/"]:
		_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, add.call(name)), ids) == "INVALID_MEMBER_LAYOUT", "undeclared/unsafe member rejected: %s" % name)
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, func(e): return e + [e[1]]), ids) == "INVALID_MEMBER_LAYOUT", "exact duplicate member rejected")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, func(e): return e + [[String(e[1][0]).to_upper(), e[1][1]]]), ids) == "INVALID_MEMBER_LAYOUT", "casefold-duplicate member rejected")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, func(e): return [e[1], e[0], e[2], e[3]]), ids) == "INVALID_MEMBER_LAYOUT", "pack.json not first rejected")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, func(e): return [e[0], e[2], e[1], e[3]]), ids) == "INVALID_MEMBER_LAYOUT", "non-canonical member order rejected")
	var meta_cases := {
		"symlink": {"eattr": 0xA1FF << 16}, "executable": {"eattr": 0x81ED << 16}, "encrypted": {"flags": 1},
		"deflated": {"method": 8}, "unknown host system": {"made_by": (7 << 8) | 20}, "DOS directory attr": {"made_by": 20, "eattr": 0x10},
		"char device": {"eattr": 0x21A4 << 16}}
	for k in meta_cases:
		_ok(_inspect(F.build_pack("fam-a", 1, lv, {"*": meta_cases[k]}), ids) == "UNSUPPORTED_ZIP_METADATA", "%s entry rejected" % k)
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {"levels/fam_l011/level.json": {"local_name": "levels/fam_l011/levxl.json"}}), ids) == "INVALID_ZIP", "local/central name mismatch rejected")
	var good := F.build_pack("fam-a", 1, lv)
	var commented := good.duplicate(); commented.encode_u16(commented.size() - 2, 3); commented.append_array("abc".to_utf8_buffer())
	_ok(_inspect(commented, ids) == "INVALID_ZIP", "archive comment / trailing bytes rejected")
	var z64 := good.duplicate(); z64.encode_u32(z64.size() - 6, 0xFFFFFFFF)
	_ok(_inspect(z64, ids) in ["UNSUPPORTED_ZIP_METADATA", "INVALID_ZIP"], "ZIP64 marker rejected")
	_ok(_inspect("not a zip".to_utf8_buffer(), ids) == "INVALID_ZIP", "non-ZIP bytes rejected")
	_case("c12_zip_member_contract")

func _c13() -> void:
	print("[c13 per-member SHA-256]")
	var lv := _levels({"fam_l011": "level_002_apple"})
	var swap := func(pj):
		pj["levels"][0]["sha256"]["metadata"] = "0".repeat(64)
		return pj
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, Callable(), swap), ["fam_l011"]) == "MEMBER_DIGEST_MISMATCH", "metadata digest mismatch rejected")
	var edit := func(e):
		e[1] = [e[1][0], (e[1][1] as PackedByteArray).get_string_from_utf8().replace("\"Apple\"", "\"Apfel\"").to_utf8_buffer()]
		return e
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, edit), ["fam_l011"]) == "MEMBER_DIGEST_MISMATCH", "level bytes edited after digesting rejected")
	_case("c13_member_sha")

func _c14() -> void:
	print("[c14 pack.json schema / version / media / identity]")
	var lv := _levels({"fam_l011": "level_002_apple"})
	var with := func(k, v) -> Callable:
		return func(pj):
			if v == null:
				pj.erase(k)
			else:
				pj[k] = v
			return pj
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, Callable(), with.call("version", 2)), ["fam_l011"]) == "UNSUPPORTED_VERSION", "future pack version")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, Callable(), with.call("schema", "scrubbots.scrubpack.manifest.v2")), ["fam_l011"]) == "UNSUPPORTED_VERSION", "unknown pack schema")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, Callable(), with.call("version", 1.0)), ["fam_l011"]) == "INVALID_MANIFEST", "float version malformed")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, Callable(), with.call("mediaType", "application/zip")), ["fam_l011"]) == "INVALID_MANIFEST", "wrong mediaType")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, Callable(), with.call("levelCount", 2)), ["fam_l011"]) == "INVALID_MANIFEST", "levelCount mismatch")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, Callable(), with.call("createdAtUtc", null)), ["fam_l011"]) == "INVALID_MANIFEST", "missing createdAtUtc")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, Callable(), with.call("extra", true)), ["fam_l011"]) == "INVALID_MANIFEST", "unknown pack.json field")
	_ok(_inspect(F.build_pack("fam-a", 1, lv, {}, Callable(), func(_pj): return "{\"schema\":\"a\",\"schema\":\"b\"}".to_utf8_buffer()), ["fam_l011"]) == "INVALID_MANIFEST", "duplicate key in pack.json")
	_ok(_inspect(F.build_pack("fam-a", 1, lv), ["fam_l011"], "fam-b") == "PACK_IDENTITY_MISMATCH", "packId != manifest pack_id")
	_ok(_inspect(F.build_pack("fam-a", 1, lv), ["fam_l011"], "fam-a", 2) == "PACK_IDENTITY_MISMATCH", "packVersion != manifest pack_version")
	_case("c14_pack_schema")

## Rebuild one member's bytes (digests recomputed so only payload validation decides).
func _variant(role: String, edit: Callable) -> String:
	var lv := _levels({"fam_l011": "level_002_apple"})
	var files: Dictionary = lv["fam_l011"]
	var v = StrictJson.parse(files[role], 1 << 20, 32, 65536, 8192)["value"]   # ints stay ints
	files[role] = edit.call(files[role].get_string_from_utf8(), v).to_utf8_buffer()
	return _inspect(F.build_pack("fam-a", 1, lv), ["fam_l011"])

func _c15() -> void:
	print("[c15 executable-looking JSON payloads rejected; JSON is data only]")
	_ok(_variant("level", func(s, _v): return s.replace("\"Apple\"", "\"apple.gd\"")) == "LEVEL_EXECUTABLE_CONTENT", "script-file value in level")
	_ok(_variant("metadata", func(_s, v): v["sourceLineage"] = "res://evil.tscn"; return JSON.stringify(v)) == "METADATA_EXECUTABLE_CONTENT", "res:// resource reference in metadata")
	_ok(_variant("supply_plan", func(_s, v): v["ownerInput"] = "preload(\"x\")"; return JSON.stringify(v)) == "SUPPLY_EXECUTABLE_CONTENT", "preload( expression in supply plan")
	_ok(_variant("metadata", func(_s, v): v["fileDigests"] = {"script": "x"}; return JSON.stringify(v)) == "METADATA_EXECUTABLE_CONTENT", "executable-looking key nested")
	_ok(_variant("level", func(s, _v): return "[1,2]") == "LEVEL_WRONG_TOP_LEVEL_TYPE", "non-object member")
	_ok(_variant("level", func(s, _v): return s.replace("\"version\"", "\"version\": 1, \"version\"")) == "LEVEL_DUPLICATE_KEY", "duplicate key in a member")
	_case("c15_executable_json")

func _c16() -> void:
	print("[c16 LevelData contract + current LevelValidator]")
	_ok(_variant("level", func(_s, v): v["cells"][0] = 99; return JSON.stringify(v)) == "LEVEL_INVALID_PAYLOAD", "cell outside palette")
	_ok(_variant("level", func(_s, v): v["cells"].pop_back(); return JSON.stringify(v)) == "LEVEL_INVALID_PAYLOAD", "cell count != width*height")
	_ok(_variant("level", func(_s, v): v.erase("name"); return JSON.stringify(v)) == "LEVEL_UNKNOWN_OR_MISSING_FIELD", "missing field")
	_ok(_variant("level", func(_s, v): v["layer"] = 1; return JSON.stringify(v)) == "LEVEL_UNKNOWN_OR_MISSING_FIELD", "unknown field")
	_ok(_variant("level", func(_s, v): v["palette"][0] = "#ZZZZZZ"; return JSON.stringify(v)) == "SUPPLY_PLAN_INVALID", "off-canonical palette color rejected by the game palette authority (SupplyPlanLoader Cxx map)")
	_ok(_variant("level", func(_s, v): v["width"] = 0; return JSON.stringify(v)) == "LEVEL_INVALID_PAYLOAD", "width 0 rejected")
	_ok(_variant("level", func(s, _v): return s.replace("\"version\": 1", "\"version\": 1.0")) == "LEVEL_INVALID_PAYLOAD", "version 1.0 (float) rejected")
	_case("c16_level_data")

func _c17() -> void:
	print("[c17 ProductionLevelValidator: production classes / envelope / square shell]")
	_ok(_variant("level", func(_s, v): v["difficulty"] = "TEST"; return JSON.stringify(v)) == "LEVEL_NOT_PRODUCTION", "TEST fixture rejected")
	_ok(_variant("level", func(_s, v): v["difficulty"] = "ULTRA"; return JSON.stringify(v)) == "LEVEL_NOT_PRODUCTION", "unknown class rejected")
	var r := ScrubpackV1.validate_level_triplet("fam_l011", _levels({"fam_l011": "level_002_apple"})["fam_l011"])
	_ok(r["ok"] and r["difficulty"] == "EASY" and r["width"] == 32, "valid production level accepted")
	_case("c17_production_validator")

func _c18() -> void:
	print("[c18 SupplyPlanLoader: exact conservation and identity]")
	_ok(_variant("supply_plan", func(_s, v): v["columns"][0][0]["robots"] -= 1; return JSON.stringify(v)) == "SUPPLY_PLAN_INVALID", "per-color conservation broken")
	_ok(_variant("supply_plan", func(_s, v): v["levelId"] = "other"; return JSON.stringify(v)) == "SUPPLY_IDENTITY_MISMATCH", "plan for another level")
	_ok(_variant("supply_plan", func(_s, v): v["visiblePreviewDepth"] = 4; return JSON.stringify(v)) == "SUPPLY_INVALID_PAYLOAD", "preview depth != 3")
	_ok(_variant("supply_plan", func(_s, v): v["columns"][0][0]["cid"] = "C17"; return JSON.stringify(v)) == "SUPPLY_INVALID_PAYLOAD", "off-palette canonical color")
	_case("c18_supply_plan")

func _c19() -> void:
	print("[c19 cross-file identity: level / supply / metadata / pack membership]")
	_ok(_variant("level", func(_s, v): v["id"] = "fam_l099"; return JSON.stringify(v)) == "LEVEL_IDENTITY_MISMATCH", "level.json id != member path id")
	_ok(_variant("metadata", func(_s, v): v["id"] = "fam_l099"; return JSON.stringify(v)) == "METADATA_IDENTITY_MISMATCH", "metadata bound to another level")
	_ok(_variant("metadata", func(_s, v): v["width"] = 33; v["cellCount"] = 33 * 32; return JSON.stringify(v)) == "METADATA_IDENTITY_MISMATCH", "metadata dimensions differ")
	_ok(_variant("metadata", func(_s, v): v["columnCount"] = 4; return JSON.stringify(v)) == "METADATA_IDENTITY_MISMATCH", "metadata column contract differs from the plan")
	var b := F.build_pack("fam-a", 1, _levels({"fam_l011": "level_002_apple", "fam_l012": "level_003_palm_tree"}))
	_ok(_inspect(b, ["fam_l011"]) == "PACK_MEMBERSHIP_MISMATCH", "pack carries a level the manifest did not assign to it")
	_case("c19_identity_binding")

func _c20() -> void:
	print("[c20 builtin ID collision fails closed]")
	for rid in ["level_002_apple", "LEVEL_002_APPLE"]:
		var p := {"pack_id": "fam-a", "pack_version": 1, "bytes": F.build_pack("fam-a", 1, {rid: F.level_files(rid, "level_003_palm_tree")})}
		var res := await _activate(_root("c20"), [p], [[rid, "fam-a"]])
		_ok(not res[2]["ok"] and res[2]["reason"] == "BUILTIN_ID_COLLISION" and res[1].object_calls.is_empty(), "remote '%s' collides with builtin -> rejected before download" % rid)
	var cat := LevelCatalog.new(); cat.load_manifest()
	var comp := Composite.new(cat, [{"id": "Level_002_Apple", "level_path": "x", "supply_plan_path": "y", "metadata_path": "z", "difficulty": "EASY", "width": 32, "height": 32}])
	_ok(comp.remote_rejected == "BUILTIN_ID_COLLISION" and comp.size() == _builtin_ids.size(), "composite drops the whole remote set on collision; builtin intact")
	_case("c20_builtin_collision")

func _c21() -> void:
	print("[c21 remote order = manifest levels array order after the highest builtin order]")
	var spec := {"zeta_9": "level_002_apple", "alpha_10": "level_003_palm_tree", "mid_2": "level_004_orange_cat"}
	var p := {"pack_id": "fam-a", "pack_version": 1, "bytes": F.build_pack("fam-a", 1, _levels(spec))}
	var res := await _activate(_root("c21"), [p], [["zeta_9", "fam-a"], ["alpha_10", "fam-a"], ["mid_2", "fam-a"]])
	var m: RCM = res[0]
	var cat := LevelCatalog.new(); cat.load_manifest()
	var comp := Composite.new(cat, m.remote_levels())
	var tail := comp.get_entries_ordered().slice(_builtin_ids.size())
	_ok(res[2]["ok"] and tail.map(func(e): return [e.id, e.order]) == [["zeta_9", _builtin_max + 1], ["alpha_10", _builtin_max + 2], ["mid_2", _builtin_max + 3]],
		"declared order kept, no numeric-suffix / alphabetical / pack sorting: %s" % str(tail.map(func(e): return [e.id, e.order])))
	var head := comp.get_entries_ordered().slice(0, _builtin_ids.size())
	_ok(head.map(func(e): return e.id) == _builtin_ids and head[0].order == 1, "builtin entries and orders unchanged")
	var e0 = comp.get_entry_by_id("zeta_9"); e0.order = 999
	_ok(comp.get_entry_by_id("zeta_9").order == _builtin_max + 1, "composite returns deep copies")
	_case("c21_declared_order_no_numeric_sort")

func _c22() -> void:
	print("[c22 successor appending new levels is accepted]")
	var a := _pack("fam-a", 1, {"fam_l011": "level_002_apple"})
	var res := await _activate(_root("c22"), [a], [["fam_l011", "fam-a"]])
	var m: RCM = res[0]
	var b := _pack("fam-b", 1, {"fam_l012": "level_003_palm_tree"})
	res[1].set_manifest(F.manifest(2, [a, b], [["fam_l011", "fam-a"], ["fam_l012", "fam-b"]]), [a, b])
	var r: Dictionary = await m.refresh()
	_ok(r["ok"] and m.remote_levels().map(func(l): return l["id"]) == ["fam_l011", "fam_l012"], "append-only successor activated")
	_case("c22_append_only_successor")

func _c23() -> void:
	print("[c23 reorder / removal / reassignment of the activated sequence fails closed]")
	var a := _pack("fam-a", 1, {"fam_l011": "level_002_apple", "fam_l012": "level_003_palm_tree"})
	var res := await _activate(_root("c23"), [a], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"]])
	var m: RCM = res[0]
	var t = res[1]
	var b := _pack("fam-b", 1, {"fam_l012": "level_003_palm_tree"})
	var a2 := _pack("fam-a", 2, {"fam_l011": "level_002_apple"})
	var cases := {
		"reorder": [[a], [["fam_l012", "fam-a"], ["fam_l011", "fam-a"]]],
		"removal": [[a2], [["fam_l011", "fam-a"]]],
		"reassignment": [[a2, b], [["fam_l011", "fam-a"], ["fam_l012", "fam-b"]]],
	}
	for k in cases:
		t.set_manifest(F.manifest(5, cases[k][0], cases[k][1]), cases[k][0])
		var r: Dictionary = await m.refresh()
		_ok(not r["ok"] and r["reason"] == "REMOTE_SEQUENCE_NOT_APPEND_ONLY" and m.remote_levels().map(func(l): return l["id"]) == ["fam_l011", "fam_l012"],
			"%s rejected; previous LKG still active" % k)
	_case("c23_reorder_removal_rejected")

func _c24() -> void:
	print("[c24 disabled_levels / schedules are not silently ignored before CP06]")
	var a := _pack("fam-a", 1, {"fam_l011": "level_002_apple"})
	var res := await _activate(_root("c24"), [a], [["fam_l011", "fam-a"]])
	var m: RCM = res[0]
	var t = res[1]
	for extra in [{"disabled_levels": ["fam_l011"]}, {"schedules": [{"target_kind": "level", "target_id": "fam_l011", "not_before": "2026-10-07T00:00:00Z"}]}]:
		t.set_manifest(F.manifest(2, [a], [["fam_l011", "fam-a"]], "0.0.0", extra), [a])
		var r: Dictionary = await m.refresh()
		_ok(not r["ok"] and r["reason"] == "UNSUPPORTED_RUNTIME_SEMANTICS" and m.status()["content_version"] == 1 and m.remote_levels().size() == 1,
			"%s -> unsupported; LKG v1 retained" % str(extra.keys()))
	_case("c24_disabled_schedules_retain_lkg")

func _app_with_remote(tag: String) -> Array:
	ProjectSettings.set_setting("application/config/version", "1.0.0")
	var save := "user://cp04_%s_%d.save" % [tag, Time.get_ticks_usec()]
	var app = AppState.new(save)
	_roots.append(save.get_basename() + "_content/")
	var a := _pack("fam-a", 1, {"fam_l011": "level_002_apple", "fam_l012": "level_003_palm_tree"})
	var t := F.FakeTransport.new()
	t.set_manifest(F.manifest(1, [a], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"]]), [a])
	app.content.enabled = true
	app.content.transport = t
	return [app, save]

func _c25() -> void:
	print("[c25 GameplayLaunchResolver: builtin 1..10 then remote 11+]")
	var x: Array = _app_with_remote("c25")
	var app = x[0]
	var r: Dictionary = await app.content.refresh()
	_ok(r["ok"], "remote set activated through AppState.content (%s)" % r["reason"])
	app.progression.debug_set_current_level(10)
	var l10 := GameplayLaunchResolver.resolve(app)
	_ok(l10["ok"] and l10["entry_id"] == "level_010_ice_cube" and String(l10["level_path"]).begins_with("res://"), "frontier 10 -> builtin")
	app.progression.debug_set_current_level(11)
	var l11 := GameplayLaunchResolver.resolve(app)
	_ok(l11["ok"] and l11["entry_id"] == "fam_l011" and String(l11["level_path"]).begins_with(app.content.root) and String(l11["supply_plan_path"]).ends_with("fam_l011/supply-plan.json"), "frontier 11 -> remote fam_l011 under user://content root")
	app.progression.debug_set_current_level(12)
	_ok(GameplayLaunchResolver.resolve(app)["entry_id"] == "fam_l012", "frontier 12 -> remote fam_l012")
	DirAccess.remove_absolute(x[1])
	ProjectSettings.set_setting("application/config/version", null)
	_case("c25_resolver_builtin_then_remote")

func _c26() -> void:
	print("[c26 frontier past available content stays CONTENT_MISSING]")
	var x: Array = _app_with_remote("c26")
	var app = x[0]
	app.progression.debug_set_current_level(11)
	var before := GameplayLaunchResolver.resolve(app)
	_ok(not before["ok"] and before["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "no remote yet: frontier 11 -> CONTENT_MISSING (never builtin under a wrong number)")
	await app.content.refresh()
	app.progression.debug_set_current_level(13)
	var after := GameplayLaunchResolver.resolve(app)
	_ok(not after["ok"] and after["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "frontier 13 beyond remote 11..12 -> CONTENT_MISSING")
	DirAccess.remove_absolute(x[1])
	ProjectSettings.set_setting("application/config/version", null)
	_case("c26_missing_remote_frontier")

func _c27() -> void:
	print("[c27 AppState.orders_context sees the composite playable order set]")
	var x: Array = _app_with_remote("c27")
	var app = x[0]
	app.progression.debug_set_current_level(10)
	_ok(app.orders_context()["playable_ahead"] == 1, "before remote: only builtin level 10 ahead")
	await app.content.refresh()
	_ok(app.orders_context()["playable_ahead"] == 3, "after activation: 10 + remote 11, 12 playable ahead (cache invalidated)")
	DirAccess.remove_absolute(x[1])
	ProjectSettings.set_setting("application/config/version", null)
	_case("c27_orders_context_composite")

func _c28() -> void:
	print("[c28 content install never mutates progression / economy / save truth]")
	var x: Array = _app_with_remote("c28")
	var app = x[0]
	app.progression.debug_set_current_level(7)
	app.request_save()
	var save_before := FileAccess.get_file_as_bytes(x[1])
	var prog: Dictionary = app.progression.snapshot()
	var sb: int = app.economy.wallet.scrub_bucks()
	var r: Dictionary = await app.content.refresh()
	_ok(r["ok"] and FileAccess.get_file_as_bytes(x[1]) == save_before and app.progression.snapshot() == prog and app.economy.wallet.scrub_bucks() == sb and not app.is_dirty(),
		"save bytes, progression snapshot, wallet and dirty flag unchanged by activation")
	DirAccess.remove_absolute(x[1])
	ProjectSettings.set_setting("application/config/version", null)
	_case("c28_install_never_mutates_save")
