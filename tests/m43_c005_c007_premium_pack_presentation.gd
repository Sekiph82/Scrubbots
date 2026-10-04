extends SceneTree
## M43-C005-C007 (SB-M43-065) — shipping Premium Card Pack opening presentation.
## Real ModalStack + PremiumPackCeremony (specialised accepted Standard ceremony) +
## RevealSequencer + promoted Premium frames + canonical C003 cards + deterministic COMMITTED
## Premium fixtures. Player taps are real InputEventMouseButton through SubViewport.push_input.
## The real CardPackService is exercised only to prove the 5-draw / first-draw-Rare+ invariant.
## Expected/completed case ledger.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c007_premium_pack_presentation.gd

const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const PremiumPackModel = preload("res://scripts/ui/ceremony/premium_pack_model.gd")
const CardPackService = preload("res://scripts/collection/card_pack_service.gd")
const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")
const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const Fx = preload("res://tests/support/premium_pack_fixtures.gd")
const Std = preload("res://tests/support/standard_pack_fixtures.gd")

const SIZE := Vector2i(1080, 1920)
const MANIFEST := "res://coordination/sessions/M43-C005-C007/PREMIUM_FRAME_MANIFEST_V01.json"
const C002 := "res://coordination/sessions/M43-C005-C002/PACK_ASSET_MANIFEST_V01.json"
const CAND_DIR := "res://assets/ui/candidates/m43_c005/pack_opening/premium/"
const STD_DIRTY := "res://assets/ui/candidates/m43_c005/pack_opening/standard/frame_05_tear_widens.png"
const MIN_HOLD := 0.18
const RARE_PLUS := ["RARE", "EPIC", "LEGENDARY"]
const FORBIDDEN := ["open_standard", "open_premium", "grant_guaranteed_new", "add_card", "claim",
	"grant", "RewardGrant", "CardPackService", "CollectionInventory", "CardsExchange", "exchange_card",
	"exchange_all_extras", "EconomyServices", "economy", "AppState", "save", "Save", "Navigation",
	"navigation", "RandomNumberGenerator", "randi", "randf", "randomize", "shuffle", "pick_random",
	"change_scene", "rewarded", "iap", "IAP", "sort", "sort_custom"]
const SOURCES := ["res://scripts/ui/ceremony/premium_pack_ceremony.gd", "res://scripts/ui/ceremony/premium_pack_model.gd"]

var EXPECTED_CASES := [
	"p01_frame_manifest", "p02_rendered_alpha", "p03_count", "p04_identity_state", "p05_guarantee_order",
	"p06_service_invariant", "p07_idle_no_autostart", "p08_tap1_cadence", "p09_emerge_hold_3_2",
	"p10_destinations", "p11_tap2_required", "p12_mixed_routing", "p13_repeat_all_new",
	"p14_no_state_mutation", "p15_complete_once", "p16_lifecycle", "p17_reduced", "p18_static_guard",
	"p19_card_truth",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack

func _initialize() -> void:
	await process_frame
	_mount()
	_p01_frame_manifest()
	_p02_rendered_alpha()
	_p03_count()
	_p04_identity_state()
	_p05_guarantee_order()
	_p06_service_invariant()
	await _p07_idle_no_autostart()
	await _p08_tap1_cadence()
	await _p09_emerge_hold_3_2()
	await _p10_destinations()
	await _p11_tap2_required()
	await _p12_mixed_routing()
	await _p13_repeat_all_new()
	await _p14_no_state_mutation()
	await _p15_complete_once()
	await _p16_lifecycle()
	await _p17_reduced()
	_p18_static_guard()
	await _p19_card_truth()
	_unmount()
	await _frames(3)
	_cleanup()
	_done()

# ------------------------------------------------------------- assets ----

func _p01_frame_manifest() -> void:
	print("[p01 Premium frame manifest]")
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))["frames"]
	var c002 := {}
	for f in JSON.parse_string(FileAccess.get_file_as_string(C002))["frames"]:
		if String(f["relative_path"]).contains("/premium/"):
			c002[String(f["relative_path"]).get_file()] = f
	var ok := rows.size() == 9
	var counts: Array = []
	for i in range(rows.size()):
		var r: Dictionary = rows[i]
		var f := String(r["frame"])
		var ship := FileAccess.get_sha256(PremiumPackCeremony.PREMIUM_FRAME_DIR + f)
		ok = ok and f == PremiumPackCeremony.PACK_FRAMES[i] and ship == String(r["sha256"]) and ship == FileAccess.get_sha256(CAND_DIR + f) and ship == String(c002[f]["sha256"]) and bool(r["metrics"]["clean"])
		counts.append(int(c002[f]["expected_card_count"]))
	_ok(ok, "9 shipping Premium frames == manifest == C002 accepted candidates (byte-identical), all clean")
	_ok(counts == [0, 0, 0, 0, 0, 1, 1, 5, 5], "pack-art card-back counts 0/0/0/0/0/1/1/5/5 %s" % str(counts))
	var files := Array(DirAccess.get_files_at(PremiumPackCeremony.PREMIUM_FRAME_DIR)).filter(func(n): return n.ends_with(".png"))
	files.sort()
	_ok(files == PremiumPackCeremony.PACK_FRAMES, "final Premium family holds exactly the 9 canonical files")
	_complete("p01_frame_manifest")

