extends SceneTree
## M43-C005-C001 (SB-M43-076) — ceremony visual-master candidate checks.
## The candidates are PREVIEW HARNESS ONLY (tests/tools/ceremony_preview/): real BasePopup /
## ModalStack family + real final art + read-only fixtures. These checks prove the visual
## truth the owner will review (counts, rarity, NEW/DUPLICATE, exact configured rewards,
## canonical roster text), that nothing mutates economy / progression / save, and that the
## family fits the five target viewports.
##
## Run: godot --headless --path . -s res://tests/m43_c005_c001_ceremony_visual_masters.gd

const CC = preload("res://tests/tools/ceremony_preview/ceremony_candidates.gd")
const ModalStack = preload("res://scripts/ui/popup/modal_stack.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const UiTokens = preload("res://scripts/ui/ui_tokens.gd")

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1170, 2532), Vector2i(1290, 2796), Vector2i(1536, 2048)]
const BANNED := ["JACKPOT", "LUCKY", "ALMOST", "SO CLOSE", "HURRY", "LAST CHANCE", "LIMITED", "BONUS!", "EXTRA REWARD", "ODDS", "REROLL", "RE-ROLL", "OPEN AGAIN"]

var EXPECTED := ["c01_standard_3", "c02_premium_5", "c03_rarity_new_state", "c04_no_reroll", "c05_set_reward_exact",
	"c06_master_exact", "c07_robot_roster", "c08_gift_exact", "c09_feature_no_level", "c10_world_no_range",
	"c11_generic_1_to_4", "c12_no_mutation", "c13_viewport_matrix", "c14_reduced_parity", "c15_copy_guard",
	"c16_asset_paths", "c17_no_accumulation"]

var _fail := 0
var _done_cases := {}
var _sub: SubViewport
var _stack
var _t: Dictionary

func _initialize() -> void:
	await process_frame
	_t = CC.truth()
	_mount(Vector2i(1080, 2160))
	await _packs()
	await _collection()
	await _robot()
	await _gift()
	await _feature_world_generic()
	await _no_mutation()
	await _viewports()
	await _reduced()
	await _copy_and_assets()
	await _accumulation()
	_unmount()
	_finish()

# ------------------------------------------------------------------ fixtures ----

func _mount(size: Vector2i) -> void:
	_unmount()
	_sub = SubViewport.new()
	_sub.size = size
	_sub.disable_3d = true
	get_root().add_child(_sub)
	_stack = ModalStack.new()
	_sub.add_child(_stack)
	_stack.set_synthetic_safe_insets(0, 96, 0, 64)

func _unmount() -> void:
	if _sub != null and is_instance_valid(_sub):
		_sub.free()
	_sub = null
	_stack = null

func _settle() -> void:
	for _i in range(3):
		await process_frame

func _open(kind: String, fx: Dictionary, reduced := false):
	_stack.clear("t")
	await _settle()
	var p = CC.build(kind, fx, reduced)
	if p != null:
		_stack.push(p)
		CC.start_motion(p)
		await _settle()
	return p

func _all_fixtures() -> Array:
	return [["standard_pack", CC.standard_pack_fixture(_t)], ["premium_pack", CC.premium_pack_fixture(_t)],
		["set_complete", CC.set_complete_fixture(_t, 6)], ["master_complete", CC.master_fixture(_t)],
		["robot_unlock", CC.robot_fixture("Moppy")], ["gift_milestone", CC.gift_fixture(_t, 250)],
		["gift_milestone", CC.gift_fixture(_t, 1000)], ["feature_unlock", CC.feature_fixture()],
		["world_shell", CC.world_shell_fixture()],
		["generic_reward", {"title": "TASKS 3/3 COMPLETE", "rewards": {"scrub_bucks": 150, "bot_parts": 2, "standard_card_packs": 1, "random_booster_charges": 1}}]]

func _labels(p) -> Array:
	return p.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree() and not l.text.is_empty()).map(func(l): return l.text)

