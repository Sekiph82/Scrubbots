extends "res://scripts/gameplay/slots/five_slot_batch_engine.gd"
## M25 adversarial double: a real FiveSlotBatchEngine subclass (passes the `is
## FiveSlotBatchEngine` bind gate) whose commit_work() always fails, to drive the M25
## "M24 commit fails after reservation -> release reservation, publish no claim" path.
## Test-only.

func commit_work(_slot_index, _work_id) -> bool:
	return false
