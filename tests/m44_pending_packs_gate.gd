extends SceneTree
## SB-M44-025 — pending-pack inventory: earned packs granted before the card_packs unlock (L20)
## stay queued in economy.pending_packs (no draw, no ceremony) and open FIFO at L20:
##   - fresh profile L1 / L10 / L19: real reward grant ENQUEUES; Collection / receipts / RNG / pity untouched;
##   - below L20 AppState.open_earned_pack -> {ok:false, reason:"locked"}; PackPresenter.drain is a silent no-op;
##   - save / reload keeps the queue identical and still locked;
##   - at L20 the Collection screen shows the live counts and the existing ceremony drains FIFO exactly once;
##   - committed ids replay (no second draw); ack removes; empty queue after reload;
##   - grandfather: an established save below L20 opens packs exactly as before.
## Never boots main.tscn (no real user save touched): AppState on temp user:// paths + a ModalStack.
##
## Run: godot --headless --path . -s res://tests/m44_pending_packs_gate.gd

const AppState = preload("res://scripts/app/app_state.gd")
const PackPresenter = preload("res://scripts/ui/ceremony/pack_presenter.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

var EXPECTED_CASES := ["queue_below_unlock", "no_open_below_unlock", "persist", "open_at_unlock", "exactly_once", "grandfather"]

var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _sub: SubViewport
var _stack = null
var _path_main := ""
var _ids: Array = []        ## FIFO ids granted in queue_below_unlock
var _kinds: Array = []

func _initialize() -> void:
	await process_frame
	var a = _queue_below_unlock()
	_no_open_below_unlock(a)
	var b = _persist(a)
	await _open_at_unlock(b)
	_exactly_once()
	await _grandfather()
	_unmount()
	_cleanup()
	_done()

func _queue_below_unlock():
	print("[queue_below_unlock: fresh profile L1 / L10 / L19, grants only enqueue]")
	_path_main = _path("main")
	var a = AppState.new(_path_main)
	_ok(bool(a.bootstrap_new_profile()["ok"]) and a.economy.ftue.is_new_profile(), "fresh profile bootstrapped")
	var e = a.economy
	var base := _econ_core(e)
	var grants := {1: {"standard_card_packs": 1}, 10: {"premium_card_packs": 1}, 19: {"standard_card_packs": 1, "premium_card_packs": 1}}
	var expected := 0
	for lvl in grants:
		_walk_to(a, lvl)
		_ok(a.progression.current_level() == lvl and not a.feature_unlocked("card_packs"), "L%d: card_packs locked" % lvl)
		_ok(e.reward.grant("m44_025_L%d" % lvl, grants[lvl]), "L%d: reward grant applied" % lvl)
		for k in grants[lvl]:
			expected += int(grants[lvl][k])
		_ok(e.pending_packs.size() == expected, "L%d: %d packs queued" % [lvl, expected])
	_ids = e.pending_packs.entries().map(func(x): return String(x["id"]))
	_kinds = e.pending_packs.entries().map(func(x): return String(x["kind"]))
	_ok(_ids == ["earned:m44_025_L1:standard:0", "earned:m44_025_L10:premium:0", "earned:m44_025_L19:standard:0", "earned:m44_025_L19:premium:0"], "FIFO ids stable %s" % str(_ids))
	_ok(_econ_core(e) == base, "Collection / pack receipts / RNG / pity unchanged by the grants")
	_ok(bool(a.request_save()["ok"]), "saved")
	_complete("queue_below_unlock")
	return a

func _no_open_below_unlock(a) -> void:
	print("[no_open_below_unlock: L19 open refused, drain silent]")
	var e = a.economy
	var base := _econ_core(e)
	var r: Dictionary = a.open_earned_pack(_ids[0])
	_ok(not bool(r.get("ok", true)) and String(r.get("reason", "")) == "locked", "open_earned_pack(front) -> locked %s" % str(r))
	_mount()
	var pp = PackPresenter.new()
	pp.bind(_stack, a)
	var idled := [0]
	pp.idle.connect(func(): idled[0] += 1)
	_ok(not pp.drain() and not pp.is_presenting() and _stack.depth() == 0, "drain() false, no ceremony / modal opened")
	_ok(pp.last_error() == "" and idled[0] == 0 and pp.presented_log().is_empty(), "silent: no sticky error, no idle, nothing logged")
	_ok(e.pending_packs.size() == 4 and _econ_core(e) == base and e.pack_receipts.size() == 0, "queue unchanged, no receipt written")
	_complete("no_open_below_unlock")

func _persist(a):
	print("[persist: reload keeps the queue identical and locked]")
	var before: Array = a.economy.pending_packs.entries()
	var b = AppState.new(_path_main)
	var after: Array = b.economy.pending_packs.entries()
	_ok(after == before and after.map(func(x): return String(x["id"])) == _ids and after.map(func(x): return String(x["kind"])) == _kinds, "entries identical (ids, kinds, order)")
	_ok(b.economy.ftue.is_new_profile() and b.progression.current_level() == 19 and not b.feature_unlocked("card_packs"), "reloaded L19 fresh profile still locked")
	_ok(String(b.open_earned_pack(_ids[0]).get("reason", "")) == "locked" and b.economy.pending_packs.size() == 4, "reloaded open still locked, queue kept")
	_complete("persist")
	return b

func _open_at_unlock(b) -> void:
	print("[open_at_unlock: L20 Collection counts + FIFO ceremony drain once each]")
	var e = b.economy
	_walk_to(b, 20)
	_ok(b.feature_unlocked("card_packs") and b.feature_unlocked("collection"), "L20: card_packs + collection unlocked")
	_mount()
	var album = CollectionScreen.open_album(_stack, b, func(): pass)
	var label: Label = album.find_child("Packs", true, false) if album != null else null
	_ok(label != null and label.text == UiText.t("COLLECTION_PACKS", [2, 2]), "Collection shows live counts: %s" % (label.text if label != null else "<none>"))
	album.close()
	await _frames(2)
	var owned0 := _owned_total(e)
	var pp = PackPresenter.new()
	pp.bind(_stack, b)
	var finished: Array = []
	pp.pack_finished.connect(func(id): finished.append(id))
	var cards := 0
	for i in range(_ids.size()):
		_ok(pp.drain() and pp.current_id() == _ids[i], "drain #%d opens %s" % [i, _ids[i]])
		var p = pp.current()
		if p == null:
			break
		cards += int(p.get_model()["cards"].size())
		await _finish_pack(p)
	_ok(finished == _ids, "FIFO order, each finished once %s" % str(finished))
	_ok(pp.presented_log().map(func(x): return x[0]) == _ids and pp.presented_log().all(func(x): return not bool(x[2])), "each opened exactly once, no replay")
	_ok(e.pending_packs.size() == 0 and _ids.all(func(id): return e.pack_receipts.has(id)), "queue empty, receipts exist")
	_ok(_owned_total(e) == owned0 + cards and cards > 0, "Collection gained the %d revealed cards" % cards)
	_ok(not pp.drain() and _stack.depth() == 0, "drain on empty queue: no-op")
	_complete("open_at_unlock")

func _exactly_once() -> void:
	print("[exactly_once: committed id replays, ack removes, reload empty]")
	var p := _path("once")
	var a = AppState.new(p)
	a.bootstrap_new_profile()
	_walk_to(a, 20)
	var e = a.economy
	e.reward.grant("m44_025_once", {"standard_card_packs": 1})
	var id: String = e.pending_packs.front()["id"]
	var r1: Dictionary = a.open_earned_pack(id)
	_ok(bool(r1["ok"]) and not bool(r1["replay"]), "first open draws")
	var core := _econ_core(e)
	var r2: Dictionary = a.open_earned_pack(id)
	_ok(bool(r2["ok"]) and bool(r2["replay"]) and r2["receipt"] == r1["receipt"] and _econ_core(e) == core, "repeat open replays the receipt; Collection / RNG unchanged")
	_ok(bool(a.acknowledge_earned_pack(id)["ok"]) and e.pending_packs.size() == 0, "ack removes the entry")
	_mount()
	var pp = PackPresenter.new()
	pp.bind(_stack, a)
	_ok(not pp.drain() and _stack.depth() == 0 and _econ_core(e) == core, "second drain: no-op")
	var re = AppState.new(p)
	_ok(re.economy.pending_packs.size() == 0 and re.economy.pack_receipts.has(id), "reload after ack: empty queue, receipt kept")
	_complete("exactly_once")

func _grandfather() -> void:
	print("[grandfather: established save below L20 opens as before]")
	var a = AppState.new(_path("est"))
	_ok(not a.economy.ftue.is_new_profile() and a.progression.current_level() < 20 and a.feature_unlocked("card_packs"), "established L%d save: card_packs unlocked" % a.progression.current_level())
	var e = a.economy
	e.reward.grant("m44_025_est", {"standard_card_packs": 1})
	var id: String = e.pending_packs.front()["id"]
	_mount()
	var pp = PackPresenter.new()
	pp.bind(_stack, a)
	_ok(pp.drain() and pp.current_id() == id, "drain opens the ceremony immediately")
	var finished: Array = []
	pp.pack_finished.connect(func(x): finished.append(x))
	if pp.current() != null:
		await _finish_pack(pp.current())
	_ok(finished == [id] and e.pending_packs.size() == 0 and e.pack_receipts.has(id), "opened + acknowledged normally")
	_complete("grandfather")

# ------------------------------------------------------------------ helpers ----

func _econ_core(e) -> String:
	var s: Dictionary = e.snapshot()
	return JSON.stringify([e.collection.snapshot(), s["pack_receipts"], e.packs.snapshot(), e.pack_pity.snapshot()])

func _owned_total(e) -> int:
	var n := 0
	var o: Dictionary = e.collection.snapshot()["owned"]
	for k in o:
		n += int(o[k])
	return n

func _walk_to(app, level: int) -> void:
	while app.progression.current_level() < level:
		app.progression.record_win(app.progression.current_level())

## Real taps: Tap 1 -> AWAIT_ROUTE -> Tap 2 -> closed "complete".
func _finish_pack(p) -> void:
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

func _mount() -> void:
	_unmount()
	_sub = SubViewport.new()
	_sub.size = Vector2i(1080, 1920)
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_stack = ModalStack.new()
	_sub.add_child(_stack)

func _unmount() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_sub = null
	_stack = null

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _path(tag: String) -> String:
	var p := "user://m44_pending_packs_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp", ".json"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = EXPECTED_CASES.filter(func(c): return not _completed.has(c))
	for c in missing:
		print("  FAIL: case did not complete: %s" % c)
	_fail += missing.size()
	print("M44 PENDING PACKS GATE: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size(), _fail])
	quit(0 if _fail == 0 else 1)
