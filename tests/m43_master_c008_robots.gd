extends SceneTree
## M43 master — Lane C008 Robots destination (SB-M43-102..111).
## Real app root (main.tscn) + real AppState / facade / ModalStack / CeremonyPresenter.
##
## Run: godot --headless --path . -s res://tests/m43_master_c008_robots.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const RobotsScreen = preload("res://scripts/ui/robots/robots_screen.gd")
const RobotRoster = preload("res://scripts/progression/robot_roster.gd")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const AppState = preload("res://scripts/app/app_state.gd")

## Gameplay-truth identifiers a robot/presentation file must never reference (SB-M43-109).
const FORBIDDEN := ["BoardState", "TargetSelector", "RoutingSystem", "Router", "Solver", "solver", "BatchSupply",
	"ColorCandidateIndex", "Reachability", "CompleteClearingLoop", "ScrubbotAgent"]

var EXPECTED_CASES := [
	"r01_nav_opens_real_roster", "r02_states_parts_overflow", "r03_perk_meta_truth", "r04_unlock_ceremony_equip_persist",
	"r05_locked_detail_earned_only", "r06_active_robot_presentation", "r07_no_gameplay_truth_mutation",
	"r08_new_badge_once_no_repeat_ceremony", "r09_all_ten_mobile_scale", "r10_missing_asset_fallback",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null

func _initialize() -> void:
	await process_frame
	# Fixed wall clock: r07 compares whole economy snapshots, and Hearts / 2x keep wall-clock
	# high-water marks that would otherwise tick between the two snapshots.
	MainScript.boot_clock_override = func(): return 1790000000
	await _r01()
	await _r02()
	await _r03()
	await _r04()
	await _r05()
	await _r06()
	await _r07()
	await _r08()
	await _r09()
	await _r10()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _r01() -> void:
	print("[r01 BottomNav ROBOTS opens the real 10-robot roster]")
	await _boot("r01")
	var b: Button = _root.get_home().get_region("Nav_robots")
	_ok(b != null and not b.disabled, "Nav_robots live")
	b.pressed.emit()
	await _frames(2)
	_ok(_top_id() == "robots", "ROBOTS -> Robots destination")
	var ids: Array = []
	for c in _top().find_children("Robot_*", "PanelContainer", true, false):
		ids.append(String(c.get_meta("robot_id")))
	_ok(ids == RobotRoster.ids() and ids.size() == 10, "10 rows in owner order %s" % str(ids))
	_top().close("test")
	await _frames(2)
	_ok(_top() == null, "closed back to Home")
	_complete("r01_nav_opens_real_roster")

func _r02() -> void:
	print("[r02 ACTIVE / next / LOCKED, Bot Parts N / 250, overflow]")
	await _boot("r02")
	var e = _eco()
	e.wallet.credit(EconomyWallet.BOT_PARTS, 120)
	var p = await _open()
	_ok(_state("scrubby") == UiText.t("ROBOTS_ACTIVE") and _state("moppy") == UiText.t("ROBOTS_LOCKED") and _state("atlas") == UiText.t("ROBOTS_LOCKED"), "Scrubby ACTIVE, rest LOCKED")
	_ok(_txt("Parts") == UiText.t("ROBOTS_PARTS", ["120", "250", "Moppy"]), "parts line '%s'" % _txt("Parts"))
	_ok(bool(p.get_action_button("robot:moppy").disabled) and p.get_action_button("robot:moppy").text == UiText.t("ROBOTS_UNLOCK", ["250"]), "next unlock blocked at 120/250")
	_ok(p.get_action_button("robot:bubbles").text == UiText.t("COLLECTION_DETAILS") and not p.get_action_button("robot:bubbles").disabled, "later robots: DETAILS only (order enforced)")
	e.wallet.credit(EconomyWallet.BOT_PARTS, 180)
	RobotsScreen.refresh(p, e)
	_ok(_txt("Parts").contains(UiText.t("ROBOTS_OVERFLOW", ["50"])) and not p.get_action_button("robot:moppy").disabled, "300 parts: unlockable, +50 overflow stated")
	_tap("robot:bubbles")
	await _frames(1)
	_ok(_top_id() == "robot_detail" and not e.robots.is_unlocked("bubbles"), "out-of-order tap never unlocks")
	_complete("r02_states_parts_overflow")

func _r03() -> void:
	print("[r03 canonical 20% meta perk shown; never puzzle power]")
	await _boot("r03")
	await _open()
	var bad: Array = []
	for r in RobotRoster.load_roster()["robots"]:
		var want := "%s: %s" % [r["perk_name"], r["perk_text"]]
		if _row_label(String(r["id"]), "Perk") != want:
			bad.append(r["id"])
		var mods: Dictionary = r.get("perk_modifiers", {})
		for k in mods:
			if int(mods[k]) != 20:
				bad.append("%s:%s" % [r["id"], k])
	_ok(bad.is_empty(), "every row shows the roster perk text, every modifier 20%% %s" % str(bad))
	var words := ["slot", "target", "solve", "board", "route", "puzzle", "batch"]
	var leaks: Array = []
	for r in RobotRoster.load_roster()["robots"]:
		for w in words:
			if String(r["perk_text"]).to_lower().contains(w):
				leaks.append("%s:%s" % [r["id"], w])
	_ok(leaks.is_empty(), "no perk text claims puzzle/board power %s" % str(leaks))
	_ok(UiText.t("ROBOTS_PERK_META").contains("never change a puzzle"), "meta-only statement in copy")
	_complete("r03_perk_meta_truth")

func _r04() -> void:
	print("[r04 UNLOCK -> facade -> ceremony on top; EQUIP persists]")
	await _boot("r04")
	var e = _eco()
	e.wallet.credit(EconomyWallet.BOT_PARTS, 300)
	var p = await _open()
	_tap("robot:moppy")
	await _frames(3)
	_ok(e.robots.is_unlocked("moppy") and e.wallet.bot_parts() == 50, "unlocked, exactly 250 spent")
	_ok(_top_id() == "ceremony_robot_unlock", "Robot Unlock ceremony above Robots (got %s)" % _top_id())
	_top()._on_action("keep")
	await _frames(3)
	await create_timer(0.5).timeout
	_ok(_top() == p and _state("moppy") == UiText.t("ROBOTS_UNLOCKED") and p.get_action_button("robot:moppy").text == UiText.t("ROBOTS_EQUIP"), "back on refreshed roster: Moppy UNLOCKED / EQUIP")
	_tap("robot:moppy")
	await _frames(2)
	await create_timer(0.5).timeout
	_ok(e.robots.active_robot() == "moppy" and _state("moppy") == UiText.t("ROBOTS_ACTIVE") and _state("scrubby") == UiText.t("ROBOTS_UNLOCKED") and e.wallet.bot_parts() == 50, "EQUIP: Moppy ACTIVE, spends nothing")
	var re = AppState.new(MainScript.boot_save_path_override)
	_ok(re.economy.robots.active_robot() == "moppy", "active robot persisted through the canonical save")
	_tap("robot:scrubby")
	await _frames(2)
	_ok(e.robots.active_robot() == "scrubby", "any unlocked robot re-equippable")
	_complete("r04_unlock_ceremony_equip_persist")

func _r05() -> void:
	print("[r05 locked detail: preview, required Bot Parts, perk, earned only]")
	await _boot("r05")
	var e = _eco()
	e.wallet.credit(EconomyWallet.BOT_PARTS, 40)
	await _open()
	_tap("robot:bubbles")
	await _frames(2)
	var d = _top()
	_ok(_top_id() == "robot_detail", "DETAILS opens the locked detail")
	_ok(d.find_child("PreviewArt", true, false).texture.resource_path == RobotRoster.entry("bubbles")["assets"]["master"] and d.find_child("Lock", true, false) != null, "preview art under the lock emblem")
	_ok(_txt("Required") == UiText.t("ROBOTS_DETAIL_NEED", ["500", "40"]), "required '%s' (Moppy then Bubbles)" % _txt("Required"))
	_ok(_txt("Perk").begins_with(String(RobotRoster.entry("bubbles")["perk_name"])) and _txt("EarnedOnly") == UiText.t("ROBOTS_DETAIL_EARNED"), "perk + earned-only")
	_ok(d.get_action_ids() == ["back"], "no purchase action of any kind")
	var src := FileAccess.get_file_as_string("res://scripts/ui/robots/robots_screen.gd")
	_ok(not src.contains("scrub_bucks") and not src.contains("debit(") and not src.contains("ShopHandoff") and not src.contains("purchase"), "no SB / money path to Bot Parts")
	_tap("back")
	await _frames(2)
	await create_timer(0.5).timeout
	_ok(_top_id() == "robots" and not _top().is_latched(), "back to a usable roster")
	_complete("r05_locked_detail_earned_only")

func _r06() -> void:
	print("[r06 active robot -> Home / gameplay HUD / support / victory presentation]")
	await _boot("r06")
	var e = _eco()
	var home = _root.get_home()
	var scrubby_tex: Texture2D = home.get_region("ProfilePortrait").texture
	e.wallet.credit(EconomyWallet.BOT_PARTS, 250)
	_root.get_app_state().actions.unlock_next_robot()
	_root.get_app_state().actions.equip_robot("moppy")
	home.refresh()
	await _frames(2)
	var m := RobotRoster.entry("moppy")["assets"] as Dictionary
	_ok(home.get_region("ProfileName").text == "Moppy" and home.get_region("ProfilePortrait").texture.resource_path == m["portrait"], "Home profile: Moppy name + portrait")
	_ok(_root._results_model({}).get("robot_id") == "moppy", "Results model carries the active robot")
	_ok(_root.get_acquisition()._help_pose() == m["help_pose"], "support / Need a Hand / Life hero: Moppy help pose")
	var gs = GameplayScreen.new()
	_sub.add_child(gs)
	await _frames(1)
	gs.set_profile({"level": 3, "robot_id": "moppy"})
	_ok(gs.find_child("Portrait", true, false).texture.resource_path == m["profile_portrait"] and gs.find_child("ProfileName", true, false).text == "Moppy", "gameplay HUD: Moppy portrait + name")
	gs.set_profile({"level": 3, "robot_id": "scrubby"})
	_ok(gs.find_child("Portrait", true, false).texture.resource_path == GameplayScreen.PORTRAIT_ART, "gameplay HUD back to Scrubby")
	gs.free()
	_root.get_app_state().actions.equip_robot("scrubby")
	home.refresh()
	await _frames(2)
	_ok(home.get_region("ProfilePortrait").texture == scrubby_tex and _root.get_acquisition()._help_pose() == RobotRoster.entry("scrubby")["assets"]["help_pose"], "re-equip Scrubby restores the owner-approved Home binding")
	var rs := FileAccess.get_file_as_string("res://scripts/ui/results_screen.gd")
	_ok(rs.contains("RobotRoster.asset(rid, \"victory_pose\" if won else \"help_pose\")"), "Results victory / help pose from the roster family")
	_complete("r06_active_robot_presentation")

func _r07() -> void:
	print("[r07 robot selection never reaches gameplay truth]")
	var bad: Array = []
	for f in ["res://scripts/ui/robots/robots_screen.gd", "res://scripts/progression/robot_roster.gd", "res://scripts/progression/robot_unlock_service.gd"]:
		var s := _code_only(FileAccess.get_file_as_string(f))
		for t in FORBIDDEN:
			if s.contains(t):
				bad.append("%s:%s" % [f.get_file(), t])
	_ok(bad.is_empty(), "robot files reference no board/target/route/solver/batch type %s" % str(bad))
	var host := FileAccess.get_file_as_string("res://scripts/gameplay/runtime/production_gameplay_host.gd")
	var uses: Array = []
	for line in host.split("\n"):
		if line.contains("active_robot()"):
			uses.append(line.strip_edges())
	_ok(uses.size() == 1 and uses[0].begins_with("prof[\"robot_id\"]"), "gameplay host reads the robot only into the HUD profile %s" % str(uses))
	await _boot("r07")
	var e = _eco()
	e.wallet.credit(EconomyWallet.BOT_PARTS, 250)
	_root.get_app_state().actions.unlock_next_robot()
	var snap0: Dictionary = e.snapshot()
	_root.get_app_state().actions.equip_robot("moppy")
	var snap1: Dictionary = e.snapshot()
	var changed: Array = []
	for k in snap1:
		if JSON.stringify(snap0.get(k)) != JSON.stringify(snap1[k]):
			changed.append(k)
	_ok(changed == ["robots"], "equip changes only the robots section %s" % str(changed))
	_complete("r07_no_gameplay_truth_mutation")

func _r08() -> void:
	print("[r08 NEW badge until first seen; ceremony shown once]")
	await _boot("r08")
	var e = _eco()
	e.wallet.credit(EconomyWallet.BOT_PARTS, 250)
	_root.get_app_state().actions.unlock_next_robot()
	await _frames(3)
	var c = _root.ceremonies
	for _i in range(10):
		if _top_id() == "ceremony_robot_unlock":
			break
		await _frames(1)
	_ok(_top_id() == "ceremony_robot_unlock", "Home shows the Robot Unlock ceremony after the commit (got %s, pending %s)" % [_top_id(), str(c.pending())])
	_top()._on_action("keep")
	await _frames(3)
	_ok(c.pending().is_empty() and e.meta_ui.is_seen("robot:moppy"), "ceremony acknowledged once")
	var p = await _open()
	_ok(_new_badge("moppy") and not _new_badge("scrubby"), "NEW on Moppy only")
	p.close("test")
	await _frames(2)
	await _open()
	_ok(not _new_badge("moppy"), "NEW cleared after first view")
	_ok(c.pending().is_empty() and _top_id() == "robots", "no ceremony repeated on revisit")
	_root.get_app_state().request_save()
	var re = AppState.new(MainScript.boot_save_path_override)
	_ok(re.economy.meta_ui.is_seen(RobotsScreen.seen_key("moppy")) and RobotsScreen.unseen_robots(re.economy).is_empty(), "seen mark persists")
	var legacy: Dictionary = e.snapshot()
	legacy.erase("meta_ui")
	e.import_snapshot(legacy)
	_ok(RobotsScreen.unseen_robots(e).is_empty(), "legacy save: already-unlocked robots are not flooded with NEW")
	_complete("r08_new_badge_once_no_repeat_ceremony")

func _r09() -> void:
	print("[r09 all 10 robots at mobile scale]")
	for size in [Vector2i(1080, 2160), Vector2i(720, 1280)]:
		await _boot("r09", size)
		var e = _eco()
		e.wallet.credit(EconomyWallet.BOT_PARTS, 250 * 9)
		for _i in range(9):
			_root.get_app_state().actions.unlock_next_robot()
		for id in RobotRoster.ids():
			e.meta_ui.mark_seen("robot:" + id)
		var p = await _open()
		await _frames(2)
		var problems: Array = []
		var scroll: Control = p.find_child("RobotList", true, false)
		for card in p.find_children("Robot_*", "PanelContainer", true, false):
			var id := String(card.get_meta("robot_id"))
			var pt: TextureRect = card.find_child("Portrait", true, false)
			var nm: Label = card.find_child("Name", true, false)
			var b: Button = p.get_action_button("robot:" + id)
			if pt.texture == null or pt.texture.resource_path != RobotRoster.entry(id)["assets"]["portrait"]:
				problems.append(id + ":portrait")
			if nm.get_minimum_size().x > card.size.x or card.size.x > scroll.size.x + 1:
				problems.append(id + ":overflow")
			if b.size.y < 80 or (b.disabled != (id == e.robots.active_robot())):
				problems.append(id + ":button")
		_ok(problems.is_empty() and _txt("Parts") == UiText.t("ROBOTS_ALL_UNLOCKED", ["0"]), "%s: 10 portraits, no overflow, 80px buttons, all-unlocked line %s" % [str(size), str(problems)])
	_complete("r09_all_ten_mobile_scale")

func _r10() -> void:
	print("[r10 missing presentation asset falls back to Scrubby, never breaks]")
	var cache: Dictionary = RobotRoster.load_roster()
	var saved: String = cache["robots"][1]["assets"]["portrait"]
	cache["robots"][1]["assets"]["portrait"] = "res://assets/ui/final/characters/robots/moppy/__missing__.png"
	_ok(RobotRoster.asset("moppy", "portrait") == cache["robots"][0]["assets"]["portrait"], "missing Moppy portrait -> Scrubby portrait")
	_ok(RobotRoster.asset("ghost", "victory_pose") == cache["robots"][0]["assets"]["victory_pose"], "unknown robot -> Scrubby victory pose")
	await _boot("r10")
	var e = _eco()
	e.wallet.credit(EconomyWallet.BOT_PARTS, 250)
	_root.get_app_state().actions.unlock_next_robot()
	_root.get_app_state().actions.equip_robot("moppy")
	_root.get_home().refresh()
	await _frames(2)
	_ok(_root.get_home().get_region("ProfilePortrait").texture != null and _root.get_home().get_region("ProfileName").text == "Moppy", "Home still renders with the fallback portrait")
	cache["robots"][1]["assets"]["portrait"] = saved
	var gs = GameplayScreen.new()
	_sub.add_child(gs)
	await _frames(1)
	gs.set_profile({"level": 1, "robot_id": "ghost"})
	_ok(gs.find_child("Portrait", true, false).texture != null and gs.find_child("ProfileName", true, false).text == UiText.t("HOME_PLAYER_NAME_DEFAULT"), "unknown id in HUD: Scrubby art + default name")
	gs.free()
	_complete("r10_missing_asset_fallback")

# ------------------------------------------------------------------ helpers ----

func _boot(tag: String, size := Vector2i(1080, 2160)) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m43master_c008_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)

