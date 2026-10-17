extends SceneTree
## M46-RM-004 — whole-milestone residual evidence (ChatGPT spec
## CHATGPT_M46_RM004_WHOLE_EVIDENCE_CLOSURE_PROMPT_V01.md, frozen V2-P2..P5).
##   G1 (RM004-01/02) four-booster transaction ledger on a real 59x59 VOID-pocket host, 5 -> 6
##      slots: legal AND illegal +1 Slot / Random / Selector / Tornado with exact SB / charges /
##      capacity / FIFO / slots / reservations / board before -> after, injected rollback faults
##      (Random commit, Selector extract, Tornado after claims+board+slots mutated), popup
##      close / reopen and modal-open refusal; genuine LOSE (pocket WAITING deadlock) and WON
##      terminals refuse all four with nothing changed;
##   G2 (RM004-03/04) fail-closed fallback: a malformed live slot makes detached_copy() null ->
##      the R05 400 ms synchronous fallback runs, bounded, refuses, spends nothing; board/level
##      cell-count mismatch and wrong-class supply give no ProofState and no authorization; a
##      1 ms budget (UNKNOWN_BOUND) refuses; every listed Selector id on L1-L3 equals an
##      independent fresh DeadlockClassifier verdict (still, unbudgeted) and the in-flight
##      shortcut equals classifier PROGRESSABLE with robots moving;
##   G3 (RM004-05) internal provenance of an off-frame proof: completed / deadline_timeout /
##      worker_error (a real script error inside run_offframe) / cancelled / stale, with the SAME
##      external fail-closed verdict for a deadline and a crash and no restart for that state;
##   G4 (RM004-06) a real 59x59 still-moment Selector popup under the 5 s cap: a partial list,
##      every chip compared id by id with the cached proven ids, each chip re-proven by an
##      independent unbudgeted adapter, an unlisted batch refused unspent, a chip used once;
##   G5 (RM004-07) lifecycle on the real app: earned charge + running worker + Retry (used at most
##      once), bought charge HUD hold + route Home + next level (no worker, charge kept), host
##      freed with a worker running (joined, no callback after free);
##   G6 (RM004-08) first (cold) vs second (warm) Results show frame cost, and a bounded p12-style
##      59x59 retry profile (report, no threshold change).
## Every case asserts it reached its branch. Local Godot 4.7.2 only.
## Run: godot --headless --path . -s res://tests/m46_rm004_residual_adversarial.gd

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const ProductionBoosterAdapter = preload("res://scripts/economy/production_booster_adapter.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const DeadlockClassifier = preload("res://scripts/gameplay/solver/deadlock_classifier.gd")
const SlotBatchState = preload("res://scripts/gameplay/slots/slot_batch_state.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ProviderDouble = preload("res://tests/support/rewarded_provider_double.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")

const DT := 1.0 / 60.0
const PLUS := "plus_one_slot"
const RANDOM := "random"
const SELECTOR := "selector"
const TORNADO := "tornado"
const N := 59
const GROUPS := 6
const FALLBACK_MAX_MS := 400.0 + 150.0   # R05 owner bound + one classifier step of overrun
const JOIN_MAX_MS := 250.0
const STRIPE_CIDS := ["C01", "C02", "C03", "C04", "C07", "C08", "C10", "C11"]
const POCKET_CIDS := ["C13", "C14", "C15"]
const POCKET_CENTRES := [Vector2i(15, 15), Vector2i(43, 15), Vector2i(15, 43), Vector2i(43, 43)]
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
	await _g1_ledger()
	await _g2_fallback_and_classifier()
	await _g3_provenance()
	await _g4_partial_chips()
	await _g5_lifecycle()
	await _g6_results_and_retry()
	_shutdown()
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for f in [p, p + ".bak", p + ".tmp"]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	var pass_all: bool = _fail == 0 and _cases == GROUPS
	print("M46 RM004 RESIDUAL: %s (%d case groups)" % ["PASS" if pass_all else "FAIL (%d fails, %d/%d groups completed)" % [_fail, _cases, GROUPS], _cases])
	quit(0 if pass_all else 1)

# ------------------------------------------------------------------ fixtures ----

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _ms(t0: int) -> float:
	return (Time.get_ticks_usec() - t0) / 1000.0

func _stats(a: Array) -> Dictionary:
	if a.is_empty():
		return {"n": 0, "mean": 0.0, "p95": 0.0, "max": 0.0}
	var s := a.duplicate()
	s.sort()
	var sum := 0.0
	for v in s:
		sum += v
	return {"n": s.size(), "mean": sum / s.size(), "p95": s[mini(s.size() - 1, int(ceil(s.size() * 0.95)) - 1)], "max": s[-1]}

func _write(tag: String, text: String) -> String:
	var p := "user://m46rm004_%s.json" % tag
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _host_in(h) -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	h.auto_build = false
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)

func _host_file(level: Dictionary, tag: String):
	var h = ProductionGameplayHost.new()
	h.level_path = _write("lvl_" + tag, JSON.stringify(level))
	h.supply_plan_path = _write("plan_" + tag, JSON.stringify(_plan(level)))
	_host_in(h)
	_ok(h.build(), "%s host builds %s" % [tag, h.get_build_error()])
	h.get_runtime().set_process(false)
	await _frames(2)
	return h

## A campaign level host (L1..L4) with its own save (prior levels recorded as won).
func _host_level(order: int):
	var path := "user://m46rm004_l%d_%d.save" % [order, Time.get_ticks_usec()]
	_tmp.append(path)
	var app = AppState.new(path, Callable())
	for n in range(1, order):
		app.progression.record_win(n)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	_host_in(h)
	_ok(h.build(), "L%d host builds" % order)
	h.get_runtime().set_process(false)
	await _frames(2)
	return h

func _free(h) -> void:
	if h != null and is_instance_valid(h):
		var sub = h.get_parent()
		sub.remove_child(h)
		h.free()
		sub.free()

func _boot_play(level: int) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m46rm004_app_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	_prov = ProviderDouble.new()
	_root.get_app_state().economy.rewarded.set_provider(_prov)
	_root.get_modal_stack().clear("t")
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

func _tap(h, column: int = -1) -> bool:
	if column >= 0:
		return h.get_input_controller().activate_front(column).get("ok", false)
	for c in range(h.get_supply().get_column_count()):
		if h.get_input_controller().activate_front(c).get("ok", false):
			return true
	return false

func _empty_slots(h) -> int:
	var s = h.get_slots()
	var n := 0
	for i in range(s.get_slot_count()):
		n += 0 if s.is_occupied(i) else 1
	return n

## Robots in flight AND at least `room` empty slots.
func _busy(h, room: int = 1) -> bool:
	for _i in range(3000):
		if h.get_scheduler().live_assignment_count() > 0 and _empty_slots(h) >= room:
			return true
		if h.get_scheduler().live_assignment_count() == 0 and _empty_slots(h) > 0:
			_tap(h)
		h.get_runtime().tick(DT)
		if _i % 4 == 0:
			await process_frame
	return false

func _still(h) -> bool:
	for _i in range(8000):
		if h.get_scheduler().live_assignment_count() == 0:
			return true
		h.get_runtime().tick(DT)
		if _i % 4 == 0:
			await process_frame
	return false

func _play_to_terminal(h, cap: int = 40000) -> bool:
	h.get_runtime().set_speed_2x(true)
	for _i in range(cap):
		if h.get_completion().is_terminal():
			return true
		_tap(h)
		h.get_runtime().tick(DT)
		if _i % 8 == 0:
			await process_frame
	return h.get_completion().is_terminal()

func _wait_worker(h, cap_ms: float = 9000.0) -> float:
	var t0 := Time.get_ticks_usec()
	while h.is_booster_proof_running() and _ms(t0) < cap_ms:
		await process_frame
	await _frames(2)
	return _ms(t0)

func _supply_ids(h) -> Array:
	var out: Array = []
	for col in h.get_supply().debug_snapshot()["columns"]:
		for bd in col:
			out.append(String(bd["batch_id"]))
	return out

func _slot_ids(h) -> Array:
	var out: Array = []
	var s = h.get_slots()
	for i in range(s.get_slot_count()):
		out.append(s.get_batch_id(i) if s.is_occupied(i) else "")
	return out

## Everything a booster transaction can move (the receipt, last_booster_request, separately).
func _ledger(h) -> Dictionary:
	var e = h.get_economy()
	return {"sb": e.wallet.scrub_bucks(), "charges": e.boosters.snapshot(), "cap": h.get_slots().get_slot_count(),
		"fifo": _supply_ids(h), "slots": h.get_slots().snapshot(), "res": h.get_scheduler().live_assignment_count(),
		"board": h.get_board().get_cell_states_copy()}

func _diff(a: Dictionary, b: Dictionary) -> Array:
	var out: Array = []
	for k in a:
		if a[k] != b[k]:
			out.append(k)
	return out

func _supply_has_color(h, col: int) -> bool:
	for c in h.get_supply().debug_snapshot()["columns"]:
		for bd in c:
			if int(bd["color_id"]) == col:
				return true
	return false

func _price(h, id: String) -> int:
	return int(h.get_economy().config.booster_price(id))

## One ledger row: run `f`, then compare ledger fields against `expect` (Callable(before, after,
## result) -> bool). Prints SB / charge / cap / FIFO size / reservations / board-changed / receipt.
func _row(rows: Array, booster: String, case: String, h, f: Callable, expect: Callable) -> void:
	var before := _ledger(h)
	var r: Dictionary = f.call()
	var after := _ledger(h)
	var ok: bool = bool(expect.call(before, after, r))
	var receipt: Dictionary = h.last_booster_request
	rows.append(ok)
	print("    %-8s %-40s %s | SB %d->%d charges %s cap %d->%d fifo %d->%d res %d->%d board %s | ok=%s reason=%s receipt=%s | changed %s" % [
		booster, case, "ok" if ok else "FAIL", before["sb"], after["sb"], "same" if before["charges"] == after["charges"] else "CHANGED",
		before["cap"], after["cap"], before["fifo"].size(), after["fifo"].size(), before["res"], after["res"],
		"same" if before["board"] == after["board"] else "changed", str(r.get("ok", false)), str(r.get("reason", "")),
		str(receipt.get("id", "")) + "/" + str(receipt.get("reason", "ok" if receipt.get("ok", false) else "")), str(_diff(before, after))])

# ---------------------------------------------------------------------- G1 ----

func _unchanged(b: Dictionary, a: Dictionary, r: Dictionary) -> bool:
	return not r.get("ok", false) and b == a

func _g1_ledger() -> void:
	print("[G1 four-booster ledger on 59x59 pockets: legal / illegal / rollback / popup / LOSE / WON]")
	var level := _pocket_level()
	var h = await _host_file(level, "g1")
	var e = h.get_economy()
	var a = h.get_booster_adapter()
	var rows: Array = []
	e.wallet.debit("scrub_bucks", e.wallet.scrub_bucks())
	for id in [PLUS, RANDOM, SELECTOR, TORNADO]:
		_ok(e.boosters.charges(id) == 0, "%s starts with 0 charges" % id)
	_row(rows, PLUS, "illegal: 0 charges, 0 SB", h, func(): return h.execute_booster(PLUS),
		func(b, af, r): return _unchanged(b, af, r) and r["reason"] == "insufficient_sb")
	e.wallet.credit("scrub_bucks", 100000)
	_row(rows, TORNADO, "illegal: colour not present", h, func(): return h.execute_booster(TORNADO, 99),
		func(b, af, r): return _unchanged(b, af, r) and r["reason"] == "color_not_present")
	_row(rows, SELECTOR, "illegal: unknown batch", h, func(): return h.execute_booster(SELECTOR, "NO_SUCH_BATCH"),
		func(b, af, r): return _unchanged(b, af, r) and (r["reason"] == "not_eligible" or r["reason"] == "proof_timeout"))
	_row(rows, SELECTOR, "illegal: no target", h, func(): return h.execute_booster(SELECTOR, null),
		func(b, af, r): return _unchanged(b, af, r) and r["reason"] == "target_required")
	# Five slots full at a still moment (no tick => nothing dispatches).
	while _empty_slots(h) > 0 and _tap(h):
		pass
	_ok(_empty_slots(h) == 0 and h.get_slots().get_slot_count() == 5, "5 slots filled")
	var any_listed: Array = _supply_ids(h)
	_row(rows, SELECTOR, "illegal: slots full", h, func(): return h.execute_booster(SELECTOR, any_listed[0]),
		func(b, af, r): return _unchanged(b, af, r) and r["reason"] == "not_eligible")
	_row(rows, RANDOM, "illegal: slots full", h, func(): return h.execute_booster(RANDOM),
		func(b, af, r): return _unchanged(b, af, r) and (r["reason"] == "not_solver_safe" or r["reason"] == "proof_timeout"))
	var p1 := _price(h, PLUS)
	_row(rows, PLUS, "legal: SB buy, 5 -> 6", h, func(): return h.execute_booster(PLUS),
		func(b, af, r): return (r.get("ok", false) and af["sb"] == b["sb"] - p1 and af["charges"] == b["charges"] and af["cap"] == 6
			and af["fifo"] == b["fifo"] and af["board"] == b["board"] and af["res"] == b["res"]))
	_row(rows, PLUS, "illegal: second +1 this attempt", h, func(): return h.execute_booster(PLUS),
		func(b, af, r): return _unchanged(b, af, r))
	# Robots in flight with three empty slots (Random proves three consecutive placements).
	_ok(await _busy(h, 3), "robots in flight, >= 3 empty of 6 slots")
	var pr := _price(h, RANDOM)
	a.set_fault_injector(func(stage): return stage == "random_commit")
	_row(rows, RANDOM, "rollback: commit fault", h, func(): return h.execute_booster(RANDOM),
		func(b, af, r): return _unchanged(b, af, r) and r["reason"] == "commit_failed")
	a.set_fault_injector(Callable())
	_row(rows, RANDOM, "legal: SB buy", h, func(): return h.execute_booster(RANDOM),
		func(b, af, r):
			var s0: Array = b["fifo"].duplicate()
			var s1: Array = af["fifo"].duplicate()
			s0.sort()
			s1.sort()
			return (r.get("ok", false) and af["sb"] == b["sb"] - pr and af["charges"] == b["charges"] and s0 == s1 and af["fifo"] != b["fifo"]
				and af["slots"] == b["slots"] and af["board"] == b["board"] and af["cap"] == 6))
	var ids: Array = a.eligible_safe_batches()
	_ok(not ids.is_empty(), "a proven Selector target exists (%d listed, robots in flight)" % ids.size())
	var pick: String = String(ids[-1])
	var ps := _price(h, SELECTOR)
	a.set_fault_injector(func(stage): return stage == "selector_extract")
	_row(rows, SELECTOR, "rollback: extract fault", h, func(): return h.execute_booster(SELECTOR, pick),
		func(b, af, r): return _unchanged(b, af, r) and r["reason"] == "extract_failed")
	a.set_fault_injector(Callable())
	_row(rows, SELECTOR, "legal: SB buy, deep batch", h, func(): return h.execute_booster(SELECTOR, pick),
		func(b, af, r):
			var rest: Array = b["fifo"].duplicate()
			rest.erase(pick)
			return (r.get("ok", false) and af["sb"] == b["sb"] - ps and af["charges"] == b["charges"] and af["fifo"] == rest
				and _slot_ids(h).has(pick) and af["board"] == b["board"] and af["cap"] == 6))
	var colors: Array = a.present_colors()
	var col := int(colors[0])
	var pt := _price(h, TORNADO)
	var stages_hit := []
	a.set_fault_injector(func(stage):
		stages_hit.append(stage)
		return stage == "tornado_supply")
	_row(rows, TORNADO, "rollback: fault after claims/board/slots", h, func(): return h.execute_booster(TORNADO, col),
		func(b, af, r): return _unchanged(b, af, r) and stages_hit.has("tornado_board") and stages_hit.has("tornado_slots"))
	a.set_fault_injector(Callable())
	_row(rows, TORNADO, "legal: SB buy", h, func(): return h.execute_booster(TORNADO, col),
		func(b, af, r):
			return (r.get("ok", false) and af["sb"] == b["sb"] - pt and af["charges"] == b["charges"] and not a.present_colors().has(col)
				and not _supply_has_color(h, col) and af["res"] <= b["res"] and af["cap"] == 6))
	print("    tornado stages reached before the fault: %s" % str(stages_hit))
	# Popup open / close / reopen before any spend, and a request while a modal is open (paused).
	await _still(h)
	var before := _ledger(h)
	var receipt0: Dictionary = h.last_booster_request.duplicate()
	var acq = h.acquisition
	var pa = acq.open_booster(h, TORNADO)
	var opened_a: bool = pa != null and pa.is_open()
	await _frames(2)
	pa.close("t")
	await _frames(2)
	var pb = acq.open_booster(h, TORNADO)
	var opened_b: bool = pb != null and pb.is_open()
	await _frames(2)
	var paused: Dictionary = h.request_booster(RANDOM)
	pb.close("t")
	await _frames(2)
	var refusal: Dictionary = h.last_booster_request
	print("    popup opened twice: %s / %s" % [str(opened_a), str(opened_b)])
	rows.append(opened_a and opened_b and paused.get("reason", "") == "modal_open" and _ledger(h) == before
		and (refusal == receipt0 or (not refusal.get("ok", true) and refusal.get("reason", "") == "modal_open")))
	print("    popup open/close/reopen + request while modal open (%s): ledger unchanged %s, receipt %s (was %s)" % [paused.get("reason", ""), str(_ledger(h) == before), str(refusal), str(receipt0)])
	_free(h)
	# Genuine LOSE: five P1 pocket batches enter the five slots and WAIT (enclosed): no slot can
	# ever free, no stripe can be placed.
	h = await _host_file(level, "g1_lose")
	for _k in range(5):
		_tap(h, 4)
	var waiting := 0
	for _f in range(3):
		h.get_runtime().tick(DT)
	var states: Array = []
	for i in range(h.get_slots().get_slot_count()):
		waiting += 1 if h.get_slots().get_state(i) == SlotBatchState.WAITING else 0
		states.append("%s:%s" % [h.get_slots().get_batch_id(i), h.get_slots().get_state(i)] if h.get_slots().is_occupied(i) else "-")
	var lost: bool = await _play_terminal_no_taps(h)
	var st := String(h.get_completion().get_state())
	var ids_left := _supply_ids(h).size()
	print("    LOSE fixture: slots %s (%d WAITING), completion %s, %d supply batches never placeable" % [str(states), waiting, st, ids_left])
	rows.append(_terminal_refusals(h, "LOST") and lost and st == "LOST" and waiting >= 1 and _empty_slots(h) == 0)
	_free(h)
	h = await _host_level(1)
	var won: bool = await _play_to_terminal(h)
	rows.append(won and String(h.get_completion().get_state()) == "WON" and _terminal_refusals(h, "WON"))
	_free(h)
	var okc := rows.filter(func(x): return x).size()
	var bad_rows: Array = []
	for i in range(rows.size()):
		if not rows[i]:
			bad_rows.append(i)
	print("    failing row indices: %s" % str(bad_rows))
	_ok(okc == rows.size() and rows.size() == 17, "ledger rows %d/%d as expected (14 booster rows, popup/modal, LOSE, WON)" % [okc, rows.size()])
	_cases += 1

func _play_terminal_no_taps(h) -> bool:
	for _i in range(6000):
		if h.get_completion().is_terminal():
			return true
		h.get_runtime().tick(DT)
		if _i % 8 == 0:
			await process_frame
	return h.get_completion().is_terminal()

func _terminal_refusals(h, tag: String) -> bool:
	var e = h.get_economy()
	e.wallet.credit("scrub_bucks", 100000)
	for id in [PLUS, RANDOM, SELECTOR, TORNADO]:
		e.boosters.add_charges(id, 1)
	var before := _ledger(h)
	var ok := true
	var ids := _supply_ids(h)
	var targets := {PLUS: null, RANDOM: null, SELECTOR: ids[0] if not ids.is_empty() else "X", TORNADO: 0}
	for id in [PLUS, RANDOM, SELECTOR, TORNADO]:
		var r: Dictionary = h.execute_booster(id, targets[id])
		var q: Dictionary = h.request_booster(id)
		var leg: Dictionary = h.booster_legality(id)
		ok = ok and not r.get("ok", false) and r["reason"] == "terminal" and not q.get("ok", false) and q["reason"] == "terminal" \
			and not leg["legal"] and leg["reason"] == "terminal"
	ok = ok and _ledger(h) == before
	print("    %s terminal: execute / request / legality refuse all four ('terminal'), ledger unchanged %s" % [tag, str(_ledger(h) == before)])
	return ok

# ---------------------------------------------------------------------- G2 ----

## Independent of the adapter's own reorder / probe code: a fresh classifier on the exact
## post-placement state of `bid` (moved to its column front, placed in the rightmost empty slot).
func _indep_safe(a, bid: String, inflight: int) -> bool:
	var cols: Array = a._current_cols()
	var col := -1
	var out: Array = []
	for c in range(cols.size()):
		var front: Array = []
		var rest: Array = []
		for b in cols[c]:
			if b.get_batch_id() == bid:
				front.append(b)
				col = c
			else:
				rest.append(b)
		out.append(front + rest)
	if col == -1:
		return false
	var sup = BatchSupplyEngine.create(a._supply.get_column_count(), a._supply.get_preview_depth())
	if sup == null or not sup.load_candidate(out, a._supply.get_seed(), a._supply.get_palette_size()):
		return false
	var ss = a._scratch_slots_from_live()
	if ss == null or ss.rightmost_empty_index() == -1 or not ss.select_front_batch(sup, col).get("ok", false):
		return false
	var state = ProofState.from_runtime(a._level, a._board, sup, ss)
	if state == null:
		return false
	var status = DeadlockClassifier.new().classify(state, inflight).get("status", &"")
	return status == DeadlockClassifier.PROGRESSABLE or status == DeadlockClassifier.STALLED or status == DeadlockClassifier.COMPLETED

func _g2_fallback_and_classifier() -> void:
	print("[G2 detached_copy()==null fallback, malformed inputs, UNKNOWN_BOUND, independent classifier]")
	var seen := {}
	var h = await _host_level(1)
	var a = h.get_booster_adapter()
	var e = h.get_economy()
	e.wallet.credit("scrub_bucks", 100000)
	_tap(h)
	var occ := -1
	for i in range(h.get_slots().get_slot_count()):
		if h.get_slots().is_occupied(i):
			occ = i
	var saved: int = h.get_slots()._slots[occ]._remaining_to_clear
	h.get_slots()._slots[occ]._remaining_to_clear = 0   # malformed live slot (test-only corruption)
	var null_copy: bool = a.detached_copy() == null
	var before := _ledger(h)
	for id in [RANDOM, SELECTOR]:
		var lp0: int = a.live_proof_count
		var t := Time.get_ticks_usec()
		var leg: Dictionary = h.booster_legality_offframe(id)
		var ms := _ms(t)
		var lp_leg: int = a.live_proof_count - lp0   # the fallback: exactly one synchronous budgeted question
		var r: Dictionary = h.execute_booster(id, _supply_ids(h)[0] if id == SELECTOR else null)
		print("    (%s: legality ran %d synchronous budgeted question(s); execute re-proves on its own)" % [id, lp_leg])
		seen["fallback_" + id] = null_copy and not h.is_booster_proof_running() and lp_leg == 1 and not leg["legal"] \
			and ms <= FALLBACK_MAX_MS and not r.get("ok", false) and _ledger(h) == before
		print("    malformed slot, %s: detached_copy null %s, no worker, synchronous fallback %.2f ms (<= %.0f), legal %s (%s), execute %s (%s), nothing spent %s" % [
			id, str(null_copy), ms, FALLBACK_MAX_MS, str(leg["legal"]), leg["reason"], str(r.get("ok", false)), r.get("reason", ""), str(_ledger(h) == before)])
	h.get_slots()._slots[occ]._remaining_to_clear = saved
	# Board / LevelData cell-count mismatch and a wrong-class supply: no ProofState, no authorization.
	var bad = ProductionBoosterAdapter.new(a._level, BoardState.from_level_data(_level_of_size(24)), a._supply, a._slots, null)
	var bad_ids: Array = bad.eligible_safe_batches()
	seen["count_mismatch"] = not bad.propose_random_reorder().get("safe", false) and bad_ids.is_empty() and not bad.has_eligible_safe_batch() \
		and ProofState.from_runtime(a._level, bad._board, a._supply, a._slots) == null
	seen["wrong_supply"] = not a._proof_state_buildable(RefCounted.new(), a._scratch_slots_from_live()) \
		and ProofState.from_runtime(a._level, a._board, RefCounted.new(), a._slots) == null and not a._is_safe_probe(RefCounted.new(), a._scratch_slots_from_live())
	# UNKNOWN_BOUND: a 1 ms budget is "not proven", never "safe".
	a.budget_ms = 1
	a._verdicts.clear()
	var bid: String = _supply_ids(h)[0]
	var el: bool = a.is_batch_eligible(bid)
	var to: bool = a.last_proof_timed_out()
	var rr: Dictionary = a.propose_random_reorder()
	var before2 := _ledger(h)
	var rx: Dictionary = h.execute_booster(SELECTOR, bid)
	seen["unknown_bound"] = not el and to and not rr["safe"] and rr["reason"] == "proof_timeout" and rx["reason"] == "proof_timeout" and _ledger(h) == before2
	a.budget_ms = a.PROOF_BUDGET_MS
	_free(h)
	# Independent classifier vs the Selector list, L1..L3 at a still moment, unbudgeted.
	var agree_all := true
	for order in [1, 2, 3]:
		h = await _host_level(order)
		a = h.get_booster_adapter()
		a.budget_ms = 0
		var listed: Array = a.eligible_safe_batches()
		var all_ids := _supply_ids(h)
		var agree := 0
		for b in all_ids:
			agree += 1 if _indep_safe(a, b, 0) == listed.has(b) else 0
		agree_all = agree_all and agree == all_ids.size() and not listed.is_empty()
		print("    L%d still: %d/%d supply ids agree with an independent DeadlockClassifier (%d listed)" % [order, agree, all_ids.size(), listed.size()])
		if order == 1:
			# Robots moving: the in-flight shortcut list == classifier PROGRESSABLE at that in-flight count.
			_ok(await _busy(h, 1), "L1 robots in flight")
			var inflight: int = h.get_scheduler().live_assignment_count()
			var mlisted: Array = a.eligible_safe_batches()
			var magree := 0
			var mids := _supply_ids(h)
			for b in mids:
				magree += 1 if _indep_safe(a, b, inflight) == mlisted.has(b) else 0
			seen["moving_classifier"] = magree == mids.size()
			print("    L1 moving (%d in flight): %d/%d ids agree with the classifier at that in-flight count" % [inflight, magree, mids.size()])
		_free(h)
	seen["indep_still"] = agree_all
	var need := ["fallback_random", "fallback_selector", "count_mismatch", "wrong_supply", "unknown_bound", "indep_still", "moving_classifier"]
	_ok(need.all(func(k): return seen.get(k, false)), "G2 every branch reached and fail-closed / equivalent: %s" % str(seen))
	_cases += 1

func _level_of_size(n: int):
	var pal: Array = [_v3[0], _v3[1], _v3[2]]
	var cells: Array = []
	for i in range(n * n):
		cells.append(i % 3)
	var d := {"version": 1, "id": "m46rm004_s%d" % n, "name": "S", "difficulty": "TEST", "width": n, "height": n, "palette": pal, "cells": cells}
	return LevelLoader.load_from_text(JSON.stringify(d), "m46rm004").level_data

# ---------------------------------------------------------------------- G3 ----

func _g3_provenance() -> void:
	print("[G3 off-frame proof provenance: completed / deadline / worker error / cancelled / stale]")
	var seen := {}
	var h = await _host_level(1)
	var a = h.get_booster_adapter()
	a._verdicts.clear()
	h.booster_legality_offframe(RANDOM)
	await _wait_worker(h)
	seen["completed"] = String(h.last_proof_diagnostic.get("outcome", "")) == "completed" and typeof(a.cached_verdict("random")) == TYPE_BOOL
	h.booster_legality_offframe(SELECTOR)
	h.cancel_booster_proof()
	seen["cancelled"] = String(h.last_proof_diagnostic.get("outcome", "")) == "cancelled" and a.cached_verdict("selector_list") == null
	_free(h)
	h = await _host_file(_stripe_level(), "g3")
	a = h.get_booster_adapter()
	# Genuine deadline: the cap runs out on a real 59x59 Random proof.
	a.offframe_budget_ms = 50
	a._verdicts.clear()
	h.booster_legality_offframe(RANDOM)
	await _wait_worker(h)
	var dl_diag: Dictionary = h.last_proof_diagnostic.duplicate()
	var dl_leg: Dictionary = h.booster_legality_offframe(RANDOM)
	var dl_restart: bool = h.is_booster_proof_running()
	seen["deadline"] = String(dl_diag.get("outcome", "")) == "deadline_timeout" and not dl_restart
	# Worker error with no result: the REAL run_offframe proves, then its own result write hits a
	# script error (read-only out array), so nothing is written. (A script error deeper inside
	# the proof does not end run_offframe: the engine returns a default to the caller and the
	# worker writes an ordinary refusal; observed and logged, see G3 note in the log.)
	a.offframe_budget_ms = 50
	a._verdicts.clear()
	var d = a.detached_copy()
	var out: Array = [null]
	out.make_read_only()
	h._proof_job = {"id": RANDOM, "kind": "random", "key": a.state_key(), "adapter": d, "out": out,
		"task": WorkerThreadPool.add_task(d.run_offframe.bind("random", out))}
	h.set_process(true)
	await _wait_worker(h)
	var er_diag: Dictionary = h.last_proof_diagnostic.duplicate()
	var er_leg: Dictionary = h.booster_legality_offframe(RANDOM)
	var er_restart: bool = h.is_booster_proof_running()
	seen["worker_error"] = out[0] == null and String(er_diag.get("outcome", "")) == "worker_error" and not er_restart
	# Observation row: a script error DEEP in the proof (supply gone) is swallowed by the engine;
	# run_offframe still writes a result, a plain refusal (never an authorization).
	var d2 = a.detached_copy()
	d2._supply = null
	var out2: Array = [null]
	d2.run_offframe("random", out2)
	seen["deep_error_refuses"] = out2[0] != null and out2[0]["value"] == false
	print("    deep script error inside the proof -> worker result %s (a refusal; provenance reads 'completed')" % str(out2[0]))
	a.offframe_budget_ms = a.PROOF_TOTAL_MS
	# Same external verdict for both: refused as proof_timeout, cached, no new worker, nothing spent.
	seen["same_external"] = dl_leg == er_leg and String(er_leg.get("reason", "")) == "proof_timeout" and not bool(er_leg.get("legal", true))
	print("    deadline %s -> %s | worker error %s -> %s" % [str(dl_diag), str(dl_leg), str(er_diag), str(er_leg)])
	# Stale: the state changes while the worker runs; its result is dropped, never cached.
	a._verdicts.clear()
	a.offframe_budget_ms = 300
	h.booster_legality_offframe(RANDOM)
	var key0: Array = a.state_key()
	_tap(h)
	var changed: bool = a.state_key() != key0
	await _wait_worker(h)
	seen["stale"] = changed and String(h.last_proof_diagnostic.get("outcome", "")) != "" and bool(h.last_proof_diagnostic.get("stale", false)) \
		and a.cached_verdict("random") == null
	print("    stale run: %s" % str(h.last_proof_diagnostic))
	a.offframe_budget_ms = a.PROOF_TOTAL_MS
	_free(h)
	var need := ["completed", "cancelled", "deadline", "worker_error", "same_external", "stale", "deep_error_refuses"]
	_ok(need.all(func(k): return seen.get(k, false)), "G3 provenance distinguishes every outcome, external verdict identical for deadline vs crash: %s" % str(seen))
	_cases += 1

# ---------------------------------------------------------------------- G4 ----

func _chips(p) -> Array:
	var out: Array = []
	for ch in p.find_child("Targets", true, false).get_children():
		if not ch.is_queued_for_deletion():
			out.append(ch)
	return out

func _g4_partial_chips() -> void:
	print("[G4 59x59 still-moment Selector popup under the real 5 s cap: chip-by-chip membership]")
	var h = await _host_file(_stripe_level(), "g4")
	var a = h.get_booster_adapter()
	var e = h.get_economy()
	_ok(e.boosters.add_charges(SELECTOR, 1), "one Selector charge (USE mode)")
	var sb0: int = e.wallet.scrub_bucks()
	var p = h.acquisition.open_booster(h, SELECTOR)
	await _frames(1)
	var checking: bool = h.is_booster_proof_running() and _chips(p).is_empty() \
		and (p.find_child("Safety", true, false) as Label).text == UiText.t("BOOSTER_CHECKING") and p.get_action_button("use").disabled
	var waited := await _wait_worker(h, 12000.0)
	var v = a.cached_verdict("selector_list")
	var ids: Array = v["ids"] if v != null else []
	var chips := _chips(p)
	var keys: Array = chips.map(func(c): return String(c.name).trim_prefix("Target_"))
	var cap: int = h.acquisition.MAX_TARGET_CHIPS
	var exact: bool = keys == ids.slice(0, cap).map(func(x): return String(x).validate_node_name())
	print("    checking %s, worker %.0f ms, partial %s, proven %d of %d supply batches, chips %d (cap %d)" % [
		str(checking), waited, str(v != null and v["partial"]), ids.size(), _supply_ids(h).size(), chips.size(), cap])
	# Each displayed chip re-proven by an independent, unbudgeted adapter (no shared cache).
	var indep = a.detached_copy()
	indep.budget_ms = 0
	var reproven := 0
	for k in keys:
		reproven += 1 if indep.is_batch_eligible(k) else 0
	var unlisted := ""
	for b in _supply_ids(h):
		if not ids.has(b):
			unlisted = b
			break
	var before := _ledger(h)
	var ru: Dictionary = h.execute_booster(SELECTOR, unlisted)
	var unl_ok: bool = unlisted != "" and not ru.get("ok", false) and ru["reason"] == "proof_timeout" and _ledger(h) == before
	_ok(checking and v != null and v["partial"] and exact and not keys.is_empty() and reproven == keys.size() and unl_ok,
		"partial list: %d chips == the first proven ids in order, %d/%d re-proven independently; unlisted %s refused (%s), nothing spent" % [
			keys.size(), reproven, keys.size(), unlisted, ru.get("reason", "")])
	var fifo0 := _supply_ids(h)
	chips[0].pressed.emit()
	await _frames(1)
	p.get_action_button("use").pressed.emit()
	await _frames(3)
	var used: String = keys[0]
	var rest := fifo0.duplicate()
	rest.erase(used)
	_ok(e.boosters.charges(SELECTOR) == 0 and e.wallet.scrub_bucks() == sb0 and _slot_ids(h).has(used) and _supply_ids(h) == rest,
		"chip %s used: charge 1 -> 0 once, SB unchanged, batch moved to a slot, other supply order untouched" % used)
	_free(h)
	_cases += 1

# ---------------------------------------------------------------------- G5 ----

func _g5_lifecycle() -> void:
	print("[G5 lifecycle: earned charge + worker + Retry; bought HUD hold + Home + next level; host freed mid-proof]")
	await _boot_play(1)
	var eco = _root.get_app_state().economy
	var tx0: int = eco.reward.applied_transaction_count()
	var p = _root.get_acquisition().open_booster(_host, RANDOM)
	p.get_action_button("watch").pressed.emit()
	_prov.deliver_last({"outcome": "completed", "verified": true})
	var armed: bool = p.context.get("auto_use", false) and eco.boosters.charges(RANDOM) == 1 and _host.is_booster_proof_running()
	var uses := [0]
	var base := []
	_ok(_host.retry(), "Retry while the earned-charge proof runs")
	base = _supply_ids(_host)
	await _wait_worker(_host)
	await _frames(3)
	var after := _supply_ids(_host)
	uses[0] = 0 if after == base else 1
	var rev := base.duplicate()
	_ok(armed and eco.reward.applied_transaction_count() == tx0 + 1 and eco.boosters.charges(RANDOM) == 1 - uses[0]
		and not _host.is_booster_proof_running(),
		"earned + Retry: one receipt, charge used %d time(s) (never twice), no worker left (popup open %s)" % [uses[0], str(is_instance_valid(p) and p.is_open())])
	if is_instance_valid(p) and p.is_open():
		p.close("t")
	await _frames(2)
	# Bought (owned) charge: the HUD hold starts a worker; route Home and start the next level.
	_root.get_modal_stack().clear("t")
	await _frames(1)
	eco.boosters.add_charges(RANDOM, 1)
	var c0: int = eco.boosters.charges(RANDOM)
	var sb0: int = eco.wallet.scrub_bucks()
	await _still(_host)
	_host.get_booster_adapter()._verdicts.clear()
	var hold: Dictionary = _host.request_booster(RANDOM)
	var old = _host
	var running: bool = old.is_booster_proof_running()
	_root.get_modal_stack().clear("t")
	var went: bool = _root.get_navigation().go(NavigationController.Route.HOME)
	await _frames(3)
	var old_ok: bool = not is_instance_valid(old) or not old.is_booster_proof_running()
	_root.get_app_state().progression.record_win(1)
	var r: Dictionary = _root.play_current_frontier()
	await _frames(6)
	var nh = _root.get_gameplay_host()
	_ok(hold.get("reason", "") == "checking" and running and went and old_ok and r.get("ok", false) and nh != null and nh != old
		and not nh.is_booster_proof_running() and eco.boosters.charges(RANDOM) == c0 and eco.wallet.scrub_bucks() == sb0,
		"bought charge HUD hold -> Home -> next level: old worker joined, new host idle, charge %d kept, SB unchanged" % c0)
	_shutdown()
	# A host freed with a worker running: _exit_tree cancels + joins; no callback after free.
	var h = await _host_file(_stripe_level(), "g5")
	var settles := [0]
	h.booster_proof_settled.connect(func(_id): settles[0] += 1)
	h.booster_legality_offframe(RANDOM)
	var was: bool = h.is_booster_proof_running()
	var t := Time.get_ticks_usec()
	_free(h)
	var join := _ms(t)
	await _frames(5)
	_ok(was and join <= JOIN_MAX_MS and settles[0] == 1, "host freed mid-proof: joined in %.2f ms (<= %.0f), exactly one settle, none after free" % [join, JOIN_MAX_MS])
	_cases += 1

# ---------------------------------------------------------------------- G6 ----

## Plays to the terminal tick WITHOUT yielding a frame in between, timing that tick (it carries
## any synchronous terminal work), then times frames until Results is the route + 30 frames.
func _play_and_time_terminal(h) -> Dictionary:
	h.get_runtime().set_speed_2x(true)
	var tick_ms := 0.0
	for _i in range(40000):
		_tap(h)
		var t := Time.get_ticks_usec()
		h.get_runtime().tick(DT)
		tick_ms = _ms(t)
		if h.get_completion().is_terminal():
			break
		if _i % 8 == 0:
			await process_frame
	var r := await _results_show()
	r["terminal_tick"] = tick_ms
	r["won"] = String(h.get_completion().get_state()) == "WON"
	return r

func _results_show() -> Dictionary:
	var frames: Array = []
	var t0 := Time.get_ticks_usec()
	var shown_at := -1
	var nav = _root.get_navigation()
	while _ms(t0) < 8000.0 and (shown_at < 0 or frames.size() < shown_at + 30):
		var tf := Time.get_ticks_usec()
		await process_frame
		frames.append(_ms(tf))
		if shown_at < 0 and nav.current() == NavigationController.Route.RESULTS:
			shown_at = frames.size() - 1
	var st := _stats(frames)
	return {"shown": shown_at >= 0, "at": shown_at, "show_frame": frames[shown_at] if shown_at >= 0 else 0.0, "max": st["max"], "mean": st["mean"], "n": frames.size()}

func _g6_results_and_retry() -> void:
	print("[G6 cold vs warm Results show; bounded 59x59 retry profile]")
	await _boot_play(1)
	var cold := await _play_and_time_terminal(_host)
	var r: bool = _root.retry_from_results()
	await _frames(6)
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)
	_root.get_modal_stack().clear("t")
	var warm := await _play_and_time_terminal(_host)
	for row in [["cold", cold], ["warm", warm]]:
		var x: Dictionary = row[1]
		print("    Results %s: terminal tick %.2f ms, Results route at frame %d (that frame %.2f ms), frame max %.2f / mean %.2f ms over %d frames" % [
			row[0], x["terminal_tick"], x["at"], x["show_frame"], x["max"], x["mean"], x["n"]])
	_ok(cold["won"] and warm["won"] and r and cold["shown"] and warm["shown"], "both WON attempts reached Results after the terminal tick (cost attributed above, report only)")
	_shutdown()
	var h = await _host_file(_stripe_level(), "g6")
	h.get_runtime().set_speed_2x(true)
	for _w in range(2):
		for _i in range(240):
			h.get_runtime().tick(DT)
			_tap(h)
		h.retry()
	var all: Array = []
	for round in range(2):
		var ms: Array = []
		for _k in range(30):
			for _i in range(120):
				h.get_runtime().tick(DT)
				_tap(h)
				if _i % 8 == 0:
					await process_frame
			var t := Time.get_ticks_usec()
			h.retry()
			ms.append(_ms(t))
		var st := _stats(ms)
		all.append_array(ms)
		print("    retry round %d: 30 retries, mean %.2f, p95 %.2f, worst %.2f ms" % [round + 1, st["mean"], st["p95"], st["max"]])
	var s := _stats(all)
	_ok(all.size() == 60 and s["max"] <= 50.1, "60 retries worst %.2f ms <= 50.1 (existing p12 bound, unchanged; report)" % s["max"])
	_free(h)
	_cases += 1

