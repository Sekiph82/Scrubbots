extends SceneTree
## M46-RM-002 — adversarial validation of the R05-R07 booster proof / worker / UI lifecycle
## (ChatGPT-authored spec CHATGPT_M46_RM002_BOOSTER_WORKER_UI_ADVERSARIAL_PROMPT_V01.md).
## Complements p20-p22 (m46_performance), m46_r07_ui_legality and m46_slot_rebuild with the
## cases they do not cover:
##   T02 one-dimension cache invalidation (board revision / clear+restore, supply order, slot
##       remaining, WAITING, 5->6 capacity, placement sequence) + the _next_sequence-only case
##       proven equivalent, moving robots never answer from the cache;
##   T03 cancel / stale race matrix on a long 59x59 worker (immediate, mid-run, at completion,
##       twice, Retry, different booster, same booster reuse) + the null-result (crash) path;
##   T01/T06 extras on the real app: SB press while Checking, ad aborted before grant,
##       duplicate settle signal, late popup close vs deferred auto-use, FTUE while robots move,
##       FTUE route to Home.
## Every case asserts it reached its branch. Local Godot 4.7.2 only.
## Run: godot --headless --path . -s res://tests/m46_rm002_adversarial.gd

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const SlotBatchState = preload("res://scripts/gameplay/slots/slot_batch_state.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")

const DT := 1.0 / 60.0
const RANDOM := "random"
const SELECTOR := "selector"
const JOIN_MAX_MS := 250.0
var _fail := 0
var _cases := 0
var _tmp: Array = []
var _v3 := PackedStringArray()
var _cids: Array = []
var _sub: SubViewport = null
var _root = null
var _host = null
var _prov = null

func _initialize() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	await process_frame
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_v3.append("#%sFF" % String(c["hex"]).trim_prefix("#").to_upper())
		_cids.append(String(c["id"]))
	await _t02_cache_l1()
	await _t02_cache_59()
	await _t03_race_matrix()
	await _t01_sb_press_while_checking()
	await _t06_abort_before_grant()
	await _t06_duplicate_settle()
	await _t06_late_close_vs_auto_use()
	await _t06_ftue_moving_and_home()
	_shutdown()
	MainScript.boot_save_path_override = ""
	MainScript.boot_ftue_override = -1
	for p in _tmp:
		for f in [p, p + ".bak", p + ".tmp"]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("M46 RM002 ADVERSARIAL: %s (%d case groups)" % ["PASS" if _fail == 0 and _cases == 8 else "FAIL (%d fails, %d/8 groups completed)" % [_fail, _cases], _cases])
	quit(0 if _fail == 0 and _cases == 8 else 1)

# ------------------------------------------------------------------ fixtures ----

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _ms(t0: int) -> float:
	return (Time.get_ticks_usec() - t0) / 1000.0

func _write(tag: String, text: String) -> String:
	var p := "user://m46rm002_%s.json" % tag
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

## 59x59 eight-stripe level + plan (the m46_performance p13 / p22 fixture).
func _stripe59() -> Array:
	var n := 59
	var pick := [0, 1, 2, 3, 6, 7, 9, 10]
	var pal: Array = []
	for p in pick:
		pal.append(_v3[p])
	var cells: Array = []
	for y in range(n):
		for x in range(n):
			cells.append(mini(x * pick.size() / n, pick.size() - 1))
	var level := {"version": 1, "id": "m46rm002_stripes", "name": "RM002", "difficulty": "TEST", "width": n, "height": n, "palette": pal, "cells": cells}
	var counts := {}
	for c in cells:
		counts[int(c)] = int(counts.get(int(c), 0)) + 1
	var cols: Array = [[], [], [], [], []]
	var k := 0
	for local in counts:
		var left: int = counts[local]
		while left > 0:
			var m := mini(30, left)
			cols[k % 5].append({"batchId": "RMB%04d" % k, "cid": _cids[pick[local]], "robots": m})
			left -= m
			k += 1
	var plan := {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": level["id"], "columnCount": 5, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}
	return [level, plan]

func _host_in(h) -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	h.auto_build = false
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)

