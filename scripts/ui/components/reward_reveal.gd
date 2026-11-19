extends RefCounted
## RewardReveal — preload (res://scripts/ui/components/reward_reveal.gd).
##
## SB-TF-05 (owner 2026-11-18: "Bütün ödül uçuşları. ekranda bekleme suresi 1.5 saniye olsun.")
## The ONE reward reveal every reward source uses (level win, Tasks / ScrubBox, Daily, Gift
## Meter, Events, Rewarded Ads, Shop, collection set / master). One call =
##   appear  every entry's icon + "+N" fades in TOGETHER (APPEAR_S)
##   hold    exactly HOLD_S with everything shown (a card pack grows here)
##   fly     K = min(N, 5) staggered copies per entry fly FLY_S to the entry's HUD target; each
##           arrival steps the target's counter by its share of N (the last lands exactly on `to`)
## and a full-rect MOUSE_FILTER_STOP layer on its own CanvasLayer (above the ModalStack) swallows
## every tap from the first frame to the last arrival (the app root also ignores Back while
## is_running()). A pack entry never flies: at the end it hands over to the app's earned-pack flow.
## Entry = {kind, n, from, to, target} (target = a Home region name; "" or unknown = no flight,
## the counter still lands). Reduced Effects: same appear + hold, then the final values at once
## (no copies, no growth). One-shot per key; a request while one runs is queued behind it.
## Win x2 (opts.double = {request: Callable(done), abandon: Callable()}): a native button shows
## during the hold; a tap pauses the clock while the ad plays (AD_TIMEOUT_S bound), done(true)
## doubles the Scrub Bucks entry, done(false) starts the flight at once.
## The clock is advance(dt): the layer's _process drives it unless `manual_clock` (tests).
## PRESENTATION ONLY: it never grants, stores or reads economy state; the caller passes committed
## results and the Home view model.

signal completed(key: String)

const UiText = preload("res://scripts/ui/ui_text.gd")
const HomeRewardFlight = preload("res://scripts/ui/home/home_reward_flight.gd")
const HomeStyle = preload("res://scripts/ui/home/home_style.gd")

const ICONS := {
	"hearts": "res://assets/ui/final/common/currencies/icon_currency_heart.png",
	"mystery_booster": "res://assets/ui/final/rewards/gift_box.png",
	"booster_choice": "res://assets/ui/final/rewards/booster_of_choice.png",
	"booster_plus_one_slot": "res://assets/ui/final/boosters/extra_slot.png",
	"booster_random": "res://assets/ui/final/boosters/random.png",
	"booster_selector": "res://assets/ui/final/boosters/selector.png",
	"booster_tornado": "res://assets/ui/final/boosters/tornado.png",
	"standard_card_packs": "res://assets/ui/final/rewards/card_pack_standard.png",
	"premium_card_packs": "res://assets/ui/final/rewards/card_pack_premium.png",
}
const ICON_PX := 132.0
const ROW_GAP := 16.0
const APPEAR_S := 0.12
const HOLD_S := 1.5
const FLY_S := 0.5
const STAGGER_S := 0.12
const MAX_COPIES := 5
const PACK_GROW := 1.35
## Backdrop dim behind the shown rewards (fades out as they fly to the HUD).
const DIM_ALPHA := 0.45
## Upper bound on one rewarded video while the hold is paused (then: no grant, fly at once).
const AD_TIMEOUT_S := 30.0
## Above ModalStack.LAYER (64): the reveal covers the popup that claimed the reward.
const LAYER := 70

## A tweenable value whose setter shows itself on the Home HUD.
class Counter extends RefCounted:
	var kind := ""
	var show := Callable()
	var value := 0.0:
		set(v):
			value = v
			if show.is_valid():
				show.call(kind, v)

