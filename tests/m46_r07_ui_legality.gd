extends SceneTree
## M46 R07 — the two remaining player-facing booster legality checks (rewarded-grant completion,
## FTUE booster coach copy) never run a main-thread still-moment proof: they use the shared R06
## off-frame seam (exact-state cache, one WorkerThreadPool proof, 5 s cap, sticky cancel).
## Real app (main scene), rewarded provider test double, local only.
## Every async case asserts it reached its branch (job running / auto_use armed) before PASS,
## and counts synchronous proofs (ProductionBoosterAdapter.live_proof_count) across the flow.
## Run: godot --headless --path . -s res://tests/m46_r07_ui_legality.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const RANDOM := "random"
const FRAME_SPIKE_MS := 16.7
var _fail := 0
var _tmp: Array = []
var _sub: SubViewport = null
var _root = null
var _host = null
var _prov = null

func _initialize() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	await process_frame
	await _rewarded_complete()
	await _rewarded_after_proof()
	await _rewarded_cached_timeout()
	await _rewarded_selector()
	await _rewarded_cancel_reopen()
	await _rewarded_timeout_retry()
	await _rewarded_scene_exit()
	await _rewarded_refused()
	await _ftue_copy()
	_shutdown()
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for f in [p, p + ".bak", p + ".tmp"]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("M46 R07 UI LEGALITY: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

# ------------------------------------------------------------------ fixtures ----

func _boot_play(level: int) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m46r07_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	_prov = ProviderDouble.new()
	_eco().rewarded.set_provider(_prov)
	_root.get_modal_stack().clear("t")
	# SB-M44-031: boosters are locked on a fresh L2 profile; open them in the in-memory unlock
	# table so the L2 booster coach this suite exercises still runs.
	for b in ["plus_one_slot", "random", "selector", "tornado"]:
		_root.get_app_state().unlocks.cfg["unlocks"][b] = 1
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _frames(6)
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)
	_root.get_modal_stack().clear("t")
	await _frames(2)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null

func _eco():
	return _root.get_app_state().economy

func _acq():
	return _root.get_acquisition()

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _lp() -> int:
	return _host.get_booster_adapter().live_proof_count

func _supply() -> Array:
	var out: Array = []
	for col in _host.get_supply().debug_snapshot()["columns"]:
		for bd in col:
			out.append(String(bd["batch_id"]))
	return out

func _txt(p, node: String) -> String:
	var l = p.find_child(node, true, false)
	return l.text if l != null else "<missing>"

## Frames until the off-frame proof ends -> [worst WAIT frame ms, waited ms, settle frame ms].
## Measured separately (not proof cost): the first 2 frames (just-opened popup build) and the
## frame the proof settles in (result applied + popup / coach refresh + an auto-used booster's
## economy commit, deferred to that frame's end). Then 4 frames to let everything land.
func _wait_proof(cap_ms: float = 7000.0) -> Array:
	var frames: Array = []
	var t0 := Time.get_ticks_usec()
	await _frames(2)
	while _host.is_booster_proof_running() and (Time.get_ticks_usec() - t0) / 1000.0 < cap_ms:
		var tf := Time.get_ticks_usec()
		await process_frame
		frames.append((Time.get_ticks_usec() - tf) / 1000.0)
	var settle: float = frames.pop_back() if not frames.is_empty() else 0.0
	var waited := (Time.get_ticks_usec() - t0) / 1000.0
	await _frames(4)
	return [frames.max() if not frames.is_empty() else 0.0, waited, settle]

## Open the zero-charge Random popup and complete a rewarded video IN THE SAME FRAME, while the
## popup's own off-frame proof is still running (the stall case R07 removes).
func _watch_complete_now() -> Dictionary:
	var p = _acq().open_booster(_host, RANDOM)
	var running_at_open: bool = _host.is_booster_proof_running()
	p.get_action_button("watch").pressed.emit()
	_prov.deliver_last({"outcome": "completed", "verified": true})
	return {"p": p, "running_at_open": running_at_open}

# ------------------------------------------------------------------ rewarded ----

