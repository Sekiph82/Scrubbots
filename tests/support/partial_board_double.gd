extends RefCounted
## PartialBoardDouble — M16 adversarial test double. Preload it (AL-001).
##
## Exposes only SOME of the narrow M16 BoardState method surface (get_width /
## get_height) and deliberately omits the rest (is_valid_index / get_cell_state /
## get_cell_position). The validator must fail closed BEFORE calling a missing
## method (AL-040: non-null is not enough at a duck-typed dependency boundary).

func get_width() -> int:
	return 5

func get_height() -> int:
	return 5
# Intentionally missing: is_valid_index, get_cell_state, get_cell_position.
