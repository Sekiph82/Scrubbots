extends SceneTree
## Deterministic production-Home snapshot harness (SB-M42 master convergence V02).
## Renders the REAL scenes/ui/home/home_screen.tscn bound to a representative,
## non-destructive AppState (isolated temp save) inside a SubViewport and saves PNGs.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/home_snapshot.gd -- <out_dir> [WxH ...] [modals]
## `modals` additionally captures, at the first size, the ad slot collapsed and the Daily
## popup / Settings panel open over Home (modal state).
## Output goes to <out_dir> (never to approved art paths).

const AppState = preload("res://scripts/app/app_state.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")
const SettingsPanelScene = preload("res://scenes/ui/settings_panel.tscn")

const DEFAULT_SIZES := [Vector2i(1080, 2160)]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := "user://home_snapshots"
	var sizes: Array = []
	var modals := args.has("modals")
	for a in args:
		if a == "modals":
			continue
		if a.find("x") > 0 and a.split("x").size() == 2 and a.split("x")[0].is_valid_int():
			sizes.append(Vector2i(int(a.split("x")[0]), int(a.split("x")[1])))
		else:
			out_dir = a
	if sizes.is_empty():
		sizes = DEFAULT_SIZES
	DirAccess.make_dir_recursive_absolute(out_dir if out_dir.is_absolute_path() else ProjectSettings.globalize_path(out_dir))
	var now := 1790000000
	var clock := func(): return now
	var save_path := "user://home_snapshot_state_%d.save" % Time.get_ticks_usec()
	var app = AppState.new(save_path, clock, LocalCalendar.offset_provider(clock, 0))
	# Representative, deterministic state (in-memory; the temp save is deleted below).
	var e = app.economy
	e.wallet.credit("scrub_bucks", 1250)
	e.wallet.credit("bot_parts", 158)
	e.hearts.consume()
	e.gift.add_streak_sb("snapshot_gift", 60)
	e.streak.process_first_clear_win(1)
	e.streak.process_first_clear_win(2)
	e.collection.add_copies(e.collection.all_card_ids()[0], 3)
	await process_frame
	for size in sizes:
		var sub := SubViewport.new()
		sub.size = size
		sub.disable_3d = true
		sub.transparent_bg = false
		sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_root().add_child(sub)
		var home = HomeScreenScene.instantiate()
		sub.add_child(home)
		home.bind(app)
		# A phone without notch/gesture insets (desktop work-area insets are not a phone).
		home.get_region("SafeAreaRoot").set_synthetic_insets(0, 0, 0, 0)
		for _i in range(12):
			await process_frame
		home.refresh()
		for _i in range(6):
			await process_frame
		_save(sub, "%s/home_%dx%d.png" % [out_dir, size.x, size.y])
		if modals and size == sizes[0]:
			# V04: ad slot collapsed (future No-Ads entitlement simulation).
			home.set_ad_slot_enabled(false)
			for _i in range(6):
				await process_frame
			_save(sub, "%s/home_adslot_collapsed_%dx%d.png" % [out_dir, size.x, size.y])
			home.set_ad_slot_enabled(true)
			for _i in range(6):
				await process_frame
			for id in ["daily"]:
				var p = home.open_popup(id)
				for _i in range(6):
					await process_frame
				_save(sub, "%s/modal_%s_%dx%d.png" % [out_dir, id, size.x, size.y])
				p.close_popup()
			# Same wiring as the app root (main.gd): Settings panel above Home + modal state.
			var panel = SettingsPanelScene.instantiate()
			sub.add_child(panel)
			panel.bind(app)
			panel.open_panel()
			home.set_modal_active("settings", true)
			for _i in range(6):
				await process_frame
			_save(sub, "%s/modal_settings_%dx%d.png" % [out_dir, size.x, size.y])
		sub.queue_free()
		await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	quit(0)

func _save(sub: SubViewport, path: String) -> void:
	var img := sub.get_texture().get_image()
	var err := img.save_png(path)
	print("SNAPSHOT ", path, " err=", err, " size=", img.get_size())
