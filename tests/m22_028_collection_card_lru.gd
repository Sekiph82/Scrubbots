extends SceneTree
## SB-M22-028 — Collection card texture LRU + single-card thumbnails on the real main.tscn
## (1080x2400, throw-away save, all 135 cards owned). Checks: 135 thumbnails 440x660, lossless,
## the whole card scaled (no crop); album rows and the 9-card set grid draw thumbnails only, the
## full art loads only in the card detail; a sweep of all 135 card details through the 15 sets and
## back keeps the album LRU <= 24 full cards / <= 96 MiB and the ResourceLoader-resident card art
## <= 96 MiB; evicted invisible textures leave the ResourceLoader cache; pinned (visible) textures
## are never evicted but counted; fast paging and reopening reuse the same texture instances (no
## double loading); closing the album leaves no card art resident, reopen/close does not grow.
## Run: godot --headless --path . -s res://tests/m22_028_collection_card_lru.gd

const MainScript = preload("res://scripts/app/main.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const CollectionCardCatalog = preload("res://scripts/collection/collection_card_catalog.gd")
const CardTextureLru = preload("res://scripts/ui/collection/card_texture_lru.gd")

const MIB := 1024.0 * 1024.0
const THUMB_SIZE := Vector2i(440, 660)

var _fail := 0
var _root
var _save := ""
var _arts: Array = []   # 135 full card art paths, album order

func _initialize() -> void:
	for n in range(1, 16):
		for k in range(9):
			_arts.append(String(CollectionCardCatalog.entry("s%d_c%d" % [n, k])["art"]))
	_thumb_files()
	_lru_rules()
	MainScript.boot_opening_override = 0
	_save = "user://m22_028_lru_%d.save" % Time.get_ticks_usec()
	MainScript.boot_save_path_override = _save
	var sub := SubViewport.new()
	sub.size = Vector2i(1080, 2400)
	sub.disable_3d = true
	get_root().add_child(sub)
	_root = MainScene.instantiate()
	sub.add_child(_root)
	await _frames(6)
	_root.get_modal_stack().clear("test")
	var e = _root.get_app_state().economy
	for cid in e.collection.all_card_ids():
		e.collection.add_card(cid)
	# set-complete ceremonies draw their 9 full arts: acknowledge them (not Collection album memory)
	for ev in _root.ceremonies.pending():
		e.meta_ui.mark_seen(String(ev["key"]))
	await _frames(2)
	_ok(_resident()["n"] == 0, "before the album: no card art resident")
	await _sweep()
	await _reopen()
	_root.free()
	sub.free()
	MainScript.boot_save_path_override = ""
	MainScript.boot_opening_override = -1
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(_save + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(_save + suffix))
	print("M22-028 COLLECTION CARD LRU: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

## 135 separate thumbnails: 440x660 with alpha, lossless import without size_limit / mipmaps, and the
## whole source card scaled (one card per set compared against a fresh Lanczos downscale).
func _thumb_files() -> void:
	print("[thumbnail files]")
	var bad: Array = []
	for art in _arts:
		var t := CardTextureLru.thumb(art)
		var c := ConfigFile.new()
		var tex := load(t) as Texture2D
		if t == art or tex == null or Vector2i(tex.get_size()) != THUMB_SIZE or tex.get_image().get_format() != Image.FORMAT_RGBA8 \
				or c.load(t + ".import") != OK or int(c.get_value("params", "compress/mode", -1)) != 0 \
				or int(c.get_value("params", "process/size_limit", -1)) != 0 or bool(c.get_value("params", "mipmaps/generate", true)):
			bad.append(t)
	_ok(bad.is_empty(), "135 thumbnails 440x660 RGBA8, lossless, no size_limit / mipmaps %s" % str(bad.slice(0, 3)))
	var worst := 0.0
	for i in range(0, 135, 9):
		var src := Image.load_from_file(ProjectSettings.globalize_path(_arts[i]))
		src.convert(Image.FORMAT_RGBA8)
		src.resize(THUMB_SIZE.x, THUMB_SIZE.y, Image.INTERPOLATE_LANCZOS)
		var th := (load(CardTextureLru.thumb(_arts[i])) as Texture2D).get_image()
		var diff := 0.0
		for y in range(0, THUMB_SIZE.y, 4):
			for x in range(0, THUMB_SIZE.x, 4):
				var a := src.get_pixel(x, y)
				var b := th.get_pixel(x, y)
				diff += absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) + absf(a.a - b.a)
		worst = maxf(worst, diff / float((THUMB_SIZE.x / 4) * (THUMB_SIZE.y / 4) * 4))
	_ok(worst < 0.02, "thumbnails are the whole card scaled, not a crop (worst mean channel diff %.4f < 0.02)" % worst)

## Pure LRU rules on real card art: limits, LRU order, pins exempt but counted, eviction frees.
func _lru_rules() -> void:
	print("[LRU rules]")
	var lru = CardTextureLru.new()
	var keep := TextureRect.new()
	keep.texture = lru.texture(_arts[0])
	lru.pin("card", [_arts[0]])
	for i in range(1, 40):
		lru.texture(_arts[i])
	lru.unpin("none")   # trim
	_ok(lru.full_count() == CardTextureLru.MAX_FULL and lru.bytes() <= CardTextureLru.MAX_BYTES, "40 requested -> %d full cards, %.2f MiB" % [lru.full_count(), lru.bytes() / MIB])
	_ok(lru.has(_arts[0]) and lru.is_pinned(_arts[0]), "pinned first-loaded card never evicted (and counted in the 24)")
	_ok(not lru.has(_arts[1]) and lru.has(_arts[39]) and lru.paths()[-1] == _arts[39], "least recently used evicted first, newest kept")
	_ok(not ResourceLoader.has_cached(_arts[1]), "evicted, undrawn card left the ResourceLoader cache")
	var loads: int = lru.loads
	lru.texture(_arts[39])
	_ok(lru.loads == loads, "cached request does not reload")
	lru.unpin("card")
	keep.free()
	for i in range(40, 64):
		lru.texture(_arts[i])
	lru.unpin("none")
	_ok(not lru.has(_arts[0]) and not ResourceLoader.has_cached(_arts[0]), "unpinned, undrawn card evicted and released")
	lru = null
	_ok(_resident()["n"] == 0, "freeing the LRU releases every card art")

func _sweep() -> void:
	print("[sweep all 135 card details through the 15 sets and back]")
	var st = _root.get_modal_stack()
	var app = _root.get_app_state()
	var album = CollectionScreen.open_album(st, app)
	await _frames(2)
	var lru = album.get_meta("tex_cache")
	var rows: Array = album.find_children("Thumb", "TextureRect", true, false).map(func(t): return t.texture.resource_path)
	_ok(rows.size() == 15 and rows.all(func(p): return p.begins_with(CardTextureLru.THUMB_DIR) or p == CollectionScreen.ART["set_complete"]), "album rows draw a thumbnail or the set-complete emblem, never full art (%d)" % rows.size())
	_ok(_resident()["full"] == 0, "album open: no full card art loaded")
	album._on_action("set:1")
	await _frames(2)
	var d = st.top()
	var max_full := 0
	var max_bytes := 0
	var max_res := 0.0
	var grid_ok := true
	var detail_ok := true
	for step in range(30):   # 15 sets forward (wraps to 1), then 15 back
		var n := int(d.get_meta("set"))
		var tiles: Array = d.find_child("Cards", true, false).get_children()
		for k in range(9):
			var tr: TextureRect = tiles[k].find_child("CardArt", true, false)
			grid_ok = grid_ok and tiles.size() == 9 and tr.texture.resource_path == CardTextureLru.thumb(_arts[(n - 1) * 9 + k]) and lru.is_pinned(tr.texture.resource_path)
		if step < 15:   # every card detail once
			for k in range(9):
				d._on_action("card:s%d_c%d" % [n, k])
				await _frames(1)
				var c = st.top()
				var art: TextureRect = c.find_child("CardArt", true, false)
				detail_ok = detail_ok and String(c.popup_id) == "collection_card" and art.texture.resource_path == _arts[(n - 1) * 9 + k] and lru.is_pinned(_arts[(n - 1) * 9 + k])
				max_full = maxi(max_full, lru.full_count())
				max_bytes = maxi(max_bytes, lru.bytes())
				max_res = maxf(max_res, _resident()["mib"])
				c._on_action("back")
				await _frames(2)
				max_res = maxf(max_res, _resident()["mib"])
		d._on_action("next" if step < 15 else "prev")
		await _frames(1)
	await _frames(2)
	_ok(grid_ok, "every set page: 9 tiles drawing their card's thumbnail, pinned")
	_ok(detail_ok, "every card detail drew its full art, pinned while open")
	_ok(int(d.get_meta("set")) == 1, "15 forward + 15 back returns to set 1")
	_ok(max_full <= CardTextureLru.MAX_FULL and max_bytes <= CardTextureLru.MAX_BYTES, "LRU peak %d full cards / %.2f MiB (<= %d / %.0f)" % [max_full, max_bytes / MIB, CardTextureLru.MAX_FULL, CardTextureLru.MAX_BYTES / MIB])
	_ok(max_res <= CardTextureLru.MAX_BYTES / MIB, "ResourceLoader card-art peak %.2f MiB <= 96" % max_res)
	var res := _resident()
	print("  steady after sweep: LRU %d full / %.2f MiB; resident %d full + %d thumbs, %.2f MiB; loads %d" % [lru.full_count(), lru.bytes() / MIB, res["full"], res["thumbs"], res["mib"], lru.loads])
	_ok(res["mib"] <= CardTextureLru.MAX_BYTES / MIB, "steady card art %.2f MiB <= 96" % res["mib"])
	_ok(not lru.has(_arts[0]) and not ResourceLoader.has_cached(_arts[0]), "first viewed full art evicted and released by the ResourceLoader")
	var held := 0
	for p in _paths():
		held += int(ResourceLoader.has_cached(p) and not lru.has(p))
	_ok(held == 0, "every resident card texture is one the LRU holds (%d outside)" % held)
	_ok(_fast_paging(d), "30 pages without a frame: same 9 texture instances (no double load)")
	await _frames(2)
	_ok(d.find_child("Cards", true, false).get_child_count() == 9, "one 9-card grid after fast paging")
	lru = null
	st.clear("test")
	await _frames(3)
	_ok(_resident()["n"] == 0, "album closed: no card art or thumbnail resident")

## No frame between pages: the old tiles are still queued for deletion. In its own function so the
## texture references it takes die with its stack.
func _fast_paging(d) -> bool:
	var before: Array = d.find_child("Cards", true, false).get_children().map(func(t): return t.find_child("CardArt", true, false).texture)
	for i in range(30):
		d._on_action("next" if i % 2 == 0 else "prev")
	var after: Array = d.find_child("Cards", true, false).get_children().filter(func(t): return not t.is_queued_for_deletion()).map(func(t): return t.find_child("CardArt", true, false).texture)
	return after.size() == 9 and range(9).all(func(i): return is_same(before[i], after[i]))

func _reopen() -> void:
	print("[reopen / close]")
	var st = _root.get_modal_stack()
	var app = _root.get_app_state()
	var counts: Array = []
	for visit in 3:
		var album = CollectionScreen.open_album(st, app)
		await _frames(1)
		album._on_action("set:7")
		await _frames(1)
		st.top()._on_action("card:s7_c4")
		await _frames(2)
		var r := _resident()
		counts.append(r["n"])
		var drawn := {}
		for t in album.find_children("Thumb", "TextureRect", true, false) + _root.find_children("CardArt", "TextureRect", true, false):
			drawn[t.texture.resource_path] = true
		var thumbs: int = drawn.keys().filter(func(p): return p.begins_with(CardTextureLru.THUMB_DIR)).size()
		_ok(r["full"] == 1 and r["thumbs"] == thumbs and thumbs == 9, "visit %d: 1 full card + exactly the %d drawn thumbnails resident (%.2f MiB)" % [visit + 1, r["thumbs"], r["mib"]])
		st.clear("test")
		await _frames(3)
		_ok(_resident()["n"] == 0, "visit %d closed: nothing resident" % (visit + 1))
	_ok(counts[0] == counts[1] and counts[1] == counts[2], "reopen does not grow (%s)" % str(counts))

func _paths() -> Array:
	return _arts + _arts.map(func(a): return CardTextureLru.thumb(a))

## Card art (full + thumbnails) in the ResourceLoader cache, RGBA8 bytes.
func _resident() -> Dictionary:
	var r := {"n": 0, "full": 0, "thumbs": 0, "mib": 0.0}
	for p in _paths():
		if not ResourceLoader.has_cached(p):
			continue
		var t := ResourceLoader.get_cached_ref(p) as Texture2D
		r["n"] += 1
		r["full" if p.begins_with(CardTextureLru.FULL_DIR) else "thumbs"] += 1
		r["mib"] += t.get_width() * t.get_height() * 4 / MIB
	return r

func _frames(n: int) -> void:
	for _i in range(n):
		await process_frame

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
