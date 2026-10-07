extends Node
## HttpsContentTransport — preload (res://scripts/content_runtime/https_content_transport.gd).
##
## Production RemoteContent transport (CP04-001/011). Implements the provider-neutral
## transport seam the RemoteContentManager awaits:
##   fetch_manifest() -> {ok, reason, bytes}
##   fetch_object(object_key, part_path, max_bytes) -> {ok, reason}   (writes the .part file)
## HTTPS GET only, certificate-validated (Godot default TLS client), redirects are never
## followed (max_redirects = 0, so a redirect can never downgrade to HTTP), bounded body,
## timeout. Carries no credential, token or upload authority: the URLs come from the
## non-secret runtime config. Must be in the scene tree (HTTPRequest is a Node).

var manifest_url := ""
var object_base_url := ""
var timeout_s := 20.0
var max_manifest_bytes := 1_048_576

func _init(manifest: String = "", object_base: String = "", timeout: float = 20.0) -> void:
	name = "HttpsContentTransport"
	manifest_url = manifest
	object_base_url = object_base.trim_suffix("/")
	timeout_s = timeout

## HTTPS-only URL gate: scheme https, non-empty host, no userinfo/credentials, no
## whitespace, no query/fragment (provider-neutral object keys never carry them).
static func is_safe_https_url(url: String) -> bool:
	if not url.begins_with("https://") or url.length() > 2048:
		return false
	var rest := url.substr(8)
	var host := rest.get_slice("/", 0)
	if host.is_empty() or host.contains("@"):
		return false
	for ch in [" ", "\t", "\n", "\r", "?", "#", "\\"]:
		if url.contains(ch):
			return false
	return true

func fetch_manifest() -> Dictionary:
	if not is_safe_https_url(manifest_url):
		return {"ok": false, "reason": "TRANSPORT_URL_REJECTED", "bytes": PackedByteArray()}
	var r: Dictionary = await _http_get(manifest_url, max_manifest_bytes, "")
	return r

func fetch_object(object_key: String, part_path: String, max_bytes: int) -> Dictionary:
	var url := object_base_url + "/" + object_key
	if not is_safe_https_url(object_base_url) or not is_safe_https_url(url):
		return {"ok": false, "reason": "TRANSPORT_URL_REJECTED"}
	var r: Dictionary = await _http_get(url, max_bytes, part_path)
	r.erase("bytes")
	return r

func _http_get(url: String, max_bytes: int, download_file: String) -> Dictionary:
	var req := HTTPRequest.new()
	req.max_redirects = 0
	req.body_size_limit = max_bytes
	req.timeout = timeout_s
	req.download_file = download_file
	add_child(req)
	var err := req.request(url, PackedStringArray(), HTTPClient.METHOD_GET)
	if err != OK:
		req.queue_free()
		return {"ok": false, "reason": "TRANSPORT_REQUEST_FAILED", "bytes": PackedByteArray()}
	var res: Array = await req.request_completed
	req.queue_free()
	var result: int = res[0]
	var code: int = res[1]
	if result == HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
		return {"ok": false, "reason": "TRANSPORT_TOO_LARGE", "bytes": PackedByteArray()}
	if result == HTTPRequest.RESULT_TIMEOUT:
		return {"ok": false, "reason": "TRANSPORT_TIMEOUT", "bytes": PackedByteArray()}
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "reason": "TRANSPORT_OFFLINE", "bytes": PackedByteArray()}
	if code != 200:
		return {"ok": false, "reason": "TRANSPORT_HTTP_%d" % code, "bytes": PackedByteArray()}
	return {"ok": true, "reason": "OK", "bytes": res[3]}
