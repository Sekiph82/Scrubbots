extends SceneTree
## Deterministic production-Home snapshot harness (SB-M42 master convergence V02).
## Renders the REAL scenes/ui/home/home_screen.tscn bound to a representative,
## non-destructive AppState (isolated temp save) inside a SubViewport and saves PNGs.
## Needs a rendering driver (run WITHOUT --headless):
##   godot --path . -s res://tests/tools/home_snapshot.gd -- <out_dir> [WxH ...]
## Output goes to <out_dir> (never to approved art paths).

const AppState = preload("res://scripts/app/app_state.gd")
const HomeScreenScene = preload("res://scenes/ui/home/home_screen.tscn")
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")

const DEFAULT_SIZES := [Vector2i(1080, 2160)]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := "user://home_snapshots"
	var sizes: Array = []
	for a in args:
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
		for _i in range(12):
			await process_frame
		home.refresh()
		for _i in range(6):
			await process_frame
		var img := sub.get_texture().get_image()
		var path := "%s/home_%dx%d.png" % [out_dir, size.x, size.y]
		var err := img.save_png(path)
		print("SNAPSHOT ", path, " err=", err, " size=", img.get_size())
		sub.queue_free()
		await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	quit(0)
