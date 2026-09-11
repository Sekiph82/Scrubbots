extends "res://scripts/gameplay/dispatch/production_target_access.gd"
## M20 V04 test double — a REAL ProductionTargetAccess subclass (so M19 dispatch
## uses genuine reachability truth) that fires a one-shot hook from inside the M19
## dispatch path (set_origin), late enough that M19 would otherwise complete a
## successful dispatch. Used to inject `loop.reset()` (or a renderer queue_free)
## as an M19-callback adversary for the F-M20-STRICT-002.K post-dispatch bracket.
## The hook fires exactly once so a re-driven dispatch is not re-hooked.
var hook: Callable = Callable()
var _fired: bool = false

func set_origin(origin: Vector2) -> void:
	if hook.is_valid() and not _fired:
		_fired = true
		hook.call()
	super.set_origin(origin)
