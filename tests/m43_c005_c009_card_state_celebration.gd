extends SceneTree
## M43-C005-C009 (SB-M43-067) — first-new-card celebration + duplicate-count presentation.
## Real ModalStack + shipping StandardPackCeremony / PremiumPackCeremony (shared CardView),
## deterministic COMMITTED fixture models and real C008 receipts (AppState.commit_pack). Player
## taps are real InputEventMouseButton through SubViewport.push_input. Expected/completed ledger.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c009_card_state_celebration.gd

const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")
const StandardPackModel = preload("res://scripts/ui/ceremony/standard_pack_model.gd")
const PremiumPackModel = preload("res://scripts/ui/ceremony/premium_pack_model.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const SFx = preload("res://tests/support/standard_pack_fixtures.gd")
const PFx = preload("res://tests/support/premium_pack_fixtures.gd")
const CardView = StandardPackCeremony.CardView

const SIZE := Vector2i(1080, 1920)
const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]
const GLOW := "res://assets/ui/final/collection/states/card_new_glow.png"
## Canonical asset bytes this task must not change (sha256 at the C009 baseline 3dda957).
const GLOW_SHA := "b972e9c51e48cef150a7e12b41545ad34ddee128625bdd35139482e98f595afb"
const DEST_SHA := {
	"res://assets/ui/final/home/shortcuts/icon_shortcut_collection.png": "bde7a0442a016c272897e2487a85c2895f4883afbffd07efd5126a54c9d05872",
	"res://assets/ui/final/home/shortcuts/icon_shortcut_cards_exchange.png": "5de717cbe474fdc46bad67e3bcf78cced1272a5f16843fa9b570d5f3ab63cec8",
}
## Restraint ceiling for the one NEW pulse (task: restrained pop, no overlap with neighbours).
const RESTRAINED_MAX_SCALE := 1.05
const STD_MANIFEST := "res://coordination/sessions/M43-C005-C006/STANDARD_FRAME_ALPHA_MANIFEST_V03.json"
const PREM_MANIFEST := "res://coordination/sessions/M43-C005-C007/PREMIUM_FRAME_MANIFEST_V01.json"
const SOURCES := ["res://scripts/ui/ceremony/standard_pack_ceremony.gd", "res://scripts/ui/ceremony/premium_pack_ceremony.gd"]
## Card-state presentation must never read live Collection / economy / transaction state.
const NO_LIVE := ["CollectionInventory", "owned", "economy", "EconomyServices", "AppState", "pack_receipt",
	"PackCommitTransaction", "PackReceiptLedger", "CardPackService", "open_standard", "open_premium", "add_card",
	"grant", "claim", "exchange_card", "save", "Save", "RandomNumberGenerator", "randi", "randf",
	"GameFeelFlow", "GFF", "Saltmire", "Spark"]

