extends SceneTree
## M52-C001-R01 — parallel slot dispatch lanes, departure counts, 2x acquisition, stutter
## fixes. Direct assertions against the REAL production stack (AppState -> catalog ->
## resolver -> ProductionGameplayHost -> M23..M27 engines).
##
## Run: godot --headless --path . -s res://tests/m52_r01_parallel_runtime.gd

const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

const DT := 1.0 / 60.0

var _fail := 0
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_five_blue_one_wave()
	_runtime_lane_wave()
	_five_colors_one_wave()
	_waiting_slot_does_not_block()
	_six_lanes_never_seven()
	_departure_count_and_rollback()
	_pause_and_focus()
	_retry_cancels_parallel()
	_tornado_multi_inflight()
	_terminal_cardinality_n()
	_speed_cadence_and_travel()
	await _two_x_acquisition()
	_auto_2x_free()
	_prefilter_equivalence()
	_fast_route_equivalence()
	_keyed_sort_equivalence()
	_kernel_wave_model()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ------
func _host_level(order: int):
	var app = AppState.new(_uniq("lvl%d" % order))
	for n in range(1, order):
		app.progression.record_win(n)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	get_root().add_child(h)
	_ok(h.build(), "host builds level %d %s" % [order, h.get_build_error()])
	h.get_runtime().set_process(false)
	return h

## Host with a custom level + plan written to user:// (TEST fixture, never production).
func _host_fixture(level_dict: Dictionary, plan: Dictionary):
	var lp := _write("lvl", JSON.stringify(level_dict))
	plan["levelId"] = level_dict["id"]
	var pp := _write("plan", JSON.stringify(plan))
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = lp
	h.supply_plan_path = pp
	get_root().add_child(h)
	_ok(h.build(), "fixture host builds %s" % h.get_build_error())
	h.get_runtime().set_process(false)
	return h

func _click(h, cols: Array) -> bool:
	var ok := true
	for c in cols:
		ok = ok and h.get_input_controller().activate_front(int(c) - 1).get("ok", false)
	return ok

func _displayed(h) -> Array:
	var out: Array = []
	for s in h.get_slots().snapshot():
		out.append(maxi(int(s["remaining_to_clear"]) - int(s["committed"]), 0) if s["occupied"] else -1)
	return out

func _by_slot(h) -> Dictionary:
	var out := {}
	for a in h.get_scheduler().assignment_snapshot():
		out[int(a["slot"])] = int(out.get(int(a["slot"]), 0)) + 1
	return out

func _active(h) -> int:
	return h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)

## Canonical stripe fixture: 20x20, five vertical 4-wide stripes C01..C05 (all touching the
## bottom row) and an optional enclosed 2x4 C06 block inside the C01 stripe.
func _stripe_level(with_block: bool) -> Dictionary:
	var hexes := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]  # C01..C06
	var pal: Array = hexes.slice(0, 6 if with_block else 5)
	var cells: Array = []
	for y in range(20):
		for x in range(20):
			var c := x / 4
			if with_block and x >= 1 and x <= 2 and y >= 8 and y <= 11:
				c = 5
			cells.append(c)
	return {"version": 1, "id": "r01_stripes%s" % ("_block" if with_block else ""), "name": "R01 Stripes",
		"difficulty": "TEST", "width": 20, "height": 20, "palette": pal, "cells": cells}

func _plan(cols: Array) -> Dictionary:
	var out: Array = []
	var n := 0
	for col in cols:
		var q: Array = []
		for b in col:
			n += 1
			q.append({"batchId": "F%02d" % n, "cid": b[0], "robots": b[1]})
		out.append(q)
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "columnCount": 3, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": out}

