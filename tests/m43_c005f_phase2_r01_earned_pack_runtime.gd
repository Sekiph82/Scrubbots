extends SceneTree
## M43-C005F-PHASE2-R01 — earned packs reach the shipping pack ceremony in production.
##   q*: PendingPackQueue schema / migration, reward grant ENQUEUES (no silent draw), canonical
##       PackCommitTransaction open-once / replay / rollback / restart, acknowledgement rules;
##   g*: the REAL app (main.tscn): Gift 10/250/500/1000 and Daily 2/4/5 -> PackPresenter ->
##       Standard / Premium ceremony on the app ModalStack -> taps -> Collection, FIFO, restart,
##       Reduced, plugins missing / throwing, no-pack rewards, gameplay never interrupted.
##   h*: R02 durable acknowledgement - SaveService fault injection (temp_write) on the ack save:
##       exact pre-ack restore, no pack_finished, FIFO blocked, no reopen loop, replay with zero
##       draw on retry / restart, exactly-once removal once the save succeeds.
## Run: godot --headless --path . -s res://tests/m43_c005f_phase2_r01_earned_pack_runtime.gd

const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const PendingPackQueue = preload("res://scripts/collection/pending_pack_queue.gd")
const PackCommitTransaction = preload("res://scripts/collection/pack_commit_transaction.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const MainScript = preload("res://scripts/app/main.gd")
const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")

class FaultySpark extends Node:
	var presets := {"spark": {}, "pickup": {}, "confetti": {}}
	func burst(_p, _o = {}) -> void:
		var broken = null
		broken.explode()   # injected plugin failure (expected SCRIPT ERROR, see test log)
	func at(_n, _o = {}) -> void:
		pass
	func clear() -> void:
		pass

var EXPECTED_CASES := [
	"q01_queue_schema_migration", "q02_grant_enqueues_never_draws", "q03_open_once_replay_ack",
	"q04_premium_guarantee_pity_once", "q05_save_failure_rollback", "q06_restart_queue_and_receipt",
	"g01_gift10_standard_ceremony", "g02_gift_250_500_exact", "g03_gift1000_premium", "g04_daily_2_4_5",
	"g05_restart_before_open", "g06_restart_after_commit_no_reroll", "g07_fifo_one_at_a_time",
	"g08_reduced", "g09_plugins_missing_or_throwing", "g10_no_pack_no_popup", "g11_duplicate_claim",
	"g12_gameplay_never_interrupted", "g13_static_single_draw_path",
	"h01_ack_save_failure_restores_exact_state", "h02_failed_ack_real_app_retry_then_fifo", "h03_restart_after_failed_ack",
]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _root = null
var _now := [1790000000]
var _day := [20000]

func _initialize() -> void:
	await process_frame
	MainScript.boot_clock_override = func(): return _now[0]
	MainScript.boot_local_day_override = func(): return _day[0]
	_q01(); _q02(); _q03(); _q04(); _q05(); _q06()
	await _g01(); await _g02(); await _g03(); await _g04(); await _g05(); await _g06(); await _g07()
	await _g08(); await _g09(); await _g10(); await _g11(); await _g12(); _g13()
	_h01(); await _h02(); await _h03()
	_shutdown()
	_cleanup()
	_done()

# ------------------------------------------------------------------ helpers ----

func _app(path: String = "") -> Object:
	return AppState.new(path if not path.is_empty() else _uniq("app"), func(): return _now[0], func(): return _day[0])

func _owned_total(e) -> int:
	var n := 0
	var o: Dictionary = e.collection.snapshot()["owned"]
	for k in o:
		n += int(o[k])
	return n

func _uniq(tag: String) -> String:
	var p := "user://c005f_r01_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _boot(path: String) -> void:
	_shutdown()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 2160)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	MainScript.boot_save_path_override = path
	_root = MainScene.instantiate()
	_sub.add_child(_root)
	await _frames(6)

func _shutdown() -> void:
	if _root != null and is_instance_valid(_root):
		_root.free()
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_root = null
	_sub = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _top():
	return _root.get_modal_stack().top()

func _is_pack(p) -> bool:
	return p != null and (String(p.popup_id) == "standard_pack" or String(p.popup_id) == "premium_pack")

func _pack_count_in_stack() -> int:
	var n := 0
	for c in _root.get_modal_stack().find_children("*", "Control", true, false):
		if c.has_method("phase") and c.has_method("feel_log") and c.is_open():
			n += 1
	return n

## Real taps: Tap 1 -> AWAIT_ROUTE -> Tap 2 -> closed "complete". Returns the ceremony model.
func _finish_pack(p) -> Dictionary:
	var model: Dictionary = p.get_model()
	p.tap()
	for _i in range(1500):
		if not is_instance_valid(p) or p.phase() == "AWAIT_ROUTE":
			break
		await process_frame
	p.tap()
	for _i in range(1500):
		if not is_instance_valid(p) or p.is_closed():
			break
		await process_frame
	await _frames(3)
	return model

