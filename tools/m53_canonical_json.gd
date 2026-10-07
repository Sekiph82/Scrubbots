extends RefCounted
## M53CanonicalJson — preload (res://tools/m53_canonical_json.gd). QA-only; never shipped.
##
## SB-M53-C002-R01-001 R02: the ONE canonical JSON serialization authority for M53-C002
## calibration evidence (tools/calibrate_difficulty_v2.gd writers) and for the exact
## fresh == committed determinism comparison in tests/m53_c002_difficulty_calibration.gd.
##
## Why: Godot 4.7.2's default `JSON.stringify` prints floats through
## `String::num(x, 14 - floor(log10|x|))` -> the platform C runtime `snprintf("%.<p>lf")`,
## whose rounding differs between glibc and msvcrt-style runtimes on decimal midpoints
## (see SB-M53-C002-R01-001_CLAUDE_LOG_V01.md). With `full_precision = true` Godot instead
## uses `String::num_scientific` -> thirdparty/grisu2 (integer diyfp arithmetic; shortest
## round-trip digits; no C runtime formatting), so the text is identical on every platform.
##
## Policy: full-precision shortest round-trip floats (exact 0 prints "0.0"); integers, strings,
## bools and null unchanged; keys sorted; "\t" indent (or compact with ""), "\n"-terminated
## files. No epsilon, rounding or field removal. Generic game JSON behaviour is untouched.

static func stringify(value, indent: String = "\t") -> String:
	return JSON.stringify(value, indent, true, true)

## File text: canonical body + one trailing newline.
static func file_text(value) -> String:
	return stringify(value, "\t") + "\n"
