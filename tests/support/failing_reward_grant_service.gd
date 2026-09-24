extends "res://scripts/economy/reward_grant_service.gd"
## FailingRewardGrantService — M38 V03 test double (SB-M38-016,
## F-M38-REOPEN-001). A TRUE RewardGrantService subclass, so it satisfies the
## typed `WinStreakService._init(reward: RewardGrantService, ...)` contract.
## The real parent is initialized with the test wallet (inherited wallet()
## returns that same wallet); grant() always fails and nothing is ever
## "already applied", driving WinStreakService's reward-failure branch.
## Counters let the test prove the branch really called through this double.

var grant_calls := 0
var already_applied_calls := 0

func _init(wallet = null) -> void:
	super(wallet)

func grant(_tx_id: String, _rewards: Dictionary) -> bool:
	grant_calls += 1
	return false

func already_applied(_tx_id: String) -> bool:
	already_applied_calls += 1
	return false
