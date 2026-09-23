extends RefCounted
## FirstClearRewardService — preload
## (res://scripts/economy/first_clear_reward_service.gd).
##
## Grants the owner-locked first-clear economic rewards (SB-M39-005/006):
## base SB by difficulty (EASY 50 / MEDIUM 75 / HARD 100 / VERY_HARD 150) plus
## +1 Bot Part, ONCE per progression level. Replay and duplicate callbacks never
## farm — a stable per-level transaction id routes through RewardGrantService.
##
## This is DISTINCT from Win Streak SB (M38). Base first-clear SB must NOT feed
## the Gift Meter (owner §4), so this service never calls GiftMeterService.

const RewardGrantService = preload("res://scripts/economy/reward_grant_service.gd")
const EconomyWallet = preload("res://scripts/economy/economy_wallet.gd")
const EconomyConfig = preload("res://scripts/economy/economy_config.gd")

var _reward: RewardGrantService
var _config: EconomyConfig

func _init(reward: RewardGrantService, config: EconomyConfig) -> void:
	_reward = reward
	_config = config

## Grant first-clear rewards for `level_number` of `difficulty`. Returns
## {applied, scrub_bucks, bot_parts}. Idempotent + replay-safe.
func grant_first_clear(level_number: int, difficulty: String, is_replay: bool = false) -> Dictionary:
	if is_replay or level_number < 1:
		return {"applied": false, "scrub_bucks": 0, "bot_parts": 0}
	var sb := _config.first_clear_sb(difficulty)
	var bp := _config.first_clear_bot_parts()
	if sb <= 0 and bp <= 0:
		return {"applied": false, "scrub_bucks": 0, "bot_parts": 0}
	var tx := "first_clear:L%d" % level_number
	var applied := _reward.grant(tx, {
		EconomyWallet.SCRUB_BUCKS: sb,
		EconomyWallet.BOT_PARTS: bp,
	})
	return {"applied": applied, "scrub_bucks": sb if applied else 0, "bot_parts": bp if applied else 0}