## One entry's K flying copies, driven by `t` 0 -> 1. Copy i leaves STAGGER_S after copy i-1 and
## flies FLY_S; each arrival hides it and steps the counter by its share of N. No copies (no
## target / Reduced): t > 0 lands the final value at once.
class Burst extends RefCounted:
	var flight = null
	var kind := ""
	var target: Control = null
	var hero: Control = null
	var copies: Array = []
	var counter = null   # null = nothing counts (cards, hearts, boosters)
	var from := 0
	var n := 0
	var origin := Vector2.ZERO
	var dest := Vector2.ZERO
	var arrived := 0
	## Counter value after each arrival (presentation trace).
	var landed: Array = []
	var t := 0.0:
		set(v):
			t = v
			_update()

	func duration() -> float:
		return FLY_S + maxi(copies.size() - 1, 0) * STAGGER_S

	func _update() -> void:
		hero.get_node("Icon").visible = t <= 0.0
		hero.get_node("Amount").visible = t <= 0.0
		if copies.is_empty():
			if t > 0.0 and arrived == 0:
				arrived = 1
				landed.append(from + n)
				if counter != null:
					counter.value = float(from + n)
			return
		var d := duration()
		for i in copies.size():
			var c: Control = copies[i]
			var k := clampf((t * d - i * STAGGER_S) / FLY_S, 0.0, 1.0)
			c.position = origin.lerp(dest, k)
			c.visible = k > 0.0 and k < 0.9999
			if k >= 0.9999 and i >= arrived:
				arrived = i + 1
				var v := from + n * arrived / copies.size()
				landed.append(v)
				if counter != null:
					counter.value = float(v)
				flight.arrive(self, i)

## The full-rect input blocker; its _process is the reveal's production clock.
class Layer extends Control:
	var tick := Callable()
	func _process(dt: float) -> void:
		if tick.is_valid():
			tick.call(dt)

## Tests drive the clock with advance(dt) only.
var manual_clock := false

var _home: Control
var _feel = null
var _played: Dictionary = {}
var _queue: Array = []
var _active := false
var _finishing := false
var _key := ""
var _t := 0.0
var _fly_at := 0.0
var _end := 0.0
var _reduced := false
var _canvas: CanvasLayer = null
var _layer: Control = null
var _dim: ColorRect = null
var _bursts: Array = []
var _packs: Array = []
var _counters: Array = []
var _double: Dictionary = {}
var _x2: Button = null
var _x2_used := false
var _ad_pending := false
var _ad_wait := 0.0

func _init(home: Control) -> void:
	_home = home

func bind_feel(adapter) -> void:
	_feel = adapter

## Reveal entry list for a committed reward dictionary ({resource: amount}, as granted). `vm` =
## the live Home view model (the HUD's final values). Unknown / invisible resources show nothing.
static func entries_for(rewards: Dictionary, vm: Dictionary) -> Array:
	var out: Array = []
	var keys: Array = rewards.keys()
	keys.sort()
	for res in keys:
		var n := int(rewards[res])
		if n <= 0:
			continue
		var e := {"kind": "", "n": n, "from": 0, "to": 0, "target": "ProfileCard"}
		match String(res):
			"scrub_bucks":
				e["kind"] = "scrub_bucks"
				e["target"] = "ScrubBucksChip"
				if bool(vm.get("ok", false)):
					e["to"] = int(vm["scrub_bucks"])
					e["from"] = int(e["to"]) - n
			"bot_parts":
				e["kind"] = "bot_parts"
				e["target"] = "ProfileBotParts"
				if bool(vm.get("ok", false)):
					e["to"] = int(vm["bot_parts"])
					e["from"] = maxi(int(e["to"]) - n, 0)
			"hearts", "rewarded_heart":
				e["kind"] = "hearts"
				e["target"] = "HeartsChip"
			"standard_card_packs", "premium_card_packs":
				e["kind"] = String(res)
				e["target"] = ""
			"random_any_booster_charges", "random_booster_charges":
				e["kind"] = "mystery_booster"
			"selected_booster_charges":
				e["kind"] = "booster_choice"
			"guaranteed_new_cards", "featured_card":
				e["kind"] = "collection_cards"
			_:
				if String(res).begins_with("booster_charge_") and ICONS.has("booster_" + String(res).substr(15)):
					e["kind"] = "booster_" + String(res).substr(15)
				else:
					continue
		out.append(e)
	return out

static func icon_path(kind: String) -> String:
	return String(ICONS.get(kind, HomeRewardFlight.ICONS.get(kind, "")))

static func is_pack(kind: String) -> bool:
	return kind.ends_with("_card_packs")

