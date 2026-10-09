extends RefCounted
## EconomyServices — preload
## (res://scripts/economy/economy_services.gd).
##
## Composition root for Economy & Rewards V1. Wires the single canonical wallet
## through every service, registers all RewardGrantService resource handlers so
## every reward bundle (first-clear, streak, gift milestone, daily) applies
## atomically, and exposes ONE aggregate snapshot/import contract that M40's
## SaveService persists. There is exactly one authority per resource — no
## duplicate wallet/reward/gift services.

const EconomyConfig = preload("res://scripts/economy/economy_config.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")
const WinStreakService = preload("res://scripts/economy/win_streak_service.gd")
const FirstClearRewardService = preload("res://scripts/economy/first_clear_reward_service.gd")
const RobotUnlockService = preload("res://scripts/progression/robot_unlock_service.gd")
const HeartService = preload("res://scripts/economy/heart_service.gd")
const SpeedEntitlementService = preload("res://scripts/economy/speed_entitlement_service.gd")
const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")
const RandomBoosterRewardPicker = preload("res://scripts/economy/random_booster_reward_picker.gd")
const SlotCapacityAuthority = preload("res://scripts/economy/slot_capacity_authority.gd")
const DailyService = preload("res://scripts/economy/daily_service.gd")
const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")
const CardPackService = preload("res://scripts/collection/card_pack_service.gd")
const PackReceiptLedger = preload("res://scripts/collection/pack_receipt_ledger.gd")
const PendingPackQueue = preload("res://scripts/collection/pending_pack_queue.gd")
const MetaUiState = preload("res://scripts/economy/meta_ui_state.gd")
const CeremonyEvents = preload("res://scripts/economy/ceremony_events.gd")
const PackPity = preload("res://scripts/collection/pack_pity.gd")
const CardsExchangeService = preload("res://scripts/economy/cards_exchange_service.gd")
const RewardedGrantService = preload("res://scripts/economy/rewarded_grant_service.gd")
const DailyOrders = preload("res://scripts/economy/daily_orders.gd")
const PlayerRecords = preload("res://scripts/economy/player_records.gd")
const EventService = preload("res://scripts/economy/event_service.gd")
const ReturnService = preload("res://scripts/economy/return_service.gd")
const NotificationPolicy = preload("res://scripts/economy/notification_policy.gd")
const RewardedDailyService = preload("res://scripts/economy/rewarded_daily_service.gd")

const GUARANTEED_NEW_FALLBACK_SB := 500

var config: EconomyConfig
var wallet: EconomyWallet
var reward: RewardGrantService
var gift: GiftMeterService
var streak: WinStreakService
var first_clear: FirstClearRewardService
var robots: RobotUnlockService
var hearts: HeartService
var speed: SpeedEntitlementService
var boosters: BoosterInventory
var capacity: SlotCapacityAuthority
var daily: DailyService
var collection: CollectionInventory
var packs: CardPackService
## M43-C005-C008 durable receipts of presented pack openings (written only by PackCommitTransaction).
var pack_receipts: PackReceiptLedger
## M43-C005F-PHASE2-R01: earned packs granted but not yet opened through the pack ceremony.
var pending_packs: PendingPackQueue
## M43 master: durable ceremony acknowledgements (presentation state, never a grant authority).
var meta_ui: MetaUiState
## M43-C007R: earned-pack pity counter (CardPackService reports every earned opening).
var pack_pity: PackPity
var exchange: CardsExchangeService
## M43-C003 rewarded-video grants (provider-neutral; production provider = unavailable).
var rewarded: RewardedGrantService
## M43-C009R: which order each of the three daily tasks is today + its play progress.
var orders: DailyOrders
## M43-C010R personal bests; C010 events; C012 return windows / Catch-Up; C012 notification policy.
var records: PlayerRecords
var events: EventService
var returns: ReturnService
var notify: NotificationPolicy
## M43-C015R Rewarded Ads daily track. No save section: state is derived from the canonical
## reward ledger (daily_rewarded:<day>:<slot> ids).
var rewarded_daily: RewardedDailyService

