extends SceneTree
## M55-C001 Step 0 — Heart regen authority drift guard (owner ruling
## coordination/OWNER_HEART_REGEN_INTERVAL_V01.md: 900 s / 15 min per Heart).
## Every ACTIVE Heart authority (runtime config, HeartService, Home full-state display,
## planning config, active docs) must agree on 900 s; the unrelated 30-minute paid 2x
## product must stay exactly as configured. Historical owner decision files are
## provenance and are not scanned.
## Run: godot --headless --path . -s res://tests/m55_heart_900_authority.gd

const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const HeartService = preload("res://scripts/economy/heart_service.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")

const CANON_SECONDS := 900

## Active (non-historical) text authorities that describe the Heart interval.
const ACTIVE_DOCS := [
	"res://README.md",
	"res://CLAUDE.md",
	"res://docs/01_GAMEPLAY_SPEC.md",
	"res://docs/02_TECH_ARCHITECTURE.md",
	"res://docs/06_TEST_STRATEGY.md",
	"res://docs/MASTER_UI_SYSTEM.md",
	"res://docs/15_PLAYER_EXPERIENCE_UI_ARCHITECTURE.md",
	"res://docs/16_FTUE_FEATURE_UNLOCK_AND_RETENTION_SURFACES.md",
	"res://scripts/economy/README.md",
]

var _fail := 0
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_runtime_config()
	_heart_service()
	_planning_config()
	_active_docs()
	_two_x_unchanged()
	await _home_full_state()
	_cleanup()
	print("M55 HEART 900 AUTHORITY: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _runtime_config() -> void:
	print("[runtime config]")
	var raw: Dictionary = _json("res://data/config/economy_rewards_v1.json")["hearts"]
	_ok(int(raw["regen_seconds"]) == CANON_SECONDS, "economy_rewards_v1.json hearts.regen_seconds == 900 (got %s)" % str(raw["regen_seconds"]))
	_ok(int(raw["max"]) == 5 and int(raw["plus_one_sb"]) == 500 and int(raw["full_refill_sb_per_missing"]) == 400,
		"max 5 / +1 = 500 SB / refill 400 SB per missing preserved")
	_ok(EconomyConfig.new().hearts_regen_seconds() == CANON_SECONDS, "EconomyConfig.hearts_regen_seconds() == 900")

func _heart_service() -> void:
	print("[HeartService]")
	var t := [5_000_000]
	var hs = HeartService.new(EconomyWallet.new(0), EconomyConfig.new(), func(): return t[0])
	hs.consume()
	_ok(hs.seconds_to_next() == CANON_SECONDS, "after one consume the next Heart is exactly 900 s away (%d)" % hs.seconds_to_next())
	t[0] += CANON_SECONDS - 1
	_ok(hs.hearts() == 4, "+899 s: still 4")
	t[0] += 1
	_ok(hs.hearts() == 5, "+900 s: back to 5")

func _planning_config() -> void:
	print("[planning config]")
	var h: Dictionary = _json("res://data/config/player_experience_plan_v1.json")["hearts"]
	_ok(int(h["regen_minutes_per_heart"]) * 60 == CANON_SECONDS, "player_experience_plan_v1.json regen_minutes_per_heart == 15 (got %s)" % str(h["regen_minutes_per_heart"]))

## A line in an active doc drifts when it mentions Hearts + regen and states a
## 30-minute / 1800 s interval without marking it as superseded provenance.
func _active_docs() -> void:
	print("[active docs]")
	var re := RegEx.create_from_string("(?i)(\\b30[- ]?(real[- ]world )?min|\\b1800\\b|thirty minute)")
	for path in ACTIVE_DOCS:
		if not FileAccess.file_exists(path):
			_ok(false, "active doc exists: %s" % path)
			continue
		var bad: Array = []
		var n := 0
		for line in FileAccess.get_file_as_string(path).split("\n"):
			n += 1
			var l := line.to_lower()
			if l.find("heart") == -1 or re.search(line) == null:
				continue
			if l.find("supersede") != -1 or l.find("was 1800") != -1:
				continue
			bad.append("%d: %s" % [n, line.strip_edges()])
		_ok(bad.is_empty(), "%s has no active 30-min Heart claim %s" % [path, str(bad)])

func _two_x_unchanged() -> void:
	print("[30-minute 2x product unchanged]")
	var got := {}
	for p in EconomyConfig.new().speed_timed_products():
		got[int(p["seconds"])] = int(p["sb"])
	_ok(got == {900: 300, 1800: 500, 3600: 750}, "timed 2x products still 15m/300, 30m/500, 60m/750 (got %s)" % str(got))

func _home_full_state() -> void:
	print("[Home full-state Heart display]")
	var p := "user://m55_heart_%d.save" % Time.get_ticks_usec()
	_tmp.append(p)
	MainScript.boot_save_path_override = p
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	var app = root.get_app_state()
	var home = root.get_home()
	_ok(app.economy.hearts.hearts() == 5, "fresh profile full Hearts")
	var txt: String = home.get_region("HeartsChip").value_label.text
	_ok(txt == "15:00", "Home full Heart pill shows the 900 s ready state 15:00 (got %s)" % txt)
	root.free()
	MainScript.boot_save_path_override = ""

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
