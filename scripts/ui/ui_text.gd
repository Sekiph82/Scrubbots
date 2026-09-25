extends RefCounted
## UiText — preload (res://scripts/ui/ui_text.gd).
##
## M42 (SB-M42-025) — the ONE translation/format seam for Home / Results / Home popups.
## Every user-facing string is a KEY. t(key, args) asks Godot's TranslationServer first
## (so shipping localizations are plain Translation resources) and falls back to the
## built-in English table. Values (SB amounts, Bot Parts, Gift Meter, streak rewards,
## Daily state, prices) are always passed in as live arguments — never baked into copy,
## and this seam never changes locked Economy V1 numbers.

const EN := {
	"HOME_PLAY": "PLAY",
	"HOME_CONTINUE_LEVEL": "CONTINUE · LEVEL %d",
	"HOME_START_LEVEL": "LEVEL %d",
	"HOME_PLAYER_NAME_DEFAULT": "Scrubby",
	"HOME_AREA_TITLE": "WHISPERING PARK",
	"HOME_AREA_NUMBER": "AREA %d",
	"HOME_LEVEL_COMING_SOON": "Level %d is coming soon.",
	"HOME_LEVELS_UNAVAILABLE": "Levels unavailable (%s).",
	"HOME_LOADING": "Loading...",
	"HOME_SAVE_BLOCKED": "Save data is from a newer version. Update the game to continue.",
	"HOME_PROFILE_LINE": "LEVEL %d · %s",
	"HOME_BOT_PARTS": "BOT PARTS %s/%s",
	"HOME_ROBOT_READY": " · ROBOT READY",
	"HOME_GIFT_METER": "GIFT METER %s/%s · %s",
	"HOME_GIFT_NEXT": "NEXT GIFT AT %s",
	"HOME_GIFT_CYCLE_COMPLETE": "CYCLE COMPLETE",
	"HOME_CURRENCY_SB": "SB",
	"HOME_TRACK_AMOUNT": "+%s",
	"HOME_TRACK_WIN": "WIN %s",
	"HOME_TRACK_WIN_NOW": "WIN %s · NOW",
	"HOME_SC_WIN_STREAK": "WIN STREAK",
	"HOME_SC_GIFT_BAR": "GIFTS",
	"HOME_SC_COLLECTION": "COLLECTION",
	"HOME_SC_SHOP": "SHOP",
	"HOME_SC_DAILY": "DAILY",
	"HOME_SC_TASKS": "TASKS",
	"HOME_SC_CARDS_EXCHANGE": "CARDS EXCHANGE",
	"HOME_SC_NO_ADS": "NO ADS",
	"HOME_NAV_EVENTS": "EVENTS",
	"HOME_NAV_ROBOTS": "ROBOTS",
	"HOME_NAV_HOME": "HOME",
	"HOME_NAV_LEADERBOARD": "RANKS",
	"HOME_NAV_SETTINGS": "SETTINGS",
	"HOME_COMING_LATER": "Coming later",
	"POPUP_CLOSE": "CLOSE",
	"POPUP_CLAIM": "CLAIM",
	"GIFTS_TITLE": "GIFTS",
	"GIFTS_ROW": "GIFT %s · %s",
	"GIFTS_EMPTY": "No gifts to claim. Win levels in a row to fill the Gift Meter.",
	"GIFTS_READ_ONLY": "Claims are unavailable while the save is read-only.",
	"CARDS_TITLE": "CARDS EXCHANGE",
	"CARDS_ROW": "%s · x%s duplicate(s) · %s SB",
	"CARDS_EMPTY": "No duplicate cards yet.",
	"CARDS_NOTE": "%s duplicate card(s) worth %s SB. Exchange them in the Collection (coming later).",
	"DAILY_TITLE": "DAILY REWARDS",
	"DAILY_ROW": "DAY %d · %s%s",
	"DAILY_TODAY": " · TODAY",
	"DAILY_CLAIMED_TODAY": " · CLAIMED TODAY",
	"DAILY_STREAK": "Login streak: %s day(s).",
	"REWARD_ITEM": "%s x%s",
	"REWARD_scrub_bucks": "SB",
	"REWARD_bot_parts": "Bot Parts",
	"REWARD_standard_card_packs": "Card Pack",
	"REWARD_premium_card_packs": "Premium Pack",
	"REWARD_random_booster_charges": "Random Booster",
	"REWARD_selected_booster_charges": "Booster of choice",
	"REWARD_guaranteed_new_cards": "New Card",
	"RESULTS_WON": "LEVEL COMPLETE",
	"RESULTS_LOST": "LEVEL FAILED",
	"RESULTS_ERROR": "SOMETHING WENT WRONG",
	"RESULTS_LEVEL": "Level %d",
	"RESULTS_CONTINUE": "CONTINUE",
	"RESULTS_RETRY": "RETRY",
	"RESULTS_HOME": "HOME",
}

## Translated (or English fallback) copy for `key`, formatted with `args`.
static func t(key: String, args: Array = []) -> String:
	var tr_text := String(TranslationServer.translate(key))
	var text: String = tr_text if tr_text != key else String(EN.get(key, key))
	if args.is_empty():
		return text
	return text % args

## Integer with thousands grouping (single seam; a locale-aware separator can replace it).
static func num(n: int) -> String:
	var neg := n < 0
	var d := str(absi(n))
	var out := ""
	while d.length() > 3:
		out = "," + d.substr(d.length() - 3) + out
		d = d.substr(0, d.length() - 3)
	return ("-" if neg else "") + d + out

## Human text for a canonical reward bundle, e.g. {"scrub_bucks": 100} -> "SB x100".
static func reward_text(rewards: Dictionary) -> String:
	var parts: Array = []
	var keys: Array = rewards.keys()
	keys.sort()
	for k in keys:
		if int(rewards[k]) > 0:
			parts.append(t("REWARD_ITEM", [t("REWARD_" + String(k)), num(int(rewards[k]))]))
	return ", ".join(parts)
