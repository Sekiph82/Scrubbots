extends "res://scripts/gameplay/agents/scrubbot_agent.gd"
## DispatchAgentDouble — M19 TEST-ONLY ScrubbotAgent subclass. Preload it (AL-001).
##
## A fresh instance is a valid, UNASSIGNED, unparented ScrubbotAgent subclass, so
## the dispatcher WILL own it (proving subclasses are accepted). It lets a test:
##   - force an ordinary assign() failure on an otherwise-ownable agent
##     (fail_assign) to exercise the assign-failure rollback (release + free, no
##     orphan) without needing a route mismatch;
##   - inject a side effect at the start of assign() (on_assign), e.g. call
##     dispatcher.reset(), to prove reset-during-assign rollback
##     (F-M19-STRICT-003).
## It adds no other behavior; movement/cancel/completion are the real M18 agent.

var fail_assign: bool = false
var on_assign: Callable = Callable()

func assign(a_owner_id: int, a_color_id: int, request, route_result, a_speed: float = 6.0) -> bool:
	if on_assign.is_valid():
		on_assign.call()
	if fail_assign:
		return false
	return super.assign(a_owner_id, a_color_id, request, route_result, a_speed)
