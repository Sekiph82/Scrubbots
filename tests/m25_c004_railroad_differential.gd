extends SceneTree
## M25-C004 V01 — exact-equivalent Railroad acceleration (S2): point-for-point differential suite.
##
## Optimized production ProductionRoutingSystem vs the FROZEN pre-S2 oracle
## (tests/support/m25_c004_railroad_baseline.gd, verbatim copy of commit aadc5725). For every
## comparison the observable RouteResult must be bit-identical: success, failure reason, target
## index, point count and EVERY point (byte-exact) — never just "same length / same target".
##
##   t1 generated state matrix: production levels 1..10, synthetic 20/32/38/59 + rectangular
##      boards, many ACTIVE/CLEARED topologies (peel, uniform, rooms+corridors, stripes/bands,
##      late-game sparse ACTIVE, checkerboard, bottom-up peel), tie-prone / production-like /
##      outside / debug-inside origins, both routing modes (railway-first + equal weight), and
##      extra tunings (fallback proof).
##   t2 non-canonical access / board / request adversarial cases (generic path must be unchanged).
##   t3 path accounting: the layered path is actually exercised (hit/no-route/guard-fallback counts).
##
## Args: godot --headless --path . -s res://tests/m25_c004_railroad_differential.gd [-- <evidence.json> [scale]]

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const Baseline = preload("res://tests/support/m25_c004_railroad_baseline.gd")

const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const PRODUCTION := ["res://data/levels/m21_level_001_hazard_bot.json", "res://data/levels/level_002_apple.json",
	"res://data/levels/level_003_palm_tree.json", "res://data/levels/level_004_orange_cat.json",
	"res://data/levels/level_005_party_toucan.json", "res://data/levels/level_006_chicken.json",
	"res://data/levels/level_007_pigeon.json", "res://data/levels/level_008_butterfly.json",
	"res://data/levels/level_009_frog.json", "res://data/levels/level_010_ice_cube.json"]

var _fail := 0
var _base = Baseline.new()
var _opt = ProductionRoutingSystem.new()
var _scale := 1
var _total := 0
var _both_ok := 0
var _both_fail := 0
var _diffs := 0
var _paths := {}          # layered path classification
var _fail_reasons := {}
var _by_mode := {}
var _by_group := {}
var _points_checked := 0
var _first_diffs: Array = []
var _states := 0
var _t4only := false
var _quick := false   # mutation-check aid: small boards only

# ---------------------------------------------------------------- doubles ----
## Same behaviour, different script => must take the generic (frozen) path.
class SubAccess:
	extends "res://scripts/gameplay/routing/production_access_query.gd"

## Duck-typed wrapper: full seam delegated to a real ProductionAccessQuery.
class WrapAccess:
	extends RefCounted
	var real
	func _init(r) -> void:
		real = r
	func is_segment_traversable(a: Vector2, b: Vector2, idx: int) -> bool:
		return real.is_segment_traversable(a, b, idx)
	func classify_cell(cx: int, cy: int, idx: int) -> int:
		return real.classify_cell(cx, cy, idx)
	func cell_of_point(p: Vector2) -> Vector2i:
		return real.cell_of_point(p)
	func is_bound_to(b) -> bool:
		return real.is_bound_to(b)

## Non-canonical edge blocker: rejects every segment ending in one specific cell centre.
class EdgeBlockAccess:
	extends "res://scripts/gameplay/routing/production_access_query.gd"
	var blocked := Vector2i(-99, -99)
	func is_segment_traversable(a: Vector2, b: Vector2, idx: int) -> bool:
		if Vector2i(int(floor(b.x)), int(floor(b.y))) == blocked and b.is_equal_approx(Vector2(blocked.x + 0.5, blocked.y + 0.5)):
			return false
		return super.is_segment_traversable(a, b, idx)

## Board subclass: get_script() != BoardState => the snapshot fast path must not engage.
class SpyBoard:
	extends "res://scripts/gameplay/board/board_state.gd"
	var reads := 0
	func get_cell_state(index: int) -> int:
		reads += 1
		return super.get_cell_state(index)

