extends SceneTree
## M43-C005-C006 (SB-M43-064) — shipping Standard Card Pack opening presentation.
## Real ModalStack + StandardPackCeremony (BasePopup) + RevealSequencer + promoted owner
## frames + canonical C003 cards, driven by deterministic COMMITTED fixture models.
## Expected/completed case ledger.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c006_standard_pack_presentation.gd

const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const StandardPackModel = preload("res://scripts/ui/ceremony/standard_pack_model.gd")
const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")
const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const Fx = preload("res://tests/support/standard_pack_fixtures.gd")

const MANIFEST := "res://coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json"
const CAND_DIR := "res://assets/ui/candidates/m43_c005/pack_opening/standard/"
const CARD_TREE := "res://assets/ui/final/collection/cards/"
## Identifiers meaning pack-opening / grant / Collection / save / navigation / RNG authority.
const FORBIDDEN := ["open_standard", "open_premium", "grant_guaranteed_new", "add_card", "claim",
	"grant", "RewardGrant", "CardPackService", "CollectionInventory", "EconomyServices", "economy",
	"AppState", "save", "Save", "Navigation", "navigation", "RandomNumberGenerator", "randi", "randf",
	"randomize", "shuffle", "pick_random", "change_scene", "rewarded", "iap", "IAP"]
const SOURCES := ["res://scripts/ui/ceremony/standard_pack_ceremony.gd",
	"res://scripts/ui/ceremony/standard_pack_model.gd", "res://scripts/collection/collection_card_catalog.gd"]

