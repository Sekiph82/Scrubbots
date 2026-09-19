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
