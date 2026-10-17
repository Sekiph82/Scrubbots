extends SceneTree
## M46-RM-003 — FTUE coach copy without the moving-robot Selector full-list hitch
## (ChatGPT spec CHATGPT_M46_RM003_FTUE_MOVING_COACH_PERFORMANCE_PROMPT_V01.md, finding V2-P1).
## The copy now asks host.booster_legality_offframe(id, false): Selector answers "any batch safe?"
## (has_eligible_safe_batch) instead of building every target. Cases:
##   C1 real L2 app, step A (+1 / Selector) and B (Random / Tornado) while robots move: the copy
##      main code path is rebuilt (timestamp + body), equals an oracle from the FULL legality,
##      costs <= 4 ms mean / < 16.7 ms max (old full-list path reported side by side), no worker;
##      at a still moment: "checking" + worker, no main-thread proof, then oracle after settle;
##   C2 truth equivalence hint == non-empty full list: L1 still (unbudgeted real classifier) at
##      start / 5 full / 6 slots one empty / 6 full / empty supply / cached partial and safe
##      verdicts; 59x59 stripes + VOID pocket (WAITING) moving; missing adapter, exiting,
##      terminal (L1 played to WON); 59x59 moving hint cost vs full list;
##   C3 the real Selector popup still lists the proven targets (every chip == a full-list id),
##      a boolean hint authorizes nothing (unknown target refused, nothing spent), a real chip
##      spends one charge once;
##   C4 timers: 200 ms tick never rebuilds the copy (one per 2000 ms), a modal hides it and stops
##      all hint work, Retry refreshes to the new state with no stale copy or leaked worker.
## Every case asserts it reached its branch. Local Godot 4.7.2 only.
## Run: godot --headless --path . -s res://tests/m46_rm003_ftue_coach_performance.gd

