extends RefCounted
## Test-only deterministic remote-content fixture builder (CP04/CP05). Never shipped.
## Builds canonical `.scrubpack` V1 bytes the same way the Level Factory builder does
## (ZIP STORED, Unix 0644 regular files, DOS epoch, no extras/comments, pack.json first,
## levels in ASCII order, each level.json / supply-plan.json / metadata.json), a matching
## Content Manifest V1, and an injectable fake transport. `zip_opts` lets tests forge
## hostile archives (symlink / executable / encrypted / deflated / traversal names ...).

const ContentManifestV1 = preload("res://scripts/content_runtime/content_manifest_v1.gd")
## Unix regular file mode 0o100644 in the external-attribute high 16 bits.
const UNIX_REG_0644 := 0x81A4 << 16

## Synthetic remote level: a builtin production level + supply plan re-identified as `id`,
## plus LF-schema approved metadata. Returns {level, supply_plan, metadata} -> bytes.
static func level_files(id: String, builtin_id: String) -> Dictionary:
	var level_txt := FileAccess.get_file_as_string("res://data/levels/%s.json" % builtin_id)
	var plan_txt := FileAccess.get_file_as_string("res://data/levels/supply/%s_supply_v1.json" % builtin_id)
	var quoted := "\"%s\"" % builtin_id
	level_txt = level_txt.replace(quoted, "\"%s\"" % id)
	plan_txt = plan_txt.replace(quoted, "\"%s\"" % id)
	var lv = JSON.parse_string(level_txt)
	var pl = JSON.parse_string(plan_txt)
	var w := int(lv["width"])
	var h := int(lv["height"])
	var md := {"schema": "scrubbots.level.metadata.v1", "version": 1, "builderVersion": "cp04-fixture/v1", "id": id,
		"width": w, "height": h, "cellCount": w * h, "difficulty": String(lv["difficulty"]),
		"columnCount": int(pl["columnCount"]), "visiblePreviewDepth": 3,
		"fileDigests": {"level": ContentManifestV1.sha256_hex(level_txt.to_utf8_buffer())}}
	return {"level": level_txt.to_utf8_buffer(), "supply_plan": plan_txt.to_utf8_buffer(),
		"metadata": JSON.stringify(md, "", true).to_utf8_buffer()}

static func crc32(b: PackedByteArray) -> int:
	var crc := 0xFFFFFFFF
	for x in b:
		crc ^= x
		for _k in 8:
			crc = (crc >> 1) ^ (0xEDB88320 if crc & 1 else 0)
	return crc ^ 0xFFFFFFFF

static func _u16(v: int) -> PackedByteArray:
	var b := PackedByteArray(); b.resize(2); b.encode_u16(0, v); return b

static func _u32(v: int) -> PackedByteArray:
	var b := PackedByteArray(); b.resize(4); b.encode_u32(0, v & 0xFFFFFFFF); return b

## entries: Array[[name, bytes]] in archive order. opts per entry name (or "*"):
## {made_by, flags, method, eattr, local_name, csize}.
static func build_zip(entries: Array, opts: Dictionary = {}) -> PackedByteArray:
	var out := PackedByteArray()
	var central := PackedByteArray()
	for e in entries:
		var name: String = e[0]
		var data: PackedByteArray = e[1]
		var o: Dictionary = opts.get(name, opts.get("*", {}))
		var nb := name.to_utf8_buffer()
		var lnb := String(o.get("local_name", name)).to_utf8_buffer()
		var crc := crc32(data)
		var flags: int = o.get("flags", 0)
		var method: int = o.get("method", 0)
		var csize: int = o.get("csize", data.size())
		var off := out.size()
		out.append_array(_u32(0x04034b50)); out.append_array(_u16(20)); out.append_array(_u16(flags))
		out.append_array(_u16(method)); out.append_array(_u16(0)); out.append_array(_u16(0x21))   # 1980-01-01 00:00
		out.append_array(_u32(crc)); out.append_array(_u32(csize)); out.append_array(_u32(data.size()))
		out.append_array(_u16(lnb.size())); out.append_array(_u16(0)); out.append_array(lnb); out.append_array(data)
		central.append_array(_u32(0x02014b50)); central.append_array(_u16(o.get("made_by", (3 << 8) | 20)))
		central.append_array(_u16(20)); central.append_array(_u16(flags)); central.append_array(_u16(method))
		central.append_array(_u16(0)); central.append_array(_u16(0x21)); central.append_array(_u32(crc))
		central.append_array(_u32(csize)); central.append_array(_u32(data.size())); central.append_array(_u16(nb.size()))
		central.append_array(_u16(0)); central.append_array(_u16(0)); central.append_array(_u16(0)); central.append_array(_u16(0))
		central.append_array(_u32(o.get("eattr", UNIX_REG_0644)))
		central.append_array(_u32(off)); central.append_array(nb)
	var cd_off := out.size()
	out.append_array(central)
	out.append_array(_u32(0x06054b50)); out.append_array(_u16(0)); out.append_array(_u16(0))
	out.append_array(_u16(entries.size())); out.append_array(_u16(entries.size()))
	out.append_array(_u32(central.size())); out.append_array(_u32(cd_off)); out.append_array(_u16(0))
	return out


