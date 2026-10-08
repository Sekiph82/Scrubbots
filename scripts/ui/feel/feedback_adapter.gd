extends RefCounted
## FeedbackAdapter — preload (res://scripts/ui/feel/feedback_adapter.gd).
##
## M43-C005F (SB-M43-C005F-002 / -013 / -014) — the ONE SCRUBBOTS gateway to the optional
## GameFeelFlow and Saltmire Spark presentation plugins (canonical intake SB-M43-C005F-001:
## addons/game_feel_flow 1.0.0 + addons/saltmire_spark 1.0.0, both MIT), with the owner
## intensity ladder MICRO -> SMALL -> REWARD -> MAJOR_REWARD -> WIN -> MAJOR_UNLOCK
## (a presentation budget only — never gameplay / economy importance truth).
##
## PRESENTATION ONLY AND FAIL-OPEN:
##   - plugins are looked up by autoload name at call time and used only when the installed
##     compatibility contract holds (expected script + required methods); otherwise silent no-op;
##   - every plugin call is DEFERRED into the adapter's own dispatch, so a plugin error can
##     never interrupt the caller's control flow (navigation / terminal / commit / save);
##   - only the allow-listed installed names are reachable: GFF `punch_scale` (on the effect
##     stack, so it can be stopped per target and restores the node), Spark `spark` / `pickup` /
##     `confetti`. DO-NOT-USE categories (camera_*, flash, freeze_frame, time_scale, impulse,
##     velocity, shake*, hit/death/explosion combos) are unreachable;
##   - every tier has a particle ceiling AND a duration ceiling; work is owned per dispatch and
##     expires within its ceiling (no loops, no scene-long ownership);
##   - optional one-shot `key`: a key is consumed on first request in EITHER mode, so a
##     refresh / reopen / REDUCED->FULL toggle never replays it;
##   - Reduced Effects (canonical EffectsSettingsService, no second setting) maps every intent
##     to its REDUCED row: no particles, no motion, no flash, no camera/screen work. A live
##     FULL->REDUCED toggle cancels only adapter-owned plugin work (targeted GFF stop on the
##     targets it played on, which restores them; queue_free of the Spark bursts it spawned).
## Placement (M43-C005F-PHASE2): a Control target bursts at the centre of its global rect (Spark's
## own `at()` would use the Control's top-left corner), and every burst the adapter spawned is
## moved into the target's CanvasLayer, so a target inside a popup (ModalStack is a CanvasLayer)
## shows its particles above the popup instead of under the scrim. Still adapter-owned / freed.
## Nothing here grants, saves, navigates, decides success or touches gameplay. The adapter is
## ephemeral (created by scripts/app/main.gd, never saved) and is the only production entry
## point to either plugin (static guard: tests/m43_c005f_phase1_foundation.gd).

const GFF_AUTOLOAD := "GameFeelFlow"
const SPARK_AUTOLOAD := "Spark"
## Installed compatibility contract (SB-M43-C005F-001 intake). Anything else = treated absent.
const GFF_SCRIPT := "res://addons/game_feel_flow/core/game_feel_flow.gd"
const SPARK_SCRIPT := "res://addons/saltmire_spark/spark.gd"
const GFF_VERSION := "1.0.0"
const SPARK_VERSION := "1.0.0"
const GFF_METHODS := ["play", "stop_all", "get_effect_names"]
const SPARK_METHODS := ["at", "burst", "clear"]
const SPARK_POOL := "SaltmireSparkPool"   ## Spark's own burst parent (each burst = one child)
## Spark presets are tuned for small 2D game canvases (2.5-5 px particle radius); on the
## 1080-wide SCRUBBOTS UI canvas they read as specks. Particle RADIUS only is scaled (counts,
## lifetimes, speeds and every budget unchanged). M43-C005F-PHASE2; owner visual gate tunes it.
const SPARK_UI_SIZE_SCALE := 2.5