func _host59():
	var lp: Array = _stripe59()
	var h = ProductionGameplayHost.new()
	h.level_path = _write("lvl", JSON.stringify(lp[0]))
	h.supply_plan_path = _write("plan", JSON.stringify(lp[1]))
	_host_in(h)
	_ok(h.build(), "59x59 host builds")
	h.get_runtime().set_process(false)
	await _frames(2)
	return h

func _host_l1():
	var path := "user://m46rm002_l1_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	var h = ProductionGameplayHost.new()
	h.app_state = AppState.new(path, Callable())
	_host_in(h)
	_ok(h.build(), "L1 host builds")
	h.get_runtime().set_process(false)
	await _frames(2)
	return h

func _free(h) -> void:
	if h != null and is_instance_valid(h):
		var sub = h.get_parent()
		sub.remove_child(h)
		h.free()
		sub.free()

func _tap(h) -> bool:
	for c in range(h.get_supply().get_column_count()):
		if h.get_input_controller().activate_front(c).get("ok", false):
			return true
	return false

func _still(h) -> bool:
	for _i in range(6000):
		if h.get_scheduler().live_assignment_count() == 0:
			return true
		h.get_runtime().tick(DT)
		await process_frame
	return false

func _wait_worker(h, cap_ms: float = 8000.0) -> float:
	var t0 := Time.get_ticks_usec()
	while h.is_booster_proof_running() and _ms(t0) < cap_ms:
		await process_frame
	await _frames(2)
	return _ms(t0)

# --------------------------------------------------------------------- T02 ----

## A cached verdict exists for the current state (injected through the real put_verdict, so each
## dimension is tested in isolation); one proof-relevant change must invalidate it.
func _fresh_verdicts(a) -> void:
	a._verdicts.clear()
	a.put_verdict("random", a.state_key(), true)
	a.put_verdict("selector_list", a.state_key(), {"ids": ["X"], "partial": false})

func _invalidated(a) -> bool:
	return a.cached_verdict("random") == null and a.cached_verdict("selector_list") == null

func _occupied_index(h, min_remaining: int) -> int:
	var s = h.get_slots()
	for i in range(s.get_slot_count()):
		if s.is_occupied(i) and s.get_remaining(i) >= min_remaining:
			return i
	return -1

## Returns the per-dimension results (null if this helper aborted on a script error, which the
## caller asserts - a helper error can never pass silently).
func _t02_dimensions(h, tag: String):
	var a = h.get_booster_adapter()
	var s = h.get_slots()
	var b = h.get_board()
	var results := {}
	_fresh_verdicts(a)
	results["baseline_hit"] = a.cached_verdict("random") == true and a.cached_verdict("selector_list") != null
	# 1. board revision: one ACTIVE cell cleared, then the board restored (revision monotonic).
	_fresh_verdicts(a)
	var cell := -1
	for i in range(b.get_cell_count()):
		if b.get_cell_state(i) == BoardState.CellState.ACTIVE:
			cell = i
			break
	b.set_cell_state(cell, BoardState.CellState.CLEARED)
	results["board_clear"] = _invalidated(a)
	_fresh_verdicts(a)
	b.set_cell_state(cell, BoardState.CellState.ACTIVE)
	results["board_restore"] = _invalidated(a)
	# 2. supply FIFO order (same batches, one column reversed).
	_fresh_verdicts(a)
	var cols: Array = a._current_cols()
	var ci := -1
	for c in range(cols.size()):
		if (cols[c] as Array).size() >= 2:
			ci = c
			break
	cols[ci].reverse()
	results["supply_order"] = a._supply.replace_live_columns(cols) and _invalidated(a)
	# 3-6 need an occupied slot.
	var oi := _occupied_index(h, 2)
	results["occupied_slot"] = oi >= 0
	if oi >= 0:
		_fresh_verdicts(a)
		s._slots[oi]._remaining_to_clear -= 1
		results["slot_remaining"] = _invalidated(a)
		_fresh_verdicts(a)
		var st0: String = s.get_state(oi)
		s._slots[oi].set_state(SlotBatchState.WAITING if st0 == SlotBatchState.ACTIVE else SlotBatchState.ACTIVE)
		results["slot_waiting_toggle"] = _invalidated(a)
		_fresh_verdicts(a)
		s._slots[oi]._placement_sequence += 10
		results["placement_sequence"] = _invalidated(a)
	_fresh_verdicts(a)
	results["capacity_5_to_6"] = s.grow_to_sixth() and _invalidated(a)
	# 7. _next_sequence alone: not in the key -> the cache answers; justified below by equivalence.
	_fresh_verdicts(a)
	s._next_sequence += 7
	results["next_sequence_cache_kept"] = a.cached_verdict("random") == true
	print("    %s T02 %s" % [tag, str(results)])
	return results

