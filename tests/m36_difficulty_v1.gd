extends SceneTree
## M36-C001 V01 — Difficulty V1 evidence.
## Run: godot --headless --path . -s res://tests/m36_difficulty_v1.gd
## Exits 0 on success, 1 on any failure.
##
## Proves:
##   - cadence class/role/modifier are the owner-locked repeating 10-level pattern;
##   - target curve is deterministic and campaign-age monotone within a lane;
##   - level 311 EASY target > level 11 EASY target (and both are EASY relief);
##   - recovery drops present (boss slot -> next relief slot);
##   - Challenge Score is finite and in [0,100] for extreme/NaN inputs;
##   - Challenge, Session Load, Frustration Risk are three separate values;
##   - board size cannot determine class: a compact board can carry VERY_HARD
##     and a large board can carry EASY; workload is sqrt-compressed and weighted
##     10% so dimensions alone cannot dominate D;
##   - M35 catalog is Difficulty-V1 compatible.

const DifficultyProgressionV1 = preload("res://scripts/difficulty/difficulty_progression_v1.gd")
const ChallengeScoreModelV1 = preload("res://scripts/difficulty/challenge_score_model_v1.gd")
const DifficultyV1CatalogCheck = preload("res://scripts/difficulty/difficulty_v1_catalog_check.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")

var _fail := 0

func _initialize() -> void:
	_cadence_pattern()
	_target_curve_regression()
	_recovery_drops()
	_challenge_score_bounds()
	_axis_separation()
	_board_size_cannot_determine_class()
	_catalog_compatibility()
	_done()

func _cadence_pattern() -> void:
	print("[cadence]")
	var p = DifficultyProgressionV1.new()
	_ok(p.is_ok(), "progression config loaded: %s" % p.get_error())
	var expected := ["EASY", "EASY", "MEDIUM", "EASY", "HARD", "EASY", "EASY", "MEDIUM", "EASY", "VERY_HARD"]
	var all_match := true
	for i in range(10):
		if p.class_for(i + 1) != expected[i]:
			all_match = false
			print("  slot %d expected %s got %s" % [i + 1, expected[i], p.class_for(i + 1)])
	_ok(all_match, "cadence classes match owner lock (levels 1..10)")
	# Cadence repeats: level 11 == slot 1 == EASY, level 20 == VERY_HARD.
	_ok(p.class_for(11) == "EASY", "level 11 is EASY (cadence repeats)")
	_ok(p.class_for(20) == "VERY_HARD", "level 20 is VERY_HARD (boss repeats)")
	_ok(p.class_for(311) == "EASY", "level 311 is EASY")
	# Micro modifiers per slot.
	var mods := [0.0, 2.0, 0.0, -1.0, 0.0, -2.0, 1.0, 2.0, -1.0, 0.0]
	var mods_ok := true
	for i in range(10):
		if not is_equal_approx(p.modifier_for(i + 1), mods[i]):
			mods_ok = false
	_ok(mods_ok, "micro modifiers match owner lock")

func _target_curve_regression() -> void:
	print("[target curve]")
	var p = DifficultyProgressionV1.new()
	var levels := [1, 10, 11, 100, 101, 110, 111, 300, 310, 311, 1000, 1001, 1010]
	for n in levels:
		var d := p.describe(n)
		var t: float = d["target_challenge"]
		_ok(t >= 0.0 and t <= 100.0 and is_finite(t), "level %d target finite/in-range (%.2f, %s)" % [n, t, d["class"]])
	# The key owner assertion: campaign-age growth within a lane.
	var t11 := p.target_challenge_for(11)
	var t311 := p.target_challenge_for(311)
	_ok(t311 > t11, "level 311 EASY target (%.2f) > level 11 EASY target (%.2f)" % [t311, t11])
	# Both still EASY relief lanes (class unchanged by age).
	_ok(p.class_for(11) == "EASY" and p.class_for(311) == "EASY", "both 11 and 311 remain EASY")
	# Monotone growth across cycles for a fixed slot (slot 1 EASY: n=1,11,21,...).
	var prev := -1.0
	var monotone := true
	for cyc in range(0, 40):
		var n := cyc * 10 + 1
		var t := p.target_challenge_for(n)
		if t < prev - 0.0001:
			monotone = false
		prev = t
	_ok(monotone, "slot-1 EASY target is non-decreasing with campaign age")

func _recovery_drops() -> void:
	print("[recovery]")
	var p = DifficultyProgressionV1.new()
	# Boss (slot 10 VERY_HARD) is far above the following relief (next cycle slot 1 EASY).
	var boss := p.target_challenge_for(10)
	var relief := p.target_challenge_for(11)
	_ok(boss - relief >= 35.0, "cycle boss->relief drop >= 35 (%.2f -> %.2f)" % [boss, relief])
	# Mini-boss (slot 5 HARD) above the strong recovery (slot 6 EASY).
	var mini := p.target_challenge_for(5)
	var rec := p.target_challenge_for(6)
	_ok(mini - rec >= 20.0, "mini-boss->strong recovery drop >= 20 (%.2f -> %.2f)" % [mini, rec])
	# First tension (slot 3 MEDIUM) above recovery (slot 4 EASY).
	var tension := p.target_challenge_for(3)
	var rec2 := p.target_challenge_for(4)
	_ok(tension - rec2 >= 15.0, "first tension->recovery drop >= 15 (%.2f -> %.2f)" % [tension, rec2])

