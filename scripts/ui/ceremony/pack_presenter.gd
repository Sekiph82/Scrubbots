extends RefCounted
## PackPresenter — preload (res://scripts/ui/ceremony/pack_presenter.gd).
##
## M43-C005F-PHASE2-R01 — the ONE app-level presenter of EARNED card packs (the counterpart of
## CeremonyPresenter for packs). It shows, one at a time on the real app ModalStack, every pending
## earned pack of the durable PendingPackQueue in FIFO order:
##
##   drain() -> front entry -> AppState.open_earned_pack(id)  (canonical PackCommitTransaction:
##     draws exactly once and durably saves the receipt; an entry already committed - app killed
##     mid-ceremony - REPLAYS its receipt, never redraws) -> the accepted Standard / Premium
##     shipping ceremony, bound to the app's single FeedbackAdapter -> ModalStack.push.
##   presentation_completed -> AppState.acknowledge_earned_pack(id) (removed + durable save)
##     -> `pack_finished(id)`; the app root then drains again (next pack) / its meta ceremonies.
##   R02: an acknowledgement whose save FAILED (AppState restored the pre-ack state, so the entry
##     is still pending with its committed receipt) emits `pack_ack_failed(id, result)` instead,
##     never `pack_finished`, and does NOT advance. A transient, presentation-local guard then
##     keeps drain() from instantly reopening that pack (no reopen loop under a persistent save
##     failure) until release_ack_guard() - the app root calls it on the next HOME entry; a
##     restart starts unguarded. The reopened pack is the same committed receipt (replay, no draw).
##   A ceremony closed any other way (stack cleared by a route change) is NOT acknowledged: the
##     same committed receipt reopens at the next drain.
##
## PRESENTATION ONLY: it never grants, draws, rerolls or decides rarity / NEW / copies itself.

signal pack_shown(id: String, kind: String)
signal pack_finished(id: String)
signal pack_ack_failed(id: String, result: Dictionary)
signal idle

const StandardPackCeremony = preload("res://scripts/ui/ceremony/standard_pack_ceremony.gd")
const PremiumPackCeremony = preload("res://scripts/ui/ceremony/premium_pack_ceremony.gd")

var _stack = null
var _app = null
var _feel = null
var _current = null          ## the open pack ceremony, or null
var _current_id := ""
var _log: Array = []         ## [id, kind, replay] in presentation order (evidence)
var _last_error := ""
var _ack_ok := {}             ## id -> bool: durable acknowledgement result of its completion
var _ack_guard := {}          ## id -> true: ack failed this session; not reopened until released

func bind(stack, app_state, feel = null) -> void:
	_stack = stack
	_app = app_state
	_feel = feel

func is_presenting() -> bool:
	return _current != null and is_instance_valid(_current) and not _current.is_closed()

func current():
	return _current if is_presenting() else null

func current_id() -> String:
	return _current_id if is_presenting() else ""

func pending_count() -> int:
	return 0 if _app == null or _app.economy == null else _app.economy.pending_packs.size()

func presented_log() -> Array:
	return _log.duplicate(true)

func last_error() -> String:
	return _last_error

## Open the oldest pending earned pack. True when a ceremony was opened by this call.
func drain() -> bool:
	if is_presenting() or _stack == null or _app == null or _app.economy == null or _app.is_blocked:
		return false
	var e: Dictionary = _app.economy.pending_packs.front()
	if e.is_empty():
		idle.emit()
		return false
	var id := String(e["id"])
	if _ack_guard.has(id):
		_last_error = "ack_retry_guarded"   # FIFO stays blocked behind it; nothing is reopened yet
		return false
	var c: Dictionary = _app.open_earned_pack(id)
	if not bool(c.get("ok", false)):
		_last_error = String(c.get("reason", "open_failed"))   # stays pending (nothing partial survives)
		return false
	var reduced: bool = _app.effects != null and _app.effects.is_reduced()
	var made: Dictionary = PremiumPackCeremony.create_premium(c["model"], reduced) if String(e["kind"]) == "premium" \
		else StandardPackCeremony.create(c["model"], reduced)
	if not bool(made.get("ok", false)):
		_last_error = "model:" + String(made.get("reason", ""))
		return false
	var p = made["popup"]
	if _feel != null:
		p.bind_feedback(_feel)
	p.presentation_completed.connect(_on_completed.bind(id), CONNECT_ONE_SHOT)
	p.closed.connect(_on_closed.bind(id), CONNECT_ONE_SHOT)
	if not _stack.push(p):
		p.free()
		_last_error = "push_refused"
		return false
	_current = p
	_current_id = id
	_log.append([id, String(e["kind"]), bool(c.get("replay", false))])
	pack_shown.emit(id, String(e["kind"]))
	return true

## The ceremony ran to its end (all cards routed): the pack is now durably acknowledged.
func _on_completed(_presentation_id: String, id: String) -> void:
	var r: Dictionary = _app.acknowledge_earned_pack(id)
	_ack_ok[id] = bool(r.get("ok", false))
	if not _ack_ok[id]:
		_last_error = "ack:" + String(r.get("reason", ""))
		_ack_guard[id] = true
		pack_ack_failed.emit(id, r.duplicate(true))

func _on_closed(reason: String, id: String) -> void:
	_current = null
	_current_id = ""
	if reason == "complete" and bool(_ack_ok.get(id, false)):
		pack_finished.emit(id)
	_ack_ok.erase(id)

## Allow a pack whose durable acknowledgement failed to be presented again (same receipt).
func release_ack_guard() -> void:
	_ack_guard.clear()

func is_ack_guarded(id: String) -> bool:
	return _ack_guard.has(id)
