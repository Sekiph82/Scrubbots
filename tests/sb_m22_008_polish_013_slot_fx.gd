extends SceneTree
## SB-M22-008 WAITING slot pulse + SB-POLISH-013 finished-batch pop (presentation only):
##   - only an occupied WAITING slot pulses (alpha 1.0..0.94, 1.8 s cosine, non-strobing); ACTIVE /
##     EMPTY never; reachable (ACTIVE), release (EMPTY) and reuse end it at once; colour / count stay;
##     pause and Reduced Effects hold it static; 5 and 6 slots; no input captured;
##   - the pop: presets A 0.95 / B 1.25 / C 1.60 s (default, owner 2026-11-06); LIFT -> BURST -> STARS strictly in
##     order; the lifted tile's bottom edge clears the former slot top by >= 0.25 x slot height;
##     ease-in-out lift with no jump at t = 0; overlapping pops bounded; Reduced Effects -> no pop;
##     the slot is EMPTY the moment the batch finishes (no gameplay delay).
## Run: godot --headless --path . -s res://tests/sb_m22_008_polish_013_slot_fx.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const FiveSlotStrip = preload("res://scripts/ui/five_slot_strip.gd")
const BatchSlotView = preload("res://scripts/ui/batch_slot_view.gd")
const BoosterVfx = preload("res://scripts/ui/feel/booster_vfx.gd")

var _fail := 0

