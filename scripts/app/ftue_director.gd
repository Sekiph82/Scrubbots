extends RefCounted
## FtueDirector — preload (res://scripts/app/ftue_director.gd).
##
## M44 (SB-M44-001..009/014..017) — decides WHICH single coachmark step (if any) belongs on a
## surface right now, from the data-driven lessons in FtueConfig and the durable FtueState.
## Presentation authority only: it never grants, claims, spends, moves progression, touches
## the board / supply / solver, or starts a booster / 2x / loss. Acknowledging a step, Skip
## Tips, closing the window and What's New acknowledgements only write FtueState / MetaUiState
## and request the canonical save.
##
## Rules (owner V03):
##   - tips exist only for a conclusively NEW profile, while not skipped and not closed;
##   - only levels 1..max_tutorial_level (<= 3) have lessons, and only on the PROGRESSION
##     attempt of that exact production level id; L4+ never has a scheduled step;
##   - the window closes once the frontier passes max_tutorial_level (L3 Results), whether or
##     not every optional step was seen;
##   - one step at a time, in data order; an acknowledged step never shows again;
##   - SB-M44-031: a coachmark never targets a locked control (AppState.feature_unlocked): a
##     Home step on a locked shortcut is skipped and locked boosters are dropped from a
##     `boosters` step (skipped when none remain). Skipped steps are NOT marked seen.
##   - SB-M44-005/006 contextual entries (first WAITING, first win, first loss) are event-
##     triggered, not scheduled: shown once at the first real occurrence to a NEW profile that
##     has not skipped tips, at any level (not limited to the L1-L3 window). Established profiles
##     never see them. A due scheduled step wins; acknowledged into the same seen ledger.

