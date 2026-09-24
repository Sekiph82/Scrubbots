extends SceneTree
## M39-C001 V04 Phases B-E (F-M39-V03-002..005).
##   B: real production local-calendar provider + deterministic local-day seams;
##   C: +1 Slot exact rollback on forced engine/strip failure;
##   D: atomic progression + first-clear transaction with per-stage faults;
##   E: canonical production action facade (explicit results + committed signal).
## Run: godot --headless --path . -s res://tests/m39_v04_integration.gd

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const DailyService = preload("res://scripts/economy/daily_service.gd")
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")
const FirstClearTransaction = preload("res://scripts/economy/first_clear_transaction.gd")
const ProductionActionFacade = preload("res://scripts/economy/production_action_facade.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const DT := 1.0
const MAX_TICKS := 80000

var _fail := 0
var _now := 0

func _initialize() -> void:
	_phase_b_calendar()
	await _phase_c_plus_one()
	_phase_d_first_clear()
	await _phase_d_host_terminal()
	await _phase_e_facade()
	_done()

# ------------------------------------------------------------------ B ----

func _unix(y: int, m: int, d: int, hh: int, mm: int) -> int:
	return int(Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": d,
		"hour": hh, "minute": mm, "second": 0}))

func _daily(offset: int) -> DailyService:
	var econ = EconomyServices.new(EconomyConfig.DEFAULT_PATH, func(): return _now, null,
		LocalCalendar.offset_provider(func(): return _now, offset))
	return econ.daily