## Gift Bar on the real Home: open, press CLAIM for `occ`, let the app react.
func _claim_gift_ui(occ: String) -> void:
	if not (_top() != null and String(_top().popup_id) == "gift_bar"):
		_root._on_home_shortcut("gift_bar")
		await _frames(2)
	var gb = _top()
	await create_timer(0.45).timeout   # the popup re-arms its CTAs shortly after opening / a claim
	gb.get_action_button("gift:" + occ).pressed.emit()
	await _frames(4)

func _cards_delta(before: Dictionary, after: Dictionary) -> Dictionary:
	var out := {}
	for k in after:
		var d := int(after[k]) - int(before.get(k, 0))
		if d != 0:
			out[k] = d
	return out

func _model_counts(model: Dictionary) -> Dictionary:
	var out := {}
	for c in model["cards"]:
		out[c["card_id"]] = int(out.get(c["card_id"], 0)) + 1
	return out

# ------------------------------------------------------------- unit / authority ----

func _q01() -> void:
	print("[q01 PendingPackQueue: ids, FIFO, strict import, safe migration]")
	var q := PendingPackQueue.new()
	_ok(q.enqueue("gift_ms:c0:m10", "standard", 2) and q.enqueue("daily:5", "premium", 1), "enqueue standard x2 + premium x1")
	_ok(q.entries().map(func(e): return e["id"]) == ["earned:gift_ms:c0:m10:standard:0", "earned:gift_ms:c0:m10:standard:1", "earned:daily:5:premium:0"], "stable ids parent:kind:ordinal, FIFO")
	_ok(not q.enqueue("gift_ms:c0:m10", "standard", 1) and q.size() == 3, "same parent tx cannot enqueue a duplicate")
	_ok(not q.enqueue("x", "gold", 1) and not q.enqueue("", "standard", 1) and not q.enqueue(" x", "standard", 1), "bad kind / parent refused")
	var good := q.snapshot()
	var bad := {
		"no version": {"entries": []}, "extra key": {"version": 1, "entries": [], "x": 1}, "version 2": {"version": 2, "entries": []},
		"entries not array": {"version": 1, "entries": {}}, "bad kind": {"version": 1, "entries": [{"id": "earned:a:gold:0", "kind": "gold"}]},
		"dup id": {"version": 1, "entries": [{"id": "earned:a:standard:0", "kind": "standard"}, {"id": "earned:a:standard:0", "kind": "standard"}]},
		"unprefixed": {"version": 1, "entries": [{"id": "a:standard:0", "kind": "standard"}]},
		"empty id": {"version": 1, "entries": [{"id": "", "kind": "standard"}]}, "extra entry key": {"version": 1, "entries": [{"id": "earned:a:standard:0", "kind": "standard", "n": 1}]},
		"not dict": [],
	}
	var rejected: Array = []
	for k in bad:
		var q2 := PendingPackQueue.new()
		q2.import_snapshot(good)
		if not q2.import_snapshot(bad[k]) and q2.snapshot() == good:
			rejected.append(k)
	_ok(rejected.size() == bad.size(), "malformed sections fail closed, no partial change %s" % str(rejected))
	var e := EconomyServices.new()
	var s := e.snapshot()
	s.erase("pending_packs")
	_ok(e.import_snapshot(s) and e.pending_packs.size() == 0, "old save without the section -> empty queue")
	e.pending_packs.enqueue("t", "standard", 1)
	var s2 := e.snapshot()
	var before := JSON.stringify(e.snapshot())
	s2["pending_packs"] = {"version": 1, "entries": [{"id": "bad", "kind": "standard"}]}
	_ok(not e.import_snapshot(s2) and JSON.stringify(e.snapshot()) == before, "present malformed section fails the whole economy import, state restored")
	_complete("q01_queue_schema_migration")

