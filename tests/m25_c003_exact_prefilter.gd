extends SceneTree
## M25-C003 V01 — exact-safe target prefilter (S1) + laid-out 59x59 harness (S0) suite.
##
##   t1 touch-mask exactness: materialised ProductionTargetAccess mask == the pre-C003
##      per-call M52 necessary condition (reference copy below) for EVERY index, many
##      boards/sizes/revisions/origins; inside-board / non-finite origin -> unsupported.
##   t2 selector filtered vs unfiltered: same TargetSelector, canonical access (prefilter)
##      vs a test wrapper hiding the capability -> same winner / no-target / reservations,
##      and impossible candidates never enter the strict body.
##   t3 fallback / adversarial: missing / malformed / always-true / skip-one / drifting
##      prefilter doubles; inside-board canonical access == old loop.
##   t4 revision / identity invalidation + bounded single-slot cache.
##   t5 full 59x59 six-stripe level on a REAL laid-out host (origins below the board):
##      prefilter vs baseline dispatch/clear identity, 3481/3481, work-count bounds, timing.
##
## Run: godot --headless --path . -s res://tests/m25_c003_exact_prefilter.gd [-- <evidence_dir>]

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const ColorCandidateIndex = preload("res://scripts/gameplay/targeting/color_candidate_index.gd")
const ReservationState = preload("res://scripts/gameplay/targeting/reservation_state.gd")
const TargetSelector = preload("res://scripts/gameplay/targeting/target_selector.gd")
const ProductionTargetAccess = preload("res://scripts/gameplay/dispatch/production_target_access.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const ProductionRuntimeController = preload("res://scripts/gameplay/runtime/production_runtime_controller.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const RP = preload("res://scripts/debug/runtime_perf_probe.gd")

const HEX := ["#FF4500FF", "#FFA800FF", "#FFD635FF", "#00CC78FF", "#00CCC0FF", "#51E9F4FF"]
const CIDS := ["C01", "C02", "C03", "C04", "C05", "C06"]
const PRODUCTION := ["res://data/levels/m21_level_001_hazard_bot.json", "res://data/levels/level_002_apple.json",
	"res://data/levels/level_003_palm_tree.json", "res://data/levels/level_004_orange_cat.json",
	"res://data/levels/level_005_party_toucan.json", "res://data/levels/level_006_chicken.json",
	"res://data/levels/level_007_pigeon.json", "res://data/levels/level_008_butterfly.json",
	"res://data/levels/level_009_frog.json", "res://data/levels/level_010_ice_cube.json"]

var _fail := 0
var _tmp: Array = []
var _report := {}
var _lines: Array = []

# ------------------------------------------------------------ test doubles ----

## Baseline seam: same authoritative is_targetable(), NO prefilter capability -> the
## selector runs its pre-C003 full strict loop.
class BaselineAccess:
	extends RefCounted
	var real
	var calls: Array = []
	func _init(r) -> void:
		real = r
	func is_targetable(idx: int) -> bool:
		calls.append(idx)
		return real.is_targetable(idx)

## Canonical capability forwarded + counted (fast path with work counts).
class CountingAccess:
	extends RefCounted
	var real
	var pre_true: Array = []
	var pre_false: Array = []
	var pre_null := 0
	var calls: Array = []
	var fails := 0
	func _init(r) -> void:
		real = r
	func prefilter_maybe_targetable(idx: int) -> Variant:
		var v = real.prefilter_maybe_targetable(idx)
		if typeof(v) != TYPE_BOOL:
			pre_null += 1
		elif v:
			pre_true.append(idx)
		else:
			pre_false.append(idx)
		return v
	func is_targetable(idx: int) -> bool:
		calls.append(idx)
		var ok: bool = real.is_targetable(idx)
		if not ok:
			fails += 1
		return ok

## Scripted double: is_targetable true only for `ok_set`; optional prefilter returns
## `pre_value` (or per-index override `pre_map`).
class ScriptedAccess:
	extends RefCounted
	var ok_set := {}
	var calls: Array = []
	func _init(oks: Array) -> void:
		for i in oks:
			ok_set[i] = true
	func is_targetable(idx: int) -> bool:
		calls.append(idx)
		return ok_set.has(idx)

class ScriptedPrefilterAccess:
	extends ScriptedAccess
	var pre_value = null
	var pre_map := {}
	var pre_calls := 0
	var on_prefilter: Callable = Callable()
	func _init(oks: Array, v, m: Dictionary = {}) -> void:
		super(oks)
		pre_value = v
		pre_map = m
	func prefilter_maybe_targetable(idx: int) -> Variant:
		pre_calls += 1
		if on_prefilter.is_valid():
			on_prefilter.call(idx)
		return pre_map[idx] if pre_map.has(idx) else pre_value

## Counts strict-body entries: is_reserved is the first collaborator call of the strict
## per-candidate body (after pure board reads).
class CountingReservations:
	extends "res://scripts/gameplay/targeting/reservation_state.gd"
	var reserved_checks: Array = []
	func is_reserved(target_index: int) -> bool:
		reserved_checks.append(target_index)
		return super.is_reserved(target_index)

## Full-host selector swaps (t5): wrap the scheduler's real ProductionTargetAccess.
class BaselineSelector:
	extends "res://scripts/gameplay/targeting/target_selector.gd"
	func select_and_reserve(color_id: int, owner_id: int, access_query) -> int:
		return super.select_and_reserve(color_id, owner_id, BaselineAccess.new(access_query))

class CountingSelector:
	extends "res://scripts/gameplay/targeting/target_selector.gd"
	var lanes: Array = []
	var routing = null
	var raccess = null
	func select_and_reserve(color_id: int, owner_id: int, access_query) -> int:
		var ca := CountingAccess.new(access_query)
		# Touchable matching unreserved candidates, from a SEPARATE access (same board /
		# origin / shared mask) so the real access's memo is never touched.
		var side = ProductionTargetAccess.new(routing, raccess, _board, access_query._origin)
		var cand: Array = _candidate_index.get_candidates(color_id, _reservations.get_reserved_indices())
		var touchable := 0
		for c in cand:
			if side.prefilter_maybe_targetable(int(c)) != false:
				touchable += 1
		var o: Vector2 = access_query._origin
		var r: int = super.select_and_reserve(color_id, owner_id, ca)
		lanes.append({"cand": cand.size(), "touchable": touchable, "strict": ca.calls.size(), "fails": ca.fails,
			"pre_false_probed": _intersect(ca.pre_false, ca.calls), "winner": r, "origin": o})
		return r
	static func _intersect(a: Array, b: Array) -> int:
		var s := {}
		for x in a:
			s[x] = true
		var n := 0
		for y in b:
			if s.has(y):
				n += 1
		return n

func _initialize() -> void:
	await process_frame
	_t1_touch_mask_exact()
	_t2_selector_equivalence()
	_t3_fallback_adversarial()
	_t4_invalidation()
	await _t5_full_59_laid_out()
	_write_evidence()
	_cleanup()
	_done()

# ============================================================== t1 touch mask ==
## Pre-C003 per-call necessary condition, copied verbatim in behaviour (reference).
func _ref_mask(board) -> PackedByteArray:
	var w: int = board.get_width()
	var h: int = board.get_height()
	var m := PackedByteArray()
	m.resize(w * h)
	var stack := PackedInt32Array()
	for y in range(h):
		for x in range(w):
			if x == 0 or y == 0 or x == w - 1 or y == h - 1:
				var i: int = y * w + x
				if board.get_cell_state(i) == BoardState.CellState.CLEARED and m[i] == 0:
					m[i] = 1
					stack.append(i)
	while not stack.is_empty():
		var u: int = stack[stack.size() - 1]
		stack.resize(stack.size() - 1)
		for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
			var nx: int = u % w + d.x
			var ny: int = u / w + d.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var n: int = ny * w + nx
			if m[n] == 0 and board.get_cell_state(n) == BoardState.CellState.CLEARED:
				m[n] = 1
				stack.append(n)
	return m

func _ref_could_reach(board, origin: Vector2, index: int, reach: PackedByteArray) -> bool:
	if not board.is_valid_index(index):
		return true
	if not (is_finite(origin.x) and is_finite(origin.y)):
		return true
	var w: int = board.get_width()
	var h: int = board.get_height()
	var ox: int = int(floor(origin.x))
	var oy: int = int(floor(origin.y))
	if ox >= 0 and oy >= 0 and ox < w and oy < h:
		return true
	var pos: Vector2i = board.get_cell_position(index)
	if pos.x == 0 or pos.y == 0 or pos.x == w - 1 or pos.y == h - 1:
		return true
	for d in [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]:
		var nx: int = pos.x + d.x
		var ny: int = pos.y + d.y
		if nx >= 0 and ny >= 0 and nx < w and ny < h and reach[ny * w + nx] == 1:
			return true
	return false

func _t1_touch_mask_exact() -> void:
	print("[t1 touch mask == pre-C003 necessary condition]")
	var routing = ProductionRoutingSystem.new()
	var boards: Array = []
	for w in [[20, 20], [32, 32], [38, 38], [24, 40], [40, 24], [59, 59]]:
		boards.append(["stripe %dx%d" % w, _stripe_board(w[0], w[1], 6)])
	for p in PRODUCTION:
		var r = LevelLoader.load_from_path(p)
		if r.is_ok():
			boards.append([p.get_file(), BoardState.from_level_data(r.level_data)])
	var states := 0
	var checks := 0
	var mismatches := 0
	var false_neg := 0
	var sizes := {}
	for entry in boards:
		var board = entry[1]
		var w: int = board.get_width()
		var h: int = board.get_height()
		sizes["%dx%d" % [w, h]] = true
		var origins := [Vector2(w * 0.5, h + 13.7), Vector2(0.3, h + 2.0), Vector2(w - 0.5, h + 40.0),
			Vector2(-3.5, h * 0.5), Vector2(w + 2.5, h * 0.25), Vector2(w * 0.5, -4.0)]
		var accs: Array = []
		for o in origins:
			accs.append(ProductionTargetAccess.new(routing, ProductionAccessQuery.new(board), board, o))
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(entry[0])
		var order: Array = range(w * h)
		# Two clearing orders: realistic bottom-up peel, then random.
		var peel: Array = order.duplicate()
		peel.sort_custom(func(a, b): return (a / w) > (b / w) or ((a / w) == (b / w) and a < b))
		var shuffled: Array = order.duplicate()
		for i in range(shuffled.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var t = shuffled[i]; shuffled[i] = shuffled[j]; shuffled[j] = t
		for si in range(2):
			var seq: Array = peel if si == 0 else shuffled
			var is_peel: bool = si == 0
			board.restore_all_active()
			var cleared := 0
			var step: int = maxi(1, (w * h) / 9)
			for k in range(-1, seq.size()):
				if k >= 0:
					# Peel skips some cells to leave sealed pockets / corridors.
					if is_peel and (int(seq[k]) % 7 == 3):
						continue
					board.set_cell_state(int(seq[k]), BoardState.CellState.CLEARED)
					cleared += 1
					if cleared % step != 0:
						continue
				states += 1
				var reach := _ref_mask(board)
				for ai in range(accs.size()):
					var acc = accs[ai]
					for i in range(w * h):
						var ref: bool = _ref_could_reach(board, origins[ai], i, reach)
						var got = acc.prefilter_maybe_targetable(i)
						checks += 1
						if typeof(got) != TYPE_BOOL or got != ref or acc._could_reach(i) != ref:
							mismatches += 1
							if ref and got == false:
								false_neg += 1
		board.restore_all_active()
		# Retry/restore invalidation within t1: mask after restore == reference.
		for ai in range(accs.size()):
			var reach2 := _ref_mask(board)
			for i in range(w * h):
				checks += 1
				if accs[ai].prefilter_maybe_targetable(i) != _ref_could_reach(board, origins[ai], i, reach2):
					mismatches += 1
	_ok(mismatches == 0 and false_neg == 0, "materialised touch mask == reference for every index (%d checks, %d states, %d boards, sizes %s; mismatches %d, false negatives %d)" % [
		checks, states, boards.size(), str(sizes.keys()), mismatches, false_neg])
	# Unsupported origins.
	var b = _stripe_board(20, 20, 6)
	var unsupported := 0
	var old_true := 0
	for o in [Vector2(3.5, 4.5), Vector2(0.0, 0.0), Vector2(19.9, 19.9), Vector2(NAN, 25.0), Vector2(5.0, INF)]:
		var acc = ProductionTargetAccess.new(routing, ProductionAccessQuery.new(b), b, o)
		for i in range(400):
			if acc.prefilter_maybe_targetable(i) == null:
				unsupported += 1
			if acc._could_reach(i):
				old_true += 1
	_ok(unsupported == 5 * 400 and old_true == 5 * 400, "inside-board / non-finite origin: capability unsupported (null) and legacy probe path kept (%d/%d)" % [unsupported, 2000])
	var acc2 = ProductionTargetAccess.new(routing, ProductionAccessQuery.new(b), b, Vector2(10, 30))
	_ok(acc2.prefilter_maybe_targetable(-1) == null and acc2.prefilter_maybe_targetable(400) == null, "invalid index -> unsupported (null), never false")
	_report["t1"] = {"checks": checks, "states": states, "boards": boards.size(), "sizes": sizes.keys(), "mismatches": mismatches, "false_negatives": false_neg}

# ======================================================= t2 selector identity ==
func _t2_selector_equivalence() -> void:
	print("[t2 selector filtered vs unfiltered]")
	var routing = ProductionRoutingSystem.new()
	var boards: Array = []
	for p in PRODUCTION:
		var r = LevelLoader.load_from_path(p)
		if r.is_ok():
			boards.append([p.get_file(), BoardState.from_level_data(r.level_data)])
	for w in [[20, 20], [32, 32], [38, 38], [59, 59], [24, 40]]:
		boards.append(["stripe %dx%d" % w, _stripe_board(w[0], w[1], 6)])
	var tx := 0
	var diff := 0
	var no_target := 0
	var strict_violation := 0
	var bound_violation := 0
	var skipped_total := 0
	var strict_total_fast := 0
	var strict_total_base := 0
	for entry in boards:
		var board = entry[1]
		var w: int = board.get_width()
		var h: int = board.get_height()
		var ci = ColorCandidateIndex.create(); ci.bind(board)
		var rs = CountingReservations.new(); rs.bind(board)
		var sel = TargetSelector.create(); sel.bind(board, ci, rs)
		var raccess = ProductionAccessQuery.new(board)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(entry[0]) + 7
		var colors: Array = ci.get_color_ids()
		var order: Array = range(w * h)
		order.sort_custom(func(a, b): return (a / w) > (b / w) or ((a / w) == (b / w) and a < b))
		var cleared := 0
		for phase in range(6):
			# Advance the board: clear a bottom-up slice with gaps (revisions move).
			var target_n := int(float(w * h) * float(phase) / 6.0)
			while cleared < target_n:
				var c: int = order[cleared]
				cleared += 1
				if c % 5 != 2:
					board.set_cell_state(c, BoardState.CellState.CLEARED)
					ci.sync_cell(c)
			for rep in range(3):
				# Duplicate-colour reservation pressure: foreign owners hold random candidates.
				rs.reset()
				for color in colors:
					var cand: Array = ci.get_candidates(color, [])
					for k in range(mini(cand.size(), rep * 4)):
						rs.reserve(int(cand[rng.randi_range(0, cand.size() - 1)]), 100000 + color * 100 + k)
				for color in colors:
					for origin in [Vector2(rng.randf_range(0.0, w), h + 12.0), Vector2(w * 0.5, h + 30.0)]:
						tx += 1
						var pre_snapshot := _res_snapshot(rs)
						# Baseline (capability hidden).
						var base = BaselineAccess.new(ProductionTargetAccess.new(routing, raccess, board, origin))
						rs.reserved_checks.clear()
						var wa: int = sel.select_and_reserve(color, 7, base)
						var snap_a := _res_snapshot(rs)
						var base_checks: int = rs.reserved_checks.size()
						if wa != -1:
							rs.release(wa, 7)
						# Fast (canonical access, prefilter).
						var fast = CountingAccess.new(ProductionTargetAccess.new(routing, raccess, board, origin))
						rs.reserved_checks.clear()
						var wb: int = sel.select_and_reserve(color, 7, fast)
						var snap_b := _res_snapshot(rs)
						var fast_checks: Array = rs.reserved_checks.duplicate()
						if wb != -1:
							rs.release(wb, 7)
						if wa != wb or snap_a != snap_b or _res_snapshot(rs) != pre_snapshot:
							diff += 1
						if wa == -1:
							no_target += 1
						# Impossible candidates never reach the strict body (is_reserved / is_targetable).
						var pf := {}
						for x in fast.pre_false:
							pf[x] = true
						for x in fast_checks:
							if pf.has(x):
								strict_violation += 1
						for x in fast.calls:
							if pf.has(x):
								strict_violation += 1
						# Strict-body bound: <= touchable (prefilter-true) candidates examined.
						if fast.calls.size() > fast.pre_true.size() + fast.pre_null:
							bound_violation += 1
						skipped_total += fast.pre_false.size()
						strict_total_fast += fast_checks.size()
						strict_total_base += base_checks
	_ok(tx > 0 and diff == 0, "filtered == unfiltered on %d selection transactions (winner, no-target, ReservationState before/after) — diffs %d" % [tx, diff])
	_ok(no_target > 0 and no_target < tx, "matrix covers WAITING/no-target (%d) and successful selections (%d)" % [no_target, tx - no_target])
	_ok(strict_violation == 0, "provably-impossible candidates never entered the strict body (violations %d)" % strict_violation)
	_ok(bound_violation == 0, "strict is_targetable calls <= prefilter-true candidates every transaction (violations %d)" % bound_violation)
	_ok(strict_total_fast < strict_total_base, "strict-body entries reduced %d -> %d (%d impossible candidates skipped)" % [strict_total_base, strict_total_fast, skipped_total])
	_report["t2"] = {"transactions": tx, "diffs": diff, "no_target": no_target, "strict_body_entries_baseline": strict_total_base,
		"strict_body_entries_prefilter": strict_total_fast, "skipped": skipped_total, "strict_violations": strict_violation}

func _res_snapshot(rs) -> Array:
	var out: Array = []
	for t in rs.get_reserved_indices():
		out.append([int(t), rs.get_owner(int(t))])
	out.sort()
	return out

# ===================================================== t3 fallback / adversarial ==
func _t3_fallback_adversarial() -> void:
	print("[t3 optional capability fallback / adversarial doubles]")
	var board = _stripe_board(20, 20, 1)   # single colour: 400 candidates
	var ci = ColorCandidateIndex.create(); ci.bind(board)
	var rs = ReservationState.create(); rs.bind(board)
	var sel = TargetSelector.create(); sel.bind(board, ci, rs)
	var order: Array = TargetSelector._priority_sorted(ci.get_candidates(0, []), board)
	var ok_set := [order[37], order[120]]
	# Missing capability -> old loop: is_targetable called for candidates 0..37 in order.
	var none := ScriptedAccess.new(ok_set)
	var w0: int = sel.select_and_reserve(0, 1, none)
	rs.release(w0, 1)
	_ok(w0 == order[37] and none.calls == order.slice(0, 38), "missing capability: exact old full loop (38 ordered is_targetable calls)")
	# Malformed returns -> identical to old loop.
	var malformed_ok := true
	for v in [0, 1, 0.0, "false", "", [], {}, null, Vector2.ZERO]:
		var a := ScriptedPrefilterAccess.new(ok_set, v)
		var w1: int = sel.select_and_reserve(0, 1, a)
		if w1 != -1:
			rs.release(w1, 1)
		malformed_ok = malformed_ok and w1 == order[37] and a.calls == order.slice(0, 38)
	_ok(malformed_ok, "malformed capability values (0/1/0.0/strings/arrays/dicts/null/Vector2) -> exact old full loop")
	# Always-true is never a success: every candidate still asks authoritative is_targetable.
	var t := ScriptedPrefilterAccess.new([], true)
	var wt: int = sel.select_and_reserve(0, 1, t)
	_ok(wt == -1 and t.calls.size() == 400 and rs.get_reservation_count() == 0, "prefilter true never selects: 400 authoritative is_targetable calls, no-target, no reservation")
	# false skips exactly that candidate (even a would-be winner, per the access contract).
	var s := ScriptedPrefilterAccess.new(ok_set, true, {order[37]: false})
	var ws: int = sel.select_and_reserve(0, 1, s)
	rs.release(ws, 1)
	_ok(ws == order[120] and not s.calls.has(order[37]) and s.calls.size() == 120, "false skips only that candidate; canonical order continues to the next targetable")
	# Drift from inside the prefilter callback: foreign reservation of the winner.
	var d1 := ScriptedPrefilterAccess.new(ok_set, true)
	d1.on_prefilter = func(idx):
		if idx == order[36] and not rs.is_reserved(order[37]):
			rs.reserve(order[37], 999)
	var wd1: int = sel.select_and_reserve(0, 1, d1)
	_ok(wd1 != order[37] and rs.get_owner(order[37]) == 999 and (wd1 == -1 or rs.get_owner(wd1) == 1),
		"drift (foreign reservation injected by prefilter) never double-reserves (%d)" % wd1)
	if wd1 != -1:
		rs.release(wd1, 1)
	rs.release(order[37], 999)
	# Drift: prefilter assigns the SAME owner a target -> one target per owner still holds.
	var d2 := ScriptedPrefilterAccess.new(ok_set, true)
	d2.on_prefilter = func(idx):
		if idx == order[10] and rs.get_target_for_owner(1) == -1:
			rs.reserve(order[200], 1)
	var wd2: int = sel.select_and_reserve(0, 1, d2)
	_ok(wd2 == -1 and rs.get_target_for_owner(1) == order[200] and rs.get_reservation_count() == 1,
		"same-owner drift from prefilter: selector reserves nothing more (one target per owner)")
	rs.release(order[200], 1)
	# Re-entrant select / rebind from the prefilter callback are refused.
	var d3 := ScriptedPrefilterAccess.new(ok_set, true)
	var nested := [0, 0]
	d3.on_prefilter = func(_idx):
		nested[0] = sel.select_and_reserve(0, 2, ScriptedAccess.new(ok_set))
		nested[1] = 1 if sel.bind(board, ci, rs) else 0
	var wd3: int = sel.select_and_reserve(0, 1, d3)
	_ok(wd3 == order[37] and nested[0] == -1 and nested[1] == 0 and rs.get_reservation_count() == 1, "re-entrant select/bind from prefilter refused; outer selection intact")
	rs.release(wd3, 1)
	# Canonical access with an inside-board origin == old loop (no filtering).
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	board.set_cell_state(order[0], BoardState.CellState.CLEARED); ci.sync_cell(order[0])
	var inside_a = BaselineAccess.new(ProductionTargetAccess.new(routing, raccess, board, Vector2(10.5, 10.5)))
	var inside_b = CountingAccess.new(ProductionTargetAccess.new(routing, raccess, board, Vector2(10.5, 10.5)))
	var wa: int = sel.select_and_reserve(0, 1, inside_a)
	if wa != -1: rs.release(wa, 1)
	var wb: int = sel.select_and_reserve(0, 1, inside_b)
	if wb != -1: rs.release(wb, 1)
	_ok(wa == wb and inside_a.calls == inside_b.calls and inside_b.pre_false.is_empty() and inside_b.pre_null > 0,
		"canonical access, inside-board origin: capability unsupported, identical old loop (%d calls)" % inside_b.calls.size())
	board.restore_all_active(); ci.rebuild()

# ================================================================ t4 revision ==
func _t4_invalidation() -> void:
	print("[t4 revision / identity invalidation]")
	var routing = ProductionRoutingSystem.new()
	var b1 = _stripe_board(20, 20, 6)
	var o := Vector2(10, 30)
	var a = ProductionTargetAccess.new(routing, ProductionAccessQuery.new(b1), b1, o)
	var x: int = b1.get_cell_index(5, 17)           # interior, sealed on a fresh board
	var n0: int = ProductionTargetAccess.mask_build_count
	_ok(a.prefilter_maybe_targetable(x) == false, "sealed interior cell -> false")
	var n1: int = ProductionTargetAccess.mask_build_count
	var a2 = ProductionTargetAccess.new(routing, ProductionAccessQuery.new(b1), b1, Vector2(3, 25))
	a2.prefilter_maybe_targetable(x)
	_ok(ProductionTargetAccess.mask_build_count == n1 and n1 == n0 + 1, "same board + revision: second access adopts the shared mask (no rebuild)")
	var rev0: int = b1.get_revision()
	b1.set_cell_state(b1.get_cell_index(5, 19), BoardState.CellState.CLEARED)
	b1.set_cell_state(b1.get_cell_index(5, 18), BoardState.CellState.CLEARED)
	_ok(b1.get_revision() > rev0 and a.prefilter_maybe_targetable(x) == true and ProductionTargetAccess.mask_build_count == n1 + 1,
		"clear -> revision moves -> mask rebuilt, cell now touchable")
	b1.restore_all_active()
	_ok(a.prefilter_maybe_targetable(x) == false and ProductionTargetAccess.mask_build_count == n1 + 2, "restore_all_active (Retry) -> rebuilt, sealed again")
	# Different BoardState, identical dims + revision number, different truth.
	var b2 = _stripe_board(20, 20, 6)
	var b3 = _stripe_board(20, 20, 6)
	b2.set_cell_state(b2.get_cell_index(5, 19), BoardState.CellState.CLEARED)
	b2.set_cell_state(b2.get_cell_index(5, 18), BoardState.CellState.CLEARED)
	b3.set_cell_state(b3.get_cell_index(15, 19), BoardState.CellState.CLEARED)
	b3.set_cell_state(b3.get_cell_index(15, 18), BoardState.CellState.CLEARED)
	var p2 = ProductionTargetAccess.new(routing, ProductionAccessQuery.new(b2), b2, o)
	var p3 = ProductionTargetAccess.new(routing, ProductionAccessQuery.new(b3), b3, o)
	_ok(b2.get_revision() == b3.get_revision(), "two boards at the same revision number")
	_ok(p2.prefilter_maybe_targetable(x) == true and p3.prefilter_maybe_targetable(x) == false and p2.prefilter_maybe_targetable(x) == true,
		"different BoardState identity never reuses another board's mask")
	_ok(ProductionTargetAccess._shared_touch.size() == 400 and ProductionTargetAccess._shared_mask.size() == 400, "shared cache is a single bounded slot (one board state)")

# ======================================================= t5 full 59x59 laid-out ==
func _t5_full_59_laid_out() -> void:
	print("[t5 full 59x59 six-stripe level on a laid-out host]")
	var fast := await _full_run("prefilter (counting)", "count", true)
	var base := await _full_run("baseline (capability hidden)", "base", true)
	var prod := await _full_run("production uninstrumented 2x", "none", true)
	var prod1 := await _full_run("production uninstrumented 1x", "none", false)
	for r in [fast, base, prod, prod1]:
		_ok(r["origins_below"], "%s: every slot origin finite and below the board %s" % [r["tag"], str(r["origins"])])
		_ok(r["won"] and r["clears"] == 3481 and r["dup_dispatch"] == 0 and r["dup_clear"] == 0 and r["residue"] == [0, 0, 0, 0],
			"%s: WON, 3481/3481 clears, no duplicate claim/clear, zero residue" % r["tag"])
		_ok(r["max_route_per_lane"] <= 1, "%s: compute_route <= 1 per lane (max %d)" % [r["tag"], r["max_route_per_lane"]])
		_ok(r["max_lanes_per_frame"] <= 1, "%s: one lane per frame" % r["tag"])
	_ok(fast["dispatch"] == base["dispatch"] and fast["dispatch"] == prod["dispatch"], "dispatch target/colour sequence identical: prefilter == baseline == production (%d)" % fast["dispatch"].size())
	_ok(fast["clears_seq"] == base["clears_seq"] and fast["clears_seq"] == prod["clears_seq"], "authenticated clear identity/order identical")
	_ok(fast["final"] == base["final"], "identical final board")
	var ws: Dictionary = fast["work"]
	_ok(ws["failed_route_probes"] == 0, "0 failed route probes over the full level")
	_ok(ws["pre_false_probed"] == 0, "no prefilter-false candidate ever entered the strict body")
	_ok(ws["strict_over_touchable"] == 0, "strict-body iterations <= touchable matching candidates every lane (max strict %d)" % ws["max_strict"])
	_report["t5"] = {"prefilter_counting": _strip(fast), "baseline": _strip(base), "production_2x": _strip(prod), "production_1x": _strip(prod1)}
	for r in [base, prod, prod1]:
		_lines.append("%s: %s" % [r["tag"], JSON.stringify(r["timing"])])

func _strip(r: Dictionary) -> Dictionary:
	var o := r.duplicate()
	for k in ["dispatch", "clears_seq", "final"]:
		o.erase(k)
	o["dispatches"] = r["dispatch"].size()
	return o

func _full_run(tag: String, mode: String, two: bool) -> Dictionary:
	var lvl := _stripe_level(59, 6, "m25c003_59_%s_%d" % [mode, Time.get_ticks_usec()])
	var h = await _laid_out_host(lvl, _plan(lvl))
	h.get_economy().boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
	h.activate_plus_one_slot()
	await _settle(h)
	h.get_runtime().set_process(false)
	h.get_runtime().reset_runtime()
	var origins: Array = []
	var below := true
	for i in range(h.get_slots().active_capacity()):
		var o: Vector2 = h.get_origin_provider().origin_for_slot(i)
		origins.append([snappedf(o.x, 0.01), snappedf(o.y, 0.01)])
		below = below and is_finite(o.x) and is_finite(o.y) and o.y >= float(h.get_board().get_height())
	var cs = null
	if mode == "base":
		var s = BaselineSelector.new()
		s.bind(h.get_board(), h.get_candidate_index(), h.get_reservations())
		h.get_claim_engine()._selector = s
	elif mode == "count":
		cs = CountingSelector.new()
		cs.routing = h.get_scheduler()._routing_system
		cs.raccess = h.get_scheduler()._routing_access
		cs.bind(h.get_board(), h.get_candidate_index(), h.get_reservations())
		h.get_claim_engine()._selector = cs
	var rt = h.get_runtime()
	var sch = h.get_scheduler()
	rt.set_speed_2x(two)
	var dispatch: Array = []
	var clears: Array = []
	var live := {}
	var cleared := {}
	var dup := [0, 0]
	h.get_dispatcher().assignment_dispatched.connect(func(_o, t, c, _a):
		if live.has(t): dup[0] += 1
		live[t] = true
		dispatch.append([t, c]))
	h.get_clearing_loop().authenticated_clear.connect(func(_o, t, c, _a):
		live.erase(t)
		if cleared.has(t): dup[1] += 1
		cleared[t] = true
		clears.append([t, c]))
	RP.reset()
	RP.enabled = true
	var col := 0
	var frames := 0
	var guard := 0
	var max_route := 0
	var max_lanes := 0
	var sel_ms: Array = []
	var scan_ms: Array = []
	var route_ms: Array = []
	var dij_ms: Array = []
	var frame_ms: Array = []
	while not h.get_completion().is_terminal() and frames < 60 * 1200 and guard < 3000000:
		guard += 1
		if h.get_slots().rightmost_empty_index() != -1 and not h.get_supply().is_exhausted():
			var placed := false
			for k in range(3):
				if h.get_input_controller().activate_front((col + k) % 3).get("ok", false):
					col = (col + k + 1) % 3
					placed = true
					break
			if placed:
				continue
		if not two and rt.is_2x():
			rt.set_speed_2x(false)
		var rc0: int = _rp_count("access_compute_route")
		var lc0: int = _rp_count("m26_dispatch_lane")
		RP.take_frame()
		var t0 := Time.get_ticks_usec()
		rt.tick(1.0 / 60.0)
		frame_ms.append(float(Time.get_ticks_usec() - t0) / 1000.0)
		var f: Dictionary = RP.take_frame()
		frames += 1
		max_route = maxi(max_route, _rp_count("access_compute_route") - rc0)
		max_lanes = maxi(max_lanes, _rp_count("m26_dispatch_lane") - lc0)
		if f.has("target_selection"):
			var sel := float(f["target_selection"]) / 1000.0
			var rte := float(f.get("access_compute_route", 0)) / 1000.0
			var val := float(f.get("access_validate", 0)) / 1000.0
			sel_ms.append(sel)
			scan_ms.append(maxf(0.0, sel - rte - val))
			if f.has("access_compute_route"):
				route_ms.append(rte)
				dij_ms.append(float(f.get("route_dijkstra", 0)) / 1000.0)
	RP.enabled = false
	var final: Array = []
	var b = h.get_board()
	for k in range(b.get_width() * b.get_height()):
		final.append(b.get_cell_state(k))
	var out := {"tag": tag, "speed": "2x" if two else "1x", "origins": origins, "origins_below": below,
		"won": h.get_completion().is_won(), "clears": cleared.size(), "dup_dispatch": dup[0], "dup_clear": dup[1],
		"residue": [h.get_claim_engine().live_claim_count(), h.get_reservations().get_reservation_count(),
			h.get_dispatcher().get_active_count(), h.get_slots().live_work_count()],
		"frames": frames, "max_route_per_lane": max_route, "max_lanes_per_frame": max_lanes,
		"dispatch": dispatch, "clears_seq": clears, "final": final,
		"timing": {"note": "RuntimePerfProbe per frame (one lane per frame); instrumentation adds overhead in counting/baseline modes",
			"lanes": sel_ms.size(), "target_selection_ms": _dist(sel_ms), "scan_excl_route_ms": _dist(scan_ms),
			"winner_route_ms": _dist(route_ms), "route_dijkstra_ms": _dist(dij_ms), "frame_ms": _dist(frame_ms)}}
	if cs != null:
		var fails := 0
		var pfp := 0
		var over := 0
		var max_strict := 0
		var strict_hist := {}
		for L in cs.lanes:
			fails += int(L["fails"])
			pfp += int(L["pre_false_probed"])
			if int(L["strict"]) > int(L["touchable"]):
				over += 1
			max_strict = maxi(max_strict, int(L["strict"]))
		var strict_counts: Array = cs.lanes.map(func(L): return float(L["strict"]))
		var cand_counts: Array = cs.lanes.map(func(L): return float(L["cand"]))
		out["work"] = {"lanes": cs.lanes.size(), "failed_route_probes": fails, "pre_false_probed": pfp,
			"strict_over_touchable": over, "max_strict": max_strict, "strict_body_per_lane": _dist(strict_counts),
			"candidates_per_lane": _dist(cand_counts)}
	print("  %s %s" % [tag, JSON.stringify(_strip(out))])
	h.get_meta("sub").free()
	return out

func _rp_count(section: String) -> int:
	var a = RP._acc.get(section, null)
	return int(a[0]) if a != null else 0

func _dist(a: Array) -> Dictionary:
	if a.is_empty():
		return {"n": 0}
	var s := a.duplicate()
	s.sort()
	var sum := 0.0
	for v in s:
		sum += float(v)
	return {"n": s.size(), "p50": snappedf(s[s.size() / 2], 0.001), "p90": snappedf(s[int(s.size() * 0.9)], 0.001),
		"p99": snappedf(s[int(s.size() * 0.99)], 0.001), "max": snappedf(s[s.size() - 1], 0.001), "mean": snappedf(sum / s.size(), 0.001)}

# ================================================================== helpers ====
func _stripe_board(w: int, h: int, k: int):
	var cells := PackedInt32Array()
	for y in range(h):
		for x in range(w):
			cells.append(x * k / w)
	return BoardState.from_level_data(LevelData.new(1, "m25c003_%dx%d" % [w, h], "m25c003", "TEST", w, h,
		PackedStringArray(HEX.slice(0, k)), cells))

func _stripe_level(w: int, k: int, id: String) -> Dictionary:
	var cells: Array = []
	for y in range(w):
		for x in range(w):
			cells.append(x * k / w)
	return {"version": 1, "id": id, "name": id, "difficulty": "TEST", "width": w, "height": w,
		"palette": HEX.slice(0, k), "cells": cells}

func _plan(lvl: Dictionary) -> Dictionary:
	var left := {}
	for c in lvl["cells"]:
		left[int(c)] = int(left.get(int(c), 0)) + 1
	var batches: Array = []
	var more := true
	while more:
		more = false
		for c in range(lvl["palette"].size()):
			if int(left.get(c, 0)) > 0:
				var n := mini(30, int(left[c]))
				left[c] = int(left[c]) - n
				batches.append([CIDS[c], n])
				more = true
	var cols := [[], [], []]
	for i in range(batches.size()):
		cols[i % 3].append({"batchId": "T%03d" % i, "cid": batches[i][0], "robots": batches[i][1]})
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "columnCount": 3, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols, "levelId": lvl["id"]}

## Real production slot geometry: 1080x2160 SubViewport, settle, build, relayout, settle.
func _laid_out_host(lvl: Dictionary, plan: Dictionary):
	var h = ProductionGameplayHost.new()
	h.auto_build = false
	h.level_path = _write_tmp(JSON.stringify(lvl))
	h.supply_plan_path = _write_tmp(JSON.stringify(plan))
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)
	h.set_meta("sub", sub)
	await process_frame
	await process_frame
	_ok(h.build(), "laid-out host builds %s" % h.get_build_error())
	await _settle(h)
	h.get_runtime().set_process(false)
	return h

