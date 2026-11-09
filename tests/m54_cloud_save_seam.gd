extends SceneTree
## SB-M43-152..157 / SB-M49-030 / SB-M54-031 — cloud save seam regression against a mock
## provider (no SDK, no network; the real Play Games / Game Center + iCloud plugins come later):
##   c01 null provider (shipping default): signed out, nothing read / written, no sync file,
##       no network / SDK in the cloud scripts
##   c02 schema round trip: upload header (schema, revision, device, saved_at, lineage) + whole
##       M40 payload; new device restores it byte-identical and persisted; equal re-sync writes
##       nothing; local-ahead uploads revision 2; an unchanged device takes a proven descendant
##   c03 conflict detection with both summaries; KEEP_DEVICE overwrites the cloud only, KEEP_CLOUD
##       replaces the device only; never merged; choose() without a conflict is refused
##   c04 restored applied tx ids (reward + store:<token>) can never grant twice
##   c05 offline / error / provider refusal / invalid cloud copy / failed restore save never
##       touch the local save (file bytes + live state)
##   c06 conflict screen (account_conflict) + destructive confirm fit 720x1280 and 1170x2532
##       (EN + TR), touch >= 88; cancel re-arms, confirm commits the choice
##   c07 Settings cloud status line: NOT AVAILABLE without a provider, live state with one
## Throw-away user:// saves only, removed at the end.
##
## Run: godot --headless --path . -s res://tests/m54_cloud_save_seam.gd

