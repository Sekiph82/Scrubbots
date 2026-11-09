extends "res://scripts/economy/rewarded_ad_provider.gd"
## AdProvider — preload (res://scripts/economy/ad_provider.gd).
##
## SB-M57-001..011 provider-neutral ad seam (Google AdMob plugs in here, SB-M57-022). One
## provider object serves all three owner 2026-10-22 ad kinds; it extends the M43-C003
## RewardedAdProvider, so AdService hands the same object to RewardedGrantService and a
## rewarded video still grants only through RewardedGrantService.resolve(). This base class
## IS the shipping default (the null provider): no banner, no interstitial, no rewarded
## video, no SDK and no network.
##
## Contract for a real provider (and test doubles), in addition to the rewarded contract:
##   set_banner(visible)              show / hide the bottom banner, anchored in the ad band
##       below the board (never over it).
##   show_interstitial(placement) -> bool   true = a full-screen ad was shown. AdService
##       calls it only between levels (Results -> next attempt), never during gameplay.

func set_banner(_visible: bool) -> void:
	pass

func show_interstitial(_placement: String) -> bool:
	return false
