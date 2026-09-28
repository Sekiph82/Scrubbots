extends RefCounted
## ShopHandoff — preload (res://scripts/app/shop_handoff.gd).
##
## M43-C003 (SB-M43-036 / SB-M43-022 consumer) — the canonical Shop / SB-acquisition
## navigation intent with a DETACHED return context. The full Shop destination is
## M43-C006; until it exists, the app shows an explicit "Shop coming soon" state and
## finishes the ticket as "cancelled". No SB pack is sold and no currency moves here.
##
## A ticket is a deep copy of the caller's context plus {ticket_id, source}:
##   source   "home_sb_plus" | "life" | "booster" | "speed"
##   product  exact pending product, e.g. "heart_plus_one", "heart_refill",
##            "booster:tornado", "speed:timed_900"
##   ...      caller data needed to resume/cancel (price, target, level, ...)
## Tickets live here, not on any popup node, so a closed popup cannot lose them.
## finish(ticket_id, outcome) resolves a ticket exactly once and emits `returned`;
## a caller resumes (outcome "fulfilled", future Shop) or restores (any other outcome).

signal shop_requested(ticket: Dictionary)
signal returned(ticket: Dictionary, outcome: String)

var _open: Dictionary = {}   ## ticket_id -> ticket
var _seq := 0

func open(context: Dictionary) -> Dictionary:
	_seq += 1
	var ticket := context.duplicate(true)
	ticket["ticket_id"] = "shop_%d" % _seq
	ticket["source"] = String(context.get("source", "unknown"))
	_open[ticket["ticket_id"]] = ticket
	shop_requested.emit(ticket.duplicate(true))
	return ticket.duplicate(true)

func finish(ticket_id: String, outcome: String = "cancelled") -> bool:
	if not _open.has(ticket_id):
		return false
	var t: Dictionary = _open[ticket_id]
	_open.erase(ticket_id)
	returned.emit(t.duplicate(true), outcome)
	return true

func get_ticket(ticket_id: String) -> Dictionary:
	return (_open.get(ticket_id, {}) as Dictionary).duplicate(true)

func open_tickets() -> Array:
	return _open.values().map(func(t): return t.duplicate(true))