func _buttons(p) -> Array:
	return p.find_children("*", "Button", true, false).filter(func(b): return b.is_visible_in_tree())

func _rows(p) -> Dictionary:
	var out := {}
	for r in p.find_children("Row_*", "", true, false):
		out[r.get_meta("reward_key")] = int(r.get_meta("amount"))
	return out

# =================================================================== packs =======

func _packs() -> void:
	print("[01-04 pack opening candidates]")
	var sp = await _open("standard_pack", CC.standard_pack_fixture(_t))
	var tiles: Array = sp.find_children("CardTile_*", "", true, false)
	_ok(tiles.size() == 3 and int(_t["config"].collection_config()["standard_pack_draws"]) == 3, "Standard: exactly 3 card slots (config draws 3)")
	_ok(sp.find_child("HeroArt", true, false).texture.resource_path == CC.ART["pack_standard"], "Standard: real Standard Pack art")
	var detail: Array = []
	var ok := _tiles_ok(tiles, detail)
	var sp_buttons: String = " ".join(_buttons(sp).map(func(b): return b.text.to_upper()))
	var sp_actions: Array = sp.get_action_ids()
	_complete("c01_standard_3")
	var pp = await _open("premium_pack", CC.premium_pack_fixture(_t))
	var ptiles: Array = pp.find_children("CardTile_*", "", true, false)
	var rare_plus := ptiles.filter(func(tl): return tl.get_meta("card")["rarity"] in ["RARE", "EPIC", "LEGENDARY"]).size()
	_ok(ptiles.size() == 5 and int(_t["config"].collection_config()["premium_pack_draws"]) == 5 and rare_plus >= 1, "Premium: exactly 5 card slots, %d Rare-or-better in the fixture" % rare_plus)
	_ok(pp.find_child("HeroArt", true, false).texture.resource_path == CC.ART["pack_premium"], "Premium: real Premium Pack art")
	_complete("c02_premium_5")
	ok = _tiles_ok(ptiles, detail) and ok
	_ok(ok, "every card: catalog rarity chip + rarity frame + own art + NEW/DUPLICATE (+copies) %s" % str(detail))
	_complete("c03_rarity_new_state")
	var texts: String = sp_buttons + " " + " ".join(_buttons(pp).map(func(b): return b.text.to_upper()))
	_ok(sp_actions == ["continue"] and pp.get_action_ids() == ["continue"] and texts.find("REROLL") == -1 and texts.find("AGAIN") == -1
		and " ".join(_labels(pp)).to_upper().find("GUARANTEE") == -1, "packs: single CONTINUE, no reroll / open-again, no after-the-fact 'guaranteed' claim")
	_complete("c04_no_reroll")

func _tiles_ok(tiles: Array, detail: Array) -> bool:
	var ok := true
	for tl in tiles:
		var c: Dictionary = tl.get_meta("card")
		var rarity_chip: String = tl.find_child("Rarity", true, false).find_child("Text", true, false).text
		var state_chip: String = tl.find_child("NewState", true, false).find_child("Text", true, false).text
		var art: String = tl.find_child("CardArt", true, false).texture.resource_path
		var frame: String = tl.find_child("RarityFrame", true, false).texture.resource_path
		var truth: String = _t["catalog"].card_rarity(c["id"])
		ok = ok and rarity_chip == truth and c["rarity"] == truth and frame == CC.ART["frame_" + truth] and art == CC.card_art(c["id"]) \
			and state_chip == ("NEW" if c["new"] else "DUPLICATE") and (c["new"] or tl.find_child("Copies", true, false) != null)
		detail.append("%s %s %s" % [c["id"], rarity_chip, state_chip])
	return ok

# ============================================================== collection =======