const T02_KEYS := ["baseline_hit", "board_clear", "board_restore", "supply_order", "occupied_slot", "slot_remaining",
	"slot_waiting_toggle", "placement_sequence", "capacity_5_to_6", "next_sequence_cache_kept"]

func _t02_assert(results, tag: String) -> void:
	var ok: bool = results is Dictionary
	if ok:
		for k in T02_KEYS:
			ok = ok and bool(results.get(k, false))
	_ok(ok, "%s: state-key completeness - every proof-relevant one-dimension change invalidates the cached verdicts (board clear / restore, supply order, slot remaining, WAITING, sequence, 5->6); _next_sequence alone keeps it (all %d checks reached)" % [tag, T02_KEYS.size()])

func _t02_cache_l1() -> void:
	print("[T02 exact-state cache, L1 real host]")
	var h = await _host_l1()
	var a = h.get_booster_adapter()
	# Real off-frame proof first (not only injected verdicts).
	var leg: Dictionary = h.booster_legality_offframe(RANDOM)
	var started: bool = leg.get("reason") == "checking"
	await _wait_worker(h)
	_ok(started and a.cached_verdict("random") != null, "L1 still: a real off-frame Random proof settles into the cache")
	_tap(h)
	await _still(h)
	_t02_assert(_t02_dimensions(h, "L1"), "L1")
	# _next_sequence: invariant + equivalence (helper result asserted here).
	var eq = await _free_and_equivalence()
	_ok(eq == true, "_next_sequence check completed and held (see lines above)")
	_free(h)
	_cases += 1

## _next_sequence only shifts the absolute sequence a proof-placed batch gets. The proof depends on
## it only through RELATIVE order (dispatch = ascending sequence), so the invariant that matters is
## "every batch the proof places sorts after every live batch" - asserted directly on the scratch
## engine before and after the change, with a negative control below the live maximum. The
## verdict equivalence on L1 is supporting evidence only (an easy L1 state discriminates little).
func _free_and_equivalence():
	var h = await _host_l1()
	_tap(h)
	await _still(h)
	_tap(h)
	var a = h.get_booster_adapter()
	var s = h.get_slots()
	var live_max := 0
	for i in range(s.get_slot_count()):
		if s.is_occupied(i):
			live_max = maxi(live_max, s.get_placement_sequence(i))
	var inv0: bool = a._scratch_slots_from_live()._next_sequence > live_max
	a.budget_ms = 0
	var r0 = a.propose_random_reorder().get("safe")
	var l0: Array = a.eligible_safe_batches()
	s._next_sequence += 5
	var inv1: bool = a._scratch_slots_from_live()._next_sequence > live_max
	var r1 = a.propose_random_reorder().get("safe")
	var l1: Array = a.eligible_safe_batches()
	var saved: int = s._next_sequence
	s._next_sequence = live_max   # negative control: a proof-placed batch would tie / precede a live one
	var neg: bool = not (a._scratch_slots_from_live()._next_sequence > live_max)
	s._next_sequence = saved
	_ok(inv0 and inv1 and neg, "_next_sequence invariant: scratch next sequence > every live sequence (%d) before and after +5; a value at the live maximum is detected (negative control)" % live_max)
	_ok(r0 == r1 and l0 == l1, "_next_sequence +5 alone (supporting): unbudgeted Random (%s) and Selector list (%d ids) verdicts identical" % [str(r1), l1.size()])
	_free(h)
	return inv0 and inv1 and neg and r0 == r1 and l0 == l1