const INTENTS := ["MICRO", "SMALL", "REWARD", "MAJOR_REWARD", "WIN", "MAJOR_UNLOCK"]
const GFF_ALLOWED := ["punch_scale"]
const SPARK_ALLOWED := ["spark", "pickup", "confetti"]
## Owner TASKS budgets: Spark particle ceilings per tier (FULL). REDUCED = 0.
const PARTICLE_CEILING := {"MICRO": 0, "SMALL": 4, "REWARD": 8, "MAJOR_REWARD": 14, "WIN": 18, "MAJOR_UNLOCK": 24}
## Hard wall-clock ceiling of all adapter-owned work per dispatch (seconds).
const DURATION_CEILING_S := {"MICRO": 0.3, "SMALL": 0.5, "REWARD": 0.7, "MAJOR_REWARD": 0.9, "WIN": 1.1, "MAJOR_UNLOCK": 1.3}
## intent -> plan. gff_intensity scales punch_scale's installed 0.25 elastic punch (measured
## peak scale ~= 1 + 0.51 * intensity, so MAJOR_UNLOCK peaks ~1.12); gff_duration is the punch
## length. amount = Spark particles (<= ceiling). GFF 1.0.0's scale target only drives Node2D /
## Node3D (a Control is untouched), so the punch is dispatched only to Node2D / Node3D targets.
const FULL := {
	"MICRO": {"gff": "punch_scale", "gff_intensity": 0.08, "gff_duration": 0.12, "spark": "", "amount": 0},
	"SMALL": {"gff": "punch_scale", "gff_intensity": 0.12, "gff_duration": 0.18, "spark": "spark", "amount": 4},
	"REWARD": {"gff": "punch_scale", "gff_intensity": 0.16, "gff_duration": 0.25, "spark": "pickup", "amount": 8},
	"MAJOR_REWARD": {"gff": "punch_scale", "gff_intensity": 0.2, "gff_duration": 0.3, "spark": "confetti", "amount": 14},
	"WIN": {"gff": "punch_scale", "gff_intensity": 0.22, "gff_duration": 0.35, "spark": "confetti", "amount": 18},
	"MAJOR_UNLOCK": {"gff": "punch_scale", "gff_intensity": 0.24, "gff_duration": 0.4, "spark": "confetti", "amount": 24},
}
const _NONE := {"gff": "", "gff_intensity": 0.0, "gff_duration": 0.0, "spark": "", "amount": 0}
const REDUCED := {"MICRO": _NONE, "SMALL": _NONE, "REWARD": _NONE, "MAJOR_REWARD": _NONE, "WIN": _NONE, "MAJOR_UNLOCK": _NONE}

var _tree: SceneTree = null
var _effects = null
var _played: Dictionary = {}     ## one-shot keys already consumed
var _gff_override = null         ## test seam: spy backends (never set in production)
var _spark_override = null
var _use_override := false
var _log: Array = []             ## [intent, key, plan] accepted (evidence)
var _owned: Array = []           ## live dispatches: {id, target (WeakRef), emitters [WeakRef], intent}
var _seq := 0

func bind(tree: SceneTree, effects_service = null) -> void:
	_tree = tree
	_effects = effects_service
	if _effects != null and _effects.has_signal("changed") and not _effects.changed.is_connected(_on_effects_changed):
		_effects.changed.connect(_on_effects_changed)

## Teardown (app exit): cancel owned work and drop the settings subscription.
func unbind() -> void:
	cancel_all()
	if _effects != null and _effects.has_signal("changed") and _effects.changed.is_connected(_on_effects_changed):
		_effects.changed.disconnect(_on_effects_changed)
	_effects = null

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

## Harmless capability query: which plugin is usable right now (no plugin side effects).
func capabilities() -> Dictionary:
	var gff = _gff()
	var spark = _spark()
	var out := {"gff": gff != null, "spark": spark != null, "gff_effects": [], "spark_presets": []}
	if gff != null:
		var names = gff.get_effect_names()
		out["gff_effects"] = names if typeof(names) == TYPE_ARRAY else []
	if spark != null and typeof(spark.get("presets")) == TYPE_DICTIONARY:
		out["spark_presets"] = (spark.get("presets") as Dictionary).keys()
	return out

## Request presentation feedback. Returns true when accepted (dispatched to whatever plugin is
## usable, possibly none = no-op). Refused: unknown intent, consumed one-shot key, bad target.
func play(intent: String, target: Node, key: String = "") -> bool:
	var p := plan(intent)
	if p.is_empty() or not is_instance_valid(target):
		return false
	if not key.is_empty():
		if _played.has(key):
			return false
		_played[key] = true
	_log.append([intent, key, p])
	if String(p["gff"]).is_empty() and int(p["amount"]) <= 0:
		return true   # REDUCED / nothing decorative: no plugin work at all
	_seq += 1
	var entry := {"id": _seq, "target": weakref(target), "emitters": [], "intent": intent}
	_owned.append(entry)
	Callable(self, "_dispatch").call_deferred(entry, p)
	if _tree != null:
		_tree.create_timer(float(DURATION_CEILING_S[intent]), true, false, true).timeout.connect(_expire.bind(entry))
	return true

func has_played(key: String) -> bool:
	return _played.has(key)

func dispatch_log() -> Array:
	return _log.duplicate(true)

## Live adapter-owned dispatches (bounded by DURATION_CEILING_S).
func owned_count() -> int:
	return _owned.size()