# ------------------------------------------------------------ five BLUE, one wave --
func _five_blue_one_wave() -> void:
	print("[five BLUE x30 -> one wave, five lanes]")
	var h = _host_level(2)
	_ok(_click(h, [1, 2, 3, 1, 2]), "five C08 x30 batches placed (Apple fronts)")
	var disp0 := _displayed(h)
	_ok(disp0 == [30, 30, 30, 30, 30], "all five slots show 30 before the wave (%s)" % str(disp0))
	var active0 := _active(h)
	var r: Dictionary = h.get_scheduler().step()
	_ok(r["ok"] and int(r["assigned"]) == 5, "ONE wave produced exactly five assignments (%s)" % str(r.get("assigned")))
	var by := _by_slot(h)
	_ok(by.size() == 5 and by.values().filter(func(v): return v != 1).is_empty(), "one assignment from EACH occupied slot %s" % str(by))
	var targets := {}
	var claims := {}
	var owners := {}
	var agents := {}
	for a in h.get_scheduler().assignment_snapshot():
		targets[int(a["target"])] = true
		claims[a["claim_id"]] = true
		agents[a["agent"].get_instance_id()] = true
	for o in h.get_scheduler().assignment_snapshot():
		owners[o["claim_id"]] = true
	_ok(targets.size() == 5 and claims.size() == 5 and agents.size() == 5, "unique targets/claims/agents")
	_ok(h.get_reservations().get_reservation_count() == 5 and h.get_claim_engine().live_claim_count() == 5 \
		and h.get_slots().live_work_count() == 5 and h.get_dispatcher().get_active_count() == 5, "5 reservations/claims/work/agents coexist")
	_ok(_displayed(h) == [29, 29, 29, 29, 29] and _active(h) == active0, "every display 30 -> 29 BEFORE any target clears")
	var r2: Dictionary = h.get_scheduler().step()
	_ok(int(r2.get("assigned", 0)) == 5 and _by_slot(h).values().filter(func(v): return v != 2).is_empty(), "next wave: again one per slot (never two per slot per wave)")
	h.free()

func _runtime_lane_wave() -> void:
	print("[runtime frame-budgeted wave]")
	var h = _host_level(2)
	_click(h, [1, 2, 3, 1, 2])
	var rt = h.get_runtime()
	var sch = h.get_scheduler()
	var interval: float = rt.get_speed_authority().cadence_interval()
	rt.tick(interval)
	var frames := 1
	var max_live_per_frame := 1
	var prev: int = sch.live_assignment_count()
	while sch.has_pending_lanes() and frames < 20:
		rt.tick(DT)
		frames += 1
		max_live_per_frame = maxi(max_live_per_frame, sch.live_assignment_count() - prev)
		prev = sch.live_assignment_count()
	_ok(sch.live_assignment_count() == 5 and frames <= 6, "cadence wave serviced one lane per frame: 5 live after %d frames" % frames)
	_ok(max_live_per_frame == 1, "never more than one new assignment in a single frame")
	_ok(_displayed(h) == [29, 29, 29, 29, 29] and _by_slot(h).size() == 5, "runtime wave: one per slot, displays 29")
	_ok(sch.step_lane().get("reason", "") == "no_wave", "no extra lane after the wave is exhausted")
	h.free()

# ------------------------------------------------------- five colors, one wave --
func _five_colors_one_wave() -> void:
	print("[five different colors -> one wave]")
	var plan := _plan([
		[["C01", 20], ["C04", 20], ["C01", 20], ["C04", 20], ["C01", 20], ["C04", 20], ["C01", 20], ["C04", 20]],
		[["C02", 20], ["C05", 20], ["C02", 20], ["C05", 20], ["C02", 20], ["C05", 20], ["C02", 20], ["C05", 20]],
		[["C03", 20], ["C03", 20], ["C03", 20], ["C03", 20]],
	])
	var h = _host_fixture(_stripe_level(false), plan)
	if not h.is_built():
		h.free()
		return
	_click(h, [1, 2, 3, 1, 2])
	var colors := {}
	for s in h.get_slots().snapshot():
		colors[int(s["color_id"])] = true
	_ok(colors.size() == 5, "five different colors occupy the five slots")
	var r: Dictionary = h.get_scheduler().step()
	var c2 := {}
	for a in r.get("assignments", []):
		c2[int(a["color"])] = true
	_ok(int(r.get("assigned", 0)) == 5 and c2.size() == 5 and _by_slot(h).size() == 5, "one assignment per slot, five colors, same wave")
	h.free()

