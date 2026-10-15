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
##   - one step at a time, in data order; an acknowledged step never shows again.

const FtueConfig = preload("res://scripts/app/ftue_config.gd")
const UiText = preload("res://scripts/ui/ui_text.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

var _app = null
var _cfg: Dictionary = {}
## Presentation policy (app root seam): false = no tips / What's New are presented.
var enabled := true

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
			return (st as Dictionary).duplicate(true)
	return {}

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
		_:
			body = UiText.t(String(step["body"]))
	if step.has("boosters"):
		var lines: Array = []
		var host = ctx.get("host", null)
		for id in step["boosters"]:
			var line := UiText.t("FTUE_BOOSTER_LINE", [UiText.t("BOOSTER_NAME_" + String(id).to_upper()),
				UiText.num(_app.economy.boosters.charges(String(id))), UiText.t("BOOSTER_EFFECT_" + String(id).to_upper())])
			if host != null and is_instance_valid(host) and host.has_method("booster_legality") \
					and not bool(host.booster_legality(String(id)).get("legal", false)):
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
	return (_cfg["whats_new"] as Array).filter(func(e): return not _app.economy.meta_ui.is_seen(whats_new_key(e)))

## Every What's New key in this config (the new-profile presentation baseline).
func whats_new_keys() -> Array:
	return (_cfg.get("whats_new", []) as Array).map(func(e): return whats_new_key(e))

## Dev / test seam: drive the director with another validated config (e.g. a simulated later
## build that adds a feature version). Never used by the shipping boot path.
func use_config(cfg: Dictionary) -> void:
	_cfg = cfg.duplicate(true)

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
		return false
	return true
