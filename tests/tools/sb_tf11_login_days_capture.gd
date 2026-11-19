extends SceneTree
## SB-TF-11 evidence captures (NOT shipping): the REAL app root (main.tscn) in a SubViewport at the
## logical size a 720x1520 phone gets (1080x2280), saved at 720x1520, on a test save:
##   01 Profile with the claimable badge on the Login Days card
##   02 the Daily ladder opened from that card
## Needs a rendering driver (not --headless):
##   godot --path . -s res://tests/tools/sb_tf11_login_days_capture.gd -- <out_dir> [en|tr]

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const LOGICAL := Vector2i(1080, 2280)
const PHONE := Vector2i(720, 1520)

var _out := ""
var _loc := "en"
var _root = null
var _sub: SubViewport
var _path := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://sb_tf11_capture"
	_loc = args[1] if args.size() > 1 else "en"
	UiText.locale = _loc
	DirAccess.make_dir_recursive_absolute(_out)
	MainScript.boot_opening_override = 0
	MainScript.boot_level_intro_override = 0
	_run.call_deferred()

func _run() -> void:
	_path = "user://sb_tf11_capture_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = _path
	_sub = SubViewport.new()
	_sub.size = LOGICAL
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await create_timer(1.0).timeout
	_root.get_modal_stack().clear("capture")
	_root.get_home().get_region("ProfileButton").pressed.emit()
	await create_timer(0.6).timeout
	await _shot("01_profile_login_days_badge_" + _loc)
	(_root.get_modal_stack().top().find_child("LoginDaysButton", true, false) as Button).pressed.emit()
	await create_timer(0.6).timeout
	await _shot("02_login_days_ladder_" + _loc)
	_root.free()
	_sub.free()
	for s in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_path + s):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_path + s))
	quit(0)

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := _sub.get_texture().get_image()
	img.resize(PHONE.x, PHONE.y, Image.INTERPOLATE_LANCZOS)
	var p := _out.path_join(name + ".png")
	img.save_png(p)
	print("captured %s %dx%d" % [p, img.get_width(), img.get_height()])