func _waiting_slot_does_not_block() -> void:
	print("[one WAITING slot does not block siblings]")
	var plan := _plan([
		[["C06", 8], ["C01", 30], ["C01", 30], ["C01", 12], ["C04", 30], ["C04", 30], ["C04", 20]],
		[["C02", 30], ["C02", 30], ["C02", 20], ["C05", 30], ["C05", 30], ["C05", 20]],
		[["C03", 30], ["C03", 30], ["C03", 20]],
	])
	var h = _host_fixture(_stripe_level(true), plan)
	if not h.is_built():
		h.free()
		return
	_click(h, [1, 2, 3])
	var r: Dictionary = h.get_scheduler().step()
	var slots_used := {}
	for a in r.get("assignments", []):
		slots_used[int(a["slot"])] = int(a["color"])
	var enclosed_slot := -1
	for i in range(5):
		if h.get_slots().is_occupied(i) and h.get_slots().get_color_id(i) == 5:
			enclosed_slot = i
	_ok(enclosed_slot != -1 and h.get_scheduler().is_slot_waiting(enclosed_slot), "enclosed C06 lane is WAITING (no target)")
	_ok(int(r.get("assigned", 0)) == 2 and not slots_used.has(enclosed_slot), "both sibling lanes dispatched in the same wave (%s)" % str(slots_used))
	_ok(h.get_slots().get_state(enclosed_slot) == "WAITING" and h.get_slots().get_capacity(enclosed_slot) == 8, "waiting lane keeps its full count, no reservation")
	h.free()

# ------------------------------------------------------------------- +1 slot -----
func _six_lanes_never_seven() -> void:
	print("[+1 Slot: six lanes, never seven]")
	var h = _host_level(2)
	h.get_economy().boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
	_ok(h.activate_plus_one_slot(), "+1 Slot activated")
	_ok(_click(h, [1, 2, 3, 1, 2, 3]), "six C08 x30 batches placed")
	_ok(not _click(h, [1]), "seventh placement refused (all six slots full)")
	var r: Dictionary = h.get_scheduler().step()
	_ok(int(r.get("assigned", 0)) == 6 and _by_slot(h).size() == 6, "one wave -> exactly six assignments, one per slot")
	var r2: Dictionary = h.get_scheduler().step()
	_ok(int(r2.get("assigned", 0)) == 6, "next wave again six, never seven")
	h.free()

# ---------------------------------------------------------- departure counter -----
func _departure_count_and_rollback() -> void:
	print("[departure-time count + rollback]")
	var h = _host_level(2)
	_click(h, [1])
	var slots = h.get_slots()
	var sch = h.get_scheduler()
	var s0 := -1
	for i in range(5):
		if slots.is_occupied(i):
			s0 = i
	var r: Dictionary = sch.step()
	_ok(r["ok"] and int(r["assigned"]) == 1, "one lane dispatched one Scrubby")
	_ok(slots.get_remaining(s0) == 30 and slots.snapshot()[s0]["committed"] == 1 and _displayed(h)[s0] == 29,
		"before its clear: remaining=30, committed=1, displayed=29")
	sch.pause()  # no further waves: isolate this one departure
	h.get_runtime().tick(DT)  # runtime tick pushes the live snapshot into the UI
	var view_count := _view_count(h, s0)
	_ok(view_count == 29, "player-visible slot view shows 29 before the clear (%d)" % view_count)
	var before := _active(h)
	for i in range(3000):
		h.get_runtime().tick(DT)
		if _active(h) < before:
			break
	_ok(_active(h) == before - 1 and slots.get_remaining(s0) == 29 and slots.snapshot()[s0]["committed"] == 0 and _displayed(h)[s0] == 29,
		"after the clear: remaining=29, committed=0, displayed stays 29")
	# Pre-spawn rollback restores the display (exact M25 claim + rollback).
	var origin: Vector2 = h.get_origin_provider().origin_for_slot(s0)
	var access = ProductionTargetAccess.new(ProductionRoutingSystem.new(), ProductionAccessQuery.new(h.get_board()), h.get_board(), origin)
	var c: Dictionary = h.get_claim_engine().claim_for_slot(s0, access)
	_ok(c["ok"] and _displayed(h)[s0] == 28, "an established claim shows 28")
	_ok(h.get_claim_engine().rollback_claim(c["claim_id"]) and _displayed(h)[s0] == 29, "rollback before clear restores 29")
	h.free()

