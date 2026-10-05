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
## Premium Rare-or-better card 0). The threshold is DATA (`collection.pity.threshold`) that must
## be balance-simulated (M56) and owner-approved; absent / 0 = guarantee disabled. Nothing here
## can be bought, rerolled or accelerated.
##
## Section {version: 1, count: int >= 0}: strict when present; absent (older save) = 0.

const IntDomain = preload("res://scripts/economy/int_domain.gd")
const VERSION := 1

var _count := 0
var _threshold := 0
## Test-only seam (never set in production): replaces the configured threshold.
var threshold_override := -1

func _init(config = null) -> void:
	if config != null:
		var p = config.collection_config().get("pity", {})
		if typeof(p) == TYPE_DICTIONARY:
			var t = IntDomain.nonneg_int(p.get("threshold", 0))
			_threshold = int(t) if t != null else 0

func count() -> int:
	return _count

func threshold() -> int:
	return threshold_override if threshold_override >= 0 else _threshold

## True when the next earned pack must contain a missing card.
func guarantee_due() -> bool:
	return threshold() > 0 and _count >= threshold()

## One packs-away from a guarantee (for honest "NEW CARD GUARANTEED NEXT PACK" copy).
func guaranteed_next() -> bool:
	return guarantee_due()

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
