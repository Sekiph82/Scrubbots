extends Node
## MetaFeedback — preload (res://scripts/ui/feel/meta_feedback.gd).
##
## M43-C014 (SB-M43-161..164, 167; master remediation V03) — the ONE compact meta-UI sound /
## haptic coordinator. A pure observer; it never grants, saves, navigates or reorders anything.
##
## Family (SB-M43-161) — two existing owner-approved M33 files, no per-screen sound zoo:
##   moment        trigger (shipping seam)                                 sound                 haptic
##   confirm       a popup action button accepted (BasePopup.action_selected) tick  (dispatch, hi)   -
##   back          popup dismissed by Back / Escape / X (closed "back")     tick  (dispatch, low)  -
##   popup_open    a NEW popup becomes top on the app ModalStack           tick  (dispatch, up)   -
##   popup_close   popup closed programmatically ("close" / "complete")   tick  (dispatch, down) -
##   success       committed purchase / equip (facade action_committed)   - (the tap already ticked) success
##   reward        committed claim / reward ceremony                       chime (completion)     success
##   pack_reveal   first committed card emerging in a Standard/Premium pack chime (completion, up) -
##   pack_rare     first Rare-or-better committed card emerging           - (rides the reveal)   pack_rare
##   unlock        committed robot unlock / set / Master / robot ceremony  chime (completion, low) unlock
##   error         facade refusal or failed pending purchase / ad          tick  (dispatch, very low) warning
## Failure never uses the success chime and nothing sounds like success before the authority
## committed (SB-M43-164): success / reward / unlock come ONLY from `action_committed` or a shown
## ceremony; idempotent no-ops (already claimed, duplicate, replay, in flight) stay silent.
## Ceremony kinds are the canonical CeremonyEvents kinds: robot_unlock / master_complete /
## set_complete -> unlock; gift_milestone (and any other) -> reward.
## Pack hook: the ceremony's own RevealSequencer step_started is read; the emerging CardView's
## committed model row gives the rarity. Read-only: no reroll / reorder / economy access, and
## each presentation_id fires reveal / Rare+ at most once (refresh / reopen safe).
##
## Haptics (SB-M43-162): success 25 ms · warning 40 ms · pack_rare 60 ms · unlock 80 ms, skipped
## when Haptics is OFF or Reduced Effects is ON, both read live at every request.
## Fatigue (SB-M43-167): ONE voice (a lower-priority moment never cuts a higher one inside its
## hold window and same-frame moments never double-fire); a per-moment minimum gap (short for
## UI ticks, so a genuinely different later action is heard); at most one buzz per HAPTIC_GAP_MS;
## a route change (stack cleared) stops the voice; ticks are hard-bounded (no tail).
## UI ticks play only on the HOME route (`ui_gate`): gameplay keeps its own M33 / M34 feedback.

const SFX_BUS := "SFX"
const REWARD_STREAM := "res://assets/audio/sfx/completion.wav"
const TICK_STREAM := "res://assets/audio/sfx/dispatch.wav"
const SUCCESS_MS := 25
const WARNING_MS := 40
const PACK_RARE_MS := 60
const UNLOCK_MS := 80
const HAPTIC_GAP_MS := 250
const TICK_MAX_S := 0.12
const RARE_OR_BETTER := ["RARE", "EPIC", "LEGENDARY"]
const UNLOCK_KINDS := ["robot_unlock", "master_complete", "set_complete"]
## Popup closes that are route changes / host teardown: silent, and the voice is stopped.
const ROUTE_CLOSE := ["clear", "deep_link", "host_released", "restart", "home"]
## Refusals that are idempotent no-ops, not player-facing errors.
const SILENT_REFUSALS := ["already_claimed", "already_claimed_or_rollback", "duplicate", "duplicate_token",
	"replay", "in_flight", "pending", "not_pending"]