func _p02_rendered_alpha() -> void:
	print("[p02 rendered alpha / matte]")
	var verdicts: Array = []
	for f in PremiumPackCeremony.PACK_FRAMES:
		verdicts.append(_matte_free(Image.load_from_file(ProjectSettings.globalize_path(PremiumPackCeremony.PREMIUM_FRAME_DIR + f))))
	_ok(verdicts.all(func(v): return v), "all 9 Premium frames: transparent border, no dark wash, no rectangular boundary %s" % str(verdicts))
	var boxed := Image.load_from_file(ProjectSettings.globalize_path(PremiumPackCeremony.PREMIUM_FRAME_DIR + "frame_09_final_reveal.png"))
	boxed.convert(Image.FORMAT_RGBA8)
	boxed.fill_rect(Rect2i(120, 120, 784, 1296), Color(0.02, 0.02, 0.02, 0.6))
	_ok(not _matte_free(boxed) and not _matte_free(Image.load_from_file(ProjectSettings.globalize_path(STD_DIRTY))), "sensitivity: a dark rectangle on a Premium frame and a historical dirty frame are rejected")
	_complete("p02_rendered_alpha")

# ------------------------------------------------------------- model ----

func _p03_count() -> void:
	print("[p03 exactly 5 cards]")
	var m := Fx.mixed("p03")
	for n in [0, 1, 2, 3, 4, 6]:
		var bad := m.duplicate(true)
		bad["cards"] = []
		for i in range(n):
			bad["cards"].append(m["cards"][i % 5].duplicate())
		var r := PremiumPackCeremony.create_premium(bad)
		_ok(not r["ok"] and r["popup"] == null and r["reason"] == "card_count", "%d cards rejected" % n)
	var good := PremiumPackCeremony.create_premium(m)
	if good["popup"] != null:
		good["popup"].free()
	_ok(good["ok"] and PremiumPackModel.CARD_COUNT == int(EconomyConfig.new().collection_config()["premium_pack_draws"]) and PremiumPackModel.CARD_COUNT == CardPackService.PREMIUM_DRAWS, "5 accepted; 5 == configured premium_pack_draws == CardPackService.PREMIUM_DRAWS")
	_complete("p03_count")