func _collection() -> void:
	print("[05-06 collection candidates]")
	var ok := true
	for s in range(1, 16):
		var fx: Dictionary = CC.set_complete_fixture(_t, s)
		var p = await _open("set_complete", fx)
		var entry: Dictionary = (_t["config"].collection_config()["set_rewards"] as Array).filter(func(e): return int(e["set"]) == s)[0]
		ok = ok and _rows(p) == {"scrub_bucks": int(entry["scrub_bucks"]), "bot_parts": int(entry["bot_parts"])} \
			and p.find_child("SetName", true, false).text == "Set %d · %s" % [s, entry["name"]] \
			and p.find_child("Progress", true, false).text == "9 / 9 cards" and p.find_children("Thumb*", "TextureRect", true, false).size() == 9
	_ok(ok, "all 15 Set Complete fixtures show their exact configured SB + Bot Parts, name, 9/9 and 9 real card thumbs")
	var p6 = await _open("set_complete", CC.set_complete_fixture(_t, 6))
	_ok(p6.get_action_ids() == ["continue"] and p6.find_child("CommittedNote", true, false).text.find("already added") != -1, "Set Complete: one CONTINUE, reward stated as already added (no grant on tap)")
	_complete("c05_set_reward_exact")
	var m = await _open("master_complete", CC.master_fixture(_t))
	var texts: Array = m.find_children("Row_*", "", true, false).map(func(r): return r.find_child("Text", true, false).text)
	_ok(_rows(m) == {"scrub_bucks": 2500, "bot_parts": 20} and texts == ["+2,500 Scrub Bucks", "+20 Bot Parts"]
		and _t["config"].collection_config()["all_sets_complete"]["scrub_bucks"] == 2500 and _t["config"].collection_config()["all_sets_complete"]["bot_parts"] == 20,
		"Master: exactly +2,500 SB +20 Bot Parts (= config), nothing else %s" % str(texts))
	_ok(m.find_child("HeroArt", true, false).texture.resource_path == CC.ART["master_complete"], "Master: Master Collection emblem")
	_complete("c06_master_exact")

# =================================================================== robot =======

func _robot() -> void:
	print("[07 robot unlock candidate]")
	var row := CC.roster_row("Moppy")
	var fx := CC.robot_fixture("Moppy")
	var p = await _open("robot_unlock", fx)
	var perk_full := String(row["perk"]).replace("**", "")
	_ok(row["number"] == "2" and p.find_child("RobotName", true, false).text == "MOPPY" and p.find_child("RobotRole", true, false).text == row["role"],
		"name + role verbatim from OWNER_ROBOT_ROSTER_V01 (#2 Moppy)")
	_ok(perk_full == "Clean Bonus: +20% first-clear Scrub Bucks." and p.find_child("PerkName", true, false).text == "Clean Bonus"
		and p.find_child("PerkText", true, false).text == "+20% first-clear Scrub Bucks.", "canonical 20%% perk: %s" % perk_full)
	_ok(p.find_child("HeroArt", true, false).texture.resource_path == "res://assets/ui/final/characters/robots/moppy/moppy_master.png"
		and p.find_child("PartsLeft", true, false).find_child("Text", true, false).text == "Bot Parts left: 37", "canonical Moppy art + remaining Bot Parts")
	_ok(p.get_action_ids() == ["equip", "keep"] and p.get_action_button("equip").text == "EQUIP MOPPY" and p.get_action_button("keep").text == "KEEP CURRENT",
		"EQUIP (primary) + KEEP CURRENT (secondary)")
	_complete("c07_robot_roster")

# ==================================================================== gift =======

