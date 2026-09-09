extends Node
## M19NodeCollabDouble — TEST-ONLY method-compatible Node collaborator. Preload it
## (AL-001). Exposes the same seams as M19CollabDouble but as a Node, to prove the
## dispatcher rejects a method-compatible externally-freeable Node in any injected
## collaborator slot (V03 F-M19-STRICT-001.B): only agent_parent may be a Node.

func is_bound_to(_a, _b = null) -> bool:
	return true
func is_coherent_with(_a, _b, _c) -> bool:
	return true
func select_and_reserve(_color: int, _owner: int, _access) -> int:
	return -1
func reserve(_t: int, _o: int) -> bool:
	return false
func release(_t: int, _o: int) -> bool:
	return false
func release_for_owner(_o: int) -> bool:
	return false
func get_target_for_owner(_o: int) -> int:
	return -1
func compute_route(_req, _board, _acc):
	return null
func is_segment_traversable(_a: Vector2, _b: Vector2, _i: int) -> bool:
	return true
func is_targetable(_i: int) -> bool:
	return false
