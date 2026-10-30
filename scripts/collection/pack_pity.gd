extends RefCounted
## PackPity — preload (res://scripts/collection/pack_pity.gd).
##
## M43-C007R (SB-M43-R07-001..004) — the versioned EARNED-pack pity counter. Every earned
## Standard / Premium pack opening (CardPackService; reward-granted packs and presented C008
## commits — there is no purchasable pack in V1) reports whether it produced at least one NEW
## card: no new card -> count + 1, any new card -> count = 0.
##
## Guarantee: when a configured threshold exists and count >= threshold, the next earned pack
## must contain at least one currently missing card (CardPackService applies it, keeping the
## Premium Rare-or-better card 0). The threshold is DATA (`collection.pity.threshold`),
## balance-simulated in docs/COLLECTION_PITY_FIRST_SPRINT_TUNING_V1.md (tools/sim_pack_pity.gd);
## absent / 0 = guarantee disabled. Nothing here can be bought, rerolled or accelerated.
##
## First Collection Sprint (SB-M43-R07-006): while Set 1 is incomplete and
## `collection.pity.first_sprint_threshold` > 0, "new" means a new SET 1 card and that threshold
## applies; the guaranteed missing card is then a Set 1 card (first_missing_eligible_card walks
## sets in order). Once Set 1 is complete the plain rule above applies for good.
##
## Section {version: 1, count: int >= 0}: strict when present; absent (older save) = 0.

const IntDomain = preload("res://scripts/economy/int_domain.gd")
const VERSION := 1
const SPRINT_SET := 1

var _count := 0
var _threshold := 0
var _sprint_threshold := 0
## Test-only seam (never set in production): replaces the configured threshold.
var threshold_override := -1

func _init(config = null) -> void:
	if config != null:
		var p = config.collection_config().get("pity", {})
		if typeof(p) == TYPE_DICTIONARY:
			var t = IntDomain.nonneg_int(p.get("threshold", 0))
			_threshold = int(t) if t != null else 0
			var st = IntDomain.nonneg_int(p.get("first_sprint_threshold", 0))
			_sprint_threshold = int(st) if st != null else 0

func count() -> int:
	return _count

## The set whose cards count as "new" for the counter: SPRINT_SET during the First Collection
## Sprint, 0 (any set) otherwise. `inventory` is the CollectionInventory; null = no sprint.
func focus_set(inventory) -> int:
	if threshold_override >= 0 or _sprint_threshold == 0 or inventory == null or inventory.is_set_complete(SPRINT_SET):
		return 0
	return SPRINT_SET

func threshold(inventory = null) -> int:
	if threshold_override >= 0:
		return threshold_override
	return _sprint_threshold if focus_set(inventory) > 0 else _threshold

## True when the next earned pack must contain a missing card.
func guarantee_due(inventory = null) -> bool:
	var t := threshold(inventory)
	return t > 0 and _count >= t

## One packs-away from a guarantee (for honest "NEW CARD GUARANTEED NEXT PACK" copy).
func guaranteed_next(inventory = null) -> bool:
	return guarantee_due(inventory)

func on_opened(had_new: bool) -> void:
	_count = 0 if had_new else _count + 1

func snapshot() -> Dictionary:
	return {"version": VERSION, "count": _count}

func import_snapshot(s) -> bool:
	if typeof(s) != TYPE_DICTIONARY or s.size() != 2 or not s.has("version") or not s.has("count"):
		return false
	if IntDomain.exact_int(s["version"]) != VERSION:
		return false
	var c = IntDomain.nonneg_int(s["count"])
	if c == null:
		return false
	_count = int(c)
	return true
