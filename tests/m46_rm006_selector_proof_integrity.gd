extends "res://tests/m46_rm004_residual_adversarial.gd"
## M46 RM006 — booster proof diagnostic integrity, Selector availability, +1 receipt
## (V3-F03 / F04 / F05). Real production hosts (RM004 fixtures), no owner wallet / network.
##
##   S1a 59x59 stripes, 118 batches, the REAL 5 s off-frame cap: the whole list is proven (no
##       prefix), popup chips == the first 12 proven ids in supply order, every chip and the
##       deepest batch independently re-proven, deep batch used once, unlisted id refused
##   S1b forced short cap: same state repeated -> no second worker, identical chips; across
##       genuine state changes the cut list resumes where the last one stopped, so proofs reach
##       past the first prefix. Control: the old reset-to-0 cursor never leaves the prefix
##   S2  typed worker outcomes: completed safe / completed refusal / deadline_timeout /
##       worker_error (no result) / worker_internal_error (preflight, script error on the worker
##       thread, invalid state mid-proof, malformed verdict) / cancelled / stale; every failure
##       refuses with proof_timeout, spends nothing and never restarts on the same state
##   S3  +1 Slot: first activation debits once 5 -> 6; a second (SB, owned charge, HUD) is
##       refused with reason plus_one_used and no debit / charge / slot / success receipt
##   S4  lifecycle: one worker at a time, Retry / exit mid-proof, 5 vs 6 slot state keys
##
## Run: godot --headless --path . -s res://tests/m46_rm006_selector_proof_integrity.gd

const RM006_GROUPS := 5
const OFFFRAME_CAP_MS := 5000.0

var _groups := 0
var _settles := 0

func _initialize() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	await process_frame
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_v3.append("#%sFF" % String(c["hex"]).trim_prefix("#").to_upper())
		_cids.append(String(c["id"]))
	await _s1a_full_list()
	await _s1b_fair_cursor()
	await _s2_diagnostics()
	await _s3_plus_one()
	await _s4_lifecycle()
	_shutdown()
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for f in [p, p + ".bak", p + ".tmp"]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var pass_all: bool = _fail == 0 and _groups == RM006_GROUPS
	print("M46 RM006 SELECTOR PROOF INTEGRITY: %s (%d/%d groups)" % ["PASS" if pass_all else "FAIL (%d fails)" % _fail, _groups, RM006_GROUPS])
	quit(0 if pass_all else 1)

# ------------------------------------------------------------------ helpers ----

func _count_settles(h) -> void:
	h.booster_proof_settled.connect(func(_id): _settles += 1)

## Independent, unbudgeted re-proof of each id on a fresh detached adapter (no shared cache).
func _reproven(h, ids: Array) -> int:
	var indep = h.get_booster_adapter().detached_copy()
	indep.budget_ms = 0
	var n := 0
	for k in ids:
		n += 1 if indep.is_batch_eligible(String(k)) else 0
	return n

## Off-frame Selector list for the current state -> [verdict, waited ms].
func _offframe_list(h) -> Array:
	var t := Time.get_ticks_usec()
	h.booster_legality_offframe(SELECTOR)
	await _wait_worker(h, 12000.0)
	return [h.get_booster_adapter().cached_verdict("selector_list"), _ms(t)]

## A genuine state change: one player tap, then run to the next still moment.
func _evolve(h) -> void:
	h.get_runtime().set_speed_2x(true)
	_tap(h)
	for _i in range(4000):
		h.get_runtime().tick(DT)
		if h.get_scheduler().live_assignment_count() == 0 and _i > 2:
			break
		if _i % 16 == 0:
			await process_frame

func _core_level() -> Dictionary:
	var cells: Array = []
	for y in range(20):
		for x in range(20):
			cells.append(1 if x >= 7 and x <= 11 and y >= 7 and y <= 12 else 0)
	return {"version": 1, "id": "m46rm006_core", "name": "RM006 Core", "difficulty": "TEST", "width": 20, "height": 20,
		"palette": [_v3[0], _v3[1]], "cells": cells}

