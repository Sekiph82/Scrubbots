extends SceneTree
## SB-POLISH-003 — booster activation VFX (Tornado vortex, +1 Slot pop, Random dice flicker,
## Selector reticle) in the REAL app (main.tscn, 1080x2160 SubViewport, save override):
##   - every committed booster plays its own BoosterVfx effect, which ends by itself <= 0.9 s;
##   - +1 Slot from the booster row (request_booster) plays too, with the master crossfade;
##   - Tornado: the ghost image holds exactly the purged colour's cells; one ghost node only;
##   - the overlay never takes input; Reduced Effects -> no effect, same committed result;
##   - gameplay truth is the action's own (cells CLEARED, batch in its slot, 6 slots);
##   - SB-POLISH-012: a slot batch that finishes in real play pops (lift + burst + stars) every
##     time, with no node created; Retry resets and Reduced Effects never pop.
## Evidence frames: run WITHOUT --headless and pass `-- --evidence=<abs dir>`.
## Run: godot --headless --path . -s res://tests/sb_polish_003_booster_vfx.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const IDS := ["plus_one_slot", "random", "selector", "tornado"]

var _fail := 0
var _sub: SubViewport
var _root = null
var _host = null
var _vfx = null
var _evidence := ""
var _save := ""

func _initialize() -> void:
	await process_frame
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--evidence="):
			_evidence = String(a).trim_prefix("--evidence=")
	_save = "user://sb_polish_003_%d.save" % Time.get_ticks_usec()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _save
	MainScript.boot_opening_override = 0   # no opening video (windowed evidence runs)
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(14)
	var app = _root.get_app_state()
	for id in IDS:
		app.unlocks.cfg["unlocks"][id] = 1
		app.economy.boosters.add_charges(id, 2)
	_ok(_root.play_current_frontier()["ok"], "real gameplay host launched")
	await _frames(8)
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)   # hold the board still (no robot travel)
	_vfx = _host.get_screen().get_booster_vfx()
	_ok(_vfx != null and _vfx.mouse_filter == Control.MOUSE_FILTER_IGNORE and _vfx.get_child_count() == 1,
		"one BoosterVfx overlay, input-transparent, one child (Tornado ghost) only")
	await _plus_one()
	await _random()
	await _selector()
	await _tornado()
	await _reduced()
	await _batch_pop()
	_root.free()
	_sub.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save))
	print("SB-POLISH-003 BOOSTER VFX: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

func _plus_one() -> void:
	print("[+1 Slot from the booster row]")
	var scr = _host.get_screen()
	var r: Dictionary = _host.request_booster("plus_one_slot")
	var prev: TextureRect = scr.find_child("GameplayShellPrevious", true, false)
	var views: Array = scr.get_five_slot_strip().get_slot_views()
	_ok(r["ok"] and _host.get_slots().get_slot_count() == 6, "+1 Slot committed: 6 slots")
	_ok(_vfx.get_kind() == "plus_one_slot" and prev.visible and prev.texture.resource_path != scr.get_shell_texture_path() and views[5].modulate.a < 1.0,
		"pop effect playing, 5-slot master crossfading, sixth slot fading in")
	await _settle("plus_one_slot")
	_ok(not prev.visible and views[5].modulate.a == 1.0, "crossfade done, sixth slot fully shown")

func _random() -> void:
	print("[Random]")
	var r: Dictionary = _host.execute_booster("random")
	_ok(r["ok"], "Random committed %s" % str(r))
	_ok(_vfx.get_kind() == "random" and not (_vfx._d["tiles"] as Array).is_empty(), "dice flicker over the visible supply tiles")
	await _settle("random")

func _selector() -> void:
	print("[Selector]")
	var targets: Array = _host.booster_legality("selector")["targets"]
	_ok(not targets.is_empty(), "a solver-safe batch to pick")
	if targets.is_empty():
		return
	var bid = targets[0]["key"]
	var r: Dictionary = _host.execute_booster("selector", bid)
	var snap: Array = _host.get_slots().snapshot()
	_ok(r["ok"] and snap.any(func(s): return s.get("batch_id") == bid), "Selector committed: batch %s in a slot" % str(bid))
	_ok(_vfx.get_kind() == "selector" and _vfx._d["dst_rect"].size.x > 0.0, "reticle lock + fly effect playing")
	await _settle("selector")

func _tornado() -> void:
	print("[Tornado]")
	var board = _host.get_board()
	var colour: int = _host.get_booster_adapter().present_colors()[0]
	var n := 0
	for i in range(board.get_cell_count()):
		if board.get_cell_state(i) == BoardState.CellState.ACTIVE and board.get_color_id(i) == colour:
			n += 1
	var r: Dictionary = _host.execute_booster("tornado", colour)
	_ok(r["ok"] and not _host.get_booster_adapter().present_colors().has(colour), "Tornado committed: colour %d gone from the board" % colour)
	var img: Image = _vfx._d["ghost"]
	var lit := 0
	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if img.get_pixel(x, y).a > 0.0:
				lit += 1
	_ok(_vfx.get_kind() == "tornado" and lit == n and n > 0, "vortex playing; ghost holds exactly the %d purged cells (%d)" % [n, lit])
	_ok((_vfx._d["samples"] as Array).size() <= 48 and _vfx.get_child_count() == 1, "<= 48 spiral samples drawn, no per-cell nodes")
	await _settle("tornado")

func _reduced() -> void:
	print("[Reduced Effects]")
	_root.get_app_state().set_reduced_effects(true)
	var colours: Array = _host.get_booster_adapter().present_colors()
	var r: Dictionary = _host.execute_booster("tornado", colours[0])
	_ok(r["ok"] and not _vfx.is_playing(), "Reduced: Tornado committed, no VFX")
	_root.get_app_state().set_reduced_effects(false)

func _batch_pop() -> void:
	print("[SB-POLISH-012 batch complete pop]")
	var scr = _host.get_screen()
	var real: Array = _host.get_slots().snapshot()
	var fake: Array = real.duplicate(true)
	fake[0] = {"state": "ACTIVE", "occupied": true, "batch_id": "X", "color_id": 0, "capacity": 0}
	scr.refresh_slot_snapshot(fake)
	scr.refresh_slot_snapshot(real, false)
	_ok(_vfx.pop_count() == 0, "Retry-style reset (batch_fx false): no pop")
	_root.get_app_state().set_reduced_effects(true)
	scr.refresh_slot_snapshot(fake)
	scr.refresh_slot_snapshot(real)
	_ok(_vfx.pop_count() == 0, "Reduced Effects: no pop")
	_root.get_app_state().set_reduced_effects(false)
	# Real play: send every column's front batch (Random's order varies per run) and let the
	# robots work until a slot empties.
	var nodes0: int = get_node_count()
	for c in range(scr.get_supply_panel().get_column_count()):
		scr.get_supply_panel().front_batch_activated.emit(c)
		await _frames(2)
	_host.get_runtime().set_process(true)
	var pops := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000 and pops == 0:
		await process_frame
		pops = _vfx.pop_count()
	_ok(pops >= 1, "a finished slot batch popped in real play (%d)" % pops)
	if _evidence != "" and pops >= 1:
		_host.get_runtime().set_process(false)
		_vfx.set_process(false)
		for k in range(3):
			var p: Dictionary = _vfx._pops[0]
			p["t"] = [0.1, 0.24, 0.36][k]
			_vfx.queue_redraw()
			await _frames(2)
			_sub.get_texture().get_image().save_png(_evidence.path_join("batch_pop_%d.png" % (k + 1)))
		_vfx.set_process(true)
		_host.get_runtime().set_process(true)
	var t1 := Time.get_ticks_msec()
	while _vfx.pop_count() > 0 and Time.get_ticks_msec() - t1 < 2000:
		await process_frame
	_ok(_vfx.pop_count() == 0 and (Time.get_ticks_msec() - t1 <= 800 or _evidence != ""), "pop ended by itself (%d ms)" % (Time.get_ticks_msec() - t1))
	_ok(_vfx.get_child_count() == 1, "no nodes created by pops (overlay children %d, tree nodes %d -> %d)" % [_vfx.get_child_count(), nodes0, get_node_count()])
	_host.get_runtime().set_process(false)

## Effect ends by itself within 0.9 s. Evidence runs instead step the effect to 4 fixed moments
## (PNG saves are slower than a frame) and save one 1080x2160 still at each.
func _settle(id: String) -> void:
	if _evidence != "":
		_vfx.set_process(false)
		for k in range(4):
			_vfx._process([0.12, 0.3, 0.5, 0.7][k] - _vfx._t)
			await _frames(2)
			_sub.get_texture().get_image().save_png(_evidence.path_join("%s_%d.png" % [id, k + 1]))
		_vfx.set_process(true)
	var t0 := Time.get_ticks_msec()
	while _vfx.is_playing() and Time.get_ticks_msec() - t0 < 2000:
		await process_frame
	var ms := Time.get_ticks_msec() - t0
	_ok(not _vfx.is_playing() and (ms <= 1200 or _evidence != ""), "%s effect ended by itself (%d ms)" % [id, ms])

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
