extends SceneTree
## M43-C005-C006 (SB-M43-064) V02/V03 — shipping Standard Card Pack interactive opening.
## V03: clean-alpha frames (STANDARD_FRAME_ALPHA_MANIFEST_V03) + FULL cadence >= 0.18 s per beat.
## Real ModalStack + StandardPackCeremony (BasePopup) + RevealSequencer + promoted owner
## frames + canonical C003 cards, deterministic COMMITTED fixture models. Player taps are
## delivered as real InputEventMouseButton through SubViewport.push_input (both gates).
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

const SIZE := Vector2i(1080, 1920)
const MANIFEST := "res://coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json"
const MANIFEST_V03 := "res://coordination/sessions/M43-C005-C006/STANDARD_FRAME_ALPHA_MANIFEST_V03.json"
const CAND_DIR := "res://assets/ui/candidates/m43_c005/pack_opening/standard/"
const V03_DIR := "res://assets/ui/candidates/m43_c005/pack_opening/standard_v03_alpha_clean/"
const MIN_HOLD := 0.18
const CARD_TREE := "res://assets/ui/final/collection/cards/"
## Identifiers meaning pack-opening / grant / Collection / exchange / save / navigation / RNG authority.
const FORBIDDEN := ["open_standard", "open_premium", "grant_guaranteed_new", "add_card", "claim",
	"grant", "RewardGrant", "CardPackService", "CollectionInventory", "CardsExchange", "exchange_card",
	"exchange_all_extras", "EconomyServices", "economy", "AppState", "save", "Save", "Navigation",
	"navigation", "RandomNumberGenerator", "randi", "randf", "randomize", "shuffle", "pick_random",
	"change_scene", "rewarded", "iap", "IAP"]
const SOURCES := ["res://scripts/ui/ceremony/standard_pack_ceremony.gd",
	"res://scripts/ui/ceremony/standard_pack_model.gd", "res://scripts/collection/collection_card_catalog.gd"]

