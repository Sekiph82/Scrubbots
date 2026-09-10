extends RefCounted
## M19SelectorReturnDouble — TEST-ONLY selector standing in for TargetSelector in
## the dispatcher's narrow selector seam (F-M19-STRICT-001.E/002.D). Preload it
## (AL-001). It returns a CONFIGURABLE Variant from select_and_reserve and can
## optionally create a side-effect reservation in the REAL dispatcher
## ReservationState, so a test can prove the dispatcher validates the selector
## return type AND proves exact reservation ownership before trusting a target.
##
## is_bound_to reports coherent (true) so the double passes the dispatcher's
## bundle-coherence gate; it is the RETURN CONTRACT under test, not coherence.

var ret = -1               ## verbatim (untyped) value returned by select_and_reserve
var reservations = null    ## the real ReservationState the dispatcher also holds
## Side effect performed before returning:
##   ""            -> none;
##   "owner"       -> reserve (effect_target, owner_id)  [owner maps to effect_target];
##   "other_owner" -> reserve (int(ret), owner_id + 1000) [ret target owned by another].
var effect := ""
var effect_target := -1
var select_calls: int = 0

func is_bound_to(_board, _reservations = null) -> bool:
	return true

func select_and_reserve(_color_id: int, owner_id: int, _access):
	select_calls += 1
	match effect:
		"owner":
			reservations.reserve(effect_target, owner_id)
		"other_owner":
			reservations.reserve(int(ret), owner_id + 1000)
	return ret