func _gift() -> void:
	print("[08 Gift milestone candidates]")
	var ok := true
	var info: Array = []
	for ms in _t["config"].gift_meter_milestones():
		var fx: Dictionary = CC.gift_fixture(_t, int(ms))
		var p = await _open("gift_milestone", fx)
		var cfg: Dictionary = _t["config"].gift_meter_milestone(int(ms))
		var want := {}
		for k in cfg:
			want[k] = int(cfg[k])   # JSON numbers arrive as float
		var fb := int(want.get("guaranteed_new_fallback_sb", 0))
		want.erase("guaranteed_new_fallback_sb")
		ok = ok and _rows(p) == want and p.find_child("Milestone", true, false).text.begins_with("Milestone %s" % _num(int(ms)))
		if fb > 0:
			ok = ok and p.find_child("FallbackNote", true, false).text.find(_num(fb)) != -1
		info.append("%d:%s" % [ms, str(_rows(p))])
	_ok(ok and _t["config"].gift_meter_milestones() == [10, 50, 250, 500, 1000], "Gift 10/50/250/500/1000 rows = exact config bundles; 1000 fallback shown as a condition, not a reward %s" % str(info))
	var big = await _open("gift_milestone", CC.gift_fixture(_t, 1000))
	var big_hero: float = big.find_child("HeroArt", true, false).custom_minimum_size.y
	var small = await _open("gift_milestone", CC.gift_fixture(_t, 250))
	var small_hero: float = small.find_child("HeroArt", true, false).custom_minimum_size.y
	_ok(big_hero > small_hero, "1000 milestone hero (%d px) larger than the small milestone (%d px)" % [big_hero, small_hero])
	_complete("c08_gift_exact")

func _num(n: int) -> String:
	return preload("res://scripts/ui/ui_text.gd").num(n)

# ========================================================== feature / world ======

func _feature_world_generic() -> void:
	print("[09-11 feature / world shell / generic reward]")
	var fx := CC.feature_fixture()
	var p = await _open("feature_unlock", fx)
	var re := RegEx.create_from_string("(?i)level\\s*\\d")
	_ok(not fx.has("level") and not fx.has("unlock_level") and _labels(p).all(func(t): return re.search(t) == null)
		and p.find_child("FixtureTag", true, false).visible and _rows(p).is_empty(), "feature: no campaign level anywhere, fixture-tagged, no reward rows")
	_complete("c09_feature_no_level")
	var wfx := CC.world_shell_fixture()
	var w = await _open("world_shell", wfx)
	var range_re := RegEx.create_from_string("\\d+\\s*[-–]\\s*\\d+")
	var joined: String = " ".join(_labels(w)).to_upper() + " " + w.get_title().to_upper()
	_ok(_labels(w).all(func(t): return range_re.search(t) == null) and joined.find("WORLD 02") == -1 and joined.find("WORLD 2") == -1
		and not wfx.has("world_id") and not wfx.has("range") and w.find_child("PreviewTag", true, false).visible
		and w.find_child("WorldArt", true, false).texture.resource_path == CC.ART["world_01"], "world shell: slots only, no range / World 02, World 01 art tagged PREVIEW HARNESS · SHELL TEST ONLY")
	_complete("c10_world_no_range")
	var keys := ["scrub_bucks", "bot_parts", "standard_card_packs", "random_booster_charges", "premium_card_packs"]
	var ok := true
	for n in range(1, 5):
		var rw := {}
		for k in keys.slice(0, n):
			rw[k] = 1
		var g = await _open("generic_reward", {"title": "REWARD", "rewards": rw})
		ok = ok and g != null and _rows(g).size() == n and g.get_action_ids() == ["continue"]
	var five := {}
	for k in keys:
		five[k] = 1
	_ok(ok and CC.generic_reward({"rewards": {}}, false) == null and CC.generic_reward({"rewards": five}, false) == null, "generic reward: 1..4 rows build, 0 and 5 are refused")
	_complete("c11_generic_1_to_4")

# ============================================================== no mutation ======

