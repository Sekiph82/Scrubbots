extends RefCounted
## M25 adversarial access double: an access_query (is_targetable) that, the first time
## the selector probes it during an outer claim, synchronously re-enters the claim engine
## to prove the M25 re-entrancy guard fails the nested claim closed. It then reports
## targetable=true so the OUTER claim still proceeds normally. Test-only.

var engine
var color := 0
var access_map: Dictionary = {}
var nested_result: Dictionary = {}
var _fired := false

func is_targetable(_index: int) -> bool:
	if not _fired:
		_fired = true
		nested_result = engine.claim_for_color(color, access_map)
	return true