func _p04_identity_state() -> void:
	print("[p04 identity / state]")
	var m := Fx.mixed("p04")
	var cases := {
		"presentation_id_empty": func(x): x["presentation_id"] = " ",
		"kind": func(x): x["kind"] = "standard",
		"card_2_unknown_id": func(x): x["cards"][2]["card_id"] = "s99_c0",
		"card_1_art": func(x): x["cards"][1]["art"] = CollectionCardCatalog.entry("s3_c1")["art"],
		"card_3_name": func(x): x["cards"][3]["name"] = "Bug Vacuum",
		"card_4_rarity": func(x): x["cards"][4]["rarity"] = "RARE",
		"card_2_state": func(x): x["cards"][2]["is_new"] = 1,
		"card_2_copies": func(x): x["cards"][2]["copies_after"] = 3,
		"card_1_copies": func(x): x["cards"][1]["copies_after"] = 1,
	}
	for want in cases:
		var bad := m.duplicate(true)
		cases[want].call(bad)
		var r := PremiumPackCeremony.create_premium(bad)
		_ok(not r["ok"] and r["popup"] == null and r["reason"] == want, "rejected %s" % want)
	var rep := Fx.repeat("p04r")
	rep["cards"][2]["copies_after"] = 2
	_ok(PremiumPackModel.validate(rep)["reason"] == "card_2_repeat_order", "repeated card must count up by one")
	_ok(PremiumPackModel.validate(Fx.repeat("p04ok"))["ok"], "duplicates (incl. the guaranteed card repeated) are allowed")
	_complete("p04_identity_state")

## Card 0 is the service's Rare-or-better draw: never COMMON, never reordered into place.
func _p05_guarantee_order() -> void:
	print("[p05 card 0 Rare-or-better, order preserved]")
	var common0 := Fx.mixed("p05a")
	common0["cards"] = [Std.card("s2_c1", false, 2), Std.card("s4_c6", true, 1), Std.card("s15_c6", true, 1), Std.card("s9_c3", true, 1), Std.card("s14_c0", true, 1)]
	var r := PremiumPackCeremony.create_premium(common0)
	_ok(not r["ok"] and r["reason"] == "card_0_not_rare_or_better", "card 0 COMMON rejected although cards 1/2 are EPIC/LEGENDARY (%s)" % r["reason"])
	var ok_all := true
	for cid in ["s6_c4", "s8_c7", "s15_c8"]:   # RARE, EPIC, LEGENDARY first
		var m := Fx.mixed("p05_" + cid)
		m["cards"][0] = Std.card(cid, true, 1)
		var v := PremiumPackModel.validate(m)
		ok_all = ok_all and v["ok"]
	_ok(ok_all, "card 0 RARE / EPIC / LEGENDARY accepted")
	var v2 := PremiumPackModel.validate(Fx.mixed("p05o"))
	_ok(v2["model"]["cards"].map(func(c): return c["card_id"]) == Fx.mixed()["cards"].map(func(c): return c["card_id"]), "validated model keeps the committed draw order")
	_complete("p05_guarantee_order")

## The real service: 5 draws, first draw Rare-or-better; its output maps to a valid model.
func _p06_service_invariant() -> void:
	print("[p06 CardPackService invariant]")
	var inv := CollectionInventory.new(EconomyConfig.new(), RewardStub.new())
	var rng := RandomNumberGenerator.new()
	rng.seed = 64065
	var svc := CardPackService.new(inv, rng)
	var first_ok := true
	var five := true
	var models_ok := true
	var commons_later := 0
	for n in range(200):
		var before := {}
		for cid in inv.all_card_ids():
			before[cid] = inv.owned(cid)
		var drawn: Array = svc.open_premium()
		five = five and drawn.size() == 5
		first_ok = first_ok and inv.card_rarity(drawn[0]) in RARE_PLUS
		for i in range(1, drawn.size()):
			commons_later += 1 if inv.card_rarity(drawn[i]) == "COMMON" else 0
		var cards: Array = []
		var running := before.duplicate()
		for cid in drawn:
			running[cid] = int(running[cid]) + 1
			cards.append(Std.card(cid, int(running[cid]) == 1, int(running[cid])))
		models_ok = models_ok and PremiumPackModel.validate({"presentation_id": "svc_%d" % n, "kind": "premium", "cards": cards})["ok"]
	_ok(CardPackService.PREMIUM_DRAWS == 5 and five, "PREMIUM_DRAWS == 5; every open_premium() returns 5 draws")
	_ok(first_ok, "200 opens: first returned draw always RARE/EPIC/LEGENDARY")
	_ok(commons_later > 0, "the other four are arbitrary eligible draws (COMMONs appear: %d)" % commons_later)
	_ok(models_ok, "every real service result, in service order, is a valid Premium presentation model")
	_ok(not _first_rare_plus([["s2_c1", "s4_c6"]], inv), "sensitivity: the checker flags a COMMON first draw")
	_complete("p06_service_invariant")

