extends RefCounted
## AccessibilityAudit — preload (res://tools/accessibility_audit.gd). DEVELOPER TOOL (tools/ is
## excluded from every export).
##
## M50 (SB-M50-001/003/004) — pure, deterministic measurements, no game state touched:
##   - WCAG 2.x contrast ratio of two sRGB colours;
##   - colour-vision-deficiency simulation (Machado, Oliveira & Fernandes 2009, severity 1.0,
##     applied in linear sRGB) for protanopia / deuteranopia / tritanopia;
##   - CIE76 colour difference (Delta E*ab, D65) between two sRGB colours;
##   - per-palette minimum pairwise Delta E under normal vision and each simulated CVD.
## Thresholds are NOT decided here: reports are evidence for owner decisions.

const KINDS := ["normal", "protan", "deutan", "tritan"]
const MACHADO := {
	"protan": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
	"deutan": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
	"tritan": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}

static func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)

static func _enc(v: float) -> float:
	var x := clampf(v, 0.0, 1.0)
	return 12.92 * x if x <= 0.0031308 else 1.055 * pow(x, 1.0 / 2.4) - 0.055

static func relative_luminance(c: Color) -> float:
	return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)

## WCAG contrast ratio, 1.0 .. 21.0.
static func contrast_ratio(a: Color, b: Color) -> float:
	var la := relative_luminance(a)
	var lb := relative_luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

## Simulated appearance of `c` for `kind` ("normal" returns c unchanged).
static func simulate(c: Color, kind: String) -> Color:
	if not MACHADO.has(kind):
		return c
	var m: Array = MACHADO[kind]
	var l := [_lin(c.r), _lin(c.g), _lin(c.b)]
	var o: Array = []
	for i in range(3):
		o.append(_enc(float(m[i][0]) * l[0] + float(m[i][1]) * l[1] + float(m[i][2]) * l[2]))
	return Color(o[0], o[1], o[2], c.a)

static func to_lab(c: Color) -> Vector3:
	var r := _lin(c.r)
	var g := _lin(c.g)
	var b := _lin(c.b)
	var x := (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
	var y := 0.2126 * r + 0.7152 * g + 0.0722 * b
	var z := (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
	var fx := _f(x)
	var fy := _f(y)
	var fz := _f(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))

static func _f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0

## CIE76 Delta E*ab between two sRGB colours.
static func delta_e(a: Color, b: Color) -> float:
	return to_lab(a).distance_to(to_lab(b))

## {kind: {"min": float, "a": int, "b": int}} — the closest colour pair (indices into
## `colors`) under each vision kind. Fewer than 2 colours -> min = INF.
static func palette_report(colors: Array) -> Dictionary:
	var out := {}
	for kind in KINDS:
		var best := {"min": INF, "a": -1, "b": -1}
		var sim: Array = colors.map(func(c): return simulate(c, kind))
		for i in range(sim.size()):
			for j in range(i + 1, sim.size()):
				var d := delta_e(sim[i], sim[j])
				if d < float(best["min"]):
					best = {"min": d, "a": i, "b": j}
		out[kind] = best
	return out
