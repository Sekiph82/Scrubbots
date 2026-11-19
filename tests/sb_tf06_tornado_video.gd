extends SceneTree
## SB-TF-06 (owner 2026-11-18) Tornado booster video: the owner's black-background tornado clip
## plays additively from the Tornado button to the board centre (track-mapped on any viewport),
## the purged colour's real cells spiral into the moving tornado, then a code spin-collapse and
## the burst; the vector arms / rings are gone; Reduced Effects -> no video; a missing stream
## runs code-only; the purge result is identical with or without the effect.
## Asset / mapping cases on the real GameplayScreen (sb_tf04 fixtures); play / truth / timeline /
## Reduced / failure / performance cases on the real main.tscn host (save override).
## Evidence (frame strip frames + perf): run WITHOUT --headless, `-- --evidence=<abs dir>`.
##
## Run: godot --headless --path . -s res://tests/sb_tf06_tornado_video.gd

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoosterVfx = preload("res://scripts/ui/feel/booster_vfx.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const PaletteColors = preload("res://scripts/data/palette_colors.gd")

const VIDEO_DIR := "res://assets/ui/final/boosters/videos/"
const VIEWPORTS := [Vector2i(720, 1280), Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532),
	Vector2i(1080, 2400), Vector2i(1290, 2796), Vector2i(1440, 3200), Vector2i(1536, 2048)]
const PERF_SRC := """extends "res://scripts/ui/feel/booster_vfx.gd"
var frame_us := {}
func _process(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	super(delta)
	_add(Time.get_ticks_usec() - t0)
func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	super()
	_add(Time.get_ticks_usec() - t0)
func _add(us: int) -> void:
	var f := Engine.get_process_frames()
	frame_us[f] = int(frame_us.get(f, 0)) + us
"""

var EXPECTED_CASES := ["asset", "provenance", "black_level", "track", "mapping", "real_play", "cells",
	"truth", "timeline", "reduced", "failure_path", "performance"]

var _fail := 0
var _completed: Dictionary = {}
var _evidence := ""
var _save := ""
var _sub: SubViewport
var _root = null
var _host = null
var _vfx = null
var _perf_line := ""

func _initialize() -> void:
	await process_frame
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--evidence="):
			_evidence = String(a).trim_prefix("--evidence=")
	_asset()
	_provenance()
	await _black_level()
	_track()
	await _mapping()
	await _boot()
	await _real_play()
	await _cells()
	await _truth()
	await _timeline()
	await _reduced()
	await _failure_path()
	await _performance()
	if _evidence != "":
		await _evidence_frames()
	_root.free()
	_sub.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save))
	_done()

# ------------------------------------------------------------------ helpers ----

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _players(n: Node) -> Array:
	return n.find_children("*", "VideoStreamPlayer", true, false)

func _clip_len(stream: VideoStream) -> float:
	var v := VideoStreamPlayer.new()
	v.stream = stream
	get_root().add_child(v)
	v.play()
	var len := v.get_stream_length() if v.is_playing() else -1.0
	v.stop()
	v.free()
	return len

func _boot() -> void:
	_save = "user://sb_tf06_%d.save" % Time.get_ticks_usec()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = _save
	MainScript.boot_opening_override = 0
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(14)
	var app = _root.get_app_state()
	app.unlocks.cfg["unlocks"]["tornado"] = 1
	app.economy.boosters.add_charges("tornado", 20)
	if _evidence != "":
		app.progression.debug_set_current_level(2)   # evidence: the apple, 296 orange-red cells
	_ok(_root.play_current_frontier()["ok"], "real gameplay host launched")
	await _frames(8)
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)   # hold the board still (no robot travel)
	_vfx = _host.get_screen().get_booster_vfx()

## Fresh attempt (same level, same deterministic supply), Reduced off, overlay idle.
func _fresh() -> void:
	_vfx.stop()
	_vfx.set_process(true)
	_root.get_app_state().set_reduced_effects(false)
	_ok(_host.retry(), "retry restored a fresh attempt")
	_host.get_runtime().set_process(false)
	await _frames(3)