func _t02_cache_59() -> void:
	print("[T02 exact-state cache, 59x59 still + moving]")
	var h = await _host59()
	h.get_runtime().set_speed_2x(true)
	for _i in range(400):
		if h.get_slots().rightmost_empty_index() != -1:
			_tap(h)
		h.get_runtime().tick(DT)
		await process_frame
	var moving: bool = h.get_scheduler().live_assignment_count() > 0
	var a = h.get_booster_adapter()
	_fresh_verdicts(a)
	var no_cache_moving: bool = moving and a.cached_verdict("random") == null and not h.needs_offframe_proof(RANDOM)
	_ok(no_cache_moving, "59x59 robots moving: the cache never answers and no off-frame proof is needed (in-flight shortcut)")
	await _still(h)
	# Still (0 in flight) with an occupied, not yet dispatched slot: place one batch without ticking.
	_tap(h)
	_t02_assert(_t02_dimensions(h, "59x59"), "59x59")
	_free(h)
	_cases += 1

# --------------------------------------------------------------------- T03 ----

func _t03_race_matrix() -> void:
	print("[T03 cancel / stale race matrix on a long 59x59 worker]")
	var h = await _host59()
	var a = h.get_booster_adapter()
	var settles := [0]
	h.booster_proof_settled.connect(func(_id): settles[0] += 1)
	var rows: Array = []
	# a) cancel in the same frame as the start.
	a._verdicts.clear()
	h.booster_legality_offframe(RANDOM)
	var ran: bool = h.is_booster_proof_running()
	var s0: int = settles[0]
	var t := Time.get_ticks_usec()
	h.cancel_booster_proof()
	var join := _ms(t)
	rows.append(["immediate", ran and not h.is_booster_proof_running() and settles[0] == s0 + 1 and a._verdicts.is_empty() and join <= JOIN_MAX_MS, join])
	# b) cancel mid-run.
	h.booster_legality_offframe(RANDOM)
	await _frames(6)
	ran = h.is_booster_proof_running() and not WorkerThreadPool.is_task_completed(h._proof_job.get("task", -1))
	s0 = settles[0]
	t = Time.get_ticks_usec()
	h.cancel_booster_proof()
	join = _ms(t)
	rows.append(["mid_run", ran and not h.is_booster_proof_running() and settles[0] == s0 + 1 and a._verdicts.is_empty() and join <= JOIN_MAX_MS, join])
	# c) cancel when the worker already finished but the host has not polled it yet (forced timeout
	#    so it finishes fast; the main thread blocks until the task is complete).
	a.offframe_budget_ms = 1
	h.booster_legality_offframe(RANDOM)
	var task = h._proof_job.get("task", -1)
	var tw := Time.get_ticks_usec()
	while not WorkerThreadPool.is_task_completed(task) and _ms(tw) < 3000.0:
		OS.delay_msec(2)
	var done_unpolled: bool = WorkerThreadPool.is_task_completed(task) and h.is_booster_proof_running()
	s0 = settles[0]
	h.cancel_booster_proof()
	await _frames(2)
	rows.append(["at_completion", done_unpolled and not h.is_booster_proof_running() and settles[0] == s0 + 1 and a._verdicts.is_empty(), 0.0])
	a.offframe_budget_ms = a.PROOF_TOTAL_MS
	# d) cancel twice: the second is a no-op.
	h.booster_legality_offframe(RANDOM)
	var ran_d: bool = h.is_booster_proof_running()
	h.cancel_booster_proof()
	s0 = settles[0]
	h.cancel_booster_proof()
	rows.append(["twice", ran_d and settles[0] == s0 and not h.is_booster_proof_running(), 0.0])
	# e) Retry while running.
	h.booster_legality_offframe(RANDOM)
	ran = h.is_booster_proof_running()
	var retried: bool = h.retry()
	await _frames(2)
	rows.append(["retry", ran and retried and not h.is_booster_proof_running() and a._verdicts.is_empty(), 0.0])
	# f) a second source asks for a different booster: one worker, the old one stopped silently.
	h.booster_legality_offframe(RANDOM)
	var task_r = h._proof_job.get("task", -1)
	s0 = settles[0]
	h.booster_legality_offframe(SELECTOR)
	# (task_r was joined by _stop_proof; a joined task id must not be queried again.)
	var one_job: bool = h.is_booster_proof_running() and h._proof_job.get("kind", "") == "selector_list" and h._proof_job.get("task", -1) != task_r
	var silent: bool = settles[0] == s0
	h.cancel_booster_proof()
	rows.append(["different_booster", one_job and silent, 0.0])
	# g) the same booster asked twice on the same state reuses the running worker.
	h.booster_legality_offframe(RANDOM)
	var ran_g: bool = h.is_booster_proof_running()
	var task_a = h._proof_job.get("task", -1)
	h.booster_legality_offframe(RANDOM)
	var reused: bool = ran_g and h._proof_job.get("task", -2) == task_a
	h.cancel_booster_proof()
	rows.append(["same_booster_reuse", reused, 0.0])
	# h) null worker result (a crashed run_offframe): counts as the cap running out, settles once,
	#    is cached, and no new worker starts for that state.
	a._verdicts.clear()
	var key: Array = a.state_key()
	h._proof_job = {"id": RANDOM, "kind": "random", "key": key, "adapter": a.detached_copy(), "out": [null],
		"task": WorkerThreadPool.add_task(func(): pass)}
	h.set_process(true)
	s0 = settles[0]
	await _frames(4)
	var cached_timeout: bool = typeof(a.cached_verdict("random")) == TYPE_STRING
	var leg: Dictionary = h.booster_legality_offframe(RANDOM)
	rows.append(["null_result", cached_timeout and settles[0] == s0 + 1 and not h.is_booster_proof_running() and leg.get("reason") == "proof_timeout", 0.0])
	var ok := true
	for row in rows:
		ok = ok and bool(row[1])
		print("    T03 %-18s %s%s" % [row[0], "ok" if row[1] else "FAIL", ("  join %.2f ms" % row[2]) if row[2] > 0.0 else ""])
	_ok(ok, "race matrix: every cancel point leaves 0 workers and no verdict, settles exactly once per real cancel, joins <= %.0f ms; one worker across sources; a null result fails closed without restarting" % JOIN_MAX_MS)
	_free(h)
	_cases += 1