## local_day: Daily local-calendar ordinal provider (M39 V04, F-M39-V03-002).
## Omitted in production -> DailyService uses LocalCalendar.system_provider().
func _init(config_path: String = EconomyConfig.DEFAULT_PATH, clock: Callable = Callable(), pack_rng: RandomNumberGenerator = null, local_day: Callable = Callable()) -> void:
	config = EconomyConfig.new(config_path)
	wallet = EconomyWallet.new(config.starting_scrub_bucks())
	reward = RewardGrantService.new(wallet)
	gift = GiftMeterService.new()
	first_clear = FirstClearRewardService.new(reward, config)
	robots = RobotUnlockService.new(wallet, config.robot_unlock_cost(), config.initial_robot_id())
	hearts = HeartService.new(wallet, config, clock)
	speed = SpeedEntitlementService.new(wallet, config, clock)
	boosters = BoosterInventory.new(wallet, config)
	capacity = SlotCapacityAuthority.new()
	daily = DailyService.new(config, reward, clock, local_day)
	orders = DailyOrders.new(daily)
	records = PlayerRecords.new()
	events = EventService.new(clock)
	returns = ReturnService.new(clock)
	notify = NotificationPolicy.new()
	collection = CollectionInventory.new(config, reward)
	packs = CardPackService.new(collection, pack_rng)
	pack_receipts = PackReceiptLedger.new()
	pending_packs = PendingPackQueue.new()
	meta_ui = MetaUiState.new()
	pack_pity = PackPity.new(config)
	packs.pity = pack_pity
	exchange = CardsExchangeService.new(collection, reward, config)
	streak = WinStreakService.new(reward, gift)
	rewarded = RewardedGrantService.new(reward, hearts)
	rewarded_daily = RewardedDailyService.new(reward, rewarded, Callable(daily, "local_day"))
	_register_handlers()

func _register_handlers() -> void:
	# scrub_bucks / bot_parts already registered by RewardGrantService defaults.
	# M43-C005F-PHASE2-R01: an EARNED pack is never drawn silently here any more. The grant
	# enqueues N pending entries (stable ids from the parent reward tx); each is drawn exactly
	# once by PackCommitTransaction when the production PackPresenter opens its ceremony, and is
	# acknowledged only after that ceremony completed (see PendingPackQueue / PackPresenter).
	reward.register_handler("standard_card_packs", func(n):
		pending_packs.enqueue(reward.current_tx(), "standard", n))
	reward.register_handler("premium_card_packs", func(n):
		pending_packs.enqueue(reward.current_tx(), "premium", n))
	# SB-M39-054 (owner lock 2026-10-09): a random-any booster reward = per charge, one booster
	# picked uniformly from all four canonical boosters, derived from (parent tx, ordinal) so a
	# duplicate / retry / relaunch can never reroll. The legacy key is an alias with the SAME
	# meaning; it never maps to the gameplay booster RANDOM alone.
	var random_any := func(n):
		for i in range(n):
			boosters.add_charges(RandomBoosterRewardPicker.pick(reward.current_tx(), i), 1)
	reward.register_handler(RandomBoosterRewardPicker.RESOURCE, random_any)
	reward.register_handler(RandomBoosterRewardPicker.LEGACY_RESOURCE, random_any)
	# Player-selected charges go to the pending pool (player chooses later).
	reward.register_handler("selected_booster_charges", func(n):
		boosters.add_pending_selected(n))
	# Guaranteed-new card, with exact 500 SB fallback when no eligible card exists.
	reward.register_handler("guaranteed_new_cards", func(n):
		for _i in range(n):
			var cid := packs.grant_guaranteed_new()
			if cid.is_empty():
				wallet.credit(EconomyWallet.SCRUB_BUCKS, GUARANTEED_NEW_FALLBACK_SB))
	# The explicit fallback key is a no-op: the fallback is applied inside the
	# guaranteed_new_cards handler only when no card is available, so we never
	# double-grant it.
	reward.register_handler("guaranteed_new_fallback_sb", func(_n): pass)
	# M43-C003 rewarded grants (RewardedGrantService is the only caller; it pre-checks
	# Heart fullness, so grant_one never has to fail here).
	reward.register_handler(RewardedGrantService.RES_HEART, func(n):
		for _i in range(n):
			hearts.grant_one())
	for b in BoosterInventory.BOOSTERS:
		var id: String = b
		reward.register_handler(RewardedGrantService.RES_BOOSTER_PREFIX + id, func(n):
			boosters.add_charges(id, n))

## M55-C001 (SB-M55-010): release a graph that is being discarded. The reward handlers
## (registered above and RewardGrantService's own defaults) are lambdas that capture
## this graph, so without this call a dropped EconomyServices is a reference cycle that
## leaks every service it owns. Only for throw-away graphs (dry-run validation, a host's
## private fallback economy); the canonical AppState graph lives for the app lifetime.
func dispose() -> void:
	if reward != null:
		reward.release_handlers()

