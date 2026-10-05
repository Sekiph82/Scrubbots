extends RefCounted
## CloudSave — preload (res://scripts/save/cloud_save.gd).
##
## M43-C013 (SB-M43-152/154/155/157) — provider-neutral cloud-save envelope + conflict rules on
## top of the M40 save. No account / network SDK is wired (SB-M43-153 owner/platform decision):
## the LOCAL save stays authoritative and fully offline; this module only defines what a
## cloud copy is and how two copies are reconciled.
##   - envelope = {schema, revision, device, saved_at, lineage, payload: SaveService.collect(), summary};
##     `lineage` = authority fingerprints of the copies this one was built on (the last synced
##     envelope is passed as `previous`), newest last, bounded to LINEAGE_MAX;
##   - restore(save_service, envelope): validate -> migrate -> atomic apply (M40 rules).
##
## resolve(local, remote) — SB-M43-155, master remediation V03. A cloud copy is a WHOLE save:
## the result only ever names one side to keep; currencies / rewards are never field-merged.
## Both envelopes are validated first (shape + exact-int revision / saved_at + M40 payload
## validation); a malformed / future remote fails closed (invalid_remote), a malformed local
## refuses to decide (invalid_local). Then, conservatively:
##   1. exact canonical payload equality -> keep_local / "equal" (the ONLY "equal" case);
##   2. identical AUTHORITY (progression + every economy section except presentation-only
##      `meta_ui`) with only device settings / meta_ui differing -> keep_local / "same_authority";
##   3. one side a strict descendant -> that whole side wins, only when ALL hold:
##      - its completed-level set and reward-tx set are supersets (at least one strictly larger);
##      - every append-only history (robot unlocks, win-streak processed levels, gift tx,
##        claimed set rewards, Master claim, pack receipts) is a superset too;
##      - its revision is strictly higher AND its saved_at is not older;
##      - ANCESTRY PROOF: the other side's exact authority fingerprint is in its lineage, i.e.
##        it was built on precisely that state (so a spend / wallet-only change made on the
##        other side after the fork can never be silently overwritten or refunded).
##      Any contradiction (stale/newer order against the history direction, a history the
##      "ahead" side lacks, no ancestry proof) proves nothing safe -> conflict;
##   4. same progression + tx history but different authoritative economy (wallet after a
##      spend, Collection copies, robots, boosters, Daily, ...) -> conflict: a lower balance can
##      be a legitimate spend, so no balance is ever treated as "newer";
##   5. diverged histories -> conflict.
## A conflict carries both (recomputed, never trusted) summaries; the player chooses one whole copy.

const SCHEMA := "scrubbots.cloud.v1"
const IntDomain = preload("res://scripts/economy/int_domain.gd")
const LINEAGE_MAX := 64

## Presentation-only economy sections: never economy truth (MetaUiState is acknowledgements).
const TRANSIENT_ECONOMY := ["meta_ui"]
## Order-free id sets inside the payload (canonicalised as sorted sets).
const SET_PATHS := [["progression", "completed"], ["economy", "reward", "applied"], ["economy", "robots", "unlocked"],
	["economy", "streak", "processed"], ["economy", "gift", "applied"], ["economy", "collection", "set_reward_claimed"]]
## Append-only histories: a true descendant can never lack an entry of its ancestor.
const HISTORY_PATHS := [["economy", "robots", "unlocked"], ["economy", "streak", "processed"], ["economy", "gift", "applied"],
	["economy", "collection", "set_reward_claimed"], ["economy", "pack_receipts", "receipts"]]

## `previous` = the last envelope this device synced (uploaded or restored), or null.
static func envelope(save_service, device_id: String, revision: int, now_ts: int, previous = null) -> Dictionary:
	var payload: Dictionary = save_service.collect()
	var lineage: Array = []
	if typeof(previous) == TYPE_DICTIONARY and typeof(previous.get("payload")) == TYPE_DICTIONARY:
		if typeof(previous.get("lineage")) == TYPE_ARRAY:
			lineage = (previous["lineage"] as Array).duplicate()
		lineage.append(fingerprint(authority(previous["payload"])))
		while lineage.size() > LINEAGE_MAX:
			lineage.pop_front()
	return {"schema": SCHEMA, "revision": revision, "device": device_id, "saved_at": now_ts,
		"lineage": lineage, "payload": payload, "summary": summary(payload)}

static func summary(payload: Dictionary) -> Dictionary:
	var prog: Dictionary = payload.get("progression", {})
	var econ: Dictionary = payload.get("economy", {})
	return {"completed": (prog.get("completed", []) as Array).size(), "level": int(prog.get("current_level", 1)),
		"tx": ((econ.get("reward", {}) as Dictionary).get("applied", []) as Array).size()}

## Deterministic canonical form: integral floats -> int (JSON round trips), dictionary keys
## sorted by JSON.stringify, order-free id sets sorted. Arrays elsewhere keep their order.
static func canonical(v, path: Array = []):
	match typeof(v):
		TYPE_FLOAT:
			if not is_nan(v) and not is_inf(v) and floor(v) == v and absf(v) < 9.0e15:
				return int(v)
			return v
		TYPE_DICTIONARY:
			var out := {}
			for k in v:
				out[String(k)] = canonical(v[k], path + [String(k)])
			return out
		TYPE_ARRAY:
			var arr: Array = []
			for e in v:
				arr.append(canonical(e, path))
			if SET_PATHS.has(path):
				arr.sort_custom(func(a, b): return JSON.stringify(a) < JSON.stringify(b))
			return arr
	return v

static func fingerprint(v) -> String:
	return JSON.stringify(canonical(v)).sha256_text()