func _first_rare_plus(draws: Array, inv) -> bool:
	return draws.all(func(d): return inv.card_rarity(d[0]) in RARE_PLUS)

# ------------------------------------------------------------- owner flow ----

func _p07_idle_no_autostart() -> void:
	print("[p07 Premium pack alone, no auto-start]")
	var tw := _tweens()
	var p = _push(Fx.mixed("p07"))
	await _frames(150)
	_ok(p.phase() == "IDLE" and p.frame_history().is_empty() and not p.get_sequencer().is_active() and _tweens() == tw, "150 frames untouched: IDLE, nothing bound, no run, no tween")
	_ok(p.get_stage().is_visible_in_tree() and p.get_stage().texture.resource_path == PremiumPackCeremony.PREMIUM_FRAME_DIR + "frame_01_closed.png", "Premium frame 01 shown")
	_ok(p.get_card_views().all(func(cv): return not cv.is_visible_in_tree()) and not p.get_destinations_layer().is_visible_in_tree() and _buttons(p).is_empty() and p.get_action_ids().is_empty(), "no card, no destination, no button")
	_ok(p.get_layer().get_node("Title").text == UiText.t("PACK_PREMIUM_TITLE") and p.popup_id == "premium_pack" and p.get_hint().text == UiText.t("PACK_TAP_OPEN"), "PREMIUM PACK title, 'Tap to open'")
	_close(p)
	_complete("p07_idle_no_autostart")

func _p08_tap1_cadence() -> void:
	print("[p08 Tap 1 -> Premium 01..09 cadence]")
	var p = _push(Fx.mixed("p08"))
	var binds: Array = []
	var runs: Array = []
	p.get_sequencer().step_started.connect(func(k, i):
		if i == 0: runs.append(k)
		if i < 9: binds.append([i + 1, Time.get_ticks_usec()]))
	await _frames(2)
	_tap()
	_ok(p.phase() == "OPENING" and not p.tap() and not p.tap(), "real tap -> OPENING; extra taps refused")
	var max_nodes := 0
	var early := false
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:   # time cap: a regression fails, never hangs
		if p.phase() != "OPENING":
			break
		max_nodes = maxi(max_nodes, _frame_nodes(p))
		if p.pack_frame < 9:
			early = early or p.get_card_views().any(func(cv): return cv.is_visible_in_tree())
		await process_frame
	var holds := _holds(binds)
	print("    timing: " + str(holds.map(func(h): return "%02d hold %.3f s" % [h[0], h[1]])))
	_ok(runs == ["p08:open"] and p.frame_history() == range(1, 10), "one run; frames bound exactly 01..09 %s" % str(p.frame_history()))
	_ok(holds.size() == 8 and holds.all(func(h): return h[1] >= MIN_HOLD), "every FULL beat 01..08 held >= 0.18 s")
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))["frames"]
	var tex_ok := true
	for v in range(1, 10):
		p.pack_frame = v
		tex_ok = tex_ok and FileAccess.get_sha256(p.get_stage().texture.resource_path) == String(rows[v - 1]["sha256"]) and p.get_stage().texture.resource_path.begins_with(PremiumPackCeremony.PREMIUM_FRAME_DIR)
	_ok(tex_ok, "beat N binds the Premium manifest's Nth frame bytes")
	_ok(max_nodes == 1 and not early, "one pack frame at a time; no card face before 09")
	_close(p)
	_complete("p08_tap1_cadence")

