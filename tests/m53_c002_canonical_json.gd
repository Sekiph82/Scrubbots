extends SceneTree
## SB-M53-C002-R01-001 R02 — golden tests for the QA-only canonical JSON authority
## (tools/m53_canonical_json.gd). The expected strings are platform-independent: Godot's
## full-precision path is grisu2 (integer arithmetic), not the C runtime printf whose midpoint
## rounding differed between platforms. Includes the three known boundary values.
##
## Run: godot --headless --path . -s res://tests/m53_c002_canonical_json.gd

const Canon = preload("res://tools/m53_canonical_json.gd")

var _fail := 0
var _n := 0

func _initialize() -> void:
	_goldens()
	_nested_and_order()
	_repeated()
	_round_trip()
	_wiring()
	print("M53-C002 canonical JSON: %s (%d checks, %d fail)" % ["PASS" if _fail == 0 else "FAIL", _n, _fail])
	quit(0 if _fail == 0 else 1)

func _ok(c: bool, msg: String) -> void:
	_n += 1
	if c:
		print("  ok: " + msg)
	else:
		_fail += 1
		print("  FAIL: " + msg)

func _goldens() -> void:
	print("[goldens: full-precision shortest round-trip text]")
	var cases := [
		[1.286916935992815, "1.286916935992815"],    # corpus boundary (flow_stripes3_20 RR / RR_REV meanDetour)
		[124.9313038031345, "124.9313038031345"],    # corpus boundary (slot_high_24 RR lengthVariance)
		[0.1, "0.1"], [-2.5, "-2.5"], [1.0 / 3.0, "0.3333333333333333"], [123456789.125, "123456789.125"],
		[-0.000123, "-0.000123"], [1e-7, "1e-07"], [1e21, "1e+21"],
		[0.0, "0.0"], [29.0, "29.0"],                 # floats keep a decimal point
		[29, "29"], [-3, "-3"], [0, "0"],             # integers stay integers
		[true, "true"], [null, "null"], ["x", "\"x\""],
	]
	for c in cases:
		_ok(Canon.stringify(c[0]) == c[1], "%s -> %s (got %s)" % [var_to_str(c[0]), c[1], Canon.stringify(c[0])])
	# The three boundary leaves: same double, exactly the shortest digits (no 15-digit printf rounding).
	_ok(Canon.stringify({"meanDetour": 1.286916935992815}, "") == "{\"meanDetour\":1.286916935992815}", "boundary value inside an object")
	_ok(Canon.stringify(1.286916935992815) != "1.28691693599282" and Canon.stringify(124.9313038031345) != "124.931303803135", "never the platform-dependent 15-significant-digit text")

func _nested_and_order() -> void:
	print("[nested structures, key order, indent / newline policy]")
	var a := {"b": [1, 2.5, {"z": 0.1, "a": -3}], "a": true, "n": null, "s": "x"}
	var b := {"s": "x", "n": null, "a": true, "b": [1, 2.5, {"a": -3, "z": 0.1}]}   # different insertion order
	_ok(Canon.stringify(a, "") == "{\"a\":true,\"b\":[1,2.5,{\"a\":-3,\"z\":0.1}],\"n\":null,\"s\":\"x\"}", "compact form, keys sorted at every depth")
	_ok(Canon.stringify(a) == Canon.stringify(b), "insertion order never changes the text")
	_ok(Canon.stringify(a) == "{\n\t\"a\": true,\n\t\"b\": [\n\t\t1,\n\t\t2.5,\n\t\t{\n\t\t\t\"a\": -3,\n\t\t\t\"z\": 0.1\n\t\t}\n\t],\n\t\"n\": null,\n\t\"s\": \"x\"\n}", "tab indent, \\n newlines")
	var ft := Canon.file_text(a)
	_ok(ft.ends_with("}\n") and not ft.ends_with("\n\n") and not ft.contains("\r"), "file text: exactly one trailing LF, no CR")

func _repeated() -> void:
	print("[repeated runs]")
	var v := {"x": [1.286916935992815, 124.9313038031345, {"k": 0.1}], "y": 7}
	var first := Canon.stringify(v)
	var same := true
	for i in 200:
		same = same and Canon.stringify(v.duplicate(true)) == first
	_ok(same, "200 repeated serializations byte-identical")

func _round_trip() -> void:
	print("[parse round trip of the boundary values]")
	for x in [1.286916935992815, 124.9313038031345]:
		var y = JSON.parse_string(Canon.stringify(x))
		_ok(typeof(y) == TYPE_FLOAT and var_to_bytes(y) == var_to_bytes(x), "%s parses back to the identical double" % var_to_str(x))
		_ok(Canon.stringify(JSON.parse_string(Canon.stringify(x))) == Canon.stringify(x), "%s: canonical(parse(canonical)) stable" % var_to_str(x))

func _wiring() -> void:
	print("[the calibration tool + determinism test use this authority]")
	var tool := FileAccess.get_file_as_string("res://tools/calibrate_difficulty_v2.gd")
	_ok(tool.count("Canon.file_text(") == 5, "all five evidence writers (corpus raw, config, corpus evidence, holdout raw, holdout evidence) are canonical")
	var t := FileAccess.get_file_as_string("res://tests/m53_c002_difficulty_calibration.gd")
	_ok(t.contains("JSON.parse_string(Canon.stringify(raw, \"\"))") and t.contains("return Canon.stringify(d, \"\")"), "determinism check normalizes with the canonical authority (exact string equality kept)")