func _count(cid: int) -> int:
	var b = _host.get_board()
	var n := 0
	for i in range(b.get_cell_count()):
		if b.get_cell_state(i) == BoardState.CellState.ACTIVE and b.get_color_id(i) == cid:
			n += 1
	return n

## The present colour with the most ACTIVE cells (`skip` excluded).
func _big_colour(skip: int = -1) -> int:
	var best := -1
	for c in _host.get_booster_adapter().present_colors():
		if int(c) != skip and (best < 0 or _count(int(c)) > _count(best)):
			best = int(c)
	return best

func _canon(cid: int) -> Color:
	return PaletteColors.parse(_host.get_level().palette).colors[cid]

func _run_out() -> void:
	while _vfx.is_playing():
		_vfx._process(0.05)
		await process_frame

# ------------------------------------------------------------------ cases ----

func _asset() -> void:
	print("[asset]")
	var path := VIDEO_DIR + "tornado_additive.ogv"
	var bytes := FileAccess.get_file_as_bytes(path)
	var stream = load(path)
	var len := _clip_len(stream) if stream is VideoStreamTheora else -1.0
	var txt := bytes.get_string_from_ascii()
	_ok(bytes.size() > 0 and bytes.size() <= 2000000, "tornado_additive.ogv %.1f KB (hard limit 2,000,000 B, target <= 1.5 MB)" % (bytes.size() / 1024.0))
	_ok(stream is VideoStreamTheora and len >= 1.3 and len <= 2.2, "Theora stream opens, length %.3f s in 1.3..2.2" % len)
	_ok(txt.find("vorbis") < 0 and txt.find("OpusHead") < 0, "no audio stream (no Vorbis / Opus header in the Ogg)")
	_completed["asset"] = true

func _provenance() -> void:
	print("[provenance + manifest]")
	var sha := FileAccess.get_sha256(VIDEO_DIR + "tornado_additive.ogv")
	var prov := FileAccess.get_file_as_string(VIDEO_DIR + "PROVENANCE.md")
	_ok(prov.find("`tornado_additive.ogv` sha256 `%s`" % sha) >= 0 and prov.find("Blue_tornado_spinning_and_growing_6bafdac1.mp4") >= 0,
		"PROVENANCE.md records the master and the .ogv sha256 %s" % sha.left(16))
	var man = JSON.parse_string(FileAccess.get_file_as_string("res://ASSET_GENERATION_MANIFEST.json"))
	var e = man.get("canonical_references", {}).get("tornado_booster_video_v1") if man is Dictionary else null
	_ok(e is Dictionary and e.get("sha256", "") == sha and e.get("repository_path", "") == "assets/ui/final/boosters/videos/tornado_additive.ogv",
		"ASSET_GENERATION_MANIFEST.json tornado_booster_video_v1 sha256 == file")
	_completed["provenance"] = true

func _black_level() -> void:
	print("[black level]")
	var sub := SubViewport.new()
	sub.size = Vector2i(544, 1008)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var v := VideoStreamPlayer.new()
	v.stream = BoosterVfx.tornado_video
	sub.add_child(v)
	v.play()
	await _frames(6)
	var tex := v.get_video_texture()
	var img: Image = tex.get_image() if tex != null else null
	if img != null and not img.is_empty():
		var worst := 0.0
		for p in [Vector2i(0, 0), Vector2i(img.get_width() - 1, 0), Vector2i(0, img.get_height() - 1), Vector2i(img.get_width() - 1, img.get_height() - 1)]:
			var c := img.get_pixelv(p)
			worst = maxf(worst, maxf(c.r, maxf(c.g, c.b)))
		_ok(worst <= 4.0 / 255.0 + 0.0001, "decoded frame (%dx%d) corners max %d/255 <= 4" % [img.get_width(), img.get_height(), int(round(worst * 255.0))])
	else:
		var prov := FileAccess.get_file_as_string(VIDEO_DIR + "PROVENANCE.md")
		var re := RegEx.create_from_string("decoded corner pixels max (\\d+)/255 over every frame")
		var m := re.search(prov)
		_ok(m != null and int(m.get_string(1)) <= 4,
			"no frame readback on this driver: build-time decode check in PROVENANCE.md says corners max %s/255 <= 4" % (m.get_string(1) if m != null else "?"))
	v.stop()
	sub.free()
	_completed["black_level"] = true

