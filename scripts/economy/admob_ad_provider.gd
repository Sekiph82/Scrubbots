extends "res://scripts/economy/ad_provider.gd"
## AdmobAdProvider — preload (res://scripts/economy/admob_ad_provider.gd).
##
## SB-M57-022: the AdProvider contract over Google AdMob through the godot-sdk-integrations
## godot-admob plugin v7.0 (MIT; native singleton "AdmobPlugin", GDScript node
## res://addons/AdmobPlugin/Admob.gd; both added to Android / iOS exports by the CI workflow
## input billing_ads). main.gd installs it only when that singleton exists; editor / desktop /
## headless keep the null AdProvider. Tests drive it with a fake node (same methods + signals).
##
## Order (Google UMP first, then iOS ATT, then the SDK): update_consent_info -> the consent
## form only when the status is REQUIRED -> request_tracking_authorization on iOS -> initialize
## -> load one interstitial + one rewarded (+ the banner when wanted). Nothing loads before.
## Debug / test builds keep is_real = false (Google's TEST ad units, AdMob invalid-traffic
## policy). Only a release build with billing_ads gets REAL_IDS, written by the CI workflow from
## the ADMOB_* GitHub secrets (never committed); when it exists the node turns is_real on.
##
##   set_banner(visible)        bottom banner (AdService passes No Ads); shown once loaded
##   show_interstitial(p)       true only when a loaded interstitial is shown; otherwise it
##                              starts a load and AdService keeps the ad due
##   rewarded request/deliver   "completed" + verified only when the SDK reported the earned
##                              reward before the ad closed; closed without it = "cancelled";
##                              failed to show = "failed" (RewardedGrantService grants only the first)

const NATIVE := "AdmobPlugin"
const NODE_SCRIPT := "res://addons/AdmobPlugin/Admob.gd"
## CI-generated in release billing_ads builds only: const IDS = {banner, interstitial, rewarded}.
const REAL_IDS := "res://addons/AdmobPlugin/scrubbots_real_ids.gd"
## LoadAdRequest.AdPosition.BOTTOM of the plugin.
const POSITION_BOTTOM := 1

var _n
var _ios := false
var _sdk_ready := false
var _want_banner := false
var _banner_loaded := false
var _interstitial := "none"   ## none | loading | ready
var _rewarded := "none"       ## none | loading | ready
var _rw := {}                 ## the open rewarded view: {token, deliver, earned}

## node: an Admob node (not yet in the tree); ios: request ATT after consent.
func _init(node, ios: bool = OS.has_feature("ios"), real_ids: String = REAL_IDS) -> void:
	_n = node
	_ios = ios
	if ResourceLoader.exists(real_ids):
		var ids: Dictionary = load(real_ids).IDS
		_n.set("is_real", true)
		for kind in ["banner", "interstitial", "rewarded"]:
			_n.set("%s_real_%s_id" % ["ios" if ios else "android", kind], ids[kind])
	_n.set("banner_position", POSITION_BOTTOM)
	_n.set("banner_anchor_to_safe_area", true)
	_n.set("remove_interstitial_ads_after_displayed", true)
	_n.connect("consent_info_updated", _on_consent_info)
	_n.connect("consent_info_update_failed", _after_consent.unbind(1))
	_n.connect("consent_form_loaded", func(): _n.show_consent_form())
	_n.connect("consent_form_failed_to_load", _after_consent.unbind(1))
	_n.connect("consent_form_dismissed", _after_consent.unbind(1))
	_n.connect("tracking_authorization_granted", _init_sdk)
	_n.connect("tracking_authorization_denied", _init_sdk)
	_n.connect("initialization_completed", _on_initialized.unbind(1))
	_n.connect("banner_ad_loaded", _on_banner_loaded.unbind(2))
	_n.connect("interstitial_ad_loaded", func(_a, _r): _interstitial = "ready")
	_n.connect("interstitial_ad_failed_to_load", func(_a, _e): _interstitial = "none")
	_n.connect("interstitial_ad_failed_to_show_full_screen_content", func(_a, _e): _load_interstitial())
	_n.connect("interstitial_ad_dismissed_full_screen_content", _load_interstitial.unbind(1))
	_n.connect("rewarded_ad_loaded", func(_a, _r): _rewarded = "ready")
	_n.connect("rewarded_ad_failed_to_load", func(_a, _e): _rewarded = "none")
	_n.connect("rewarded_ad_user_earned_reward", func(_a, _r): if not _rw.is_empty(): _rw["earned"] = true)
	_n.connect("rewarded_ad_dismissed_full_screen_content", _on_rewarded_closed.bind("").unbind(1))
	_n.connect("rewarded_ad_failed_to_show_full_screen_content", _on_rewarded_closed.bind("failed").unbind(2))

## Call once the node is in the tree (its _ready picks the ad unit ids).
func start() -> void:
	_n.update_consent_info()

func is_ready() -> bool:
	return _sdk_ready

func _on_consent_info() -> void:
	var status = _n.get_consent_status()
	if status != null and status.to_status_string() == "REQUIRED" and _n.is_consent_form_available():
		_n.load_consent_form()
	else:
		_after_consent()

func _after_consent() -> void:
	if _ios:
		_n.request_tracking_authorization()
	else:
		_init_sdk()

func _init_sdk() -> void:
	if not _sdk_ready:
		_n.initialize()

func _on_initialized() -> void:
	_sdk_ready = true
	_load_interstitial()
	_load_rewarded()
	set_banner(_want_banner)

# ------------------------------------------------------------------ banner ----

func set_banner(visible: bool) -> void:
	_want_banner = visible
	if not _sdk_ready:
		return
	if not _banner_loaded:
		if visible:
			_n.load_banner_ad()
	elif visible:
		_n.show_banner_ad()
	else:
		_n.hide_banner_ad()

func _on_banner_loaded() -> void:
	_banner_loaded = true
	set_banner(_want_banner)

# ------------------------------------------------------------ interstitial ----

func show_interstitial(_placement: String) -> bool:
	if not _sdk_ready:
		return false
	if _interstitial != "ready":
		if _interstitial == "none":
			_load_interstitial()
		return false
	_interstitial = "none"
	_n.show_interstitial_ad()
	return true

func _load_interstitial() -> void:
	_interstitial = "loading"
	_n.load_interstitial_ad()

# ---------------------------------------------------------------- rewarded ----

func is_available(_placement: String) -> bool:
	if _sdk_ready and _rewarded == "none":
		_load_rewarded()
	return _rewarded == "ready" and _rw.is_empty()

func request(_placement: String, token: String, deliver: Callable) -> bool:
	if not is_available(_placement):
		return false
	_rw = {"token": token, "deliver": deliver, "earned": false}
	_rewarded = "none"
	_n.show_rewarded_ad()
	return true

func _on_rewarded_closed(failure: String) -> void:
	if _rw.is_empty():
		return
	var rw := _rw
	_rw = {}
	_load_rewarded()
	var earned: bool = failure.is_empty() and rw["earned"]
	rw["deliver"].call(rw["token"], {"outcome": "completed" if earned else (failure if not failure.is_empty() else "cancelled"), "verified": earned})

func _load_rewarded() -> void:
	_rewarded = "loading"
	_n.load_rewarded_ad()