func _initialize() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	if args.size() > 1:
		_scale = maxi(1, int(args[1]))
	_quick = args.size() > 2 and args[2] == "quick"
	_t4only = args.size() > 2 and args[2] == "t4only"
	_opt.collect_work_counts = true
	if not _t4only:
		_t1_matrix()
		_t2_adversarial()
	_t4_tie_guard()
	_t3_accounting()
	var rep := {"total_comparisons": _total, "both_success": _both_ok, "both_failure": _both_fail, "diffs": _diffs,
		"points_compared": _points_checked, "states": _states, "layered_paths": _paths, "failure_reasons": _fail_reasons,
		"by_mode": _by_mode, "by_group": _by_group, "first_diffs": _first_diffs, "scale": _scale,
		"oracle": "tests/support/m25_c004_railroad_baseline.gd @ aadc57253d45dcd6b71ca8cc1b00b7a7684e0574"}
	print("REPORT %s" % JSON.stringify(rep))
	if args.size() > 0:
		var f := FileAccess.open(args[0], FileAccess.WRITE)
		f.store_string(JSON.stringify(rep, "  "))
		f.close()
	print("m25_c004_railroad_differential: %s (%d comparisons, %d diffs, %d failed checks)" % [
		"PASS" if _fail == 0 and _diffs == 0 else "FAIL", _total, _diffs, _fail])
	quit(0 if _fail == 0 and _diffs == 0 else 1)

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)

# ------------------------------------------------------------ comparison -----
## Runs frozen oracle + optimized on the SAME request/board/access and demands bit-identity.
func _cmp(group: String, request, board, access, cost: float) -> bool:
	_base.interior_step_cost = cost
	_opt.interior_step_cost = cost
	_opt.last_work_counts = {}
	var a = _base.compute_route(request, board, access)
	var b = _opt.compute_route(request, board, access)
	var path: String = String(_opt.last_work_counts.get("path", "generic"))
	_total += 1
	_paths[path] = int(_paths.get(path, 0)) + 1
	var mk := "cost=%s" % str(cost)
	_by_mode[mk] = int(_by_mode.get(mk, 0)) + 1
	_by_group[group] = int(_by_group.get(group, 0)) + 1
	var same := true
	var why := ""
	if a.success != b.success:
		same = false
		why = "success %s vs %s" % [a.success, b.success]
	elif String(a.failure_reason) != String(b.failure_reason):
		same = false
		why = "reason %s vs %s" % [a.failure_reason, b.failure_reason]
	elif a.target_index != b.target_index:
		same = false
		why = "target %d vs %d" % [a.target_index, b.target_index]
	else:
		var pa: PackedVector2Array = a.get_points()
		var pb: PackedVector2Array = b.get_points()
		if pa.size() != pb.size():
			same = false
			why = "point count %d vs %d" % [pa.size(), pb.size()]
		elif pa.to_byte_array() != pb.to_byte_array():
			same = false
			why = "points differ"
		_points_checked += pa.size()
	if a.success:
		_both_ok += 1
	else:
		_both_fail += 1
		var rk := String(a.failure_reason)
		_fail_reasons[rk] = int(_fail_reasons.get(rk, 0)) + 1
	if not same:
		_diffs += 1
		if _first_diffs.size() < 20:
			_first_diffs.append("%s cost=%s origin=%s target=%d path=%s: %s" % [group, str(cost), str(request.start_position) if request is RouteRequest else "?", request.target_index if request is RouteRequest else -1, path, why])
	return same

func _req(board, origin: Vector2, idx: int):
	return RouteRequest.for_target(board, origin, idx)

