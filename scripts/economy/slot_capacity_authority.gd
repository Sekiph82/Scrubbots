extends RefCounted
## SlotCapacityAuthority — preload
## (res://scripts/economy/slot_capacity_authority.gd).
##
## Canonical source of the ACTIVE slot capacity (5 or 6). The audited five-slot
## engine (scripts/gameplay/slots/*) keeps its locked five-slot baseline; this
## authority is the single place that says whether the current attempt has been
## upgraded to a temporary sixth slot by the +1 Slot booster.
##
## Rules (owner §, SB-M39-030/031):
##   - baseline capacity 5;
##   - +1 Slot upgrades to 6 for the CURRENT attempt only, at most once;
##   - a new attempt returns to 5;
##   - capacity is NEVER 7+ (hard clamp).
##
## The M27 solver / M24 engine adapter reads active_capacity() so state
## encoding, canonicalization and deadlock logic operate at the correct 5 or 6.

const BASE := 5
const MAX := 6

var _capacity: int = BASE
var _plus_one_used_this_attempt: bool = false

func active_capacity() -> int:
	return _capacity

func can_activate_plus_one() -> bool:
	return not _plus_one_used_this_attempt and _capacity < MAX

## Upgrade to 6 for the current attempt. At most once. Returns true on upgrade.
func activate_plus_one() -> bool:
	if not can_activate_plus_one():
		return false
	_capacity = MAX
	_plus_one_used_this_attempt = true
	return true

## New attempt: back to baseline 5, +1 Slot re-armed.
func begin_new_attempt() -> void:
	_capacity = BASE
	_plus_one_used_this_attempt = false

func plus_one_active() -> bool:
	return _capacity == MAX
