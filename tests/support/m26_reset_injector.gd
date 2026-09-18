extends Node
## M26-C001 V02 test double (F-M26-V01-STRICT-001). Injects EXACTLY ONE deferred
## AutoDispatchScheduler.reset() at a chosen mid-step callback boundary, then behaves
## transparently. It doubles as both the scheduler's origin_provider (origin_for_slot)
## and the dispatcher's agent_factory (make_agent), so a single object can fire a reset
## either from the origin/route/access boundary (BEFORE dispatch) or from inside the
## preclaimed dispatch (the agent-factory callback). A Node so the test can free it.

const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

var _sched = null
var _origin: Vector2 = Vector2(10.0, 23.0)
## 1-based origin_for_slot call index that fires the reset (-1 disables). The single
## occupied same-color slot's origin is looked up once while building access (BEFORE the
## claim) and once after the claim (BEFORE dispatch), so index 2 fires reset with a live
## M25 claim already established but no robot yet.
var _origin_fire_on: int = -1
var _origin_calls: int = 0
var _factory_fires: bool = false
var _factory_fired: bool = false
var reset_calls: int = 0

func setup(sched, origin: Vector2) -> void:
	_sched = sched
	_origin = origin

func arm_origin(fire_on_call: int) -> void:
	_origin_fire_on = fire_on_call

func arm_factory() -> void:
	_factory_fires = true

func _fire() -> void:
	reset_calls += 1
	_sched.reset()

func origin_for_slot(slot_index: int) -> Vector2:
	_origin_calls += 1
	if _sched != null and _origin_fire_on == _origin_calls:
		_origin_fire_on = -1  # single shot; later scheduling proceeds untouched
		_fire()
	return _origin

func make_agent():
	if _sched != null and _factory_fires and not _factory_fired:
		_factory_fired = true
		_fire()
	return ScrubbotAgent.new()
