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
##   Win Streak        Win Streak badge               TrackGift<after>  streak before -> after
##   Collection cards  standard pack art              Shortcut_collection  (fly only)
##
## Each reward = icon fades in at the screen centre -> flies to its target -> the target counts
## up from the pre-win value to the live value (adapter REWARD pickup at the target). Driven by
## the shared RevealSequencer: one-shot per key (one terminal attempt), Reduced Effects lands the
## final state at once (no flight), finish() fast-forwards. The 10-level journey strip and the
## streak track get the existing HomeMicroFeel pops on the same Home entry.
## PRESENTATION ONLY: it never grants, saves or reads anything but the receipt and the Home view
## model; `completed` only tells the app root it may present the ceremonies.

signal completed(key: String)

const RevealSequencer = preload("res://scripts/ui/components/reveal_sequencer.gd")

const ICONS := {
	"scrub_bucks": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
	"bot_parts": "res://assets/ui/final/robots/bot_parts_icon.png",
	"gift_meter": "res://assets/ui/final/home/gift_meter/gift_meter_emblem.png",
	"win_streak": "res://assets/ui/final/home/reward_track/win_streak_reward_badge.png",
	"collection_cards": "res://assets/ui/final/rewards/card_pack_standard.png",
}
const ICON_PX := 132.0
const APPEAR_S := 0.12
const FLY_S := 0.5
const COUNT_S := 0.45

## A tweenable value whose setter shows itself on the Home HUD.
class Counter extends RefCounted:
	var kind := ""
	var show := Callable()
	var value := 0.0:
		set(v):
			value = v
			if show.is_valid():
				show.call(kind, v)

var _home: Control
var _seq: RevealSequencer
var _layer: Control = null
var _counters: Array = []
var _feel = null

func _init(home: Control) -> void:
	_home = home
	_seq = RevealSequencer.new(home)
	_seq.step_started.connect(_on_step)
	_seq.completed.connect(_on_completed)

func bind_feel(adapter) -> void:
	_feel = adapter

## The rewards a receipt shows, in order: [{kind, from, to, target}]. `vm` = the live Home view
## model (the HUD's final values). Pure: nothing outside the committed receipt adds an entry.
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
	var st: Dictionary = receipt.get("streak", {})
	if int(st.get("after", 0)) > int(st.get("before", 0)):
		out.append({"kind": "win_streak", "from": int(st["before"]), "to": int(st["after"]), "target": "TrackGift%d" % clampi(int(st["after"]), 1, 5)})
	if int(receipt.get("cards_delta", 0)) > 0:
		out.append({"kind": "collection_cards", "from": 0, "to": 0, "target": "Shortcut_collection"})
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
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_home.add_child(_layer)
	var half := Vector2(ICON_PX, ICON_PX) * 0.5
	var origin := _home.size * 0.5 - half
	var steps: Array = []
	for e in p:
		var target: Control = _home.get_region(String(e["target"]))
		var icon := TextureRect.new()
		icon.name = "Fly_" + String(e["kind"])
		icon.texture = load(ICONS[e["kind"]])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.size = half * 2.0
		icon.set_meta("target", String(e["target"]))
		_layer.add_child(icon)
		var dest: Vector2 = target.get_global_rect().get_center() - _home.global_position - half if target != null else origin
		var c := Counter.new()
		c.kind = String(e["kind"])
		c.show = _home.show_hud_value
		_counters.append(c)
		steps.append(RevealSequencer.fade(icon, APPEAR_S))
		steps.append({"target": icon, "property": "position", "from": origin, "to": dest, "duration": FLY_S})
		steps.append({"target": c, "property": "value", "from": float(e["from"]), "to": float(e["to"]), "duration": COUNT_S})
	return _seq.play(key, steps, reduced)

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

## A counter step starting = its icon arrived: hide it, pickup feel at the HUD target.
func _on_step(key: String, index: int) -> void:
	if index % 3 != 2 or _layer == null:
		return
	var icon: Control = _layer.get_child(floori(index / 3.0))
	icon.visible = false
	var target: Control = _home.get_region(String(icon.get_meta("target")))
	if _feel != null and target != null:
		_feel.play("REWARD", target, "%s:%s" % [key, icon.name])

func _on_completed(key: String) -> void:
	_clear()
	completed.emit(key)

func _clear() -> void:
	_counters.clear()
	if _layer != null and is_instance_valid(_layer):
		_layer.get_parent().remove_child(_layer)
		_layer.queue_free()
	_layer = null
