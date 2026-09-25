extends SceneTree
## M42-C001 — opening cinematic evidence (SB-M42-026..033). Later tasks append cases.
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_opening.gd

const MP4 := "res://assets/brand/opening/final_15_seconds_opening_video.mp4"
const MP4_SHA256 := "c044841d4aad1bc97c3d2bd144468c44f514bc2e288a970ae0a6aa14191f4388"

var EXPECTED_CASES := ["mp4_preserved"]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_mp4_preserved()
	_done()

## SB-M42-026: owner MP4 preserved byte-exact with provenance.
func _mp4_preserved() -> void:
	print("[mp4 preserved]")
	_ok(FileAccess.file_exists(MP4), "canonical MP4 path exists")
	_ok(FileAccess.get_sha256(MP4) == MP4_SHA256, "SHA-256 matches recorded provenance")
	_ok(FileAccess.get_file_as_bytes(MP4).size() == 25234301, "size 25,234,301 bytes")
	var prov := FileAccess.get_file_as_string("res://assets/brand/opening/PROVENANCE.md")
	_ok(prov.find(MP4_SHA256) != -1 and prov.find("1280x720") != -1 and prov.find("44,100 Hz") != -1, "PROVENANCE.md records hash, dimensions and audio")
	_complete("mp4_preserved")

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
	print("M42 opening cases completed: %d/%d" % [EXPECTED_CASES.size() - missing.size(), EXPECTED_CASES.size()])
	print("M42 opening evidence: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
