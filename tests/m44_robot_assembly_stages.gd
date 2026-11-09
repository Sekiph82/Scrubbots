extends SceneTree
## SB-M44-027 — Robots screen 5-stage assembly visual (50/100/150/200/250 Bot Parts).
## Stage mapping + the visual fed live from the real Bot Parts wallet / RobotUnlockService on the
## real app root (main.tscn), throw-away saves. Visual only: opening/refreshing never mutates economy.
##
## Run: godot --headless --path . -s res://tests/m44_robot_assembly_stages.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := ["a01_stage_mapping", "a02_fed_from_bot_parts", "a03_next_robot_and_all_unlocked", "a04_no_economy_mutation"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	preload("res://scripts/app/app_state.gd").test_unlock_all = true
	await process_frame
	MainScript.boot_clock_override = func(): return 1790000000
	_a01()
	await _a02()
	await _a03()
	await _a04()
	_shutdown()
	_cleanup()
	_done()

func _a01() -> void:
	print("[a01 stage mapping 0/49/50/149/250/overflow]")
	for c in [[0, 0], [49, 0], [50, 1], [99, 1], [100, 2], [149, 2], [150, 3], [200, 4], [249, 4], [250, 5], [251, 5], [400, 5], [10000, 5]]:
		_ok(RobotsScreen.assembly_stage(c[0], 250) == c[1], "%d parts -> stage %d (got %d)" % [c[0], c[1], RobotsScreen.assembly_stage(c[0], 250)])
	_complete("a01_stage_mapping")

func _a02() -> void:
	print("[a02 visual fed from the Bot Parts service]")
	await _boot("a02")
	var e = _eco()
	var p = await _open()
	_ok(_stage_text() == UiText.t("ROBOTS_ASSEMBLY", ["0", "5"]) and is_equal_approx(_reveal(), 0.0), "0 parts -> stage 0/5, reveal 0")
	for c in [[49, 0], [50, 1], [149, 2], [250, 5], [400, 5]]:
		e.wallet.credit(EconomyWallet.BOT_PARTS, c[0] - e.wallet.bot_parts())
		RobotsScreen.refresh(p, e)
		_ok(int(e.robots.next_robot_progress()["parts"]) == c[0], "service reports %d parts" % c[0])
		_ok(_stage_text() == UiText.t("ROBOTS_ASSEMBLY", [str(c[1]), "5"]), "%d parts -> '%s'" % [c[0], _stage_text()])
		_ok(is_equal_approx(_reveal(), c[1] / 5.0), "%d parts -> reveal %.1f (got %.2f)" % [c[0], c[1] / 5.0, _reveal()])
	_complete("a02_fed_from_bot_parts")

func _a03() -> void:
	print("[a03 next locked robot's existing portrait; hidden when all unlocked]")
	await _boot("a03")
	var e = _eco()
	e.wallet.credit(EconomyWallet.BOT_PARTS, 300)
	var p = await _open()
	_ok(_art().texture.resource_path == RobotRoster.asset("moppy", "portrait"), "art = Moppy portrait")
	_ok(_art().material is ShaderMaterial, "one shader material reveals the art")
	_ok(bool(_root.get_app_state().actions.unlock_next_robot().get("ok", false)), "unlock Moppy via facade")
	RobotsScreen.refresh(p, e)
	_ok(_art().texture.resource_path == RobotRoster.asset(RobotRoster.next_locked(e.robots), "portrait"), "art follows next locked robot")
	_ok(_stage_text() == UiText.t("ROBOTS_ASSEMBLY", ["1", "5"]), "50 overflow parts carry over -> stage 1 toward next ('%s')" % _stage_text())
	e.wallet.credit(EconomyWallet.BOT_PARTS, 250 * 8)
	for _i in range(8):
		_root.get_app_state().actions.unlock_next_robot()
	RobotsScreen.refresh(p, e)
	_ok(RobotRoster.next_locked(e.robots) == "" and not _top().find_child("Assembly", true, false).visible, "all unlocked -> assembly hidden")
	_complete("a03_next_robot_and_all_unlocked")

func _a04() -> void:
	print("[a04 opening / refreshing never mutates economy]")
	await _boot("a04")
	var e = _eco()
	e.wallet.credit(EconomyWallet.BOT_PARTS, 180)
	var before: Dictionary = e.robots.snapshot()
	var p = await _open()
	RobotsScreen.refresh(p, e)
	_ok(e.wallet.bot_parts() == 180 and e.robots.snapshot() == before, "parts and robots unchanged")
	var src := FileAccess.get_file_as_string("res://scripts/ui/robots/robots_screen.gd")
	_ok(not src.contains(".credit(") and not src.contains(".debit("), "robots screen never credits/debits the wallet")
	_complete("a04_no_economy_mutation")

# ---------------------------------------------------------------- helpers ----

func _boot(tag: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m44_assembly_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _open():
	var p = RobotsScreen.open(_root.get_modal_stack(), _root.get_app_state(), _root.ceremonies)
	await _frames(2)
	return p

func _eco():
	return _root.get_app_state().economy

func _top():
	return _root.get_modal_stack().top()

func _art() -> TextureRect:
	return _top().find_child("AssemblyArt", true, false)

func _reveal() -> float:
	return float(_art().material.get_shader_parameter("reveal"))

func _stage_text() -> String:
	return (_top().find_child("AssemblyStage", true, false) as Label).text

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M44 robot assembly stages evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