func _track() -> void:
	print("[track]")
	var tr: Array = BoosterVfx.TORNADO_TRACK
	var ordered := true
	for i in range(1, tr.size()):
		ordered = ordered and int(tr[i][0]) > int(tr[i - 1][0])
	var clip_frames := int(round(BoosterVfx.TORNADO_CLIP_S * BoosterVfx.TORNADO_FPS))
	_ok(tr.size() >= 12 and ordered and int(tr[0][0]) == 0 and int(tr[-1][0]) == clip_frames - 1,
		"%d keys, frames ordered 0..%d (first = button start, last = end of travel)" % [tr.size(), clip_frames - 1])
	_ok(float(tr[-1][3]) > 3.0 * float(tr[0][3]) and float(tr[-1][2]) < float(tr[0][2]),
		"diameter %.0f -> %.0f (> 3x), travels up %.0f px" % [tr[0][3], tr[-1][3], float(tr[0][2]) - float(tr[-1][2])])
	_completed["track"] = true

func _mapping() -> void:
	print("[mapping x %d viewports]" % VIEWPORTS.size())
	var sub := SubViewport.new()
	sub.size = VIEWPORTS[0]
	sub.disable_3d = true
	get_root().add_child(sub)
	var lvl = BoardDebugFixtures.make_level(24, 24)
	var scr = GameplayScreen.new()
	scr.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(scr)
	scr.configure(BoardDebugFixtures.make_board(24, 24), lvl.palette, [], BatchSupplyGenerator.generate(lvl, 4, 3, 5).player_snapshot())
	var vfx = scr.get_booster_vfx()
	vfx.set_process(false)
	var tr: Array = BoosterVfx.TORNADO_TRACK
	var k0 := Vector2(tr[0][1], tr[0][2])
	var kn := Vector2(tr[-1][1], tr[-1][2])
	for vp in VIEWPORTS:
		sub.size = vp
		await _frames(3)
		vfx.play("tornado", scr.capture_booster_fx("tornado", 0))
		var v: VideoStreamPlayer = vfx.get_video_player()
		var btn: Vector2 = scr.get_booster_button("tornado").get_global_rect().get_center()
		var brd: Vector2 = scr.get_board_rect().get_center()
		var p0: Vector2 = v.get_global_transform() * k0 if v != null else Vector2.INF
		vfx._process(vfx._clip)   # end of the clip: last key, collapse not started
		var pn: Vector2 = v.get_global_transform() * kn if v != null else Vector2.INF
		var sc: Vector2 = vfx._map.get("scale", Vector2.ONE)
		var ratio: float = maxf(sc.x, sc.y) / minf(sc.x, sc.y)
		_ok(v != null and p0.distance_to(btn) <= 1.5 and pn.distance_to(brd) <= 1.5 and ratio <= 1.25 + 1e-5 and absf(v.rotation) < 0.0001,
			"%dx%d: key 0 -> %s (button %s, %.2f px), last key -> %s (board %s, %.2f px), s=(%.3f, %.3f) ratio %.3f" %
			[vp.x, vp.y, str(p0.round()), str(btn.round()), p0.distance_to(btn), str(pn.round()), str(brd.round()), pn.distance_to(brd), sc.x, sc.y, ratio])
		vfx.stop()
	scr.free()
	sub.free()
	_completed["mapping"] = true

