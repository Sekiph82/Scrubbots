extends RefCounted
## RealPlayDriver — SB-CAMPAIGN-RUNTIME-KERNEL-DIVERGENCE (owner redirect 2026-10-31). Preload
## this script (res://scripts/gameplay/solver/real_play_driver.gd); no global class_name.
##
## Plays a level through the REAL shipping ProductionGameplayHost the way a human does, and
## searches supply-column orders under that play. This is the ONLY "shippable" proof: a plan
## is winnable in the game players run iff it reaches WON here. ProofKernel SOLVED is a
## canonical-timing proof and analysis model, not a shippability verdict.
##
## Canonical timing model (real_play_v1): fixed dt = 1/60 s, speed 1x (the runtime's own
## auto-2x after the last placement stays as in production), runtime.set_process(false) and
## runtime.tick(dt) called directly so agents are driven by the controller as in production,
## no pause. Limitation: devices at other FPS or at manual 2x may order claims differently
## (lane service is one lane per frame, cadence and travel advance per frame). The canonical
## model is the contract; a plan is accepted only if it also wins at every SENSITIVITY_DTS
## entry. Manual 2x is not modelled.
##
## Human policy: before every tick (frame 0 included), while a slot is free
## (slots.rightmost_empty_index() != -1) and a click remains, place the next column. The five
## slots fill at frame 0 and a slot freed while other bots still fly is refilled on the next
## frame boundary; the driver never waits for quiescence or landings. Without a plan (Level 1,
## M23 generator) the choice is the first column with a front batch (the first whose
## activate_front succeeds); should that ever lose, the searched clicks are kept in the level's
## provenance record instead.

const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

const MODEL := "real_play_v1"
const CANONICAL_DT := 1.0 / 60.0
const SENSITIVITY_DTS := [1.0 / 30.0, 1.0 / 60.0, 1.0 / 120.0]
const DT_LABELS := {30: "1/30", 60: "1/60", 120: "1/120"}
## Frame cap per play (game time at 1/120 s: ~2.3 h; no level comes close).
const MAX_FRAMES := 1000000
## Search node budget (nodes = rollout replays), not wall clock, so results are reproducible.
const NODE_BUDGET := 400
const PROVENANCE_PATH := "res://data/levels/supply/real_play_provenance_v1.json"
const PROVENANCE_SCHEMA := "scrubbots.real_play_provenance.v1"

static var _orders: Dictionary = {}

static func fps(dt: float) -> int:
	return int(round(1.0 / dt))

static func dt_label(dt: float) -> String:
	return DT_LABELS.get(fps(dt), "1/%d" % fps(dt))

