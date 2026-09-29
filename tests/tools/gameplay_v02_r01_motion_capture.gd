extends SceneTree
## M28-C002-C003-R01 V02 motion evidence: one continuous real-runtime session (Home with the
## owner-selected background -> PLAY -> Level 1 -> timed 2x purchase -> Level 1 fast-forwarded to
## WON -> Results -> Continue -> Level 2 auto-starts at 2x with the countdown running -> Scrubbots
## travel the railway) recorded with Godot's built-in Movie Maker (no extra dependency). Real app root,
## real runtime processing at the fixed movie frame rate, every interaction a ROUTED pointer
## tap (SubViewport.push_input) on the visible control: supply fronts (owner plan order),
## Pause, booster row, popup chips / X / SB CTA, 2x box and 2x offers. The wall clock the
## economy reads is the movie clock, so the timed-2x countdown runs in video time.
## (Original header follows.)
## A caption strip under the game names each step; the step timeline is printed as
## "STEP <seconds> <caption>".
## Run WITHOUT --headless. The 720x1440 window keeps the canvas exactly 1:2 on screens
## shorter than 2160 px (Movie Maker records the 1080x2160 stretch canvas):
##   godot --path . --write-movie <out.avi> --fixed-fps 30 --resolution 720x1440 -s res://tests/tools/gameplay_v02_motion_capture.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const FPS := 30
const T0 := 1_900_000_000
const GAME := Vector2i(1080, 2160)

var _frames := 0
var _sub: SubViewport
var _root
var _h
var _caption: Label
var _step := ""
var _plan: Array = []
var _plan_i := 0
var _auto_every := 0

func _initialize() -> void:
	MainScript.boot_opening_override = 0
	MainScript.boot_clock_override = func(): return T0 + _frames / FPS
	var view := Control.new()
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(view)
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	view.add_child(bg)
	_sub = SubViewport.new()
	_sub.size = GAME
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.add_child(_sub)
	var tex := TextureRect.new()
	tex.texture = _sub.get_texture()
	# Movie Maker records the 1080x2160 stretch canvas: the real 1080x2160 game render is
	# shown at 95 % so the caption strip fits underneath (input stays in game coordinates).
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.size = Vector2(GAME) * 0.95
	tex.position = Vector2((GAME.x - tex.size.x) * 0.5, 0)
	view.add_child(tex)
	_caption = Label.new()
	_caption.position = Vector2(24, GAME.y * 0.95 + 4)
	_caption.size = Vector2(GAME.x - 48, GAME.y * 0.05 - 8)
	_caption.add_theme_font_size_override("font_size", 30)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	view.add_child(_caption)
	MainScript.boot_save_path_override = "user://gameplay_v02_motion_%d.save" % Time.get_ticks_usec()
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await process_frame
	var app = _root.get_app_state()
	app.economy.wallet.credit("scrub_bucks", 2000)
	await process_frame
	await _run()
	_root.free()
	for suffix in ["", ".bak", ".tmp"]:
		var p: String = MainScript.boot_save_path_override + suffix
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	quit(0)

func _run() -> void:
	var stack = _root.get_modal_stack()
	var home = _root.get_home()
	_h = null
	await _say("Home with the owner-selected background (home_background.png)", 2.2)
	await _tap(home.get_region("PlayButton"))
	for _i in range(6):
		await _frame()
	_h = _root.get_gameplay_host()
	_prep_plan()
	var s = _h.get_screen()
	await _say("PLAY -> Level 1 starts at 1x (no timed entitlement yet)", 1.5)
	_auto_every = 10
	await _say("Scrubbots leave the slot connector and follow the railway", 4.0)
	_auto_every = 0
	await _tap(s.get_speed_button())
	await _say("2x without entitlement -> 2x Acquire", 1.6)
	await _tap(_h.get_speed_acquisition_popup().get_offer_button("timed_900"))
	_auto_every = 10
	await _say("15 MIN timed 2x bought: 2x on, countdown in the 2x box", 3.0)
	_auto_every = 0
	await _say("(Level 1 is fast-forwarded to WON for this recording)", 0.6)
	_drain(_h)
	for _i in range(20):
		await _frame()
	await _say("Results (win)", 2.0)
	var res = _root.get_results_screen()
	await _tap(res.get_primary_button())
	for _i in range(8):
		await _frame()
	_h = _root.get_gameplay_host()
	_prep_plan()
	s = _h.get_screen()
	_auto_every = 8
	await _say("Level 2 starts at 2x automatically - the timed countdown keeps running", 6.0)
	_auto_every = 0
	await _tap(s.get_speed_button())
	_auto_every = 8
	await _say("Manual 1x is free (no popup, no SB)", 3.0)
	_auto_every = 0
	await _tap(s.get_speed_button())
	_auto_every = 8
	await _say("...and back to 2x at no cost; bots hug the rail to the nearest exit", 6.0)
	_auto_every = 0

func _prep_plan() -> void:
	_plan_i = 0
	_h.get_runtime().set_process(true)
	_plan = SupplyPlanLoader.load_plan(_h.supply_plan_path)["plan"]["intendedColumnClicks"] if not String(_h.supply_plan_path).is_empty() else []

func _drain(h) -> void:
	var supply = h.get_supply()
	for _i in range(80000):
		if h.get_slots().rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					h.get_input_controller().activate_front(col)
					break
		h.get_runtime().tick(1.0)
		if h.get_completion().is_terminal():
			return

## Hold for `sec` of movie time while showing `text`; optionally keep tapping supply fronts.
func _say(text: String, sec: float) -> void:
	_step = text
	print("STEP %.2f %s" % [float(_frames) / FPS, text])
	var n := int(sec * FPS)
	for i in range(n):
		if _auto_every > 0 and i % _auto_every == 0 and _h != null and not _root.get_modal_stack().is_open():
			await _supply_tap()
		await _frame()

func _supply_tap() -> void:
	if _h.get_slots().rightmost_empty_index() == -1:
		return
	var col := -1
	if not _plan.is_empty():
		if _plan_i >= _plan.size():
			return
		col = int(_plan[_plan_i]) - 1
	else:
		for c in range(_h.get_supply().get_column_count()):
			if _h.get_supply().get_front(c) != null:
				col = c
				break
	if col < 0:
		return
	var panels: Array = _h.get_screen().get_supply_panel().get_column_row_panels(col)
	var hit = panels[0].get_node_or_null("HitArea") if not panels.is_empty() else null
	if hit == null:
		return
	var occ := _occupied()
	await _tap(hit)
	if _occupied() > occ:
		_plan_i += 1

func _occupied() -> int:
	return _h.get_slots().snapshot().filter(func(x): return bool(x.get("occupied", false))).size()

func _mouse(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = pos
	e.global_position = pos
	_sub.push_input(e)

func _tap(c: Control) -> void:
	var p := c.get_global_rect().get_center()
	_mouse(p, true)
	await _frame()
	_mouse(p, false)
	await _frame()

func _frame() -> void:
	var eco = _root.get_app_state().economy
	var sp := ""
	if _h != null and is_instance_valid(_h) and _h.get_speed_authority() != null:
		sp = "  |  live %s" % ("2x" if _h.get_speed_authority().is_2x() else "1x")
		if eco.speed.timed_seconds_remaining() > 0:
			sp += "  timed %s left" % _h.get_screen().format_remaining(eco.speed.timed_seconds_remaining())
	_caption.text = "%05.1fs  %s%s" % [float(_frames) / FPS, _step, sp]
	await process_frame
	_frames += 1
