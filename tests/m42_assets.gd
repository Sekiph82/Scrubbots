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
	_ok(approved == 0, "no asset is currently APPROVED in the manifest (owner approval pending)")
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
		["APPROVED without hash", func(m): m["assets"][0]["status"] = "APPROVED", "approved_sha256"],
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
	_ok(required == 49, "49 generation_required ART targets in the manifest (%d)" % required)
	_ok(missing.is_empty(), "all generation targets already exist -> no generation needed %s" % str(missing))
	_ok(sizes_ok, "existing targets are real images (> 1 KiB)")
	_ok(approved == 0, "none approved -> OWNER_ASSET_APPROVAL_REQUIRED before binding")
	_complete("generation_inventory")

const HomeArtBinder = preload("res://scripts/ui/home/home_art_binder.gd")

## SB-M42-016: only owner-APPROVED, hash-pinned final assets can bind.
func _lifecycle_gate() -> void:
	print("[lifecycle gate]")
	var b = HomeArtBinder.new()
	_ok(b.is_manifest_valid() and b.summary() == {"NOT_APPROVED": 50}, "real manifest: all 50 ART entries NOT_APPROVED (%s)" % str(b.summary()))
	var any_tex := false
	for a in V.load_manifest()["assets"]:
		if a["kind"] == "ART" and b.texture(a["slug"]) != null:
			any_tex = true
	_ok(not any_tex, "no Home texture binds while unapproved")
	_ok(b.state("nope") == "UNKNOWN" and b.texture("nope") == null, "unknown slug -> null")
	var m = V.load_manifest()
	m["assets"][0]["status"] = "APPROVED"
	m["assets"][0]["approved_sha256"] = FileAccess.get_sha256("res://" + m["assets"][0]["path"])
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
