extends SceneTree
## M55-C001 — long-run / lifecycle chaos QA through the REAL app root
## (scenes/app/main.tscn -> NavigationController -> Home -> ProductionGameplayHost ->
## Results -> AppState economy/progression/save).
## Rows: SB-M55-008 repeated scene transitions, 009 long high-load session,
## 010 memory growth, 011 duplicate signals, 012 orphan Nodes, 013 duplicate rewards.
## Bounded pass rules are fixed up front (see constants) — never "looks stable".
## M43-C005F-PHASE4-QA-R01 warm-up model: the FIRST real Levels 1..10 lap materializes
## first-use presentation state (lazily created popup / ceremony / plugin structures, first-load
## content). Lap 1 still runs every gameplay / reward / idempotency / host / orphan / listener
## check and RECORDS its Node / Object / static-memory first-use delta (with the tree branch the
## new Nodes live in) as warm-up evidence. The strict leak rule is steady_state_violations():
## the same workload again (lap 2) against the lap-1 end must keep the Node count exactly,
## never grow orphans and stay inside MAX_OBJECT_DRIFT / MAX_STATIC_MEM_DRIFT; case 014 proves
## that rule fails on each kind of post-warm-up growth. Lap-end HOME samples are taken at feel
## quiescence (FeedbackAdapter owns no live, ceiling-bounded decoration), so a burst still in
## flight is never counted as a Node.
##
## Run: godot --headless --path . -s res://tests/m55_long_session.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const BoardState = preload("res://scripts/gameplay/board/board_state.gd")

const TRANSITION_CYCLES := 40
const WARMUP_CYCLES := 5
## Bounded rules (post-warm-up): tree Node count must return EXACTLY to baseline;
## orphan Nodes must not grow at all; Object count may drift by at most this many
## (engine-internal caches), and static memory by at most this many bytes.
const MAX_OBJECT_DRIFT := 64
const MAX_STATIC_MEM_DRIFT := 4 * 1024 * 1024
const LEVELS := 10
const DT := 1.0

var _fail := 0
var _tmp: Array = []
var _completed := {}
var _routes: Array = []
const EXPECTED_CASES := ["008_transitions", "009_long_session", "010_memory", "011_signals", "012_orphans", "013_rewards", "014_steady_state_sensitivity"]

