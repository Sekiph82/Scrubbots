extends SceneTree
## CP04 + CP05 end-to-end family fixture (local, deterministic; NOT the owner's real 11-50).
##   builtin Levels 1-10 stay in res://;
##   manifest N   : synthetic pack fam-a = remote Levels 11-12 -> downloaded + activated;
##   frontier 11  : resolves remote Level 11 and the REAL ProductionGameplayHost loads it;
##   relaunch     : offline AppState still resolves 11 from the cached LKG;
##   manifest N+1 : appends Level 13 (pack fam-b) -> only fam-b is downloaded;
##   manifest N+2 : malicious / corrupt -> rejected, N+1 stays active and playable.
##
## Run: godot --headless --path . -s res://tests/remote_content_family_fixture.gd

const F = preload("res://tests/support/scrubpack_fixture.gd")
const RCM = preload("res://scripts/content_runtime/remote_content_manager.gd")
const ContentManifestV1 = preload("res://scripts/content_runtime/content_manifest_v1.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")

var _fail := 0
var _save := ""
var _content := ""

func _initialize() -> void:
	await process_frame
	ProjectSettings.set_setting("application/config/version", "1.0.0")
	_save = "user://family_fixture_%d.save" % Time.get_ticks_usec()
	_content = _save.get_basename() + "_content/"
	await _run()
	_rm(_content)
	DirAccess.remove_absolute(_save)
	ProjectSettings.set_setting("application/config/version", null)
	print("Remote content family fixture evidence: %s (%d fail)" % ["PASS" if _fail == 0 else "FAIL", _fail])
	quit(0 if _fail == 0 else 1)

func _ok(c: bool, msg: String) -> void:
	if c:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _rm(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + f)
	for d in DirAccess.get_directories_at(dir):
		_rm(dir + d + "/")
	DirAccess.remove_absolute(dir)

func _pack(pack_id: String, spec: Dictionary, mutate: Callable = Callable()) -> Dictionary:
	var lv := {}
	for id in spec:
		lv[id] = F.level_files(id, spec[id])
	return {"pack_id": pack_id, "pack_version": 1, "bytes": F.build_pack(pack_id, 1, lv, {}, mutate)}

func _resolve(app, n: int) -> Dictionary:
	app.progression.debug_set_current_level(n)
	return GameplayLaunchResolver.resolve(app)

