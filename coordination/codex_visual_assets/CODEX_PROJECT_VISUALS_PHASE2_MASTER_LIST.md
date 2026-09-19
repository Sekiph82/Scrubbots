# SCRUBBOTS — CODEX PROJECT-WIDE VISUALS PHASE 2 MASTER LIST

Status: READY_FOR_CODEX_PRODUCTION
Branch: codex/visual-assets-production
Scope: remaining static/reusable/release visuals not covered by the completed 306/306 core visual pack.

## Absolute boundaries

Codex may write only:
- exact image targets listed below;
- raw generation outputs under `assets/ui/generated/project_wide_phase2/**`;
- `coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_TASKS.md`;
- `coordination/codex_visual_assets/CODEX_PROJECT_VISUALS_PHASE2_LOG.md`.

Codex must not modify:
- `main`;
- root `TASKS.md`;
- Claude files/logs;
- code, scenes, scripts, tests, configs, manifests, workflows;
- existing Phase 1 visual task/master/prompt/log files;
- existing owner-approved/generated production images unless a task explicitly says DERIVE/COPY.

## Visual authority

Use these owner references when applicable:
- `assets/art/references/_owner_inbox/Colorful logo.png`
- `assets/art/references/_owner_inbox/logo simple.png`
- `assets/art/references/_owner_inbox/app icon.png`
- `assets/art/references/_owner_inbox/app icon (small).png`
- `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png`
- `assets/art/references/_owner_inbox/Game Screens/main screen.png`

Use the established SCRUBBOTS visual language from the completed core visual pack.

## A. Production branding exports

| ID | Asset | Target | Method | Notes |
|---|---|---|---|---|
| P2-001 | Colorful logo production master | `assets/ui/final/branding/logo_colorful.png` | DERIVE/CLEAN EXPORT | Preserve owner reference identity. Transparent background. |
| P2-002 | Simple wide logo production master | `assets/ui/final/branding/logo_simple_wide.png` | DERIVE/CLEAN EXPORT | Preserve owner reference identity. Transparent background. |
| P2-003 | App icon canonical square master | `assets/ui/final/branding/app_icon_master.png` | DERIVE/CLEAN EXPORT | Preserve owner app-icon design. Square master. |
| P2-004 | Android adaptive foreground | `assets/ui/final/branding/app_icon_android_foreground.png` | DERIVE | Transparent foreground with safe padding. |
| P2-005 | Android adaptive background | `assets/ui/final/branding/app_icon_android_background.png` | GENERATE/DERIVE | Simple on-brand background only, no character clipping. |
| P2-006 | Android monochrome notification icon | `assets/ui/final/branding/icon_notification_android.png` | DERIVE | Single-color silhouette suitable for Android notification rendering. |
| P2-007 | iOS 1024 app icon master | `assets/ui/final/branding/app_icon_ios_1024.png` | DERIVE | 1024x1024, no transparent outer background. |

## B. Boot splash and loading visuals

| ID | Asset | Target | Method | Notes |
|---|---|---|---|---|
| P2-008 | Boot splash background | `assets/ui/final/system/splash/splash_background.png` | GENERATE | Portrait-safe, cyan/teal cleaning-tech ambience, no text/logo baked. |
| P2-009 | Boot splash Scrubby | `assets/ui/final/system/splash/splash_scrubby.png` | GENERATE | Canonical Scrubby, transparent, welcoming startup pose. |
| P2-010 | Boot splash logo | `assets/ui/final/system/splash/splash_logo.png` | DERIVE | Use canonical production logo, transparent. |
| P2-011 | Loading Scrubby pose | `assets/ui/final/system/loading/loading_scrubby.png` | GENERATE | Canonical Scrubby doing a compact cleaning/loading action, transparent. |
| P2-012 | Loading spinner ring | `assets/ui/final/system/loading/loading_spinner_ring.png` | GENERATE | Clean cyan/teal mechanical ring, transparent, no text. |
| P2-013 | Loading glow | `assets/ui/final/system/loading/loading_glow.png` | GENERATE | Soft reusable radial glow, transparent. |

## C. Release / store marketing art

These are branded marketing components, not fake gameplay screenshots.

| ID | Asset | Target | Method | Notes |
|---|---|---|---|---|
| P2-014 | Google Play feature graphic | `assets/ui/final/marketing/google_play_feature_graphic.png` | GENERATE/COMPOSE | 1024x500 marketing graphic, canonical Scrubby + logo + cleaning-tech world, no fake UI claims. |
| P2-015 | Store hero Scrubby | `assets/ui/final/marketing/store_hero_scrubby.png` | GENERATE | Large transparent hero pose for store compositions. |
| P2-016 | Store cleaning-props cluster | `assets/ui/final/marketing/store_cleaning_props.png` | GENERATE | Transparent decorative cluster. |
| P2-017 | Store background | `assets/ui/final/marketing/store_background.png` | GENERATE | Wide adaptable branded environment, no text/UI. |
| P2-018 | Store logo lockup | `assets/ui/final/marketing/store_logo_lockup.png` | DERIVE/COMPOSE | Clean logo lockup using owner-approved logo identity. |

