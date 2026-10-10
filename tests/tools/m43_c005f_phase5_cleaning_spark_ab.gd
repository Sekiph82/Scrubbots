extends SceneTree
## M43-C005F-PHASE5 visual A/B evidence (NOT shipping) for SB-M43-C005F-011.
## Real app (main.tscn) Level 1 and a real laid-out 59x59 host, with the REAL installed Saltmire
## Spark plugin. Arm A = untouched production M31 cleaning FX; arm B = A + the evidence-only
## tests/support/cleaning_spark_ab_arm.gd (one FeedbackAdapter SMALL `spark` accent per ACCEPTED
## native cue, GameFeelFlow absent). Every pair uses the SAME deterministic gameplay: same level,
## same greedy activation, one DT gameplay tick per frame, frames paced at 60 FPS, captured at the
## SAME gameplay tick. Per scenario:
##   <size>_<scenario>_A.jpg / _B.jpg                full frame at the capture tick
##   <size>_<scenario>_board_strip.jpg               board crop, 4 frames (every 3rd), A row over B row
## Scenarios: level1_1x, level1_2x, level1_reduced_1x, dense59_2x (1080x2160 + 1536x2048).
## Needs a rendering driver:  godot --path . -s res://tests/tools/m43_c005f_phase5_cleaning_spark_ab.gd
## Output: coordination/sessions/M43-C005F-PHASE5/evidence/ (+ .gdignore) and A/B numbers printed.

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const AbArm = preload("res://tests/support/cleaning_spark_ab_arm.gd")
const OUT := "res://coordination/sessions/M43-C005F-PHASE5/evidence"
const SIZES := [Vector2i(1080, 2160), Vector2i(1536, 2048)]
const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const CIDS := ["C01", "C02", "C03", "C04", "C05", "C06"]
const DT := 1.0 / 60.0
## scenario -> [kind, 2x, reduced, warm-up gameplay ticks before the capture]
const SCENARIOS := {
	"level1_1x": ["level1", false, false, 420],
	"level1_2x": ["level1", true, false, 300],
	"level1_reduced_1x": ["level1", false, true, 420],
	"dense59_2x": ["dense59", true, false, 240],
}
const STRIP_FRAMES := 4
const STRIP_STEP := 3

var _sub: SubViewport
var _root = null
var _host = null
var _tmp: Array = []

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var gi := FileAccess.open(OUT + "/.gdignore", FileAccess.WRITE)
	gi.close()
	MainScript.boot_opening_override = 0
	Engine.max_fps = 60   # real-time pacing: one gameplay tick of DT per ~1/60 s frame
	_run.call_deferred()

func _run() -> void:
	await _scenario(SIZES[0], "level1_1x", false)   # warm-up (first-boot one-time work), not saved
	for size in SIZES:
		for name in SCENARIOS:
			var a: Dictionary = await _scenario(size, name, false)
			var b: Dictionary = await _scenario(size, name, true)
			var tag := "%dx%d_%s" % [size.x, size.y, name]
			_save(a["full"], tag + "_A")
			_save(b["full"], tag + "_B")
			_save(_strip(a["frames"], b["frames"]), tag + "_board_strip")
			print("AB %s | capture tick %d, identical clear sequence %s (%d clears) | A native accepted %d peak %d supp %d, frame %.2f ms | B native accepted %d peak %d supp %d, Spark req %d, peak owned %d, peak emitters %d, frame %.2f ms" % [tag,
				a["tick"], str(a["seq"] == b["seq"]), a["seq"].size(), a["native"], a["peak_native"], a["supp"], a["frame_ms"],
				b["native"], b["peak_native"], b["supp"], b["spark"], b["peak_owned"], b["peak_emit"], b["frame_ms"]])
	_shutdown()
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))
	quit(0)

## Boot, drive to the capture tick, grab the full frame + STRIP_FRAMES board crops.
func _scenario(size: Vector2i, name: String, with_b: bool) -> Dictionary:
	var spec: Array = SCENARIOS[name]
	if spec[0] == "level1":
		await _boot_app(size, bool(spec[2]))
	else:
		await _boot_59(size)
	var h = _host
	var arm = null
	var feel = null
	if with_b:
		feel = FeedbackAdapter.new()
		feel.bind(self, _root.get_app_state().effects if _root != null else null)
		feel.set_backends_for_test(null, get_root().get_node_or_null("Spark"))
		arm = AbArm.new()
		arm.attach(h, feel)
	if bool(spec[2]) and spec[0] != "level1":
		h.get_cleaning_fx().set_reduced_effects(true)
	var rt = h.get_runtime()
	rt.set_speed_2x(bool(spec[1]))
	var seq: Array = []
	var tick := [0]
	h.get_clearing_loop().authenticated_clear.connect(func(_o, t, _c, _a): seq.append([tick[0], t]))
	var peak := 0
	var peak_emit := 0
	var frames: Array = []
	var full: Image = null
	var t0 := 0
	var total := int(spec[3]) + STRIP_FRAMES * STRIP_STEP
	for i in range(total):
		_activate(h)
		rt.tick(DT)
		tick[0] += 1
		await process_frame
		peak = maxi(peak, h.get_cleaning_fx().get_active_count())
		peak_emit = maxi(peak_emit, _emitters())
		if i == int(spec[3]) - 60:
			t0 = Time.get_ticks_usec()
		var k := i - int(spec[3])
		if k >= 0 and k % STRIP_STEP == 0:
			await RenderingServer.frame_post_draw
			var img := _sub.get_texture().get_image()
			if full == null:
				full = img.duplicate()
			frames.append(img.get_region(_board_rect(h)))
	var out := {"tick": int(spec[3]), "seq": seq, "full": full, "frames": frames, "native": arm.native_accepted if arm else seq.size() - h.get_cleaning_fx().get_suppressed_count(),
		"peak_native": peak, "supp": h.get_cleaning_fx().get_suppressed_count(), "peak_emit": peak_emit,
		"frame_ms": float(Time.get_ticks_usec() - t0) / 1000.0 / float(60 + STRIP_FRAMES * STRIP_STEP),
		"spark": arm.spark_requests if arm else 0, "peak_owned": arm.peak_owned if arm else 0}
	if arm != null:
		arm.detach()
	return out

