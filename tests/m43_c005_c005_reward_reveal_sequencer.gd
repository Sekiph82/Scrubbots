extends SceneTree
## M43-C005-C005 (SB-M43-063) — reusable production RevealSequencer + Results integration.
## s* cases drive the sequencer with dummy presentation controls (future-ceremony seam: no
## pack/card/robot assets bound). r* cases use the real main.tscn root, real AppState, real
## host terminal commit and the real ResultsScreen. Expected/completed case ledger.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c005_reward_reveal_sequencer.gd

const RevealSequencer = preload("res://scripts/ui/components/reveal_sequencer.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const STEP := 0.05
## Identifiers that would mean the sequencer reaches gameplay/economy/save/navigation truth.
const FORBIDDEN := ["RewardGrant", "CardPack", "CollectionInventory", "RobotUnlock", "GiftMeter",
	"Economy", "economy", "Wallet", "AppState", "Navigation", "navigation", "save", "Save",
	"grant", "claim", "unlock", "equip", "preload", "load", "get_tree", "change_scene", "ads", "iap", "IAP"]

var EXPECTED_CASES := [
	"s01_three_and_five_steps", "s02_fast_forward_any_step", "s03_reduced_parity",
	"s04_cancel_restart_new_key", "s05_one_shot_key", "s06_empty_and_invalid",
	"s07_cleanup_no_accumulation", "s08_no_authority_source",
	"r01_results_plan_equivalence", "r02_results_authority_idempotency",
	"r03_results_hide_free_kills", "r04_results_reduced_parity",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _done_keys: Array = []

func _initialize() -> void:
	await process_frame
	await _s01_three_and_five_steps()
	await _s02_fast_forward_any_step()
	await _s03_reduced_parity()
	await _s04_cancel_restart_new_key()
	await _s05_one_shot_key()
	await _s06_empty_and_invalid()
	await _s07_cleanup_no_accumulation()
	_s08_no_authority_source()
	await _results_cases()
	_cleanup()
	_done()

# ------------------------------------------------------------ sequencer (dummy) ----

func _s01_three_and_five_steps() -> void:
	print("[s01 3-step and 5-step ordered sequences]")
	for n in [3, 5]:
		var h := _host(n)
		var seq := _seq(h)
		var steps := _fades(h, n)
		if n == 5:
			steps[2]["delay"] = 0.03
			steps[4]["delay"] = 0.03
		var key := "k%d" % n
		var seen: Array = []
		seq.step_started.connect(func(k, i): seen.append([k, i]))
		_ok(seq.play(key, steps) and seq.is_running() and _alphas(h) == _fill(n, 0.0), "%d steps: starts from the hidden state and runs" % n)
		var ordered := true
		for _i in range(600):
			var a := _alphas(h)
			for i in range(n):
				for j in range(i + 1, n):
					ordered = ordered and (a[j] == 0.0 or a[i] == 1.0)
			if not seq.is_active():
				break
			await process_frame
		_ok(ordered, "%d steps: a later step never starts before the earlier one is final" % n)
		_ok(seen == range(n).map(func(i): return [key, i]), "%d steps: each step started once, strictly in order %s" % [n, str(seen)])
		_ok(_alphas(h) == _fill(n, 1.0) and _done_keys == [key], "%d steps: exact final state, completed once" % n)
		await _frames(5)
		_ok(_done_keys == [key] and _tweens() == 0, "%d steps: no late duplicate completion, no tween left" % n)
		_free(h)
	_complete("s01_three_and_five_steps")

func _s02_fast_forward_any_step() -> void:
	print("[s02 fast-forward from step 0 / middle / final]")
	for at in [0, 2, 4]:
		var h := _host(5)
		var seq := _seq(h)
		seq.play("ff%d" % at, _fades(h, 5))
		for _i in range(600):
			if seq.current_step() >= at:
				break
			await process_frame
		var before := _alphas(h)
		_ok(seq.is_running() and before.min() < 1.0, "step %d: mid-sequence, not yet final (%s)" % [at, str(before)])
		seq.finish()
		_ok(_alphas(h) == _fill(5, 1.0) and not seq.is_running() and not seq.is_active(), "step %d: finish() lands the exact final state" % at)
		seq.finish()
		await _frames(10)
		_ok(_done_keys == ["ff%d" % at] and _tweens() == 0 and _alphas(h) == _fill(5, 1.0), "step %d: completion exactly once, killed tween never fires late" % at)
		_free(h)
	_complete("s02_fast_forward_any_step")

## Reduced Effects lands the same final information as the full run, at once.
func _s03_reduced_parity() -> void:
	print("[s03 Reduced Effects parity]")
	var full := _host(3)
	var seq := _seq(full)
	seq.play("full", _mixed(full))
	for _i in range(600):
		if not seq.is_active():
			break
		await process_frame
	var full_final := _props(full)
	var red := _host(3)
	var seq2 := _seq(red)
	var tw0 := _tweens()
	var ok := seq2.play("reduced", _mixed(red), true)
	_ok(ok and _props(red) == full_final and _done_keys == ["reduced"], "Reduced: final state immediately, equal to the full run %s" % str(full_final))
	_ok(not seq2.is_running() and _tweens() == tw0, "Reduced: no tween created")
	# Sensitivity: the comparator sees a non-final state as different.
	(red.get_child(1) as Control).modulate.a = 0.5
	_ok(_props(red) != full_final, "sensitivity: a non-final visual differs from the final state")
	_free(full)
	_free(red)
	_complete("s03_reduced_parity")

func _s04_cancel_restart_new_key() -> void:
	print("[s04 cancel / restart / new key]")
	var h := _host(3)
	var seq := _seq(h)
	seq.play("c1", _fades(h, 3))
	await _frames(2)
	seq.cancel()
	await _frames(20)
	_ok(_done_keys.is_empty() and not seq.is_running() and _tweens() == 0, "cancel: no completion, no tween")
	_ok(not seq.play("c1", _fades(h, 3)), "cancelled key cannot replay")
	_ok(seq.play("c2", _fades(h, 3)), "a new key runs after cancel")
	await _frames(2)
	_ok(seq.play("c3", _fades(h, 3)) and seq.current_key() == "c3", "restart with a new key mid-run")
	for _i in range(600):
		if not seq.is_active():
			break
		await process_frame
	await _frames(10)
	_ok(_done_keys == ["c3"] and _alphas(h) == _fill(3, 1.0) and _tweens() == 0, "only the live key completes; superseded c2 never completes %s" % str(_done_keys))
	_free(h)
	_complete("s04_cancel_restart_new_key")

func _s05_one_shot_key() -> void:
	print("[s05 one-shot key]")
	var h := _host(3)
	var seq := _seq(h)
	seq.play("once", _fades(h, 3))
	seq.finish()
	for c in h.get_children():
		c.modulate.a = 0.5
	_ok(not seq.play("once", _fades(h, 3)) and _alphas(h) == _fill(3, 0.5) and _done_keys == ["once"], "same key refused: no restart, no re-applied state, no second completion")
	_ok(not seq.play("", _fades(h, 3)) and seq.has_played("once") and not seq.has_played("other"), "empty key refused; ledger per key")
	_ok(seq.play("other", _fades(h, 3)), "a genuinely new key runs")
	seq.finish()
	_ok(_done_keys == ["once", "other"], "each key completes exactly once")
	_free(h)
	_complete("s05_one_shot_key")

func _s06_empty_and_invalid() -> void:
	print("[s06 empty / invalid / idle]")
	var h := _host(0)
	var seq := _seq(h)
	seq.finish()
	seq.cancel()
	_ok(_done_keys.is_empty(), "finish/cancel while idle: no-op")
	_ok(seq.play("empty", []) and _done_keys == ["empty"] and not seq.is_running() and _tweens() == 0, "empty sequence: completes once immediately, no tween")
	var gone := ColorRect.new()
	gone.free()
	_ok(seq.play("freed", [{"target": gone, "property": "modulate:a", "from": 0.0, "to": 1.0, "duration": STEP}]) and _done_keys == ["empty", "freed"] and _tweens() == 0, "freed target is dropped safely")
	var off := Control.new()   # host outside the tree: cannot tween -> final state at once
	off.add_child(ColorRect.new())
	var seq2 := RevealSequencer.new(off)
	seq2.completed.connect(func(k): _done_keys.append(k))
	_ok(seq2.play("off", [RevealSequencer.fade(off.get_child(0), STEP)]) and (off.get_child(0) as Control).modulate.a == 1.0 and _done_keys.back() == "off", "host outside the tree: final state immediately")
	off.free()
	_free(h)
	_complete("s06_empty_and_invalid")

func _s07_cleanup_no_accumulation() -> void:
	print("[s07 cleanup / no accumulation]")
	var h := _host(5)
	var seq := _seq(h)
	var nodes := _count(h)
	var conns := seq.get_signal_connection_list("completed").size()
	for i in range(60):
		seq.play("loop%d" % i, _fades(h, 5))
		if i % 3 == 0:
			await process_frame
		if i % 3 == 1:
			seq.finish()
		elif i % 3 == 2:
			seq.cancel()
	seq.cancel()
	await _frames(3)
	_ok(_tweens() == 0 and _count(h) == nodes and seq.get_signal_connection_list("completed").size() == conns, "60 play/finish/cancel cycles: no tween, node or connection accumulation")
	# Freeing the host kills its presentation work; nothing completes afterwards.
	var n_done := _done_keys.size()
	seq.play("freed_host", _fades(h, 5))
	await _frames(2)
	_ok(_tweens() == 1, "one tween while running")
	_free(h)
	await _frames(10)
	_ok(_tweens() == 0 and _done_keys.size() == n_done, "freed host: tween gone, no completion")
	_complete("s07_cleanup_no_accumulation")

## Static authority guard: the sequencer source references no economy / progression /
## save / navigation / gameplay identifier and owns no nodes.
func _s08_no_authority_source() -> void:
	print("[s08 zero authority (source)]")
	var src := _code_only(FileAccess.get_file_as_string("res://scripts/ui/components/reveal_sequencer.gd"))
	_ok(_forbidden_hits(src).is_empty(), "sequencer source has no authority identifiers %s" % str(_forbidden_hits(src)))
	_ok(_forbidden_hits(src + "\n\tRewardGrantService.grant(x)\n").size() >= 2, "sensitivity: the scan flags an injected grant call")
	var sc: Script = RevealSequencer
	var signals: Array = sc.get_script_signal_list().map(func(s): return s["name"])
	_ok(sc.get_instance_base_type() == &"RefCounted" and signals == ["completed", "step_started"], "RefCounted (owns no nodes); presentation signals only %s" % str(signals))
	_complete("s08_no_authority_source")

# ------------------------------------------------------------ Results (real) ----

func _results_cases() -> void:
	var path := _uniq("res")
	var root = await _boot_main(path)
	var app = root.get_app_state()
	var nav = root.get_navigation()
	app.economy.gift.add_streak_sb("c005c005_seed", 9)   # Level 1 also yields the gift follow-up row
	var h = await _play(root)
	_drain(h)
	var res = root.get_results_screen()
	var seq = res.get_reveal_sequencer()
	var model: Dictionary = root._results_model(nav.last_payload())
	await _r01_plan(res, seq, h)
	await _r02_authority(root, app, nav, h, res, seq, model, path)
	await _r03_hide_free(res, model)
	await _r04_reduced(model)
	_shutdown(root)

## The refactor keeps the approved timing family: one 0.16 s fade per committed row in
## receipt order, then the momentum section after its configured delay.
func _r01_plan(res, seq, h) -> void:
	print("[r01 Results plan equivalence]")
	var rows := _rows(res)
	var steps: Array = seq.get_steps()
	var rc: Dictionary = h.get_terminal_receipt()
	var delay := float(res.get_model()["momentum"]["reveal_delay_s"])
	_ok(res.is_revealing() and res.get_momentum_section().visible and rows.size() == 5 and steps.size() == 6, "WON level 1: 5 committed rows + momentum = 6 steps (%d)" % steps.size())
	var plan_ok := true
	for i in range(rows.size()):
		plan_ok = plan_ok and steps[i]["target"] == rows[i] and steps[i]["property"] == "modulate:a" and steps[i]["duration"] == ResultsScreen.REVEAL_STEP_S and steps[i]["delay"] == 0.0
	_ok(plan_ok and ResultsScreen.REVEAL_STEP_S == 0.16, "rows: one 0.16 s fade each, in display order")
	_ok(steps[5]["target"] == res.get_momentum_section() and steps[5]["duration"] == 0.16 and steps[5]["delay"] == delay and delay == 0.2, "momentum follows after the configured %.2f s delay" % delay)
	_ok(res.shown_row_texts() == ResultsScreen.reward_lines(rc), "rows = committed receipt lines, receipt order")
	_complete("r01_results_plan_equivalence")

func _r02_authority(root, app, nav, h, res, seq, model: Dictionary, path: String) -> void:
	print("[r02 Results authority / idempotency]")
	var counts := {}
	seq.completed.connect(func(k): counts[k] = int(counts.get(k, 0)) + 1)
	var e0: Dictionary = _econ(app.economy)
	var tx0: int = app.economy.reward.applied_transaction_count()
	var save0 := FileAccess.get_file_as_bytes(path)
	var rc0: Dictionary = h.get_terminal_receipt().duplicate(true)
	var route0: int = nav.current()
	var tid0: int = nav.transition_id()
	var lines0: Array = res.shown_row_texts()
	var stable := true
	for i in range(6):
		res.show_model(model)
		stable = stable and res.shown_row_texts() == lines0 and _rows(res).size() == 5
		if i % 2 == 0:
			res.finish_reveal()
		await process_frame
	seq.finish()
	seq.cancel()
	seq.play("probe_empty", [])
	res.show_model(model)
	await _frames(40)   # let the last reveal end naturally
	res.finish_reveal()
	_ok(stable and res.shown_row_texts() == lines0 and _rows(res).size() == 5, "repeated show_model: exact reward text/order, no row accumulation")
	var once := true
	for k in counts:
		once = once and counts[k] == 1
	_ok(once and not counts.is_empty(), "every presentation key completed at most once %s" % str(counts))
	_ok(_econ(app.economy) == e0 and app.economy.reward.applied_transaction_count() == tx0, "start/restart/finish/cancel: economy snapshot and applied grants unchanged")
	_ok(FileAccess.get_file_as_bytes(path) == save0 and save0.size() > 0, "save file bytes unchanged (%d bytes)" % save0.size())
	_ok(h.get_terminal_receipt() == rc0 and nav.current() == route0 and nav.transition_id() == tid0, "committed receipt, route and transition id unchanged")
	# Sensitivity: a real grant IS detected by the same comparator.
	app.economy.gift.add_streak_sb("c005c005_sensitivity", 1)
	_ok(_econ(app.economy) != e0, "sensitivity: a real economy mutation is detected")
	_complete("r02_results_authority_idempotency")

func _r03_hide_free(res, model: Dictionary) -> void:
	print("[r03 hide / free kills presentation work]")
	var b := _tweens()   # the real root may own unrelated tweens; count relative to it
	res.show_model(model)
	_ok(res.is_revealing() and _tweens() == b + 1, "reveal running (1 tween)")
	res.visible = false
	await process_frame
	_ok(not res.is_revealing() and _tweens() == b and res.get_reward_lines_node().get_child_count() == 0 and res.get_momentum_section().modulate.a == 1.0, "hidden Results: reveal cancelled, rows released, momentum not left hidden")
	res.visible = true
	res.show_model(model)
	res.finish_reveal()
	var lone = ResultsScreen.new()
	get_root().add_child(lone)
	var done := []
	lone.get_reveal_sequencer().completed.connect(func(k): done.append(k))
	lone.show_model(model)
	_ok(lone.is_revealing() and _tweens() == b + 1, "standalone Results revealing")
	lone.free()
	await _frames(10)
	_ok(_tweens() == b and done.is_empty(), "freed Results: tween gone, no completion")
	_complete("r03_results_hide_free_kills")

func _r04_reduced(model: Dictionary) -> void:
	print("[r04 Results Reduced Effects parity]")
	var full = _lone(model, false)
	var mid := _info(full)
	full.finish_reveal()
	var final_full := _info(full)
	var red = _lone(model, true)
	_ok(not red.is_revealing() and _info(red) == final_full, "Reduced: immediate final information == FULL final %s" % str(final_full["alphas"]))
	_ok(mid != final_full, "sensitivity: mid-reveal information differs from final")
	full.free()
	red.free()
	_complete("r04_results_reduced_parity")

func _lone(model: Dictionary, reduced: bool):
	var m := model.duplicate(true)
	m["reduced_effects"] = reduced
	var r = ResultsScreen.new()
	get_root().add_child(r)
	r.show_model(m)
	return r

func _info(r) -> Dictionary:
	return {
		"kinds": _rows(r).map(func(c): return c.get_meta("kind")),
		"texts": r.shown_row_texts(),
		"alphas": _rows(r).map(func(c): return c.modulate.a),
		"momentum": [r.get_momentum_section().visible, r.get_momentum_section().modulate.a, r.get_next_cleanup_panel().visible],
		"teaser": r.get_teaser_image().texture != null,
		"primary": [r.get_primary_button().text, r.get_primary_button().disabled],
		"note": r.get_note_label().text,
	}

# ------------------------------------------------------------ helpers ----

func _host(n: int) -> Control:
	var h := Control.new()
	get_root().add_child(h)
	for i in range(n):
		var c := ColorRect.new()
		c.name = "Dummy%d" % i
		h.add_child(c)
	return h

func _seq(h: Node) -> RevealSequencer:
	_done_keys = []
	var s := RevealSequencer.new(h)
	s.completed.connect(func(k): _done_keys.append(k))
	h.set_meta("seq", s)   # lifetime tied to the host, as in a real consumer
	return s

func _fades(h: Node, n: int) -> Array:
	var out: Array = []
	for i in range(n):
		out.append(RevealSequencer.fade(h.get_child(i), STEP))
	return out

func _mixed(h: Node) -> Array:
	return [
		RevealSequencer.fade(h.get_child(0), STEP),
		{"target": h.get_child(1), "property": "position:x", "from": 0.0, "to": 40.0, "duration": STEP},
		{"target": h.get_child(2), "property": "scale", "from": Vector2.ZERO, "to": Vector2.ONE, "duration": STEP, "delay": 0.02},
	]

func _props(h: Node) -> Array:
	return h.get_children().map(func(c): return [c.modulate.a, c.position.x, c.scale])

func _alphas(h: Node) -> Array:
	return h.get_children().map(func(c): return c.modulate.a)

func _fill(n: int, v: float) -> Array:
	var a: Array = []
	a.resize(n)
	a.fill(v)
	return a

func _tweens() -> int:
	return get_processed_tweens().filter(func(t): return t.is_valid()).size()

func _free(n: Node) -> void:
	if is_instance_valid(n):
		n.free()

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

func _rows(res) -> Array:
	return res.get_reward_lines_node().get_children().filter(func(c): return not c.is_queued_for_deletion())

func _code_only(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var i := line.find("#")
		out.append(line if i == -1 else line.substr(0, i))
	return "\n".join(out)

func _forbidden_hits(src: String) -> Array:
	var hits: Array = []
	for w in FORBIDDEN:
		var re := RegEx.create_from_string("(?<![A-Za-z_])" + w + "(?![a-z])")
		if re.search(src) != null:
			hits.append(w)
	return hits

func _econ(eco) -> Dictionary:
	var s: Dictionary = eco.snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	return s

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _play(root):
	root.play_current_frontier()
	await process_frame
	var h = root.get_gameplay_host()
	h.get_runtime().set_process(false)
	return h

func _drain(h) -> void:
	var supply = h.get_supply()
	var slots = h.get_slots()
	var input = h.get_input_controller()
	var runtime = h.get_runtime()
	var scheduler = h.get_scheduler()
	var agent_layer = h.get_agent_layer()
	for _i in range(80000):
		if slots.rightmost_empty_index() != -1:
			for col in range(supply.get_column_count()):
				if supply.get_front(col) != null:
					input.activate_front(col)
					break
		runtime.tick(1.0)
		if h.get_completion().is_terminal():
			break
		if supply.is_exhausted() and scheduler.live_assignment_count() == 0 and not _any_moving(agent_layer):
			runtime.tick(1.0)
			if h.get_completion().is_terminal():
				break
			runtime.tick(1.0)
			break

func _any_moving(agent_layer) -> bool:
	if agent_layer == null:
		return false
	for c in agent_layer.get_children():
		if c is ScrubbotAgent and c.is_moving():
			return true
	return false

func _boot_main(path: String):
	MainScript.boot_save_path_override = path
	var root = MainScene.instantiate()
	get_root().add_child(root)
	await process_frame
	return root

func _shutdown(root) -> void:
	if root != null and is_instance_valid(root):
		root.free()
	MainScript.boot_save_path_override = ""

func _uniq(tag: String) -> String:
	var p := "user://m43c005c005_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(case_id: String) -> void:
	_completed[case_id] = true

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete, missing %s" % str(missing))
	print("M43-C005-C005 reward reveal sequencer evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
