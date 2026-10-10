extends RefCounted
## AppState — preload
## (res://scripts/app/app_state.gd).
##
## App-level canonical composition root for durable state (M40 V03,
## F-M40-V02-001). Owns exactly ONE instance of each canonical service graph
## used by the shipping runtime:
##   - AudioSettingsService (M33)
##   - HapticsSettingsService (M34)
##   - EffectsSettingsService (M41-C002 Reduced Effects)
##   - LevelProgressionService (M37)
##   - EconomyServices (M39)
##   - SaveService (M40) — bound to the above, using the canonical save path.
##
## ProductionGameplayHost consumes this graph instead of creating a second
## progression/economy/settings authority. Tests inject an isolated instance
## via a temp save path so no real user:// files are touched.
##
## Bootstrap policy (F-M40-V02-002/-008):
##   1. build the graph;
##   2. call SaveService.load();
##   3. `load_result` records {ok, source, reason?} for the runtime to consult;
##   4. if source == "future_schema", `is_blocked` is true and the app must
##      refuse to run normal gameplay (host halts build).

const AudioSettingsService = preload("res://scripts/audio/audio_settings_service.gd")
const HapticsSettingsService = preload("res://scripts/haptics/haptics_settings_service.gd")
const LevelProgressionService = preload("res://scripts/progression/level_progression_service.gd")
const EconomyServices = preload("res://scripts/economy/economy_services.gd")
const SaveService = preload("res://scripts/save/save_service.gd")
const EffectsSettingsService = preload("res://scripts/settings/effects_settings_service.gd")
const LocalCalendar = preload("res://scripts/economy/local_calendar.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const ProductionActionFacade = preload("res://scripts/economy/production_action_facade.gd")
const FailureAssistanceService = preload("res://scripts/economy/failure_assistance_service.gd")
const PackCommitTransaction = preload("res://scripts/collection/pack_commit_transaction.gd")
const LevelCatalog = preload("res://scripts/data/level_catalog.gd")
const RemoteContentManager = preload("res://scripts/content_runtime/remote_content_manager.gd")
const CompositeLevelCatalog = preload("res://scripts/content_runtime/composite_level_catalog.gd")

const CANONICAL_SAVE_PATH := "user://scrubbots_save.dat"

var audio: AudioSettingsService
var haptics: HapticsSettingsService
## M41-C002 canonical Reduced Effects setting (default OFF).
var effects: EffectsSettingsService
var progression: LevelProgressionService
var economy: EconomyServices
var save: SaveService
var load_result: Dictionary = {}
var is_blocked: bool = false
## App-wide economy action facade (menus/Home; no gameplay host). Committed
## actions save through request_save (M40 V04, F-M40-V03-003).
var actions: ProductionActionFacade
## M43-C004 same-level failure counter / Need a Hand choice (session-scoped, not saved).
var assist: FailureAssistanceService
var _dirty: bool = false
var _catalog_orders: Array = []
## CP04/CP05: the ONE remote content authority (builtin + cached LKG at boot, no network).
## Content install never touches progression / economy / save truth.
var content: RemoteContentManager
## CP06: level numbers skipped this session (presentation notice only; durable truth is the
## progression skip ledger). Cleared when gameplay launches.
var skip_notice: Array = []

## clock/local_day are test seams. Production passes neither: the shipping graph
## injects the real OS local-calendar provider explicitly (F-M39-V03-002).
## content_root: remote content cache root; default user://content/ for the canonical
## save, and an isolated sibling dir for test save paths (tests never touch the real cache).
func _init(save_path: String = CANONICAL_SAVE_PATH, clock: Callable = Callable(), local_day: Callable = Callable(), content_root: String = "") -> void:
	audio = AudioSettingsService.new()
	haptics = HapticsSettingsService.new()
	effects = EffectsSettingsService.new()
	progression = LevelProgressionService.new()
	var day_provider: Callable = local_day if local_day.is_valid() else LocalCalendar.system_provider()
	economy = EconomyServices.new(EconomyConfig.DEFAULT_PATH, clock, null, day_provider)
	save = SaveService.new(save_path, audio, haptics, progression, economy, effects)
	load_result = save.load()
	is_blocked = not bool(load_result.get("ok", false)) and String(load_result.get("source", "")) == "future_schema"
	actions = ProductionActionFacade.new(economy, null, Callable(self, "request_save"))
	economy.orders.bind_context(Callable(self, "orders_context"))
	assist = FailureAssistanceService.new()
	# M43-C003: a committed rewarded grant hits the canonical save boundary.
	economy.rewarded.bind_save(Callable(self, "request_save"))
	var croot := content_root
	if croot.is_empty():
		croot = RemoteContentManager.DEFAULT_ROOT if save_path == CANONICAL_SAVE_PATH else save_path.get_basename() + "_content/"
	content = RemoteContentManager.new(croot, null, Callable(self, "_builtin_ids"))
	content.boot()
	content.content_changed.connect(Callable(self, "_on_content_changed"))
	# CP06: cold/offline boot applies the cached LKG disabled set (idempotent retry after a
	# crash between registry activation and the skip save).
	reconcile_disabled_frontier()

## Builtin + verified active remote levels (CompositeLevelCatalog); null when the builtin
## production catalog itself is invalid (callers report CATALOG_INVALID).
func playable_catalog():
	var cat = LevelCatalog.new()
	if not cat.load_manifest().ok:
		return null
	return CompositeLevelCatalog.new(cat, content.remote_levels() if content != null else [])

func _builtin_ids() -> Array:
	var cat = LevelCatalog.new()
	cat.load_manifest()
	return cat.get_entries_ordered().map(func(e): return e.id)

func _on_content_changed() -> void:
	_catalog_orders.clear()
	reconcile_disabled_frontier()

## CP06 owner option B (OWNER_DISABLED_FRONTIER_DECISION_V02): while the CURRENT frontier is a
## remote level the verified active manifest disables, record a non-rewarding skip (provenance:
## exact id + content_version + manifest sha) and move to the next number. Never a win: no
## record_win, no economy / streak / Daily / achievement touch. Bounded by the remote level
## count; stops at the first frontier that is not an explicitly disabled remote entry (missing
## content stays CONTENT_MISSING, builtin levels are never skipped). Durable first: if the save
## fails the exact pre-skip progression is restored and nothing is reported as skipped.
## Idempotent: a second call with the same content is a no-op. Returns {ok, skipped[, reason, save]}.
func reconcile_disabled_frontier() -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked", "skipped": []}
	if content == null:
		return {"ok": true, "skipped": []}
	var disabled: Array = content.disabled_level_ids()
	var prov: Dictionary = content.active_provenance()
	if disabled.is_empty() or prov.is_empty():
		return {"ok": true, "skipped": []}
	var cat = playable_catalog()
	if cat == null:
		return {"ok": false, "reason": "CATALOG_INVALID", "skipped": []}
	var remote_ids := {}
	for rl in content.remote_levels():
		remote_ids[String(rl["id"])] = true
	var by_order := {}
	for e in cat.get_entries_ordered():
		by_order[int(e.order)] = String(e.id)
	var pre: Dictionary = progression.snapshot()
	var skipped: Array = []
	while skipped.size() < remote_ids.size():
		var n := int(progression.current_level())
		var id := String(by_order.get(n, ""))
		if id.is_empty() or not remote_ids.has(id) or not disabled.has(id):
			break
		if not progression.record_skip(n, id, int(prov["content_version"]), String(prov["manifest_sha256"])):
			break
		skipped.append(n)
	if skipped.is_empty():
		return {"ok": true, "skipped": []}
	var r: Dictionary = request_save()
	if not bool(r.get("ok", false)):
		var restored: bool = progression.import_snapshot(pre)
		return {"ok": false, "reason": "skip_save_failed", "skipped": [], "save": r, "restored": restored}
	skip_notice.append_array(skipped)
	return {"ok": true, "skipped": skipped, "save": r}

## M43-C009R: read-only eligibility context for Daily Scrub Orders: the progression frontier,
## its class lookup and how many catalog levels are playable from the frontier on.
func orders_context() -> Dictionary:
	var frontier := int(progression.current_level())
	if _catalog_orders.is_empty():
		var cat = playable_catalog()
		if cat != null:
			for e in cat.get_entries_ordered():
				_catalog_orders.append(int(e.order))
	# CP06: a disabled level ahead is skipped, never played, so it is not counted as playable.
	var disabled_orders := {}
	if content != null and not content.disabled_level_ids().is_empty():
		var cat = playable_catalog()
		if cat != null:
			for e in cat.get_entries_ordered():
				if content.is_level_disabled(String(e.id)):
					disabled_orders[int(e.order)] = true
	var ahead := 0
	var n := frontier
	while _catalog_orders.has(n):
		if not disabled_orders.has(n):
			ahead += 1
		n += 1
	return {"frontier": frontier, "playable_ahead": ahead, "class_for": Callable(progression, "class_for")}

## True when the app must not proceed to gameplay against fresh defaults
## (F-M40-V02-002/-008: future/unsupported schema case).
func blocked_reason() -> String:
	return String(load_result.get("source", ""))

## Canonical durable save (M40 V04). Called by the action facade after every
## committed durable action, by the gameplay host at its save boundaries and by
## flush(). Never writes while blocked (future-schema save is preserved).
func request_save() -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	var r: Dictionary = save.save()
	if r.get("ok", false):
		_dirty = false
	return r

## M43-C005-C008 (SB-M43-066): the canonical pack-opening commit for presentation. kind is
## "standard" | "premium"; tx_id is the caller's stable transaction id. Returns
## {ok, replay, receipt, model} only after the commit is durably saved (see
## PackCommitTransaction); the same tx_id always returns the same receipt and never draws again.
## Feed `model` to StandardPackCeremony.create / PremiumPackCeremony.create_premium.
func commit_pack(kind: String, tx_id: String) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	return PackCommitTransaction.commit(economy, kind, tx_id, Callable(self, "request_save"))

## M43-C005F-PHASE2-R01: open the pending EARNED pack `id` through the canonical commit (its
## kind comes from the durable queue entry; the entry id is the pack tx / presentation id).
## A pack already committed (app killed mid-ceremony) replays its receipt, never redraws. The
## entry stays pending until acknowledge_earned_pack().
func open_earned_pack(id: String) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	for e in economy.pending_packs.entries():
		if e["id"] == id:
			return commit_pack(String(e["kind"]), id)
	return {"ok": false, "reason": "not_pending"}

## Acknowledge a pending earned pack after its ceremony completed. Refused unless its receipt
## is committed (the cards are really in Collection). R02: DURABLE + transactional - the entry
## is removed only if the canonical save succeeds; on a save failure the exact pre-ack economy
## snapshot is re-imported (same entry back at the same FIFO position, receipt / Collection /
## RNG / pity untouched - nothing is redrawn) and the outer result is ok:false.
func acknowledge_earned_pack(id: String) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	if economy.pack_receipts.get_receipt(id).is_empty():
		return {"ok": false, "reason": "not_committed"}
	if not economy.pending_packs.has(id):
		return {"ok": false, "reason": "not_pending"}
	var pre: Dictionary = economy.snapshot()
	economy.pending_packs.remove(id)
	var r: Dictionary = request_save()
	if bool(r.get("ok", false)):
		return {"ok": true, "save": r}
	var restored: bool = economy.import_snapshot(pre)
	return {"ok": false, "reason": "ack_save_failed", "save": r, "restored": restored}

## Committed receipt / presentation model for tx_id ({} when none). Read-only.
func pack_receipt(tx_id: String) -> Dictionary:
	return PackCommitTransaction.receipt(economy, tx_id)

func pack_presentation_model(tx_id: String) -> Dictionary:
	return PackCommitTransaction.presentation_model(economy, tx_id)

## Mark in-memory durable state as pending (no write). Flushed at the next
## lifecycle boundary. Not per-frame.
func mark_dirty() -> void:
	_dirty = true

func is_dirty() -> bool:
	return _dirty

## Lifecycle flush (background/pause, focus loss, close/quit). Writes the
## canonical save once; lifecycle events are rare, so this also captures any
## state a caller forgot to mark dirty. Refused while blocked.
func flush() -> Dictionary:
	return request_save()

# ----------------------------------------------------- settings actions ----
# Settings mutate only through these app actions, which persist canonically.

func set_haptics_enabled(enabled: bool) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	haptics.set_enabled(enabled)
	return request_save()

## M41 V01 live audio actions. `bus` is "master" | "music" | "sfx". The value applies to
## the AudioServer immediately. persist=false (slider drag in progress) only marks the state
## dirty; the Settings UI saves on drag end / close and the app lifecycle flush covers the
## rest. Unknown bus => rejected, nothing mutated.
func set_audio_volume(bus: String, value: float, persist: bool = true) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	match bus:
		"master": audio.set_master_volume(value)
		"music": audio.set_music_volume(value)
		"sfx": audio.set_sfx_volume(value)
		_: return {"ok": false, "reason": "unknown_bus"}
	if not persist:
		mark_dirty()
		return {"ok": true, "pending": true}
	return request_save()

## M41 V01 channel ON/OFF (OFF mutes, keeps the slider value). Applies live and persists.
func set_audio_enabled(bus: String, on: bool) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	match bus:
		"master": audio.set_master_enabled(on)
		"music": audio.set_music_enabled(on)
		"sfx": audio.set_sfx_enabled(on)
		_: return {"ok": false, "reason": "unknown_bus"}
	return request_save()

## Save only when a deferred settings change is pending (Settings drag end / close).
func flush_if_dirty() -> Dictionary:
	if not _dirty:
		return {"ok": true, "skipped": true}
	return request_save()

## M41-C002 Reduced Effects: applies live (service `changed` -> gameplay cleaning FX) and
## persists canonically. Refused while blocked.
func set_reduced_effects(on: bool) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	effects.set_reduced(on)
	return request_save()

func set_volumes(master: float, music: float, sfx: float) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	audio.set_master_volume(master)
	audio.set_music_volume(music)
	audio.set_sfx_volume(sfx)
	return request_save()