## Play on a built host under the human policy. `clicks` (1-based columns) are placed in
## order; when they run out: `rollout_plan` == null -> no more clicks, except that an empty
## `clicks` places the first column whose activate_front succeeds; an Array -> search
## rollout: the plan's column while the clicks so far equal the plan prefix, else the
## best-ranked legal column (rank_columns). `taken` / `legal_at` record every placement and
## the legal columns (1-based, rank order) a rollout chose from. The host must already be laid
## out (one frame in the tree at full size): before that SlotOriginProvider has no slot anchors
## and returns its fallback origins, which is not the game players run. Play starts from a
## fresh runtime clock (reset_runtime: 1x, cadence accumulator 0).
static func play_on_host(host, clicks: Array, dt: float = CANONICAL_DT, max_frames: int = MAX_FRAMES, rollout_plan = null) -> Dictionary:
	var runtime = host.get_runtime()
	runtime.set_process(false)
	runtime.reset_runtime()
	var input = host.get_input_controller()
	var slots = host.get_slots()
	var supply = host.get_supply()
	var completion = host.get_completion()
	var cleared: Array = []
	var on_clear := func(_o, target, _c, _a): cleared.append(int(target))
	host.get_clearing_loop().authenticated_clear.connect(on_clear)
	var greedy: bool = clicks.is_empty() and rollout_plan == null
	var taken: Array = []
	var legal_at: Array = []
	var frames := 0
	var rejected := {}
	var stuck := false
	while frames < max_frames and not completion.is_terminal():
		while slots.rightmost_empty_index() != -1 and not supply.is_exhausted():
			var col := -1
			if taken.size() < clicks.size():
				col = int(clicks[taken.size()])
			elif greedy:
				for c in range(supply.get_column_count()):
					if supply.get_front(c) != null:
						col = c + 1
						break
			elif rollout_plan is Array:
				var ranked := rank_columns(host)
				legal_at.resize(taken.size())
				legal_at.append(ranked)
				var on_plan: bool = taken.size() < rollout_plan.size() and taken == rollout_plan.slice(0, taken.size())
				col = int(rollout_plan[taken.size()]) if on_plan and ranked.has(int(rollout_plan[taken.size()])) else int(ranked[0])
			if col == -1:
				break
			var r: Dictionary = input.activate_front(col - 1)
			if not r.get("ok", false):
				# A legal column (has a front) with a free slot must never be rejected.
				var legal: bool = col >= 1 and col <= supply.get_column_count() and supply.get_front(col - 1) != null
				rejected = {"click": taken.size() + 1, "column": col, "error": str(r.get("error", "")), "driver_bug": legal}
				if legal:
					push_error("RealPlayDriver: legal column %d rejected with a free slot: %s" % [col, str(r)])
				break
			taken.append(col)
		if not rejected.is_empty():
			break
		if _quiescent(host):
			stuck = host.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) > 0
			if stuck:
				break
		runtime.tick(dt)
		frames += 1
	host.get_clearing_loop().authenticated_clear.disconnect(on_clear)
	var active: int = host.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)
	legal_at.resize(taken.size())
	return {
		"won": completion.is_won() and active == 0 and supply.is_exhausted() and slots.occupied_count() == 0,
		"frames": frames,
		"clicks_placed": taken.size(),
		"taken": taken,
		"legal_at": legal_at,
		"rejected": rejected,
		"cleared_sequence": cleared,
		"final": {"active": active, "supply_exhausted": supply.is_exhausted(), "slots_empty": slots.occupied_count() == 0,
			"terminal": String(completion.get_state())},
		"stuck": stuck or (completion.is_terminal() and not completion.is_won()),
	}

## Nothing can change until the next click: no live assignment, no moving bot, every
## occupied slot WAITING.
static func _quiescent(host) -> bool:
	var scheduler = host.get_scheduler()
	if scheduler.live_assignment_count() != 0:
		return false
	for ch in host.get_agent_layer().get_children():
		if ch.has_method("is_moving") and ch.is_moving():
			return false
	var slots = host.get_slots()
	for k in range(slots.get_slot_count()):
		if slots.is_occupied(k) and not scheduler.is_slot_waiting(k):
			return false
	return true

## Search branch order (read-only; the runtime alone decides outcomes): legal columns
## (1-based) by how much unclaimed exposed work their front colour has right now, net of the
## robots of that colour already waiting in slots; ties by column. "Exposed" = ACTIVE cell on
## the board edge or 4-adjacent to a CLEARED cell connected to the edge.
## ponytail: edge flood fill approximates per-slot routing; good enough to order branches.
static func rank_columns(host) -> Array:
	var board = host.get_board()
	var claim = host.get_claim_engine()
	var w: int = board.get_width()
	var h: int = board.get_height()
	var cleared := BoardState.CellState.CLEARED
	var open := PackedByteArray()
	open.resize(w * h)
	var stack: Array = []
	for i in range(w * h):
		if _on_edge(i, w, h) and board.get_cell_state(i) == cleared:
			open[i] = 1
			stack.append(i)
	while not stack.is_empty():
		var i: int = stack.pop_back()
		for n in _neighbours(i, w, h):
			if open[n] == 0 and board.get_cell_state(n) == cleared:
				open[n] = 1
				stack.append(n)
	var exposed := {}
	for i in range(w * h):
		if board.get_cell_state(i) != BoardState.CellState.ACTIVE or claim.is_target_claimed(i):
			continue
		var touch := _on_edge(i, w, h)
		if not touch:
			for n in _neighbours(i, w, h):
				if open[n] == 1:
					touch = true
					break
		if touch:
			var c: int = board.get_color_id(i)
			exposed[c] = int(exposed.get(c, 0)) + 1
	var slots = host.get_slots()
	for k in range(slots.get_slot_count()):
		if slots.is_occupied(k):
			var c: int = slots.get_color_id(k)
			exposed[c] = int(exposed.get(c, 0)) - (slots.get_remaining(k) - slots.get_committed(k))
	var supply = host.get_supply()
	var cols: Array = []
	for c in range(supply.get_column_count()):
		var f = supply.get_front(c)
		if f != null:
			cols.append([-int(exposed.get(f.get_color_id(), 0)), c + 1])
	cols.sort()
	var out: Array = []
	for e in cols:
		out.append(e[1])
	return out