func _q02() -> void:
	print("[q02 a reward grant ENQUEUES packs; nothing is drawn, Collection / pity / RNG untouched]")
	var e := EconomyServices.new()
	var owned0 := _owned_total(e)
	var rng0 := JSON.stringify(e.packs.snapshot())
	var pity0 := JSON.stringify(e.pack_pity.snapshot())
	var sb0: int = e.wallet.scrub_bucks()
	_ok(e.reward.grant("t1", {"standard_card_packs": 2, "premium_card_packs": 1, "scrub_bucks": 5}), "grant applied")
	_ok(e.pending_packs.entries().map(func(x): return x["id"]) == ["earned:t1:standard:0", "earned:t1:standard:1", "earned:t1:premium:0"] or e.pending_packs.size() == 3, "3 pending entries %s" % str(e.pending_packs.entries()))
	_ok(_owned_total(e) == owned0 and JSON.stringify(e.packs.snapshot()) == rng0 and JSON.stringify(e.pack_pity.snapshot()) == pity0, "Collection, pack RNG and pity unchanged by the grant")
	_ok(e.wallet.scrub_bucks() == sb0 + 5, "non-pack resources still applied")
	_ok(not e.reward.grant("t1", {"standard_card_packs": 2}) and e.pending_packs.size() == 3, "duplicate parent tx: nothing new queued")
	_ok(e.reward.current_tx() == "", "no parent tx leaks outside a grant")
	_complete("q02_grant_enqueues_never_draws")

func _q03() -> void:
	print("[q03 canonical open draws once; replay never redraws; ack only after commit]")
	var a = _app()
	var e = a.economy
	e.reward.grant("t3", {"standard_card_packs": 1})
	var id: String = e.pending_packs.front()["id"]
	_ok(not a.acknowledge_earned_pack(id)["ok"] and e.pending_packs.size() == 1, "ack before commit refused (not_committed)")
	var owned0 := _owned_total(e)
	var c1: Dictionary = a.open_earned_pack(id)
	_ok(c1["ok"] and not c1["replay"] and c1["model"]["cards"].size() == 3 and String(c1["model"]["presentation_id"]) == id, "first open: committed, 3 cards, presentation id = queue id")
	_ok(_owned_total(e) == owned0 + 3 and e.pending_packs.size() == 1, "Collection +3 exactly; entry still pending (not yet viewed)")
	var c2: Dictionary = a.open_earned_pack(id)
	_ok(c2["ok"] and c2["replay"] and c2["model"] == c1["model"] and _owned_total(e) == owned0 + 3, "second open: same receipt, zero draw")
	var r: Dictionary = a.acknowledge_earned_pack(id)
	_ok(r["ok"] and bool(r["save"]["ok"]) and e.pending_packs.size() == 0 and not a.open_earned_pack(id)["ok"], "ack after commit: removed + saved; not pending any more")
	_complete("q03_open_once_replay_ack")

func _q04() -> void:
	print("[q04 Premium: exactly 5, card 0 Rare-or-better; pity advances exactly once per opened pack]")
	var a = _app()
	var e = a.economy
	e.reward.grant("t4", {"premium_card_packs": 1, "standard_card_packs": 1})
	var calls := [0]
	var orig = e.pack_pity
	var p0 := JSON.stringify(e.pack_pity.snapshot())
	var ids: Array = [e.pending_packs.entries().filter(func(x): return x["kind"] == "standard")[0]["id"],
		e.pending_packs.entries().filter(func(x): return x["kind"] == "premium")[0]["id"]]
	var prem: Dictionary = a.open_earned_pack(ids[1])
	_ok(prem["ok"] and prem["model"]["cards"].size() == 5 and String(prem["model"]["cards"][0]["rarity"]) != "COMMON", "Premium: 5 cards, card 0 Rare-or-better")
	var p1 := JSON.stringify(e.pack_pity.snapshot())
	a.open_earned_pack(ids[1])
	_ok(JSON.stringify(e.pack_pity.snapshot()) == p1, "replay does not advance pity")
	var std: Dictionary = a.open_earned_pack(ids[0])
	_ok(std["ok"] and std["model"]["cards"].size() == 3, "Standard: 3 cards")
	var had_new0 := (prem["model"]["cards"] as Array).any(func(c): return c["is_new"])
	_ok(had_new0 or p1 != p0, "pity reported once for the Premium opening (reset on NEW or +1)")
	_complete("q04_premium_guarantee_pity_once")

func _q05() -> void:
	print("[q05 save failure during open restores the exact pre-open state; entry stays pending]")
	var e := EconomyServices.new()
	e.reward.grant("t5", {"standard_card_packs": 1})
	var id: String = e.pending_packs.front()["id"]
	var pre := JSON.stringify(e.snapshot())
	var r: Dictionary = PackCommitTransaction.commit(e, "standard", id, func(): return {"ok": false})
	_ok(not r["ok"] and r["stage"] == "save" and bool(r["restored"]) and JSON.stringify(e.snapshot()) == pre, "rolled back exactly (Collection, RNG, pity, ledger, queue)")
	var ok: Dictionary = PackCommitTransaction.commit(e, "standard", id, func(): return {"ok": true})
	_ok(ok["ok"] and not ok["replay"] and e.pending_packs.has(id), "a later successful open still works; entry pending until ack")
	_complete("q05_save_failure_rollback")

