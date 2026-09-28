extends SceneTree
## M43-C001A — Results foundation evidence (receipt/model, reward + Continue idempotency).
## Production path: real main.tscn root, real AppState graph, real ProductionGameplayHost
## terminal transaction, real ResultsScreen. Expected/completed case ledger.
##
## Run: godot --headless --path . -s res://tests/m43_c001a_results_foundation.gd

const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const FirstClearTransaction = preload("res://scripts/economy/first_clear_transaction.gd")
const TerminalRewardReceipt = preload("res://scripts/economy/terminal_reward_receipt.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const R := NavigationController.Route

var EXPECTED_CASES := [
	"receipt_matches_commit", "already_cleared_and_rollback", "duplicate_terminal_open_refresh",
	"rapid_continue_once", "stale_continue_rejected", "level10_no_next_content",
	"gift_milestone_handoff", "follow_ups_authoritative_only", "lost_retry_regression",
	"m42_contract_preserved", "results_never_grants_source",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	await _receipt_matches_commit()
	await _already_cleared_and_rollback()
	await _duplicate_terminal_open_refresh()
	await _rapid_continue_once()
	await _stale_continue_rejected()
	await _level10_no_next_content()
	await _gift_milestone_handoff()
	_follow_ups_authoritative_only()
	await _lost_retry_regression()
	await _m42_contract_preserved()
	_results_never_grants_source()
	_cleanup()
	_done()

## SB-M43-001/004: the receipt is exactly the committed terminal transaction.
func _receipt_matches_commit() -> void:
	print("[receipt matches commit]")
	var root = await _boot_main(_uniq("rc"))
	var app = root.get_app_state()
	var eco = app.economy
	var cfg = eco.config
	var sb0: int = eco.wallet.scrub_bucks()
	var bp0: int = eco.wallet.bot_parts()
	var h = await _play(root)
	_drain(h)
	_ok(h.get_completion().is_won() and root.get_navigation().current() == R.RESULTS, "real Level 1 WON -> RESULTS")
	var rc: Dictionary = h.get_terminal_receipt()
	var fc_sb: int = cfg.first_clear_sb(app.progression.class_for(1))
	_ok(rc["schema"] == TerminalRewardReceipt.SCHEMA and rc["status"] == "WON" and rc["level"] == 1, "receipt identity WON / level 1")
	_ok(rc["first_clear"] and not rc["already_cleared"] and rc["commit_reason"] == "ok", "first clear committed")
	_ok(rc["rewards"] == {"first_clear_sb": fc_sb, "first_clear_bot_parts": cfg.first_clear_bot_parts(), "win_streak_sb": 1, "win_streak_bot_parts": 0}, "reward components = committed service results %s" % str(rc["rewards"]))
	_ok(rc["wallet_delta"] == {"scrub_bucks": eco.wallet.scrub_bucks() - sb0, "bot_parts": eco.wallet.bot_parts() - bp0}, "wallet delta = real wallet change")
	_ok(rc["reconciled"] and rc["wallet_delta"]["scrub_bucks"] == fc_sb + 1, "components explain the whole wallet change")
	_ok(rc["streak"] == {"before": 0, "after": eco.streak.streak()} and eco.streak.streak() == 1, "streak 0 -> 1")
	_ok(rc["frontier"] == {"before": 1, "after": app.progression.current_level()} and app.progression.current_level() == 2, "frontier 1 -> 2")
	_ok(rc["gift_meter"]["before"] == 0 and rc["gift_meter"]["after"] == eco.gift.cycle_progress() and rc["gift_meter"]["newly_queued"].is_empty(), "gift meter 0 -> 1, no milestone")
	_ok(rc["cards_delta"] == 0 and rc["saved"], "no card change; terminal save committed")
	var kinds: Array = rc["reveal_queue"].map(func(e): return e["kind"])
	_ok(kinds == ["first_clear_sb", "win_streak_sb", "bot_parts", "gift_meter"], "ordered reveal queue %s" % str(kinds))
	_ok(rc["reveal_queue"].map(func(e): return e["seq"]) == [0, 1, 2, 3], "deterministic seq")
	_ok(rc["follow_ups"].is_empty(), "no follow-up ceremony without committed truth")
	var res = root.get_results_screen()
	var model: Dictionary = res.get_model()
	_ok(model["receipt"] == rc and model["attempt"] == 1 and model["continue"]["available"] and model["continue"]["next_level"] == 2, "Results model binds the host receipt + canonical next frontier")
	_ok(_labels(res.get_reward_lines_node()) == ResultsScreen.reward_lines(rc) and _labels(res.get_reward_lines_node()).size() == 4, "Results shows every committed reveal line at once (Reduced-Effects safe)")
	_ok(_labels(res.get_reward_lines_node())[0] == UiText.t("RESULTS_FIRST_CLEAR_SB", [fc_sb]), "first line = first-clear SB")
	var copy: Dictionary = h.get_terminal_receipt()
	copy["rewards"]["first_clear_sb"] = 999999
	var m2: Dictionary = res.get_model()
	m2["receipt"]["level"] = 77
	_ok(h.get_terminal_receipt() == rc and res.get_model()["receipt"] == rc, "receipt/model getters return detached copies")
	_shutdown(root)
	_complete("receipt_matches_commit")

## SB-M43-001/006 truth: a non-frontier WON (already cleared) and a rolled-back
## commit produce zero-reward receipts through the real host terminal path.
func _already_cleared_and_rollback() -> void:
	print("[already cleared / rollback]")
	var root = await _boot_main(_uniq("ac"))
	var app = root.get_app_state()
	var h = await _play(root)
	# Frontier moved past the running level (test seam) -> record_win rejects.
	app.progression.debug_set_current_level(2)
	var econ0: Dictionary = _econ(app.economy)
	h.get_completion().terminal_reached.emit(&"WON", {})
	var rc: Dictionary = h.get_terminal_receipt()
	_ok(rc["status"] == "WON" and rc["already_cleared"] and not rc["first_clear"] and rc["commit_reason"] == "not_frontier", "already-cleared WON: no first clear")
	_ok(rc["reveal_queue"].is_empty() and rc["follow_ups"].is_empty() and rc["wallet_delta"] == {"scrub_bucks": 0, "bot_parts": 0} and rc["reconciled"], "zero rewards, zero reveals")
	_ok(_econ(app.economy) == econ0 and app.progression.current_level() == 2, "economy/progression untouched")
	var res = root.get_results_screen()
	_ok(res.get_note_label().visible and res.get_note_label().text == UiText.t("RESULTS_ALREADY_CLEARED"), "Results states no progression reward")
	_ok(_labels(res.get_reward_lines_node()).is_empty(), "no reward lines")
	_shutdown(root)
	root = await _boot_main(_uniq("rb"))
	app = root.get_app_state()
	h = await _play(root)
	h.set_first_clear_fault_injector(func(stage): return stage == "streak")
	var e0: Dictionary = _econ(app.economy)
	h.get_completion().terminal_reached.emit(&"WON", {})
	rc = h.get_terminal_receipt()
	_ok(not rc["first_clear"] and rc["commit_reason"] == "rolled_back" and rc["commit_stage"] == "streak", "rolled-back commit reported truthfully")
	_ok(rc["reveal_queue"].is_empty() and rc["wallet_delta"]["scrub_bucks"] == 0 and _econ(app.economy) == e0 and app.progression.current_level() == 1, "rollback: nothing shown, nothing granted")
	_shutdown(root)
	_complete("already_cleared_and_rollback")

## SB-M43-007: duplicate terminal callbacks and repeated Results open/refresh grant nothing.
func _duplicate_terminal_open_refresh() -> void:
	print("[duplicate terminal / open / refresh]")
	var root = await _boot_main(_uniq("dup"))
	var app = root.get_app_state()
	var nav = root.get_navigation()
	var saves := [0]
	app.save.set_fault_injector(func(stage):
		if stage == "temp_write":
			saves[0] += 1
		return false)
	var h = await _play(root)
	_drain(h)
	var rc: Dictionary = h.get_terminal_receipt()
	var e0: Dictionary = _econ(app.economy)
	var p0: Dictionary = app.progression.snapshot()
	var tx0: int = app.economy.reward.applied_transaction_count()
	var s0: int = saves[0]
	var t0: int = nav.transition_id()
	for _i in range(5):
		h.get_completion().terminal_reached.emit(&"WON", {})
		h._on_terminal_reached(&"WON", {})
	var res = root.get_results_screen()
	for _i in range(5):
		res.show_model(root._results_model(nav.last_payload()))
		root._on_route_changed(R.GAMEPLAY, R.RESULTS, nav.last_payload())
	_ok(h.get_terminal_receipt() == rc, "receipt never rebuilt/overwritten by duplicates")
	_ok(_econ(app.economy) == e0 and app.progression.snapshot() == p0 and app.economy.reward.applied_transaction_count() == tx0, "no SB / Bot Parts / Gift / streak / progression change")
	_ok(saves[0] == s0 and nav.transition_id() == t0 and nav.current() == R.RESULTS, "no extra save, no extra route transition")
	_ok(res.get_model()["receipt"] == rc and _labels(res.get_reward_lines_node()).size() == 4, "refresh re-renders the same committed lines (no duplicated lines)")
	app.save.set_fault_injector(Callable())
	_shutdown(root)
	_complete("duplicate_terminal_open_refresh")

## SB-M43-005/008/014: rapid Continue -> exactly one transition, one host, exact frontier.
func _rapid_continue_once() -> void:
	print("[rapid continue once]")
	var root = await _boot_main(_uniq("rapid"))
	var app = root.get_app_state()
	var nav = root.get_navigation()
	var h = await _play(root)
	_drain(h)
	var rc: Dictionary = h.get_terminal_receipt()
	var e0: Dictionary = _econ(app.economy)
	var t0: int = nav.transition_id()
	var emitted := [0]
	var res = root.get_results_screen()
	res.continue_requested.connect(func(_a): emitted[0] += 1)
	for _i in range(10):
		res.get_primary_button().pressed.emit()   # same-frame taps
	var extra := 0
	for _i in range(5):
		if root.continue_from_results().get("ok", false):
			extra += 1
	await process_frame
	var h2 = root.get_gameplay_host()
	_ok(emitted[0] == 1 and extra == 0, "10 taps -> 1 Continue intent; 5 late direct calls refused")
	_ok(nav.transition_id() == t0 + 1 and nav.current() == R.GAMEPLAY and nav.attempt_id() == 2 and _hosts(root) == 1, "one transition, one new attempt, one host")
	_ok(h2 != h and int(h2.progression_level) == rc["frontier"]["after"] and int(h2.progression_level) == app.progression.current_level(), "launched the exact canonical frontier (level %d)" % int(h2.progression_level))
	_ok(_econ(app.economy) == e0, "Continue grants nothing")
	_shutdown(root)
	_complete("rapid_continue_once")

## Stale Continue from an earlier Results can never launch.
func _stale_continue_rejected() -> void:
	print("[stale continue]")
	var root = await _boot_main(_uniq("stale"))
	var nav = root.get_navigation()
	var h = await _play(root)
	_drain(h)
	var res = root.get_results_screen()
	res.get_primary_button().pressed.emit()        # attempt 1 -> Level 2
	await process_frame
	var h2 = root.get_gameplay_host()
	h2.get_runtime().set_process(false)
	h2.get_completion().terminal_reached.emit(&"WON", {})   # attempt 2 Results
	_ok(nav.current() == R.RESULTS and nav.last_payload()["attempt"] == 2, "attempt 2 Results shown")
	var t0: int = nav.transition_id()
	var r: Dictionary = root.continue_from_results(1)
	res.continue_requested.emit(1)
	_ok(r.get("reason", "") == "stale_results" and nav.transition_id() == t0 and root.get_gameplay_host() == h2, "stale attempt-1 Continue refused, no transition/host change")
	var cur: Dictionary = root.continue_from_results(2)
	_ok(cur.get("ok", false) and nav.current() == R.GAMEPLAY and nav.transition_id() == t0 + 1, "current attempt-2 Continue accepted once")
	# LOST Results never accept a Continue.
	var h3 = root.get_gameplay_host()
	h3.get_runtime().set_process(false)
	h3.get_completion().terminal_reached.emit(&"LOST", {})
	var t1: int = nav.transition_id()
	_ok(root.continue_from_results().get("reason", "") == "not_won" and nav.transition_id() == t1 and root.get_gameplay_host() == h3, "LOST Results: Continue refused")
	_shutdown(root)
	_complete("stale_continue_rejected")

## Level 10 -> frontier 11 CONTENT_MISSING: clean unavailable Continue, no mutation.
func _level10_no_next_content() -> void:
	print("[level 10 no next content]")
	var root = await _boot_main(_uniq("l10"))
	var app = root.get_app_state()
	var nav = root.get_navigation()
	app.progression.debug_set_current_level(10)
	var h = await _play(root)
	_ok(int(h.progression_level) == 10, "frontier Level 10 launched")
	h.get_completion().terminal_reached.emit(&"WON", {})
	var rc: Dictionary = h.get_terminal_receipt()
	_ok(rc["first_clear"] and rc["frontier"] == {"before": 10, "after": 11} and rc["rewards"]["first_clear_sb"] == app.economy.config.first_clear_sb(app.progression.class_for(10)), "Level 10 first clear committed")
	var res = root.get_results_screen()
	var model: Dictionary = res.get_model()
	_ok(model["continue"] == {"available": false, "reason": "CONTENT_MISSING", "next_level": 11}, "model: next frontier 11 CONTENT_MISSING")
	_ok(res.get_primary_button().disabled and res.get_note_label().visible and res.get_note_label().text == UiText.t("RESULTS_NEXT_UNAVAILABLE", [11]), "Continue disabled with clear unavailable state")
	var e0: Dictionary = _econ(app.economy)
	var p0: Dictionary = app.progression.snapshot()
	var t0: int = nav.transition_id()
	var emitted := [0]
	res.continue_requested.connect(func(_a): emitted[0] += 1)
	for _i in range(3):
		res.get_primary_button().pressed.emit()
	var r: Dictionary = root.continue_from_results()
	_ok(emitted[0] == 0 and r.get("reason", "") == "no_next_content", "taps no-op; direct Continue -> no_next_content")
	_ok(_econ(app.economy) == e0 and app.progression.snapshot() == p0 and nav.transition_id() == t0 and root.get_gameplay_host() == h and nav.current() == R.RESULTS, "no mutation, no transition, host kept")
	_ok(res.get_primary_button().disabled and res.get_model()["receipt"] == rc, "still a clean unavailable Continue with the same receipt")
	res.get_home_button().pressed.emit()
	await process_frame
	_ok(nav.current() == R.HOME, "HOME still works")
	_shutdown(root)
	_complete("level10_no_next_content")

## SB-M43-012: crossing a Gift Meter milestone is handed off (queued, unclaimed), never granted by Results.
func _gift_milestone_handoff() -> void:
	print("[gift milestone handoff]")
	var root = await _boot_main(_uniq("gift"))
	var app = root.get_app_state()
	var eco = app.economy
	eco.gift.add_streak_sb("m43_seed", 9)    # 9/1000; the Level 1 streak SB (+1) crosses 10
	var h = await _play(root)
	_drain(h)
	var rc: Dictionary = h.get_terminal_receipt()
	var nq: Array = rc["gift_meter"]["newly_queued"]
	_ok(nq.size() == 1 and nq[0]["milestone"] == 10 and rc["gift_meter"]["before"] == 9 and rc["gift_meter"]["after"] == 10, "receipt: 9 -> 10 crosses milestone 10")
	_ok(rc["follow_ups"] == [{"kind": "gift_milestone", "occurrence_id": nq[0]["id"], "milestone": 10, "cycle": 0, "claim_surface": "gift_bar"}], "one gift_milestone handoff to the Gift Bar")
	var gift_entry: Array = rc["reveal_queue"].filter(func(e): return e["kind"] == "gift_meter")
	_ok(gift_entry.size() == 1 and gift_entry[0]["milestones"] == [10], "reveal queue carries the crossed milestone")
	_ok(eco.gift.claimable().size() == 1 and eco.gift.claimable()[0]["id"] == nq[0]["id"] and rc["reconciled"], "milestone queued unclaimed; no gift reward in the wallet delta")
	var res = root.get_results_screen()
	_ok(_labels(res.get_reward_lines_node()).has(UiText.t("RESULTS_GIFT_READY")), "Results announces the gift handoff")
	var e0: Dictionary = _econ(eco)
	for _i in range(3):
		res.show_model(root._results_model(root.get_navigation().last_payload()))
	_ok(_econ(eco) == e0 and eco.gift.claimable().size() == 1, "refresh never claims/queues again")
	var claim: Dictionary = eco.gift.claim(nq[0]["id"], eco.reward, eco.config)
	var again: Dictionary = eco.gift.claim(nq[0]["id"], eco.reward, eco.config)
	_ok(claim.get("ok", false) and not again.get("ok", true), "canonical Gift Bar claim still grants exactly once")
	_shutdown(root)
	_complete("gift_milestone_handoff")

## SB-M43-013: follow-ups come only from committed state changes; feature/world never.
func _follow_ups_authoritative_only() -> void:
	print("[follow-ups authoritative only]")
	var app = AppState.new(_uniq("fu"))
	var pre: Dictionary = TerminalRewardReceipt.capture(app.progression, app.economy)
	var same: Dictionary = TerminalRewardReceipt.build("WON", 1, pre, pre, {"ok": false, "reason": "not_frontier"}, {"ok": true})
	_ok(same["follow_ups"].is_empty() and same["reveal_queue"].is_empty(), "no state change -> no follow-up, no reveal")
	# Real robot unlock commit between probes (spend Bot Parts through the service).
	app.economy.wallet.credit("bot_parts", app.economy.robots.unlock_cost())
	var pre2: Dictionary = TerminalRewardReceipt.capture(app.progression, app.economy)
	_ok(app.economy.robots.unlock("atlas").get("ok", false), "robot unlock committed by its service")
	var post2: Dictionary = TerminalRewardReceipt.capture(app.progression, app.economy)
	var rr: Dictionary = TerminalRewardReceipt.build("WON", 1, pre2, post2, {"ok": false, "reason": "not_frontier"}, {"ok": true})
	var kinds: Array = rr["follow_ups"].map(func(f): return f["kind"])
	_ok(kinds == ["robot_unlock"], "committed robot unlock -> robot_unlock handoff only %s" % str(kinds))
	var src := FileAccess.get_file_as_string("res://scripts/economy/terminal_reward_receipt.gd")
	_ok(src.find("\"feature_unlock\"") == -1 and src.find("\"world_unlock\"") == -1, "no feature/world ceremony is ever emitted (no authority exists)")
	_ok(same.is_read_only(), "receipt is read-only")
	_complete("follow_ups_authoritative_only")

## LOST Retry (M30) unchanged; LOST receipt = committed Heart/streak truth.
func _lost_retry_regression() -> void:
	print("[LOST retry regression]")
	var root = await _boot_main(_uniq("lost"))
	var app = root.get_app_state()
	var nav = root.get_navigation()
	var hearts0: int = app.economy.hearts.hearts()
	var h = await _play(root)
	h.get_completion().terminal_reached.emit(&"LOST", {})
	var rc: Dictionary = h.get_terminal_receipt()
	_ok(rc["status"] == "LOST" and not rc["first_clear"] and rc["hearts"] == {"before": hearts0, "after": hearts0 - 1} and rc["streak"]["after"] == 0, "LOST receipt: -1 Heart, streak 0")
	_ok(rc["reveal_queue"].is_empty() and rc["wallet_delta"] == {"scrub_bucks": 0, "bot_parts": 0}, "LOST: no reward reveal")
	var res = root.get_results_screen()
	_ok(res.get_primary_button().text == UiText.t("RESULTS_RETRY") and not res.get_primary_button().disabled, "RETRY offered")
	res.get_primary_button().pressed.emit()
	_ok(nav.current() == R.GAMEPLAY and nav.attempt_id() == 2 and root.get_gameplay_host() == h, "Retry = same host, transaction-safe, attempt 2")
	_ok(h.get_terminal_receipt().is_empty() and app.economy.hearts.hearts() == hearts0 - 1, "fresh attempt: receipt cleared, no second Heart")
	_ok(h.get_board().count_cells_by_state(0) > 0 and not h.get_completion().is_terminal(), "board restored ACTIVE, PLAYING")
	_shutdown(root)
	_complete("lost_retry_regression")

## M42 contract: nav payload stays minimal; show_result() compatibility; ERROR = HOME only.
func _m42_contract_preserved() -> void:
	print("[M42 contract preserved]")
	var root = await _boot_main(_uniq("m42"))
	var nav = root.get_navigation()
	var h = await _play(root)
	_drain(h)
	_ok(nav.last_payload() == {"status": "WON", "level": 1, "attempt": 1}, "navigation payload unchanged (receipt not in nav)")
	_shutdown(root)
	var res = ResultsScreen.new()
	get_root().add_child(res)
	res.show_result({"status": "WON", "level": 3, "attempt": 1}, true)
	_ok(res.get_payload() == {"status": "WON", "level": 3, "attempt": 1} and not res.get_primary_button().disabled and _labels(res.get_reward_lines_node()).is_empty(), "legacy show_result still works (no receipt -> no lines)")
	res.show_result({"status": "ERROR", "level": 3, "attempt": 1}, true)
	_ok(not res.get_primary_button().visible, "ERROR: HOME only")
	res.free()
	_complete("m42_contract_preserved")

func _results_never_grants_source() -> void:
	print("[Results never grants (source)]")
	var bad: Array = []
	for f in ["res://scripts/ui/results_screen.gd", "res://scripts/app/main.gd", "res://scripts/economy/terminal_reward_receipt.gd"]:
		var t := _strip_comments(FileAccess.get_file_as_string(f))
		for needle in [".grant(", "grant_first_clear", "process_first_clear_win", "FirstClearTransaction", ".claim(", "add_streak_sb", ".credit(", ".debit(", "record_win"]:
			if t.find(needle) != -1:
				bad.append([f, needle])
	_ok(bad.is_empty(), "Results/app/receipt code never calls a grant/commit API %s" % str(bad))
	_complete("results_never_grants_source")

# ---------------------------------------------------------------- helpers ----

func _play(root):
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	return h

## Economy snapshot minus the two wall-clock bookkeeping fields (Heart regen anchor,
## timed-2x clock high-water) that tick with real time while the test runs.
func _econ(eco) -> Dictionary:
	var s: Dictionary = eco.snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	return s

## Shown reward-row texts (C001B rows are icon+text cards; see ResultsScreen.shown_row_texts).
func _labels(box: Node) -> Array:
	var out: Array = []
	for c in box.get_children():
		if c.is_queued_for_deletion():
			continue
		for l in ([c] if c is Label else c.find_children("Text", "Label", true, false)):
			out.append(l.text)
	return out

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

func _strip_comments(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var i := line.find("#")
		out.append(line if i == -1 else line.substr(0, i))
	return "\n".join(out)

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
	var p := "user://m43c001a_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
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
	print("M43-C001A results foundation evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