func _phase_b_calendar() -> void:
	print("[B local calendar]")
	_ok(LocalCalendar.ordinal(1970, 1, 1) == 0, "ordinal epoch 1970-01-01 == 0")
	_ok(LocalCalendar.ordinal(2026, 2, 1) - LocalCalendar.ordinal(2026, 1, 31) == 1, "month boundary consecutive")
	_ok(LocalCalendar.ordinal(2027, 1, 1) - LocalCalendar.ordinal(2026, 12, 31) == 1, "year boundary consecutive")
	_ok(LocalCalendar.ordinal(2028, 2, 29) - LocalCalendar.ordinal(2028, 2, 28) == 1, "leap day 02-28 -> 02-29 consecutive")
	_ok(LocalCalendar.ordinal(2028, 3, 1) - LocalCalendar.ordinal(2028, 2, 29) == 1, "leap day 02-29 -> 03-01 consecutive")
	_ok(LocalCalendar.ordinal(2027, 3, 1) - LocalCalendar.ordinal(2027, 2, 28) == 1, "non-leap 02-28 -> 03-01 consecutive")
	_ok(LocalCalendar.ordinal(2000, 3, 1) - LocalCalendar.ordinal(2000, 2, 28) == 2, "2000 is leap (02-29 exists)")
	_ok(LocalCalendar.ordinal(2100, 3, 1) - LocalCalendar.ordinal(2100, 2, 28) == 1, "2100 not leap")
	for y in [2026, 2027, 2028]:
		var ts := _unix(y, 7, 4, 12, 0)
		_ok(LocalCalendar.ordinal(y, 7, 4) == int(ts / 86400), "ordinal matches UTC day index at offset 0 (%d) — persisted keys compatible" % y)

	# Same LOCAL day across a UTC midnight (UTC-5): no new Daily.
	var dly := _daily(-5 * 3600)
	_now = _unix(2026, 1, 10, 23, 0)   # local 18:00 Jan 10
	var r1 = dly.claim_login()
	_ok(r1["ok"], "first login claim ok")
	_now = _unix(2026, 1, 11, 1, 0)    # UTC day changed; local 20:00 Jan 10
	_ok(not dly.claim_login()["ok"], "same local day across UTC midnight -> no new Daily")
	# Local midnight crossing: local 23:59 -> 00:01 Jan 11 local.
	_now = _unix(2026, 1, 11, 4, 59)
	_ok(not dly.claim_login()["ok"], "local 23:59 still same day")
	_now = _unix(2026, 1, 11, 5, 1)
	var r2 = dly.claim_login()
	_ok(r2["ok"] and dly.streak() == 2, "local-midnight crossing -> next Daily, streak 2")

	# UTC+9: UTC day same, local day changes (local midnight = 15:00 UTC).
	var east := _daily(9 * 3600)
	_now = _unix(2026, 6, 1, 14, 0)    # local 23:00 Jun 1
	_ok(east.claim_login()["ok"], "east: claim local Jun 1")
	_now = _unix(2026, 6, 1, 15, 30)   # same UTC day, local 00:30 Jun 2
	_ok(east.claim_login()["ok"] and east.streak() == 2, "east: local midnight inside one UTC day -> next Daily")

	# Month + year transitions keep the streak consecutive.
	var ny := _daily(0)
	_now = _unix(2026, 12, 31, 10, 0)
	ny.claim_login()
	_now = _unix(2027, 1, 1, 10, 0)
	_ok(ny.claim_login()["ok"] and ny.streak() == 2, "year transition increments streak")
	_now = _unix(2027, 1, 31, 10, 0)
	var mo := _daily(0)
	mo.claim_login()
	_now = _unix(2027, 2, 1, 10, 0)
	_ok(mo.claim_login()["ok"] and mo.streak() == 2, "month transition increments streak")
	var lp := _daily(0)
	_now = _unix(2028, 2, 28, 10, 0); lp.claim_login()
	_now = _unix(2028, 2, 29, 10, 0); lp.claim_login()
	_now = _unix(2028, 3, 1, 10, 0)
	_ok(lp.claim_login()["ok"] and lp.streak() == 3, "leap-day transitions increment streak (3)")

	# Clock rollback fail-closed.
	var rb := _daily(0)
	_now = _unix(2026, 5, 5, 12, 0)
	rb.claim_login()
	var snap_before = rb.snapshot()
	_now = _unix(2026, 5, 4, 12, 0)
	_ok(not rb.claim_login()["ok"], "clock rollback to prior day -> refused")
	_now = _unix(2026, 5, 6, 11, 0)
	# Forward local day but ts below high-water (simulated skew via provider): refused.
	var skew := DailyService.new(EconomyConfig.new(), EconomyServices.new().reward,
		func(): return _now, func(): return LocalCalendar.ordinal(2026, 5, 7))
	skew.import_snapshot({"last_claim_day": LocalCalendar.ordinal(2026, 5, 6), "last_claim_ts": _now + 5000,
		"highest_seen_ts": _now + 5000, "streak": 1, "tasks_day": -1, "tasks_done": [], "tasks_claimed_day": -1})
	_ok(skew.claim_login()["reason"] == "clock_rollback", "ts below high-water -> clock_rollback fail-closed")
	_ok(rb.snapshot() == snap_before, "refused claims mutate nothing")

	# Tasks done before today's login survive it; rollback never wipes/claims tasks.
	var tk := _daily(0)
	_now = _unix(2026, 9, 1, 8, 0)
	tk.mark_task_done(0)
	tk.claim_login()
	_ok(tk.tasks_done_count() == 1, "task done before login survives the login claim")
	_now = _unix(2026, 8, 31, 8, 0)
	_ok(tk.tasks_done_count() == 1, "clock rollback does not wipe today's task progress")
	_ok(tk.claim_task(0)["reason"] == "clock_rollback", "task claim refused under rollback")
	_now = _unix(2026, 9, 1, 9, 0)
	_ok(tk.claim_task(0)["ok"], "task claim ok once clock is back")

	# Relaunch preserves timestamps/high-water.
	var d1 := _daily(0)
	_now = _unix(2026, 8, 8, 9, 0)
	d1.claim_login()
	var s1 = d1.snapshot()
	var d2 := _daily(0)
	_ok(d2.import_snapshot(s1), "relaunch import ok")
	_ok(d2.snapshot()["last_claim_ts"] == _now and d2.snapshot()["highest_seen_ts"] == _now, "relaunch preserves last_claim_ts + highest_seen_ts")
	_ok(not d2.claim_login()["ok"], "relaunch same local day -> no duplicate Daily")

	# Production graph: AppState/EconomyServices default = OS LOCAL date.
	var sys_ord := LocalCalendar.ordinal_of_dict(Time.get_date_dict_from_system(false))
	var app = AppState.new("user://m39_v04_cal_%d.dat" % Time.get_ticks_usec())
	_ok(int(app.economy.daily._local_day_provider.call()) == sys_ord, "AppState injects OS local-calendar provider")
	_ok(int(EconomyServices.new().daily._local_day_provider.call()) == sys_ord, "EconomyServices default Daily = OS local date")
	var src := FileAccess.get_file_as_string("res://scripts/economy/daily_service.gd")
	_ok(src.find("_clock.call() / 86400") == -1 and src.find("LocalCalendar.system_provider()") != -1, "no UTC epoch-day fallback left in DailyService; system local provider wired")

