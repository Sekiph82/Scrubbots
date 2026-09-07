extends Node
## M13BoardNodeDouble — adversarial test double. Preload/instantiate in tests
## only; never referenced by production. Exposes the FULL narrow M13 board API
## with canonical returns, but is a NODE (not RefCounted). The M13 dependency
## boundary must reject it on lifecycle category alone (RefCounted-only, V04 §2),
## so no externally-freed Node dependency can enter M13 — proving the boundary
## does not trust a method-shape match.

const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

func get_cell_count() -> int:
	return 4

func is_valid_index(index: int) -> bool:
	return index >= 0 and index < 4

func get_cell_state(_index: int) -> int:
	return BoardState.CellState.ACTIVE

func get_color_id(_index: int) -> int:
	return 0