func _real_play() -> void:
	print("[real play]")
	var scr = _host.get_screen()
	var colour := _big_colour()
	var r: Dictionary = _host.execute_booster("tornado", colour)
	var ps := _players(scr)
	var v: VideoStreamPlayer = ps[0] if ps.size() == 1 else null
	_ok(r["ok"] and _vfx.get_kind() == "tornado" and v != null and v == _vfx.get_video_player() and v.is_playing(),
		"Tornado committed (colour %d), exactly one VideoStreamPlayer playing (%d), kind %s" % [colour, ps.size(), _vfx.get_kind()])
	_ok(v != null and v.material is CanvasItemMaterial and (v.material as CanvasItemMaterial).blend_mode == CanvasItemMaterial.BLEND_MODE_ADD
		and v.mouse_filter == Control.MOUSE_FILTER_IGNORE and _vfx.mouse_filter == Control.MOUSE_FILTER_IGNORE and v.get_parent() == _vfx,
		"additive CanvasItemMaterial, mouse ignored, child of the input-transparent overlay")
	var src := FileAccess.get_file_as_string("res://scripts/ui/feel/booster_vfx.gd")
	var a := src.find("func _draw_tornado(")
	var body := src.substr(a, src.find("\nfunc ", a + 1) - a)
	_ok(a >= 0 and body.find("draw_polyline") < 0 and body.find("draw_arc") < 0 and src.find("VORTEX") < 0,
		"old vector arms / rings gone (_draw_tornado has no draw_polyline / draw_arc)")
	await _run_out()
	_completed["real_play"] = true

func _cells() -> void:
	print("[cells: every purged cell, its own colour]")
	await _fresh()
	var seen: Array = []
	for _i in range(2):
		var colour := _big_colour(seen[0] if not seen.is_empty() else -1)
		var n := _count(colour)
		var nodes0 := get_node_count()
		var r: Dictionary = _host.execute_booster("tornado", colour)
		var img: Image = _vfx._d.get("ghost")
		var want := _canon(colour)
		var lit := 0
		var exact := true
		for y in range(img.get_height() if img != null else 0):
			for x in range(img.get_width()):
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					lit += 1
					exact = exact and absf(c.r - want.r) < 0.003 and absf(c.g - want.g) < 0.003 and absf(c.b - want.b) < 0.003 and c.a == 1.0
		_ok(r["ok"] and n > 0 and lit == n and exact, "colour %d (%s): ghost holds exactly the %d purged cells (%d lit), every lit pixel the canonical colour" % [colour, want.to_html(false), n, lit])
		_ok((_vfx._d["samples"] as Array).size() <= 48 and _vfx.get_child_count() <= 2 and get_node_count() - nodes0 <= 1,
			"%d samples <= 48, overlay children %d <= 2, +%d nodes (the one player; no per-cell nodes)" % [(_vfx._d["samples"] as Array).size(), _vfx.get_child_count(), get_node_count() - nodes0])
		seen.append(colour)
		await _run_out()
	_ok(seen.size() == 2 and seen[0] != seen[1] and _canon(seen[0]) != _canon(seen[1]), "second run purged a different colour and showed that colour")
	_completed["cells"] = true

func _state() -> Dictionary:
	var b = _host.get_board()
	var cells := PackedInt32Array()
	for i in range(b.get_cell_count()):
		cells.append(int(b.get_cell_state(i)) * 100 + b.get_color_id(i))
	var econ = _root.get_app_state().economy
	return {"cells": cells, "supply": _host.get_supply().player_snapshot(), "slots": _host.get_slots().snapshot(),
		"charges": econ.boosters.charges("tornado"), "sb": econ.wallet.scrub_bucks()}

func _renderer_hash() -> String:
	var img: Image = _host.get_screen().get_presentation().get_renderer()._image
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(img.get_data())
	return h.finish().hex_encode()

