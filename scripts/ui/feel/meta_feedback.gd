extends Node
## MetaFeedback — preload (res://scripts/ui/feel/meta_feedback.gd).
##
## M43-C014 (SB-M43-161..164, 167) — the compact meta-UI sound / haptic family. A pure observer:
## it reacts ONLY to committed facade results (`action_committed`, emitted after the authority
## succeeded and saved) and to ceremonies actually shown, so no sound or buzz can imply a
## purchase / ad / claim succeeded before its authoritative callback. Failures are silent.
##   - sound: the existing owner-approved completion.wav is reused for reward / unlock moments
##     (no new noisy per-screen sounds); played on the SFX bus, so Master / SFX volume and
##     mute apply immediately at every play;
##   - haptics: success (short) / unlock + rare reveal (longer); skipped when Haptics is OFF or
##     Reduced Effects is ON, read live per request;
##   - fatigue: one voice, and each moment is rate-limited (MIN_GAP_MS) so repeated claim /
##     open / close loops cannot stack sound or vibration.

const SFX_BUS := "SFX"
const REWARD_STREAM := "res://assets/audio/sfx/completion.wav"
const MIN_GAP_MS := 600
const SUCCESS_MS := 25
const UNLOCK_MS := 80
const REWARD_DB := -8.0

## facade action -> moment ("" = silent). Every reward-granting / unlocking commit is listed.
const MOMENTS := {
	"claim_daily_login": "reward", "claim_daily_task": "reward", "claim_daily_all_tasks": "reward",
	"claim_gift": "reward", "claim_collection_rewards": "reward", "exchange_card": "reward",
	"exchange_all_extras": "reward", "claim_event_milestone": "reward", "claim_first_try": "reward",
	"unlock_robot": "unlock", "buy_booster_charge": "success", "buy_heart": "success",
	"refill_hearts": "success", "buy_current_level_2x": "success", "buy_timed_2x": "success",
	"equip_robot": "success",
}

var _app = null
var _player: AudioStreamPlayer
var _last_ms := {}
var played: Array = []            ## [[moment, sound, haptic_ms]] diagnostics for tests
var platform_vibrate: Callable = func(ms): Input.vibrate_handheld(ms)

func bind(app) -> void:
	_app = app
	if _player == null:
		_player = AudioStreamPlayer.new()
		_player.name = "MetaFeedbackVoice"
		_player.bus = SFX_BUS if AudioServer.get_bus_index(SFX_BUS) != -1 else "Master"
		_player.volume_db = REWARD_DB
		_player.stream = load(REWARD_STREAM)
		add_child(_player)
	if app != null and app.actions != null and not app.actions.action_committed.is_connected(_on_committed):
		app.actions.action_committed.connect(_on_committed)

func _on_committed(action: String, result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		return
	var m := String(MOMENTS.get(action, ""))
	if not m.is_empty():
		moment(m)

## A ceremony that is actually on screen (pack rare reveal, robot unlock, set complete).
func on_ceremony_shown(_key: String, kind: String) -> void:
	moment("unlock" if kind in ["robot", "master", "set"] else "reward")

func moment(m: String) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last_ms.get(m, -100000)) < MIN_GAP_MS:
		return
	_last_ms[m] = now
	var sound := m != "success"
	if sound and _player != null and _audio_on():
		_player.stop()
		_player.play()
	else:
		sound = false
	var ms := 0
	if _haptics_on():
		ms = UNLOCK_MS if m == "unlock" else SUCCESS_MS
		platform_vibrate.call(ms)
	played.append([m, sound, ms])

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
