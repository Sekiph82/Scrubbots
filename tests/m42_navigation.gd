extends SceneTree
## M42-C001 — NavigationController + app-root ownership evidence.
## Covers SB-M42-001 (architecture) and later nav tasks append cases here.
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_navigation.gd

const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")

const R := NavigationController.Route

var EXPECTED_CASES := [
	"nav_edges", "nav_reentry", "nav_terminal_latch", "nav_settings_overlay",
	"nav_back", "main_owns_one_nav", "no_shipping_level_select",
	"home_to_gameplay_once", "results_on_real_won", "results_lost_retry_error",
	"duplicate_transitions",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_nav_edges()
	_nav_reentry()
	_nav_terminal_latch()
	_nav_settings_overlay()
	_nav_back()
	await _main_owns_one_nav()
	_no_shipping_level_select()
	await _home_to_gameplay_once()
	await _results_on_real_won()
	await _results_lost_retry_error()
	await _duplicate_transitions()
	_cleanup()
	_done()

func _nav_edges() -> void:
	print("[nav edges]")
	var n = NavigationController.new()
	_ok(n.current() == R.BOOT and n.transition_id() == 0, "starts at BOOT, transition 0")
	_ok(not n.go(R.GAMEPLAY) and not n.go(R.RESULTS) and n.current() == R.BOOT, "BOOT cannot jump to GAMEPLAY/RESULTS")
	_ok(not n.go(99) and not n.go(-1), "unknown route ids rejected")
	_ok(n.go(R.HOME) and n.current() == R.HOME and n.transition_id() == 1, "BOOT -> HOME")
	_ok(not n.go(R.HOME) and n.transition_id() == 1, "same-route request rejected (idempotent)")
	_ok(not n.go(R.RESULTS) and not n.go(R.OPENING), "HOME cannot go to RESULTS/OPENING")
	_ok(n.go(R.GAMEPLAY) and n.attempt_id() == 1, "HOME -> GAMEPLAY starts attempt 1")
	_ok(not n.go(R.OPENING), "GAMEPLAY cannot go to OPENING")
	var log: Array = []
	n.route_changed.connect(func(f, t, p): log.append([f, t, p]))
	_ok(n.go(R.HOME, {"x": 1}) and log.size() == 1 and log[0][0] == R.GAMEPLAY and log[0][1] == R.HOME and log[0][2] == {"x": 1}, "route_changed carries from/to/payload")
	var names: Array = []
	for k in R:
		names.append(k)
	_ok(names == ["BOOT", "OPENING", "HOME", "GAMEPLAY", "RESULTS"], "closed route set, no LEVEL_SELECT")
	_complete("nav_edges")

func _nav_reentry() -> void:
	print("[nav re-entry]")
	var n = NavigationController.new()
	n.go(R.HOME)
	var inner := [null]
	n.route_changed.connect(func(_f, _t, _p): inner[0] = n.go(R.HOME))
	_ok(n.go(R.GAMEPLAY), "outer transition accepted")
	_ok(inner[0] == false and n.current() == R.GAMEPLAY and n.transition_id() == 2, "re-entrant go() inside route_changed rejected")
	var payload := {"a": [1]}
	var n2 = NavigationController.new()
	n2.go(R.HOME, payload)
	payload["a"].append(2)
	_ok(n2.last_payload() == {"a": [1]}, "payload stored as detached copy")
	var lp: Dictionary = n2.last_payload()
	lp["a"].append(3)
	_ok(n2.last_payload() == {"a": [1]}, "last_payload() returns a detached copy")
	_complete("nav_reentry")

func _nav_terminal_latch() -> void:
	print("[nav terminal latch]")
	var n = NavigationController.new()
	n.go(R.HOME)
	_ok(not n.on_gameplay_terminal(0, &"WON", 1), "terminal outside GAMEPLAY rejected")
	n.go(R.GAMEPLAY)
	var a: int = n.attempt_id()
	_ok(not n.on_gameplay_terminal(a + 1, &"WON", 1), "wrong attempt id rejected")
	_ok(n.on_gameplay_terminal(a, &"WON", 1) and n.current() == R.RESULTS, "terminal -> RESULTS")
	_ok(n.last_payload() == {"status": "WON", "level": 1, "attempt": a}, "minimal results payload")
	_ok(not n.on_gameplay_terminal(a, &"WON", 1) and n.transition_id() == 3, "repeated terminal ignored")
	_ok(n.resume_gameplay_after_retry() and n.attempt_id() == a + 1, "RESULTS -> GAMEPLAY retry = new attempt")
	_ok(not n.on_gameplay_terminal(a, &"LOST", 1), "stale attempt terminal ignored after retry")
	_ok(n.on_gameplay_terminal(a + 1, &"LOST", 1) and n.last_payload()["status"] == "LOST", "new attempt terminal accepted once")
	_complete("nav_terminal_latch")

func _nav_settings_overlay() -> void:
	print("[nav settings overlay]")
	var n = NavigationController.new()
	_ok(not n.open_settings(), "no Settings outside HOME (BOOT)")
	n.go(R.HOME)
	var ev: Array = []
	n.settings_changed.connect(func(o): ev.append(o))
	_ok(n.open_settings() and n.is_settings_open() and ev == [true], "HOME opens Settings")
	_ok(not n.open_settings() and ev == [true], "double open ignored")
	_ok(n.go(R.GAMEPLAY) and not n.is_settings_open() and ev == [true, false], "leaving HOME closes Settings")
	_ok(not n.open_settings(), "no Settings during GAMEPLAY")
	_ok(not n.close_settings(), "close when closed is a no-op")
	_complete("nav_settings_overlay")

func _nav_back() -> void:
	print("[nav back]")
	var n = NavigationController.new()
	_ok(n.back() == "none" and n.current() == R.BOOT, "BOOT back: none")
	n.go(R.HOME)
	_ok(n.back() == "none" and n.current() == R.HOME, "HOME back: none (no exit/level select)")
	n.open_settings()
	_ok(n.back() == "close_settings" and not n.is_settings_open() and n.current() == R.HOME, "back closes Settings first")
	n.go(R.GAMEPLAY)
	_ok(n.back() == "none" and n.current() == R.GAMEPLAY, "GAMEPLAY back after action: none")
	_ok(n.back(true) == "home" and n.current() == R.HOME, "GAMEPLAY back pre-action: HOME")
	n.go(R.GAMEPLAY)
	n.on_gameplay_terminal(n.attempt_id(), &"WON", 1)
	_ok(n.back() == "home" and n.current() == R.HOME, "RESULTS back: HOME")
	_complete("nav_back")

func _main_owns_one_nav() -> void:
	print("[main owns one nav]")
	var root = await _boot_main(_uniq("nav"))
	var nav = root.get_navigation()
	_ok(nav != null and nav.current() == R.HOME, "real main.tscn root owns the navigation authority, at HOME")
	_ok(root.get_navigation() == nav, "same instance on repeated access")
	root.open_settings()
	_ok(nav.is_settings_open() and root.get_settings_panel().visible, "main Settings opens via nav overlay")
	root.get_settings_panel().close_panel()
	_ok(not nav.is_settings_open() and not root.get_settings_panel().visible, "panel Close closes the nav overlay")
	root.open_settings()
	nav.close_settings()
	_ok(not root.get_settings_panel().visible, "nav close hides the panel")
	_shutdown(root)
	_complete("main_owns_one_nav")

## SB-M42-006: Home -> Gameplay exactly once per accepted activation, one host,
## same AppState graph, host released on return HOME.
func _home_to_gameplay_once() -> void:
	print("[home to gameplay once]")
	var root = await _boot_main(_uniq("h2g"))
	var app = root.get_app_state()
	var nav = root.get_navigation()
	var r1: Dictionary = root.play_current_frontier()
	var r2: Dictionary = root.play_current_frontier()
	await process_frame
	_ok(r1.get("ok", false) and not r2.get("ok", true) and r2.get("reason") == "not_home", "second activation refused while in GAMEPLAY")
	_ok(_hosts(root) == 1 and nav.attempt_id() == 1, "exactly one GameplayHost, attempt 1")
	var h = root.get_gameplay_host()
	_ok(h.app_state == app and h.get_audio_settings() == app.audio, "host uses the same AppState + audio settings service")
	_ok(h._economy == app.economy and h._progression == app.progression and h._save == app.save, "host uses the same economy/progression/save graph")
	# Direct relaunch replaces, never duplicates (old host leaves the tree immediately).
	root.launch_gameplay()
	var old_in_tree: bool = is_instance_valid(h) and h.is_inside_tree()
	_ok(_hosts(root) == 1 and root.get_gameplay_host() != h and not old_in_tree, "direct relaunch keeps exactly one host in the tree (old one removed immediately)")
	# Pre-action exit back to HOME releases the host.
	_ok(nav.back(true) == "home" and nav.current() == R.HOME, "pre-action back -> HOME")
	await process_frame
	_ok(_hosts(root) == 0 and root.get_gameplay_host() == null, "host released on return HOME (no orphan)")
	_ok(root.get_home().visible, "Home visible again")
	var r3: Dictionary = root.play_current_frontier()
	await process_frame
	_ok(r3.get("ok", false) and _hosts(root) == 1 and nav.attempt_id() == 2, "next activation -> new single host, attempt 2")
	_shutdown(root)
	_complete("home_to_gameplay_once")

## SB-M42-007: authoritative terminal -> RESULTS once, minimal payload, economy/save
## already committed by the host before Results appears.
func _results_on_real_won() -> void:
	print("[results on real WON]")
	var root = await _boot_main(_uniq("won"))
	var app = root.get_app_state()
	var nav = root.get_navigation()
	var sb0: int = app.economy.wallet.scrub_bucks()
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	var seen := {"sb_at_results": -1, "count": 0}
	nav.route_changed.connect(func(_f, t, _p):
		if t == R.RESULTS:
			seen["count"] += 1
			seen["sb_at_results"] = app.economy.wallet.scrub_bucks())
	_drain(h)
	_ok(h.get_completion().is_won(), "real gameplay reached WON")
	_ok(nav.current() == R.RESULTS and seen["count"] == 1, "exactly one RESULTS transition")
	_ok(nav.last_payload() == {"status": "WON", "level": 1, "attempt": 1}, "minimal payload %s" % str(nav.last_payload()))
	_ok(seen["sb_at_results"] > sb0 and app.progression.current_level() == 2, "first-clear economy + progression committed before Results")
	var res = root.get_results_screen()
	_ok(res.visible and res.get_payload()["status"] == "WON" and res.get_primary_button().text == "CONTINUE", "Results visible: WON / CONTINUE")
	_ok(res.get_primary_button().disabled and not root.continue_from_results().get("ok", true), "CONTINUE disabled: next frontier (level 2) has no content")
	h.get_completion().terminal_reached.emit(&"WON", {})
	_ok(seen["count"] == 1 and nav.current() == R.RESULTS, "repeated terminal callback ignored")
	res.get_home_button().pressed.emit()
	await process_frame
	_ok(nav.current() == R.HOME and root.get_gameplay_host() == null and not res.visible, "HOME from Results releases the host")
	_shutdown(root)
	_complete("results_on_real_won")

func _results_lost_retry_error() -> void:
	print("[results LOST / retry / ERROR]")
	var root = await _boot_main(_uniq("lost"))
	var nav = root.get_navigation()
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	# Signal-level terminal injection on the REAL completion controller (a LOST board
	# cannot be produced from the shipped level without a QA seam).
	h.get_completion().terminal_reached.emit(&"LOST", {})
	_ok(nav.current() == R.RESULTS and nav.last_payload()["status"] == "LOST", "LOST -> RESULTS")
	var res = root.get_results_screen()
	_ok(res.get_primary_button().text == "RETRY" and not res.get_primary_button().disabled, "Results LOST offers RETRY")
	_ok(root.retry_from_results() and nav.current() == R.GAMEPLAY and nav.attempt_id() == 2, "RETRY -> same host transaction-safe retry, attempt 2")
	_ok(root.get_gameplay_host() == h and not res.visible, "same host, Results hidden")
	h.get_completion().terminal_reached.emit(&"ERROR", {})
	_ok(nav.current() == R.RESULTS and nav.last_payload()["attempt"] == 2 and nav.last_payload()["status"] == "ERROR", "new attempt terminal accepted once")
	_ok(not res.get_primary_button().visible, "ERROR: HOME only")
	_shutdown(root)
	_complete("results_lost_retry_error")

## SB-M42-008: double taps, repeated terminal callbacks and rapid re-entry never
## duplicate hosts/Results, rewards or saves.
func _duplicate_transitions() -> void:
	print("[duplicate transitions]")
	var root = await _boot_main(_uniq("dup"))
	var app = root.get_app_state()
	var nav = root.get_navigation()
	var saves := [0]
	app.save.set_fault_injector(func(stage):
		if stage == "temp_write":
			saves[0] += 1
		return false)
	var play: Button = root.get_home().get_region("PlayButton")
	for _i in range(5):
		play.pressed.emit()   # same-frame double/triple tap
	await process_frame
	_ok(_hosts(root) == 1 and nav.attempt_id() == 1 and nav.transition_id() == 2, "5 PLAY taps -> 1 host, 1 attempt, 1 transition")
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	_drain(h)
	var sb_after: int = app.economy.wallet.scrub_bucks()
	var saves_after_terminal: int = saves[0]
	var results_count := [0]
	nav.route_changed.connect(func(_f, t, _p):
		if t == R.RESULTS:
			results_count[0] += 1)
	for _i in range(5):
		h.get_completion().terminal_reached.emit(&"WON", {})
	_ok(results_count[0] == 0 and nav.current() == R.RESULTS, "5 repeated terminal callbacks -> no extra Results")
	_ok(app.economy.wallet.scrub_bucks() == sb_after and app.progression.current_level() == 2, "no double reward / double progression")
	_ok(saves[0] == saves_after_terminal, "no repeated saves from repeated terminals")
	var res = root.get_results_screen()
	var t0: int = nav.transition_id()
	res.get_home_button().pressed.emit()
	res.get_home_button().pressed.emit()
	res.get_primary_button().pressed.emit()
	await process_frame
	_ok(nav.current() == R.HOME and nav.transition_id() == t0 + 1 and _hosts(root) == 0, "double HOME + late CONTINUE -> one transition, no host")
	_ok(not root.retry_from_results() and not root.continue_from_results().get("ok", true), "Results actions refused outside RESULTS")
	root.open_settings()
	root.open_settings()
	_ok(root.find_children("*", "", true, false).filter(func(n): return n == root.get_settings_panel()).size() == 1 and nav.is_settings_open(), "double Settings open -> one overlay")
	_ok(nav.back() == "close_settings" and nav.back() == "none", "back twice: close then nothing")
	app.save.set_fault_injector(Callable())
	_shutdown(root)
	_complete("duplicate_transitions")

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	var scheduler = h.get_scheduler()
	var agent_layer = h.get_agent_layer()
	for _i in range(80000):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(1.0)
		if h.get_completion().is_terminal():
			break
		if supply.is_exhausted() and scheduler.live_assignment_count() == 0 and not _any_moving(agent_layer):
			runtime.tick(1.0)
			if h.get_completion().is_terminal():
				break
			runtime.tick(1.0)
			break

func _any_moving(agent_layer) -> bool:
	if agent_layer == null:
		return false
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return true
	return false

func _hosts(root) -> int:
	var n := 0
	for c in root.get_children():
		if String(c.name).begins_with("GameplayHost"):
			n += 1
	return n

## SB-M42-005 / OWNER_M37_LEVEL_SELECT_DECISION_V01: NO SHIPPING LEVEL SELECT.
func _no_shipping_level_select() -> void:
	print("[no shipping level select]")
	var offenders: Array = []
	for dir in ["res://scripts/app", "res://scripts/ui", "res://scenes/app", "res://scenes/ui"]:
		for f in _files(dir):
			var t := _strip_comments(FileAccess.get_file_as_string(f)).to_lower()
			if t.find("debug_set_current_level") != -1 or t.find("level_select") != -1 or t.find("levelselect") != -1 or t.find("level select") != -1:
				offenders.append(f)
	_ok(offenders.is_empty(), "no production app/ui code references a level picker or the debug frontier seam %s" % str(offenders))
	var probe = MainScript.new()
	var main_methods: Array = []
	for m in probe.get_method_list():
		main_methods.append(m["name"])
	_ok(main_methods.has("play_current_frontier") and not main_methods.has("play_level") and not main_methods.has("launch_level"), "app root exposes only frontier launch, no level-number launch")
	var play_args: Array = []
	for m in probe.get_method_list():
		if m["name"] == "play_current_frontier":
			play_args = m["args"]
	probe.free()
	_ok(play_args.is_empty(), "play_current_frontier takes no level argument")
	_complete("no_shipping_level_select")

## Code only: drop `#` comments so documentation of the prohibition is not a hit.
func _strip_comments(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("
"):
		var i := line.find("#")
		out.append(line if i == -1 else line.substr(0, i))
	return "
".join(out)

func _files(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		out.append_array(_files(dir + "/" + sub))
	return out

# ---------------------------------------------------------------- helpers ----

func _boot_main(path: String):
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	return root

func _shutdown(root) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	MainScript.boot_save_path_override = ""

func _uniq(tag: String) -> String:
	var p := "user://m42nav_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	for c in missing:
		print("  FAIL: sub-test did not complete: %s" % c)
	_fail += missing.size()
	print("M42 navigation cases completed: %d/%d" % [EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size()])
	print("M42 navigation evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
