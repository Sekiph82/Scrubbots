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
##
## SB-TF-01 diagnostics + load retry: every failed load logs ADS_LOAD_FAILED kind code msg and,
## up to RETRY_DELAYS.size() times in a row, schedules one reload (5 s, 15 s, 45 s) through
## `schedule` (a SceneTree timer; tests inject a fake). A successful load resets the count;
## after the cap the ad reloads lazily on the next is_available / due interstitial, as before.
## ADS_INIT_DONE after the SDK init; consent / ATT failures are logged and still initialize.

const NATIVE := "AdmobPlugin"
const NODE_SCRIPT := "res://addons/AdmobPlugin/Admob.gd"
## CI-generated in release billing_ads builds only: const IDS = {banner, interstitial, rewarded}.
const REAL_IDS := "res://addons/AdmobPlugin/scrubbots_real_ids.gd"
## LoadAdRequest.AdPosition.BOTTOM of the plugin.
const POSITION_BOTTOM := 1
const RETRY_DELAYS := [5.0, 15.0, 45.0]

var _n
var _ios := false
var _sdk_ready := false
var _want_banner := false
var _banner_loaded := false
var _interstitial := "none"   ## none | loading | retry | ready
var _rewarded := "none"       ## none | loading | retry | ready
var _rw := {}                 ## the open rewarded view: {token, deliver, earned}
var _retries := {"interstitial": 0, "rewarded": 0}   ## consecutive automatic reloads
## schedule.call(delay_s, callback): one deferred call (default: a SceneTree timer).
var schedule := func(delay: float, cb: Callable) -> void:
	(Engine.get_main_loop() as SceneTree).create_timer(delay).timeout.connect(cb)

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
	_n.connect("consent_info_update_failed", _on_consent_failed.bind("info"))
	_n.connect("consent_form_loaded", func(): _n.show_consent_form())
	_n.connect("consent_form_failed_to_load", _on_consent_failed.bind("form"))
	_n.connect("consent_form_dismissed", _on_consent_dismissed)
	_n.connect("tracking_authorization_granted", _init_sdk)
	_n.connect("tracking_authorization_denied", _on_att_denied)
	_n.connect("initialization_completed", _on_initialized.unbind(1))
	_n.connect("banner_ad_loaded", _on_banner_loaded.unbind(2))
	_n.connect("interstitial_ad_loaded", func(_a, _r): _on_loaded("interstitial"))
	_n.connect("interstitial_ad_failed_to_load", func(_a, e): _on_load_failed("interstitial", e))
	_n.connect("interstitial_ad_failed_to_show_full_screen_content", func(_a, _e): _load_interstitial())
	_n.connect("interstitial_ad_dismissed_full_screen_content", _load_interstitial.unbind(1))
	_n.connect("rewarded_ad_loaded", func(_a, _r): _on_loaded("rewarded"))
	_n.connect("rewarded_ad_failed_to_load", func(_a, e): _on_load_failed("rewarded", e))
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

func _on_consent_failed(e, step: String) -> void:
	print("ADS_CONSENT_FAILED step=%s %s" % [step, _err(e)])
	_after_consent()

## The plugin always passes a FormError; an empty message = a normal close.
func _on_consent_dismissed(e) -> void:
	if e != null and e.has_method("get_message") and not String(e.get_message()).is_empty():
		_on_consent_failed(e, "dismissed")
	else:
		_after_consent()

func _after_consent() -> void:
	if _ios:
		_n.request_tracking_authorization()
	else:
		_init_sdk()

func _on_att_denied() -> void:
	print("ADS_ATT_DENIED")
	_init_sdk()

func _init_sdk() -> void:
	if not _sdk_ready:
		_n.initialize()

func _on_initialized() -> void:
	_sdk_ready = true
	print("ADS_INIT_DONE test_units=%s" % str(not bool(_n.get("is_real"))))
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

# ------------------------------------------------------------- load retry ----

func _on_loaded(kind: String) -> void:
	_retries[kind] = 0
	_set_state(kind, "ready")

func _on_load_failed(kind: String, e) -> void:
	print("ADS_LOAD_FAILED kind=%s %s" % [kind, _err(e)])
	var n: int = _retries[kind]
	if n >= RETRY_DELAYS.size():
		_set_state(kind, "none")
		return
	_retries[kind] = n + 1
	_set_state(kind, "retry")
	schedule.call(RETRY_DELAYS[n], _retry.bind(kind))

func _retry(kind: String) -> void:
	if kind == "rewarded" and _rewarded == "retry":
		_load_rewarded()
	elif kind == "interstitial" and _interstitial == "retry":
		_load_interstitial()

func _set_state(kind: String, s: String) -> void:
	if kind == "rewarded":
		_rewarded = s
	else:
		_interstitial = s

## "code=<n> msg=<text>" of a godot-admob AdError / LoadAdError / FormError (null-safe).
static func _err(e) -> String:
	if e == null or not e.has_method("get_code"):
		return "code=? msg=?"
	return "code=%s msg=%s" % [str(e.get_code()), String(e.get_message())]
