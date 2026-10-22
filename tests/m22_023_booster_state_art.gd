extends SceneTree
## SB-M22-023 — approved booster state art bound to the HUD booster buttons:
##   free badge frame (wraps the owned-charge count), reward glow (charge grant),
##   activated burst (successful booster execution). booster_tutorial_pointer stays unbound.
## Run: godot --headless --path . -s res://tests/m22_023_booster_state_art.gd

const GameplayScreen = preload("res://scripts/ui/gameplay_screen.gd")
const ART := {
	"BadgeFrame": "booster_free_badge_frame.png",
	"RewardGlow": "booster_reward_glow.png",
	"ActivatedBurst": "booster_activated_burst.png",
}

var _fail := 0

func _initialize() -> void:
	await process_frame
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2160)
	sub.disable_3d = true
	get_root().add_child(sub)
	var scr = GameplayScreen.new()
	scr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sub.add_child(scr)
	for _i in range(3):
		await process_frame
	_bound(scr)
	_badge_frame(scr)
	_reward_glow(scr)
	await _burst(scr)
	_structure(scr)
	sub.free()
	_done()

func _states(charges: Dictionary) -> Array:
	var out: Array = []
	for id in charges:
		out.append({"id": id, "charges": charges[id], "price": 500, "state": "available"})
	return out

func _bound(scr) -> void:
	print("[bound]")
	for id in scr.get_booster_ids():
		var b: Button = scr.get_booster_button(id)
		for n in ART:
			var r := b.get_node_or_null(n) as TextureRect
			_ok(r != null and r.texture != null and r.texture.resource_path.ends_with(ART[n]), "%s %s -> %s" % [id, n, ART[n]])
		_ok(b.get_node("BadgeFrame").get_index() < b.get_node("Badge").get_index(), "%s BadgeFrame draws under the count" % id)
		_ok(b.get_node("RewardGlow").get_index() < b.get_node("Icon").get_index()
			and b.get_node("ActivatedBurst").get_index() > b.get_node("Icon").get_index(), "%s glow behind, burst above Icon" % id)
		_ok(not b.get_node("RewardGlow").visible and not b.get_node("ActivatedBurst").visible, "%s glow/burst hidden by default" % id)

func _badge_frame(scr) -> void:
	print("[badge frame]")
	# First population (0 charges) and a later 0 -> 2 grant.
	scr.set_booster_states(_states({"random": 0}))
	var b: Button = scr.get_booster_button("random")
	_ok(not b.get_node("BadgeFrame").visible, "charges 0 -> BadgeFrame hidden")
	scr.set_booster_states(_states({"random": 2}))
	_ok(b.get_node("BadgeFrame").visible and b.get_node("BadgeFrame").visible == b.get_node("Badge").visible, "charges 2 -> BadgeFrame visible == Badge visible")
	_ok(b.get_node("Badge").text == "2", "count text unchanged by the frame")

func _reward_glow(scr) -> void:
	print("[reward glow]")
	# Fresh screen semantics: the first population must not glow even with owned charges.
	var fresh = GameplayScreen.new()
	get_root().add_child(fresh)
	fresh.set_booster_states(_states({"plus_one_slot": 3, "selector": 0}))
	_ok(not fresh.get_booster_button("plus_one_slot").get_node("RewardGlow").visible, "first population with charges -> no glow")
	fresh.set_booster_states(_states({"selector": 1}))
	_ok(fresh.get_booster_button("selector").get_node("RewardGlow").visible, "charges 0 -> 1 -> RewardGlow visible")
	fresh.set_booster_states(_states({"plus_one_slot": 2}))
	_ok(not fresh.get_booster_button("plus_one_slot").get_node("RewardGlow").visible, "charges 3 -> 2 -> no glow")
	fresh.free()

func _burst(scr) -> void:
	print("[activated burst]")
	scr.play_booster_activated("tornado")
	for id in scr.get_booster_ids():
		var v: bool = scr.get_booster_button(id).get_node("ActivatedBurst").visible
		_ok(v == (id == "tornado"), "%s ActivatedBurst visible == %s" % [id, id == "tornado"])
	await create_timer(scr.BOOSTER_FLASH_S + 0.2).timeout
	var b: Button = scr.get_booster_button("tornado")
	_ok(scr.BOOSTER_FLASH_S <= 0.6 and not b.get_node("ActivatedBurst").visible and not scr.get_booster_button("random").get_node("RewardGlow").visible, "fade <= 0.6 s ends hidden (burst + glow)")

func _structure(scr) -> void:
	print("[structure]")
	var row: Node = scr.find_child("BoosterRow", true, false)
	_ok(scr.get_booster_ids().size() == 4 and row != null and row.get_child_count() == 4, "4 booster buttons, BoosterRow child count 4")
	var ptr := 0
	for n in scr.find_children("*", "TextureRect", true, false):
		if (n as TextureRect).texture != null and (n as TextureRect).texture.resource_path.contains("booster_tutorial_pointer"):
			ptr += 1
	_ok(ptr == 0, "booster_tutorial_pointer not bound")

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M22-023 BOOSTER STATE ART: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