func _view_count(h, slot: int) -> int:
	var views: Array = h.get_screen().get_five_slot_strip().get_slot_views()
	return int(views[slot].get_display_count()) if slot < views.size() else -1

# ------------------------------------------------------------ pause / focus -----
func _pause_and_focus() -> void:
	print("[pause freezes waves + travel; focus suspend/resume]")
	var h = _host_level(2)
	_click(h, [1, 2, 3])
	var rt = h.get_runtime()
	var sch = h.get_scheduler()
	rt.tick(rt.get_speed_authority().cadence_interval())
	for i in range(3):
		rt.tick(DT)
	var live0: int = sch.live_assignment_count()
	var pos0 := _agent_positions(h)
	rt.set_user_paused(true)
	for i in range(240):
		rt.tick(DT)
	_ok(sch.live_assignment_count() == live0 and _agent_positions(h) == pos0, "paused: no new wave, agents frozen")
	rt.set_user_paused(false)
	rt.notify_focus_lost()
	for i in range(240):
		rt.tick(DT)
	_ok(sch.live_assignment_count() == live0 and _agent_positions(h) == pos0, "focus lost: no new wave, agents frozen")
	rt.notify_focus_gained()
	for i in range(120):
		rt.tick(DT)
	var by := _by_slot(h)
	_ok(sch.live_assignment_count() + (_cleared(h)) > live0 and not h.get_completion().is_error(), "resumed safely: progress continues, no ERROR")
	_ok(by.values().filter(func(v): return v > 30).is_empty(), "no slot over-dispatched after resume")
	h.free()

func _cleared(h) -> int:
	return h.get_board().get_cell_count() - _active(h)

func _agent_positions(h) -> Array:
	var out: Array = []
	for c in h.get_agent_layer().get_children():
		if c is ScrubbotAgent:
			out.append(c.position)
	return out

# ---------------------------------------------------------------- retry -----
func _retry_cancels_parallel() -> void:
	print("[Retry cancels all live parallel assignments]")
	var h = _host_level(2)
	_click(h, [1, 2, 3, 1, 2])
	h.get_scheduler().step()
	h.get_scheduler().step()
	_ok(h.get_scheduler().live_assignment_count() == 10, "ten live parallel assignments before Retry")
	_ok(h.retry(), "Retry succeeds transaction-safely")
	_ok(h.get_scheduler().live_assignment_count() == 0 and h.get_claim_engine().live_claim_count() == 0
		and h.get_reservations().get_reservation_count() == 0 and h.get_slots().live_work_count() == 0
		and h.get_dispatcher().get_active_count() == 0 and h.get_slots().occupied_count() == 0
		and _active(h) == h.get_board().get_cell_count(), "all claims/reservations/work/agents cleared, board full, slots empty")
	var cols: Array = SupplyPlanLoader.load_engine(h.supply_plan_path, h.get_level())["engine"].debug_snapshot()["columns"]
	_ok(JSON.stringify(h.get_supply().debug_snapshot()["columns"]) == JSON.stringify(cols), "supply restored to the exact owner queues")
	h.free()

# --------------------------------------------------------------- tornado -----
func _tornado_multi_inflight() -> void:
	print("[Tornado with multiple same-color in-flight agents]")
	var h = _host_level(2)
	_click(h, [1, 2, 3, 1, 2])
	h.get_scheduler().step()
	h.get_scheduler().step()
	var c08: int = h.get_slots().get_color_id(0)
	_ok(h.get_scheduler().color_assignment_owners(c08).size() == 10, "ten same-color in-flight agents")
	h.get_economy().boosters.add_charges(BoosterInventory.TORNADO, 1)
	var r: Dictionary = h.get_actions().tornado(c08)
	_ok(r.get("ok", false), "Tornado on C08 commits %s" % str(r.get("reason", "")))
	var ev = CompletionEvaluator.new()
	var cards: Array = ev.transaction_cardinalities(h.get_scheduler(), h.get_dispatcher(), h.get_claim_engine(), h.get_reservations(), h.get_slots())
	_ok(not ev.has_fatal_inconsistency(h.get_scheduler(), h.get_dispatcher(), h.get_claim_engine(), h.get_reservations(), h.get_slots()),
		"post-Tornado cardinalities coherent %s" % str(cards))
	_ok(h.get_scheduler().color_assignment_owners(c08).is_empty(), "no C08 assignment survives the selected-color cancel")
	h.free()