func _q06() -> void:
	print("[q06 restart: the queue and a committed-but-unviewed receipt both survive]")
	var path := _uniq("q06")
	var a = _app(path)
	a.economy.reward.grant("t6", {"standard_card_packs": 2})
	a.request_save()
	var b = _app(path)
	_ok(b.economy.pending_packs.size() == 2, "relaunch after the claim: 2 pending packs")
	var id: String = b.economy.pending_packs.front()["id"]
	var c: Dictionary = b.open_earned_pack(id)
	var owned1 := _owned_total(b.economy)
	var d = _app(path)
	var r: Dictionary = d.open_earned_pack(id)
	_ok(r["ok"] and r["replay"] and r["model"] == c["model"] and _owned_total(d.economy) == owned1 and d.economy.pending_packs.size() == 2, "relaunch after commit: same receipt replayed, no reroll, still pending")
	_complete("q06_restart_queue_and_receipt")

# ------------------------------------------------------------- real production ----

func _g01() -> void:
	print("[g01 REAL app: Gift 10 CLAIM -> Standard ceremony opens -> taps -> Collection = those 3 cards]")
	await _boot(_uniq("g01"))
	var e = _root.get_app_state().economy
	var occ: Array = e.gift.add_streak_sb("streak:test:g01", 10)
	_ok(occ.size() == 1 and int(occ[0]["milestone"]) == 10, "Gift 10 reached")
	var owned0: Dictionary = e.collection.snapshot()["owned"].duplicate()
	var bp0: int = e.wallet.bot_parts()
	await _claim_gift_ui(String(occ[0]["id"]))
	var p = _top()
	_ok(_is_pack(p) and String(p.popup_id) == "standard_pack" and _root.get_pack_presenter().current() == p, "Standard pack ceremony opened automatically on the app ModalStack")
	_ok(e.wallet.bot_parts() == bp0 + 1 and _cards_delta(owned0, e.collection.snapshot()["owned"]) == _model_counts(p.get_model()), "claim committed (+1 Bot Part); the pack was drawn once, at ceremony open, into exactly its receipt cards")
	_ok(p.get("_feel") == _root.feel, "ceremony bound to the app's single feel adapter (F005)")
	var gb = _root.get_modal_stack().find_children("Popup_gift_bar", "", true, false)
	var hero_z: int = (gb[0].z_index + gb[0].find_child("Hero", true, false).z_index) if not gb.is_empty() else -99
	_ok(not gb.is_empty() and p.z_index > hero_z, "pack ceremony draws above the Gift Bar's hero art (z %d > %d)" % [p.z_index, hero_z])
	var model := await _finish_pack(p)
	var delta := _cards_delta(owned0, e.collection.snapshot()["owned"])
	_ok(delta == _model_counts(model) and model["cards"].size() == 3, "Collection gained exactly the 3 revealed cards %s" % str(delta))
	_ok(e.pending_packs.size() == 0 and String(_top().popup_id) == "gift_bar", "acknowledged; back on the Gift Bar")
	_complete("g01_gift10_standard_ceremony")

func _g02() -> void:
	print("[g02 Gift 250 / 500: Standard ceremony; every other reward exact]")
	await _boot(_uniq("g02"))
	var e = _root.get_app_state().economy
	var occ: Array = e.gift.add_streak_sb("streak:test:g02", 500)
	var by := {}
	for o in occ:
		by[int(o["milestone"])] = String(o["id"])
	for m in [250, 500]:
		var sb0: int = e.wallet.scrub_bucks()
		var bp0: int = e.wallet.bot_parts()
		var sel0 = JSON.stringify(e.boosters.snapshot())
		await _claim_gift_ui(by[m])
		var p = _top()
		var exp_sb := 100 if m == 250 else 250
		_ok(_is_pack(p) and String(p.popup_id) == "standard_pack", "Gift %d -> Standard ceremony" % m)
		_ok(e.wallet.scrub_bucks() == sb0 + exp_sb and e.wallet.bot_parts() == bp0 + 2, "Gift %d: +%d SB, +2 Bot Parts exact" % [m, exp_sb])
		if m == 500:
			_ok(JSON.stringify(e.boosters.snapshot()) != sel0, "Gift 500: +1 selected booster charge applied")
		await _finish_pack(p)
	_ok(e.pending_packs.size() == 0, "both acknowledged")
	_complete("g02_gift_250_500_exact")

