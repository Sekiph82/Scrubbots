extends SceneTree
## M28-C002-C004: prints every slot spawn anchor + slot view rect for a size/capacity matrix.
## Run on the pre-C004 slot code and on the new code; the two outputs must be identical
## (tests/m28_c002_c004_tile_visual.gd pins the pre-C004 numbers).
##   godot --headless --path . -s res://tests/tools/m28_c004_anchor_probe.gd
const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const BoardDebugFixtures = preload("res://scripts/debug/board_debug_fixtures.gd")

func _initialize() -> void:
	await process_frame
	var pal := PackedStringArray()
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/palettes/scrubbots_palette_v3.json"))
	for c in j["colors"]:
		pal.append(String(c["hex"]))
	var slots := []
	for i in range(6):
		slots.append({"state": "WAITING" if i % 2 else "ACTIVE", "occupied": i < 4, "remaining_to_clear": 20 + i, "committed": 1, "color_id": i})
	for size in [Vector2i(1080, 2160), Vector2i(720, 1600), Vector2i(1080, 1920), Vector2i(1536, 2048), Vector2i(1290, 2796)]:
		for cap in [5, 6]:
			var sub := SubViewport.new()
			sub.size = size
			sub.disable_3d = true
			get_root().add_child(sub)
			var scr = GameplayScreen.new()
			scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			sub.add_child(scr)
			scr.configure(BoardDebugFixtures.make_board(24, 24), pal, [], [{"front": null, "preview": [], "remaining": 0}, {"front": null, "preview": [], "remaining": 0}, {"front": null, "preview": [], "remaining": 0}, {"front": null, "preview": [], "remaining": 0}, {"front": null, "preview": [], "remaining": 0}])
			if cap == 6:
				scr.get_five_slot_strip().set_capacity(6)
			scr.refresh_slot_snapshot(slots.slice(0, cap))
			for _i in range(6):
				await process_frame
			var strip = scr.get_five_slot_strip()
			var line := "%dx%d/%d " % [size.x, size.y, cap]
			for k in range(strip.get_slot_count()):
				var a: Vector2 = strip.get_slot_anchor_global(k)
				var v = strip.get_slot_views()[k]
				line += "[a=(%.2f,%.2f) r=(%.2f,%.2f,%.2f,%.2f)] " % [a.x, a.y, v.global_position.x, v.global_position.y, v.size.x, v.size.y]
			print("ANCHORS ", line)
			scr.free()
			sub.free()
	quit()