## levels: {id: files}. Returns the canonical archive bytes. `mutate`: Callable(entries) -> entries.
static func build_pack(pack_id: String, pack_version: int, levels: Dictionary, zip_opts: Dictionary = {}, mutate: Callable = Callable(), pack_json_override = null) -> PackedByteArray:
	var ids: Array = levels.keys()
	ids.sort()
	var lv_entries: Array = []
	var members: Array = []
	for id in ids:
		var f: Dictionary = levels[id]
		var files := {"levelData": "levels/%s/level.json" % id, "supplyPlan": "levels/%s/supply-plan.json" % id,
			"metadata": "levels/%s/metadata.json" % id}
		lv_entries.append({"id": id, "files": files, "sha256": {
			"levelData": ContentManifestV1.sha256_hex(f["level"]),
			"supplyPlan": ContentManifestV1.sha256_hex(f["supply_plan"]),
			"metadata": ContentManifestV1.sha256_hex(f["metadata"])}})
		members.append([files["levelData"], f["level"]])
		members.append([files["supplyPlan"], f["supply_plan"]])
		members.append([files["metadata"], f["metadata"]])
	var pj = {"schema": "scrubbots.scrubpack.manifest.v1", "version": 1, "mediaType": "application/vnd.scrubbots.scrubpack+zip",
		"packId": pack_id, "packVersion": pack_version, "createdAtUtc": "2026-10-07T00:00:00Z",
		"levelCount": ids.size(), "levels": lv_entries}
	if pack_json_override != null:
		pj = pack_json_override.call(pj)
	var pj_bytes: PackedByteArray = pj if typeof(pj) == TYPE_PACKED_BYTE_ARRAY else JSON.stringify(pj, "", true).to_utf8_buffer()
	var entries: Array = [["pack.json", pj_bytes]] + members
	if mutate.is_valid():
		entries = mutate.call(entries)
	return build_zip(entries, zip_opts)

## packs: Array[{pack_id, pack_version, bytes}] ; levels: Array[[level_id, pack_id]].
static func manifest(content_version: int, packs: Array, levels: Array, min_game_version := "0.0.0", extra := {}) -> Dictionary:
	var pk: Array = []
	for p in packs:
		pk.append({"pack_id": p["pack_id"], "pack_version": p["pack_version"],
			"object_key": "packs/%s/%s-v%d.scrubpack" % [p["pack_id"], p["pack_id"], p["pack_version"]],
			"sha256": ContentManifestV1.sha256_hex(p["bytes"]), "byte_length": p["bytes"].size()})
	var lv: Array = []
	for l in levels:
		lv.append({"level_id": l[0], "pack_id": l[1]})
	var m := {"schema": "scrubbots.content.manifest.v1", "schema_version": 1, "content_version": content_version,
		"minimum_game_version": min_game_version, "disabled_levels": [], "schedules": [], "packs": pk, "levels": lv}
	m.merge(extra, true)
	return m

## Injectable provider-neutral transport. objects: object_key -> bytes.
class FakeTransport:
	var manifest_bytes := PackedByteArray()
	var objects := {}
	var offline := false
	var http_error := 0
	var manifest_calls := 0
	var object_calls: Array = []
	var corrupt_objects := {}   ## object_key -> bytes served instead (tamper in transit)

	func set_manifest(m: Dictionary, packs: Array) -> void:
		manifest_bytes = JSON.stringify(m, "", true).to_utf8_buffer()
		for i in packs.size():
			objects[m["packs"][i]["object_key"]] = packs[i]["bytes"]

	func fetch_manifest() -> Dictionary:
		manifest_calls += 1
		if offline:
			return {"ok": false, "reason": "TRANSPORT_OFFLINE", "bytes": PackedByteArray()}
		if http_error != 0:
			return {"ok": false, "reason": "TRANSPORT_HTTP_%d" % http_error, "bytes": PackedByteArray()}
		return {"ok": true, "reason": "OK", "bytes": manifest_bytes}

	func fetch_object(object_key: String, part_path: String, max_bytes: int) -> Dictionary:
		object_calls.append(object_key)
		if offline:
			return {"ok": false, "reason": "TRANSPORT_OFFLINE"}
		var b: PackedByteArray = corrupt_objects.get(object_key, objects.get(object_key, PackedByteArray()))
		if b.is_empty():
			return {"ok": false, "reason": "TRANSPORT_HTTP_404"}
		if b.size() > max_bytes:
			return {"ok": false, "reason": "TRANSPORT_TOO_LARGE"}
		var f := FileAccess.open(part_path, FileAccess.WRITE)
		f.store_buffer(b)
		f.close()
		return {"ok": true, "reason": "OK"}
