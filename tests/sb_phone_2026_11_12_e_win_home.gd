extends SceneTree
## SB-PHONE-2026-11-12-E — a WIN plays the level-complete animation over the board, then Home
## opens by itself (no Results, no button, no tap); Home flies the receipt's rewards into their
## HUD targets, then the milestone ceremonies follow on Home. LOSS keeps Results Retry / Home.
## Production path: real main.tscn root, real AppState graph, real ProductionGameplayHost
## terminal transaction (a real Level 1 played to its WON), real HomeScreen and ceremonies.
##
## Run: godot --headless --path . -s res://tests/sb_phone_2026_11_12_e_win_home.gd

const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const WinOverlay = preload("res://scripts/ui/win_overlay.gd")
const HomeRewardFlight = preload("res://scripts/ui/home/home_reward_flight.gd")
const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const R := NavigationController.Route

var EXPECTED_CASES := [
	"win_animation_then_home", "back_skips_to_home", "flight_targets_hud", "ceremony_after_flight",
	"granted_once_no_replay", "loss_results_unchanged", "reduced_effects", "no_interstitial_before_home",
	"results_won_branch_removed",
]

## Records interstitial calls (no SDK).
class MockAds extends AdProvider:
	var interstitials: Array = []
	func show_interstitial(placement: String) -> bool:
		interstitials.append(placement)
		return true

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _routes: Array = []
var _results_seen := false

func _initialize() -> void:
	MainScript.boot_opening_override = 0
	MainScript.boot_level_intro_override = 0
	await process_frame
	await _win_animation_then_home()
	await _back_skips_to_home()
	await _flight_and_ceremony()
	await _granted_once_no_replay()
	await _loss_results_unchanged()
	await _reduced_effects()
	await _no_interstitial_before_home()
	_results_won_branch_removed()
	_cleanup()
	_done()

## The full path with the shipping animation: board -> WinOverlay (keyed WIN video) -> Home, no input.
func _win_animation_then_home() -> void:
	print("[win animation, then Home without input]")
	var root = await _boot_main(_uniq("anim"), 1)
	var nav = root.get_navigation()
	var h = await _play(root)
	_drain(h)
	_ok(h.get_completion().is_won() and nav.current() == R.GAMEPLAY and nav.is_won_pending(), "real Level 1 WON: still GAMEPLAY (the board) while the win animation plays")
	var o = root.get_win_overlay()
	_ok(o != null and o.get_parent() == h and o.get_video_player() != null and o.get_video_player().is_playing(), "WinOverlay over the board plays the keyed WIN video")
	_ok(String((o.find_child("TitleLabel", true, false) as Label).text) == UiText.t("RESULTS_WON"), "level-complete title")
	var t0 := Time.get_ticks_msec()
	while nav.current() == R.GAMEPLAY and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	_ok(nav.current() == R.HOME and secs > 3.0, "Home opened by itself after the animation (%.1f s)" % secs)
	_ok(_routes == [R.HOME] and not _results_seen, "route sequence after the terminal %s; Results never visible" % str(_routes))
	_ok(root.get_gameplay_host() == null and nav.attempt_id() == 1 and root.get_app_state().progression.current_level() == 2, "no level started: host released, attempt 1, frontier waits at 2")
	_ok(String(nav.last_payload().get("via", "")) == "win" and root.get_home().visible, "HOME via win, Home visible")
	_shutdown(root)
	_complete("win_animation_then_home")

## Back during the animation goes Home at once and never starts a level.
func _back_skips_to_home() -> void:
	print("[Back skips the win animation]")
	var root = await _boot_main(_uniq("back"), 1)
	var nav = root.get_navigation()
	var h = await _play(root)
	_drain(h)
	_ok(root.get_win_overlay() != null, "animation running")
	_ok(root.handle_back() == "home" and nav.current() == R.HOME, "Back -> HOME")
	_ok(root.handle_back() == "none" and nav.current() == R.HOME and root.get_gameplay_host() == null and nav.attempt_id() == 1, "second Back on Home: nothing (no level starts)")
	_ok(_routes == [R.HOME] and not _results_seen and root.get_win_overlay() == null, "no Results; overlay gone with the host")
	_shutdown(root)
	_complete("back_skips_to_home")