func _terminal_cardinality_n() -> void:
	print("[terminal cardinality supports N concurrent]")
	var h = _host_level(2)
	_click(h, [1, 2, 3, 1, 2])
	h.get_scheduler().step()
	var ev = CompletionEvaluator.new()
	var cards: Array = ev.transaction_cardinalities(h.get_scheduler(), h.get_dispatcher(), h.get_claim_engine(), h.get_reservations(), h.get_slots())
	_ok(cards == [5, 5, 5, 5, 5] and not ev.has_fatal_inconsistency(h.get_scheduler(), h.get_dispatcher(), h.get_claim_engine(), h.get_reservations(), h.get_slots()),
		"five concurrent transactions: all cardinalities 5, no ERROR")
	_ok(h.get_completion().on_tick() == CompletionEvaluator.PLAYING, "completion stays PLAYING with in-flight work")
	h.free()

# ------------------------------------------------------------------ speed -----
func _speed_cadence_and_travel() -> void:
	print("[2x doubles travel, halves wave cadence]")
	var progress := []
	for two in [false, true]:
		var h = _host_level(2)
		_click(h, [1])
		var rt = h.get_runtime()
		var base: float = rt.get_speed_authority().cadence_interval()
		rt.set_speed_2x(two)
		var iv: float = rt.get_speed_authority().cadence_interval()
		if two:
			_ok(is_equal_approx(iv * 2.0, progress[0]["iv"]), "2x cadence interval is half of 1x (%.3f vs %.3f)" % [iv, progress[0]["iv"]])
		h.get_scheduler().step()
		h.get_scheduler().pause()
		var agent = null
		for c in h.get_agent_layer().get_children():
			if c is ScrubbotAgent:
				agent = c
		var p0: Vector2 = agent.position
		for i in range(6):
			rt.tick(DT)
		progress.append({"iv": iv, "d": agent.position.distance_to(p0)})
		h.free()
	_ok(absf(progress[1]["d"] - 2.0 * progress[0]["d"]) < 0.01 * maxf(1.0, progress[1]["d"]), "same frames: 2x travel distance is double (%.3f vs %.3f)" % [progress[1]["d"], progress[0]["d"]])

