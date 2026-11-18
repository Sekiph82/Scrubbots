extends SceneTree
## SB-TF-03 owner captures: Home EN, Home TR and Profile at a phone viewport, on the real app
## root (main.tscn) with a temp save (never the canonical one). Fixture: every feature unlocked
## (test seam), 4 active events (injected list) so both activity columns hold >= 3 buttons, and
## one owned card not yet viewed (new-card badge). Needs a rendering driver (no --headless):
##   godot --path . -s res://tests/tools/sb_tf03_capture.gd -- <out_dir> [WxH]

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const EVENTS := ["scrub_sprint", "first_brush_race", "weekly_cleanup_challenge", "sparkling_streak"]

class FakeEvents extends "res://scripts/economy/events_v02_service.gd":
	var views: Array = []
	func list() -> Array:
		return views.duplicate(true)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://sb_tf03_captures"
	var size := Vector2i(1080, 2160)
	if args.size() > 1:
		size = Vector2i(int(args[1].split("x")[0]), int(args[1].split("x")[1]))
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	preload("res://scripts/app/app_state.gd").test_unlock_all = true
	MainScript.boot_clock_override = func(): return 1790000000
	MainScript.boot_opening_override = 0   # no opening cinematic over the capture
	MainScript.boot_local_day_override = func(): return 20000
	var save := "user://sb_tf03_capture_%d.save" % Time.get_ticks_usec()
	for loc in ["en", "tr"]:
		UiText.locale = loc
		MainScript.boot_save_path_override = save
		var sub := SubViewport.new()
		sub.size = size
		sub.disable_3d = true
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_root().add_child(sub)
		var root = MainScene.instantiate()
		sub.add_child(root)
		await _frames(6)
		root.get_modal_stack().clear("capture")
		var app = root.get_app_state()
		app.progression.debug_set_current_level(12)
		var e = app.economy
		var fake := FakeEvents.new(func(): return 1790000000)
		for id in EVENTS:
			fake.views.append({"iid": id + ":1", "id": id, "phase": "active", "claimable": 1 if id == EVENTS[0] else 0,
				"steps": [{"rid": "m0", "claimed": false}]})
		e.events_v02 = fake
		var cid := String(e.collection.all_card_ids()[0])
		if e.collection.owned(cid) == 0:
			e.collection.add_card(cid)
		var home = root.get_home()
		home.get_region("SafeAreaRoot").set_synthetic_insets(0, 0, 0, 0)
		home.refresh()
		await _frames(12)
		root.get_modal_stack().clear("capture")
		await _frames(4)
		_save(sub, "%s/home_%s.png" % [out_dir, loc])
		if loc == "en":
			(home.get_region("ProfileButton") as Button).pressed.emit()
			await _frames(12)
			_save(sub, "%s/profile.png" % out_dir)
		root.free()
		sub.free()
		await _frames(2)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save + suffix))
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	quit(0)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _save(sub: SubViewport, path: String) -> void:
	var img := sub.get_texture().get_image()
	print("CAPTURE ", path, " err=", img.save_png(path), " size=", img.get_size())
