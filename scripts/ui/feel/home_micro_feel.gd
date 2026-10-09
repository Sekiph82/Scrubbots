extends RefCounted
## HomeMicroFeel — preload (res://scripts/ui/feel/home_micro_feel.gd).
##
## M43-C005F-PHASE4 (SB-M43-C005F-012) — Home state-change micro feedback without refresh spam.
## Home refreshes constantly (1 s Heart timer, modal close, route-to-Home, content refresh,
## setup calls), so a refresh is NEVER a trigger. HomeScreen hands every VISIBLE render's
## already-built view-model values here; only an actual change of this compact ephemeral
## snapshot between two visible renders may answer, with MICRO only (no particles):
##
##   delta (priority order)                  target (existing Home node)
##   frontier advanced (completed count up)  HomeJourneyStrip (PlayButton when the strip is hidden)
##   Bot Parts became unlockable (false->true) ProfileBotParts meter
##   Win Streak value up                     current Win Streak track gift
##
## Coalescing: one reconciliation answers its dominant delta, plus at most ONE more serialized
## after the first pop ends (max two). The first observed render is the baseline (zero effect);
## a new HomeScreen = a new baseline. Not tracked on purpose: Heart clock / count, Scrub Bucks,
## Gift Meter / claimable badge (F008 owns Gift milestones + claims, Results F004 owns the
## committed reward rows), badges, layout, modal state, content that leaves these values alone.
## FULL: the adapter request (MICRO = no Spark; GFF punch never drives a Control) + one native
## sine scale bump on the target. REDUCED: values update as always; the adapter does no plugin
## work and no native pulse runs. Nothing here grants, saves, navigates or reads durable state;
## the snapshot lives in memory with this object only.

const INTENT := "MICRO"
const POP := 0.06     ## native bump 1.0 -> 1.06 -> 1.0
const POP_S := 0.36
const MAX_EVENTS := 2

var _feel = null
var _last: Dictionary = {}   ## empty = no baseline yet
var _log: Array = []         ## [kind, target name] accepted (evidence, session memory only)
var _tweens: Dictionary = {} ## target instance id -> Tween (one live bump per target)

func bind(feel) -> void:
	_feel = feel

func feel_log() -> Array:
	return _log.duplicate(true)

func has_baseline() -> bool:
	return not _last.is_empty()

## The tracked slice of a Home view model ({} when the model is not usable).
static func snapshot(vm: Dictionary) -> Dictionary:
	if not bool(vm.get("ok", false)) or bool(vm.get("blocked", false)):
		return {}
	return {"completed": int(vm["completed_levels"]), "unlockable": bool(vm["robot_can_unlock"]), "streak": int(vm["win_streak"])}

## Compare one visible render against the previous one. `targets`: kind -> Control. Returns the
## kinds answered (dominant first); [] for the baseline, an unchanged render or an unusable model.
func observe(vm: Dictionary, targets: Dictionary) -> Array:
	var s := snapshot(vm)
	if s.is_empty():
		return []
	var prev := _last
	_last = s
	if prev.is_empty():
		return []   # first render: baseline only
	var kinds: Array = []
	if s["completed"] > prev["completed"]:
		kinds.append("frontier")
	if s["unlockable"] and not prev["unlockable"]:
		kinds.append("bot_parts")
	if s["streak"] > prev["streak"]:
		kinds.append("win_streak")
	kinds = kinds.slice(0, MAX_EVENTS)
	for i in range(kinds.size()):
		var t = targets.get(kinds[i])
		if i == 0:
			_answer(kinds[i], t)
		elif t is Control and t.is_inside_tree():
			t.get_tree().create_timer(POP_S).timeout.connect(_answer.bind(kinds[i], weakref(t)))
	return kinds

func _answer(kind: String, t) -> void:
	if t is WeakRef:
		t = t.get_ref()
	if _feel == null or not (t is Control) or not t.is_visible_in_tree():
		return
	if not _feel.play(INTENT, t):
		return
	_log.append([kind, String(t.name)])
	if not _feel.reduced():
		_pop(t)

func _pop(c: Control) -> void:
	var id := c.get_instance_id()
	if _tweens.has(id) and (_tweens[id] as Tween).is_valid():
		(_tweens[id] as Tween).kill()
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween()
	tw.tween_method(func(t: float): c.scale = Vector2.ONE * (1.0 + POP * sin(PI * t)), 0.0, 1.0, POP_S)
	tw.tween_callback(func():
		c.scale = Vector2.ONE
		_tweens.erase(id))   # no finished Tween is retained
	_tweens[id] = tw
