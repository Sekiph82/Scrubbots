extends RefCounted
## StrictJson — preload (res://scripts/content_runtime/strict_json.gd).
##
## Remote-content trust boundary JSON reader (CP04). Godot's JSON silently keeps the
## last duplicate key and turns every number into a float, so untrusted remote bytes go
## through this small RFC 8259 parser instead. It mirrors the Level Factory publisher's
## Python reader (json.loads + duplicate-key hook + non-finite rejection):
##   - strict UTF-8 (no overlong / surrogate / truncated sequences), no BOM;
##   - duplicate object keys rejected (exact key compare);
##   - integers stay TYPE_INT (no fraction/exponent), other numbers TYPE_FLOAT;
##   - non-finite / out-of-range numbers rejected;
##   - nesting depth, per-collection item count, string length and byte size capped;
##   - control characters inside strings and lone surrogate escapes rejected.
## Returns {ok, reason, value}. Never executes or loads anything.

const OK_REASON := "OK"

static func parse(raw: PackedByteArray, max_bytes: int, max_depth: int, max_items: int, max_string: int) -> Dictionary:
	if raw.size() > max_bytes:
		return _fail("TOO_LARGE")
	if not is_valid_utf8(raw):
		return _fail("INVALID_UTF8")
	var text := raw.get_string_from_utf8()
	# Godot drops a leading BOM and stops at NUL while decoding; Python's json.loads rejects
	# both. Requiring an exact round trip keeps the parsed text byte-identical to the input.
	if text.to_utf8_buffer() != raw:
		return _fail("INVALID_JSON")
	var p := _Parser.new(text, max_depth, max_items, max_string)
	p.skip_ws()
	var v = p.value(0)
	if p.err.is_empty():
		p.skip_ws()
		if p.i != p.n:
			p.err = "INVALID_JSON"
	if not p.err.is_empty():
		return _fail(p.err)
	return {"ok": true, "reason": OK_REASON, "value": v}

static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "value": null}

## Strict UTF-8 (RFC 3629): rejects overlong forms, surrogates, > U+10FFFF, truncation.
static func is_valid_utf8(b: PackedByteArray) -> bool:
	var i := 0
	var n := b.size()
	while i < n:
		var c := b[i]
		if c < 0x80:
			i += 1
			continue
		var need := 0
		var lo := 0x80
		var hi := 0xBF
		if c >= 0xC2 and c <= 0xDF:
			need = 1
		elif c == 0xE0:
			need = 2; lo = 0xA0
		elif c == 0xED:
			need = 2; hi = 0x9F
		elif c >= 0xE1 and c <= 0xEF:
			need = 2
		elif c == 0xF0:
			need = 3; lo = 0x90
		elif c >= 0xF1 and c <= 0xF3:
			need = 3
		elif c == 0xF4:
			need = 3; hi = 0x8F
		else:
			return false
		for k in range(1, need + 1):
			if i + k >= n:
				return false
			var cc := b[i + k]
			if k == 1:
				if cc < lo or cc > hi:
					return false
			elif cc < 0x80 or cc > 0xBF:
				return false
		i += need + 1
	return true

