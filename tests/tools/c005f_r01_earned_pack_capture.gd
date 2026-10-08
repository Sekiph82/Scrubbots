extends SceneTree
## M43-C005F-PHASE2-R01 runtime evidence (NOT shipping): the REAL app (main.tscn) in a 1080x2160
## SubViewport with the real plugins. Real Gift Meter progress -> Gift Bar CLAIM -> the production
## PackPresenter opens the shipping Standard (Gift 10) / Premium (Gift 1000) ceremony -> real taps
## -> back on the Gift Bar -> Collection album. Needs a rendering driver (not --headless):
##   godot --path . -s res://tests/tools/c005f_r01_earned_pack_capture.gd
## Output: coordination/sessions/M43-C005F-PHASE2-R01/evidence/*.png (+ counts printed).

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const OUT := "res://coordination/sessions/M43-C005F-PHASE2-R01/evidence"

var _sub: SubViewport
var _root = null
var _tmp := ""

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_run.call_deferred()

func _run() -> void:
	await _boot()   # warm-up boot (first app boot of a process runs one-time startup work)
	_root.free()
	_sub.free()
	await _boot()
	var e = _root.get_app_state().economy
	var occ: Array = e.gift.add_streak_sb("streak:evidence:1", 1000)
	_root.get_app_state().request_save()
	var ids := {}
	for o in occ:
		ids[int(o["milestone"])] = String(o["id"])
	await _route(e, ids[10], "01_gift10")
	await _route(e, ids[1000], "02_gift1000")
	# Collection album after both openings (live counts).
	for _i in range(8):   # close the Gift Bar, then any queued meta ceremony (e.g. Gift milestone)
		if _top() == null:
			break
		_top().close("action:continue" if String(_top().popup_id).begins_with("ceremony_") else "test")
		await _frames(4)
	_root._on_home_shortcut("collection")
	await create_timer(0.6).timeout
	await _shot("03_collection_after_both_packs")
	print("FINAL owned_total=%d pending=%d receipts=%d" % [_owned(e), e.pending_packs.size(), e.pack_receipts.size()])
	_root.free()
	_sub.free()
	MainScript.boot_save_path_override = ""
	for s in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_tmp + s):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_tmp + s))
	quit(0)

func _route(e, occ_id: String, tag: String) -> void:
	if _top() == null or String(_top().popup_id) != "gift_bar":
		_root._on_home_shortcut("gift_bar")
	await create_timer(0.6).timeout
	var owned0 := _owned(e)
	await _shot(tag + "_a_gift_bar_before_claim")
	_top().get_action_button("gift:" + occ_id).pressed.emit()
	await _frames(3)
	var p = _top()
	print("%s claimed: top=%s pending=%d owned %d -> %d" % [tag, p.popup_id, e.pending_packs.size(), owned0, _owned(e)])
	await create_timer(0.3).timeout
	await _shot(tag + "_b_pack_screen_opened_automatically")
	p.tap()
	for _i in range(1500):
		if p.phase() == "AWAIT_ROUTE":
			break
		await process_frame
	await create_timer(0.4).timeout
	await _shot(tag + "_c_cards_revealed")
	var model: Dictionary = p.get_model()
	p.tap()
	for _i in range(1500):
		if not is_instance_valid(p) or p.is_closed():
			break
		await process_frame
	await create_timer(0.5).timeout
	await _shot(tag + "_d_after_completion_back_on_gift_bar")
	print("%s cards=%s owned_after=%d pending=%d" % [tag, str(model["cards"].map(func(c): return [c["card_id"], c["rarity"], c["is_new"], c["copies_after"]])), _owned(e), e.pending_packs.size()])

func _boot() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	_sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(_sub)
	_tmp = "user://c005f_r01_capture_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = _tmp
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(8)

func _top():
	return _root.get_modal_stack().top()

func _owned(e) -> int:
	var n := 0
	var o: Dictionary = e.collection.snapshot()["owned"]
	for k in o:
		n += int(o[k])
	return n

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	_sub.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, name]))

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
