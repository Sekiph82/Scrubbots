extends RefCounted
## RuntimePerfProbe — preload (res://scripts/debug/runtime_perf_probe.gd).
##
## M52-C001-R01 bounded main-thread attribution probe. OFF by default: every hook is a
## single static bool test, no allocation, no gameplay effect. A debug/QA harness turns it
## on, runs real production gameplay, then reads per-section totals/max and the per-frame
## breakdown of the worst frames. Never read by gameplay logic.

static var enabled := false
static var _acc: Dictionary = {}      # section -> [count, total_usec, max_usec]
static var _frame: Dictionary = {}    # section -> usec within the current frame

static func now() -> int:
	return Time.get_ticks_usec() if enabled else 0

## Record one timed section that started at `start_usec` (from now()).
static func add(section: String, start_usec: int) -> void:
	if not enabled:
		return
	var d: int = Time.get_ticks_usec() - start_usec
	var a = _acc.get(section, null)
	if a == null:
		a = [0, 0, 0]
		_acc[section] = a
	a[0] += 1
	a[1] += d
	a[2] = maxi(a[2], d)
	_frame[section] = int(_frame.get(section, 0)) + d

static func reset() -> void:
	_acc.clear()
	_frame.clear()

## Detached per-frame section breakdown; clears the frame accumulator.
static func take_frame() -> Dictionary:
	var f := _frame.duplicate()
	_frame.clear()
	return f

static func snapshot() -> Dictionary:
	var out := {}
	for k in _acc:
		var a: Array = _acc[k]
		out[k] = {"count": a[0], "total_ms": snappedf(a[1] / 1000.0, 0.001), "max_ms": snappedf(a[2] / 1000.0, 0.001),
			"mean_ms": snappedf(a[1] / 1000.0 / maxf(1.0, a[0]), 0.001)}
	return out