func _p09_emerge_hold_3_2() -> void:
	print("[p09 five cards emerge, pack gone, 3 + 2 hold]")
	var p = _push(Fx.mixed("p09"))
	await _frames(2)
	_tap()
	var hold_seen := false
	var emerged := {}
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:   # time cap: a regression fails, never hangs
		if p.phase() != "OPENING":
			break
		for i in range(5):
			if p.get_card_views()[i].emerge > 0.0 and p.pack_frame == 9:
				emerged[i] = true
		if p.get_stage().modulate.a == 0.0 and not p.get_destinations_layer().visible:
			hold_seen = hold_seen or p.get_card_views().all(func(cv): return cv.modulate.a == 1.0)
		await process_frame
	var cvs: Array = p.get_card_views()
	_ok(emerged.size() == 5 and cvs.size() == 5, "exactly 5 cards emerged on the final beat")
	_ok(hold_seen and p.phase() == "AWAIT_ROUTE" and not p.get_stage().is_visible_in_tree(), "pack-free five-card hold before destinations; pack gone")
	var at_slots: bool = cvs.all(func(cv): return cv.is_visible_in_tree() and cv.modulate.a == 1.0 and cv.scale == Vector2.ONE and cv.face_center().distance_to(cv.slot_point()) < 0.5)
	var c: Array = cvs.map(func(cv): return cv.slot_point())
	var layout_ok: bool = c[0].y == c[1].y and c[1].y == c[2].y and c[3].y == c[4].y and c[3].y > c[0].y and c[0].x < c[1].x and c[1].x < c[2].x and c[3].x < c[4].x
	var centred: bool = absf((c[0].x + c[2].x) * 0.5 - p.get_layer().size.x * 0.5) < 1.0 and absf((c[3].x + c[4].x) * 0.5 - p.get_layer().size.x * 0.5) < 1.0
	var overlap := false
	for a in range(5):
		for b in range(a + 1, 5):
			overlap = overlap or cvs[a].get_global_rect().intersects(cvs[b].get_global_rect())
	var safe: Rect2 = p.get_layer().get_global_rect().grow(1.0)
	_ok(at_slots and layout_ok and centred and not overlap and cvs.all(func(cv): return safe.encloses(cv.get_global_rect())), "centred 3 + 2 in draw order 0,1,2 / 3,4; no overlap; inside safe area")
	_close(p)
	_complete("p09_emerge_hold_3_2")

func _p10_destinations() -> void:
	print("[p10 destinations]")
	var p = await _to_await(Fx.mixed("p10"))
	var vp := Vector2(SIZE)
	var col: Rect2 = p.get_destination("collection").get_global_rect()
	var exc: Rect2 = p.get_destination("exchange").get_global_rect()
	_ok(p.get_destinations_layer().is_visible_in_tree() and col.get_center().x < vp.x * 0.25 and col.get_center().y < vp.y * 0.2 and exc.get_center().x > vp.x * 0.75 and exc.get_center().y < vp.y * 0.2, "Collection upper-left, Cards Exchange upper-right, visible before Tap 2")
	var clear := true
	for cv in p.get_card_views():
		var r: Rect2 = cv.get_global_rect()
		for k in ["collection", "exchange"]:
			clear = clear and not r.intersects(p.get_destination(k).get_global_rect()) and not r.intersects(p.get_destination(k).get_node("Label").get_global_rect())
	_ok(clear, "destination icons/labels clear of all five cards")
	_close(p)
	_complete("p10_destinations")

func _p11_tap2_required() -> void:
	print("[p11 Tap 2 required]")
	var p = await _to_await(Fx.mixed("p11"))
	await _frames(150)
	var still: bool = p.get_card_views().all(func(cv): return cv.route == 0.0 and cv.face_center().distance_to(cv.slot_point()) < 0.5)
	_ok(p.phase() == "AWAIT_ROUTE" and p.route_log().is_empty() and still, "150 frames untouched: no route, five cards stationary")
	_tap()
	_ok(p.phase() == "ROUTING" and not p.tap(), "real tap -> ROUTING; extra tap refused")
	await _until(p, "COMPLETE")
	_complete("p11_tap2_required")

