extends SceneTree
## M42-C001 — Home asset manifest / lifecycle evidence (SB-M42-013/014/016/017).
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_assets.gd

const V = preload("res://scripts/tools/home_asset_manifest_validator.gd")

var EXPECTED_CASES := ["manifest_valid", "manifest_adversarial", "generation_inventory", "lifecycle_gate"]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_manifest_valid()
	_manifest_adversarial()
	_generation_inventory()
	_lifecycle_gate()
	_done()

func _manifest_valid() -> void:
	print("[manifest valid]")
	var m = V.load_manifest()
	var r: Dictionary = V.validate(m)
	_ok(r["ok"], "real HOME_ASSET_MANIFEST validates (errors: %s)" % str(r["errors"]))
	_ok(r["reuse"] == {"HOME-087": "HOME-042"}, "only declared reuse: HOME-087 -> HOME-042 (%s)" % str(r["reuse"]))
	_ok(r["warnings"].size() == 1 and String(r["warnings"][0]).begins_with("HOME-110"), "fx_star_burst reported as decorative star-shaped FX warning only")
	var approved := 0
	for a in m["assets"]:
		if a["status"] == "APPROVED":
			approved += 1
	_ok(approved == 51, "owner-approved production state: 51 ART entries APPROVED (49 unique + HOME-087 reuse + V04 HOME-120 World 01) (%d)" % approved)
	var sha_042 := ""
	var sha_087 := ""
	var pins_ok := true
	for a in m["assets"]:
		if a["status"] == "APPROVED":
			var want := String(a.get("approved_sha256", ""))
			var got := FileAccess.get_sha256("res://" + String(a["path"]))
			pins_ok = pins_ok and want.length() == 64 and want == want.to_lower() and want == got
			if a["id"] == "HOME-042":
				sha_042 = want
			if a["id"] == "HOME-087":
				sha_087 = want
	_ok(pins_ok, "every approved_sha256 is 64-char lowercase and equals the actual file bytes")
	_ok(sha_087 == sha_042 and sha_042.length() == 64, "HOME-087 reuse carries HOME-042's pin")
	_complete("manifest_valid")

func _mut(fn: Callable) -> Dictionary:
	var m = V.load_manifest()
	fn.call(m)
	return V.validate(m)

func _has(r: Dictionary, needle: String) -> bool:
	for e in r["errors"]:
		if String(e).find(needle) != -1:
			return true
	return false

func _manifest_adversarial() -> void:
	print("[manifest adversarial]")
	var cases := [
		["duplicate id", func(m): m["assets"][1]["id"] = m["assets"][0]["id"], "duplicate id"],
		["duplicate slug", func(m): m["assets"][1]["slug"] = m["assets"][0]["slug"], "duplicate slug"],
		["bad slug case", func(m): m["assets"][0]["slug"] = "Home_BG", "snake_case"],
		["unknown kind", func(m): m["assets"][0]["kind"] = "PHOTO", "unknown kind"],
		["kind/impl mismatch", func(m): m["assets"][0]["implementation"] = "live_godot_ui", "invalid for kind"],
		["bad status", func(m): m["assets"][0]["status"] = "DONE", "unknown status"],
		["provider order", func(m): m["assets"][0]["provider"] = "magnific", "provider must be"],
		["fallback order", func(m): m["assets"][0]["fallback_providers"] = ["chatgpt_image_generation"], "fallback_providers"],
		["path outside final", func(m): m["assets"][0]["path"] = "assets/ui/generated/x.png", "ART path must"],
		["non-reuse duplicate path", func(m): m["assets"][1]["path"] = m["assets"][0]["path"], "duplicate final path"],
		["LIVE with baked image", func(m): m["assets"][7]["path"] = "assets/ui/final/home/area_title.png", "no baked live text"],
		["Star currency slug", func(m): m["assets"][45]["slug"] = "currency_star_amount", "banned Economy V1 token 'star'"],
		["Event Points path", func(m): m["assets"][0]["path"] = "assets/ui/final/home/event_points_bar.png", "banned Economy V1 token"],
		["profile XP", func(m): m["assets"][40]["slug"] = "profile_xp_values", "banned Economy V1 token"],
		["coin icon", func(m): m["assets"][41]["slug"] = "icon_currency_coin", "banned Economy V1 token 'coin'"],
		["APPROVED without hash", func(m):
			m["assets"][0]["status"] = "APPROVED"
			m["assets"][0].erase("approved_sha256"), "approved_sha256"],
		["APPROVED hash mismatch", func(m):
			m["assets"][0]["status"] = "APPROVED"
			m["assets"][0]["approved_sha256"] = "0".repeat(64), "approved asset changed on disk"],
		["missing Scrub Bucks icon", func(m): m["assets"].remove_at(41), "icon_currency_scrub_bucks"],
		["not an object", null, "not an object"],
	]
	for c in cases:
		var r: Dictionary
		if c[1] == null:
			r = V.validate([1, 2])
		else:
			r = _mut(c[1])
		_ok(not r["ok"] and _has(r, c[2]), "rejects %s (%s)" % [c[0], str(r["errors"]).left(160)])
	# Positive APPROVED path: correct hash validates.
	var m = V.load_manifest()
	m["assets"][0]["status"] = "APPROVED"
	m["assets"][0]["approved_sha256"] = FileAccess.get_sha256("res://" + m["assets"][0]["path"])
	_ok(V.validate(m)["ok"], "APPROVED with matching sha256 validates")
	_complete("manifest_adversarial")

