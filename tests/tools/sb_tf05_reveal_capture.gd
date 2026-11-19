extends SceneTree
## SB-TF-05 evidence captures (NOT shipping): the REAL app root (main.tscn) in a SubViewport at the
## logical size a 720x1520 phone gets (1080x2280), saved at 720x1520, on a test save:
##   01 win reveal holding with the "WATCH AD · x2" button (a test rewarded provider is ready)
##   02 the same reveal after a verified completed view: Scrub Bucks show the doubled amount
##   03 the win reveal mid flight into the HUD
##   04 a non-win source: the Daily login claim's reveal over the Daily popup
## Needs a rendering driver (not --headless):
##   godot --path . -s res://tests/tools/sb_tf05_reveal_capture.gd -- <out_dir> [en|tr]

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const LOGICAL := Vector2i(1080, 2280)
const PHONE := Vector2i(720, 1520)

## Rewarded provider that is ready and keeps the request for the capture to resolve.
class ReadyAds extends AdProvider:
	var requests: Array = []
	func is_available(_placement: String) -> bool:
		return true
	func request(placement: String, token: String, deliver: Callable) -> bool:
		requests.append([placement, token, deliver])
		return true

var _out := ""
var _root = null
var _sub: SubViewport
var _tmp: Array = []

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://sb_tf05_capture"
	UiText.locale = args[1] if args.size() > 1 else "en"
	DirAccess.make_dir_recursive_absolute(_out)
	MainScript.boot_opening_override = 0
	MainScript.boot_level_intro_override = 0
	MainScript.boot_win_animation_override = 0
	_run.call_deferred()

func _run() -> void:
	await _boot()
	var ads := ReadyAds.new()
	_root.get_app_state().economy.ads.set_provider(ads)
	await _win()
	var rv = _root.get_home().get_reward_flight()
	while rv.is_running() and rv.elapsed() < 0.6:
		await process_frame
	await _shot("01_win_reveal_hold_x2_button")
	rv.get_double_button().pressed.emit()
	await create_timer(0.8).timeout   # the hold stands still while the "ad" plays
	(ads.requests[-1][2] as Callable).call(ads.requests[-1][1], {"outcome": "completed", "verified": true})
	await process_frame
	await _shot("02_win_reveal_doubled")
	while rv.is_running() and rv.elapsed() < rv.fly_at() + 0.3:
		await process_frame
	await _shot("03_win_reveal_mid_flight")
	while rv.is_running():
		await process_frame
	await create_timer(0.5).timeout
	_root.get_modal_stack().clear("capture")
	_root._on_home_shortcut("daily")
	await create_timer(0.6).timeout
	_root.get_modal_stack().top().get_action_button("claim").pressed.emit()
	while rv.is_running() and rv.elapsed() < 0.9:
		await process_frame
	await _shot("04_daily_claim_reveal")
	print("reveal log %s" % str(_root.reveal_log))
	_shutdown()
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))
	quit(0)

func _boot() -> void:
	var path := "user://sb_tf05_capture_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	var seed = AppState.new(path)
	for o in seed.economy.gift.add_streak_sb("capture_seed", 1):
		seed.economy.meta_ui.mark_seen("gift:" + String(o["id"]))
	seed.request_save()
	MainScript.boot_save_path_override = path
	_sub = SubViewport.new()
	_sub.size = LOGICAL
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await create_timer(1.0).timeout

## Level 1 played to its real WON (front clicks + runtime ticks), then Home.
func _win() -> void:
	_root.play_current_frontier()
	await process_frame
	var h = _root.get_gameplay_host()
	var rt = h.get_runtime()
	rt.set_process(false)
	for _i in range(80000):
		if h.get_completion().is_terminal():
			break
		if h.get_slots().rightmost_empty_index() != -1:
			for col in range(h.get_supply().get_column_count()):
				if h.get_input_controller().activate_front(col).get("ok", false):
					break
		rt.tick(1.0)
	await process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _sub.get_texture().get_image()
	img.resize(PHONE.x, PHONE.y, Image.INTERPOLATE_LANCZOS)
	var p := _out.path_join(name + ".png")
	img.save_png(p)
	print("captured %s %dx%d" % [p, img.get_width(), img.get_height()])

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	MainScript.boot_save_path_override = ""
