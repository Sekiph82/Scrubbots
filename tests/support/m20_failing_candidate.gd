extends "res://scripts/gameplay/targeting/color_candidate_index.gd"
## M20 test double — a REAL ColorCandidateIndex (subclass, so `is
## ColorCandidateIndex` and is_bound_to() stay genuine) whose sync_cell() can be
## made to fail a set number of times to exercise the M20 clearing-loop candidate
## rollback path (M20-C001 §6). It returns false WITHOUT neutralizing, so the
## loop's rollback restore can succeed on the retry.
var fail_syncs: int = 0

func sync_cell(index: int) -> bool:
	if fail_syncs > 0:
		fail_syncs -= 1
		return false
	return super.sync_cell(index)
