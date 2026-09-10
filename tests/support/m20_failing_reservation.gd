extends "res://scripts/gameplay/targeting/reservation_state.gd"
## M20 test double — a REAL ReservationState (subclass, so `is ReservationState`
## and is_bound_to() stay genuine) whose resolve_arrival() can be made to fail a
## set number of times to exercise the M20 clearing-loop reservation rollback
## path (M20-C001 §6). On a forced failure it does NOT call super, so the
## reservation is left exactly as it was (still held).
var fail_resolves: int = 0

func resolve_arrival(target_index: int, owner_id: int) -> bool:
	if fail_resolves > 0:
		fail_resolves -= 1
		return false
	return super.resolve_arrival(target_index, owner_id)