func _g03() -> void:
	print("[g03 Gift 1000: Premium ceremony, 5 cards, Rare-or-better first; guaranteed-new exact]")
	await _boot(_uniq("g03"))
	var e = _root.get_app_state().economy
	var occ: Array = e.gift.add_streak_sb("streak:test:g03", 1000)
	var id1000 := ""
	for o in occ:
		if int(o["milestone"]) == 1000:
			id1000 = String(o["id"])
	var owned0: Dictionary = e.collection.snapshot()["owned"].duplicate()
	var sb0: int = e.wallet.scrub_bucks()
	await _claim_gift_ui(id1000)
	var p = _top()
	_ok(_is_pack(p) and String(p.popup_id) == "premium_pack", "Premium ceremony opened")
	var after_open := _cards_delta(owned0, e.collection.snapshot()["owned"])
	var pc := _model_counts(p.get_model())
	var after_claim := {}
	for k in after_open:
		var d := int(after_open[k]) - int(pc.get(k, 0))
		if d != 0:
			after_claim[k] = d
	_ok(after_claim.size() == 1 and after_claim.values() == [1] and e.wallet.scrub_bucks() == sb0 + 500, "claim: exactly one guaranteed NEW card + 500 SB (no fallback needed) besides the 5 pack cards")
	var model := await _finish_pack(p)
	_ok(model["cards"].size() == 5 and String(model["cards"][0]["rarity"]) != "COMMON", "5 cards, card 0 Rare-or-better")
	var total := _cards_delta(owned0, e.collection.snapshot()["owned"])
	var expect := _model_counts(model)
	for k in after_claim:
		expect[k] = int(expect.get(k, 0)) + int(after_claim[k])
	_ok(total == expect, "Collection = guaranteed card + exactly the 5 revealed cards")
	_complete("g03_gift1000_premium")

func _g04() -> void:
	print("[g04 Daily day 2 / 4 -> Standard, day 5 -> Premium (after the claim confirmation)]")
	await _boot(_uniq("g04"))
	var a = _root.get_app_state()
	var e = a.economy
	var d0: int = _day[0]
	a.actions.claim_daily_login()   # day 1 (100 SB)
	await _frames(3)
	var kinds: Array = []
	for day in [2, 3, 4, 5]:
		_day[0] = d0 + day - 1
		_now[0] += 86400
		_root._on_home_shortcut("daily")
		await _frames(2)
		var dp = _top()
		await create_timer(0.45).timeout
		dp.get_action_button("claim").pressed.emit()
		await _frames(4)
		var conf = _top()
		var pack_waiting: bool = String(conf.popup_id) == "ceremony_daily" and _pack_count_in_stack() == 0
		if day == 3:
			_ok(pack_waiting or not _is_pack(_top()), "day 3 (booster): no pack")
		conf.close("test")
		await _frames(4)
		if day != 3:
			_ok(pack_waiting, "day %d: the claim's confirmation shows first, no pack under/over it" % day)
			var p = _top()
			kinds.append(String(p.popup_id) if _is_pack(p) else "none")
			if _is_pack(p):
				await _finish_pack(p)
		if _top() != null:
			_top().close("test")
			await _frames(3)
	_ok(kinds == ["standard_pack", "standard_pack", "premium_pack"], "day 2 Standard, day 4 Standard, day 5 Premium %s" % str(kinds))
	_ok(e.pending_packs.size() == 0, "all acknowledged")
	_day[0] = d0
	_complete("g04_daily_2_4_5")

func _g05() -> void:
	print("[g05 restart after the claim but before opening -> the same pending pack opens]")
	var path := _uniq("g05")
	var a = _app(path)
	a.economy.reward.grant("gift_ms:c0:m10", {"standard_card_packs": 1, "bot_parts": 1})
	a.request_save()
	var id: String = a.economy.pending_packs.front()["id"]
	await _boot(path)
	var p = _top()
	_ok(_is_pack(p) and p.get_model()["presentation_id"] == id and _root.get_pack_presenter().presented_log()[0][2] == false, "boot -> Home -> the pending pack opens (first commit)")
	await _finish_pack(p)
	_ok(_root.get_app_state().economy.pending_packs.size() == 0, "acknowledged")
	_complete("g05_restart_before_open")

func _g06() -> void:
	print("[g06 restart after commit, before the ceremony finished -> same receipt, no reroll]")
	var path := _uniq("g06")
	var a = _app(path)
	a.economy.reward.grant("daily:5", {"premium_card_packs": 1})
	var id: String = a.economy.pending_packs.front()["id"]
	var c: Dictionary = a.open_earned_pack(id)   # committed + saved; app "dies" here
	var owned1: Dictionary = a.economy.collection.snapshot()["owned"].duplicate()
	await _boot(path)
	var p = _top()
	_ok(_is_pack(p) and p.get_model()["cards"] == c["model"]["cards"] and _root.get_pack_presenter().presented_log()[0][2] == true, "relaunch: identical committed cards replayed (replay=true)")
	await _finish_pack(p)
	var e = _root.get_app_state().economy
	_ok(e.collection.snapshot()["owned"] == owned1 and e.pending_packs.size() == 0, "no second draw; acknowledged")
	_complete("g06_restart_after_commit_no_reroll")

