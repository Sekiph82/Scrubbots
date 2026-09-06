extends RefCounted
## RoutingLabScenarios — M17 deterministic scenario builders for the Routing
## Prototype Lab. Preload it (AL-001). Stateless: only static functions.
##
## Scenarios build a BoardState (ACTIVE/CLEARED) plus already-assigned target
## indices and slot origins. Target assignment is deterministic and lives HERE,
## OUTSIDE any RoutingSystem — routing never selects a target (M17 multi-bot
## semantics). No Scrubbot nodes, no reservation/dispatch orchestration.
##
## Cell model matches the experimental access truth: CLEARED = open corridor,
## ACTIVE = blocker, an ACTIVE target is enterable only as a final endpoint.
## Boards are laid out CLEARED (open) with ACTIVE cells placed only where a
## blocker or an assigned target is wanted, so scenarios stay easy to reason
## about.

const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")

## An open board: every cell CLEARED (free space).
static func make_open_board(w: int, h: int) -> BoardState:
	var board := BoardDebugFixtures.make_board(w, h)
	for i in board.get_cell_count():
		board.set_cell_state(i, BoardState.CellState.CLEARED)
	return board

static func _set_active(board: BoardState, x: int, y: int) -> void:
	var idx: int = board.get_cell_index(x, y)
	if idx >= 0:
		board.set_cell_state(idx, BoardState.CellState.ACTIVE)

## Slot origins outside the board, deterministic, alternating left/right so
## multi-route sets produce genuine crossing pressure. Count origins spread over
## the board height.
static func slot_origins(w: int, h: int, count: int = 5) -> Array:
	var out: Array = []
	for i in range(count):
		var frac: float = (float(i) + 0.5) / float(count)
		var y: float = clampf(frac * float(h), 0.5, float(h) - 0.5)
		if i % 2 == 0:
			out.append(Vector2(-2.0, y)) # left exterior
		else:
			out.append(Vector2(float(w) + 2.0, y)) # right exterior
	return out

## Build already-assigned RouteRequests: each target cycles through the origins.
## Origins are per-request slot positions (a bot leaves its own slot).
static func build_requests(board: BoardState, targets: Array, origins: Array) -> Array:
	var reqs: Array = []
	for i in range(targets.size()):
		var origin: Vector2 = origins[i % origins.size()]
		var req = RouteRequest.for_target(board, origin, int(targets[i]))
		if req != null:
			reqs.append(req)
	return reqs

## Deterministically pick `count` ACTIVE target cells, evenly spaced across the
## board interior. Used by open-board multi-route scenarios.
static func spread_targets(board: BoardState, count: int) -> Array:
	var w: int = board.get_width()
	var h: int = board.get_height()
	var targets: Array = []
	# Interior lattice avoiding the outermost ring so neighbours stay open.
	var cols: int = int(ceil(sqrt(float(count))))
	var rows: int = int(ceil(float(count) / float(cols)))
	var placed: int = 0
	for r in range(rows):
		for c in range(cols):
			if placed >= count:
				break
			var x: int = int(round((float(c) + 1.0) / float(cols + 1) * float(w - 1)))
			var y: int = int(round((float(r) + 1.0) / float(rows + 1) * float(h - 1)))
			x = clampi(x, 1, w - 2)
			y = clampi(y, 1, h - 2)
			var idx: int = board.get_cell_index(x, y)
			# Ensure ACTIVE + unique.
			if not targets.has(idx):
				board.set_cell_state(idx, BoardState.CellState.ACTIVE)
				targets.append(idx)
				placed += 1
	return targets

# ------------------------------------------------------------- scenarios --

## S1 — Open/simple. Direct-route baseline friendly.
static func make_s1() -> Dictionary:
	var board := make_open_board(12, 9)
	var targets := spread_targets(board, 3)
	return {
		"id": "S1", "name": "Open / simple", "board": board,
		"targets": targets, "origins": slot_origins(12, 9),
		"notes": "All-open board, 3 targets; direct route should succeed.",
	}

## S2 — Single blocker / detour. Straight segment blocked; grid can detour.
static func make_s2() -> Dictionary:
	var board := make_open_board(14, 11)
	# Vertical wall at x=7, gap at the top two rows.
	for y in range(2, 11):
		_set_active(board, 7, y)
	var tx: int = 11
	var ty: int = 5
	_set_active(board, tx, ty)
	var target: int = board.get_cell_index(tx, ty)
	return {
		"id": "S2", "name": "Single blocker / detour", "board": board,
		"targets": [target], "origins": [Vector2(-2.0, 5.5)],
		"notes": "Wall at x=7 (gap rows 0-1). Direct fails; grid detours over the top.",
	}

