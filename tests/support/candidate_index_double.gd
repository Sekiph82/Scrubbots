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
## Board this double claims coherence with (strict-v2 F-M15-STRICT-002). The
## double mirrors ColorCandidateIndex's is_bound_to() identity seam so it can pass
## TargetSelector.bind()'s coherence gate.
var _board = null

## When non-null, get_candidates returns this verbatim (used to inject a
## malformed non-Array candidate container for the strict-v2 boundary tests).
var candidates_force = null

func set_candidates(color_id: int, indices: Array) -> void:
	by_color[color_id] = indices.duplicate()

func bind(board) -> void:
	_board = board

## Exact-identity coherence check, mirroring ColorCandidateIndex.is_bound_to().
func is_bound_to(board) -> bool:
	return _board != null and _board == board

func get_candidates(color_id: int, excluded = []):
	if candidates_force != null:
		return candidates_force
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
