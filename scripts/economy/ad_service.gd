extends RefCounted
## AdService — preload (res://scripts/economy/ad_service.gd).
##
## SB-M57-001..011 (owner 2026-10-22) provider-independent ad policy. The provider (AdProvider;
## shipping default = the null base class) only shows ads; every decision is made here and
## asks StoreService.ads_allowed(kind) first, so No Ads removes the banner, interstitials and
## the App Open ad, and rewarded videos stay.
##
##   banner        bottom banner in the ad band, never over the board (update_banner)
##   interstitial  none before level interstitial.min_level, then once every interval_plays
##                 finished plays (data/config/ad_placements_v1.json, SB-TF-07 owner 2026-11-18),
##                 shown only by main.gd's Results -> next attempt transition (never mid-level)
##   app_open      SB-TF-07: once per local day from progression level app_open.min_level, never
##                 on the install day (first_day = the profile's first launch day, note_launch()),
##                 tried by main.gd once per cold boot after the opening video (try_app_open)
##   rewarded      opt-in; the provider is shared with RewardedGrantService, which grants
##                 only on a verified completed view (cancel / skip / fail grant nothing)
##
## A play = any finished level, win or loss (the gameplay host's terminal commit calls
## on_play_finished(level) once per attempt, saved by that same terminal save). A play below
## the interstitial min_level counts in plays() but not toward the cadence. An interstitial
## the provider could not show stays due until the next transition. A missing / invalid
## placement config turns interstitial and App Open off (banner / rewarded unaffected).

const AdProvider = preload("res://scripts/economy/ad_provider.gd")
const IntDomain = preload("res://scripts/economy/int_domain.gd")

const PATH := "res://data/config/ad_placements_v1.json"
const SCHEMA := "scrubbots.ad_placements.v1"
const POLICY_VERSION := 2
const PLACEMENT_INTERSTITIAL := "interstitial_between_levels"
const PLACEMENT_APP_OPEN := "app_open_launch"

var _store
var _rewarded
var _provider
var _cfg := {}                 ## validated ad_placements_v1.json; {} = interstitial + App Open off
var _today: Callable           ## local-calendar day (DailyService.local_day)
var _level := Callable()       ## progression frontier (bind_level)
var _on_placement := Callable()   ## (event, params) analytics sink (on_placement)
var _plays := 0                ## finished plays (persisted)
var _last_interstitial := 0    ## _plays when the last interstitial was shown / cadence start (persisted)
var _first_day := -1           ## install day = local day of the profile's first launch (persisted)
var _app_open_day := -1        ## local day of the last shown App Open ad (persisted)

func _init(store, rewarded, provider = null, local_day: Callable = Callable(), path: String = PATH) -> void:
	_store = store
	_rewarded = rewarded
	_today = local_day
	load_config(path)
	set_provider(provider)

