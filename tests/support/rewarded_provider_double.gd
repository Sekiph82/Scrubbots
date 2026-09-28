extends "res://scripts/economy/rewarded_ad_provider.gd"
## Test double for the provider-neutral rewarded seam (M43-C003 tests only).
## `available` gates every placement (or `per_placement` overrides); requests are recorded
## and a test delivers each provider outcome explicitly with deliver_last()/deliver().

var available := true
var per_placement: Dictionary = {}
var requests: Array = []   ## [placement, token, deliver]

func is_available(placement: String) -> bool:
	return bool(per_placement.get(placement, available))

func request(placement: String, token: String, deliver: Callable) -> bool:
	if not is_available(placement):
		return false
	requests.append([placement, token, deliver])
	return true

func last_token() -> String:
	return String(requests.back()[1]) if not requests.is_empty() else ""

func deliver_last(result: Dictionary) -> Dictionary:
	var r: Array = requests.back()
	return (r[2] as Callable).call(r[1], result)

func deliver(token: String, result: Dictionary) -> Dictionary:
	for r in requests:
		if r[1] == token:
			return (r[2] as Callable).call(token, result)
	return {}
