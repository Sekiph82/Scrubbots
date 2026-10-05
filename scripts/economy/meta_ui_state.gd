extends RefCounted
## MetaUiState — preload (res://scripts/economy/meta_ui_state.gd).
##
## M43 master (SB-M43-068 onward) — durable PRESENTATION acknowledgements for meta
## ceremonies. It records which already-committed events (a Collection set reward, the
## Master Collection reward, a robot unlock, a Gift Meter milestone occurrence, ...) the
## player has already been shown, so a ceremony appears once per event and survives reload.
##
## It is NOT reward/economy truth: it never grants, spends or decides anything. It rides in
## the canonical EconomyServices snapshot (section "meta_ui") only so it is saved, rolled
## back and validated with the same save graph as the events it acknowledges.
##
## Section {version: 1, seen: [key, ...]}: strict when present (exact keys, unique
## non-empty strings). A save without the section (written before this existed) is handled
## by EconomyServices: every event already committed is baselined as seen, so an old
## profile never replays a backlog of ceremonies.

const VERSION := 1
const KEYS := ["version", "seen"]

var _seen: Dictionary = {}   ## key -> true

func is_seen(key: String) -> bool:
	return _seen.has(key)

## Mark one event as presented. True when newly marked (idempotent).
func mark_seen(key: String) -> bool:
	if key.is_empty() or _seen.has(key):
		return false
	_seen[key] = true
	return true

func seen_keys() -> Array:
	var k: Array = _seen.keys()
	k.sort()
	return k

func snapshot() -> Dictionary:
	return {"version": VERSION, "seen": seen_keys()}

## Strict, all-or-nothing import of a PRESENT section.
func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY or s.size() != KEYS.size() or not KEYS.all(func(k): return s.has(k)):
		return false
	var v = s["version"]
	if (typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT) or float(v) != float(VERSION):
		return false
	var raw = s["seen"]
	if typeof(raw) != TYPE_ARRAY:
		return false
	var next := {}
	for k in raw:
		if typeof(k) != TYPE_STRING or String(k).is_empty() or next.has(k):
			return false
		next[k] = true
	_seen = next
	return true

## Legacy baseline (section absent): replace the seen set with `keys`.
func baseline(keys: Array) -> void:
	_seen = {}
	for k in keys:
		_seen[String(k)] = true
