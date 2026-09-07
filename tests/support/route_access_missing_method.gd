extends RefCounted
## M17-C002 V03 test double — a PARTIAL access object missing one required seam
## method (cell_of_point). ProductionRoutingSystem must reject it (fail closed),
## proving the COMPLETE seam is required (F-M17-STRICT-004). Preload it (AL-001).

func is_segment_traversable(_a, _b, _i) -> bool:
	return true

func classify_cell(_cx, _cy, _i) -> int:
	return 0

func is_bound_to(_b) -> bool:
	return true
