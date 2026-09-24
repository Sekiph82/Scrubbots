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
const SlotCapacityAuthority = preload("res://scripts/economy/slot_capacity_authority.gd")
const DailyService = preload("res://scripts/economy/daily_service.gd")
const CollectionInventory = preload("res://scripts/collection/collection_inventory.gd")
const CardPackService = preload("res://scripts/collection/card_pack_service.gd")
const CardsExchangeService = preload("res://scripts/economy/cards_exchange_service.gd")

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
var exchange: CardsExchangeService

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
	collection = CollectionInventory.new(config, reward)
	packs = CardPackService.new(collection, pack_rng)
	exchange = CardsExchangeService.new(collection, reward, config)
	streak = WinStreakService.new(reward, gift)
	_register_handlers()

func _register_handlers() -> void:
	# scrub_bucks / bot_parts already registered by RewardGrantService defaults.
	reward.register_handler("standard_card_packs", func(n):
		for _i in range(n):
			packs.open_standard())
	reward.register_handler("premium_card_packs", func(n):
		for _i in range(n):
			packs.open_premium())
	# "random Booster Charge" = a charge for the Random booster (owner wording).
	reward.register_handler("random_booster_charges", func(n):
		boosters.add_charges(BoosterInventory.RANDOM, n))
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
	return true
