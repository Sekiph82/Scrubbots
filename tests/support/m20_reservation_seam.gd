extends "res://scripts/gameplay/targeting/reservation_state.gd"
## M20 V02 test double — a REAL ReservationState subclass (so `is
## ReservationState` and is_bound_to() stay genuine) exposing adversarial callback
## seams for the mutation-sensitive rollback matrix (F-M20-STRICT-004/009):
##   - mode "mutate_false": remove the exact owner<->target pair via the canonical
##                          resolve, then return false.
##   - mode "true_noop":    return true WITHOUT removing the pair (lying success).
##   - mode "normal":       delegate to the real implementation.
## `resolve_hook` fires once at the top of resolve_arrival (inject reset, etc.).
var mode: String = "normal"
var resolve_hook: Callable = Callable()
var _resolve_hook_fired: bool = false
## For mode "identity_swap" (V03 §3 reservation identity-swap mutate-false):
## after the real current resolve, drop an UNRELATED pair and re-reserve its owner
## on another valid target, then return false — a collateral corruption that a
## count-only rollback verify would miss but an exact owner-map verify catches.
var swap_from_owner: int = -1
var swap_from_target: int = -1
var swap_to_target: int = -1

func resolve_arrival(target_index: int, owner_id: int) -> bool:
	if resolve_hook.is_valid() and not _resolve_hook_fired:
		_resolve_hook_fired = true
		resolve_hook.call(target_index, owner_id)
	match mode:
		"mutate_false":
			super.resolve_arrival(target_index, owner_id) # real removal
			return false
		"identity_swap":
			super.resolve_arrival(target_index, owner_id) # real current resolve
			release(swap_from_target, swap_from_owner)    # drop unrelated U
			reserve(swap_to_target, swap_from_owner)      # re-own ownerU on V
			return false
		"true_noop":
			return true # lie: claims success without removing the pair
		_:
			return super.resolve_arrival(target_index, owner_id)