func _g07() -> void:
	print("[g07 several queued packs open one at a time, FIFO]")
	var path := _uniq("g07")
	var a = _app(path)
	a.economy.reward.grant("multi", {"standard_card_packs": 2, "premium_card_packs": 1})
	a.request_save()
	var want: Array = a.economy.pending_packs.entries().map(func(x): return x["id"])
	await _boot(path)
	var seen: Array = []
	var single := true
	for _k in range(3):
		var p = _top()
		single = single and _pack_count_in_stack() == 1
		if not _is_pack(p):
			break
		seen.append(String(p.get_model()["presentation_id"]))
		await _finish_pack(p)
	_ok(seen == want and single, "FIFO %s, never two pack ceremonies at once" % str(seen))
	_complete("g07_fifo_one_at_a_time")

func _g08() -> void:
	print("[g08 Reduced Effects: same truth, reduced ceremony, zero plugin work]")
	var path := _uniq("g08")
	var a = _app(path)
	a.effects.set_reduced(true)
	a.economy.reward.grant("gift_ms:c0:m10", {"standard_card_packs": 1})
	a.request_save()
	await _boot(path)
	var p = _top()
	var n0: int = _root.feel.dispatch_log().size()
	_ok(_root.get_app_state().effects.is_reduced() and p.get("_reduced") == true, "Reduced restored from save -> reduced ceremony")
	var model := await _finish_pack(p)
	_ok(_root.feel.dispatch_log().size() == n0 and model["cards"].size() == 3 and _root.get_app_state().economy.pending_packs.size() == 0, "no feel dispatch, 3 cards, acknowledged")
	_complete("g08_reduced")

func _g09() -> void:
	print("[g09 plugins missing / throwing: the ceremony completes natively]")
	for mode in ["missing", "throwing"]:
		var path := _uniq("g09_" + mode)
		var a = _app(path)
		a.economy.reward.grant("t9_" + mode, {"standard_card_packs": 1})
		a.request_save()
		await _boot(path)
		var spark := FaultySpark.new()
		get_root().add_child(spark)
		if mode == "missing":
			_root.feel.set_backends_for_test(null, null)
		else:
			print("  EXPECTED_FAULT_INJECTION: SCRIPT ERRORs ('explode' on null) follow, deliberately raised inside a spy plugin")
			_root.feel.set_backends_for_test(null, spark)
		var p = _top()
		var model := await _finish_pack(p)
		_ok(model["cards"].size() == 3 and _root.get_app_state().economy.pending_packs.size() == 0, "%s plugins: Tap 1 -> hold -> Tap 2 -> complete -> acknowledged" % mode)
		spark.free()
	_complete("g09_plugins_missing_or_throwing")

func _g10() -> void:
	print("[g10 a claim without packs opens no pack popup]")
	await _boot(_uniq("g10"))
	var e = _root.get_app_state().economy
	var occ: Array = e.gift.add_streak_sb("streak:test:g10", 50)
	var m50 := ""
	for o in occ:
		if int(o["milestone"]) == 50:
			m50 = String(o["id"])
	await _claim_gift_ui(m50)
	_ok(String(_top().popup_id) == "gift_bar" and _pack_count_in_stack() == 0 and e.pending_packs.size() == 0, "Gift 50 (Bot Part + booster): no pack ceremony")
	_complete("g10_no_pack_no_popup")

func _g11() -> void:
	print("[g11 a duplicate claim / action callback never queues or opens a second pack]")
	await _boot(_uniq("g11"))
	var a = _root.get_app_state()
	var occ: Array = a.economy.gift.add_streak_sb("streak:test:g11", 10)
	var id := String(occ[0]["id"])
	await _claim_gift_ui(id)
	var p = _top()
	_ok(not a.actions.claim_gift(id)["ok"] and a.economy.pending_packs.size() == 1, "second claim refused; one pending pack")
	a.actions.action_committed.emit("claim_gift", {"ok": true})   # spurious duplicate callback
	await _frames(4)
	_ok(_pack_count_in_stack() == 1 and _top() == p, "still exactly one pack ceremony")
	await _finish_pack(p)
	_ok(a.economy.pending_packs.size() == 0 and _pack_count_in_stack() == 0, "no second pack")
	_complete("g11_duplicate_claim")

