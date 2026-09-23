extends RefCounted
## ChallengeScoreModelV1 — preload
## (res://scripts/difficulty/challenge_score_model_v1.gd).
##
## Versioned reader/evaluator for the owner-locked Challenge Score model in
## `data/config/difficulty_score_model_v1.json`. Implements the exact weighted
## formulas; it does NOT invent coefficients and never silently changes them
## under model version 1.
##
##   Challenge  D = 100 * (0.10W + 0.15C + 0.20A + 0.20U + 0.15B + 0.10R + 0.10S)
##   SessionLoad  = 100 * (0.50*actions + 0.30*routeTime + 0.20*decisionCount)
##   FrustrationRisk = 100 * (0.35*retryRisk + 0.30*sessionOverrun + 0.20*lateFailure + 0.15*choiceOpacity)
##
## Every submetric input is clamped to [0,1] before use, so the outputs are
## always finite and in [0,100]. Challenge, Session Load and Frustration Risk are
## three SEPARATE axes (owner decision) — this class never collapses one into
## another.
##
## The submetric VALUES for a real level come from canonical gameplay/routing/
## solver analysis (a separate analyzer). This class owns only the model math,
## its provenance (model version), and clamping — so the coefficients live in
## exactly one versioned place.

const DEFAULT_CONFIG_PATH := "res://data/config/difficulty_score_model_v1.json"
const EXPECTED_SCHEMA := "scrubbots-difficulty-score-model/v1"

## Canonical challenge-vector order (matches config challengeVectorOrder).
const VECTOR_ORDER := ["W", "C", "A", "U", "B", "R", "S"]

var _loaded := false
var _error := ""
var _model_version := 0
var _challenge_weights := {}       ## key -> float
var _session_weights := {}
var _frustration_weights := {}
var _workload := {}                ## {cellTransform, referenceMinCells, referenceMaxCells}
var _color := {}                   ## {countNormalization:{minDistinct,maxDistinct}}

func _init(config_path: String = DEFAULT_CONFIG_PATH) -> void:
	_load(config_path)

func _load(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		_error = "cannot open %s (err %d)" % [path, FileAccess.get_open_error()]
		return
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		_error = "malformed JSON line %d: %s" % [json.get_error_line(), json.get_error_message()]
		return
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY or data.get("schema", "") != EXPECTED_SCHEMA:
		_error = "unexpected schema"
		return
	_model_version = int(data.get("version", 0))
	_challenge_weights = data.get("challengeScore", {}).get("weights", {})
	_session_weights = data.get("sessionLoad", {}).get("weights", {})
	_frustration_weights = data.get("frustrationRisk", {}).get("weights", {})
	_workload = data.get("workload", {})
	_color = data.get("colorComplexity", {})
	if _challenge_weights.is_empty():
		_error = "missing challenge weights"
		return
	_loaded = true

func is_ok() -> bool:
	return _loaded

func get_error() -> String:
	return _error

func model_version() -> int:
	return _model_version

func _clamp01(v: float) -> float:
	if is_nan(v) or is_inf(v):
		return 0.0
	return clampf(v, 0.0, 1.0)

## vec: {W,C,A,U,B,R,S} each in [0,1]. Missing keys default to 0.
## Returns the 0..100 Challenge Score.
func challenge_score(vec: Dictionary) -> float:
	var w := _clamp01(float(vec.get("W", 0.0)))
	var c := _clamp01(float(vec.get("C", 0.0)))
	var a := _clamp01(float(vec.get("A", 0.0)))
	var u := _clamp01(float(vec.get("U", 0.0)))
	var b := _clamp01(float(vec.get("B", 0.0)))
	var r := _clamp01(float(vec.get("R", 0.0)))
	var s := _clamp01(float(vec.get("S", 0.0)))
	var d := 100.0 * (
		float(_challenge_weights.get("workload", 0.0)) * w +
		float(_challenge_weights.get("colorComplexity", 0.0)) * c +
		float(_challenge_weights.get("accessibilityScarcity", 0.0)) * a +
		float(_challenge_weights.get("unlockDepth", 0.0)) * u +
		float(_challenge_weights.get("bottleneckPressure", 0.0)) * b +
		float(_challenge_weights.get("routeComplexity", 0.0)) * r +
		float(_challenge_weights.get("slotColorPressure", 0.0)) * s
	)
	return clampf(d, 0.0, 100.0)

## load: {actions, routeTime, decisionCount} each in [0,1]. 0..100.
func session_load(load: Dictionary) -> float:
	var a := _clamp01(float(load.get("actions", 0.0)))
	var r := _clamp01(float(load.get("routeTime", 0.0)))
	var d := _clamp01(float(load.get("decisionCount", 0.0)))
	var v := 100.0 * (
		float(_session_weights.get("actions", 0.0)) * a +
		float(_session_weights.get("routeTime", 0.0)) * r +
		float(_session_weights.get("decisionCount", 0.0)) * d
	)
	return clampf(v, 0.0, 100.0)

## risk: {retryRisk, sessionOverrun, lateFailure, choiceOpacity} each in [0,1]. 0..100.
func frustration_risk(risk: Dictionary) -> float:
	var rr := _clamp01(float(risk.get("retryRisk", 0.0)))
	var so := _clamp01(float(risk.get("sessionOverrun", 0.0)))
	var lf := _clamp01(float(risk.get("lateFailure", 0.0)))
	var co := _clamp01(float(risk.get("choiceOpacity", 0.0)))
	var v := 100.0 * (
		float(_frustration_weights.get("retryRisk", 0.0)) * rr +
		float(_frustration_weights.get("sessionOverrun", 0.0)) * so +
		float(_frustration_weights.get("lateFailure", 0.0)) * lf +
		float(_frustration_weights.get("choiceOpacity", 0.0)) * co
	)
	return clampf(v, 0.0, 100.0)

## Workload submetric W in [0,1] from cell_count, using the config sqrt
## transform and reference bounds. This is the ONLY board-size-derived
## submetric, and it is compressed (sqrt) then weighted 10% — so board size
## alone cannot dominate Challenge Score (SB-M36-006 / owner note).
func workload_submetric(cell_count: int) -> float:
	var lo := float(_workload.get("referenceMinCells", 400))
	var hi := float(_workload.get("referenceMaxCells", 2400))
	if hi <= lo:
		return 0.0
	var transform := String(_workload.get("cellTransform", "sqrt"))
	var v := float(max(cell_count, 0))
	var flo := lo
	var fhi := hi
	if transform == "sqrt":
		v = sqrt(v)
		flo = sqrt(lo)
		fhi = sqrt(hi)
	var norm := (v - flo) / (fhi - flo)
	return _clamp01(norm)

## Color-complexity submetric C in [0,1] from the distinct used-color count and
## a normalized entropy in [0,1] (Shannon over the used-color distribution).
func color_submetric(distinct_colors: int, normalized_entropy: float) -> float:
	var cn = _color.get("countNormalization", {})
	var lo := float(cn.get("minDistinct", 3))
	var hi := float(cn.get("maxDistinct", 12))
	var count_norm := 0.0
	if hi > lo:
		count_norm = _clamp01((float(distinct_colors) - lo) / (hi - lo))
	var cw := float(_color.get("countWeight", 0.5))
	var ew := float(_color.get("entropyWeight", 0.5))
	return _clamp01(cw * count_norm + ew * _clamp01(normalized_entropy))

## Provenance stamp for a published level analysis.
func provenance() -> Dictionary:
	return {
		"model_schema": EXPECTED_SCHEMA,
		"model_version": _model_version,
	}
