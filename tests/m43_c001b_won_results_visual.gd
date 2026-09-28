extends SceneTree
## M43-C001B — WON Results visual binding evidence (OWNER_RESULTS_VISUAL_REPLAY_V01).
## Production path: real main.tscn root, real AppState, real host terminal commit, real
## ResultsScreen. Expected/completed case ledger.
##
## Run: godot --headless --path . -s res://tests/m43_c001b_won_results_visual.gd

const NavigationController = preload("res://scripts/app/navigation_controller.gd")
const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const AppState = preload("res://scripts/app/app_state.gd")
const FirstClearTransaction = preload("res://scripts/economy/first_clear_transaction.gd")
const TerminalRewardReceipt = preload("res://scripts/economy/terminal_reward_receipt.gd")
const ResultsScreen = preload("res://scripts/ui/results_screen.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")
const ScrubbotAgent = preload("res://scripts/gameplay/agents/scrubbot_agent.gd")

const R := NavigationController.Route

## SHA-256 of every approved art file the Results screen binds (unchanged by C001B).
const ART_SHA := {
	"res://assets/ui/final/popups/victory/victory_scrubby_pose.png": "2f96af7a61a1e4a37dcf4434ef55a7c70da2fe9667edb6ad0b675bf1e78a3733",
	"res://assets/ui/final/popups/victory/victory_emblem.png": "91c9a41e5fb0909c322a29a5535c44911628a49c4b77eaf52d0b4f7b143efdfe",
	"res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png": "a843e21f429b28f2f2c91e9b5015efee7312e96e9112ce616947035dff68a8ef",
	"res://assets/ui/final/home/reward_track/win_streak_reward_badge.png": "52304ff7cb6a1ed276f8139a76dfed3dec1b84de7ee1b5daa9ce7c1b1fb44812",
	"res://assets/ui/final/robots/bot_parts_icon.png": "7a0dcf3f81d3b9ef4c0080839a5b5f8cca503afb979ade513eb6f0b52ce552ae",
	"res://assets/ui/final/home/gift_meter/gift_meter_emblem.png": "0ba66f7b48f72b19c8bf4d402ae57553f8f13079728ffe37c66a5aef3e0d3917",
	"res://assets/ui/final/rewards/card_pack_standard.png": "25685b379f7a93b30ebd1931d34fdb77980daa42ea7cf436642b1d4872dba6d2",
	"res://assets/ui/final/rewards/gift_box.png": "17b1f73e9e2ae804d96ecf9fd5623222ccc62462de053bf86d15069dae975415",
}

