extends RefCounted
## FeedbackAdapter — preload (res://scripts/ui/feel/feedback_adapter.gd).
##
## M43-C005F (SB-M43-C005F-002) — the ONE SCRUBBOTS gateway to the optional GameFeelFlow and
## Saltmire Spark presentation plugins, with the owner intensity ladder
##   MICRO -> SMALL -> REWARD -> MAJOR_REWARD -> WIN -> MAJOR_UNLOCK
## (a presentation budget only — never gameplay / economy importance truth).
##
## PRESENTATION ONLY AND FAIL-OPEN:
##   - plugins are looked up by autoload name at call time; a missing plugin is a silent no-op;
##   - every plugin call is DEFERRED, so a plugin error can never interrupt the caller;
##   - only an allow-listed effect/combo/preset can be requested (DO-NOT-USE categories such as
##     camera_*, freeze_frame, time_scale, impulse, velocity, shake are unreachable);
##   - optional one-shot `key`: the same key never plays twice (refresh / reopen safe);
##   - Reduced Effects maps every intent to its REDUCED row (no particles, no motion except an
##     optional tiny UI press) and a live toggle to Reduced cancels decorative plugin work.
## Nothing here grants, saves, navigates or touches gameplay. No shipping call site exists until
## the canonical plugin intake (SB-M43-C005F-001) is resolved.

const GFF_AUTOLOAD := "GameFeelFlow"
const SPARK_AUTOLOAD := "Spark"
const INTENTS := ["MICRO", "SMALL", "REWARD", "MAJOR_REWARD", "WIN", "MAJOR_UNLOCK"]
## Installed names only (PLUGIN_INTAKE_REPORT_V01): no camera / time / physics / shake / flash.
const GFF_ALLOWED := ["punch_scale", "elastic", "ui_button_press", "ui_notification"]
const SPARK_ALLOWED := ["spark", "pickup", "confetti"]
## Owner TASKS budgets: Spark particle ceilings per tier (FULL). Reduced = 0.
const PARTICLE_CEILING := {"MICRO": 0, "SMALL": 4, "REWARD": 8, "MAJOR_REWARD": 14, "WIN": 18, "MAJOR_UNLOCK": 24}
## intent -> {gff, gff_kind ("effect"|"combo"|""), spark, amount} for FULL / REDUCED.
const FULL := {
	"MICRO": {"gff": "ui_button_press", "gff_kind": "combo", "spark": "", "amount": 0},
	"SMALL": {"gff": "punch_scale", "gff_kind": "effect", "spark": "spark", "amount": 4},
	"REWARD": {"gff": "ui_notification", "gff_kind": "combo", "spark": "pickup", "amount": 8},
	"MAJOR_REWARD": {"gff": "punch_scale", "gff_kind": "effect", "spark": "confetti", "amount": 14},
	"WIN": {"gff": "elastic", "gff_kind": "effect", "spark": "confetti", "amount": 18},
	"MAJOR_UNLOCK": {"gff": "elastic", "gff_kind": "effect", "spark": "confetti", "amount": 24},
}
const REDUCED := {
	"MICRO": {"gff": "", "gff_kind": "", "spark": "", "amount": 0},
	"SMALL": {"gff": "", "gff_kind": "", "spark": "", "amount": 0},
	"REWARD": {"gff": "", "gff_kind": "", "spark": "", "amount": 0},
	"MAJOR_REWARD": {"gff": "", "gff_kind": "", "spark": "", "amount": 0},
	"WIN": {"gff": "", "gff_kind": "", "spark": "", "amount": 0},
	"MAJOR_UNLOCK": {"gff": "", "gff_kind": "", "spark": "", "amount": 0},
}

var _tree: SceneTree = null
var _effects = null
var _played: Dictionary = {}     ## one-shot keys already played
var _gff_override = null         ## test seam: spy backends (never set in production)
var _spark_override = null
var _use_override := false
var _log: Array = []             ## [intent, key, plan] actually dispatched (evidence)

func bind(tree: SceneTree, effects_service = null) -> void:
	_tree = tree
	_effects = effects_service
	if _effects != null and _effects.has_signal("changed"):
		_effects.changed.connect(_on_effects_changed)

## Test seam only: replace the autoload lookup with spies (null = plugin absent).
func set_backends_for_test(gff, spark) -> void:
	_use_override = true
	_gff_override = gff
	_spark_override = spark

func reduced() -> bool:
	return _effects != null and _effects.is_reduced()

## The plan an intent maps to right now (FULL or REDUCED row). Pure; unknown intent -> {}.
func plan(intent: String) -> Dictionary:
	if not INTENTS.has(intent):
		return {}
	return ((REDUCED if reduced() else FULL)[intent] as Dictionary).duplicate()

## Request presentation feedback. Returns true when something was dispatched (possibly to an
## absent plugin = no-op). Refused: unknown intent, already-played one-shot key, invalid target.
func play(intent: String, target: Node, key: String = "") -> bool:
	var p := plan(intent)
	if p.is_empty() or not is_instance_valid(target):
		return false
	if not key.is_empty():
		if _played.has(key):
			return false
		_played[key] = true
	var gff = _gff()
	var spark = _spark()
	var gname := String(p["gff"])
	if gff != null and GFF_ALLOWED.has(gname):
		if p["gff_kind"] == "combo" and gff.has_method("play_combo"):
			Callable(gff, "play_combo").call_deferred(gname, target)
		elif p["gff_kind"] == "effect" and gff.has_method("play"):
			Callable(gff, "play").call_deferred(gname, target)
	var preset := String(p["spark"])
	var amount := mini(int(p["amount"]), int(PARTICLE_CEILING[intent]))
	if spark != null and SPARK_ALLOWED.has(preset) and amount > 0 and spark.has_method("at") and target is CanvasItem:
		# Spark takes a preset NAME or raw opts; merge the installed preset with the capped amount.
		var presets = spark.get("presets")
		var opts: Dictionary = (presets.get(preset, {}) as Dictionary).duplicate() if typeof(presets) == TYPE_DICTIONARY else {}
		opts["amount"] = amount
		Callable(spark, "at").call_deferred(target, opts)
	_log.append([intent, key, p])
	return true

func has_played(key: String) -> bool:
	return _played.has(key)

func dispatch_log() -> Array:
	return _log.duplicate(true)

## Cancel decorative plugin work (live Reduced toggle / scene teardown). Never touches native state.
func cancel_all(root: Node = null) -> void:
	var gff = _gff()
	if gff != null and gff.has_method("stop_all"):
		Callable(gff, "stop_all").call_deferred(root)
	var spark = _spark()
	if spark != null and spark.has_method("clear"):
		Callable(spark, "clear").call_deferred()

func _on_effects_changed(is_reduced: bool) -> void:
	if is_reduced:
		cancel_all()

func _gff():
	if _use_override:
		return _gff_override
	return _autoload(GFF_AUTOLOAD)

func _spark():
	if _use_override:
		return _spark_override
	return _autoload(SPARK_AUTOLOAD)

func _autoload(n: String):
	if _tree == null or _tree.root == null:
		return null
	return _tree.root.get_node_or_null(n)