const FtueConfig = preload("res://scripts/app/ftue_config.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

var _app = null
var _cfg: Dictionary = {}
## Presentation policy (app root seam): false = no tips / What's New are presented.
var enabled := true
## Session-only What's New keys whose acknowledgement could not be saved (owner D2 review).
var _snoozed: Dictionary = {}

func _init(app_state, cfg: Dictionary = {}) -> void:
	_app = app_state
	_cfg = cfg if not cfg.is_empty() else FtueConfig.load_config()

func is_ok() -> bool:
	return bool(_cfg.get("ok", false))

func config() -> Dictionary:
	return _cfg.duplicate(true)

func max_level() -> int:
	return int(_cfg.get("max_tutorial_level", 0))

func _live() -> bool:
	return enabled and is_ok() and _app != null and _app.economy != null and not _app.is_blocked

func tips_active() -> bool:
	return _live() and _app.economy.ftue.tips_active()

## Close the compulsory window once the frontier is past it (L3 Results / any later boot).
## True when it closed on this call.
func settle() -> bool:
	if not is_ok() or _app == null or _app.economy == null or _app.is_blocked:
		return false
	var st = _app.economy.ftue
	if st.is_new_profile() and not st.closed and int(_app.progression.current_level()) > max_level():
		st.close()
		_app.request_save()
		return true
	return false

## Truthful Home conditions for `when` steps (read-only canonical state).
func home_context() -> Dictionary:
	var lvl := int(_app.progression.current_level()) if _app != null else 0
	if _app == null or _app.economy == null:
		return {"level": lvl}
	var d = _app.economy.daily
	return {"level": lvl, "daily_claimable": not d.claimed_today(),
		"tasks_claimable": d.is_welcome_task(0) and d.is_task_done(0) and not d.task_claimed(0)}

## The single step for `surface` ("home" | "gameplay") given ctx {level, level_id, ...flags}.
## {} when nothing should show.
func current_step(surface: String, ctx: Dictionary) -> Dictionary:
	if not tips_active():
		return {}
	var lvl := int(ctx.get("level", 0))
	if lvl < 1 or lvl > max_level() or lvl != int(_app.progression.current_level()):
		return {}
	for lesson in _cfg["lessons"]:
		if String(lesson["surface"]) != surface or int(lesson["level"]) != lvl:
			continue
		if surface == "gameplay" and String(lesson["level_id"]) != String(ctx.get("level_id", "")):
			continue
		for st in lesson["steps"]:
			if _app.economy.ftue.is_seen(String(st["id"])):
				continue
			if st.has("when") and not bool(ctx.get(String(st["when"]), false)):
				continue
			var target := String(st["target"])
			if target.begins_with("shortcut:") and not _app.feature_unlocked(target.trim_prefix("shortcut:")):
				continue
			var out: Dictionary = (st as Dictionary).duplicate(true)
			if out.has("boosters"):
				out["boosters"] = (out["boosters"] as Array).filter(func(b): return _app.feature_unlocked(String(b)))
				if (out["boosters"] as Array).is_empty():
					continue
			return out
	return {}

## Contextual entries may show: NEW profile, Skip Tips not chosen (window `closed` does not matter).
func contextual_active() -> bool:
	return _live() and _app.economy.ftue.is_new_profile() and not _app.economy.ftue.skipped

## The unseen contextual entry for a live `trigger` ("slot_waiting" | "result_won" |
## "result_lost", read from canonical state by the caller), or {}.
func contextual_step(trigger: String) -> Dictionary:
	if trigger.is_empty() or not contextual_active():
		return {}
	for c in _cfg["contextual"]:
		if String(c["trigger"]) == trigger and not _app.economy.ftue.is_seen(String(c["id"])):
			return (c as Dictionary).duplicate(true)
	return {}

## The trigger of contextual entry `step_id` ("" when it is not a contextual entry).
func contextual_trigger(step_id: String) -> String:
	for c in _cfg.get("contextual", []):
		if String(c["id"]) == step_id:
			return String(c["trigger"])
	return ""

## Acknowledge (Got it / completed by the real action). Idempotent; never double-acks.
func acknowledge(step_id: String) -> bool:
	if not _live() or not _app.economy.ftue.is_new_profile():
		return false
	if not _app.economy.ftue.mark_seen(step_id):
		return false
	_app.request_save()
	return true

## A real player action happened (e.g. "supply_placed", "shortcut:daily", "play"): completes
## the CURRENT step only when that step is completed by exactly this action.
func notify(event: String, surface: String, ctx: Dictionary) -> bool:
	var st := current_step(surface, ctx)
	if st.is_empty() or String(st.get("complete_on", "")) != event:
		return false
	return acknowledge(String(st["id"]))

## Skip Tips (presentation only, once). Rewards / inventory / progression untouched.
func skip_tips() -> bool:
	if not tips_active() or not _app.economy.ftue.skip():
		return false
	_app.request_save()
	return true

## Localized copy for a step with LIVE values. ctx may carry "host" (gameplay) for booster
## charges / legality. {title, body}.
func step_copy(step: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var body := ""
	match String(step.get("id", "")):
		"home_daily":
			var d = _app.economy.daily
			body = UiText.t(String(step["body"]), [UiText.reward_text(d.login_reward_for(d.next_claim_cycle_day()))])
		"home_tasks":
			body = UiText.t(String(step["body"]), [UiText.num(_app.economy.daily.task_reward_sb(0))])
		"ctx_result_lost":
			# "cost 1 Heart" only when the committed receipt really lost one (ctx "receipt").
			var h: Dictionary = (ctx.get("receipt", {}) as Dictionary).get("hearts", {})
			var lost := int(h.get("after", 0)) < int(h.get("before", 0))
			body = UiText.t(String(step["body"]), [UiText.t("FTUE_CTX_HEART_LOST" if lost else "FTUE_CTX_HEART_KEPT")])
		_:
			body = UiText.t(String(step["body"]))
	if step.has("boosters"):
		var lines: Array = []
		var host = ctx.get("host", null)
		for id in step["boosters"]:
			var line := UiText.t("FTUE_BOOSTER_LINE", [UiText.t("BOOSTER_NAME_" + String(id).to_upper()),
				UiText.num(_app.economy.boosters.charges(String(id))), UiText.t("BOOSTER_EFFECT_" + String(id).to_upper())])
			if host != null and is_instance_valid(host) and host.has_method("booster_legality"):
				# M46 R07: never a main-thread still-moment proof for a hint. Off-frame legality
				# answers from the exact-state cache or starts the shared R06 worker ("checking":
				# no claim either way, so no suffix; main refreshes the copy when it settles).
				# M46 RM003: a yes/no hint, so no Selector target list (the full list rebuilt a
				# scratch engine per batch every 2 s while robots moved: 23-28 ms main thread).
				var leg: Dictionary = host.booster_legality_offframe(String(id), false) \
					if host.has_method("booster_legality_offframe") else host.booster_legality(String(id))
				if String(leg.get("reason", "")) != "checking" and not bool(leg.get("legal", false)):
					line += " " + UiText.t("FTUE_BOOSTER_NOT_NOW")
			lines.append(line)
		body = "\n".join(lines)
	return {"title": UiText.t(String(step["title"])), "body": body}

# ------------------------------------------------------------------ What's New --

static func whats_new_key(e: Dictionary) -> String:
	return "feature:%s:%d" % [String(e["feature_id"]), int(e["version"])]

## Entries not shown yet. Established profiles: as before. NEW profiles (owner D2,
## OWNER_D2_WHATS_NEW_AND_DISK_DIAG_DECISION_V01): nothing while the L1-L3 window is open -
## Skip Tips does not open it - only after the window is genuinely `closed` (L3 completed).
## Entries present at their bootstrap were baselined as seen there, so only a feature/version
## added LATER can show, once.
func whats_new_due() -> Array:
	if not _live():
		return []
	if _app.economy.ftue.is_new_profile() and not _app.economy.ftue.closed:
		return []
	return (_cfg["whats_new"] as Array).filter(func(e):
		var k := whats_new_key(e)
		return not _app.economy.meta_ui.is_seen(k) and not _snoozed.has(k))

## Dev / test seam: drive the director with another config that passed FtueConfig.validate
## (e.g. a simulated later build adding a feature version). Refuses anything not `ok`.
## Never used by the shipping boot path.
func use_config(cfg: Dictionary) -> bool:
	if not bool(cfg.get("ok", false)):
		return false
	_cfg = cfg.duplicate(true)
	return true

## Feature-unlock ceremony event (M43-C005 builder input) for a What's New entry.
func whats_new_event(e: Dictionary) -> Dictionary:
	return {"key": whats_new_key(e), "kind": "feature_unlock", "feature_id": String(e["feature_id"]),
		"name": UiText.t(String(e["name"])), "body": UiText.t(String(e["body"])), "icon": String(e["icon"])}

## Durable acknowledgement: kept only if the canonical save succeeds; on a save failure the
## presentation ledger is restored exactly and the entry stays due (fail closed).
func acknowledge_whats_new(e: Dictionary) -> bool:
	if _app == null or _app.economy == null or _app.is_blocked:
		return false
	var meta = _app.economy.meta_ui
	var pre: Dictionary = meta.snapshot()
	if not meta.mark_seen(whats_new_key(e)):
		return false
	var r: Dictionary = _app.request_save()
	if not bool(r.get("ok", false)):
		meta.import_snapshot(pre)
		# Not dismissed durably: snooze it for THIS session only (never persisted), so the
		# non-dismissible ceremony cannot re-open in a loop while saves fail; it is due again
		# on the next launch.
		_snoozed[whats_new_key(e)] = true
		return false
	return true