class _Parser:
	var s: String
	var i := 0
	var n := 0
	var err := ""
	var max_depth: int
	var max_items: int
	var max_string: int

	func _init(text: String, d: int, it: int, st: int) -> void:
		s = text
		n = text.length()
		max_depth = d
		max_items = it
		max_string = st

	func skip_ws() -> void:
		while i < n:
			var c := s.unicode_at(i)
			if c == 0x20 or c == 0x09 or c == 0x0A or c == 0x0D:
				i += 1
			else:
				return

	func value(depth: int):
		if i >= n:
			err = "INVALID_JSON"
			return null
		var c := s.unicode_at(i)
		if c == 0x7B or c == 0x5B:   # { [
			if depth + 1 > max_depth:
				err = "NESTING_TOO_DEEP"
				return null
			return object(depth + 1) if c == 0x7B else array(depth + 1)
		if c == 0x22:
			return string()
		if c == 0x2D or (c >= 0x30 and c <= 0x39):
			return number()
		for lit in [["true", true], ["false", false], ["null", null]]:
			if s.substr(i, lit[0].length()) == lit[0]:
				i += lit[0].length()
				return lit[1]
		err = "INVALID_JSON"
		return null

	func object(depth: int):
		i += 1
		var out := {}
		skip_ws()
		if i < n and s.unicode_at(i) == 0x7D:
			i += 1
			return out
		while err.is_empty():
			skip_ws()
			if i >= n or s.unicode_at(i) != 0x22:
				err = "INVALID_JSON"
				return null
			var k = string()
			if not err.is_empty():
				return null
			if out.has(k):
				err = "DUPLICATE_KEY"
				return null
			skip_ws()
			if i >= n or s.unicode_at(i) != 0x3A:
				err = "INVALID_JSON"
				return null
			i += 1
			skip_ws()
			var v = value(depth)
			if not err.is_empty():
				return null
			out[k] = v
			if out.size() > max_items:
				err = "LIMIT_EXCEEDED"
				return null
			skip_ws()
			if i < n and s.unicode_at(i) == 0x2C:
				i += 1
				continue
			if i < n and s.unicode_at(i) == 0x7D:
				i += 1
				return out
			err = "INVALID_JSON"
		return null

	func array(depth: int):
		i += 1
		var out := []
		skip_ws()
		if i < n and s.unicode_at(i) == 0x5D:
			i += 1
			return out
		while err.is_empty():
			skip_ws()
			var v = value(depth)
			if not err.is_empty():
				return null
			out.append(v)
			if out.size() > max_items:
				err = "LIMIT_EXCEEDED"
				return null
			skip_ws()
			if i < n and s.unicode_at(i) == 0x2C:
				i += 1
				continue
			if i < n and s.unicode_at(i) == 0x5D:
				i += 1
				return out
			err = "INVALID_JSON"
		return null

	func string():
		i += 1
		var parts := PackedStringArray()
		var start := i
		while i < n:
			var c := s.unicode_at(i)
			if c == 0x22:
				parts.append(s.substr(start, i - start))
				i += 1
				var out := "".join(parts)
				if out.length() > max_string:
					err = "STRING_TOO_LONG"
					return null
				return out
			if c < 0x20:
				err = "INVALID_JSON"
				return null
			if c == 0x5C:
				parts.append(s.substr(start, i - start))
				if i + 1 >= n:
					break
				var e := s[i + 1]
				var map := {"\"": "\"", "\\": "\\", "/": "/", "b": "\b", "f": "\f", "n": "\n", "r": "\r", "t": "\t"}
				if map.has(e):
					parts.append(map[e])
					i += 2
				elif e == "u":
					var cp := _hex4(i + 2)
					if cp < 0:
						err = "INVALID_JSON"
						return null
					i += 6
					if cp >= 0xD800 and cp <= 0xDBFF:
						var lo := _hex4(i + 2) if i + 1 < n and s[i] == "\\" and s[i + 1] == "u" else -1
						if lo < 0xDC00 or lo > 0xDFFF:
							err = "INVALID_JSON"   # lone high surrogate
							return null
						cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00)
						i += 6
					elif cp >= 0xDC00 and cp <= 0xDFFF:
						err = "INVALID_JSON"   # lone low surrogate
						return null
					parts.append(String.chr(cp))
				else:
					err = "INVALID_JSON"
					return null
				start = i
				continue
			i += 1
		err = "INVALID_JSON"
		return null

	func _hex4(at: int) -> int:
		if at + 4 > n:
			return -1
		var h := s.substr(at, 4)
		for ch in h:
			if not "0123456789abcdefABCDEF".contains(ch):
				return -1
		return h.hex_to_int()

	func number():
		var start := i
		if s[i] == "-":
			i += 1
		if i >= n:
			err = "INVALID_JSON"
			return null
		if s[i] == "0":
			i += 1
		elif _digit(i):
			while i < n and _digit(i):
				i += 1
		else:
			err = "INVALID_JSON"
			return null
		var is_int := true
		if i < n and s[i] == ".":
			is_int = false
			i += 1
			if not (i < n and _digit(i)):
				err = "INVALID_JSON"
				return null
			while i < n and _digit(i):
				i += 1
		if i < n and (s[i] == "e" or s[i] == "E"):
			is_int = false
			i += 1
			if i < n and (s[i] == "+" or s[i] == "-"):
				i += 1
			if not (i < n and _digit(i)):
				err = "INVALID_JSON"
				return null
			while i < n and _digit(i):
				i += 1
		var tok := s.substr(start, i - start)
		if is_int:
			# int64 only; a longer literal would silently wrap, so it fails closed.
			var digits := tok.trim_prefix("-")
			if digits.length() > 18:
				err = "LIMIT_EXCEEDED"
				return null
			return tok.to_int()
		var f := tok.to_float()
		if is_nan(f) or is_inf(f):
			err = "NON_FINITE_NUMBER"
			return null
		return f

	func _digit(at: int) -> bool:
		var c := s.unicode_at(at)
		return c >= 0x30 and c <= 0x39
