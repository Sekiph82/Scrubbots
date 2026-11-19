extends RefCounted
## HomeRewardFlight — preload (res://scripts/ui/home/home_reward_flight.gd).
##
## SB-PHONE-2026-11-12-E (owner 2026-11-12) — after a win the app goes straight Home and the
## level's rewards fly into their Home HUD targets there. Built ONLY from the host's committed
## TerminalRewardReceipt (economy already granted + saved before the win animation started):
##
##   reward            icon (existing approved art)   HUD target        count-up
##   Scrub Bucks       SB currency icon               ScrubBucksChip    wallet before -> after
##   Bot Parts         Bot Parts icon                 ProfileBotParts   parts before -> after
##   Gift Meter        Gift Meter emblem              GiftMeterBar      cycle progress (tick overlay pulses)
##   Collection cards  standard pack art              ProfileCard       (fly only)
## SB-TF-03: Home has no win-streak strip any more, so the streak flies nowhere (its Scrub Bucks
## still land in the wallet row); Collection moved into Profile, so cards fly to the profile card.
##
## SB-TF-05 (owner 2026-11-18): the flight itself moved into the shared RewardReveal
## (res://scripts/ui/components/reward_reveal.gd: all rewards appear together, hold 1.5 s, then
## fly; one input lock; Reduced keeps the hold). This file keeps only the receipt -> entries map.
## PRESENTATION ONLY: plan() reads nothing but the committed receipt and the Home view model.

const ICONS := {
	"scrub_bucks": "res://assets/ui/final/common/currencies/icon_currency_scrub_bucks.png",
	"bot_parts": "res://assets/ui/final/robots/bot_parts_icon.png",
	"gift_meter": "res://assets/ui/final/home/gift_meter/gift_meter_emblem.png",
	"collection_cards": "res://assets/ui/final/rewards/card_pack_standard.png",
}

## The rewards a receipt shows, in order: [{kind, from, to, n, target}]. `vm` = the live Home view
## model (the HUD's final values); n = the "+N" amount (to - from where a counter climbs). Pure:
## nothing outside the committed receipt adds an entry.
static func plan(receipt: Dictionary, vm: Dictionary) -> Array:
	var out: Array = []
	if String(receipt.get("status", "")) != "WON" or not bool(vm.get("ok", false)):
		return out
	var wd: Dictionary = receipt.get("wallet_delta", {})
	if int(wd.get("scrub_bucks", 0)) > 0:
		out.append({"kind": "scrub_bucks", "from": int(vm["scrub_bucks"]) - int(wd["scrub_bucks"]), "to": int(vm["scrub_bucks"]), "target": "ScrubBucksChip"})
	if int(wd.get("bot_parts", 0)) > 0:
		out.append({"kind": "bot_parts", "from": maxi(int(vm["bot_parts"]) - int(wd["bot_parts"]), 0), "to": int(vm["bot_parts"]), "target": "ProfileBotParts"})
	for e in receipt.get("reveal_queue", []):
		if String(e.get("kind", "")) == "gift_meter":
			var g: Dictionary = receipt.get("gift_meter", {})
			var wrapped: bool = int(g.get("cycles_after", 0)) > int(g.get("cycles_before", 0))
			out.append({"kind": "gift_meter", "from": 0 if wrapped else int(e["from"]), "to": int(e["to"]), "target": "GiftMeterBar"})
	if int(receipt.get("cards_delta", 0)) > 0:
		out.append({"kind": "collection_cards", "from": 0, "to": 0, "n": int(receipt["cards_delta"]), "target": "ProfileCard"})
	for e in out:
		if not e.has("n"):
			e["n"] = int(e["to"]) - int(e["from"])
	return out