var EXPECTED_CASES := [
	"c01_frame_hashes", "c02_frame_order", "c03_requires_three", "c04_three_faces_final",
	"c05_canonical_card_tree", "c06_rarity_and_name", "c07_new_duplicate", "c08_no_reroll_back",
	"c09_reduced_parity", "c10_no_state_mutation", "c11_lifecycle", "c12_static_guard",
	"c13_sensitivity",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack

func _initialize() -> void:
	await process_frame
	_mount()
	_c01_frame_hashes()
	await _c02_frame_order()
	_c03_requires_three()
	await _c04_three_faces_final()
	await _c05_canonical_card_tree()
	await _c06_rarity_and_name()
	await _c07_new_duplicate()
	await _c08_no_reroll_back()
	await _c09_reduced_parity()
	await _c10_no_state_mutation()
	await _c11_lifecycle()
	_c12_static_guard()
	await _c13_sensitivity()
	_unmount()
	await _frames(3)   # let queued popup frees flush before exit
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

## 1. Promoted frames are the exact owner-accepted bytes (manifest authority).
func _c01_frame_hashes() -> void:
	print("[c01 promoted frame hashes]")
	var want := _manifest_hashes()
	var ok := want.size() == 9
	for f in StandardPackCeremony.PACK_FRAMES:
		var dst := FileAccess.get_sha256(StandardPackCeremony.FRAME_DIR + f)
		var src := FileAccess.get_sha256(CAND_DIR + f)
		ok = ok and want.get(f, "") == dst and dst == src
		print("    %s %s" % [f, dst])
	_ok(ok, "9 promoted frames == accepted source == PACK_ASSET_MANIFEST_V01 sha256")
	var files := Array(DirAccess.get_files_at(StandardPackCeremony.FRAME_DIR)).filter(func(n): return n.ends_with(".png"))
	files.sort()
	_ok(files == StandardPackCeremony.PACK_FRAMES, "final family holds exactly the 9 Standard frames %s" % str(files))
	_ok(not DirAccess.dir_exists_absolute("res://assets/ui/final/rewards/pack_opening/premium"), "no Premium frames promoted")
	_complete("c01_frame_hashes")

## 2. Opening beats bind 01 -> 09 in order; no face is visible before frame 09.
func _c02_frame_order() -> void:
	print("[c02 frame order]")
	var p = _create(Fx.mixed("c02"))
	var steps: Array = []
	p.get_sequencer().step_started.connect(func(k, i): steps.append([k, i]))
	_stack.push(p)
	var early_face := false
	for _i in range(600):
		if p.pack_frame < 9:
			for t in p.get_card_tiles():
				early_face = early_face or t.modulate.a > 0.0
		if not p.is_presenting():
			break
		await process_frame
	_ok(_frame_order_ok(p.frame_history()), "pack frames bound strictly 01..09 %s" % str(p.frame_history()))
	var hist: Array = p.frame_history()
	var tex_ok := true
	var manifest := _manifest_hashes()
	var names: Array = manifest.keys()
	names.sort()   # manifest order 01..09, independent of the ceremony's own list
	for v in range(1, 10):   # every beat binds exactly the accepted Nth frame bytes
		p.pack_frame = v
		var bound: String = p.get_stage().texture.resource_path
		tex_ok = tex_ok and bound.get_file() == names[v - 1] and bound.get_base_dir() + "/" == StandardPackCeremony.FRAME_DIR and FileAccess.get_sha256(bound) == manifest[names[v - 1]]
	_ok(tex_ok and hist == range(1, 10), "beat N binds the accepted Nth frame (name + sha256 vs manifest; no drift, no generated art)")
	_ok(steps.size() == 13 and steps[0] == ["c02", 0] and steps[12] == ["c02", 12], "one ordered sequencer run: 9 beats + 3 faces + note")
	_ok(not early_face, "card faces hidden while the pack shows frames 01..08")
	_close(p)
	_complete("c02_frame_order")

## 3. Exactly 3 committed cards are required (fail closed otherwise).
func _c03_requires_three() -> void:
	print("[c03 exactly 3 cards]")
	var m := Fx.mixed("c03")
	for n in [0, 1, 2, 4, 5]:
		var bad := m.duplicate(true)
		bad["cards"] = []
		for i in range(n):
			bad["cards"].append(m["cards"][i % 3].duplicate())
		var r := StandardPackCeremony.create(bad)
		_ok(not r["ok"] and r["popup"] == null and r["reason"] == "card_count", "%d cards rejected (%s)" % [n, r["reason"]])
	var good := StandardPackCeremony.create(m)
	if good["popup"] != null:
		good["popup"].free()   # never pushed: free the orphan
	_ok(good["ok"] and StandardPackModel.CARD_COUNT == int(EconomyConfig.new().collection_config()["standard_pack_draws"]), "3 cards accepted; 3 == configured standard_pack_draws")
	_complete("c03_requires_three")

func _c04_three_faces_final() -> void:
	print("[c04 three faces at final state]")
	var p = _create(Fx.mixed("c04"))
	_stack.push(p)
	await _until_done(p)
	var tiles: Array = p.get_card_tiles()
	var ok := tiles.size() == 3
	for t in tiles:
		ok = ok and t.modulate.a == 1.0 and t.is_visible_in_tree() and (t.find_child("CardArt", true, false) as TextureRect).texture != null
	_ok(ok and p.pack_frame == 9 and p.get_note().modulate.a == 1.0, "final: frame 09 + exactly 3 fully visible faces + committed note")
	_ok(not p.get_action_button("continue").disabled, "Continue live once the presentation completes")
	_close(p)
	_complete("c04_three_faces_final")

## 5. Every face texture is the canonical C003 card for its id; the catalog is consistent.
func _c05_canonical_card_tree() -> void:
	print("[c05 canonical 135-card tree]")
	var ids: Array = CollectionCardCatalog.card_ids()
	var inv := CollectionInventory.new(EconomyConfig.new(), null)   # catalog only; nothing is added
	var arts := {}
	var cat_ok := ids.size() == 135
	for cid in ids:
		var e := CollectionCardCatalog.entry(cid)
		var want := CARD_TREE + "set_%02d/card_%02d.png" % [int(e["set"]), int(e["card"])]
		cat_ok = cat_ok and e["art"] == want and ResourceLoader.exists(want) and e["rarity"] == inv.card_rarity(cid) and not String(e["name"]).is_empty()
		arts[e["art"]] = true
	_ok(cat_ok and arts.size() == 135 and ids.size() == inv.all_card_ids().size(), "catalog: 135 unique canonical paths, rarity == CollectionInventory catalog")
	var p = _create(Fx.mixed("c05"))
	_stack.push(p)
	p.finish_presentation()
	var paths: Array = p.get_card_tiles().map(func(t): return (t.find_child("CardArt", true, false) as TextureRect).texture.resource_path)
	var want: Array = Fx.mixed()["cards"].map(func(c): return CollectionCardCatalog.entry(c["card_id"])["art"])
	_ok(paths == want and paths.all(func(x): return x.begins_with(CARD_TREE)), "face textures = canonical cards in model order %s" % str(paths))
	_ok(p.get_card_tiles().all(func(t): return t.find_children("*", "TextureRect", true, false).size() == 1), "no second card frame drawn over the card art")
	_close(p)
	_complete("c05_canonical_card_tree")

func _c06_rarity_and_name() -> void:
	print("[c06 rarity / name truth]")
	var p = _create(Fx.mixed("c06"))
	_stack.push(p)
	p.finish_presentation()
	var ok := true
	var got: Array = []
	for i in range(3):
		var c: Dictionary = p.get_model()["cards"][i]
		var t: Control = p.get_card_tiles()[i]
		var rar := _text(t, "Rarity")
		got.append(rar)
		ok = ok and rar == UiText.t("RARITY_" + c["rarity"]) and _text(t, "Name") == c["name"] and c["rarity"] == CollectionCardCatalog.entry(c["card_id"])["rarity"]
	_ok(ok and got == ["COMMON", "RARE", "LEGENDARY"], "rarity chip + live name match committed truth %s" % str(got))
	_close(p)
	_complete("c06_rarity_and_name")

func _c07_new_duplicate() -> void:
	print("[c07 NEW / DUPLICATE + counts]")
	for m in [Fx.mixed("c07a"), Fx.repeat("c07b")]:
		var p = _create(m)
		_stack.push(p)
		p.finish_presentation()
		var states: Array = []
		var counts: Array = []
		for t in p.get_card_tiles():
			states.append(_text(t, "State"))
			counts.append(_text(t, "Copies"))
		var want_states: Array = m["cards"].map(func(c): return UiText.t("PACK_CARD_NEW" if c["is_new"] else "PACK_CARD_DUPLICATE"))
		var want_counts: Array = m["cards"].map(func(c): return UiText.t("PACK_CARD_OWNED", [c["copies_after"]]))
		_ok(states == want_states and counts == want_counts, "%s: badges %s / counts %s" % [m["presentation_id"], str(states), str(counts)])
		_close(p)
	_ok(UiText.t("PACK_CARD_NEW") != UiText.t("PACK_CARD_DUPLICATE"), "state is stated in text, not colour only")
	_complete("c07_new_duplicate")

## 8. One action only; Back/Escape consumed and does nothing; no reroll / open again.
func _c08_no_reroll_back() -> void:
	print("[c08 no reroll / back cannot bypass]")
	var p = _create(Fx.mixed("c08"))
	var acts: Array = []
	p.action_selected.connect(func(id, _c): acts.append(id))
	_stack.push(p)
	_ok(p.get_action_ids() == ["continue"], "exactly one action: continue")
	var words := ["REROLL", "RE-ROLL", "OPEN AGAIN", "AGAIN", "OPEN ANOTHER", "BUY", "WATCH"]
	var leaked: Array = []
	for b in p.find_children("*", "Button", true, false):
		for w in words:
			if (b as Button).text.to_upper().contains(w):
				leaked.append(b.text)
	_ok(leaked.is_empty(), "no reroll / open-again affordance %s" % str(leaked))
	_ok(p.get_action_button("continue").disabled and not p.dismissible, "mid-presentation: Continue blocked, not dismissible")
	_ok(_stack.handle_back() and p.is_open() and acts.is_empty(), "Back/Escape consumed; popup stays, no action emitted")
	var esc := InputEventAction.new()
	esc.action = "ui_cancel"
	esc.pressed = true
	_stack._input(esc)
	_ok(p.is_open() and acts.is_empty() and p.is_presenting(), "ui_cancel mid-presentation changes nothing")
	p.get_action_button("continue").pressed.emit()
	_ok(p.is_open() and acts.is_empty(), "blocked Continue cannot fire early")
	p.finish_presentation()
	p.get_action_button("continue").pressed.emit()
	p.get_action_button("continue").pressed.emit()
	_ok(p.is_closed() and acts == ["continue"], "after completion: Continue closes once %s" % str(acts))
	await _frames(2)
	_complete("c08_no_reroll_back")

## 9. Reduced Effects lands the same final truth immediately, with no 01..08 chain.
func _c09_reduced_parity() -> void:
	print("[c09 Reduced Effects parity]")
	var full = _create(Fx.mixed("c09_full"))
	_stack.push(full)
	await _until_done(full)
	var want := _info(full)
	_close(full)
	await _frames(2)
	var red = _create(Fx.mixed("c09_red"), true)
	var done: Array = []
	red.presentation_completed.connect(func(k): done.append(k))
	var tw := _tweens()
	_stack.push(red)
	var got := _info(red)
	_ok(got == want, "Reduced final info == FULL final info %s" % str(got["cards"]))
	_ok(red.frame_history() == [9] and _tweens() == tw and not red.is_presenting() and done == ["c09_red"], "Reduced: only frame 09 bound, no tween, completed once at open")
	_ok(not red.get_action_button("continue").disabled, "Reduced: Continue live immediately")
	_close(red)
	_complete("c09_reduced_parity")

## 10. Presenting / fast-forwarding / tapping / continuing never touches committed truth.
func _c10_no_state_mutation() -> void:
	print("[c10 no model / economy / save mutation]")
	var path := _uniq("c10")
	var app = AppState.new(path)
	app.request_save()
	var e0: Dictionary = _econ(app.economy)
	var rng0: int = app.economy.packs._rng.state
	var save0 := FileAccess.get_file_as_bytes(path)
	var input := Fx.mixed("c10")
	var input0 := input.duplicate(true)
	var p = _create(input)
	var model0: Dictionary = p.get_model()
	_stack.push(p)
	await _frames(3)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	p.find_child("Reveal", true, false).gui_input.emit(tap)   # tap-to-fast-forward
	p.finish_presentation()
	p.start_presentation()
	p.get_action_button("continue").pressed.emit()
	await _frames(2)
	_ok(input == input0 and model0 == StandardPackModel.validate(input0)["model"], "caller model and validated model unchanged")
	_ok(_econ(app.economy) == e0 and app.economy.packs._rng.state == rng0, "economy + Collection snapshot and pack RNG unchanged")
	_ok(FileAccess.get_file_as_bytes(path) == save0 and save0.size() > 0, "save bytes unchanged (%d)" % save0.size())
	# Sensitivity: a real pack open IS seen by the same comparators.
	app.economy.packs.open_standard()
	_ok(_econ(app.economy) != e0 and app.economy.packs._rng.state != rng0, "sensitivity: a real open_standard() is detected")
	_complete("c10_no_state_mutation")

## 11. Cancel / free / re-open: no tween, node, timer or connection accumulation.
func _c11_lifecycle() -> void:
	print("[c11 lifecycle]")
	var tw := _tweens()
	var root_children: int = _stack.get_child(0).get_child_count()
	var stack_conns: int = _stack.get_signal_connection_list("modal_changed").size()
	var done: Array = []
	for i in range(30):
		var p = _create(Fx.mixed("c11_%d" % i))
		p.presentation_completed.connect(func(k): done.append(k))
		_stack.push(p)
		if i % 3 == 0:
			await process_frame
			_stack.clear("route_change")
		elif i % 3 == 1:
			p.finish_presentation()
			p.get_action_button("continue").pressed.emit()
		else:
			await _frames(2)
			p.close("freed")
	await _frames(5)
	_ok(_tweens() == tw and _stack.depth() == 0 and _stack.get_child(0).get_child_count() == root_children and _stack.get_signal_connection_list("modal_changed").size() == stack_conns, "30 open/clear/finish/close cycles: no tween/node/connection left")
	_ok(done.size() == 10 and done.all(func(k): return int(k.split("_")[1]) % 3 == 1), "only fast-forwarded runs completed; cancelled runs never complete late %s" % str(done.size()))
	var p = _create(Fx.mixed("c11_same"))
	_stack.push(p)
	_ok(not p.start_presentation(), "same presentation id cannot start a second run in this instance")
	p.finish_presentation()
	var hist: Array = p.frame_history()
	_ok(not p.start_presentation() and p.frame_history() == hist, "re-start after completion refused; no frame re-bound")
	_close(p)
	var host := Control.new()
	_sub.add_child(host)
	var lone = _create(Fx.mixed("c11_free"))
	host.add_child(lone)
	var lone_done: Array = []
	lone.presentation_completed.connect(func(k): lone_done.append(k))
	_ok(lone.start_presentation() and _tweens() == tw + 1, "running outside a stack (1 tween)")
	await process_frame
	host.free()   # freed mid-run without close: the host-bound tween dies with it
	await _frames(3)
	_ok(_tweens() == tw and lone_done.is_empty(), "freed mid-presentation: no tween survives, no completion")
	_stack.clear()
	await _frames(2)
	_complete("c11_lifecycle")

## 12. Source guard: no pack-opening / grant / Collection / save / navigation / RNG authority.
func _c12_static_guard() -> void:
	print("[c12 static authority guard]")
	for path in SOURCES:
		var hits := _forbidden_hits(_code_only(FileAccess.get_file_as_string(path)))
		_ok(hits.is_empty(), "%s: no authority identifiers %s" % [path.get_file(), str(hits)])
	var inj := _code_only(FileAccess.get_file_as_string(SOURCES[0])) + "\n\tapp.economy.packs.open_standard()\n\tinventory.add_card(cid)\n"
	_ok(_forbidden_hits(inj).size() >= 3, "sensitivity: injected open_standard/add_card is flagged %s" % str(_forbidden_hits(inj)))
	_complete("c12_static_guard")

## 13. Sensitivity: wrong count / rarity / asset path / name / state / frame order are caught.
func _c13_sensitivity() -> void:
	print("[c13 sensitivity]")
	var m := Fx.mixed("c13")
	var cases := {
		"card_count": func(x): x["cards"].pop_back(),
		"card_1_rarity": func(x): x["cards"][1]["rarity"] = "EPIC",
		"card_0_rarity": func(x): x["cards"][0]["rarity"] = "MYTHIC",
		"card_2_art": func(x): x["cards"][2]["art"] = CollectionCardCatalog.entry("s15_c7")["art"],
		"card_0_art": func(x): x["cards"][0]["art"] = "res://assets/ui/final/collection/card_frame_common.png",
		"card_1_name": func(x): x["cards"][1]["name"] = "Shiny Pan",
		"card_0_unknown_id": func(x): x["cards"][0]["card_id"] = "s16_c0",
		"card_0_copies": func(x): x["cards"][0]["copies_after"] = 2,
		"card_1_copies": func(x): x["cards"][1]["copies_after"] = 1,
		"card_2_state": func(x): x["cards"][2]["is_new"] = "yes",
		"presentation_id_empty": func(x): x["presentation_id"] = "  ",
	}
	for want in cases:
		var bad := m.duplicate(true)
		cases[want].call(bad)
		var r := StandardPackCeremony.create(bad)
		_ok(not r["ok"] and r["popup"] == null and r["reason"] == want, "rejected %s" % want)
	var rep := Fx.repeat("c13r")
	rep["cards"][1]["is_new"] = true
	rep["cards"][1]["copies_after"] = 1
	_ok(StandardPackModel.validate(rep)["reason"] == "card_1_repeat_order", "repeated card cannot be NEW twice")
	_ok(not _frame_order_ok([1, 2, 4, 3, 5, 6, 7, 8, 9]) and not _frame_order_ok([1, 2, 3, 4, 5, 6, 7, 8]) and not _frame_order_ok([9]) and _frame_order_ok(range(1, 10)), "frame-order check flags swapped / missing beats")
	var p = _create(Fx.mixed("c13p"))
	_stack.push(p)
	p.finish_presentation()
	var info := _info(p)
	(p.get_card_tiles()[1].find_child("Rarity", true, false).get_node("Text") as Label).text = "EPIC"
	_ok(_info(p) != info, "sensitivity: the final-info comparator sees a changed rarity label")
	_close(p)
	_complete("c13_sensitivity")

# ------------------------------------------------------------------ helpers ----

func _create(model: Dictionary, reduced := false):
	var r := StandardPackCeremony.create(model, reduced)
	if not r["ok"]:
		_ok(false, "fixture rejected: %s" % r["reason"])
	return r["popup"]

func _info(p) -> Dictionary:
	var cards: Array = []
	for t in p.get_card_tiles():
		cards.append([(t.find_child("CardArt", true, false) as TextureRect).texture.resource_path, _text(t, "Name"),
			_text(t, "Rarity"), _text(t, "State"), _text(t, "Copies"), t.modulate.a, t.visible])
	return {"frame": p.pack_frame, "stage": p.get_stage().texture.resource_path, "cards": cards,
		"note": [p.get_note().text, p.get_note().modulate.a], "title": p.get_title(),
		"actions": p.get_action_ids(), "continue_live": not p.get_action_button("continue").disabled}

func _text(tile: Node, n: String) -> String:
	var node := tile.find_child(n, true, false)
	if node is Label:
		return node.text
	return (node.get_node("Text") as Label).text if node != null else ""

func _frame_order_ok(hist: Array) -> bool:
	return hist == range(1, 10)

func _manifest_hashes() -> Dictionary:
	var out := {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for f in d["frames"]:
		if String(f["relative_path"]).contains("/standard/"):
			out[String(f["relative_path"]).get_file()] = f["sha256"]
	return out

func _until_done(p) -> void:
	for _i in range(600):
		if not p.is_presenting():
			return
		await process_frame

func _close(p) -> void:
	if is_instance_valid(p) and p.is_open():
		p.close("test")

func _mount() -> void:
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_stack = ModalStack.new()
	_sub.add_child(_stack)
	_stack.set_synthetic_safe_insets(0, 96, 0, 64)

func _unmount() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.free()

func _tweens() -> int:
	return get_processed_tweens().filter(func(t): return t.is_valid()).size()

func _econ(eco) -> Dictionary:
	var s: Dictionary = eco.snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	return s

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

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _uniq(tag: String) -> String:
	var p := "user://m43c005c006_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M43-C005-C006 standard pack presentation evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