## Aggregate versioned snapshot (M40 persists this).
func snapshot() -> Dictionary:
	return {
		"reward": reward.snapshot(),
		"gift": gift.snapshot(),
		"streak": streak.snapshot(),
		"robots": robots.snapshot(),
		"hearts": hearts.snapshot(),
		"speed": speed.snapshot(),
		"boosters": boosters.snapshot(),
		"daily": daily.snapshot(),
		"collection": collection.snapshot(),
		"packs": packs.snapshot(),
		"pack_receipts": pack_receipts.snapshot(),
		"pending_packs": pending_packs.snapshot(),
		"meta_ui": meta_ui.snapshot(),
		"pack_pity": pack_pity.snapshot(),
		"daily_orders": orders.snapshot(),
		"records": records.snapshot(),
		"events": events.snapshot(),
		"return": returns.snapshot(),
		"notifications": notify.snapshot(),
	}

## Independently all-or-nothing import (F-M39-005). Captures the exact current
## live state first, then applies each section; if ANY section import fails, the
## captured backup is restored so the whole service graph is left exactly as it
## was before the call. Safe to call directly, not only through SaveService.
func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var backup := snapshot()
	if _apply_sections(s):
		return true
	# Roll back to the captured pre-call state. The backup was produced by our
	# own snapshot(), so every section import accepts it.
	_apply_sections(backup)
	return false

## Applies each section import in order; returns false on the first failure
## (leaving partial mutation for import_snapshot to roll back).
func _apply_sections(s) -> bool:
	if not reward.import_snapshot(s.get("reward", {})):
		return false
	if not gift.import_snapshot(s.get("gift", {})):
		return false
	if not streak.import_snapshot(s.get("streak", {})):
		return false
	if not robots.import_snapshot(s.get("robots", {})):
		return false
	if not hearts.import_snapshot(s.get("hearts", {})):
		return false
	if not speed.import_snapshot(s.get("speed", {})):
		return false
	if not boosters.import_snapshot(s.get("boosters", {})):
		return false
	if not daily.import_snapshot(s.get("daily", {})):
		return false
	if not collection.import_snapshot(s.get("collection", {})):
		return false
	# M43-C009R: absent = older save (orders generated on demand); present = strict.
	if not orders.import_snapshot(s["daily_orders"] if s.has("daily_orders") else null):
		return false
	# M43-C010 / C012: absent = older save (fresh); present = strict.
	for pair in [["records", records], ["events", events], ["return", returns], ["notifications", notify]]:
		if not pair[1].import_snapshot(s[pair[0]] if s.has(pair[0]) else null):
			return false
	# M43-C005-C008: key ABSENT = pre-C008 save (keep the live OS-seeded RNG / empty ledger).
	# Key PRESENT = strict C008 schema; an empty or partial section fails closed.
	if s.has("packs") and not packs.import_snapshot(s["packs"]):
		return false
	var ledger = s["pack_receipts"] if s.has("pack_receipts") else PackReceiptLedger.empty_snapshot()
	if not pack_receipts.import_snapshot(ledger):
		return false
	# M43-C005F-PHASE2-R01: absent = a save from before earned packs were queued (empty queue);
	# present = strict (a malformed section fails the whole import closed).
	if not pending_packs.import_snapshot(s["pending_packs"] if s.has("pending_packs") else PendingPackQueue.empty_snapshot()):
		return false
	# M43 master: absent = a save from before ceremonies existed -> every event it already
	# committed counts as seen (no backlog replay); present = strict.
	# M43-C007R: absent = older save (counter 0); present = strict.
	if s.has("pack_pity"):
		if not pack_pity.import_snapshot(s["pack_pity"]):
			return false
	elif not pack_pity.import_snapshot(PackPity.new().snapshot()):
		return false
	if s.has("meta_ui"):
		if not meta_ui.import_snapshot(s["meta_ui"]):
			return false
	else:
		# Owned cards also count as already viewed (no Collection NEW flood on an old save).
		var keys: Array = CeremonyEvents.keys(self)
		for cid in collection.all_card_ids():
			if collection.owned(cid) > 0:
				keys.append("card:" + String(cid))
		for rid in robots.snapshot().get("unlocked", []):
			keys.append("robot_seen:" + String(rid))
		meta_ui.baseline(keys)
	return true
