extends "res://scripts/gameplay/dispatch/production_target_access.gd"
## M20 V04 test double — a REAL ProductionTargetAccess subclass (so M19 dispatch
## uses genuine reachability truth) that fires a one-shot hook from inside the M19
## dispatch path (set_origin), late enough that M19 would otherwise complete a
## successful dispatch. Used to inject `loop.reset()` (or a renderer queue_free)
## as an M19-callback adversary for the F-M20-STRICT-002.K post-dispatch bracket.
## The hook fires exactly once so a re-driven dispatch is not re-hooked.
var hook: Callable = Callable()
var _fired: bool = false
## One-shot hook fired from inside the M19 bind-time coherence callback
## (is_coherent_with), to inject e.g. an explicit-parent queue_free/free during a
## dispatcher bind (M20-C001 V08 §4). Dispatcher revalidates the explicit parent
## AFTER the coherence callbacks, so a parent killed here must fail the bind.
var coherence_hook: Callable = Callable()
var _coh_fired: bool = false

func set_origin(origin: Vector2) -> void:
	if hook.is_valid() and not _fired:
		_fired = true
		hook.call()
	super.set_origin(origin)

func is_coherent_with(board, routing_system, routing_access) -> bool:
	if coherence_hook.is_valid() and not _coh_fired:
		_coh_fired = true
		coherence_hook.call()
	return super.is_coherent_with(board, routing_system, routing_access)