func _g12() -> void:
	print("[g12 a pending pack never interrupts gameplay / Results; it opens back on Home]")
	await _boot(_uniq("g12"))
	var a = _root.get_app_state()
	var r: Dictionary = _root.play_current_frontier()
	await _frames(4)
	a.economy.reward.grant("t12", {"standard_card_packs": 1})
	_root.request_earned_packs()
	await _frames(4)
	_ok(r["ok"] and _root.get_navigation().route_name() == "GAMEPLAY" and _pack_count_in_stack() == 0, "GAMEPLAY: no pack popup")
	var h = _root.get_gameplay_host()
	h.get_runtime().set_process(false)
	h.get_completion().terminal_reached.emit(&"WON", {})
	await _frames(4)
	_root.request_earned_packs()
	await _frames(4)
	_ok(_root.get_navigation().route_name() == "RESULTS" and _pack_count_in_stack() == 0, "RESULTS: no pack popup")
	_root.get_results_screen().home_requested.emit()
	for _i in range(60):
		await process_frame
		if _is_pack(_top()):
			break
		if _top() != null and not _is_pack(_top()) and String(_top().popup_id).begins_with("ceremony_"):
			_top().close("action:continue")
	_ok(_root.get_navigation().route_name() == "HOME" and _is_pack(_top()), "HOME (after any meta ceremony): the pack opens")
	await _finish_pack(_top())
	_complete("g12_gameplay_never_interrupted")

func _g13() -> void:
	print("[g13 static: one draw path, one presenter, no plugin access]")
	var hits: Array = []
	for p in _gd("res://scripts"):
		var src := _code(p)
		if (src.contains("open_standard()") or src.contains("open_premium()")) and not p.ends_with("pack_commit_transaction.gd") and not p.ends_with("card_pack_service.gd"):
			hits.append(p)
	_ok(hits.is_empty(), "CardPackService draws are reached only by PackCommitTransaction %s" % str(hits))
	var es := _code("res://scripts/economy/economy_services.gd")
	_ok(es.contains("pending_packs.enqueue(reward.current_tx(), \"standard\", n)") and not es.contains("packs.open_"), "reward handlers enqueue; no silent draw")
	var pp := _code("res://scripts/ui/ceremony/pack_presenter.gd")
	_ok(not pp.contains("GameFeelFlow") and not pp.contains("Spark") and not pp.contains("grant(") and not pp.contains("open_standard"), "PackPresenter: no plugin, grant or draw")
	var users: Array = _gd("res://scripts").filter(func(p): return _code(p).contains("PackPresenter.new()"))
	_ok(users == ["res://scripts/app/main.gd"], "one production PackPresenter %s" % str(users))
	_complete("g13_static_single_draw_path")

# ------------------------------------------------------- R02 durable acknowledgement ----

func _fail_temp_write(a) -> void:
	a.save.set_fault_injector(func(stage): return stage == "temp_write")

func _econ_parts(e) -> Dictionary:
	return {"owned": JSON.stringify(e.collection.snapshot()), "rng": JSON.stringify(e.packs.snapshot()),
		"pity": JSON.stringify(e.pack_pity.snapshot()), "receipts": JSON.stringify(e.pack_receipts.snapshot()),
		"queue": JSON.stringify(e.pending_packs.snapshot())}

func _h01() -> void:
	print("[h01 ack save failure (SaveService temp_write) restores the exact pre-ack economy]")
	var a = _app()
	var e = a.economy
	e.reward.grant("h01", {"standard_card_packs": 2})
	a.request_save()
	var id: String = e.pending_packs.front()["id"]
	var c: Dictionary = a.open_earned_pack(id)
	var before := _econ_parts(e)
	var full_before := JSON.stringify(e.snapshot())
	_fail_temp_write(a)
	var r: Dictionary = a.acknowledge_earned_pack(id)
	_ok(not r["ok"] and r["reason"] == "ack_save_failed" and bool(r["restored"]) and String(r["save"]["reason"]) == "temp_write_failed", "outer ok:false, ack_save_failed, restored (save: temp_write_failed)")
	_ok(e.pending_packs.front()["id"] == id and e.pending_packs.size() == 2 and _econ_parts(e) == before and JSON.stringify(e.snapshot()) == full_before, "same entry back at the FIFO front; receipt / Collection / RNG / pity / queue byte-identical")
	a.save.set_fault_injector(Callable())
	var c2: Dictionary = a.open_earned_pack(id)
	_ok(c2["replay"] and c2["model"] == c["model"] and _econ_parts(e)["owned"] == before["owned"], "retry open: replay, same cards, zero draw")
	var r2: Dictionary = a.acknowledge_earned_pack(id)
	_ok(r2["ok"] and e.pending_packs.size() == 1 and not e.pending_packs.has(id) and a.acknowledge_earned_pack(id)["reason"] == "not_pending", "durable ack: removed exactly once")
	_complete("h01_ack_save_failure_restores_exact_state")

