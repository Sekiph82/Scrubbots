extends "res://scripts/gameplay/supply/batch_supply_engine.gd"
## M24 V02 adversarial M23 test double. A real BatchSupplyEngine subclass (so it passes
## the `is BatchSupplyEngine` gate) that can synchronously re-enter the FiveSlotBatchEngine
## from either the begin OR the commit boundary, and can force commit failure. Test-only.
##
## mode:
##   "begin"  — fire nested M24 mutations from begin_front_selection(), then return a real tx
##   "commit" — fire nested M24 mutations from commit(tx), then perform the real commit
##   "fail"   — return a real tx from begin, but make commit(tx) fail deterministically
##
## Initialized as a valid 3-column engine; the test then loads real columns via the
## inherited load_columns().

var m24                       # FiveSlotBatchEngine under test
var mode: String = ""
var results: Dictionary = {}  # nested-call outcomes captured during the callback
var _fired := false

func _init() -> void:
	_column_count = 3
	_preview_depth = 3
	_columns = [[], [], []]
	_initial = _snapshot_initial(_columns)
	_initial_seed = _seed
	_initial_palette_size = _palette_size

func _attack() -> void:
	# Every nested mutation must fail closed while the outer placement holds _busy.
	results["reset"] = m24.reset()
	results["nested_select"] = m24.select_front_batch(self, 0)
	results["commit_work"] = m24.commit_work(0, "NESTED_W")
	results["set_claim"] = m24.set_claimable_work_available(0, false)

func begin_front_selection(column):
	var tx = super.begin_front_selection(column)
	if mode == "begin" and not _fired:
		_fired = true
		_attack()
	return tx

func commit(tx) -> bool:
	if mode == "fail":
		return false
	if mode == "commit" and not _fired:
		_fired = true
		_attack()
	return super.commit(tx)