## D. Generic release/support visuals

| ID | Asset | Target | Method | Notes |
|---|---|---|---|---|
| P2-019 | Generic level-preview placeholder | `assets/ui/final/system/placeholders/level_preview_placeholder.png` | GENERATE | Neutral SCRUBBOTS preview placeholder only, no fake level art. |
| P2-020 | Generic content-loading placeholder | `assets/ui/final/system/placeholders/content_loading_placeholder.png` | GENERATE | Low-detail branded placeholder, no text. |
| P2-021 | Offline/network decorative icon | `assets/ui/final/common/icons/icon_offline.png` | GENERATE | Simple disconnected-cloud/network concept, transparent. |
| P2-022 | Refresh/retry decorative icon | `assets/ui/final/common/icons/icon_refresh.png` | GENERATE | Reusable refresh arrow, transparent. |
| P2-023 | Download/content-delivery icon | `assets/ui/final/common/icons/icon_download.png` | GENERATE | Reusable content-download symbol, transparent. |
| P2-024 | Warning/error decorative icon | `assets/ui/final/common/icons/icon_warning.png` | GENERATE | Friendly warning symbol, transparent, no text. |

## E. Explicitly NOT AUTHORIZED YET

Do not generate these until owner/system design is resolved:

1. Actual Robot 2..6 character identities or perks. The roster is still an owner decision.
2. Leaderboard-specific art. Leaderboard is an unresolved design gate.
3. Event-specific banners, currencies, mascots or reward themes. Event format is unresolved.
4. Real-money IAP pack art, ad/rewarded-ad creatives, subscription visuals or cash-price assets. M57 remains owner-gated.
5. Achievements/social/cloud-save-specific branded art. Those systems are not finalized.
6. Final Google Play/App Store gameplay screenshots. These must be captured/composed from the finished integrated app later, not invented by image generation.
7. Production level pixel-art library. M52+ level content is owned by the level/content pipeline and locked C01..C16 palette rules, not by this static UI asset job.
8. New booster types. V1 has exactly four: +1 Slot, Random, Selector, Tornado.
9. Any new currency. Scrub Bucks + Hearts + Bot Parts + card/booster inventory semantics remain authoritative.

## Completion condition

Phase 2 is complete when P2-001..P2-024 exist at their exact target paths on `origin/codex/visual-assets-production`, with required transparency/format checks, and no forbidden file was modified.


## F. Master UI Asset Kit expansion

These reusable assets come from the early SCRUBBOTS UI planning work and fit the current component-based Godot architecture. They must remain text-free and reusable.

| ID | Asset | Target | Method | Notes |
|---|---|---|---|---|
| P2-025 | Small popup frame | `assets/ui/final/common/frames/popup_small_frame.png` | GENERATE | 9-slice friendly, no text. |
| P2-026 | Medium popup frame | `assets/ui/final/common/frames/popup_medium_frame.png` | GENERATE | 9-slice friendly, no text. |
| P2-027 | Large popup frame | `assets/ui/final/common/frames/popup_large_frame.png` | GENERATE | 9-slice friendly, portrait-safe. |
| P2-028 | Confirmation popup frame | `assets/ui/final/common/frames/popup_confirmation_frame.png` | GENERATE | Neutral confirmation chrome. |
| P2-029 | Reward popup frame | `assets/ui/final/common/frames/popup_reward_frame.png` | GENERATE | Celebratory, currency-neutral. |
| P2-030 | Warning popup frame | `assets/ui/final/common/frames/popup_warning_frame.png` | GENERATE | Friendly warning treatment. |
| P2-031 | Blue button frame | `assets/ui/final/common/frames/button_blue_frame.png` | GENERATE | 9-slice friendly, no text/icon. |
| P2-032 | Green button frame | `assets/ui/final/common/frames/button_green_frame.png` | GENERATE | Primary CTA frame. |
| P2-033 | Purple button frame | `assets/ui/final/common/frames/button_purple_frame.png` | GENERATE | Special/secondary CTA frame. |
| P2-034 | Red button frame | `assets/ui/final/common/frames/button_red_frame.png` | GENERATE | Destructive/cancel frame. |
| P2-035 | Disabled button frame | `assets/ui/final/common/frames/button_disabled_frame.png` | GENERATE | Disabled state, no text. |
| P2-036 | Generic badge frame | `assets/ui/final/common/badges/badge_generic_frame.png` | GENERATE | Reusable badge frame. |
| P2-037 | Notification badge frame | `assets/ui/final/common/badges/badge_notification_frame.png` | GENERATE | No number baked. |
| P2-038 | Quantity badge frame | `assets/ui/final/common/badges/badge_quantity_frame.png` | GENERATE | No quantity baked. |
| P2-039 | Generic progress bar frame | `assets/ui/final/common/frames/progress_bar_frame.png` | GENERATE | Reusable frame. |
| P2-040 | Generic progress bar fill | `assets/ui/final/common/frames/progress_bar_fill.png` | GENERATE | Stretchable fill. |

