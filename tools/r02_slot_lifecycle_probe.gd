extends SceneTree
## M52-C001-R02 slot-lifecycle evidence probe (debug/QA only). Real production host on a
## TEST stripe fixture: Batch A (C01 x1) is placed, the runtime dispatches its only
## Scrubby, and every 60 Hz frame until A's pixel clears records the physical slot state,
## the player-visible count, the live transaction count and whether a new batch can be
## placed. Right after A's departure it tries to place Batch B (C01 x1) and, after A clears,
## records B. Written to run on both pre- and post-R02 code (draining APIs are optional).
##
## Usage: godot --headless --path . -s res://tools/r02_slot_lifecycle_probe.gd -- <out.json>

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

const DT := 1.0 / 60.0

func _initialize() -> void:
	await process_frame
	var out_path: String = OS.get_cmdline_user_args()[0]
	var cells: Array = []
	for y in range(20):
		for x in range(20):
			cells.append(x / 4)
	var lvl := {"version": 1, "id": "r02_stripes", "name": "R02", "difficulty": "TEST", "width": 20, "height": 20,
		"palette": ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF"], "cells": cells}
	var cols: Array = [[["C01", 1], ["C01", 1]], [["C02", 30], ["C02", 30], ["C02", 20]], [["C03", 30], ["C03", 30], ["C03", 20]]]
	var left := {"C01": 78, "C04": 80, "C05": 80}
	for cid in ["C01", "C04", "C05"]:
		var n: int = left[cid]
		while n > 0:
			cols[2].append([cid, mini(30, n)])
			n -= mini(30, n)
	var q: Array = []
	var k := 0
	for col in cols:
		var qq: Array = []
		for b in col:
			k += 1
			qq.append({"batchId": "P%03d" % k, "cid": b[0], "robots": b[1]})
		q.append(qq)
	var plan := {"schema": "scrubbots.level_supply_plan.v1", "version": 1, "levelId": "r02_stripes", "columnCount": 3,
		"visiblePreviewDepth": 3, "maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": q}
	var lp := "user://r02_probe_lvl.json"
	var pp := "user://r02_probe_plan.json"
	FileAccess.open(lp, FileAccess.WRITE).store_string(JSON.stringify(lvl))
	FileAccess.open(pp, FileAccess.WRITE).store_string(JSON.stringify(plan))
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = lp
	h.supply_plan_path = pp
	get_root().add_child(h)
	var built: bool = h.build()
	var rt = h.get_runtime()
	rt.set_process(false)
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var a: Dictionary = input.activate_front(0)
	var n: int = int(a.get("slot", -1))
	var active0: int = h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)
	var frames: Array = []
	var b_attempt := {}
	var dispatched := false
	for f in range(4000):
		rt.tick(DT)
		var s: Dictionary = slots.snapshot()[n]
		var live: int = h.get_scheduler().live_assignment_count()
		var cleared: bool = h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) < active0
		if live > 0 and not dispatched:
			dispatched = true
			# Attempt to place Batch B right after A's departure (same frame).
			var rb: Dictionary = input.activate_front(0)
			b_attempt = {"frame": f, "ok": rb.get("ok", false), "slot": rb.get("slot", -1), "error": rb.get("error", "")}
			h.get_scheduler().pause()   # keep B waiting so A's arrival is isolated
		frames.append({"f": f, "slot_state": s["state"], "occupied": s["occupied"], "batch": s["batch_id"],
			"displayed": maxi(int(s["remaining_to_clear"]) - int(s["committed"]), 0), "live": live, "a_cleared": cleared,
			"draining": slots.draining_count() if slots.has_method("draining_count") else -1})
		if cleared and live == 0:
			break
	var first_dispatch := -1
	var first_empty_while_inflight := -1
	var clear_frame := -1
	for fr in frames:
		if fr["live"] > 0 and first_dispatch == -1:
			first_dispatch = fr["f"]
		if first_empty_while_inflight == -1 and fr["live"] > 0 and not fr["occupied"]:
			first_empty_while_inflight = fr["f"]
		if fr["a_cleared"] and clear_frame == -1:
			clear_frame = fr["f"]
	var result := {"built": built, "a_slot": n, "first_dispatch_frame": first_dispatch, "a_clear_frame": clear_frame,
		"frames_slot_empty_while_a_in_flight": frames.filter(func(fr): return fr["live"] > 0 and not fr["occupied"]).size(),
		"frames_slot_occupied_showing_0_while_a_in_flight": frames.filter(func(fr): return fr["live"] > 0 and fr["occupied"] and fr["displayed"] == 0 and fr["batch"] != "P002").size(),
		"b_placement_right_after_departure": b_attempt, "slot_after_a_clear": slots.snapshot()[n], "frames": frames}
	var fo := FileAccess.open(out_path, FileAccess.WRITE)
	fo.store_string(JSON.stringify(result, "\t") + "\n")
	fo.close()
	print("R02_PROBE_DONE dispatch=%d clear=%d b=%s" % [first_dispatch, clear_frame, str(b_attempt)])
	h.free()
	quit(0)
