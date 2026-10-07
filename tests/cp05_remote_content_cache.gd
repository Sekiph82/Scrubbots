extends SceneTree
## CP05/M16 — offline cache, versioned local registry and last-known-good recovery.
## Deterministic: injected FakeTransport + locally built canonical packs (no network).
##
## Run: godot --headless --path . -s res://tests/cp05_remote_content_cache.gd

const F = preload("res://tests/support/scrubpack_fixture.gd")
const RCM = preload("res://scripts/content_runtime/remote_content_manager.gd")
const ContentManifestV1 = preload("res://scripts/content_runtime/content_manifest_v1.gd")
const Composite = preload("res://scripts/content_runtime/composite_level_catalog.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")

var EXPECTED := ["k01_first_launch_no_network", "k02_cached_lkg_offline_boot", "k03_fetch_failure_keeps_lkg",
	"k04_server_error_keeps_lkg", "k05_corrupt_registry_builtin_fallback", "k06_corrupt_candidate_never_replaces_lkg",
	"k07_interrupted_download_cleanup", "k08_interrupted_staging_cleanup", "k09_atomic_registry_activation",
	"k10_relaunch_same_catalog", "k11_partial_cache_after_update_repairs", "k12_min_version_downgrade",
	"k13_lkg_never_deleted_before_replacement", "k14_retention_keeps_active", "k15_idempotent_and_single_flight"]

var _fail := 0
var _done := {}
var _roots: Array = []
var _builtin_ids: Array = []

## Manifest fetch that suspends for a few frames (lets a second refresh() race it).
class SlowTransport extends F.FakeTransport:
	var tree: SceneTree
	func fetch_manifest() -> Dictionary:
		await tree.create_timer(0.05).timeout
		return super.fetch_manifest()