func _two_x_acquisition() -> void:
	print("[2x acquisition flow]")
	var h = _host_level(2)
	var eco = h.get_economy()
	var btn: Button = h.get_screen().get_speed_button()
	var sb0: int = eco.wallet.scrub_bucks()
	_ok(not eco.speed.is_manual_2x_entitled(2), "no manual entitlement at start")
	btn.pressed.emit()
	var pop = h.get_speed_acquisition_popup()
	_ok(pop != null and pop.visible and not h.get_speed_authority().is_2x(), "no-entitlement press opens the 2x popup, speed unchanged")
	_ok(pop.get_offer_button("level") != null and pop.get_offer_button("timed_900") != null and pop.get_offer_button("timed_1800") != null and pop.get_offer_button("timed_3600") != null,
		"offers: current level / 15m / 30m / 60m")
	_ok(pop.get_offer_button("level").text.find("200") != -1 and pop.get_offer_button("timed_900").text.find("300") != -1
		and pop.get_offer_button("timed_1800").text.find("500") != -1 and pop.get_offer_button("timed_3600").text.find("750") != -1, "canonical prices 200/300/500/750 SB")
	pop.get_cancel_button().pressed.emit()
	_ok(not pop.visible and eco.wallet.scrub_bucks() == sb0 and not h.get_speed_authority().is_2x() and not eco.speed.is_manual_2x_entitled(2), "cancel: nothing spent, no entitlement, speed unchanged")
	# Insufficient SB.
	eco.wallet.debit(EconomyWallet.SCRUB_BUCKS, eco.wallet.scrub_bucks() - 100)
	btn.pressed.emit()
	pop.get_offer_button("level").pressed.emit()
	_ok(pop.visible and pop.get_status_text().find("Not enough") != -1 and eco.wallet.scrub_bucks() == 100 and not h.get_speed_authority().is_2x(),
		"insufficient SB: visible message, nothing spent, speed unchanged")
	pop.get_cancel_button().pressed.emit()
	# Current-level purchase.
	eco.wallet.credit(EconomyWallet.SCRUB_BUCKS, 900)
	btn.pressed.emit()
	pop.get_offer_button("level").pressed.emit()
	_ok(not pop.visible and h.get_speed_authority().is_2x() and btn.text == "2x" and eco.wallet.scrub_bucks() == 800 and eco.speed.is_manual_2x_entitled(2),
		"current-level purchase: 200 SB spent, 2x immediately, control shows 2x")
	_ok(h.last_speed_purchase_result.has("save"), "purchase went through the durable-save action boundary")
	btn.pressed.emit()
	_ok(not h.get_speed_authority().is_2x() and btn.text == "1x", "entitled + 2x press -> 1x")
	btn.pressed.emit()
	_ok(h.get_speed_authority().is_2x() and (pop == null or not pop.visible), "entitled + 1x press -> 2x (no popup)")
	h.free()
	# Timed purchase on a fresh attempt.
	var h2 = _host_level(2)
	var eco2 = h2.get_economy()
	var sb2: int = eco2.wallet.scrub_bucks()
	h2.get_screen().get_speed_button().pressed.emit()
	h2.get_speed_acquisition_popup().get_offer_button("timed_900").pressed.emit()
	_ok(h2.get_speed_authority().is_2x() and eco2.wallet.scrub_bucks() == sb2 - 300 and eco2.speed.timed_seconds_remaining() > 0,
		"15m timed purchase: 300 SB, 2x on, timed entitlement authoritative")
	h2.free()
	await process_frame

func _auto_2x_free() -> void:
	print("[free supply-exhausted auto-2x]")
	var h = _host_level(2)
	var eco = h.get_economy()
	_ok(not eco.speed.is_manual_2x_entitled(2), "no entitlement")
	var plan: Dictionary = SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]
	var clicks: Array = plan["intendedColumnClicks"]
	var rt = h.get_runtime()
	var slots = h.get_slots()
	var i := 0
	var guard := 0
	while i < clicks.size() and guard < 200000:
		guard += 1
		if slots.rightmost_empty_index() != -1:
			if h.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
				i += 1
				continue
		rt.tick(DT)
	_ok(h.get_supply().is_exhausted() and h.get_speed_authority().is_2x(), "supply exhausted -> automatic 2x without purchase")
	h.free()

# ---------------------------------------------- perf-fix equivalence proofs -----
## The reachability prefilter may only skip candidates the full route would reject.
func _prefilter_equivalence() -> void:
	print("[reachability prefilter == full route verdict]")
	var h = _host_level(2)
	var board = h.get_board()
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var checked := 0
	var mismatches := 0
	# Walk the owner Apple sequence through the real kernel and compare at several states.
	var kernel = ProofKernel.new()
	var st = kernel.quiesce(ProofState.from_level_and_supply(h.get_level(), h.get_supply()))["state"]
	var clicks: Array = SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]["intendedColumnClicks"]
	for step in range(clicks.size()):
		if step % 6 == 0:
			for i in range(board.get_cell_count()):
				board.set_cell_state(i, BoardState.CellState.ACTIVE if st.active[i] == ProofState.ACTIVE_BYTE else BoardState.CellState.CLEARED)
			var origin := Vector2(float(board.get_width()) * 0.5, float(board.get_height()) + 4.0)
			var fast = ProductionTargetAccess.new(routing, raccess, board, origin)
			for i in range(board.get_cell_count()):
				if board.get_cell_state(i) != BoardState.CellState.ACTIVE:
					continue
				var req = RouteRequest.for_target(board, origin, i)
				var full_ok: bool = req != null and routing.compute_route(req, board, raccess).success
				checked += 1
				if fast.is_targetable(i) != full_ok:
					mismatches += 1
		st = kernel.apply_placement(st, int(clicks[step]) - 1)["state"]
	_ok(checked > 1000 and mismatches == 0, "prefiltered is_targetable == full route verdict on %d ACTIVE cells across 6 Apple states (%d mismatches)" % [checked, mismatches])
	h.free()

