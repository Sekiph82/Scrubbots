extends SceneTree
## M27-C001 V01 — generation acceptance / deterministic retry evidence
## (SB-M27-016..018 / master audit §G, §N). Headless, deterministic.
##
## Drives the GenerationGate over a ring-enclosure level and prints the full attempt-by-
## attempt report: base seed, effective attempt seed, attempt index, solver outcome, visited
## states, and the accepted trace hash. Proves: acceptance ONLY on a solver-proven SOLVED
## candidate; at least one candidate rejected before the accepted one; identical inputs
## reproduce the identical accept/reject sequence and accepted attempt; exact per-color
## conservation on every candidate.
##
## Run: godot --headless --path . -s res://tests/m27_generation_retry.gd  (exit 0 on success)

const LevelData = preload("res://scripts/data/level_data.gd")
const SolvabilitySolver = preload("res://scripts/gameplay/solver/solvability_solver.gd")
const GenerationGate = preload("res://scripts/gameplay/solver/generation_gate.gd")

const BASE_SEED := 101
const MAX_ATTEMPTS := 6

var _fail := 0

func _pal(n: int) -> PackedStringArray:
	var p := PackedStringArray()
	for i in range(n):
		p.append("#%02x%02x%02x" % [16 + i, 16 + i, 16 + i])
	return p

func _ring(w: int, h: int, inner: int, gate: int) -> LevelData:
	var cells := PackedInt32Array(); cells.resize(w * h)
	for y in range(h):
		for x in range(w):
			cells[y * w + x] = gate if (x == 0 or y == 0 or x == w - 1 or y == h - 1) else inner
	return LevelData.new(1, "m27genring", "m27genring", "TEST", w, h, _pal(4), cells)

func _initialize() -> void:
	var lvl = _ring(5, 5, 0, 1)
	var gate = GenerationGate.new()
	# Deterministic proof budget: candidates that need more legal decisions than the depth
	# budget are UNPROVABLE within policy (UNKNOWN_BOUND -> rejected); generation retries.
	var cfg := {"max_visited": 50000, "max_depth": 8}
	var rep: Dictionary = gate.generate_accepted(lvl, 3, 3, BASE_SEED, MAX_ATTEMPTS, cfg)

	print("GEN_REPORT base_seed=%d max_attempts=%d" % [BASE_SEED, MAX_ATTEMPTS])
	for a in rep["attempts"]:
		print("  attempt=%d effective_seed=%d outcome=%s visited=%d conservation_ok=%s%s" % [
			int(a["attempt"]), int(a["effective_seed"]), a["outcome"], int(a["visited"]),
			str(a["conservation_ok"]),
			(" trace_hash=%d" % int(a["trace_hash"])) if a.has("trace_hash") else ""])

	_ok(rep["accepted"] != null, "generation accepted a SOLVED candidate")
	if rep["accepted"] == null:
		_done(); return
	var acc: int = int(rep["accepted"]["attempt"])
	print("GEN_ACCEPTED attempt=%d effective_seed=%d visited=%d decisions=%d trace_hash=%d" % [
		acc, int(rep["accepted"]["effective_seed"]), int(rep["accepted"]["visited"]),
		int(rep["accepted"]["decisions"]), int(rep["accepted"]["trace_hash"])])

	_ok(acc >= 1, "acceptance happened only after >=1 earlier rejection (attempt %d)" % acc)
	var rejected_before := 0
	for a in rep["attempts"]:
		if int(a["attempt"]) < acc:
			_ok(a["outcome"] != SolvabilitySolver.SOLVED, "attempt %d before acceptance was NOT SOLVED (%s)" % [int(a["attempt"]), a["outcome"]])
			if a["outcome"] != SolvabilitySolver.SOLVED:
				rejected_before += 1
	_ok(rejected_before >= 1, "at least one candidate was rejected before acceptance (%d rejected)" % rejected_before)

	var all_cons := true
	for a in rep["attempts"]:
		if not a["conservation_ok"]:
			all_cons = false
	_ok(all_cons, "every generated candidate preserved exact per-color conservation")

	# Reproducibility: identical inputs -> identical accept/reject sequence + accepted attempt.
	var rep2: Dictionary = gate.generate_accepted(lvl, 3, 3, BASE_SEED, MAX_ATTEMPTS, cfg)
	_ok(int(rep2["accepted"]["attempt"]) == acc, "identical inputs reproduce the identical accepted attempt")
	_ok(int(rep2["accepted"]["trace_hash"]) == int(rep["accepted"]["trace_hash"]), "identical inputs reproduce the identical accepted trace hash")
	var seq_match: bool = rep2["attempts"].size() == rep["attempts"].size()
	for i in range(min(rep["attempts"].size(), rep2["attempts"].size())):
		if String(rep["attempts"][i]["outcome"]) != String(rep2["attempts"][i]["outcome"]) \
				or int(rep["attempts"][i]["effective_seed"]) != int(rep2["attempts"][i]["effective_seed"]):
			seq_match = false
	_ok(seq_match, "identical inputs reproduce the identical accept/reject sequence")
	_done()

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M27 generation retry: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