func _p12_mixed_routing() -> void:
	print("[p12 mixed routing across five]")
	var m := Fx.mixed("p12")
	var p = await _to_await(m)
	var cvs: Array = p.get_card_views()
	var dest := {"collection": _center(p.get_destination("collection")), "exchange": _center(p.get_destination("exchange"))}
	var start: Array = cvs.map(func(cv): return cv.face_center())
	var targets: Array = cvs.map(func(cv): return cv.destination_point())
	var mid := [false, false, false, false, false]
	var toward := [true, true, true, true, true]
	var concurrent := 0
	var log: Array = []
	var arrivals: Array = []
	p.closed.connect(func(_r): arrivals.append_array(p.arrivals()))
	_tap()
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:   # time cap: a regression fails, never hangs
		if not is_instance_valid(p) or p.phase() != "ROUTING":
			break
		var moving := 0
		for i in range(5):
			var cv = cvs[i]
			if cv.route > 0.0 and cv.route < 1.0:
				moving += 1
				mid[i] = true
				var own: Vector2 = dest[PremiumPackCeremony.destination_of(m["cards"][i])]
				toward[i] = toward[i] and cv.face_center().distance_to(own) < start[i].distance_to(own) and cv.is_visible_in_tree()
		concurrent = maxi(concurrent, moving)
		log = p.route_log()
		await process_frame
	await _frames(2)
	var want: Array = [[0, "collection"], [1, "exchange"], [2, "collection"], [3, "exchange"], [4, "collection"]]
	_ok(log == want, "NEW -> Collection, DUPLICATE -> Cards Exchange, each card once %s" % str(log))
	_ok(mid == [true, true, true, true, true] and toward == [true, true, true, true, true], "every card observed travelling toward its own destination")
	_ok(concurrent == 1 and arrivals == [0, 1, 2, 3, 4], "serialized: one card in flight at a time (max %d); arrivals in draw order %s" % [concurrent, str(arrivals)])
	var t_ok := true
	for i in range(5):
		t_ok = t_ok and targets[i] == dest[want[i][1]]
	_ok(t_ok, "route end points are the destination icon centres")
	_complete("p12_mixed_routing")

func _p13_repeat_all_new() -> void:
	print("[p13 repeated duplicates + all NEW]")
	var res: Array = []
	for run in range(2):
		var p = await _to_await(Fx.repeat("p13_%d" % run))
		var d := {}
		p.closed.connect(func(_r): d["routes"] = p.route_log(); d["arrivals"] = p.arrivals())
		_tap()
		await _until(p, "COMPLETE")
		await process_frame
		res.append(d)
	_ok(res[0]["routes"] == [[0, "collection"], [1, "exchange"], [2, "exchange"], [3, "exchange"], [4, "exchange"]] and res[0]["arrivals"] == [0, 1, 2, 3, 4] and res[0] == res[1], "repeat fixture: 5 deterministic routes, identical across runs %s" % str(res[0]))
	var q = await _to_await(Fx.all_new("p13n"))
	var dn := {}
	q.closed.connect(func(_r): dn["routes"] = q.route_log())
	_tap()
	await _until(q, "COMPLETE")
	await process_frame
	_ok(dn.get("routes", []).map(func(x): return x[1]) == ["collection", "collection", "collection", "collection", "collection"], "all NEW: every card to Collection")
	_complete("p13_repeat_all_new")

func _p14_no_state_mutation() -> void:
	print("[p14 no state mutation]")
	var path := _uniq("p14")
	var app = AppState.new(path)
	app.request_save()
	var e0: Dictionary = _econ(app.economy)
	var rng0: int = app.economy.packs._rng.state
	var save0 := FileAccess.get_file_as_bytes(path)
	var input := Fx.mixed("p14")
	var input0 := input.duplicate(true)
	var p = _push(input)
	await _frames(2)
	_tap()
	await _until(p, "AWAIT_ROUTE")
	_tap()
	await _until(p, "COMPLETE")
	await _frames(2)
	_ok(input == input0, "caller model unchanged")
	_ok(_econ(app.economy) == e0 and app.economy.packs._rng.state == rng0 and FileAccess.get_file_as_bytes(path) == save0, "economy/Collection/exchange snapshot, pack RNG and save bytes unchanged")
	app.economy.packs.open_premium()
	_ok(_econ(app.economy) != e0 and app.economy.packs._rng.state != rng0, "sensitivity: a real open_premium() is detected")
	_complete("p14_no_state_mutation")

