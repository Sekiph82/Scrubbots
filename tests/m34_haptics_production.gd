extends SceneTree
## M34-C001 V02 — production haptics wiring evidence (F-M34-001).
## Proves the REAL production host owns one live HapticsController wired to the
## authoritative committed seams — by emitting the real signals through the full
## stack and asserting injected platform-sink calls, NOT by calling request_*.
##
## Run: godot --headless --path . -s res://tests/m34_haptics_production.gd
## Exits 0 on success, 1 on any failure.

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const HapticsController = preload("res://scripts/haptics/haptics_controller.gd")

const DT := 1.0
const MAX_TICKS := 80000

var _fail := 0

func _initialize() -> void:
	await _wiring_and_events()
	_done()

func _wiring_and_events() -> void:
	print("[production wiring]")
	var h = await _make_host(0)
	if h == null:
		_done()
		return
	var hc = h.get_haptics_controller()
	_ok(hc != null, "production host owns a live HapticsController")
	_ok(h.get_haptics_settings() != null, "host owns the persisted haptics settings")

	# Inject a platform sink so we can count REAL wired calls without a device.
	var calls: Array = []
	hc.set_platform_sink(func(ms, cat): calls.append(cat))
	# Force enabled regardless of the machine's persisted setting, and clear any
	# throttle state so the first committed clear is observable.
	hc.set_enabled(true)
	hc.reset_for_new_attempt()

	# Exactly-once wiring: the authoritative seams must be connected to the live
	# controller exactly once.
	_ok(h.get_clearing_loop().authenticated_clear.is_connected(hc._on_authenticated_clear), "authenticated_clear wired to cleaning haptic")
	_ok(h.get_completion().terminal_reached.is_connected(hc._on_terminal_reached), "terminal_reached wired to completion haptic")
	_ok(h.get_clearing_loop().authenticated_clear.get_connections().filter(func(c): return c.callable == hc._on_authenticated_clear).size() == 1, "authenticated_clear connected exactly once")
	_ok(h.get_completion().terminal_reached.get_connections().filter(func(c): return c.callable == hc._on_terminal_reached).size() == 1, "terminal_reached connected exactly once")

	# Idempotent rebind must NOT stack a duplicate connection.
	h._bind_haptics_signals()
	_ok(h.get_clearing_loop().authenticated_clear.get_connections().filter(func(c): return c.callable == hc._on_authenticated_clear).size() == 1, "rebind does not duplicate cleaning connection")

	# Drive the real stack to WON.
	_drain(h)
	_ok(h.get_completion().is_won(), "production stack reaches WON (haptics never blocks gameplay)")
	_ok(h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == 0, "board fully cleared")

	# Cleaning haptic fired via the REAL committed-clear seam (throttled, so
	# played <= clears but >= 1). Completion fired exactly once via WON.
	var clean_calls := 0
	var completion_calls := 0
	for c in calls:
		if c == HapticsController.Category.CLEANING:
			clean_calls += 1
		elif c == HapticsController.Category.COMPLETION:
			completion_calls += 1
	var cd: Dictionary = hc.get_diagnostics(HapticsController.Category.CLEANING)
	_ok(cd["requests"] > 0, "cleaning haptic requested by real committed clears (%d)" % cd["requests"])
	_ok(clean_calls >= 1, "at least one cleaning vibration reached the platform")
	_ok(completion_calls == 1, "completion vibration fired exactly once on WON")

	# WON latched once.
	_ok(hc.completion_played_this_attempt(), "completion latch set for the attempt")

	# Toggle OFF at the setting level suppresses further platform calls without
	# affecting the (already-won) gameplay truth.
	var before = hc.get_platform_call_count()
	hc.set_enabled(false)
	hc.request_cleaning()
	_ok(hc.get_platform_call_count() == before, "OFF suppresses further platform calls")

	_free_host(h)

# --- host driver (mirrors m33 audio runtime) ---

func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	var scheduler = h.get_scheduler()
	var agent_layer = h.get_agent_layer()
	for _i in range(MAX_TICKS):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(DT)
		if supply.is_exhausted() and scheduler.live_assignment_count() == 0 and not _any_moving(agent_layer):
			runtime.tick(DT)
			if h.get_completion().is_terminal():
				break
			runtime.tick(DT)
			break

func _make_host(drop: int):
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.qa_supply_drop_last = drop
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame
	await process_frame
	var ok: bool = host.build()
	_ok(ok, "production host built (%s)" % host.get_build_error())
	if not ok:
		return null
	await process_frame
	await process_frame
	host.get_screen().relayout()
	await process_frame
	await process_frame
	host.get_runtime().set_process(false)
	host.set_meta("sub", sub)
	return host

func _free_host(host) -> void:
	if host == null:
		return
	var sub = host.get_meta("sub") if host.has_meta("sub") else null
	if sub != null and is_instance_valid(sub):
		sub.free()

func _any_moving(agent_layer) -> bool:
	if agent_layer == null:
		return false
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return true
	return false

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M34 haptics production wiring evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
