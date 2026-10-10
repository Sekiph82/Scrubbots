extends SceneTree
## CP06 (SB-CP06-004 / SB-CP06-010) — disabled remote levels, owner option B
## (coordination/sessions/CP06-GAME-DISABLED-LEVELS-C001/OWNER_DISABLED_FRONTIER_DECISION_V02.md):
## a verified ACTIVE manifest that disables the player's remote frontier is skipped without a
## win: frontier N -> N+1 (still labelled N+1), versioned skip ledger with provenance, zero
## economy / streak / reward mutation, durable-first with exact rollback on save failure.
##
## p* cases are in-memory (progression / save validation / manifest / registry parsing).
## i* cases are integration: AppState + FakeTransport + synthetic packs under isolated
## user://cp06_* roots (removed at the end). Deterministic, no network, no live R2.
##
## OWNER ZERO-TEMP RULE (2026-10-10): this suite writes under user:// (outside the Desktop
## checkout) and Godot itself writes user://logs, so it was NOT executed on the owner's PC.
## Run only in an owner-approved environment:
##   godot --headless --path . -s res://tests/cp06_disabled_levels.gd

const F = preload("res://tests/support/scrubpack_fixture.gd")
const ContentManifestV1 = preload("res://scripts/content_runtime/content_manifest_v1.gd")
const RCM = preload("res://scripts/content_runtime/remote_content_manager.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const GameplayLaunchResolver = preload("res://scripts/app/gameplay_launch_resolver.gd")

const SHA_A := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const L3 := [["fam_l011", "fam-a"], ["fam_l012", "fam-a"], ["fam_l013", "fam-a"]]

var EXPECTED := ["p01_record_skip_rules", "p02_progression_import_matrix", "p03_save_versioning",
	"p04_manifest_disabled_subset", "p05_registry_v1_v2", "i01_frontier12_skips_to13_no_rewards",
	"i02_win_into_disabled_then_skip", "i03_two_consecutive_disabled", "i04_last_level_disabled_content_missing",
	"i05_reenable_history_and_fresh_player", "i06_cold_offline_boot_idempotent", "i07_save_failure_rollback",
	"i08_builtin_and_unknown_ids_rejected", "i09_unusable_content_never_skips", "i10_stale_and_mutated_manifest",
	"i11_v2_save_roundtrip_and_old_reader_guard"]

var _fail := 0
var _done := {}
var _roots: Array = []
var _files: Array = []
var _builtin_ids: Array = []
var _pack3: Dictionary

func _initialize() -> void:
	await process_frame
	var cat := LevelCatalog.new()
	cat.load_manifest()
	for e in cat.get_entries_ordered():
		_builtin_ids.append(e.id)
	_pack3 = {"pack_id": "fam-a", "pack_version": 1, "bytes": F.build_pack("fam-a", 1, {
		"fam_l011": F.level_files("fam_l011", "level_002_apple"),
		"fam_l012": F.level_files("fam_l012", "level_003_palm_tree"),
		"fam_l013": F.level_files("fam_l013", "level_004_orange_cat")})}
	_p01(); _p02(); _p03(); _p04(); _p05()
	await _i01(); await _i02(); await _i03(); await _i04(); await _i05(); await _i06()
	await _i07(); await _i08(); await _i09(); await _i10(); await _i11()
	for f in _files:
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(f + suffix)
	for r in _roots:
		_rm(r)
	ProjectSettings.set_setting("application/config/version", null)
	var missing := EXPECTED.filter(func(c): return not _done.has(c))
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: cases not completed: %s" % str(missing))
	print("CP06 disabled levels evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _done.size(), EXPECTED.size(), _fail])
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

func _rm(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir + f)
	for d in DirAccess.get_directories_at(dir):
		_rm(dir + d + "/")
	DirAccess.remove_absolute(dir)

func _v1(cur: int) -> Dictionary:
	return {"schema": LevelProgressionService.SNAPSHOT_SCHEMA, "current_level": cur, "completed": range(1, cur)}

func _rec(n: int, id: String, cv := 2, sha := SHA_A) -> Dictionary:
	return {"level_number": n, "level_id": id, "content_version": cv, "manifest_sha256": sha}

func _save_service(prog) -> SaveService:
	return SaveService.new("user://cp06_unused.save", AudioSettingsService.new(), HapticsSettingsService.new(), prog, EconomyServices.new())

## Fresh AppState on an isolated save + content root, with a legitimate history up to
## `frontier` (canonical import + save, never the debug seam).
func _app(tag: String, frontier: int, save := "") -> Array:
	ProjectSettings.set_setting("application/config/version", "1.0.0")
	if save.is_empty():
		save = "user://cp06_%s_%d.save" % [tag, Time.get_ticks_usec()]
		_files.append(save)
		_roots.append(save.get_basename() + "_content/")
	var app = AppState.new(save)
	var t := F.FakeTransport.new()
	app.content.enabled = true
	app.content.transport = t
	if frontier > 0:
		_ok(app.progression.import_snapshot(_v1(frontier)) and bool(app.request_save().get("ok", false)), "%s: legitimate history 1..%d saved" % [tag, frontier - 1])
	return [app, t, save]

func _publish(app, t, cv: int, disabled: Array, levels: Array = L3) -> Dictionary:
	t.set_manifest(F.manifest(cv, [_pack3], levels, "0.0.0", {"disabled_levels": disabled}), [_pack3])
	return await app.content.refresh()

func _orders(app) -> Dictionary:
	var out := {}
	for e in app.playable_catalog().get_entries_ordered():
		out[int(e.order)] = String(e.id)
	return out

# ------------------------------------------------------------ pure cases --

func _p01() -> void:
	print("[p01 record_skip: exact frontier only, strict provenance, never a first-clear]")
	var p := LevelProgressionService.new()
	p.import_snapshot(_v1(12))
	_ok(not p.record_skip(11, "fam_l011", 2, SHA_A) and not p.record_skip(13, "fam_l013", 2, SHA_A), "stale / future level refused")
	_ok(not p.record_skip(12, "", 2, SHA_A) and not p.record_skip(12, "bad id!", 2, SHA_A), "malformed level id refused")
	_ok(not p.record_skip(12, "fam_l012", 0, SHA_A) and not p.record_skip(12, "fam_l012", 2, "ABC"), "bad content_version / sha refused")
	_ok(p.current_level() == 12 and p.skipped_records().is_empty(), "refusals mutate nothing")
	_ok(p.record_skip(12, "fam_l012", 2, SHA_A), "exact frontier skip accepted")
	_ok(p.current_level() == 13 and p.completed_count() == 11 and not p.is_completed(12) and p.is_skipped(12), "frontier 13; 12 skipped, NOT completed; completed_count stays 11")
	_ok(not p.record_skip(12, "fam_l012", 2, SHA_A), "duplicate skip refused")
	_ok(not p.record_win(12), "record_win on a skipped level refused (no spoofed first-clear)")
	_ok(not p.record_skip(13, "FAM_L012", 2, SHA_A), "same level identity (casefold) cannot be skipped at a second order")
	var s := p.snapshot()
	_ok(s["schema"] == LevelProgressionService.SNAPSHOT_SCHEMA_V2 and s["skipped"] == [_rec(12, "fam_l012")], "snapshot v2 carries the exact provenance record")
	var q := LevelProgressionService.new()
	_ok(q.import_snapshot(JSON.parse_string(JSON.stringify(s))) and q.snapshot() == s, "v2 JSON round-trip is exact")
	var plain := LevelProgressionService.new()
	plain.import_snapshot(_v1(5))
	_ok(plain.snapshot().keys().size() == 3 and plain.snapshot()["schema"] == LevelProgressionService.SNAPSHOT_SCHEMA, "no skips -> unchanged v1 snapshot shape")
	_case("p01_record_skip_rules")

func _p02() -> void:
	print("[p02 progression import: completed ∪ skipped == 1..cur-1, disjoint, strict, fail closed]")
	var V2 := LevelProgressionService.SNAPSHOT_SCHEMA_V2
	var good := {"schema": V2, "current_level": 14, "completed": range(1, 12) + [13], "skipped": [_rec(12, "fam_l012")]}
	var p := LevelProgressionService.new()
	_ok(p.import_snapshot(good) and p.current_level() == 14 and p.is_skipped(12) and p.is_completed(13), "valid v2 (skip 12, win 13) imports")
	_ok(LevelProgressionService.new().import_snapshot(_v1(12)), "legacy v1 imports with an empty skip ledger")
	var bad := {
		"overlap": {"schema": V2, "current_level": 13, "completed": range(1, 13), "skipped": [_rec(12, "fam_l012")]},
		"gap": {"schema": V2, "current_level": 14, "completed": range(1, 12), "skipped": [_rec(12, "fam_l012")]},
		"future skip": {"schema": V2, "current_level": 13, "completed": range(1, 12), "skipped": [_rec(13, "fam_l013")]},
		"dup number": {"schema": V2, "current_level": 13, "completed": range(1, 12), "skipped": [_rec(12, "fam_l012"), _rec(12, "fam_l012")]},
		"dup id casefold": {"schema": V2, "current_level": 14, "completed": range(1, 12), "skipped": [_rec(12, "fam_l012"), _rec(13, "FAM_L012")]},
		"extra field": {"schema": V2, "current_level": 13, "completed": range(1, 12), "skipped": [_rec(12, "fam_l012").merged({"x": 1})]},
		"missing field": {"schema": V2, "current_level": 13, "completed": range(1, 12), "skipped": [{"level_number": 12, "level_id": "fam_l012", "content_version": 2}]},
		"fractional number": {"schema": V2, "current_level": 13, "completed": range(1, 12), "skipped": [_rec(12, "fam_l012").merged({"level_number": 12.5}, true)]},
		"string number": {"schema": V2, "current_level": 13, "completed": range(1, 12), "skipped": [_rec(12, "fam_l012").merged({"level_number": "12"}, true)]},
		"bad sha": {"schema": V2, "current_level": 13, "completed": range(1, 12), "skipped": [_rec(12, "fam_l012", 2, "zz")]},
		"cv zero": {"schema": V2, "current_level": 13, "completed": range(1, 12), "skipped": [_rec(12, "fam_l012", 0)]},
		"skipped not array": {"schema": V2, "current_level": 13, "completed": range(1, 12), "skipped": {}},
		"skipped missing": {"schema": V2, "current_level": 12, "completed": range(1, 12)},
		"v1 still contiguous": {"schema": LevelProgressionService.SNAPSHOT_SCHEMA, "current_level": 13, "completed": range(1, 12)},
		"future schema": {"schema": "scrubbots.progression.v3", "current_level": 1, "completed": []},
	}
	for k in bad:
		var live := LevelProgressionService.new()
		live.import_snapshot(good)
		var before := live.snapshot()
		_ok(not live.import_snapshot(bad[k]) and live.snapshot() == before, "%s -> rejected, live state untouched" % k)
	_case("p02_progression_import_matrix")

func _p03() -> void:
	print("[p03 save: lowest representing version; v2 progression requires save v2]")
	var p := LevelProgressionService.new()
	p.import_snapshot(_v1(12))
	var svc := _save_service(p)
	var c1 := svc.collect()
	_ok(c1["version"] == 1 and c1["progression"]["schema"] == LevelProgressionService.SNAPSHOT_SCHEMA and svc.validate_candidate(c1)["ok"], "no skips -> save version 1 (pre-CP06 readers unaffected)")
	p.record_skip(12, "fam_l012", 2, SHA_A)
	var c2 := svc.collect()
	_ok(c2["version"] == 2 and c2["progression"]["schema"] == LevelProgressionService.SNAPSHOT_SCHEMA_V2 and svc.validate_candidate(c2)["ok"], "skips -> save version 2, valid")
	var forged := c2.duplicate(true)
	forged["version"] = 1
	_ok(svc.validate_candidate(svc.migrate(forged))["reason"] == "progression_schema_version_mismatch", "v1 save carrying a v2 skip ledger rejected")
	var fut := c2.duplicate(true)
	fut["version"] = 3
	_ok(svc.validate_candidate(fut)["reason"] == "future_schema", "version 3 -> future_schema (fail closed)")
	var legacy := c1.duplicate(true)
	_ok(svc.migrate(legacy)["version"] == 1 and svc.validate_candidate(legacy)["ok"], "legacy v1 save is not rewritten by migrate and still validates")
	var zero := {"schema": "scrubbots.save", "version": 0}
	_ok(svc.migrate(zero)["version"] == 1 and svc.validate_candidate(zero)["ok"], "pre-v1 save still migrates to the neutral v1 defaults")
	_case("p03_save_versioning")

func _p04() -> void:
	print("[p04 manifest: disabled IDs are exact declared level IDs]")
	var base := F.manifest(1, [_pack3], L3)
	var cases := {"undeclared": [["fam_l099"], "MANIFEST_DISABLED_LEVEL_NOT_DECLARED"],
		"case variant": [["FAM_L012"], "MANIFEST_DISABLED_LEVEL_NOT_DECLARED"],
		"builtin id": [[String(_builtin_ids[0])], "MANIFEST_DISABLED_LEVEL_NOT_DECLARED"],
		"duplicate": [["fam_l012", "fam_l012"], "MANIFEST_INVALID_DISABLED_LEVELS"],
		"casefold duplicate": [["fam_l012", "FAM_L012"], "MANIFEST_INVALID_DISABLED_LEVELS"],
		"not a string": [[12], "MANIFEST_INVALID_DISABLED_LEVELS"]}
	for k in cases:
		var m := base.duplicate(true)
		m["disabled_levels"] = cases[k][0]
		_ok(ContentManifestV1.parse(JSON.stringify(m).to_utf8_buffer())["reason"] == cases[k][1], "%s -> %s" % [k, cases[k][1]])
	var okm := base.duplicate(true)
	okm["disabled_levels"] = ["fam_l012", "fam_l013"]
	var r := ContentManifestV1.parse(JSON.stringify(okm).to_utf8_buffer())
	_ok(r["ok"] and r["manifest"]["disabled_levels"] == ["fam_l012", "fam_l013"] and r["manifest"]["levels"].size() == 3, "declared IDs accepted; levels untouched")
	_case("p04_manifest_disabled_subset")

func _p05() -> void:
	print("[p05 registry: v1 legacy readable; v2 = exact nonempty declared disabled set]")
	var lvl := {"level_id": "fam_l012", "pack_id": "fam-a", "difficulty": "EASY", "width": 20, "height": 20,
		"sha256": {"level": SHA_A, "metadata": SHA_A, "supply_plan": SHA_A}}
	var reg := {"schema": RCM.REGISTRY_SCHEMA, "version": 1, "content_version": 1, "manifest_sha256": SHA_A,
		"minimum_game_version": "0.0.0", "validated_game_version": "1.0.0",
		"packs": [{"pack_id": "fam-a", "pack_version": 1, "object_key": "packs/fam-a/fam-a-v1.scrubpack", "sha256": SHA_A, "byte_length": 10}],
		"levels": [lvl]}
	var enc := func(d): return JSON.stringify(d).to_utf8_buffer()
	_ok(RCM.parse_registry(enc.call(reg)) == reg, "legacy v1 registry (no disabled key) parses unchanged")
	var v2 := reg.duplicate(true)
	v2["version"] = 2
	v2["disabled_levels"] = ["fam_l012"]
	_ok(RCM.parse_registry(enc.call(v2)) == v2, "v2 registry with exact declared disabled id parses")
	var bad := {"v2 empty": [], "v2 unknown": ["fam_l099"], "v2 case": ["FAM_L012"], "v2 dup": ["fam_l012", "fam_l012"], "v2 non-string": [1]}
	for k in bad:
		var b := v2.duplicate(true)
		b["disabled_levels"] = bad[k]
		_ok(RCM.parse_registry(enc.call(b)).is_empty(), "%s -> registry rejected" % k)
	var v1x := reg.duplicate(true)
	v1x["disabled_levels"] = ["fam_l012"]
	_ok(RCM.parse_registry(enc.call(v1x)).is_empty(), "v1 registry with a disabled key -> rejected")
	var v2x := reg.duplicate(true)
	v2x["version"] = 2
	_ok(RCM.parse_registry(enc.call(v2x)).is_empty(), "v2 registry without disabled key -> rejected")
	var v3 := v2.duplicate(true)
	v3["version"] = 3
	_ok(RCM.parse_registry(enc.call(v3)).is_empty(), "registry version 3 -> rejected")
	_case("p05_registry_v1_v2")

# ------------------------------------------------------ integration cases --

func _i01() -> void:
	print("[i01 SB-CP06-010: remote 12 disabled at frontier 12 -> 13, identity stable, zero rewards]")
	var x := _app("i01", 12)
	var app = x[0]
	var t = x[1]
	var r1: Dictionary = await _publish(app, t, 1, [])
	_ok(r1["ok"] and app.progression.current_level() == 12, "v1 activated, frontier 12 untouched")
	var orders_before := _orders(app)
	var econ_before: Dictionary = app.economy.snapshot()
	var sb: int = app.economy.wallet.scrub_bucks()
	var r2: Dictionary = await _publish(app, t, 2, ["fam_l012"])
	var sha := String(app.content.active_registry()["manifest_sha256"])
	_ok(r2["ok"] and app.content.disabled_level_ids() == ["fam_l012"], "v2 disabling fam_l012 activated (pack bytes unchanged)")
	_ok(app.progression.current_level() == 13 and app.progression.skipped_records() == [_rec(12, "fam_l012", 2, sha)], "frontier 13; ledger {12, fam_l012, v2, manifest sha}")
	_ok(app.progression.completed_count() == 11 and not app.progression.is_completed(12), "no fake first-clear (completed_count 11)")
	_ok(app.economy.snapshot() == econ_before and app.economy.wallet.scrub_bucks() == sb, "economy snapshot (wallet, hearts, streak, Daily, gifts, cards, robots) unchanged")
	_ok(_orders(app) == orders_before and orders_before[11] == "fam_l011" and orders_before[12] == "fam_l012" and orders_before[13] == "fam_l013", "catalog orders/IDs 11/12/13 unchanged (no compaction)")
	var l := GameplayLaunchResolver.resolve(app)
	_ok(l["ok"] and l["level"] == 13 and l["entry_id"] == "fam_l013", "launch resolves Level 13 -> fam_l013 (labelled 13)")
	_ok(app.skip_notice == [12], "session notice names the real skipped number")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(x[2]))
	_ok(saved["version"] == 2 and saved["progression"]["current_level"] == 13 and saved["progression"]["skipped"].size() == 1, "skip durably saved as save v2")
	_ok(app.reconcile_disabled_frontier()["skipped"] == [] and app.progression.current_level() == 13, "second reconcile is a no-op")
	_case("i01_frontier12_skips_to13_no_rewards")

func _i02() -> void:
	print("[i02 disabled level ahead: no early skip; a real WON into it then skips]")
	var x := _app("i02", 11)
	var app = x[0]
	await _publish(app, x[1], 1, ["fam_l012"])
	_ok(app.progression.current_level() == 11 and app.progression.skipped_records().is_empty(), "frontier 11 not disabled -> nothing skipped")
	_ok(app.orders_context()["playable_ahead"] == 2, "Daily eligibility counts 11 and 13, not disabled 12")
	_ok(app.progression.record_win(11), "real win on 11 (the host's first-clear path)")
	var blocked := GameplayLaunchResolver.resolve(app)
	_ok(not blocked["ok"] and blocked["reason"] == GameplayLaunchResolver.LEVEL_DISABLED and blocked["level"] == 12, "before reconcile Level 12 resolves LEVEL_DISABLED, never launches")
	var r: Dictionary = app.reconcile_disabled_frontier()
	_ok(r["ok"] and r["skipped"] == [12] and app.progression.current_level() == 13 and app.progression.completed_count() == 11, "terminal reconcile skips 12 -> 13 (only 11 counted as a win)")
	_case("i02_win_into_disabled_then_skip")

func _i03() -> void:
	print("[i03 two consecutive disabled remote levels: bounded one-at-a-time]")
	var x := _app("i03", 11)
	var app = x[0]
	var r: Dictionary = await _publish(app, x[1], 1, ["fam_l012", "fam_l013"])
	_ok(r["ok"] and app.progression.current_level() == 11, "frontier 11 enabled: no skip")
	app.progression.record_win(11)
	var rr: Dictionary = app.reconcile_disabled_frontier()
	var recs: Array = app.progression.skipped_records()
	_ok(rr["skipped"] == [12, 13] and app.progression.current_level() == 14 and recs.size() == 2 and recs[0]["level_id"] == "fam_l012" and recs[1]["level_id"] == "fam_l013",
		"12 then 13 skipped one number at a time -> frontier 14")
	var l := GameplayLaunchResolver.resolve(app)
	_ok(not l["ok"] and l["reason"] == GameplayLaunchResolver.CONTENT_MISSING and l["level"] == 14, "stops at the real next frontier 14 (CONTENT_MISSING), no jump")
	_case("i03_two_consecutive_disabled")

func _i04() -> void:
	print("[i04 last remote level disabled: skip lands on CONTENT_MISSING, never fabricated]")
	var x := _app("i04", 13)
	var app = x[0]
	await _publish(app, x[1], 1, ["fam_l013"])
	_ok(app.progression.current_level() == 14 and app.progression.skipped_records().size() == 1, "13 skipped -> 14")
	var l := GameplayLaunchResolver.resolve(app)
	_ok(not l["ok"] and l["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "Level 14 honestly CONTENT_MISSING")
	_case("i04_last_level_disabled_content_missing")

func _i05() -> void:
	print("[i05 re-enable: skipped history kept, no rewind/payout; fresh player can play it]")
	var x := _app("i05", 12)
	var app = x[0]
	await _publish(app, x[1], 1, [])
	await _publish(app, x[1], 2, ["fam_l012"])
	var econ: Dictionary = app.economy.snapshot()
	var r: Dictionary = await _publish(app, x[1], 3, [])
	_ok(r["ok"] and app.content.disabled_level_ids().is_empty(), "v3 re-enable activated (registry back to v1 shape)")
	_ok(app.progression.current_level() == 13 and app.progression.is_skipped(12) and not app.progression.is_completed(12) and app.economy.snapshot() == econ, "skipped player: frontier 13, 12 stays skipped, no payout")
	var y := _app("i05b", 12)
	var fresh = y[0]
	await _publish(fresh, y[1], 1, [])
	await _publish(fresh, y[1], 2, ["fam_l012"])
	_ok(fresh.progression.current_level() == 13, "second player at 12 also skipped under v2")
	var z := _app("i05c", 11)
	var early = z[0]
	await _publish(early, z[1], 1, [])
	await _publish(early, z[1], 2, ["fam_l012"])
	await _publish(early, z[1], 3, [])
	early.progression.record_win(11)
	early.reconcile_disabled_frontier()
	var l := GameplayLaunchResolver.resolve(early)
	_ok(l["ok"] and l["level"] == 12 and l["entry_id"] == "fam_l012" and early.progression.skipped_records().is_empty(), "player who had not reached 12 plays re-enabled fam_l012")
	_case("i05_reenable_history_and_fresh_player")

func _i06() -> void:
	print("[i06 cold offline boot: cached v2 disabled set applied, idempotent across relaunch]")
	var x := _app("i06", 12)
	var app = x[0]
	var save: String = x[2]
	var root: String = app.content.root
	# Crash window: content activated by another manager instance on the same root, before
	# the app could save the skip.
	var t := F.FakeTransport.new()
	var m := RCM.new(root, "1.0.0", func(): return _builtin_ids)
	m.enabled = true
	m.transport = t
	m.boot()
	t.set_manifest(F.manifest(2, [_pack3], L3, "0.0.0", {"disabled_levels": ["fam_l012"]}), [_pack3])
	var r: Dictionary = await m.refresh()
	_ok(r["ok"] and JSON.parse_string(FileAccess.get_file_as_string(save))["progression"]["current_level"] == 12, "registry v2 active on disk; save still at 12")
	var boot2 = AppState.new(save)   # no transport: offline cold boot
	_ok(boot2.progression.current_level() == 13 and boot2.progression.skipped_records().size() == 1, "offline boot applies cached disabled set -> 13")
	var boot3 = AppState.new(save)
	_ok(boot3.progression.current_level() == 13 and boot3.progression.skipped_records().size() == 1, "relaunch: no further skip (idempotent)")
	_case("i06_cold_offline_boot_idempotent")

func _i07() -> void:
	print("[i07 skip save failure: exact rollback, LEVEL_DISABLED, retry later succeeds]")
	var x := _app("i07", 12)
	var app = x[0]
	await _publish(app, x[1], 1, [])
	var pre: Dictionary = app.progression.snapshot()
	var bytes := FileAccess.get_file_as_bytes(x[2])
	app.save.set_fault_injector(func(stage): return stage == "temp_write")
	await _publish(app, x[1], 2, ["fam_l012"])
	_ok(app.progression.snapshot() == pre and FileAccess.get_file_as_bytes(x[2]) == bytes and app.skip_notice.is_empty(), "failed save: progression + save bytes exactly as before, no notice")
	_ok(GameplayLaunchResolver.resolve(app)["reason"] == GameplayLaunchResolver.LEVEL_DISABLED, "disabled 12 still never launches")
	app.save.set_fault_injector(Callable())
	var r: Dictionary = app.reconcile_disabled_frontier()
	_ok(r["ok"] and r["skipped"] == [12] and app.progression.current_level() == 13, "retry after fault cleared: one skip")
	_case("i07_save_failure_rollback")

func _i08() -> void:
	print("[i08 builtin / unknown / case-variant disabled IDs: whole manifest refused, LKG kept]")
	var x := _app("i08", 12)
	var app = x[0]
	await _publish(app, x[1], 1, [])
	for ids in [[String(_builtin_ids[0])], ["fam_l099"], ["FAM_L012"]]:
		var r: Dictionary = await _publish(app, x[1], 2, ids)
		_ok(not r["ok"] and r["reason"] == "MANIFEST_DISABLED_LEVEL_NOT_DECLARED" and app.content.status()["content_version"] == 1 and app.progression.current_level() == 12,
			"%s -> refused, v1 + frontier 12 kept" % str(ids))
	_case("i08_builtin_and_unknown_ids_rejected")

func _i09() -> void:
	print("[i09 missing / unverifiable content and offline never justify a skip]")
	var x := _app("i09", 12)
	var app = x[0]
	var t = x[1]
	t.offline = true
	await _publish(app, t, 1, ["fam_l012"])
	_ok(app.progression.current_level() == 12, "offline: no manifest -> no skip")
	t.offline = false
	t.corrupt_objects[F.manifest(1, [_pack3], L3)["packs"][0]["object_key"]] = PackedByteArray([1, 2, 3])
	var r: Dictionary = await _publish(app, t, 1, ["fam_l012"])
	_ok(not r["ok"] and app.progression.current_level() == 12, "tampered pack: refused, no skip (%s)" % r["reason"])
	t.corrupt_objects.clear()
	var z := _app("i09z", 11)
	var app2 = z[0]
	await _publish(app2, z[1], 1, ["fam_l012"])
	# Frontier reaches 12 and is saved WITHOUT a reconcile (crash window), then the verified
	# cache is damaged before the next cold boot: an unusable set exposes no disabled membership.
	app2.progression.record_win(11)
	_ok(bool(app2.request_save().get("ok", false)), "frontier 12 saved")
	var reg: Dictionary = app2.content.active_registry()
	var lvl: String = app2.content.level_dir(reg["packs"][0], "fam_l013") + "level.json"
	var f := FileAccess.open(lvl, FileAccess.WRITE)
	f.store_string("{}")
	f.close()
	var y := _app("i09b", 0, z[2])
	_ok(not y[0].content.is_active_usable() and y[0].content.disabled_level_ids().is_empty() and y[0].progression.current_level() == 12 and y[0].progression.skipped_records().is_empty(),
		"corrupt cache: set unusable, frontier stays 12, no skip")
	var l := GameplayLaunchResolver.resolve(y[0])
	_ok(not l["ok"] and l["reason"] == GameplayLaunchResolver.CONTENT_MISSING, "unusable content -> CONTENT_MISSING, never a skip")
	_case("i09_unusable_content_never_skips")

func _i10() -> void:
	print("[i10 stale / mutated successor manifests keep the active disabled state]")
	var x := _app("i10", 11)
	var app = x[0]
	await _publish(app, x[1], 2, ["fam_l012"])
	var r1: Dictionary = await _publish(app, x[1], 1, [])
	_ok(not r1["ok"] and r1["reason"] == "CONTENT_VERSION_NOT_INCREASED" and app.content.disabled_level_ids() == ["fam_l012"], "downgrade refused; still disabled")
	var r2: Dictionary = await _publish(app, x[1], 2, [])
	_ok(not r2["ok"] and r2["reason"] == "MANIFEST_MUTATION" and app.content.disabled_level_ids() == ["fam_l012"], "same-version re-enable mutation refused")
	var sched: Dictionary = await _publish(app, x[1], 3, [], L3)
	_ok(sched["ok"], "a proper v3 still activates")
	x[1].set_manifest(F.manifest(4, [_pack3], L3, "0.0.0", {"schedules": [{"target_kind": "level", "target_id": "fam_l013", "not_before": "2026-10-07T00:00:00Z"}]}), [_pack3])
	var r3: Dictionary = await app.content.refresh()
	_ok(not r3["ok"] and r3["reason"] == "UNSUPPORTED_RUNTIME_SEMANTICS", "nonempty schedules remain refused")
	_case("i10_stale_and_mutated_manifest")

func _i11() -> void:
	print("[i11 v2 save reload; future-version guard protects it from older readers]")
	var x := _app("i11", 12)
	var app = x[0]
	await _publish(app, x[1], 1, ["fam_l012"])
	var y := _app("i11b", 0, x[2])
	_ok(y[0].progression.current_level() == 13 and y[0].progression.skipped_records() == app.progression.skipped_records(), "v2 save reloads exactly")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(x[2]))
	_ok(int(saved["version"]) > SaveService.LEGACY_VERSION, "file version 2 > 1: a pre-CP06 build (VERSION 1) treats it as future_schema and never overwrites it")
	_case("i11_v2_save_roundtrip_and_old_reader_guard")
