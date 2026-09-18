extends Node
## ProductionInputController — M29 supply-front production input gate. Preload this
## script (res://scripts/ui/production_input_controller.gd); do not rely on global
## class_name (AL-001).
##
## This is the ONLY place a supply-front activation becomes real gameplay. It owns the
## authoritative M23 BatchSupplyEngine + M24 FiveSlotBatchEngine + M26 scheduler +
## runtime references; the presentation BatchSupplyPanel owns none of them and only
## reports which front column the player activated (front_batch_activated). The gate:
##
##   1. validates focus/pause state (no activation while paused/suspended);
##   2. serializes the transaction (a reentrant/overlapping activation is dropped);
##   3. calls the REAL FiveSlotBatchEngine.select_front_batch(real M23, column)
##      (never M23 commit directly, never a destination slot, never legacy activation);
##   4. on rejection preserves supply + slots exactly (M24 guarantees atomicity) and
##      triggers no scheduler wake and no auto-2x;
##   5. on success refreshes the DETACHED M23/M24 UI snapshots, wakes the scheduler
##      (notify_placed), then and only then reads authoritative M23.is_exhausted();
##   6. if exhausted, switches runtime speed to 2x (owner rule §3).
##
## The controller validates that the authoritative M23 column count is exactly 3/4/5 at
## bind — UI clamping is never trusted as gameplay truth (M28 audit O-M28-002).

signal activation_result(column: int, ok: bool, error: String)

const BatchSupplyEngine = preload("res://scripts/gameplay/supply/batch_supply_engine.gd")
const FiveSlotBatchEngine = preload("res://scripts/gameplay/slots/five_slot_batch_engine.gd")

var _supply = null       # BatchSupplyEngine (M23) — authoritative
var _slots = null        # FiveSlotBatchEngine (M24) — authoritative
var _scheduler = null    # AutoDispatchScheduler (M26)
var _runtime = null      # ProductionRuntimeController
var _panel = null        # BatchSupplyPanel (presentation input surface)
var _screen = null       # GameplayScreen (detached snapshot refresh + speed visual)

var _bound := false
var _activating := false
var _last_placement := {}   # detached copy of the most recent successful result

## Bind the production bundle. Fail-closed: returns false and stays unbound on a
## null/foreign dependency OR an authoritative M23 column count outside 3..5. Connects
## the panel's presentation signal and enables front-only input.
func bind(supply, slots, scheduler, runtime, panel, screen) -> bool:
	if _bound:
		return false
	if not (supply is BatchSupplyEngine):
		return false
	# Authoritative M23 truth must be a legal 3/4/5-column production supply — never a
	# UI-clamped count (M28 audit O-M28-002).
	var cols: int = supply.get_column_count()
	if cols < 3 or cols > 5:
		return false
	if not (slots is FiveSlotBatchEngine):
		return false
	if typeof(scheduler) != TYPE_OBJECT or not scheduler.has_method("notify_placed"):
		return false
	if typeof(runtime) != TYPE_OBJECT or not runtime.has_method("is_paused"):
		return false
	if typeof(panel) != TYPE_OBJECT or not panel.has_signal("front_batch_activated"):
		return false
	_supply = supply
	_slots = slots
	_scheduler = scheduler
	_runtime = runtime
	_panel = panel
	_screen = screen
	_bound = true
	_panel.enable_front_input()
	if not _panel.front_batch_activated.is_connected(_on_front_activated):
		_panel.front_batch_activated.connect(_on_front_activated)
	return true

func is_bound() -> bool:
	return _bound

func get_last_placement() -> Dictionary:
	return _last_placement.duplicate(true)

## Cancel any in-progress panel gesture (focus/background loss seam for the runtime).
func cancel_all_gestures() -> void:
	if _panel != null and is_instance_valid(_panel):
		_panel.cancel_all_gestures()

## One accepted front activation. Public so headless tests can drive it deterministically
## without synthesizing raw InputEvents; the panel signal routes here in the live game.
func activate_front(column: int) -> Dictionary:
	if not _bound:
		return {"ok": false, "error": "unbound"}
	# Serialize: a reentrant/overlapping activation while one transaction is committing is
	# dropped (no double consume / double place / overfill).
	if _activating:
		var re := {"ok": false, "error": "reentrant"}
		activation_result.emit(column, false, "reentrant")
		return re
	# No activation while paused or system-suspended (WP03).
	if _runtime != null and _runtime.is_paused():
		var pr := {"ok": false, "error": "paused"}
		activation_result.emit(column, false, "paused")
		return pr
	_activating = true
	var result := _commit_activation(column)
	_activating = false
	activation_result.emit(column, bool(result.get("ok", false)), str(result.get("error", "")))
	return result

func _commit_activation(column: int) -> Dictionary:
	# REAL M24 transactional placement against REAL M23. M24 owns full-slots rejection,
	# atomic supply commit, and the busy guard — a rejection consumes nothing.
	var res: Dictionary = _slots.select_front_batch(_supply, column)
	if not bool(res.get("ok", false)):
		# Rejection (slots full / no front / reentrant): supply + slots unchanged, no
		# scheduler wake, no auto-2x.
		return {"ok": false, "error": str(res.get("error", "rejected"))}
	_last_placement = res.duplicate(true)
	# Refresh DETACHED M23/M24 snapshots only after the authoritative result.
	if _screen != null and is_instance_valid(_screen):
		_screen.update_snapshots(_slots.snapshot(), _supply.player_snapshot())
	# Wake the scheduler and prime a prompt (still one-per-step) cadence.
	_scheduler.notify_placed()
	if _runtime != null and _runtime.has_method("request_immediate_step"):
		_runtime.request_immediate_step()
	# Only AFTER a successful final transfer, read authoritative M23 exhaustion; hidden
	# future batches count. Exhausted => switch runtime to 2x (idempotent if already 2x).
	if _supply.is_exhausted() and _runtime != null and _runtime.has_method("set_speed_2x"):
		_runtime.set_speed_2x(true)
		if _screen != null and is_instance_valid(_screen) and _screen.has_method("set_speed_2x"):
			_screen.set_speed_2x(true)
	return res

func _on_front_activated(column: int) -> void:
	activate_front(column)
