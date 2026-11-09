extends RefCounted
## CloudSaveService — preload (res://scripts/save/cloud_save_service.gd).
##
## SB-M43-152/154/156/157 — the ONE cloud-sync authority on top of the M40 save. The provider
## (CloudProvider; shipping default = the unavailable base class) only moves one JSON text to
## and from the player's platform account; this service decides what it means:
##   - the cloud copy is a CloudSave envelope: the whole M40 save + {schema, revision, device,
##     saved_at, lineage} header. `device` is a random per-install id (never a hardware id);
##   - states: signed_out / syncing / synced / conflict / error / offline;
##   - CloudSave.resolve decides: equal / local ahead -> keep (upload when ahead); a proven
##     descendant cloud copy (built on exactly this device's last synced state) replaces the
##     local one (its progress is provably contained; the M40 .bak holds the replaced save only
##     until the next save); anything else is a CONFLICT
##     that waits for choose(KEEP_DEVICE | KEEP_CLOUD) — never merged, never auto-picked;
##   - a restore applies the WHOLE payload, so its applied reward-tx set (incl. store:<token>)
##     comes with it and a replayed grant / store re-delivery is refused (no double grant);
##   - read / write failure, an invalid cloud copy or a failed restore never touches the local
##     save (a restore whose save fails is rolled back to the exact pre-restore state).
## The sync bookkeeping (device id + last synced header and authority fingerprint, no save
## content) lives in its own small file, written only after a successful sync.

signal state_changed(state: String)
signal conflict_found(info: Dictionary)

const CloudSave = preload("res://scripts/save/cloud_save.gd")
const CloudProvider = preload("res://scripts/save/cloud_provider.gd")

const SIGNED_OUT := "signed_out"
const SYNCING := "syncing"
const SYNCED := "synced"
const CONFLICT := "conflict"
const ERROR := "error"
const OFFLINE := "offline"
const KEEP_DEVICE := "keep_device"
const KEEP_CLOUD := "keep_cloud"
const STATE_SCHEMA := "scrubbots.cloud_sync.v1"
const DEFAULT_PATH := "user://cloud_sync_v1.json"

var _save
var _provider
var _path: String
var _clock: Callable
var _save_cb: Callable = Callable()
var _state := SIGNED_OUT
var _reason := ""
var _device := ""
## Last envelope this device synced: {revision, saved_at, device, lineage, fp} or {}.
var _last: Dictionary = {}
## While CONFLICT: {local, remote, info}.
var _conflict: Dictionary = {}

func _init(save_service, path: String = DEFAULT_PATH, clock: Callable = Callable(), provider = null) -> void:
	_save = save_service
	_path = path
	_clock = clock
	_provider = provider if provider != null else CloudProvider.new()
	_load_state()

func set_provider(p) -> void:
	_provider = p if p != null else CloudProvider.new()
	_conflict = {}
	_set_state(SIGNED_OUT)

func bind_save(cb: Callable) -> void:
	_save_cb = cb

func is_available() -> bool:
	return _provider.is_available()

func state() -> String:
	return _state

func reason() -> String:
	return _reason

func device_id() -> String:
	if _device.is_empty():
		_device = Crypto.new().generate_random_bytes(16).hex_encode()
	return _device

## {local, remote}: each {level, scrub_bucks, robots, saved_at, ...} while CONFLICT, else {}.
func conflict() -> Dictionary:
	return (_conflict.get("info", {}) as Dictionary).duplicate(true)

## Start the platform's own sign-in UI; a successful sign-in syncs.
func sign_in() -> Dictionary:
	if not is_available():
		return {"ok": false, "reason": "unavailable"}
	if not _provider.sign_in(Callable(self, "_on_signed_in")):
		return {"ok": false, "reason": "provider_refused"}
	return {"ok": true}

func _on_signed_in(r: Dictionary) -> void:
	if bool(r.get("ok", false)):
		sync()
	else:
		_set_state(SIGNED_OUT, String(r.get("reason", "")))

## Read the cloud copy and reconcile. The result arrives through state_changed.
func sync() -> Dictionary:
	if _state == SYNCING:
		return {"ok": false, "reason": "busy"}
	if not is_available() or not _provider.is_signed_in():
		_set_state(SIGNED_OUT)
		return {"ok": false, "reason": SIGNED_OUT}
	_conflict = {}
	_set_state(SYNCING)
	if not _provider.read(Callable(self, "_on_read")):
		_fail({"reason": "provider_refused"})
		return {"ok": false, "reason": "provider_refused"}
	return {"ok": true}

func _on_read(r: Dictionary) -> void:
	if _state != SYNCING:
		return
	if not bool(r.get("ok", false)):
		_fail(r)
		return
	var local := _local_envelope()
	var data := String(r.get("data", ""))
	if data.is_empty():
		_upload(local)
		return
	var json := JSON.new()
	var remote = json.get_data() if json.parse(data) == OK else null
	var res: Dictionary = CloudSave.resolve(_save, local, remote)
	match String(res["action"]):
		"keep_local":
			if res["reason"] == "local_ahead":
				_upload(local)
			else:
				_mark(remote)
				_set_state(SYNCED)
		"take_remote":
			_apply_remote(remote)
		"conflict":
			var info := {"reason": res["reason"], "local": res["local"], "remote": res["remote"]}
			info["local"]["saved_at"] = int(local["saved_at"])
			info["remote"]["saved_at"] = int(remote["saved_at"])
			_conflict = {"local": local, "remote": remote, "info": info}
			_set_state(CONFLICT, String(res["reason"]))
			conflict_found.emit(info.duplicate(true))
		_:
			_set_state(ERROR, "%s:%s" % [res["action"], res["reason"]])