func _p15_complete_once() -> void:
	print("[p15 completion once after 5 arrivals]")
	var p = await _to_await(Fx.mixed("p15"))
	var ev: Array = []
	p.presentation_completed.connect(func(k): ev.append(["completed", k, p.arrivals().size()]))
	p.closed.connect(func(r): ev.append(["closed", r]))
	_tap()
	await _until(p, "COMPLETE")
	await _frames(10)
	_ok(ev == [["completed", "p15", 5], ["closed", "complete"]] and _stack.depth() == 0 and not is_instance_valid(p), "completed once with 5 arrivals, then closed + freed %s" % str(ev))
	_complete("p15_complete_once")

func _p16_lifecycle() -> void:
	print("[p16 lifecycle / Back / re-entry]")
	var tw := _tweens()
	var kids: int = _stack.get_child(0).get_child_count()
	var done: Array = []
	var phases := ["IDLE", "OPENING", "AWAIT_ROUTE", "ROUTING"]
	for i in range(12):
		var target: String = phases[i % 4]
		var p = _push(Fx.mixed("p16_%d" % i))
		p.presentation_completed.connect(func(k): done.append(k))
		await _frames(1)
		if target != "IDLE":
			_tap()
		if target == "AWAIT_ROUTE" or target == "ROUTING":
			await _until(p, "AWAIT_ROUTE")
		if target == "ROUTING":
			_tap()
			await _frames(3)
		var before: String = p.phase()
		var esc := InputEventAction.new()
		esc.action = "ui_cancel"
		esc.pressed = true
		_stack._input(esc)
		_ok(_stack.handle_back() and p.is_open() and p.phase() == before, "%s: Back/Escape consumed, nothing changes" % target)
		if i < 6:
			_stack.clear("route_change")
		else:
			p.close("freed")
	await _frames(10)
	_ok(done.is_empty() and _tweens() == tw and _stack.depth() == 0 and _stack.get_child(0).get_child_count() == kids, "12 clears/closes across all phases: no late completion, no tween/node left")
	var p2 = await _to_await(Fx.mixed("p16_re"))
	_ok(p2.tap() and not p2.tap(), "AWAIT_ROUTE tap routes once; next refused")
	await _until(p2, "COMPLETE")
	_ok(not is_instance_valid(p2) or not p2.tap(), "a completed instance cannot replay")
	var p3 = await _to_await(Fx.all_new("p16_new"))
	_ok(p3.phase() == "AWAIT_ROUTE" and p3.frame_history() == range(1, 10), "re-entry with a new committed model runs clean")
	_close(p3)
	_complete("p16_lifecycle")

func _p17_reduced() -> void:
	print("[p17 Reduced Effects]")
	var full = await _to_await(Fx.mixed("p17f"))
	var want := _info(full)
	_close(full)
	await _frames(2)
	var p = _push(Fx.mixed("p17r"), true)
	var done: Array = []
	p.presentation_completed.connect(func(k): done.append(k))
	await _frames(120)
	_ok(p.phase() == "IDLE", "Reduced: pack waits (no auto-open)")
	_tap()
	await _until(p, "AWAIT_ROUTE")
	_ok(p.frame_history() == [9] and _info(p) == want, "Reduced: frame 09 only; same 5 cards/order/rarity/state/counts/destinations as FULL")
	await _frames(120)
	_ok(p.phase() == "AWAIT_ROUTE" and p.route_log().is_empty(), "Reduced: waits for Tap 2")
	_tap()
	await _until(p, "COMPLETE")
	_ok(done == ["p17r"], "Reduced: routes and completes once")
	_complete("p17_reduced")

func _p18_static_guard() -> void:
	print("[p18 static authority guard]")
	for path in SOURCES:
		var hits := _hits(_code_only(FileAccess.get_file_as_string(path)), FORBIDDEN)
		_ok(hits.is_empty(), "%s: no authority / RNG / reordering identifiers %s" % [path.get_file(), str(hits)])
	var inj := _code_only(FileAccess.get_file_as_string(SOURCES[0])) + "\n\tpacks.open_premium()\n\tcards.sort()\n"
	_ok(_hits(inj, FORBIDDEN).size() >= 2, "sensitivity: injected open_premium / sort flagged")
	_complete("p18_static_guard")

