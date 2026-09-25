extends SceneTree
## M42-C001 — opening cinematic evidence (SB-M42-026..033). Later tasks append cases.
## Expected/completed case ledger (AL-091).
##
## Run: godot --headless --path . -s res://tests/m42_opening.gd

const MP4 := "res://assets/brand/opening/final_15_seconds_opening_video.mp4"
const MP4_SHA256 := "c044841d4aad1bc97c3d2bd144468c44f514bc2e288a970ae0a6aa14191f4388"
const OGV := "res://assets/brand/opening/scrubbots_opening_720p30.ogv"
const OGV_SHA256 := "3ec6e1347bbb1d8ced2709f3383b06ae6dbfba017e0a6d23a0fb991ec78ee89a"

var EXPECTED_CASES := ["mp4_preserved", "ogv_runtime_asset"]

var _fail := 0
var _completed: Dictionary = {}

func _initialize() -> void:
	await process_frame
	_mp4_preserved()
	_ogv_runtime_asset()
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

## SB-M42-027: Ogg Theora + Vorbis 720p30 runtime derivative, recorded command.
func _ogv_runtime_asset() -> void:
	print("[ogv runtime asset]")
	_ok(FileAccess.file_exists(OGV) and FileAccess.get_sha256(OGV) == OGV_SHA256, "OGV exists with recorded SHA-256")
	var b := FileAccess.get_file_as_bytes(OGV)
	_ok(b.slice(0, 4).get_string_from_ascii() == "OggS", "Ogg container")
	var raw := b.slice(0, 8192)
	_ok(_find(raw, "theora".to_ascii_buffer()) != -1 and _find(raw, "vorbis".to_ascii_buffer()) != -1, "Theora + Vorbis stream headers present")
	var th := _find(raw, PackedByteArray([0x80]) + "theora".to_ascii_buffer())
	if th >= 0:
		var fmbw := (raw[th + 10] << 8) | raw[th + 11]
		var fmbh := (raw[th + 12] << 8) | raw[th + 13]
		var picw := (raw[th + 14] << 16) | (raw[th + 15] << 8) | raw[th + 16]
		var pich := (raw[th + 17] << 16) | (raw[th + 18] << 8) | raw[th + 19]
		var frn := (raw[th + 22] << 24) | (raw[th + 23] << 16) | (raw[th + 24] << 8) | raw[th + 25]
		var frd := (raw[th + 26] << 24) | (raw[th + 27] << 16) | (raw[th + 28] << 8) | raw[th + 29]
		_ok(picw == 1280 and pich == 720, "Theora picture 1280x720 (%dx%d, frame %dx%d MBs)" % [picw, pich, fmbw, fmbh])
		_ok(frd > 0 and frn / frd == 30 and frn % frd == 0, "Theora frame rate 30/1 (%d/%d)" % [frn, frd])
	else:
		_ok(false, "Theora identification header found")
	var s = load(OGV)
	_ok(s is VideoStreamTheora, "Godot imports it as VideoStreamTheora (%s)" % (s.get_class() if s else "null"))
	_ok(FileAccess.get_sha256(MP4) == MP4_SHA256, "MP4 master unchanged after conversion")
	var prov := FileAccess.get_file_as_string("res://assets/brand/opening/PROVENANCE.md")
	_ok(prov.find("-c:v libtheora -q:v 8") != -1 and prov.find("ffmpeg 9.0.1") != -1 and prov.find(OGV_SHA256) != -1, "exact command, tool version and hash recorded")
	_complete("ogv_runtime_asset")

func _find(hay: PackedByteArray, needle: PackedByteArray) -> int:
	for i in range(hay.size() - needle.size()):
		var hit := true
		for k in range(needle.size()):
			if hay[i + k] != needle[k]:
				hit = false
				break
		if hit:
			return i
	return -1

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