func _rewarded_complete() -> void:
	print("[rewarded Random at a still L1 start: grant now, use once proven off-frame]")
	await _boot_play(1)
	var sb0: int = _eco().wallet.scrub_bucks()
	var tx0: int = _eco().reward.applied_transaction_count()
	var lp0 := _lp()
	var s0 := _supply()
	var w := _watch_complete_now()
	var p = w["p"]
	var armed: bool = w["running_at_open"] and _host.is_booster_proof_running() and p.context.get("auto_use", false) \
		and _eco().boosters.charges(RANDOM) == 1 and _txt(p, "Status") == UiText.t("BOOSTER_CHARGE_SAVED") \
		and _txt(p, "Safety") == UiText.t("BOOSTER_CHECKING") and p.get_action_button("use").disabled
	_ok(armed and _lp() == lp0, "ad completes while checking: charge granted (+1), status Charge saved, Checking..., Use blocked, auto-use armed, NO main-thread proof")
	var wp: Array = await _wait_proof()
	var used: bool = _eco().boosters.charges(RANDOM) == 0 and _supply() != s0 and (not is_instance_valid(p) or not p.is_open())
	print("    proof settled after %.0f ms (worst wait frame %.1f ms; settle + auto-use commit frame %.1f ms, report-only); used %s" % [wp[1], wp[0], wp[2], str(used)])
	_ok(used and _eco().reward.applied_transaction_count() == tx0 + 1 and _eco().wallet.scrub_bucks() == sb0 and _lp() == lp0,
		"proven legal -> granted charge used exactly once, popup closed, one reward receipt, SB unchanged, 0 main-thread proofs")
	_ok(wp[0] < FRAME_SPIKE_MS, "no frame >= %.1f ms while the worker proves (worst %.1f ms)" % [FRAME_SPIKE_MS, wp[0]])

func _rewarded_after_proof() -> void:
	print("[rewarded Random after the popup's proof already settled legal: immediate use]")
	await _boot_play(1)
	var tx0: int = _eco().reward.applied_transaction_count()
	var p = _acq().open_booster(_host, RANDOM)
	await _wait_proof()
	var cached: bool = _host.get_booster_adapter().cached_verdict("random") == true and not _host.is_booster_proof_running()
	var lp0 := _lp()
	p.get_action_button("watch").pressed.emit()
	_prov.deliver_last({"outcome": "completed", "verified": true})
	await _frames(2)
	_ok(cached and _eco().boosters.charges(RANDOM) == 0 and not is_instance_valid(p) or (cached and not p.is_open() and _eco().boosters.charges(RANDOM) == 0),
		"cached legal verdict -> the granted charge is used at once (popup closed)")
	_ok(_lp() == lp0 and _eco().reward.applied_transaction_count() == tx0 + 1 and not _host.is_booster_proof_running(),
		"immediate branch: no main-thread proof, no new worker, one receipt")

func _rewarded_cached_timeout() -> void:
	print("[rewarded Random on a cached timeout: charge saved at once]")
	await _boot_play(1)
	_host.get_booster_adapter().offframe_budget_ms = 1
	var p = _acq().open_booster(_host, RANDOM)
	await _wait_proof()
	var timed: bool = typeof(_host.get_booster_adapter().cached_verdict("random")) == TYPE_STRING
	var lp0 := _lp()
	var tx0: int = _eco().reward.applied_transaction_count()
	p.get_action_button("watch").pressed.emit()
	_prov.deliver_last({"outcome": "completed", "verified": true})
	await _frames(2)
	_ok(timed and p.is_open() and _eco().boosters.charges(RANDOM) == 1 and not _host.is_booster_proof_running() and _lp() == lp0
		and _txt(p, "Status") == UiText.t("BOOSTER_CHARGE_SAVED") and _txt(p, "Safety") == UiText.t("BOOSTER_SAFETY_BUSY")
		and not p.context.get("auto_use", true) and _eco().reward.applied_transaction_count() == tx0 + 1,
		"cached timeout -> charge saved at once (retry text), no worker, no main-thread proof, no auto-use, one receipt")
	p.close("x")
	await _frames(2)

func _rewarded_selector() -> void:
	print("[rewarded Selector while checking: granted, never auto-used (needs a target)]")
	await _boot_play(1)
	var tx0: int = _eco().reward.applied_transaction_count()
	var lp0 := _lp()
	var s0 := _supply()
	var p = _acq().open_booster(_host, "selector")
	var running: bool = _host.is_booster_proof_running()
	p.get_action_button("watch").pressed.emit()
	_prov.deliver_last({"outcome": "completed", "verified": true})
	var armed: bool = p.context.get("auto_use", false)
	await _wait_proof()
	var chips: int = (p.get_meta("legality").get("targets", []) as Array).size()
	_ok(running and not armed and p.is_open() and _eco().boosters.charges("selector") == 1 and _supply() == s0 and chips > 0
		and p.get_action_button("use").disabled and _lp() == lp0 and _eco().reward.applied_transaction_count() == tx0 + 1,
		"Selector: charge granted and kept, no auto-use, proven chips appear (%d), Use waits for a chosen target, no main-thread proof" % chips)
	p.close("x")
	await _frames(2)