func _initialize() -> void:
	await process_frame
	var cat := LevelCatalog.new()
	cat.load_manifest()
	_builtin_ids = cat.get_entries_ordered().map(func(e): return e.id)
	await _k01(); await _k02(); await _k03(); await _k04(); await _k05(); await _k06(); await _k07(); await _k08()
	await _k09(); await _k10(); await _k11(); await _k12(); await _k13(); await _k14(); await _k15()
	for r in _roots:
		_rm(r)
	ProjectSettings.set_setting("application/config/version", null)
	var missing := EXPECTED.filter(func(c): return not _done.has(c))
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: cases not completed: %s" % str(missing))
	print("CP05 remote content cache evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _done.size(), EXPECTED.size(), _fail])
	quit(0 if _fail == 0 else 1)

func _ok(c: bool, msg: String) -> void:
	if c:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _root(tag: String) -> String:
	var r := "user://cp05_%s_%d/" % [tag, Time.get_ticks_usec()]
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
	m.enabled = t != null
	m.transport = t
	m.boot()
	return m

func _pack(pack_id: String, ver: int, spec: Dictionary) -> Dictionary:
	var lv := {}
	for id in spec:
		lv[id] = F.level_files(id, spec[id])
	return {"pack_id": pack_id, "pack_version": ver, "bytes": F.build_pack(pack_id, ver, lv)}

var _a := {}
var _b := {}

## Root with v1 = pack fam-a {fam_l011, fam_l012} activated. Returns [mgr, transport].
func _v1(root: String, version := "1.0.0", min_version := "0.0.0") -> Array:
	if _a.is_empty():
		_a = _pack("fam-a", 1, {"fam_l011": "level_002_apple", "fam_l012": "level_003_palm_tree"})
		_b = _pack("fam-b", 1, {"fam_l013": "level_004_orange_cat"})
	var t := F.FakeTransport.new()
	t.set_manifest(F.manifest(1, [_a], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"]], min_version), [_a])
	var m := _mgr(root, t, version)
	var r: Dictionary = await m.refresh()
	_ok(r["ok"] and m.remote_levels().size() == 2, "setup: v1 activated (%s)" % r["reason"])
	return [m, t]

func _ids(m: RCM) -> Array:
	return m.remote_levels().map(func(l): return l["id"])

func _put(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

# ----------------------------------------------------------------- cases --

func _k01() -> void:
	print("[k01 first-ever launch, no network: builtin playable, no fake success, no crash]")
	ProjectSettings.set_setting("application/config/version", "1.0.0")
	var save := "user://cp05_k01_%d.save" % Time.get_ticks_usec()
	var app = AppState.new(save)
	_roots.append(save.get_basename() + "_content/")
	var t := F.FakeTransport.new()
	t.offline = true
	app.content.enabled = true
	app.content.transport = t
	_ok(app.content.remote_levels().is_empty() and GameplayLaunchResolver.resolve(app)["entry_id"] == "m21_level_001_hazard_bot", "boot: builtin level 1 resolves, no remote")
	var r: Dictionary = await app.content.refresh()
	_ok(not r["ok"] and app.content.status()["status"] == RCM.OFFLINE_USING_CACHE and app.content.remote_levels().is_empty(), "offline refresh -> offline_using_cache, nothing activated")
	_ok(not DirAccess.dir_exists_absolute(app.content.root + "packs/") and not FileAccess.file_exists(app.content.root + RCM.REGISTRY_FILE), "no registry / pack written")
	app.progression.debug_set_current_level(10)
	_ok(GameplayLaunchResolver.resolve(app)["ok"], "builtin 1..10 still playable")
	DirAccess.remove_absolute(save)
	_done["k01_first_launch_no_network"] = true

func _k02() -> void:
	print("[k02 valid cached LKG boots offline]")
	var root := _root("k02")
	await _v1(root)
	var off := F.FakeTransport.new()
	off.offline = true
	var m := _mgr(root, off)
	_ok(_ids(m) == ["fam_l011", "fam_l012"] and m.is_active_usable(), "cold boot exposes cached remote levels before any network")
	var r: Dictionary = await m.refresh()
	_ok(not r["ok"] and m.status()["status"] == RCM.OFFLINE_USING_CACHE and _ids(m) == ["fam_l011", "fam_l012"], "offline refresh keeps LKG playable")
	_done["k02_cached_lkg_offline_boot"] = true

func _k03() -> void:
	print("[k03 manifest fetch / parse failure keeps LKG]")
	var x := await _v1(_root("k03"))
	var m: RCM = x[0]
	var t = x[1]
	t.offline = true
	await m.refresh()
	_ok(_ids(m).size() == 2 and m.status()["reason"] == "TRANSPORT_OFFLINE", "fetch failure -> LKG")
	t.offline = false
	t.manifest_bytes = "{not json".to_utf8_buffer()
	var r: Dictionary = await m.refresh()
	_ok(not r["ok"] and m.status()["status"] == RCM.FAILED_USING_CACHE and _ids(m).size() == 2, "unparseable manifest -> failed_using_cache, LKG kept")
	_done["k03_fetch_failure_keeps_lkg"] = true

func _k04() -> void:
	print("[k04 server error keeps LKG]")
	var x := await _v1(_root("k04"))
	var m: RCM = x[0]
	x[1].http_error = 503
	var r: Dictionary = await m.refresh()
	_ok(not r["ok"] and r["reason"] == "TRANSPORT_HTTP_503" and m.status()["status"] == RCM.OFFLINE_USING_CACHE and _ids(m).size() == 2, "HTTP 503 -> LKG kept")
	_done["k04_server_error_keeps_lkg"] = true

func _k05() -> void:
	print("[k05 corrupt active registry -> builtin fallback (no crash, nothing deleted)]")
	var root := _root("k05")
	await _v1(root)
	var packs_before := DirAccess.get_directories_at(root + "packs/fam-a/")
	for junk in ["", "{", "{\"schema\":\"scrubbots.content.registry.v1\"}", "[1,2,3]"]:
		_put(root + RCM.REGISTRY_FILE, junk)
		var m := _mgr(root, null)
		_ok(m.remote_levels().is_empty() and m.active_registry().is_empty(), "registry '%s' -> builtin only" % junk.left(20))
	_ok(DirAccess.get_directories_at(root + "packs/fam-a/") == packs_before, "corrupt registry never triggers pruning")
	var cat := LevelCatalog.new(); cat.load_manifest()
	_ok(Composite.new(cat, []).size() == _builtin_ids.size(), "composite = builtin only")
	_done["k05_corrupt_registry_builtin_fallback"] = true

func _k06() -> void:
	print("[k06 corrupt candidate can never replace the LKG]")
	var root := _root("k06")
	var x := await _v1(root)
	var m: RCM = x[0]
	var t = x[1]
	var reg := FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE)
	var man := F.manifest(2, [_a, _b], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"], ["fam_l013", "fam-b"]])
	t.set_manifest(man, [_a, _b])
	var bad: PackedByteArray = _b["bytes"].duplicate()
	bad[bad.size() / 2] ^= 0xFF
	t.corrupt_objects[man["packs"][1]["object_key"]] = bad
	var r: Dictionary = await m.refresh()
	_ok(not r["ok"] and r["reason"] == "PACK_SHA256_MISMATCH", "candidate v2 rejected")
	_ok(FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE) == reg and _ids(m) == ["fam_l011", "fam_l012"] and m.status()["content_version"] == 1, "active registry bytes and v1 set unchanged")
	_ok(not DirAccess.dir_exists_absolute(root + "packs/fam-b/") and _empty(root + "staging/"), "nothing of the bad candidate installed or left staged")
	_done["k06_corrupt_candidate_never_replaces_lkg"] = true

func _k07() -> void:
	print("[k07 interrupted download (.part) is cleaned at boot; LKG untouched]")
	var root := _root("k07")
	await _v1(root)
	var reg := FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE)
	_put(root + "downloads/123_456.part", "half a pack")
	var m := _mgr(root, null)
	_ok(_empty(root + "downloads/") and FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE) == reg and _ids(m).size() == 2, ".part removed, registry + LKG intact")
	_done["k07_interrupted_download_cleanup"] = true

func _k08() -> void:
	print("[k08 interrupted staging / orphan install / tmp registry are cleaned at boot]")
	var root := _root("k08")
	await _v1(root)
	var reg := FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE)
	_put(root + "staging/999_1/pack/levels/x/level.json", "{}")
	_put(root + "packs/fam-z/1-%s/levels/x/level.json" % "0".repeat(64), "{}")
	_put(root + RCM.REGISTRY_TMP, "{\"half\":")
	var m := _mgr(root, null)
	_ok(not DirAccess.dir_exists_absolute(root + "staging/") and not DirAccess.dir_exists_absolute(root + "packs/fam-z/") and not FileAccess.file_exists(root + RCM.REGISTRY_TMP),
		"staging, orphan pack and tmp registry removed")
	_ok(FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE) == reg and _ids(m).size() == 2, "active set untouched")
	_done["k08_interrupted_staging_cleanup"] = true