# ------------------------------------------------------------- real app (T01/T06) --

func _boot_play(level: int) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m46rm002_app_%d.save" % Time.get_ticks_usec()
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

func _supply_ids(h) -> Array:
	var out: Array = []
	for col in h.get_supply().debug_snapshot()["columns"]:
		for bd in col:
			out.append(String(bd["batch_id"]))
	return out

func _t01_sb_press_while_checking() -> void:
	print("[T01 SB buy pressed while Checking: refused, nothing spent]")
	await _boot_play(1)
	var w = _eco().wallet
	w.credit("scrub_bucks", 5000)
	var sb0: int = w.scrub_bucks()
	var c0: int = _eco().boosters.charges(RANDOM)
	var s0 := _supply_ids(_host)
	var lp0: int = _host.get_booster_adapter().live_proof_count
	var p = _acq().open_booster(_host, RANDOM)
	var checking: bool = _host.is_booster_proof_running() and p.get_action_button("sb").visible and p.get_action_button("sb").disabled
	p.get_action_button("sb").pressed.emit()
	await _frames(1)
	_ok(checking and w.scrub_bucks() == sb0 and _eco().boosters.charges(RANDOM) == c0 and _supply_ids(_host) == s0
		and _host.get_booster_adapter().live_proof_count == lp0,
		"SB CTA pressed during Checking: refused (blocked), SB / charges / supply unchanged, no main-thread proof")
	await _wait_worker(_host)
	var enabled: bool = not p.get_action_button("sb").disabled
	p.get_action_button("sb").pressed.emit()
	await _frames(2)
	var price: int = int(_eco().config.booster_price(RANDOM))
	_ok(enabled and w.scrub_bucks() == sb0 - price and _eco().boosters.charges(RANDOM) == c0 and _supply_ids(_host) != s0,
		"after the proof: SB buy-and-use spends the price exactly once (charge count unchanged, supply reordered)")
	_cases += 1

