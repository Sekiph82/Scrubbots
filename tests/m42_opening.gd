extends SceneTree
## M42-C001 — opening cinematic evidence (SB-M42-026..033). Later tasks append cases.
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_opening.gd

const MP4 := "res://assets/brand/opening/final_15_seconds_opening_video.mp4"
const MP4_SHA256 := "c044841d4aad1bc97c3d2bd144468c44f514bc2e288a970ae0a6aa14191f4388"
const OGV := "res://assets/brand/opening/scrubbots_opening_720p30.ogv"
const OGV_SHA256 := "3ec6e1347bbb1d8ced2709f3383b06ae6dbfba017e0a6d23a0fb991ec78ee89a"

var EXPECTED_CASES := ["mp4_preserved", "ogv_runtime_asset", "opening_player_aspect", "opening_lifecycle",
	"boot_opening_to_home_once", "once_per_cold_launch", "device_instrumentation", "ios_static_readiness"]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_mp4_preserved()
	_ogv_runtime_asset()
	await _opening_player_aspect()
	await _opening_lifecycle()
	await _boot_opening_to_home_once()
	await _once_per_cold_launch()
	await _device_instrumentation()
	_ios_static_readiness()
	_cleanup()
	_done()

## SB-M42-026: owner MP4 preserved byte-exact with provenance.
func _mp4_preserved() -> void:
	print("[mp4 preserved]")
	_ok(FileAccess.file_exists(MP4), "canonical MP4 path exists")
	_ok(FileAccess.get_sha256(MP4) == MP4_SHA256, "SHA-256 matches recorded provenance")
	_ok(FileAccess.get_file_as_bytes(MP4).size() == 25234301, "size 25,234,301 bytes")
	var prov := FileAccess.get_file_as_string("res://assets/brand/opening/PROVENANCE.md")
	_ok(prov.find(MP4_SHA256) != -1 and prov.find("1280x720") != -1 and prov.find("44,100 Hz") != -1, "PROVENANCE.md records hash, dimensions and audio")
	_complete("mp4_preserved")

## SB-M42-027: Ogg Theora + Vorbis 720p30 runtime derivative, recorded command.
func _ogv_runtime_asset() -> void:
	print("[ogv runtime asset]")
	_ok(FileAccess.file_exists(OGV) and FileAccess.get_sha256(OGV) == OGV_SHA256, "OGV exists with recorded SHA-256")
	var b := FileAccess.get_file_as_bytes(OGV)
	_ok(b.slice(0, 4).get_string_from_ascii() == "OggS", "Ogg container")
	var raw := b.slice(0, 8192)
	_ok(_find(raw, "theora".to_ascii_buffer()) != -1 and _find(raw, "vorbis".to_ascii_buffer()) != -1, "Theora + Vorbis stream headers present")
	var th := _find(raw, PackedByteArray([0x80]) + "theora".to_ascii_buffer())
	if th >= 0:
		var fmbw := (raw[th + 10] << 8) | raw[th + 11]
		var fmbh := (raw[th + 12] << 8) | raw[th + 13]
		var picw := (raw[th + 14] << 16) | (raw[th + 15] << 8) | raw[th + 16]
		var pich := (raw[th + 17] << 16) | (raw[th + 18] << 8) | raw[th + 19]
		var frn := (raw[th + 22] << 24) | (raw[th + 23] << 16) | (raw[th + 24] << 8) | raw[th + 25]
		var frd := (raw[th + 26] << 24) | (raw[th + 27] << 16) | (raw[th + 28] << 8) | raw[th + 29]
		_ok(picw == 1280 and pich == 720, "Theora picture 1280x720 (%dx%d, frame %dx%d MBs)" % [picw, pich, fmbw, fmbh])
		_ok(frd > 0 and frn / frd == 30 and frn % frd == 0, "Theora frame rate 30/1 (%d/%d)" % [frn, frd])
	else:
		_ok(false, "Theora identification header found")
	var s = load(OGV)
	_ok(s is VideoStreamTheora, "Godot imports it as VideoStreamTheora (%s)" % (s.get_class() if s else "null"))
	_ok(FileAccess.get_sha256(MP4) == MP4_SHA256, "MP4 master unchanged after conversion")
	var prov := FileAccess.get_file_as_string("res://assets/brand/opening/PROVENANCE.md")
	_ok(prov.find("-c:v libtheora -q:v 8") != -1 and prov.find("ffmpeg 9.0.1") != -1 and prov.find(OGV_SHA256) != -1, "exact command, tool version and hash recorded")
	_complete("ogv_runtime_asset")

