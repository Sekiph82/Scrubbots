extends RefCounted
## GiftProgressModel — preload (res://scripts/economy/gift_progress_model.gd).
##
## M43-C005R (SB-M43-R05-001/002) — the ONE normalized, read-only Gift Meter progress model
## shared by Home, Results and the Gift Bar. It is a pure function of the committed cycle
## progress and the canonical milestones (GiftMeterService: 10 / 50 / 250 / 500 / 1000):
##
##   {progress, cycle_max, prev, next, segment_fraction, ticks, ticks_reached, cycle_fraction}
##
## `ticks` splits the CURRENT milestone gap (prev -> next) into TICKS equal micro-ticks purely
## for presentation so a long gap (e.g. 500 -> 1000) visibly advances. A micro-tick is NOT a
## threshold: it mints no reward, creates no economic state and cannot be claimed. Rewards
## remain the authoritative milestone bundles queued by GiftMeterService.

const GiftMeterService = preload("res://scripts/economy/gift_meter_service.gd")

const TICKS := 10

static func build(progress: int, cycle_max: int = GiftMeterService.CYCLE_MAX, milestones: Array = GiftMeterService.MILESTONES) -> Dictionary:
	var p := clampi(progress, 0, maxi(cycle_max - 1, 0))
	var prev := 0
	var next := cycle_max
	for m in milestones:
		if int(m) <= p:
			prev = int(m)
		elif int(m) < next:
			next = int(m)
	var gap := maxi(next - prev, 1)
	var frac := float(p - prev) / float(gap)
	return {"progress": p, "cycle_max": cycle_max, "prev": prev, "next": next,
		"segment_fraction": frac, "ticks": TICKS, "ticks_reached": int(floor(frac * TICKS + 1e-9)),
		"cycle_fraction": float(p) / float(maxi(cycle_max, 1))}

static func from_service(gift) -> Dictionary:
	return build(gift.cycle_progress())
