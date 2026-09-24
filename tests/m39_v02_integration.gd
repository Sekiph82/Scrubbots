extends SceneTree
## M39-C001 V02 Phase B/C/E — production runtime economy integration over the REAL
## gameplay host (F-M39-003/004/010). Manual 2x gate, live +1 slot, terminal-
## driven economy, and the concrete booster adapter (Random/Selector/Tornado)
## acting on real BoardState/supply/slots with fault-injection rollback.
## Run: godot --headless --path . -s res://tests/m39_v02_integration.gd

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

const DT := 1.0
const MAX_TICKS := 80000

var _fail := 0

func _initialize() -> void:
	await _wiring_and_gate()
	await _terminal_economy()
	_done()

func _wiring_and_gate() -> void:
	print("[wiring + manual 2x gate + +1 slot + boosters]")
	var h = await _make_host(0)
	if h == null:
		return
	var econ = h.get_economy()
	_ok(econ != null, "production host owns EconomyServices (F-M39-010)")
	_ok(h.get_booster_adapter() != null, "concrete production booster adapter present (F-M39-003)")

	# Manual 2x gate (F-M39-004): no entitlement -> refused.
	_ok(not h.get_speed_authority().is_2x(), "starts at 1x")
	h._on_speed_pressed()
	_ok(not h.get_speed_authority().is_2x(), "manual 2x refused without entitlement")
	# Buy current-level 2x -> entitled -> allowed.
	var buy = econ.speed.purchase_current_level(h.progression_level)
	_ok(buy["ok"], "current-level 2x purchased")
	h._on_speed_pressed()
	_ok(h.get_speed_authority().is_2x(), "manual 2x allowed with entitlement")
	h._on_speed_pressed()
	_ok(not h.get_speed_authority().is_2x(), "manual 2x OFF always allowed")

	# +1 Slot live growth (F-M39-001): economy gate + real engine to 6.
	econ.boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
	_ok(h.get_slots().get_slot_count() == 5, "engine baseline 5 slots")
	_ok(h.activate_plus_one_slot(), "activate +1 slot ok")
	_ok(h.get_slots().get_slot_count() == 6, "engine grew to 6 (authoritative capacity)")
	_ok(not h.activate_plus_one_slot(), "cannot +1 slot twice in an attempt")

	# Concrete booster adapter over REAL engines (fresh, quiescent host).
	var adapter = h.get_booster_adapter()
	var bs = h.get_booster_service()
	var colors: Array = adapter.present_colors()
	_ok(colors.size() > 0, "present_colors reads real BoardState (%d colors)" % colors.size())

	# Tornado fault injection at each stage -> exact rollback, no charge (real board/supply).
	econ.boosters.add_charges(BoosterInventory.TORNADO, 10)
	var color = colors[0]
	var active_before = h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)
	for stage in ["tornado_guard", "tornado_board", "tornado_slots", "tornado_supply"]:
		adapter.set_fault_injector(func(s): return s == stage)
		var charges_before = econ.boosters.charges(BoosterInventory.TORNADO)
		var r = bs.apply_tornado(adapter, color)
		_ok(not r["ok"], "tornado fails at %s" % stage)
		_ok(h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == active_before, "%s: board fully restored on rollback" % stage)
		_ok(econ.boosters.charges(BoosterInventory.TORNADO) == charges_before, "%s: no charge consumed on rollback" % stage)
	adapter.set_fault_injector(Callable())
	# Happy tornado: real purge of one color across board + supply.
	var color_cells = _count_color(h.get_board(), color)
	var r2 = bs.apply_tornado(adapter, color)
	_ok(r2["ok"], "tornado commits on the real engines")
	_ok(_count_color(h.get_board(), color) == 0, "all ACTIVE cells of the color purged from real BoardState")
	_ok(h.get_board().count_cells_by_state(BoardState.CellState.ACTIVE) == active_before - color_cells, "exactly the color's cells were cleared")

	_free_host(h)

func _terminal_economy() -> void:
	print("[terminal-driven economy]")
	var h = await _make_host(0)
	if h == null:
		return
	var econ = h.get_economy()
	var sb_before = econ.wallet.scrub_bucks()
	var bp_before = econ.wallet.bot_parts()
	_drain(h)
	_ok(h.get_completion().is_won(), "real stack reaches WON")
	# WON drove first-clear (EASY 50 + 1 bot part) + streak (1 -> +1 SB) once.
	_ok(econ.wallet.scrub_bucks() == sb_before + 50 + 1, "WON granted first-clear 50 + streak 1 SB")
	_ok(econ.wallet.bot_parts() == bp_before + 1, "WON granted +1 bot part")
	_ok(econ.streak.streak() == 1, "win streak advanced to 1")
	_ok(h.get_progression().current_level() == h.progression_level + 1, "progression frontier advanced")
	_free_host(h)

func _count_color(board, color) -> int:
	var n := 0
	for i in range(board.get_cell_count()):
		if board.get_cell_state(i) == BoardState.CellState.ACTIVE and board.get_color_id(i) == int(color):
			n += 1
	return n

# --- host driver ---

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
	print("M39 V02 production integration evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