# ---------------------------------------------------------- t1 state matrix ---
func _origins(w: int, h: int, rng: RandomNumberGenerator) -> Array:
	var oy: float = float(h) + 13.78
	var out: Array = []
	# Production-like slot origins (six slots) below the board.
	for i in range(6):
		out.append(Vector2(float(w) * (0.1064 + 0.1576 * i), oy))
	# Tie-prone: integer / half-integer entry x, edges, exact centre.
	var mid: int = w / 2
	out.append(Vector2(float(mid) + 0.5, float(h) + 2.0))
	out.append(Vector2(float(mid), float(h) + 2.0))
	out.append(Vector2(0.0, float(h) + 5.0))
	out.append(Vector2(float(w), float(h) + 5.0))
	out.append(Vector2(0.5, float(h) + 3.5))
	out.append(Vector2(float(w) - 0.5, float(h) + 3.5))
	out.append(Vector2(float(w) * 0.25, float(h) + 1.5))
	# Beyond the rail span (clamped entry).
	out.append(Vector2(-7.3, float(h) + 5.0))
	out.append(Vector2(float(w) + 9.1, float(h) + 2.2))
	# Other outside starts (top / left / right / corner) - same bottom-connector policy.
	out.append(Vector2(float(w) * 0.4, -4.2))
	out.append(Vector2(-3.3, float(h) * 0.6))
	out.append(Vector2(float(w) + 4.7, float(h) * 0.3))
	out.append(Vector2(-2.0, -2.0))
	# Random extra.
	for i in range(3):
		out.append(Vector2(rng.randf_range(-3.0, float(w) + 3.0), float(h) + rng.randf_range(1.0, 40.0)))
	return out

func _inside_origins(w: int, h: int) -> Array:
	return [Vector2(3.5, 4.5), Vector2(float(w) - 0.5, float(h) - 0.5), Vector2(float(w) * 0.5 + 0.3, float(h) * 0.5 + 0.7)]

func _make_board(w: int, h: int, seed_v: int, k: int = 6):
	var cells := PackedInt32Array()
	for y in range(h):
		for x in range(w):
			cells.append(x * k / w)
	return BoardState.from_level_data(LevelData.new(1, "m25c004_%dx%d_%d" % [w, h, seed_v], "m25c004", "TEST", w, h,
		PackedStringArray(HEX.slice(0, k)), cells))

