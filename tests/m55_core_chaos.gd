extends SceneTree
## M55-C001 — core chaos QA against the REAL production stack
## (ProductionGameplayHost -> M23..M27 engines -> ProductionInputController /
## ProductionRuntimeController / ProductionActionFacade / AppState economy).
## Rows: SB-M55-001..007, 014..017. Rows 008..013 (transitions / long session /
## memory / signals / orphans / rewards) live in tests/m55_long_session.gd.
## Expected/completed case ledger: a case that aborts early is reported, never
## silently green.
##
## Run: godot --headless --path . -s res://tests/m55_core_chaos.gd

const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")

const DT := 1.0 / 30.0
const EXPECTED_CASES := [
	"001_spam_fixture", "001_spam_level2", "002_restart_in_flight", "003_pause_in_flight",
	"004_background_in_flight", "005_complete_in_flight", "006_exhaust_color",
	"007_exhaust_slot_work", "014_booster_spam", "015_heart_2x_background",
	"016_tornado_in_flight", "017_exchange_all_spam",
]

var _fail := 0
var _tmp: Array = []
var _completed := {}

func _initialize() -> void:
	await process_frame
	await _spam_fixture()
	await _spam_level2()
	await _restart_in_flight()
	await _pause_in_flight()
	await _background_in_flight()
	await _complete_in_flight()
	await _exhaust_color()
	await _exhaust_slot_work()
	await _booster_spam()
	await _heart_2x_background()
	await _tornado_in_flight()
	_exchange_all_spam()
	_cleanup()
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	_ok(missing.is_empty(), "case ledger: every expected case completed %s" % str(missing))
	print("M55 CORE CHAOS: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

# ------------------------------------------------------------------ helpers ------

func _host_level(order: int, clock: Callable = Callable(), save_path: String = ""):
	var app = AppState.new(save_path if save_path != "" else _uniq("lvl%d" % order), clock)
	for n in range(1, order):
		app.progression.record_win(n)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	get_root().add_child(h)
	_ok(h.build(), "host builds level %d %s" % [order, h.get_build_error()])
	h.get_runtime().set_process(false)
	return h

## TEST fixture (user://, never production): 20x20, five 4-wide vertical stripes
## C01..C05, every stripe touching the bottom row, so any placement order solves.
func _stripe_host():
	var hexes := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF"]
	var cells: Array = []
	for y in range(20):
		for x in range(20):
			cells.append(x / 4)
	var lvl := {"version": 1, "id": "m55_stripes", "name": "M55 Stripes", "difficulty": "TEST",
		"width": 20, "height": 20, "palette": hexes, "cells": cells}
	var cols := [[], [], []]
	var n := 0
	for spec in [[0, "C01"], [0, "C04"], [1, "C02"], [1, "C05"], [2, "C03"]]:
		for _k in range(4):
			n += 1
			cols[spec[0]].append({"batchId": "S%02d" % n, "cid": spec[1], "robots": 20})
	var plan := {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": "m55_stripes", "columnCount": 3,
		"visiblePreviewDepth": 3, "maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = _write("lvl", JSON.stringify(lvl))
	h.supply_plan_path = _write("plan", JSON.stringify(plan))
	get_root().add_child(h)
	_ok(h.build(), "stripe fixture host builds %s" % h.get_build_error())
	h.get_runtime().set_process(false)
	return h

## Attach authoritative observers: every committed clear and every terminal emission.
func _watch(h) -> Dictionary:
	var w := {"clears": {}, "clear_events": 0, "dup_clears": 0, "terminals": [], "by_color": {}}
	h.get_clearing_loop().authenticated_clear.connect(func(_o, target, color, _a):
		w["clear_events"] += 1
		if w["clears"].has(target):
			w["dup_clears"] += 1
		w["clears"][target] = true
		w["by_color"][color] = int(w["by_color"].get(color, 0)) + 1)
	h.get_completion().terminal_reached.connect(func(status, _d): w["terminals"].append(String(status)))
	return w

func _active(h) -> int:
	return h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)

func _active_of(h, color: int) -> int:
	var b = h.get_board()
	var n := 0
	for i in range(b.get_cell_count()):
		if b.get_cell_state(i) == BoardState.CellState.ACTIVE and b.get_color_id(i) == color:
			n += 1
	return n

func _coherent(h) -> bool:
	var ev = CompletionEvaluator.new()
	return not ev.has_fatal_inconsistency(h.get_scheduler(), h.get_dispatcher(), h.get_claim_engine(), h.get_reservations(), h.get_slots())

func _live_agents(h) -> int:
	var n := 0
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent and not c.is_queued_for_deletion():
			n += 1
	return n

func _moving(h) -> int:
	var n := 0
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent and c.is_moving():
			n += 1
	return n

func _positions(h) -> Array:
	var out: Array = []
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent:
			out.append(c.position)
	return out

func _supply_batches(h) -> int:
	var s = h.get_supply()
	var n := 0
	for c in range(s.get_column_count()):
		n += s.get_remaining(c)
	return n

func _slots_ok(h) -> bool:
	var occ := 0
	for s in h.get_slots().snapshot():
		if s["occupied"]:
			occ += 1
			if int(s["committed"]) < 0 or int(s["committed"]) > int(s["remaining_to_clear"]) or int(s["remaining_to_clear"]) > int(s["initial_count"]):
				return false
	return occ <= h.get_slots().get_slot_count()

## Tick until at least `n` agents are moving (max `limit` frames).
func _until_moving(h, n: int, limit: int = 600) -> bool:
	for _i in range(limit):
		if _moving(h) >= n:
			return true
		h.get_runtime().tick(DT)
	return _moving(h) >= n

## Spam-drain: every frame try every column (and an invalid one), tick, check invariants.
## Returns {accepted, rejected_invalid_ok, frames, invariant_breaks}.
func _spam_drain(h, delta: float, max_frames: int, per_frame: int = 3) -> Dictionary:
	var input = h.get_input_controller()
	var out := {"accepted": 0, "invalid_accepted": 0, "frames": 0, "breaks": 0, "supply_mismatch": 0}
	var batches0 := _supply_batches(h)
	for f in range(max_frames):
		for _k in range(per_frame):
			for col in range(h.get_supply().get_column_count()):
				if input.activate_front(col).get("ok", false):
					out["accepted"] += 1
		if input.activate_front(7).get("ok", false) or input.activate_front(-1).get("ok", false):
			out["invalid_accepted"] += 1
		if batches0 - _supply_batches(h) != out["accepted"]:
			out["supply_mismatch"] += 1
		h.get_runtime().tick(delta)
		if not (_slots_ok(h) and _coherent(h)):
			out["breaks"] += 1
		out["frames"] = f + 1
		if h.get_completion().is_terminal():
			break
	return out

# ------------------------------------------------------- SB-M55-001 spam slots ----

func _spam_fixture() -> void:
	print("[SB-M55-001 spam all five slots — solvable fixture, 400 cells]")
	var h = _stripe_host()
	var w := _watch(h)
	var cells: int = h.get_board().get_cell_count()
	var r := _spam_drain(h, DT, 40000)
	print("    spam: %s" % str(r))
	_ok(r["invalid_accepted"] == 0, "invalid column activations never accepted")
	_ok(r["supply_mismatch"] == 0, "every accepted activation consumed exactly one supply batch; rejections consumed none")
	_ok(r["breaks"] == 0, "slots never over capacity and transaction cardinalities coherent on every frame (%d frames)" % r["frames"])
	_ok(r["accepted"] == 20, "exactly the 20 plan batches were placed (%d)" % r["accepted"])
	_ok(h.get_completion().is_won() and w["terminals"] == ["WON"], "spam run reaches WON exactly once %s" % str(w["terminals"]))
	_ok(w["clear_events"] == cells and w["clears"].size() == cells and w["dup_clears"] == 0 and _active(h) == 0,
		"each of %d cells cleared exactly once (events %d, unique %d)" % [cells, w["clear_events"], w["clears"].size()])
	var batches := _supply_batches(h)
	var post := 0
	for _i in range(30):
		var a: Dictionary = h.get_input_controller().activate_front(_i % 3)
		if a.get("ok", false) or String(a.get("error", "")) != "terminal":
			post += 1
	_ok(post == 0 and _supply_batches(h) == batches and w["terminals"].size() == 1, "30 post-WON taps rejected as terminal; nothing consumed; no second terminal")
	h.free()
	await process_frame
	_completed["001_spam_fixture"] = true

func _spam_level2() -> void:
	print("[SB-M55-001 spam all five slots — production Level 2 (owner content)]")
	var h = _host_level(2)
	var w := _watch(h)
	var cells: int = h.get_board().get_cell_count()
	var t0 := Time.get_ticks_msec()
	var r := _spam_drain(h, 1.0, 60000)
	print("    spam: %s, %d ms, terminal %s, active left %d" % [str(r), Time.get_ticks_msec() - t0, str(w["terminals"]), _active(h)])
	_ok(r["invalid_accepted"] == 0 and r["supply_mismatch"] == 0 and r["breaks"] == 0,
		"L2 spam: no invalid accept, supply accounting exact, capacity/cardinalities coherent every frame (%d frames)" % r["frames"])
	_ok(w["terminals"].size() == 1 and w["terminals"][0] in ["WON", "LOST"], "L2 spam reaches exactly one terminal (%s); never ERROR" % str(w["terminals"]))
	_ok(w["dup_clears"] == 0 and w["clear_events"] == cells - _active(h), "no cell cleared twice; clear events == cells cleared (%d)" % w["clear_events"])
	_ok(_live_agents(h) == 0 and h.get_reservations().get_reservation_count() == 0 and h.get_claim_engine().live_claim_count() == 0,
		"terminal leaves no agent/reservation/claim")
	h.free()
	await process_frame
	_completed["001_spam_level2"] = true

# ------------------------------------------------- SB-M55-002 restart in flight ----

func _restart_in_flight() -> void:
	print("[SB-M55-002 restart while bots travel — production Level 2]")
	var t := [2_000_000]
	var h = _host_level(2, func(): return t[0])
	var eco = h.get_economy()
	var owner_cols: Array = SupplyPlanLoader.load_engine(h.supply_plan_path, h.get_level())["engine"].debug_snapshot()["columns"]
	var cells: int = h.get_board().get_cell_count()
	var hearts0: int = eco.hearts.hearts()
	var nodes := []
	for cycle in range(4):
		var input = h.get_input_controller()
		for c in [0, 1, 2, 0, 1]:
			input.activate_front(c)
		_ok(_until_moving(h, 3), "cycle %d: agents in flight before restart (%d moving)" % [cycle, _moving(h)])
		var cleared_before: int = cells - _active(h)
		_ok(h.retry(), "cycle %d: Retry commits mid-travel" % cycle)
		_ok(h.get_scheduler().live_assignment_count() == 0 and h.get_claim_engine().live_claim_count() == 0
			and h.get_reservations().get_reservation_count() == 0 and h.get_slots().live_work_count() == 0
			and h.get_dispatcher().get_active_count() == 0 and h.get_slots().occupied_count() == 0 and _live_agents(h) == 0,
			"cycle %d: no assignment/claim/reservation/work/agent survives (had cleared %d)" % [cycle, cleared_before])
		_ok(_active(h) == cells and JSON.stringify(h.get_supply().debug_snapshot()["columns"]) == JSON.stringify(owner_cols),
			"cycle %d: board fully ACTIVE and supply == exact owner queues" % cycle)
		_ok(eco.hearts.hearts() == hearts0 - (cycle + 1), "cycle %d: post-action restart consumed exactly one Heart (%d)" % [cycle, eco.hearts.hearts()])
		_ok(h.retry() and eco.hearts.hearts() == hearts0 - (cycle + 1), "cycle %d: immediate second (pre-action) restart consumes nothing" % cycle)
		for _i in range(300):
			h.get_runtime().tick(DT)
		_ok(_active(h) == cells and h.get_scheduler().live_assignment_count() == 0, "cycle %d: 300 frames later no ghost agent cleared/dispatched anything" % cycle)
		await process_frame
		var agents_left := 0
		for c in h.get_agent_layer().get_children():
			if c is ScrubbotAgent:
				agents_left += 1
		nodes.append([h.get_child_count(), agents_left, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	print("    per-cycle [host children, agent nodes, tree nodes]: %s" % str(nodes))
	_ok(nodes.all(func(n): return n[1] == 0), "every cancelled agent node is freed after one frame")
	_ok(nodes[3][2] <= nodes[0][2], "node count does not grow across 4 restart cycles (%d -> %d)" % [nodes[0][2], nodes[3][2]])
	h.free()
	# Full completion after in-flight restarts (solvable fixture).
	var f = _stripe_host()
	var w := _watch(f)
	for c in [0, 1, 2, 0, 1]:
		f.get_input_controller().activate_front(c)
	_until_moving(f, 3)
	_ok(f.retry(), "fixture: Retry mid-travel")
	w["clears"].clear()
	w["clear_events"] = 0
	var r := _spam_drain(f, DT, 40000)
	_ok(f.get_completion().is_won() and w["clear_events"] == 400 and w["dup_clears"] == 0 and w["terminals"] == ["WON"],
		"after an in-flight restart the attempt completes: 400 clears once each, one WON")
	f.free()
	await process_frame
	_completed["002_restart_in_flight"] = true

# --------------------------------------------------- SB-M55-003 pause in flight ----

func _pause_in_flight() -> void:
	print("[SB-M55-003 pause while bots travel]")
	var h = _stripe_host()
	var w := _watch(h)
	var rt = h.get_runtime()
	for c in [0, 1, 2]:
		h.get_input_controller().activate_front(c)
	_ok(_until_moving(h, 3), "three agents in flight")
	var pos0 := _positions(h)
	var active0 := _active(h)
	var live0: int = h.get_scheduler().live_assignment_count()
	var batches0 := _supply_batches(h)
	rt.set_user_paused(true)
	var refused := 0
	for _i in range(600):
		for c in range(3):
			if String(h.get_input_controller().activate_front(c).get("error", "")) == "paused":
				refused += 1
		rt.tick(DT)
	_ok(_positions(h) == pos0 and _active(h) == active0 and h.get_scheduler().live_assignment_count() == live0,
		"600 paused frames: agents frozen, board and assignments unchanged")
	_ok(refused == 1800 and _supply_batches(h) == batches0, "1800 paused taps all refused as paused; supply untouched")
	for i in range(100):
		rt.set_user_paused(i % 2 == 0)
		rt.tick(DT)
		if not _coherent(h):
			_ok(false, "pause toggle %d incoherent" % i)
			break
	rt.set_user_paused(false)
	var r := _spam_drain(h, DT, 40000)
	_ok(h.get_completion().is_won() and w["clear_events"] == 400 and w["dup_clears"] == 0 and w["terminals"] == ["WON"] and r["breaks"] == 0,
		"after 600 paused frames + 100 rapid pause toggles: WON once, 400 unique clears")
	h.free()
	await process_frame
	_completed["003_pause_in_flight"] = true

# ---------------------------------------------- SB-M55-004 background in flight ----

func _background_in_flight() -> void:
	print("[SB-M55-004 background while bots travel (OS notifications)]")
	var h = _stripe_host()
	var w := _watch(h)
	var rt = h.get_runtime()
	for c in [0, 1, 2]:
		h.get_input_controller().activate_front(c)
	_ok(_until_moving(h, 3), "three agents in flight")
	var pos0 := _positions(h)
	var active0 := _active(h)
	get_root().propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	_ok(rt.is_system_suspended() and rt.is_paused(), "APPLICATION_PAUSED suspends the runtime")
	var refused := 0
	for _i in range(600):
		if not h.get_input_controller().activate_front(0).get("ok", false):
			refused += 1
		rt.tick(DT)
	_ok(_positions(h) == pos0 and _active(h) == active0 and refused == 600, "600 background frames: frozen, 600 taps refused")
	rt.set_user_paused(true)
	get_root().propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	_ok(not rt.is_system_suspended() and rt.is_user_paused() and rt.is_paused(), "resume clears only the system suspension; explicit user pause survives")
	rt.set_user_paused(false)
	for i in range(40):
		get_root().propagate_notification(NOTIFICATION_APPLICATION_FOCUS_OUT if i % 2 == 0 else NOTIFICATION_APPLICATION_FOCUS_IN)
		rt.tick(DT)
	get_root().propagate_notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	_ok(not rt.is_paused(), "after 40 focus flips the runtime is running")
	var r := _spam_drain(h, DT, 40000)
	_ok(h.get_completion().is_won() and w["clear_events"] == 400 and w["dup_clears"] == 0 and w["terminals"] == ["WON"] and r["breaks"] == 0,
		"background/focus chaos then WON once, 400 unique clears")
	h.free()
	await process_frame
	_completed["004_background_in_flight"] = true

# ----------------------------------------- SB-M55-005 complete with bots in flight ----

func _complete_in_flight() -> void:
	print("[SB-M55-005 complete with bots in flight — production Level 1]")
	var h = _host_level(1)
	var w := _watch(h)
	var eco = h.get_economy()
	var input = h.get_input_controller()
	var rt = h.get_runtime()
	var cells: int = h.get_board().get_cell_count()
	var exhausted_in_flight := -1
	var early_terminal := 0
	for _i in range(80000):
		if h.get_slots().rightmost_empty_index() != -1:
			for col in range(h.get_supply().get_column_count()):
				if input.activate_front(col).get("ok", false):
					break
		rt.tick(1.0)
		if h.get_supply().is_exhausted() and exhausted_in_flight < 0 and h.get_scheduler().live_assignment_count() > 0:
			exhausted_in_flight = h.get_scheduler().live_assignment_count()
		if h.get_completion().is_terminal() and (_active(h) > 0 or _moving(h) > 0):
			early_terminal += 1
		if h.get_completion().is_terminal():
			break
	_ok(exhausted_in_flight > 0, "supply exhausted while %d assignments were still in flight" % exhausted_in_flight)
	_ok(early_terminal == 0, "never terminal while cells remained ACTIVE or agents were moving")
	_ok(h.get_completion().is_won() and w["terminals"] == ["WON"], "WON exactly once after the last in-flight arrival %s" % str(w["terminals"]))
	_ok(w["clear_events"] == cells and w["dup_clears"] == 0, "all %d cells cleared exactly once" % cells)
	_ok(_live_agents(h) == 0 and h.get_reservations().get_reservation_count() == 0 and h.get_claim_engine().live_claim_count() == 0,
		"WON leaves no live agent/reservation/claim")
	var sb: int = eco.wallet.scrub_bucks()
	var tx: int = eco.reward.applied_transaction_count()
	for _i in range(300):
		rt.tick(DT)
		input.activate_front(0)
	_ok(eco.wallet.scrub_bucks() == sb and eco.reward.applied_transaction_count() == tx and w["terminals"].size() == 1,
		"300 post-WON frames + taps: no extra SB, no extra reward tx, no second terminal")
	h.free()
	await process_frame
	_completed["005_complete_in_flight"] = true

# ------------------------------------------------------ SB-M55-006 exhaust color ----

func _exhaust_color() -> void:
	print("[SB-M55-006 exhaust a color]")
	var h = _stripe_host()
	var w := _watch(h)
	var input = h.get_input_controller()
	for _k in range(4):
		input.activate_front(0)   # all four C01 batches (C01 = color id 0)
	var c01 := -1
	for s in h.get_slots().snapshot():
		if s["occupied"]:
			c01 = int(s["color_id"])
	var assigned_after := 0
	var exhausted_frame := -1
	for f in range(40000):
		h.get_runtime().tick(DT)
		if exhausted_frame < 0 and _active_of(h, c01) == 0 and h.get_scheduler().color_assignment_owners(c01).is_empty():
			exhausted_frame = f
		elif exhausted_frame >= 0 and not h.get_scheduler().color_assignment_owners(c01).is_empty():
			assigned_after += 1
		if exhausted_frame >= 0 and f > exhausted_frame + 120:
			break
	_ok(exhausted_frame >= 0 and w["by_color"].get(c01, 0) == 80, "C01 exhausted: exactly its 80 cells cleared (%s)" % str(w["by_color"].get(c01, 0)))
	var c01_slots := 0
	for s in h.get_slots().snapshot():
		if s["occupied"] and int(s["color_id"]) == c01:
			c01_slots += 1
	_ok(c01_slots == 0 and h.get_slots().draining_count() == 0, "no slot or draining record of the exhausted color remains")
	_ok(h.get_candidate_index().count_candidates(c01) == 0 and assigned_after == 0, "no candidate and no assignment for the exhausted color afterwards")
	var eco = h.get_economy()
	if eco != null:
		eco.boosters.add_charges(BoosterInventory.TORNADO, 1)
		var tr: Dictionary = h.get_actions().tornado(c01)
		_ok(not tr.get("ok", false) and eco.boosters.charges(BoosterInventory.TORNADO) == 1, "Tornado on the exhausted color refused, charge kept (%s)" % str(tr.get("reason")))
	var r := _spam_drain(h, DT, 40000)
	_ok(h.get_completion().is_won() and w["clear_events"] == 400 and w["dup_clears"] == 0 and r["breaks"] == 0, "remaining colors complete: WON, 400 unique clears")
	h.free()
	await process_frame
	_completed["006_exhaust_color"] = true

# -------------------------------------------------- SB-M55-007 exhaust slot work ----

func _exhaust_slot_work() -> void:
	print("[SB-M55-007 exhaust slot work — release + immediate reuse under load]")
	var h = _stripe_host()
	var w := _watch(h)
	var input = h.get_input_controller()
	var reuse_in_flight := 0
	var breaks := 0
	for f in range(60000):
		var empty: int = h.get_slots().rightmost_empty_index()
		if empty != -1:
			var had_draining: bool = h.get_slots().draining_count() > 0 and _moving(h) > 0
			for col in range(3):
				if input.activate_front(col).get("ok", false):
					if had_draining:
						reuse_in_flight += 1
					break
		h.get_runtime().tick(DT)
		if not (_slots_ok(h) and _coherent(h)):
			breaks += 1
		if h.get_completion().is_terminal():
			break
	_ok(reuse_in_flight >= 5, "a released slot was refilled while its old batch still had robots in flight %d times" % reuse_in_flight)
	_ok(breaks == 0, "capacity/cardinalities coherent on every frame")
	_ok(h.get_completion().is_won() and w["clear_events"] == 400 and w["dup_clears"] == 0 and w["terminals"] == ["WON"],
		"old in-flight robots and replacement batches never disturb each other: WON, 400 unique clears")
	h.free()
	await process_frame
	_completed["007_exhaust_slot_work"] = true

# ---------------------------------------------------- SB-M55-014 booster spam ----

func _booster_spam() -> void:
	print("[SB-M55-014 spam booster use/purchase/charge actions]")
	var h = _host_level(2)
	var eco = h.get_economy()
	var cfg = eco.config
	var act = h.get_actions()
	eco.wallet.credit(EconomyWallet.SCRUB_BUCKS, 100000)
	var sb0: int = eco.wallet.scrub_bucks()
	var spent := 0
	# +1 Slot x30: exactly one.
	var plus := 0
	for _i in range(30):
		if act.plus_one_slot().get("ok", false):
			plus += 1
	spent += plus * cfg.booster_price(BoosterInventory.PLUS_ONE_SLOT)
	_ok(plus == 1 and h.get_slots().get_slot_count() == 6, "30 x +1 Slot -> exactly one activation, capacity 6 (never 7)")
	_ok(eco.wallet.scrub_bucks() == sb0 - spent, "+1 Slot charged exactly once (%d SB)" % cfg.booster_price(BoosterInventory.PLUS_ONE_SLOT))
	# Selector x30 on one eligible batch: at most one extraction.
	var eligible: Array = h.get_booster_adapter().eligible_safe_batches()
	var sel := 0
	if not eligible.is_empty():
		var bid = eligible[0]
		for _i in range(30):
			if act.selector(bid).get("ok", false):
				sel += 1
	spent += sel * cfg.booster_price(BoosterInventory.SELECTOR)
	_ok(not eligible.is_empty() and sel == 1, "30 x Selector on the same batch -> exactly one extraction (%d)" % sel)
	# Random x30: each either commits and charges, or refuses and charges nothing.
	var rnd := 0
	var rnd_other := 0
	for _i in range(30):
		var r: Dictionary = act.random()
		if r.get("ok", false):
			rnd += 1
		elif String(r.get("reason", "")) != "not_solver_safe":
			rnd_other += 1
	spent += rnd * cfg.booster_price(BoosterInventory.RANDOM)
	_ok(rnd_other == 0, "every refused Random is an explicit not_solver_safe (committed %d/30)" % rnd)
	_ok(eco.wallet.scrub_bucks() == sb0 - spent, "SB spent == sum of committed booster prices (%d)" % spent)
	# Tornado x10 on one present color: exactly one commit.
	var color: int = h.get_booster_adapter().present_colors()[0]
	var tor := 0
	for _i in range(10):
		if act.tornado(color).get("ok", false):
			tor += 1
	spent += tor * cfg.booster_price(BoosterInventory.TORNADO)
	_ok(tor == 1 and _active_of(h, color) == 0, "10 x Tornado on one color -> one commit, color gone")
	# Charge path: 3 charges, 10 Tornado taps on present colors -> 3 charge uses, 0 SB.
	eco.boosters.add_charges(BoosterInventory.TORNADO, 3)
	var sb_before_charges: int = eco.wallet.scrub_bucks()
	var charged := 0
	for _i in range(3):
		var cols: Array = h.get_booster_adapter().present_colors()
		if cols.is_empty():
			break
		if act.tornado(cols[0]).get("ok", false):
			charged += 1
	_ok(charged == 3 and eco.boosters.charges(BoosterInventory.TORNADO) == 0 and eco.wallet.scrub_bucks() == sb_before_charges,
		"three charged Tornados consume exactly the 3 charges and no SB")
	_ok(eco.wallet.scrub_bucks() == sb0 - spent, "global SB ledger exact after booster spam (spent %d)" % spent)
	_ok(_coherent(h), "engine cardinalities coherent after booster spam")
	# 2x acquisition popup: presses only while visible (a hidden popup receives no taps).
	var btn: Button = h.get_screen().get_speed_button()
	var sb2: int = eco.wallet.scrub_bucks()
	var presses := 0
	for _i in range(20):
		btn.pressed.emit()
		var pop = h.get_speed_acquisition_popup()
		if pop != null and pop.visible:
			presses += 1
			pop.get_offer_button("level").pressed.emit()
	_ok(eco.wallet.scrub_bucks() == sb2 - cfg.speed_current_level_sb() and eco.speed.is_manual_2x_entitled(2),
		"20 speed-button taps: current-level 2x charged exactly once (%d popup purchases)" % presses)
	var dup := 0
	for _i in range(20):
		if act.buy_current_level_2x(2).get("ok", false):
			dup += 1
	_ok(dup == 0 and eco.wallet.scrub_bucks() == sb2 - cfg.speed_current_level_sb(), "20 direct re-purchases refused (already_entitled), no second charge")
	h.free()
	await process_frame
	_completed["014_booster_spam"] = true

# ------------------------------------ SB-M55-015 Hearts + timed 2x across background ----

func _heart_2x_background() -> void:
	print("[SB-M55-015 background/foreground across 900 s Heart regen + timed 2x expiry]")
	var t := [10_000_000]
	var clock := func(): return t[0]
	var save_path := _uniq("hearts")
	var h = _host_level(2, clock, save_path)
	var app = h.app_state
	var eco = app.economy
	eco.wallet.credit(EconomyWallet.SCRUB_BUCKS, 5000)
	eco.hearts.consume()
	eco.hearts.consume()
	_ok(eco.hearts.hearts() == 3 and eco.hearts.seconds_to_next() == 900, "3 Hearts, next in 900 s")
	_ok(h.get_actions().buy_timed_2x(900).get("ok", false), "15-minute timed 2x bought at T")
	_ok(h.get_actions().buy_timed_2x(1800).get("ok", false), "30-minute timed 2x bought at T (stacks to 2700 s)")
	for c in [0, 1, 2]:
		h.get_input_controller().activate_front(c)
	_until_moving(h, 3)
	get_root().propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	_ok(h.get_runtime().is_system_suspended(), "backgrounded mid-travel")
	_ok(app.flush().get("ok", false), "background flush persisted the save")
	t[0] += 899
	_ok(eco.hearts.hearts() == 3 and eco.hearts.seconds_to_next() == 1, "+899 s in background: still 3 Hearts, 1 s left")
	t[0] += 1
	_ok(eco.hearts.hearts() == 4 and eco.hearts.seconds_to_next() == 900, "+900 s: exactly one Heart regenerated, next interval restarts at 900")
	_ok(eco.speed.timed_seconds_remaining() == 1800, "timed 2x is independent of Heart regen: 1800 s remain")
	t[0] += 1800
	_ok(eco.hearts.hearts() == 5 and eco.speed.timed_seconds_remaining() == 0 and not eco.speed.is_manual_2x_entitled(3),
		"+2700 s: Hearts capped at 5; timed 2x expired by wall clock")
	eco.hearts.consume()
	t[0] -= 5000
	_ok(eco.hearts.hearts() == 4, "clock rolled back 5000 s: no Heart gained or lost (owner rollback-safety rule)")
	# M55-C002 owner ruling (OWNER_TIMED_2X_CLOCK_ROLLBACK_V01): timed 2x fails closed.
	_ok(eco.speed.timed_seconds_remaining() == 0 and not eco.speed.is_manual_2x_entitled(3),
		"clock rolled back 5000 s: expired timed 2x stays expired (was 5000 s revived before M55-C002)")
	t[0] += 5000
	_ok(eco.hearts.hearts() == 4 and eco.hearts.seconds_to_next() <= 900, "clock restored: Hearts still 4, regen interval intact")
	t[0] += 900
	_ok(eco.hearts.hearts() == 5, "900 s after restore the consumed Heart regenerates")
	get_root().propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	_ok(not h.get_runtime().is_paused(), "foreground resumes the runtime")
	_ok(app.flush().get("ok", false), "foreground flush ok")
	h.free()
	await process_frame
	# Relaunch the persisted profile; close for 899 s then 900 s with one Heart missing.
	var app2 = AppState.new(save_path, clock)
	_ok(app2.economy.hearts.hearts() == 5 and app2.economy.speed.timed_seconds_remaining() == 0, "relaunch restores 5 Hearts and expired 2x")
	app2.economy.hearts.consume()
	_ok(app2.flush().get("ok", false), "consume persisted")
	t[0] += 899
	var app3 = AppState.new(save_path, clock)
	_ok(app3.economy.hearts.hearts() == 4, "closed app for 899 s: still 4 on relaunch")
	t[0] += 1
	var app4 = AppState.new(save_path, clock)
	_ok(app4.economy.hearts.hearts() == 5, "closed app for 900 s: the consumed Heart regenerated on relaunch")
	_completed["015_heart_2x_background"] = true

# ------------------------------------------- SB-M55-016 Tornado with in-flight ----

func _tornado_in_flight() -> void:
	print("[SB-M55-016 Tornado while matching-color agents are in flight — production Level 2]")
	var h = _host_level(2)
	var w := _watch(h)
	var eco = h.get_economy()
	for c in [0, 1, 2, 0, 1]:
		h.get_input_controller().activate_front(c)
	var color: int = h.get_slots().get_color_id(0)
	for _i in range(200):
		h.get_runtime().tick(DT)
		if h.get_scheduler().color_assignment_owners(color).size() >= 5 and _moving(h) >= 5:
			break
	var inflight: int = h.get_scheduler().color_assignment_owners(color).size()
	_ok(inflight >= 5, "%d same-color agents in flight" % inflight)
	var other_live: int = h.get_scheduler().live_assignment_count() - inflight
	var color_active: int = _active_of(h, color)
	var cleared_by_agents_before: int = w["by_color"].get(color, 0)
	var sb0: int = eco.wallet.scrub_bucks()
	eco.boosters.add_charges(BoosterInventory.TORNADO, 1)
	var r: Dictionary = h.get_actions().tornado(color)
	_ok(r.get("ok", false), "Tornado commits with in-flight same-color work (%s)" % str(r.get("reason", "")))
	_ok(eco.boosters.charges(BoosterInventory.TORNADO) == 0 and eco.wallet.scrub_bucks() == sb0, "exactly one charge used, no SB")
	_ok(_active_of(h, color) == 0 and color_active > 0, "all %d ACTIVE cells of the color purged atomically" % color_active)
	_ok(h.get_scheduler().color_assignment_owners(color).is_empty() and h.get_scheduler().live_assignment_count() == other_live, "no same-color assignment survives; other colors' assignments untouched (%d)" % other_live)
	_ok(_coherent(h), "post-Tornado cardinalities coherent")
	var supply_has := false
	for col in h.get_supply().debug_snapshot()["columns"]:
		for b in col:
			if int(b.get("color_id", -1)) == color:
				supply_has = true
	_ok(not supply_has, "no batch of the color remains in supply")
	await process_frame
	for _i in range(600):
		h.get_runtime().tick(DT)
	_ok(int(w["by_color"].get(color, 0)) == cleared_by_agents_before, "600 frames later: no ghost clear by a cancelled agent (%d)" % int(w["by_color"].get(color, 0)))
	var r2 := _spam_drain(h, 1.0, 60000)
	_ok(w["terminals"].size() == 1 and w["dup_clears"] == 0 and r2["breaks"] == 0, "attempt continues to exactly one terminal %s with no duplicate clear" % str(w["terminals"]))
	h.free()
	await process_frame
	# Mixed colors (M55-C001 takeover: the Level 2 case above has 0 other-color assignments,
	# so "others untouched" must be proven where other colors really are in flight).
	var f = _stripe_host()
	var fw := _watch(f)
	var feco = f.get_economy()
	for c in [0, 1, 2]:
		f.get_input_controller().activate_front(c)
	for _i in range(400):
		f.get_runtime().tick(DT)
		if _moving(f) >= 3:
			break
	var sched = f.get_scheduler()
	var colors: Array = []
	for s in f.get_slots().snapshot():
		if s["occupied"]:
			colors.append(int(s["color_id"]))
	var target: int = colors[0]
	var others := {}
	for c in colors:
		if c != target:
			others[c] = (sched.color_assignment_owners(c) as Array).duplicate()
	var others_live := 0
	for c in others:
		others_live += (others[c] as Array).size()
	var target_live: int = sched.color_assignment_owners(target).size()
	_ok(target_live >= 1 and others_live >= 1, "mixed: %d target-color and %d other-color assignments in flight" % [target_live, others_live])
	var other_cleared0: int = fw["clear_events"] - int(fw["by_color"].get(target, 0))
	if feco != null:
		feco.boosters.add_charges(BoosterInventory.TORNADO, 1)
	_ok(f.get_actions().tornado(target).get("ok", false), "mixed: Tornado commits")
	var same := true
	for c in others:
		same = same and sched.color_assignment_owners(c) == others[c]
	_ok(_active_of(f, target) == 0 and sched.color_assignment_owners(target).is_empty() and same and _coherent(f),
		"mixed: target color purged, its assignments gone, every other-color assignment owner unchanged (%d)" % others_live)
	for _i in range(600):
		f.get_runtime().tick(DT)
	_ok(fw["clear_events"] - int(fw["by_color"].get(target, 0)) > other_cleared0, "mixed: other-color in-flight agents still arrive and clear afterwards")
	var r3 := _spam_drain(f, DT, 40000)
	_ok(f.get_completion().is_won() and fw["dup_clears"] == 0 and fw["terminals"] == ["WON"] and r3["breaks"] == 0,
		"mixed: attempt completes WON once with no duplicate clear")
	f.free()
	await process_frame
	_completed["016_tornado_in_flight"] = true

# ------------------------------------------------- SB-M55-017 Exchange-all spam ----

func _exchange_all_spam() -> void:
	print("[SB-M55-017 Cards Exchange-all under repeated taps]")
	var path := _uniq("exch")
	var app = AppState.new(path)
	var eco = app.economy
	var inv = eco.collection
	var ids: Array = inv.all_card_ids()
	# Owned: first 20 cards get 1..4 copies; the rest 0.
	var expected := 0
	for i in range(20):
		var n := 1 + (i % 4)
		inv.add_copies(ids[i], n)
		expected += (n - 1) * eco.exchange.card_value(ids[i])
	var sb0: int = eco.wallet.scrub_bucks()
	var tx0: int = eco.reward.applied_transaction_count()
	var oks := 0
	var nothing := 0
	for _i in range(25):
		var r: Dictionary = app.actions.exchange_all_extras()
		if r.get("ok", false):
			oks += 1
		elif String(r.get("reason", "")) == "nothing_to_exchange":
			nothing += 1
	_ok(oks == 1 and nothing == 24, "25 Exchange-all taps: one exchange, 24 nothing_to_exchange")
	_ok(eco.wallet.scrub_bucks() == sb0 + expected and eco.reward.applied_transaction_count() == tx0 + 1, "SB credited exactly once (+%d), one reward tx" % expected)
	var protected_ok := true
	for i in range(ids.size()):
		var want := 1 if i < 20 else 0
		if inv.owned(ids[i]) != want:
			protected_ok = false
	_ok(protected_ok, "every owned card keeps exactly its protected first copy; unowned cards untouched")
	# New extras arrive between taps; relaunch must not make legitimate tx ids collide.
	inv.add_copies(ids[0], 2)
	var extra: int = 2 * eco.exchange.card_value(ids[0])
	app.flush()
	var app2 = AppState.new(path)
	var sb1: int = app2.economy.wallet.scrub_bucks()
	var oks2 := 0
	for _i in range(10):
		if app2.actions.exchange_all_extras().get("ok", false):
			oks2 += 1
	_ok(oks2 == 1 and app2.economy.wallet.scrub_bucks() == sb1 + extra and app2.economy.collection.owned(ids[0]) == 1,
		"after relaunch: 10 taps -> exactly one exchange of the 2 new extras (+%d), protected copy kept" % extra)
	_completed["017_exchange_all_spam"] = true

# ------------------------------------------------------------------- infra -----

func _write(tag: String, text: String) -> String:
	var p := "user://m55_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _uniq(tag: String) -> String:
	var p := "user://m55_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

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
