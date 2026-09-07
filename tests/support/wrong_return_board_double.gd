extends RefCounted
## WrongReturnBoardDouble — M16 adversarial test double. Preload it (AL-001).
##
## Exposes the FULL M16 BoardState method surface (get_width / get_height /
## is_valid_index / get_cell_state / get_cell_position) but returns wrong-typed
## values. It is NOT a BoardState, so exact `x is BoardState` identity at the M16
## board boundary rejects it BEFORE any method is called — proving the boundary
## does not trust a method-shape match and cannot be poisoned by bad return types
## (F-M16-STRICT-006). If a method were ever reached, its wrong return would fault;
## the tests prove it is never reached.

func get_width():
	return "wide"

func get_height():
	return Vector2.ZERO

func is_valid_index(_index):
	return "yes"

func get_cell_state(_index):
	return 3.14

func get_cell_position(_index):
	return "nope"