func _apply_pattern(board, kind: int, rng: RandomNumberGenerator, param: float) -> void:
	board.restore_all_active()
	var w: int = board.get_width()
	var h: int = board.get_height()
	var CL = BoardState.CellState.CLEARED
	var AC = BoardState.CellState.ACTIVE
	match kind:
		0:  # ring peel: clear cells whose ring layer < L, each with probability 1-skip
			var lmax: int = rng.randi_range(1, maxi(1, mini(w, h) / 2))
			var skip: float = param * 0.35
			for y in range(h):
				for x in range(w):
					if mini(mini(x, y), mini(w - 1 - x, h - 1 - y)) < lmax and rng.randf() >= skip:
						board.set_cell_state(y * w + x, CL)
		1:  # uniform random
			for i in range(w * h):
				if rng.randf() < param:
					board.set_cell_state(i, CL)
		2:  # rooms + corridors + sealed pockets
			var rooms: int = rng.randi_range(2, 8)
			for _r in range(rooms):
				var rw: int = rng.randi_range(2, maxi(3, w / 3))
				var rh: int = rng.randi_range(2, maxi(3, h / 3))
				var rx: int = rng.randi_range(0, w - rw)
				var ry: int = rng.randi_range(0, h - rh)
				for y in range(ry, ry + rh):
					for x in range(rx, rx + rw):
						board.set_cell_state(y * w + x, CL)
			var walks: int = rng.randi_range(2, 8)
			for _r in range(walks):
				var x: int = 0 if rng.randf() < 0.5 else rng.randi_range(0, w - 1)
				var y: int = rng.randi_range(0, h - 1) if x == 0 else 0
				for _s in range(rng.randi_range(w / 2, w * 2)):
					board.set_cell_state(y * w + x, CL)
					var d: int = rng.randi_range(0, 3)
					x = clampi(x + (1 if d == 1 else (-1 if d == 3 else 0)), 0, w - 1)
					y = clampi(y + (1 if d == 2 else (-1 if d == 0 else 0)), 0, h - 1)
		3:  # vertical stripes
			var stripes: int = 6
			for s in range(stripes):
				if rng.randf() < param:
					for y in range(h):
						for x in range(s * w / stripes, (s + 1) * w / stripes):
							board.set_cell_state(y * w + x, CL)
			for i in range(w * h / 25):
				board.set_cell_state(rng.randi_range(0, w * h - 1), CL)
		4:  # horizontal bands with gaps
			var bands: int = rng.randi_range(2, 7)
			for _b in range(bands):
				var by: int = rng.randi_range(0, h - 1)
				for x in range(w):
					if rng.randf() < 0.92:
						board.set_cell_state(by * w + x, CL)
		5:  # late game: everything cleared, sparse ACTIVE remain
			for i in range(w * h):
				board.set_cell_state(i, CL)
			var keep: int = maxi(1, int(param * float(w * h)))
			for _k in range(keep):
				board.set_cell_state(rng.randi_range(0, w * h - 1), AC)
		6:  # checkerboard (diagonal-only connectivity) with random extra clears
			for y in range(h):
				for x in range(w):
					if (x + y) % 2 == 0 or rng.randf() < param * 0.3:
						board.set_cell_state(y * w + x, CL)
		7:  # bottom-up row peel with skips (M15-style peel)
			var rows: int = rng.randi_range(1, h)
			for y in range(h - 1, h - 1 - rows, -1):
				for x in range(w):
					if rng.randf() >= param * 0.25:
						board.set_cell_state(y * w + x, CL)
		8:  # large open area with a few walls
			for i in range(w * h):
				board.set_cell_state(i, CL)
			for _k in range(rng.randi_range(2, 6)):
				var wx: int = rng.randi_range(0, w - 1)
				var wy: int = rng.randi_range(0, h - 1)
				var horiz: bool = rng.randf() < 0.5
				var ln: int = rng.randi_range(w / 4, w)
				for s in range(ln):
					var xx: int = wx + (s if horiz else 0)
					var yy: int = wy + (0 if horiz else s)
					if xx < w and yy < h:
						board.set_cell_state(yy * w + xx, AC)

func _pick_targets(board, rng: RandomNumberGenerator, n_frontier: int, n_perim: int, n_rand: int) -> Array:
	var w: int = board.get_width()
	var h: int = board.get_height()
	var frontier: Array = []
	var perim: Array = []
	var actives: Array = []
	for i in range(w * h):
		if board.get_cell_state(i) != BoardState.CellState.ACTIVE:
			continue
		actives.append(i)
		var x: int = i % w
		var y: int = i / w
		if x == 0 or y == 0 or x == w - 1 or y == h - 1:
			perim.append(i)
		var adj := false
		for d in [[0, -1], [1, 0], [0, 1], [-1, 0]]:
			var nx: int = x + d[0]
			var ny: int = y + d[1]
			if nx >= 0 and ny >= 0 and nx < w and ny < h and board.get_cell_state(ny * w + nx) == BoardState.CellState.CLEARED:
				adj = true
				break
		if adj:
			frontier.append(i)
	var out := {}
	for pair in [[frontier, n_frontier], [perim, n_perim], [actives, n_rand]]:
		var src: Array = pair[0]
		for _k in range(mini(pair[1], src.size())):
			out[src[rng.randi_range(0, src.size() - 1)]] = true
	return out.keys()

func _run_state(group: String, board, rng: RandomNumberGenerator, origins: Array, n_targets: Array, cost_modes: Array) -> void:
	_states += 1
	var access = ProductionAccessQuery.new(board)
	var targets := _pick_targets(board, rng, n_targets[0], n_targets[1], n_targets[2])
	# A per-state origin subset keeps volume bounded while every origin class recurs.
	var subset: Array = []
	for i in range(origins.size()):
		if i < 3 or rng.randf() < 0.25:
			subset.append(origins[i])
	for t in targets:
		for o in subset:
			for c in cost_modes:
				_cmp(group, _req(board, o, t), board, access, c)