func _challenge_score_bounds() -> void:
	print("[challenge bounds]")
	var m = ChallengeScoreModelV1.new()
	_ok(m.is_ok(), "score model loaded: %s" % m.get_error())
	# All zeros -> 0. All ones -> 100 (weights sum to 1).
	_ok(is_equal_approx(m.challenge_score({}), 0.0), "empty vector -> 0")
	var ones := {"W": 1, "C": 1, "A": 1, "U": 1, "B": 1, "R": 1, "S": 1}
	_ok(is_equal_approx(m.challenge_score(ones), 100.0), "all-ones vector -> 100")
	# Out-of-range and NaN inputs clamp; output stays finite in [0,100].
	var extreme := {"W": 5.0, "C": -3.0, "A": NAN, "U": INF, "B": 0.5, "R": 2.0, "S": -1.0}
	var d := m.challenge_score(extreme)
	_ok(is_finite(d) and d >= 0.0 and d <= 100.0, "extreme/NaN inputs clamp to finite [0,100] (%.2f)" % d)

func _axis_separation() -> void:
	print("[axis separation]")
	var m = ChallengeScoreModelV1.new()
	# A level with high Session Load but modest Challenge (long/easy).
	var long_easy_challenge := m.challenge_score({"W": 0.9, "C": 0.2, "A": 0.1, "U": 0.1, "B": 0.1, "R": 0.2, "S": 0.1})
	var long_easy_load := m.session_load({"actions": 0.95, "routeTime": 0.9, "decisionCount": 0.4})
	_ok(long_easy_load > long_easy_challenge, "long/easy: session load (%.1f) > challenge (%.1f)" % [long_easy_load, long_easy_challenge])
	# A level with high Challenge but modest Session Load (short/hard).
	var short_hard_challenge := m.challenge_score({"W": 0.2, "C": 0.6, "A": 0.9, "U": 0.9, "B": 0.8, "R": 0.6, "S": 0.7})
	var short_hard_load := m.session_load({"actions": 0.2, "routeTime": 0.2, "decisionCount": 0.3})
	_ok(short_hard_challenge > short_hard_load, "short/hard: challenge (%.1f) > session load (%.1f)" % [short_hard_challenge, short_hard_load])
	# Frustration Risk is its own axis.
	var fr := m.frustration_risk({"retryRisk": 0.8, "sessionOverrun": 0.7, "lateFailure": 0.6, "choiceOpacity": 0.5})
	_ok(is_finite(fr) and fr >= 0.0 and fr <= 100.0, "frustration risk finite/in-range (%.1f)" % fr)

func _board_size_cannot_determine_class() -> void:
	print("[board size vs class]")
	var m = ChallengeScoreModelV1.new()
	# Compact board (24x24 = 576 cells) carrying VERY_HARD-level structural challenge.
	var compact_cells := 24 * 24
	var compact_vec := {
		"W": m.workload_submetric(compact_cells),
		"C": m.color_submetric(11, 0.9),
		"A": 0.95, "U": 0.95, "B": 0.9, "R": 0.8, "S": 0.85,
	}
	var compact_score := m.challenge_score(compact_vec)
	# Large board (48x48 = 2304 cells) carrying EASY structural challenge.
	var large_cells := 48 * 48
	var large_vec := {
		"W": m.workload_submetric(large_cells),
		"C": m.color_submetric(3, 0.2),
		"A": 0.1, "U": 0.1, "B": 0.1, "R": 0.15, "S": 0.1,
	}
	var large_score := m.challenge_score(large_vec)
	_ok(compact_score > large_score, "compact-hard (%.1f) scores HIGHER than large-easy (%.1f)" % [compact_score, large_score])
	# Workload alone is bounded: even the max-cell board contributes at most 10 points.
	var max_w := m.challenge_score({"W": m.workload_submetric(59 * 59)})
	_ok(max_w <= 10.01, "max-cell board contributes <=10 to D via workload (%.2f)" % max_w)
	# Changing ONLY dimensions (cell count) while holding other submetrics keeps
	# the class-defining structural vector intact: the score shifts by <= workload weight.
	var base_vec := {"C": 0.5, "A": 0.5, "U": 0.5, "B": 0.5, "R": 0.5, "S": 0.5}
	var small := base_vec.duplicate(); small["W"] = m.workload_submetric(20 * 20)
	var big := base_vec.duplicate(); big["W"] = m.workload_submetric(59 * 59)
	var delta: float = absf(m.challenge_score(big) - m.challenge_score(small))
	_ok(delta <= 10.01, "dimension-only change shifts D by <=10 (workload cap) (delta=%.2f)" % delta)

func _catalog_compatibility() -> void:
	print("[catalog compat]")
	var cat = LevelCatalog.new()
	var r = cat.load_manifest()
	_ok(r.ok, "catalog loads for compat check")
	var check = DifficultyV1CatalogCheck.new()
	var res: Dictionary = check.validate_catalog(cat)
	_ok(res["ok"], "M35 catalog is Difficulty V1 compatible: %s" % str(res["errors"]))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M36 difficulty V1 evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
