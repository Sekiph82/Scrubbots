extends SceneTree
## M43-C009 runtime evidence: Tasks / ScrubBox / Daily / Gift Bar in the real app root (opening
## skipped). Needs a rendering driver:
##   godot --path . -s res://tests/tools/daily_snapshot.gd -- <out_dir>

const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const DailyScreens = preload("res://scripts/ui/daily/daily_screens.gd")

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]

var _out := ""
var _bad := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0] if args.size() > 0 else "user://daily_snapshots"
	for sz in SIZES:
		await _run(sz, sz == SIZES[1])
	print("DAILY_EVIDENCE %s (%d rejected)" % ["CLEAN" if _bad == 0 else "REJECTED", _bad])
	quit(1 if _bad > 0 else 0)

func _run(size: Vector2i, all_states: bool) -> void:
	var sub := SubViewport.new()
	sub.size = size
	sub.disable_3d = true
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(sub)
	var path := "user://daily_ev_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = path
	MainScript.boot_opening_override = 0
	var root = MainScene.instantiate()
	sub.add_child(root)
	await _frames(6)
	var app = root.get_app_state()
	var st = root.get_modal_stack()
	app.economy.daily.mark_task_done(0)
	app.economy.orders.on_level_won({"difficulty": "EASY", "boosters_used": 0, "cells": 600})
	DailyScreens.open_tasks(st, app)
	await _draw(6)
	_shot(sub, root, "1_tasks", size)
	if all_states:
		st.clear("evidence")
		app.economy.daily.mark_task_done(1)
		app.economy.daily.mark_task_done(2)
		DailyScreens.open_tasks(st, app)
		await _draw(2)
		st.top()._on_action("scrubbox")
		await _draw(6)
		_shot(sub, root, "2_scrubbox", size)
		st.clear("evidence")
		DailyScreens.open_daily(st, app)
		await _draw(6)
		_shot(sub, root, "3_daily_fresh", size)
		st.top()._on_action("claim")
		await _draw(6)
		_shot(sub, root, "4_daily_celebration", size)
		st.clear("evidence")
		DailyScreens.open_daily(st, app)
		await _draw(4)
		_shot(sub, root, "5_daily_claimed", size)
		st.clear("evidence")
		app.economy.gift.add_streak_sb("ev", 260)
		app.actions.claim_gift(app.economy.gift.claimable()[0]["id"])
		DailyScreens.open_gift_bar(st, app)
		await _draw(6)
		_shot(sub, root, "6_gift_bar_claim_history", size)
	root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	await process_frame

func _shot(sub: SubViewport, root, key: String, size: Vector2i) -> void:
	var top = root.get_modal_stack().top()
	var p := "%s/%s_%dx%d.png" % [_out, key, size.x, size.y]
	if top == null or not Rect2(Vector2.ZERO, Vector2(size)).grow(1.0).encloses(top.get_frame_rect()) or not top.text_fits():
		_bad += 1
		print("REJECTED ", p)
	print("SNAPSHOT ", p, " err=", sub.get_texture().get_image().save_png(p))

func _draw(n: int) -> void:
	for _i in range(n):
		await RenderingServer.frame_post_draw

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame
