extends RefCounted
## CandidateIndexDouble — M15 test double standing in for ColorCandidateIndex,
## so tests can inject RAW candidate lists the real index would never produce
## (stale wrong-color / CLEARED / invalid indices) and prove TargetSelector's
## narrow BoardState final-validation filters them (AL-028 defence-in-depth).
## Preload it (AL-001).
##
## It is read-only from the selector's side: get_candidates() returns a detached
## copy, mirroring ColorCandidateIndex's contract, so a passing test also shows
## the selector never mutates candidate truth.

## color_id (int) -> Array[int] raw candidate indices in the order to return.
var by_color: Dictionary = {}

func set_candidates(color_id: int, indices: Array) -> void:
	by_color[color_id] = indices.duplicate()

func get_candidates(color_id: int, excluded = []) -> Array:
	var base: Array = by_color.get(color_id, [])
	if excluded == null or excluded.is_empty():
		return base.duplicate()
	var exc: Dictionary = {}
	for e in excluded:
		exc[e] = true
	var out: Array = []
	for i in base:
		if not exc.has(i):
			out.append(i)
	return out