func _rewarded_cancel_reopen() -> void:
	print("[rewarded Random: close mid-check -> charge kept; reopen proves; Use retries]")
	await _boot_play(1)
	var tx0: int = _eco().reward.applied_transaction_count()
	var lp0 := _lp()
	var w := _watch_complete_now()
	var p = w["p"]
	var reached: bool = w["running_at_open"] and _host.is_booster_proof_running() and p.context.get("auto_use", false)
	p.close("x")
	await _frames(2)
	var kept: bool = not _host.is_booster_proof_running() and _eco().boosters.charges(RANDOM) == 1 \
		and _host.get_booster_adapter()._verdicts.is_empty()
	_ok(reached and kept and _eco().reward.applied_transaction_count() == tx0 + 1 and _lp() == lp0,
		"closed mid-check: worker cancelled, granted charge kept (no use, no refund, one receipt), nothing cached, no main-thread proof")
	var q = _acq().open_booster(_host, RANDOM)
	var checking: bool = _host.is_booster_proof_running() and _txt(q, "Safety") == UiText.t("BOOSTER_CHECKING")
	await _wait_proof()
	var ready: bool = q.is_open() and _eco().boosters.charges(RANDOM) == 1 and not q.get_action_button("use").disabled
	_ok(checking and ready, "reopen -> Checking..., then proven: Use enabled with the kept charge (no auto-use on a plain reopen)")
	q.get_action_button("use").pressed.emit()
	await _frames(3)
	_ok(_eco().boosters.charges(RANDOM) == 0 and (not is_instance_valid(q) or not q.is_open()) and _eco().reward.applied_transaction_count() == tx0 + 1 and _lp() == lp0,
		"Use -> the kept charge used once from the cached verdict (0 main-thread proofs)")

func _rewarded_timeout_retry() -> void:
	print("[rewarded Random: proof timeout -> charge kept, cached; retry after a state change]")
	await _boot_play(1)
	_host.get_booster_adapter().offframe_budget_ms = 1   # deterministic timeout
	var tx0: int = _eco().reward.applied_transaction_count()
	var lp0 := _lp()
	var w := _watch_complete_now()
	var p = w["p"]
	var reached: bool = w["running_at_open"] and p.context.get("auto_use", false)
	await _wait_proof()
	var refused: bool = p.is_open() and _eco().boosters.charges(RANDOM) == 1 and _txt(p, "Safety") == UiText.t("BOOSTER_SAFETY_BUSY") \
		and _txt(p, "Status") == UiText.t("BOOSTER_CHARGE_SAVED") and p.get_action_button("use").disabled and not p.context.get("auto_use", true)
	_ok(reached and refused and _eco().reward.applied_transaction_count() == tx0 + 1 and _lp() == lp0,
		"timeout -> charge kept, retry text, Use blocked, auto-use disarmed, one receipt, no main-thread proof")
	p.close("x")
	await _frames(2)
	var q = _acq().open_booster(_host, RANDOM)
	_ok(not _host.is_booster_proof_running() and _txt(q, "Safety") == UiText.t("BOOSTER_SAFETY_BUSY") and _lp() == lp0,
		"reopen on the SAME state -> cached timeout at once: no new worker, no main-thread proof")
	q.close("x")
	await _frames(2)
	_host.get_booster_adapter().offframe_budget_ms = _host.get_booster_adapter().PROOF_TOTAL_MS
	var moved := false
	for col in range(_host.get_supply().get_column_count()):
		if _host.get_input_controller().activate_front(col).get("ok", false):
			moved = true
			break
	for _i in range(4000):
		_host.get_runtime().tick(1.0 / 60.0)
		await process_frame
		if _host.get_scheduler().live_assignment_count() == 0:
			break
	var r = _acq().open_booster(_host, RANDOM)
	var rechecking: bool = _host.is_booster_proof_running() and _txt(r, "Safety") == UiText.t("BOOSTER_CHECKING")
	await _wait_proof()
	_ok(moved and rechecking and _txt(r, "Safety") != UiText.t("BOOSTER_CHECKING") and _eco().boosters.charges(RANDOM) == 1,
		"after a real move the player can retry: a fresh off-frame check runs and settles (charge still kept)")
	r.close("x")
	await _frames(2)

