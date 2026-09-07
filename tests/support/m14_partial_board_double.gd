extends RefCounted
## M14PartialBoardDouble — adversarial M14 test double. Preload it (AL-001);
## never referenced by production.
##
## RefCounted (correct lifecycle category) but exposes only PART of the narrow
## M14 board API: get_cell_count() is present, is_valid_index() and
## get_cell_state() are deliberately omitted. The ReservationState dependency
## gate must reject it on the missing methods (AL-040) — proving non-null +
## correct category is still not enough, and that a partial dependency can never
## reach reserve() to fault on a missing is_valid_index/get_cell_state.
func get_cell_count() -> int:
	return 4
# Intentionally missing: is_valid_index, get_cell_state.
