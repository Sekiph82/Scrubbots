extends RefCounted
## MetaRewardFeel — preload (res://scripts/ui/feel/meta_reward_feel.gd).
##
## M43-C005F-PHASE3 (SB-M43-C005F-006 / -008 / -009) — the ONE presentation-only coordinator
## that maps already-committed meta outcomes onto the canonical FeedbackAdapter intents:
##
##   child  committed seam (observed, never driven)            intent         target             one-shot key
##   F006   CeremonyPresenter.ceremony_shown set_complete       REWARD         ceremony HeroArt   c005f006:<ceremony key>
##   F006   CeremonyPresenter.ceremony_shown master_complete    MAJOR_REWARD   ceremony HeroArt   c005f006:<ceremony key>
##   F008   CeremonyPresenter.ceremony_shown gift_milestone     REWARD (cycle max: MAJOR_REWARD)   c005f008:<ceremony key>
##   F008   action_committed claim_gift                         REWARD         Gift Bar hero      c005f008:gift_claim:<occurrence id>
##   F008   action_committed claim_daily_login                  REWARD         Daily reward hero  c005f008:<daily_login:<local day>>
##   F008   action_committed claim_daily_task                   SMALL          Tasks row          c005f008:<daily_task:<day>:<i>>
##   F008   action_committed claim_daily_all_tasks (ScrubBox)   MAJOR_REWARD   ScrubBox hero      c005f008:<daily_all_tasks:<day>>
##   F009   action_committed buy_heart / buy_booster_charge     SMALL          Life heart / NAH card   (none: see below)
##   F009   action_committed refill_hearts                      REWARD         Life heart              (none)
##   F009   RewardedGrantService.resolved ok (heart / booster)  REWARD         Life heart / NAH card / booster hero  c005f009:rewarded:<token>
##   F009   gameplay facade action_committed booster use        SMALL          HUD booster button      (none)
##
## Identity: claims / ceremonies / rewarded grants key on their canonical transaction identity,
## so a refresh / reopen / re-drain / resize can never replay them (FeedbackAdapter consumes a
## key in FULL and REDUCED alike). Heart / charge purchases and booster use have no transaction
## id: each is a distinct spend, and the facade emits `action_committed` exactly once per real
## commit (refusals emit nothing), so one commit = at most one confirmation.
## Targets are resolved one frame later (deferred), because the confirmation popups (Daily
## reward, ScrubBox) are pushed right after the facade returns; a missing target = no work. The
## request itself waits for the target's layout to settle (burst placement).
## FULL adds a short native Control scale settle on REWARD / MAJOR_REWARD heroes (a tween owned
## by the target node, so it dies with the popup). REDUCED: no settle; the adapter does no
## plugin work. Nothing here grants, claims, saves, navigates or decides success, and it holds
## no durable state (the diagnostic log is session memory only).

## Native settle per intent: [peak scale, total seconds]. FULL only.
const SETTLE := {"REWARD": [1.05, 0.3], "MAJOR_REWARD": [1.1, 0.45]}
const PURCHASE := {"buy_heart": "SMALL", "refill_hearts": "REWARD", "buy_booster_charge": "SMALL"}
const BOOSTER_USE := ["plus_one_slot", "random", "selector", "tornado"]

var _feel = null
var _stack = null
var _ceremonies = null
var _effects = null
var _log: Array = []   ## [child, intent, key, target name] accepted requests (evidence)

func bind(feel, stack, ceremonies, actions, rewarded, effects = null) -> void:
	_feel = feel
	_stack = stack
	_ceremonies = ceremonies
	_effects = effects
	if ceremonies != null and not ceremonies.ceremony_shown.is_connected(_on_ceremony_shown):
		ceremonies.ceremony_shown.connect(_on_ceremony_shown)
	if actions != null and not actions.action_committed.is_connected(_on_committed):
		actions.action_committed.connect(_on_committed)
	if rewarded != null and not rewarded.resolved.is_connected(_on_rewarded):
		rewarded.resolved.connect(_on_rewarded)

## The gameplay host owns its own facade (boosters need the live board): observe its commits.
func bind_gameplay(host) -> void:
	if host == null or not host.has_method("get_actions") or host.get_actions() == null:
		return
	var a = host.get_actions()
	if not a.action_committed.is_connected(_on_gameplay_committed):
		a.action_committed.connect(_on_gameplay_committed.bind(weakref(host)))

func feel_log() -> Array:
	return _log.duplicate(true)

# ------------------------------------------------------------------ seams ----