func _truth_run(colour: int, reduced: bool) -> Dictionary:
	await _fresh()
	_root.get_app_state().set_reduced_effects(reduced)
	var before := _state()
	var r: Dictionary = _host.execute_booster("tornado", colour)
	var after := _state()
	var h0 := _renderer_hash()
	var played: bool = _vfx.is_playing()
	await _run_out()
	await _frames(2)
	var keep := r.duplicate(true)
	return {"r": keep, "after": after, "d_charges": after["charges"] - before["charges"], "d_sb": after["sb"] - before["sb"],
		"hash_same": h0 == _renderer_hash(), "played": played}

func _truth() -> void:
	print("[truth: effect on vs Reduced]")
	await _fresh()
	var colour := _big_colour()
	var a: Dictionary = await _truth_run(colour, false)
	var b: Dictionary = await _truth_run(colour, true)
	_root.get_app_state().set_reduced_effects(false)
	_ok(a["played"] and not b["played"], "the effect ran in run A only")
	_ok(JSON.stringify(a["r"]) == JSON.stringify(b["r"]), "identical r: %s" % JSON.stringify(a["r"]))
	_ok(a["after"]["cells"] == b["after"]["cells"] and JSON.stringify(a["after"]["supply"]) == JSON.stringify(b["after"]["supply"])
		and JSON.stringify(a["after"]["slots"]) == JSON.stringify(b["after"]["slots"]), "identical board cells, supply and slot snapshots")
	_ok(a["d_charges"] == b["d_charges"] and a["d_sb"] == b["d_sb"], "identical economy deltas (charges %d, SB %d)" % [a["d_charges"], a["d_sb"]])
	_ok(a["hash_same"] and b["hash_same"], "BoardRenderer image unchanged by the effect")
	_completed["truth"] = true

func _timeline() -> void:
	print("[timeline, manual clock]")
	await _fresh()
	var colour := _big_colour()
	_host.execute_booster("tornado", colour)
	_vfx.set_process(false)
	var clip: float = _vfx._clip
	var total: float = _vfx._dur
	var d: Dictionary = _vfx._d
	var center: Vector2 = d["center"]
	var phases: Array = []
	var moving := true
	var positions: Array = []
	var collapse_ok := false
	var burst_ok := false
	var dt := 1.0 / 60.0
	while _vfx.is_playing():
		var ph: String = _vfx.tornado_phase()
		if phases.is_empty() or phases[-1] != ph:
			phases.append(ph)
		if ph == "VIDEO":
			var tp: Vector2 = _vfx.tornado_pos()
			positions.append(tp)
			var g: TextureRect = _vfx._ghost
			if g.visible and g.scale.x < 0.999 and g.scale.x > 0.01:
				var gp: Vector2 = g.get_global_transform() * g.pivot_offset
				var a: Vector2 = gp - center
				var b: Vector2 = tp - center
				moving = moving and absf(a.cross(b)) <= 0.01 * b.length() * maxf(a.length(), 1.0) + 0.5 and a.length() <= b.length() + 0.5
		if ph == "COLLAPSE" and _vfx._t + dt >= clip + BoosterVfx.COLLAPSE_S:
			var v: VideoStreamPlayer = _vfx.get_video_player()
			var sc: Vector2 = _vfx._map["scale"]
			collapse_ok = v != null and v.paused and absf(v.scale.x / sc.x - 0.15) < 0.03 and absf(v.rotation + TAU * 1.5) < 0.2
		if ph == "BURST":
			burst_ok = _vfx.get_video_player() == null and _players(_host.get_screen()).all(func(v): return v.is_queued_for_deletion() and not v.visible)
		_vfx._process(dt)
	_vfx.set_process(true)
	await process_frame
	var travel: float = positions[0].distance_to(positions[-1]) if positions.size() > 1 else 0.0
	_ok(phases == ["VIDEO", "COLLAPSE", "BURST"], "phases in order %s" % str(phases))
	_ok(moving and travel > 100.0 and positions[-1].distance_to(d["board_center"]) <= 1.5,
		"the ghost is pulled toward the tornado's current position (travels %.0f px, ends on the board centre)" % travel)
	_ok(collapse_ok, "collapse: layer paused on the last frame, scale -> ~0.15, ~1.5 turns")
	_ok(burst_ok, "burst: the player is hidden and freed (queue_free)")
	_ok(absf(clip - _clip_len(BoosterVfx.tornado_video)) < 0.01 and total - clip >= 0.4 and total - clip <= 0.6,
		"total %.3f s = clip %.3f + %.3f" % [total, clip, total - clip])
	_ok(_vfx.get_kind() == "" and _vfx.get_video_player() == null and not _vfx._ghost.visible and _vfx.get_child_count() == 1,
		"done: kind \"\", player freed, ghost hidden, one child")
	_completed["timeline"] = true