## Reads + validates the placement policy; anything unexpected disables interstitial + App Open.
func load_config(path: String) -> void:
	_cfg = {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if typeof(d) != TYPE_DICTIONARY or d.get("schema") != SCHEMA or IntDomain.exact_int(d.get("policy_version")) != POLICY_VERSION:
		return
	var i = d.get("interstitial")
	var o = d.get("app_open")
	if typeof(i) != TYPE_DICTIONARY or typeof(o) != TYPE_DICTIONARY or typeof(o.get("skip_install_day")) != TYPE_BOOL:
		return
	var cfg := {"inter_min": IntDomain.exact_int(i.get("min_level")), "inter_every": IntDomain.exact_int(i.get("interval_plays")),
		"open_min": IntDomain.exact_int(o.get("min_level")), "open_per_day": IntDomain.exact_int(o.get("max_per_day"))}
	for k in cfg:
		if cfg[k] == null or cfg[k] < 1:
			return
	if cfg["open_per_day"] != 1:   # the one-per-day ledger (app_open_day) supports exactly 1
		return
	cfg["skip_install_day"] = o["skip_install_day"]
	_cfg = cfg

func config_ok() -> bool:
	return not _cfg.is_empty()

func set_provider(p) -> void:
	_provider = p if p != null else AdProvider.new()
	_rewarded.set_provider(_provider)
	update_banner()

func get_provider():
	return _provider

## Callable() -> int: the progression frontier (AppState wires progression.current_level).
func bind_level(cb: Callable) -> void:
	_level = cb

## Callable(event, params): receives one ad_placement event per asked placement (analytics.track).
func on_placement(cb: Callable) -> void:
	_on_placement = cb

func allowed(kind: String) -> bool:
	return _store.ads_allowed(kind)

## Show / hide the bottom banner per the No Ads entitlement (call after a buy / restore).
func update_banner() -> void:
	_provider.set_banner(allowed("banner"))

## `level` = the level just played (production_gameplay_host progression_level).
func on_play_finished(level: int) -> void:
	_plays += 1
	if _cfg.is_empty() or level < int(_cfg["inter_min"]):
		_last_interstitial = _plays   # below the gate: counted, never banked toward the cadence

func plays() -> int:
	return _plays

func interstitial_due() -> bool:
	return not _cfg.is_empty() and allowed("interstitial") and _plays - _last_interstitial >= int(_cfg["inter_every"])

## Between levels only (main.gd Home PLAY / Results Retry). True when an ad was shown.
func try_interstitial() -> bool:
	if not interstitial_due():
		return false
	var shown: bool = _provider.show_interstitial(PLACEMENT_INTERSTITIAL)
	_track("interstitial", shown)
	if shown:
		_last_interstitial = _plays
	return shown

## Once per boot: records the install day on the profile's first launch. True = state changed.
func note_launch() -> bool:
	if _first_day >= 0 or not _today.is_valid():
		return false
	_first_day = int(_today.call())
	return true

func first_day() -> int:
	return _first_day

func app_open_day() -> int:
	return _app_open_day

## Every App Open gate except the provider (No Ads, level, install day, once per local day).
func app_open_eligible() -> bool:
	if _cfg.is_empty() or not allowed("app_open") or not _today.is_valid() or not _level.is_valid():
		return false
	if int(_level.call()) < int(_cfg["open_min"]):
		return false
	var day := int(_today.call())
	if _cfg["skip_install_day"] and (_first_day < 0 or day <= _first_day):
		return false
	return day > _app_open_day   # strictly later: a clock moved back never re-enables it

## main.gd, once per cold boot after the Home entry that follows the opening. Only a shown ad
## consumes the day.
func try_app_open() -> bool:
	if not app_open_eligible():
		return false
	var shown: bool = _provider.show_app_open(PLACEMENT_APP_OPEN)
	_track("app_open", shown)
	if shown:
		_app_open_day = int(_today.call())
	return shown

func _track(placement: String, shown: bool) -> void:
	if _on_placement.is_valid():
		_on_placement.call("ad_placement", {"placement": placement, "shown": shown, "reason": "shown" if shown else "no_fill"})

func snapshot() -> Dictionary:
	return {"plays": _plays, "last_interstitial": _last_interstitial, "first_day": _first_day, "app_open_day": _app_open_day}

## Absent (null) = a save from before ads existed (0 plays); present = strict. first_day /
## app_open_day absent = a save from before SB-TF-07 (-1); present = an int >= -1.
func import_snapshot(s) -> bool:
	if s == null:
		_plays = 0
		_last_interstitial = 0
		_first_day = -1
		_app_open_day = -1
		return true
	if typeof(s) != TYPE_DICTIONARY:
		return false
	var p = IntDomain.nonneg_int(s.get("plays"))
	var l = IntDomain.nonneg_int(s.get("last_interstitial"))
	var f = IntDomain.exact_int(s.get("first_day", -1))
	var a = IntDomain.exact_int(s.get("app_open_day", -1))
	if p == null or l == null or l > p or f == null or f < -1 or a == null or a < -1:
		return false
	_plays = p
	_last_interstitial = l
	_first_day = f
	_app_open_day = a
	return true
