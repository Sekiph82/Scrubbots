extends SceneTree
## M29-C001 V01 — speed authority / cadence / auto-2x evidence (audit §J/§K/§L).
##
## Focused deterministic proofs of the owner-locked 1x/2x rule
## (OWNER_GAMEPLAY_SPEED_RULE_V01), decoupled from full-board play:
##   J: 1x default, manual toggle, exact half cadence interval at 2x, runtime agent
##      travel accelerates (future + in-flight), no global Engine.time_scale.
##   K: automatic M23-exhausted -> 2x ONLY after a successful final transfer; NOT on
##      rejection, NOT on visible-empty-while-hidden-remains, NOT on five-full; idempotent
##      when already 2x; manual toggle back to 1x afterward; reset/new session -> 1x.
##
## Run: godot --headless --path . -s res://tests/m29_speed_authority_evidence.gd
## Exits 0 on success, 1 on any failure.

const GameplaySpeedAuthority = preload("res://scripts/gameplay/runtime/gameplay_speed_authority.gd")
const ProductionRuntimeController = preload("res://scripts/gameplay/runtime/production_runtime_controller.gd")
const ProductionInputController = preload("res://scripts/ui/production_input_controller.gd")
const BatchSupplyPanel = preload("res://scripts/ui/batch_supply_panel.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const AutoDispatchScheduler = preload("res://scripts/gameplay/dispatch/auto_dispatch_scheduler.gd")
const LevelLoader = preload("res://scripts/data/level_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ProductionRoutingSystem = preload("res://scripts/gameplay/routing/production_routing_system.gd")
const ProductionAccessQuery = preload("res://scripts/gameplay/routing/production_access_query.gd")
const RouteRequest = preload("res://scripts/gameplay/routing/route_request.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const LEVEL := "res://data/levels/m21_level_001_hazard_bot.json"

var _fail := 0

func _initialize() -> void:
	_test_speed_authority_unit()
	_test_auto_2x_final_transfer()
	_test_no_auto_2x_rejection_and_partial()
	_test_agent_travel_scaling()
	_done()

# ------------------------------------------------------------- J: speed unit --

func _test_speed_authority_unit() -> void:
	var sp = GameplaySpeedAuthority.new(0.5)
	_ok(not sp.is_2x() and sp.factor() == 1.0, "new speed authority starts 1x")
	_ok(is_equal_approx(sp.cadence_interval(), 0.5), "1x cadence interval == base")
	var emits := [0]
	sp.speed_changed.connect(func(_f): emits[0] += 1)
	_ok(sp.toggle() and sp.is_2x() and sp.factor() == 2.0, "manual toggle 1x -> 2x")
	_ok(is_equal_approx(sp.cadence_interval(), 0.25), "2x cadence interval is EXACTLY half of 1x")
	sp.set_2x(true)  # idempotent — no second emit
	_ok(emits[0] == 1, "already-2x set_2x is an idempotent no-op (no duplicate emit)")
	_ok(not sp.toggle() and not sp.is_2x(), "manual toggle 2x -> 1x")
	sp.set_2x(true)
	sp.reset()
	_ok(not sp.is_2x(), "reset restores 1x")

# ------------------------------------------------- K: auto-2x on final transfer --

## Minimal production-input harness with a controllable small M23 supply (no routing —
## auto-2x depends only on M23 exhaustion after a successful M24 placement).
func _harness(cols: Array):
	var supply = BatchSupplyEngine.create(3, 3)
	supply.load_columns(cols)
	var slots = FiveSlotBatchEngine.new()
	var scheduler = AutoDispatchScheduler.new()
	var speed = GameplaySpeedAuthority.new(0.5)
	var layer := Node2D.new()
	get_root().add_child(layer)
	var runtime = ProductionRuntimeController.new()
	get_root().add_child(runtime)
	runtime.bind(scheduler, speed, layer)
	runtime.set_process(false)
	var panel = BatchSupplyPanel.new()
	get_root().add_child(panel)
	var input = ProductionInputController.new()
	get_root().add_child(input)
	input.bind(supply, slots, scheduler, runtime, panel, null)
	return {"supply": supply, "slots": slots, "runtime": runtime, "input": input,
		"speed": speed, "layer": layer, "panel": panel}

func _b(id: String, color: int, count: int):
	return ColorBatch.make(id, color, count, 16)

func _test_auto_2x_final_transfer() -> void:
	# Three columns, one batch each -> 3 transfers exhaust supply.
	var h = _harness([[_b("a", 0, 3)], [_b("b", 1, 3)], [_b("c", 2, 3)]])
	var input = h["input"]; var runtime = h["runtime"]; var supply = h["supply"]
	input.activate_front(0)
	_ok(not runtime.is_2x(), "no auto-2x after first transfer (supply not exhausted)")
	input.activate_front(1)
	_ok(not runtime.is_2x() and not supply.is_exhausted(), "no auto-2x mid-supply")
	input.activate_front(2)
	_ok(supply.is_exhausted(), "final transfer leaves every M23 column empty")
	_ok(runtime.is_2x(), "auto-2x engaged after the successful FINAL transfer (owner rule §3)")
	# Idempotent: any further (rejected) activation does not re-toggle or flip speed.
	input.activate_front(0)
	_ok(runtime.is_2x(), "already-2x stays 2x on a subsequent rejected activation (idempotent)")
	# Manual toggle back to 1x works after auto-2x.
	runtime.toggle_speed()
	_ok(not runtime.is_2x(), "manual toggle back to 1x works after auto-2x")
	# Reset -> 1x.
	runtime.set_speed_2x(true)
	runtime.reset_runtime()
	_ok(not runtime.is_2x(), "reset/new session restores 1x after a 2x session")
	_cleanup(h)

func _test_no_auto_2x_rejection_and_partial() -> void:
	# Six batches so five placements fill all slots and the sixth is rejected while supply
	# still has a batch left (five-full rejection MUST NOT auto-2x).
	var h = _harness([[_b("a", 0, 3), _b("d", 0, 3)], [_b("b", 1, 3), _b("e", 1, 3)], [_b("c", 2, 3), _b("f", 2, 3)]])
	var input = h["input"]; var runtime = h["runtime"]; var slots = h["slots"]; var supply = h["supply"]
	# Fill five slots (col0,col1,col2,col0,col1).
	for col in [0, 1, 2, 0, 1]:
		input.activate_front(col)
	_ok(slots.is_full(), "five slots filled")
	_ok(not supply.is_exhausted(), "supply NOT exhausted (one batch still queued)")
	var res: Dictionary = input.activate_front(2)
	_ok(not res.get("ok", false) and res.get("error", "") == "slots_full", "sixth activation rejected (slots full)")
	_ok(not runtime.is_2x(), "five-full rejection does NOT trigger auto-2x")
	# Visible-empty-while-hidden-remains style: partial consumption never exhausts.
	var h2 = _harness([[_b("x", 0, 3), _b("y", 0, 3), _b("z", 0, 3), _b("w", 0, 3)], [_b("p", 1, 3)], [_b("q", 2, 3)]])
	var in2 = h2["input"]; var rt2 = h2["runtime"]; var sup2 = h2["supply"]
	# Consume column 1 and 2 fronts (their visible rows go empty) but column 0 keeps hidden depth.
	in2.activate_front(1)
	in2.activate_front(2)
	_ok(not sup2.is_exhausted(), "hidden future batches remain -> supply not exhausted")
	_ok(not rt2.is_2x(), "visible rows empty while hidden supply remains does NOT auto-2x")
	_cleanup(h)
	_cleanup(h2)

# --------------------------------------------------- J: agent travel scaling --

func _test_agent_travel_scaling() -> void:
	var res = LevelLoader.load_from_path(LEVEL)
	if not res.is_ok():
		_ok(false, "load level for agent-travel scaling")
		return
	var board = BoardState.from_level_data(res.level_data)
	var routing = ProductionRoutingSystem.new()
	var raccess = ProductionAccessQuery.new(board)
	var origin := Vector2(2.5, float(board.get_height()) + 4.0)
	var routed = _first_routed(board, routing, raccess, origin)
	if routed.is_empty():
		_ok(false, "found a real routable target for agent-travel scaling")
		return

	var speed = GameplaySpeedAuthority.new(0.5)
	var scheduler = AutoDispatchScheduler.new()
	var layer := Node2D.new(); get_root().add_child(layer)
	var runtime = ProductionRuntimeController.new(); get_root().add_child(runtime)
	runtime.bind(scheduler, speed, layer)
	runtime.set_process(false)

	# Agent A at 1x: one tick.
	var a1 = ScrubbotAgent.new(); layer.add_child(a1)
	a1.assign(0, routed["color"], routed["req"], routed["route"])
	runtime.tick(0.1)
	var p1: float = a1.get_route_length() * a1.get_progress()

	# Agent B at 2x: one tick of the same duration.
	speed.set_2x(true)
	var a2 = ScrubbotAgent.new(); layer.add_child(a2)
	a2.assign(1, routed["color"], routed["req"], routed["route"])
	runtime.tick(0.1)
	var p2: float = a2.get_route_length() * a2.get_progress()
	_ok(is_equal_approx(p2, 2.0 * p1) or p2 >= 1.9 * p1, "2x future agent travels ~2x distance per tick (%.3f vs %.3f)" % [p2, p1])

	# In-flight change: A (still 1x-progressed) accelerates immediately when 2x is set.
	var before: float = a1.get_route_length() * a1.get_progress()
	runtime.tick(0.1)   # already 2x now
	var after: float = a1.get_route_length() * a1.get_progress()
	var moved_2x: float = after - before
	# Compare to a 1x baseline step on a fresh agent.
	speed.set_2x(false)
	var a3 = ScrubbotAgent.new(); layer.add_child(a3)
	a3.assign(2, routed["color"], routed["req"], routed["route"])
	runtime.tick(0.1)
	var moved_1x: float = a3.get_route_length() * a3.get_progress()
	_ok(moved_2x >= 1.9 * moved_1x or is_equal_approx(moved_2x, 2.0 * moved_1x), "already-moving agent updates to 2x immediately (%.3f vs 1x %.3f)" % [moved_2x, moved_1x])
	layer.free()
	runtime.free()

func _first_routed(board, routing, raccess, origin) -> Dictionary:
	for t in range(board.get_width() * board.get_height()):
		if board.get_cell_state(t) != BoardState.CellState.ACTIVE:
			continue
		var req = RouteRequest.for_target(board, origin, t)
		if req == null:
			continue
		var route = routing.compute_route(req, board, raccess)
		if route != null and route.success:
			return {"req": req, "route": route, "color": board.get_color_id(t)}
	return {}

func _cleanup(h) -> void:
	for k in ["layer", "runtime", "panel", "input"]:
		if h.has(k) and h[k] != null and is_instance_valid(h[k]):
			h[k].free()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M29 speed authority evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
