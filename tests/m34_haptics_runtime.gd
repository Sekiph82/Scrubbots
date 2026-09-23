extends SceneTree
## M34-C001 V01 — haptics runtime evidence. Proves the M34 presentation-only
## haptics infrastructure without a real device:
##   - toggle default = enabled, OFF suppresses all requests and never calls the
##     platform sink;
##   - cleaning burst above throttle window is deterministically suppressed;
##   - platform call count grows only for played requests, never for suppressed;
##   - completion latch: WON once per attempt, LOST/ERROR play nothing, Retry
##     re-arms; a repeated WON does not vibrate again;
##   - HapticsSettingsService round-trip through isolated user:// path;
##   - snapshot / import_snapshot preserve the enabled bit and fall back safely
##     on malformed dictionaries.
##
## Run: godot --headless --path . -s res://tests/m34_haptics_runtime.gd
## Exits 0 on success, 1 on any failure.

const HapticsController = preload("res://scripts/haptics/haptics_controller.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")

var _fail := 0
var _sink_calls := []
var _sink: Callable

func _initialize() -> void:
	_sink = Callable(self, "_on_platform_call")
	_toggle_and_burst()
	_completion_latch()
	_settings_service()
	_snapshot_roundtrip()
	_done()

func _on_platform_call(duration_ms: int, category: int) -> void:
	_sink_calls.append({"ms": duration_ms, "cat": category})

func _reset_sink() -> void:
	_sink_calls.clear()

func _toggle_and_burst() -> void:
	print("[toggle+burst]")
	_reset_sink()
	var hc = HapticsController.new()
	hc.set_platform_sink(_sink)
	get_root().add_child(hc)
	_ok(hc.is_enabled(), "default enabled=true")
	# OFF suppresses everything and never calls the platform sink.
	hc.set_enabled(false)
	for _i in range(20):
		hc.request_cleaning()
	hc.request_completion()
	_ok(_sink_calls.is_empty(), "OFF: no platform calls")
	var cd: Dictionary = hc.get_diagnostics(HapticsController.Category.CLEANING)
	var wd: Dictionary = hc.get_diagnostics(HapticsController.Category.COMPLETION)
	_ok(cd["requests"] == 20 and cd["played"] == 0 and cd["suppressed"] == 20, "OFF: cleaning all suppressed")
	_ok(wd["requests"] == 1 and wd["played"] == 0 and wd["suppressed"] == 1, "OFF: completion suppressed")
	# ON: burst limited by throttle window.
	hc.set_enabled(true)
	_reset_sink()
	for _i in range(20):
		hc.request_cleaning()
	cd = hc.get_diagnostics(HapticsController.Category.CLEANING)
	_ok(cd["requests"] == 40, "burst counted 20 more requests")
	_ok(cd["played"] >= 1, "at least one cleaning played")
	_ok(cd["played"] <= 2, "burst throttled to <=2 played within the same tick window")
	_ok(_sink_calls.size() == cd["played"] - 0, "platform calls == played (this burst)")
	# All platform calls must be cleaning cat.
	var all_cleaning := true
	for c in _sink_calls:
		if c["cat"] != HapticsController.Category.CLEANING:
			all_cleaning = false
	_ok(all_cleaning, "burst platform calls are cleaning category")
	hc.free()

func _completion_latch() -> void:
	print("[completion latch]")
	_reset_sink()
	var hc = HapticsController.new()
	hc.set_platform_sink(_sink)
	get_root().add_child(hc)
	# LOST/ERROR play nothing.
	hc._on_terminal_reached(&"LOST", {})
	hc._on_terminal_reached(&"ERROR", {})
	_ok(hc.get_diagnostics(HapticsController.Category.COMPLETION)["played"] == 0, "LOST/ERROR: no completion buzz")
	# WON plays exactly once per attempt.
	hc._on_terminal_reached(HapticsController.WON, {})
	_ok(hc.completion_played_this_attempt(), "WON latches attempt")
	hc._on_terminal_reached(HapticsController.WON, {})
	_ok(hc.get_diagnostics(HapticsController.Category.COMPLETION)["played"] == 1, "repeated WON does not duplicate")
	# Retry re-arms.
	hc.reset_for_new_attempt()
	_ok(not hc.completion_played_this_attempt(), "Retry re-arms latch")
	hc._on_terminal_reached(HapticsController.WON, {})
	_ok(hc.get_diagnostics(HapticsController.Category.COMPLETION)["played"] == 2, "fresh WON plays again")
	# Platform received exactly 2 completion vibrations with the completion duration.
	var completion_calls := 0
	var total_ms := 0
	for c in _sink_calls:
		if c["cat"] == HapticsController.Category.COMPLETION:
			completion_calls += 1
			total_ms += int(c["ms"])
	_ok(completion_calls == 2, "platform saw exactly 2 completion vibrations")
	_ok(total_ms == HapticsController.COMPLETION_MS * 2, "completion durations summed correctly")
	hc.free()

func _settings_service() -> void:
	print("[settings service]")
	var path := "user://m34_test_haptics_%d.cfg" % Time.get_ticks_usec()
	_remove_user_file(path)
	var svc = HapticsSettingsService.new(path)
	_ok(svc.is_enabled(), "default enabled=true")
	svc.set_enabled(false)
	_ok(svc.save(), "save() writes the isolated test config")
	var svc2 = HapticsSettingsService.new(path)
	_ok(svc2.load(), "load() reads existing config")
	_ok(not svc2.is_enabled(), "persisted enabled=false round-trips")
	# Missing file -> defaults, never blocks.
	var missing := "user://m34_test_missing_%d.cfg" % Time.get_ticks_usec()
	_remove_user_file(missing)
	var svc3 = HapticsSettingsService.new(missing)
	_ok(not svc3.load(), "missing file: load returns false")
	_ok(svc3.is_enabled(), "missing file: safe default enabled=true")
	_remove_user_file(path)
	_remove_user_file(missing)

func _snapshot_roundtrip() -> void:
	print("[snapshot roundtrip]")
	var svc = HapticsSettingsService.new("user://m34_snapshot_%d.cfg" % Time.get_ticks_usec())
	svc.set_enabled(false)
	var snap: Dictionary = svc.snapshot()
	_ok(snap.get("enabled") == false, "snapshot exposes enabled bit")
	var svc2 = HapticsSettingsService.new("user://m34_snapshot2_%d.cfg" % Time.get_ticks_usec())
	svc2.import_snapshot(snap)
	_ok(not svc2.is_enabled(), "import_snapshot restores enabled bit")
	svc2.import_snapshot({"enabled": "garbage"})
	_ok(svc2.is_enabled(), "malformed snapshot falls back to safe default")
	svc2.import_snapshot({})
	_ok(svc2.is_enabled(), "empty snapshot falls back to safe default")

# ------------------------------------------------------------- utilities ----

func _remove_user_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M34 haptics runtime evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
