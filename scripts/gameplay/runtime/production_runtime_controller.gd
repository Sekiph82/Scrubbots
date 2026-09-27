extends Node
## ProductionRuntimeController — M29 production clock / runtime driver. Preload this
## script (res://scripts/gameplay/runtime/production_runtime_controller.gd); do not
## rely on global class_name (AL-001).
##
## This is the automatic production cadence driver the accepted M26 AutoDispatchScheduler
## needs: each M26 step() is ONE bounded parallel dispatch wave (at most one assignment per
## eligible slot, M52-C001-R01), and this controller calls step() on a deterministic timer
## (never run_until_idle(), at most one wave per frame). It
## also owns the in-flight ScrubbotAgent travel clock and the two pause reasons.
##
## Speed authority (OWNER_GAMEPLAY_SPEED_RULE_V01): the single GameplaySpeedAuthority
## sets factor 1x/2x. 2x halves the cadence interval AND doubles the per-frame travel
## delta fed to agents — it does NOT use Engine.time_scale and touches NO gameplay
## accounting. Both current and future agents accelerate uniformly because EVERY agent
## is advanced with the same delta*factor here (agent self-_process is disabled so this
## controller is the sole time source; pause therefore truly freezes travel).
##
## Pause reasons (WP03): user pause and system/background/focus suspension are distinct.
## While EITHER is active there is no cadence, no agent travel, and no accepted input.
## Focus/background loss cancels pending gestures; focus regain resumes ONLY if the user
## had not explicitly paused, never synthesizes a stale tap, and preserves the selected
## 1x/2x speed. A full reset restores 1x.

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")
const GameplaySpeedAuthority = preload("res://scripts/gameplay/runtime/gameplay_speed_authority.gd")
const RuntimePerfProbe = preload("res://scripts/debug/runtime_perf_probe.gd")

## Max dispatch waves serviced in a single _process frame (M52-C001-R01). Each M26 step()
## is now one parallel wave (<= one assignment per eligible slot, so up to 5/6 agents), so a
## long/first frame must never become a multi-wave storm: exactly one wave per frame, and
## any cadence backlog beyond one pending interval is dropped (no unbounded catch-up).
const MAX_STEPS_PER_FRAME := 1
## Lanes of the current wave serviced per frame (M52-C001-R01 stutter fix). One exact-slot
## claim + route per frame keeps the per-frame cost to a single lane; a full 5/6-lane wave
## still completes within 5/6 frames, far below one cadence interval (0.5 s / 0.25 s).
const MAX_LANES_PER_FRAME := 1

var _scheduler = null            # AutoDispatchScheduler (M26)
var _speed: GameplaySpeedAuthority = null
var _agent_layer: Node2D = null  # parent node the dispatcher attaches agents under
var _gesture_canceler = null     # optional object with cancel_all_gestures()

var _bound := false
var _user_paused := false
var _system_suspended := false
## M30 terminal stop: a DISTINCT halt reason from user pause and system suspension
## (OWNER_WIN_LOSE_RETRY_DECISION_V01 §3). Set once the M30 CompletionController latches a
## terminal WON/LOST/ERROR result — it freezes cadence + travel exactly like pause, but is
## its own state so a pause/focus toggle can never clear it and a terminal result is never
## disguised as a user pause. A full reset_runtime() (Retry) clears it back to a live 1x
## attempt.
var _terminal_stopped := false
var _accum := 0.0
## Optional live-presentation sync (M29-C001 V03): invoked at the end of every driven
## tick so the five-slot UI refreshes from a fresh authoritative M24 snapshot after
## scheduler-driven mutations (commit / WAITING / wake / rollback / finalize / completion),
## not only after player placement. Presentation-only; it must not mutate gameplay truth.
var _state_sync: Callable = Callable()

func _ready() -> void:
	# Keep processing even if the SceneTree is globally paused, so this controller — not
	# a blind tree pause — remains the single, explicit gameplay clock.
	process_mode = Node.PROCESS_MODE_ALWAYS

## Bind the production runtime bundle. `scheduler` must expose step()/notify_placed();
## `speed` is the GameplaySpeedAuthority; `agent_layer` is the Node2D the dispatcher
## parents agents under; `gesture_canceler` (optional) exposes cancel_all_gestures()
## (the supply input surface). Fail-closed: returns false and stays unbound on a
## missing/foreign dependency, and a second bind is rejected.
func bind(scheduler, speed, agent_layer, gesture_canceler = null) -> bool:
	if _bound:
		return false
	if typeof(scheduler) != TYPE_OBJECT or not scheduler.has_method("step") or not scheduler.has_method("notify_placed"):
		return false
	if not (speed is GameplaySpeedAuthority):
		return false
	if not (agent_layer is Node2D):
		return false
	if gesture_canceler != null and not (gesture_canceler is Object and gesture_canceler.has_method("cancel_all_gestures")):
		return false
	_scheduler = scheduler
	_speed = speed
	_agent_layer = agent_layer
	_gesture_canceler = gesture_canceler
	_bound = true
	return true

func is_bound() -> bool:
	return _bound

## Install the live five-slot presentation sync callback (see _state_sync).
func set_state_sync(cb: Callable) -> void:
	_state_sync = cb

func get_speed_authority() -> GameplaySpeedAuthority:
	return _speed

# ------------------------------------------------------------------- pause -----

func is_paused() -> bool:
	return _user_paused or _system_suspended

func is_user_paused() -> bool:
	return _user_paused

func is_system_suspended() -> bool:
	return _system_suspended

func is_terminal_stopped() -> bool:
	return _terminal_stopped

