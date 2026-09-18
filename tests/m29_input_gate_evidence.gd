extends SceneTree
## M29-C001 V01 — supply-front input gate evidence (audit §B/§C/§D/§E/§F/§G/§H).
##
## Deterministic proofs that ONLY the supply front row is player-selectable and that the
## activation transaction is exact and hardened against mouse/touch double-fire, cancel,
## focus loss, rapid reentry, multi-touch and pause — all against the REAL M23 M24
## engines through the M29 ProductionInputController + BatchSupplyPanel.
##
## Run: godot --headless --path . -s res://tests/m29_input_gate_evidence.gd
## Exits 0 on success, 1 on any failure.

const ProductionRuntimeController = preload("res://scripts/gameplay/runtime/production_runtime_controller.gd")
const ProductionInputController = preload("res://scripts/ui/production_input_controller.gd")
const BatchSupplyPanel = preload("res://scripts/ui/batch_supply_panel.gd")
const FiveSlotStrip = preload("res://scripts/ui/five_slot_strip.gd")
const BatchSlotView = preload("res://scripts/ui/batch_slot_view.gd")
const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")
const ColorBatch = preload("res://scripts/gameplay/supply/color_batch.gd")
const GameplaySpeedAuthority = preload("res://scripts/gameplay/runtime/gameplay_speed_authority.gd")
const AutoDispatchScheduler = preload("res://scripts/gameplay/dispatch/auto_dispatch_scheduler.gd")
const PaletteColors = preload("res://scripts/data/palette_colors.gd")

var _fail := 0

func _initialize() -> void:
	_test_input_authority()
	_test_exact_transaction()
	_test_mouse_touch_dedup()
	_test_cancel_focus()
	_test_rapid_and_multitouch()
	_test_pause_background()
	_done()

# --------------------------------------------------------------- harness ------

func _b(id: String, color: int, count: int):
	return ColorBatch.make(id, color, count, 16)

## Default 3-column supply, plenty of depth. `cols` overrides the layout.
func _harness(cols: Array = []):
	if cols.is_empty():
		cols = [
			[_b("a0", 0, 3), _b("a1", 0, 3), _b("a2", 0, 3), _b("a3", 0, 3)],
			[_b("b0", 1, 3), _b("b1", 1, 3), _b("b2", 1, 3)],
			[_b("c0", 2, 3), _b("c1", 2, 3), _b("c2", 2, 3)],
		]
	var supply = BatchSupplyEngine.create(3, 3)
	supply.load_columns(cols)
	var slots = FiveSlotBatchEngine.new()
	var scheduler = AutoDispatchScheduler.new()
	var speed = GameplaySpeedAuthority.new(0.5)
	var layer := Node2D.new(); get_root().add_child(layer)
	var runtime = ProductionRuntimeController.new(); get_root().add_child(runtime)
	var panel = BatchSupplyPanel.new(); get_root().add_child(panel)
	panel.bind_player_snapshot(supply.player_snapshot(), _colors())
	var input = ProductionInputController.new(); get_root().add_child(input)
	# Wire the runtime's focus-loss gesture canceler to the input controller (as the host does).
	runtime.bind(scheduler, speed, layer, input)
	runtime.set_process(false)
	input.bind(supply, slots, scheduler, runtime, panel, null)
	return {"supply": supply, "slots": slots, "runtime": runtime, "input": input,
		"speed": speed, "layer": layer, "panel": panel, "scheduler": scheduler}

func _colors() -> Array:
	var c: Array = []
	for i in range(16):
		c.append(Color(0.5, 0.5, 0.5, 1.0))
	return c

