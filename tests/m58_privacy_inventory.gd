extends SceneTree
## SB-M58-001..006 — privacy inventory guard. Static scan: every network / native-permission
## API use in game scripts and scenes, every `user://` path, every addon, every Android
## permission and every iOS privacy/capability key must be listed in
## docs/PRIVACY_DATA_INVENTORY.md; the committed project.godot must not load the editor-only
## Godot AI plugin. A scanner self-check proves the patterns fire.
##
## Run: godot --headless --path . -s res://tests/m58_privacy_inventory.gd

const DOC := "res://docs/PRIVACY_DATA_INVENTORY.md"
const ANDROID_PRESET := "res://.github/android/export_presets_family_first10.cfg"
const IOS_WORKFLOW := "res://.github/workflows/ios-ipa.yml"
const ROOTS := ["res://scripts", "res://scenes", "res://addons"]
## Owner-local editor plugin, untracked, never in a build (the inventory says so).
const SKIP_DIRS := ["res://addons/godot_ai"]
const NET_PATTERN := "\\b(HTTPRequest|HTTPClient|StreamPeerTCP|StreamPeerTLS|TCPServer|UDPServer|PacketPeerUDP|PacketPeerDTLS|DTLSServer|WebSocketPeer|WebSocketMultiplayerPeer|WebRTCPeerConnection|WebRTCMultiplayerPeer|ENetConnection|ENetMultiplayerPeer|JavaScriptBridge|JavaClassWrapper|IP\\.resolve_hostname|OS\\.shell_open|Engine\\.get_singleton|OS\\.request_permission|OS\\.request_permissions)\\b"

var EXPECTED_CASES := ["scanner_self_check", "android_permissions", "ios_privacy_keys", "network_usage", "user_paths", "addons", "godot_ai_not_loaded"]

var _fail := 0
var _completed: Dictionary = {}
var _doc := ""
var _net := RegEx.new()
var _user := RegEx.new()

func _initialize() -> void:
	_net.compile(NET_PATTERN)
	_user.compile("\"(user://[^\"]*)\"")
	_doc = FileAccess.get_file_as_string(DOC)
	_check(not _doc.is_empty(), "inventory doc readable")
	var files: Array = []
	for r in ROOTS:
		_walk(r, files)
	_check(files.size() > 100, "scanned %d game files" % files.size())

	_case("scanner_self_check")
	_check(_net_hits("\tvar r := HTTPRequest.new()").size() == 1, "self: HTTPRequest detected")
	_check(_net_hits("## HTTPRequest in a comment").is_empty(), "self: comment ignored")
	_check(_net_hits("OS.request_permission(P)").size() == 1, "self: request_permission detected")
	_check(_user_paths("var p := \"user://x.dat\"") == ["user://x.dat"], "self: user path detected")
	_check(_android_permissions("permissions/vibrate=true\npermissions/camera=false\npermissions/custom_permissions=PackedStringArray(\"a.B\")") == ["permissions/vibrate", "a.B"], "self: android permissions parsed")
	_check(_ios_keys("  privacy/camera_usage_description=\"x\"\n  capabilities/push_notifications=false\n  application/bundle_identifier=\"y\"") == ["privacy/camera_usage_description"], "self: ios keys parsed")
	_check(not _listed("permissions/camera"), "self: unlisted item reported")

	_case("android_permissions")
	var perms := _android_permissions(FileAccess.get_file_as_string(ANDROID_PRESET))
	_check(perms.size() >= 1, "android preset parsed (%s)" % [perms])
	for p in perms:
		_check(_listed(p), "android permission listed: " + p)

	_case("ios_privacy_keys")
	var ios := FileAccess.get_file_as_string(IOS_WORKFLOW)
	_check(ios.contains("platform=\"iOS\""), "ios preset found")
	for k in _ios_keys(ios):
		_check(_listed(k), "ios key listed: " + k)

	_case("network_usage")
	for f in files:
		var hits := _net_hits(FileAccess.get_file_as_string(f))
		if not hits.is_empty():
			_check(_listed(String(f).trim_prefix("res://")), "network/native use listed: %s %s" % [f, hits])

	_case("user_paths")
	for f in files:
		if String(f).get_extension() == "gd":
			for u in _user_paths(FileAccess.get_file_as_string(f)):
				_check(_listed(u), "user:// path listed: %s (%s)" % [u, f])

	_case("addons")
	var d := DirAccess.open("res://addons")
	for a in d.get_directories():
		_check(_listed("addons/" + a), "addon listed: " + a)

	_case("godot_ai_not_loaded")
	_check(not FileAccess.get_file_as_string("res://project.godot").contains("godot_ai"), "project.godot does not load addons/godot_ai")

	print("M58 privacy inventory evidence: %s (%d/%d cases, %d fail)" % ["PASS" if _fail == 0 and _completed.size() == EXPECTED_CASES.size() else "FAIL", _completed.size(), EXPECTED_CASES.size(), _fail])
	quit(1 if _fail > 0 else 0)

func _walk(dir: String, out: Array) -> void:
	if dir in SKIP_DIRS:
		return
	var d := DirAccess.open(dir)
	if d == null:
		return
	for f in d.get_files():
		if f.get_extension() in ["gd", "tscn"]:
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		_walk(dir.path_join(sub), out)

func _net_hits(text: String) -> Array:
	var hits: Array = []
	for line in text.split("\n"):
		if line.strip_edges().begins_with("#"):
			continue
		for m in _net.search_all(line):
			if not hits.has(m.get_string(1)):
				hits.append(m.get_string(1))
	return hits

func _user_paths(text: String) -> Array:
	var out: Array = []
	for m in _user.search_all(text):
		if not out.has(m.get_string(1)):
			out.append(m.get_string(1))
	return out

## Enabled `permissions/<name>=true` lines plus every entry of custom_permissions.
func _android_permissions(text: String) -> Array:
	var out: Array = []
	for line in text.split("\n"):
		line = line.strip_edges()
		if line.begins_with("permissions/custom_permissions="):
			for p in line.get_slice("=", 1).trim_prefix("PackedStringArray(").trim_suffix(")").split(",", false):
				out.append(p.strip_edges().trim_prefix("\"").trim_suffix("\""))
		elif line.begins_with("permissions/") and line.ends_with("=true"):
			out.append(line.get_slice("=", 0))
	return out

## Set iOS privacy/capability/entitlement/plist keys (false/empty values are not requests).
func _ios_keys(text: String) -> Array:
	var out: Array = []
	for line in text.split("\n"):
		line = line.strip_edges()
		var k := line.get_slice("=", 0)
		var v := line.substr(k.length() + 1)
		if (k.begins_with("privacy/") or k.begins_with("capabilities/") or k.begins_with("entitlements/") \
				or k == "application/additional_plist_content") and line.contains("=") and v not in ["false", "\"\"", ""]:
			out.append(k)
	return out

func _listed(item: String) -> bool:
	return _doc.contains("`" + item + "`") or _doc.contains("`" + item + "/`")

func _case(name: String) -> void:
	_completed[name] = true

func _check(ok: bool, msg: String) -> void:
	if ok:
		print("  ok   " + msg)
	else:
		_fail += 1
		print("  FAIL " + msg)