const AppState = preload("res://scripts/app/app_state.gd")
const CloudSave = preload("res://scripts/save/cloud_save.gd")
const CloudSaveService = preload("res://scripts/save/cloud_save_service.gd")
const CloudConflictScreen = preload("res://scripts/ui/cloud_conflict_screen.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const SettingsPanelScene = preload("res://scenes/ui/settings_panel.tscn")
const UiText = preload("res://scripts/ui/ui_text.gd")

const T0 := 1790000000
const SIZES := [Vector2i(720, 1280), Vector2i(1170, 2532)]

var EXPECTED_CASES := ["c01_null_provider", "c02_schema_round_trip", "c03_conflict_choices", "c04_no_double_grant",
	"c05_failures_untouched", "c06_conflict_screen_fit", "c07_settings_status"]
var _fail := 0
var _completed: Dictionary = {}
var _tmp: Array = []
var _now := [T0]
var _day := [20000]

## Test double for CloudProvider: one shared cloud slot, synchronous callbacks.
class MockProvider:
	var available := true
	var signed_in := true
	var data := ""
	var writes := 0
	var read_fail := ""
	var write_fail := ""
	var refuse := false
	func is_available() -> bool: return available
	func is_signed_in() -> bool: return signed_in
	func sign_in(deliver: Callable) -> bool:
		signed_in = true
		deliver.call({"ok": true})
		return true
	func read(deliver: Callable) -> bool:
		if refuse:
			return false
		deliver.call({"ok": false, "reason": read_fail} if not read_fail.is_empty() else {"ok": true, "data": data})
		return true
	func write(d: String, deliver: Callable) -> bool:
		if not write_fail.is_empty():
			deliver.call({"ok": false, "reason": write_fail})
			return true
		data = d
		writes += 1
		deliver.call({"ok": true})
		return true

func _initialize() -> void:
	await process_frame
	_c01()
	_c02()
	_c03()
	_c04()
	_c05()
	await _c06()
	await _c07()
	UiText.locale = "en"
	_cleanup()
	_done()

# ------------------------------------------------------------------ cases ----

func _c01() -> void:
	print("[c01 null provider: signed out, local only]")
	var a := _app("c01")
	a.progression.record_win(1)
	a.request_save()
	var before := _bytes(a)
	_ok(not a.cloud.is_available() and a.cloud.state() == CloudSaveService.SIGNED_OUT, "shipping default: unavailable, signed_out")
	_ok(a.cloud.sync()["reason"] == CloudSaveService.SIGNED_OUT and a.cloud.state() == CloudSaveService.SIGNED_OUT, "sync() -> signed_out")
	_ok(a.cloud.sign_in()["reason"] == "unavailable", "sign_in() -> unavailable (no platform UI to start)")
	_ok(_bytes(a) == before and not FileAccess.file_exists(_sync_path(a)), "local save untouched, no sync file written")
	var ms := ModalStack.new()
	_ok(CloudConflictScreen.open(ms, a.cloud) == null, "no conflict screen outside CONFLICT")
	ms.free()
	var bad: Array = []
	for f in ["res://scripts/save/cloud_provider.gd", "res://scripts/save/cloud_save_service.gd", "res://scripts/ui/cloud_conflict_screen.gd"]:
		var s := FileAccess.get_file_as_string(f)
		for t in ["HTTPRequest", "HTTPClient", "StreamPeerTCP", "WebSocket", "JavaClassWrapper", "Engine.get_singleton"]:
			if s.contains(t):
				bad.append("%s:%s" % [f.get_file(), t])
	_ok(bad.is_empty(), "no network / platform SDK in the cloud scripts %s" % str(bad))
	_complete("c01_null_provider")

func _c02() -> void:
	print("[c02 schema round trip + proven descendant]")
	var mock := MockProvider.new()
	var a := _app("c02a", mock)
	a.actions.claim_daily_login()
	a.progression.record_win(1)
	a.economy.reward.grant("c02-tx", {"scrub_bucks": 40})
	a.request_save()
	_ok(a.cloud.sync()["ok"] and a.cloud.state() == CloudSaveService.SYNCED and mock.writes == 1, "empty cloud -> upload -> synced")
	var env = JSON.parse_string(mock.data)
	_ok(env["schema"] == CloudSave.SCHEMA and int(env["revision"]) == 1 and int(env["saved_at"]) == _now[0] and env["lineage"] == [],
		"header: schema %s, revision 1, saved_at = clock, empty lineage" % env["schema"])
	_ok(env["device"] == a.cloud.device_id() and String(env["device"]).length() == 32 and String(env["device"]).is_valid_hex_number(), "device = random 128-bit install id")
	_ok(CloudSave.fingerprint(env["payload"]) == CloudSave.fingerprint(a.save.collect()) and env["payload"]["schema"] == "scrubbots.save", "payload = the whole M40 save")
	_ok(CloudSave.validate_envelope(a.save, env)["ok"], "uploaded copy validates (M40 dry run)")
	_ok(a.cloud.sync()["ok"] and a.cloud.state() == CloudSaveService.SYNCED and mock.writes == 1, "equal re-sync: synced, nothing written")
	# A new device: no shared history -> explicit choice; KEEP_CLOUD restores the whole save.
	_now[0] += 60
	var b := _app("c02b", mock)
	b.cloud.sync()
	_ok(b.cloud.state() == CloudSaveService.CONFLICT, "fresh device vs cloud progress -> conflict (no silent replace)")
	b.cloud.choose(CloudSaveService.KEEP_CLOUD)
	_ok(b.cloud.state() == CloudSaveService.SYNCED and _same(a, b), "KEEP_CLOUD: economy + progression byte-identical")
	var b2 := AppState.new(b.save._path, func(): return _now[0], func(): return _day[0])
	b2.cloud.set_provider(mock)
	_ok(_same(a, b2), "restore persisted (relaunch reads it back)")
	_ok(b2.cloud.sync()["ok"] and b2.cloud.state() == CloudSaveService.SYNCED and mock.writes == 1, "relaunched device keeps its sync header: equal, nothing written (%s %s, %d writes)" % [b2.cloud.state(), b2.cloud.reason(), mock.writes])
	# A plays on -> revision 2 built on revision 1; the unchanged device takes it automatically.
	_now[0] += 60
	a.progression.record_win(2)
	a.cloud.sync()
	var env2 = JSON.parse_string(mock.data)
	_ok(mock.writes == 2 and int(env2["revision"]) == 2 and (env2["lineage"] as Array).has(CloudSave.fingerprint(CloudSave.authority(env["payload"]))), "local ahead -> revision 2 uploaded, lineage proves revision 1")
	b2.cloud.sync()
	_ok(b2.cloud.state() == CloudSaveService.SYNCED and _same(a, b2) and mock.writes == 2, "unchanged device takes the proven descendant, writes nothing (%s %s)" % [b2.cloud.state(), b2.cloud.reason()])
	_complete("c02_schema_round_trip")

func _c03() -> void:
	print("[c03 conflict: both summaries, KEEP_DEVICE / KEEP_CLOUD, never merged]")
	for choice in [CloudSaveService.KEEP_DEVICE, CloudSaveService.KEEP_CLOUD]:
		var s := _conflict_pair("c03" + choice)
		var a = s["a"]
		var b = s["b"]
		var mock: MockProvider = s["mock"]
		var info: Dictionary = b.cloud.conflict()
		var remote = JSON.parse_string(mock.data)
		_ok(b.cloud.state() == CloudSaveService.CONFLICT and String(info["reason"]) == "diverged", "%s: diverged copies -> conflict" % choice)
		var want_l := {"level": b.progression.current_level(), "scrub_bucks": b.economy.wallet.scrub_bucks(), "robots": b.economy.robots.snapshot()["unlocked"].size()}
		var want_r := {"level": a.progression.current_level(), "scrub_bucks": a.economy.wallet.scrub_bucks(), "robots": a.economy.robots.snapshot()["unlocked"].size()}
		var ok_sum := true
		for k in want_l:
			ok_sum = ok_sum and int(info["local"][k]) == int(want_l[k]) and int(info["remote"][k]) == int(want_r[k])
		_ok(ok_sum and info["local"]["level"] != info["remote"]["level"] and int(info["remote"]["saved_at"]) == int(remote["saved_at"]) and int(info["local"]["saved_at"]) == _now[0],
			"%s: summaries local %s remote %s" % [choice, str(info["local"]), str(info["remote"])])
		_ok(_bytes(b) == s["b_bytes"] and JSON.stringify(_live(b)) == s["b_live"] and mock.writes == s["writes"], "%s: while CONFLICT nothing changed on either side" % choice)
		_ok(b.cloud.choose("merge")["reason"] == "bad_choice" and b.cloud.state() == CloudSaveService.CONFLICT, "%s: unknown choice refused" % choice)
		_now[0] += 60
		_ok(b.cloud.choose(choice)["ok"] and b.cloud.state() == CloudSaveService.SYNCED, "%s: chosen -> synced" % choice)
		var cloud_now = JSON.parse_string(mock.data)
		if choice == CloudSaveService.KEEP_DEVICE:
			_ok(JSON.stringify(_live(b)) == s["b_live"] and _bytes(b) == s["b_bytes"], "KEEP_DEVICE: device save untouched")
			_ok(mock.writes == s["writes"] + 1 and CloudSave.fingerprint(cloud_now["payload"]) == CloudSave.fingerprint(b.save.collect())
				and int(cloud_now["revision"]) == int(remote["revision"]) + 1 and (cloud_now["lineage"] as Array).has(CloudSave.fingerprint(CloudSave.authority(remote["payload"]))),
				"KEEP_DEVICE: cloud = this device's whole save, revision %d built on the replaced copy" % int(cloud_now["revision"]))
			# Device A still holds progress the chosen copy lacks: it is asked too, never overwritten.
			var a_live := JSON.stringify(_live(a))
			a.cloud.sync()
			_ok(a.cloud.state() == CloudSaveService.CONFLICT and JSON.stringify(_live(a)) == a_live and a.economy.reward.already_applied("c03-a-only"),
				"KEEP_DEVICE: device A (has c03-a-only) gets its own choice, untouched (%s %s)" % [a.cloud.state(), a.cloud.reason()])
			a.cloud.choose(CloudSaveService.KEEP_CLOUD)
			_ok(a.cloud.state() == CloudSaveService.SYNCED and _same(a, b) and not a.economy.reward.already_applied("c03-a-only") and a.economy.reward.already_applied("c03-b-only"),
				"KEEP_DEVICE then A keeps cloud: A = B's whole copy (no merge)")
		else:
			_ok(mock.writes == s["writes"] and mock.data == s["cloud"], "KEEP_CLOUD: cloud copy untouched")
			_ok(_same(a, b) and not b.economy.reward.already_applied("c03-b-only") and b.economy.reward.already_applied("c03-a-only"), "KEEP_CLOUD: device = the whole cloud save (b-only tx gone, no merge)")
			_ok(FileAccess.get_file_as_string(b.save._path + ".bak") == s["b_bytes"], "KEEP_CLOUD: the replaced device save is the M40 backup")
		_ok(b.cloud.choose(choice)["reason"] == "no_conflict", "%s: choose() without a conflict refused" % choice)
	_complete("c03_conflict_choices")

func _c04() -> void:
	print("[c04 restored tx ids never grant twice]")
	var mock := MockProvider.new()
	var a := _app("c04a", mock)
	var pack: String = a.economy.store.sb_pack_ids()[0]
	var r: Dictionary = a.economy.store.deliver({"product_id": pack, "token": "tok-1", "outcome": "purchased"})
	a.economy.reward.grant("c04-gift", {"scrub_bucks": 25})
	a.actions.claim_daily_login()
	a.request_save()
	_ok(bool(r["ok"]) and a.economy.reward.already_applied("store:tok-1"), "store purchase granted once on device A (tx store:tok-1)")
	a.cloud.sync()
	var b := _app("c04b", mock)
	b.cloud.sync()
	b.cloud.choose(CloudSaveService.KEEP_CLOUD)
	var sb: int = b.economy.wallet.scrub_bucks()
	_ok(sb == a.economy.wallet.scrub_bucks() and b.economy.reward.already_applied("store:tok-1"), "restore carries the applied tx set (%d SB)" % sb)
	var again: Dictionary = b.economy.store.deliver({"product_id": pack, "token": "tok-1", "outcome": "purchased"})
	_ok(not bool(again["ok"]) and again["reason"] == "duplicate" and b.economy.wallet.scrub_bucks() == sb, "store re-delivery of tok-1 after restore: duplicate, no SB")
	_ok(not b.economy.reward.grant("c04-gift", {"scrub_bucks": 25}) and b.economy.wallet.scrub_bucks() == sb, "reward replay refused")
	_ok(not b.actions.claim_daily_login()["ok"] and b.economy.wallet.scrub_bucks() == sb, "Daily claim not repeatable")
	_ok(CloudSave.restore(b.save, JSON.parse_string(mock.data))["ok"] and b.economy.wallet.scrub_bucks() == sb, "restoring the same copy again: whole replace, balance not added")
	_complete("c04_no_double_grant")

func _c05() -> void:
	print("[c05 offline / error never touch the local save]")
	var mock := MockProvider.new()
	var a := _app("c05a", mock)
	a.cloud.sync()
	var b := _app("c05b", mock)
	b.cloud.sync()
	b.cloud.choose(CloudSaveService.KEEP_CLOUD)
	b.progression.record_win(1)
	b.economy.reward.grant("c05-b", {"scrub_bucks": 7})
	b.request_save()
	var cloud0 := mock.data
	var fe = JSON.parse_string(cloud0)
	fe["payload"]["version"] = 99
	var future := JSON.stringify(fe)
	var runs := [
		["read offline", func(): mock.read_fail = "offline", CloudSaveService.OFFLINE],
		["read error", func(): mock.read_fail = "auth_expired", CloudSaveService.ERROR],
		["provider refused", func(): mock.refuse = true, CloudSaveService.ERROR],
		["write offline (local ahead)", func(): mock.write_fail = "offline", CloudSaveService.OFFLINE],
		["write error (local ahead)", func(): mock.write_fail = "quota", CloudSaveService.ERROR],
		["garbage cloud copy", func(): mock.data = "{not json", CloudSaveService.ERROR],
		["future-schema cloud copy", func(): mock.data = future, CloudSaveService.ERROR],
	]
	for run in runs:
		mock.read_fail = ""
		mock.write_fail = ""
		mock.refuse = false
		mock.data = cloud0
		run[1].call()
		var cloud_before := mock.data
		var bytes := _bytes(b)
		var live := JSON.stringify(_live(b))
		b.cloud.sync()
		_ok(b.cloud.state() == run[2] and _bytes(b) == bytes and JSON.stringify(_live(b)) == live and mock.data == cloud_before,
			"%s -> %s (%s); local file + live state + cloud unchanged" % [run[0], b.cloud.state(), b.cloud.reason()])
	# Proven descendant arrives but the local save fails: restore rolled back exactly.
	mock.data = cloud0
	mock.write_fail = ""
	var c := _app("c05c", mock)
	c.cloud.sync()
	c.cloud.choose(CloudSaveService.KEEP_CLOUD)
	_now[0] += 60
	a.progression.record_win(1)
	a.cloud.sync()
	var bytes_c := _bytes(c)
	var live_c := JSON.stringify(_live(c))
	c.save.set_fault_injector(func(stage): return stage == "temp_write")
	c.cloud.sync()
	_ok(c.cloud.state() == CloudSaveService.ERROR and c.cloud.reason().begins_with("save:") and _bytes(c) == bytes_c and JSON.stringify(_live(c)) == live_c,
		"descendant restore whose save fails -> error (%s), rolled back exactly" % c.cloud.reason())
	c.save.set_fault_injector(Callable())
	c.cloud.sync()
	_ok(c.cloud.state() == CloudSaveService.SYNCED and _same(a, c), "retry after the fault: descendant taken (%s %s)" % [c.cloud.state(), c.cloud.reason()])
	_anti_rollback()
	_complete("c05_failures_untouched")

## Review 142 r1: a restore never lowers the 2x anti-rollback mark (auto descendant + KEEP_CLOUD).
func _anti_rollback() -> void:
	var t: int = _now[0]
	var mock := MockProvider.new()
	var a := _app("c05ra", mock)
	a.economy.wallet.credit("scrub_bucks", 5000)
	var secs := int(a.economy.config.speed_timed_products()[0]["seconds"])
	_ok(bool(a.economy.speed.purchase_timed(secs)["ok"]), "timed 2x bought (%d s)" % secs)
	a.request_save()
	a.cloud.sync()   # cloud rev 1, mark t
	var b := _app("c05rb", mock)
	b.cloud.sync()
	b.cloud.choose(CloudSaveService.KEEP_CLOUD)
	_now[0] = t + 10
	b.progression.record_win(1)
	b.cloud.sync()   # cloud rev 2 built on rev 1, mark t + 10
	_now[0] = t + secs + 1000
	_ok(a.economy.speed.timed_seconds_remaining() == 0, "device A: timed 2x expired, mark %d" % a.economy.speed.clock_high_water())
	var c := _app("c05rc", mock)   # a fresh device that also saw the late clock
	c.economy.speed.timed_seconds_remaining()
	var late: int = a.economy.speed.clock_high_water()
	_now[0] = t + 100   # clock rolled back, before the cloud copy's timed 2x expiry
	a.cloud.sync()
	_ok(a.cloud.state() == CloudSaveService.SYNCED and _same(a, b), "rolled-back clock: proven descendant (rev 2, mark t+10) applied (%s %s)" % [a.cloud.state(), a.cloud.reason()])
	_ok(a.economy.speed.clock_high_water() >= late and a.economy.speed.timed_seconds_remaining() == 0,
		"auto apply: mark kept %d >= %d, expired timed 2x stays expired" % [a.economy.speed.clock_high_water(), late])
	c.cloud.sync()
	c.cloud.choose(CloudSaveService.KEEP_CLOUD)
	_ok(c.cloud.state() == CloudSaveService.SYNCED and c.economy.speed.clock_high_water() >= late and c.economy.speed.timed_seconds_remaining() == 0,
		"KEEP_CLOUD: mark kept %d >= %d, the cloud's timed 2x stays expired" % [c.economy.speed.clock_high_water(), late])
	_now[0] = t + secs + 2000

func _c06() -> void:
	print("[c06 conflict screen + confirm fit, choice flow]")
	for loc in ["en", "tr"]:
		UiText.locale = loc
		for phys in SIZES:
			var s := _conflict_pair("c06%s%d" % [loc, phys.x])
			var b = s["b"]
			var sub := _mount(phys)
			var stack := ModalStack.new()
			sub.add_child(stack)
			var p = CloudConflictScreen.open(stack, b.cloud)
			await _frames(4)
			var tag := "%s %s (logical %s)" % [loc, str(phys), str(sub.size)]
			_ok(p != null and p.popup_id == "account_conflict" and stack.top() == p, "%s: account_conflict is the top popup" % tag)
			_fit(p, sub, [CloudSaveService.KEEP_DEVICE, CloudSaveService.KEEP_CLOUD], tag)
			var info: Dictionary = b.cloud.conflict()
			var want := [["Device", info["local"]], ["Cloud", info["remote"]]]
			var shown := true
			for w in want:
				var side: Node = p.find_child(w[0], true, false)
				shown = shown and _text(side, "Level") == UiText.t("CLOUD_SUMMARY_LEVEL", [UiText.num(int(w[1]["level"]))]) \
					and _text(side, "ScrubBucks") == UiText.t("CLOUD_SUMMARY_SB", [UiText.num(int(w[1]["scrub_bucks"]))]) \
					and _text(side, "Robots") == UiText.t("CLOUD_SUMMARY_ROBOTS", [UiText.num(int(w[1]["robots"]))]) \
					and _text(side, "LastPlayed") == UiText.t("CLOUD_SUMMARY_LAST", [CloudConflictScreen._date(int(w[1]["saved_at"]))])
			_ok(shown, "%s: both sides show level / Scrub Bucks / robots / last played" % tag)
			p.get_action_button(CloudSaveService.KEEP_CLOUD).pressed.emit()
			await _frames(4)
			var c = stack.top()
			_ok(c != null and c.popup_id == "account_conflict_confirm" and c.get_frame_kind() == "warning" and stack.depth() == 2, "%s: KEEP CLOUD opens the warning confirm" % tag)
			_fit(c, sub, ["confirm", "cancel"], tag + " confirm")
			if loc == "en" and phys == SIZES[0]:
				c.get_action_button("cancel").pressed.emit()
				await _frames(2)
				_ok(stack.top() == p and not p.is_latched() and b.cloud.state() == CloudSaveService.CONFLICT and _bytes(b) == s["b_bytes"], "cancel: back on the choice, re-armed, nothing changed")
				p.get_action_button(CloudSaveService.KEEP_CLOUD).pressed.emit()
				await _frames(2)
				stack.top().get_action_button("confirm").pressed.emit()
				await _frames(2)
				_ok(stack.depth() == 0 and b.cloud.state() == CloudSaveService.SYNCED and _same(s["a"], b), "confirm: choice committed (KEEP_CLOUD), screen closed")
			sub.free()
	UiText.locale = "en"
	_complete("c06_conflict_screen_fit")

func _c07() -> void:
	print("[c07 Settings cloud status line]")
	var a := _app("c07")
	var sub := _mount(Vector2i(1080, 1920))
	var panel = SettingsPanelScene.instantiate()
	panel.bind(a)
	sub.add_child(panel)
	panel.open_panel()
	await _frames(4)
	var line: Label = panel.find_child("CloudStatus", true, false)
	var frame: Control = panel.find_child("Frame", true, false)
	_ok(line != null and line.text == "CLOUD SAVE: NOT AVAILABLE", "null provider: %s" % (line.text if line != null else "<none>"))
	_ok(Rect2(Vector2.ZERO, Vector2(sub.size)).encloses(frame.get_global_rect()) and frame.get_global_rect().encloses(line.get_global_rect()), "line inside the Settings frame, frame fits %s" % str(sub.size))
	var mock := MockProvider.new()
	a.cloud.set_provider(mock)
	a.cloud.sync()
	panel.open_panel()
	_ok(line.text == "CLOUD SAVE: SYNCED", "mock provider after sync: %s" % line.text)
	mock.read_fail = "offline"
	a.cloud.sync()
	panel.open_panel()
	_ok(line.text == "CLOUD SAVE: OFFLINE", "offline: %s" % line.text)
	sub.free()
	_complete("c07_settings_status")

# ---------------------------------------------------------------- helpers ----

## Two devices synced to one copy, then both play differently: A uploads, B is in CONFLICT.
func _conflict_pair(tag: String) -> Dictionary:
	var mock := MockProvider.new()
	var a := _app(tag + "a", mock)
	a.request_save()
	a.cloud.sync()
	var b := _app(tag + "b", mock)
	b.cloud.sync()
	b.cloud.choose(CloudSaveService.KEEP_CLOUD)
	_now[0] += 60
	a.progression.record_win(1)
	a.economy.reward.grant("c03-a-only", {"scrub_bucks": 30})
	a.cloud.sync()
	_now[0] += 60
	b.economy.reward.grant("c03-b-only", {"scrub_bucks": 500})
	b.economy.wallet.credit("bot_parts", 260)
	b.actions.unlock_next_robot()
	b.request_save()
	b.cloud.sync()
	return {"a": a, "b": b, "mock": mock, "b_bytes": _bytes(b), "b_live": JSON.stringify(_live(b)), "writes": mock.writes, "cloud": mock.data}

func _fit(p, sub: SubViewport, actions: Array, tag: String) -> void:
	var screen := Rect2(Vector2.ZERO, Vector2(sub.size))
	var fr: Rect2 = p.get_frame_rect()
	var bad: Array = []
	var rects: Array = []
	for id in actions:
		var r: Rect2 = p.get_action_button(id).get_global_rect()
		if r.size.y < 88.0 - 0.5:
			bad.append("%s<88" % id)
		if not fr.grow(0.5).encloses(r):
			bad.append("%s outside" % id)
		for o in rects:
			if (o as Rect2).intersects(r):
				bad.append("%s overlaps" % id)
		rects.append(r)
	_ok(screen.grow(0.5).encloses(fr) and p.text_fits() and bad.is_empty(), "%s: frame %s inside the screen, text fits, actions ok %s" % [tag, str(fr), str(bad)])

func _app(tag: String, provider = null) -> AppState:
	var path := "user://m54_cloud_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(path)
	var app := AppState.new(path, func(): return _now[0], func(): return _day[0])
	if provider != null:
		app.cloud.set_provider(provider)
	return app

func _sync_path(app) -> String:
	return String(app.save._path).get_basename() + "_cloud.json"

func _bytes(app) -> String:
	return FileAccess.get_file_as_string(app.save._path) if FileAccess.file_exists(app.save._path) else ""

## Live progression + economy truth (CloudSave authority: no meta_ui / wall-clock bookkeeping).
func _live(app) -> Dictionary:
	return CloudSave.authority(app.save.collect())

func _same(x, y) -> bool:
	return CloudSave.fingerprint(CloudSave.authority(x.save.collect())) == CloudSave.fingerprint(CloudSave.authority(y.save.collect()))

func _text(n: Node, child: String) -> String:
	var l = n.find_child(child, true, false) if n != null else null
	return l.text if l is Label else ""

## tests/m49_responsive_matrix.gd logical size of a physical portrait device.
func _mount(phys: Vector2i) -> SubViewport:
	var ratio := float(phys.x) / float(phys.y)
	var sub := SubViewport.new()
	sub.size = Vector2i(int(round(2160.0 * ratio)), 2160) if ratio >= 0.5 else Vector2i(1080, int(round(1080.0 / ratio)))
	sub.disable_3d = true
	get_root().add_child(sub)
	return sub

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _cleanup() -> void:
	for p in _tmp:
		var base := String(p).get_basename()
		for f in [p, p + ".bak", p + ".tmp", base + "_cloud.json", base + "_analytics.json"]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
		_rmdir(base + "_content/")

func _rmdir(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_rmdir(dir + sub + "/")
	for f in d.get_files():
		d.remove(f)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))

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
	print("M54 cloud save seam: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)