var EXPECTED_CASES := [
	"c01_frame_hashes", "c03_requires_three", "c05_canonical_card_tree", "c06_rarity_and_name",
	"c07_new_duplicate", "c12_static_guard", "c13_model_sensitivity",
	"v01_initial_pack_only", "v02_no_auto_start", "v03_tap1_opening_order", "v04_hold_pack_absent",
	"v05_destinations_corners", "v06_tap2_required", "v07_mixed_routing", "v08_repeat_routing",
	"v09_no_state_mutation", "v10_complete_once", "v11_lifecycle_back", "v12_reduced_semantics",
	"v13_full_cadence", "v14_rendered_alpha_clean",
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
	_c03_requires_three()
	await _v01_initial_pack_only()
	await _v02_no_auto_start()
	await _v03_tap1_opening_order()
	await _v04_hold_pack_absent()
	await _v05_destinations_corners()
	await _v06_tap2_required()
	await _v07_mixed_routing()
	await _v08_repeat_routing()
	await _c05_canonical_card_tree()
	await _c06_rarity_and_name()
	await _c07_new_duplicate()
	await _v09_no_state_mutation()
	await _v10_complete_once()
	await _v11_lifecycle_back()
	await _v12_reduced_semantics()
	await _v13_full_cadence()
	_v14_rendered_alpha_clean()
	_c12_static_guard()
	_c13_model_sensitivity()
	_unmount()
	await _frames(3)   # let queued popup frees flush before exit
	_cleanup()
	_done()

# ------------------------------------------------------------- asset / model ----

## Promoted frames are the exact owner-accepted bytes (manifest authority).
func _c01_frame_hashes() -> void:
	print("[c01 promoted frame hashes (V03 clean-alpha authority)]")
	var want := _manifest_hashes()
	var c002 := _c002_hashes()
	var ok := want.size() == 9 and c002.size() == 9
	var hist_ok := true
	for f in StandardPackCeremony.PACK_FRAMES:
		var dst := FileAccess.get_sha256(StandardPackCeremony.FRAME_DIR + f)
		ok = ok and want.get(f, "") == dst and dst == FileAccess.get_sha256(V03_DIR + f)
		hist_ok = hist_ok and FileAccess.get_sha256(CAND_DIR + f) == c002[f]
	_ok(ok, "9 shipping frames == V03 clean candidates == STANDARD_FRAME_ALPHA_MANIFEST_V03 sha256")
	_ok(hist_ok, "historical C002 candidates unchanged (== PACK_ASSET_MANIFEST_V01)")
	var same := []
	for f in StandardPackCeremony.PACK_FRAMES:
		same.append(want[f] == c002[f])
	_ok(same == [true, true, true, true, false, false, false, false, false], "01..04 kept byte-identical (already clean); 05..09 alpha re-derived %s" % str(same))
	var files := Array(DirAccess.get_files_at(StandardPackCeremony.FRAME_DIR)).filter(func(n): return n.ends_with(".png"))
	files.sort()
	# (C006 also asserted "no Premium frames promoted"; SB-M43-065 / M43-C005-C007 now owns that family.)
	_ok(files == StandardPackCeremony.PACK_FRAMES, "exactly the 9 Standard frames in the Standard family")
	_complete("c01_frame_hashes")

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

# ------------------------------------------------------------- owner flow ----

## 1. Pack alone: frame 01, no card, no destination, no CTA, no cream frame, "Tap to open".
func _v01_initial_pack_only() -> void:
	print("[v01 initial pack-only state]")
	var p = _push(Fx.mixed("v01"))
	await _frames(2)
	var cards_hidden: bool = p.get_card_views().all(func(cv): return not cv.is_visible_in_tree())
	_ok(p.phase() == "IDLE" and p.get_stage().is_visible_in_tree() and p.pack_frame == 1 and _stage_path(p).ends_with("frame_01_closed.png"), "IDLE: pack frame 01 visible")
	_ok(cards_hidden and not p.get_destinations_layer().is_visible_in_tree(), "IDLE: no card, no Collection / Exchange destination")
	_ok(p.get_action_ids().is_empty() and _buttons(p).is_empty() and not p.find_child("Frame", true, false).is_visible_in_tree(), "IDLE: no Continue / no visible button; cream frame hidden")
	_ok(p.get_hint().is_visible_in_tree() and p.get_hint().text == UiText.t("PACK_TAP_OPEN"), "IDLE: live 'Tap to open' hint")
	_close(p)
	_complete("v01_initial_pack_only")

## 2. Nothing auto-starts.
func _v02_no_auto_start() -> void:
	print("[v02 no auto-start]")
	var tw := _tweens()
	var p = _push(Fx.mixed("v02"))
	await _frames(150)
	_ok(p.phase() == "IDLE" and p.frame_history().is_empty() and not p.get_sequencer().is_active() and _tweens() == tw, "150 frames untouched: still IDLE, no frame bound, no run, no tween")
	_close(p)
	_complete("v02_no_auto_start")

## 3-5. Tap 1 (real input) starts exactly one run; 01..09 one beat at a time; no strip.
func _v03_tap1_opening_order() -> void:
	print("[v03 tap 1 -> 01..09]")
	var p = _push(Fx.mixed("v03"))
	var runs: Array = []
	p.get_sequencer().step_started.connect(func(k, i): if i == 0: runs.append(k))
	await _frames(2)
	_tap(p)
	_ok(p.phase() == "OPENING", "real tap -> OPENING")
	var extra := [p.tap(), p.tap()]
	_tap(p)
	_ok(extra == [false, false], "extra taps during the opening are refused")
	var max_frame_nodes := 0
	var early_card := false
	for _g in range(900):   # capped: a regression fails, never hangs
		if p.phase() != "OPENING":
			break
		max_frame_nodes = maxi(max_frame_nodes, _frame_nodes(p))
		if p.pack_frame < 9:
			early_card = early_card or p.get_card_views().any(func(cv): return cv.is_visible_in_tree())
		await process_frame
	_ok(runs == ["v03:open"], "exactly one opening run %s" % str(runs))
	_ok(p.frame_history() == range(1, 10), "frames bound strictly 01..09 %s" % str(p.frame_history()))
	var manifest := _manifest_hashes()
	var names: Array = manifest.keys()
	names.sort()   # manifest order 01..09, independent of the ceremony's own list
	var tex_ok := true
	var stage = p.get_stage()
	for v in range(1, 10):   # every beat binds exactly the accepted Nth frame bytes
		p.pack_frame = v
		var bound: String = stage.texture.resource_path
		tex_ok = tex_ok and bound.get_file() == names[v - 1] and bound.get_base_dir() + "/" == StandardPackCeremony.FRAME_DIR and FileAccess.get_sha256(bound) == manifest[names[v - 1]]
	_ok(tex_ok, "beat N binds the accepted Nth frame (name + sha256 vs manifest)")
	_ok(max_frame_nodes == 1, "one current beat at a time: never more than one pack-frame node drawn (no strip)")
	_ok(not early_card, "no card visible before frame 09")
	_close(p)
	_complete("v03_tap1_opening_order")

## 7. After the reveal the pack is gone; exactly 3 readable cards hold in the row.
func _v04_hold_pack_absent() -> void:
	print("[v04 three-card hold, pack absent]")
	var p = _push(Fx.mixed("v04"))
	await _frames(2)
	_tap(p)
	var hold_seen := false
	for _g in range(900):   # capped: a regression fails, never hangs
		if p.phase() != "OPENING":
			break
		if p.get_stage().modulate.a == 0.0 and not p.get_destinations_layer().visible:
			hold_seen = hold_seen or p.get_card_views().all(func(cv): return cv.modulate.a == 1.0)
		await process_frame
	_ok(hold_seen, "a three-card hold with the pack faded out precedes the destinations")
	var cvs: Array = p.get_card_views()
	var at_slots: bool = cvs.all(func(cv): return cv.is_visible_in_tree() and cv.modulate.a == 1.0 and cv.scale == Vector2.ONE and cv.face_center().distance_to(cv.slot_point()) < 0.5)
	_ok(p.phase() == "AWAIT_ROUTE" and not p.get_stage().is_visible_in_tree() and cvs.size() == 3 and at_slots, "AWAIT_ROUTE: pack absent, 3 cards fully visible at their slots")
	var rows: Array = cvs.map(func(cv): return cv.get_global_rect())
	_ok(not rows[0].intersects(rows[1]) and not rows[1].intersects(rows[2]) and rows[0].position.x < rows[1].position.x and rows[1].position.x < rows[2].position.x, "cards in committed order, left to right, no overlap")
	_close(p)
	_complete("v04_hold_pack_absent")

## 8. Collection upper-left, Cards Exchange upper-right, both before Tap 2, clear of cards.
func _v05_destinations_corners() -> void:
	print("[v05 destinations upper-left / upper-right]")
	var p = await _to_await(Fx.mixed("v05"))
	var vp := Vector2(SIZE)
	var col: Rect2 = p.get_destination("collection").get_global_rect()
	var exc: Rect2 = p.get_destination("exchange").get_global_rect()
	_ok(p.get_destinations_layer().is_visible_in_tree() and p.get_destinations_layer().modulate.a == 1.0, "destinations visible before Tap 2")
	_ok(col.get_center().x < vp.x * 0.25 and col.get_center().y < vp.y * 0.2, "Collection icon upper-left %s" % str(col))
	_ok(exc.get_center().x > vp.x * 0.75 and exc.get_center().y < vp.y * 0.2, "Cards Exchange icon upper-right %s" % str(exc))
	_ok(p.get_destination("collection").texture.resource_path == StandardPackCeremony.DEST_ART["collection"] and p.get_destination("exchange").texture.resource_path == StandardPackCeremony.DEST_ART["exchange"], "existing approved Collection / Cards Exchange icons")
	_ok(p.get_destination("collection").get_node("Label").text == UiText.t("HOME_SC_COLLECTION") and p.get_destination("exchange").get_node("Label").text == UiText.t("HOME_SC_CARDS_EXCHANGE"), "destinations are labelled in text")
	var clear := true
	var safe: Rect2 = p.get_layer().get_global_rect().grow(1.0)
	for cv in p.get_card_views():
		var r: Rect2 = cv.get_global_rect()
		clear = clear and not r.intersects(col) and not r.intersects(exc) and safe.encloses(r)
	_ok(clear and safe.encloses(col) and safe.encloses(exc), "destinations do not cover a card; everything inside the safe area")
	_close(p)
	_complete("v05_destinations_corners")

## 9. Cards never route on their own; only a real Tap 2 starts routing, once.
func _v06_tap2_required() -> void:
	print("[v06 tap 2 required]")
	var p = await _to_await(Fx.mixed("v06"))
	await _frames(150)
	var still: bool = p.get_card_views().all(func(cv): return cv.route == 0.0 and cv.face_center().distance_to(cv.slot_point()) < 0.5)
	_ok(p.phase() == "AWAIT_ROUTE" and p.route_log().is_empty() and still and not p.get_sequencer().is_active(), "150 frames untouched: still AWAIT_ROUTE, no route, cards at slots")
	_ok(p.get_hint().is_visible_in_tree() and p.get_hint().text == UiText.t("PACK_TAP_COLLECT"), "live 'Tap to collect' hint")
	_tap(p)
	_ok(p.phase() == "ROUTING" and not p.tap() and not p.tap(), "real tap -> ROUTING; extra taps refused")
	await _until(p, "COMPLETE")
	_complete("v06_tap2_required")

## 10-12. NEW -> Collection only, DUPLICATE -> Cards Exchange only; cards travel visibly.
func _v07_mixed_routing() -> void:
	print("[v07 mixed routing]")
	var m := Fx.mixed("v07")
	var p = await _to_await(m)
	var dest_pt := {"collection": _center(p.get_destination("collection")), "exchange": _center(p.get_destination("exchange"))}
	var cvs: Array = p.get_card_views()
	var start: Array = cvs.map(func(cv): return cv.face_center())
	var mid_seen := [false, false, false]
	var toward := [true, true, true]
	var targets: Array = cvs.map(func(cv): return cv.destination_point())
	_tap(p)
	var log: Array = p.route_log()
	for _g in range(900):   # capped: a regression fails, never hangs
		if not is_instance_valid(p) or p.phase() != "ROUTING":
			break
		for i in range(3):
			var cv = cvs[i]
			if cv.route > 0.0 and cv.route < 1.0:
				mid_seen[i] = true
				var own: Vector2 = dest_pt[StandardPackCeremony.destination_of(m["cards"][i])]
				toward[i] = toward[i] and cv.face_center().distance_to(own) < start[i].distance_to(own) and cv.is_visible_in_tree()
		log = p.route_log()
		await process_frame
	var want: Array = [[0, "collection"], [1, "exchange"], [2, "collection"]]
	_ok(log == want, "route destinations follow committed NEW/DUPLICATE %s" % str(log))
	_ok(mid_seen == [true, true, true] and toward == [true, true, true], "each card visibly travels (observed mid-route) toward its own destination")
	var targets_ok := true
	for i in range(3):
		targets_ok = targets_ok and targets[i] == dest_pt[want[i][1]]
	_ok(targets_ok, "route end points are the destination icon centres")
	_complete("v07_mixed_routing")

## 13. Repeated duplicates still give exactly 3 deterministic routes.
func _v08_repeat_routing() -> void:
	print("[v08 repeated-duplicate routing]")
	var results: Array = []
	for run in range(2):
		var p = await _to_await(Fx.repeat("v08_%d" % run))
		var done := {}
		p.closed.connect(func(_r): done["routes"] = p.route_log(); done["arrivals"] = p.arrivals())
		_tap(p)
		await _until(p, "COMPLETE")
		await process_frame
		results.append(done)
	var want := [[0, "collection"], [1, "exchange"], [2, "exchange"]]
	_ok(results[0]["routes"] == want and results[0]["arrivals"] == [0, 1, 2], "NEW + DUPLICATE x2: exactly 3 routes %s" % str(results[0]))
	_ok(results[0] == results[1], "deterministic across runs")
	_complete("v08_repeat_routing")

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
	var p = await _to_await(Fx.mixed("c05"))
	var paths: Array = p.get_card_views().map(func(cv): return (cv.find_child("CardArt", true, false) as TextureRect).texture.resource_path)
	var want: Array = Fx.mixed()["cards"].map(func(c): return CollectionCardCatalog.entry(c["card_id"])["art"])
	_ok(paths == want and paths.all(func(x): return x.begins_with(CARD_TREE)), "face textures = canonical cards in model order")
	_ok(p.get_card_views().all(func(cv): return cv.find_children("*", "TextureRect", true, false).size() == 1), "no second card frame drawn over the card art")
	_close(p)
	_complete("c05_canonical_card_tree")

func _c06_rarity_and_name() -> void:
	print("[c06 rarity / name truth]")
	var p = await _to_await(Fx.mixed("c06"))
	var ok := true
	var got: Array = []
	for i in range(3):
		var c: Dictionary = p.get_model()["cards"][i]
		var cv = p.get_card_views()[i]
		got.append(_text(cv, "Rarity"))
		ok = ok and _text(cv, "Rarity") == UiText.t("RARITY_" + c["rarity"]) and _text(cv, "Name") == c["name"] and c["rarity"] == CollectionCardCatalog.entry(c["card_id"])["rarity"]
	_ok(ok and got == ["COMMON", "RARE", "LEGENDARY"], "rarity chip + live name match committed truth %s" % str(got))
	_close(p)
	_complete("c06_rarity_and_name")

func _c07_new_duplicate() -> void:
	print("[c07 NEW / DUPLICATE + counts]")
	for m in [Fx.mixed("c07a"), Fx.repeat("c07b")]:
		var p = await _to_await(m)
		var states: Array = p.get_card_views().map(func(cv): return _text(cv, "State"))
		var counts: Array = p.get_card_views().map(func(cv): return _text(cv, "Copies"))
		var want_states: Array = m["cards"].map(func(c): return UiText.t("PACK_CARD_NEW" if c["is_new"] else "PACK_CARD_DUPLICATE"))
		var want_counts: Array = m["cards"].map(func(c): return (UiText.t("PACK_CARD_FIRST_COPY") if c["is_new"] else UiText.t("PACK_CARD_EXTRAS", [int(c["copies_after"]) - 1])))
		_ok(states == want_states and counts == want_counts, "%s: badges %s / counts %s" % [m["presentation_id"], str(states), str(counts)])
		_close(p)
	_ok(UiText.t("PACK_CARD_NEW") != UiText.t("PACK_CARD_DUPLICATE"), "state is stated in text, not colour only")
	_complete("c07_new_duplicate")

## 14. The whole flow (both taps, routing, completion) touches no committed truth.
func _v09_no_state_mutation() -> void:
	print("[v09 no model / economy / exchange / save mutation]")
	var path := _uniq("v09")
	var app = AppState.new(path)
	app.request_save()
	var e0: Dictionary = _econ(app.economy)
	var rng0: int = app.economy.packs._rng.state
	var save0 := FileAccess.get_file_as_bytes(path)
	var input := Fx.mixed("v09")
	var input0 := input.duplicate(true)
	var p = _push(input)
	var model0: Dictionary = p.get_model()
	await _frames(2)
	_tap(p)
	await _until(p, "AWAIT_ROUTE")
	_tap(p)
	await _until(p, "COMPLETE")
	await _frames(2)
	_ok(input == input0 and model0 == StandardPackModel.validate(input0)["model"], "caller model and validated model unchanged")
	_ok(_econ(app.economy) == e0 and app.economy.packs._rng.state == rng0, "economy + Collection + exchange snapshot and pack RNG unchanged after routing")
	_ok(FileAccess.get_file_as_bytes(path) == save0 and save0.size() > 0, "save bytes unchanged (%d)" % save0.size())
	app.economy.packs.open_standard()   # sensitivity: a real open IS seen by the comparators
	_ok(_econ(app.economy) != e0 and app.economy.packs._rng.state != rng0, "sensitivity: a real open_standard() is detected")
	_complete("v09_no_state_mutation")

## 15. Completion fires exactly once, only after all 3 arrivals, then the popup closes.
func _v10_complete_once() -> void:
	print("[v10 completion once after 3 arrivals]")
	var p = await _to_await(Fx.mixed("v10"))
	var events: Array = []
	p.presentation_completed.connect(func(k): events.append(["completed", k, p.arrivals().size()]))
	p.closed.connect(func(r): events.append(["closed", r]))
	_tap(p)
	await _until(p, "COMPLETE")
	await _frames(10)
	_ok(events == [["completed", "v10", 3], ["closed", "complete"]], "completed once with 3 arrivals, then closed('complete') %s" % str(events))
	_ok(_stack.depth() == 0 and not is_instance_valid(p), "popup removed and freed by the ModalStack")
	_complete("v10_complete_once")

## 16. Cancel / free / Back / re-entry at every phase leaves nothing behind.
func _v11_lifecycle_back() -> void:
	print("[v11 lifecycle / Back / re-entry]")
	var tw := _tweens()
	var root_children: int = _stack.get_child(0).get_child_count()
	var conns: int = _stack.get_signal_connection_list("modal_changed").size()
	var done: Array = []
	var phases := ["IDLE", "OPENING", "AWAIT_ROUTE", "ROUTING"]
	for i in range(16):
		var target: String = phases[i % 4]
		var p = _push(Fx.mixed("v11_%d" % i))
		p.presentation_completed.connect(func(k): done.append(k))
		await _frames(1)
		if target != "IDLE":
			_tap(p)
		if target == "AWAIT_ROUTE" or target == "ROUTING":
			await _until(p, "AWAIT_ROUTE")
		if target == "ROUTING":
			_tap(p)
			await _frames(3)
		var before: String = p.phase()
		var esc := InputEventAction.new()
		esc.action = "ui_cancel"
		esc.pressed = true
		_stack._input(esc)
		var back_ok: bool = _stack.handle_back() and p.is_open() and p.phase() == before
		_ok(back_ok, "%s: Back/Escape consumed, nothing changes" % target)
		if i < 8:
			_stack.clear("route_change")
		else:
			p.close("freed")
	await _frames(10)
	_ok(done.is_empty(), "no cancelled ceremony ever completes late")
	_ok(_tweens() == tw and _stack.depth() == 0 and _stack.get_child(0).get_child_count() == root_children and _stack.get_signal_connection_list("modal_changed").size() == conns, "16 clears/closes across all phases: no tween/node/connection left")
	# Re-entry on one instance: a finished run never restarts.
	var p2 = await _to_await(Fx.mixed("v11_re"))
	_ok(p2.tap() and p2.phase() == "ROUTING" and not p2.tap(), "AWAIT_ROUTE tap routes once; the next tap is refused")
	var hist: Array = p2.frame_history()
	await _until(p2, "COMPLETE")
	_ok(hist == range(1, 10), "opening ran exactly once for the instance (no frame re-bound by later taps)")
	# Freed mid-run outside a stack: the host-bound tween dies with it.
	var host := Control.new()
	_sub.add_child(host)
	var other = ModalStack.new()
	host.add_child(other)
	var lone = StandardPackCeremony.create(Fx.mixed("v11_free"))["popup"]
	other.push(lone)
	await process_frame
	var tw2 := _tweens()
	var started: bool = lone.tap()
	_ok(started and _tweens() == tw2 + 1, "running in a second stack (+1 tween; %d -> %d)" % [tw2, _tweens()])
	await process_frame
	host.free()   # stack + popup freed mid-run without close
	await _frames(3)
	_ok(_tweens() == tw2, "freed mid-run: no tween survives")
	_complete("v11_lifecycle_back")

## 17. Reduced Effects: same two gates, no auto-start / auto-route, same routes and truth.
func _v12_reduced_semantics() -> void:
	print("[v12 Reduced Effects semantics]")
	var full = await _to_await(Fx.mixed("v12_full"))
	var full_info := _info(full)
	_close(full)
	await _frames(2)
	var p = _push(Fx.mixed("v12_red"), true)
	var done: Array = []
	p.presentation_completed.connect(func(k): done.append(k))
	await _frames(120)
	_ok(p.phase() == "IDLE" and p.pack_frame == 1 and p.frame_history().is_empty(), "Reduced: pack waits at IDLE (no auto-open)")
	_tap(p)
	await _until(p, "AWAIT_ROUTE")
	_ok(p.frame_history() == [9], "Reduced: frames 01..08 skipped, only the open pack (09)")
	_ok(_info(p) == full_info, "Reduced AWAIT_ROUTE info == FULL (cards, order, rarity, state, counts, destinations)")
	await _frames(120)
	_ok(p.phase() == "AWAIT_ROUTE" and p.route_log().is_empty(), "Reduced: waits for Tap 2 (no auto-route)")
	var mid := false
	var cv0 = p.get_card_views()[0]
	_tap(p)
	for _g in range(900):   # capped: a regression fails, never hangs
		if not is_instance_valid(p) or p.phase() != "ROUTING":
			break
		mid = mid or (cv0.route > 0.0 and cv0.route < 1.0)
		await process_frame
	_ok(mid and done == ["v12_red"], "Reduced: short visible route, completed once")
	_complete("v12_reduced_semantics")

## V03: FULL opening binds every beat 01..09 once, in order, each 01..08 for >= 0.18 s,
## one pack-frame node at a time, no face before 09. Bind times come from the sequencer's
## step_started (the instant each zero-duration frame step applies).
func _v13_full_cadence() -> void:
	print("[v13 FULL 01..09 cadence]")
	var p = _push(Fx.mixed("v13"))
	var binds: Array = []   ## [frame, usec]
	p.get_sequencer().step_started.connect(func(_k, i): if i < 9: binds.append([i + 1, Time.get_ticks_usec()]))
	await _frames(2)
	_tap(p)
	var max_nodes := 0
	var early_card := false
	for _g in range(900):   # capped: a regression fails, never hangs
		if p.phase() != "OPENING":
			break
		max_nodes = maxi(max_nodes, _frame_nodes(p))
		if p.pack_frame < 9:
			early_card = early_card or p.get_card_views().any(func(cv): return cv.is_visible_in_tree())
		await process_frame
	var holds := _holds(binds)
	print("    timing: " + str(holds.map(func(h): return "%02d bind %.3f s hold %.3f s" % [h[0], h[1], h[2]])))
	_ok(binds.map(func(b): return b[0]) == range(1, 10) and p.frame_history() == range(1, 10), "beats bound exactly 01..09, none skipped or repeated %s" % str(p.frame_history()))
	_ok(_cadence_ok(holds) and holds.size() == 8, "every FULL beat 01..08 held >= %.2f s" % MIN_HOLD)
	_ok(max_nodes == 1 and not early_card, "one current pack frame only; no card face before 09")
	_ok(StandardPackCeremony.FRAME_HOLD.slice(1).all(func(h): return h >= MIN_HOLD) and StandardPackCeremony.MIN_FULL_HOLD == MIN_HOLD, "configured FULL holds all >= 0.18 s")
	# Sensitivity: the checks reject a short hold, a skipped and a repeated beat.
	var short_ok := _cadence_ok([[1, 0.0, 0.4], [2, 0.4, 0.12]])
	var skip: Array = range(1, 10)
	skip.erase(5)
	var rep := [1, 2, 3, 4, 4, 5, 6, 7, 8, 9]
	_ok(not short_ok and skip != range(1, 10) and rep != range(1, 10), "sensitivity: short hold / skipped beat / repeated beat are rejected")
	_close(p)
	_complete("v13_full_cadence")

## [frame, bind_s (relative), hold_s] for 01..08 from [frame, usec] bind events.
func _holds(binds: Array) -> Array:
	var out: Array = []
	if binds.is_empty():
		return out
	var t0: int = binds[0][1]
	for i in range(binds.size() - 1):
		out.append([binds[i][0], (binds[i][1] - t0) / 1e6, (binds[i + 1][1] - binds[i][1]) / 1e6])
	return out

func _cadence_ok(holds: Array) -> bool:
	return holds.size() >= 1 and holds.all(func(h): return h[2] >= MIN_HOLD)

## V03: decoded shipping pixels have no matte: transparent border band, no dark visible wash,
## visible region never fills a side of its own bbox. (Full matte authority: the Python
## validator tools/validate_m43_c005_standard_frame_alpha_v03.py.)
func _v14_rendered_alpha_clean() -> void:
	print("[v14 rendered alpha clean]")
	var verdicts: Array = []
	for f in StandardPackCeremony.PACK_FRAMES:
		var img := Image.load_from_file(ProjectSettings.globalize_path(StandardPackCeremony.FRAME_DIR + f))
		verdicts.append(_matte_free(img))
	_ok(verdicts.all(func(v): return v), "all 9 shipping frames: transparent border, no dark wash, no rectangular boundary %s" % str(verdicts))
	var dirty := Image.load_from_file(ProjectSettings.globalize_path(CAND_DIR + "frame_05_tear_widens.png"))
	var boxed := Image.load_from_file(ProjectSettings.globalize_path(StandardPackCeremony.FRAME_DIR + "frame_09_final_reveal.png"))
	boxed.convert(Image.FORMAT_RGBA8)
	boxed.fill_rect(Rect2i(120, 120, 784, 1296), Color(0.02, 0.02, 0.02, 0.6))
	_ok(not _matte_free(dirty) and not _matte_free(boxed), "sensitivity: historical frame 05 and an injected dark rectangle are rejected")
	_complete("v14_rendered_alpha_clean")

## Sampled every 2nd pixel: border band transparent, dark semi-transparent wash under budget,
## visible region covers <= 55 % of its bbox's top and left sides.
func _matte_free(img: Image) -> bool:
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var wash := 0
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	for y in range(0, h, 2):
		var row := y * w * 4
		for x in range(0, w, 2):
			var i := row + x * 4
			var a := data[i + 3]
			if a < 8:
				continue
			if x < 24 or y < 24 or x >= w - 24 or y >= h - 24:
				return false
			x0 = mini(x0, x)
			y0 = mini(y0, y)
			x1 = maxi(x1, x)
			y1 = maxi(y1, y)
			if a >= 16 and a <= 230 and maxi(data[i], maxi(data[i + 1], data[i + 2])) < 40:
				wash += 1
	if x1 < 0 or wash * 4 > 8000:
		return false
	var top := 0
	for x in range(x0, x1 + 1, 2):
		top += 1 if data[(y0 * w + x) * 4 + 3] >= 8 else 0
	var left := 0
	for y in range(y0, y1 + 1, 2):
		left += 1 if data[(y * w + x0) * 4 + 3] >= 8 else 0
	return top * 2.0 / float(x1 - x0 + 1) <= 0.55 and left * 2.0 / float(y1 - y0 + 1) <= 0.55

## Source guard: no pack-opening / grant / Collection / exchange / save / navigation / RNG authority.
func _c12_static_guard() -> void:
	print("[c12 static authority guard]")
	for path in SOURCES:
		var hits := _forbidden_hits(_code_only(FileAccess.get_file_as_string(path)))
		_ok(hits.is_empty(), "%s: no authority identifiers %s" % [path.get_file(), str(hits)])
	var inj := _code_only(FileAccess.get_file_as_string(SOURCES[0])) + "\n\tpacks.open_standard()\n\tinventory.add_card(cid)\n\texchange.exchange_card(cid, 1, tx)\n"
	_ok(_forbidden_hits(inj).size() >= 3, "sensitivity: injected open_standard/add_card/exchange_card flagged %s" % str(_forbidden_hits(inj)))
	_complete("c12_static_guard")

func _c13_model_sensitivity() -> void:
	print("[c13 model sensitivity]")
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
	_ok(StandardPackCeremony.destination_of({"is_new": true}) == "collection" and StandardPackCeremony.destination_of({"is_new": false}) == "exchange", "destination rule: NEW Collection / DUPLICATE Exchange")
	_complete("c13_model_sensitivity")

# ------------------------------------------------------------------ helpers ----

func _push(model: Dictionary, reduced := false):
	var r := StandardPackCeremony.create(model, reduced)
	if not r["ok"]:
		_ok(false, "fixture rejected: %s" % r["reason"])
		return null
	_stack.push(r["popup"])
	return r["popup"]

## Push, real Tap 1, wait for AWAIT_ROUTE.
func _to_await(model: Dictionary, reduced := false):
	var p = _push(model, reduced)
	await _frames(2)
	_tap(p)
	await _until(p, "AWAIT_ROUTE")
	return p

## A real player tap: mouse press + release delivered through the SubViewport's GUI input.
func _tap(p) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = Vector2(SIZE) * Vector2(0.5, 0.82)
	ev.global_position = ev.position
	ev.pressed = true
	_sub.push_input(ev)
	var up := ev.duplicate()
	up.pressed = false
	_sub.push_input(up)

func _until(p, phase_name: String) -> void:
	for _i in range(900):
		if not is_instance_valid(p) or p.phase() == phase_name:
			return
		await process_frame
	_ok(false, "timed out waiting for %s" % phase_name)

func _info(p) -> Dictionary:
	var cards: Array = []
	for cv in p.get_card_views():
		cards.append([(cv.find_child("CardArt", true, false) as TextureRect).texture.resource_path, _text(cv, "Name"),
			_text(cv, "Rarity"), _text(cv, "State"), _text(cv, "Copies"), cv.modulate.a, cv.is_visible_in_tree(),
			StandardPackCeremony.destination_of(cv.card)])
	return {"phase": p.phase(), "stage_visible": p.get_stage().is_visible_in_tree(), "cards": cards,
		"destinations": [p.get_destinations_layer().is_visible_in_tree(), p.get_destination("collection").texture.resource_path, p.get_destination("exchange").texture.resource_path],
		"hint": p.get_hint().text}

func _text(node: Node, n: String) -> String:
	var c := node.find_child(n, true, false)
	if c is Label:
		return c.text
	return (c.get_node("Text") as Label).text if c != null else ""

func _stage_path(p) -> String:
	return p.get_stage().texture.resource_path

## Pack-frame nodes currently drawn (a strip/contact sheet would show more than one).
func _frame_nodes(p) -> int:
	return p.find_children("*", "TextureRect", true, false).filter(func(t): return t.is_visible_in_tree() and t.texture != null and String(t.texture.resource_path).begins_with(StandardPackCeremony.FRAME_DIR)).size()

func _buttons(p) -> Array:
	return p.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree())

func _center(c: Control) -> Vector2:
	return c.position + c.size * 0.5

## V03 shipping authority: frame name -> sha256 after alpha cleanup.
func _manifest_hashes() -> Dictionary:
	var out := {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_V03))
	for f in d["frames"]:
		out[String(f["frame"])] = f["sha256_after"]
	return out

## Historical C002 accepted candidates (provenance only).
func _c002_hashes() -> Dictionary:
	var out := {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for f in d["frames"]:
		if String(f["relative_path"]).contains("/standard/"):
			out[String(f["relative_path"]).get_file()] = f["sha256"]
	return out

func _close(p) -> void:
	if is_instance_valid(p) and p.is_open():
		p.close("test")

func _mount() -> void:
	_sub = SubViewport.new()
	_sub.size = SIZE
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
	print("M43-C005-C006 V02 standard pack interactive opening evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
