extends SceneTree
## M55-C001 SB-M55-010 regression — discarded EconomyServices graphs must be released.
##
## Defect found by the M55 long-session run: EconomyServices / RewardGrantService store
## handler lambdas that capture their own graph, so every throw-away graph was a
## reference cycle. SaveService.validate_candidate builds one per validation (2 per
## durable save), and a no-AppState host builds one per host, so each durable save
## leaked 16 services + 1 RNG (~200 KB). Fix: EconomyServices.dispose() /
## RewardGrantService.release_handlers(), called by SaveService on its dry-run scratch
## and by a host on its private fallback economy.
##
## Sensitivity: sections 2 and 4 fail on the pre-fix code (Object count grows by ~17 per
## validated save / per fallback host).
##
## Run: godot --headless --path . -s res://tests/m55_economy_release_regression.gd

const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const AppState = preload("res://scripts/app/app_state.gd")
const Host = preload("res://scripts/gameplay/runtime/production_gameplay_host.gd")

const SAVES := 60
const HOSTS := 8

var _fail := 0
var _tmp: Array = []

func _initialize() -> void:
	await process_frame
	_dispose_frees_graph()
	await _save_loop_no_growth()
	_validation_semantics()
	await _fallback_host_no_growth()
	_canonical_graph_untouched()
	_cleanup()
	print("M55 ECONOMY RELEASE REGRESSION: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)

func _objects() -> int:
	return int(Performance.get_monitor(Performance.OBJECT_COUNT))

func _dispose_frees_graph() -> void:
	print("[1. dispose() releases a discarded graph]")
	var s = EconomyServices.new()
	var w_s: WeakRef = weakref(s)
	var w_reward: WeakRef = weakref(s.reward)
	var w_packs: WeakRef = weakref(s.packs)
	s.dispose()
	s = null
	_ok(w_s.get_ref() == null and w_reward.get_ref() == null and w_packs.get_ref() == null,
		"after dispose() and dropping the last reference, services/reward/packs are all freed")
	var k = EconomyServices.new()
	var w_k: WeakRef = weakref(k)
	k = null
	print("    (context) an UNdisposed dropped graph is %s" % ("still alive: handler-lambda cycle" if w_k.get_ref() != null else "freed"))

func _save_loop_no_growth() -> void:
	print("[2. %d durable saves through AppState -> SaveService do not grow Objects]" % SAVES)
	var app = AppState.new(_uniq("saves"))
	for _i in range(3):   # warm-up
		app.economy.wallet.credit(EconomyWallet.SCRUB_BUCKS, 1)
		app.mark_dirty()
		app.flush()
	await process_frame
	var o0 := _objects()
	var ok_saves := 0
	for i in range(SAVES):
		app.economy.wallet.credit(EconomyWallet.SCRUB_BUCKS, 1)
		app.mark_dirty()
		if app.flush().get("ok", false):
			ok_saves += 1
	await process_frame
	var d := _objects() - o0
	_ok(ok_saves == SAVES, "all %d saves succeeded" % SAVES)
	_ok(d <= 2, "Object count growth over %d validated saves = %d (pre-fix ~ +%d: 2 validations x 17 per save)" % [SAVES, d, SAVES * 34])

func _validation_semantics() -> void:
	print("[3. validate_candidate semantics unchanged]")
	var app = AppState.new(_uniq("val"))
	app.mark_dirty()
	_ok(app.flush().get("ok", false), "a valid profile saves")
	var good: Dictionary = app.save.collect()
	_ok(app.save.validate_candidate(good).get("ok", false), "live candidate validates ok")
	var bad: Dictionary = good.duplicate(true)
	bad["economy"]["reward"] = "not a dictionary"
	var o0 := _objects()
	var reasons := {}
	for _i in range(30):
		reasons[String(app.save.validate_candidate(bad).get("reason", ""))] = true
	_ok(reasons.keys() == ["economy_import"], "corrupt economy section still rejected as economy_import %s" % str(reasons.keys()))
	_ok(_objects() - o0 <= 2, "30 rejected validations do not grow Objects (%d)" % (_objects() - o0))

func _fallback_host_no_growth() -> void:
	print("[4. %d no-AppState hosts (private fallback economy) do not grow Objects]" % HOSTS)
	var counts: Array = []
	for _i in range(HOSTS):
		var h = Host.new()
		h.level_path = "res://data/levels/level_002_apple.json"
		h.supply_plan_path = "res://data/levels/supply/level_002_apple_supply_v1.json"
		h.auto_build = false
		get_root().add_child(h)
		h.build()
		h.free()
		await process_frame
		await process_frame
		counts.append(_objects())
	print("    Object count after each host: %s" % str(counts))
	# Engine-internal counts alternate by +/-3 between identical builds (seen with build-only
	# hosts too); a leak is monotonic (+17 per host pre-fix). Bound: window max - host 2 <= 4.
	var growth: int = counts.slice(1).max() - counts[1]
	_ok(growth <= 4, "Object growth over hosts 2..%d = %d (bound 4; pre-fix ~ +%d)" % [HOSTS, growth, (HOSTS - 2) * 17])

func _canonical_graph_untouched() -> void:
	print("[5. the canonical AppState graph keeps its handlers across saves]")
	var app = AppState.new(_uniq("canon"))
	for _i in range(5):
		app.mark_dirty()
		app.flush()
	var ids: Array = app.economy.collection.all_card_ids()
	var owned0 := 0
	for id in ids:
		owned0 += app.economy.collection.owned(id)
	_ok(app.economy.reward.has_handler("standard_card_packs") and app.economy.reward.has_handler(EconomyWallet.SCRUB_BUCKS),
		"canonical reward handlers still registered after 5 saves")
	var sb0: int = app.economy.wallet.scrub_bucks()
	_ok(app.economy.reward.grant("m55_regression_tx", {EconomyWallet.SCRUB_BUCKS: 7}) and app.economy.wallet.scrub_bucks() == sb0 + 7,
		"canonical reward grant still applies (+7 SB)")
	var granted: bool = app.economy.reward.grant("m55_regression_pack", {"standard_card_packs": 1})
	var owned1 := 0
	for id in ids:
		owned1 += app.economy.collection.owned(id)
	_ok(granted and owned1 > owned0, "canonical pack handler still opens a pack (%d -> %d cards)" % [owned0, owned1])

func _uniq(tag: String) -> String:
	var p := "user://m55_rel_%s_%d.save" % [tag, Time.get_ticks_usec()]
	_tmp.append(p)
	return p

func _cleanup() -> void:
	for p in _tmp:
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(p + suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(p + suffix))

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)