func _rewarded_scene_exit() -> void:
	print("[rewarded Random: leave gameplay mid-check]")
	await _boot_play(1)
	var tx0: int = _eco().reward.applied_transaction_count()
	var w := _watch_complete_now()
	var reached: bool = w["running_at_open"] and _host.is_booster_proof_running()
	var seen := _watch_exit_settle(_host)
	_root._release_gameplay_host()
	await _frames(3)
	_ok(reached and _no_exit_proof(seen) and _root.get_gameplay_host() == null
		and _eco().boosters.charges(RANDOM) == 1 and _eco().reward.applied_transaction_count() == tx0 + 1,
		"scene exit mid-check: worker cancelled + joined (settled, nothing restarted), host freed, granted charge kept, exactly one receipt")

## Record, at the exiting host's settle signal (after every earlier listener, e.g. the coach
## refresh), whether a new worker was started on that host or any main-thread proof ran.
func _watch_exit_settle(h) -> Dictionary:
	var ad = h.get_booster_adapter()
	var seen := {"lp0": ad.live_proof_count, "ad": ad}
	h.booster_proof_settled.connect(func(_id):
		seen["settled"] = true
		seen["running_after"] = h.is_booster_proof_running())
	return seen

func _no_exit_proof(seen: Dictionary) -> bool:
	return seen.get("settled", false) and not seen.get("running_after", true) and seen["ad"].live_proof_count == seen["lp0"]

func _rewarded_refused() -> void:
	print("[rewarded Random at a still L2 start: not provable -> charge kept]")
	await _boot_play(2)
	var tx0: int = _eco().reward.applied_transaction_count()
	var lp0 := _lp()
	var s0 := _supply()
	var w := _watch_complete_now()
	var p = w["p"]
	var reached: bool = w["running_at_open"] and p.context.get("auto_use", false)
	var wp: Array = await _wait_proof()
	var why: String = _txt(p, "Safety")
	print("    L2 settled after %.0f ms (worst wait frame %.1f ms; settle frame %.1f ms): %s" % [wp[1], wp[0], wp[2], why])
	var kept: bool = p.is_open() and _eco().boosters.charges(RANDOM) == 1 and _supply() == s0 \
		and why in [UiText.t("BOOSTER_SAFETY_RANDOM"), UiText.t("BOOSTER_SAFETY_BUSY")]
	_ok(reached and kept and _eco().reward.applied_transaction_count() == tx0 + 1 and _lp() == lp0 and wp[0] < FRAME_SPIKE_MS,
		"not proven (unsafe or 5 s cap) -> charge kept, supply untouched, one receipt, no main-thread proof, no frame spike")
	p.close("x")
	await _frames(2)

# ---------------------------------------------------------------------- FTUE ----

func _body() -> String:
	return _root.get_coachmarks().get_body_label().text

## The coach line for booster `id` carries "not now" exactly when its cached verdict says so.
func _line_matches(id: String, kind: String) -> bool:
	var name := UiText.t("BOOSTER_NAME_" + id.to_upper())
	var line := ""
	for l in _body().split("\n"):
		if l.contains(name):
			line = l
	var v = _host.get_booster_adapter().cached_verdict(kind)
	if v == null:
		return false
	var legal: bool = (typeof(v) == TYPE_BOOL and v) if kind == "random" else not (v["ids"] as Array).is_empty()
	return line != "" and line.contains(UiText.t("FTUE_BOOSTER_NOT_NOW")) == (not legal)