# ------------------------------------------------------------------ C ----

func _phase_c_plus_one() -> void:
	print("[C +1 Slot exact rollback]")
	var h = await _make_host()
	if h == null:
		return
	var econ = h.get_economy()
	var strip = h.get_screen().get_five_slot_strip()
	var origin = h.get_origin_provider()
	for stage in ["engine", "strip"]:
		for pay in ["charge", "sb"]:
			if pay == "charge":
				econ.boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
			else:
				econ.wallet.credit(EconomyWallet.SCRUB_BUCKS, 100000)
			var pre_econ = econ.snapshot()
			var pre_slots = h.get_slots().snapshot()
			h.set_plus_one_fault_injector(func(s): return s == stage)
			_ok(not h.activate_plus_one_slot(), "%s/%s: forced failure returns false" % [stage, pay])
			_ok(h.get_slots().get_slot_count() == 5, "%s/%s: M24 engine back at 5" % [stage, pay])
			_ok(h.get_slots().snapshot() == pre_slots, "%s/%s: M24 slots exact" % [stage, pay])
			_ok(strip.get_capacity() == 5 and strip.get_slot_count() == 5, "%s/%s: strip back at 5" % [stage, pay])
			_ok(econ.capacity.active_capacity() == 5 and econ.capacity.can_activate_plus_one(), "%s/%s: capacity authority (5, unused)" % [stage, pay])
			_ok(econ.snapshot() == pre_econ, "%s/%s: economy (charge/SB) exact" % [stage, pay])
			_ok(not is_finite(origin.origin_for_slot(5).x), "%s/%s: slot 5 origin unroutable" % [stage, pay])
			_ok(h.get_slots().can_grow_to_sixth(), "%s/%s: can grow again" % [stage, pay])
			_ok(econ.boosters.charges(BoosterInventory.PLUS_ONE_SLOT) == (1 if pay == "charge" else 0), "%s/%s: paid via %s and refunded" % [stage, pay, pay])
			# Remove the refunded charge so the next case is isolated.
			if pay == "charge":
				var bsnap = econ.boosters.snapshot()
				bsnap[BoosterInventory.PLUS_ONE_SLOT] = 0
				econ.boosters.import_snapshot(bsnap)
	h.set_plus_one_fault_injector(Callable())
	_ok(h.activate_plus_one_slot(), "after rollbacks a clean +1 Slot commits")
	_ok(h.get_slots().get_slot_count() == 6 and strip.get_capacity() == 6, "engine + strip at 6")
	var sb_after: int = econ.wallet.scrub_bucks()
	_ok(sb_after >= 0, "SB non-negative after commit")
	_free_host(h)

# ------------------------------------------------------------------ D ----

func _fresh_pair() -> Array:
	return [LevelProgressionService.new(), EconomyServices.new(EconomyConfig.DEFAULT_PATH, func(): return 1000)]

