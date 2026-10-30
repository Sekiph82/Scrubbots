extends SceneTree
## SB-M22-026 steps 1-4 — per-screen resident RGBA8 texture budgets (Home, Gameplay, Results,
## Shop/Collection; step 4: Daily/Tasks, Profile, Ceremonies, Robots detail, Popups, Results
## variants, Coachmarks) and the size_limit'ed textures (alpha kept, loaded <= limit).
## Path lists come from tools/m22_026_texture_inventory.py reference data plus the textures the
## step 2 runtime measurement (tests/tools/m22_026_texture_measure.gd) showed on screen
## (UI-ADR-008); a texture shared by two screens counts on both. Step 3: the 135 catalog card arts
## (size_limit 1080, summed budget) and CollectionScreen holding no static texture cache (the
## per-visit cache lives on the album popup and is freed with it).
## Run: godot --headless --path . -s res://tests/m22_026_texture_budget.gd

const F := "res://assets/ui/final/"
const MIB := 1024 * 1024
const CollectionScreen = preload("res://scripts/ui/collection/collection_screen.gd")
const CATALOG := "res://data/config/collection_card_catalog_v1.json"
## Step 3: card art drawn at max 540 px (step 2 measure), cap 2 x 540; all 135 resident 401.2 MiB + ~10%.
const CARD_LIMIT := 1080
const CARD_BUDGET_MIB := 440

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
	# step 2 measurement: the 3-column shells drawn at runtime
	"gameplay/master/gameplay_v02_shell_5slot_3col.png", "gameplay/master/gameplay_v02_shell_6slot_3col.png",
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
	# step 2 measurement: popup frames, set-reward glow, parts icon
	"common/frames/popup_large_frame.png", "common/frames/popup_reward_frame.png",
	"popups/victory/reward_glow.png", "robots/bot_parts_icon.png",
]
## Step 4 (UI-ADR-008 step 4): per-screen lists from the step 4 measurement: the final/ textures
## the screen's scenarios draw outside the Home layer, minus what the screen underneath already
## draws (Gameplay under booster popups, Results variants and coachmarks; Fail Results under Need
## a Hand); catalog card art excluded.
const DAILY_TASKS := [
	"common/frames/popup_large_frame.png", "common/frames/popup_medium_frame.png",
	"daily/daily_login_calendar.png", "daily/daily_streak_flame.png", "daily/daily_task_check.png",
	"rewards/chest_small.png", "rewards/gift_box.png",
]
const PROFILE_EVENTS := [
	"characters/scrubby/scrubby_portrait.png", "common/frames/popup_large_frame.png",
	"common/frames/popup_medium_frame.png", "popups/help/help_scrubby_pose.png",
	# SB-M43-125-REBUILD Profile hero / stat tiles / Personal Bests icons
	"home/top_hud/profile_avatar_frame.png", "home/top_hud/profile_rank_badge.png",
	"daily/daily_task_check.png", "home/shortcuts/icon_shortcut_collection.png",
	"common/navigation/icon_nav_robots.png", "profile/profile_trophy_icon.png",
	"daily/daily_login_calendar.png", "daily/daily_streak_flame.png",
	"popups/victory/victory_emblem.png", "profile/profile_no_booster_icon.png",
]
const CEREMONIES := [
	"characters/robots/atlas/atlas_master.png", "characters/robots/bubbles/bubbles_master.png",
	"characters/robots/clippy/clippy_master.png", "characters/robots/dusty/dusty_master.png",
	"characters/robots/moppy/moppy_master.png", "characters/robots/polly/polly_master.png",
	"characters/robots/rinse/rinse_master.png", "characters/robots/spark/spark_master.png",
	"characters/robots/squeegee/squeegee_master.png", "characters/scrubby/scrubby_master.png",
	"collection/collection_complete_emblem.png", "collection/master_collection_emblem.png",
	"collection/states/card_back.png", "collection/states/card_new_glow.png",
	"common/currencies/icon_currency_scrub_bucks.png", "common/frames/popup_large_frame.png",
	"common/frames/popup_medium_frame.png", "common/frames/popup_reward_frame.png",
	"gameplay/tutorial/speech_bubble.png", "home/background/home_background.png",
	"home/gift_meter/gift_meter_reward_crate.png", "home/shortcuts/icon_shortcut_cards_exchange.png",
	"home/shortcuts/icon_shortcut_collection.png", "popups/victory/reward_glow.png",
	"rewards/booster_of_choice.png", "rewards/card_pack_premium.png",
	"rewards/card_pack_standard.png", "rewards/gift_box.png",
	"rewards/pack_opening/premium/frame_01_closed.png",
	"rewards/pack_opening/premium/frame_02_charge.png",
	"rewards/pack_opening/premium/frame_03_pressure.png",
	"rewards/pack_opening/premium/frame_04_first_tear.png",
	"rewards/pack_opening/premium/frame_05_tear_widens.png",
	"rewards/pack_opening/premium/frame_06_card_edge.png",
	"rewards/pack_opening/premium/frame_07_one_card_rises.png",
	"rewards/pack_opening/premium/frame_08_cards_emerge.png",
	"rewards/pack_opening/premium/frame_09_final_reveal.png",
	"rewards/pack_opening/standard/frame_01_closed.png",
	"rewards/pack_opening/standard/frame_02_charge.png",
	"rewards/pack_opening/standard/frame_03_pressure.png",
	"rewards/pack_opening/standard/frame_04_first_tear.png",
	"rewards/pack_opening/standard/frame_05_tear_widens.png",
	"rewards/pack_opening/standard/frame_06_card_edge.png",
	"rewards/pack_opening/standard/frame_07_one_card_rises.png",
	"rewards/pack_opening/standard/frame_08_cards_emerge.png",
	"rewards/pack_opening/standard/frame_09_final_reveal.png", "robots/bot_parts_icon.png",
	"robots/perks/perk_booster_discount.png", "robots/perks/perk_cards_exchange_bonus.png",
	"robots/perks/perk_daily_task_bonus.png", "robots/perks/perk_first_clear_sb_bonus.png",
	"robots/perks/perk_gift_bar_sb_bonus.png", "robots/perks/perk_heart_refill_discount.png",
	"robots/perks/perk_master_cleaner.png", "robots/perks/perk_speed_2x_discount.png",
	"robots/perks/perk_win_streak_bonus.png", "robots/robot_unlocked_burst.png",
]
const ROBOTS_DETAIL := [
	"characters/robots/atlas/atlas_master.png", "characters/robots/bubbles/bubbles_master.png",
	"characters/robots/clippy/clippy_master.png", "characters/robots/dusty/dusty_master.png",
	"characters/robots/moppy/moppy_master.png", "characters/robots/polly/polly_master.png",
	"characters/robots/rinse/rinse_master.png", "characters/robots/spark/spark_master.png",
	"characters/robots/squeegee/squeegee_master.png", "common/frames/popup_large_frame.png",
	"robots/robot_lock_emblem.png",
]
const POPUPS := [
	"common/currencies/icon_currency_scrub_bucks.png", "common/frames/popup_medium_frame.png",
	"common/frames/popup_reward_frame.png", "home/shortcuts/icon_shortcut_no_ads.png",
	"shop/shop_heart_bundle.png", "shop/shop_scrub_bucks_bundle.png", "shop/shop_speed_2x_icon.png",
]
const RESULTS_VARIANTS := [
	"common/currencies/icon_currency_heart.png", "common/currencies/icon_currency_scrub_bucks.png",
	"home/gift_meter/gift_meter_emblem.png", "home/reward_track/win_streak_reward_badge.png",
	"popups/failure/fail_header_emblem.png", "popups/help/help_scrubby_pose.png",
	"popups/help/robots/atlas_help_pose.png", "popups/help/robots/bubbles_help_pose.png",
	"popups/help/robots/clippy_help_pose.png", "popups/help/robots/dusty_help_pose.png",
	"popups/help/robots/moppy_help_pose.png", "popups/help/robots/polly_help_pose.png",
	"popups/help/robots/rinse_help_pose.png", "popups/help/robots/spark_help_pose.png",
	"popups/help/robots/squeegee_help_pose.png", "popups/victory/robots/atlas_victory_pose.png",
	"popups/victory/robots/bubbles_victory_pose.png", "popups/victory/robots/clippy_victory_pose.png",
	"popups/victory/robots/dusty_victory_pose.png", "popups/victory/robots/moppy_victory_pose.png",
	"popups/victory/robots/polly_victory_pose.png", "popups/victory/robots/rinse_victory_pose.png",
	"popups/victory/robots/spark_victory_pose.png", "popups/victory/robots/squeegee_victory_pose.png",
	"popups/victory/victory_emblem.png", "popups/victory/victory_scrubby_pose.png",
	"rewards/card_pack_standard.png", "rewards/gift_box.png", "robots/bot_parts_icon.png",
]
const COACHMARKS := [
	"gameplay/tutorial/speech_bubble.png", "gameplay/tutorial/tutorial_highlight_ring.png",
	"gameplay/tutorial/tutorial_pointer.png",
]
## Measured resident MiB after the step 2 caps (UI-ADR-008) plus ~10% headroom.
const BUDGET_MIB := {"Home": 117, "Gameplay": 69, "Results": 32, "Shop/Collection": 41,
	# step 4: measured after the step 4 caps plus ~10%
	# SB-M43-125-REBUILD: Profile hero / tile / bests icons re-measured 28.8 MiB + ~10%
	"Daily/Tasks": 32, "Profile/Events/Achievements": 32, "Ceremonies": 230, "Robots detail": 41, "Popups": 18, "Results variants": 83, "Coachmarks": 15}
