extends SceneTree
## M43-C005F-PHASE3 runtime evidence (NOT shipping): the REAL app (main.tscn) with the real
## plugins, at 1080x2160 and 1536x2048, FULL and REDUCED. Every moment is produced through its
## shipping seam (real Collection add_card -> CeremonyPresenter, real Gift Meter progress, real
## Tasks / Life popup buttons). Frames are taken mid-burst (FULL) and at rest. Needs a rendering
## driver (not --headless):
##   godot --path . -s res://tests/tools/c005f_phase3_capture.gd
## Output: coordination/sessions/M43-C005F-PHASE3/evidence/*.jpg at native resolution (JPEG keeps
## the evidence set light; .gdignore keeps it out of the Godot import) + feel log printed.

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const OUT := "res://coordination/sessions/M43-C005F-PHASE3/evidence"
const SIZES := [Vector2i(1080, 2160), Vector2i(1536, 2048)]

var _sub: SubViewport
var _root = null
var _tmp: Array = []
var _tag := ""

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var gi := FileAccess.open(OUT + "/.gdignore", FileAccess.WRITE)
	gi.close()
	_run.call_deferred()

func _run() -> void:
	await _boot(SIZES[0], false)   # warm-up (first app boot of a process runs one-time startup work)
	for size in SIZES:
		for reduced in [false, true]:
			_tag = "%dx%d_%s" % [size.x, size.y, "reduced" if reduced else "full"]
			await _set_complete(size, reduced)
			await _master(size, reduced)
			await _gift_milestone(size, reduced)
			await _scrubbox(size, reduced)
			await _heart(size, reduced)
	_shutdown()
	MainScript.boot_save_path_override = ""
	for p in _tmp:
		for s in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + s):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + s))
	quit(0)

func _set_complete(size: Vector2i, reduced: bool) -> void:
	await _boot(size, reduced)
	_complete_set(1)
	_root.request_home_ceremonies()
	await _burst_and_rest("01_set_complete")

func _master(size: Vector2i, reduced: bool) -> void:
	await _boot(size, reduced)
	for n in range(1, 16):
		_complete_set(n)
	var e = _root.get_app_state().economy
	for ev in CeremonyEvents.pending(e, e.meta_ui):
		if String(ev["kind"]) != "master_complete":
			e.meta_ui.mark_seen(String(ev["key"]))
	_root.request_home_ceremonies()
	await _burst_and_rest("02_master_collection")

func _gift_milestone(size: Vector2i, reduced: bool) -> void:
	await _boot(size, reduced)
	var e = _root.get_app_state().economy
	e.gift.add_streak_sb("streak:evidence:p3", 10)
	_root.request_home_ceremonies()
	await _burst_and_rest("03_gift_milestone_10")
	_top().close("action:continue")
	await _frames(4)
	e.gift.add_streak_sb("streak:evidence:p3b", 990)
	_root.request_home_ceremonies()
	await _frames(3)
	for _i in range(4):   # 50 / 250 / 500 first, then the cycle-max 1000
		if _top() == null or int(_top().get_meta("event", {}).get("milestone", 0)) == 1000:
			break
		_top().close("action:continue")
		await _frames(4)
	await _burst_and_rest("04_gift_milestone_1000_cycle_max", false)

func _scrubbox(size: Vector2i, reduced: bool) -> void:
	await _boot(size, reduced)
	var e = _root.get_app_state().economy
	for i in range(3):
		e.daily.mark_task_done(i)
	_root._on_home_shortcut("tasks")
	await create_timer(0.5).timeout
	_top().get_action_button("task:0").pressed.emit()
	await _burst_and_rest("05_task_claim_small", false)
	await create_timer(0.3).timeout
	for i in [1, 2]:
		_top().get_action_button("task:%d" % i).pressed.emit()
		await create_timer(0.5).timeout
	_top().get_action_button("scrubbox").pressed.emit()
	await _burst_and_rest("06_earned_scrubbox", false)

func _heart(size: Vector2i, reduced: bool) -> void:
	await _boot(size, reduced)
	var e = _root.get_app_state().economy
	e.wallet.credit("scrub_bucks", 2000)
	e.hearts.consume()
	e.hearts.consume()
	var p = _root.open_life("evidence")
	await create_timer(0.5).timeout
	p.get_action_button("heart_plus_one").pressed.emit()
	await _burst_and_rest("07_heart_plus_one_success", false)
	e.wallet.debit("scrub_bucks", e.wallet.scrub_bucks())
	await create_timer(1.1).timeout
	var n: int = _root.get_meta_reward_feel().feel_log().size()
	p.get_action_button("heart_plus_one").pressed.emit()
	await create_timer(0.4).timeout
	await _shot("08_heart_insufficient_no_success_feel")
	print("%s 08 insufficient: last=%s feel_requests %d -> %d" % [_tag, _root.get_acquisition().last_result.get("reason", ""), n, _root.get_meta_reward_feel().feel_log().size()])

## FULL: one frame mid-burst; REDUCED: the static final state. Plus the feel log line.
func _burst_and_rest(name: String, _settle_first: bool = true) -> void:
	# Wait for the coordinator's actual feel request (it waits for the popup layout to settle).
	var n0: int = _root.get_meta_reward_feel().feel_log().size()
	for _i in range(40):
		if _root.get_meta_reward_feel().feel_log().size() > n0:
			break
		await process_frame
	if not _root.get_app_state().effects.is_reduced():
		await create_timer(0.1).timeout   # burst mid-flight
		await _shot(name + "_burst")
	else:
		await create_timer(0.9).timeout
		await _shot(name + "_static")
	var log: Array = _root.get_meta_reward_feel().feel_log()
	print("%s %s top=%s feel=%s" % [_tag, name, _top().popup_id if _top() != null else "-", str(log.back() if not log.is_empty() else [])])

func _complete_set(n: int) -> void:
	var c = _root.get_app_state().economy.collection
	for k in range(9):
		var cid := "s%d_c%d" % [n, k]
		if c.owned(cid) == 0:
			c.add_card(cid)

func _boot(size: Vector2i, reduced: bool) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	var p := "user://c005f_p3_capture_%d.save" % Time.get_ticks_usec()
	_tmp.append(p)
	MainScript.boot_save_path_override = p
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(8)
	_root.get_app_state().set_reduced_effects(reduced)
	await _frames(2)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _top():
	return _root.get_modal_stack().top()

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	_sub.get_texture().get_image().save_jpg(ProjectSettings.globalize_path("%s/%s_%s.jpg" % [OUT, _tag, name]), 0.88)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
