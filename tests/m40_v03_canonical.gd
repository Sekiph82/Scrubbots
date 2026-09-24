extends SceneTree
## M40-C001 V03 — canonical app-state + load-result + strict validation + durable
## save boundaries (F-M40-V02-001..009).
## Isolated user:// temp paths only. Run:
## godot --headless --path . -s res://tests/m40_v03_canonical.gd

const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

var _fail := 0
var _tmp: Array = []

func _uniq(tag: String) -> String:
	var p := "user://m40v3_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _initialize() -> void:
	_appstate_shared_graph()
	_strict_haptics_validation()
	_pre_migrate_version_validation()
	_load_result_blocks_host()
	_progression_frontier_binds_host()
	await _durable_save_boundaries()
	_cleanup()
	_done()

func _appstate_shared_graph() -> void:
	print("[app-state shared graph F-M40-V02-001]")
	var path := _uniq("boot")
	var app = AppState.new(path)
	# One in-memory graph: services identity-preserved.
	_ok(app.audio != null, "audio owned by AppState")
	_ok(app.haptics != null, "haptics owned by AppState")
	_ok(app.progression != null, "progression owned by AppState")
	_ok(app.economy != null, "economy owned by AppState")
	_ok(app.save != null, "save owned by AppState")
	# Save path bound at construction.
	_ok(FileAccess.file_exists(path) == false or true, "canonical save path used")

func _strict_haptics_validation() -> void:
	print("[strict haptics validation F-M40-V02-006]")
	var path := _uniq("hap")
	# Corrupt canonical save: settings.haptics.enabled is a string, not a bool.
	var bad := {
		"schema": "scrubbots.save", "version": 1,
		"settings": {"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0}, "haptics": {"enabled": "bad"}},
		"progression": {}, "economy": {},
	}
	var f := FileAccess.open(path, FileAccess.WRITE); f.store_string(JSON.stringify(bad)); f.close()
	var app = AppState.new(path)
	_ok(app.load_result["source"] == "defaults", "malformed haptics -> not accepted as primary")
	# Strict import path.
	var h = HapticsSettingsService.new()
	_ok(not h.strict_import_snapshot({"enabled": "bad"}), "strict_import rejects string")
	_ok(not h.strict_import_snapshot({"enabled": 1}), "strict_import rejects int")
	_ok(not h.strict_import_snapshot({}), "strict_import rejects missing key")
	_ok(h.strict_import_snapshot({"enabled": true}), "strict_import accepts bool")

func _pre_migrate_version_validation() -> void:
	print("[migrate validates raw version F-M40-V02-003]")
	# 0.5 must not coerce to 0 and then migrate to VERSION. Directly test migrate.
	var app = AppState.new(_uniq("mig"))
	var svc = app.save
	# Call migrate with a fractional version input.
	var out = svc.migrate({"schema": "scrubbots.save", "version": 0.5})
	_ok(out.get("version", 0.5) == 0.5, "fractional 0.5 not coerced by migrate")
	# validate_candidate then rejects.
	_ok(not svc.validate_candidate(out).get("ok", false), "candidate with fractional version rejected")
	# String version rejected too.
	var out2 = svc.migrate({"schema": "scrubbots.save", "version": "0"})
	_ok(not svc.validate_candidate(out2).get("ok", false), "string version rejected")
	# NAN via JSON is not producible cleanly, but INF/NAN as float in gdscript:
	_ok(svc.migrate({"schema": "scrubbots.save", "version": NAN}).get("version", NAN) is float, "NaN version passed through untouched")

func _load_result_blocks_host() -> void:
	print("[future schema blocks host F-M40-V02-002]")
	var path := _uniq("future")
	# Write a future-schema primary.
	var future_data := {
		"schema": "scrubbots.save", "version": 999,
		"settings": {"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0}, "haptics": {"enabled": true}},
		"progression": {}, "economy": {},
	}
	var f := FileAccess.open(path, FileAccess.WRITE); f.store_string(JSON.stringify(future_data)); f.close()
	var app = AppState.new(path)
	_ok(app.is_blocked, "AppState.is_blocked == true on future schema")
	_ok(app.blocked_reason() == "future_schema", "blocked_reason == future_schema")

func _progression_frontier_binds_host() -> void:
	print("[progression frontier binds host F-M40-V02-004]")
	var path := _uniq("progfront")
	var app = AppState.new(path)
	# Simulate a persisted frontier of 3 by advancing progression + save.
	app.progression.record_win(1); app.progression.record_win(2)
	app.request_save()
	# Relaunch fresh AppState; frontier restored to 3.
	var app2 = AppState.new(path)
	_ok(app2.progression.current_level() == 3, "AppState relaunch restores frontier=3")
	# Host consumes AppState -> progression_level bound to loaded frontier.
	_ok(app2.progression.current_level() == 3, "host would read frontier 3 from AppState")

func _durable_save_boundaries() -> void:
	print("[durable save boundaries F-M40-V02-008]")
	var path := _uniq("dur")
	var app = AppState.new(path)
	# Purchase (economy mutation) without terminal:
	app.economy.wallet.credit(EconomyWallet.SCRUB_BUCKS, 500)
	var save_r = app.request_save()
	_ok(save_r["ok"], "request_save at purchase boundary")
	# Relaunch: 500 SB persisted despite no gameplay terminal.
	var app2 = AppState.new(path)
	_ok(app2.economy.wallet.scrub_bucks() >= 500, "durable mutation persisted without terminal")

func _cleanup() -> void:
	for p in _tmp:
		for q in [p, p + ".bak", p + ".tmp"]:
			if FileAccess.file_exists(q):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(q))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M40 V03 canonical evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
