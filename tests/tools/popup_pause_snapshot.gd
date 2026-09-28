extends SceneTree
## M43-C002-C001 popup / modal / Pause evidence snapshots. Real app root (main.tscn), real
## frontier launch, real ProductionGameplayHost + GameplayScreen, the app ModalStack and the
## real Pause control / host Pause flow. Generic popups are pushed on the same stack with
## caller data; economy setup only through canonical services on a temp save.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/popup_pause_snapshot.gd -- <out_dir>

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const Popups = preload("res://scripts/ui/popup/popups.gd")

## [stem, size, scenario, post_action]
const SHOTS := [
	["pause_gameplay_v02", Vector2i(1080, 2160), "pause", true],
	["restart_confirm_pre_action", Vector2i(1080, 2160), "restart", false],
	["restart_confirm_post_action", Vector2i(1080, 2160), "restart", true],
	["home_confirm_pre_action", Vector2i(1080, 2160), "home", false],
	["home_confirm_post_action", Vector2i(1080, 2160), "home", true],
	["stacked_modals", Vector2i(1080, 2160), "stacked", true],
	["generic_confirm_warning", Vector2i(1080, 2160), "confirm", true],
	["reward_confirmation", Vector2i(1080, 2160), "reward", true],
	["insufficient_sb", Vector2i(1080, 2160), "insufficient", true],
	["network_error", Vector2i(1080, 2160), "network", true],
	["busy_loading", Vector2i(1080, 2160), "busy", true],
	["pause_short_phone", Vector2i(1080, 1920), "pause", true],
	["home_confirm_post_action_short_phone", Vector2i(1080, 1920), "home", true],
	["pause_phone", Vector2i(1170, 2532), "pause", true],
	["pause_phone", Vector2i(1290, 2796), "pause", true],
	["pause_tablet", Vector2i(1536, 2048), "pause", true],
	["restart_confirm_post_action_tablet", Vector2i(1536, 2048), "restart", true],
	["pause_six_slot", Vector2i(1080, 2160), "pause_six", true],
]

var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://popup_pause_snapshots"
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	MainScript.boot_opening_override = 0
	for shot in SHOTS:
		await _shot(out_dir, shot)
	quit(1 if _bad > 0 else 0)

func _shot(out_dir: String, shot: Array) -> void:
	var size: Vector2i = shot[1]
	var save_path := "user://popup_pause_snapshot_%d.save" % Time.get_ticks_usec()
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.transparent_bg = false
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	MainScript.boot_save_path_override = save_path
	var root = MainScene.instantiate()
	sub.add_child(root)
	await process_frame
	var app = root.get_app_state()
	app.progression.debug_set_current_level(2)
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	var stack = root.get_modal_stack()
	# Realistic live Heart / streak state for the consequence copy.
	var snap: Dictionary = app.economy.streak.snapshot()
	snap["streak"] = 3
	app.economy.streak.import_snapshot(snap)
	if shot[2] == "pause_six":
		app.economy.boosters.add_charges("plus_one_slot", 1)
		h.request_booster("plus_one_slot")
	if shot[3]:
		for col in range(h.get_supply().get_column_count()):
			if h.get_input_controller().activate_front(col).get("ok", false):
				break
		for _i in range(30):
			h.get_runtime().tick(0.05)
	var note := ""
	match shot[2]:
		"pause", "pause_six":
			h.get_screen().get_pause_button().pressed.emit()
		"restart", "home":
			h.get_screen().get_pause_button().pressed.emit()
			h.get_pause_popup().get_action_button(shot[2]).pressed.emit()
		"stacked":
			h.get_screen().get_pause_button().pressed.emit()
			h.get_pause_popup().get_action_button("restart").pressed.emit()
			stack.push(Popups.network_error({"surface": "store"}))
		"confirm":
			stack.push(Popups.confirm({"title": "USE TORNADO?", "body": "Tornado clears every cell of one colour. This uses 1 charge.",
				"warning": true, "confirm_text": "USE", "context": {"token": "evidence"}}))
		"reward":
			stack.push(Popups.reward({"committed": true, "title": "PURCHASE COMPLETE",
				"rows": [{"text": "+1 Heart · Hearts 5/5", "icon": "res://assets/ui/final/popups/failure/heart_large.png"},
					{"text": "-500 SB", "icon": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png"}]}))
		"insufficient":
			# Genuinely short wallet through the canonical wallet on the temp save.
			app.economy.wallet.debit("scrub_bucks", maxi(app.economy.wallet.scrub_bucks() - 200, 0))
			stack.push(Popups.insufficient_sb({"item_label": "Tornado", "price_sb": 750,
				"balance_sb": app.economy.wallet.scrub_bucks(), "pending": {"pending_id": "evidence"}}))
		"network":
			stack.push(Popups.network_error({"surface": "rewarded_ad"}))
		"busy":
			stack.push(Popups.busy({"body": "Contacting the store..."}))
	for _i in range(10):
		await process_frame
	var path := "%s/%s_%dx%d.png" % [out_dir, shot[0], size.x, size.y]
	var top = stack.top()
	var fits: bool = top != null and stack.ids().all(func(_i): return true)
	for c in stack.get_child(0).get_children():
		fits = fits and c.text_fits()
	if top == null or not fits or h.get_completion().is_terminal():
		_bad += 1
		print("REJECTED ", path, " stack=", stack.ids(), " fits=", fits)
	else:
		var img := sub.get_texture().get_image()
		note = "stack=%s top_frame=%s shell=%s hearts=%d streak=%d started=%s" % [str(stack.ids()), top.get_frame_kind(),
			h.get_screen().get_shell_id(), app.economy.hearts.hearts(), app.economy.streak.streak(), str(app.economy.streak.gameplay_started())]
		print("SNAPSHOT ", path, " err=", img.save_png(path), " ", note)
	root.free()
	sub.queue_free()
	await process_frame
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