func _open():
	var p = RobotsScreen.open(_root.get_modal_stack(), _root.get_app_state(), _root.ceremonies)
	await _frames(2)
	return p

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _eco():
	return _root.get_app_state().economy

func _top():
	return _root.get_modal_stack().top()

func _top_id() -> String:
	var t = _top()
	return String(t.popup_id) if t != null else ""

func _tap(id: String) -> void:
	var t = _top()
	if t != null:
		t._on_action(id)

func _txt(n: String) -> String:
	var l = _top().find_child(n, true, false)
	return l.text if l is Label else ""

func _row_label(id: String, n: String) -> String:
	var c = _top().find_child("Robot_" + id, true, false)
	return (c.find_child(n, true, false) as Label).text if c != null else ""

func _state(id: String) -> String:
	var c = _top().find_child("Robot_" + id, true, false)
	return c.find_child("State", true, false).get_node("Text").text if c != null else ""

func _new_badge(id: String) -> bool:
	var c = _top().find_child("Robot_" + id, true, false)
	return c != null and c.find_child("NewBadge", true, false).visible

## Source without comment lines (doc comments may name what the file must NOT touch).
func _code_only(src: String) -> String:
	var out: PackedStringArray = []
	for line in src.split("
"):
		if not line.strip_edges().begins_with("#"):
			out.append(line)
	return "
".join(out)

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
	print("M43 master C008 Robots evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