func _k09() -> void:
	print("[k09 registry activation: verified tmp -> rename; previous LKG kept as evidence]")
	var root := _root("k09")
	var x := await _v1(root)
	var m: RCM = x[0]
	var reg1 := FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE)
	var parsed := RCM.parse_registry(reg1)
	_ok(not parsed.is_empty() and parsed["content_version"] == 1 and parsed["validated_game_version"] == "1.0.0" and parsed["levels"].size() == 2
		and parsed["manifest_sha256"] == ContentManifestV1.sha256_hex(x[1].manifest_bytes), "registry v1: versioned, manifest digest, pack identities, ordered levels")
	x[1].set_manifest(F.manifest(2, [_a, _b], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"], ["fam_l013", "fam-b"]]), [_a, _b])
	var r: Dictionary = await m.refresh()
	_ok(r["ok"] and FileAccess.get_file_as_bytes(root + RCM.REGISTRY_PREV) == reg1 and not FileAccess.file_exists(root + RCM.REGISTRY_TMP)
		and RCM.parse_registry(FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE))["content_version"] == 2, "v2 committed by rename; v1 kept as registry_v1.prev.json")
	var src := FileAccess.get_file_as_string("res://scripts/content_runtime/remote_content_manager.gd")
	var vi := src.find("_verify_set(candidate, dirs)")
	var ci := src.find("return _commit(tx, candidate, staged)")
	_ok(vi > 0 and ci > vi and src.find("func _commit") > ci and src.contains("DirAccess.rename_absolute(tmp, active)"), "whole candidate verified in staging before the single commit (pack placement + registry rename)")
	_done["k09_atomic_registry_activation"] = true

func _k10() -> void:
	print("[k10 relaunch reconstructs the same remote catalog]")
	var root := _root("k10")
	var x := await _v1(root)
	var cat := LevelCatalog.new(); cat.load_manifest()
	var a := Composite.new(cat, x[0].remote_levels()).get_entries_ordered()
	var b := Composite.new(cat, _mgr(root, null).remote_levels()).get_entries_ordered()
	var sig := func(es: Array): return es.map(func(e): return [e.id, e.order, e.level_path, e.supply_plan_path, e.difficulty, e.width])
	_ok(sig.call(a) == sig.call(b) and a.size() == _builtin_ids.size() + 2, "identical composite after relaunch")
	_done["k10_relaunch_same_catalog"] = true

func _k11() -> void:
	print("[k11 partial cache / app update: verified fallback, then exact repair]")
	var root := _root("k11")
	var x := await _v1(root)
	var lp: String = x[0].remote_levels()[1]["level_path"]
	DirAccess.remove_absolute(lp)
	var t := F.FakeTransport.new()
	t.set_manifest(F.manifest(1, [_a], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"]]), [_a])
	var m := _mgr(root, t)
	_ok(m.remote_levels().is_empty() and m.status()["reason"] == "CACHE_FILE_MISSING_OR_CHANGED", "missing file -> whole remote set hidden (builtin only)")
	var r: Dictionary = await m.refresh()
	_ok(r["ok"] and r["reason"] == "ACTIVATED" and t.object_calls.size() == 1 and _ids(m) == ["fam_l011", "fam_l012"], "same manifest re-download repairs the set")
	var upd := _mgr(root, null, "1.1.0")
	_ok(_ids(upd) == ["fam_l011", "fam_l012"], "app update 1.0.0 -> 1.1.0: cache fully re-validated with current validators and kept")
	var lvl := FileAccess.open(lp, FileAccess.READ_WRITE); lvl.seek(10); lvl.store_8(0x20); lvl.close()
	_ok(_mgr(root, null).remote_levels().is_empty(), "a changed byte in an installed file -> hidden")
	_done["k11_partial_cache_after_update_repairs"] = true

func _k12() -> void:
	print("[k12 app downgrade below manifest minimum: cache hidden, kept, usable again after update]")
	var root := _root("k12")
	await _v1(root, "1.2.0", "1.2.0")
	var down := _mgr(root, null, "1.1.0")
	_ok(down.remote_levels().is_empty() and down.status()["reason"] == "CACHE_GAME_VERSION_TOO_OLD", "1.1.0 < minimum 1.2.0 -> builtin only")
	_ok(DirAccess.dir_exists_absolute(root + "packs/fam-a/") and FileAccess.file_exists(root + RCM.REGISTRY_FILE), "cache files are preserved (not pruned)")
	_ok(_ids(_mgr(root, null, "1.2.0")) == ["fam_l011", "fam_l012"], "back on a compatible build: cache usable again")
	_ok(_mgr(root, null, "").remote_levels().is_empty(), "absent app version -> remote never exposed (fail closed)")
	_done["k12_min_version_downgrade"] = true

func _k13() -> void:
	print("[k13 the only known-good set is never deleted before a replacement validates]")
	var root := _root("k13")
	var x := await _v1(root)
	var m: RCM = x[0]
	var t = x[1]
	var files: Array = m.remote_levels().map(func(l): return FileAccess.get_file_as_bytes(l["level_path"]))
	var a2 := _pack("fam-a", 2, {"fam_l011": "level_002_apple", "fam_l012": "level_003_palm_tree"})
	var man := F.manifest(2, [a2], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"]])
	t.set_manifest(man, [a2])
	var broken: PackedByteArray = a2["bytes"].duplicate()
	broken.resize(broken.size() - 1)
	t.corrupt_objects[man["packs"][0]["object_key"]] = broken
	var r: Dictionary = await m.refresh()
	_ok(not r["ok"] and m.remote_levels().map(func(l): return FileAccess.get_file_as_bytes(l["level_path"])) == files, "failed replacement: every v1 file still on disk, byte-identical")
	t.corrupt_objects.clear()
	r = await m.refresh()
	_ok(r["ok"] and m.status()["content_version"] == 2 and not DirAccess.dir_exists_absolute(x[0].install_dir(F.manifest(1, [_a], [])["packs"][0])), "valid replacement commits, only then the old pack version is pruned")
	_done["k13_lkg_never_deleted_before_replacement"] = true

func _k14() -> void:
	print("[k14 retention never removes active packs]")
	var root := _root("k14")
	var x := await _v1(root)
	var m: RCM = x[0]
	x[1].set_manifest(F.manifest(2, [_a, _b], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"], ["fam_l013", "fam-b"]]), [_a, _b])
	await m.refresh()
	var active_dirs: Array = m.active_registry()["packs"].map(func(p): return m.install_dir(p))
	_mgr(root, null)   # boot-time prune
	_mgr(root, null)
	_ok(active_dirs.all(func(d): return DirAccess.dir_exists_absolute(d)) and active_dirs.size() == 2, "both active pack dirs survive repeated boot pruning")
	_ok(_ids(_mgr(root, null)) == ["fam_l011", "fam_l012", "fam_l013"], "active set intact")
	_ok(RCM.load_config().get("max_cache_bytes") == 536870912, "shipped cache cap 512 MiB")
	var c := _pack("fam-c", 1, {"fam_l014": "level_005_party_toucan"})
	x[1].set_manifest(F.manifest(3, [_a, _b, c], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"], ["fam_l013", "fam-b"], ["fam_l014", "fam-c"]]), [_a, _b, c])
	m.config["max_cache_bytes"] = _a["bytes"].size() + _b["bytes"].size()
	x[1].object_calls.clear()
	var r: Dictionary = await m.refresh()
	_ok(not r["ok"] and r["reason"] == "CACHE_LIMIT_EXCEEDED" and x[1].object_calls.is_empty() and m.status()["content_version"] == 2, "candidate over the cache cap refused before download; LKG v2 kept")
	_done["k14_retention_keeps_active"] = true

func _k15() -> void:
	print("[k15 repeated refresh is idempotent; concurrent refresh is single-flight]")
	var root := _root("k15")
	var t := SlowTransport.new()
	t.tree = self
	if _a.is_empty():
		await _v1(_root("k15seed"))
	t.set_manifest(F.manifest(1, [_a], [["fam_l011", "fam-a"], ["fam_l012", "fam-a"]]), [_a])
	var m := _mgr(root, t)
	var untyped = m
	untyped.refresh()   # fire-and-forget like main.gd; suspends inside the slow manifest fetch
	var second: Dictionary = await m.refresh()
	_ok(not second["ok"] and second["reason"] == "REFRESH_IN_PROGRESS", "second concurrent refresh refused")
	while m.status()["refreshing"]:
		await process_frame
	_ok(m.status()["status"] == RCM.UPDATED and t.manifest_calls == 1 and t.object_calls.size() == 1, "one transaction, one download")
	var reg := FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE)
	for i in 3:
		var r: Dictionary = await m.refresh()
		_ok(r["ok"] and r["reason"] == "UP_TO_DATE" and m.status()["status"] == RCM.IDLE, "refresh #%d up to date" % (i + 2))
	_ok(t.object_calls.size() == 1 and FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE) == reg, "no re-download, registry byte-identical")
	_done["k15_idempotent_and_single_flight"] = true