func _phase_d_first_clear() -> void:
	print("[D atomic first-clear]")
	for stage in ["progression", "first_clear", "streak", "entitlement"]:
		var pr = _fresh_pair()
		var prog = pr[0]
		var econ = pr[1]
		econ.wallet.credit(EconomyWallet.SCRUB_BUCKS, 10000)
		_ok(econ.speed.purchase_current_level(1)["ok"], "%s: level-1 2x entitlement bought (so entitlement stage mutates)" % stage)
		var pre_p = prog.snapshot()
		var pre_e = econ.snapshot()
		var r = FirstClearTransaction.commit(prog, econ, 1, func(s): return s == stage)
		_ok(not r["ok"] and r["stage"] == stage and r["restored"], "%s: fault -> rolled back" % stage)
		_ok(prog.snapshot() == pre_p, "%s: progression exact" % stage)
		_ok(econ.snapshot() == pre_e, "%s: wallet/BP/streak/gift/applied-tx/entitlement exact" % stage)
		# Same transaction then commits cleanly (no poisoned tx ids).
		var r2 = FirstClearTransaction.commit(prog, econ, 1)
		_ok(r2["ok"], "%s: clean retry commits" % stage)
		_ok(prog.current_level() == 2, "%s: frontier advanced once" % stage)
	# Stale / future / replay zero mutation.
	var pr2 = _fresh_pair()
	var p2 = pr2[0]
	var e2 = pr2[1]
	FirstClearTransaction.commit(p2, e2, 1)
	var sp = p2.snapshot()
	var se = e2.snapshot()
	_ok(not FirstClearTransaction.commit(p2, e2, 1)["ok"], "replay refused")
	_ok(not FirstClearTransaction.commit(p2, e2, 5)["ok"], "future refused")
	_ok(not FirstClearTransaction.commit(p2, e2, 0)["ok"], "invalid refused")
	_ok(p2.snapshot() == sp and e2.snapshot() == se, "stale/future/replay zero mutation")
	# Success grants exactly once.
	var pr3 = _fresh_pair()
	var sb0: int = pr3[1].wallet.scrub_bucks()
	var bp0: int = pr3[1].wallet.bot_parts()
	_ok(FirstClearTransaction.commit(pr3[0], pr3[1], 1)["ok"], "frontier WON commits")
	_ok(pr3[1].wallet.scrub_bucks() > sb0 and pr3[1].wallet.bot_parts() == bp0 + 1, "first-clear SB + bot part granted")
	_ok(pr3[1].streak.streak() == 1, "streak advanced")

func _phase_d_host_terminal() -> void:
	print("[D host terminal fault]")
	var h = await _make_host()
	if h == null:
		return
	var econ = h.get_economy()
	var prog = h.get_progression()
	var pre_p = prog.snapshot()
	h.set_first_clear_fault_injector(func(s): return s == "streak")
	_drain(h)
	_ok(h.get_completion().is_won(), "real stack reaches WON")
	_ok(not h.last_first_clear_result.get("ok", true) and h.last_first_clear_result.get("stage", "") == "streak", "host WON used the coordinator (fault at streak)")
	_ok(prog.snapshot() == pre_p, "host: progression unchanged after downstream failure")
	_ok(econ.streak.streak() == 0, "host: streak unchanged")
	_free_host(h)

# ------------------------------------------------------------------ E ----

