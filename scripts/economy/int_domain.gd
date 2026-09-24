extends RefCounted
## IntDomain — preload (res://scripts/economy/int_domain.gd).
##
## Shared exact-integer validation for economy save/import state (F-M39-006).
## JSON delivers whole numbers as int or integral float; economy integer state
## (balances, counts, timestamps, ids) must accept those but REJECT a fractional
## float (1.9), NaN, INF or a non-numeric value rather than silently truncating.

## Returns the exact integer value of `v`, or null if `v` is not an exact
## integer (non-numeric, fractional float, NaN or INF).
static func exact_int(v):
	if typeof(v) == TYPE_INT:
		return v
	if typeof(v) == TYPE_FLOAT:
		if is_nan(v) or is_inf(v) or floor(v) != v:
			return null
		return int(v)
	return null

## exact_int that additionally requires value >= 0. Returns null otherwise.
static func nonneg_int(v):
	var i = exact_int(v)
	if i == null or i < 0:
		return null
	return i