# ------------------------------------------------------------------ levels ----

func _stripe_level() -> Dictionary:
	var pal: Array = []
	for cid in STRIPE_CIDS:
		pal.append(_v3[_cids.find(cid)])
	var cells: Array = []
	for y in range(N):
		for x in range(N):
			cells.append(mini(x * STRIPE_CIDS.size() / N, STRIPE_CIDS.size() - 1))
	return {"version": 1, "id": "m46rm004_stripes", "name": "RM004", "difficulty": "TEST", "width": N, "height": N, "palette": pal, "cells": cells}

func _pocket_level() -> Dictionary:
	var used: Array = POCKET_CIDS + STRIPE_CIDS
	used.sort()
	var pal: Array = []
	var local := {}
	for cid in used:
		local[cid] = pal.size()
		pal.append(_v3[_cids.find(cid)])
	var cells: Array = []
	for y in range(N):
		for x in range(N):
			if x < 2 or y < 2 or x >= N - 2 or y >= N - 2:
				cells.append(LevelData.VOID_CELL)
				continue
			var cid: String = STRIPE_CIDS[mini((x - 2) * STRIPE_CIDS.size() / (N - 4), STRIPE_CIDS.size() - 1)]
			for c in POCKET_CENTRES:
				var d: int = maxi(absi(x - c.x), absi(y - c.y))
				if d <= 4:
					cid = POCKET_CIDS[0] if d == 4 else (POCKET_CIDS[1] if d == 3 else POCKET_CIDS[2])
			cells.append(local[cid])
	return {"version": 2, "id": "m46rm004_pockets", "name": "RM004 Pockets", "difficulty": "TEST", "width": N, "height": N, "palette": pal, "cells": cells}

## Stripes round-robin over columns 0..3 (0..4 without pockets); pocket batches (P1 -> P3) all in
## column 4, so its first five fronts are the enclosed P1 ring.
func _plan(level: Dictionary) -> Dictionary:
	var counts := {}
	for c in level["cells"]:
		if int(c) >= 0:
			counts[int(c)] = int(counts.get(int(c), 0)) + 1
	var cid_of := {}
	for i in range(level["palette"].size()):
		cid_of[i] = _cids[_v3.find(String(level["palette"][i]))]
	var lanes := 4 if cid_of.values().any(func(c): return POCKET_CIDS.has(c)) else 5
	var cols: Array = [[], [], [], [], []]
	var n := 0
	var rr := 0
	for want in STRIPE_CIDS + POCKET_CIDS:
		for local in counts:
			if cid_of[local] != want:
				continue
			var left: int = counts[local]
			while left > 0:
				var k := mini(30, left)
				var col: int = 4 if POCKET_CIDS.has(want) else rr % lanes
				if not POCKET_CIDS.has(want):
					rr += 1
				cols[col].append({"batchId": "R4B%04d" % n, "cid": want, "robots": k})
				left -= k
				n += 1
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": level["id"], "columnCount": 5, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)