var EXPECTED_CASES := [
	"won_composition_bound", "rows_match_receipt_order", "reveal_presentation_only",
	"reduced_effects_static", "no_replay", "lost_no_victory_art", "level10_unavailable_visual",
	"continue_once_visual", "hide_show_no_leak", "responsive_fit", "art_and_manifest_governance",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	await _won_composition_bound()
	await _rows_match_receipt_order()
	await _reveal_presentation_only()
	await _reduced_effects_static()
	_no_replay()
	await _lost_no_victory_art()
	await _level10_unavailable_visual()
	await _continue_once_visual()
	await _hide_show_no_leak()
	await _responsive_fit()
	_art_and_manifest_governance()
	_cleanup()
	_done()

## Owner B1-A / B2-A: robot over frame, small emblem in header, green CTA, live text.
func _won_composition_bound() -> void:
	print("[WON composition bound]")
	var root = await _boot_main(_uniq("comp"))
	var h = await _play(root)
	_drain(h)
	var res = root.get_results_screen()
	await _frames(3)
	res.finish_reveal()
	_ok(res.visible and res.is_victory_layout(), "WON -> Victory layout")
	var robot: TextureRect = res.get_robot()
	var emblem: TextureRect = res.get_emblem()
	_ok(robot.is_visible_in_tree() and robot.texture != null and robot.texture.resource_path == ResultsScreen.ROBOT_ART, "Scrubby victory pose bound (safe default robot)")
	_ok(emblem.is_visible_in_tree() and emblem.texture != null and emblem.texture.resource_path == ResultsScreen.EMBLEM_ART, "Victory emblem bound")
	var header: Control = res.get_panel().find_child("Header", true, false)
	_ok(header != null and header.is_ancestor_of(emblem), "emblem lives in the header")
	_ok(emblem.size.x <= ResultsScreen.EMBLEM_SIZE + 1 and emblem.size.x < res.get_panel().size.x * 0.2, "emblem is small (%d px)" % int(emblem.size.x))
	var rr := robot.get_global_rect()
	var pr: Rect2 = res.get_panel().get_global_rect()
	_ok(rr.position.y < pr.position.y and rr.end.y > pr.position.y and robot.z_index > 0, "robot sits above and overlaps the frame top (robot %s, frame top %d)" % [str(rr), int(pr.position.y)])
	var frame := res.get_panel().get_theme_stylebox("panel") as StyleBoxFlat
	_ok(frame != null and frame.bg_color == ResultsScreen.CREAM and frame.border_color == ResultsScreen.ROYAL, "warm cream frame with royal-blue rim (Life/Help family)")
	var cta := res.get_primary_button().get_theme_stylebox("normal") as StyleBoxFlat
	_ok(cta != null and cta.bg_color == HomeStyle.GREEN, "Continue uses the green Life/Help-family CTA")
	_ok(res.get_home_button().size.y < res.get_primary_button().size.y and (res.get_home_button().get_theme_stylebox("normal") as StyleBoxFlat).bg_color != HomeStyle.GREEN, "Home is visually subordinate")
	_ok(res.get_primary_button().text == UiText.t("RESULTS_CONTINUE") and res.get_panel().find_child("Title", true, false).text == UiText.t("RESULTS_WON") and res.get_panel().find_child("LevelLabel", true, false).text == UiText.t("RESULTS_LEVEL", [1]), "title / level / CTA are live UiText")
	_shutdown(root)
	_complete("won_composition_bound")

## Rows come only from the committed receipt, in locked order, each with its approved icon.
func _rows_match_receipt_order() -> void:
	print("[rows match receipt order]")
	var root = await _boot_main(_uniq("rows"))
	var app = root.get_app_state()
	app.economy.gift.add_streak_sb("c001b_seed", 9)   # Level 1 streak SB crosses milestone 10
	var h = await _play(root)
	_drain(h)
	var res = root.get_results_screen()
	var rc: Dictionary = h.get_terminal_receipt()
	var rows: Array = _rows(res)
	var kinds: Array = rows.map(func(c): return c.get_meta("kind"))
	var want: Array = rc["reveal_queue"].map(func(e): return e["kind"])
	want.append("gift_milestone")
	_ok(kinds == want and want == ["first_clear_sb", "win_streak_sb", "bot_parts", "gift_meter", "gift_milestone"], "row order = committed reveal_queue + gift follow-up %s" % str(kinds))
	_ok(res.shown_row_texts() == ResultsScreen.reward_lines(rc), "row texts = receipt lines")
	var icons_ok := true
	for i in range(rows.size()):
		var spec: Dictionary = ResultsScreen.reward_rows(rc)[i]
		var icon: TextureRect = rows[i].find_child("Icon", true, false)
		icons_ok = icons_ok and icon != null and icon.texture != null and icon.texture.resource_path == ResultsScreen.ICON_ART[spec["icon"]]
	_ok(icons_ok, "each row shows its existing approved icon")
	_ok(ResultsScreen.reward_rows({}).is_empty() and ResultsScreen.reward_rows({"reveal_queue": [{"kind": "invented_reward", "amount": 5}]}).is_empty(), "nothing outside the receipt vocabulary becomes a row")
	_shutdown(root)
	_complete("rows_match_receipt_order")

## Ordered reveal is presentation only: no grant, Continue live mid-reveal, refresh safe.
func _reveal_presentation_only() -> void:
	print("[reveal presentation only]")
	var root = await _boot_main(_uniq("rev"))
	var app = root.get_app_state()
	var nav = root.get_navigation()
	var h = await _play(root)
	_drain(h)
	var res = root.get_results_screen()
	var rows: Array = _rows(res)
	_ok(res.is_revealing() and rows.size() == 4 and rows[3].modulate.a < 1.0, "normal effects: ordered reveal running, later rows still hidden")
	var e0: Dictionary = _econ(app.economy)
	var tx0: int = app.economy.reward.applied_transaction_count()
	await _frames(2)
	_ok(rows[0].modulate.a >= rows[3].modulate.a, "earlier row reveals no later than a later row")
	for _i in range(5):
		res.show_model(root._results_model(nav.last_payload()))
	res.finish_reveal()
	var all_on := true
	for c in _rows(res):
		all_on = all_on and c.modulate.a == 1.0
	_ok(all_on and not res.is_revealing() and _rows(res).size() == 4, "fast-forward shows every committed row; refresh keeps 4 rows")
	_ok(_econ(app.economy) == e0 and app.economy.reward.applied_transaction_count() == tx0, "reveal / refresh / fast-forward grant nothing")
	res.show_model(root._results_model(nav.last_payload()))
	_ok(res.is_revealing(), "reveal restarted")
	var t0: int = nav.transition_id()
	res.get_primary_button().pressed.emit()
	res.get_primary_button().pressed.emit()
	await process_frame
	_ok(nav.current() == R.GAMEPLAY and nav.transition_id() == t0 + 1 and _econ(app.economy) == e0, "Continue works mid-reveal, exactly once, no grant")
	_shutdown(root)
	_complete("reveal_presentation_only")

func _reduced_effects_static() -> void:
	print("[reduced effects static]")
	var root = await _boot_main(_uniq("rfx"))
	var app = root.get_app_state()
	app.set_reduced_effects(true)
	var h = await _play(root)
	_drain(h)
	var res = root.get_results_screen()
	var all_on := true
	for c in _rows(res):
		all_on = all_on and c.modulate.a == 1.0
	_ok(res.get_model()["reduced_effects"] and not res.is_revealing() and all_on and _rows(res).size() == 4, "Reduced Effects: all committed rows shown immediately, no sequence")
	_ok(res.is_victory_layout() and res.get_robot().texture != null, "Reduced Effects keeps the same composition")
	_shutdown(root)
	_complete("reduced_effects_static")

## Owner A1-NO: no Replay button, action, route or hidden affordance.
func _no_replay() -> void:
	print("[no replay]")
	var bad: Array = []
	for f in ["res://scripts/ui/results_screen.gd", "res://scripts/app/main.gd", "res://scripts/app/navigation_controller.gd", "res://scripts/ui/ui_text.gd", "res://scripts/app/gameplay_launch_resolver.gd"]:
		if _strip_comments(FileAccess.get_file_as_string(f)).to_lower().find("replay") != -1:
			bad.append(f)
	_ok(bad.is_empty(), "no replay code/copy in Results / app root / navigation / resolver %s" % str(bad))
	var names: Array = []
	for k in R:
		names.append(k)
	_ok(not names.has("REPLAY") and not UiText.EN.has("RESULTS_REPLAY"), "no REPLAY route / copy key")
	var res = ResultsScreen.new()
	var buttons: Array = res.find_children("*", "Button", true, false).map(func(b): return String(b.name))
	var sigs: Array = res.get_signal_list().map(func(s): return String(s["name"]))
	res.free()
	_ok(buttons == ["PrimaryButton", "HomeButton"], "Results has exactly Continue/Retry + Home buttons %s" % str(buttons))
	_ok(sigs.has("continue_requested") and sigs.has("retry_requested") and sigs.has("home_requested") and sigs.filter(func(s): return s.to_lower().find("replay") != -1).is_empty(), "no replay intent signal")
	_complete("no_replay")

## Owner B3-A: LOST uses no Victory art; Retry still works; clean WON<->LOST switching.
func _lost_no_victory_art() -> void:
	print("[LOST no victory art]")
	var root = await _boot_main(_uniq("lost"))
	var nav = root.get_navigation()
	var h = await _play(root)
	h.get_completion().terminal_reached.emit(&"LOST", {})
	var res = root.get_results_screen()
	_ok(not res.is_victory_layout() and not res.get_robot().is_visible_in_tree() and res.get_robot().texture == null, "LOST: no robot")
	_ok(not res.get_emblem().is_visible_in_tree() and res.get_emblem().texture == null and _rows(res).is_empty(), "LOST: no emblem, no reward celebration")
	_ok(res.theme == null and (res.get_panel().get_theme_stylebox("panel") as StyleBoxFlat).bg_color != ResultsScreen.CREAM, "LOST: technical fallback chrome, not the Victory frame")
	_ok(_textures(res).is_empty(), "LOST: no texture of any kind in Results")
	res.get_primary_button().pressed.emit()
	_ok(nav.current() == R.GAMEPLAY and nav.attempt_id() == 2 and root.get_gameplay_host() == h, "Retry still M30 same-host, attempt 2")
	_drain(h)
	_ok(res.is_victory_layout() and res.get_robot().texture != null, "later WON on the same screen gets the Victory layout")
	res.get_primary_button().pressed.emit()
	await process_frame
	var h2 = root.get_gameplay_host()
	h2.get_runtime().set_process(false)
	h2.get_completion().terminal_reached.emit(&"LOST", {})
	_ok(not res.is_victory_layout() and _textures(res).is_empty() and res.get_primary_button().text == UiText.t("RESULTS_RETRY"), "WON -> LOST switch leaves no Victory art behind")
	_shutdown(root)
	_complete("lost_no_victory_art")

func _level10_unavailable_visual() -> void:
	print("[level 10 unavailable visual]")
	var root = await _boot_main(_uniq("l10"))
	var app = root.get_app_state()
	var nav = root.get_navigation()
	app.progression.debug_set_current_level(10)
	var h = await _play(root)
	h.get_completion().terminal_reached.emit(&"WON", {})
	var res = root.get_results_screen()
	await _frames(2)
	var note: Label = res.get_note_label()
	_ok(res.is_victory_layout() and res.get_primary_button().disabled and note.is_visible_in_tree() and note.text == UiText.t("RESULTS_NEXT_UNAVAILABLE", [11]), "Level 10: Victory layout, Continue disabled, readable coming-soon note")
	_ok(res.get_panel().get_global_rect().encloses(note.get_global_rect()), "note sits inside the frame")
	var e0: Dictionary = _econ(app.economy)
	var t0: int = nav.transition_id()
	for _i in range(3):
		res.get_primary_button().pressed.emit()
	_ok(_econ(app.economy) == e0 and nav.transition_id() == t0 and nav.current() == R.RESULTS, "disabled Continue: no mutation, no transition")
	_shutdown(root)
	_complete("level10_unavailable_visual")

func _continue_once_visual() -> void:
	print("[continue once visual]")
	var root = await _boot_main(_uniq("once"))
	var nav = root.get_navigation()
	var h = await _play(root)
	_drain(h)
	var res = root.get_results_screen()
	var emitted := [0]
	res.continue_requested.connect(func(_a): emitted[0] += 1)
	var t0: int = nav.transition_id()
	for _i in range(10):
		res.get_primary_button().pressed.emit()
	await process_frame
	_ok(emitted[0] == 1 and nav.transition_id() == t0 + 1 and _hosts(root) == 1 and int(root.get_gameplay_host().progression_level) == 2, "10 taps on the styled CTA -> 1 Continue, Level 2")
	_shutdown(root)
	_complete("continue_once_visual")

## Hide/show cycles and repeated refreshes never accumulate nodes, tweens or connections.
func _hide_show_no_leak() -> void:
	print("[hide/show no leak]")
	var app = AppState.new(_uniq("leak"))
	var rc: Dictionary = _rich_receipt(app)
	var res = ResultsScreen.new()
	get_root().add_child(res)
	var model := {"status": "WON", "level": 10, "attempt": 1, "receipt": rc, "continue": {"available": true}}
	res.show_model(model)
	await _frames(2)
	var base := _count(res)
	var conns: int = res.get_primary_button().get_signal_connection_list("pressed").size()
	for i in range(20):
		res.visible = false
		res.visible = true
		res.show_model(model)
		if i % 3 == 0:
			res.show_model({"status": "LOST", "level": 10, "attempt": 1, "receipt": {}, "continue": {}})
			res.show_model(model)
	await _frames(3)
	_ok(_count(res) == base, "node count stable over 20 hide/show/refresh cycles (%d -> %d)" % [base, _count(res)])
	_ok(res.get_primary_button().get_signal_connection_list("pressed").size() == conns and res.get_home_button().get_signal_connection_list("pressed").size() == 1, "no signal connections accumulate")
	res.visible = false
	await _frames(2)
	_ok(res.get_reward_lines_node().get_child_count() == 0 and not res.is_revealing(), "hidden Results releases rows and stops the reveal")
	res.free()
	_complete("hide_show_no_leak")

## Representative portrait sizes: frame, robot, text and touch controls stay on screen.
func _responsive_fit() -> void:
	print("[responsive fit]")
	var app = AppState.new(_uniq("fit"))
	var rc: Dictionary = _rich_receipt(app)
	_ok(rc["reveal_queue"].size() == 4 and rc["follow_ups"].size() == 1, "rich receipt: 4 reveals + gift follow-up (worst-case height)")
	for size in [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1080, 2400), Vector2i(1215, 2160)]:
		var sub := SubViewport.new()
		sub.size = size
		sub.disable_3d = true
		get_root().add_child(sub)
		var res = ResultsScreen.new()
		sub.add_child(res)
		res.show_model({"status": "WON", "level": 10, "attempt": 1, "receipt": rc,
			"continue": {"available": false, "reason": "CONTENT_MISSING", "next_level": 11}, "reduced_effects": true})
		await _frames(3)
		var vp := Rect2(Vector2.ZERO, Vector2(size))
		var panel: Rect2 = res.get_panel().get_global_rect()
		var robot: Rect2 = res.get_robot().get_global_rect()
		var inside: bool = vp.grow(-16).encloses(panel) and vp.encloses(robot)
		var texts_ok := true
		for l in res.get_panel().find_children("*", "Label", true, false):
			if l.is_visible_in_tree():
				texts_ok = texts_ok and panel.encloses(l.get_global_rect())
		var touch_ok := true
		for b in [res.get_primary_button(), res.get_home_button()]:
			var br: Rect2 = b.get_global_rect()
			touch_ok = touch_ok and br.size.y >= UiTokens.TOUCH_MIN and br.size.x >= 300 and vp.encloses(br)
		_ok(inside and texts_ok and touch_ok, "%dx%d: frame %s + robot on screen, all text inside frame, touch targets >= %d px" % [size.x, size.y, str(panel), UiTokens.TOUCH_MIN])
		sub.queue_free()
	await process_frame
	_complete("responsive_fit")

