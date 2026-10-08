extends SceneTree
## M43-C005F-PHASE2 runtime evidence (NOT shipping). Real app root (main.tscn) in a fixed-size
## SubViewport, real GameFeelFlow + Saltmire Spark autoloads, the app's ONE FeedbackAdapter:
##   - Results WON: real launch -> real WON terminal commit -> Results (FULL / REDUCED);
##   - Standard / Premium pack: real AppState.commit_pack() model -> shipping ceremony on the
##     app's ModalStack, bound to the app adapter, real taps (FULL / REDUCED).
## Captures at the canonical 1080x2160 viewport and a 1536x2048 tablet aspect.
## Needs a rendering driver (not --headless):
##   godot --path . -s res://tests/tools/c005f_phase2_capture.gd
## Output: coordination/sessions/M43-C005F-PHASE2/evidence/*.png

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const OUT := "res://coordination/sessions/M43-C005F-PHASE2/evidence"
const SIZES := [Vector2i(1080, 2160), Vector2i(1536, 2048)]

var _sub: SubViewport
var _root = null
var _tmp: Array = []
var _shots: Array = []

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_run.call_deferred()

func _run() -> void:
	# Warm-up boot: the first app boot of a process runs one-time startup work; captures start after it.
	await _boot(SIZES[0], false)
	print("warm-up route=%s launch=%s" % [_root.get_navigation().route_name(), str(_root.play_current_frontier())])
	await _frames(30)
	await _teardown()
	for sz in SIZES:
		var tag := "%dx%d" % [sz.x, sz.y]
		for mode in ["full", "reduced"]:
			await _results_won(sz, mode == "reduced", "results_won_%s_%s" % [mode, tag])
			await _pack(sz, mode == "reduced", false, "standard_%s_%s" % [mode, tag])
			await _pack(sz, mode == "reduced", true, "premium_%s_%s" % [mode, tag])
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))
	print("CAPTURED %d shots: %s" % [_shots.size(), str(_shots)])
	quit(0)

func _boot(size: Vector2i, reduced: bool) -> void:
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	var path := "user://c005f_p2_capture_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)
	_root.get_app_state().effects.set_reduced(reduced)

func _teardown() -> void:
	_root.free()
	_sub.free()
	MainScript.boot_save_path_override = ""
	await _frames(2)

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	_sub.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, name]))
	_shots.append(name)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

## Real launch -> real WON terminal (economy + save commit inside the host) -> Results.
func _results_won(size: Vector2i, reduced: bool, name: String) -> void:
	await _boot(size, reduced)
	var r: Dictionary = _root.play_current_frontier()
	var h = null
	for _i in range(240):
		await process_frame
		h = _root.get_gameplay_host()
		if h != null and is_instance_valid(h) and h.get_runtime() != null:
			break
	h.get_runtime().set_process(false)
	h.get_completion().terminal_reached.emit(&"WON", {})
	await create_timer(0.30 if not reduced else 0.6).timeout
	print("%s route=%s launch=%s owned=%d" % [name, _root.get_navigation().route_name(), str(r.get("ok")), _root.feel.owned_count()])
	await _shot(name + ("_celebration" if not reduced else "_static"))
	await create_timer(1.6).timeout
	await _shot(name + "_settled")
	await _teardown()

## Real committed pack model -> shipping ceremony on the app's ModalStack, app adapter bound.
func _pack(size: Vector2i, reduced: bool, premium: bool, name: String) -> void:
	await _boot(size, reduced)
	var app = _root.get_app_state()
	var c: Dictionary = app.commit_pack("premium" if premium else "standard", "ev_%s_%d" % [name, Time.get_ticks_usec()])
	if not c.get("ok", false):
		print("%s commit failed %s" % [name, str(c)])
		await _teardown()
		return
	var cr: Dictionary = PremiumPackCeremony.create_premium(c["model"], reduced) if premium else StandardPackCeremony.create(c["model"], reduced)
	var p = cr["popup"]
	p.bind_feedback(_root.feel)
	_root.get_modal_stack().push(p)
	await _frames(3)
	p.tap()
	var mid_done := false
	for _i in range(1500):
		if not mid_done and not reduced and p.feel_log().size() >= 2:
			await create_timer(0.05).timeout
			await _shot(name + "_reveal_feel")
			await create_timer(0.15).timeout
			await _shot(name + "_reveal_feel_rising")
			mid_done = true
		if p.phase() == "AWAIT_ROUTE":
			break
		await process_frame
	await create_timer(0.25).timeout
	print("%s cards=%s feel=%s" % [name, str(c["model"]["cards"].map(func(x): return [x["rarity"], x["is_new"]])), str(p.feel_log())])
	await _shot(name + "_hold")
	await _teardown()