var EXPECTED_CASES := [
	"k01_truth_from_committed_row", "k02_new_requires_first_copy", "k03_new_hold_text", "k04_new_glow_asset",
	"k05_full_one_celebration", "k06_reduced_no_bounce", "k07_duplicate_badge", "k08_extras_formula",
	"k11_new_never_x0", "k12_repeat_sequential", "k13_standard_mixed_layout", "k14_premium_mixed_layout",
	"k15_all_new_standard", "k16_all_new_premium", "k17_all_duplicate_standard", "k18_all_duplicate_premium",
	"k19_order_deterministic", "k20_relayout_no_retrigger", "k21_tap2_gate", "k22_routing_unchanged",
	"k23_reopen_no_authority", "k24_no_live_collection", "k25_no_authority_calls", "k26_assets_unchanged",
	"k27_sensitivity",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack

func _initialize() -> void:
	await process_frame
	_mount()
	await _k01_truth_from_committed_row()
	_k02_new_requires_first_copy()
	await _k03_new_hold_text()
	await _k04_new_glow_asset()
	await _k05_full_one_celebration()
	await _k06_reduced_no_bounce()
	_k07_duplicate_badge()
	_k08_extras_formula()
	_k11_new_never_x0()
	await _k12_repeat_sequential()
	await _k13_14_layout()
	await _k15_18_uniform_packs()
	await _k19_order_deterministic()
	await _k20_relayout_no_retrigger()
	await _k21_tap2_gate()
	await _k22_routing_unchanged()
	await _k23_reopen_no_authority()
	_k24_25_static()
	_k26_assets_unchanged()
	_k27_sensitivity()
	_unmount()
	await _frames(3)
	_cleanup()
	_done()

# ------------------------------------------------------------------ truth ----

func _k01_truth_from_committed_row() -> void:
	print("[k01 card state = committed row, never live Collection]")
	var app = AppState.new(_uniq("k01"))
	var r: Dictionary = app.commit_pack("premium", "c009_k01")
	var model: Dictionary = r["model"]
	var want := _texts_from_rows(model["cards"])
	# Live Collection moves on afterwards: every committed card gains 4 more copies.
	for c in model["cards"]:
		app.economy.collection.add_copies(c["card_id"], 4)
	var p = await _to_await(PremiumPackCeremony.create_premium(app.pack_presentation_model("c009_k01"))["popup"])
	_ok(_hold_texts(p) == want, "reopened ceremony shows the COMMITTED NEW / FIRST COPY / EXTRAS truth, not the live counts %s" % str(_hold_texts(p)))
	var live_new: Array = model["cards"].map(func(c): return app.economy.collection.owned(c["card_id"]) == 1)
	_ok(live_new.count(true) == 0 and _hold_texts(p).any(func(t): return t[1] == UiText.t("PACK_CARD_FIRST_COPY")) == model["cards"].any(func(c): return c["is_new"]), "live Collection now says no card is a first copy; the presentation still follows is_new")
	_close(p)
	_complete("k01_truth_from_committed_row")

func _k02_new_requires_first_copy() -> void:
	print("[k02 NEW requires copies_after == 1 (existing model truth)]")
	var bad_s := SFx.mixed("k02")
	bad_s["cards"][0]["copies_after"] = 2
	var bad_p := PFx.mixed("k02p")
	bad_p["cards"][2]["copies_after"] = 3
	var dup1 := SFx.mixed("k02d")
	dup1["cards"][1]["copies_after"] = 1
	_ok(StandardPackModel.validate(bad_s)["reason"] == "card_0_copies" and PremiumPackModel.validate(bad_p)["reason"] == "card_2_copies" and StandardPackModel.validate(dup1)["reason"] == "card_1_copies", "NEW with copies 2/3 and DUPLICATE with copies 1 are rejected before any presentation")
	_ok(not StandardPackCeremony.create(bad_s)["ok"] and not PremiumPackCeremony.create_premium(bad_p)["ok"], "the ceremonies fail closed on them")
	_complete("k02_new_requires_first_copy")

func _k03_new_hold_text() -> void:
	print("[k03 NEW hold text]")
	var p = await _to_await(_std(SFx.mixed("k03")))
	var t := _hold_texts(p)
	_ok(t[0] == [UiText.t("PACK_CARD_NEW"), "FIRST COPY"] and t[2] == [UiText.t("PACK_CARD_NEW"), "FIRST COPY"], "NEW cards read NEW + FIRST COPY %s" % str(t))
	_ok(UiText.t("PACK_CARD_NEW") == "NEW" and UiText.t("PACK_CARD_DUPLICATE") == "DUPLICATE", "badge text is explicit (not colour / glow alone)")
	_close(p)
	_complete("k03_new_hold_text")

func _k04_new_glow_asset() -> void:
	print("[k04 canonical new-card glow]")
	var p = await _to_await(_std(SFx.mixed("k04")))
	var cvs: Array = p.get_card_views()
	var glows: Array = cvs.map(func(cv): return cv.get_glow())
	_ok(glows[0] != null and glows[2] != null and glows[1] == null, "NEW cards own a glow, the DUPLICATE does not")
	_ok(glows[0].texture.resource_path == GLOW and glows[2].texture.resource_path == GLOW and FileAccess.get_sha256(GLOW) == GLOW_SHA, "glow texture is the canonical card_new_glow.png, bytes unchanged")
	var layer: Control = p.get_glow_layer()
	var under := true
	for g in [glows[0], glows[2]]:
		under = under and g.get_parent() == layer
	for cv in cvs:
		under = under and layer.get_index() < cv.get_index()
	under = under and layer.get_index() < p.get_destinations_layer().get_index()
	_ok(under, "glows live in one layer drawn UNDER every card (never over card art or text)")
	_ok(glows[0].visible and is_equal_approx(glows[0].modulate.a, CardView.GLOW_REST), "settled hold: glow visible at rest alpha %.2f" % glows[0].modulate.a)
	_ok(glows[0].get_global_rect().get_center().distance_to(_face_center(cvs[0])) < 1.0, "glow centred on its card face")
	_close(p)
	_complete("k04_new_glow_asset")

## FULL: one bounded pulse per NEW card, after the cards settled, before the pack fades and
## before destinations / Tap 2; no flash, no loop.
func _k05_full_one_celebration() -> void:
	print("[k05 FULL: one restrained celebration per NEW card]")
	var p = _std(SFx.mixed("k05"))
	var log := _watch(p)
	var max_scale := [1.0]
	var max_glow := [0.0]
	var during_dest := [false]
	var emerge_done_at_first := [true]
	var sample := func():
		if not is_instance_valid(p) or p.phase() != "OPENING":
			return
		for cv in p.get_card_views():
			if cv.get_glow() != null:
				max_scale[0] = maxf(max_scale[0], cv.scale.x)
				max_glow[0] = maxf(max_glow[0], cv.glow_alpha())
				if cv.celebrate > 0.0 and cv.celebrate < 1.0:
					during_dest[0] = during_dest[0] or p.get_destinations_layer().visible or p.get_stage().modulate.a > 0.0
					emerge_done_at_first[0] = emerge_done_at_first[0] and p.get_card_views().all(func(c): return c.emerge >= 1.0)
	process_frame.connect(sample)
	_stack.push(p)
	await _frames(2)
	_tap()
	await _until(p, "AWAIT_ROUTE")
	process_frame.disconnect(sample)
	_ok(log == [0, 2], "celebrated exactly once per NEW card, model order: %s" % str(log))
	_ok(max_scale[0] > 1.02 and max_scale[0] <= RESTRAINED_MAX_SCALE, "pulse bounded: peak card scale %.3f (restrained ceiling %.2f, independent of the code constant)" % [max_scale[0], RESTRAINED_MAX_SCALE])
	_ok(max_glow[0] <= 1.0 + 1e-6 and max_glow[0] > CardView.GLOW_REST, "glow peaks once then settles (peak %.2f)" % max_glow[0])
	_ok(emerge_done_at_first[0] and not during_dest[0], "pulse only after every card settled in its slot and the pack faded (accepted pack-out timing); destinations hidden during it")
	var cvs: Array = p.get_card_views()
	_ok(cvs.all(func(cv): return is_equal_approx(cv.scale.x, 1.0)) and is_equal_approx(cvs[0].glow_alpha(), CardView.GLOW_REST), "settled hold before Tap 2: scale 1.0, glow at rest")
	var src := _code_only(FileAccess.get_file_as_string(SOURCES[0]))
	_ok(not RegEx.create_from_string("set_loops|rotation|shake|flash|confetti|strobe").search(src), "no loop / spin / shake / flash / confetti in the ceremony source")
	_ok(_plan_props(p).count("celebration") == 1, "one celebration step in the shared sequencer plan")
	await _route_and_close(p)
	_complete("k05_full_one_celebration")

func _k06_reduced_no_bounce() -> void:
	print("[k06 Reduced: no bounce / pulse / flash, truth explicit]")
	for kind in ["standard", "premium"]:
		var p = _std(SFx.mixed("k06s"), true) if kind == "standard" else _prem(PFx.mixed("k06p"), true)
		var log := _watch(p)
		var max_scale := [1.0]
		var max_glow := [0.0]
		var sample := func():
			if is_instance_valid(p) and p.phase() in ["OPENING", "AWAIT_ROUTE"]:
				for cv in p.get_card_views():
					max_scale[0] = maxf(max_scale[0], cv.scale.x)
					max_glow[0] = maxf(max_glow[0], cv.glow_alpha())
		process_frame.connect(sample)
		_stack.push(p)
		await _frames(2)
		_tap()
		await _until(p, "AWAIT_ROUTE")
		await _frames(3)
		process_frame.disconnect(sample)
		_ok(log.is_empty() and is_equal_approx(max_scale[0], 1.0), "%s Reduced: no celebration, face scale never above 1.0 (%.3f)" % [kind, max_scale[0]])
		_ok(max_glow[0] <= CardView.GLOW_REST + 1e-6 and p.get_card_views().filter(func(cv): return cv.get_glow() != null).all(func(cv): return is_equal_approx(cv.glow_alpha(), CardView.GLOW_REST)), "%s Reduced: static glow at rest, never brighter (no flash)" % kind)
		_ok(_hold_texts(p) == _texts_from_rows(p.get_model()["cards"]) and not _plan_props(p).has("celebration"), "%s Reduced: same NEW / FIRST COPY / EXTRAS truth, no celebration step" % kind)
		await _route_and_close(p)
	_complete("k06_reduced_no_bounce")

func _k07_duplicate_badge() -> void:
	print("[k07 DUPLICATE badge]")
	var cv := CardView.new(SFx.card("s7_c4", false, 2), 0, false)
	_ok(_text(cv, "State") == "DUPLICATE" and _text(cv, "Copies") == "EXTRAS x1" and cv.get_glow() == null, "DUPLICATE row: DUPLICATE badge + EXTRAS x1, no glow")
	cv.free()
	_complete("k07_duplicate_badge")

func _k08_extras_formula() -> void:
	print("[k08-k10 EXTRAS xN, N = copies_after - 1]")
	var got: Array = []
	for n in [2, 3, 4, 8, 12, 100]:
		var cv := CardView.new(SFx.card("s1_c1", false, n), 0, false)
		got.append([n, _text(cv, "Copies"), CardView.extra_copies(cv.card)])
		cv.free()
	_ok(got == [[2, "EXTRAS x1", 1], [3, "EXTRAS x2", 2], [4, "EXTRAS x3", 3], [8, "EXTRAS x7", 7], [12, "EXTRAS x11", 11], [100, "EXTRAS x99", 99]], "copies_after 2/3/4/8/12/100 -> EXTRAS x1/x2/x3/x7/x11/x99 %s" % str(got))
	_complete("k08_extras_formula")

func _k11_new_never_x0() -> void:
	print("[k11 NEW never shows EXTRAS x0]")
	var texts: Array = []
	for m in [SFx.mixed(), SFx.all_new(), SFx.repeat(), SFx.triple(), SFx.all_duplicate(), PFx.mixed(), PFx.all_new(), PFx.repeat(), PFx.all_duplicate()]:
		for c in m["cards"]:
			var cv := CardView.new(c, 0, false)
			texts.append([c["is_new"], _text(cv, "Copies")])
			cv.free()
	_ok(not texts.any(func(t): return t[1].contains("x0")) and texts.filter(func(t): return t[0]).all(func(t): return t[1] == "FIRST COPY") and texts.filter(func(t): return not t[0]).all(func(t): return t[1].begins_with("EXTRAS x")), "every NEW row reads FIRST COPY, every DUPLICATE row EXTRAS xN (N >= 1), nothing reads x0 (%d rows)" % texts.size())
	_complete("k11_new_never_x0")

func _k12_repeat_sequential() -> void:
	print("[k12 same card repeated in one pack]")
	var p = await _to_await(_std(SFx.triple("k12")))
	var t := _hold_texts(p)
	_ok(t == [["NEW", "FIRST COPY"], ["DUPLICATE", "EXTRAS x1"], ["DUPLICATE", "EXTRAS x2"]], "Standard s8_c3 x3: FIRST COPY / EXTRAS x1 / EXTRAS x2 in receipt order %s" % str(t))
	_close(p)
	var q = await _to_await(_prem(PFx.repeat("k12p")))
	var tq := _hold_texts(q)
	_ok(tq.map(func(x): return x[1]) == ["FIRST COPY", "EXTRAS x1", "EXTRAS x2", "EXTRAS x3", "EXTRAS x4"], "Premium repeat: FIRST COPY / x1 / x2, then the other card x3 / x4 %s" % str(tq))
	_close(q)
	# Real C008 receipt with a repeated card (seeded test RNG): rows count up in receipt order.
	var app = AppState.new(_uniq("k12"))
	var seeds := 0
	var rng := RandomNumberGenerator.new()
	for s in range(1, 200000):
		rng.seed = s
		app.economy.packs._rng.state = rng.state
		var probe := RandomNumberGenerator.new()
		probe.state = rng.state
		var ids: Array = app.economy.packs._card_ids
		var d: Array = [ids[probe.randi_range(0, ids.size() - 1)], ids[probe.randi_range(0, ids.size() - 1)], ids[probe.randi_range(0, ids.size() - 1)]]
		if d[0] == d[1]:
			seeds = s
			break
	var r: Dictionary = app.commit_pack("standard", "c009_k12")
	var c = await _to_await(_std(r["model"]))
	var tc := _hold_texts(c)
	_ok(seeds > 0 and tc[0][1] == "FIRST COPY" and tc[1][1] == "EXTRAS x1", "committed C008 receipt (card drawn twice): FIRST COPY then EXTRAS x1 %s" % str(tc))
	_close(c)
	_complete("k12_repeat_sequential")

# ------------------------------------------------------------------ layout ----

func _k13_14_layout() -> void:
	print("[k13/k14 Standard 3-card + Premium 3+2 layouts, 5 viewports]")
	for kind in ["standard", "premium"]:
		var problems: Array = []
		for sz in SIZES:
			_sub.size = sz
			await _frames(2)
			var p = await _to_await(_std(SFx.mixed("k13_%d" % sz.y)) if kind == "standard" else _prem(PFx.mixed("k14_%d" % sz.y)))
			var bad := _layout_problem(p)
			if not bad.is_empty():
				problems.append("%dx%d: %s" % [sz.x, sz.y, bad])
			if not _geometry_preserved(p):
				problems.append("%dx%d: slots differ from the accepted geometry" % [sz.x, sz.y])
			_close(p)
			await _frames(2)
		_sub.size = SIZE
		await _frames(2)
		_ok(problems.is_empty(), "%s mixed: accepted geometry, no overlap / clipping / text overflow at 5 viewports %s" % [kind, str(problems)])
	_complete("k13_standard_mixed_layout")
	_complete("k14_premium_mixed_layout")

func _k15_18_uniform_packs() -> void:
	print("[k15-k18 all NEW / all DUPLICATE]")
	var cases := [["k15_all_new_standard", _std(SFx.all_new("k15"))], ["k16_all_new_premium", _prem(PFx.all_new("k16"))],
		["k17_all_duplicate_standard", _std(SFx.all_duplicate("k17"))], ["k18_all_duplicate_premium", _prem(PFx.all_duplicate("k18"))]]
	for c in cases:
		var p = c[1]
		var log := _watch(p)
		_stack.push(p)
		await _frames(2)
		_tap()
		await _until(p, "AWAIT_ROUTE")
		var rows: Array = p.get_model()["cards"]
		var n_new: int = rows.filter(func(r): return r["is_new"]).size()
		_ok(_hold_texts(p) == _texts_from_rows(rows) and log.size() == n_new and _layout_problem(p).is_empty(), "%s: texts %s, %d celebrations, layout clean" % [c[0], str(_hold_texts(p).map(func(t): return t[1])), log.size()])
		_ok(p.get_card_views().filter(func(cv): return cv.get_glow() != null).size() == n_new, "%s: glow only on NEW cards" % c[0])
		await _route_and_close(p)
		_complete(c[0])

# ------------------------------------------------------------------ sequencing ----

func _k19_order_deterministic() -> void:
	print("[k19 celebration order deterministic]")
	var runs: Array = []
	for i in range(2):
		var p = _prem(PFx.all_new("k19_%d" % i))
		var log := _watch(p)
		_stack.push(p)
		await _frames(2)
		_tap()
		await _until(p, "AWAIT_ROUTE")
		runs.append(log.duplicate())
		_close(p)
		await _frames(2)
	_ok(runs[0] == [0, 1, 2, 3, 4] and runs[1] == runs[0], "Premium all-NEW celebrates 0,1,2,3,4 (model order) on every run %s" % str(runs))
	var q = _prem(PFx.mixed("k19m"))
	var logq := _watch(q)
	_stack.push(q)
	await _frames(2)
	_tap()
	await _until(q, "AWAIT_ROUTE")
	_ok(logq == [0, 2, 4], "Premium mixed celebrates only NEW cards 0,2,4 in order %s" % str(logq))
	_close(q)
	_complete("k19_order_deterministic")

func _k20_relayout_no_retrigger() -> void:
	print("[k20 relayout / resize / reads / destinations / Tap 2 never retrigger]")
	var p = _prem(PFx.mixed("k20"))
	var log := _watch(p)
	_stack.push(p)
	await _frames(2)
	_tap()
	await _until(p, "AWAIT_ROUTE")
	for sz in [Vector2i(1170, 2532), Vector2i(1536, 2048), SIZE, Vector2i(1290, 2796), SIZE]:
		_sub.size = sz
		await _frames(2)
	p.get_model()
	p.get_card_views()
	var cvs: Array = p.get_card_views()
	_ok(log == [0, 2, 4] and cvs.all(func(cv): return is_equal_approx(cv.scale.x, 1.0)) and cvs.filter(func(cv): return cv.get_glow() != null).all(func(cv): return is_equal_approx(cv.glow_alpha(), CardView.GLOW_REST)), "5 resizes + model reads: still 3 celebrations, scale 1.0, glow at rest %s" % str(log))
	_tap()
	await _until(p, "COMPLETE")
	await _frames(2)
	_ok(log == [0, 2, 4], "Tap 2 / routing / completion: no further celebration %s" % str(log))
	_complete("k20_relayout_no_retrigger")

func _k21_tap2_gate() -> void:
	print("[k21 Tap 2 blocked until AWAIT_ROUTE, also during the celebration]")
	var p = _prem(PFx.all_new("k21"))
	_stack.push(p)
	await _frames(2)
	_tap()
	var refused := 0
	var mid_celebration := false
	var deadline := Time.get_ticks_msec() + 20000
	while p.phase() == "OPENING" and Time.get_ticks_msec() < deadline:
		if p.celebration > 0.0 and p.celebration < 1.0:
			mid_celebration = true
			_tap()
			if p.phase() == "OPENING":
				refused += 1
		await process_frame
	_ok(mid_celebration and refused > 0 and p.phase() == "AWAIT_ROUTE" and p.route_log().is_empty(), "%d taps during the celebration refused; still waits in AWAIT_ROUTE, nothing routed" % refused)
	await _frames(20)
	_ok(p.phase() == "AWAIT_ROUTE", "no auto Tap 2")
	await _route_and_close(p)
	_complete("k21_tap2_gate")

func _k22_routing_unchanged() -> void:
	print("[k22 routing destinations unchanged]")
	for m in [SFx.mixed("k22s"), PFx.mixed("k22p"), SFx.triple("k22t"), PFx.all_duplicate("k22d")]:
		var p = await _to_await(_std(m) if m["cards"].size() == 3 else _prem(m))
		var want: Array = []
		for i in range(m["cards"].size()):
			want.append([i, "collection" if m["cards"][i]["is_new"] else "exchange"])
		var dest_ok: bool = p.get_card_views().all(func(cv): return cv.destination_point().is_equal_approx(p.get_destination("collection" if cv.card["is_new"] else "exchange").position + StandardPackCeremony.DEST_BOX * 0.5))
		var got: Array = []
		p.presentation_completed.connect(func(_id): got.append_array(p.route_log()))
		_tap()
		await _until(p, "COMPLETE")
		_ok(got == want and dest_ok, "%s: NEW -> Collection, DUPLICATE -> Exchange, in model order" % m["presentation_id"])
		await _frames(2)
	_complete("k22_routing_unchanged")

func _k23_reopen_no_authority() -> void:
	print("[k23 reopening a committed C008 model changes no authority]")
	var app = AppState.new(_uniq("k23"))
	app.commit_pack("standard", "c009_k23s")
	app.commit_pack("premium", "c009_k23p")
	var a0 := _auth(app)
	var counts := []
	for run in range(2):
		for tx in ["c009_k23s", "c009_k23p"]:
			var m: Dictionary = app.pack_presentation_model(tx)
			var p = _std(m) if tx.ends_with("s") else _prem(m)
			var log := _watch(p)
			_stack.push(p)
			await _frames(2)
			_tap()
			await _until(p, "AWAIT_ROUTE")
			counts.append(log.size())
			_tap()
			await _until(p, "COMPLETE")
			await _frames(2)
	_ok(_auth(app) == a0, "4 full presentations (celebration incl.): economy, Collection, rewards, RNG, ledger, save bytes unchanged")
	_ok(counts[0] == counts[2] and counts[1] == counts[3], "a NEW ceremony instance replays the visual celebration (presentation only) %s" % str(counts))
	_complete("k23_reopen_no_authority")

# ------------------------------------------------------------------ static / assets ----

func _k24_25_static() -> void:
	print("[k24/k25 no live Collection query, no authority calls]")
	var hits: Array = []
	for path in SOURCES:
		var src := _code_only(FileAccess.get_file_as_string(path))
		for w in NO_LIVE:
			if RegEx.create_from_string("(?<![A-Za-z_])" + w + "(?![a-z])").search(src) != null:
				hits.append("%s:%s" % [path.get_file(), w])
	_ok(hits.is_empty(), "ceremony + CardView sources: no Collection / economy / transaction / save / RNG / plugin access %s" % str(hits))
	var src0 := _code_only(FileAccess.get_file_as_string(SOURCES[0]))
	_ok(src0.contains("int(c[\"copies_after\"]) - 1") and src0.contains("bool(c[\"is_new\"])"), "count line is derived only from the committed row fields")
	_complete("k24_no_live_collection")
	_complete("k25_no_authority_calls")

func _k26_assets_unchanged() -> void:
	print("[k26 frame / glow / destination / card asset bytes]")
	var std_ok := true
	for f in JSON.parse_string(FileAccess.get_file_as_string(STD_MANIFEST))["frames"]:
		std_ok = std_ok and FileAccess.get_sha256(StandardPackCeremony.FRAME_DIR + String(f["frame"])) == String(f["sha256_after"])
	var prem_ok := true
	for f in JSON.parse_string(FileAccess.get_file_as_string(PREM_MANIFEST))["frames"]:
		prem_ok = prem_ok and FileAccess.get_sha256("res://" + String(f["final_path"])) == String(f["sha256"])
	_ok(std_ok and prem_ok, "9 Standard + 9 Premium shipping frames == their manifests")
	var dest_ok := true
	for path in DEST_SHA:
		dest_ok = dest_ok and FileAccess.get_sha256(path) == DEST_SHA[path]
	_ok(dest_ok and FileAccess.get_sha256(GLOW) == GLOW_SHA, "destination icons + card_new_glow bytes unchanged")
	_complete("k26_assets_unchanged")

## Comparator sensitivity (the source mutations are in CLAUDE_LOG_V01 §4).
func _k27_sensitivity() -> void:
	print("[k27 comparator sensitivity]")
	var rows: Array = SFx.triple()["cards"]
	var off_by_one: Array = rows.map(func(c): return ["NEW" if c["is_new"] else "DUPLICATE", "FIRST COPY" if c["is_new"] else "EXTRAS x%d" % int(c["copies_after"])])
	var shows_x0: Array = rows.map(func(c): return ["NEW" if c["is_new"] else "DUPLICATE", "EXTRAS x%d" % (int(c["copies_after"]) - 1)])
	_ok(off_by_one != _texts_from_rows(rows) and shows_x0 != _texts_from_rows(rows), "the text oracle rejects copies_after-as-extras and NEW-as-EXTRAS x0")
	var expected := _texts_from_rows(rows)
	_ok(expected == [["NEW", "FIRST COPY"], ["DUPLICATE", "EXTRAS x1"], ["DUPLICATE", "EXTRAS x2"]], "oracle itself: x1 for copies_after 2 (not x2)")
	_complete("k27_sensitivity")

# ------------------------------------------------------------------ helpers ----

## Independent oracle of the hold text, from the committed rows only.
func _texts_from_rows(rows: Array) -> Array:
	return rows.map(func(c): return ["NEW" if c["is_new"] else "DUPLICATE", "FIRST COPY" if c["is_new"] else "EXTRAS x%d" % (int(c["copies_after"]) - 1)])

func _hold_texts(p) -> Array:
	return p.get_card_views().map(func(cv): return [_text(cv, "State"), _text(cv, "Copies")])

func _watch(p) -> Array:
	var log: Array = []
	for cv in p.get_card_views():
		cv.celebrated.connect(func(i): log.append(i))
	return log

func _plan_props(p) -> Array:
	return p._open_plan().map(func(s): return String(s["property"]))

func _std(m: Dictionary, reduced := false):
	var r := StandardPackCeremony.create(m, reduced)
	if not r["ok"]:
		_ok(false, "fixture rejected: %s" % r["reason"])
	return r["popup"]

func _prem(m: Dictionary, reduced := false):
	var r := PremiumPackCeremony.create_premium(m, reduced)
	if not r["ok"]:
		_ok(false, "fixture rejected: %s" % r["reason"])
	return r["popup"]

func _to_await(p):
	_stack.push(p)
	await _frames(2)
	_tap()
	await _until(p, "AWAIT_ROUTE")
	return p

func _route_and_close(p) -> void:
	_tap()
	await _until(p, "COMPLETE")
	await _frames(2)

func _face_center(cv) -> Vector2:
	return cv.get_global_rect().position + cv.pivot_offset * cv.scale

## Accepted geometry, recomputed independently from the C006 / C007 layout rules.
func _geometry_preserved(p) -> bool:
	var sz: Vector2 = p.get_layer().size
	var n: int = p.get_card_views().size()
	var cw := minf(300.0, (sz.x - 40.0 - 48.0) / 3.0)
	var want: Array = []
	if n == 3:
		var row_w := 3.0 * cw + 48.0
		for i in range(3):
			want.append(Vector2((sz.x - row_w) * 0.5 + cw * 0.5 + i * (cw + 24.0), sz.y * 0.5))
	else:
		var card_h := cw * 1.5 + CardView.LABEL_H
		var top := (sz.y - (2.0 * card_h + 28.0)) * 0.5
		for r in range(2):
			var row: Array = [[0, 1, 2], [3, 4]][r]
			var row_w := row.size() * cw + (row.size() - 1) * 24.0
			for j in range(row.size()):
				want.append(Vector2((sz.x - row_w) * 0.5 + cw * 0.5 + j * (cw + 24.0), top + r * (card_h + 28.0) + cw * 0.75))
	for i in range(n):
		if not p.get_card_views()[i].slot_point().is_equal_approx(want[i]):
			return false
	return true

## Cards (face + labels) inside the safe layer, never overlapping each other, the destinations or
## the hint; every card text fits its card width.
func _layout_problem(p) -> String:
	var safe: Rect2 = p.get_layer().get_global_rect().grow(1.0)
	var cvs: Array = p.get_card_views()
	for a in range(cvs.size()):
		var r: Rect2 = cvs[a].get_global_rect()
		if not safe.encloses(r):
			return "%s outside safe area" % cvs[a].name
		for b in range(a + 1, cvs.size()):
			if r.intersects(cvs[b].get_global_rect()):
				return "cards %d and %d overlap" % [a, b]
		for k in ["collection", "exchange"]:
			var d: Control = p.get_destination(k)
			if r.intersects(d.get_global_rect()) or r.intersects(d.get_node("Label").get_global_rect()):
				return "%s overlaps %s" % [cvs[a].name, k]
		if r.intersects(p.get_hint().get_global_rect()):
			return "%s overlaps the hint" % cvs[a].name
		for n in ["Name", "Copies"]:
			var l: Label = cvs[a].find_child(n, true, false)
			if l.get_minimum_size().x > cvs[a].size.x + 0.5:
				return "%s %s wider than the card (%d > %d)" % [cvs[a].name, n, int(l.get_minimum_size().x), int(cvs[a].size.x)]
		for n in ["State", "Rarity"]:
			var chip: Control = cvs[a].find_child(n, true, false)
			if chip.get_minimum_size().x > cvs[a].size.x + 0.5:
				return "%s %s chip wider than the card" % [cvs[a].name, n]
	return ""

func _auth(app) -> Dictionary:
	var s: Dictionary = app.economy.snapshot()
	s["hearts"].erase("anchor")
	s["speed"].erase("clock_high_water")
	return {"econ": s, "rng": app.economy.packs._rng.state, "save": FileAccess.get_file_as_bytes(app.save._path)}

func _tap() -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.position = Vector2(_sub.size) * Vector2(0.5, 0.82)
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

func _text(node: Node, n: String) -> String:
	var c := node.find_child(n, true, false)
	if c is Label:
		return c.text
	return (c.get_node("Text") as Label).text if c != null else ""

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

func _code_only(text: String) -> String:
	var out := PackedStringArray()
	for line in text.split("\n"):
		var i := line.find("#")
		out.append(line if i == -1 else line.substr(0, i))
	return "\n".join(out)

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _uniq(tag: String) -> String:
	var p := "user://m43c005c009_%s_%d.save" % [tag, Time.get_ticks_usec()]
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
	print("M43-C005-C009 card state celebration evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