func _t1_matrix() -> void:
	print("[t1 generated state matrix: optimized == frozen oracle, point for point]")
	var boards: Array = []
	for p in PRODUCTION:
		var r = LevelLoader.load_from_path(p)
		if r.is_ok():
			boards.append(["prod:" + p.get_file(), BoardState.from_level_data(r.level_data), 3])
	var sizes := [[20, 20], [24, 40], [40, 24], [32, 32], [38, 38], [23, 31], [59, 59], [45, 27]]
	if _quick:
		sizes = [[20, 20], [24, 40], [23, 31]]
		boards = boards.slice(0, 3)
	for sz in sizes:
		boards.append(["syn:%dx%d" % sz, _make_board(sz[0], sz[1], 1), 3])
	var seed_base := 0xC004
	for entry in boards:
		var board = entry[1]
		var w: int = board.get_width()
		var h: int = board.get_height()
		var big: bool = w * h > 2000
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(str(entry[0])) ^ seed_base
		var origins := _origins(w, h, rng)
		# Pattern schedule: each kind at several parameters; big boards get fewer states.
		var kinds := [0, 1, 2, 3, 4, 5, 6, 7, 8]
		var params := [0.2, 0.55, 0.9]
		var reps: int = 1
		for _rep in range(reps * _scale):
			for kind in kinds:
				for pi in range(params.size()):
					if big and pi == 1:
						continue
					_apply_pattern(board, kind, rng, params[pi] if kind != 5 else params[pi] * 0.05)
					var nt := [2, 1, 1] if big else [3, 1, 1]
					_run_state("t1:" + String(entry[0]).split(":")[0], board, rng, origins, nt, [ProductionRoutingSystem.INTERIOR_STEP_COST, ProductionRoutingSystem.TOTAL_TRAVEL_COST])
		# Extra tunings (generic fallback proof) on a couple of states.
		for cost in [0.5, 2.0, 500.0, 999.0, 1000.0]:
			_apply_pattern(board, 1, rng, 0.55)
			var acc = ProductionAccessQuery.new(board)
			for t in _pick_targets(board, rng, 3, 1, 1):
				for o in origins.slice(0, 4):
					_cmp("t1:tunings", _req(board, o, t), board, acc, cost)
		# Inside-board (debug interior planner) origins: generic path unchanged.
		_apply_pattern(board, 1, rng, 0.6)
		var acc2 = ProductionAccessQuery.new(board)
		for t in _pick_targets(board, rng, 4, 1, 1):
			for o in _inside_origins(w, h):
				for c in [ProductionRoutingSystem.INTERIOR_STEP_COST, ProductionRoutingSystem.TOTAL_TRAVEL_COST]:
					_cmp("t1:inside_origin", _req(board, o, t), board, acc2, c)
		board.restore_all_active()
	print("  t1 total so far: %d comparisons, %d diffs" % [_total, _diffs])
	_ok(_diffs == 0, "t1: zero diffs across %d comparisons" % _total)