## moment -> {stream ("" = none), pitch, db, prio, hold_ms (voice ownership), gap_ms, haptic, ui}
const SPEC := {
	"confirm": {"stream": "tick", "pitch": 1.25, "db": -14.0, "prio": 1, "hold": 120, "gap": 90, "haptic": 0, "ui": true},
	"back": {"stream": "tick", "pitch": 0.95, "db": -15.0, "prio": 1, "hold": 120, "gap": 90, "haptic": 0, "ui": true},
	"popup_open": {"stream": "tick", "pitch": 1.12, "db": -16.0, "prio": 1, "hold": 120, "gap": 90, "haptic": 0, "ui": true},
	"popup_close": {"stream": "tick", "pitch": 0.88, "db": -17.0, "prio": 1, "hold": 120, "gap": 90, "haptic": 0, "ui": true},
	"error": {"stream": "tick", "pitch": 0.62, "db": -12.0, "prio": 2, "hold": 300, "gap": 400, "haptic": WARNING_MS, "ui": false},
	"success": {"stream": "", "pitch": 1.0, "db": 0.0, "prio": 3, "hold": 0, "gap": 600, "haptic": SUCCESS_MS, "ui": false},
	"reward": {"stream": "chime", "pitch": 1.0, "db": -8.0, "prio": 4, "hold": 900, "gap": 600, "haptic": SUCCESS_MS, "ui": false},
	"pack_reveal": {"stream": "chime", "pitch": 1.12, "db": -9.0, "prio": 4, "hold": 900, "gap": 600, "haptic": 0, "ui": false},
	"pack_rare": {"stream": "", "pitch": 1.0, "db": 0.0, "prio": 5, "hold": 0, "gap": 600, "haptic": PACK_RARE_MS, "ui": false},
	"unlock": {"stream": "chime", "pitch": 0.94, "db": -6.0, "prio": 6, "hold": 900, "gap": 600, "haptic": UNLOCK_MS, "ui": false},
}

## facade action -> committed moment. Every reward-granting / unlocking commit is listed.
const MOMENTS := {
	"claim_daily_login": "reward", "claim_daily_task": "reward", "claim_daily_all_tasks": "reward",
	"claim_gift": "reward", "claim_collection_rewards": "reward", "exchange_card": "reward",
	"exchange_all_extras": "reward", "claim_event_milestone": "reward", "claim_first_try": "reward",
	"claim_catchup": "reward", "claim_rewarded_daily": "reward", "unlock_robot": "unlock", "buy_booster_charge": "success", "buy_heart": "success",
	"refill_hearts": "success", "buy_current_level_2x": "success", "buy_timed_2x": "success",
	"equip_robot": "success",
}

var _app = null
var _stack = null
var _player: AudioStreamPlayer
var _streams := {}
var _last_ms := {}
var _voice_prio := 0
var _voice_until := 0
var _voice_frame := -1
var _tick_stop_at := 0
var _last_haptic_ms := -100000
var _known_popups := {}           ## instance id -> true (popups already announced as opened)
var _ui_queue: Array = []        ## UI ticks requested this frame (flushed deferred)
var _pack_fired := {}             ## "<presentation_id>:reveal" / ":rare" -> true
var played: Array = []            ## [[moment, sound, haptic_ms]] diagnostics for tests
var platform_vibrate: Callable = func(ms): Input.vibrate_handheld(ms)
var ui_gate: Callable = Callable()   ## () -> bool; UI ticks only while true (unset = always)
var clock_ms: Callable = func(): return Time.get_ticks_msec()

func bind(app) -> void:
	_app = app
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "MetaFeedbackVoice"
		_player.bus = SFX_BUS if AudioServer.get_bus_index(SFX_BUS) != -1 else "Master"
		_streams = {"chime": load(REWARD_STREAM), "tick": load(TICK_STREAM)}
		add_child(_player)
	set_process(false)
	if app != null and app.actions != null:
		if not app.actions.action_committed.is_connected(_on_committed):
			app.actions.action_committed.connect(_on_committed)
		if app.actions.has_signal("action_refused") and not app.actions.action_refused.is_connected(_on_refused):
			app.actions.action_refused.connect(_on_refused)

## Observe the app ModalStack: popup open / close / back / confirm / pending failures, packs.
func bind_stack(stack) -> void:
	_stack = stack
	if stack != null and not stack.top_changed.is_connected(_on_top_changed):
		stack.top_changed.connect(_on_top_changed)