func _on_ceremony_shown(key: String, kind: String) -> void:
	var p = _ceremonies.current() if _ceremonies != null else null
	if p == null:
		return
	var hero: Node = p.find_child("HeroArt", true, false)
	match kind:
		"set_complete":
			_play("F006", "REWARD", hero, "c005f006:" + key)
		"master_complete":
			_play("F006", "MAJOR_REWARD", hero, "c005f006:" + key)
		"gift_milestone":
			var e: Dictionary = p.get_meta("event", {})
			var big := int(e.get("milestone", 0)) == int(e.get("cycle_max", -1))
			_play("F008", "MAJOR_REWARD" if big else "REWARD", hero, "c005f008:" + key)

func _on_committed(action: String, result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		return
	match action:
		"claim_gift":
			_later("F008", "REWARD", "gift_bar", "", "c005f008:gift_claim:" + String(result.get("occurrence_id", "")))
		"claim_daily_login":
			_later("F008", "REWARD", "ceremony_daily", "", "c005f008:" + String(result.get("tx", "")))
		"claim_daily_task":
			_later("F008", "SMALL", "tasks", "Task_%d" % int(result.get("task_index", -1)), "c005f008:" + String(result.get("tx", "")))
		"claim_daily_all_tasks":
			_later("F008", "MAJOR_REWARD", "ceremony_scrubbox", "", "c005f008:" + String(result.get("tx", "")))
		"buy_heart", "refill_hearts":
			_later("F009", PURCHASE[action], "life", "Heart", "")
		"buy_booster_charge":
			_later("F009", PURCHASE[action], "need_a_hand", "Card_" + String(result.get("booster", "")), "")

## Verified rewarded grants (Life / Booster / Need a Hand). The Rewarded Ads daily track (its
## grants carry a daily tx) is not an acquisition surface of this milestone.
func _on_rewarded(token: String, product: String, result: Dictionary) -> void:
	if not bool(result.get("ok", false)) or result.has("tx"):
		return
	var key := "c005f009:rewarded:" + token
	if product == "heart":
		_later("F009", "REWARD", "life", "Heart", key)
	elif product.begins_with("booster:"):
		var id := product.substr(8)
		if _find("need_a_hand") != null:
			_later("F009", "REWARD", "need_a_hand", "Card_" + id, key)
		else:
			_later("F009", "REWARD", "booster_" + id, "", key)

func _on_gameplay_committed(action: String, result: Dictionary, host_ref: WeakRef) -> void:
	var host = host_ref.get_ref()
	if not bool(result.get("ok", false)) or not BOOSTER_USE.has(action) or host == null:
		return
	var screen = host.get_screen() if host.has_method("get_screen") else null
	var b = screen.get_booster_button(action) if screen != null and screen.has_method("get_booster_button") else null
	if b != null:
		_play("F009", "SMALL", b, "")

# ----------------------------------------------------------------- dispatch ----

func _later(child: String, intent: String, popup_id: String, node_name: String, key: String) -> void:
	Callable(self, "_resolve").call_deferred(child, intent, popup_id, node_name, key)

func _resolve(child: String, intent: String, popup_id: String, node_name: String, key: String) -> void:
	var p = _find(popup_id)
	if p == null:
		return
	var t: Node = p.get_hero() if node_name.is_empty() else p.find_child(node_name, true, false)
	_play(child, intent, t, key)

## The burst is placed at the target's rect, so it is requested only once the freshly pushed
## popup's nested containers have settled (the rect stops moving; at most SETTLE_FRAMES frames),
## the same rule as the Results WIN burst.
const SETTLE_FRAMES := 8
func _play(child: String, intent: String, target: Node, key: String) -> void:
	if _feel == null or target == null or not is_instance_valid(target):
		return
	if target is Control and target.is_inside_tree():
		var tree := target.get_tree()
		var last: Rect2 = (target as Control).get_global_rect()
		for _i in range(SETTLE_FRAMES):
			await tree.process_frame
			if not is_instance_valid(target) or not target.is_inside_tree():
				return
			var r: Rect2 = (target as Control).get_global_rect()
			if r == last:
				break
			last = r
	if not _feel.play(intent, target, key):
		return   # consumed key / bad target: nothing replays
	_log.append([child, intent, key, String(target.name)])
	if SETTLE.has(intent) and target is Control and not _reduced():
		_settle(target as Control, SETTLE[intent])

## Short native scale settle 1 -> peak -> 1 (Control-safe; no plugin, no layout change).
func _settle(c: Control, spec: Array) -> void:
	if not c.is_inside_tree():
		return
	c.pivot_offset = c.size * 0.5
	var half: float = float(spec[1]) * 0.5
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * float(spec[0]), half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector2.ONE, half).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _reduced() -> bool:
	return _effects != null and _effects.is_reduced()

## The open popup with `popup_id` on the app ModalStack, or null.
func _find(popup_id: String):
	if _stack == null or not is_instance_valid(_stack):
		return null
	for c in _stack.find_children("*", "Control", true, false):
		if c.get("popup_id") == popup_id and c.has_method("is_open") and c.is_open():
			return c
	return null
