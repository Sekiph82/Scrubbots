extends SceneTree
## M43 master — Lane C005R Gift Meter micro-progress (SB-M43-R05-001 / R05-002).
## Real AppState / GiftMeterService, real Home scene, real Results row builder, real Gift Bar
## popup. Expected/completed case ledger.
##
## Run: godot --headless --path . -s res://tests/m43_master_c005r_gift_micro_progress.gd

const AppState = preload("res://scripts/app/app_state.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const GiftProgressModel = preload("res://scripts/economy/gift_progress_model.gd")
const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")

var EXPECTED_CASES := [
	"g01_model_segments", "g02_ticks_mint_nothing", "g03_home_overlay_no_layout_change", "g04_pulse_once_reduced_static",
	"g05_no_authority_static", "g06_results_row_model", "g07_one_model_three_surfaces", "g08_crossing_keeps_bundle",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_g01_model_segments()
	_g02_ticks_mint_nothing()
	await _g03_home_overlay()
	await _g04_pulse()
	_g05_no_authority_static()
	_g06_results_row_model()
	await _g07_one_model()
	_g08_crossing_keeps_bundle()
	_cleanup()
	_done()

func _g01_model_segments() -> void:
	print("[g01 normalized segments between canonical milestones]")
	var cases := [[0, 0, 10, 0], [9, 0, 10, 9], [10, 10, 50, 0], [61, 50, 250, 0], [70, 50, 250, 1], [300, 250, 500, 2],
		[999, 500, 1000, 9], [500, 500, 1000, 0]]
	var bad: Array = []
	for c in cases:
		var m := GiftProgressModel.build(c[0])
		if [m["prev"], m["next"], m["ticks_reached"]] != [c[1], c[2], c[3]] or m["ticks"] != 10:
			bad.append([c, [m["prev"], m["next"], m["ticks_reached"]]])
	_ok(bad.is_empty(), "prev / next / ticks_reached for 8 progress values %s" % str(bad))
	_ok(GiftMeterService.MILESTONES == [10, 50, 250, 500, 1000] and GiftProgressModel.build(61)["cycle_max"] == 1000, "canonical milestones / cycle max unchanged")
	_complete("g01_model_segments")

func _g02_ticks_mint_nothing() -> void:
	print("[g02 micro-ticks mint nothing: only milestones queue rewards]")
	var app = AppState.new(_uniq("g02"))
	var wallet0: Dictionary = app.economy.wallet.snapshot()
	var applied0: Array = app.economy.reward.snapshot()["applied"]
	var tick_changes := 0
	var last := -1
	for i in range(999):
		app.economy.gift.add_streak_sb("g02_%d" % i, 1)
		var m := GiftProgressModel.from_service(app.economy.gift)
		if m["ticks_reached"] != last:
			tick_changes += 1
			last = m["ticks_reached"]
	_ok(tick_changes > 30 and app.economy.gift.gift_bar_queue().size() == 4, "%d micro-tick changes over 0..999 but only 4 milestone occurrences queued (10/50/250/500)" % tick_changes)
	_ok(app.economy.wallet.snapshot() == wallet0 and app.economy.reward.snapshot()["applied"] == applied0, "no wallet change, no reward transaction from progress or ticks")
	_complete("g02_ticks_mint_nothing")

func _g03_home_overlay() -> void:
	print("[g03 Home: ticks inside the SAME bar; caption / value / geometry unchanged]")
	var r := await _home("g03", 61)
	var home = r[1]
	var meter = home.get_region("GiftMeterBar")
	var ov = home.get_region("GiftTickOverlay")
	var m: Dictionary = ov.get_model()
	_ok(meter.caption.text == "61/1,000" and is_equal_approx(meter.bar.value, 61.0), "owner-locked ratio caption + full-cycle value unchanged")
	_ok(ov.get_parent() == meter.bar and ov.get_global_rect().is_equal_approx(meter.bar.get_global_rect()), "overlay is a full-rect child of the existing bar (no new geometry)")
	var w: float = ov.size.x
	var ticks: Array = ov.tick_positions()
	_ok(m["prev"] == 50 and m["next"] == 250 and ticks.size() == 9 and ticks[0] > w * 0.05 and ticks[8] < w * 0.25, "nine micro-ticks split the 50 -> 250 gap")
	r[0].free()
	_complete("g03_home_overlay_no_layout_change")

func _g04_pulse() -> void:
	print("[g04 newly reached tick pulses once (FULL); Reduced static; plain refresh never pulses]")
	var r := await _home("g04", 61)
	var app = r[2]
	var home = r[1]
	var ov = home.get_region("GiftTickOverlay")
	home.refresh()
	_ok(not ov.is_pulsing(), "refresh with unchanged state: no pulse")
	app.economy.gift.add_streak_sb("g04_a", 20)
	home.refresh()
	_ok(ov.is_pulsing() and ov.get_model()["ticks_reached"] == 1, "61 -> 81 reached a new tick: one pulse")
	r[0].free()
	var r2 := await _home("g04r", 61, true)
	r2[2].economy.gift.add_streak_sb("g04_b", 20)
	r2[1].refresh()
	_ok(not r2[1].get_region("GiftTickOverlay").is_pulsing() and r2[1].get_region("GiftTickOverlay").get_model()["ticks_reached"] == 1, "Reduced Effects: same tick state, no pulse")
	r2[0].free()
	_complete("g04_pulse_once_reduced_static")

func _g05_no_authority_static() -> void:
	print("[g05 model / overlay carry no authority]")
	var hits: Array = []
	for path in ["res://scripts/economy/gift_progress_model.gd", "res://scripts/ui/components/gift_tick_overlay.gd"]:
		var src := _code_only(FileAccess.get_file_as_string(path))
		for w in ["add_streak_sb(", ".claim(", "grant(", "credit(", "debit(", "request_save("]:
			if src.contains(w):
				hits.append("%s:%s" % [path.get_file(), w])
	_ok(hits.is_empty(), "no progress / claim / grant / save calls %s" % str(hits))
	_complete("g05_no_authority_static")

# ------------------------------------------------------------------- R05-002 ----

func _g06_results_row_model() -> void:
	print("[g06 Results gift row = shared model of the committed receipt value]")
	var rows: Array = ResultsScreen.reward_rows({"reveal_queue": [{"kind": "gift_meter", "from": 41, "to": 61, "cycle_max": 1000, "milestones": [50]}], "follow_ups": []})
	_ok(rows.size() == 1 and rows[0]["text"] == "Gift Meter 61/1,000 · next gift at 250", "row text %s" % str(rows))
	_complete("g06_results_row_model")

func _g07_one_model() -> void:
	print("[g07 Home overlay, Gift Bar and Results read one normalized model]")
	var r := await _home("g07", 330)
	var home = r[1]
	var app = r[2]
	var svc := GiftProgressModel.from_service(app.economy.gift)
	var popup = home.open_popup("gift_bar")
	await process_frame
	var res_text: String = ResultsScreen.reward_rows({"reveal_queue": [{"kind": "gift_meter", "to": app.economy.gift.cycle_progress(), "cycle_max": 1000}], "follow_ups": []})[0]["text"]
	_ok(home.get_region("GiftTickOverlay").get_model() == svc, "Home overlay model == model from the service")
	_ok(popup.get_note().contains("Gift Meter 330/1,000 · next gift at 500") and res_text == "Gift Meter 330/1,000 · next gift at 500", "Gift Bar note and Results row state the same model values")
	r[0].free()
	_complete("g07_one_model_three_surfaces")

func _g08_crossing_keeps_bundle() -> void:
	print("[g08 milestone crossing keeps the authoritative queued bundle]")
	var app = AppState.new(_uniq("g08"))
	app.economy.gift.add_streak_sb("g08_a", 240)
	var q0: int = app.economy.gift.gift_bar_queue().size()
	var newly: Array = app.economy.gift.add_streak_sb("g08_b", 15)
	var m := GiftProgressModel.from_service(app.economy.gift)
	_ok(newly.size() == 1 and int(newly[0]["milestone"]) == 250 and app.economy.gift.gift_bar_queue().size() == q0 + 1, "crossing 250 queued exactly one occurrence")
	_ok(str(app.economy.config.gift_meter_milestone(250)) == str({"bot_parts": 2.0, "scrub_bucks": 100.0, "standard_card_packs": 1.0}) and m["prev"] == 250 and m["next"] == 500 and m["ticks_reached"] == 0, "bundle = config 250; model starts the next segment")
	_complete("g08_crossing_keeps_bundle")

# ------------------------------------------------------------------ helpers ----

## [SubViewport, Home, AppState] with the Gift Meter fed to `gift` through the real service.
func _home(tag: String, gift: int, reduced := false) -> Array:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var app = AppState.new(_uniq(tag))
	if gift > 0:
		app.economy.gift.add_streak_sb(tag + "_seed", gift)
	if reduced:
		app.set_reduced_effects(true)
	var home = HomeScreenScene.instantiate()
	sub.add_child(home)
	home.bind(app)
	for _i in range(3):
		await process_frame
	home.refresh()
	await process_frame
	return [sub, home, app]

func _code_only(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var i := line.find("#")
		out.append(line if i == -1 else line.substr(0, i))
	return "\n".join(out)

func _uniq(tag: String) -> String:
	var p := "user://m43master_c005r_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M43 master C005R gift micro-progress evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
