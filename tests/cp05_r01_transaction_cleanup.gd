extends SceneTree
## SB-CP05-R01-001 — failed multi-pack candidate transactions leave NO trace, immediately
## (no reboot): the whole content root is byte-identical to before the failed refresh.
## Deterministic FakeTransport + synthetic packs; isolated user://cp05r01_* roots only.
##
## Run: godot --headless --path . -s res://tests/cp05_r01_transaction_cleanup.gd

const F = preload("res://tests/support/scrubpack_fixture.gd")
const RCM = preload("res://scripts/content_runtime/remote_content_manager.gd")
const ContentManifestV1 = preload("res://scripts/content_runtime/content_manifest_v1.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")

var EXPECTED := ["t1_multipack_failure_with_lkg", "t2_multipack_failure_without_registry", "t3_reused_pack_survives",
	"t4_valid_retry_activates_once", "t5_verify_and_registry_failures_roll_back", "t6_cold_boot_after_interruption"]

var _fail := 0
var _done := {}
var _roots: Array = []
var _builtin_ids: Array = []
var A := {}
var B := {}
var C := {}

func _initialize() -> void:
	await process_frame
	var cat := LevelCatalog.new()
	cat.load_manifest()
	_builtin_ids = cat.get_entries_ordered().map(func(e): return e.id)
	A = _pack("fam-a", {"fam_l011": "level_002_apple"})
	B = _pack("fam-b", {"fam_l012": "level_003_palm_tree"})
	C = _pack("fam-c", {"fam_l013": "level_004_orange_cat"})
	await _t1(); await _t2(); await _t3(); await _t4(); await _t5(); await _t6()
	for r in _roots:
		_rm(r)
	ProjectSettings.set_setting("application/config/version", null)
	var missing := EXPECTED.filter(func(c): return not _done.has(c))
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: cases not completed: %s" % str(missing))
	print("CP05-R01 transaction cleanup evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _done.size(), EXPECTED.size(), _fail])
	quit(0 if _fail == 0 else 1)

# --------------------------------------------------------------- helpers --

func _ok(c: bool, msg: String) -> void:
	if c:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _root(tag: String) -> String:
	var r := "user://cp05r01_%s_%d/" % [tag, Time.get_ticks_usec()]
	_roots.append(r)
	return r

func _rm(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + f)
	for d in DirAccess.get_directories_at(dir):
		_rm(dir + d + "/")
	DirAccess.remove_absolute(dir)

## Every file AND directory under `dir` -> sha256 ("<dir>" for directories). Exact tree identity.
func _tree(dir: String, base: String = "") -> Dictionary:
	var out := {}
	if not DirAccess.dir_exists_absolute(dir):
		return out
	for f in DirAccess.get_files_at(dir):
		out[base + f] = ContentManifestV1.sha256_hex(FileAccess.get_file_as_bytes(dir + f))
	for d in DirAccess.get_directories_at(dir):
		out[base + d + "/"] = "<dir>"
		out.merge(_tree(dir + d + "/", base + d + "/"))
	return out

func _pack(pack_id: String, spec: Dictionary) -> Dictionary:
	var lv := {}
	for id in spec:
		lv[id] = F.level_files(id, spec[id])
	return {"pack_id": pack_id, "pack_version": 1, "bytes": F.build_pack(pack_id, 1, lv)}

func _mgr(root: String, t) -> RCM:
	var m := RCM.new(root, "1.0.0", func(): return _builtin_ids)
	m.enabled = t != null
	m.transport = t
	m.boot()
	return m

const LV_A := [["fam_l011", "fam-a"]]
const LV_ABC := [["fam_l011", "fam-a"], ["fam_l012", "fam-b"], ["fam_l013", "fam-c"]]

func _key(p: Dictionary) -> String:
	return "packs/%s/%s-v1.scrubpack" % [p["pack_id"], p["pack_id"]]

## Active N = pack A only. Returns [mgr, transport].
func _with_a(root: String) -> Array:
	var t := F.FakeTransport.new()
	t.set_manifest(F.manifest(1, [A], LV_A), [A])
	var m := _mgr(root, t)
	var r: Dictionary = await m.refresh()
	_ok(r["ok"] and m.remote_levels().size() == 1, "setup: active N=1 with pack A (%s)" % r["reason"])
	return [m, t]

## Serve candidate N+1 = A + B + C with C broken. mode: "hash" | "zip".
func _serve_abc_broken_c(t, mode: String) -> void:
	if mode == "hash":
		t.set_manifest(F.manifest(2, [A, B, C], LV_ABC), [A, B, C])
		var bad: PackedByteArray = C["bytes"].duplicate()
		bad[bad.size() / 2] ^= 0xFF
		t.corrupt_objects[_key(C)] = bad
	else:   # correctly hashed, malformed archive (extra script member)
		var lv := {"fam_l013": F.level_files("fam_l013", "level_004_orange_cat")}
		var evil := {"pack_id": "fam-c", "pack_version": 1, "bytes": F.build_pack("fam-c", 1, lv, {}, func(e): return e + [["levels/fam_l013/x.gd", "x".to_utf8_buffer()]])}
		t.corrupt_objects.clear()
		t.set_manifest(F.manifest(2, [A, B, evil], LV_ABC), [A, B, evil])

func _ids(m: RCM) -> Array:
	return m.remote_levels().map(func(l): return l["id"])

func _no_trace(root: String, label: String) -> void:
	_ok(not DirAccess.dir_exists_absolute(root + "staging/") or DirAccess.get_directories_at(root + "staging/").is_empty(), "%s: no transaction staging left" % label)
	_ok(not DirAccess.dir_exists_absolute(root + "downloads/") or DirAccess.get_files_at(root + "downloads/").is_empty(), "%s: no .part left" % label)
	_ok(not FileAccess.file_exists(root + RCM.REGISTRY_TMP), "%s: no candidate registry tmp" % label)
	_ok(not DirAccess.dir_exists_absolute(root + "packs/fam-b/") and not DirAccess.dir_exists_absolute(root + "packs/fam-c/"), "%s: no final B / C pack dir" % label)

# ----------------------------------------------------------------- cases --

func _t1() -> void:
	print("[t1 active N(A); candidate N+1 = A + B + C; B verifies, C fails -> immediate, exact cleanup]")
	for mode in ["hash", "zip"]:
		var root := _root("t1" + mode)
		var x := await _with_a(root)
		var m: RCM = x[0]
		var t = x[1]
		var before := _tree(root)
		_serve_abc_broken_c(t, mode)
		t.object_calls.clear()
		var r: Dictionary = await m.refresh()
		_ok(not r["ok"] and r["reason"] == ("PACK_SHA256_MISMATCH" if mode == "hash" else "INVALID_MEMBER_LAYOUT"), "C %s failure reported (%s)" % [mode, r["reason"]])
		_ok(t.object_calls == [_key(B), _key(C)], "B was downloaded and verified before C failed (%s)" % str(t.object_calls))
		_ok(_tree(root) == before, "WITHOUT reboot: whole content root byte-identical to before (registry, A, no B/C)")
		_no_trace(root, "C " + mode)
		_ok(_ids(m) == ["fam_l011"] and m.status()["content_version"] == 1 and m.status()["status"] == RCM.FAILED_USING_CACHE, "LKG N=1 still active and playable in this session")
	_done["t1_multipack_failure_with_lkg"] = true

func _t2() -> void:
	print("[t2 no active registry; two new packs, second fails -> nothing remains; builtin plays]")
	ProjectSettings.set_setting("application/config/version", "1.0.0")
	var save := "user://cp05r01_t2_%d.save" % Time.get_ticks_usec()
	var app = AppState.new(save)
	var root: String = app.content.root
	_roots.append(root)
	var t := F.FakeTransport.new()
	t.set_manifest(F.manifest(1, [B, C], [["fam_l012", "fam-b"], ["fam_l013", "fam-c"]]), [B, C])
	var bad: PackedByteArray = C["bytes"].duplicate()
	bad[100] ^= 0x01
	t.corrupt_objects[_key(C)] = bad
	app.content.enabled = true
	app.content.transport = t
	var r: Dictionary = await app.content.refresh()
	_ok(not r["ok"] and t.object_calls == [_key(B), _key(C)], "B fetched + verified, C failed (%s)" % r["reason"])
	var left := _tree(root).keys().filter(func(k): return not (k in ["staging/", "downloads/"]))
	_ok(left.is_empty(), "no candidate pack, registry, staging or .part remains (%s)" % str(left))
	_no_trace(root, "first install")
	_ok(not FileAccess.file_exists(root + RCM.REGISTRY_FILE) and app.content.remote_levels().is_empty(), "no registry; no remote levels")
	app.progression.debug_set_current_level(1)
	var l1 := GameplayLaunchResolver.resolve(app)
	app.progression.debug_set_current_level(10)
	_ok(l1["ok"] and String(l1["level_path"]).begins_with("res://") and GameplayLaunchResolver.resolve(app)["entry_id"] == "level_010_ice_cube", "builtin 1..10 gameplay still resolves")
	DirAccess.remove_absolute(save)
	_done["t2_multipack_failure_without_registry"] = true

func _t3() -> void:
	print("[t3 the exactly reused active pack A survives cleanup unchanged]")
	var root := _root("t3")
	var x := await _with_a(root)
	var m: RCM = x[0]
	var a_dir := m.install_dir(m.active_registry()["packs"][0])
	var a_tree := _tree(a_dir)
	var lvl: Dictionary = m.remote_levels()[0]
	var lvl_bytes := FileAccess.get_file_as_bytes(lvl["level_path"])
	var plan_bytes := FileAccess.get_file_as_bytes(lvl["supply_plan_path"])
	_serve_abc_broken_c(x[1], "hash")
	x[1].object_calls.clear()
	await m.refresh()
	_ok(not (_key(A) in x[1].object_calls), "A was reused (never re-downloaded)")
	_ok(_tree(a_dir) == a_tree and a_tree.size() > 3, "A dir: every file hash unchanged (%d entries)" % a_tree.size())
	_ok(FileAccess.get_file_as_bytes(lvl["level_path"]) == lvl_bytes and FileAccess.get_file_as_bytes(lvl["supply_plan_path"]) == plan_bytes, "A level + supply plan bytes unchanged")
	_done["t3_reused_pack_survives"] = true

func _t4() -> void:
	print("[t4 a valid retry activates once; no redundant download, no ghost dirs]")
	var root := _root("t4")
	var x := await _with_a(root)
	var m: RCM = x[0]
	var t = x[1]
	_serve_abc_broken_c(t, "hash")
	await m.refresh()
	t.corrupt_objects.clear()
	t.object_calls.clear()
	var changed := [0]
	m.content_changed.connect(func(): changed[0] += 1)
	var r: Dictionary = await m.refresh()
	_ok(r["ok"] and r["reason"] == "ACTIVATED" and changed[0] == 1 and _ids(m) == ["fam_l011", "fam_l012", "fam_l013"], "retry activated exactly once")
	_ok(t.object_calls == [_key(B), _key(C)], "only the missing B and C fetched; A reused (%s)" % str(t.object_calls))
	var pack_dirs: Array = []
	for pid in DirAccess.get_directories_at(root + "packs/"):
		for v in DirAccess.get_directories_at(root + "packs/" + pid):
			pack_dirs.append(root + "packs/%s/%s/" % [pid, v])
	pack_dirs.sort()
	var want: Array = m.active_registry()["packs"].map(func(p): return m.install_dir(p))
	want.sort()
	_ok(pack_dirs == want, "packs/ holds exactly the three active pack dirs")
	_ok(not DirAccess.dir_exists_absolute(root + "staging/") or DirAccess.get_directories_at(root + "staging/").is_empty(), "no staging residue after success")
	r = await m.refresh()
	_ok(r["reason"] == "UP_TO_DATE" and t.object_calls.size() == 2 and changed[0] == 1, "a further refresh is a no-op")
	_done["t4_valid_retry_activates_once"] = true

func _t5() -> void:
	print("[t5 candidate verification / registry write / rename / post-activate failures roll back immediately]")
	for fault in ["verify_candidate", "registry_write", "registry_rename", "post_activate_verify"]:
		var root := _root("t5")
		var x := await _with_a(root)
		var m: RCM = x[0]
		var t = x[1]
		var before := _tree(root)
		var reg := FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE)
		t.set_manifest(F.manifest(2, [A, B, C], LV_ABC), [A, B, C])
		m._fault = fault
		var r: Dictionary = await m.refresh()
		m._fault = ""
		_ok(not r["ok"], "%s -> refused (%s)" % [fault, r["reason"]])
		_ok(FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE) == reg and _ids(m) == ["fam_l011"] and m.status()["content_version"] == 1, "%s: previous registry byte-identical and active" % fault)
		_ok(_tree(root) == before, "%s: WHOLE content root byte-identical (B/C final paths removed at once, no registry/prev change)" % fault)
		_no_trace(root, fault)
	print("  [repair variant: a broken active pack of the same identity is moved aside, then restored]")
	var root := _root("t5r")
	var x := await _with_a(root)
	var m: RCM = x[0]
	var lp: String = m.remote_levels()[0]["level_path"]
	DirAccess.remove_absolute(lp)
	m = _mgr(root, x[1])
	var broken := _tree(root)
	m._fault = "registry_rename"
	var r: Dictionary = await m.refresh()
	m._fault = ""
	var got := _tree(root)
	_ok(not r["ok"] and got == broken, "failed repair restores the displaced dir exactly as it was (%s)" % str(r["reason"]) + ("" if got == broken else " diff +%s -%s" % [str(got.keys().filter(func(k): return not broken.has(k) or broken[k] != got[k])), str(broken.keys().filter(func(k): return not got.has(k)))]))
	r = await m.refresh()
	_ok(r["ok"] and _ids(m) == ["fam_l011"] and FileAccess.file_exists(lp), "repair without fault succeeds")
	_done["t5_verify_and_registry_failures_roll_back"] = true

