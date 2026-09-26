extends SceneTree
## M52-C001 — verify an owner-specified declarative supply candidate with the canonical
## gameplay proof stack. The candidate's exact FIFO columns (every hidden row kept) are
## loaded into a real BatchSupplyEngine through ColorBatch.make + load_candidate (the same
## path the runtime host uses for a direct layout), then:
##   1. conservation gate: 3 columns, every batch 1..maxRobotsPerBatch, per-color totals ==
##      LevelData totals, grand total == cell count, C-IDs resolved via palette authority;
##   2. intended-sequence replay: the owner's column clicks applied one by one through the
##      real ProofKernel (legal placement only); records per-step clears/active and the
##      first step that is illegal (all slots occupied) or leaves the board unsolved;
##   3. authoritative SolvabilitySolver.solve (default bounds) on the full ProofState, and
##      replay of the emitted trace when SOLVED.
## Writes a detached evidence JSON; never mutates the candidate, level or runtime.
##
## Usage:
##   godot --headless --path . -s res://tools/verify_m52_supply_candidate.gd -- <candidate.json> <evidence_out.json>
## Exit 0 only when conservation passes AND the solver returns SOLVED AND replay completes.

const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ProductionArtLevelBuilder = preload("res://scripts/tools/production_art_level_builder.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const BatchSupplyGenerator = preload("res://scripts/gameplay/supply/batch_supply_generator.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const ProofState = preload("res://scripts/gameplay/solver/proof_state.gd")
const ProofKernel = preload("res://scripts/gameplay/solver/proof_kernel.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const Pack = preload("res://tools/build_m52_first_10_pack.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var cand_path: String = args[0]
	var out_path: String = args[1]
	var cand: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(cand_path))
	var ev := {"schema": "scrubbots.supply_candidate_verification.v1", "version": 1,
		"candidatePath": cand_path, "candidateSha256": Pack.content_sha256(cand_path),
		"levelId": cand["levelId"], "levelPath": cand["levelPath"],
		"levelSha256": Pack.content_sha256(cand["levelPath"]),
		"solverBounds": {"maxVisited": SolvabilitySolver.DEFAULT_MAX_VISITED,
			"maxDepth": SolvabilitySolver.DEFAULT_MAX_DEPTH}}
	var lvl = LevelLoader.load_from_path(cand["levelPath"]).level_data

	# --- 1. conservation / shape gate ---
	var auth = ProductionArtLevelBuilder.load_palette_authority()
	var hex_to_index := {}
	for i in lvl.palette.size():
		hex_to_index[lvl.palette[i]] = i
	var cid_to_index := {}
	for cid in auth["cid_to_hex"]:
		if hex_to_index.has(auth["cid_to_hex"][cid]):
			cid_to_index[cid] = hex_to_index[auth["cid_to_hex"][cid]]
	var errors: Array = []
	var cols: Array = []
	var sums := {}
	var lengths: Array = []
	var max_b := int(cand["maxRobotsPerBatch"])
	for col in cand["columns"]:
		var q: Array = []
		for b in col:
			var n := int(b["robots"])
			if not cid_to_index.has(b["cid"]):
				errors.append("%s: %s not in level palette" % [b["batchId"], b["cid"]])
				continue
			if n <= 0 or n > max_b:
				errors.append("%s: robots %d outside 1..%d" % [b["batchId"], n, max_b])
			var ci: int = cid_to_index[b["cid"]]
			sums[ci] = int(sums.get(ci, 0)) + n
			var batch = ColorBatch.make(String(b["batchId"]), ci, n, lvl.palette.size())
			if batch == null:
				errors.append("%s: ColorBatch.make rejected" % b["batchId"])
				continue
			q.append(batch)
		cols.append(q)
		lengths.append(q.size())
	var totals := BatchSupplyGenerator.color_totals(lvl)
	if sums != totals:
		errors.append("per-color totals %s != level totals %s" % [str(sums), str(totals)])
	var grand := 0
	for c in sums:
		grand += int(sums[c])
	if cols.size() != int(cand["columnCount"]) or grand != lvl.get_cell_count():
		errors.append("shape: %d columns, grand total %d vs %d cells" % [cols.size(), grand, lvl.get_cell_count()])
	var eng = BatchSupplyEngine.create(int(cand["columnCount"]), int(cand["visiblePreviewDepth"]))
	if eng == null or not eng.load_candidate(cols, 0, lvl.palette.size()):
		errors.append("BatchSupplyEngine.load_candidate rejected the layout")
	ev["conservation"] = {"ok": errors.is_empty(), "errors": errors, "queueLengths": lengths,
		"grandTotal": grand, "cellCount": lvl.get_cell_count()}
	if not errors.is_empty():
		_finish(ev, out_path, 1)
		return
	var ps = ProofState.from_level_and_supply(lvl, eng)
	var ps_len: Array = []
	for q in ps.supply:
		ps_len.append(q.size())
	ev["proofStateQueueLengths"] = ps_len
	ev["proofStateHoldsFullQueue"] = ps_len == lengths

	# --- 2. owner intended click sequence through the real kernel ---
	var k = ProofKernel.new()
	var st = k.quiesce(ps)["state"]
	var steps: Array = []
	var stall = null
	var clicks: Array = cand["intendedColumnClicks"]
	for i in clicks.size():
		var col := int(clicks[i]) - 1
		var front = st.supply[col][0] if st.supply[col].size() > 0 else null
		if not st.legal_action_columns().has(col):
			stall = {"step": i + 1, "column": col + 1, "reason": "illegal_placement_all_slots_occupied" if not st.has_empty_slot() else "column_empty_or_illegal",
				"front": front, "slots": st.slots, "activeRemaining": st.active_count(),
				"activeByColor": _active_by_color(st, lvl)}
			break
		var r: Dictionary = k.apply_placement(st, col)
		st = r["state"]
		steps.append({"step": i + 1, "column": col + 1, "placed": r["placed"], "clears": int(r["clears"]),
			"activeAfter": st.active_count(), "occupiedSlots": st.occupied_slot_count()})
	if stall == null and not st.is_solved():
		stall = {"step": clicks.size(), "reason": "sequence_exhausted_board_not_solved", "slots": st.slots,
			"activeRemaining": st.active_count(), "activeByColor": _active_by_color(st, lvl)}
	ev["intendedSequence"] = {"completed": stall == null, "steps": steps, "firstStall": stall}
	print("INTENDED completed=%s steps_applied=%d stall=%s" % [stall == null, steps.size(), str(stall).left(400)])

	# --- 3. authoritative solver + replay ---
	var solver = SolvabilitySolver.new()
	var t0 := Time.get_ticks_msec()
	var res: Dictionary = solver.solve(ps)
	var sol := {"status": String(res["status"]), "reason": res["reason"], "visited": int(res["visited"]),
		"memoHits": int(res["memo_hits"]), "frontierPeak": int(res["frontier_peak"]),
		"maxDepthReached": int(res["max_depth_reached"]), "decisions": int(res["decisions"]),
		"elapsedMs": Time.get_ticks_msec() - t0}
	var ok := false
	if res["status"] == SolvabilitySolver.SOLVED:
		sol["traceHash"] = int(res["trace_hash"])
		sol["traceSummary"] = String(res["trace_summary"])
		var total := 0
		for l in lengths:
			total += int(l)
		sol["fullQueueConsumed"] = int(res["decisions"]) == total
		var rep: Dictionary = solver.replay(ProofState.from_level_and_supply(lvl, eng), res["trace"])
		sol["replay"] = {"ok": rep["ok"], "solved": rep["solved"], "finalActive": int(rep["final_active"]),
			"steps": int(rep["steps"]), "divergedAt": int(rep["diverged_at"])}
		ok = rep["ok"] and rep["solved"] and int(rep["final_active"]) == 0 and sol["fullQueueConsumed"]
	ev["solver"] = sol
	print("SOLVER ", JSON.stringify(sol).left(600))
	_finish(ev, out_path, 0 if ok else 1)

func _active_by_color(st, lvl) -> Dictionary:
	var out := {}
	for i in range(st.active.size()):
		if st.active[i] == ProofState.ACTIVE_BYTE:
			var c := String(lvl.palette[lvl.cells[i]])
			out[c] = int(out.get(c, 0)) + 1
	return out

func _finish(ev: Dictionary, out_path: String, code: int) -> void:
	ev["pass"] = code == 0
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(ev, "\t") + "\n")
	f.close()
	print("VERIFY_DONE pass=%s -> %s" % [code == 0, out_path])
	quit(code)
