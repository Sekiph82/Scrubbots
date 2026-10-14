extends RefCounted
## FtueState — preload (res://scripts/economy/ftue_state.gd).
##
## M44 (SB-M44-014/019) — durable first-time-experience PRESENTATION state: whether this save
## is a conclusively fresh profile bootstrapped by M44, whether the player chose Skip Tips,
## whether the compulsory (L1-L3) tutorial window is closed, and which coachmark steps were
## acknowledged.
##
## It is NOT reward truth: the starter booster grant and the first-day welcome task live in
## the canonical RewardGrantService / DailyService state (AppState.bootstrap_new_profile).
## It rides in the EconomyServices snapshot (section "ftue") only so it is saved, rolled back
## and validated with the same save graph.
##
## profile:
##   ""     every existing / migrated / older save and never-bootstrapped defaults: an
##          established player — no beginner tips, never a starter grant;
##   "new"  a conclusively fresh profile bootstrapped by this build.
## Section {version, profile, skipped, closed, seen}: strict when present (exact keys, exact
## bools, known profile, unique non-empty step ids). Absent (a pre-M44 save) = established.

const VERSION := 1
const KEYS := ["version", "profile", "skipped", "closed", "seen"]
const PROFILE_ESTABLISHED := ""
const PROFILE_NEW := "new"
const PROFILES := [PROFILE_ESTABLISHED, PROFILE_NEW]

var profile := PROFILE_ESTABLISHED
var skipped := false
var closed := false
var _seen: Dictionary = {}

func is_new_profile() -> bool:
	return profile == PROFILE_NEW

## Compulsory tips may still show (new profile, not skipped, window not closed).
func tips_active() -> bool:
	return profile == PROFILE_NEW and not skipped and not closed

func is_seen(step_id: String) -> bool:
	return _seen.has(step_id)

func seen_steps() -> Array:
	var k: Array = _seen.keys()
	k.sort()
	return k

## Acknowledge one step. True when newly marked (idempotent).
func mark_seen(step_id: String) -> bool:
	if step_id.is_empty() or _seen.has(step_id):
		return false
	_seen[step_id] = true
	return true

## Only an established/default state becomes "new" once (never re-classifies twice).
func mark_new() -> bool:
	if profile == PROFILE_NEW:
		return false
	profile = PROFILE_NEW
	return true

## Skip Tips: once, presentation only. True when newly skipped.
func skip() -> bool:
	if profile != PROFILE_NEW or skipped:
		return false
	skipped = true
	return true

## The compulsory window ends (L3 completed). True when newly closed.
func close() -> bool:
	if profile != PROFILE_NEW or closed:
		return false
	closed = true
	return true

func snapshot() -> Dictionary:
	return {"version": VERSION, "profile": profile, "skipped": skipped, "closed": closed, "seen": seen_steps()}

## Strict, all-or-nothing import. null (section absent) = a pre-M44 save = established.
func import_snapshot(s) -> bool:
	if s == null:
		profile = PROFILE_ESTABLISHED
		skipped = false
		closed = false
		_seen = {}
		return true
	if typeof(s) != TYPE_DICTIONARY or s.size() != KEYS.size() or not KEYS.all(func(k): return s.has(k)):
		return false
	var v = s["version"]
	if (typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT) or float(v) != float(VERSION):
		return false
	if typeof(s["profile"]) != TYPE_STRING or not PROFILES.has(s["profile"]):
		return false
	if typeof(s["skipped"]) != TYPE_BOOL or typeof(s["closed"]) != TYPE_BOOL or typeof(s["seen"]) != TYPE_ARRAY:
		return false
	var next := {}
	for k in s["seen"]:
		if typeof(k) != TYPE_STRING or String(k).is_empty() or next.has(k):
			return false
		next[k] = true
	profile = String(s["profile"])
	skipped = bool(s["skipped"])
	closed = bool(s["closed"])
	_seen = next
	return true