# ---------------------------------------------------------- t2 adversarial ----
func _t2_adversarial() -> void:
	print("[t2 non-canonical access / board / request: generic semantics unchanged]")
	var before := _diffs
	var n0 := _total
	var rng := RandomNumberGenerator.new()
	rng.seed = 0xBEEF
	for sz in [[20, 20], [32, 32], [24, 40]]:
		var board = _make_board(sz[0], sz[1], 7)
		var origins := _origins(sz[0], sz[1], rng)
		for kind in [0, 1, 2, 8]:
			_apply_pattern(board, kind, rng, 0.5)
			var real = ProductionAccessQuery.new(board)
			var targets := _pick_targets(board, rng, 5, 1, 1)
			var eb := EdgeBlockAccess.new(board)
			# Block one random CLEARED cell's centre.
			for i in range(sz[0] * sz[1]):
				var cand: int = rng.randi_range(0, sz[0] * sz[1] - 1)
				if board.get_cell_state(cand) == BoardState.CellState.CLEARED:
					eb.blocked = Vector2i(cand % sz[0], cand / sz[0])
					break
			for t in targets:
				for o in origins.slice(0, 6):
					for c in [1000.0, 1.0]:
						_cmp("t2:subclass_access", _req(board, o, t), board, SubAccess.new(board), c)
						_cmp("t2:wrapper_access", _req(board, o, t), board, WrapAccess.new(real), c)
						_cmp("t2:edge_block_access", _req(board, o, t), board, eb, c)
			# Board subclass (script != BoardState): snapshot fast path must not engage.
			var spy = SpyBoard.new()
			spy._width = board._width
			spy._height = board._height
			spy._color_ids = board._color_ids.duplicate()
			spy._cell_states = board._cell_states.duplicate()
			var spy_access = ProductionAccessQuery.new(spy)
			for t in targets:
				for o in origins.slice(0, 4):
					_cmp("t2:board_subclass", _req(spy, o, t), spy, spy_access, 1000.0)
	# Invalid / hostile requests (identical validation path).
	var b = _make_board(20, 20, 9)
	var acc = ProductionAccessQuery.new(b)
	b.set_cell_state(5, BoardState.CellState.CLEARED)
	var junk: Array = [null, 7, "x", Vector2.ZERO, RefCounted.new()]
	for j in junk:
		_ok(_same_result(_base.compute_route(j, b, acc), _opt.compute_route(j, b, acc)), "junk request %s identical" % str(j))
	var good = _req(b, Vector2(10.5, 25.0), 100)
	_ok(_same_result(_base.compute_route(good, b, null), _opt.compute_route(good, b, null)), "null access identical")
	_ok(_same_result(_base.compute_route(good, b, 5), _opt.compute_route(good, b, 5)), "scalar access identical")
	_ok(_same_result(_base.compute_route(good, null, acc), _opt.compute_route(good, null, acc)), "null board identical")
	var other = _make_board(20, 20, 10)
	_ok(_same_result(_base.compute_route(good, other, acc), _opt.compute_route(good, other, acc)), "unbound (other board) access identical")
	var cleared_target = _req(b, Vector2(10.5, 25.0), 5)   # target already CLEARED -> TARGET_NOT_ACTIVE
	_ok(_same_result(_base.compute_route(cleared_target, b, acc), _opt.compute_route(cleared_target, b, acc)), "non-ACTIVE target identical")
	var bad_idx = _req(b, Vector2(10.5, 25.0), 100)
	bad_idx.target_index = 9999
	_ok(_same_result(_base.compute_route(bad_idx, b, acc), _opt.compute_route(bad_idx, b, acc)), "invalid target index identical")
	var nonfinite = _req(b, Vector2(10.5, 25.0), 100)
	nonfinite.start_position = Vector2(NAN, 3.0)
	_ok(_same_result(_base.compute_route(nonfinite, b, acc), _opt.compute_route(nonfinite, b, acc)), "non-finite origin identical")
	_ok(_diffs == before, "t2: zero diffs across %d comparisons" % (_total - n0))

func _same_result(a, b) -> bool:
	return a.success == b.success and String(a.failure_reason) == String(b.failure_reason) and a.target_index == b.target_index \
		and a.get_points().to_byte_array() == b.get_points().to_byte_array()

