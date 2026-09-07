extends RefCounted
## M17-C002 V03 test double — an access object of the CORRECT SHAPE (all four
## seam methods exist) but with WRONG RETURN TYPES. ProductionRoutingSystem must
## reject it (fail closed), proving method existence alone is not trusted
## (F-M17-STRICT-004). Preload it (AL-001).

func is_segment_traversable(_a, _b, _i):
	return "not-a-bool"

func classify_cell(_cx, _cy, _i):
	return "not-an-int"

func cell_of_point(_p):
	return 42 # not a Vector2i

func is_bound_to(_b) -> bool:
	return true
