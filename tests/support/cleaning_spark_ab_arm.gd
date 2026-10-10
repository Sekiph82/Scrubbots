extends RefCounted
## CleaningSparkAbArm — EVIDENCE-ONLY B arm for M43-C005F-PHASE5 (SB-M43-C005F-011).
## NOT shipping: lives under tests/, is never preloaded by production code, and is attached
## to one live ProductionGameplayHost by a test / evidence tool only.
##
##   Arm A (baseline): the untouched production wiring
##       CompleteClearingLoop.authenticated_clear -> CleaningEffectsController._on_authenticated_clear
##   Arm B (this file): the SAME controller, reached through one wrapper on the SAME signal:
##       authenticated_clear -> request_effect(target)            (native M31 cue, unchanged)
##                           -> only if that native cue was ACCEPTED and not Reduced:
##                              FeedbackAdapter.play("SMALL", <that cue's own Node2D>)
##   so a cap-suppressed / invalid / unbound / disabled native cue never yields a Spark accent,
##   and a rejected or non-committed clear never reaches it (authenticated_clear is the only
##   source). The accent target is the native cue container (Node2D at cell centre x+0.5,
##   y+0.5 in the CleaningFxLayer), freed with the cue: no extra anchor node exists.
##
## The adapter is a dedicated FeedbackAdapter bound to the app's effects service, whose
## backends are set through its existing test seam to (GameFeelFlow ABSENT, the installed
## Saltmire Spark autoload): GFF is never used per cell. SMALL = the adapter's smallest
## particle tier: Spark preset `spark`, 4 particles, lifetime inside the 0.5 s SMALL ceiling.
## No direct Spark call exists here; Reduced = zero Spark (the arm skips the request and the
## adapter's REDUCED row would do no plugin work anyway). Nothing here writes gameplay truth.

var _host = null
var _fx = null          ## the host's real CleaningEffectsController
var _loop = null
var _feel = null
var _attached := false

## Counters for the A/B packet (B arm only; arm A is measured from the controller itself).
var authenticated := 0      ## authenticated_clear events observed
var native_accepted := 0    ## request_effect() == true
var native_rejected := 0    ## suppressed / invalid / disabled / unbound
var spark_requests := 0     ## FeedbackAdapter.play() calls (<= native_accepted)
var spark_accepted := 0     ## play() accepted
var peak_owned := 0         ## peak FeedbackAdapter.owned_count()

func attach(host, feel) -> bool:
	if _attached or host == null or feel == null:
		return false
	_host = host
	_fx = host.get_cleaning_fx()
	_loop = host.get_clearing_loop()
	_feel = feel
	if _fx == null or _loop == null:
		return false
	if _loop.authenticated_clear.is_connected(_fx._on_authenticated_clear):
		_loop.authenticated_clear.disconnect(_fx._on_authenticated_clear)
	_loop.authenticated_clear.connect(_on_authenticated_clear)
	_attached = true
	return true

## Restore exact arm-A wiring and cancel any B-arm decoration still owned by the adapter.
func detach() -> void:
	if not _attached:
		return
	if _loop.authenticated_clear.is_connected(_on_authenticated_clear):
		_loop.authenticated_clear.disconnect(_on_authenticated_clear)
	if not _loop.authenticated_clear.is_connected(_fx._on_authenticated_clear):
		_loop.authenticated_clear.connect(_fx._on_authenticated_clear)
	_feel.cancel_all()
	_attached = false

func is_attached() -> bool:
	return _attached

func get_feel():
	return _feel

func _on_authenticated_clear(_owner_id: int, target_index: int, _color_id: int, _agent) -> void:
	authenticated += 1
	request(target_index)

## One native request, then at most one Spark accent for an ACCEPTED native cue.
func request(target_index: int) -> bool:
	if not _fx.request_effect(target_index):
		native_rejected += 1
		return false
	native_accepted += 1
	if _fx.is_reduced_effects():
		return true   # Reduced: the native reduced puff only, zero Spark
	var layer: Node = _fx_layer()
	var cue = layer.get_child(layer.get_child_count() - 1) if layer != null and layer.get_child_count() > 0 else null
	if cue == null:
		return true
	spark_requests += 1
	if _feel.play("SMALL", cue):
		spark_accepted += 1
	peak_owned = maxi(peak_owned, _feel.owned_count())
	return true

## The presentation reset the host performs on a successful Retry, mirrored for B: the native
## controller already freed its cues (host._on_retry_restored); the adapter-owned Spark work of
## the previous attempt is cancelled here (targeted, never a plugin-global clear).
func on_attempt_reset() -> void:
	_feel.cancel_all()

func _fx_layer() -> Node:
	var screen = _host.get_screen() if _host.has_method("get_screen") else null
	var p = screen.get_presentation() if screen != null else null
	return p.get_cleaning_fx_layer() if p != null else null
