extends SceneTree
## M43-C005F-PHASE1 diagnostic harness (NOT shipping, never referenced by production code).
## Renders one Node2D badge per intensity tier, fires every tier through the ONE FeedbackAdapter
## with the REAL GameFeelFlow + Saltmire Spark autoloads, and captures FULL vs REDUCED frames:
##   coordination/sessions/M43-C005F-PHASE1/evidence/tiers_full.png
##   coordination/sessions/M43-C005F-PHASE1/evidence/tiers_reduced.png
## Needs a rendering window (not --headless):
##   godot --path . -s res://tests/tools/c005f_tier_harness.gd

const FeedbackAdapter = preload("res://scripts/ui/feel/feedback_adapter.gd")
const EffectsSettingsService = preload("res://scripts/settings/effects_settings_service.gd")
const OUT := "res://coordination/sessions/M43-C005F-PHASE1/evidence"
const BG01 := Color8(0x20, 0x25, 0x33)

var _badges: Array = []

func _initialize() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DisplayServer.window_set_size(Vector2i(1200, 420))
	root.size = Vector2i(1200, 420)
	var bg := ColorRect.new()
	bg.color = BG01
	bg.size = Vector2(1200, 420)
	root.add_child(bg)
	for i in FeedbackAdapter.INTENTS.size():
		var n := Node2D.new()
		n.position = Vector2(100 + i * 200, 230)
		var sq := Polygon2D.new()
		sq.polygon = PackedVector2Array([Vector2(-40, -40), Vector2(40, -40), Vector2(40, 40), Vector2(-40, 40)])
		sq.color = Color8(0x00, 0xCC, 0xC0)
		n.add_child(sq)
		root.add_child(n)
		var l := Label.new()
		l.text = FeedbackAdapter.INTENTS[i]
		l.position = Vector2(30 + i * 200, 330)
		l.add_theme_font_size_override("font_size", 20)
		root.add_child(l)
		_badges.append(n)
	var title := Label.new()
	title.name = "Mode"
	title.position = Vector2(20, 16)
	title.add_theme_font_size_override("font_size", 24)
	root.add_child(title)
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for _i in range(10):
		await process_frame
	for mode in ["full", "reduced"]:
		var fx := EffectsSettingsService.new()
		fx.set_reduced(mode == "reduced")
		var a := FeedbackAdapter.new()
		a.bind(self, fx)
		(root.get_node("Mode") as Label).text = "FeedbackAdapter %s — real GameFeelFlow %s + Saltmire Spark %s (caps %s)" % [mode.to_upper(), FeedbackAdapter.GFF_VERSION, FeedbackAdapter.SPARK_VERSION, str(FeedbackAdapter.PARTICLE_CEILING.values())]
		for i in FeedbackAdapter.INTENTS.size():
			a.play(FeedbackAdapter.INTENTS[i], _badges[i])
		await create_timer(0.12).timeout
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image().get_region(Rect2i(0, 0, 1200, 420))
		img.save_png(ProjectSettings.globalize_path("%s/tiers_%s.png" % [OUT, mode]))
		print("captured %s owned=%d" % [mode, a.owned_count()])
		a.unbind()
		await create_timer(1.5).timeout
	quit(0)
