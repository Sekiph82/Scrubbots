extends RefCounted
## HomeRewardFlight — preload (res://scripts/ui/home/home_reward_flight.gd).
##
## SB-PHONE-2026-11-12-E (owner 2026-11-12) — after a win the app goes straight Home and the
## level's rewards fly into their Home HUD targets there. Built ONLY from the host's committed
## TerminalRewardReceipt (economy already granted + saved before the win animation started):
##
##   reward            icon (existing approved art)   HUD target        count-up
##   Scrub Bucks       SB currency icon               ScrubBucksChip    wallet before -> after
##   Bot Parts         Bot Parts icon                 ProfileBotParts   parts before -> after
##   Gift Meter        Gift Meter emblem              GiftMeterBar      cycle progress (tick overlay pulses)
##   Collection cards  standard pack art              ProfileCard       (fly only)
## SB-TF-03: Home has no win-streak strip any more, so the streak flies nowhere (its Scrub Bucks
## still land in the wallet row); Collection moved into Profile, so cards fly to the profile card.
##
## Each reward (SB-HOME-FLIGHT-LOCK-2026-11-17, owner 2026-11-17) = its icon + a "+N" label fade
## in at the screen centre -> K = min(N, 5) copies fly one after another (staggered) to the target
## -> each arrival steps the target's counter by its share of N (the last lands exactly on the live
## value) with an adapter REWARD pickup. N = SB / Bot Parts / Gift Meter counter
## increase, Collection = cards won. Driven by the shared RevealSequencer: one-shot per key (one
## terminal attempt), Reduced Effects lands the final state at once (no flight), finish()
## fast-forwards. The 10-level journey strip gets the existing HomeMicroFeel
## pops on the same Home entry.
## PRESENTATION ONLY: it never grants, saves or reads anything but the receipt and the Home view
## model; `completed` only tells the app root it may present the ceremonies.
## SB-HOME-FLIGHT-LOCK-2026-11-17: the full-rect layer swallows every Home tap until the last
## count-up ends (it is freed on completion / finish / Reduced, with Home, or by the safety timeout).

signal completed(key: String)

const RevealSequencer = preload("res://scripts/ui/components/reveal_sequencer.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const ICONS := {
	"scrub_bucks": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
	"bot_parts": "res://assets/ui/final/robots/bot_parts_icon.png",
	"gift_meter": "res://assets/ui/final/home/gift_meter/gift_meter_emblem.png",
	"collection_cards": "res://assets/ui/final/rewards/card_pack_standard.png",
}
const ICON_PX := 132.0
const APPEAR_S := 0.12
const FLY_S := 0.5
const STAGGER_S := 0.12
const MAX_COPIES := 5
const LOCK_MARGIN_S := 1.0

## A tweenable value whose setter shows itself on the Home HUD.
class Counter extends RefCounted:
	var kind := ""
	var show := Callable()
	var value := 0.0:
		set(v):
			value = v
			if show.is_valid():
				show.call(kind, v)

## One reward kind's K flying copies, driven by one tweened `t` 0 -> 1. Copy i leaves STAGGER_S
## after copy i-1 and flies FLY_S; each arrival hides it and steps the counter by its share of N.
class Burst extends RefCounted:
	var flight = null
	var target: Control = null
	var hero: Control = null
	var copies: Array = []
	var counter = null   # null = nothing counts (Collection)
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
		return FLY_S + (copies.size() - 1) * STAGGER_S

	func _update() -> void:
		var d := duration()
		hero.get_node("Icon").visible = t <= 0.0
		hero.get_node("Amount").visible = t <= 0.0
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

var _home: Control
var _seq: RevealSequencer
var _layer: Control = null
var _counters: Array = []
var _feel = null
var _bursts: Array = []
var _key := ""

func _init(home: Control) -> void:
	_home = home
	_seq = RevealSequencer.new(home)
	_seq.completed.connect(_on_completed)

func bind_feel(adapter) -> void:
	_feel = adapter