static func _on_edge(i: int, w: int, h: int) -> bool:
	var x := i % w
	var y := i / w
	return x == 0 or y == 0 or x == w - 1 or y == h - 1

static func _neighbours(i: int, w: int, h: int) -> Array:
	var x := i % w
	var y := i / w
	var out: Array = []
	if x > 0:
		out.append(i - 1)
	if x < w - 1:
		out.append(i + 1)
	if y > 0:
		out.append(i - w)
	if y < h - 1:
		out.append(i + w)
	return out

## Campaign order of a production catalog entry (cached).
static func order_of(entry_id: String) -> int:
	if _orders.is_empty():
		var cat = LevelCatalog.new()
		if cat.load_manifest().ok:
			for e in cat.get_entries_ordered():
				_orders[e.id] = e.order
	return int(_orders.get(entry_id, -1))

## Build the level's host from an AppState frontier (temp save) full-rect in `parent`, let it
## lay out for one frame (runtime clock stopped), play it, free everything. A coroutine: await it.
static func play_level(parent: Node, entry_id: String, clicks: Array, dt: float = CANONICAL_DT, max_frames: int = MAX_FRAMES, rollout_plan = null) -> Dictionary:
	var order := order_of(entry_id)
	if order < 1:
		return {"won": false, "error": "not_in_catalog %s" % entry_id}
	var path := "user://real_play_%d_%d.save" % [order, Time.get_ticks_usec()]
	var app = AppState.new(path)
	for n in range(1, order):
		app.progression.record_win(n)
	var h = ProductionGameplayHost.new()
	h.app_state = app
	h.auto_build = false
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(h)
	var out: Dictionary
	if not h.build() or h.launch_entry_id != entry_id:
		out = {"won": false, "error": "host build %s -> %s %s" % [entry_id, h.launch_entry_id, h.get_build_error()]}
	else:
		h.get_runtime().set_process(false)
		await parent.get_tree().process_frame
		out = play_on_host(h, clicks, dt, max_frames, rollout_plan)
	h.free()
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	return out

## `clicks` at every dt of `dts` (default: every sensitivity dt); `results` maps dt label ->
## play result. A coroutine.
static func verify(parent: Node, entry_id: String, clicks: Array, dts: Array = SENSITIVITY_DTS) -> Dictionary:
	var results := {}
	var all := true
	for dt in dts:
		var r: Dictionary = await play_level(parent, entry_id, clicks, dt)
		results[dt_label(dt)] = r
		all = all and bool(r.get("won", false))
	return {"won": all, "results": results}

