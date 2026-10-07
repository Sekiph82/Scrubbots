extends SceneTree
## Writes the deterministic CP04/CP05 family fixture (manifest + .scrubpack bytes) to a
## directory so the Level Factory's own Python contract code can cross-check the exact
## bytes the game runtime accepts (parse_content_manifest_v1 / inspect_scrubpack).
##   godot --headless --path . -s res://tests/tools/export_remote_content_fixture.gd -- <abs_out_dir>

const F = preload("res://tests/support/scrubpack_fixture.gd")

func _initialize() -> void:
	var out: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out)
	var packs := [
		{"pack_id": "fam-a", "spec": {"family_level_011": "level_005_party_toucan", "family_level_012": "level_006_chicken"}},
		{"pack_id": "fam-b", "spec": {"family_level_013": "level_007_pigeon"}},
	]
	var built: Array = []
	var levels: Array = []
	for p in packs:
		var lv := {}
		for id in p["spec"]:
			lv[id] = F.level_files(id, p["spec"][id])
			levels.append([id, p["pack_id"]])
		var b := F.build_pack(p["pack_id"], 1, lv)
		built.append({"pack_id": p["pack_id"], "pack_version": 1, "bytes": b})
		var f := FileAccess.open(out.path_join("%s-v1.scrubpack" % p["pack_id"]), FileAccess.WRITE)
		f.store_buffer(b)
		f.close()
	var m := F.manifest(2, built, levels)
	var mf := FileAccess.open(out.path_join("manifest.json"), FileAccess.WRITE)
	mf.store_string(JSON.stringify(m, "", true))
	mf.close()
	print("exported %d packs + manifest to %s" % [built.size(), out])
	quit()