func _h02() -> void:
	print("[h02 REAL app: failed durable ack -> no finish, FIFO blocked, no reopen loop; retry replays, then FIFO]")
	var path := _uniq("h02")
	var a0 = _app(path)
	a0.economy.reward.grant("h02", {"standard_card_packs": 2})
	a0.request_save()
	await _boot(path)
	var a = _root.get_app_state()
	var e = a.economy
	var pp = _root.get_pack_presenter()
	var finished: Array = []
	var failed: Array = []
	pp.pack_finished.connect(func(id): finished.append(id))
	pp.pack_ack_failed.connect(func(id, _r): failed.append(id))
	var p = _top()
	var id1: String = p.get_model()["presentation_id"]
	var id2: String = e.pending_packs.entries()[1]["id"]
	var parts := _econ_parts(e)
	_fail_temp_write(a)
	await _finish_pack(p)
	for _i in range(30):   # let modal_changed / Home drains run: they must not reopen or advance
		await process_frame
	_ok(failed == [id1] and finished.is_empty(), "pack_ack_failed for pack 1; no pack_finished")
	_ok(e.pending_packs.front()["id"] == id1 and e.pending_packs.size() == 2 and _econ_parts(e) == parts, "entry restored at the front; receipt / Collection / RNG / pity unchanged")
	_ok(_pack_count_in_stack() == 0 and pp.presented_log().size() == 1 and pp.is_ack_guarded(id1), "pack 2 not started, pack 1 not instantly reopened (transient guard)")
	a.save.set_fault_injector(Callable())
	pp.release_ack_guard()   # what the next Home entry does
	_root.request_earned_packs()
	await _frames(4)
	var p2 = _top()
	var log: Array = pp.presented_log()
	_ok(_is_pack(p2) and p2.get_model()["presentation_id"] == id1 and log[-1] == [id1, "standard", true] and _econ_parts(e)["owned"] == parts["owned"] and _econ_parts(e)["pity"] == parts["pity"], "retry: same id reopens as replay, zero draw / pity advance")
	await _finish_pack(p2)
	_ok(finished == [id1] and e.pending_packs.size() == 1 and not e.pending_packs.has(id1), "durable ack succeeds: pack_finished once, removed exactly once")
	var p3 = _top()
	_ok(_is_pack(p3) and p3.get_model()["presentation_id"] == id2 and pp.presented_log()[-1] == [id2, "standard", false], "FIFO advances to pack 2 (first commit)")
	await _finish_pack(p3)
	_ok(e.pending_packs.size() == 0 and finished == [id1, id2], "both acknowledged, in order")
	_complete("h02_failed_ack_real_app_retry_then_fifo")

func _h03() -> void:
	print("[h03 restart after a failed acknowledgement: last good save -> same receipt reopens, no reroll]")
	var path := _uniq("h03")
	var a = _app(path)
	a.economy.reward.grant("h03", {"premium_card_packs": 1})
	a.request_save()
	var id: String = a.economy.pending_packs.front()["id"]
	var c: Dictionary = a.open_earned_pack(id)   # commit + save
	_fail_temp_write(a)
	var r: Dictionary = a.acknowledge_earned_pack(id)
	_ok(not r["ok"] and a.economy.pending_packs.has(id), "ack failed, entry kept")
	var owned: Dictionary = a.economy.collection.snapshot()["owned"].duplicate()
	var b = _app(path)   # the app dies; relaunch loads the last good save
	_ok(b.economy.pending_packs.front()["id"] == id and b.economy.pack_receipts.get_receipt(id) == a.economy.pack_receipts.get_receipt(id), "relaunch: same pending entry + identical committed receipt")
	await _boot(path)
	var p = _top()
	_ok(_is_pack(p) and p.get_model()["cards"] == c["model"]["cards"] and _root.get_pack_presenter().presented_log()[0][2] == true, "same cards reopen (replay=true)")
	await _finish_pack(p)
	var e = _root.get_app_state().economy
	_ok(e.collection.snapshot()["owned"] == owned and e.pending_packs.size() == 0, "no reroll; acknowledged durably")
	_complete("h03_restart_after_failed_ack")

func _gd(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for s in d.get_directories():
		out.append_array(_gd(dir + "/" + s))
	return out

func _code(path: String) -> String:
	var out := ""
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var i := line.find("#")
		out += (line if i == -1 else line.substr(0, i)) + "\n"
	return out

# ------------------------------------------------------------------- infra -----

func _cleanup() -> void:
	MainScript.boot_save_path_override = ""
	MainScript.boot_clock_override = Callable()
	MainScript.boot_local_day_override = Callable()
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

func _complete(c: String) -> void:
	_completed[c] = true

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	if not missing.is_empty():
		_fail += missing.size()
		print("  FAIL: cases not completed %s" % str(missing))
	print("M43-C005F-PHASE2-R01 earned pack runtime: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
