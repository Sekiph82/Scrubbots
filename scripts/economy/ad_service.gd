extends RefCounted
## AdService — preload (res://scripts/economy/ad_service.gd).
##
## SB-M57-001..011 (owner 2026-10-22) provider-independent ad policy. The provider (AdProvider;
## shipping default = the null base class) only shows ads; every decision is made here and
## asks StoreService.ads_allowed(kind) first, so No Ads removes the banner and interstitials
## and rewarded videos stay.
##
##   banner        bottom banner in the ad band, never over the board (update_banner)
##   interstitial  once every INTERVAL finished plays, shown only by main.gd's Results ->
##                 next attempt transition (between levels, never mid-level)
##   rewarded      opt-in; the provider is shared with RewardedGrantService, which grants
##                 only on a verified completed view (cancel / skip / fail grant nothing)
##
## A play = any finished level, win or loss (the gameplay host's terminal commit calls
## on_play_finished() once per attempt, saved by that same terminal save). An interstitial
## the provider could not show stays due until the next transition.

const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const IntDomain = preload("res://scripts/economy/int_domain.gd")

const INTERVAL := 5
const PLACEMENT_INTERSTITIAL := "interstitial_between_levels"

var _store
var _rewarded
var _provider
var _plays := 0                ## finished plays (persisted)
var _last_interstitial := 0    ## _plays when the last interstitial was shown (persisted)

func _init(store, rewarded, provider = null) -> void:
	_store = store
	_rewarded = rewarded
	set_provider(provider)

func set_provider(p) -> void:
	_provider = p if p != null else AdProvider.new()
	_rewarded.set_provider(_provider)
	update_banner()

func get_provider():
	return _provider

func allowed(kind: String) -> bool:
	return _store.ads_allowed(kind)

## Show / hide the bottom banner per the No Ads entitlement (call after a buy / restore).
func update_banner() -> void:
	_provider.set_banner(allowed("banner"))

func on_play_finished() -> void:
	_plays += 1

func plays() -> int:
	return _plays

func interstitial_due() -> bool:
	return allowed("interstitial") and _plays - _last_interstitial >= INTERVAL

## Between levels only (main.gd Home PLAY / Results Retry). True when an ad was shown.
func try_interstitial() -> bool:
	if not interstitial_due() or not _provider.show_interstitial(PLACEMENT_INTERSTITIAL):
		return false
	_last_interstitial = _plays
	return true

func snapshot() -> Dictionary:
	return {"plays": _plays, "last_interstitial": _last_interstitial}

## Absent (null) = a save from before ads existed (0 plays); present = strict.
func import_snapshot(s) -> bool:
	if s == null:
		_plays = 0
		_last_interstitial = 0
		return true
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var p = IntDomain.nonneg_int(s.get("plays"))
	var l = IntDomain.nonneg_int(s.get("last_interstitial"))
	if p == null or l == null or l > p:
		return false
	_plays = p
	_last_interstitial = l
	return true