## Real-play search over column choices (the only decision). Deterministic backtracking
## search; a node is a forced click prefix, evaluated by ONE replay from a fresh host at the
## canonical dt that continues past the prefix as a rollout (plan column while on the plan
## prefix, then rank_columns' best), so the root replays the current plan to its failure. A
## node's children are the other legal columns at each of its rollout decisions. Order:
## limited discrepancy (fewest deviations from the rollout first; plain chronological DFS
## spent its whole budget under one early mistake on L1/L30), and within one discrepancy
## count the decision nearest the failure first. A canonical win is accepted only if it also
## wins at every sensitivity dt. Status: SOLVED (clicks, robust), UNWINNABLE_WITHIN_BUDGET
## (node budget hit: inconclusive) or EXHAUSTED (whole space explored, no win: unwinnable for
## every column order under the model). A 1/60-only win found on the way is returned as
## SOLVED with robust false when nothing robust exists (owner question).
static func search(parent: Node, entry_id: String, plan: Array, node_budget: int = NODE_BUDGET) -> Dictionary:
	plan = plan.map(func(c): return int(c))
	var nodes := 0
	var robust_rejects := 0
	var canonical_only: Array = []
	var buckets: Array = [[[]]]   # buckets[k] = FIFO of prefixes with k discrepancies
	var k := 0
	while k < buckets.size():
		if buckets[k].is_empty():
			k += 1
			continue
		if nodes >= node_budget:
			return _no_robust_win("UNWINNABLE_WITHIN_BUDGET", nodes, robust_rejects, canonical_only)
		var prefix: Array = buckets[k].pop_front()
		nodes += 1
		var r: Dictionary = await play_level(parent, entry_id, prefix, CANONICAL_DT, MAX_FRAMES, plan)
		if r.get("won", false):
			# The rollout already is the canonical run (replay is deterministic); check the others.
			if (await verify(parent, entry_id, r["taken"], [1.0 / 30.0, 1.0 / 120.0]))["won"]:
				return {"status": "SOLVED", "clicks": r["taken"], "nodes": nodes, "robust": true, "robust_rejects": robust_rejects}
			robust_rejects += 1
			if canonical_only.is_empty():
				canonical_only = r["taken"]
			continue
		var taken: Array = r.get("taken", [])
		var legal_at: Array = r.get("legal_at", [])
		if buckets.size() == k + 1:
			buckets.append([])
		for d in range(taken.size() - 1, prefix.size() - 1, -1):
			if legal_at[d] is Array:
				for alt in legal_at[d]:
					if alt != taken[d]:
						buckets[k + 1].append(taken.slice(0, d) + [alt])
	return _no_robust_win("EXHAUSTED", nodes, robust_rejects, canonical_only)

## No win at every sensitivity dt: a 1/60-only win is still accepted, marked robust false
## (owner question); otherwise the status stands.
static func _no_robust_win(status: String, nodes: int, robust_rejects: int, canonical_only: Array) -> Dictionary:
	if not canonical_only.is_empty():
		return {"status": "SOLVED", "clicks": canonical_only, "nodes": nodes, "robust": false, "robust_rejects": robust_rejects}
	return {"status": status, "nodes": nodes, "robust_rejects": robust_rejects}

# ------------------------------------------------------------ plans + provenance ----

## sha256 of a JSON file's text with CRLF normalized to LF (the git blob bytes), so a
## Windows checkout and CI hash identically.
static func plan_sha256(path: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(FileAccess.get_file_as_string(path).replace("\r\n", "\n").to_utf8_buffer())
	return ctx.finish().hex_encode()

## Provenance records by levelId ({} when the file is missing or of another schema).
static func load_provenance() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(PROVENANCE_PATH):
		return out
	var d = JSON.parse_string(FileAccess.get_file_as_string(PROVENANCE_PATH))
	if typeof(d) == TYPE_DICTIONARY and d.get("schema", "") == PROVENANCE_SCHEMA:
		for rec in d.get("records", []):
			out[String(rec["levelId"])] = rec
	return out

## The clicks a catalog entry is played with: its plan's intendedColumnClicks, or for a level
## without a plan (Level 1, M23 generator) the searched clicks in its provenance record.
static func clicks_for(entry_id: String, plan_path: String, provenance: Dictionary) -> Array:
	var src = null
	if not plan_path.is_empty():
		src = JSON.parse_string(FileAccess.get_file_as_string(plan_path))["intendedColumnClicks"]
	else:
		src = provenance.get(entry_id, {}).get("clicks", null)
	var out: Array = []
	if src is Array:
		for c in src:
			out.append(int(c))
	return out
