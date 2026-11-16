extends SceneTree
## SB-GIFT-METER-48H (owner 2026-11-17) — a Gift Meter cycle lasts at most 48 h from its first
## progress; expiry drops unfinished progress (meter back to 0/1), queued milestones stay
## claimable, 1000 inside the window rolls over with a fresh window, a clock moved backwards
## never expires / extends the window, old saves migrate, Home shows the time left (EN/TR).
## Real EconomyConfig / GiftMeterService / AppState / Home scene with an injected wall clock.
##
## Run: godot --headless --path . -s res://tests/sb_gift_meter_48h.gd

const AppState = preload("res://scripts/app/app_state.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const UiText = preload("res://scripts/ui/ui_text.gd")

const CONFIG := "res://data/config/economy_rewards_v1.json"
const H := 3600
const WINDOW := 48 * H
const T0 := 1_800_000_000

var EXPECTED_CASES := [
	"g01_config", "g02_no_window_at_zero", "g03_expiry_keeps_queue", "g04_rollover_new_window",
	"g05_migration", "g06_clock_rollback", "g07_home_countdown",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := T0

func _initialize() -> void:
	await process_frame
	_g01_config()
	_g02_no_window_at_zero()
	_g03_expiry_keeps_queue()
	_g04_rollover_new_window()
	_g05_migration()
	_g06_clock_rollback()
	await _g07_home_countdown()
	_cleanup()
	_done()

func _clock() -> int:
	return _now

func _svc():
	_now = T0
	return GiftMeterService.new(Callable(self, "_clock"), 48)

func _g01_config() -> void:
	print("[g01 config: schema 4, gift_meter.cycle_window_hours 48, strict]")
	var c = EconomyConfig.new()
	_ok(c.is_ok() and c.gift_meter_cycle_window_hours() == 48, "schema 4 config loads with a 48 h window %s" % c.get_error())
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var v3: Dictionary = cfg.duplicate(true)
	v3["schema_version"] = 3
	_ok(not _load(v3, "v3").is_ok(), "schema_version 3 rejected")
	for v in [null, 0, -1, 1.5, "48"]:
		var bad: Dictionary = cfg.duplicate(true)
		if v == null:
			bad["gift_meter"].erase("cycle_window_hours")
		else:
			bad["gift_meter"]["cycle_window_hours"] = v
		_ok(not _load(bad, "wh").is_ok(), "cycle_window_hours %s rejected" % str(v))
	_complete("g01_config")

func _g02_no_window_at_zero() -> void:
	print("[g02 no window while progress is 0]")
	var g = _svc()
	_now = T0 + 30 * 24 * H
	_ok(g.cycle_progress() == 0 and g.window_seconds_left() == 0 and int(g.snapshot()["window_start"]) == -1, "fresh meter: no window, nothing expires")
	g.add_streak_sb("a", 4)
	_ok(g.window_seconds_left() == WINDOW and int(g.snapshot()["window_start"]) == _now, "first progress starts a full 48 h window")
	_complete("g02_no_window_at_zero")

func _g03_expiry_keeps_queue() -> void:
	print("[g03 expiry at 48 h resets progress; queued milestones stay claimable]")
	var app = AppState.new(_uniq("g03"), Callable(self, "_clock"))
	_now = T0
	var g = app.economy.gift
	g.add_streak_sb("a", 7)
	_now = T0 + H
	g.add_streak_sb("b", 3)
	_ok(g.cycle_progress() == 10 and g.claimable().size() == 3, "10 progress, m1/m5/m10 queued")
	_now = T0 + WINDOW - 1
	_ok(g.cycle_progress() == 10 and g.window_seconds_left() == 1, "1 s before 48 h: progress kept, 1 s left (window not moved by later progress)")
	_now = T0 + WINDOW
	_ok(g.cycle_progress() == 0 and g.window_seconds_left() == 0 and g.cycles_completed() == 0, "at 48 h: progress 0, no window, not a completed cycle")
	_ok(g.claimable().map(func(o): return o["id"]) == ["gift_ms:c0:m1", "gift_ms:c0:m5", "gift_ms:c0:m10"], "queued milestones survive expiry")
	_ok(bool(app.actions.claim_gift("gift_ms:c0:m5").get("ok", false)), "pre-expiry milestone still claims")
	_ok(int(g.total_progress()) == 10 and int(g.snapshot()["expired_progress"]) == 10, "lifetime total kept, 10 recorded as expired")
	_now = T0 + WINDOW + 5 * H
	var n: Array = g.add_streak_sb("c", 2)
	_ok(n.map(func(o): return o["id"]) == ["gift_ms:c1:m1"] and g.cycle_progress() == 2 and g.window_seconds_left() == WINDOW, "next progress: new cycle c1 queues m1 again, fresh 48 h window")
	var g2 = GiftMeterService.new(Callable(self, "_clock"), 48)
	_ok(g2.import_snapshot(g.snapshot()) and g2.snapshot() == g.snapshot(), "post-expiry snapshot round-trips")
	_complete("g03_expiry_keeps_queue")

func _g04_rollover_new_window() -> void:
	print("[g04 1000 inside the window rolls over with a new window]")
	var g = _svc()
	g.add_streak_sb("a", 990)
	_now = T0 + 47 * H
	var n: Array = g.add_streak_sb("b", 15)
	_ok(n.map(func(o): return o["id"]) == ["gift_ms:c0:m1000", "gift_ms:c1:m1", "gift_ms:c1:m5"] and g.cycles_completed() == 1 and g.cycle_progress() == 5, "990 + 15 at 47 h: m1000 + c1 m1/m5 queued, 5 carried over")
	_ok(g.window_seconds_left() == WINDOW, "overflow cycle gets a fresh 48 h window")
	_now = T0 + 47 * H + WINDOW - 1
	_ok(g.cycle_progress() == 5, "old window's deadline does not expire the new cycle")
	var e = _svc()
	e.add_streak_sb("a", 1000)
	_ok(e.cycle_progress() == 0 and e.window_seconds_left() == 0, "exact 1000: progress 0, no window until the next progress")
	_complete("g04_rollover_new_window")

func _g05_migration() -> void:
	print("[g05 migration of a pre-window save + strict window fields]")
	var g = _svc()
	_now = T0 + 9 * H
	var old := {"cycle_progress": 120, "total_progress": 1120, "cycles_completed": 1,
		"gift_bar_queue": [{"id": "gift_ms:c1:m100", "cycle": 1, "milestone": 100, "claimed": false}], "applied": ["x"]}
	_ok(g.import_snapshot(old) and g.cycle_progress() == 120 and g.window_seconds_left() == WINDOW, "old save with progress 120 imports; its 48 h window starts at load")
	_ok(int(g.snapshot()["window_start"]) == _now and int(g.snapshot()["cycles_expired"]) == 0, "window_start = load time, no expired cycles")
	_now += WINDOW
	_ok(g.cycle_progress() == 0 and g.claimable().map(func(o): return o["id"]) == ["gift_ms:c1:m100", "gift_ms:c1:m1", "gift_ms:c1:m5", "gift_ms:c1:m10", "gift_ms:c1:m25"], "48 h after load it expires; queue kept")
	var z = _svc()
	_ok(z.import_snapshot({"cycle_progress": 0, "total_progress": 0, "cycles_completed": 0, "gift_bar_queue": [], "applied": []}) and z.window_seconds_left() == 0, "old save at 0: no window")
	var stale = _svc()
	_now = T0 + WINDOW + 1
	_ok(stale.import_snapshot({"cycle_progress": 40, "total_progress": 40, "cycles_completed": 0, "cycles_expired": 0, "expired_progress": 0,
		"window_start": T0, "gift_bar_queue": [], "applied": []}) and stale.cycle_progress() == 0 and int(stale.snapshot()["expired_progress"]) == 40,
		"a saved window that ran out while closed expires on load")
	var base := {"cycle_progress": 40, "total_progress": 340, "cycles_completed": 0, "cycles_expired": 2, "expired_progress": 300,
		"window_start": T0, "gift_bar_queue": [], "applied": []}
	var ok = _svc()
	_ok(ok.import_snapshot(base), "coherent windowed snapshot imports")
	var bad := {
		"window -1 with progress": {"window_start": -1},
		"window with progress 0": {"cycle_progress": 0, "total_progress": 300},
		"window -5": {"window_start": -5},
		"fractional window": {"window_start": 1.5},
		"expired mismatch": {"expired_progress": 299},
		"negative cycles_expired": {"cycles_expired": -1},
	}
	for k in bad:
		var s: Dictionary = base.duplicate(true)
		s.merge(bad[k], true)
		var t = _svc()
		t.add_streak_sb("keep", 3)
		var before: Dictionary = t.snapshot()
		_ok(not t.import_snapshot(s) and t.snapshot() == before, "%s rejected, state untouched" % k)
	_complete("g05_migration")

func _g06_clock_rollback() -> void:
	print("[g06 clock moved backwards never expires or extends the window]")
	var g = _svc()
	_now = T0 + 10 * H
	g.add_streak_sb("a", 30)
	_now = T0 - 24 * H
	_ok(g.cycle_progress() == 30 and g.window_seconds_left() == WINDOW, "clock back a day: progress kept, time left capped at 48 h")
	g.add_streak_sb("b", 2)
	_ok(int(g.snapshot()["window_start"]) == T0 + 10 * H, "progress during rollback does not re-anchor the window")
	_now = T0 + 10 * H + WINDOW
	_ok(g.cycle_progress() == 0, "clock restored: expires at the original 48 h deadline")
	_complete("g06_clock_rollback")

func _g07_home_countdown() -> void:
	print("[g07 Home countdown EN/TR; hidden at 0 progress]")
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	_now = T0
	var app = AppState.new(_uniq("g07"), Callable(self, "_clock"))
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	for _i in range(2):
		await process_frame
	home.refresh()
	var lbl: Label = home.get_region("GiftWindowLeft")
	_ok(lbl != null and not lbl.visible, "progress 0: countdown hidden")
	app.economy.gift.add_streak_sb("a", 7)
	var cases := [[H, "1d 23h", "1g 23sa"], [47 * H + 15 * 60, "45m", "45dk"], [48 * H - 30, "1m", "1dk"]]
	var bad: Array = []
	for c in cases:
		_now = T0 + int(c[0])
		for loc in ["en", "tr"]:
			UiText.locale = loc
			home.refresh()
			var want: String = c[1] if loc == "en" else c[2]
			if not lbl.visible or lbl.text != want:
				bad.append([c[0], loc, lbl.visible, lbl.text, want])
	UiText.locale = "en"
	_ok(bad.is_empty(), "47 h left 1d 23h / 1g 23sa; 45 min 45m / 45dk; 30 s 1m / 1dk %s" % str(bad))
	var meter = home.get_region("GiftMeterBar")
	var r_lbl: Rect2 = lbl.get_global_rect()
	_ok(not r_lbl.intersects(meter.caption.get_global_rect()) and not r_lbl.intersects(home.get_region("GiftEmblem").get_global_rect()) \
		and not r_lbl.intersects(home.get_region("GiftCrate").get_global_rect()), "countdown overlaps neither the bar numbers, the emblem nor the crate")
	_now = T0 + WINDOW
	home.refresh()
	_ok(not lbl.visible and meter.caption.text == "0/1", "after expiry: hidden, meter reads 0/1")
	sub.free()
	_complete("g07_home_countdown")

func _load(data: Dictionary, tag: String):
	var path := "user://sb_gift_48h_%s_%d.json" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	return EconomyConfig.new(path)

func _uniq(tag: String) -> String:
	var p := "user://sb_gift_48h_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("SB-GIFT-METER-48H evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
