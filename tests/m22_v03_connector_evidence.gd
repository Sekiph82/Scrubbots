extends SceneTree
## M22-C001 V03 — post-layout SlotCell connector evidence (F-M22-V02-STRICT-002).
##
## V02's integration test pressed the C08 Button BEFORE layout and compared route
## point 0 with agent.spawn_origin (both from the same dispatch input) — circular.
## This test hosts the real m22_slot_demo.tscn in a real SubViewport, AWAITS layout
## frames, then INDEPENDENTLY measures each of the five SlotCell top-center global
## anchors and maps them through BoardPresentation.global_to_board_local(). It then
## presses real Buttons and proves the real agent route point 0 equals the
## independently measured mapped anchor (not merely spawn_origin), route point 1
## equals ScrubRailGeometry.bottom_entry(mapped.x), and the connector is a real
## segment. A second, deliberately re-laid-out case proves the connector geometry
## is re-read from current layout (no stale cache). On a fresh scene the real C08
## Button still naturally selects target 380/(0,19).
##
## Run: godot --headless --path . -s res://tests/m22_v03_connector_evidence.gd
## Exits 0 on success, 1 on any failure.

const ScrubRailGeometry = preload("res://scripts/gameplay/routing/scrub_rail_geometry.gd")

var _fail := 0

func _initialize() -> void:
	await _case_primary(Vector2i(1080, 2160))
	await _case_relayout(Vector2i(1290, 2796))
	_done()

func _make(size: Vector2i) -> Dictionary:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var scene = load("res://scenes/demo/m22_slot_demo.tscn")
	var inst = scene.instantiate()
	sub.add_child(inst)
	if inst._board == null:
		inst.build()
	return {"sub": sub, "inst": inst}

## Independently measured mapped board-local anchor for slot `sid`.
func _mapped_anchor(inst, sid: int) -> Vector2:
	var cell = inst.get_panel().get_cell(sid)
	var anchor_global: Vector2 = cell.get_spawn_anchor_global()
	return inst.get_presentation().global_to_board_local(anchor_global)

func _case_primary(size: Vector2i) -> void:
	var m := _make(size)
	var inst = m["inst"]
	await process_frame
	await process_frame
	await process_frame

	var panel = inst.get_panel()
	var cells: Array = panel.get_slot_cells()
	_ok(cells.size() == 5, "primary %s: exactly five real SlotCell/Button instances after layout" % str(size))

	var geom = ScrubRailGeometry.new(inst._board.get_width(), inst._board.get_height())
	# Five independently measured mapped anchors, one-to-one with slot ids, distinct.
	var mapped: Array = []
	for sid in range(5):
		mapped.append(_mapped_anchor(inst, sid))
	var distinct := true
	for i in range(5):
		for j in range(i + 1, 5):
			if mapped[i].distance_to(mapped[j]) < 0.001:
				distinct = false
	_ok(distinct, "primary: five mapped connector starts are distinct and one-to-one with slot ids")
	var below_board := true
	for sid in range(5):
		if mapped[sid].y < float(inst._board.get_height()):
			below_board = false
	_ok(below_board, "primary: every mapped slot start is below the board (a genuine railroad start)")
	print("PRIMARY size=%s anchors_mapped=%s" % [str(size), str(mapped)])

	# Fresh C08 (slot 2) natural target + independent anchor->route proof.
	inst.reset_presentation()
	inst._last_result = null
	panel.get_cell(2).pressed.emit()
	var r2 = inst._last_result
	_ok(r2 != null and r2.success, "primary: real C08 Button dispatches")
	if r2 != null and r2.success:
		_ok(r2.target_index == 380, "primary: C08 naturally selects target 380")
		_ok(inst._board.get_cell_position(r2.target_index) == Vector2i(0, 19), "primary: C08 target coordinate (0,19)")
		var pts: PackedVector2Array = r2.agent.get_route_points()
		_ok(pts[0].distance_to(mapped[2]) < 0.001, "primary: route point 0 == INDEPENDENTLY measured mapped slot-2 anchor (not circular)")
		_ok(pts[1].distance_to(geom.bottom_entry(mapped[2].x)) < 0.001, "primary: route point 1 == canonical bottom_entry(mapped.x)")
		var span_min := geom.span_min()
		var span_max := geom.span_max_x()
		if mapped[2].x >= span_min and mapped[2].x <= span_max:
			_ok(absf(pts[1].x - mapped[2].x) < 0.001, "primary: connector preserves mapped x (no unnecessary clamp)")
		_ok(pts[0].distance_to(pts[1]) > 0.001, "primary: connector is a real travelled segment (no teleport)")
		_ok(pts[pts.size() - 1].is_equal_approx(Vector2(0.5, 19.5)), "primary: route ends at target centre via aligned exit")
		print("PRIMARY_C08 mapped_start=%s route=%s" % [str(mapped[2]), str(pts)])

	# Per-slot: every successful real Button route starts at that slot's mapped anchor.
	for sid in range(5):
		inst.reset_presentation()
		inst._last_result = null
		panel.get_cell(sid).pressed.emit()
		var rr = inst._last_result
		if rr != null and rr.success:
			var rp: PackedVector2Array = rr.agent.get_route_points()
			_ok(rp[0].distance_to(mapped[sid]) < 0.001, "primary: slot %d route point 0 == its own mapped anchor" % sid)
			_ok(rp[1].distance_to(geom.bottom_entry(mapped[sid].x)) < 0.001, "primary: slot %d route point 1 == bottom_entry(mapped.x)" % sid)

	inst.free()
	m["sub"].free()

## Second case: re-lay-out (different viewport AND a moved panel) and prove the
## connector start is re-derived from CURRENT geometry, not a stale cached anchor.
func _case_relayout(size: Vector2i) -> void:
	var m := _make(size)
	var inst = m["inst"]
	await process_frame
	await process_frame

	var panel = inst.get_panel()
	var geom = ScrubRailGeometry.new(inst._board.get_width(), inst._board.get_height())
	var before: Vector2 = _mapped_anchor(inst, 2)

	# Deliberately relayout: shift the panel and await new layout.
	panel.position += Vector2(53.0, 41.0)
	await process_frame
	await process_frame
	var after: Vector2 = _mapped_anchor(inst, 2)
	_ok(after.distance_to(before) > 0.001, "relayout %s: moved panel changes the measured slot-2 anchor (not cached)" % str(size))

	inst.reset_presentation()
	inst._last_result = null
	panel.get_cell(2).pressed.emit()
	var r2 = inst._last_result
	_ok(r2 != null and r2.success, "relayout: real C08 Button dispatches after relayout")
	if r2 != null and r2.success:
		var pts: PackedVector2Array = r2.agent.get_route_points()
		_ok(pts[0].distance_to(after) < 0.001, "relayout: route point 0 tracks the NEW post-layout anchor (dynamic, no stale cache)")
		_ok(pts[0].distance_to(before) > 0.001, "relayout: route point 0 is NOT the pre-move anchor")
		_ok(pts[1].distance_to(geom.bottom_entry(after.x)) < 0.001, "relayout: route point 1 == bottom_entry(new mapped x)")
		_ok(r2.target_index == 380, "relayout: C08 still naturally selects target 380")
		print("RELAYOUT size=%s before=%s after=%s route=%s" % [str(size), str(before), str(after), str(pts)])

	inst.free()
	m["sub"].free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M22 V03 connector evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
