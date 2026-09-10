extends "res://scripts/gameplay/agents/scrubbot_agent.gd"
## M19NonBoolAssignAgent — TEST-ONLY ScrubbotAgent subclass whose assign() returns
## a NON-bool value via an untyped override, to prove the dispatcher requires an
## actual TYPE_BOOL true and fails closed otherwise (F-M19-STRICT-002.E). Preload
## it (AL-001). If GDScript forbids the untyped override at parse time, that is
## itself the recorded runtime evidence that a non-bool return cannot occur.

func assign(_a_owner_id, _a_color_id, _request, _route_result, _a_speed = 6.0):
	return 5 # non-bool int; never a legitimate assign success