## process/size_limit set by step 1 (small icons with a known draw side, 4x rule).
const LIMITED := {
	"common/icons/icon_clock.png": 256,
	"daily/daily_streak_flame.png": 256,
	"daily/daily_task_check.png": 256,
	"daily/daily_login_calendar.png": 1024,
	"popups/failure/heart_large.png": 1024,
}
## process/size_limit set by step 2: next_pow2(max(2 x measured max side px, 512))
## (tools/m22_026_apply_caps.py over the m22_026_texture_measure.gd report); step 4 entries
## from the merged step 2 + step 4 map (coordination/sessions/FACTORY/043-m22-026-more-screens).
const MEASURED := {
	"cards_exchange/cards_exchange_header_emblem.png": 512,
	"characters/robots/atlas/atlas_portrait.png": 512,
	"characters/robots/bubbles/bubbles_portrait.png": 512,
	"characters/robots/clippy/clippy_portrait.png": 512,
	"characters/robots/dusty/dusty_portrait.png": 512,
	"characters/robots/moppy/moppy_portrait.png": 512,
	"characters/robots/polly/polly_portrait.png": 512,
	"characters/robots/rinse/rinse_portrait.png": 512,
	"characters/robots/spark/spark_portrait.png": 512,
	"characters/robots/squeegee/squeegee_portrait.png": 512,
	"characters/scrubby/scrubby_portrait.png": 512,
	"collection/collection_complete_emblem.png": 512,
	"collection/master_collection_emblem.png": 1024,   # step 4: raised (320 px on the Master ceremony)
	"collection/states/card_unknown_silhouette.png": 1024,
	"common/currencies/icon_currency_heart.png": 512,
	"common/currencies/icon_currency_scrub_bucks.png": 512,
	"common/navigation/icon_nav_events.png": 512,
	"common/navigation/icon_nav_home.png": 512,
	"common/navigation/icon_nav_leaderboard.png": 512,
	"common/navigation/icon_nav_robots.png": 512,
	"common/navigation/icon_nav_settings.png": 512,
	"home/gift_meter/gift_meter_emblem.png": 512,
	"home/gift_meter/gift_meter_reward_crate.png": 1024,   # step 4: raised (300 px on the 1000 Gift milestone)
	"home/reward_track/reward_gift_1.png": 1024,
	"home/reward_track/reward_gift_10.png": 1024,
	"home/reward_track/reward_gift_100.png": 1024,
	"home/reward_track/reward_gift_25.png": 1024,
	"home/reward_track/reward_gift_5.png": 1024,
	"home/reward_track/win_streak_reward_badge.png": 512,
	"home/shortcuts/icon_shortcut_collection.png": 512,
	"home/shortcuts/icon_shortcut_daily.png": 512,
	"home/shortcuts/icon_shortcut_no_ads.png": 512,
	"home/shortcuts/icon_shortcut_rewarded_ads.png": 512,
	"home/shortcuts/icon_shortcut_shop.png": 512,
	"home/shortcuts/icon_shortcut_tasks.png": 512,
	"home/top_hud/profile_avatar_frame.png": 512,
	"home/top_hud/profile_rank_badge.png": 512,
	"popups/failure/fail_header_emblem.png": 512,
	"popups/victory/reward_glow.png": 1024,
	"popups/victory/victory_emblem.png": 512,
	"popups/victory/victory_scrubby_pose.png": 1024,
	"robots/bot_parts_icon.png": 512,
	"shop/shop_heart_bundle.png": 512,
	"shop/shop_scrub_bucks_bundle.png": 512,
	"shop/shop_speed_2x_icon.png": 512,
	# step 4
	"characters/robots/atlas/atlas_master.png": 1024,
	"characters/robots/bubbles/bubbles_master.png": 1024,
	"characters/robots/clippy/clippy_master.png": 1024,
	"characters/robots/dusty/dusty_master.png": 1024,
	"characters/robots/moppy/moppy_master.png": 1024,
	"characters/robots/polly/polly_master.png": 1024,
	"characters/robots/rinse/rinse_master.png": 1024,
	"characters/robots/spark/spark_master.png": 1024,
	"characters/robots/squeegee/squeegee_master.png": 1024,
	"characters/scrubby/scrubby_master.png": 1024,
	"collection/states/card_back.png": 512,
	"gameplay/tutorial/tutorial_pointer.png": 512,
	"home/shortcuts/icon_shortcut_cards_exchange.png": 512,
	"popups/help/robots/atlas_help_pose.png": 1024,
	"popups/help/robots/bubbles_help_pose.png": 1024,
	"popups/help/robots/clippy_help_pose.png": 1024,
	"popups/help/robots/dusty_help_pose.png": 1024,
	"popups/help/robots/moppy_help_pose.png": 1024,
	"popups/help/robots/polly_help_pose.png": 1024,
	"popups/help/robots/rinse_help_pose.png": 1024,
	"popups/help/robots/spark_help_pose.png": 1024,
	"popups/help/robots/squeegee_help_pose.png": 1024,
	"popups/victory/robots/atlas_victory_pose.png": 1024,
	"popups/victory/robots/bubbles_victory_pose.png": 1024,
	"popups/victory/robots/clippy_victory_pose.png": 1024,
	"popups/victory/robots/dusty_victory_pose.png": 1024,
	"popups/victory/robots/moppy_victory_pose.png": 1024,
	"popups/victory/robots/polly_victory_pose.png": 1024,
	"popups/victory/robots/rinse_victory_pose.png": 1024,
	"popups/victory/robots/spark_victory_pose.png": 1024,
	"popups/victory/robots/squeegee_victory_pose.png": 1024,
	"rewards/booster_of_choice.png": 512,
	"rewards/card_pack_premium.png": 512,
	"rewards/card_pack_standard.png": 512,
	"robots/perks/perk_booster_discount.png": 512,
	"robots/perks/perk_cards_exchange_bonus.png": 512,
	"robots/perks/perk_daily_task_bonus.png": 512,
	"robots/perks/perk_first_clear_sb_bonus.png": 512,
	"robots/perks/perk_gift_bar_sb_bonus.png": 512,
	"robots/perks/perk_heart_refill_discount.png": 512,
	"robots/perks/perk_master_cleaner.png": 512,
	"robots/perks/perk_speed_2x_discount.png": 512,
	"robots/perks/perk_win_streak_bonus.png": 512,
	"robots/robot_lock_emblem.png": 512,
	"robots/robot_unlocked_burst.png": 1024,
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
	_screen("Daily/Tasks", DAILY_TASKS)
	_screen("Profile/Events/Achievements", PROFILE_EVENTS)
	_screen("Ceremonies", CEREMONIES)
	_screen("Robots detail", ROBOTS_DETAIL)
	_screen("Popups", POPUPS)
	_screen("Results variants", RESULTS_VARIANTS)
	_screen("Coachmarks", COACHMARKS)
	_limited("size_limit step 1", LIMITED)
	_limited("size_limit steps 2 and 4 (measured)", MEASURED)
	_card_art()
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

func _limited(title: String, caps: Dictionary) -> void:
	print("[%s]" % title)
	for p in caps:
		var tex := load(F + p) as Texture2D
		if tex == null:
			_ok(false, "%s loads" % p)
			continue
		var w := tex.get_width()
		var h := tex.get_height()
		_ok(maxi(w, h) <= caps[p], "%s %dx%d <= %d" % [p, w, h, caps[p]])
		_ok(_has_alpha_format(tex.get_image()), "%s keeps alpha" % p)

func _card_art() -> void:
	print("[card art step 3]")
	var cards: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOG))["cards"]
	var total := 0
	var arts: Array = []
	for cid in cards:
		arts.append(String(cards[cid]["art"]))
	for art in arts:
		var tex := load(art) as Texture2D
		if tex == null:
			_ok(false, "%s loads" % art)
			continue
		var w := tex.get_width()
		var h := tex.get_height()
		total += w * h * 4
		if maxi(w, h) > CARD_LIMIT or not _has_alpha_format(tex.get_image()):
			_ok(false, "%s %dx%d <= %d with alpha" % [art, w, h, CARD_LIMIT])
	_ok(arts.size() == 135, "135 catalog card arts (got %d)" % arts.size())
	print("  all card arts resident RGBA8: %.2f MiB (budget %d MiB)" % [total / float(MIB), CARD_BUDGET_MIB])
	_ok(total <= CARD_BUDGET_MIB * MIB, "card arts total %d <= %d bytes, each <= %d px with alpha" % [total, CARD_BUDGET_MIB * MIB, CARD_LIMIT])
	# static vars are not in get_script_property_list(); `in` sees them
	_ok(not ("_tex_cache" in CollectionScreen) and not (CollectionScreen as Script).get_script_constant_map().has("_tex_cache"), "CollectionScreen has no _tex_cache")
	# a viewed card stays for the visit (album cache) and leaves the ResourceLoader cache once the
	# album's cache and the TextureRect are both freed
	var visit := {}
	var tr := TextureRect.new()
	tr.texture = CollectionScreen._tex(arts[0], visit)
	tr.free()
	_ok(ResourceLoader.has_cached(arts[0]) and CollectionScreen._tex(arts[0], visit) == visit[arts[0]], "%s kept by the visit cache after its TextureRect is freed" % arts[0])
	visit = {}
	_ok(not ResourceLoader.has_cached(arts[0]), "%s released once the visit cache is freed" % arts[0])

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