## SB-M42-014: inspect before generating. Every generation_required Home ART target
## already exists on disk (Codex visual batch 47b4343/3012ebb/03109d2), so nothing is
## generated; none of them is APPROVED, so none may bind (OWNER_ASSET_APPROVAL_REQUIRED).
func _generation_inventory() -> void:
	print("[generation inventory]")
	var m = V.load_manifest()
	var required := 0
	var missing: Array = []
	var approved := 0
	var sizes_ok := true
	for a in m["assets"]:
		if a.get("kind") == "ART" and a.get("generation_required") == true:
			required += 1
			var p := "res://" + String(a["path"])
			if not FileAccess.file_exists(p):
				missing.append(a["id"])
			elif FileAccess.get_file_as_bytes(p).size() < 1024:
				sizes_ok = false
			if a.get("status") == "APPROVED":
				approved += 1
	_ok(required == 50, "50 generation_required ART targets in the manifest (49 + V04 World 01) (%d)" % required)
	_ok(missing.is_empty(), "all generation targets already exist -> no generation needed %s" % str(missing))
	_ok(sizes_ok, "existing targets are real images (> 1 KiB)")
	_ok(approved == 50, "all 50 generation targets owner-APPROVED (OWNER_M42_HOME_ART_COMPLETE_APPROVAL_V01 + OWNER_M42_HOME_REBUILD_V04 for HOME-120); nothing generated by Claude")
	_complete("generation_inventory")

const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")

## SB-M42-016: only owner-APPROVED, hash-pinned final assets can bind.
func _lifecycle_gate() -> void:
	print("[lifecycle gate]")
	var b = HomeArtBinder.new()
	_ok(b.is_manifest_valid() and b.summary() == {"APPROVED_BOUND": 51}, "real manifest: all 51 ART entries APPROVED_BOUND (%s)" % str(b.summary()))
	var any_tex := false
	for a in V.load_manifest()["assets"]:
		if a["kind"] == "ART" and b.texture(a["slug"]) != null:
			any_tex = true
	var all_tex := true
	for a in V.load_manifest()["assets"]:
		if a["kind"] == "ART" and b.texture(a["slug"]) == null:
			all_tex = false
	_ok(any_tex and all_tex, "every approved Home ART texture binds")
	var m0 = V.load_manifest()
	m0["assets"][0]["status"] = "PLANNED"
	m0["assets"][0].erase("approved_sha256")
	var b0 = HomeArtBinder.new(m0)
	_ok(b0.state("home_bg_sky") == "NOT_APPROVED" and b0.texture("home_bg_sky") == null and b0.texture("home_bg_city_far") != null, "an entry reverted to unapproved stops binding; others unaffected")
	var protected_all := true
	for a in V.load_manifest()["assets"]:
		if a["kind"] == "ART" and b.can_write(String(a["path"])):
			protected_all = false
	_ok(protected_all and b.can_write("assets/ui/generated/home/new_candidate.png"), "every approved final path is write-protected; a new candidate path is not")
	_ok(b.state("nope") == "UNKNOWN" and b.texture("nope") == null, "unknown slug -> null")
	var m = V.load_manifest()
	m["assets"][0]["status"] = "APPROVED"
	m["assets"][0]["approved_sha256"] = FileAccess.get_sha256("res://" + m["assets"][0]["path"])
	m["assets"][1]["status"] = "PLANNED"
	m["assets"][1].erase("approved_sha256")
	var b2 = HomeArtBinder.new(m)
	_ok(b2.state("home_bg_sky") == "APPROVED_BOUND" and b2.texture("home_bg_sky") != null, "owner-approved + hash-pinned asset binds")
	_ok(not b2.can_write(m["assets"][0]["path"]) and b2.can_write(m["assets"][1]["path"]), "approved final path is write-protected; unapproved is not")
	var m3 = V.load_manifest()
	m3["assets"][0]["status"] = "APPROVED"
	m3["assets"][0]["approved_sha256"] = "f".repeat(64)
	var b3 = HomeArtBinder.new(m3)
	_ok(b3.texture("home_bg_sky") == null and not b3.is_manifest_valid(), "silently changed approved file -> manifest invalid, nothing binds")
	var m4 = V.load_manifest()
	m4["assets"][0]["status"] = "APPROVED"
	m4["assets"][0]["path"] = "assets/ui/generated/home/home_bg_sky.png"
	var b4 = HomeArtBinder.new(m4)
	_ok(b4.texture("home_bg_sky") == null and b4.state("home_bg_sky") == "MANIFEST_INVALID", "generated candidate path can never bind")
	var m5 = V.load_manifest()
	m5["assets"][2]["id"] = m5["assets"][1]["id"]
	m5["assets"][0]["status"] = "APPROVED"
	m5["assets"][0]["approved_sha256"] = FileAccess.get_sha256("res://" + m5["assets"][0]["path"])
	_ok(HomeArtBinder.new(m5).texture("home_bg_sky") == null, "any manifest error blocks all binding")
	_complete("lifecycle_gate")

func _complete(c: String) -> void:
	_completed[c] = true

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	var missing: Array = []
	for c in EXPECTED_CASES:
		if not _completed.has(c):
			missing.append(c)
	for c in missing:
		print("  FAIL: sub-test did not complete: %s" % c)
	_fail += missing.size()
	print("M42 assets cases completed: %d/%d" % [EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size()])
	print("M42 assets evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