## The rewards a receipt shows, in order: [{kind, from, to, n, target}]. `vm` = the live Home view
## model (the HUD's final values); n = the "+N" amount (to - from where a counter climbs). Pure:
## nothing outside the committed receipt adds an entry.
static func plan(receipt: Dictionary, vm: Dictionary) -> Array:
	var out: Array = []
	if String(receipt.get("status", "")) != "WON" or not bool(vm.get("ok", false)):
		return out
	var wd: Dictionary = receipt.get("wallet_delta", {})
	if int(wd.get("scrub_bucks", 0)) > 0:
		out.append({"kind": "scrub_bucks", "from": int(vm["scrub_bucks"]) - int(wd["scrub_bucks"]), "to": int(vm["scrub_bucks"]), "target": "ScrubBucksChip"})
	if int(wd.get("bot_parts", 0)) > 0:
		out.append({"kind": "bot_parts", "from": maxi(int(vm["bot_parts"]) - int(wd["bot_parts"]), 0), "to": int(vm["bot_parts"]), "target": "ProfileBotParts"})
	for e in receipt.get("reveal_queue", []):
		if String(e.get("kind", "")) == "gift_meter":
			var g: Dictionary = receipt.get("gift_meter", {})
			var wrapped: bool = int(g.get("cycles_after", 0)) > int(g.get("cycles_before", 0))
			out.append({"kind": "gift_meter", "from": 0 if wrapped else int(e["from"]), "to": int(e["to"]), "target": "GiftMeterBar"})
	if int(receipt.get("cards_delta", 0)) > 0:
		out.append({"kind": "collection_cards", "from": 0, "to": 0, "n": int(receipt["cards_delta"]), "target": "ProfileCard"})
	for e in out:
		if not e.has("n"):
			e["n"] = int(e["to"]) - int(e["from"])
	return out

## Start the flight for one committed win. False when the key already played or nothing to show.
func play(receipt: Dictionary, key: String, reduced: bool) -> bool:
	if _seq.has_played(key):
		return false
	var p := plan(receipt, _home.get_view_model())
	if p.is_empty():
		return false
	_clear()
	_layer = Control.new()
	_layer.name = "RewardFlightLayer"
	_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_home.add_child(_layer)
	_key = key
	var half := Vector2(ICON_PX, ICON_PX) * 0.5
	var origin := _home.size * 0.5 - half
	var steps: Array = []
	for e in p:
		var target: Control = _home.get_region(String(e["target"]))
		var hero := Control.new()
		hero.name = "Fly_" + String(e["kind"])
		hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero.set_meta("target", String(e["target"]))
		_layer.add_child(hero)
		var tex: Texture2D = load(ICONS[e["kind"]])
		var icon := _icon(tex, half)
		icon.name = "Icon"
		icon.position = origin
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
		var bu := Burst.new()
		bu.flight = self
		bu.target = target
		bu.hero = hero
		bu.from = int(e["from"])
		bu.n = int(e["n"])
		bu.origin = origin
		bu.dest = target.get_global_rect().get_center() - _home.global_position - half if target != null else origin
		for i in clampi(bu.n, 1, MAX_COPIES):
			var c := _icon(tex, half)
			c.name = "Copy%d" % i
			c.visible = false
			hero.add_child(c)
			bu.copies.append(c)
		if int(e["to"]) != int(e["from"]):
			var c := Counter.new()
			c.kind = String(e["kind"])
			c.show = _home.show_hud_value
			c.value = float(e["from"])
			_counters.append(c)
			bu.counter = c
		_bursts.append(bu)
		steps.append(RevealSequencer.fade(hero, APPEAR_S))
		steps.append({"target": bu, "property": "t", "from": 0.0, "to": 1.0, "duration": bu.duration()})
	var ok := _seq.play(key, steps, reduced)
	if _seq.is_active() and _home.is_inside_tree():
		var total := LOCK_MARGIN_S
		for st in steps:
			total += float(st["duration"])
		_home.get_tree().create_timer(total).timeout.connect(func():
			if is_instance_valid(_home) and _seq.current_key() == key:
				finish())
	return ok

## Re-show the counters' current values (the Home refresh just wrote the live ones).
func reapply() -> void:
	for c in _counters:
		c.show.call(c.kind, c.value)

func finish() -> void:
	_seq.finish()

func is_running() -> bool:
	return _seq.is_active()

func has_played(key: String) -> bool:
	return _seq.has_played(key)

func get_layer() -> Control:
	return _layer

func get_bursts() -> Array:
	return _bursts

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
	if _feel != null and b.target != null and _seq.is_running():
		_feel.play("REWARD", b.target, "%s:%s:%d" % [_key, b.hero.name, i])

func _on_completed(key: String) -> void:
	_clear()
	completed.emit(key)

func _clear() -> void:
	_counters.clear()
	_bursts = []
	if _layer != null and is_instance_valid(_layer):
		_layer.get_parent().remove_child(_layer)
		_layer.queue_free()
	_layer = null