## The player's confirmed conflict choice: KEEP_DEVICE overwrites the cloud copy with this
## device's save, KEEP_CLOUD replaces this device's save with the cloud copy.
func choose(choice: String) -> Dictionary:
	if _state != CONFLICT:
		return {"ok": false, "reason": "no_conflict"}
	var remote: Dictionary = _conflict["remote"]
	if choice == KEEP_CLOUD:
		_conflict = {}
		_apply_remote(remote)
	elif choice == KEEP_DEVICE:
		var local: Dictionary = _conflict["local"]
		_conflict = {}
		# Built on the cloud copy, so every other device sees a proven descendant.
		var env := CloudSave.envelope(_save, device_id(), maxi(int(local["revision"]), int(remote["revision"])) + 1,
			maxi(_now(), int(remote["saved_at"])))
		env["lineage"] = _after(remote["lineage"], CloudSave.fingerprint(CloudSave.authority(remote["payload"])))
		_upload(env)
	else:
		return {"ok": false, "reason": "bad_choice"}
	return {"ok": true}

## This device's save as an envelope. Unchanged since the last sync -> that exact header (so a
## cloud copy built on it is a proven descendant); changed -> a new revision built on it.
func _local_envelope() -> Dictionary:
	if _last.is_empty():
		return CloudSave.envelope(_save, device_id(), 1, _now())
	var env: Dictionary
	if CloudSave.fingerprint(CloudSave.authority(_save.collect())) == _last["fp"]:
		env = CloudSave.envelope(_save, String(_last["device"]), int(_last["revision"]), int(_last["saved_at"]))
		env["lineage"] = (_last["lineage"] as Array).duplicate()
	else:
		env = CloudSave.envelope(_save, device_id(), int(_last["revision"]) + 1, maxi(_now(), int(_last["saved_at"])))
		env["lineage"] = _after(_last["lineage"], _last["fp"])
	return env

static func _after(lineage: Array, fp: String) -> Array:
	var out := lineage.duplicate()
	out.append(fp)
	while out.size() > CloudSave.LINEAGE_MAX:
		out.pop_front()
	return out

func _upload(env: Dictionary) -> void:
	_set_state(SYNCING)
	if not _provider.write(JSON.stringify(env), Callable(self, "_on_written").bind(env)):
		_fail({"reason": "provider_refused"})

func _on_written(r: Dictionary, env: Dictionary) -> void:
	if _state != SYNCING:
		return
	if not bool(r.get("ok", false)):
		_fail(r)
		return
	_mark(env)
	_set_state(SYNCED)

## Whole-save restore through the M40 rules, then the canonical save. A failed restore or save
## leaves the local save exactly as it was. The 2x anti-rollback mark never goes down: the copy
## is restored with max(this device's mark, the cloud copy's mark) (the mark is outside the
## CloudSave authority, so it is never a reason to accept or reject a copy).
func _apply_remote(remote: Dictionary) -> void:
	var pre: Dictionary = _save.collect()
	var cand := remote.duplicate(true)
	var speed = (cand["payload"].get("economy", {}) as Dictionary).get("speed") if typeof(cand.get("payload")) == TYPE_DICTIONARY else null
	if typeof(speed) == TYPE_DICTIONARY:
		var mine := int(pre["economy"]["speed"]["clock_high_water"])
		var theirs = speed.get("clock_high_water", 0)
		speed["clock_high_water"] = maxi(mine, int(theirs)) if typeof(theirs) == TYPE_INT or typeof(theirs) == TYPE_FLOAT else theirs
	var r: Dictionary = CloudSave.restore(_save, cand)
	if not bool(r["ok"]):
		_set_state(ERROR, "restore:" + String(r["reason"]))
		return
	if _save_cb.is_valid():
		var s: Dictionary = _save_cb.call()
		if not bool(s.get("ok", false)):
			_save._apply(pre)
			_set_state(ERROR, "save:" + String(s.get("reason", "")))
			return
	_mark(remote)
	_set_state(SYNCED)

func _fail(r: Dictionary) -> void:
	_conflict = {}
	var why := String(r.get("reason", ""))
	_set_state(OFFLINE if why == OFFLINE else ERROR, why)

func _set_state(s: String, why: String = "") -> void:
	_state = s
	_reason = why
	state_changed.emit(s)

func _now() -> int:
	return int(_clock.call()) if _clock.is_valid() else int(Time.get_unix_time_from_system())

# ------------------------------------------------------------- bookkeeping ----

func _mark(env: Dictionary) -> void:
	_last = {"revision": int(env["revision"]), "saved_at": int(env["saved_at"]), "device": String(env.get("device", "")),
		"lineage": (env["lineage"] as Array).duplicate(), "fp": CloudSave.fingerprint(CloudSave.authority(env["payload"]))}
	var f := FileAccess.open(_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"schema": STATE_SCHEMA, "device": device_id(), "last": _last}))
		f.close()

## A missing / malformed bookkeeping file = never synced (the next sync can only conflict or
## upload, never silently replace the local save).
func _load_state() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(_path)) if FileAccess.file_exists(_path) else null
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != STATE_SCHEMA or typeof(d.get("device")) != TYPE_STRING:
		return
	_device = d["device"]
	var l = d.get("last")
	if typeof(l) == TYPE_DICTIONARY and typeof(l.get("revision")) == TYPE_FLOAT and typeof(l.get("saved_at")) == TYPE_FLOAT \
			and typeof(l.get("device")) == TYPE_STRING and typeof(l.get("lineage")) == TYPE_ARRAY and typeof(l.get("fp")) == TYPE_STRING:
		_last = {"revision": int(l["revision"]), "saved_at": int(l["saved_at"]), "device": l["device"], "lineage": l["lineage"], "fp": l["fp"]}