func _art_and_manifest_governance() -> void:
	print("[art / manifest governance]")
	var changed: Array = []
	for p in ART_SHA:
		if FileAccess.get_sha256(p) != ART_SHA[p]:
			changed.append(p)
	_ok(changed.is_empty(), "bound approved art unchanged (sha256) %s" % str(changed))
	var bound: Array = [ResultsScreen.ROBOT_ART, ResultsScreen.EMBLEM_ART]
	bound.append_array(ResultsScreen.ICON_ART.values())
	_ok(bound.all(func(p): return String(p).begins_with("res://assets/ui/final/") and ART_SHA.has(p)), "Results binds only existing assets/ui/final art")
	_ok(not bound.has("res://assets/ui/final/popups/victory/continue_button_frame.png"), "cyan arrow continue_button_frame not used (owner B2-A)")
	var m = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/PLAYER_EXPERIENCE_ASSET_MANIFEST.json"))
	var status := ""
	for s in m["surfaces"]:
		if s["id"] == "victory_results":
			status = s["status"]
	_ok(status == "MASTER_REQUIRED", "victory_results not promoted to MASTER_OWNER_APPROVED (%s)" % status)
	_complete("art_and_manifest_governance")

# ---------------------------------------------------------------- helpers ----

## Real production commit on an isolated graph: Level 10 with streak 4 -> +100 streak SB,
## streak Bot Part, Gift 41 -> 141 (crosses 50).
func _rich_receipt(app) -> Dictionary:
	for n in [1, 2, 3, 4]:
		app.economy.streak.process_first_clear_win(n)
	app.progression.debug_set_current_level(10)
	var pre: Dictionary = TerminalRewardReceipt.capture(app.progression, app.economy)
	var commit: Dictionary = FirstClearTransaction.commit(app.progression, app.economy, 10)
	return TerminalRewardReceipt.build("WON", 10, pre, TerminalRewardReceipt.capture(app.progression, app.economy), commit, {"ok": true})

func _rows(res) -> Array:
	return res.get_reward_lines_node().get_children().filter(func(c): return not c.is_queued_for_deletion())

func _textures(res) -> Array:
	return res.find_children("*", "TextureRect", true, false).filter(func(t): return t.texture != null and t.is_visible_in_tree())

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

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

func _hosts(root) -> int:
	var n := 0
	for c in root.get_children():
		if String(c.name).begins_with("GameplayHost"):
			n += 1
	return n

func _strip_comments(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var i := line.find("#")
		out.append(line if i == -1 else line.substr(0, i))
	return "\n".join(out)

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
	var p := "user://m43c001b_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M43-C001B WON results visual evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