const OpeningScreen = preload("res://scripts/app/opening_screen.gd")

func _sub(size: Vector2i) -> SubViewport:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	return sub

## SB-M42-028: VideoStreamPlayer with the OGV, letterboxed aspect-preserving fit.
func _opening_player_aspect() -> void:
	print("[opening player aspect]")
	for size in [Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1440, 3200), Vector2i(1080, 1920), Vector2i(1536, 2048)]:
		var sub := _sub(size)
		var o = OpeningScreen.new()
		sub.add_child(o)
		await process_frame
		var started: bool = o.begin()
		await process_frame
		var p: VideoStreamPlayer = o.get_player()
		var r: Rect2 = o.get_video_rect()
		var tag := str(size)
		_ok(started and p.stream is VideoStreamTheora, "%s: plays the Theora OGV runtime asset" % tag)
		_ok(p.stream.resource_path.ends_with(".ogv"), "%s: never the H.264/MP4 path" % tag)
		_ok(absf(r.size.x / r.size.y - 1280.0 / 720.0) < 0.01, "%s: aspect 16:9 preserved (%s)" % [tag, str(r.size)])
		_ok(r.size.x <= size.x + 0.5 and r.size.y <= size.y + 0.5 and (absf(r.size.x - size.x) <= 1.0 or absf(r.size.y - size.y) <= 1.0), "%s: fitted inside, touching one edge (no crop/stretch)" % tag)
		_ok(absf(r.position.y + r.size.y * 0.5 - size.y * 0.5) <= 1.0 and absf(r.position.x + r.size.x * 0.5 - size.x * 0.5) <= 1.0, "%s: centered (letterbox)" % tag)
		o.cleanup()
		sub.free()
	_complete("opening_player_aspect")

