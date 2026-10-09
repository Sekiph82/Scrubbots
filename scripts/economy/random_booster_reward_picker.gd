extends RefCounted
## RandomBoosterRewardPicker — preload
## (res://scripts/economy/random_booster_reward_picker.gd).
##
## SB-M39-054 (owner lock 2026-10-09,
## coordination/OWNER_RANDOM_ANY_BOOSTER_REWARD_CORRECTION_V01.md): a "random booster" META
## reward means ONE booster chosen uniformly from ALL FOUR canonical boosters
## (BoosterInventory.BOOSTERS), not the gameplay booster named RANDOM.
##
## Pure and stateless: charge `ordinal` of reward transaction `tx_id` maps to
## SHA-256(UTF-8 "<tx_id>|random_any_booster|<ordinal>"), the first four bytes read as an
## unsigned big-endian integer, modulo the pool size. 2^32 is a multiple of 4, so every pool
## index is exactly equally likely at the algorithm level. The same (tx, ordinal) always yields
## the same booster on every platform / retry / relaunch; no RNG (gameplay, pack, level,
## solver) is consumed and nothing is persisted — RewardGrantService's applied-tx ledger is the
## only idempotency authority.

const BoosterInventory = preload("res://scripts/economy/booster_inventory.gd")

## Canonical reward resource key.
const RESOURCE := "random_any_booster_charges"
## Legacy key: accepted ONLY as an alias with the same random-any meaning (never RANDOM-only).
const LEGACY_RESOURCE := "random_booster_charges"
const DOMAIN := "random_any_booster"

## Pool index in 0..BOOSTERS.size()-1 for (tx_id, ordinal).
static func index(tx_id: String, ordinal: int) -> int:
	var h := ("%s|%s|%d" % [tx_id, DOMAIN, ordinal]).sha256_buffer()
	var u := (h[0] << 24) | (h[1] << 16) | (h[2] << 8) | h[3]
	return u % BoosterInventory.BOOSTERS.size()

## Canonical booster id selected for charge `ordinal` of `tx_id`.
static func pick(tx_id: String, ordinal: int) -> String:
	return BoosterInventory.BOOSTERS[index(tx_id, ordinal)]
