extends RefCounted
## CardTextureLru — preload (res://scripts/ui/collection/card_texture_lru.gd).
##
## SB-M22-028: the Collection album's texture cache, owned by the album popup (meta "tex_cache")
## and freed with it. Bounded LRU: at most MAX_FULL full-resolution card arts and MAX_BYTES
## resident RGBA8 over every texture it holds. Textures a visible popup draws are pinned under a
## key ("album", "set", "card"): never evicted, but counted in full_count() / bytes(). An evicted
## texture that no node still draws leaves the ResourceLoader cache; a later request reloads it.

const FULL_DIR := "res://assets/ui/final/collection/cards/"
const THUMB_DIR := "res://assets/ui/final/collection/card_thumbs/"
const MAX_FULL := 24
const MAX_BYTES := 96 * 1024 * 1024

var _tex := {}        # path -> Texture2D
var _order: Array = []   # paths, least recently used first
var _pins := {}       # key -> Array of paths
var loads := 0        # load() calls (tests: no double loading)

## The single-card thumbnail of a full card art path (other paths unchanged).
static func thumb(art: String) -> String:
	return art.replace(FULL_DIR, THUMB_DIR)

func texture(path: String) -> Texture2D:
	if _tex.has(path):
		_order.erase(path)
	else:
		_tex[path] = load(path)
		loads += 1
	_order.append(path)
	return _tex[path]

## Replaces the pins of key with paths, then evicts down to the limits.
func pin(key: String, paths: Array) -> void:
	_pins[key] = paths.duplicate()
	_trim()

func unpin(key: String) -> void:
	_pins.erase(key)
	_trim()

func is_pinned(path: String) -> bool:
	for k in _pins:
		if (_pins[k] as Array).has(path):
			return true
	return false

func has(path: String) -> bool:
	return _tex.has(path)

func paths() -> Array:
	return _order.duplicate()

func full_count() -> int:
	return _order.filter(func(p): return p.begins_with(FULL_DIR)).size()

func bytes() -> int:
	var b := 0
	for p in _order:
		var t: Texture2D = _tex[p]
		b += t.get_width() * t.get_height() * 4
	return b

## Least recently used unpinned first, until both limits hold or only pinned textures are left.
func _trim() -> void:
	var i := 0
	while i < _order.size() and (full_count() > MAX_FULL or bytes() > MAX_BYTES):
		var p: String = _order[i]
		if is_pinned(p):
			i += 1
			continue
		_order.remove_at(i)
		_tex.erase(p)
