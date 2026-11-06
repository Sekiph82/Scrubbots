extends RefCounted
## AnalyticsService — preload (res://scripts/app/analytics_service.gd).
##
## SB-M56-001..006: the ONE local analytics seam. Events are declared in the versioned
## taxonomy data/config/analytics_taxonomy_v1.json (docs/ANALYTICS_TAXONOMY_V1.md):
##   - consent gate: nothing is validated, queued or stored unless consent is granted
##     (default OFF until the M58 consent screen exists; set_consent() persists it);
##   - schema validation: an unknown event, an undeclared param, a wrong type or a missing
##     required param drops the WHOLE event with a debug warning (never a crash);
##     params are only int / bool / enum / enum_list, so no free text can leave;
##   - pluggable sink: NullSink (default, drops everything) or MemorySink (tests). Events
##     are queued and handed over in batches (batch_size or session end), never per frame;
##   - retention markers (d1/d3/d7/d14/d30) are derived locally from the first consented
##     local day. No server, no provider, no network.
## Write-only: no gameplay, economy, difficulty or save code ever reads from here.

const PATH := "res://data/config/analytics_taxonomy_v1.json"
const SCHEMA := "scrubbots.analytics_taxonomy.v1"
const STATE_VERSION := 1
const RETENTION_DAYS := {1: "d1", 3: "d3", 7: "d7", 14: "d14", 30: "d30"}

class NullSink:
	func write(_batch: Array) -> void:
		pass

class MemorySink:
	var events: Array = []
	func write(batch: Array) -> void:
		events.append_array(batch)

var sink = NullSink.new()
var config_ok := false
var version := 0
var dropped := 0
var _cfg: Dictionary = {}
var _queue: Array = []
var _clock: Callable
var _local_day: Callable
var _state_path := ""
var _state := {"consent": false, "first_day": -1, "markers": []}
var _session_t0 := -1
var _after_level := "none"

## state_path: the small local consent/retention file (never part of the game save).
func _init(state_path: String, clock: Callable, local_day: Callable, path: String = PATH) -> void:
	_state_path = state_path
	_clock = clock
	_local_day = local_day
	var d = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	config_ok = typeof(d) == TYPE_DICTIONARY and d.get("schema") == SCHEMA and typeof(d.get("events")) == TYPE_DICTIONARY
	if config_ok:
		_cfg = d
		version = int(d.get("version", 0))
	var s = JSON.parse_string(FileAccess.get_file_as_string(state_path)) if FileAccess.file_exists(state_path) else null
	if typeof(s) == TYPE_DICTIONARY and int(s.get("version", 0)) == STATE_VERSION and s.get("consent") is bool \
			and typeof(s.get("markers")) == TYPE_ARRAY:
		_state = {"consent": s["consent"], "first_day": int(s.get("first_day", -1)), "markers": s["markers"]}

func now() -> int:
	return int(_clock.call())

func has_consent() -> bool:
	return bool(_state["consent"])

## The M58 consent screen's one entry point. Revoking drops the queue and the local markers.
func set_consent(on: bool) -> void:
	_state = {"consent": on, "first_day": -1, "markers": []}
	_queue.clear()
	_save_state()

## Validate + queue one event. Returns true when queued.
func track(event: String, params: Dictionary = {}) -> bool:
	if not has_consent():
		return false
	var clean = _validate(event, params)
	if clean == null:
		return false
	if event == "level_start":
		_after_level = "none"
	elif event == "level_end":
		_after_level = clean["outcome"]
	_queue.append({"event": event, "v": version, "params": clean})
	if _queue.size() >= int(_cfg.get("batch_size", 20)):
		flush()
	return true

func flush() -> void:
	if _queue.is_empty():
		return
	var batch := _queue
	_queue = []
	sink.write(batch)

func queued() -> int:
	return _queue.size()

## Coarse bucket label for `value` under the taxonomy bucket table `kind` (edges are
## exclusive upper bounds; -1 = everything above).
func bucket(kind: String, value: int) -> String:
	for e in _cfg.get("buckets", {}).get(kind, []):
		if int(e[0]) < 0 or value < int(e[0]):
			return String(e[1])
	return ""

## Session start (cold boot / OS foreground). A second start while one is open is ignored.
func start_session(trigger: String) -> void:
	if _session_t0 >= 0:
		return
	_session_t0 = now()
	_after_level = "none"
	track("session_start", {"trigger": trigger})
	if not has_consent():
		return
	var day := int(_local_day.call())
	if int(_state["first_day"]) < 0:
		_state["first_day"] = day
		_save_state()
		return
	var mark = RETENTION_DAYS.get(day - int(_state["first_day"]))
	if mark != null and not (_state["markers"] as Array).has(mark):
		(_state["markers"] as Array).append(mark)
		_save_state()
		track("retention_day", {"day": mark})

## Session end (OS background / close). No open session = no event (duplicate guard).
func end_session(trigger: String) -> void:
	if _session_t0 < 0:
		return
	track("session_end", {"trigger": trigger, "duration": bucket("duration_s", now() - _session_t0),
		"after_level": _after_level})
	_session_t0 = -1
	flush()

func _validate(event: String, params: Dictionary):
	var def = _cfg.get("events", {}).get(event) if config_ok else null
	if typeof(def) != TYPE_DICTIONARY:
		return _drop("unknown event '%s'" % event)
	var spec: Dictionary = def["params"]
	var out := {}
	for k in params:
		if not spec.has(k):
			return _drop("%s: undeclared param '%s'" % [event, k])
	for k in spec:
		var p: Dictionary = spec[k]
		if not params.has(k):
			if bool(p.get("required", false)):
				return _drop("%s: missing '%s'" % [event, k])
			continue
		var v = params[k]
		var values: Array = p["values"] if p.has("values") else _cfg["enums"].get(p.get("enum", ""), [])
		match String(p["type"]):
			"int":
				if typeof(v) != TYPE_INT or v < int(p["min"]) or v > int(p["max"]):
					return _drop("%s: '%s' not an int in range" % [event, k])
			"bool":
				if typeof(v) != TYPE_BOOL:
					return _drop("%s: '%s' not a bool" % [event, k])
			"enum":
				if not (v is String or v is StringName) or not values.has(String(v)):
					if not p.has("fallback"):
						return _drop("%s: '%s' value not allowed" % [event, k])
					v = p["fallback"]
				v = String(v)
			"enum_list":
				if typeof(v) != TYPE_ARRAY or v.size() > int(p.get("max_items", 0)):
					return _drop("%s: '%s' not a short list" % [event, k])
				for x in v:
					if not (x is String) or not values.has(x):
						return _drop("%s: '%s' item not allowed" % [event, k])
				v = (v as Array).duplicate()
			_:
				return _drop("%s: '%s' has an unknown type" % [event, k])
		out[k] = v
	return out

func _drop(why: String):
	dropped += 1
	if OS.is_debug_build():
		push_warning("Analytics: dropped event, " + why)
	return null

func _save_state() -> void:
	var f := FileAccess.open(_state_path, FileAccess.WRITE)
	if f == null:
		return
	var s := _state.duplicate()
	s["version"] = STATE_VERSION
	f.store_string(JSON.stringify(s))
