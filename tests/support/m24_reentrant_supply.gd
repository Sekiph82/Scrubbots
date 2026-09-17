extends "res://scripts/gameplay/supply/batch_supply_engine.gd"
## M24 adversarial test double: a real BatchSupplyEngine subclass whose
## begin_front_selection() synchronously re-enters the FiveSlotBatchEngine's
## select_front_batch() to prove the engine's re-entrancy guard fails the nested call
## closed (no split-brain slot/queue state). Test-only.

var engine                      # the FiveSlotBatchEngine under test
var nested_result: Dictionary = {}
var _entered := false

func begin_front_selection(column):
	if not _entered:
		_entered = true
		nested_result = engine.select_front_batch(self, column)
	return null