## S3 — Fully enclosed assigned target. No prototype may route or retarget.
static func make_s3() -> Dictionary:
	var board := make_open_board(11, 11)
	var tx: int = 5
	var ty: int = 5
	_set_active(board, tx, ty)          # the assigned target
	_set_active(board, tx + 1, ty)      # enclose N/E/S/W
	_set_active(board, tx - 1, ty)
	_set_active(board, tx, ty + 1)
	_set_active(board, tx, ty - 1)
	var target: int = board.get_cell_index(tx, ty)
	return {
		"id": "S3", "name": "Fully enclosed target", "board": board,
		"targets": [target], "origins": [Vector2(-2.0, 5.5)],
		"notes": "Target at (5,5) enclosed by 4 ACTIVE cells; expect NO_ROUTE.",
	}

## S4 — Newly opened after clear. Starts enclosed like S3; clearing the west
## neighbour + a corridor to the left edge opens the SAME target.
static func make_s4() -> Dictionary:
	var d := make_s3()
	d["id"] = "S4"
	d["name"] = "Newly opened after clear"
	# Prerequisite cells to CLEAR to open a corridor from the left edge to the
	# west neighbour of the target (row 5, x = 0..4).
	var board: BoardState = d["board"]
	var clear_cells: Array = []
	for x in range(0, 5):
		clear_cells.append(board.get_cell_index(x, 5))
	d["clear_after"] = clear_cells
	d["notes"] = "Enclosed target; clearing row-5 cells x=0..4 opens the SAME target."
	return d

## S5 — Multi-route crossing pressure (5/10/25 driven by count).
static func make_s5(count: int = 10) -> Dictionary:
	var board := make_open_board(30, 30)
	var targets := spread_targets(board, count)
	return {
		"id": "S5", "name": "Crossing pressure (%d)" % count, "board": board,
		"targets": targets, "origins": slot_origins(30, 30),
		"notes": "%d targets from alternating left/right origins." % count,
	}

## S6 — High-density stress (>25 routes; default 50, bounded for headless).
static func make_s6(count: int = 50) -> Dictionary:
	var board := make_open_board(40, 40)
	var targets := spread_targets(board, count)
	return {
		"id": "S6", "name": "Stress density (%d)" % count, "board": board,
		"targets": targets, "origins": slot_origins(40, 40),
		"notes": "%d routes on a 40x40 open board." % count,
	}

## S7 — 59x59 production maximum.
static func make_s7(count: int = 25) -> Dictionary:
	var board := make_open_board(59, 59)
	var targets := spread_targets(board, count)
	return {
		"id": "S7", "name": "59x59 (max)", "board": board,
		"targets": targets, "origins": slot_origins(59, 59),
		"notes": "Production maximum 59x59, %d routes." % count,
	}

## S8 — Legal rectangular Very Hard (53x59).
static func make_s8(count: int = 25) -> Dictionary:
	var board := make_open_board(53, 59)
	var targets := spread_targets(board, count)
	return {
		"id": "S8", "name": "Rectangular Very Hard 53x59", "board": board,
		"targets": targets, "origins": slot_origins(53, 59),
		"notes": "Legal rectangular Very Hard 53x59, %d routes." % count,
	}

## Ordered scenario registry for the lab UI: {id, label, builder:Callable}.
static func registry() -> Array:
	return [
		{"id": "S1", "label": "S1 Open/simple", "builder": func(): return make_s1()},
		{"id": "S2", "label": "S2 Blocker/detour", "builder": func(): return make_s2()},
		{"id": "S3", "label": "S3 Enclosed (no route)", "builder": func(): return make_s3()},
		{"id": "S4", "label": "S4 Opened after clear", "builder": func(): return make_s4()},
		{"id": "S5", "label": "S5 Crossing x10", "builder": func(): return make_s5(10)},
		{"id": "S6", "label": "S6 Stress x50", "builder": func(): return make_s6(50)},
		{"id": "S7", "label": "S7 59x59", "builder": func(): return make_s7(25)},
		{"id": "S8", "label": "S8 Rect VeryHard", "builder": func(): return make_s8(25)},
	]