## Rewards fly into the right HUD nodes from the receipt; HUD ends at the receipt's values;
## the Gift milestone ceremony opens on Home only after the flight.
func _flight_and_ceremony() -> void:
	print("[reward flight into the HUD, then the ceremony on Home]")
	var root = await _boot_main(_uniq("fly"), 0, 8)   # Gift 1 + 8 = 9: the win crosses milestone 10
	var app = root.get_app_state()
	var eco = app.economy
	var home = root.get_home()
	var sb0: int = eco.wallet.scrub_bucks()
	var parts0: int = int(eco.robots.next_robot_progress()["parts"])
	var h = await _play(root)
	_drain(h)
	var rc: Dictionary = h.get_terminal_receipt()
	_ok(root.get_navigation().current() == R.HOME and not _results_seen, "WON -> HOME at once (animation off in this case)")
	var flight = home.get_reward_flight()
	_ok(home.is_reward_flight_running() and flight.get_layer() != null, "reward flight running on Home")
	var want := {"Fly_scrub_bucks": "ScrubBucksChip", "Fly_bot_parts": "ProfileBotParts", "Fly_gift_meter": "GiftMeterBar", "Fly_win_streak": "TrackGift1"}
	var got := {}
	for c in flight.get_layer().get_children():
		got[String(c.name)] = String(c.get_meta("target"))
	_ok(got == want, "icons -> HUD targets %s" % str(got))
	var plan: Array = HomeRewardFlight.plan(rc, home.get_view_model())
	var sb_plan: Dictionary = plan[0]
	_ok(sb_plan["from"] == sb0 and sb_plan["to"] == sb0 + int(rc["wallet_delta"]["scrub_bucks"]), "SB counts %d -> %d (receipt delta %d)" % [sb_plan["from"], sb_plan["to"], rc["wallet_delta"]["scrub_bucks"]])
	_ok(_chip(home) == UiText.num(sb0), "HUD starts at the pre-win SB value")
	home.refresh()
	_ok(_chip(home) == UiText.num(sb0), "a Home refresh mid-flight keeps the counter (no jump to the final value)")
	var icon: Control = flight.get_layer().get_node("Fly_scrub_bucks")
	var dest: Vector2 = home.get_region("ScrubBucksChip").get_global_rect().get_center()
	var t1 := Time.get_ticks_msec()
	while flight._seq.current_step() < 2 and Time.get_ticks_msec() - t1 < 3000:
		await process_frame
	_ok(not icon.visible and icon.get_global_rect().get_center().distance_to(dest) < 2.0, "SB icon flew to the SB chip centre, then handed over to the count-up")
	_ok(root.get_ceremonies().presented_log().is_empty() and root.get_modal_stack().depth() == 0, "no ceremony while the rewards fly")
	_complete("flight_targets_hud")
	var t0 := Time.get_ticks_msec()
	while home.is_reward_flight_running() and Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	await _frames(3)
	_ok(not home.is_reward_flight_running() and flight.get_layer() == null, "flight finished, icons freed")
	_ok(_chip(home) == UiText.num(sb0 + int(rc["wallet_delta"]["scrub_bucks"])) and _chip(home) == UiText.num(eco.wallet.scrub_bucks()), "SB chip = receipt final %s" % _chip(home))
	var parts = home.get_region("ProfileBotParts")
	_ok(int(parts.bar.value) == parts0 + int(rc["wallet_delta"]["bot_parts"]), "Bot Parts meter = receipt final %d" % int(parts.bar.value))
	_ok(int(home.get_region("GiftMeterBar").bar.value) == int(rc["gift_meter"]["after"]) and int(rc["gift_meter"]["after"]) == 10, "Gift meter = receipt after (10)")
	_ok((home.get_region("TrackStreakValue") as Label).text == UiText.num(int(rc["streak"]["after"])), "Win Streak value = receipt after")
	var log: Array = root.get_ceremonies().presented_log()
	var cur = root.get_ceremonies().current()
	_ok(log.size() == 1 and String(log[0][1]) == "gift_milestone" and cur != null and root.get_navigation().current() == R.HOME, "Gift milestone ceremony opened on Home after the flight %s" % str(log))
	_shutdown(root)
	_complete("ceremony_after_flight")