func _p19_card_truth() -> void:
	print("[p19 five-card text truth]")
	for m in [Fx.mixed("p19a"), Fx.repeat("p19b"), Fx.all_new("p19c")]:
		var p = await _to_await(m)
		var got: Array = p.get_card_views().map(func(cv): return [_text(cv, "Name"), _text(cv, "Rarity"), _text(cv, "State"), _text(cv, "Copies"), (cv.find_child("CardArt", true, false) as TextureRect).texture.resource_path])
		var want: Array = m["cards"].map(func(c): return [c["name"], UiText.t("RARITY_" + c["rarity"]), UiText.t("PACK_CARD_NEW" if c["is_new"] else "PACK_CARD_DUPLICATE"), UiText.t("PACK_CARD_OWNED", [c["copies_after"]]), c["art"]])
		_ok(got == want and got[0][1] in RARE_PLUS, "%s: name / rarity / NEW-DUPLICATE / count / canonical art per card; card 0 %s" % [m["presentation_id"], got[0][1]])
		_ok(p.get_card_views().all(func(cv): return cv.find_children("*", "TextureRect", true, false).size() == 1), "%s: no second frame over the card art" % m["presentation_id"])
		_close(p)
	_complete("p19_card_truth")

# ------------------------------------------------------------------ helpers ----

class RewardStub:
	extends RefCounted
	func grant(_tx, _reward) -> bool:
		return true
	func already_applied(_tx) -> bool:
		return false

func _push(model: Dictionary, reduced := false):
	var r := PremiumPackCeremony.create_premium(model, reduced)
	if not r["ok"]:
		_ok(false, "fixture rejected: %s" % r["reason"])
		return null
	_stack.push(r["popup"])
	return r["popup"]

func _to_await(model: Dictionary, reduced := false):
	var p = _push(model, reduced)
	await _frames(2)
	_tap()
	await _until(p, "AWAIT_ROUTE")
	return p

func _tap() -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = Vector2(SIZE) * Vector2(0.5, 0.86)
	ev.global_position = ev.position
	ev.pressed = true
	_sub.push_input(ev)
	var up := ev.duplicate()
	up.pressed = false
	_sub.push_input(up)

func _until(p, phase_name: String) -> void:
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		if not is_instance_valid(p) or p.phase() == phase_name:
			return
		await process_frame
	_ok(false, "timed out waiting for %s" % phase_name)

func _holds(binds: Array) -> Array:
	var out: Array = []
	for i in range(binds.size() - 1):
		out.append([binds[i][0], (binds[i + 1][1] - binds[i][1]) / 1e6])
	return out

func _info(p) -> Dictionary:
	var cards: Array = []
	for cv in p.get_card_views():
		cards.append([(cv.find_child("CardArt", true, false) as TextureRect).texture.resource_path, _text(cv, "Name"), _text(cv, "Rarity"), _text(cv, "State"), _text(cv, "Copies"), cv.slot_point(), PremiumPackCeremony.destination_of(cv.card)])
	return {"phase": p.phase(), "stage": p.get_stage().is_visible_in_tree(), "cards": cards, "dest": p.get_destinations_layer().is_visible_in_tree(), "hint": p.get_hint().text}

func _text(node: Node, n: String) -> String:
	var c := node.find_child(n, true, false)
	if c is Label:
		return c.text
	return (c.get_node("Text") as Label).text if c != null else ""

func _frame_nodes(p) -> int:
	return p.find_children("*", "TextureRect", true, false).filter(func(t): return t.is_visible_in_tree() and t.texture != null and String(t.texture.resource_path).contains("/pack_opening/")).size()

func _buttons(p) -> Array:
	return p.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree())

func _center(c: Control) -> Vector2:
	return c.position + c.size * 0.5

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

func _hits(src: String, words: Array) -> Array:
	var out: Array = []
	for w in words:
		if RegEx.create_from_string("(?<![A-Za-z_])" + w + "(?![a-z])").search(src) != null:
			out.append(w)
	return out

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _uniq(tag: String) -> String:
	var p := "user://m43c005c007_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M43-C005-C007 premium pack presentation evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
