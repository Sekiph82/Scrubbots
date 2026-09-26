extends RefCounted
## HomePresentationMap — preload (res://scripts/ui/home/home_presentation_map.gd).
##
## M42 presentation accounting (V02; revised by owner decision V03,
## coordination/OWNER_M42_HOME_VISUAL_REVISION_V03.md). HomeArtBinder proves that an
## approved asset is AVAILABLE (historical approval + sha pin, unchanged); this map says
## whether and where it is PRESENTED. Every ART entry of assets/ui/HOME_ASSET_MANIFEST.json
## has exactly one row:
##   STATIC         — a concrete Home node visible in the normal composition;
##   OWNER_RETIRED  — approved file kept byte-identical, owner removed it from the active
##                    Home composition (no node; never loaded by Home);
##   OWNER_DISABLED — approved idle overlay kept byte-identical, owner disabled it in
##                    production Home (no node, no idle timer).
##   WORLD_BAKED_RETIRED — V04 (coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_
##                    BACKGROUND.md): component art now baked into the single World 01
##                    background HOME-120; file kept byte-identical, never loaded by Home.
## `nodes` are Home region names (HomeScreen.get_region). `slot` says how the texture is
## applied: "texture" (TextureRect), "button_icon" (Button.icon), "chip_icon"
## (UiValueChip.set_icon).

