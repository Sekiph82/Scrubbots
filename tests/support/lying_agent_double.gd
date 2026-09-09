extends "res://scripts/gameplay/agents/scrubbot_agent.gd"
## LyingAgentDouble — TEST-ONLY ScrubbotAgent subclass whose assign() returns true
## without truly/correctly assigning. Preload it (AL-001). Proves the dispatcher
## validates assign() postconditions instead of trusting a true return
## (V03 F-M19-STRICT-002.C).
##
## lie_mode:
##   "unassigned"  -> return true but stay UNASSIGNED (no identity, not MOVING);
##   "wrong_owner" -> assign truthfully, then corrupt owner_id;
##   "wrong_color" -> assign truthfully, then corrupt color_id;
##   "wrong_target"-> assign truthfully, then corrupt target_index;
##   "parented"    -> assign truthfully, then parent self under stash_parent.

var lie_mode: String = "unassigned"
var stash_parent: Node = null

func assign(a_owner_id: int, a_color_id: int, request, route_result, a_speed: float = 6.0) -> bool:
	if lie_mode == "unassigned":
		return true
	var ok: bool = super.assign(a_owner_id, a_color_id, request, route_result, a_speed)
	match lie_mode:
		"wrong_owner":
			owner_id += 1000
		"wrong_color":
			color_id += 1000
		"wrong_target":
			target_index += 1000
		"parented":
			if stash_parent != null:
				stash_parent.add_child(self)
	return ok
