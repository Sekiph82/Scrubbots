extends "res://tests/support/access_query_double.gd"
## M19CacheSelectAccess — TEST-ONLY select_access double that also exposes the
## optional set_origin / consume_route seam. Preload it (AL-001). Inherits
## is_targetable / is_coherent_with (coherent flag) from AccessQueryDouble, so it
## is a valid dispatcher select_access.
##
## It lets a test:
##   - return a configured cached route from consume_route (null, or a
##     valid/invalid RouteResult / junk) to prove the missing-vs-invalid cache
##     distinction (V03 F-M19-STRICT-002.A);
##   - count fresh consume calls;
##   - inject reset from set_origin / consume_route to prove the generation check
##     immediately after those boundaries (V03 F-M19-STRICT-003.B).

var cached_route = null
var consume_calls: int = 0
var set_origin_calls: int = 0
var on_set_origin: Callable = Callable()
var on_consume: Callable = Callable()

func set_origin(_origin: Vector2) -> void:
	set_origin_calls += 1
	if on_set_origin.is_valid():
		on_set_origin.call()

func consume_route(_index: int):
	consume_calls += 1
	if on_consume.is_valid():
		on_consume.call()
	return cached_route
