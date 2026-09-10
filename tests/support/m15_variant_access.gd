extends RefCounted
## M15VariantAccess — TEST-ONLY access_query double whose is_targetable() returns
## a configurable Variant (F-M15-STRICT-004). Preload it (AL-001). Lets a test
## prove the selector accepts a candidate ONLY on an actual bool true and fails
## closed (never treats truthy non-bool as reachable) for every other type.
var verdict = null  ## returned verbatim by is_targetable
var on_query: Callable = Callable()  ## side effect run before the verdict returns
func is_targetable(index: int):
	if on_query.is_valid():
		on_query.call(index)
	return verdict