func _t06_abort_before_grant() -> void:
	print("[T06 ad aborted before grant while Checking]")
	await _boot_play(1)
	var tx0: int = _eco().reward.applied_transaction_count()
	var lp0: int = _host.get_booster_adapter().live_proof_count
	var p = _acq().open_booster(_host, RANDOM)
	var running: bool = _host.is_booster_proof_running()
	p.get_action_button("watch").pressed.emit()
	_prov.deliver_last({"outcome": "cancelled", "verified": true})
	var armed: bool = p.context.get("auto_use", false)
	await _wait_worker(_host)
	_ok(running and not armed and _eco().boosters.charges(RANDOM) == 0 and _eco().reward.applied_transaction_count() == tx0 and p.is_open()
		and _host.get_booster_adapter().live_proof_count == lp0,
		"cancelled ad: no grant, no receipt, auto-use never armed, nothing used after the proof, no main-thread proof")
	_cases += 1

func _t06_duplicate_settle() -> void:
	print("[T06 duplicate settle signal: the granted charge is used exactly once]")
	await _boot_play(1)
	var tx0: int = _eco().reward.applied_transaction_count()
	var s0 := _supply_ids(_host)
	var p = _acq().open_booster(_host, RANDOM)
	p.get_action_button("watch").pressed.emit()
	_prov.deliver_last({"outcome": "completed", "verified": true})
	var armed: bool = p.context.get("auto_use", false) and _eco().boosters.charges(RANDOM) == 1
	var extra := [0]
	_host.booster_proof_settled.connect(func(id):
		if extra[0] == 0:
			extra[0] = 1
			_host.booster_proof_settled.emit(id))   # a duplicate settle in the same frame
	await _wait_worker(_host)
	await _frames(3)
	# Random reverses the supply: one execute changes it, a second would restore the original.
	_ok(armed and extra[0] == 1 and _eco().boosters.charges(RANDOM) == 0 and _eco().reward.applied_transaction_count() == tx0 + 1
		and (not is_instance_valid(p) or not p.is_open()) and _supply_ids(_host) != s0,
		"duplicate settle: exactly one execute (supply reordered once, not twice), charge 1 -> 0, one receipt, popup closed")
	_cases += 1

