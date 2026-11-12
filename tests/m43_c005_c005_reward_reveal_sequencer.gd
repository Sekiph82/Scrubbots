extends SceneTree
## M43-C005-C005 (SB-M43-063) — reusable production RevealSequencer + its win integration.
## s* cases drive the sequencer with dummy presentation controls (future-ceremony seam: no
## pack/card/robot assets bound). r* cases use the real main.tscn root, real AppState, real
## host terminal commit and the real Home reward flight (SB-PHONE-2026-11-12-E: a win goes
## Home; the WON Results and its row reveal are gone). Expected/completed case ledger.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c005_reward_reveal_sequencer.gd

const CharacterMotion = preload("res://scripts/ui/feel/character_motion.gd")
const RevealSequencer = preload("res://scripts/ui/components/reveal_sequencer.gd")
const HomeRewardFlight = preload("res://scripts/ui/home/home_reward_flight.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
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
	"r01_flight_plan", "r02_flight_authority_idempotency",
	"r03_flight_hide_lands_frees", "r04_flight_reduced_parity",
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
	print("[r01-r04 the Home reward flight on the shared sequencer]")
	var path := _uniq("fl")
	var root = await _boot_main(path)
	var app = root.get_app_state()
	var h = await _play(root)
	_drain(h)
	var rc: Dictionary = h.get_terminal_receipt()
	var home = root.get_home()
	var flight = home.get_reward_flight()
	var seq: RevealSequencer = flight._seq
	var steps: Array = seq.get_steps()
	var plan: Array = HomeRewardFlight.plan(rc, home.get_view_model())
	var shape := true
	for k in range(plan.size()):
		shape = shape and steps[3 * k]["property"] == "modulate:a" and steps[3 * k + 1]["property"] == "position" and steps[3 * k + 2]["property"] == "value" \
			and float(steps[3 * k + 2]["from"]) == float(plan[k]["from"]) and float(steps[3 * k + 2]["to"]) == float(plan[k]["to"])
	_ok(seq.is_running() and seq.current_key() == "win:a1:L1" and steps.size() == 3 * plan.size() and plan.size() == 4 and shape,
		"one key per win; per reward: fade, flight, count-up from the receipt (%d rewards)" % plan.size())
	_complete("r01_flight_plan")
	var e0 := _econ(app.economy)
	var tx0: int = app.economy.reward.applied_transaction_count()
	for _i in range(3):
		home.refresh()
		_ok(not home.play_reward_flight(rc, "win:a1:L1"), "same win key refused")
	var t0 := Time.get_ticks_msec()
	while seq.is_running() and Time.get_ticks_msec() - t0 < 10000:
		await process_frame
	_ok(not seq.is_active() and flight.get_layer() == null and _econ(app.economy) == e0 and app.economy.reward.applied_transaction_count() == tx0,
		"natural end: layer freed; refresh x3 + replays changed no economy / ledger")
	_complete("r02_flight_authority_idempotency")
	_shutdown(root)
	root = await _boot_main(_uniq("fl2"))
	h = await _play(root)
	_drain(h)
	home = root.get_home()
	flight = home.get_reward_flight()
	var tw0 := _tweens()
	_ok(flight.is_running() and flight.get_layer() != null, "second run flying")
	root.play_current_frontier()   # Home hides: the flight lands at once
	await _frames(2)
	_ok(not flight.is_running() and flight.get_layer() == null and _tweens() <= tw0, "Home hidden mid-flight: final state landed, layer freed, no tween left")
	_complete("r03_flight_hide_lands_frees")
	_shutdown(root)
	root = await _boot_main(_uniq("fl3"))
	root.get_app_state().set_reduced_effects(true)
	h = await _play(root)
	_drain(h)
	home = root.get_home()
	var chip: String = home.get_region("ScrubBucksChip").value_label.text
	_ok(not home.is_reward_flight_running() and home.get_reward_flight().has_played("win:a1:L1") and home.get_reward_flight().get_layer() == null
		and chip == UiText.num(root.get_app_state().economy.wallet.scrub_bucks()), "Reduced: the same key lands the final HUD at once (SB %s)" % chip)
	_complete("r04_flight_reduced_parity")
	_shutdown(root)

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

## SB-POLISH-011: the Results robot's own CharacterMotion tween is not reveal work.
func _tweens() -> int:
	return get_processed_tweens().filter(func(t): return t.is_valid() and not _is_motion(t)).size()

func _is_motion(t: Tween) -> bool:
	for res in get_root().find_children("ResultsScreen", "", true, false):
		if res.get_robot().get_meta(CharacterMotion.META, null) == t:
			return true
	return false

func _free(n: Node) -> void:
	if is_instance_valid(n):
		n.free()

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

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
