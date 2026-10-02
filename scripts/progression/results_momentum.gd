extends RefCounted
## ResultsMomentum — preload (res://scripts/progression/results_momentum.gd).
##
## M43-C001R (SB-M43-R01-001..007) — the ONE read-only authority for the post-win momentum
## corridor and the 10-Level Cleaning Journey, shared by Results and Home.
##
## Reads only: canonical LevelProgressionService (frontier, class_for), the production
## LevelCatalog through GameplayLaunchResolver (the same frontier -> content truth gameplay
## launches), the resolved entry's LevelData (local palette = used colours) and its real
## preview texture. It never grants, unlocks, advances progression, chooses difficulty,
## writes save state or owns UI nodes. There is no journey state of its own: every journey
## is derived from (progression, context, anchor level).
##
## Cycle math (anchor n >= 1): cycle = floor((n - 1) / L) + 1, slot = ((n - 1) % L) + 1.
##   home     anchor = current frontier: slots < anchor complete, anchor slot "current".
##   results  anchor = just-completed level: slots <= anchor complete, the next slot in the
##            same cycle (if any) is "next"; L10 -> 10/10 complete.
##
## Next Cleanup teaser: a deterministic cropped detail of the entry's real preview, about
## `visible_area_fraction` (V1 0.20, owner envelope 0.15..0.25) of the full image. Only the
## crop rectangle is ever handed to UI (as an AtlasTexture region), so the full next puzzle
## is never drawn. No preview -> no image (never another level's art).

const LevelLoader = preload("res://scripts/data/level_loader.gd")

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

# ------------------------------------------------------------- Next Cleanup ----

## Teaser read model for the canonical next frontier. `launch` is a
## GameplayLaunchResolver.resolve() result (the same one Continue uses).
## {available, reason, level, entry_id, difficulty, color_count, preview_path,
##  image_ok, preview_size: Vector2i, crop: Rect2i, crop_fraction}.
static func next_cleanup(launch: Dictionary, cfg: Dictionary) -> Dictionary:
	var out := {"available": false, "reason": String(launch.get("reason", "")), "level": int(launch.get("level", 0)),
		"entry_id": "", "difficulty": "", "color_count": -1, "preview_path": "", "image_ok": false,
		"preview_size": Vector2i.ZERO, "crop": Rect2i(), "crop_fraction": 0.0}
	if not bool(launch.get("ok", false)):
		return out
	out["available"] = true
	out["reason"] = ""
	out["entry_id"] = String(launch.get("entry_id", ""))
	out["difficulty"] = String(launch.get("difficulty", ""))
	var lr = LevelLoader.load_from_path(String(launch.get("level_path", "")))
	if lr.is_ok():
		out["color_count"] = lr.level_data.palette.size()   # local palette = used canonical colours
	var path := String(launch.get("preview_path", ""))
	out["preview_path"] = path
	if not bool(cfg.get("ok", false)) or path.is_empty() or not ResourceLoader.exists(path):
		return out
	var tex = load(path) as Texture2D
	if tex == null:
		return out
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return out
	var crop := crop_rect(img, out["entry_id"], float(cfg["fraction"]))
	var full := img.get_width() * img.get_height()
	var frac := float(crop.size.x * crop.size.y) / float(full) if full > 0 else 0.0
	if crop.size.x < 1 or frac < float(cfg["fraction_min"]) or frac > float(cfg["fraction_max"]):
		return out   # cannot honour the disclosure envelope -> no image at all
	out["image_ok"] = true
	out["preview_size"] = Vector2i(img.get_width(), img.get_height())
	out["crop"] = crop
	out["crop_fraction"] = frac
	return out

## Deterministic cropped detail: a w x h window (w = W*sqrt(f), h = H*sqrt(f)) inside the
## image. Windows holding at least half of the best "detail" (pixels that are not the
## dominant background colour) are eligible; the stable entry id picks one of them.
static func crop_rect(img: Image, stable_id: String, fraction: float) -> Rect2i:
	if img.is_compressed():
		img = img.duplicate()
		img.decompress()
	var W := img.get_width()
	var H := img.get_height()
	var w := clampi(roundi(W * sqrt(fraction)), 1, W)
	var h := clampi(roundi(H * sqrt(fraction)), 1, H)
	var counts := {}
	var px := PackedInt64Array()
	px.resize(W * H)
	for y in range(H):
		for x in range(W):
			var c := img.get_pixel(x, y)
			var key: int = c.to_rgba32() if c.a > 0.0 else 0
			px[y * W + x] = key
			counts[key] = int(counts.get(key, 0)) + 1
	var dominant := 0
	var best := -1
	for k in counts:
		if int(counts[k]) > best or (int(counts[k]) == best and int(k) < dominant):
			best = counts[k]
			dominant = k
	# Summed-area table of detail pixels.
	var sat := PackedInt32Array()
	sat.resize((W + 1) * (H + 1))
	for y in range(H):
		var row := 0
		for x in range(W):
			var k: int = px[y * W + x]
			row += 1 if (k != dominant and k != 0) else 0
			sat[(y + 1) * (W + 1) + x + 1] = sat[y * (W + 1) + x + 1] + row
	var scores: Array = []
	var top := 0
	for y in range(H - h + 1):
		for x in range(W - w + 1):
			var s: int = sat[(y + h) * (W + 1) + x + w] - sat[y * (W + 1) + x + w] - sat[(y + h) * (W + 1) + x] + sat[y * (W + 1) + x]
			scores.append([x, y, s])
			top = maxi(top, s)
	var eligible: Array = scores.filter(func(e): return e[2] * 2 >= top)
	var pick: Array = eligible[stable_hash(stable_id) % eligible.size()]
	return Rect2i(pick[0], pick[1], w, h)

## FNV-1a 32-bit over UTF-8 (explicit, so the crop never depends on engine hash changes).
static func stable_hash(s: String) -> int:
	var hsh := 2166136261
	for b in s.to_utf8_buffer():
		hsh = ((hsh ^ b) * 16777619) & 0xFFFFFFFF
	return hsh

# ------------------------------------------------------------ Results model ----

## Results momentum for a WON on `completed_level`, using the SAME resolved launch the
## Continue/CLEAN NEXT route uses. {ok, reason, journey, next}.
static func results_model(app_state, completed_level: int, launch: Dictionary, cfg: Dictionary = {}) -> Dictionary:
	if cfg.is_empty():
		cfg = load_config()
	if not bool(cfg.get("ok", false)) or app_state == null or app_state.progression == null:
		return {"ok": false, "reason": String(cfg.get("reason", "no_app_state"))}
	return {"ok": true, "reason": "", "reveal_delay_s": cfg["reveal_delay_s"],
		"journey": journey(app_state.progression, "results", completed_level, cfg),
		"next": next_cleanup(launch, cfg)}