const ENTRIES := {
	"HOME-001": {"slug": "home_bg_sky", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-002": {"slug": "home_bg_city_far", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-003": {"slug": "home_bg_city_mid", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-004": {"slug": "home_bg_street_foreground", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-006": {"slug": "home_arch_whispering_park", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-007": {"slug": "home_arch_decor", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-010": {"slug": "home_platform_main", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-011": {"slug": "home_platform_top", "mode": "OWNER_RETIRED", "slot": "texture", "nodes": [], "reason": "V03 E: one platform only (HOME-010)"},
	"HOME-013": {"slug": "home_prop_cleaning_bucket", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-014": {"slug": "home_prop_hose", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-015": {"slug": "home_prop_foam_cluster", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-016": {"slug": "home_prop_puddles", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-018": {"slug": "home_prop_wet_floor_sign", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-019": {"slug": "home_prop_keep_clean_sign", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-020": {"slug": "home_prop_cleaning_equipment", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-021": {"slug": "home_prop_neon_details", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-022": {"slug": "helper_bot_floor_cleaner", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-023": {"slug": "helper_bot_cart", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-024": {"slug": "helper_bot_alt_pose", "mode": "WORLD_BAKED_RETIRED", "slot": "texture", "nodes": [], "reason": "V04: baked into the single World 01 background (HOME-120)"},
	"HOME-026": {"slug": "scrubby_home_pose", "mode": "STATIC", "slot": "texture", "nodes": ["Art_scrubby"]},
	"HOME-027": {"slug": "scrubby_portrait", "mode": "STATIC", "slot": "texture", "nodes": ["ProfilePortrait"]},
	"HOME-031": {"slug": "scrubby_face_blink_layer", "mode": "OWNER_DISABLED", "slot": "texture", "nodes": [], "reason": "V03 F: idle face overlay disabled"},
	"HOME-032": {"slug": "scrubby_brush_arm_layer", "mode": "OWNER_DISABLED", "slot": "texture", "nodes": [], "reason": "V03 F: idle brush-arm overlay disabled"},
	"HOME-034": {"slug": "profile_avatar_frame", "mode": "STATIC", "slot": "texture", "nodes": ["ProfileAvatarFrame"]},
	"HOME-035": {"slug": "profile_rank_badge", "mode": "STATIC", "slot": "texture", "nodes": ["ProfileRankBadge"]},
	"HOME-042": {"slug": "icon_currency_scrub_bucks", "mode": "STATIC", "slot": "chip_icon", "nodes": ["ScrubBucksChip"]},
	"HOME-043": {"slug": "icon_currency_heart", "mode": "STATIC", "slot": "chip_icon", "nodes": ["HeartsChip"]},
	"HOME-051": {"slug": "gift_meter_emblem", "mode": "STATIC", "slot": "texture", "nodes": ["GiftEmblem"]},
	"HOME-054": {"slug": "gift_meter_reward_crate", "mode": "STATIC", "slot": "texture", "nodes": ["GiftCrate"]},
	"HOME-062": {"slug": "icon_shortcut_win_streak", "mode": "OWNER_RETIRED", "slot": "button_icon", "nodes": [], "reason": "V04 34-40: Home shortcut panel removed (service/data kept)"},
	"HOME-063": {"slug": "icon_shortcut_gift_bar", "mode": "OWNER_RETIRED", "slot": "button_icon", "nodes": [], "reason": "V04 34-40: Home shortcut panel removed (service/data kept)"},
	"HOME-064": {"slug": "icon_shortcut_collection", "mode": "STATIC", "slot": "texture", "nodes": ["ShortcutIcon_collection"]},
	"HOME-065": {"slug": "icon_shortcut_shop", "mode": "STATIC", "slot": "texture", "nodes": ["ShortcutIcon_shop"]},
	"HOME-066": {"slug": "icon_shortcut_no_ads", "mode": "OWNER_RETIRED", "slot": "button_icon", "nodes": [], "reason": "V04 34-40: Home shortcut panel removed (service/data kept)"},
	"HOME-067": {"slug": "icon_shortcut_daily", "mode": "STATIC", "slot": "texture", "nodes": ["ShortcutIcon_daily"]},
	"HOME-068": {"slug": "icon_shortcut_tasks", "mode": "STATIC", "slot": "texture", "nodes": ["ShortcutIcon_tasks"]},
	"HOME-069": {"slug": "icon_shortcut_cards_exchange", "mode": "OWNER_RETIRED", "slot": "button_icon", "nodes": [], "reason": "V04 34-40: Home shortcut panel removed (service/data kept)"},
	"HOME-078": {"slug": "play_button_frame", "mode": "OWNER_RETIRED", "slot": "texture", "nodes": [], "reason": "V03 H: native white play triangle replaces it"},
	"HOME-086": {"slug": "win_streak_reward_badge", "mode": "STATIC", "slot": "texture", "nodes": ["TrackBadge"]},
	"HOME-087": {"slug": "win_streak_reward_scrub_bucks_icon", "mode": "OWNER_RETIRED", "reuse_of": "HOME-042", "slot": "chip_icon", "nodes": [], "reason": "V03 I: per-step SB icons removed from the reward track"},
	"HOME-090": {"slug": "win_streak_reward_gift_1", "mode": "STATIC", "slot": "texture", "nodes": ["TrackGift1"]},
	"HOME-091": {"slug": "win_streak_reward_gift_5", "mode": "STATIC", "slot": "texture", "nodes": ["TrackGift2"]},
	"HOME-092": {"slug": "win_streak_reward_gift_10", "mode": "STATIC", "slot": "texture", "nodes": ["TrackGift3"]},
	"HOME-093": {"slug": "win_streak_reward_gift_25", "mode": "STATIC", "slot": "texture", "nodes": ["TrackGift4"]},
	"HOME-094": {"slug": "win_streak_reward_gift_100", "mode": "STATIC", "slot": "texture", "nodes": ["TrackGift5"]},
	"HOME-101": {"slug": "icon_nav_events", "mode": "STATIC", "slot": "texture", "nodes": ["NavIcon_events"]},
	"HOME-102": {"slug": "icon_nav_robots", "mode": "STATIC", "slot": "texture", "nodes": ["NavIcon_robots"]},
	"HOME-103": {"slug": "icon_nav_home", "mode": "STATIC", "slot": "texture", "nodes": ["NavIcon_home"]},
	"HOME-104": {"slug": "icon_nav_leaderboard", "mode": "STATIC", "slot": "texture", "nodes": ["NavIcon_leaderboard"]},
	"HOME-105": {"slug": "icon_nav_settings", "mode": "STATIC", "slot": "texture", "nodes": ["NavIcon_settings"]},
	"HOME-120": {"slug": "world_01_whispering_park_background", "mode": "STATIC", "slot": "texture", "nodes": ["WorldBackground"]},
}

## Modes that present nothing in the active Home composition.
const INACTIVE_MODES := ["OWNER_RETIRED", "OWNER_DISABLED", "WORLD_BAKED_RETIRED"]

## Apply `tex` to one node according to the slot kind.
static func apply(node, slot: String, tex: Texture2D) -> void:
	match slot:
		"texture":
			(node as TextureRect).texture = tex
		"button_icon":
			(node as Button).icon = tex
		"chip_icon":
			node.set_icon(tex)

## Texture currently presented by a node for a slot (null when none).
static func presented(node, slot: String) -> Texture2D:
	if node == null:
		return null
	match slot:
		"texture":
			return (node as TextureRect).texture
		"button_icon":
			return (node as Button).icon
		"chip_icon":
			return node.icon.texture
	return null
