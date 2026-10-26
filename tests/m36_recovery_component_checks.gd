extends SceneTree
## SB-M36-014 — recovery component checks on actual vectors.
## Run: godot --headless --path . -s res://tests/m36_recovery_component_checks.gd
## Exits 0 on success, 1 on any failure.
##
## Proves on synthetic fixtures (peak = level 3, recovery = level 4) each rule of
## DifficultyPlaytest.recovery_component_checks: A <= peak, B <= peak (boundaries inclusive),
## not above on both B and U (strict), Session Load strictly below the peak, the shipped L8->L9
## shape fails, and the result is independent of level order. Then checks that the committed
## playtest_v2.json and playtest_v2_progression_v2.json carry recovery.componentChecks for
## 3->4, 5->6 and 8->9 equal to a recomputation from each file's own levels.

const Playtest = preload("res://tools/difficulty_playtest.gd")

const FILES := [
	"res://coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2.json",
	"res://coordination/sessions/FACTORY/046-difficulty-model-v2/playtest_v2_progression_v2.json",
]
const FLAGS := ["aNotAbovePeak", "bNotAbovePeak", "notAboveOnBothBAndU", "sessionLoadBelowPeak", "pass"]
const NUMS := ["fromLevel", "toLevel", "peakA", "recoveryA", "peakB", "recoveryB", "peakU", "recoveryU",
	"peakSessionLoad", "recoverySessionLoad"]

var _cases := 0
var _fail := 0

func _initialize() -> void:
	_s01_rules()
	_s02_files()
	print("M36_RECOVERY_COMPONENT_CHECKS %s (%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _cases, _fail])
	quit(0 if _fail == 0 else 1)

func _s01_rules() -> void:
	print("[s01 synthetic rules]")
	var c := _check({})
	_ok(c["pass"] and c["aNotAbovePeak"] and c["bNotAbovePeak"] and c["notAboveOnBothBAndU"] and c["sessionLoadBelowPeak"], "clearly lower: all pass")
	_ok(c["fromLevel"] == 3 and c["toLevel"] == 4 and c["peakA"] == 0.6 and c["recoveryA"] == 0.3, "keyed 3->4 with values")
	# A boundary
	c = _check({"A": 0.6})
	_ok(c["aNotAbovePeak"] and c["pass"], "A equal passes")
	c = _check({"A": 0.601})
	_ok(not c["aNotAbovePeak"] and not c["pass"] and c["bNotAbovePeak"] and c["notAboveOnBothBAndU"] and c["sessionLoadBelowPeak"], "A +0.001 fails A only")
	# B boundary (U lower so the B/U rule does not mask it)
	c = _check({"B": 0.6})
	_ok(c["bNotAbovePeak"] and c["pass"], "B equal passes")
	c = _check({"B": 0.601})
	_ok(not c["bNotAbovePeak"] and not c["pass"] and c["aNotAbovePeak"] and c["notAboveOnBothBAndU"] and c["sessionLoadBelowPeak"], "B +0.001 fails B only")
	# B/U rule
	_ok(not _check({"B": 0.7, "U": 0.7})["notAboveOnBothBAndU"], "B above and U above -> false")
	_ok(_check({"B": 0.7, "U": 0.6})["notAboveOnBothBAndU"], "B above, U equal -> true")
	_ok(_check({"B": 0.6, "U": 0.7})["notAboveOnBothBAndU"], "B equal, U above -> true")
	_ok(_check({"B": 0.6, "U": 0.6})["notAboveOnBothBAndU"], "B equal, U equal -> true")
	c = _check({"B": 0.7, "U": 0.3})
	_ok(c["notAboveOnBothBAndU"] and not c["bNotAbovePeak"], "B above, U below -> true (B caught by bNotAbovePeak)")
	# Session Load (strict)
	_ok(_check({"SL": 0.59})["sessionLoadBelowPeak"], "Session Load below passes")
	c = _check({"SL": 0.6})
	_ok(not c["sessionLoadBelowPeak"] and not c["pass"], "Session Load equal fails")
	_ok(not _check({"SL": 0.7})["sessionLoadBelowPeak"], "Session Load above fails")
	# Shipped L8->L9 shape: recovery above on A and B
	c = _check({"A": 0.7, "B": 0.7})
	_ok(not c["pass"] and not c["aNotAbovePeak"] and not c["bNotAbovePeak"], "above on A and B fails")
	# Order independence
	var levels := _levels({"A": 0.7})
	var shuffled := levels.duplicate()
	shuffled.reverse()
	var pairs := [{"fromLevel": 3, "toLevel": 4}]
	_ok(Playtest.recovery_component_checks(levels, pairs) == Playtest.recovery_component_checks(shuffled, pairs), "shuffled levels give same result")

func _s02_files() -> void:
	print("[s02 committed playtest files]")
	for path in FILES:
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary:
			_ok(false, "%s parses" % path)
			continue
		var got: Array = data["recovery"].get("componentChecks", [])
		var want := Playtest.recovery_component_checks(data["levels"], data["recovery"]["guards"])
		_ok(got.size() == 3, "%s has 3 componentChecks" % path.get_file())
		var pairs: Array = []
		for c in got:
			pairs.append("%d->%d" % [int(c["fromLevel"]), int(c["toLevel"])])
		_ok(pairs == ["3->4", "5->6", "8->9"], "%s pairs %s" % [path.get_file(), str(pairs)])
		for i in mini(got.size(), want.size()):
			var same := true
			for k in NUMS:
				same = same and float(got[i][k]) == float(want[i][k])
			for k in FLAGS:
				same = same and got[i].has(k) and bool(got[i][k]) == bool(want[i][k])
			_ok(same, "%s %s equals recomputation (pass=%s)" % [path.get_file(), pairs[i], str(got[i].get("pass"))])

## Peak level 3 fixed at 0.6 everywhere; recovery level 4 at 0.3 unless overridden.
func _levels(rec: Dictionary) -> Array:
	return [
		{"order": 1, "vector": {"A": 0.1, "B": 0.1, "U": 0.1}, "sessionLoad": 0.1},
		{"order": 3, "vector": {"A": 0.6, "B": 0.6, "U": 0.6}, "sessionLoad": 0.6},
		{"order": 4, "vector": {"A": rec.get("A", 0.3), "B": rec.get("B", 0.3), "U": rec.get("U", 0.3)}, "sessionLoad": rec.get("SL", 0.3)},
	]

func _check(rec: Dictionary) -> Dictionary:
	return Playtest.recovery_component_checks(_levels(rec), [{"fromLevel": 3, "toLevel": 4}])[0]

func _ok(cond: bool, msg: String) -> void:
	_cases += 1
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
