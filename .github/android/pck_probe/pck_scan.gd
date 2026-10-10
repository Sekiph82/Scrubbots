extends SceneTree
## M47-FAMILY-APK-C001 — deterministic inspection of an EXPORTED ScrubBots pack.
## Usage (from this probe project, never the game project):
##   godot --headless --path <probe> -s res://pck_scan.gd -- <pack.pck> <exclusions.txt> <required.txt> <report.json>
## 1. ProjectSettings.load_resource_pack(<pack.pck>) mounts the exported pack;
## 2. res:// is walked recursively (hidden .godot/ included) -> every packaged path;
## 3. FAIL if any packaged path lies under an excluded tree (exclusions.txt, one prefix per line);
## 4. FAIL if any required runtime path (required.txt: res:// literals referenced by shipping
##    scripts / scenes / data / addons that exist in the source tree) is not in the pack, either as
##    the file itself or as its exported .import / .remap entry;
## 5. FAIL if the walk did not see the pack at all (res://project.binary must be present).
## The JSON report is written for the build log / artifact.

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 4:
		push_error("usage: <pack.pck> <exclusions.txt> <required.txt> <report.json>")
		quit(2)
		return
	var report := {"pack": a[0], "mounted": ProjectSettings.load_resource_pack(a[0], false)}
	var files: Array = []
	_walk("res://", files)
	files.sort()
	var prefixes: Array = []
	for line in FileAccess.get_file_as_string(a[1]).split("\n"):
		var l := line.strip_edges()
		if not l.is_empty() and not l.begins_with("#"):
			prefixes.append("res://" + l.trim_suffix("/") + "/")
	var forbidden: Array = files.filter(func(f): return prefixes.any(func(p): return String(f).begins_with(p)))
	var have := {}
	for f in files:
		have[f] = true
	var required: Array = []
	var missing: Array = []
	for line in FileAccess.get_file_as_string(a[2]).split("\n"):
		var p := line.strip_edges()
		if p.is_empty():
			continue
		required.append(p)
		if not (have.has(p) or have.has(p + ".import") or have.has(p + ".remap")):
			missing.append(p)
	var tops := {}
	var top_bytes := {}
	var sized: Array = []
	var total_bytes := 0
	for f in files:
		var rel := String(f).trim_prefix("res://")
		var top := rel.get_slice("/", 0) if rel.contains("/") else "(root)"
		tops[top] = int(tops.get(top, 0)) + 1
		var fa := FileAccess.open(f, FileAccess.READ)
		var n: int = fa.get_length() if fa != null else 0
		total_bytes += n
		top_bytes[top] = int(top_bytes.get(top, 0)) + n
		sized.append([n, f])
	sized.sort_custom(func(x, y): return x[0] > y[0])
	report["packaged_bytes"] = total_bytes
	report["top_level_bytes"] = top_bytes
	report["largest_files"] = sized.slice(0, 40)
	report["packaged_file_count"] = files.size()
	report["sees_pack"] = have.has("res://project.binary")
	report["excluded_prefixes"] = prefixes
	report["forbidden_count"] = forbidden.size()
	report["forbidden_paths"] = forbidden.slice(0, 200)
	report["required_count"] = required.size()
	report["missing_required"] = missing
	report["top_level_counts"] = tops
	report["has_main_scene"] = have.has("res://scenes/app/main.tscn") or have.has("res://scenes/app/main.tscn.remap")
	var ok: bool = report["mounted"] and report["sees_pack"] and forbidden.is_empty() and missing.is_empty() and report["has_main_scene"]
	report["verdict"] = "PASS" if ok else "FAIL"
	var f := FileAccess.open(a[3], FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	var lf := FileAccess.open(a[3].get_basename() + "_files.txt", FileAccess.WRITE)
	lf.store_string("\n".join(files))
	lf.close()
	print("PCK_SCAN mounted=%s sees_pack=%s files=%d forbidden=%d required=%d missing=%d main_scene=%s verdict=%s" % [report["mounted"], report["sees_pack"],
		files.size(), forbidden.size(), required.size(), missing.size(), report["has_main_scene"], report["verdict"]])
	for p in forbidden.slice(0, 20):
		print("PCK_SCAN forbidden: " + String(p))
	for p in missing.slice(0, 50):
		print("PCK_SCAN missing: " + String(p))
	quit(0 if ok else 1)

func _walk(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.include_hidden = true
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if n != "." and n != "..":
			var p := dir.path_join(n)
			if d.current_is_dir():
				_walk(p, out)
			else:
				out.append(p)
		n = d.get_next()
	d.list_dir_end()
