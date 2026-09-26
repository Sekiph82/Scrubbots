extends SceneTree
## M52-C001 — verify an owner supply plan (data/levels/supply/<id>_supply_v1.json) with
## the canonical gameplay proof stack. The plan is loaded by the SHIPPING
## SupplyPlanLoader (global Cxx -> local palette index, full hidden FIFO queues, exact
## conservation, fail-closed), then:
##   1. static record: source/level hashes + dimensions, local palette, Cxx->local map,
##      queue lengths, full layout, max batch, conservation;
##   2. owner intended click sequence through the real ProofKernel (legal placements
##      only), per step: column, front batch, placed slot, clears, ACTIVE left, queue
##      lengths, slot snapshot; pass only if ACTIVE 0, supply exhausted, slots empty;
##   3. SolvabilitySolver.solve (default bounds) on the full ProofState + trace replay.
## Writes a detached evidence JSON. Never mutates plan, level or runtime.
##
## Usage:
##   godot --headless --path . -s res://tools/verify_m52_supply_candidate.gd -- <level_id> <evidence_out.json>
## Exit 0 only when conservation passes, the intended sequence completes, the solver
## returns SOLVED and its replay completes.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var id: String = args[0]
	var out_path: String = args[1]
	var plan_path := "res://data/levels/supply/%s_supply_v1.json" % id
	var spec: Dictionary = {}
	for s in Pack.PACK:
		if s["id"] == id:
			spec = s
	var level_path := Pack.level_path(id)
	var lvl = LevelLoader.load_from_path(level_path).level_data
	var src := Image.new()
	src.load(spec["source"])
	var ev := {"schema": "scrubbots.supply_plan_verification.v1", "version": 1, "levelId": id,
		"order": spec["order"], "difficulty": spec["difficulty"],
		"sourcePath": spec["source"], "sourceSha256": Pack.content_sha256(spec["source"]),
		"sourceWidth": src.get_width(), "sourceHeight": src.get_height(),
		"levelPath": level_path, "levelSha256": Pack.content_sha256(level_path),
		"levelWidth": lvl.width, "levelHeight": lvl.height, "cellCount": lvl.get_cell_count(),
		"localPalette": Array(lvl.palette),
		"planPath": plan_path, "planSha256": Pack.content_sha256(plan_path),
		"solverBounds": {"maxVisited": SolvabilitySolver.DEFAULT_MAX_VISITED,
			"maxDepth": SolvabilitySolver.DEFAULT_MAX_DEPTH}}
	var r := SupplyPlanLoader.load_engine(plan_path, lvl)
	ev["loader"] = {"ok": r["ok"], "error": r["error"]}
	if not r["ok"]:
		print("LOADER_FAIL %s: %s" % [id, r["error"]])
		_finish(ev, out_path, 1)
		return
	var eng = r["engine"]
	var plan: Dictionary = r["plan"]
	ev["ownerInput"] = plan["ownerInput"]
	ev["ownerInputSha256"] = plan["ownerInputSha256"]
	ev["cidToLocal"] = r["cid_to_local"]
	ev["queueLengths"] = r["queue_lengths"]
	var layout: Array = eng.debug_snapshot()["columns"]
	ev["queueLayout"] = layout
	var max_b := 0
	var batches := 0
	for col in layout:
		for b in col:
			max_b = maxi(max_b, int(b["robot_count"]))
			batches += 1
	ev["batchCount"] = batches
	ev["maxBatch"] = max_b
	ev["conservation"] = "PASS"   # enforced by SupplyPlanLoader (fail-closed above)
	var ps = ProofState.from_level_and_supply(lvl, eng)
	var ps_len: Array = []
	for q in ps.supply:
		ps_len.append(q.size())
	ev["proofStateQueueLengths"] = ps_len
	ev["proofStateHoldsFullQueue"] = ps_len == r["queue_lengths"]

	# --- owner intended click sequence ---
	var k = ProofKernel.new()
	var st = k.quiesce(ps)["state"]
	var steps: Array = []
	var failure = null
	var clicks: Array = plan["intendedColumnClicks"]
	for i in clicks.size():
		var col := int(clicks[i]) - 1
		var front = st.supply[col][0] if col >= 0 and col < st.supply.size() and st.supply[col].size() > 0 else null
		if not st.legal_action_columns().has(col):
			failure = {"step": i + 1, "column": col + 1, "front": front,
				"reason": "illegal_placement_all_slots_occupied" if not st.has_empty_slot() else "column_empty_or_illegal",
				"activeRemaining": st.active_count(), "queueLengths": _lens(st), "slots": st.slots}
			break
		var a: Dictionary = k.apply_placement(st, col)
		st = a["state"]
		steps.append({"step": i + 1, "column": col + 1, "front": front, "placedSlot": int(a["placed_slot"]),
			"clears": int(a["clears"]), "activeRemaining": st.active_count(), "queueLengths": _lens(st),
			"occupiedSlots": _slot_view(st)})
	var exhausted: bool = st.is_supply_exhausted()
	var slots_empty: bool = st.occupied_slot_count() == 0
	if failure == null and not (st.active_count() == 0 and exhausted and slots_empty):
		failure = {"step": clicks.size(), "reason": "sequence_ended_not_complete",
			"activeRemaining": st.active_count(), "supplyExhausted": exhausted, "slotsEmpty": slots_empty,
			"queueLengths": _lens(st), "slots": st.slots}
	ev["intendedSequence"] = {"clicks": clicks, "pass": failure == null, "failure": failure,
		"finalActive": st.active_count(), "supplyExhausted": exhausted, "slotsEmpty": slots_empty, "steps": steps}
	print("INTENDED %s pass=%s applied=%d failure=%s" % [id, failure == null, steps.size(), str(failure).left(300)])

	# --- canonical solver ---
	var solver = SolvabilitySolver.new()
	var t0 := Time.get_ticks_msec()
	var res: Dictionary = solver.solve(ps)
	var sol := {"status": String(res["status"]), "reason": res["reason"], "visited": int(res["visited"]),
		"memoHits": int(res["memo_hits"]), "frontierPeak": int(res["frontier_peak"]),
		"maxDepthReached": int(res["max_depth_reached"]), "decisions": int(res["decisions"]),
		"elapsedMs": Time.get_ticks_msec() - t0}
	var solved_ok := false
	if res["status"] == SolvabilitySolver.SOLVED:
		sol["traceHash"] = int(res["trace_hash"])
		sol["traceSummary"] = String(res["trace_summary"])
		sol["trace"] = res["trace"]
		sol["fullQueueConsumed"] = int(res["decisions"]) == batches
		var rep: Dictionary = solver.replay(ProofState.from_level_and_supply(lvl, eng), res["trace"])
		sol["replay"] = {"ok": rep["ok"], "solved": rep["solved"], "finalActive": int(rep["final_active"]),
			"steps": int(rep["steps"]), "divergedAt": int(rep["diverged_at"])}
		solved_ok = rep["ok"] and rep["solved"] and int(rep["final_active"]) == 0 and sol["fullQueueConsumed"]
	ev["solver"] = sol
	print("SOLVER %s status=%s visited=%d decisions=%d trace_hash=%s replay=%s elapsed_ms=%d" % [id, sol["status"],
		sol["visited"], sol["decisions"], str(sol.get("traceHash", "-")), str(sol.get("replay", {}).get("solved", "-")), sol["elapsedMs"]])
	_finish(ev, out_path, 0 if (solved_ok and failure == null) else 1)

func _lens(st) -> Array:
	var out: Array = []
	for q in st.supply:
		out.append(q.size())
	return out

func _slot_view(st) -> Array:
	var out: Array = []
	for s in st.slots:
		out.append(null if s == null else {"batch": s["batch_id"], "color": s["color"], "remaining": s["remaining"], "state": s["state"]})
	return out

func _finish(ev: Dictionary, out_path: String, code: int) -> void:
	ev["pass"] = code == 0
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(ev, "\t") + "\n")
	f.close()
	print("VERIFY_DONE %s pass=%s" % [ev["levelId"], code == 0])
	quit(code)
