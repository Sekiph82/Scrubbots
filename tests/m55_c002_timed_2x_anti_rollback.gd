extends SceneTree
## M55-C002 — timed 2x fails closed on backward device-clock movement
## (coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md).
##
## Production authorities under test: SpeedEntitlementService (persisted high-water
## clock guard), EconomyServices/SaveService/AppState save + relaunch, the
## ProductionActionFacade purchase path and the production host (background/foreground,
## free supply-exhausted auto-2x). Every before/after value is printed for the matrix.
##
## Sensitivity: with the high-water clamp removed (_effective_now returning the raw
## wall clock) sections 1, 2, 3, 4, 5 and 7 FAIL.
##
## Run: godot --headless --path . -s res://tests/m55_c002_timed_2x_anti_rollback.gd

const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const SpeedEntitlementService = preload("res://scripts/economy/speed_entitlement_service.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")

const T0 := 50_000_000
const EXPECTED_CASES := ["1_active_rollback", "2_expired_rollback", "3_forward_resume", "4_save_relaunch",
	"4b_background_foreground", "5_legacy", "6_malformed", "7_purchase", "8_level_and_auto", "9_products"]

var _fail := 0
var _tmp: Array = []
var _done_cases := {}
var t := [T0]

func _initialize() -> void:
	await process_frame
	_active_rollback()
	_expired_rollback()
	_forward_resume()
	_save_relaunch()
	await _background_foreground()
	_legacy()
	_malformed()
	_purchase()
	await _level_and_auto()
	_products()
	_cleanup()
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _done_cases.has(c))
	_ok(missing.is_empty(), "case ledger: every expected case completed %s" % str(missing))
	print("M55-C002 TIMED 2X ANTI-ROLLBACK: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

func _clock() -> int:
	return t[0]

func _svc(sb: int = 100000):
	return SpeedEntitlementService.new(EconomyWallet.new(sb), EconomyConfig.new(), Callable(self, "_clock"))

# ---------------------------------------------------------------- 1 ----------
func _active_rollback() -> void:
	print("[1. active timed 2x + backward clock jumps]")
	t[0] = T0
	var se = _svc()
	_ok(se.purchase_timed(1800).get("ok", false), "30-minute timed 2x bought at T")
	t[0] += 600
	var before: int = se.timed_seconds_remaining()
	var seen: Array = [before]
	var never_up := true
	for jump in [1, 60, 5000, 86400, 31536000]:
		t[0] = T0 + 600 - jump
		var r: int = se.timed_seconds_remaining()
		seen.append(r)
		never_up = never_up and r <= before and se.is_manual_2x_entitled(999)
	print("    remaining at T+600 = %d; after rollbacks of 1 s / 60 s / 5000 s / 1 day / 1 year: %s" % [before, str(seen.slice(1))])
	_ok(before == 1200 and never_up and seen.slice(1).all(func(v): return v == 1200),
		"remaining never increases under any backward jump (stays 1200; pre-fix would be up to 1200+jump)")
	_ok(se.clock_high_water() == T0 + 600, "high-water mark holds the highest observed wall clock (T+600)")
	_done_cases["1_active_rollback"] = true

# ---------------------------------------------------------------- 2 ----------
func _expired_rollback() -> void:
	print("[2. expired timed 2x + backward clock jumps]")
	t[0] = T0
	var se = _svc()
	se.purchase_timed(900)
	t[0] += 901
	_ok(se.timed_seconds_remaining() == 0 and not se.is_manual_2x_entitled(999), "expired at T+901")
	var revived := 0
	for jump in [2, 450, 901, 5000, 1000000]:
		t[0] = T0 + 901 - jump
		if se.timed_seconds_remaining() != 0 or se.is_manual_2x_entitled(999):
			revived += 1
	print("    after rollbacks to T-1, T+451, T, T-4099, T-999099: revived %d times" % revived)
	_ok(revived == 0, "expired entitlement never revives (remaining 0, is_manual_2x_entitled false) even when rolled back before the purchase time")
	_done_cases["2_expired_rollback"] = true

# ---------------------------------------------------------------- 3 ----------
func _forward_resume() -> void:
	print("[3. forward movement after rollback resumes only beyond the high-water mark]")
	t[0] = T0
	var se = _svc()
	se.purchase_timed(1800)
	t[0] = T0 + 600
	_ok(se.timed_seconds_remaining() == 1200, "T+600: 1200 remain")
	t[0] = T0 - 3000
	var frozen: Array = []
	for step in [0, 1000, 3000, 3599]:
		t[0] = T0 - 3000 + step
		frozen.append(se.timed_seconds_remaining())
	print("    clock climbing back from T-3000 toward the high-water mark: %s" % str(frozen))
	_ok(frozen.all(func(v): return v == 1200), "countdown frozen at 1200 while the wall clock is below the high-water mark")
	t[0] = T0 + 700
	_ok(se.timed_seconds_remaining() == 1100, "clock 100 s beyond the high-water mark: countdown resumes (1100)")
	t[0] = T0 + 1800
	_ok(se.timed_seconds_remaining() == 0 and not se.is_manual_2x_entitled(999), "normal forward movement still expires it at T+1800")
	_done_cases["3_forward_resume"] = true

# ---------------------------------------------------------------- 4 ----------
func _save_relaunch() -> void:
	print("[4. anti-rollback state persists across save/relaunch]")
	t[0] = T0
	var path := _uniq("relaunch")
	var clock := Callable(self, "_clock")
	var app = AppState.new(path, clock)
	app.economy.wallet.credit(EconomyWallet.SCRUB_BUCKS, 5000)
	_ok(app.actions.buy_timed_2x(1800).get("ok", false), "timed 2x bought through ProductionActionFacade (durable save)")
	t[0] += 600
	_ok(app.flush().get("ok", false), "flush at T+600")
	var saved = JSON.parse_string(FileAccess.get_file_as_string(path))
	var hw_saved = saved["economy"]["speed"].get("clock_high_water", null)
	_ok(hw_saved != null and int(hw_saved) == T0 + 600, "save file carries economy.speed.clock_high_water == T+600 (got %s)" % str(hw_saved))
	t[0] -= 5000
	var app2 = AppState.new(path, clock)
	var r2: int = app2.economy.speed.timed_seconds_remaining()
	print("    relaunch at T-4400 (5000 s rollback): remaining %d (pre-fix 6200)" % r2)
	_ok(r2 == 1200 and app2.economy.speed.is_manual_2x_entitled(999), "relaunch after rollback: remaining 1200, not extended")
	t[0] = T0 + 1801
	_ok(app2.economy.speed.timed_seconds_remaining() == 0, "expires at T+1801 after relaunch")
	_ok(app2.flush().get("ok", false), "flush expired state")
	t[0] = T0 - 100000
	var app3 = AppState.new(path, clock)
	_ok(app3.economy.speed.timed_seconds_remaining() == 0 and not app3.economy.speed.is_manual_2x_entitled(999),
		"relaunch after a 100k s rollback: expired entitlement stays expired")
	_ok(app3.economy.speed.clock_high_water() == T0 + 1801, "relaunched guard == persisted high-water (T+1801)")
	_done_cases["4_save_relaunch"] = true

func _background_foreground() -> void:
	print("[4b. background / foreground with a backward jump while backgrounded]")
	t[0] = T0
	var path := _uniq("bg")
	var app = AppState.new(path, Callable(self, "_clock"))
	app.economy.wallet.credit(EconomyWallet.SCRUB_BUCKS, 5000)
	for n in range(1, 2):
		app.progression.record_win(n)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	get_root().add_child(h)
	_ok(h.build(), "Level 2 host builds")
	h.get_runtime().set_process(false)
	_ok(h.get_actions().buy_timed_2x(900).get("ok", false), "15-minute timed 2x bought in gameplay")
	t[0] += 300
	var before: int = app.economy.speed.timed_seconds_remaining()
	get_root().propagate_notification(NOTIFICATION_APPLICATION_PAUSED)
	_ok(h.get_runtime().is_system_suspended() and app.flush().get("ok", false), "backgrounded + flushed at T+300")
	t[0] -= 7200
	get_root().propagate_notification(NOTIFICATION_APPLICATION_RESUMED)
	var after: int = app.economy.speed.timed_seconds_remaining()
	print("    remaining before background %d, after 7200 s backward jump + foreground %d" % [before, after])
	_ok(not h.get_runtime().is_system_suspended() and after == before and after == 600, "foreground after rollback: remaining unchanged (600)")
	t[0] = T0 + 901
	_ok(not app.economy.speed.is_manual_2x_entitled(2), "expired at T+901")
	t[0] = T0 - 10
	_ok(not app.economy.speed.is_manual_2x_entitled(2) and app.economy.speed.timed_seconds_remaining() == 0, "rollback in gameplay cannot re-enable manual 2x")
	h.free()
	await process_frame
	_done_cases["4b_background_foreground"] = true

# ---------------------------------------------------------------- 5 ----------
func _legacy() -> void:
	print("[5. legacy snapshot / save without clock_high_water]")
	t[0] = T0
	var se = _svc()
	_ok(se.import_snapshot({"entitled_level": -1, "timed_expiry": T0 + 1000}), "legacy speed snapshot (no guard) imports")
	_ok(se.timed_seconds_remaining() == 1000 and se.clock_high_water() == T0, "legitimate active entitlement preserved (1000 s); guard initialized at the import boundary to the observed clock")
	t[0] = T0 - 20000
	_ok(se.timed_seconds_remaining() == 1000, "subsequent rollback protected (still 1000)")
	t[0] = T0 + 400
	_ok(se.timed_seconds_remaining() == 600, "forward movement counts down normally (600)")
	_ok(int(se.snapshot()["clock_high_water"]) == T0 + 400, "next snapshot persists the guard")
	var se2 = _svc()
	_ok(se2.import_snapshot({"entitled_level": 7, "timed_expiry": 0}) and se2.is_manual_2x_entitled(7), "legacy current-level entitlement preserved")
	# Legacy SAVE FILE through AppState: strip the field from a real save.
	t[0] = T0
	var path := _uniq("legacy")
	var app = AppState.new(path, Callable(self, "_clock"))
	app.economy.wallet.credit(EconomyWallet.SCRUB_BUCKS, 5000)
	app.actions.buy_timed_2x(3600)
	app.flush()
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	d["economy"]["speed"].erase("clock_high_water")
	_write_raw(path, JSON.stringify(d))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	t[0] = T0 + 1000
	var app2 = AppState.new(path, Callable(self, "_clock"))
	_ok(String(app2.load_result.get("source", "")) == "primary" and not app2.is_blocked, "legacy save (no guard) loads from primary, app not blocked (%s)" % str(app2.load_result))
	_ok(app2.economy.speed.timed_seconds_remaining() == 2600, "legacy active entitlement kept at the upgrade boundary (2600)")
	t[0] = T0 - 50000
	_ok(app2.economy.speed.timed_seconds_remaining() == 2600, "rollback after the upgrade boundary protected (2600)")
	t[0] = T0 + 1000
	app2.flush()
	var d2: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_ok(int(d2["economy"]["speed"].get("clock_high_water", -1)) == T0 + 1000, "first upgraded save writes the guard (T+1000)")
	_done_cases["5_legacy"] = true

# ---------------------------------------------------------------- 6 ----------
func _malformed() -> void:
	print("[6. present-but-malformed guard fails closed]")
	t[0] = T0
	var bad := [-1, 1.5, -0.5, "100", null, true, [T0], {"v": T0}, NAN, INF]
	var rejected := 0
	for v in bad:
		var se = _svc()
		se.purchase_timed(900)
		var pre: Dictionary = se.snapshot()
		var ok: bool = se.import_snapshot({"entitled_level": -1, "timed_expiry": T0 + 5, "clock_high_water": v})
		if not ok and se.snapshot() == pre:
			rejected += 1
		else:
			print("    NOT rejected: %s" % str(v))
	_ok(rejected == bad.size(), "%d/%d malformed guard values rejected with state untouched (negative, fractional, string, null, bool, array, dict, NaN, INF)" % [rejected, bad.size()])
	var se_ok = _svc()
	_ok(se_ok.import_snapshot({"entitled_level": -1, "timed_expiry": 0, "clock_high_water": float(T0)}), "integral float (JSON number) accepted")
	# Save-level: a malformed guard in the primary save is never adopted.
	var path := _uniq("badsave")
	var app = AppState.new(path, Callable(self, "_clock"))
	app.mark_dirty()
	app.flush()
	app.flush()   # second write makes the .bak a valid previous save
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	d["economy"]["speed"]["clock_high_water"] = -5
	_ok(String(app.save.validate_candidate(d).get("reason", "")) == "economy_import", "SaveService.validate_candidate rejects a negative guard as economy_import")
	d["economy"]["speed"]["clock_high_water"] = 12.5
	_ok(String(app.save.validate_candidate(d).get("reason", "")) == "economy_import", "SaveService.validate_candidate rejects a fractional guard as economy_import")
	_write_raw(path, JSON.stringify(d))
	var app2 = AppState.new(path, Callable(self, "_clock"))
	_ok(String(app2.load_result.get("source", "")) != "primary" and app2.economy.speed.clock_high_water() == T0,
		"relaunch with a malformed primary guard falls back (%s); the malformed value is never adopted" % str(app2.load_result.get("source", "")))
	_done_cases["6_malformed"] = true

# ---------------------------------------------------------------- 7 ----------
func _purchase() -> void:
	print("[7. explicit new purchase is the only way to add time]")
	t[0] = T0
	var w := EconomyWallet.new(10000)
	var se = SpeedEntitlementService.new(w, EconomyConfig.new(), Callable(self, "_clock"))
	se.purchase_timed(1800)
	t[0] = T0 + 600
	_ok(se.timed_seconds_remaining() == 1200, "1200 remain at T+600")
	t[0] = T0 - 4000   # rolled back 4600 s below the high-water mark
	var sb0: int = w.scrub_bucks()
	var r: Dictionary = se.purchase_timed(900)
	_ok(r.get("ok", false) and w.scrub_bucks() == sb0 - 300, "15-minute purchase while rolled back charges exactly 300 SB once")
	_ok(se.timed_seconds_remaining() == 2100 and int(r["expiry"]) == T0 + 1800 + 900,
		"extends from max(effective time, expiry): 1200 + 900 = 2100 (expiry T+2700), never from the rolled-back clock")
	t[0] = T0 + 3000
	var sb1: int = w.scrub_bucks()
	se.purchase_timed(3600)
	_ok(se.timed_seconds_remaining() == 3600 and w.scrub_bucks() == sb1 - 750, "after expiry a 60-minute purchase starts from effective now (3600) and charges 750 once")
	var poor := SpeedEntitlementService.new(EconomyWallet.new(100), EconomyConfig.new(), Callable(self, "_clock"))
	_ok(not poor.purchase_timed(900).get("ok", false) and poor.timed_seconds_remaining() == 0, "insufficient SB: no charge, no time")
	_done_cases["7_purchase"] = true

# ---------------------------------------------------------------- 8 ----------
func _level_and_auto() -> void:
	print("[8. current-level 2x and free auto-2x unchanged]")
	t[0] = T0
	var w := EconomyWallet.new(1000)
	var se = SpeedEntitlementService.new(w, EconomyConfig.new(), Callable(self, "_clock"))
	_ok(se.purchase_current_level(3).get("ok", false) and w.scrub_bucks() == 800, "current-level 2x = 200 SB")
	t[0] = T0 - 999999
	_ok(se.is_manual_2x_entitled(3) and not se.is_manual_2x_entitled(4), "current-level entitlement independent of clock rollback (level 3 only)")
	se.on_level_completed(3, false)
	_ok(se.is_manual_2x_entitled(3), "survives a failed attempt")
	se.on_level_completed(3, true)
	_ok(not se.is_manual_2x_entitled(3), "cleared on success")
	# Free supply-exhausted auto-2x on the production host with a rolled-back clock.
	t[0] = T0
	var app = AppState.new(_uniq("auto"), Callable(self, "_clock"))
	app.progression.record_win(1)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	get_root().add_child(h)
	_ok(h.build(), "Level 2 host builds")
	var rt = h.get_runtime()
	rt.set_process(false)
	t[0] = T0 - 86400
	var sb0: int = app.economy.wallet.scrub_bucks()
	_ok(not app.economy.speed.is_manual_2x_entitled(2), "no manual entitlement")
	var clicks: Array = SupplyPlanLoader.load_plan(h.supply_plan_path)["plan"]["intendedColumnClicks"]
	var i := 0
	var guard := 0
	while i < clicks.size() and guard < 200000:
		guard += 1
		if h.get_slots().rightmost_empty_index() != -1 and h.get_input_controller().activate_front(int(clicks[i]) - 1).get("ok", false):
			i += 1
			continue
		rt.tick(1.0)
	_ok(h.get_supply().is_exhausted() and h.get_speed_authority().is_2x() and app.economy.wallet.scrub_bucks() == sb0,
		"supply exhausted -> free automatic 2x, no SB charged, independent of the timed guard")
	h.free()
	await process_frame
	_done_cases["8_level_and_auto"] = true

# ---------------------------------------------------------------- 9 ----------
func _products() -> void:
	print("[9. canonical product table unchanged]")
	var c := EconomyConfig.new()
	var got := {}
	for p in c.speed_timed_products():
		got[int(p["seconds"])] = int(p["sb"])
	_ok(got == {900: 300, 1800: 500, 3600: 750} and c.speed_current_level_sb() == 200, "timed 900/300, 1800/500, 3600/750; current level 200 (got %s)" % str(got))
	_ok(c.hearts_regen_seconds() == 900, "Heart regen still 900 s")
	_done_cases["9_products"] = true

# ------------------------------------------------------------------ infra ----
func _uniq(tag: String) -> String:
	var p := "user://m55c2_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

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
