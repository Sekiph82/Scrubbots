extends SceneTree
## SB-M22-026 step 1 — per-screen resident RGBA8 texture budgets (Home, Gameplay, Results,
## Shop/Collection) and the size_limit'ed small icons (alpha kept, loaded <= limit).
## Path lists come from tools/m22_026_texture_inventory.py reference data (UI-ADR-008);
## a texture shared by two screens counts on both.
## Run: godot --headless --path . -s res://tests/m22_026_texture_budget.gd

const F := "res://assets/ui/final/"
const MIB := 1024 * 1024

## Home: the STATIC entries of HomePresentationMap (bound via HOME_ASSET_MANIFEST) plus the
## home_scrubby_gestures_v03 frame set.
const HOME := [
	"characters/scrubby/scrubby_home_pose.png", "characters/scrubby/scrubby_portrait.png",
	"home/top_hud/profile_avatar_frame.png", "home/top_hud/profile_rank_badge.png",
	"common/currencies/icon_currency_scrub_bucks.png", "common/currencies/icon_currency_heart.png",
	"home/gift_meter/gift_meter_emblem.png", "home/gift_meter/gift_meter_reward_crate.png",
	"home/shortcuts/icon_shortcut_collection.png", "home/shortcuts/icon_shortcut_shop.png",
	"home/shortcuts/icon_shortcut_daily.png", "home/shortcuts/icon_shortcut_tasks.png",
	"home/shortcuts/icon_shortcut_rewarded_ads.png", "home/reward_track/win_streak_reward_badge.png",
	"home/reward_track/reward_gift_1.png", "home/reward_track/reward_gift_5.png",
	"home/reward_track/reward_gift_10.png", "home/reward_track/reward_gift_25.png",
	"home/reward_track/reward_gift_100.png", "common/navigation/icon_nav_events.png",
	"common/navigation/icon_nav_robots.png", "common/navigation/icon_nav_home.png",
	"common/navigation/icon_nav_leaderboard.png", "common/navigation/icon_nav_settings.png",
	"home/background/home_background.png",
]
const HOME_FRAMES := {"bow": 15, "full_turn": 17, "turn": 17, "wave": 14}
## Gameplay: gameplay_screen (fallback shell, portrait, boosters + state art), scrub rail,
## Scrubbot body and clean FX.
const GAMEPLAY := [
	"gameplay/master/gameplay_v02_shell_5slot_5col.png", "gameplay/profile/scrubby_portrait.png",
	"boosters/extra_slot.png", "boosters/random.png", "boosters/selector.png", "boosters/tornado.png",
	"boosters/states/booster_selected_ring.png", "boosters/states/booster_unavailable_overlay.png",
	"boosters/states/booster_free_badge_frame.png", "boosters/states/booster_reward_glow.png",
	"boosters/states/booster_activated_burst.png", "gameplay/railroad/rail_straight_horizontal.png",
	"gameplay/railroad/rail_energy_node.png", "gameplay/railroad/rail_slot_connector.png",
	"characters/scrubby/scrubby_gameplay.png", "gameplay/effects/fx_clean_puff.png",
	"gameplay/effects/fx_clean_sparkle.png",
]
## Results: won + failed hero/emblem and the reward-row icons of results_screen.
const RESULTS := [
	"popups/victory/victory_scrubby_pose.png", "popups/victory/victory_emblem.png",
	"popups/help/help_scrubby_pose.png", "popups/failure/fail_header_emblem.png",
	"common/currencies/icon_currency_scrub_bucks.png", "home/reward_track/win_streak_reward_badge.png",
	"robots/bot_parts_icon.png", "home/gift_meter/gift_meter_emblem.png",
	"rewards/card_pack_standard.png", "rewards/gift_box.png", "common/currencies/icon_currency_heart.png",
]
## Shop/Collection: shop_screen ART and collection_screen ART (catalog card art excluded).
const SHOP_COLLECTION := [
	"shop/shop_header_emblem.png", "common/currencies/icon_currency_scrub_bucks.png",
	"common/currencies/icon_currency_heart.png", "shop/shop_heart_bundle.png",
	"shop/shop_speed_2x_icon.png", "shop/shop_scrub_bucks_bundle.png",
	"home/shortcuts/icon_shortcut_no_ads.png", "boosters/extra_slot.png", "boosters/random.png",
	"boosters/selector.png", "boosters/tornado.png",
	"collection/states/card_unknown_silhouette.png", "collection/collection_complete_emblem.png",
	"collection/master_collection_emblem.png", "cards_exchange/cards_exchange_header_emblem.png",
]
## Measured resident MiB (UI-ADR-008) plus ~10% headroom.
const BUDGET_MIB := {"Home": 228, "Gameplay": 56, "Results": 73, "Shop/Collection": 77}
## process/size_limit set by this step (small icons with a known draw side, 4x rule).
const LIMITED := {
	"common/icons/icon_clock.png": 256,
	"daily/daily_streak_flame.png": 256,
	"daily/daily_task_check.png": 256,
	"daily/daily_login_calendar.png": 1024,
	"popups/failure/heart_large.png": 1024,
}

var _fail := 0

func _initialize() -> void:
	var home: Array = HOME.duplicate()
	for g in HOME_FRAMES:
		for i in range(1, HOME_FRAMES[g] + 1):
			home.append("characters/scrubby/home_animation/%s/%s_%02d.png" % [g, g, i])
	_screen("Home", home)
	_screen("Gameplay", GAMEPLAY)
	_screen("Results", RESULTS)
	_screen("Shop/Collection", SHOP_COLLECTION)
	_limited()
	_done()

func _screen(name: String, paths: Array) -> void:
	print("[%s]" % name)
	var total := 0
	for p in paths:
		var tex := load(F + p) as Texture2D
		if tex == null:
			_ok(false, "%s loads" % p)
			continue
		total += tex.get_width() * tex.get_height() * 4
	var budget: int = BUDGET_MIB[name] * MIB
	print("  %s textures resident RGBA8: %.2f MiB (%d textures, budget %d MiB)" % [name, total / float(MIB), paths.size(), BUDGET_MIB[name]])
	_ok(total <= budget, "%s total %d <= %d bytes" % [name, total, budget])

func _limited() -> void:
	print("[size_limit]")
	for p in LIMITED:
		var tex := load(F + p) as Texture2D
		if tex == null:
			_ok(false, "%s loads" % p)
			continue
		var w := tex.get_width()
		var h := tex.get_height()
		_ok(maxi(w, h) <= LIMITED[p], "%s %dx%d <= %d" % [p, w, h, LIMITED[p]])
		_ok(_has_alpha_format(tex.get_image()), "%s keeps alpha" % p)

func _has_alpha_format(img: Image) -> bool:
	return img.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_LA8, Image.FORMAT_RGBA4444, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH]

func _ok(cond: bool, msg: String) -> void:
	if not cond:
		_fail += 1
		print("  FAIL: %s" % msg)
	else:
		print("  ok: %s" % msg)

func _done() -> void:
	print("M22-026 TEXTURE BUDGET: %s" % ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)
