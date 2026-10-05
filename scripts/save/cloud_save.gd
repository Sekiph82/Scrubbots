extends RefCounted
## CloudSave — preload (res://scripts/save/cloud_save.gd).
##
## M43-C013 (SB-M43-152/154/155/157) — provider-neutral cloud-save envelope + conflict rules on
## top of the M40 save. No account / network SDK is wired (SB-M43-153 owner/platform decision):
## the LOCAL save stays authoritative and fully offline; this module only defines what a
## cloud copy is and how two copies are reconciled.
##   - envelope = {schema, revision, device, saved_at, payload: SaveService.collect(), summary};
##   - resolve(local, remote): never merges currencies. A copy whose applied reward transactions
##     AND progression are both a superset of the other's wins; equal copies keep local; a copy
##     failing M40 validation is ignored; anything else is a CONFLICT the player must resolve
##     explicitly (choose one whole copy), so rewards can never be duplicated;
##   - restore(save_service, envelope): validate -> migrate -> atomic apply (M40 rules).

const SCHEMA := "scrubbots.cloud.v1"

static func envelope(save_service, device_id: String, revision: int, now_ts: int) -> Dictionary:
	var payload: Dictionary = save_service.collect()
	return {"schema": SCHEMA, "revision": revision, "device": device_id, "saved_at": now_ts,
		"payload": payload, "summary": summary(payload)}

static func summary(payload: Dictionary) -> Dictionary:
	var prog: Dictionary = payload.get("progression", {})
	var econ: Dictionary = payload.get("economy", {})
	return {"completed": (prog.get("completed", []) as Array).size(), "level": int(prog.get("current_level", 1)),
		"tx": ((econ.get("reward", {}) as Dictionary).get("applied", []) as Array).size()}

static func _txs(env: Dictionary) -> Dictionary:
	var out := {}
	for t in env["payload"].get("economy", {}).get("reward", {}).get("applied", []):
		out[String(t)] = true
	return out

static func _completed(env: Dictionary) -> Dictionary:
	var out := {}
	for n in env["payload"].get("progression", {}).get("completed", []):
		out[int(n)] = true
	return out

static func _superset(a: Dictionary, b: Dictionary) -> bool:
	for k in b:
		if not a.has(k):
			return false
	return true

## {action: keep_local | take_remote | conflict | invalid_remote, reason}
static func resolve(save_service, local: Dictionary, remote) -> Dictionary:
	if typeof(remote) != TYPE_DICTIONARY or remote.get("schema") != SCHEMA or typeof(remote.get("payload")) != TYPE_DICTIONARY:
		return {"action": "invalid_remote", "reason": "envelope"}
	var v: Dictionary = save_service.validate_candidate(remote["payload"].duplicate(true))
	if not bool(v.get("ok", false)):
		return {"action": "invalid_remote", "reason": String(v.get("reason", ""))}
	var lt := _txs(local)
	var rt := _txs(remote)
	var lc := _completed(local)
	var rc := _completed(remote)
	var l_has_all: bool = _superset(lt, rt) and _superset(lc, rc)
	var r_has_all: bool = _superset(rt, lt) and _superset(rc, lc)
	if l_has_all:
		return {"action": "keep_local", "reason": "equal" if r_has_all else "local_ahead"}
	if r_has_all:
		return {"action": "take_remote", "reason": "remote_ahead"}
	return {"action": "conflict", "reason": "diverged", "local": local["summary"], "remote": remote["summary"]}

## Apply a cloud copy through the M40 load rules (validate, migrate, atomic apply).
static func restore(save_service, env: Dictionary) -> Dictionary:
	if env.get("schema") != SCHEMA or typeof(env.get("payload")) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "envelope"}
	var cand: Dictionary = env["payload"].duplicate(true)
	var v: Dictionary = save_service.validate_candidate(cand)
	if not bool(v.get("ok", false)):
		return {"ok": false, "reason": String(v.get("reason", ""))}
	if not save_service._apply(save_service.migrate(cand)):
		return {"ok": false, "reason": "apply"}
	return {"ok": true}
