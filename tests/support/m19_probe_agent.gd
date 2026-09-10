extends "res://scripts/gameplay/agents/scrubbot_agent.gd"
## M19ProbeAgent — TEST-ONLY ScrubbotAgent subclass that counts assign() calls via
## an external Array counter (survives the dispatcher freeing the agent), so a test
## can prove the forbidden downstream phase (assign) was NOT entered after a
## reset injected in an earlier boundary (F-M19-STRICT-003.D). Preload it (AL-001).
## Assigns truthfully via super so a non-reset success path still works.

var assign_calls = null ## optional Array [int]
## Fires SYNCHRONOUSLY inside _ready() (which the engine runs during add_child when
## the parent is already in the tree), so a test can inject reset / non-reset drift
## from the add_child lifecycle boundary deterministically (F-M19-STRICT-001.F).
var on_ready: Callable = Callable()

func assign(a_owner_id: int, a_color_id: int, request, route_result, a_speed: float = 6.0) -> bool:
	if assign_calls != null:
		assign_calls[0] += 1
	return super.assign(a_owner_id, a_color_id, request, route_result, a_speed)

func _ready() -> void:
	if on_ready.is_valid():
		on_ready.call()