# ---------------------------------------------------------- t4 tie guard ------
## Open boards + symmetric targets + entry x on / just beside quarter-integer tie points: exact ties stay on the
## layered path (rank tie-break), sub-eps near-ties must trip the guard and fall back, all point-identical.
func _t4_tie_guard() -> void:
	print("[t4 exact-tie / near-tie guard]")
	var before := _diffs
	var n0 := _total
	var hits0 := int(_paths.get("guard_fallback", 0))
	for sz in [[20, 20], [21, 20], [32, 32]]:
		var w: int = sz[0]
		var h: int = sz[1]
		var board = _make_board(w, h, 3)
		for i in range(w * h):
			board.set_cell_state(i, BoardState.CellState.CLEARED)
		var acc = ProductionAccessQuery.new(board)
		var targets: Array = []
		for c in [[w / 2, h / 2], [w / 2 - 1, h / 2], [3, 3], [w / 2, 4]]:
			var ti: int = int(c[1]) * w + int(c[0])
			board.set_cell_state(ti, BoardState.CellState.ACTIVE)
			targets.append(ti)
		for ti in targets:
			board.set_cell_state(ti, BoardState.CellState.ACTIVE)
		for ti in targets:
			for k in range(-4, w * 4 + 4):
				for delta in [0.0, 1e-9, 1e-4, 5e-4, 9e-4, 0.013]:
					_cmp("t4:tie_guard", _req(board, Vector2(float(k) * 0.25 + delta, float(h) + 5.0), ti), board, acc, 1000.0)
	# Corridor boards: the target sits mid-row of a fully cleared row, so LEFT and RIGHT ingress cells are both
	# critical (equal interior steps) and their costs are 2*(e - w/2) apart => exact tie at e = w/2, near-ties beside it.
	for sz in [[21, 21], [31, 24], [41, 30]]:
		var w2: int = sz[0]
		var h2: int = sz[1]
		for r in [3, h2 / 2, h2 - 3]:
			var b2 = _make_board(w2, h2, 3)
			for x in range(w2):
				b2.set_cell_state(r * w2 + x, BoardState.CellState.CLEARED)
			var ti: int = r * w2 + w2 / 2
			b2.set_cell_state(ti, BoardState.CellState.ACTIVE)
			var acc3 = ProductionAccessQuery.new(b2)
			for delta in [0.0, 1e-12, -1e-12, 1e-9, -1e-9, 1e-6, -1e-6, 1e-4, -1e-4, 3e-4, -3e-4, 4.9e-4, -4.9e-4, 5.1e-4, -5.1e-4, 2e-3, -2e-3, 0.05, -0.05, 0.5]:
				for oy in [float(h2) + 3.0, float(h2) + 13.78]:
					_cmp("t4:corridor_tie", _req(b2, Vector2(float(w2) * 0.5 + delta, oy), ti), b2, acc3, 1000.0)
	var hits := int(_paths.get("guard_fallback", 0)) - hits0
	print("  t4: %d comparisons, guard_fallback hits %d" % [_total - n0, hits])
	_ok(_diffs == before, "t4: zero diffs across %d tie/near-tie comparisons" % (_total - n0))
	_ok(hits > 0, "near-tie guard actually tripped and fell back (%d hits)" % hits)

# ---------------------------------------------------------- t3 accounting -----
func _t3_accounting() -> void:
	print("[t3 path accounting] %s" % JSON.stringify(_paths))
	if _t4only:
		return
	_ok(_total >= 10000 * _scale, "at least %d comparisons (got %d)" % [10000 * _scale, _total])
	_ok(int(_paths.get("layered", 0)) >= 2000, "layered success path exercised (%d)" % int(_paths.get("layered", 0)))
	_ok(int(_paths.get("layered_no_route", 0)) >= 200, "layered NO_ROUTE path exercised (%d)" % int(_paths.get("layered_no_route", 0)))
	_ok(int(_paths.get("generic", 0)) >= 500, "generic (fallback / non-eligible) path exercised (%d)" % int(_paths.get("generic", 0)))
	_ok(_both_ok >= 2000 and _both_fail >= 500, "both successes (%d) and failures (%d) compared" % [_both_ok, _both_fail])
	# Explicit guard-fallback probe is reported (may legitimately be 0 for production-like origins).
	print("  guard_fallback hits: %d" % int(_paths.get("guard_fallback", 0)))