func _initialize() -> void:
	await process_frame
	await _pulse_strip()
	_pop_unit()
	await _real_app()
	print("SB-M22-008 + SB-POLISH-013 SLOT FX: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

func _snap(state: String, bid: String = "b0", cid: int = 1) -> Dictionary:
	if state == "EMPTY":
		return {"state": "EMPTY", "occupied": false}
	return {"state": state, "occupied": true, "batch_id": bid, "color_id": cid, "remaining_to_clear": 9, "committed": 2, "capacity": 7}

func _pulse_strip() -> void:
	print("[SB-M22-008 WAITING pulse]")
	var cols := [Color.RED, Color.GREEN, Color.BLUE]
	var strip = FiveSlotStrip.new()
	strip.size = Vector2(600, 120)
	get_root().add_child(strip)
	await process_frame
	strip.bind_snapshots([_snap("WAITING"), _snap("ACTIVE", "b1"), _snap("EMPTY"), _snap("EMPTY"), _snap("EMPTY")], cols)
	var v: Array = strip.get_slot_views()
	_ok(v.size() == 5 and v[0].is_pulsing() and v[0].is_processing() and not v[1].is_pulsing() and not v[2].is_pulsing() and not v[1].is_processing(),
		"5 slots: only the WAITING slot pulses (ACTIVE / EMPTY static)")
	var tile = v[0].get_tile()
	var text: String = v[0].get_count_label_text()
	var lo := 1.0
	var max_step := 0.0
	var prev := 1.0
	for _i in range(120):   # 2 s at 60 fps
		v[0]._process(1.0 / 60.0)
		lo = minf(lo, tile.modulate.a)
		max_step = maxf(max_step, absf(tile.modulate.a - prev))
		prev = tile.modulate.a
	_ok(is_equal_approx(lo, 1.0 - BatchSlotView.PULSE_DEPTH) and BatchSlotView.PULSE_DEPTH <= 0.08, "amplitude: alpha dips to %.3f (<= 8%%)" % lo)
	_ok(BatchSlotView.PULSE_PERIOD_S >= 1.6 and BatchSlotView.PULSE_PERIOD_S <= 2.0 and max_step < 0.005, "period %.1f s, non-strobing (max %.4f alpha per frame)" % [BatchSlotView.PULSE_PERIOD_S, max_step])
	v[0]._pulse_t = 0.0
	v[0]._process(BatchSlotView.PULSE_PERIOD_S * 0.5)
	_ok(is_equal_approx(tile.modulate.a, 1.0 - BatchSlotView.PULSE_DEPTH), "trough at half period")
	_ok(v[0].get_count_label_text() == text and v[0].get_state() == "WAITING" and v[0].mouse_filter == Control.MOUSE_FILTER_IGNORE and tile.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"same count / state while pulsing; no input captured")
	# Reachable again -> ACTIVE: the pulse ends at once.
	strip.bind_snapshots([_snap("ACTIVE"), _snap("ACTIVE", "b1"), _snap("EMPTY"), _snap("EMPTY"), _snap("EMPTY")], cols)
	_ok(not v[0].is_pulsing() and not v[0].is_processing() and tile.modulate.a == 1.0, "reachable (ACTIVE): pulse ends immediately, full alpha")
	# WAITING again, then released (EMPTY), then reused by a new batch.
	strip.bind_snapshots([_snap("WAITING"), _snap("ACTIVE", "b1"), _snap("EMPTY"), _snap("EMPTY"), _snap("EMPTY")], cols)
	v[0]._process(0.7)
	strip.bind_snapshots([_snap("EMPTY"), _snap("ACTIVE", "b1"), _snap("EMPTY"), _snap("EMPTY"), _snap("EMPTY")], cols)
	_ok(not v[0].is_pulsing() and tile.modulate.a == 1.0 and v[0]._pulse_t == 0.0, "release (EMPTY): pulse ends, phase reset")
	strip.bind_snapshots([_snap("ACTIVE", "b9", 2), _snap("ACTIVE", "b1"), _snap("EMPTY"), _snap("EMPTY"), _snap("EMPTY")], cols)
	_ok(not v[0].is_pulsing() and tile.modulate.a == 1.0, "reuse by a new ACTIVE batch: no pulse")
	strip.bind_snapshots([_snap("WAITING", "b9", 2), _snap("ACTIVE", "b1"), _snap("EMPTY"), _snap("EMPTY"), _snap("EMPTY")], cols)
	v[0]._process(1.0 / 60.0)
	_ok(v[0].is_pulsing() and tile.modulate.a > 0.999, "reused batch WAITING: pulse starts from full alpha (no jump)")
	# Pause / Reduced Effects -> static; resume -> pulses again.
	v[0]._process(0.6)
	strip.set_waiting_pulse_allowed(false)
	_ok(not v[0].is_pulsing() and not v[0].is_processing() and tile.modulate.a == 1.0, "paused / Reduced: static full alpha, no loop")
	strip.set_waiting_pulse_allowed(true)
	_ok(v[0].is_pulsing() and v[0].is_processing(), "resume: WAITING pulses again")
	# Six slots: a slot added later follows the current allowance.
	strip.set_waiting_pulse_allowed(false)
	strip.set_capacity(6)
	strip.bind_snapshots([_snap("ACTIVE"), _snap("EMPTY"), _snap("EMPTY"), _snap("EMPTY"), _snap("EMPTY"), _snap("WAITING", "b6")], cols)
	v = strip.get_slot_views()
	_ok(v.size() == 6 and not v[5].is_pulsing(), "6 slots: the sixth (WAITING) is static while disallowed")
	strip.set_waiting_pulse_allowed(true)
	_ok(v[5].is_pulsing() and not v[0].is_pulsing(), "6 slots: the sixth WAITING slot pulses once allowed")
	strip.free()

func _pop_unit() -> void:
	print("[SB-POLISH-013 pop timing / geometry / order]")
	var fx = BoosterVfx.new()
	get_root().add_child(fx)
	_ok(is_equal_approx(fx.pop_duration(), 1.60), "default preset C = 1.60 s (owner pick 2026-11-06)")
	var want := {"A": 0.95, "B": 1.25, "C": 1.60}
	var r := Rect2(200, 1500, 120, 140)
	for id in ["A", "B", "C"]:
		_ok(fx.set_pop_preset(id) and is_equal_approx(fx.pop_duration(), want[id]), "preset %s total %.2f s" % [id, fx.pop_duration()])
		var tm: Dictionary = BoosterVfx.POP_PRESETS[id]
		var lift: float = tm["lift"]
		var f0: Dictionary = fx.pop_frame(r, 0.0)
		_ok(f0["tile"] == r and f0["phase"] == "LIFT", "%s: t=0 tile exactly on the slot (no jump)" % id)
		var top: Dictionary = fx.pop_frame(r, lift)
		var gap: float = r.position.y - (top["tile"] as Rect2).end.y
		_ok(gap >= 0.25 * r.size.y - 0.001 and (top["tile"] as Rect2).size == r.size, "%s: lifted bottom edge %.1f px above the slot top (>= %.1f)" % [id, gap, 0.25 * r.size.y])
		var early: float = r.position.y - (fx.pop_frame(r, lift * 0.1)["tile"] as Rect2).position.y
		var late: float = r.position.y - (fx.pop_frame(r, lift * 0.9)["tile"] as Rect2).position.y
		var full: float = r.size.y * 1.25
		_ok(early < full * 0.1 and late > full * 0.9, "%s: lift eases in and out" % id)
		var order: Array = []
		var ok_order := true
		var t := 0.0
		while t <= fx.pop_duration() + 0.02:
			var f: Dictionary = fx.pop_frame(r, t)
			if order.is_empty() or order[-1] != f["phase"]:
				order.append(f["phase"])
			if f["phase"] == "LIFT" and (f["burst"] > 0.0 or f["stars"] > 0.0):
				ok_order = false
			if f["phase"] == "BURST" and f["stars"] > 0.0:
				ok_order = false
			t += 0.01
		_ok(ok_order and order == ["LIFT", "BURST", "STARS", "DONE"], "%s: LIFT -> BURST -> STARS -> DONE, no overlap (%s)" % [id, str(order)])
	fx.set_pop_preset("B")
	_ok(not fx.set_pop_preset("Z") and is_equal_approx(fx.pop_duration(), 1.25), "unknown preset rejected, B kept")
	for i in range(10):
		fx.pop_batch(Rect2(i * 10, 0, 10, 10), Color.RED)
	_ok(fx.pop_count() == BoosterVfx.POP_MAX, "overlapping pops bounded to %d" % BoosterVfx.POP_MAX)
	fx._process(1.24)
	_ok(fx.pop_count() == BoosterVfx.POP_MAX, "pops still alive at 1.24 s")
	fx._process(0.02)
	_ok(fx.pop_count() == 0 and not fx.is_processing(), "pops gone after 1.25 s; overlay idle")
	fx.pop_batch(r, Color.RED)
	fx.clear_pops()
	_ok(fx.pop_count() == 0 and fx.get_child_count() == 1, "clear_pops empties; no nodes made")
	fx.free()

func _real_app() -> void:
	print("[real GameplayScreen: gating, pop source rect, immediate release]")
	var save := "user://sb_m22_008_%d.save" % Time.get_ticks_usec()
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	MainScript.boot_save_path_override = save
	MainScript.boot_opening_override = 0
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(14)
	_ok(root.play_current_frontier()["ok"], "real gameplay host launched")
	await _frames(8)
	var host = root.get_gameplay_host()
	host.get_runtime().set_process(false)
	var scr = host.get_screen()
	var vfx = scr.get_booster_vfx()
	var views: Array = scr.get_five_slot_strip().get_slot_views()
	var real: Array = host.get_slots().snapshot()
	var fake: Array = real.duplicate(true)
	fake[0] = {"state": "WAITING", "occupied": true, "batch_id": "X", "color_id": 0, "remaining_to_clear": 3, "committed": 0, "capacity": 3}
	scr.refresh_slot_snapshot(fake, false)
	_ok(views[0].is_pulsing(), "WAITING snapshot from the runtime sync pulses")
	scr.set_paused(true)
	_ok(not views[0].is_pulsing(), "screen paused: static")
	scr.set_paused(false)
	_ok(views[0].is_pulsing(), "screen resumed: pulses")
	root.get_app_state().set_reduced_effects(true)
	_ok(not views[0].is_pulsing(), "Reduced Effects (live setting): static")
	scr.refresh_slot_snapshot(real)
	_ok(vfx.pop_count() == 0, "Reduced Effects: finished batch makes no pop")
	scr.refresh_slot_snapshot(fake, false)
	root.get_app_state().set_reduced_effects(false)
	_ok(views[0].is_pulsing(), "Reduced off: pulses")
	var tile_rect: Rect2 = views[0].get_tile().get_global_rect()
	scr.refresh_slot_snapshot(real)
	_ok(vfx.pop_count() == 1 and vfx._pops[0]["rect"] == tile_rect, "finish: one pop from the slot tile's own rect")
	_ok(not views[0].is_occupied_view() and not views[0].is_pulsing(), "slot released at once (EMPTY, no pulse) while the pop plays")
	root.get_app_state().set_reduced_effects(true)
	_ok(vfx.pop_count() == 0, "Reduced Effects switched on mid-pop: pop removed")
	root.get_app_state().set_reduced_effects(false)
	root.free()
	sub.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