## Authoritative part of a payload: progression + economy minus presentation-only sections.
static func authority(payload: Dictionary) -> Dictionary:
	var econ: Dictionary = (payload.get("economy", {}) as Dictionary).duplicate(true)
	for k in TRANSIENT_ECONOMY:
		econ.erase(k)
	return {"progression": payload.get("progression", {}), "economy": econ}

## Validates the envelope shape and its payload (M40 dry-run). {ok, reason}.
static func validate_envelope(save_service, env) -> Dictionary:
	if typeof(env) != TYPE_DICTIONARY or env.get("schema") != SCHEMA or typeof(env.get("payload")) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "envelope"}
	if IntDomain.nonneg_int(env.get("revision")) == null or IntDomain.nonneg_int(env.get("saved_at")) == null:
		return {"ok": false, "reason": "envelope_order"}
	if env.has("device") and typeof(env["device"]) != TYPE_STRING:
		return {"ok": false, "reason": "envelope_device"}
	var lineage = env.get("lineage")
	if typeof(lineage) != TYPE_ARRAY or (lineage as Array).size() > LINEAGE_MAX:
		return {"ok": false, "reason": "envelope_lineage"}
	for fp in lineage:
		if typeof(fp) != TYPE_STRING or (fp as String).length() != 64 or not (fp as String).is_valid_hex_number():
			return {"ok": false, "reason": "envelope_lineage"}
	var v: Dictionary = save_service.validate_candidate(env["payload"].duplicate(true))
	if not bool(v.get("ok", false)):
		return {"ok": false, "reason": String(v.get("reason", ""))}
	return {"ok": true}

static func _at(payload: Dictionary, path: Array):
	var cur = payload
	for k in path:
		if typeof(cur) != TYPE_DICTIONARY or not cur.has(k):
			return null
		cur = cur[k]
	return cur

static func _id_set(payload: Dictionary, path: Array) -> Dictionary:
	var out := {}
	var arr = _at(payload, path)
	if typeof(arr) == TYPE_ARRAY:
		for e in arr:
			out[JSON.stringify(canonical(e))] = true
	return out

static func _superset(a: Dictionary, b: Dictionary) -> bool:
	for k in b:
		if not a.has(k):
			return false
	return true

## "" when `desc` is provably a strict descendant of `anc` (history, order, ancestry); else the conflict reason.
static func _descends(desc: Dictionary, anc: Dictionary) -> String:
	var dp: Dictionary = desc["payload"]
	var ap: Dictionary = anc["payload"]
	for path in HISTORY_PATHS:
		if not _superset(_id_set(dp, path), _id_set(ap, path)):
			return "history_contradiction"
	if bool(_at(ap, ["economy", "collection", "master_claimed"])) and not bool(_at(dp, ["economy", "collection", "master_claimed"])):
		return "history_contradiction"
	if IntDomain.exact_int(desc["revision"]) <= IntDomain.exact_int(anc["revision"]) or IntDomain.exact_int(desc["saved_at"]) < IntDomain.exact_int(anc["saved_at"]):
		return "order_contradiction"
	if not (desc["lineage"] as Array).has(fingerprint(authority(ap))):
		return "no_ancestry_proof"
	return ""

static func _conflict(reason: String, lp: Dictionary, rp: Dictionary) -> Dictionary:
	return {"action": "conflict", "reason": reason, "local": summary(lp), "remote": summary(rp)}

## {action: keep_local | take_remote | conflict | invalid_remote | invalid_local, reason[, local, remote]}
static func resolve(save_service, local, remote) -> Dictionary:
	var rv := validate_envelope(save_service, remote)
	if not bool(rv["ok"]):
		return {"action": "invalid_remote", "reason": String(rv["reason"])}
	var lv := validate_envelope(save_service, local)
	if not bool(lv["ok"]):
		return {"action": "invalid_local", "reason": String(lv["reason"])}
	var lp: Dictionary = local["payload"]
	var rp: Dictionary = remote["payload"]
	if fingerprint(lp) == fingerprint(rp):
		return {"action": "keep_local", "reason": "equal"}
	var tx := ["economy", "reward", "applied"]
	var done := ["progression", "completed"]
	var lt := _id_set(lp, tx)
	var rt := _id_set(rp, tx)
	var lc := _id_set(lp, done)
	var rc := _id_set(rp, done)
	var l_all: bool = _superset(lt, rt) and _superset(lc, rc)
	var r_all: bool = _superset(rt, lt) and _superset(rc, lc)
	if l_all and r_all:
		if fingerprint(authority(lp)) == fingerprint(authority(rp)):
			return {"action": "keep_local", "reason": "same_authority"}
		return _conflict("same_history_economy_differs", lp, rp)
	if l_all:
		var why := _descends(local, remote)
		return {"action": "keep_local", "reason": "local_ahead"} if why.is_empty() else _conflict(why, lp, rp)
	if r_all:
		var why := _descends(remote, local)
		return {"action": "take_remote", "reason": "remote_ahead"} if why.is_empty() else _conflict(why, lp, rp)
	return _conflict("diverged", lp, rp)

## Apply a cloud copy through the M40 load rules (validate, migrate, atomic apply). The whole
## payload is applied; nothing is merged with the live save.
static func restore(save_service, env: Dictionary) -> Dictionary:
	var ev := validate_envelope(save_service, env)
	if not bool(ev["ok"]):
		return {"ok": false, "reason": String(ev["reason"])}
	var cand: Dictionary = env["payload"].duplicate(true)
	if not save_service._apply(save_service.migrate(cand)):
		return {"ok": false, "reason": "apply"}
	return {"ok": true}