func _no_mutation() -> void:
	print("[12 previews never mutate economy / progression / save]")
	var path := "user://m43c005_preview_%d.save" % Time.get_ticks_usec()
	var app := AppState.new(path, func(): return 1_900_000_000)   # fixed clock: Heart anchor / 2x high-water never drift
	app.request_save()
	var eco0: Dictionary = app.economy.snapshot()
	var prog0: Dictionary = app.progression.snapshot()
	var bytes0 := FileAccess.get_file_as_bytes(path)
	for f in _all_fixtures():
		var p = await _open(f[0], f[1])
		for id in p.get_action_ids():
			p.rearm()
			p.get_action_button(id).pressed.emit()   # inert: a candidate action only closes
		await _settle()
	_ok(app.economy.snapshot() == eco0 and app.progression.snapshot() == prog0 and FileAccess.get_file_as_bytes(path) == bytes0, "economy / progression snapshots and save bytes unchanged after opening every candidate and pressing every action")
	var src := FileAccess.get_file_as_string("res://tests/tools/ceremony_preview/ceremony_candidates.gd")
	var forbidden := ["open_standard(", "open_premium(", "add_card(", "add_copies(", ".unlock(", "claim(", "claim_", "grant(", "redeem_", "credit(", "debit(", "request_save(", "AppState.new("]
	var hits := forbidden.filter(func(s): return src.find(s) != -1)
	_ok(hits.is_empty(), "harness source calls no grant / open / unlock / claim / wallet / save API %s" % str(hits))
	var scripts_ref := false
	for d in ["res://scripts"]:
		scripts_ref = scripts_ref or _dir_mentions(d, "ceremony_preview")
	_ok(not scripts_ref, "no shipping script under scripts/ references the preview harness")
	app.economy.dispose()
	for sfx in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + sfx):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path + sfx))
	_complete("c12_no_mutation")

func _dir_mentions(dir: String, needle: String) -> bool:
	var d := DirAccess.open(dir)
	if d == null:
		return false
	for f in d.get_files():
		if f.ends_with(".gd") and FileAccess.get_file_as_string(dir + "/" + f).find(needle) != -1:
			return true
	for sub in d.get_directories():
		if _dir_mentions(dir + "/" + sub, needle):
			return true
	return false

# ============================================================ viewport matrix ====

func _viewports() -> void:
	print("[13 shared family fits all five viewports]")
	var bad: Array = []
	for sz in SIZES:
		_mount(sz)
		var safe := Rect2(Vector2(0, 96), Vector2(sz) - Vector2(0, 160))
		for f in _all_fixtures():
			var p = await _open(f[0], f[1])
			if not (p.text_fits() and safe.encloses(p.get_frame_rect())):
				bad.append("%dx%d %s frame %s" % [sz.x, sz.y, p.popup_id, str(p.get_frame_rect())])
			for b in _buttons(p):
				if b.size.y < UiTokens.TOUCH_MIN:
					bad.append("%dx%d %s touch %s" % [sz.x, sz.y, p.popup_id, b.name])
			for tl in p.find_children("CardTile_*", "", true, false):
				if not p.get_frame_rect().encloses(tl.get_global_rect()):
					bad.append("%dx%d %s card %s outside frame" % [sz.x, sz.y, p.popup_id, tl.name])
	_mount(Vector2i(1080, 2160))
	_ok(bad.is_empty(), "10 candidates x 5 viewports: frame in safe area, no clipped text, CTAs >= %d px, cards inside the frame %s" % [UiTokens.TOUCH_MIN, str(bad)])
	_complete("c13_viewport_matrix")

func _reduced() -> void:
	print("[14 Reduced Effects: identical information, no motion]")
	var ok := true
	var still := true
	for f in _all_fixtures():
		var n = await _open(f[0], f[1], false)
		var nl := _labels(n)
		var nb := _buttons(n).map(func(b): return b.text)
		var moving: bool = n.find_children("*", "", true, false).any(func(x): return x.has_meta("spin") or x.has_meta("flip_delay")) or f[0] in ["generic_reward", "world_shell"]
		var r = await _open(f[0], f[1], true)
		ok = ok and _labels(r) == nl and _buttons(r).map(func(b): return b.text) == nb
		still = still and moving and not r.find_children("*", "", true, false).any(func(x): return x.has_meta("spin") or x.has_meta("flip_delay"))
		for face in r.find_children("Face", "Control", true, false):
			still = still and face.scale == Vector2.ONE
	_ok(ok, "every candidate: Reduced Effects labels + actions identical to the animated version")
	_ok(still, "Reduced Effects: no glow spin / card flip, cards face-up immediately (animated versions do move)")
	_complete("c14_reduced_parity")