## Show `entries` once for `key` (opts: reduced: bool, double: {request, abandon}). False = empty
## key, already played / queued, or nothing to show (then nothing locks).
func show_rewards(entries: Array, key: String, opts: Dictionary = {}) -> bool:
	if key.is_empty() or _played.has(key):
		return false
	var list := entries.filter(func(e): return int(e.get("n", 0)) > 0 and not icon_path(String(e.get("kind", ""))).is_empty())
	if list.is_empty():
		return false
	_played[key] = true
	if _active:
		_queue.append([list, key, opts])
	else:
		_start(list, key, opts)
	return true

func _start(entries: Array, key: String, opts: Dictionary) -> void:
	_clear()
	_active = true
	_finishing = false
	_key = key
	_t = 0.0
	_reduced = bool(opts.get("reduced", false))
	_double = opts.get("double", {})
	_x2_used = false
	_ad_pending = false
	_ad_wait = 0.0
	_canvas = CanvasLayer.new()
	_canvas.name = "RewardRevealCanvas"
	_canvas.layer = LAYER
	_home.add_child(_canvas)
	_layer = Layer.new()
	_layer.name = "RewardFlightLayer"
	_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.tick = _tick
	_layer.theme = _home.theme
	_canvas.add_child(_layer)
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0, 0, 0, DIM_ALPHA)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_dim)
	var half := Vector2(ICON_PX, ICON_PX) * 0.5
	var rows := entries.size() + (0 if _double.is_empty() else 1)
	var top := _home.size.y * 0.5 - (rows * ICON_PX + (rows - 1) * ROW_GAP) * 0.5
	var longest := 0.0
	for i in entries.size():
		var e: Dictionary = entries[i]
		var kind := String(e["kind"])
		var origin := Vector2(_home.size.x * 0.5 - ICON_PX, top + i * (ICON_PX + ROW_GAP))
		var tex: Texture2D = load(icon_path(kind))
		var hero := Control.new()
		hero.name = "Fly_" + kind
		hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero.set_meta("target", String(e.get("target", "")))
		_layer.add_child(hero)
		var icon := _icon(tex, half)
		icon.name = "Icon"
		icon.position = origin
		icon.pivot_offset = half
		hero.add_child(icon)
		var amount := Label.new()
		amount.name = "Amount"
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		amount.text = "+" + UiText.num(int(e["n"]))
		amount.add_theme_font_size_override("font_size", 56)
		amount.add_theme_color_override("font_color", Color(1, 1, 1))
		amount.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.2))
		amount.add_theme_constant_override("outline_size", 12)
		amount.position = origin + Vector2(ICON_PX + 8.0, ICON_PX * 0.5 - 40.0)
		hero.add_child(amount)
		if is_pack(kind):
			_packs.append(hero)
			continue
		var target: Control = _home.get_region(String(e.get("target", ""))) if not String(e.get("target", "")).is_empty() else null
		var bu := Burst.new()
		bu.flight = self
		bu.kind = kind
		bu.target = target
		bu.hero = hero
		bu.from = int(e.get("from", 0))
		bu.n = int(e["n"])
		bu.origin = origin
		bu.dest = target.get_global_rect().get_center() - half if target != null else origin
		if target != null and not _reduced:
			for k in clampi(bu.n, 1, MAX_COPIES):
				var c := _icon(tex, half)
				c.name = "Copy%d" % k
				c.visible = false
				hero.add_child(c)
				bu.copies.append(c)
		if int(e.get("to", 0)) != int(e.get("from", 0)):
			var c := Counter.new()
			c.kind = kind
			c.show = _home.show_hud_value
			c.value = float(e["from"])
			_counters.append(c)
			bu.counter = c
		_bursts.append(bu)
		longest = maxf(longest, bu.duration() if not bu.copies.is_empty() else 0.0)
	if not _double.is_empty():
		_x2 = Button.new()
		_x2.name = "WinDoubleButton"
		_x2.text = UiText.t("REVEAL_WATCH_X2")
		HomeStyle.style_play_button(_x2)
		_x2.add_theme_font_size_override("font_size", 40)
		_x2.custom_minimum_size = Vector2(420, ICON_PX * 0.8)
		_x2.position = Vector2(_home.size.x * 0.5 - 210.0, top + entries.size() * (ICON_PX + ROW_GAP))
		_x2.pressed.connect(_on_double)
		_layer.add_child(_x2)
	_fly_at = APPEAR_S + HOLD_S
	_end = _fly_at + longest
	_apply()
	if not _home.is_visible_in_tree():
		finish()   # nothing to watch (Home hidden / outside the tree): land at once

