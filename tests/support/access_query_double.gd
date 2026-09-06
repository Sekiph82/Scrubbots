extends RefCounted
## AccessQueryDouble — M15 test double for the injected reachability/access
## truth TargetSelector consumes. Preload it (AL-001).
##
## It lets a test:
##   - mark specific target indices targetable or unreachable;
##   - directly observe WHICH indices the selector queried and how often
##     (AL-018 direct observability — not a proxy assertion like "reservation
##     count changed").
##   - optionally run a side effect during a query, to simulate a competing
##     synchronous assignment grabbing a target between the targetable-check and
##     the selector's reserve() attempt (prompt scenario #29).

## index (int) -> bool targetable. Absent indices use `default_targetable`.
var _targetable: Dictionary = {}
## Value returned for indices not explicitly set. Defaults false so the double
## is fail-closed unless a test opts a target in.
var default_targetable: bool = false
## Ordered list of every index passed to is_targetable(), in call order.
var query_log: Array = []
## index (int) -> number of times queried.
var query_counts: Dictionary = {}
## Optional side effect invoked with the queried index before the verdict is
## returned. Used to simulate a race (e.g. reserve the target for another owner).
var on_query: Callable = Callable()

func set_targetable(index: int, ok: bool) -> void:
	_targetable[index] = ok

## Mark every index in the array targetable (others keep default).
func set_all_targetable(indices) -> void:
	for i in indices:
		_targetable[i] = true

func is_targetable(index: int) -> bool:
	query_log.append(index)
	query_counts[index] = int(query_counts.get(index, 0)) + 1
	if on_query.is_valid():
		on_query.call(index)
	return bool(_targetable.get(index, default_targetable))

func was_queried(index: int) -> bool:
	return query_counts.has(index)

func query_count(index: int) -> int:
	return int(query_counts.get(index, 0))

func total_queries() -> int:
	return query_log.size()

func reset_observations() -> void:
	query_log.clear()
	query_counts.clear()