func _reduced() -> void:
	print("[Reduced Effects]")
	await _fresh()
	var scr = _host.get_screen()
	_root.get_app_state().set_reduced_effects(true)
	var r: Dictionary = _host.execute_booster("tornado", _big_colour())
	var burst: TextureRect = scr.get_booster_button("tornado").get_node("ActivatedBurst")
	_ok(r["ok"] and _players(scr).is_empty() and not _vfx.is_playing() and burst.visible and burst.modulate.a > 0.0,
		"Reduced: Tornado committed, no VideoStreamPlayer, no effect, the button burst flashes")
	await _fresh()
	_host.execute_booster("tornado", _big_colour())
	var had := _players(scr).size()
	_root.get_app_state().set_reduced_effects(true)
	await process_frame
	_ok(had == 1 and _players(scr).is_empty() and _vfx.get_video_player() == null and not _vfx.is_playing(),
		"Reduced turned on mid-effect: the player is freed (%d -> %d)" % [had, _players(scr).size()])
	_root.get_app_state().set_reduced_effects(false)
	_completed["reduced"] = true

func _failure_path() -> void:
	print("[failure path]")
	await _fresh()
	var scr = _host.get_screen()
	var fx: Dictionary = scr.capture_booster_fx("tornado", _big_colour())
	var keep: VideoStream = BoosterVfx.tornado_video
	var broken := VideoStreamTheora.new()
	broken.file = VIDEO_DIR + "missing.ogv"
	for injected in [null, broken]:
		BoosterVfx.tornado_video = injected
		var nodes0 := get_node_count()
		_vfx.play("tornado", fx)
		var phases: Array = []
		var at_centre := true
		_vfx.set_process(false)
		while _vfx.is_playing():
			var ph: String = _vfx.tornado_phase()
			if phases.is_empty() or phases[-1] != ph:
				phases.append(ph)
			at_centre = at_centre and _vfx.tornado_pos() == fx["board_center"]
			_vfx._process(1.0 / 30.0)
		_vfx.set_process(true)
		await _frames(2)
		_ok(phases == ["VIDEO", "COLLAPSE", "BURST"] and at_centre and _players(scr).is_empty() and get_node_count() == nodes0 and _vfx.get_child_count() == 1,
			"%s: code-only spiral into the board centre, collapse, burst over %.3f s; no player, no leaked nodes" %
			["null stream" if injected == null else "broken stream", BoosterVfx.TORNADO_CLIP_S])
	BoosterVfx.tornado_video = keep
	_vfx.play("tornado", fx)
	_vfx.play("tornado", fx)   # a second play while one runs finishes the first
	await _frames(1)
	_ok(_players(scr).size() == 1, "second tornado mid-effect: exactly one player (%d)" % _players(scr).size())
	_vfx.stop()
	_completed["failure_path"] = true

