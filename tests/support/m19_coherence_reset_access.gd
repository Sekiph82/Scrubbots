extends "res://tests/support/m19_cache_select_access.gd"
## M19CoherenceResetAccess — TEST-ONLY select_access that injects a dispatcher
## reset() from a chosen post-boundary bundle-coherence callback (F-M19-STRICT-003.D).
## Preload it (AL-001). It inherits is_targetable / set_origin / consume_route /
## cached-route behaviour from M19CacheSelectAccess and overrides is_coherent_with
## to count invocations and fire reset() at a chosen ordinal WITHIN one dispatch.
##
## is_coherent_with call ordinals during ONE dispatch (real selector, reachable
## target): 1 initial, 2 post-selection, 3 post-owner-proof#1, 4 post-owner-proof#2,
## 5 post-routing, 6 post-factory, 7 post-assign, 8 post-add-child.

var dispatcher = null
var reset_at_call: int = -1
var coherence_calls: int = 0

func is_coherent_with(_a, _b, _c):
	coherence_calls += 1
	if coherence_calls == reset_at_call and dispatcher != null:
		dispatcher.reset()
	return coherent