func _ftue_copy() -> void:
	print("[FTUE L2 booster coach copy at a still start]")
	MainScript.boot_ftue_override = 1   # FTUE runs on a test save path only with this seam (as m44)
	await _boot_play(2)
	MainScript.boot_ftue_override = -1
	var cm = _root.get_coachmarks()
	var ftue = _root.get_ftue()
	var sb0: int = _eco().wallet.scrub_bucks()
	var lp0 := _lp()
	_ok(ftue.tips_active(), "fresh profile: tips active at L2")
	_root.refresh_coachmark()
	var a_step: bool = cm.get_step_id() == "l2_boosters_a"
	var sel_line_checking: bool = _host.is_booster_proof_running() and not _body().contains(UiText.t("FTUE_BOOSTER_NOT_NOW"))
	_ok(a_step and sel_line_checking and _lp() == lp0, "phase A copy: Selector line starts the shared off-frame check, no 'not now' claim while checking, no main-thread proof")
	var wa: Array = await _wait_proof()
	_ok(_line_matches("selector", "selector_list") and _lp() == lp0 and wa[0] < FRAME_SPIKE_MS,
		"settle re-renders the copy: Selector 'not now' iff its proven verdict refuses (worst frame %.1f ms)" % wa[0])
	cm.get_got_it_button().pressed.emit()
	_root.refresh_coachmark()
	var b_step: bool = cm.get_step_id() == "l2_boosters_b" and _host.is_booster_proof_running()
	# Stale: the player moves while Random is being checked -> that verdict is dropped.
	var key0: Array = _host.get_booster_adapter().state_key()
	# At EVERY settle: a Random verdict stored under the OLD state would be the stale result. (The
	# coach's next copy refresh may instead stop the stale job silently and prove the new state.)
	var first := {"settles": 0, "stale_stored": false}
	var ad = _host.get_booster_adapter()
	var rec := func(_id):
		first["settles"] += 1
		if ad._verdicts.has("random") and ad._verdict_key == key0:
			first["stale_stored"] = true
	_host.booster_proof_settled.connect(rec)
	for col in range(_host.get_supply().get_column_count()):
		if _host.get_input_controller().activate_front(col).get("ok", false):
			break
	var moved: bool = _host.get_booster_adapter().state_key() != key0
	await _wait_proof()
	_host.booster_proof_settled.disconnect(rec)
	_ok(first["settles"] > 0 and not first["stale_stored"], "no settle ever stored a Random verdict under the old state (%d settle(s))" % first["settles"])
	print("    phase B: step %s, running-at-start %s, moved %s, random verdict cached %s, live proofs %d" % [
		cm.get_step_id(), str(b_step), str(moved), str(_host.get_booster_adapter()._verdicts.has("random")), _lp() - lp0])
	# Dropped = nothing stored under the OLD state (the settle refresh may already have proven the
	# NEW state off-frame; that verdict is keyed to the new state).
	_ok(b_step and moved and _host.get_booster_adapter()._verdict_key != key0 and _lp() == lp0,
		"phase B: Random check started by the copy; a move mid-check drops its old-state verdict (no stale 'not now' / no main-thread proof)")
	for _i in range(4000):
		_host.get_runtime().tick(1.0 / 60.0)
		await process_frame
		if _host.get_scheduler().live_assignment_count() == 0:
			break
	_root._coach_copy["at"] = 0
	_root.refresh_coachmark()
	var rechecks: bool = _host.is_booster_proof_running()
	await _wait_proof()
	_ok(rechecks and cm.get_step_id() == "l2_boosters_b" and _line_matches("random", "random") and _lp() == lp0,
		"at the next still moment the copy re-checks off-frame and shows the proven Random verdict")
	# A modal hides the coach, and the copy then starts no proof.
	_host.cancel_booster_proof()
	_host.get_booster_adapter()._verdicts.clear()
	var pause = _host.open_pause()
	_root._coach_copy["at"] = 0
	_root.refresh_coachmark()
	await _frames(2)
	_ok(pause != null and not cm.is_showing() and not _host.is_booster_proof_running(), "modal open: coach hidden, no proof started by the copy")
	_root.get_modal_stack().clear("t")
	await _frames(2)
	# Leaving gameplay while the coach's proof runs (tips active): nothing restarts on the exiting host.
	_root._coach_copy["at"] = 0
	_root.refresh_coachmark()
	var exit_running: bool = _host.is_booster_proof_running()
	var seen := _watch_exit_settle(_host)
	var c0 := 0
	for id in ["plus_one_slot", "random", "selector", "tornado"]:
		c0 += int(_eco().boosters.charges(id))
	_root._release_gameplay_host()
	await _frames(3)
	_ok(exit_running and _no_exit_proof(seen) and _root.get_gameplay_host() == null,
		"FTUE active, host released mid-check: worker joined, the settle-triggered coach refresh starts no new worker on the exiting host")
	var skipped: bool = ftue.skip_tips()
	_root.refresh_coachmark()
	_ok(skipped, "Skip Tips accepted once")
	var c1 := 0
	for id in ["plus_one_slot", "random", "selector", "tornado"]:
		c1 += int(_eco().boosters.charges(id))
	_ok(not cm.is_showing() and c1 == c0 and _eco().wallet.scrub_bucks() == sb0, "Skip Tips: coach hidden, wallet / charges unchanged")

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)
