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
const FtueConfig = preload("res://scripts/app/ftue_config.gd")
const FtueDirector = preload("res://scripts/app/ftue_director.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const FeatureUnlocks = preload("res://scripts/progression/feature_unlocks.gd")

## M44 owner V03: the ONE ledger tx of the new-profile starter booster grant.
const STARTER_TX := "ftue_starter_boosters:v1"

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
var _builtin_catalog = null
## CP04/CP05: the ONE remote content authority (builtin + cached LKG at boot, no network).
## Content install never touches progression / economy / save truth.
var content: RemoteContentManager
## CP06: level numbers skipped this session (presentation notice only; durable truth is the
## progression skip ledger). Cleared when gameplay launches.
var skip_notice: Array = []
## M44: a fresh profile whose bootstrap could not be saved yet; retried (only while no save
## file exists) before the next canonical save so that save can never persist a profile
## that silently lost its starter grant.
var _bootstrap_pending := false
var _bootstrapping := false
var last_bootstrap: Dictionary = {}
## SB-M44-031: the owner feature unlock table (feature_unlocks_v1.json), read once.
var unlocks: FeatureUnlocks

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
	unlocks = FeatureUnlocks.new()
	unlocks.load_config()
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
## M46 RM005: the validated builtin catalog is loaded once per AppState (res:// never changes at
## runtime; every read is a deep copy), instead of re-validating all builtin levels + supply plans
## on every Results / launch (~15 ms each). An invalid manifest is not cached (re-checked).
func playable_catalog():
	if _builtin_catalog == null:
		var cat = LevelCatalog.new()
		if not cat.load_manifest().ok:
			return null
		_builtin_catalog = cat
	return CompositeLevelCatalog.new(_builtin_catalog, content.remote_levels() if content != null else [])

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

## SB-M44-031 — the ONE feature-unlock gate every UI asks. Grandfather rule (orchestrator
## default): a save that is NOT a new FTUE profile (existing / migrated / established) keeps
## every feature; a fresh profile unlocks a feature once its frontier reaches the table level.
## The frontier never decreases, so a reached feature stays unlocked.
func feature_unlocked(feature_id: String) -> bool:
	return unlocks.is_unlocked(feature_id, int(progression.current_level()), not economy.ftue.is_new_profile())

## Campaign level that unlocks `feature_id` (for "Unlocks at level N" copy; never hard-coded in UI).
func feature_unlock_level(feature_id: String) -> int:
	return unlocks.unlock_level(feature_id)

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
	if _bootstrap_pending and not _bootstrapping:
		var b: Dictionary = bootstrap_new_profile()
		if b.has("save"):
			return b["save"]
	var r: Dictionary = save.save()
	if r.get("ok", false):
		_dirty = false
	return r

## M44 owner V03 — the ONE new-profile bootstrap (app root calls it once per cold launch).
## Only a CONCLUSIVELY fresh profile qualifies: SaveService found no save artefact at all
## (load_result.fresh) and none has been written since. An existing / migrated / backup /
## corrupt / future-schema save is never re-classified. In one transaction it:
##   1. marks the FTUE profile "new" (tips + What's New presentation state);
##   2. grants exactly the configured starter charges (owner: 2 x +1 Slot / Random / Selector /
##      Tornado) through RewardGrantService under the single tx STARTER_TX;
##   3. installs today's Welcome task (DailyService index 0, ready to CLAIM, 100 SB);
## then saves. Save failure re-imports the exact pre-bootstrap economy (nothing half-granted)
## and keeps the bootstrap pending: it is retried only while no save file exists.
## Idempotent: a bootstrapped profile / applied STARTER_TX is a replay no-op.
## Returns {ok, reason[, replay, save, restored]}.
func bootstrap_new_profile() -> Dictionary:
	if is_blocked:
		return _boot_result({"ok": false, "reason": "app_blocked"})
	if economy.ftue.is_new_profile() or economy.reward.already_applied(STARTER_TX):
		_bootstrap_pending = false
		return _boot_result({"ok": true, "reason": "", "replay": true})
	if not bool(load_result.get("fresh", false)) or save.has_any_save_file():
		_bootstrap_pending = false
		return _boot_result({"ok": false, "reason": "not_fresh"})
	var cfg: Dictionary = FtueConfig.load_config()
	if not bool(cfg.get("ok", false)):
		_bootstrap_pending = false
		return _boot_result({"ok": false, "reason": "config_invalid:" + String(cfg.get("reason", ""))})
	var grant := {}
	for id in cfg["starter_booster_charges"]:
		if int(cfg["starter_booster_charges"][id]) > 0:
			grant[RewardedGrantService.RES_BOOSTER_PREFIX + String(id)] = int(cfg["starter_booster_charges"][id])
	var pre: Dictionary = economy.snapshot()
	economy.ftue.mark_new()
	# Owner D2: features/versions already in this build are taught by the tutorial / Help, not
	# announced. Baseline them as seen (presentation only, same transaction) so a newcomer only
	# ever gets What's New for a feature version added AFTER their profile was created.
	for e in cfg["whats_new"]:
		economy.meta_ui.mark_seen(FtueDirector.whats_new_key(e))
	var granted: bool = economy.reward.grant(STARTER_TX, grant)
	var welcomed: bool = economy.daily.set_first_day_welcome(economy.daily.local_day(), int(cfg["welcome_sb"]))
	if not granted or not welcomed:
		economy.import_snapshot(pre)
		_bootstrap_pending = false
		return _boot_result({"ok": false, "reason": "grant_failed" if not granted else "welcome_failed"})
	_bootstrapping = true
	var r: Dictionary = save.save()
	_bootstrapping = false
	if not bool(r.get("ok", false)):
		var restored: bool = economy.import_snapshot(pre)
		_bootstrap_pending = true
		return _boot_result({"ok": false, "reason": "save_failed", "save": r, "restored": restored})
	_bootstrap_pending = false
	_dirty = false
	return _boot_result({"ok": true, "reason": "", "save": r})

func _boot_result(r: Dictionary) -> Dictionary:
	last_bootstrap = r.duplicate(true)
	return r

func is_bootstrap_pending() -> bool:
	return _bootstrap_pending

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
## entry stays pending until acknowledge_earned_pack(). SB-M44-025: below the card_packs unlock
## (fresh profile, frontier < 20) nothing opens - the entry just stays queued.
func open_earned_pack(id: String) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	if not feature_unlocked("card_packs"):
		return {"ok": false, "reason": "locked"}
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

## M50-BOARD Color Symbols (board cells + Supply/Slots + booster chips): applies live (service
## `color_symbols_changed` -> ColorSymbols.set_enabled) and persists canonically. Refused while blocked.
func set_color_symbols(on: bool) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	effects.set_color_symbols(on)
	return request_save()

func set_volumes(master: float, music: float, sfx: float) -> Dictionary:
	if is_blocked:
		return {"ok": false, "reason": "app_blocked"}
	audio.set_master_volume(master)
	audio.set_music_volume(music)
	audio.set_sfx_volume(sfx)
	return request_save()
