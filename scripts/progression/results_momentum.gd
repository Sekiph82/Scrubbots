extends RefCounted
## ResultsMomentum — preload (res://scripts/progression/results_momentum.gd).
##
## M43-C001R (SB-M43-R01-001..007) — the ONE read-only authority for the post-win momentum
## corridor and the 10-Level Cleaning Journey, shared by Results and Home.
##
## Reads only: canonical LevelProgressionService (frontier, class_for). It never grants, unlocks, advances progression, chooses difficulty,
## writes save state or owns UI nodes. There is no journey state of its own: every journey
## is derived from (progression, context, anchor level).
##
## Cycle math (anchor n >= 1): cycle = floor((n - 1) / L) + 1, slot = ((n - 1) % L) + 1.
##   home     anchor = current frontier: slots < anchor complete, anchor slot "current".
##   results  anchor = just-completed level: slots <= anchor complete, the next slot in the
##            same cycle (if any) is "next"; L10 -> 10/10 complete.
##
## SB-PHONE-2026-11-12-B (owner 2026-11-12): the Next Cleanup teaser read model is gone (a win
## goes Home). The config's `teaser` block still carries `reveal_delay_s` (journey reveal); its
## visible_area_fraction fields stay validated but unused.

const DEFAULT_CONFIG := "res://data/config/results_momentum_v1.json"
const SCHEMA := "scrubbots.results_momentum.v1"
const REVEAL_MODE := "cropped_detail"
## Owner lock (TASKS M43-C001R): ten cadence slots, slot 5 mini-boss, slot 10 cycle boss.
const OWNER_CYCLE := 10
const OWNER_MINI := 5
const OWNER_BOSS := 10

## Validated presentation config. Fail closed: {ok:false, reason} on any malformed value.
static func load_config(path: String = DEFAULT_CONFIG) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"ok": false, "reason": "missing"}
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY or d.get("schema", "") != SCHEMA or not _whole(d.get("version")) or int(d["version"]) != 1:
		return {"ok": false, "reason": "bad_schema"}
	var j = d.get("journey")
	var t = d.get("teaser")
	if typeof(j) != TYPE_DICTIONARY or typeof(t) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "bad_shape"}
	for k in ["cycle_length", "mini_boss_slot", "boss_slot"]:
		if not _whole(j.get(k)):
			return {"ok": false, "reason": "bad_" + k}
	if int(j["cycle_length"]) != OWNER_CYCLE or int(j["mini_boss_slot"]) != OWNER_MINI or int(j["boss_slot"]) != OWNER_BOSS:
		return {"ok": false, "reason": "journey_not_owner_locked"}
	var lo = t.get("visible_area_fraction_min")
	var hi = t.get("visible_area_fraction_max")
	var fr = t.get("visible_area_fraction")
	var delay = t.get("reveal_delay_s")
	if t.get("reveal_mode", "") != REVEAL_MODE:
		return {"ok": false, "reason": "bad_reveal_mode"}
	if not (_num(lo) and _num(hi) and _num(fr) and _num(delay)):
		return {"ok": false, "reason": "bad_teaser_numbers"}
	# The configured envelope may only narrow the owner-approved 0.15..0.25 range.
	if lo < 0.15 or hi > 0.25 or lo > hi or fr < lo or fr > hi or delay < 0.0 or delay > 1.0:
		return {"ok": false, "reason": "teaser_out_of_range"}
	return {"ok": true, "reason": "", "cycle_length": OWNER_CYCLE, "mini_boss_slot": OWNER_MINI, "boss_slot": OWNER_BOSS,
		"reveal_mode": REVEAL_MODE, "fraction": float(fr), "fraction_min": float(lo), "fraction_max": float(hi),
		"reveal_delay_s": float(delay)}

static func _whole(v) -> bool:
	return (v is int) or (v is float and not is_nan(v) and not is_inf(v) and floor(v) == v)

static func _num(v) -> bool:
	return (v is int) or (v is float and not is_nan(v) and not is_inf(v))

static func cycle_of(n: int, length: int = OWNER_CYCLE) -> int:
	return int(floor(float(n - 1) / length)) + 1

static func slot_of(n: int, length: int = OWNER_CYCLE) -> int:
	return ((n - 1) % length) + 1

# ------------------------------------------------------------------ journey ----

## Journey read model. context "home" | "results". {ok, context, anchor, cycle, slot,
## completed, length, nodes:[{slot, level, state, beat, class}]}. Pure read.
static func journey(progression, context: String, anchor: int, cfg: Dictionary) -> Dictionary:
	if not bool(cfg.get("ok", false)) or progression == null or anchor < 1 or not (context in ["home", "results"]):
		return {"ok": false, "reason": "unavailable"}
	var length: int = cfg["cycle_length"]
	var slot := slot_of(anchor, length)
	var cycle := cycle_of(anchor, length)
	var first := (cycle - 1) * length + 1
	var nodes: Array = []
	var completed := 0
	for s in range(1, length + 1):
		var state := "future"
		if context == "home":
			state = "complete" if s < slot else ("current" if s == slot else "future")
		else:
			state = "complete" if s <= slot else ("next" if s == slot + 1 else "future")
		if state == "complete":
			completed += 1
		var beat := "boss" if s == int(cfg["boss_slot"]) else ("mini_boss" if s == int(cfg["mini_boss_slot"]) else "normal")
		nodes.append({"slot": s, "level": first + s - 1, "state": state, "beat": beat,
			"class": String(progression.class_for(first + s - 1))})
	return {"ok": true, "context": context, "anchor": anchor, "cycle": cycle, "slot": slot,
		"completed": completed, "length": length, "nodes": nodes}

static func home_journey(app_state, cfg: Dictionary) -> Dictionary:
	if app_state == null or app_state.progression == null:
		return {"ok": false, "reason": "no_app_state"}
	return journey(app_state.progression, "home", int(app_state.progression.current_level()), cfg)

# ------------------------------------------------------------ Results model ----

## Results momentum for a WON on `completed_level`: {ok, reason, reveal_delay_s, journey}.
## SB-PHONE-2026-11-12-B: no Next Cleanup teaser on Results (a win goes Home).
static func results_model(app_state, completed_level: int, cfg: Dictionary = {}) -> Dictionary:
	if cfg.is_empty():
		cfg = load_config()
	if not bool(cfg.get("ok", false)) or app_state == null or app_state.progression == null:
		return {"ok": false, "reason": String(cfg.get("reason", "no_app_state"))}
	return {"ok": true, "reason": "", "reveal_delay_s": cfg["reveal_delay_s"],
		"journey": journey(app_state.progression, "results", completed_level, cfg)}
