extends RefCounted
## RewardedAdProvider — preload (res://scripts/economy/rewarded_ad_provider.gd).
##
## M43-C003 provider-neutral rewarded-video seam. This base class IS the production
## default: every placement is unavailable until M57 connects a real provider (SDK,
## placement ids, frequency/cooldown/caps, regional policy and No-Ads interaction are
## M57 decisions and live in that provider, never here or in popup UI).
##
## Contract for a real provider (and test doubles):
##   is_available(placement) -> bool   may this logical product be offered right now?
##   request(placement, token, deliver) -> bool
##       true = a video was started for `token`; the provider later calls
##       deliver.call(token, {"outcome": "completed"|"cancelled"|"skipped"|"failed"|"timeout",
##                            "verified": bool})
##       at most once per real result (duplicates are tolerated by RewardedGrantService).
##       false = refused / nothing shown.
## `placement` is a logical product key (e.g. "rewarded_heart"), not a provider id.

func is_available(_placement: String) -> bool:
	return false

func request(_placement: String, _token: String, _deliver: Callable) -> bool:
	return false
