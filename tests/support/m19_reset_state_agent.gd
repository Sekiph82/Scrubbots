extends "res://scripts/gameplay/agents/scrubbot_agent.gd"
## M19ResetStateAgent — TEST-ONLY ScrubbotAgent subclass whose overridable
## get_state() triggers dispatcher.reset() on a chosen call ordinal and can return
## an overriding state, so a test can prove reset generation WINS over the
## _dispatcher_ownable / _agent_assigned_ok verdict (V05 F-M19-STRICT-003.I).
## Preload it (AL-001).
##
## get_state() ordinals during one dispatch: 1 = _dispatcher_ownable probe (agent
## still UNASSIGNED); 2 = _agent_assigned_ok probe (agent MOVING after assign).

var dispatcher = null
var reset_on_call: int = -1
var override_state: int = -1 ## returned on the reset call; -1 = real state
var _calls: int = 0

func get_state() -> int:
	_calls += 1
	if _calls == reset_on_call:
		if dispatcher != null:
			dispatcher.reset()
		if override_state != -1:
			return override_state
	return super.get_state()
