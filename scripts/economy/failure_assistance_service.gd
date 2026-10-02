extends RefCounted
## FailureAssistanceService — preload (res://scripts/economy/failure_assistance_service.gd).
##
## M43-C004 (SB-M43-051/052/053/055/056/057/060/061) — the ONE non-UI authority for the
## same-level consecutive-failure counter and the Need a Hand recommendation choice.
##
## Counter (owner lock OWNER_FAIL_RETRY_NEED_HAND_V01 §3):
##   - counts only PROGRESSION terminal failures (the attempt was the canonical frontier);
##     replay / non-frontier failures are excluded and change nothing;
##   - consecutive on the same level: a failure on another level restarts the count;
##   - a progression win resets;
##   - assistance is due when the count reaches the configured trigger (V1: 3); later
##     failures are suppressed until reset unless the config sets a repeat interval.
## Persistence: session-scoped (lives with the app-level AppState graph). It is not part
## of the save file, so a cold relaunch restarts the count (documented in the C004 log).
##
## Recommendation (§4): recommend() ranks the four canonical boosters from caller-supplied
## evidence — `legality` proved on the NEXT canonical start-state (never the terminal
## board) and read-only terminal `context` signals — then the owner fallback order. Only
## legal boosters can be picked; fewer than `count` legal boosters fails closed.
##
## assistance_event(kind, data) is the local seam for future M56 analytics. No provider.

signal assistance_event(kind: String, data: Dictionary)

const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

const DEFAULT_PATH := "res://data/config/failure_assistance_v1.json"
const SCHEMA := "scrubbots.failure_assistance.v1"

var trigger := 0
var repeat_every := 0
var count := 2
var fallback_order: Array = []
var dominant_share := 1.0
var weights: Dictionary = {}
var config_ok := false
var config_error := ""

var _level := 0
var _count := 0

func _init(path: String = DEFAULT_PATH) -> void:
	config_error = _load(path)
	config_ok = config_error.is_empty()

## Fail-closed config load: any malformed value leaves config_ok false (assistance is then
## never due; Fail / Retry are unaffected). Returns "" on success or the reason.
func _load(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return "missing"
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY or d.get("schema", "") != SCHEMA:
		return "bad_schema"
	var t: Dictionary = d.get("trigger", {})
	var r: Dictionary = d.get("recommendation", {})
	var tr = t.get("consecutive_progression_failures")
	var rp = t.get("repeat_every_failures_after_trigger")
	var n = r.get("count")
	var order = r.get("fallback_order")
	var share = r.get("dominant_color_min_share")
	var w = r.get("context_weights")
	if not (_whole(tr) and tr >= 1 and _whole(rp) and rp >= 0 and _whole(n) and n == 2):
		return "bad_trigger"
	if typeof(order) != TYPE_ARRAY or order.size() != BoosterInventory.BOOSTERS.size():
		return "bad_fallback_order"
	for b in BoosterInventory.BOOSTERS:
		if not order.has(b):
			return "bad_fallback_order"
	if not (share is float or share is int) or share <= 0.0 or share > 1.0 or typeof(w) != TYPE_DICTIONARY:
		return "bad_context"
	for sig in w:
		for b in w[sig]:
			if not BoosterInventory.BOOSTERS.has(b) or not _whole(w[sig][b]):
				return "bad_context"
	trigger = int(tr)
	repeat_every = int(rp)
	count = int(n)
	fallback_order = order.duplicate()
	dominant_share = float(share)
	weights = w.duplicate(true)
	return ""

static func _whole(v) -> bool:
	return (v is int) or (v is float and not is_nan(v) and not is_inf(v) and floor(v) == v)

# ------------------------------------------------------------------ counter ----

## Record one authoritative terminal. status "WON" | "LOST"; progression_attempt = the
## attempt was the canonical frontier level. Returns {counted, level, count, due}.
func record_terminal(level: int, status: String, progression_attempt: bool) -> Dictionary:
	if not progression_attempt:
		_emit("excluded_non_progression", {"level": level, "status": status})
		return _result(false, false)
	if status == "WON":
		if _count > 0:
			_emit("reset_win", {"level": _level, "count": _count})
		_level = level
		_count = 0
		return _result(false, false)
	if status != "LOST":
		return _result(false, false)
	if level != _level:
		_reset_level(level)
	_count += 1
	var due := is_due(_count)
	_emit("failure_counted", {"level": _level, "count": _count})
	if due:
		_emit("assistance_due", {"level": _level, "count": _count})
	elif _count > trigger and trigger > 0:
		_emit("assistance_suppressed", {"level": _level, "count": _count})
	return _result(true, due)

## A new progression attempt on `level` (a level change restarts the count).
func on_attempt_started(level: int, progression_attempt: bool) -> void:
	if progression_attempt and level != _level:
		_reset_level(level)

func _reset_level(level: int) -> void:
	if _count > 0:
		_emit("reset_level_change", {"from": _level, "to": level, "count": _count})
	_level = level
	_count = 0

func is_due(n: int) -> bool:
	if not config_ok or n < trigger:
		return false
	return n == trigger or (repeat_every > 0 and (n - trigger) % repeat_every == 0)

func note_shown(level: int, boosters: Array) -> void:
	_emit("assistance_shown", {"level": level, "boosters": boosters.duplicate()})

func note_fail_closed(level: int, reason: String) -> void:
	_emit("assistance_fail_closed", {"level": level, "reason": reason})

func state() -> Dictionary:
	return {"level": _level, "count": _count, "trigger": trigger, "repeat_every": repeat_every,
		"due": is_due(_count), "config_ok": config_ok}

func _result(counted: bool, due: bool) -> Dictionary:
	return {"counted": counted, "level": _level, "count": _count, "due": due}

func _emit(kind: String, data: Dictionary) -> void:
	assistance_event.emit(kind, data)

# ----------------------------------------------------------- recommendation ----

## Pick exactly `count` distinct boosters. context: {signal: bool} read from the terminal
## (read-only). Rank = sum of configured weights of the true signals, ties in fallback
## order. Then walk that ranking and keep each booster `prove.call(id) -> bool` confirms
## is legal on the NEXT canonical start-state, stopping at `count` (so a costly proof such
## as Random's solver run happens only when the ranking reaches it).
## Returns {ok, picks:[{id, score, signals}], proved:{id: bool}, reason}. Deterministic.
func recommend(prove: Callable, context: Dictionary) -> Dictionary:
	if not config_ok:
		return {"ok": false, "picks": [], "proved": {}, "reason": "config_invalid"}
	var ranked: Array = []
	for i in range(fallback_order.size()):
		var id: String = fallback_order[i]
		var score := 0
		var sigs: Array = []
		for sig in weights:
			if bool(context.get(sig, false)) and (weights[sig] as Dictionary).has(id):
				score += int(weights[sig][id])
				sigs.append(sig)
		sigs.sort()
		ranked.append({"id": id, "score": score, "signals": sigs, "order": i})
	ranked.sort_custom(func(a, b): return a["score"] > b["score"] or (a["score"] == b["score"] and a["order"] < b["order"]))
	var picks: Array = []
	var proved := {}
	for e in ranked:
		if picks.size() >= count:
			break
		var legal := bool(prove.call(e["id"])) if prove.is_valid() else false
		proved[e["id"]] = legal
		if legal:
			picks.append({"id": e["id"], "score": e["score"], "signals": e["signals"]})
	if picks.size() < count:
		return {"ok": false, "picks": [], "proved": proved, "reason": "insufficient_meaningful"}
	return {"ok": true, "picks": picks, "proved": proved, "reason": "ok"}
