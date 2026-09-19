extends RefCounted
## CompletionController — M30 production terminal authority (SB-M30-001..004). Preload this
## script (res://scripts/gameplay/completion/completion_controller.gd); do not rely on
## global class_name (AL-001).
##
## Owns ONE terminal result per attempt: PLAYING -> (WON | LOST | ERROR), latched EXACTLY
## ONCE, with exactly one terminal event emitted (OWNER_WIN_LOSE_RETRY_DECISION_V01 §3,
## audit §D). It holds NO win/lose truth itself — it asks the read-only CompletionEvaluator
## and only owns the latch, the dirty/event-driven cadence, and the single signal. Win/lose
## POLICY lives in the evaluator + real M27 classifier; this controller never duplicates it.
##
## Evaluation cadence (audit §G): the expensive M27 deadlock proof is dirty/event-gated.
## notify_event() marks the state dirty at a meaningful boundary (placement, authenticated
## clear, scheduler quiescence, supply exhaustion). on_tick() runs the cheap WIN/ERROR check
## every call but only runs the M27 proof when dirty; a non-terminal proof clears the dirty
## flag so repeated idle ticks with no new event never re-invoke the proof.
##
## Exact-once: once terminal, on_tick()/notify_event() are inert until reset_attempt() begins
## a fresh attempt with a fresh latch. A terminal result never flips (WON<->LOST) and never
## emits a second event.

const CompletionEvaluator = preload("res://scripts/gameplay/completion/completion_evaluator.gd")

## Emitted EXACTLY ONCE per attempt when a terminal result latches. status is one of
## CompletionEvaluator.WON / LOST / ERROR. detail is a detached diagnostic dict.
signal terminal_reached(status, detail)

var _evaluator = null
var _board = null
var _scheduler = null
var _dispatcher = null
var _claim = null
var _reservations = null
var _slots = null
var _level = null
var _supply = null

var _bound := false
var _state: StringName = CompletionEvaluator.PLAYING
## True while a meaningful gameplay boundary has occurred since the last non-terminal M27
## proof — the single gate that lets the expensive proof run (audit §G). Starts true so the
## first quiescent boundary of an attempt is evaluated once.
var _dirty := true
var _last_detail: Dictionary = {}

## Bind the read-only evaluator + the exact live engines it reads. Fail-closed: returns false
## and stays unbound on a missing dependency or a second bind.
func bind(evaluator, board, scheduler, dispatcher, claim, reservations, slots, level, supply) -> bool:
	if _bound:
		return false
	if evaluator == null or board == null or scheduler == null or dispatcher == null:
		return false
	if claim == null or reservations == null or slots == null or level == null or supply == null:
		return false
	_evaluator = evaluator
	_board = board
	_scheduler = scheduler
	_dispatcher = dispatcher
	_claim = claim
	_reservations = reservations
	_slots = slots
	_level = level
	_supply = supply
	_bound = true
	return true

func is_bound() -> bool:
	return _bound

func get_state() -> StringName:
	return _state

func is_playing() -> bool:
	return _state == CompletionEvaluator.PLAYING

func is_terminal() -> bool:
	return _state != CompletionEvaluator.PLAYING

func is_won() -> bool:
	return _state == CompletionEvaluator.WON

func is_lost() -> bool:
	return _state == CompletionEvaluator.LOST

func is_error() -> bool:
	return _state == CompletionEvaluator.ERROR

func get_last_detail() -> Dictionary:
	return _last_detail.duplicate(true)

## Mark a meaningful gameplay boundary. Cheap: it only sets the dirty flag (so the next
## on_tick may run the M27 proof) and does not itself evaluate. Inert once terminal.
func notify_event() -> void:
	if not _bound or is_terminal():
		return
	_dirty = true

## One evaluation pass. Cheap WIN/ERROR checks run every call; the M27 LOSE proof runs only
## while dirty. Latches EXACTLY ONCE and emits one terminal event. Returns the current state.
func on_tick() -> StringName:
	if not _bound or is_terminal():
		return _state
	var r: Dictionary = _evaluator.evaluate(_board, _scheduler, _dispatcher, _claim,
		_reservations, _slots, _level, _supply, _dirty)
	var st = r.get("status", CompletionEvaluator.PLAYING)
	if st == CompletionEvaluator.PLAYING:
		# A completed non-terminal M27 proof clears the dirty flag so idle ticks with no new
		# event never re-run the proof. A gated (proof-skipped) pass leaves dirty set.
		if r.get("reason", "") != "deadlock_proof_gated":
			_dirty = false
		return _state
	# Terminal: latch exactly once + emit exactly one event.
	_state = st
	_last_detail = r.duplicate(true)
	terminal_reached.emit(_state, _last_detail)
	return _state

## Begin a fresh attempt (Retry): back to PLAYING with a fresh exact-once latch and a fresh
## dirty flag so the new attempt's first quiescent boundary is evaluated.
func reset_attempt() -> void:
	_state = CompletionEvaluator.PLAYING
	_dirty = true
	_last_detail = {}
