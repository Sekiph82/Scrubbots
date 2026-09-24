extends SceneTree
## M39-C001 V03 — REAL host integration for F-M39-V02-007/008/014 + sixth-slot
## presentation (F-M39-V02-001).
## Run: godot --headless --path . -s res://tests/m39_v03_integration.gd

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

const DT := 1.0
const MAX_TICKS := 80000

var _fail := 0

func _initialize() -> void:
	await _plus_one_slot_strip_grows()
	await _retry_after_action_consumes_heart()
	await _first_clear_gated_by_frontier()
	_done()

func _plus_one_slot_strip_grows() -> void:
	print("[+1 slot -> engine+strip both grow to 6 (F-M39-V02-001)]")
	var h = await _make_host()
	if h == null: return
	var strip = h.get_screen().get_five_slot_strip()
	_ok(strip.get_slot_count() == 5, "baseline strip = 5")
	h.get_economy().boosters.add_charges(BoosterInventory.PLUS_ONE_SLOT, 1)
	_ok(h.activate_plus_one_slot(), "+1 slot activated")
	_ok(strip.get_slot_count() == 6, "strip grew to 6")
	_ok(h.get_slots().get_slot_count() == 6, "engine grew to 6")
	# Origin provider gives a finite origin for slot 5 now.
	var origin = h._origin_provider.origin_for_slot(5) if "_origin_provider" in h else Vector2(0, 0)
	# Access via public seam.
	origin = h._origin_provider.origin_for_slot(5)
	_ok(is_finite(origin.x) and is_finite(origin.y), "slot 5 origin finite when capacity=6")
	_free_host(h)

func _retry_after_action_consumes_heart() -> void:
	print("[retry after action consumes heart + resets streak (F-M39-V02-007)]")
	var h = await _make_host()
	if h == null: return
	var econ = h.get_economy()
	var hearts_before = econ.hearts.hearts()
	# Case A — retry AFTER a real player action but BEFORE a win: heart consumed,
	# streak reset to 0 (already 0 here). Streak state proxy: was_started=true.
	h._on_activation_event(0, true, "")
	_ok(econ.streak.gameplay_started(), "gameplay-started armed by real activation")
	_ok(h.retry(), "retry succeeded")
	_ok(econ.hearts.hearts() == hearts_before - 1, "heart consumed after retry-with-gameplay")
	_ok(not econ.streak.gameplay_started(), "gameplay-started cleared after retry")
	# Case B — pre-action retry: no heart consumed.
	var hearts_mid = econ.hearts.hearts()
	_ok(h.retry(), "pre-action retry succeeded")
	_ok(econ.hearts.hearts() == hearts_mid, "no heart consumed on pre-action retry")
	_free_host(h)

func _first_clear_gated_by_frontier() -> void:
	print("[first-clear gated by M37 frontier (F-M39-V02-014)]")
	var h = await _make_host()
	if h == null: return
	var econ = h.get_economy()
	# Jump the frontier ahead of progression_level via the non-shipping debug seam.
	# Now progression_level (1) is stale; a WON terminal must NOT grant economy.
	h.get_progression().debug_set_current_level(5)
	var sb_before = econ.wallet.scrub_bucks()
	var bp_before = econ.wallet.bot_parts()
	var streak_before = econ.streak.streak()
	# Drive to WON.
	_drain(h)
	_ok(h.get_completion().is_won(), "real stack reaches WON")
	# Stale (progression_level != current_level) -> no economy.
	_ok(econ.wallet.scrub_bucks() == sb_before, "no first-clear SB on stale progression")
	_ok(econ.wallet.bot_parts() == bp_before, "no first-clear bot part on stale progression")
	_ok(econ.streak.streak() == streak_before, "streak unchanged on stale progression")
	_free_host(h)

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
			if h.get_completion().is_terminal(): break
			runtime.tick(DT)
			break

func _make_host():
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var host = ProductionGameplayHost.new()
	host.auto_build = false
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(host)
	await process_frame; await process_frame
	var ok: bool = host.build()
	_ok(ok, "host built (%s)" % host.get_build_error())
	if not ok: return null
	await process_frame; await process_frame
	host.get_screen().relayout()
	await process_frame; await process_frame
	host.get_runtime().set_process(false)
	host.set_meta("sub", sub)
	return host

func _free_host(host) -> void:
	if host == null: return
	var sub = host.get_meta("sub") if host.has_meta("sub") else null
	if sub != null and is_instance_valid(sub): sub.free()

func _any_moving(agent_layer) -> bool:
	if agent_layer == null: return false
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving(): return true
	return false

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M39 V03 integration evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