const ProductionGameplayHost = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const SupplyPlanLoader = preload("res://scripts/gameplay/supply/supply_plan_loader.gd")
const LevelData = preload("res://scripts/data/level_data.gd")
const SlotBatchState = preload("res://scripts/gameplay/slots/slot_batch_state.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const DT := 1.0 / 60.0
const PLUS := "plus_one_slot"
const RANDOM := "random"
const SELECTOR := "selector"
const TORNADO := "tornado"
const SAMPLES := 20
const MEAN_MAX_MS := 4.0
const FRAME_MS := 16.7
const N := 59
const STRIPE_CIDS := ["C01", "C02", "C03", "C04", "C07", "C08", "C10", "C11"]
const POCKET_CIDS := ["C13", "C14", "C15"]
const POCKET_CENTRES := [Vector2i(15, 15), Vector2i(43, 15), Vector2i(15, 43), Vector2i(43, 43)]
var _fail := 0
var _cases := 0
var _tmp: Array = []
var _v3 := PackedStringArray()
var _cids: Array = []
var _sub: SubViewport = null
var _root = null
var _host = null

func _initialize() -> void:
	OS.low_processor_usage_mode_sleep_usec = 0
	await process_frame
	var pal = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in pal["colors"]:
		_v3.append("#%sFF" % String(c["hex"]).trim_prefix("#").to_upper())
		_cids.append(String(c["id"]))
	await _c1_l2_copy()
	await _c2_equivalence()
	await _c3_popup_chips()
	await _c4_timers_lifecycle()
	_shutdown()
	MainScript.boot_save_path_override = ""
	MainScript.boot_ftue_override = -1
	for p in _tmp:
		for f in [p, p + ".bak", p + ".tmp"]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("M46 RM003 FTUE COACH: %s (%d case groups)" % ["PASS" if _fail == 0 and _cases == 4 else "FAIL (%d fails, %d/4 groups completed)" % [_fail, _cases], _cases])
	quit(0 if _fail == 0 and _cases == 4 else 1)

# ------------------------------------------------------------------ fixtures ----

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _ms(t0: int) -> float:
	return (Time.get_ticks_usec() - t0) / 1000.0

func _stats(a: Array) -> Dictionary:
	if a.is_empty():
		return {"n": 0, "mean": INF, "p95": INF, "p99": INF, "max": INF}
	var s := a.duplicate()
	s.sort()
	var sum := 0.0
	for v in s:
		sum += v
	return {"n": s.size(), "mean": sum / s.size(), "p95": s[mini(s.size() - 1, int(ceil(s.size() * 0.95)) - 1)],
		"p99": s[mini(s.size() - 1, int(ceil(s.size() * 0.99)) - 1)], "max": s[-1]}

func _fmt(st: Dictionary) -> String:
	return "n %d mean %.2f p95 %.2f p99 %.2f max %.2f ms" % [st["n"], st["mean"], st["p95"], st["p99"], st["max"]]

func _write(tag: String, text: String) -> String:
	var p := "user://m46rm003_%s.json" % tag
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	_tmp.append(p)
	return p

func _boot_play(level: int) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	var path := "user://m46rm003_app_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	MainScript.boot_save_path_override = path
	MainScript.boot_ftue_override = 1
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(4)
	MainScript.boot_ftue_override = -1
	_root.get_modal_stack().clear("t")
	_root.get_app_state().progression.debug_set_current_level(level)
	_root.play_current_frontier()
	await _frames(6)
	_host = _root.get_gameplay_host()
	_host.get_runtime().set_process(false)
	_root.get_modal_stack().clear("t")
	await _frames(2)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_host = null
	_sub = null

func _host_in(h) -> void:
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	h.auto_build = false
	h.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub.add_child(h)

func _host_file(level: Dictionary, plan: Dictionary, tag: String):
	var h = ProductionGameplayHost.new()
	h.level_path = _write("lvl_" + tag, JSON.stringify(level))
	h.supply_plan_path = _write("plan_" + tag, JSON.stringify(plan))
	_host_in(h)
	_ok(h.build(), "%s host builds %s" % [tag, h.get_build_error()])
	h.get_runtime().set_process(false)
	await _frames(2)
	return h

func _host_l1():
	var path := "user://m46rm003_l1_%d.save" % Time.get_ticks_usec()
	_tmp.append(path)
	var h = ProductionGameplayHost.new()
	h.app_state = AppState.new(path, Callable())
	_host_in(h)
	_ok(h.build(), "L1 host builds")
	h.get_runtime().set_process(false)
	await _frames(2)
	return h

func _free(h) -> void:
	if h != null and is_instance_valid(h):
		var sub = h.get_parent()
		sub.remove_child(h)
		h.free()
		sub.free()

func _tap(h) -> bool:
	for c in range(h.get_supply().get_column_count()):
		if h.get_input_controller().activate_front(c).get("ok", false):
			return true
	return false

## Robots in flight AND an empty slot (the state where the Selector hint has real work to do).
func _busy_with_room(h) -> bool:
	for _i in range(600):
		var s = h.get_slots()
		if h.get_scheduler().live_assignment_count() > 0 and s.rightmost_empty_index() != -1:
			return true
		if h.get_scheduler().live_assignment_count() == 0 or s.rightmost_empty_index() == -1:
			if s.rightmost_empty_index() != -1:
				_tap(h)
		h.get_runtime().tick(DT)
		await process_frame
	return false

func _still(h) -> bool:
	for _i in range(6000):
		if h.get_scheduler().live_assignment_count() == 0:
			return true
		h.get_runtime().tick(DT)
		await process_frame
	return false

func _wait_worker(h, cap_ms: float = 8000.0) -> void:
	var t0 := Time.get_ticks_usec()
	while h.is_booster_proof_running() and _ms(t0) < cap_ms:
		await process_frame
	await _frames(2)

## The copy the coach SHOULD show, from the FULL (list) legality of the same state.
func _oracle(step: Dictionary, h) -> String:
	var lines: Array = []
	for id in step["boosters"]:
		var line := UiText.t("FTUE_BOOSTER_LINE", [UiText.t("BOOSTER_NAME_" + String(id).to_upper()),
			UiText.num(_root.get_app_state().economy.boosters.charges(String(id))), UiText.t("BOOSTER_EFFECT_" + String(id).to_upper())])
		if not bool(h.booster_legality(String(id)).get("legal", false)):
			line += " " + UiText.t("FTUE_BOOSTER_NOT_NOW")
		lines.append(line)
	return "\n".join(lines)

## One timed rebuild of the real coach copy (main.refresh_coachmark with the 2 s gate opened).
## Returns [copy ms, rebuilt?, body, step].
func _timed_copy() -> Array:
	_root._coach_copy["at"] = 0
	var t := Time.get_ticks_usec()
	_root.refresh_coachmark()
	var ms := _ms(t)
	var c: Dictionary = _root._coach_copy
	var want: Dictionary = _root._coach_want()
	return [ms, int(c["at"]) > 0 and String(c["id"]) == _root.get_coachmarks().get_step_id(), String(c["copy"].get("body", "")),
		want.get("step", {})]

# ---------------------------------------------------------------------- C1 ----

func _c1_l2_copy() -> void:
	print("[C1 real L2 coach copy while robots move: cost, accuracy, no worker; still-moment checking]")
	await _boot_play(2)
	var cm = _root.get_coachmarks()
	_host.cancel_booster_proof()
	for step_id in ["l2_boosters_a", "l2_boosters_b"]:
		if step_id == "l2_boosters_b":
			_ok(_root.get_ftue().acknowledge("l2_boosters_a"), "step A acknowledged -> step B")
		var copy_ms: Array = []
		var old_ms: Array = []
		var frame_ms: Array = []
		var accurate := 0
		var rebuilt := 0
		var workers := 0
		var busy := 0
		var per_id := {}
		for _w in range(3 + SAMPLES):
			busy += 1 if await _busy_with_room(_host) else 0
			_host.cancel_booster_proof()   # any still-frame job from the tick timer: only moving copies are measured
			var r := await _timed_copy()
			workers += 1 if _host.is_booster_proof_running() else 0
			var oracle := _oracle(r[3], _host)
			# The pre-RM003 path: every advertised booster through the full (list) legality.
			var t := Time.get_ticks_usec()
			for id in r[3].get("boosters", []):
				_host.booster_legality(String(id))
			var old := _ms(t)
			for id in r[3].get("boosters", []):   # per-booster hint attribution (report only)
				t = Time.get_ticks_usec()
				_host.booster_legality(String(id), false)
				per_id[id] = per_id.get(id, []) + [_ms(t)] if _w >= 3 else per_id.get(id, [])
			var tf := Time.get_ticks_usec()
			_root._coach_copy["at"] = 0
			_root.refresh_coachmark()
			await process_frame
			var fr := _ms(tf)
			if _w < 3:
				continue   # warm-up
			copy_ms.append(r[0])
			old_ms.append(old)
			frame_ms.append(fr)
			rebuilt += 1 if r[1] else 0
			accurate += 1 if r[2] == oracle and cm.get_step_id() == step_id else 0
		var st := _stats(copy_ms)
		print("    %s moving copy: %s | old full-list path: %s | frame incl. copy: %s" % [step_id, _fmt(st), _fmt(_stats(old_ms)), _fmt(_stats(frame_ms))])
		for id in per_id:
			print("      hint %s: %s" % [id, _fmt(_stats(per_id[id]))])
		_ok(busy == 3 + SAMPLES and not _host.get_completion().is_terminal(), "%s: every sample taken with robots in flight and an empty slot (%d)" % [step_id, busy])
		_ok(rebuilt == SAMPLES and accurate == SAMPLES, "%s: %d/%d copies rebuilt through main.refresh_coachmark, %d/%d equal the full-legality oracle" % [step_id, rebuilt, SAMPLES, accurate, SAMPLES])
		_ok(workers == 0, "%s: robots moving -> no off-frame worker (%d)" % [step_id, workers])
		_ok(st["mean"] <= MEAN_MAX_MS and st["max"] < FRAME_MS, "%s: copy mean %.2f <= %.1f ms and max %.2f < %.1f ms" % [step_id, st["mean"], MEAN_MAX_MS, st["max"], FRAME_MS])
	# Still moment, step B (Random): no cached verdict -> "checking" + worker, no main-thread proof.
	_ok(await _still(_host), "robots still")
	_host.cancel_booster_proof()
	var a = _host.get_booster_adapter()
	var lp1: int = a.live_proof_count
	var r2 := await _timed_copy()
	var checking: bool = _host.is_booster_proof_running() and a.live_proof_count == lp1
	_ok(checking and not String(r2[2].split("\n")[0]).ends_with(UiText.t("FTUE_BOOSTER_NOT_NOW")), "still: copy says nothing for Random while checking (worker running, %.2f ms, no main-thread proof)" % r2[0])
	await _wait_worker(_host)
	var r3 := await _timed_copy()
	_ok(r3[2] == _oracle(r3[3], _host) and a.live_proof_count == lp1, "after settle: copy == oracle from the cached verdict, still no main-thread Random proof")
	_cases += 1

# ---------------------------------------------------------------------- C2 ----

func _same(h, tag: String) -> bool:
	var hint: Dictionary = h.booster_legality(SELECTOR, false)
	var full: Dictionary = h.booster_legality(SELECTOR)
	var ok: bool = bool(hint["legal"]) == not (full["targets"] as Array).is_empty() and bool(hint["legal"]) == bool(full["legal"]) \
		and String(hint["reason"]) == String(full["reason"]) and (hint["targets"] as Array).is_empty()
	_ok(ok, "%s: hint {legal %s, %s} == full list {legal %s, %d targets, %s}" % [tag, str(hint["legal"]), hint["reason"], str(full["legal"]), full["targets"].size(), full["reason"]])
	_same_tornado(h, tag)
	return bool(hint["legal"])

## Tornado hint (native any-ACTIVE search) == non-empty present_colors() / full legality.
func _same_tornado(h, tag: String) -> bool:
	var a = h.get_booster_adapter()
	if a == null:
		return false
	var hint: Dictionary = h.booster_legality(TORNADO, false)
	var full: Dictionary = h.booster_legality(TORNADO)
	var ok: bool = a.has_present_color() == not a.present_colors().is_empty() and bool(hint["legal"]) == bool(full["legal"]) 		and String(hint["reason"]) == String(full["reason"]) and (hint["targets"] as Array).is_empty()
	_ok(ok, "%s: Tornado hint {legal %s, %s} == full {legal %s, %d colours}" % [tag, str(hint["legal"]), hint["reason"], str(full["legal"]), full["targets"].size()])
	return ok

func _c2_equivalence() -> void:
	print("[C2 hint == non-empty full Selector list, every state class]")
	# L1 still, real classifier, unbudgeted on both sides (truth, not the 400 ms cap).
	var h = await _host_l1()
	var a = h.get_booster_adapter()
	a.budget_ms = 0
	var seen := {}
	seen["start"] = _same(h, "L1 still start")
	# Cached verdicts for the exact current state answer both (partial empty / proven list).
	a.put_verdict("selector_list", a.state_key(), {"ids": [], "partial": true})
	var c1: Dictionary = h.booster_legality(SELECTOR, false)
	_same(h, "L1 cached partial-empty verdict")
	a.put_verdict("selector_list", a.state_key(), {"ids": ["X"], "partial": false})
	var c2: Dictionary = h.booster_legality(SELECTOR, false)
	_same(h, "L1 cached proven verdict")
	seen["cache_timeout"] = not c1["legal"] and c1["reason"] == "proof_timeout" and c2["legal"]
	a._verdicts.clear()
	# Empty supply with room in the slots (restored afterwards).
	var cols: Array = a._current_cols()
	var sup = h.get_supply()
	var empties: Array = []
	empties.resize(sup.get_column_count())
	for i in range(empties.size()):
		empties[i] = []
	_ok(sup.load_candidate(empties, sup.get_seed(), sup.get_palette_size()), "supply emptied (test fixture, %d columns)" % empties.size())
	seen["empty_supply"] = not _same(h, "L1 empty supply")
	_ok(sup.load_candidate(cols, sup.get_seed(), sup.get_palette_size()), "supply restored")
	while h.get_slots().rightmost_empty_index() != -1 and _tap(h):
		pass
	seen["full5"] = _same(h, "L1 5 slots full")
	var eco = h.get_economy()
	eco.wallet.credit("scrub_bucks", 5000)
	_ok(h.execute_booster(PLUS).get("ok", false) and h.get_slots().get_slot_count() == 6, "+1 Slot -> 6 slots")
	seen["six_room"] = _same(h, "L1 6 slots, one empty")
	_tap(h)
	seen["six_full"] = _same(h, "L1 6 slots full")
	var keep = h._booster_adapter
	h._booster_adapter = null
	var na: Dictionary = h.booster_legality(SELECTOR, false)
	seen["no_adapter"] = not na["legal"] and na["reason"] == "economy_unavailable" and h.booster_legality(SELECTOR)["reason"] == "economy_unavailable"
	h._booster_adapter = keep
	h._proof_closed = true
	var ex: Dictionary = h.booster_legality_offframe(SELECTOR, false)
	seen["exiting"] = not ex["legal"] and ex["reason"] == "exiting" and not h.is_booster_proof_running()
	h._proof_closed = false
	_free(h)
	# L1 played to WON: terminal.
	h = await _host_l1()
	h.get_runtime().set_speed_2x(true)
	for _i in range(20000):
		if h.get_completion().is_terminal():
			break
		_tap(h)
		h.get_runtime().tick(DT)
		if _i % 8 == 0:
			await process_frame
	var tl: Dictionary = h.booster_legality(SELECTOR, false)
	var ad = h.get_booster_adapter()
	seen["terminal"] = h.get_completion().is_terminal() and not tl["legal"] and tl["reason"] == "terminal" 		and not ad.has_present_color() and ad.present_colors().is_empty()
	print("    L1 played to %s" % String(h.get_completion().get_state()))
	_free(h)
	# 59x59 stripes + VOID pocket (WAITING), robots in flight: the in-flight shortcut on both sides.
	for which in ["stripes", "pocket"]:
		var lv: Dictionary = _stripe_level() if which == "stripes" else _pocket_level()
		h = await _host_file(lv, _plan(lv), "eq_" + which)
		_ok(await _busy_with_room(h), "59x59 %s robots in flight with room" % which)
		var waiting := 0
		for i in range(h.get_slots().get_slot_count()):
			waiting += 1 if h.get_slots().is_occupied(i) and h.get_slots().get_state(i) == SlotBatchState.WAITING else 0
		seen[which] = _same(h, "59x59 %s moving (WAITING slots %d)" % [which, waiting])
		if which == "stripes":
			var hint_ms: Array = []
			var full_ms: Array = []
			for _k in range(3 + SAMPLES):
				await _busy_with_room(h)
				var t := Time.get_ticks_usec()
				h.booster_legality(SELECTOR, false)
				var hm := _ms(t)
				t = Time.get_ticks_usec()
				h.booster_legality(SELECTOR)
				var fm := _ms(t)
				if _k >= 3:
					hint_ms.append(hm)
					full_ms.append(fm)
			var hs := _stats(hint_ms)
			print("    59x59 moving Selector: hint %s | full list %s" % [_fmt(hs), _fmt(_stats(full_ms))])
			_ok(hs["mean"] <= MEAN_MAX_MS and hs["max"] < FRAME_MS, "59x59 moving hint mean %.2f <= %.1f, max %.2f < %.1f ms" % [hs["mean"], MEAN_MAX_MS, hs["max"], FRAME_MS])
			while h.get_slots().rightmost_empty_index() != -1 and _tap(h):
				pass
			seen["59_full"] = not _same(h, "59x59 slots full while moving")
		_free(h)
	var need := ["start", "full5", "six_room", "six_full", "cache_timeout", "empty_supply", "no_adapter", "exiting", "terminal", "stripes", "pocket", "59_full"]
	var reached := need.filter(func(k): return seen.has(k))
	_ok(reached.size() == need.size() and seen["start"] and not seen["full5"] and seen["six_room"] and not seen["six_full"]
		and seen["cache_timeout"] and seen["empty_supply"] and seen["no_adapter"] and seen["exiting"] and seen["terminal"]
		and seen["stripes"] and seen["59_full"],
		"every state class reached with the expected verdict (%d/%d): %s" % [reached.size(), need.size(), str(seen)])
	_cases += 1

# ---------------------------------------------------------------------- C3 ----

func _chips(p) -> Array:
	var out: Array = []
	for ch in p.find_child("Targets", true, false).get_children():
		if not ch.is_queued_for_deletion():
			out.append(String(ch.name).trim_prefix("Target_"))
	return out

func _c3_popup_chips() -> void:
	print("[C3 the real Selector popup still lists proven targets only; a hint authorizes nothing]")
	await _boot_play(2)
	_ok(await _still(_host), "L2 still")
	_host.cancel_booster_proof()
	var hint: Dictionary = _host.booster_legality_offframe(SELECTOR, false)
	await _wait_worker(_host)
	var eco = _root.get_app_state().economy
	_ok(eco.boosters.add_charges(SELECTOR, 1), "test grants one Selector charge")
	var p = _root.get_acquisition().open_booster(_host, SELECTOR)
	await _wait_worker(_host)
	var a = _host.get_booster_adapter()
	var proven: Array = a.eligible_safe_batches()
	var chips := _chips(p)
	var all_proven: bool = not chips.is_empty() and chips.all(func(k): return proven.has(k))
	var hint2: Dictionary = _host.booster_legality(SELECTOR, false)
	_ok(String(hint["reason"]) == "checking" and all_proven and chips.size() == mini(proven.size(), _root.get_acquisition().MAX_TARGET_CHIPS)
		and bool(hint2["legal"]) == not chips.is_empty(),
		"popup chips %d == proven list (capped; %d proven, partial %s), every chip proven; hint legal %s agrees" % [chips.size(), proven.size(), str(a.last_proof_timed_out()), str(hint2["legal"])])
	var c0: int = eco.boosters.charges(SELECTOR)
	var sb0: int = eco.wallet.scrub_bucks()
	var bad: Dictionary = _host.execute_booster(SELECTOR, "NO_SUCH_BATCH")
	var none: Dictionary = _host.execute_booster(SELECTOR, null)
	_ok(not bad.get("ok", false) and not none.get("ok", false) and eco.boosters.charges(SELECTOR) == c0 and eco.wallet.scrub_bucks() == sb0,
		"unknown / missing target refused (%s, %s), charge %d and SB %d unchanged" % [bad.get("reason", ""), none.get("reason", ""), c0, sb0])
	p.close("t")
	await _frames(2)
	var good: Dictionary = _host.execute_booster(SELECTOR, chips[0])
	_ok(good.get("ok", false) and eco.boosters.charges(SELECTOR) == c0 - 1 and eco.wallet.scrub_bucks() == sb0,
		"a proven chip target executes: charge %d -> %d once, SB unchanged" % [c0, eco.boosters.charges(SELECTOR)])
	_cases += 1

# ---------------------------------------------------------------------- C4 ----

## Real frames for `secs` with the in-flight state held (robots mid-route, scheduler not ticked);
## returns [copy rebuilds observed, budgeted Selector questions].
func _hold(secs: float) -> Array:
	var a = _host.get_booster_adapter()
	var lp0: int = a.live_proof_count
	var at := int(_root._coach_copy["at"])
	var rebuilds := 0
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(secs * 1000.0):
		await process_frame
		if int(_root._coach_copy["at"]) != at:
			at = int(_root._coach_copy["at"])
			rebuilds += 1
	return [rebuilds, a.live_proof_count - lp0]

func _c4_timers_lifecycle() -> void:
	print("[C4 200 ms tick / 2000 ms copy cadence, modal, Retry]")
	await _boot_play(2)
	_host.cancel_booster_proof()
	_ok(await _busy_with_room(_host), "robots in flight")
	_host.cancel_booster_proof()
	_root._coach_copy["at"] = 0
	_root.refresh_coachmark()   # fresh copy now; the next one is due 2000 ms later
	var r := await _hold(2.5)
	_ok(r[0] == 1 and r[1] == 1 and _root.get_coachmarks().get_step_id() == "l2_boosters_a",
		"2.5 s of real frames (~12 ticks of 200 ms): %d copy rebuild, %d Selector question (one per 2000 ms, not per tick)" % [r[0], r[1]])
	var p = _root.get_acquisition().open_booster(_host, TORNADO)
	await _frames(2)
	var hidden: bool = not _root.get_coachmarks().is_showing()
	r = await _hold(2.5)
	_ok(p != null and hidden and r[0] == 0 and r[1] == 0, "modal open: coach hidden, 0 copy rebuilds, 0 hint proofs over 2.5 s")
	p.close("t")
	await _frames(2)
	_ok(_root.get_coachmarks().is_showing(), "modal closed: coach shown again")
	var key0: Array = _host.get_booster_adapter().state_key()
	_ok(_host.retry(), "Retry")
	await _frames(2)
	_host.cancel_booster_proof()
	var rr := await _timed_copy()
	var a = _host.get_booster_adapter()
	var fresh: bool = a.state_key() != key0
	await _wait_worker(_host)
	var rr2 := await _timed_copy()
	_ok(fresh and rr[1] and rr2[2] == _oracle(rr2[3], _host) and not _host.is_booster_proof_running(),
		"after Retry: new state, copy rebuilt and == oracle once proven, no worker left running")
	_cases += 1

# ------------------------------------------------------------------ levels ----

func _stripe_level() -> Dictionary:
	var used: Array = STRIPE_CIDS.duplicate()
	var pal: Array = []
	for cid in used:
		pal.append(_v3[_cids.find(cid)])
	var cells: Array = []
	for y in range(N):
		for x in range(N):
			cells.append(mini(x * used.size() / N, used.size() - 1))
	return {"version": 1, "id": "m46rm003_stripes", "name": "RM003", "difficulty": "TEST", "width": N, "height": N, "palette": pal, "cells": cells}

func _pocket_level() -> Dictionary:
	var used: Array = POCKET_CIDS + STRIPE_CIDS
	used.sort()
	var pal: Array = []
	var local := {}
	for cid in used:
		local[cid] = pal.size()
		pal.append(_v3[_cids.find(cid)])
	var cells: Array = []
	for y in range(N):
		for x in range(N):
			if x < 2 or y < 2 or x >= N - 2 or y >= N - 2:
				cells.append(LevelData.VOID_CELL)
				continue
			var cid: String = STRIPE_CIDS[mini((x - 2) * STRIPE_CIDS.size() / (N - 4), STRIPE_CIDS.size() - 1)]
			for c in POCKET_CENTRES:
				var d: int = maxi(absi(x - c.x), absi(y - c.y))
				if d <= 4:
					cid = POCKET_CIDS[0] if d == 4 else (POCKET_CIDS[1] if d == 3 else POCKET_CIDS[2])
			cells.append(local[cid])
	return {"version": 2, "id": "m46rm003_pockets", "name": "RM003 Pockets", "difficulty": "TEST", "width": N, "height": N, "palette": pal, "cells": cells}

## Stripe batches round-robin in columns 0..3, pocket batches (P1 -> P3) in column 4: its front
## enters a slot at once and WAITS until the stripes around a pocket clear.
func _plan(level: Dictionary) -> Dictionary:
	var counts := {}
	for c in level["cells"]:
		if int(c) >= 0:
			counts[int(c)] = int(counts.get(int(c), 0)) + 1
	var cid_of := {}
	for i in range(level["palette"].size()):
		cid_of[i] = _cids[_v3.find(String(level["palette"][i]))]
	var cols: Array = [[], [], [], [], []]
	var n := 0
	var rr := 0
	var lanes := 4 if cid_of.values().any(func(c): return POCKET_CIDS.has(c)) else 5
	for want in STRIPE_CIDS + POCKET_CIDS:
		for local in counts:
			if cid_of[local] != want:
				continue
			var left: int = counts[local]
			while left > 0:
				var k := mini(30, left)
				var col: int = 4 if POCKET_CIDS.has(want) else rr % lanes
				if not POCKET_CIDS.has(want):
					rr += 1
				cols[col].append({"batchId": "R3B%04d" % n, "cid": want, "robots": k})
				left -= k
				n += 1
	return {"schema": SupplyPlanLoader.SCHEMA, "version": 1, "levelId": level["id"], "columnCount": 5, "visiblePreviewDepth": 3,
		"maxRobotsPerBatch": 30, "intendedColumnClicks": [], "columns": cols}

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)