func _t06_late_close_vs_auto_use() -> void:
	print("[T06 popup closed after settle but before the deferred auto-use]")
	await _boot_play(1)
	var p = _acq().open_booster(_host, RANDOM)
	p.get_action_button("watch").pressed.emit()
	_prov.deliver_last({"outcome": "completed", "verified": true})
	var armed: bool = p.context.get("auto_use", false)
	var closed := [false]
	var scheduled := [false]
	var ad = _host.get_booster_adapter()
	# Connected after AcquisitionFlow's handler: runs after the refresh consumed auto_use and
	# scheduled the deferred auto-use (proven legal), and before it executes (end of frame).
	_host.booster_proof_settled.connect(func(_id):
		if not closed[0] and is_instance_valid(p) and p.is_open():
			scheduled[0] = not p.context.get("auto_use", true) and ad.cached_verdict("random") == true
			closed[0] = true
			p.close("x"))
	var s0 := _supply_ids(_host)
	await _wait_worker(_host)
	await _frames(3)
	_ok(armed and closed[0] and scheduled[0] and _eco().boosters.charges(RANDOM) == 1 and _supply_ids(_host) == s0,
		"late close: the auto-use WAS scheduled (proven legal, flag consumed) but does not fire for the closed popup; granted charge kept, supply untouched")
	_cases += 1

func _t06_ftue_moving_and_home() -> void:
	print("[T06 FTUE L2 copy while robots move, then route to Home]")
	MainScript.boot_ftue_override = 1
	await _boot_play(2)
	MainScript.boot_ftue_override = -1
	var cm = _root.get_coachmarks()
	_host.cancel_booster_proof()
	_tap(_host)
	var moving := false
	for _i in range(120):
		_host.get_runtime().tick(DT)
		await process_frame
		if _host.get_scheduler().live_assignment_count() > 0:
			moving = true
			break
	# A job the coach timer may have started in the still frames before dispatch is cancelled, so
	# only the copy computed WHILE moving is observed.
	_host.cancel_booster_proof()
	_root._coach_copy["at"] = 0
	var t := Time.get_ticks_usec()
	_root.refresh_coachmark()
	var copy_ms := _ms(t)
	print("    moving %s (in flight %d), step %s, worker %s" % [str(moving), _host.get_scheduler().live_assignment_count(), cm.get_step_id(), str(_host.is_booster_proof_running())])
	var no_worker: bool = moving and cm.get_step_id() == "l2_boosters_a" and not _host.is_booster_proof_running()
	# T09 property: no still-moment proof and no worker while robots move. The copy's main-thread
	# cost is REPORTED (RM-002 finding: the in-flight Selector list still builds one scratch engine
	# per remaining batch - pre-existing R04 behaviour, not an R07 change; not patched here).
	print("    FTUE copy with robots moving (in-flight shortcut, Selector list): %.2f ms main thread (report-only finding)" % copy_ms)
	_ok(no_worker, "robots moving: the coach copy uses the in-flight shortcut and starts no off-frame worker")
	# Route to Home: the gameplay coach copy is no longer asked; no worker restarts.
	await _still(_host)
	_root._coach_copy["at"] = 0
	_root.refresh_coachmark()
	var before_home: bool = _host.is_booster_proof_running()
	# Watch the host's settle (after the coach-refresh listener): the running worker must be joined
	# and nothing (no worker, no main-thread proof) may start on the leaving host.
	var hh = _host
	var ad = hh.get_booster_adapter()
	var seen := {"lp0": ad.live_proof_count}
	hh.booster_proof_settled.connect(func(_id):
		seen["settled"] = true
		seen["running_after"] = hh.is_booster_proof_running())
	var nav = _root.get_navigation()
	var went: bool = nav.go(NavigationController.Route.HOME)
	await _frames(3)
	var host_alive: bool = is_instance_valid(hh)
	var ok_home: bool = before_home and went and seen.get("settled", false) and not seen.get("running_after", true) \
		and ad.live_proof_count == seen["lp0"] and (not host_alive or not hh.is_booster_proof_running())
	_ok(ok_home, "route to Home mid-check: the worker is cancelled + joined (settled), nothing restarts, no main-thread proof (host alive afterwards: %s)" % str(host_alive))
	_cases += 1

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)