## G. Booster state family

V1 still has exactly four boosters. Do not invent a fifth booster. These are state overlays/frames, not new booster identities.

| ID | Asset | Target | Method | Notes |
|---|---|---|---|---|
| P2-041 | Booster selected ring | `assets/ui/final/boosters/states/booster_selected_ring.png` | GENERATE | Reusable selected state. |
| P2-042 | Booster unavailable overlay | `assets/ui/final/boosters/states/booster_unavailable_overlay.png` | GENERATE | Reusable disabled state. |
| P2-043 | Booster reward glow | `assets/ui/final/boosters/states/booster_reward_glow.png` | GENERATE | Reward presentation. |
| P2-044 | Booster activated burst | `assets/ui/final/boosters/states/booster_activated_burst.png` | GENERATE | Activation feedback. |
| P2-045 | Booster tutorial pointer | `assets/ui/final/boosters/states/booster_tutorial_pointer.png` | GENERATE | Tutorial cue. |
| P2-046 | Booster free/ad badge frame | `assets/ui/final/boosters/states/booster_free_badge_frame.png` | GENERATE | Frame only; no FREE/ad copy baked. |

## H. Robot Collection visual system

The Robot Collection system is part of the long-term SCRUBBOTS IP. UI chrome already exists in Phase 1. Phase 2 adds reusable presentation assets that do NOT invent Robot 2..6 identities.

| ID | Asset | Target | Method | Notes |
|---|---|---|---|---|
| P2-047 | Locked robot silhouette | `assets/ui/final/robots/robot_locked_silhouette.png` | GENERATE | Generic silhouette, no identity. |
| P2-048 | Robot portrait frame | `assets/ui/final/robots/robot_portrait_frame.png` | GENERATE | Reusable portrait frame. |
| P2-049 | Robot detail hero frame | `assets/ui/final/robots/robot_detail_hero_frame.png` | GENERATE | Reusable hero frame. |
| P2-050 | Robot selected ring | `assets/ui/final/robots/robot_selected_ring.png` | GENERATE | Active robot state. |
| P2-051 | New robot unlocked burst | `assets/ui/final/robots/robot_unlocked_burst.png` | GENERATE | Unlock FX. |
| P2-052 | Robot ability/perk emblem frame | `assets/ui/final/robots/robot_perk_emblem_frame.png` | GENERATE | No perk icon/text baked. |
| P2-053 | Robot lock emblem | `assets/ui/final/robots/robot_lock_emblem.png` | GENERATE | Locked robot state. |

### Robot roster rule

Do NOT generate actual Robot 2..6 characters yet.

The old planning document contained example names/concepts such as Moppy, Bubbles and Spark. Those examples are NOT current owner-approved canon and must not be promoted automatically.

Actual new robot identities require a separate owner-approved Robot Roster decision. Once approved, each robot should receive:
- full-body master
- portrait
- Home/collection pose
- unlock pose
- selected/gameplay pose
- optional expression/animation layers

## I. System-state icon family

| ID | Asset | Target | Method | Notes |
|---|---|---|---|---|
| P2-054 | Language icon | `assets/ui/final/common/icons/icon_language.png` | GENERATE | Globe/language concept. |
| P2-055 | Notifications icon | `assets/ui/final/common/icons/icon_notifications.png` | GENERATE | Bell/notification. |
| P2-056 | Privacy icon | `assets/ui/final/common/icons/icon_privacy.png` | GENERATE | Friendly shield/privacy. |
| P2-057 | Support/help icon | `assets/ui/final/common/icons/icon_support.png` | GENERATE | Support/help. |
| P2-058 | Player ID icon | `assets/ui/final/common/icons/icon_player_id.png` | GENERATE | Profile/ID concept. |
| P2-059 | Cloud save icon | `assets/ui/final/common/icons/icon_cloud_save.png` | GENERATE | Cloud save. |
| P2-060 | Save conflict icon | `assets/ui/final/common/icons/icon_save_conflict.png` | GENERATE | Cloud conflict/warning. |
| P2-061 | Maintenance icon | `assets/ui/final/common/icons/icon_maintenance.png` | GENERATE | Maintenance/tool concept. |
| P2-062 | Update required icon | `assets/ui/final/common/icons/icon_update_required.png` | GENERATE | App/update arrow. |
| P2-063 | Connection lost icon | `assets/ui/final/common/icons/icon_connection_lost.png` | GENERATE | Broken connection/wifi. |

## J. Current exclusions from the old planning document

The following old concepts are intentionally NOT added to the current production system:
- World Map / Area Map
- Area Complete / New Area Reveal
- XP progression
- Player Level Up as a separate XP system
- Star Reward / Star Exchange
- new Star currency
- Weekly progression systems
- event-specific progression/banners before event rules exist
- robot perks that alter puzzle truth
- seven-day login structure when current Economy V1 uses a five-day repeating cycle
- new Pickup booster identity; current canonical boosters are +1 Slot / Random / Selector / Tornado