## Advance the reveal clock by `dt` seconds. While the x2 ad plays the clock stands still.
func advance(dt: float) -> void:
	if not _active:
		return
	if _ad_pending:
		_ad_wait += dt
		if _ad_wait >= AD_TIMEOUT_S:
			var ab: Callable = _double.get("abandon", Callable())
			if ab.is_valid():
				ab.call()
			_on_double_result(false)
		return
	_t += dt
	_apply()
	if _t >= _end:
		_complete()

func _tick(dt: float) -> void:
	if not manual_clock:
		advance(dt)

func _apply() -> void:
	var a := 1.0 if _reduced else clampf(_t / APPEAR_S, 0.0, 1.0)
	var hold := clampf((_t - APPEAR_S) / HOLD_S, 0.0, 1.0)
	_dim.modulate.a = a * (1.0 - clampf((_t - _fly_at) / FLY_S, 0.0, 1.0))
	for b in _bursts:
		b.hero.modulate.a = a
		if _t >= _fly_at:
			b.t = clampf((_t - _fly_at) / b.duration(), 0.0, 1.0) if not b.copies.is_empty() else 1.0
	for p in _packs:
		p.modulate.a = a
		p.get_node("Icon").scale = Vector2.ONE * (1.0 if _reduced else lerpf(1.0, PACK_GROW, hold))
		p.visible = _t < _fly_at
	if _x2 != null:
		_x2.visible = not _x2_used and _t < _fly_at
		_x2.modulate.a = a

func _on_double() -> void:
	if _x2_used or _ad_pending or _t >= _fly_at or _double.is_empty():
		return
	_x2_used = true
	_x2.queue_free()
	_x2 = null
	_ad_pending = true
	_ad_wait = 0.0
	(_double["request"] as Callable).call(_on_double_result)

## The x2 ad's outcome (once): granted = the Scrub Bucks entry shows and counts double, the rest
## of the hold continues; anything else = the flight starts now with the normal amount.
func _on_double_result(granted: bool) -> void:
	if not _ad_pending:
		return
	_ad_pending = false
	if granted:
		for b in _bursts:
			if b.kind == "scrub_bucks":
				b.n *= 2
				(b.hero.get_node("Amount") as Label).text = "+" + UiText.num(b.n)
	else:
		_t = maxf(_t, _fly_at)
	_apply()

## Fast-forward to the exact final state and free the lock (no-op when nothing runs).
func finish() -> void:
	if not _active:
		return
	_finishing = true
	_ad_pending = false
	_t = maxf(_t, _end)
	for b in _bursts:
		b.t = 1.0
	_complete()

func _complete() -> void:
	var k := _key
	_clear()
	_active = false
	completed.emit(k)
	if not _active and not _queue.is_empty():
		var q: Array = _queue.pop_front()
		_start(q[0], q[1], q[2])

## Re-show the counters' current values (a Home refresh just wrote the live ones).
func reapply() -> void:
	for c in _counters:
		c.show.call(c.kind, c.value)

func is_running() -> bool:
	return _active

func has_played(key: String) -> bool:
	return _played.has(key)

func current_key() -> String:
	return _key if _active else ""

## Seconds on the reveal clock (ad time excluded) and the flight start (APPEAR_S + HOLD_S).
func elapsed() -> float:
	return _t

func fly_at() -> float:
	return _fly_at

func is_ad_pending() -> bool:
	return _ad_pending

func get_layer() -> Control:
	return _layer

func get_bursts() -> Array:
	return _bursts

func get_pack_heroes() -> Array:
	return _packs

func get_double_button() -> Button:
	return _x2 if _x2 != null and is_instance_valid(_x2) else null

func _icon(tex: Texture2D, half: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size = half * 2.0
	return icon

## One copy arrived: pickup feel at the HUD target (live run only; finish / Reduced land quietly).
func arrive(b: Burst, i: int) -> void:
	if _feel != null and b.target != null and not _finishing:
		_feel.play("REWARD", b.target, "%s:%s:%d" % [_key, b.hero.name, i])

func _clear() -> void:
	_counters.clear()
	_bursts = []
	_packs = []
	_x2 = null
	if _canvas != null and is_instance_valid(_canvas):
		_canvas.get_parent().remove_child(_canvas)
		_canvas.queue_free()
	_canvas = null
	_layer = null
	_dim = null
