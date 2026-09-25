extends SceneTree
## M41-C001 V01 — early audio/haptics Settings slice evidence
## (SB-M41-001 Master, -002 Music, -003 SFX, -004 Haptics, -006 Persistence,
##  -007 Settings UI, -008 Relaunch). SB-M41-005 Reduced Effects is out of scope.
##
## Every case uses the ONE canonical post-M40 AppState/SaveService graph on an isolated
## user:// save path (never the real player save) and asserts:
##   - live apply on the actual AudioServer buses / live HapticsController;
##   - exact persistence + relaunch (fresh AppState and the real main.tscn root);
##   - Music 0 -> only Music; SFX 0 -> only SFX; Master 0 -> Master (all audio);
##   - Haptics OFF suppresses vibration only; gameplay truth identical;
##   - malformed persisted toggles fail closed; pre-M41 saves default ON;
##   - the Settings UI drives only canonical AppState actions, is mobile-readable (touch
##     >= 88, text >= 30) and fits phone widths; no legacy side-file authority is written;
##   - blocked (future-schema) app: Settings read-only, nothing written.
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m41_settings.gd

const AppState = preload("res://scripts/app/app_state.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const SettingsPanelScene = preload("res://scenes/ui/settings_panel.tscn")
const SettingsPanel = preload("res://scripts/ui/settings_panel.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const HapticsController = preload("res://scripts/haptics/haptics_controller.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const LEGACY_AUDIO := "user://audio_settings.cfg"
const LEGACY_HAPTICS := "user://haptics_settings.cfg"
const MAX_TICKS := 80000

const EXPECTED_CASES := [
	"service_toggle_semantics", "live_apply_actions", "bus_isolation_via_appstate", "exact_relaunch",
	"deferred_slider_persistence", "toggle_schema_validation", "settings_ui_controls",
	"settings_ui_layout", "main_root_settings", "blocked_app_readonly",
	"haptics_live_no_gameplay_mutation", "real_host_bus_routing", "no_legacy_side_files",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _legacy_before: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_legacy_before = {LEGACY_AUDIO: _stamp(LEGACY_AUDIO), LEGACY_HAPTICS: _stamp(LEGACY_HAPTICS)}
	_service_toggle_semantics()
	_live_apply_actions()
	_bus_isolation_via_appstate()
	_exact_relaunch()
	_deferred_slider_persistence()
	_toggle_schema_validation()
	await _settings_ui_controls()
	await _settings_ui_layout()
	await _main_root_settings()
	await _blocked_app_readonly()
	await _haptics_live_no_gameplay_mutation()
	await _real_host_bus_routing()
	_no_legacy_side_files()
	_neutral()
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")

## Toggle semantics on the canonical service: OFF mutes and keeps the slider value; ON
## restores the exact level; changing the level while OFF stays muted; Master toggle mutes
## Master; the snapshot carries all six values.
func _service_toggle_semantics() -> void:
	print("[service toggle semantics]")
	var svc = AudioSettingsService.new("user://m41_unused.cfg")
	var m := AudioServer.get_bus_index("Master")
	var mu := AudioServer.get_bus_index("Music")
	var sfx := AudioServer.get_bus_index("SFX")
	svc.set_sfx_volume(0.6)
	svc.set_sfx_enabled(false)
	_ok(AudioServer.is_bus_mute(sfx) and is_equal_approx(svc.get_sfx_volume(), 0.6), "SFX OFF mutes and keeps the slider value")
	svc.set_sfx_enabled(true)
	_ok(not AudioServer.is_bus_mute(sfx) and is_equal_approx(AudioServer.get_bus_volume_db(sfx), linear_to_db(0.6)), "SFX ON restores the exact kept level")
	svc.set_sfx_enabled(false)
	svc.set_sfx_volume(0.9)
	_ok(AudioServer.is_bus_mute(sfx), "changing the level while OFF keeps the bus muted")
	svc.set_music_enabled(false)
	_ok(AudioServer.is_bus_mute(mu) and not AudioServer.is_bus_mute(m), "Music OFF mutes only Music")
	svc.set_master_enabled(false)
	_ok(AudioServer.is_bus_mute(m), "Master OFF mutes Master")
	var snap: Dictionary = svc.snapshot()
	_ok(snap.keys().size() == 6 and snap["sfx_on"] == false and snap["music_on"] == false and snap["master_on"] == false and is_equal_approx(snap["sfx"], 0.9), "snapshot carries 3 volumes + 3 toggles")
	_neutral()
	_complete("service_toggle_semantics")

func _live_apply_actions() -> void:
	print("[live apply actions]")
	var app = AppState.new(_uniq("live"))
	var mu := AudioServer.get_bus_index("Music")
	var r: Dictionary = app.set_audio_volume("music", 0.3)
	_ok(r.get("ok", false), "set_audio_volume(music) ok + saved")
	_ok(is_equal_approx(app.audio.get_music_volume(), 0.3) and is_equal_approx(AudioServer.get_bus_volume_db(mu), linear_to_db(0.3)), "Music applies live to the bus")
	r = app.set_audio_enabled("music", false)
	_ok(r.get("ok", false) and AudioServer.is_bus_mute(mu) and is_equal_approx(app.audio.get_music_volume(), 0.3), "Music toggle OFF mutes live, keeps value")
	app.set_audio_enabled("music", true)
	_ok(not AudioServer.is_bus_mute(mu), "Music toggle ON unmutes live")
	var before: Dictionary = app.audio.snapshot()
	r = app.set_audio_volume("voice", 0.1)
	_ok(not r.get("ok", true) and r.get("reason") == "unknown_bus" and app.audio.snapshot() == before, "unknown bus rejected, nothing mutated")
	r = app.set_audio_enabled("bogus", false)
	_ok(not r.get("ok", true) and app.audio.snapshot() == before, "unknown toggle bus rejected")
	r = app.set_haptics_enabled(false)
	_ok(r.get("ok", false) and not app.haptics.is_enabled(), "haptics OFF action applies")
	_complete("live_apply_actions")

func _bus_isolation_via_appstate() -> void:
	print("[bus isolation via AppState]")
	var app = AppState.new(_uniq("iso"))
	var m := AudioServer.get_bus_index("Master")
	var mu := AudioServer.get_bus_index("Music")
	var s := AudioServer.get_bus_index("SFX")
	app.set_audio_volume("music", 0.0)
	_ok(AudioServer.is_bus_mute(mu) and not AudioServer.is_bus_mute(s) and not AudioServer.is_bus_mute(m), "Music 0 affects music only")
	app.set_audio_volume("music", 1.0)
	app.set_audio_volume("sfx", 0.0)
	_ok(AudioServer.is_bus_mute(s) and not AudioServer.is_bus_mute(mu) and not AudioServer.is_bus_mute(m), "SFX 0 affects gameplay SFX only (music unaffected)")
	app.set_audio_volume("sfx", 1.0)
	app.set_audio_volume("master", 0.0)
	_ok(AudioServer.is_bus_mute(m) and String(AudioServer.get_bus_send(mu)) == "Master" and String(AudioServer.get_bus_send(s)) == "Master", "Master 0 mutes Master, which carries Music and SFX (all audio)")
	app.set_audio_volume("master", 1.0)
	_complete("bus_isolation_via_appstate")

func _exact_relaunch() -> void:
	print("[exact relaunch]")
	var path := _uniq("relaunch")
	var app = AppState.new(path)
	app.set_audio_volume("master", 0.35)
	app.set_audio_volume("music", 0.2)
	app.set_audio_volume("sfx", 0.85)
	app.set_audio_enabled("master", true)
	app.set_audio_enabled("music", false)
	app.set_audio_enabled("sfx", true)
	app.set_haptics_enabled(false)
	var want: Dictionary = app.audio.snapshot()
	_neutral()   # prove the relaunch re-applies buses itself
	var app2 = AppState.new(path)
	_ok(app2.load_result.get("source") == "primary", "relaunch loads the canonical primary save")
	var got: Dictionary = app2.audio.snapshot()
	_ok(got == want, "relaunch restores exact audio values+toggles %s" % str(got))
	_ok(not app2.haptics.is_enabled(), "relaunch restores Haptics OFF")
	_ok(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "relaunch re-applies Music OFF to the bus")
	_ok(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")), linear_to_db(0.35)), "relaunch re-applies Master level to the bus")
	# Second relaunch after flipping back: exact again (no stale state).
	app2.set_audio_enabled("music", true)
	app2.set_haptics_enabled(true)
	var app3 = AppState.new(path)
	_ok(app3.audio.is_music_enabled() and app3.haptics.is_enabled() and is_equal_approx(app3.audio.get_music_volume(), 0.2), "second relaunch restores the re-enabled values exactly")
	_complete("exact_relaunch")

func _deferred_slider_persistence() -> void:
	print("[deferred slider persistence]")
	var path := _uniq("deferred")
	var app = AppState.new(path)
	app.set_audio_volume("sfx", 0.5)
	var r: Dictionary = app.set_audio_volume("sfx", 0.25, false)
	_ok(r.get("pending", false) and app.is_dirty(), "drag-time change applies live and marks dirty")
	_ok(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")), linear_to_db(0.25)), "drag-time value is live on the bus")
	_ok(is_equal_approx(AppState.new(path).audio.get_sfx_volume(), 0.5), "not yet on disk before flush")
	_ok(app.flush_if_dirty().get("ok", false) and not app.is_dirty(), "flush_if_dirty saves")
	_ok(is_equal_approx(AppState.new(path).audio.get_sfx_volume(), 0.25), "relaunch after flush has the dragged value")
	_ok(app.flush_if_dirty().get("skipped", false), "flush_if_dirty with nothing pending skips the write")
	_complete("deferred_slider_persistence")

func _toggle_schema_validation() -> void:
	print("[toggle schema validation]")
	var app = AppState.new(_uniq("schema"))
	var svc = app.save
	var base := {"schema": "scrubbots.save", "version": 1,
		"settings": {"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0}, "haptics": {"enabled": true}},
		"progression": app.progression.snapshot(), "economy": app.economy.snapshot()}
	_ok(svc.validate_candidate(base.duplicate(true)).get("ok", false), "pre-M41 save without toggles is valid (defaults ON)")
	var rejected := 0
	var tried := 0
	for k in ["master_on", "music_on", "sfx_on"]:
		for bad in [1, 0, "true", 1.0, null, [], {}]:
			var c: Dictionary = base.duplicate(true)
			c["settings"]["audio"][k] = bad
			tried += 1
			var v: Dictionary = svc.validate_candidate(c)
			if not v.get("ok", false) and v.get("reason") == "audio_%s_type" % k:
				rejected += 1
	_ok(tried == 21 and rejected == tried, "every non-bool toggle value fails the whole candidate (%d/%d)" % [rejected, tried])
	for k in ["master_on", "music_on", "sfx_on"]:
		var good: Dictionary = base.duplicate(true)
		good["settings"]["audio"][k] = false
		_ok(svc.validate_candidate(good).get("ok", false), "%s=false (exact bool) is valid" % k)
	# Load path: a corrupt-toggle primary is rejected; defaults (not a normalized value) used.
	var path := _uniq("badtoggle")
	var c2: Dictionary = base.duplicate(true)
	c2["settings"]["audio"]["music_on"] = "no"
	c2["settings"]["audio"]["music"] = 0.4
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(c2))
	f.close()
	var app2 = AppState.new(path)
	_ok(app2.load_result.get("source") == "defaults" and app2.audio.is_music_enabled() and is_equal_approx(app2.audio.get_music_volume(), 1.0), "corrupt toggle save rejected wholesale (no partial apply)")
	# Pre-M41 save on disk loads with toggles ON.
	var path2 := _uniq("prem41")
	var c3: Dictionary = base.duplicate(true)
	c3["settings"]["audio"]["music"] = 0.6
	f = FileAccess.open(path2, FileAccess.WRITE)
	f.store_string(JSON.stringify(c3))
	f.close()
	var app3 = AppState.new(path2)
	_ok(app3.load_result.get("source") == "primary" and app3.audio.is_master_enabled() and app3.audio.is_music_enabled() and app3.audio.is_sfx_enabled() and is_equal_approx(app3.audio.get_music_volume(), 0.6), "pre-M41 primary loads with toggles ON and its volumes")
	_complete("toggle_schema_validation")

func _settings_ui_controls() -> void:
	print("[settings UI controls]")
	var path := _uniq("ui")
	var app = AppState.new(path)
	app.set_audio_volume("music", 0.4)
	app.set_audio_enabled("sfx", false)
	var sub := _sub(Vector2i(1080, 2160))
	var panel = SettingsPanelScene.instantiate()
	sub.add_child(panel)
	panel.bind(app)
	await process_frame
	await process_frame
	_ok(panel.get_slider("music").value == 0.4 and panel.get_value_label("music").text == "40%", "UI shows current Music value (40%)")
	_ok(not panel.get_toggle("sfx").button_pressed and panel.get_value_label("sfx").text == "OFF" and not panel.get_slider("sfx").editable, "UI shows SFX OFF")
	_ok(panel.get_toggle("master").button_pressed and panel.get_haptics_toggle().button_pressed, "UI shows Master ON / Vibration ON")
	# Toggle through the real control signal.
	panel.get_toggle("sfx").button_pressed = true
	_ok(app.audio.is_sfx_enabled() and not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "SFX toggle ON applies live")
	_ok(AppState.new(path).audio.is_sfx_enabled(), "SFX toggle persisted immediately")
	# Slider: live on value change, persisted on drag end.
	panel.get_slider("master").value = 0.6
	_ok(is_equal_approx(app.audio.get_master_volume(), 0.6) and is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")), linear_to_db(0.6)), "Master slider applies live")
	_ok(panel.get_value_label("master").text == "60%", "value label updates live")
	_ok(is_equal_approx(AppState.new(path).audio.get_master_volume(), 1.0), "mid-drag value not yet written")
	panel.get_slider("master").drag_ended.emit(true)
	_ok(is_equal_approx(AppState.new(path).audio.get_master_volume(), 0.6), "drag end persists the Master value")
	panel.get_slider("music").value = 0.15
	panel.close_panel()
	_ok(not panel.visible and is_equal_approx(AppState.new(path).audio.get_music_volume(), 0.15), "Close persists a pending slider value")
	panel.get_haptics_toggle().button_pressed = false
	_ok(not app.haptics.is_enabled() and not AppState.new(path).haptics.is_enabled(), "Vibration toggle applies + persists")
	panel.get_toggle("music").button_pressed = false
	_ok(not panel.get_slider("music").editable and panel.get_value_label("music").text == "OFF", "OFF disables the slider and shows OFF")
	# Panel holds no settings authority: external canonical change is reflected on open.
	app.set_audio_volume("sfx", 0.05)
	panel.open_panel()
	_ok(is_equal_approx(panel.get_slider("sfx").value, 0.05), "open_panel re-syncs from canonical AppState")
	var reduced := false
	for n in panel.find_children("*", "", true, false):
		if (n is Button or n is Label) and String(n.get("text")).to_lower().find("reduced") != -1:
			reduced = true
	_ok(not reduced, "no Reduced Effects UI node exists (SB-M41-005 untouched)")
	sub.free()
	_complete("settings_ui_controls")

func _settings_ui_layout() -> void:
	print("[settings UI layout]")
	var app = AppState.new(_uniq("layout"))
	for size in [Vector2i(1080, 2160), Vector2i(1080, 1920), Vector2i(1080, 2400), Vector2i(1440, 1920)]:
		var sub := _sub(size)
		var panel = SettingsPanelScene.instantiate()
		sub.add_child(panel)
		panel.bind(app)
		await process_frame
		await process_frame
		var box: Control = panel.find_child("Panel", true, false)
		var r := box.get_global_rect()
		var inside: bool = r.position.x >= 16.0 - 0.5 and r.position.y >= 0.0 and r.end.x <= size.x - 16.0 + 0.5 and r.end.y <= size.y
		_ok(inside, "%s: panel %s inside viewport with 16px gutter" % [str(size), str(r)])
		var touch_ok := true
		var font_ok := true
		for n in panel.find_children("*", "", true, false):
			if n is BaseButton or n is HSlider:
				if (n as Control).size.y < SettingsPanel.TOUCH_MIN - 0.5:
					touch_ok = false
			if n is Label or n is Button:
				if (n as Control).get_theme_font_size("font_size") < 30:
					font_ok = false
		_ok(touch_ok, "%s: every toggle/slider/button >= 88 px tall" % str(size))
		_ok(font_ok, "%s: every label/button font >= 30" % str(size))
		sub.free()
	_complete("settings_ui_layout")

func _main_root_settings() -> void:
	print("[main root settings]")
	var path := _uniq("main")
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	var btn = root.find_child("SettingsButton", true, false)
	var panel = root.get_settings_panel()
	_ok(btn is Button and (btn as Control).custom_minimum_size.y >= 88, "real main.tscn root has a SETTINGS button")
	_ok(panel != null and not panel.visible, "Settings panel exists hidden")
	(btn as Button).pressed.emit()
	_ok(panel.visible, "SETTINGS opens the panel")
	panel.get_toggle("music").button_pressed = false
	_ok(not root.get_app_state().audio.is_music_enabled(), "panel is bound to the main root's canonical AppState")
	panel.get_slider("sfx").value = 0.45
	root.flush_lifecycle("focus_out")
	root.free()
	MainScript.boot_save_path_override = path
	var root2 = MainScene.instantiate()
	get_root().add_child(root2)
	await process_frame
	var a2 = root2.get_app_state()
	_ok(not a2.audio.is_music_enabled() and is_equal_approx(a2.audio.get_sfx_volume(), 0.45), "real app relaunch restores Settings exactly (incl. lifecycle-flushed slider)")
	_ok(root2.get_settings_panel().get_value_label("sfx").text == "45%", "relaunched UI shows restored value")
	root2.free()
	MainScript.boot_save_path_override = ""
	_complete("main_root_settings")

func _blocked_app_readonly() -> void:
	print("[blocked app read-only]")
	var path := _uniq("blocked")
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema": "scrubbots.save", "version": 999, "future": true}))
	f.close()
	var before := FileAccess.get_file_as_string(path)
	var app = AppState.new(path)
	_ok(app.is_blocked, "future schema blocks the app")
	_ok(not app.set_audio_volume("music", 0.1).get("ok", true) and not app.set_audio_enabled("sfx", false).get("ok", true), "audio actions refused while blocked")
	var sub := _sub(Vector2i(1080, 2160))
	var panel = SettingsPanelScene.instantiate()
	sub.add_child(panel)
	panel.bind(app)
	await process_frame
	_ok(panel.get_toggle("music").disabled and not panel.get_slider("music").editable and panel.get_haptics_toggle().disabled, "Settings controls read-only while blocked")
	panel.close_panel()
	_ok(FileAccess.get_file_as_string(path) == before, "future-schema save untouched")
	sub.free()
	_complete("blocked_app_readonly")

func _haptics_live_no_gameplay_mutation() -> void:
	print("[haptics live, no gameplay mutation]")
	var results := []
	for haptics_on in [true, false]:
		var app = AppState.new(_uniq("hap"))
		var h = await _make_host(app)
		if h == null:
			return
		var hc = h.get_haptics_controller()
		var calls := [0]
		hc.set_platform_sink(func(_ms, _cat): calls[0] += 1)
		# Live toggle AFTER build through the canonical action (no rebuild).
		app.set_haptics_enabled(haptics_on)
		_ok(hc.is_enabled() == haptics_on, "haptics %s: live controller follows the setting without rebuild" % haptics_on)
		var initial: int = h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)
		_drain(h)
		results.append({"won": h.get_completion().is_won(), "cleared": h.get_clearing_loop().get_cleared_count(), "initial": initial, "calls": calls[0]})
		if not haptics_on:
			app.set_haptics_enabled(true)
			_ok(hc.is_enabled(), "haptics ON again applies live")
		_free_host(h)
	_ok(results.size() == 2, "both runs completed")
	if results.size() == 2:
		_ok(results[0]["calls"] > 0, "Haptics ON vibrates (%d platform calls)" % results[0]["calls"])
		_ok(results[1]["calls"] == 0, "Haptics OFF suppresses every vibration")
		_ok(results[0]["won"] and results[1]["won"] and results[0]["cleared"] == results[1]["cleared"] and results[1]["cleared"] == results[1]["initial"], "gameplay identical (WON, %d clears) with Haptics ON and OFF" % results[1]["cleared"])
	# Malformed settings answer fails closed to no vibration.
	var hc2 = HapticsController.new()
	hc2.bind_settings(_BadSettings.new())
	_ok(not hc2.is_enabled(), "malformed settings answer -> no vibration")
	hc2.free()
	_complete("haptics_live_no_gameplay_mutation")

class _BadSettings:
	extends RefCounted
	func is_enabled():
		return "yes"

func _real_host_bus_routing() -> void:
	print("[real host bus routing]")
	var app = AppState.new(_uniq("route"))
	var h = await _make_host(app)
	if h == null:
		return
	_ok(h.get_audio_settings() == app.audio, "host consumes the canonical AppState audio service (no second authority)")
	var sfx_ok := true
	for c in h.get_audio_controller().get_children():
		if c is AudioStreamPlayer and c.bus != "SFX":
			sfx_ok = false
	_ok(sfx_ok, "all gameplay SFX players are on the SFX bus")
	_ok(h.get_music_controller().get_player().bus == "Music", "music player is on the Music bus")
	app.set_audio_volume("music", 0.0)
	_ok(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "live Settings Music 0 during gameplay mutes only the music bus")
	app.set_audio_volume("music", 1.0)
	# M33 V03: the approved gameplay music is actually playing; settings never restart it.
	var mc = h.get_music_controller()
	var mu := AudioServer.get_bus_index("Music")
	_ok(mc.has_track() and mc.is_playing() and mc.get_start_count() == 1, "approved gameplay music playing on entry")
	app.set_audio_volume("sfx", 0.0)
	app.set_audio_enabled("sfx", false)
	_ok(not AudioServer.is_bus_mute(mu) and mc.is_playing(), "SFX 0 / OFF does not mute the music")
	app.set_audio_volume("sfx", 1.0)
	app.set_audio_enabled("sfx", true)
	app.set_audio_enabled("music", false)
	_ok(AudioServer.is_bus_mute(mu) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "Music OFF mutes gameplay music only")
	app.set_audio_enabled("music", true)
	app.set_audio_volume("master", 0.0)
	_ok(AudioServer.is_bus_mute(AudioServer.get_bus_index("Master")) and AudioServer.get_bus_send(mu) == &"Master", "Master 0 mutes all audio incl. music")
	app.set_audio_volume("master", 1.0)
	var db_before := AudioServer.get_bus_volume_db(mu)
	app.set_haptics_enabled(false)
	app.set_haptics_enabled(true)
	_ok(mc.is_playing() and mc.get_start_count() == 1 and AudioServer.get_bus_volume_db(mu) == db_before and not AudioServer.is_bus_mute(mu), "Haptics setting has no music side effect")
	_ok(mc.get_start_count() == 1, "settings changes never restarted the music")
	_free_host(h)
	_complete("real_host_bus_routing")

func _no_legacy_side_files() -> void:
	print("[no legacy side files]")
	_ok(_stamp(LEGACY_AUDIO) == _legacy_before[LEGACY_AUDIO], "user://audio_settings.cfg not written by Settings")
	_ok(_stamp(LEGACY_HAPTICS) == _legacy_before[LEGACY_HAPTICS], "user://haptics_settings.cfg not written by Settings")
	var src := FileAccess.get_file_as_string("res://scripts/ui/settings_panel.gd") + FileAccess.get_file_as_string("res://scripts/app/app_state.gd")
	_ok(src.find("audio.save()") == -1 and src.find("haptics.save()") == -1, "Settings/AppState never call the legacy side-file save()")
	_complete("no_legacy_side_files")

# ---------------------------------------------------------------- helpers ----

func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	var scheduler = h.get_scheduler()
	var agent_layer = h.get_agent_layer()
	for _i in range(MAX_TICKS):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(1.0)
		if supply.is_exhausted() and scheduler.live_assignment_count() == 0 and not _any_moving(agent_layer):
			runtime.tick(1.0)
			if h.get_completion().is_terminal():
				break
			runtime.tick(1.0)
			break

func _any_moving(agent_layer) -> bool:
	if agent_layer == null:
		return false
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return true
	return false

func _make_host(app):
	var sub := _sub(Vector2i(1080, 2160))
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.app_state = app
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "production host built with injected AppState (%s)" % host.get_build_error())
	if not ok:
		sub.free()
		return null
	await process_frame
	host.get_screen().relayout()
	await process_frame
	host.get_runtime().set_process(false)
	host.set_meta("sub", sub)
	return host

func _free_host(h) -> void:
	if h != null and h.has_meta("sub"):
		var sub = h.get_meta("sub")
		if is_instance_valid(sub):
			sub.free()

func _sub(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	return sub

func _stamp(path: String) -> String:
	if not FileAccess.file_exists(path):
		return "absent"
	return "%d:%d" % [FileAccess.get_modified_time(path), FileAccess.get_file_as_bytes(path).size()]

func _uniq(tag: String) -> String:
	var p := "user://m41v1_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _neutral() -> void:
	for b in ["Master", "Music", "SFX"]:
		var i := AudioServer.get_bus_index(b)
		AudioServer.set_bus_mute(i, false)
		AudioServer.set_bus_volume_db(i, 0.0)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	for c in missing:
		print("  FAIL: sub-test did not complete: %s" % c)
	_fail += missing.size()
	print("M41 V01 cases completed: %d/%d" % [EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size()])
	print("M41 V01 settings evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