## Cancel every adapter-owned decorative work item now (live Reduced toggle / teardown). Never
## calls a plugin-global clear and never touches native/authoritative state.
func cancel_all() -> void:
	var entries := _owned.duplicate()
	_owned.clear()
	for e in entries:
		_release(e)

func _on_effects_changed(is_reduced: bool) -> void:
	if is_reduced:
		cancel_all()

## Deferred: runs after the caller's frame work, so a plugin failure stays inside here.
func _dispatch(entry: Dictionary, p: Dictionary) -> void:
	if not _owned.has(entry):
		return   # cancelled (Reduced toggle / teardown) before it ever started
	var target: Node = (entry["target"] as WeakRef).get_ref()
	if not is_instance_valid(target) or reduced():
		_owned.erase(entry)
		return
	var gff = _gff()
	var gname := String(p["gff"])
	if gff != null and GFF_ALLOWED.has(gname) and (target is Node2D or target is Node3D):
		gff.play(gname, target, {"intensity": float(p["gff_intensity"]), "duration": float(p["gff_duration"])})
	var spark = _spark()
	var preset := String(p["spark"])
	var amount := mini(int(p["amount"]), int(PARTICLE_CEILING[entry["intent"]]))
	if spark != null and SPARK_ALLOWED.has(preset) and amount > 0 and target is CanvasItem:
		var presets = spark.get("presets")
		var opts: Dictionary = (presets.get(preset, {}) as Dictionary).duplicate() if typeof(presets) == TYPE_DICTIONARY else {}
		opts["amount"] = amount
		opts["size"] = float(opts.get("size", 3.0)) * SPARK_UI_SIZE_SCALE
		# Lifetime capped so even the slowest particle dies inside the tier ceiling.
		var rand: float = float(opts.get("lifetime_rand", 0.35))
		opts["lifetime"] = minf(float(opts.get("lifetime", 0.45)), float(DURATION_CEILING_S[entry["intent"]]) / (1.0 + rand) - 0.05)
		var pool: Node = spark.get_node_or_null(SPARK_POOL) if spark is Node else null
		var before: int = pool.get_child_count() if pool != null else 0
		if target is Control:
			spark.burst((target as Control).get_global_rect().get_center(), opts)
		else:
			spark.at(target, opts)
		if pool != null:
			# Same canvas as the target: its CanvasLayer, else its own (Sub)Viewport when that is
			# not Spark's. Global canvas coordinates are kept, so the burst stays on the target.
			var home: Node = (target as CanvasItem).get_canvas_layer_node()
			if home == null and target.get_viewport() != pool.get_viewport():
				home = target.get_viewport()
			var spawned: Array = []
			for i in range(before, pool.get_child_count()):
				spawned.append(pool.get_child(i))
			for em in spawned:
				(entry["emitters"] as Array).append(weakref(em))
				if home != null and is_instance_valid(home):
					em.reparent(home, true)

func _expire(entry: Dictionary) -> void:
	if _owned.has(entry):
		_owned.erase(entry)
		_release(entry)

## Stop one dispatch's work: targeted GFF stop (restores the node) unless a newer owned
## dispatch still plays on the same target, and free the Spark bursts it spawned.
func _release(entry: Dictionary) -> void:
	for wr in entry["emitters"]:
		var em = (wr as WeakRef).get_ref()
		if is_instance_valid(em) and not em.is_queued_for_deletion():
			em.queue_free()
	var target = (entry["target"] as WeakRef).get_ref()
	if not is_instance_valid(target) or not (target is Node2D or target is Node3D):
		return   # GFF only ever played on Node2D / Node3D targets: nothing to stop on a Control
	for other in _owned:
		if (other["target"] as WeakRef).get_ref() == target:
			return
	var gff = _gff()
	if gff != null:
		Callable(gff, "stop_all").call_deferred(target)

func _gff():
	if _use_override:
		return _gff_override
	return _compatible(_autoload(GFF_AUTOLOAD), GFF_SCRIPT, GFF_METHODS)

func _spark():
	if _use_override:
		return _spark_override
	return _compatible(_autoload(SPARK_AUTOLOAD), SPARK_SCRIPT, SPARK_METHODS)

## Use a plugin only when it is the audited installed script with every required method and
## has finished _ready() (a partially initialized autoload is treated as absent).
static func _compatible(node, script_path: String, methods: Array):
	if node == null or not is_instance_valid(node) or not node.is_inside_tree() or not node.is_node_ready():
		return null
	var s = node.get_script()
	if s == null or s.resource_path != script_path:
		return null
	for m in methods:
		if not node.has_method(m):
			return null
	return node

func _autoload(n: String):
	if _tree == null or _tree.root == null:
		return null
	return _tree.root.get_node_or_null(n)