## M30 terminal latch entry/exit. A latched WON/LOST/ERROR sets terminal stop true; it
## freezes cadence + travel without touching the user-pause / system-suspension reasons or
## the selected 1x/2x speed. Distinct from pause so focus/pause callbacks cannot clear it.
func set_terminal_stopped(value: bool) -> void:
	_terminal_stopped = value

## Explicit user pause/unpause (the on-screen Pause control). Preserves the selected
## speed. Unpausing does NOT clear a separate system suspension.
func set_user_paused(value: bool) -> void:
	_user_paused = value

## System/background/focus suspension entry. Cancels any pending input gesture, blocks
## new activations and stops cadence + travel. Preserves gameplay + speed.
func notify_focus_lost() -> void:
	_system_suspended = true
	if _gesture_canceler != null and is_instance_valid(_gesture_canceler):
		_gesture_canceler.cancel_all_gestures()

## Foreground/focus regain. Clears ONLY the system suspension; an explicit user pause
## survives. Never synthesizes a stale tap and never changes the selected speed.
func notify_focus_gained() -> void:
	_system_suspended = false

# ------------------------------------------------------------------- speed -----

func is_2x() -> bool:
	return _speed != null and _speed.is_2x()

## Raw temporal toggle seam used by M29 evidence. Economy V1 shipping input must gate
## manual activation through SpeedEntitlementService before calling this method.
func toggle_speed() -> bool:
	if _speed == null:
		return false
	return _speed.toggle()

func set_speed_2x(value: bool) -> void:
	if _speed != null:
		_speed.set_2x(value)

# ------------------------------------------------------------------- reset -----

## New level / full reset: 1x, cleared cadence accumulator, cleared pause reasons.
func reset_runtime() -> void:
	if _speed != null:
		_speed.reset()
	_accum = 0.0
	_user_paused = false
	_system_suspended = false
	_terminal_stopped = false

## A successful placement wakes scheduling promptly. With a lane-capable scheduler and a
## known slot, only that newly placed batch gets an immediate lane (M52-C001-R02); every
## other lane keeps the 1x/2x cadence. Otherwise (legacy scheduler / unknown slot) prime
## the next cadence event as before. Never more than one lane serviced per frame.
func request_immediate_step(slot: int = -1) -> void:
	if slot >= 0 and _scheduler != null and _scheduler.has_method("queue_lane"):
		_scheduler.queue_lane(slot)
		return
	if _speed != null:
		_accum = maxf(_accum, _speed.cadence_interval())

# ------------------------------------------------------------- frame driver ----

func _process(delta: float) -> void:
	tick(delta)

## One deterministic runtime tick (agent travel + bounded cadence). _process delegates
## here; headless tests disable auto-processing and call tick(fixed_dt) for determinism.
## A no-op while unbound or paused, so pause truly freezes cadence + travel.
func tick(delta: float) -> void:
	if not _bound or delta <= 0.0:
		return
	if _terminal_stopped:
		# Terminal WON/LOST/ERROR freezes cadence + travel just like pause, but is its own
		# reason so a result is never mistaken for a user pause. Retry clears it.
		return
	if is_paused():
		return
	var factor: float = _speed.factor()
	# Agent travel: this controller is the SOLE time source (self-_process disabled), so
	# advancing every moving agent by delta*factor accelerates current + future agents
	# uniformly at 2x and freezes them under pause. advance() drives the whole
	# arrival -> M20 authenticated clear -> M25 finalize chain synchronously.
	var t0 := RuntimePerfProbe.now()
	_drive_agents(delta * factor)
	RuntimePerfProbe.add("agent_drive_arrival", t0)
	# Deterministic cadence: one scheduler step per cadence interval (base at 1x, half at
	# 2x). Bounded catch-up; never run_until_idle.
	_accum += delta
	var interval: float = _speed.cadence_interval()
	if _scheduler.has_method("step_lane"):
		# Production: one wave per cadence event (lane list fixed at the event), serviced
		# MAX_LANES_PER_FRAME lane(s) per frame so claim/route cost never lands in one long
		# frame. A new wave starts only once the previous one is fully serviced.
		if not _scheduler.has_pending_lanes() and _accum >= interval:
			_accum -= interval
			_scheduler.begin_wave()
		var lanes := 0
		while lanes < MAX_LANES_PER_FRAME and _scheduler.has_pending_lanes():
			lanes += 1
			var tl := RuntimePerfProbe.now()
			_scheduler.step_lane()
			RuntimePerfProbe.add("m26_dispatch_lane", tl)
	else:
		# Legacy/duck-typed scheduler: one full step per cadence event, one per frame.
		var serviced := 0
		while _accum >= interval and serviced < MAX_STEPS_PER_FRAME:
			_accum -= interval
			serviced += 1
			var tw := RuntimePerfProbe.now()
			_scheduler.step()
			RuntimePerfProbe.add("m26_dispatch_wave", tw)
	# Drop backlog beyond one pending interval: a hitch never replays several waves later.
	_accum = minf(_accum, interval)
	# Agents spawned by the steps above have not run their own _process yet; disable it now
	# so the next frame they too are driven solely by this controller.
	_disable_agent_self_process()
	# Live five-slot presentation sync: reflect any M24 mutation this tick produced
	# (commit / WAITING / wake / rollback / finalize / completion) in the UI immediately.
	if _state_sync.is_valid():
		_state_sync.call()

func _drive_agents(scaled_delta: float) -> void:
	if _agent_layer == null or not is_instance_valid(_agent_layer):
		return
	for c in _agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			c.set_process(false)
			c.advance(scaled_delta)

func _disable_agent_self_process() -> void:
	if _agent_layer == null or not is_instance_valid(_agent_layer):
		return
	for c in _agent_layer.get_children():
		if c is ScrubbotAgent:
			c.set_process(false)

# ---------------------------------------------------------- OS notifications ---

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			notify_focus_lost()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			notify_focus_gained()