## Columns start with cores[c] enclosed core batches, then the reachable ring.
func _core_host(cores: Array):
	var cols: Array = [[], [], []]
	var n := 0
	for c in range(3):
		for _j in range(cores[c]):
			cols[c].append({"batchId": "RM6B%03d" % n, "cid": "C02", "robots": 2})
			n += 1
	var left := 370
	while left > 0:
		var k := mini(30, left)
		cols[n % 3].append({"batchId": "RM6A%03d" % n, "cid": "C01", "robots": k})
		left -= k
		n += 1
	var plan := {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": "m46rm006_core", "columnCount": 3,
		"visiblePreviewDepth": 3, "maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}
	var h = ProductionGameplayHost.new()
	h.level_path = _write("lvl6_core", JSON.stringify(_core_level()))
	h.supply_plan_path = _write("plan6_core", JSON.stringify(plan))
	_host_in(h)
	_ok(h.build(), "core host builds %s" % h.get_build_error())
	h.get_runtime().set_process(false)
	await _frames(2)
	return h

# ------------------------------------------------------------------ S1a -------

func _s1a_full_list() -> void:
	print("[S1a 59x59 stripes, real 5 s cap: whole Selector list proven]")
	var f0 := _fail
	var h = await _host_file(_stripe_level(), "s1a")
	var a = h.get_booster_adapter()
	var e = h.get_economy()
	e.boosters.add_charges(SELECTOR, 1)
	var sb0: int = e.wallet.scrub_bucks()
	var fifo := _supply_ids(h)
	var p = h.acquisition.open_booster(h, SELECTOR)
	await _frames(1)
	var waited := await _wait_worker(h, 12000.0)
	var v = a.cached_verdict("selector_list")
	var ids: Array = v["ids"] if v != null else []
	var chips := _chips(p)
	var keys: Array = chips.map(func(c): return String(c.name).trim_prefix("Target_"))
	var cap: int = h.acquisition.MAX_TARGET_CHIPS
	var in_order: bool = ids == fifo.filter(func(b): return ids.has(b))
	var deep: String = fifo[-1]
	print("    %d supply batches, worker %.0f ms (%s), proven %d, partial %s, chips %d (cap %d), deepest %s listed %s" % [
		fifo.size(), waited, str(h.last_proof_diagnostic), ids.size(), str(v != null and v["partial"]), chips.size(), cap, deep, str(ids.has(deep))])
	_ok(fifo.size() >= 118 and v != null and not v["partial"] and ids.size() == fifo.size() and waited < OFFFRAME_CAP_MS + 500.0
		and h.last_proof_diagnostic.get("outcome") == "completed",
		"all %d batches proven inside the 5 s cap (%.0f ms; was a 29/118 prefix)" % [fifo.size(), waited])
	_ok(in_order and keys == ids.slice(0, cap).map(func(x): return String(x).validate_node_name()), "chips == first %d proven ids, supply order" % cap)
	_ok(_reproven(h, keys) == keys.size() and _reproven(h, [deep]) == 1, "every chip and the deepest batch re-proven independently")
	var before := _ledger(h)
	var ru: Dictionary = h.execute_booster(SELECTOR, "RM6_NOT_A_BATCH")
	_ok(not ru.get("ok", false) and _ledger(h) == before, "unknown batch refused (%s), nothing spent" % ru.get("reason", ""))
	var r: Dictionary = h.execute_booster(SELECTOR, deep)
	var rest := fifo.duplicate()
	rest.erase(deep)
	_ok(r.get("ok", false) and e.boosters.charges(SELECTOR) == 0 and e.wallet.scrub_bucks() == sb0 and _slot_ids(h).has(deep) and _supply_ids(h) == rest,
		"deepest batch %s used: charge 1 -> 0 once, SB unchanged, other supply order untouched" % deep)
	p.close("t")
	_free(h)
	if _fail == f0:
		_groups += 1

# ------------------------------------------------------------------ S1b -------

## Supply positions (current order) covered by a proven list.
func _positions(h, ids: Array) -> Array:
	var fifo := _supply_ids(h)
	var out: Array = []
	for b in ids:
		out.append(fifo.find(b))
	return out

func _s1b_fair_cursor() -> void:
	print("[S1b forced short cap: same-state no rerun; the cut list resumes across genuine changes]")
	var f0 := _fail
	var runs := {}
	for mode in ["rm006", "control_reset0"]:
		var h = await _host_file(_stripe_level(), "s1b_" + mode)
		_count_settles(h)
		var a = h.get_booster_adapter()
		a.offframe_budget_ms = 600
		var deepest: Array = []
		var starts: Array = []
		var seen := {}
		var ok_rows := true
		for step in range(4):
			if step > 0:
				await _evolve(h)
			if mode == "control_reset0":
				a._list_offset = 0   # the pre-RM006 behaviour: every worker starts at batch 0
			var s0 := _settles
			var r := await _offframe_list(h)
			var v = r[0]
			var ids: Array = v["ids"] if v != null else []
			var pos := _positions(h, ids)
			# Same state again (popup refresh / reopen): answered from the cache, no worker.
			var lp0: int = a.live_proof_count
			var again: Dictionary = h.booster_legality_offframe(SELECTOR)
			var no_rerun: bool = not h.is_booster_proof_running() and _settles == s0 + 1 and a.live_proof_count == lp0 \
				and again.get("targets", []).map(func(t): return t["key"]) == ids and String(again.get("reason", "")) != "checking"
			var reproven: int = _reproven(h, ids)
			ok_rows = ok_rows and v != null and v["partial"] and not ids.is_empty() and ids.size() < _supply_ids(h).size() and no_rerun and reproven == ids.size()
			deepest.append(pos.max() if not pos.is_empty() else -1)
			starts.append(pos.min() if not pos.is_empty() else -1)
			for b in ids:
				seen[b] = true
			print("    %s step %d: %d batches, proven %d at positions %d..%d, offset now %d, same-state rerun %s, re-proven %d/%d" % [
				mode, step, _supply_ids(h).size(), ids.size(), pos.min() if not pos.is_empty() else -1, pos.max() if not pos.is_empty() else -1,
				a._list_offset, str(not no_rerun), reproven, ids.size()])
		runs[mode] = {"deepest": deepest, "starts": starts, "distinct": seen.size(), "ok": ok_rows}
		_free(h)
	var fair: Dictionary = runs["rm006"]
	var ctl: Dictionary = runs["control_reset0"]
	_ok(fair["ok"] and ctl["ok"], "every partial list non-empty, every chip re-proven, no second worker on an unchanged state")
	_ok(int(fair["starts"][1]) > int(fair["deepest"][0]) - 2 and int(fair["starts"][2]) > int(fair["starts"][1]) and int(fair["distinct"]) > int(ctl["distinct"]),
		"fair cursor: each new state's list starts after the last cut (starts %s, deepest %s, %d distinct) vs reset-0 control (starts %s, %d distinct)" % [
			str(fair["starts"]), str(fair["deepest"]), fair["distinct"], str(ctl["starts"]), ctl["distinct"]])
	_ok(ctl["starts"] == [0, 0, 0, 0], "control: the old reset-to-0 cursor restarts at batch 0 every time (the prefix)")
	if _fail == f0:
		_groups += 1

# ------------------------------------------------------------------ S2 --------

func _diag(h) -> Dictionary:
	return h.last_proof_diagnostic

## Start the off-frame proof for `id`, wait, return the diagnostic.
func _prove(h, id: String) -> Dictionary:
	h.booster_legality_offframe(id)
	await _wait_worker(h, 12000.0)
	return _diag(h).duplicate()

func _s2_diagnostics() -> void:
	print("[S2 typed off-frame proof outcomes]")
	var f0 := _fail
	var rows: Array = []
	# Completed safe (L1 still start) and a forced deadline on the same kind.
	var h = await _host_level(1)
	var a = h.get_booster_adapter()
	var d1 := await _prove(h, RANDOM)
	var v1 = a.cached_verdict("random")
	rows.append(["completed safe", d1, d1.get("outcome") == "completed" and v1 == true])
	a._verdicts.clear()
	a.offframe_budget_ms = 1
	var d2 := await _prove(h, RANDOM)
	a.offframe_budget_ms = ProductionBoosterAdapter.PROOF_TOTAL_MS
	var r2: Dictionary = h.execute_booster(RANDOM)
	rows.append(["deadline", d2, d2.get("outcome") == "deadline_timeout" and a.cached_verdict("random") == "timeout" and r2.get("reason") == "proof_timeout"])
	# Failures: no result, preflight, a script error deep in the worker, invalid state mid-proof.
	var cases := [
		["no result", "offframe_result", "worker_error", ""],
		["preflight", "preflight", "worker_internal_error", "preflight_failed"],
		["script error", "proof_probe_error", "worker_internal_error", "script_error"],
	]
	for c in cases:
		a._verdicts.clear()
		var stage: String = c[1]
		var fired := [false]
		a.set_fault_injector(func(s):
			if stage == "proof_probe_error" and s == "proof_probe" and not fired[0]:
				fired[0] = true
				var empty := {}
				return empty["rm006_injected"]   # ONE real GDScript runtime error on the worker thread
			return s == stage)
		var e = h.get_economy()
		e.boosters.add_charges(SELECTOR, 1)
		var before := _ledger(h)
		var d := await _prove(h, SELECTOR)
		var lp0: int = a.live_proof_count
		var leg: Dictionary = h.booster_legality_offframe(SELECTOR)   # same state: cached, no restart
		var bid: String = _supply_ids(h)[0]
		var rx: Dictionary = h.execute_booster(SELECTOR, bid)
		var refused: bool = not rx.get("ok", false) and rx.get("reason") == "proof_timeout" and _ledger(h) == before
		rows.append([c[0], d, d.get("outcome") == c[2] and String(d.get("error", "")) == c[3] and refused and not h.is_booster_proof_running()
			and a.live_proof_count == lp0 and leg.get("reason") == "proof_timeout"])
		a.set_fault_injector(Callable())
	_free(h)
	# Mid-proof invalid state + malformed verdicts (run_offframe inline on a detached copy).
	var h2 = await _host_level(1)
	var d = h2.get_booster_adapter().detached_copy()
	d.set_fault_injector(func(s):
		if s == "proof_probe":
			d._level = null   # the proof state can no longer be rebuilt
		return false)
	var out: Array = [null]
	d.run_offframe("selector_list", out)
	# (ids proven before the corruption may be in "value": the host drops a result with an error.)
	rows.append(["invalid state mid-proof", out[0], out[0] != null and out[0]["error"] == "malformed_proof_state" and not out[0]["timed_out"]])
	var m = h2.get_booster_adapter().detached_copy()
	var s1: StringName = m._checked_status({})
	var e1: String = m.proof_error
	m.proof_error = ""
	var s2: StringName = m._checked_status({"status": &"SAFE_PLEASE"})
	rows.append(["malformed verdict", {"empty": [s1, e1], "bogus": [s2, m.proof_error]},
		s1 == &"" and e1 == "malformed_proof_result" and s2 == &"" and m.proof_error == "malformed_proof_result"])
	# Genuine completed refusal (nothing can ever clear) and cancel / stale.
	_free(h2)
	# Four enclosed core batches WAIT in four slots (column 0's ring batch is next, so the level
	# is STALLED, not LOST): Random cannot make three accepted selections into one free slot.
	var hc = await _core_host([4, 5, 6])
	for k in range(4):
		_tap(hc, 0)
	await _still(hc)
	for _i in range(4):
		hc.get_runtime().tick(DT)
	hc.get_economy().boosters.add_charges(RANDOM, 1)
	var dc := await _prove(hc, RANDOM)
	var bc := _ledger(hc)
	var rc: Dictionary = hc.execute_booster(RANDOM)
	rows.append(["completed refusal", [dc, rc], dc.get("outcome") == "completed" and hc.get_booster_adapter().cached_verdict("random") == false
		and rc.get("reason") == "not_solver_safe" and _ledger(hc) == bc])
	# Same state, Selector: an enclosed core batch in the last free slot deadlocks; a ring batch
	# does not. The completed list holds exactly the ring batches, each re-proven.
	var ds := await _prove(hc, SELECTOR)
	var vs = hc.get_booster_adapter().cached_verdict("selector_list")
	var sel: Array = vs["ids"] if vs != null else []
	var rings: Array = _supply_ids(hc).filter(func(b): return String(b).begins_with("RM6A"))
	rows.append(["selector proven-only", {"listed": sel.size(), "rings": rings.size(), "diag": ds},
		ds.get("outcome") == "completed" and not vs["partial"] and sel == rings and _reproven(hc, sel) == sel.size()])
	_free(hc)
	var hs = await _host_file(_stripe_level(), "s2_stale")
	hs.booster_legality_offframe(SELECTOR)
	hs.cancel_booster_proof()
	var dcan: Dictionary = _diag(hs).duplicate()
	rows.append(["cancelled", dcan, dcan.get("outcome") == "cancelled" and hs.get_booster_adapter().cached_verdict("selector_list") == null])
	hs.booster_legality_offframe(SELECTOR)
	_tap(hs)   # the state changes while the worker proves
	await _wait_worker(hs, 12000.0)
	var dst: Dictionary = _diag(hs).duplicate()
	rows.append(["stale", dst, dst.get("stale", false) and hs.get_booster_adapter()._verdicts.is_empty()])
	_free(hs)
	for r in rows:
		print("    %s: %s -> %s" % [r[0], str(r[1]), "ok" if r[2] else "FAIL"])
		_ok(r[2], "S2 %s classified and fail-closed" % r[0])
	if _fail == f0:
		_groups += 1

# ------------------------------------------------------------------ S3 --------

func _s3_plus_one() -> void:
	print("[S3 +1 Slot: one activation, second refused with a reason]")
	var f0 := _fail
	var h = await _host_level(2)
	var e = h.get_economy()
	var price := _price(h, PLUS)
	e.wallet.debit("scrub_bucks", e.wallet.scrub_bucks())
	var r0: Dictionary = h.execute_booster(PLUS)
	_ok(not r0.get("ok", false) and r0.get("reason") == "insufficient_sb" and h.get_slots().get_slot_count() == 5, "0 SB / 0 charges: insufficient_sb, 5 slots")
	e.wallet.credit("scrub_bucks", price * 3)
	var sb0: int = e.wallet.scrub_bucks()
	var r1: Dictionary = h.execute_booster(PLUS)
	_ok(r1.get("ok", false) and e.wallet.scrub_bucks() == sb0 - price and h.get_slots().get_slot_count() == 6 and e.capacity.active_capacity() == 6,
		"first +1: one debit (%d SB), 5 -> 6" % price)
	var rows: Array = []
	var b := _ledger(h)
	var r2: Dictionary = h.execute_booster(PLUS)
	rows.append(["second, SB", r2, _ledger(h) == b])
	e.boosters.add_charges(PLUS, 1)
	b = _ledger(h)
	var r3: Dictionary = h.execute_booster(PLUS)
	rows.append(["second, owned charge", r3, _ledger(h) == b])
	b = _ledger(h)
	var r4: Dictionary = h.request_booster(PLUS)
	rows.append(["HUD, owned charge", r4, _ledger(h) == b and h.last_booster_request.get("reason") == "plus_one_used"])
	var p = h.acquisition.open_booster(h, PLUS)
	await _frames(1)
	b = _ledger(h)
	var btn = null
	for act in ["use", "sb"]:
		if btn == null and p != null:
			btn = p.get_action_button(act)
	if btn != null:
		btn.pressed.emit()
		await _frames(1)
	var pr: Dictionary = h.acquisition.last_result if h.acquisition != null else {}
	var status_text := String((p.find_child("Status", true, false) as Label).text) if p != null and p.find_child("Status", true, false) != null else "?"
	rows.append(["popup SB", pr, btn == null or (_ledger(h) == b and (pr.is_empty() or pr.get("reason") == "plus_one_used"))])
	print("    popup: sb button %s disabled %s, status '%s'" % [str(btn != null), str(btn.disabled if btn != null else true), status_text])
	if p != null:
		p.close("t")
	for r in rows:
		print("    %s: ok %s reason '%s'" % [r[0], str(r[1].get("ok", false)), String(r[1].get("reason", ""))])
		_ok(not r[1].get("ok", false) and (r[1].is_empty() or r[1].get("reason") == "plus_one_used") and r[2] and h.get_slots().get_slot_count() == 6,
			"%s refused: plus_one_used, no debit / charge / slot change" % r[0])
	_ok(not h.get_slots().grow_to_sixth() and h.get_slots().get_slot_count() == 6, "no seventh slot")
	_free(h)
	if _fail == f0:
		_groups += 1

# ------------------------------------------------------------------ S4 --------

func _s4_lifecycle() -> void:
	print("[S4 one worker, Retry / exit mid-proof, 5 vs 6 slot keys]")
	var f0 := _fail
	var h = await _host_file(_stripe_level(), "s4")
	_count_settles(h)
	var a = h.get_booster_adapter()
	h.booster_legality_offframe(SELECTOR)
	var job = h._proof_job.get("task", -1)
	var again: Dictionary = h.booster_legality_offframe(SELECTOR)
	_ok(again.get("reason") == "checking" and h._proof_job.get("task", -2) == job, "a second request joins the running worker (one task)")
	var key5: Array = a.state_key()
	_ok(h.retry(), "Retry while the worker proves")
	await _frames(2)
	_ok(not h.is_booster_proof_running() and a.cached_verdict("selector_list") == null and h.last_proof_diagnostic.get("outcome") == "cancelled",
		"Retry cancelled the worker; no verdict kept")
	_ok(h.get_slots().grow_to_sixth(), "sixth slot")
	_ok(a.state_key() != key5 and a.cached_verdict("selector_list") == null, "a 6-slot state never reuses a 5-slot verdict")
	h.booster_legality_offframe(SELECTOR)
	var running: bool = h.is_booster_proof_running()
	_free(h)   # exit mid-proof: the worker is cancelled + joined in _exit_tree
	await _frames(2)
	_ok(running, "host freed while its worker proved (joined, no crash)")
	if _fail == f0:
		_groups += 1