func _t6() -> void:
	print("[t6 cold boot after an interrupted commit keeps the LKG and drops unverified orphans]")
	var root := _root("t6")
	var x := await _with_a(root)
	var reg := FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE)
	var a_tree := _tree(x[0].install_dir(x[0].active_registry()["packs"][0]))
	# Crash between pack placement and the registry swap: a placed-but-unregistered pack,
	# a staged pack, a displaced dir, a half-written registry tmp and a .part.
	var orphan := root + "packs/fam-b/1-%s/levels/fam_l012/" % ContentManifestV1.sha256_hex(B["bytes"])
	DirAccess.make_dir_recursive_absolute(orphan)
	for f in ["level.json", "supply-plan.json", "metadata.json"]:
		var w := FileAccess.open(orphan + f, FileAccess.WRITE); w.store_string("{\"unverified\":true}"); w.close()
	DirAccess.make_dir_recursive_absolute(root + "staging/123_4/p0/levels/fam_l013/")
	DirAccess.make_dir_recursive_absolute(root + "staging/123_4/displaced0/levels/x/")
	DirAccess.make_dir_recursive_absolute(root + "downloads/")
	var w2 := FileAccess.open(root + "downloads/123_4.part", FileAccess.WRITE); w2.store_string("PK"); w2.close()
	var w3 := FileAccess.open(root + RCM.REGISTRY_TMP, FileAccess.WRITE); w3.store_string("{\"schema\":"); w3.close()
	var m := _mgr(root, null)
	_ok(FileAccess.get_file_as_bytes(root + RCM.REGISTRY_FILE) == reg and _ids(m) == ["fam_l011"], "LKG registry byte-identical and active after cold boot")
	_ok(_tree(m.install_dir(m.active_registry()["packs"][0])) == a_tree, "LKG pack A unchanged")
	_ok(not DirAccess.dir_exists_absolute(root + "packs/fam-b/"), "orphan (placed, never registered) pack removed, never exposed")
	_no_trace(root, "cold boot")
	_ok(not ("fam_l012" in _ids(m)), "no unverified payload accepted")
	_done["t6_cold_boot_after_interruption"] = true