## Rewards are the host terminal's (granted once); a relaunch shows Home without any flight.
func _granted_once_no_replay() -> void:
	print("[granted once, relaunch never replays]")
	var path := _uniq("once")
	var root = await _boot_main(path, 0)
	var app = root.get_app_state()
	var h = await _play(root)
	_drain(h)
	var tx: int = app.economy.reward.applied_transaction_count()
	var sb: int = app.economy.wallet.scrub_bucks()
	var t0 := Time.get_ticks_msec()
	while root.get_home().is_reward_flight_running() and Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	_ok(app.economy.reward.applied_transaction_count() == tx and app.economy.wallet.scrub_bucks() == sb, "the flight granted nothing (ledger %d, SB %d)" % [tx, sb])
	_ok(not root.get_home().play_reward_flight(h.get_terminal_receipt() if is_instance_valid(h) else {"status": "WON"}, "win:a1:L1"), "the same win key never flies twice")
	_shutdown(root, false)
	root = MainScene.instantiate()
	MainScript.boot_save_path_override = path
	get_root().add_child(root)
	await process_frame
	var app2 = root.get_app_state()
	_ok(root.get_navigation().current() == R.HOME and not root.get_home().is_reward_flight_running() and root.get_home().get_reward_flight().get_layer() == null, "relaunch: Home, no reward flight")
	_ok(app2.economy.wallet.scrub_bucks() == sb and app2.economy.reward.applied_transaction_count() == tx and app2.progression.current_level() == 2, "relaunch: same wallet / ledger / frontier")
	_shutdown(root)
	_complete("granted_once_no_replay")

func _loss_results_unchanged() -> void:
	print("[LOST keeps Results Retry / Home]")
	var root = await _boot_main(_uniq("lost"), 1)
	var nav = root.get_navigation()
	var h = await _play(root)
	h.get_completion().terminal_reached.emit(&"LOST", {})
	var res = root.get_results_screen()
	_ok(nav.current() == R.RESULTS and res.visible and root.get_win_overlay() == null, "LOST -> Results, no win animation")
	_ok(res.get_primary_button().visible and res.get_primary_button().text == UiText.t("RESULTS_RETRY") and res.get_home_button().visible and res.get_home_button().text == UiText.t("RESULTS_HOME"), "Retry primary + Home secondary")
	res.get_primary_button().pressed.emit()
	_ok(nav.current() == R.GAMEPLAY and nav.attempt_id() == 2, "Retry works")
	_shutdown(root)
	_complete("loss_results_unchanged")

func _reduced_effects() -> void:
	print("[Reduced Effects: still, short hold, rewards land at once]")
	var root = await _boot_main(_uniq("red"), 1, 8)
	var app = root.get_app_state()
	app.set_reduced_effects(true)
	var nav = root.get_navigation()
	var h = await _play(root)
	_drain(h)
	var o = root.get_win_overlay()
	_ok(o != null and o.get_video_player() == null, "Reduced: no video decoder, the keyed still")
	var t0 := Time.get_ticks_msec()
	while nav.current() == R.GAMEPLAY and Time.get_ticks_msec() - t0 < 5000:
		await process_frame
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	_ok(nav.current() == R.HOME and secs < 2.5, "Home after the short Reduced hold (%.1f s)" % secs)
	var home = root.get_home()
	_ok(not home.is_reward_flight_running() and home.get_reward_flight().has_played("win:a1:L1") and home.get_reward_flight().get_layer() == null, "no flight: final state landed at once")
	_ok(_chip(home) == UiText.num(app.economy.wallet.scrub_bucks()), "HUD at the final values")
	await _frames(3)
	_ok(root.get_ceremonies().presented_log().size() == 1, "ceremony follows at once")
	_shutdown(root)
	_complete("reduced_effects")

