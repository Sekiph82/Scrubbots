extends SceneTree
## M28-C002-C003 motion evidence (SB-M28-C002-019): one continuous real-runtime Gameplay V02
## session recorded with Godot's built-in Movie Maker (no extra dependency). Real app root,
## real runtime processing at the fixed movie frame rate, every interaction a ROUTED pointer
## tap (SubViewport.push_input) on the visible control: supply fronts (owner plan order),
## Pause, booster row, popup chips / X / SB CTA, 2x box and 2x offers. The wall clock the
## economy reads is the movie clock, so the timed-2x countdown runs in video time.
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
	app.progression.debug_set_current_level(2)
	var w = app.economy.wallet
	if w.scrub_bucks() < 2000:
		w.credit("scrub_bucks", 2000 - w.scrub_bucks())
	_root.play_current_frontier()
	await process_frame
	_h = _root.get_gameplay_host()
	_plan = SupplyPlanLoader.load_plan(_h.supply_plan_path)["plan"]["intendedColumnClicks"]
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
	var s = _h.get_screen()
	var stack = _root.get_modal_stack()
	await _say("Fresh Level 2 - Gameplay V02 (5 slots, 3-column supply)", 1.8)
	_auto_every = 12
	await _say("Tapping supply fronts (owner plan order): Scrubbots dispatch and clean", 4.5)
	_auto_every = 0
	await _tap(s.get_pause_button())
	await _say("Pause control -> canonical Pause popup; gameplay held", 2.2)
	await _tap(_h.get_pause_popup().get_action_button("resume"))
	_auto_every = 14
	await _say("RESUME -> cleaning continues", 2.0)
	_auto_every = 0
	await _tap(s.get_booster_button("tornado"))
	await _say("Tornado with 0 charges -> Booster Acquire (nothing spent)", 2.0)
	var f = stack.top().find_child("Targets", true, false)
	await _tap(f.get_child(mini(1, f.get_child_count() - 1)))
	await _say("Owner-approved picker: choose a colour", 1.6)
	await _tap(stack.top().get_close_button())
	await _say("Close X -> no charge, no SB, no gameplay change", 1.6)
	await _tap(s.get_booster_button("plus_one_slot"))
	await _say("+1 Slot with 0 charges -> Booster Acquire", 1.8)
	await _tap(stack.top().get_action_button("sb"))
	_auto_every = 10
	await _say("USE 500 SB -> temporary sixth slot (solver-safe BoosterService)", 3.5)
	_auto_every = 0
	await _tap(s.get_speed_button())
	await _say("2x without entitlement -> 2x Acquire (200 / 300 / 500 / 750 SB)", 2.4)
	await _tap(_h.get_speed_acquisition_popup().get_offer_button("timed_900"))
	_auto_every = 12
	await _say("15 MIN bought (300 SB): 2x on, live countdown in the 2x box", 4.0)
	_auto_every = 0
	await _tap(s.get_speed_button())
	await _say("Entitled: free switch to 1x", 1.6)
	await _tap(s.get_speed_button())
	_auto_every = 12
	await _say("...and back to 2x, no charge", 3.0)
	_auto_every = 0

## Hold for `sec` of movie time while showing `text`; optionally keep tapping supply fronts.
func _say(text: String, sec: float) -> void:
	_step = text
	print("STEP %.2f %s" % [float(_frames) / FPS, text])
	var n := int(sec * FPS)
	for i in range(n):
		if _auto_every > 0 and i % _auto_every == 0 and not _root.get_modal_stack().is_open():
			await _supply_tap()
		await _frame()

func _supply_tap() -> void:
	if _plan_i >= _plan.size() or _h.get_slots().rightmost_empty_index() == -1:
		return
	var col := int(_plan[_plan_i]) - 1
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
	_caption.text = "%05.1fs  %s   |  SB %s" % [float(_frames) / FPS, _step, UiText.num(eco.wallet.scrub_bucks())]
	await process_frame
	_frames += 1