func _on_committed(action: String, result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		return
	var m := String(MOMENTS.get(action, ""))
	if not m.is_empty():
		moment(m)

func _on_refused(_action: String, result: Dictionary) -> void:
	if bool(result.get("ok", false)) or SILENT_REFUSALS.has(String(result.get("reason", ""))):
		return
	moment("error")

## A ceremony actually on screen (CeremonyPresenter.ceremony_shown, canonical kinds).
func on_ceremony_shown(_key: String, kind: String) -> void:
	moment(moment_for_ceremony(kind))

static func moment_for_ceremony(kind: String) -> String:
	return "unlock" if UNLOCK_KINDS.has(kind) else "reward"

func _on_top_changed(popup) -> void:
	if popup == null or not is_instance_valid(popup) or _known_popups.has(popup.get_instance_id()):
		return
	var id: int = popup.get_instance_id()
	_known_popups[id] = true
	popup.closed.connect(_on_popup_closed.bind(id), CONNECT_ONE_SHOT)
	popup.action_selected.connect(func(_a, _c): moment("confirm"))
	popup.pending_resolved.connect(func(_a, r):
		if not bool(r.get("ok", false)) and not SILENT_REFUSALS.has(String(r.get("reason", ""))):
			moment("error"))
	if popup.has_method("get_sequencer") and popup.has_method("get_card_views") and popup.has_method("get_model"):
		var seq = popup.get_sequencer()
		seq.step_started.connect(_on_pack_step.bind(weakref(popup)))
	moment("popup_open")

func _on_popup_closed(reason: String, id: int) -> void:
	_known_popups.erase(id)
	if ROUTE_CLOSE.has(reason):
		stop_voice()
	elif reason == "back":
		moment("back")
	elif not reason.begins_with("action:"):
		moment("popup_close")

## Pack ceremony step: the first emerging committed card -> pack_reveal; the first Rare-or-better
## committed card -> pack_rare. Reads the ceremony's committed model; never writes anything.
func _on_pack_step(_key: String, index: int, ref: WeakRef) -> void:
	var popup = ref.get_ref()
	if popup == null or popup.is_closed():
		return
	var steps: Array = popup.get_sequencer().get_steps()
	if index < 0 or index >= steps.size() or String(steps[index].get("property", "")) != "emerge":
		return
	var card_i: int = popup.get_card_views().find(steps[index].get("target"))
	var model: Dictionary = popup.get_model()
	var cards: Array = model.get("cards", [])
	if card_i < 0 or card_i >= cards.size():
		return
	var pid := String(model.get("presentation_id", ""))
	if not _pack_fired.has(pid + ":reveal"):
		_pack_fired[pid + ":reveal"] = true
		moment("pack_reveal")
	if RARE_OR_BETTER.has(String(cards[card_i].get("rarity", ""))) and not _pack_fired.has(pid + ":rare"):
		_pack_fired[pid + ":rare"] = true
		moment("pack_rare")

## Request a moment. UI ticks are deferred to the end of the frame and dropped when a stronger
## moment (a committed reward / unlock / error) already owns that frame, so a claim tap or a
## ceremony popup never double-fires a tick under its chime.
func moment(m: String) -> void:
	if not SPEC.has(m):
		return
	if bool(SPEC[m]["ui"]):
		if ui_gate.is_valid() and not bool(ui_gate.call()):
			return
		if _ui_queue.is_empty():
			call_deferred("_flush_ui", Engine.get_process_frames())
		if not _ui_queue.has(m):
			_ui_queue.append(m)
		return
	_play(m)

func _flush_ui(frame: int) -> void:
	var q := _ui_queue
	_ui_queue = []
	for m in q:
		if _voice_frame == frame and _voice_prio > 1:
			return
		_play(m)

func _play(m: String) -> void:
	var s: Dictionary = SPEC[m]
	var now: int = int(clock_ms.call())
	if now - int(_last_ms.get(m, -100000)) < int(s["gap"]):
		return
	_last_ms[m] = now
	var sound := false
	if String(s["stream"]) != "" and _player != null and _audio_on() and _voice_free(int(s["prio"]), now):
		_player.stop()
		_player.stream = _streams[String(s["stream"])]
		_player.pitch_scale = float(s["pitch"])
		_player.volume_db = float(s["db"])
		_player.play()
		_voice_prio = int(s["prio"])
		_voice_until = now + int(s["hold"])
		_voice_frame = Engine.get_process_frames()
		_tick_stop_at = now + int(TICK_MAX_S * 1000.0) if String(s["stream"]) == "tick" else 0
		set_process(_tick_stop_at > 0)
		sound = true
	var ms := 0
	if int(s["haptic"]) > 0 and _haptics_on() and now - _last_haptic_ms >= HAPTIC_GAP_MS:
		ms = int(s["haptic"])
		_last_haptic_ms = now
		platform_vibrate.call(ms)
	played.append([m, sound, ms])

## One voice: inside the current voice's hold window (always the case within one frame) only a
## strictly higher priority may replace it; nothing ever plays on top of it.
func _voice_free(prio: int, now: int) -> bool:
	return now >= _voice_until or prio > _voice_prio

func stop_voice() -> void:
	_ui_queue = []
	if _player != null:
		_player.stop()
	_voice_until = 0
	_voice_prio = 0
	_tick_stop_at = 0
	set_process(false)

func is_voice_active() -> bool:
	return _player != null and _player.playing

func _process(_d: float) -> void:
	if _tick_stop_at > 0 and int(clock_ms.call()) >= _tick_stop_at:
		_tick_stop_at = 0
		if _player != null:
			_player.stop()
		set_process(false)

func _audio_on() -> bool:
	if _app == null or _app.audio == null:
		return true
	return _app.audio.is_master_enabled() and _app.audio.is_sfx_enabled()

func _haptics_on() -> bool:
	if _app == null:
		return false
	var hap: bool = _app.haptics == null or _app.haptics.is_enabled()
	var reduced: bool = _app.effects != null and _app.effects.is_reduced()
	return hap and not reduced