## SB-M57-001: the 5th play's interstitial waits for Home PLAY; never between the win and Home.
func _no_interstitial_before_home() -> void:
	print("[interstitial only at Home PLAY]")
	var root = await _boot_main(_uniq("ads"), 1)
	var app = root.get_app_state()
	var ads := MockAds.new()
	app.economy.ads.set_provider(ads)
	for _i in range(4):
		app.economy.ads.on_play_finished()
	var h = await _play(root)
	_drain(h)
	_ok(app.economy.ads.interstitial_due() and ads.interstitials.is_empty(), "5th play finished: due, nothing shown during the win animation")
	root.handle_back()
	_ok(root.get_navigation().current() == R.HOME and ads.interstitials.is_empty(), "nothing shown on the way Home")
	await _frames(2)
	root.get_modal_stack().clear("test")
	root.play_current_frontier()
	_ok(ads.interstitials.size() == 1, "shown at Home PLAY %s" % str(ads.interstitials))
	_shutdown(root)
	_complete("no_interstitial_before_home")

func _results_won_branch_removed() -> void:
	print("[Results WON branch removed]")
	var res = ResultsScreen.new()
	_ok(not res.has_method("reward_rows") and not res.has_method("set_ceremony_barrier") and not res.has_method("is_victory_layout"), "no WON rows / barrier / Victory layout API")
	res.free()
	var t := FileAccess.get_file_as_string("res://scripts/ui/home/home_reward_flight.gd") + FileAccess.get_file_as_string("res://scripts/ui/win_overlay.gd")
	var bad: Array = []
	for needle in [".grant(", ".credit(", ".claim(", "record_win", "request_save", "mark_seen"]:
		if t.find(needle) != -1:
			bad.append(needle)
	_ok(bad.is_empty(), "flight / overlay never grant, save or acknowledge %s" % str(bad))
	_complete("results_won_branch_removed")

# ---------------------------------------------------------------- helpers ----

## Boot main.tscn on a fresh test save. `anim` = boot_win_animation_override. The Gift Meter
## starts at 1 + `gift_extra` with its own ceremonies seen (a fresh L1 win would cross Gift 1).
func _boot_main(path: String, anim: int, gift_extra := 0):
	var seed = AppState.new(path)
	for o in seed.economy.gift.add_streak_sb("test_seed", 1 + gift_extra):
		seed.economy.meta_ui.mark_seen("gift:" + String(o["id"]))
	seed.request_save()
	MainScript.boot_save_path_override = path
	MainScript.boot_win_animation_override = anim
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	_routes = []
	_results_seen = false
	root.get_navigation().route_changed.connect(func(_f, to, _p):
		if to != R.GAMEPLAY:
			_routes.append(to))
	root.get_results_screen().visibility_changed.connect(func():
		if root.get_results_screen().visible and String(root.get_navigation().last_payload().get("status", "")) == "WON":
			_results_seen = true)
	return root

func _play(root):
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	return h

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

func _chip(home) -> String:
	return String(home.get_region("ScrubBucksChip").value_label.text)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _shutdown(root, reset := true) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	if reset:
		MainScript.boot_save_path_override = ""
		MainScript.boot_win_animation_override = -1

func _uniq(tag: String) -> String:
	var p := "user://sbphone_e_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	MainScript.boot_opening_override = -1
	MainScript.boot_level_intro_override = -1
	MainScript.boot_win_animation_override = -1
	MainScript.boot_save_path_override = ""
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
	print("SB-PHONE-2026-11-12-E win home evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
