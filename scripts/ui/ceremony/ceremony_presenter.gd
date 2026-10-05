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

signal ceremony_shown(key: String, kind: String)
signal ceremony_acknowledged(key: String, kind: String)
signal idle(source: String)

const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const MetaCeremonies = preload("res://scripts/ui/ceremony/meta_ceremonies.gd")

var _stack = null
var _app = null
var _current = null          ## the open ceremony popup, or null
var _source := ""
var _log: Array = []         ## [key, kind] in presentation order (evidence)

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
	return CeremonyEvents.pending(_app.economy, _app.economy.meta_ui).filter(func(e):
		var p = MetaCeremonies.build(e, reduced)
		if p == null:
			return false
		p.free()
		return true)

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
	if _app != null and _app.economy != null and _app.economy.meta_ui.mark_seen(key):
		_app.request_save()
	ceremony_acknowledged.emit(key, kind)
	drain(_source)

func _reduced() -> bool:
	return _app != null and _app.effects != null and _app.effects.is_reduced()
