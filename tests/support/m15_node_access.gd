extends Node
## M15NodeAccess — TEST-ONLY method-compatible Node access_query (F-M15-STRICT-004).
## Preload it (AL-001). It exposes is_targetable() but is a Node, not a RefCounted,
## so the selector must reject it on category alone (an externally-freeable
## lifecycle object is not an accepted per-call access dependency).
func is_targetable(_index: int) -> bool:
	return true