# ============================================================ copy / assets ======

func _copy_and_assets() -> void:
	print("[15-16 copy guard / asset paths]")
	var hits: Array = []
	var paths := {}
	for f in _all_fixtures():
		var p = await _open(f[0], f[1])
		var all: String = (" ".join(_labels(p)) + " " + p.get_title() + " " + " ".join(_buttons(p).map(func(b): return b.text))).to_upper()
		for w in BANNED:
			if all.find(w) != -1:
				hits.append("%s:%s" % [p.popup_id, w])
		for t in p.find_children("*", "TextureRect", true, false):
			if t.texture != null and String(t.texture.resource_path) != "":
				paths[t.texture.resource_path] = true
	_ok(hits.is_empty(), "no jackpot / near-miss / urgency / odds / reroll copy %s" % str(hits))
	_complete("c15_copy_guard")
	var missing: Array = []
	for k in CC.ART:
		if not FileAccess.file_exists(CC.ART[k]):
			missing.append(CC.ART[k])
	for p in paths:
		if not FileAccess.file_exists(p) or not String(p).begins_with("res://assets/ui/final/"):
			missing.append(p)
	for s in range(1, 16):
		for k in range(9):
			if not FileAccess.file_exists(CC.card_art("s%d_c%d" % [s, k])):
				missing.append(CC.card_art("s%d_c%d" % [s, k]))
	var no_icon: Array = CC.REWARD_ROWS.keys().filter(func(k): return CC.REWARD_ROWS[k][0] == "")
	_ok(missing.is_empty() and paths.size() >= 25, "%d bound textures + 135 card arts all exist under assets/ui/final" % paths.size())
	_ok(no_icon == ["selected_booster_charges"], "explicitly recorded missing art: %s (native '?' chip, see inventory)" % str(no_icon))
	_complete("c16_asset_paths")

# ============================================================== lifecycle ========

func _accumulation() -> void:
	print("[17 repeated open / close]")
	_stack.clear("t")
	await _settle()
	await _open("premium_pack", CC.premium_pack_fixture(_t))
	_stack.clear("t")
	await _settle()
	var n0 := _count(_sub)
	var tw0 := get_processed_tweens().size()
	var c0: int = _stack.modal_changed.get_connections().size()
	for _i in range(20):
		for f in _all_fixtures():
			var p = CC.build(f[0], f[1], false)
			_stack.push(p)
			CC.start_motion(p)
			await process_frame
			_stack.clear("t")
	await _settle()
	_ok(_count(_sub) == n0 and get_processed_tweens().size() <= tw0 and _stack.modal_changed.get_connections().size() == c0,
		"20 x 10 candidates opened / closed: nodes %d -> %d, tweens and connections stable" % [n0, _count(_sub)])
	_complete("c17_no_accumulation")

func _count(n: Node) -> int:
	return n.find_children("*", "", true, false).filter(func(c): return not c.is_queued_for_deletion()).size()

# ------------------------------------------------------------------ helpers ----

func _ok(cond: bool, msg: String) -> void:
	if cond:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _complete(id: String) -> void:
	_done_cases[id] = true

func _finish() -> void:
	var missing := EXPECTED.filter(func(c): return not _done_cases.has(c))
	if not missing.is_empty():
		_fail += 1
		print("  FAIL: case ledger incomplete %s" % str(missing))
	print("M43-C005-C001 ceremony visual masters: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _done_cases.size(), EXPECTED.size(), _fail])
	quit(1 if _fail > 0 else 0)