class _SlowAccess extends "res://scripts/gameplay/routing/production_access_query.gd":
	pass

## The canonical-access Dijkstra/source fast path must return the identical route.
func _fast_route_equivalence() -> void:
	print("[canonical fast path route == full segment-checked route]")
	var lvl = LevelLoader.load_from_path(Pack.level_path("level_003_palm_tree")).level_data
	var board = BoardState.from_level_data(lvl)
	var rng := RandomNumberGenerator.new()
	rng.seed = 52
	for i in range(board.get_cell_count()):
		if rng.randf() < 0.45:
			board.set_cell_state(i, BoardState.CellState.CLEARED)
	var routing = ProductionRoutingSystem.new()
	var fast_q = ProductionAccessQuery.new(board)
	var slow_q = _SlowAccess.new(board)
	var compared := 0
	var diffs := 0
	for i in range(board.get_cell_count()):
		if board.get_cell_state(i) != BoardState.CellState.ACTIVE:
			continue
		var origin := Vector2(float((i * 7) % board.get_width()) + 0.5, float(board.get_height()) + 4.0)
		var req = RouteRequest.for_target(board, origin, i)
		var a = routing.compute_route(req, board, fast_q)
		var b = routing.compute_route(req, board, slow_q)
		compared += 1
		if a.success != b.success or (a.success and a.get_points() != b.get_points()):
			diffs += 1
	_ok(compared > 500 and diffs == 0, "fast path route identical to segment-checked route for %d targets (%d diffs)" % [compared, diffs])

func _keyed_sort_equivalence() -> void:
	print("[keyed candidate sort == comparator sort]")
	var lvl = LevelLoader.load_from_path(Pack.level_path("level_005_party_toucan")).level_data
	var board = BoardState.from_level_data(lvl)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var all_same := true
	for trial in range(20):
		var cands: Array = []
		for i in range(board.get_cell_count()):
			if rng.randf() < 0.3:
				cands.append(i)
		cands.shuffle()
		var ref := cands.duplicate()
		ref.sort_custom(func(a, b): return TargetSelector._candidate_before(a, b, board))
		all_same = all_same and TargetSelector._priority_sorted(cands.duplicate(), board) == ref
	_ok(all_same, "20 random candidate sets: keyed order == bottom-most/left-most/index comparator order")

## The proof kernel uses the same per-slot wave: five C08 lanes each claim in one wave.
func _kernel_wave_model() -> void:
	print("[proof kernel wave model]")
	var h = _host_level(2)
	var kernel = ProofKernel.new()
	var st = kernel.quiesce(ProofState.from_level_and_supply(h.get_level(), h.get_supply()))["state"]
	for c in [0, 1, 2, 0, 1]:
		var r: Dictionary = kernel.apply_placement(st, c)
		st = r["state"]
	_ok(st.active_count() == h.get_board().get_cell_count() - 150, "kernel: five C08 x30 lanes fully consumed (150 clears)")
	_ok(st.occupied_slot_count() == 0, "kernel: all five lanes finished; slots empty at quiescence")
	h.free()

# ------------------------------------------------------------------- infra -----
func _write(tag: String, text: String) -> String:
	var p := "user://r01_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _uniq(tag: String) -> String:
	var p := "user://r01_%s_%d.save" % [tag, Time.get_ticks_usec()]
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

func _done() -> void:
	if _fail == 0:
		print("M52 R01 PARALLEL RUNTIME: PASS")
		quit(0)
	else:
		print("M52 R01 PARALLEL RUNTIME: FAIL (%d)" % _fail)
		quit(1)