func _phase_e_facade() -> void:
	print("[E canonical action facade]")
	var h = await _make_host()
	if h == null:
		return
	var econ = h.get_economy()
	var act = h.get_actions()
	_ok(act != null, "host exposes ProductionActionFacade")
	var saves := [0]
	var events: Array = []
	act.bind_save(func():
		saves[0] += 1
		return {"ok": true})
	act.action_committed.connect(func(a, r): events.append(a))

	econ.wallet.credit(EconomyWallet.SCRUB_BUCKS, 1000000)
	econ.wallet.credit(EconomyWallet.BOT_PARTS, 1000)
	econ.boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
	econ.boosters.add_charges(BoosterInventory.RANDOM, 1)
	econ.boosters.add_charges(BoosterInventory.SELECTOR, 1)
	econ.boosters.add_charges(BoosterInventory.TORNADO, 1)

	var results: Array = []
	results.append(act.plus_one_slot())
	var rr = act.random()
	print("  info: random -> ", rr)
	_ok(rr["ok"] or rr.get("reason", "") == "not_solver_safe", "random: committed or explicit not_solver_safe (no charge)")
	results.append(rr)
	var elig: Array = h.get_booster_adapter().eligible_safe_batches()
	var rs = act.selector(elig[0] if not elig.is_empty() else "none")
	print("  info: selector -> ", rs, " eligible=", elig)
	_ok(elig.is_empty() or rs["ok"], "selector commits on an eligible batch")
	results.append(rs)
	var colors: Array = h.get_booster_adapter().present_colors()
	results.append(act.tornado(colors[0]))
	results.append(act.buy_current_level_2x())
	var timed: Array = econ.speed._timed_products.keys()
	results.append(act.buy_timed_2x(int(timed[0])))
	econ.hearts.consume()
	results.append(act.buy_heart())
	econ.hearts.consume()
	results.append(act.refill_hearts())
	results.append(act.claim_daily_login())
	econ.daily.mark_task_done(0)
	results.append(act.claim_daily_task(0))
	econ.daily.mark_task_done(1)
	econ.daily.mark_task_done(2)
	results.append(act.claim_daily_all_tasks())
	econ.gift.add_streak_sb("m39v04_gift", 10)
	var occ: Array = econ.gift.claimable()
	results.append(act.claim_gift(occ[0]["id"] if not occ.is_empty() else "none"))
	results.append(act.claim_collection_rewards())
	var cid: String = econ.collection.all_card_ids()[0]
	econ.collection.add_copies(cid, 3)
	results.append(act.exchange_card(cid, 1))
	results.append(act.exchange_all_extras())
	results.append(act.unlock_robot("m39v04_robot"))

	var expect_ok := {"plus_one_slot": true, "tornado": true, "buy_current_level_2x": true,
		"buy_timed_2x": true, "buy_heart": true, "refill_hearts": true, "claim_daily_login": true,
		"claim_daily_task": true, "claim_daily_all_tasks": true, "claim_gift": true,
		"claim_collection_rewards": false, "exchange_card": true, "exchange_all_extras": true,
		"unlock_robot": true}
	var n_ok := 0
	for r in results:
		_ok(typeof(r) == TYPE_DICTIONARY and r.has("ok") and r.has("action"), "explicit result for %s" % r.get("action", "?"))
		if expect_ok.has(r["action"]):
			_ok(bool(r["ok"]) == bool(expect_ok[r["action"]]), "%s ok=%s (%s)" % [r["action"], r["ok"], r.get("reason", "")])
		if r["ok"]:
			n_ok += 1
	_ok(saves[0] == n_ok, "save requested exactly once per committed action (%d)" % n_ok)
	_ok(events.size() == n_ok, "action_committed emitted only for committed actions (%d)" % events.size())
	# Failures neither save nor emit.
	var s_before: int = saves[0]
	_ok(not act.unlock_robot("m39v04_robot")["ok"], "duplicate unlock refused")
	_ok(not act.tornado(9999)["ok"], "absent-color tornado refused")
	_ok(saves[0] == s_before and events.size() == n_ok, "failed actions: no save, no signal")
	# Exchange tx id survives a relaunch-style counter reset.
	econ.collection.add_copies(cid, 2)
	econ.exchange._tx_counter = 0
	_ok(act.exchange_card(cid, 1)["ok"], "exchange after counter reset not refused as duplicate")
	# Economy-only facade (menus, no host).
	var menu = ProductionActionFacade.new(econ)
	_ok(menu.random()["reason"] == "no_gameplay_host", "economy-only facade refuses gameplay boosters explicitly")
	_free_host(h)

# ------------------------------------------------------------ host driver ----

func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	for _i in range(MAX_TICKS):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(DT)
		if h.get_completion().is_terminal():
			break

func _make_host():
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "production host built (%s)" % host.get_build_error())
	if not ok:
		return null
	await process_frame
	await process_frame
	host.get_screen().relayout()
	await process_frame
	host.get_runtime().set_process(false)
	host.set_meta("sub", sub)
	return host

func _free_host(host) -> void:
	if host == null:
		return
	var sub = host.get_meta("sub") if host.has_meta("sub") else null
	if sub != null and is_instance_valid(sub):
		sub.free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 V04 integration evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