func _run() -> void:
	print("[f01 builtin 1-10 in res://]")
	var cat := LevelCatalog.new()
	_ok(cat.load_manifest().ok and cat.size() == 10, "builtin production catalog = 10 levels")
	var builtin := cat.get_entries_ordered()
	_ok(builtin.map(func(e): return e.order) == range(1, 11) and builtin.all(func(e): return String(e.level_path).begins_with("res://")), "orders 1..10, all res://")

	var a := _pack("fam-a", {"family_level_011": "level_005_party_toucan", "family_level_012": "level_006_chicken"})
	var b := _pack("fam-b", {"family_level_013": "level_007_pigeon"})
	var t := F.FakeTransport.new()
	t.set_manifest(F.manifest(1, [a], [["family_level_011", "fam-a"], ["family_level_012", "fam-a"]]), [a])

	print("[f02 manifest N=1: remote 11-12 downloaded, verified, activated]")
	var app = AppState.new(_save)
	_ok(app.content.root == _content and app.content.remote_levels().is_empty(), "isolated content root, nothing cached yet")
	app.content.enabled = true
	app.content.transport = t
	var r: Dictionary = await app.content.refresh()
	_ok(r["ok"] and r["reason"] == "ACTIVATED" and app.content.status()["status"] == RCM.UPDATED, "N=1 activated")
	_ok(_resolve(app, 10)["entry_id"] == "level_010_ice_cube", "frontier 10 -> builtin")
	var l11 := _resolve(app, 11)
	_ok(l11["ok"] and l11["entry_id"] == "family_level_011" and String(l11["level_path"]).begins_with(_content), "frontier 11 -> remote family_level_011 (user:// content root)")
	_ok(_resolve(app, 12)["entry_id"] == "family_level_012", "frontier 12 -> remote family_level_012")

	print("[f03 the production gameplay host plays the exact remote LevelData + supply plan]")
	app.progression.debug_set_current_level(11)
	var host = await _host(app)
	if host != null:
		var lvl = host.get_level()
		var plan := SupplyPlanLoader.load_engine(host.supply_plan_path, lvl)
		var reg_lv: Dictionary = app.content.active_registry()["levels"][0]
		_ok(lvl.id == "family_level_011" and host.launch_entry_id == "family_level_011" and host.progression_level == 11, "host built level 11 from family_level_011")
		_ok(host.supply_plan_path == l11["supply_plan_path"] and plan["ok"]
			and ContentManifestV1.sha256_hex(FileAccess.get_file_as_bytes(l11["level_path"])) == reg_lv["sha256"]["level"]
			and ContentManifestV1.sha256_hex(FileAccess.get_file_as_bytes(host.supply_plan_path)) == reg_lv["sha256"]["supply_plan"],
			"host loaded the registry-verified remote level + supply plan bytes")
		_ok(host.get_supply().player_snapshot() == plan["engine"].player_snapshot(), "live supply = exact remote plan engine")
		host.get_parent().queue_free()

	print("[f04 relaunch offline: cached LKG still resolves 11]")
	var off := F.FakeTransport.new()
	off.offline = true
	var app2 = AppState.new(_save)
	app2.content.enabled = true
	app2.content.transport = off
	# (frontier set through the test seam: the progression import rightly refuses a debug-jumped
	# frontier without its first-clears; this step is about content, not progression.)
	_ok(app2.content.is_active_usable() and _resolve(app2, 11)["entry_id"] == "family_level_011", "cold offline boot: frontier 11 -> family_level_011 from the cached LKG")
	r = await app2.content.refresh()
	_ok(not r["ok"] and app2.content.status()["status"] == RCM.OFFLINE_USING_CACHE and GameplayLaunchResolver.resolve(app2)["entry_id"] == "family_level_011", "offline refresh: still playable from cache")

	print("[f05 manifest N+1=2 appends 13; only the new pack downloads]")
	t.set_manifest(F.manifest(2, [a, b], [["family_level_011", "fam-a"], ["family_level_012", "fam-a"], ["family_level_013", "fam-b"]]), [a, b])
	t.object_calls.clear()
	app2.content.transport = t
	r = await app2.content.refresh()
	_ok(r["ok"] and t.object_calls == ["packs/fam-b/fam-b-v1.scrubpack"], "only fam-b downloaded (%s)" % str(t.object_calls))
	_ok(_resolve(app2, 11)["entry_id"] == "family_level_011" and _resolve(app2, 13)["entry_id"] == "family_level_013", "11 unchanged, 13 -> family_level_013")
	var reg2 := FileAccess.get_file_as_bytes(_content + RCM.REGISTRY_FILE)

	print("[f06 manifest N+2 malicious / corrupt -> rejected; N+1 stays active]")
	var c := _pack("fam-c", {"family_level_014": "level_008_butterfly"})
	var man3 := F.manifest(3, [a, b, c], [["family_level_011", "fam-a"], ["family_level_012", "fam-a"], ["family_level_013", "fam-b"], ["family_level_014", "fam-c"]])
	t.set_manifest(man3, [a, b, c])
	var tampered: PackedByteArray = c["bytes"].duplicate()
	tampered[200] ^= 0x01
	t.corrupt_objects["packs/fam-c/fam-c-v1.scrubpack"] = tampered
	r = await app2.content.refresh()
	_ok(not r["ok"] and r["reason"] == "PACK_SHA256_MISMATCH", "tampered pack rejected (%s)" % r["reason"])
	# A compromised publisher signing a hostile archive: hashes match, layout does not.
	var evil := _pack("fam-c", {"family_level_014": "level_008_butterfly"}, func(e): return e + [["levels/family_level_014/run.gd", "extends Node".to_utf8_buffer()]])
	t.corrupt_objects.clear()
	t.set_manifest(F.manifest(3, [a, b, evil], [["family_level_011", "fam-a"], ["family_level_012", "fam-a"], ["family_level_013", "fam-b"], ["family_level_014", "fam-c"]]), [a, b, evil])
	r = await app2.content.refresh()
	_ok(not r["ok"] and r["reason"] == "INVALID_MEMBER_LAYOUT", "script member in a correctly hashed pack rejected (%s)" % r["reason"])
	_ok(FileAccess.get_file_as_bytes(_content + RCM.REGISTRY_FILE) == reg2 and app2.content.status()["content_version"] == 2, "N+1 registry byte-identical and active")
	_ok(_resolve(app2, 13)["entry_id"] == "family_level_013" and _resolve(app2, 14)["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "13 still playable; 14 truthfully CONTENT_MISSING")
	_ok(not DirAccess.dir_exists_absolute(_content + "packs/fam-c/"), "nothing of the rejected candidate installed")
	var app3 = AppState.new(_save)
	_ok(app3.content.remote_levels().map(func(l): return l["id"]) == ["family_level_011", "family_level_012", "family_level_013"], "relaunch after the failed N+2: N+1 set reconstructed")

func _host(app):
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.app_state = app
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "ProductionGameplayHost.build() for remote level 11 (%s)" % host.get_build_error())
	return host if ok else null