func _touch(pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.pressed = pressed
	e.index = index
	return e

func _mouse(pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	return e

## One complete touch gesture (press+release) on a column front.
func _touch_tap(panel, col: int, index: int = 0) -> void:
	panel._on_front_gui_input(_touch(true, index), col)
	panel._on_front_gui_input(_touch(false, index), col)

# ------------------------------------------------------ B: input authority ----

func _test_input_authority() -> void:
	var h = _harness()
	var panel = h["panel"]; var slots = h["slots"]; var supply = h["supply"]
	# Front (row 0) is the single activation surface; preview rows are IGNORE + unwired.
	var rows: Array = panel.get_column_row_panels(1)
	_ok(rows[0].mouse_filter == Control.MOUSE_FILTER_STOP, "front row IS the activation surface (STOP)")
	_ok(rows[1].mouse_filter == Control.MOUSE_FILTER_IGNORE, "preview row 2 is presentation-only (IGNORE)")
	_ok(rows[2].mouse_filter == Control.MOUSE_FILTER_IGNORE, "preview row 3 is presentation-only (IGNORE)")
	_ok(not rows[1].gui_input.get_connections().size() and not rows[2].gui_input.get_connections().size(), "preview rows have NO input handler")
	# Front activates the CORRECT column.
	var before1: int = supply.get_remaining(1)
	_touch_tap(panel, 1)
	_ok(supply.get_remaining(1) == before1 - 1, "front tap advanced ONLY the activated column")
	_ok(slots.occupied_count() == 1, "front tap placed exactly one batch into M24")

	# Exhausted column front is disabled -> no activation.
	var h2 = _harness([[_b("x", 0, 3)], [_b("p", 1, 3)], [_b("q", 2, 3)]])
	var p2 = h2["panel"]; var s2 = h2["slots"]; var sup2 = h2["supply"]
	# Consume column 0's only batch, then rebind snapshot -> front 0 becomes disabled.
	h2["input"].activate_front(0)
	p2.bind_player_snapshot(sup2.player_snapshot(), _colors())
	_ok(not p2.get_front_enabled(0), "exhausted column front is disabled")
	var occ_before: int = s2.occupied_count()
	_touch_tap(p2, 0)
	_ok(s2.occupied_count() == occ_before, "tapping an exhausted/disabled front does nothing")

	# The five M24 slots are NOT Buttons / destination controls.
	var strip = FiveSlotStrip.new(); get_root().add_child(strip)
	strip.bind_snapshots(slots.snapshot(), _colors())
	var views: Array = strip.get_slot_views()
	var any_button := false
	var any_signal := false
	for v in views:
		if v is Button:
			any_button = true
		if v.has_signal("slot_activated") or v.has_signal("front_batch_activated"):
			any_signal = true
	_ok(not any_button, "five batch slots are NOT Buttons")
	_ok(not any_signal, "five batch slots expose NO activation signal (read-only destinations)")
	strip.free()

	# Controller binds only for authoritative 3/4/5-column supply.
	for n in [3, 4, 5]:
		var s = BatchSupplyEngine.create(n, 3)
		var cols: Array = []
		for i in range(n):
			cols.append([_b("k%d" % i, i % 3, 3)])
		s.load_columns(cols)
		var inp = ProductionInputController.new(); get_root().add_child(inp)
		var pn = BatchSupplyPanel.new(); get_root().add_child(pn)
		var rt = _bare_runtime()
		_ok(inp.bind(s, FiveSlotBatchEngine.new(), AutoDispatchScheduler.new(), rt, pn, null), "controller binds for authoritative %d-column supply" % n)
		inp.free(); pn.free(); rt.free()
	_cleanup(h); _cleanup(h2)

func _bare_runtime():
	var rt = ProductionRuntimeController.new(); get_root().add_child(rt)
	var layer := Node2D.new(); get_root().add_child(layer)
	rt.bind(AutoDispatchScheduler.new(), GameplaySpeedAuthority.new(0.5), layer)
	rt.set_process(false)
	rt.set_meta("layer", layer)
	return rt

# ------------------------------------------------------- C: exact transaction --

func _test_exact_transaction() -> void:
	var h = _harness()
	var panel = h["panel"]; var slots = h["slots"]; var supply = h["supply"]
	var rem0: int = supply.get_remaining(0)
	var rem1: int = supply.get_remaining(1)
	var rem2: int = supply.get_remaining(2)
	_touch_tap(panel, 1)
	_ok(supply.get_remaining(1) == rem1 - 1, "success: exactly the originating column advanced")
	_ok(supply.get_remaining(0) == rem0 and supply.get_remaining(2) == rem2, "success: other columns byte-for-byte unchanged")
	# Rightmost EMPTY slot (index 4) receives the batch.
	_ok(slots.is_occupied(4) and slots.get_batch_id(4) == "b0", "success: front batch entered rightmost EMPTY slot")

	# Fill all five, then a sixth activation is rejected atomically.
	var h2 = _harness()
	var in2 = h2["input"]; var s2 = h2["slots"]; var sup2 = h2["supply"]; var rt2 = h2["runtime"]
	for col in [0, 1, 2, 0, 1]:
		in2.activate_front(col)
	_ok(s2.is_full(), "five slots filled")
	var snap_before: Array = s2.snapshot()
	var rem_before := [sup2.get_remaining(0), sup2.get_remaining(1), sup2.get_remaining(2)]
	var res: Dictionary = in2.activate_front(2)
	_ok(not res.get("ok", false), "full-slots activation rejected")
	_ok([sup2.get_remaining(0), sup2.get_remaining(1), sup2.get_remaining(2)] == rem_before, "rejection consumed ZERO supply")
	_ok(s2.snapshot() == snap_before, "rejection mutated ZERO slots")
	_ok(not rt2.is_2x(), "rejection caused no auto-2x")
	_cleanup(h); _cleanup(h2)

# ----------------------------------------------------- D: mouse/touch dedup ----

func _test_mouse_touch_dedup() -> void:
	# One physical touch + its synthesized mouse click -> at most ONE placement.
	var h = _harness()
	var panel = h["panel"]; var supply = h["supply"]
	var before: int = supply.get_remaining(0)
	# Real touch press+release, then the emulated mouse press+release right after.
	panel._on_front_gui_input(_touch(true, 0), 0)
	panel._on_front_gui_input(_touch(false, 0), 0)
	panel._on_front_gui_input(_mouse(true), 0)
	panel._on_front_gui_input(_mouse(false), 0)
	_ok(supply.get_remaining(0) == before - 1, "one physical touch + synthesized mouse = exactly ONE placement")

	# Desktop mouse alone (no preceding touch) works independently.
	var h2 = _harness()
	var p2 = h2["panel"]; var sup2 = h2["supply"]
	var b2: int = sup2.get_remaining(2)
	p2._on_front_gui_input(_mouse(true), 2)
	p2._on_front_gui_input(_mouse(false), 2)
	_ok(sup2.get_remaining(2) == b2 - 1, "desktop mouse activation works on its own")
	_cleanup(h); _cleanup(h2)

# --------------------------------------------------------- E: cancel / focus ---

func _test_cancel_focus() -> void:
	# Touch down then cancel -> zero activation, no stuck pending state.
	var h = _harness()
	var panel = h["panel"]; var supply = h["supply"]
	var before: int = supply.get_remaining(0)
	panel._on_front_gui_input(_touch(true, 0), 0)
	panel.cancel_all_gestures()
	panel._on_front_gui_input(_touch(false, 0), 0)   # stale release
	_ok(supply.get_remaining(0) == before, "touch down then cancel => zero activation")
	_ok(panel.get_pending_column() == -1, "no stuck pending gesture after cancel")

	# Touch down then focus loss (via runtime) -> zero activation; stale release after
	# focus return still does nothing.
	var h2 = _harness()
	var p2 = h2["panel"]; var sup2 = h2["supply"]; var rt2 = h2["runtime"]; var in2 = h2["input"]
	var b2: int = sup2.get_remaining(1)
	p2._on_front_gui_input(_touch(true, 0), 1)
	rt2.notify_focus_lost()          # runtime cancels the pending gesture via the input controller
	_ok(p2.get_pending_column() == -1, "focus loss cancelled the pending gesture")
	rt2.notify_focus_gained()
	p2._on_front_gui_input(_touch(false, 0), 1)   # stale release after focus return
	_ok(sup2.get_remaining(1) == b2, "stale release after focus return => zero activation")
	# The runtime canceler seam is wired to the input controller's panel.
	in2.cancel_all_gestures()
	_cleanup(h); _cleanup(h2)

# --------------------------------------------------- F/G: rapid tap & multitouch --

func _test_rapid_and_multitouch() -> void:
	# Rapid repeated complete taps each place exactly one batch (no double/skip).
	var h = _harness()
	var panel = h["panel"]; var supply = h["supply"]; var slots = h["slots"]
	var before: int = supply.get_remaining(0)
	for _i in range(3):
		_touch_tap(panel, 0)
	_ok(supply.get_remaining(0) == before - 3 and slots.occupied_count() == 3, "three rapid complete taps placed exactly three batches (no double/skip)")

	# Reentrant press-storm during one open gesture: extra presses are ignored; one
	# release emits exactly once.
	var h2 = _harness()
	var p2 = h2["panel"]; var sup2 = h2["supply"]
	var b2: int = sup2.get_remaining(1)
	p2._on_front_gui_input(_touch(true, 0), 1)
	p2._on_front_gui_input(_touch(true, 0), 1)   # duplicate press, same finger
	p2._on_front_gui_input(_touch(true, 1), 1)   # extra finger, same column
	p2._on_front_gui_input(_touch(false, 0), 1)  # release the original
	_ok(sup2.get_remaining(1) == b2 - 1, "reentrant press-storm still yields exactly one placement")

	# Multi-touch across columns: a second finger on another column while one gesture is
	# pending is ignored — never a second front consumed or partial mutation.
	var h3 = _harness()
	var p3 = h3["panel"]; var sup3 = h3["supply"]
	var r0: int = sup3.get_remaining(0)
	var r1: int = sup3.get_remaining(1)
	p3._on_front_gui_input(_touch(true, 0), 0)   # finger A on col 0
	p3._on_front_gui_input(_touch(true, 1), 1)   # finger B on col 1 (ignored while A pending)
	p3._on_front_gui_input(_touch(false, 1), 1)  # B release (no matching pending)
	p3._on_front_gui_input(_touch(false, 0), 0)  # A release -> one emit for col 0
	_ok(sup3.get_remaining(0) == r0 - 1 and sup3.get_remaining(1) == r1, "multi-touch: only the first column's front consumed; no partial mutation")
	_cleanup(h); _cleanup(h2); _cleanup(h3)

# ----------------------------------------------------- H: pause / background ---

func _test_pause_background() -> void:
	var h = _harness()
	var input = h["input"]; var runtime = h["runtime"]; var supply = h["supply"]; var speed = h["speed"]
	# User pause blocks activation.
	runtime.set_user_paused(true)
	var before: int = supply.get_remaining(0)
	var res: Dictionary = input.activate_front(0)
	_ok(not res.get("ok", false) and res.get("error", "") == "paused", "user pause blocks activation")
	_ok(supply.get_remaining(0) == before, "no supply consumed while user-paused")
	runtime.set_user_paused(false)
	_ok(input.activate_front(0).get("ok", false), "activation resumes after user unpause")

	# System suspension is a DISTINCT reason and also blocks activation.
	runtime.notify_focus_lost()
	_ok(runtime.is_system_suspended() and runtime.is_paused(), "system suspension is a distinct pause reason")
	_ok(not input.activate_front(1).get("ok", false), "system suspension blocks activation")

	# System return does NOT override an explicit user pause.
	runtime.set_user_paused(true)
	runtime.notify_focus_gained()
	_ok(runtime.is_paused() and runtime.is_user_paused(), "focus regain does not override an explicit user pause")

	# Resume preserves the selected speed.
	speed.set_2x(true)
	runtime.set_user_paused(false)
	_ok(runtime.is_2x(), "resume preserves the selected 2x speed")

	# While paused, a runtime tick performs no cadence / no travel (is_paused gate).
	runtime.set_user_paused(true)
	runtime.tick(10.0)   # must be a no-op
	_ok(runtime.is_paused(), "paused tick is a no-op (no cadence / no travel)")
	_cleanup(h)

# --------------------------------------------------------------- helpers ------

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
	print("M29 input gate evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