## SB-M42-028: exactly one terminal outcome, deterministic cleanup, isolation.
func _opening_lifecycle() -> void:
	print("[opening lifecycle]")
	var sub := _sub(Vector2i(1080, 2160))
	var o = OpeningScreen.new()
	sub.add_child(o)
	await process_frame
	var ev: Array = []
	o.completed.connect(func(): ev.append("completed"))
	o.failed.connect(func(r): ev.append("failed:" + r))
	o.begin()
	_ok(not o.begin(), "begin() only once")
	o.get_player().finished.emit()
	o.get_player().finished.emit()
	_ok(ev == ["completed"], "finished -> exactly one completed (%s)" % str(ev))
	_ok(o.get_player().stream == null and not o.get_player().is_playing(), "cleanup released stream and stopped playback")
	o._process(30.0)
	_ok(ev == ["completed"], "watchdog after terminal does nothing")
	o.free()
	var o2 = OpeningScreen.new()
	sub.add_child(o2)
	var ev2: Array = []
	o2.completed.connect(func(): ev2.append("completed"))
	o2.failed.connect(func(r): ev2.append("failed:" + r))
	o2.set_stream_path("res://assets/brand/opening/missing.ogv")
	_ok(not o2.begin(), "missing stream -> begin false")
	await process_frame
	o2.get_player().finished.emit()
	_ok(ev2 == ["failed:stream_unavailable"], "missing stream -> exactly one failed (%s)" % str(ev2))
	o2.free()
	var o3 = OpeningScreen.new()
	sub.add_child(o3)
	var ev3: Array = []
	o3.completed.connect(func(): ev3.append("completed"))
	o3.begin()
	o3._process(OpeningScreen.WATCHDOG_SEC + 0.1)
	_ok(ev3 == ["completed"] and o3.get_player().stream == null, "watchdog guarantees termination + cleanup")
	o3.free()
	var src := ""
	for line in FileAccess.get_file_as_string("res://scripts/app/opening_screen.gd").split("
"):
		var ci := line.find("#")
		src += (line if ci == -1 else line.substr(0, ci)).to_lower() + "
"
	_ok(src.find("app_state") == -1 and src.find("economy") == -1 and src.find("save") == -1 and src.find("progression") == -1 and src.find(".mp4") == -1, "isolated from AppState/economy/save/progression; no MP4 path")
	sub.free()
	_complete("opening_lifecycle")

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
var _tmp: Array = []

func _uniq(tag: String) -> String:
	var p := "user://m42open_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

const LaunchSession = preload("res://scripts/app/launch_session.gd")

## cold=true simulates a new native process (fresh launch session) before booting.
func _boot(opening: int, cold: bool = true, path: String = ""):
	if cold:
		LaunchSession.debug_reset_for_new_process()
	MainScript.boot_save_path_override = path if not path.is_empty() else _uniq("boot")
	MainScript.boot_opening_override = opening
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	return root

func _shutdown(root) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1

## SB-M42-029: cinematic completion -> Home exactly once; failure -> Home; repeated
## finished/error callbacks never duplicate Home/navigation state.
func _boot_opening_to_home_once() -> void:
	print("[boot opening to home once]")
	var R := NavigationController.Route
	var root = await _boot(1)
	var nav = root.get_navigation()
	var op = root.get_opening()
	_ok(nav.current() == R.OPENING and op != null and op.is_started() and not root.get_home().visible, "boot -> OPENING, cinematic playing, Home hidden")
	_ok(not root.play_current_frontier().get("ok", true) and not nav.open_settings(), "no gameplay/settings during the cinematic")
	var t0: int = nav.transition_id()
	op.get_player().finished.emit()
	op.get_player().finished.emit()
	op.failed.emit("late_error")
	await process_frame
	_ok(nav.current() == R.HOME and nav.transition_id() == t0 + 1, "completion -> HOME exactly once (repeated finished/error ignored)")
	_ok(root.get_opening() == null and root.get_home().visible and root.get_home().get_region("PlayButton") != null, "opening released, normal Home shown")
	_ok(nav.last_payload().get("outcome") == "completed", "outcome recorded: completed")
	_shutdown(root)
	var root2 = await _boot(1)
	var nav2 = root2.get_navigation()
	var t1: int = nav2.transition_id()
	var op2 = root2.get_opening()
	op2.failed.emit("decode_error")
	op2.failed.emit("decode_error")
	op2.get_player().finished.emit()
	await process_frame
	_ok(nav2.current() == R.HOME and nav2.transition_id() == t1 + 1 and nav2.last_payload().get("outcome") == "failed:decode_error", "failure -> HOME exactly once (fail-safe)")
	_shutdown(root2)
	var root3 = await _boot(-1)
	_ok(root3.get_navigation().current() == R.HOME and root3.get_opening() == null, "auto policy in a headless run (no display) boots straight to Home")
	_shutdown(root3)
	_complete("boot_opening_to_home_once")

## SB-M42-031: once per cold/native launch; never on internal navigation, Retry,
## returning from screens, root re-creation or background/foreground resume.
func _once_per_cold_launch() -> void:
	print("[once per cold launch]")
	var R := NavigationController.Route
	var path := _uniq("session")
	var root = await _boot(1, true, path)
	var nav = root.get_navigation()
	_ok(nav.current() == R.OPENING and LaunchSession.opening_consumed(), "cold launch plays the opening")
	root.get_opening().get_player().finished.emit()
	await process_frame
	_ok(nav.current() == R.HOME, "completion -> Home")
	for what in [Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_RESUMED, Node.NOTIFICATION_APPLICATION_FOCUS_IN]:
		root.notification(what)
	await process_frame
	_ok(nav.current() == R.HOME and root.get_opening() == null, "background/foreground resume does not replay")
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	h.get_completion().terminal_reached.emit(&"LOST", {})
	root.retry_from_results()
	_ok(nav.current() == R.GAMEPLAY and root.get_opening() == null, "Retry does not replay")
	root.handle_back()
	h.get_completion().terminal_reached.emit(&"LOST", {})
	root.get_results_screen().get_home_button().pressed.emit()
	root.open_settings()
	root.get_settings_panel().close_panel()
	await process_frame
	_ok(nav.current() == R.HOME and root.get_opening() == null, "returning from gameplay/results/settings does not replay")
	_shutdown(root)
	var again = await _boot(1, false, path)
	_ok(again.get_navigation().current() == R.HOME and again.get_opening() == null, "re-creating the app root in the same process (no native restart) does not replay")
	_shutdown(again)
	var cold = await _boot(1, true, path)
	_ok(cold.get_navigation().current() == R.OPENING, "a true native restart (new process) plays it again")
	cold.get_opening().get_player().finished.emit()
	_shutdown(cold)
	var saved := FileAccess.get_file_as_string(path).to_lower()
	_ok(saved.find("opening") == -1 and saved.find("launch") == -1 and saved.find("cinematic") == -1, "launch-session state is never written to the save")
	_complete("once_per_cold_launch")

## SB-M42-032: code-side device instrumentation (real-device evidence is owner-gated).
func _device_instrumentation() -> void:
	print("[device instrumentation]")
	var sub := _sub(Vector2i(1080, 2160))
	var o = OpeningScreen.new()
	sub.add_child(o)
	await process_frame
	o.begin()
	for _i in range(30):
		await process_frame
	var mid: Dictionary = o.get_metrics()
	_ok(mid["process_frames"] > 0 and mid["outcome"] == "", "metrics accumulate while playing (%d frames)" % mid["process_frames"])
	o.get_player().finished.emit()
	var m: Dictionary = o.get_metrics()
	_ok(m["outcome"] == "completed:finished" and m["playback_ms"] >= 0 and m["stream_released"], "terminal metrics: outcome, playback_ms, stream released (%s)" % str(m))
	_ok(m["video_rect"] == [0, 776, 1080, 607] and m["screen"] == [1080, 2160], "letterbox rect recorded for portrait 1080x2160")
	_ok(m["startup_latency_ms"] >= 0, "first decoded frame observed (startup_latency_ms=%d)" % m["startup_latency_ms"])
	o.free()
	sub.free()
	var doc := FileAccess.get_file_as_string("res://docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md")
	_ok(doc.find("[OPENING_METRICS]") != -1 and doc.find("not run yet") != -1 and doc.find("DEVICE_OWNER_REQUIRED") != -1, "device checklist published; no device result claimed")
	_complete("device_instrumentation")

## SB-M42-033: iOS static readiness of the same boot/cinematic architecture.
func _ios_static_readiness() -> void:
	print("[ios static readiness]")
	_ok(ClassDB.class_exists("VideoStreamTheora") and load(OGV) is VideoStreamTheora, "Theora decoder is Godot built-in (platform independent)")
	_ok(int(ProjectSettings.get_setting("display/window/handheld/orientation")) == 1, "portrait orientation for handheld (iOS/Android)")
	var branches: Array = []
	for f in ["res://scripts/app/main.gd", "res://scripts/app/opening_screen.gd", "res://scripts/app/launch_session.gd", "res://scripts/app/navigation_controller.gd"]:
		var t := FileAccess.get_file_as_string(f)
		if t.find("OS.get_name() ==") != -1 or t.find("OS.has_feature(\"ios\")") != -1 or t.find("OS.has_feature(\"android\")") != -1 or t.find("\"iOS\"") != -1:
			branches.append(f)
	_ok(branches.is_empty(), "no platform-specific branches in boot/cinematic/session/nav %s" % str(branches))
	var main_src := FileAccess.get_file_as_string("res://scripts/app/main.gd")
	_ok(main_src.find("NOTIFICATION_APPLICATION_PAUSED") != -1 and main_src.find("NOTIFICATION_WM_GO_BACK_REQUEST") != -1, "lifecycle notifications handled generically (iOS delivers PAUSED/RESUMED)")
	var doc := FileAccess.get_file_as_string("res://docs/OPENING_CINEMATIC_DEVICE_VALIDATION.md")
	_ok(doc.find("IOS_DEVICE_LATER") != -1 and doc.find("## iOS readiness") != -1, "iOS readiness recorded; physical playback not claimed")
	_complete("ios_static_readiness")

func _find(hay: PackedByteArray, needle: PackedByteArray) -> int:
	for i in range(hay.size() - needle.size()):
		var hit := true
		for k in range(needle.size()):
			if hay[i + k] != needle[k]:
				hit = false
				break
		if hit:
			return i
	return -1

func _complete(c: String) -> void:
	_completed[c] = true

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
	print("M42 opening cases completed: %d/%d" % [EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size()])
	print("M42 opening evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