func _settle(h) -> void:
	await process_frame
	await process_frame
	h.get_screen().relayout()
	await process_frame
	await process_frame

func _write_tmp(text: String) -> String:
	var p := "user://m25c003_%d.json" % Time.get_ticks_usec()
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _write_evidence() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		return
	var dir: String = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	_report["suite"] = "tests/m25_c003_exact_prefilter.gd"
	_report["engine"] = Engine.get_version_info()["string"]
	_report["failures"] = _fail
	var f := FileAccess.open(dir.path_join("prefilter_report.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_report, "  "))
	f.close()
	var t := ["M25-C003 exact-safe prefilter report (tests/m25_c003_exact_prefilter.gd)", ""]
	t.append("t1 touch mask: %s" % JSON.stringify(_report.get("t1", {})))
	t.append("t2 selector identity: %s" % JSON.stringify(_report.get("t2", {})))
	t.append("")
	var t5: Dictionary = _report.get("t5", {})
	for k in t5:
		var r: Dictionary = t5[k]
		t.append("## t5 %s (%s)" % [k, r.get("speed", "")])
		t.append("origins %s below=%s WON=%s clears=%d dup=%d/%d residue=%s max compute_route/lane=%d max lanes/frame=%d frames=%d" % [
			str(r["origins"]), r["origins_below"], r["won"], r["clears"], r["dup_dispatch"], r["dup_clear"], str(r["residue"]),
			r["max_route_per_lane"], r["max_lanes_per_frame"], r["frames"]])
		if r.has("work"):
			t.append("work %s" % JSON.stringify(r["work"]))
		t.append("timing %s" % JSON.stringify(r["timing"]))
		t.append("")
	t.append("failures: %d" % _fail)
	f = FileAccess.open(dir.path_join("prefilter_report.txt"), FileAccess.WRITE)
	f.store_string("\n".join(t) + "\n")
	f.close()

func _cleanup() -> void:
	for p in _tmp:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M25-C003 EXACT PREFILTER: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
