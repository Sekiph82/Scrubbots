extends Node
## ProductionRuntimeController — M29 production clock / runtime driver. Preload this
## script (res://scripts/gameplay/runtime/production_runtime_controller.gd); do not
## rely on global class_name (AL-001).
##
## This is the automatic production cadence driver the accepted M26 AutoDispatchScheduler
## needs: M26 guarantees ONE accepted assignment per step(), and this controller calls
## step() on a deterministic timer (never run_until_idle(), never a per-frame burst). It
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

## Max scheduler steps serviced in a single _process frame. Bounds the catch-up after a
## long/first frame so a huge delta cannot become an uncontrolled burst; each serviced
## step is still exactly one M26 cadence event -> at most one assignment.
const MAX_STEPS_PER_FRAME := 4

var _scheduler = null            # AutoDispatchScheduler (M26)
var _speed: GameplaySpeedAuthority = null
var _agent_layer: Node2D = null  # parent node the dispatcher attaches agents under
var _gesture_canceler = null     # optional object with cancel_all_gestures()

var _bound := false
var _user_paused := false
var _system_suspended := false
var _accum := 0.0

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

func get_speed_authority() -> GameplaySpeedAuthority:
	return _speed

# ------------------------------------------------------------------- pause -----

func is_paused() -> bool:
	return _user_paused or _system_suspended

func is_user_paused() -> bool:
	return _user_paused

func is_system_suspended() -> bool:
	return _system_suspended

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

## Manual bottom-right toggle. Returns the new 2x state.
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

## Prime an immediate scheduler step on the next processed frame (a successful placement
## may wake scheduling promptly) without violating the one-assignment-per-step law.
func request_immediate_step() -> void:
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
	if is_paused():
		return
	var factor: float = _speed.factor()
	# Agent travel: this controller is the SOLE time source (self-_process disabled), so
	# advancing every moving agent by delta*factor accelerates current + future agents
	# uniformly at 2x and freezes them under pause. advance() drives the whole
	# arrival -> M20 authenticated clear -> M25 finalize chain synchronously.
	_drive_agents(delta * factor)
	# Deterministic cadence: one scheduler step per cadence interval (base at 1x, half at
	# 2x). Bounded catch-up; never run_until_idle.
	_accum += delta
	var interval: float = _speed.cadence_interval()
	var serviced := 0
	while _accum >= interval and serviced < MAX_STEPS_PER_FRAME:
		_accum -= interval
		serviced += 1
		_scheduler.step()
	# Agents spawned by the steps above have not run their own _process yet; disable it now
	# so the next frame they too are driven solely by this controller.
	_disable_agent_self_process()

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