func _performance() -> void:
	print("[performance]")
	await _fresh()
	var scr = _host.get_screen()
	var s := GDScript.new()
	s.source_code = PERF_SRC
	s.reload()
	var fx = s.new()
	_vfx.add_sibling(fx)
	var cap: Dictionary = scr.capture_booster_fx("tornado", _big_colour())
	await process_frame
	fx.frame_us.clear()
	fx.play("tornado", cap)
	var t0 := Time.get_ticks_msec()
	while fx.is_playing() and Time.get_ticks_msec() - t0 < 5000:
		await process_frame
	var vals: Array = fx.frame_us.values()
	var top: Array = vals.duplicate()
	top.sort()
	print("  slowest frames (us): %s" % str(top.slice(-5)))
	var avg := 0.0
	var mx := 0
	for us in vals:
		avg += us
		mx = maxi(mx, us)
	avg = avg / maxf(vals.size(), 1.0) / 1000.0
	var res: Vector2i = BoosterVfx.TORNADO_SIZE
	_perf_line = "PERF avg=%.3f max=%.3f ms over %d frames (BoosterVfx _process + _draw script time, %d samples, %d ghost cells; decoded video %dx%d)" % [
		avg, mx / 1000.0, vals.size(), (cap["samples"] as Array).size(), _count(_big_colour()), res.x, res.y]
	print(_perf_line)
	_ok(vals.size() >= 10 and avg <= 1.0 and mx / 1000.0 <= 4.0, "avg %.3f ms <= 1.0, max %.3f ms <= 4.0" % [avg, mx / 1000.0])
	fx.queue_free()
	await process_frame
	# The decoder teardown runs once, at the burst, in the frame's delete flush (engine, not script).
	var v := VideoStreamPlayer.new()
	v.stream = BoosterVfx.tornado_video
	_vfx.add_sibling(v)
	v.play()
	await _frames(10)
	var t1 := Time.get_ticks_usec()
	v.free()
	var teardown := (Time.get_ticks_usec() - t1) / 1000.0
	_perf_line += "
PERF decoder teardown (once, at the burst, delete flush) %.3f ms" % teardown
	print("PERF decoder teardown (once, at the burst, delete flush) %.3f ms" % teardown)
	_completed["performance"] = true

## Evidence (windowed run): the real effect at 1080x2160 in real time, a frame kept whenever the
## clock crosses each of 10 evenly spaced moments (0 .. total + 0.2 s), saved as PNGs after.
func _evidence_frames() -> void:
	await _fresh()
	var colour := -1
	for c in _host.get_booster_adapter().present_colors():   # a red / orange colour, most cells
		var col := _canon(int(c))
		print("present colour %d %s %d cells" % [int(c), col.to_html(false), _count(int(c))])
		if (col.h < 0.11 or col.h > 0.93) and col.s > 0.4 and col.v > 0.3 and (colour < 0 or _count(int(c)) > _count(colour)):
			colour = int(c)
	if colour < 0:
		colour = _big_colour()
	var cells := _count(colour)
	print("evidence colour %d %s, %d cells" % [colour, _canon(colour).to_html(false), cells])
	_host.execute_booster("tornado", colour)
	var total: float = _vfx._dur
	var marks: Array = []
	for k in range(10):
		marks.append(total * k / 8.0 if k < 9 else total + 0.2)
	var shots: Array = []
	var start := Time.get_ticks_usec()
	var k := 0
	while k < marks.size():
		await RenderingServer.frame_post_draw
		var t: float = (Time.get_ticks_usec() - start) / 1000000.0
		if t >= marks[k]:
			shots.append([t, _vfx.tornado_phase(), _sub.get_texture().get_image()])
			k += 1
	for i in range(shots.size()):
		var ph: String = shots[i][1] if shots[i][1] != "" else "DONE"
		(shots[i][2] as Image).save_png(_evidence.path_join("tornado_%02d_%.2fs_%s.png" % [i, shots[i][0], ph]))
	var f := FileAccess.open(_evidence.path_join("perf.txt"), FileAccess.WRITE)
	f.store_string("%s\nclip %.3f s, total %.3f s, purge colour %d %s (%d cells)\n" % [_perf_line, _vfx.TORNADO_CLIP_S, total, colour, _canon(colour).to_html(false), cells])
	f.close()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("SB-TF-06 tornado video evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
