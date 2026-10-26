extends RefCounted
## CeremonyPresenter — preload (res://scripts/ui/ceremony/ceremony_presenter.gd).
##
## M43 master (SB-M43-068 onward) — the ONE app-level presenter of meta ceremonies. It shows,
## one at a time on the app ModalStack, every committed event (CeremonyEvents) the player has
## not been shown yet (MetaUiState), using the shipping MetaCeremonies builders.
##
##   drain(source) -> opens the next pending ceremony (if none is showing), else no-op.
##   The ceremony's CTA closes it -> the event is acknowledged (mark_seen + canonical save)
##   -> the next pending one opens -> ... -> `idle(source)` when nothing is left.
##
## PRESENTATION ONLY: it never grants, claims, spends or changes progression. Acknowledging
## only records "already shown" so reload / reopen never replays a ceremony; if the app dies
## mid-ceremony the event is simply shown again (still no grant). Kinds without a shipping
## builder stay pending (never dropped).
##
## SB-M43-072: a NEW FTUE profile also gets one Feature Unlock ceremony per owner-table feature
## (feature_unlocks_v1.json, level > 1) once AppState.feature_unlocked(id) is true, key
## "unlock:<id>", after the CeremonyEvents ones, ascending by table level. Only features with an
## existing promoted icon (FEATURE_ICONS) are presentable; the rest are skipped (no art invented).
## Grandfathered saves get none. A save failure on acknowledge keeps the event pending: it is
## snoozed for this session only (no re-open loop) and shown again on the next launch.

signal ceremony_shown(key: String, kind: String)
signal ceremony_acknowledged(key: String, kind: String)
signal idle(source: String)
signal ceremony_action(key: String, kind: String, action_id: String, result: Dictionary)

const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")

const FEATURE_ICONS := {
	"daily": "res://assets/ui/final/home/shortcuts/icon_shortcut_daily.png",
	"shop": "res://assets/ui/final/home/shortcuts/icon_shortcut_shop.png",
	"tasks": "res://assets/ui/final/home/shortcuts/icon_shortcut_tasks.png",
	"collection": "res://assets/ui/final/home/shortcuts/icon_shortcut_collection.png",
}

var _stack = null
var _app = null
var _current = null          ## the open ceremony popup, or null
var _source := ""
var _log: Array = []         ## [key, kind] in presentation order (evidence)
var _snoozed := {}           ## key -> true: acknowledged but the save failed (this session only)

func bind(stack, app_state) -> void:
	_stack = stack
	_app = app_state

func is_presenting() -> bool:
	return _current != null and is_instance_valid(_current) and not _current.is_closed()

func current():
	return _current if is_presenting() else null

func presented_log() -> Array:
	return _log.duplicate(true)

## Pending events this presenter can show right now (a kind with a builder), in order.
func pending() -> Array:
	if _app == null or _app.economy == null or _app.is_blocked:
		return []
	var reduced := _reduced()
	return (CeremonyEvents.pending(_app.economy, _app.economy.meta_ui) + feature_events()).filter(func(e):
		if _snoozed.has(String(e["key"])):
			return false
		var p = MetaCeremonies.build(e, reduced)
		if p == null:
			return false
		p.free()
		return true)

static func feature_key(feature_id: String) -> String:
	return "unlock:" + feature_id

## SB-M43-072: unseen feature-unlock events (read-only; presentable or not), ascending by level.
func feature_events() -> Array:
	if _app == null or _app.economy == null or _app.is_blocked or not _app.economy.ftue.is_new_profile():
		return []
	var out: Array = []
	for id in _app.unlocks.cfg["unlocks"]:
		var lvl: int = _app.feature_unlock_level(id)
		if lvl > 1 and _app.feature_unlocked(id) and not _app.economy.meta_ui.is_seen(feature_key(id)):
			var n := String(id).to_upper()
			out.append({"key": feature_key(id), "kind": "feature_unlock", "feature_id": String(id), "level": lvl,
				"name": UiText.t("FEATURE_%s_NAME" % n), "body": UiText.t("FEATURE_%s_BODY" % n), "icon": String(FEATURE_ICONS.get(id, ""))})
	out.sort_custom(func(a, b): return a["level"] < b["level"] or (a["level"] == b["level"] and a["feature_id"] < b["feature_id"]))
	return out

## Open the next pending ceremony. True when one was opened by this call.
func drain(source: String = "") -> bool:
	if is_presenting() or _stack == null:
		return false
	_source = source
	var list := pending()
	if list.is_empty():
		idle.emit(source)
		return false
	var e: Dictionary = list[0]
	var p = MetaCeremonies.build(e, _reduced())
	p.closed.connect(_on_closed.bind(String(e["key"]), String(e["kind"])), CONNECT_ONE_SHOT)
	p.action_selected.connect(_on_action.bind(String(e["key"]), String(e["kind"])), CONNECT_ONE_SHOT)
	if not _stack.push(p):
		p.free()
		return false
	_current = p
	_log.append([String(e["key"]), String(e["kind"])])
	MetaCeremonies.start_motion(p)
	ceremony_shown.emit(String(e["key"]), String(e["kind"]))
	return true

## Only the ceremony's own CTA ("action:<id>") acknowledges it. A stack clear (route change,
## host release) leaves the event pending, so it is shown again at the next drain.
func _on_closed(reason: String, key: String, kind: String) -> void:
	_current = null
	if not reason.begins_with("action:"):
		return
	if _app != null and _app.economy != null:
		var meta = _app.economy.meta_ui
		var pre: Dictionary = meta.snapshot()
		if meta.mark_seen(key) and not bool(_app.request_save().get("ok", false)):
			meta.import_snapshot(pre)
			_snoozed[key] = true
	ceremony_acknowledged.emit(key, kind)
	drain(_source)

## A player CHOICE inside a ceremony is routed to its authority facade (never decided here):
## Robot Unlock "equip" -> ProductionActionFacade.equip_robot (persisted selection, spends
## nothing). "keep" / "continue" change nothing.
func _on_action(action_id: String, ctx: Dictionary, key: String, kind: String) -> void:
	var result := {}
	if kind == "robot_unlock" and action_id == "equip" and _app != null and _app.actions != null:
		result = _app.actions.equip_robot(String(ctx.get("robot_id", "")))
	ceremony_action.emit(key, kind, action_id, result)

func _reduced() -> bool:
	return _app != null and _app.effects != null and _app.effects.is_reduced()