func _activate(h) -> void:
	if h.get_slots().rightmost_empty_index() == -1 or h.get_supply().is_exhausted():
		return
	for col in range(h.get_supply().get_column_count()):
		if h.get_input_controller().activate_front(col).get("ok", false):
			return

func _board_rect(h) -> Rect2i:
	var r: Rect2 = h.get_screen().get_board_region_rect()
	var t: Transform2D = h.get_screen().get_global_transform_with_canvas()
	var g := Rect2(t * r.position, r.size * t.get_scale())
	return Rect2i(g).intersection(Rect2i(Vector2i.ZERO, _sub.size))

## A row over B row, STRIP_FRAMES columns, 6 px gutters.
func _strip(a: Array, b: Array) -> Image:
	var w: int = a[0].get_width()
	var hgt: int = a[0].get_height()
	var g := 6
	var img := Image.create(w * a.size() + g * (a.size() - 1), hgt * 2 + g, false, a[0].get_format())
	img.fill(Color(1, 1, 1))
	for i in range(a.size()):
		img.blit_rect(a[i], Rect2i(Vector2i.ZERO, a[i].get_size()), Vector2i(i * (w + g), 0))
		img.blit_rect(b[i], Rect2i(Vector2i.ZERO, b[i].get_size()), Vector2i(i * (w + g), hgt + g))
	return img

func _emitters() -> int:
	return get_root().find_children("*", "Node2D", true, false).filter(func(n): return "_age" in n and "_parts" in n).size()

func _boot_app(size: Vector2i, reduced: bool) -> void:
	_shutdown()
	_mk_sub(size)
	var p := "user://c005f_p5_cap_%d.save" % Time.get_ticks_usec()
	_tmp.append(p)
	MainScript.boot_save_path_override = p
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	for _i in range(10):
		await process_frame
	_root.get_app_state().set_reduced_effects(reduced)
	_root.play_current_frontier()
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)   # the tool is the only gameplay clock (no wall-clock delta)
	for _i in range(6):
		await process_frame
	_host.get_runtime().reset_runtime()

func _boot_59(size: Vector2i) -> void:
	_shutdown()
	_mk_sub(size)
	var cells: Array = []
	for y in range(59):
		for x in range(59):
			cells.append(x * 6 / 59)
	var lvl := {"version": 1, "id": "c005f_p5_cap59", "name": "c005f_p5_cap59", "difficulty": "TEST", "width": 59, "height": 59, "palette": HEX, "cells": cells}
	var totals := {}
	for c in cells:
		totals[int(c)] = int(totals.get(int(c), 0)) + 1
	var batches: Array = []
	var more := true
	while more:
		more = false
		for c in range(6):
			if int(totals.get(c, 0)) > 0:
				var n := mini(30, int(totals[c]))
				totals[c] = int(totals[c]) - n
				batches.append({"batchId": "T%03d" % batches.size(), "cid": CIDS[c], "robots": n})
				more = true
	var cols := [[], [], []]
	for i in range(batches.size()):
		cols[i % 3].append(batches[i])
	var plan := {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "columnCount": 3, "visiblePreviewDepth": 3, "maxRobotsPerBatch": 30,
		"intendedColumnClicks": [], "columns": cols, "levelId": lvl["id"]}
	_host = ProductionGameplayHost.new()
	_host.auto_build = false
	_host.level_path = _write("lvl", JSON.stringify(lvl))
	_host.supply_plan_path = _write("plan", JSON.stringify(plan))
	_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub.add_child(_host)
	await process_frame
	await process_frame
	_host.build()
	await process_frame
	await process_frame
	_host.get_screen().relayout()
	await process_frame
	await process_frame
	_host.get_runtime().set_process(false)
	_host.get_runtime().reset_runtime()

func _mk_sub(size: Vector2i) -> void:
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)

func _write(tag: String, text: String) -> String:
	var p := "user://c005f_p5_cap_%s_%d.json" % [tag, Time.get_ticks_usec()]
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	elif _host != null and is_instance_valid(_host):
		_host.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null

func _save(img: Image, name: String) -> void:
	if img != null:
		img.save_jpg(ProjectSettings.globalize_path("%s/%s.jpg" % [OUT, name]), 0.9)