func _initialize() -> void:
	await process_frame
	var root = await _boot()
	var base := await _transitions(root)
	# Lap 1: first play of all ten levels (first-load content caching happens here).
	var lap1: Dictionary = await _long_session(root, base, 1)
	root.free()
	await process_frame
	# Lap 2 (M55-C001 steady-state leak check): a fresh profile replays the SAME ten
	# levels in the same process, so every per-attempt leak shows up as growth over the
	# end of lap 1 while one-time content caches do not.
	var root2 = await _boot()
	var lap2: Dictionary = await _long_session(root2, lap1, 2)
	root2.free()
	MainScript.boot_save_path_override = ""
	print("    lap-1 end: %s" % str(lap1))
	print("    lap-2 end: %s" % str(lap2))
	print("    STEADY lap2-vs-lap1: nodes %+d, orphans %+d, objects %+d, static_mem %+d B" % [lap2["nodes"] - lap1["nodes"],
		lap2["orphans"] - lap1["orphans"], lap2["objects"] - lap1["objects"], lap2["static_mem"] - lap1["static_mem"]])
	_ok(lap2["nodes"] == lap1["nodes"] and lap2["orphans"] <= lap1["orphans"], "steady state: lap-2 Home Node/orphan counts == lap 1 (%d/%d)" % [lap2["nodes"], lap2["orphans"]])
	_ok(abs(lap2["objects"] - lap1["objects"]) <= MAX_OBJECT_DRIFT, "steady state: lap-2 Object count within %d of lap 1 (%d)" % [MAX_OBJECT_DRIFT, lap2["objects"] - lap1["objects"]])
	_ok(lap2["static_mem"] - lap1["static_mem"] <= MAX_STATIC_MEM_DRIFT, "steady state: lap-2 static memory within %d B of lap 1 (%d B)" % [MAX_STATIC_MEM_DRIFT, lap2["static_mem"] - lap1["static_mem"]])
	_completed["010_memory"] = true
	_sensitivity(lap1)
	_cleanup()
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	_ok(missing.is_empty(), "case ledger: every expected case completed %s" % str(missing))
	print("M55 LONG SESSION: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

# ------------------------------------------------------------------ probes -------

func _sample(root) -> Dictionary:
	var app = root.get_app_state()
	return {
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"static_mem": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"hosts": root.find_children("GameplayHost", "", true, false).size(),
		"root_children": root.get_child_count(),
		# Long-lived authority listeners: a host that leaked would leave its binding here.
		"effects_listeners": app.effects.changed.get_connections().size(),
		"route_listeners": root.get_navigation().route_changed.get_connections().size(),
		"settings_listeners": root.get_navigation().settings_changed.get_connections().size(),
		"tree": _branches(),   # evidence only: Nodes per /root child (autoloads, app root)
	}

## Node count per direct /root child (the app root keyed "AppRoot": its generated name differs
## between boots). Evidence for where warm-up Nodes live; never a pass rule by itself.
func _branches() -> Dictionary:
	var out := {}
	for c in get_root().get_children():
		var k: String = "AppRoot" if c.get_script() == MainScript else String(c.name)
		out[k] = int(out.get(k, 0)) + 1 + c.find_children("*", "", true, false).size()
	return out

## The strict post-warm-up leak rule (lap 2 vs the lap-1 end, same workload). [] = steady.
static func steady_state_violations(ref: Dictionary, cur: Dictionary) -> Array:
	var v: Array = []
	if cur["nodes"] != ref["nodes"]:
		v.append("nodes %d != %d" % [cur["nodes"], ref["nodes"]])
	if cur["orphans"] > ref["orphans"]:
		v.append("orphans %d > %d" % [cur["orphans"], ref["orphans"]])
	if abs(cur["objects"] - ref["objects"]) > MAX_OBJECT_DRIFT:
		v.append("objects drift %d > %d" % [cur["objects"] - ref["objects"], MAX_OBJECT_DRIFT])
	if cur["static_mem"] - ref["static_mem"] > MAX_STATIC_MEM_DRIFT:
		v.append("static_mem drift %d > %d" % [cur["static_mem"] - ref["static_mem"], MAX_STATIC_MEM_DRIFT])
	if cur["hosts"] != 0 or cur["root_children"] != ref["root_children"]:
		v.append("hosts %d / root children %d != %d" % [cur["hosts"], cur["root_children"], ref["root_children"]])
	for k in ["effects_listeners", "route_listeners", "settings_listeners"]:
		if cur[k] != ref[k]:
			v.append("%s %d != %d" % [k, cur[k], ref[k]])
	return v

## 014: the strict rule fails on each kind of post-warm-up growth (synthetic samples derived
## from the REAL lap-1 end) and holds exactly at its bounds.
func _sensitivity(ref: Dictionary) -> void:
	print("[014 steady-state rule sensitivity: synthetic post-warm-up growth over the real lap-1 end]")
	var cases := {
		"nodes +1": {"nodes": 1}, "nodes -1": {"nodes": -1}, "orphans +1": {"orphans": 1},
		"objects +%d" % (MAX_OBJECT_DRIFT + 1): {"objects": MAX_OBJECT_DRIFT + 1},
		"objects -%d" % (MAX_OBJECT_DRIFT + 1): {"objects": -(MAX_OBJECT_DRIFT + 1)},
		"static_mem +%d B" % (MAX_STATIC_MEM_DRIFT + 1): {"static_mem": MAX_STATIC_MEM_DRIFT + 1},
		"GameplayHost +1": {"hosts": 1}, "route listener +1": {"route_listeners": 1},
	}
	for name in cases:
		var cur: Dictionary = ref.duplicate(true)
		for k in cases[name]:
			cur[k] = int(cur[k]) + int(cases[name][k])
		var v := steady_state_violations(ref, cur)
		_ok(v.size() == 1, "rule FAILS on %s %s" % [name, str(v)])
	var edge: Dictionary = ref.duplicate(true)
	edge["objects"] = int(edge["objects"]) + MAX_OBJECT_DRIFT
	edge["static_mem"] = int(edge["static_mem"]) + MAX_STATIC_MEM_DRIFT
	_ok(steady_state_violations(ref, edge).is_empty() and steady_state_violations(ref, ref).is_empty(),
		"rule holds at exactly +%d objects / +%d B and for an identical sample" % [MAX_OBJECT_DRIFT, MAX_STATIC_MEM_DRIFT])
	_completed["014_steady_state_sensitivity"] = true

func _boot():
	var path := "user://m55_long_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	root.get_navigation().route_changed.connect(func(f, t, _p): _routes.append([f, t]))
	return root

func _settle() -> void:
	await process_frame
	await process_frame

# ------------------------------------------ SB-M55-008 repeated scene transitions ----

func _transitions(root) -> Dictionary:
	print("[SB-M55-008/010/011/012 repeated transitions: %d x (Settings open/close, PLAY, double PLAY, pre-action back)]" % TRANSITION_CYCLES)
	var app = root.get_app_state()
	var nav = root.get_navigation()
	var hearts0: int = app.economy.hearts.hearts()
	var streak0: int = app.economy.streak.streak()
	var samples: Array = []
	var bad_cycles := 0
	for cycle in range(TRANSITION_CYCLES):
		var r0 := _routes.size()
		var ok: bool = nav.open_settings() and not nav.open_settings() and nav.close_settings()
		var first: Dictionary = root.play_current_frontier()
		var second: Dictionary = root.play_current_frontier()   # same-frame double tap
		ok = ok and first.get("ok", false) and not second.get("ok", false) and String(second.get("reason", "")) == "not_home"
		ok = ok and nav.current() == NavigationController.Route.GAMEPLAY and root.find_children("GameplayHost", "", true, false).size() == 1
		ok = ok and root.handle_back() == "home" and nav.current() == NavigationController.Route.HOME
		ok = ok and root.get_gameplay_host() == null and _routes.size() - r0 == 2
		await _settle()
		if not ok:
			bad_cycles += 1
		samples.append(_sample(root))
	var b: Dictionary = samples[WARMUP_CYCLES - 1]
	var e: Dictionary = samples[TRANSITION_CYCLES - 1]
	print("    after warm-up (cycle %d): %s" % [WARMUP_CYCLES, str(b)])
	print("    after cycle %d:          %s" % [TRANSITION_CYCLES, str(e)])
	_ok(bad_cycles == 0, "every cycle: one host, double PLAY rejected as not_home, pre-action back -> HOME, exactly 2 route changes (%d bad)" % bad_cycles)
	_ok(app.economy.hearts.hearts() == hearts0 and app.economy.streak.streak() == streak0, "40 pre-action exits cost no Heart and no streak")
	_ok(samples.all(func(s): return s["hosts"] == 0), "no GameplayHost survives at HOME in any cycle")
	_completed["008_transitions"] = true
	# SB-M55-012 orphans / 010 memory / 011 listeners across the transition churn.
	var nodes_eq := samples.slice(WARMUP_CYCLES - 1).all(func(s): return s["nodes"] == b["nodes"] and s["root_children"] == b["root_children"])
	_ok(nodes_eq, "tree Node count identical in every post-warm-up cycle (%d)" % b["nodes"])
	_ok(e["orphans"] <= b["orphans"], "orphan Nodes do not grow (%d -> %d)" % [b["orphans"], e["orphans"]])
	_ok(abs(e["objects"] - b["objects"]) <= MAX_OBJECT_DRIFT, "Object count drift %d <= %d" % [e["objects"] - b["objects"], MAX_OBJECT_DRIFT])
	_ok(e["static_mem"] - b["static_mem"] <= MAX_STATIC_MEM_DRIFT, "static memory drift %d B <= %d B" % [e["static_mem"] - b["static_mem"], MAX_STATIC_MEM_DRIFT])
	_ok(samples.all(func(s): return s["effects_listeners"] == b["effects_listeners"] and s["route_listeners"] == b["route_listeners"] and s["settings_listeners"] == b["settings_listeners"]),
		"long-lived authority listener counts constant (effects %d, route %d, settings %d)" % [b["effects_listeners"], b["route_listeners"], b["settings_listeners"]])
	return b

# --------------------------------------- SB-M55-009 long high-load session + 013 -----

## Drive one production level to its terminal: owner intendedColumnClicks where the
## level has an owner supply plan, otherwise (Level 1, M23 generator) greedy fronts.
func _drive(host) -> Dictionary:
	var clicks: Array = []
	if not String(host.supply_plan_path).is_empty():
		clicks = SupplyPlanLoader.load_plan(host.supply_plan_path)["plan"]["intendedColumnClicks"]
	var rt = host.get_runtime()
	rt.set_process(false)
	var input = host.get_input_controller()
	var slots = host.get_slots()
	var i := 0
	var frames := 0
	while frames < 200000 and not host.get_completion().is_terminal():
		if slots.rightmost_empty_index() != -1:
			if not clicks.is_empty():
				if i < clicks.size() and input.activate_front(int(clicks[i]) - 1).get("ok", false):
					i += 1
			else:
				for col in range(host.get_supply().get_column_count()):
					if input.activate_front(col).get("ok", false):
						break
		rt.tick(DT)
		frames += 1
	return {"frames": frames, "clicks": i}

## Plays Levels 1..10 back-to-back; returns the HOME sample at the end of the lap.
func _long_session(root, base: Dictionary, lap: int) -> Dictionary:
	print("[SB-M55-009/013 long session lap %d: Levels 1..%d back-to-back through Home -> Gameplay -> Results -> Continue]" % [lap, LEVELS])
	var app = root.get_app_state()
	var eco = app.economy
	var nav = root.get_navigation()
	var cfg = eco.config
	var t0 := Time.get_ticks_msec()
	var total_clears := 0
	var total_frames := 0
	var per_level: Array = []
	var reward_bad: Array = []
	var signal_bad: Array = []
	var dup_bad: Array = []
	var won := 0
	_ok(root.play_current_frontier().get("ok", false), "Home PLAY launches Level 1")
	for n in range(1, LEVELS + 1):
		var host = root.get_gameplay_host()
		if host == null or int(host.progression_level) != n:
			_ok(false, "level %d host present (got %s)" % [n, str(host.progression_level if host != null else null)])
			break
		var clears := {"events": 0, "dups": 0, "seen": {}}
		var terminals: Array = []
		host.get_clearing_loop().authenticated_clear.connect(func(_o, target, _c, _a):
			clears["events"] += 1
			if clears["seen"].has(target):
				clears["dups"] += 1
			clears["seen"][target] = true)
		host.get_completion().terminal_reached.connect(func(s, _d): terminals.append(String(s)))
		var cells: int = host.get_board().get_cell_count()
		var sb0: int = eco.wallet.scrub_bucks()
		var tx0: int = eco.reward.applied_transaction_count()
		var parts0: int = eco.wallet.bot_parts()
		var streak0: int = eco.streak.streak()
		var r0 := _routes.size()
		var d := _drive(host)
		total_frames += d["frames"]
		total_clears += clears["events"]
		if terminals != ["WON"]:
			_ok(false, "level %d terminal %s after %d frames (active left %d)" % [n, str(terminals), d["frames"], host.get_board().count_cells_by_state(BoardState.CellState.ACTIVE)])
			break
		won += 1
		# 011: exactly one RESULTS route per terminal; one clear per cell.
		var to_results: int = _routes.slice(r0).filter(func(x): return x[1] == NavigationController.Route.RESULTS).size()
		if to_results != 1 or nav.current() != NavigationController.Route.RESULTS or clears["events"] != cells or clears["dups"] != 0:
			signal_bad.append([n, to_results, clears["events"], cells, clears["dups"]])
		# 013: SB delta == first-clear(class) + streak position reward; exact reward tx set.
		var want_sb: int = cfg.first_clear_sb(app.progression.class_for(n)) + cfg.win_streak_sb(streak0 + 1)
		var got_sb: int = eco.wallet.scrub_bucks() - sb0
		var tx1: int = eco.reward.applied_transaction_count()
		if got_sb != want_sb or tx1 <= tx0 or eco.streak.streak() != streak0 + 1 or eco.wallet.bot_parts() <= parts0:
			reward_bad.append([n, got_sb, want_sb, tx1 - tx0])
		# 013: chaos on the terminal — re-emitted terminal signal, repeated host terminal
		# handler, repeated FirstClear commit and 10 same-frame Continue taps.
		var sb1: int = eco.wallet.scrub_bucks()
		var rr := _routes.size()
		host.get_completion().terminal_reached.emit(&"WON", {})
		host._on_terminal_reached(&"WON", {})
		var refc: Dictionary = preload("res://scripts/economy/first_clear_transaction.gd").commit(app.progression, eco, n)
		if eco.wallet.scrub_bucks() != sb1 or eco.reward.applied_transaction_count() != tx1 or refc.get("ok", false) or _routes.size() != rr:
			dup_bad.append([n, "re-terminal", eco.wallet.scrub_bucks() - sb1, _routes.size() - rr])
		var cont_ok := 0
		for _k in range(10):
			if root.continue_from_results().get("ok", false):
				cont_ok += 1
		await _settle()
		var s := _sample(root)
		per_level.append([n, cells, d["frames"], d["clicks"], got_sb, s["nodes"], s["orphans"], s["objects"], s["static_mem"]])
		if n < LEVELS:
			if cont_ok != 1 or s["hosts"] != 1 or nav.current() != NavigationController.Route.GAMEPLAY:
				dup_bad.append([n, "continue", cont_ok, s["hosts"]])
		elif cont_ok != 0:
			dup_bad.append([n, "continue past content", cont_ok])
	var ms := Time.get_ticks_msec() - t0
	print("    per level [n, cells, frames, clicks, SB, nodes, orphans, objects, static_mem]:")
	for row in per_level:
		print("      %s" % str(row))
	print("    session: %d levels WON, %d clears, %d sim frames, %d ms wall" % [won, total_clears, total_frames, ms])
	_ok(won == LEVELS, "all %d production levels WON back-to-back in one app session" % LEVELS)
	_ok(app.progression.current_level() == LEVELS + 1, "frontier advanced to %d (got %d)" % [LEVELS + 1, app.progression.current_level()])
	_completed["009_long_session"] = true
	_ok(signal_bad.is_empty(), "each level: exactly one RESULTS transition and one clear event per cell %s" % str(signal_bad))
	_ok(reward_bad.is_empty(), "each WON: SB == first_clear_sb(class) + win_streak_sb(position), reward tx grew, Bot Parts grew, streak +1 %s" % str(reward_bad))
	_ok(dup_bad.is_empty(), "re-emitted terminal / re-run handler / re-committed FirstClear / 10 Continue taps: zero extra SB, tx, route; exactly one next host %s" % str(dup_bad))
	# After frontier 11 (no content) return HOME and compare with the transition baseline.
	_ok(nav.go(NavigationController.Route.HOME, {"via": "results"}), "RESULTS -> HOME after Level %d" % LEVELS)
	await _settle()
	# Sample at feel quiescence: presentation-feel bursts (Results WIN confetti, the Home
	# ceremony's REWARD burst) are transient Nodes the adapter frees within its per-tier ceiling
	# (<= 1.3 s). Counting one mid-flight is timing noise, not a leak; a leaked burst would
	# outlive the adapter's ownership and still be counted below.
	var t0q := Time.get_ticks_msec()
	while root.feel.owned_count() > 0 and Time.get_ticks_msec() - t0q < 5000:
		await process_frame
	await _settle()
	_ok(root.feel.owned_count() == 0, "feel quiescent at the HOME sample (adapter owns no live decoration; waited %d ms)" % (Time.get_ticks_msec() - t0q))
	var e := _sample(root)
	print("    HOME baseline: %s" % str(base))
	print("    HOME after long session: %s" % str(e))
	# Every lap: no GameplayHost at HOME, same app-root shape, no orphan growth, authority
	# listeners back to baseline. Node / Object / static memory: see the lap branch below.
	_ok(e["hosts"] == 0 and e["root_children"] == base["root_children"], "back at HOME: no GameplayHost, app root children unchanged (%d)" % e["root_children"])
	_ok(e["orphans"] <= base["orphans"], "no orphan Node accumulated over the session (%d -> %d)" % [base["orphans"], e["orphans"]])
	_completed["012_orphans"] = true
	_ok(e["effects_listeners"] == base["effects_listeners"] and e["route_listeners"] == base["route_listeners"] and e["settings_listeners"] == base["settings_listeners"],
		"authority listener counts back to baseline after 10 hosts")
	_completed["011_signals"] = true
	if lap == 1:
		# WARM-UP (recorded, not a pass rule): the first real lap materializes first-use state
		# (first-load content, lazily created presentation / plugin structures). The strict leak
		# bounds apply to lap 2 against this lap's end sample.
		var grew: Dictionary = {}
		for k in e["tree"]:
			if int(e["tree"][k]) != int(base["tree"].get(k, 0)):
				grew[k] = int(e["tree"][k]) - int(base["tree"].get(k, 0))
		print("    WARM-UP lap 1 first-use delta over the empty-Home baseline: nodes %+d %s, objects %+d, static_mem %+d B" % [e["nodes"] - base["nodes"], str(grew),
			e["objects"] - base["objects"], e["static_mem"] - base["static_mem"]])
	else:
		var v := steady_state_violations(base, e)
		_ok(v.is_empty(), "lap 2 vs lap-1 end (same workload): Node count exact, orphans not grown, Object drift <= %d, static-memory drift <= %d B, hosts / root children / listeners stable %s" % [MAX_OBJECT_DRIFT, MAX_STATIC_MEM_DRIFT, str(v)])
	# Persisted truth: relaunch-level reload of the save shows the same wallet (no double grant on flush).
	var sb_end: int = eco.wallet.scrub_bucks()
	_ok(root.flush_lifecycle("test").get("ok", false), "lifecycle flush ok")
	var app2 = preload("res://scripts/app/app_state.gd").new(MainScript.boot_save_path_override)
	_ok(app2.economy.wallet.scrub_bucks() == sb_end and app2.economy.reward.applied_transaction_count() == eco.reward.applied_transaction_count(),
		"reloaded save: identical SB (%d) and reward tx set — rewards persisted exactly once" % sb_end)
	_completed["013_rewards"] = true
	return e

# ------------------------------------------------------------------- infra -----

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
