# SB-M42 HOME REBUILD V04 — SINGLE WORLD BACKGROUND IMPLEMENTATION

Status: ACTIVE
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Scope: SB-M42-011 + SB-M42-017 Home rebuild

## Authority

Read first:

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md`
4. `coordination/OWNER_M42_HOME_VISUAL_REVISION_V03.md`
5. latest M42 Home audits
6. `assets/ui/HOME_ASSET_MANIFEST.json`
7. existing Home presentation map/tests

V04 supersedes prior Home composition decisions where conflicting.

Do NOT edit:
- root `TASKS.md`;
- owner decision files;
- ChatGPT audit/criteria files.

## Mandatory first gate: exact World 01 asset

Expected local owner-inbox file:

`assets/art/references/_owner_inbox/world_01_whispering_park_1080x2160.png`

Required exact identity:

- dimensions: **1080 x 2160**
- SHA-256:
  `8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b`

If the file is missing or hash/dimensions differ:

**STOP** with:
`BLOCKED_WORLD_01_BACKGROUND_MISSING_OR_MISMATCH`

Do not regenerate, redraw, approximate, upscale or modify it.

Once verified, promote the exact bytes to:

`assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png`

The owner decision file is the approval authority for these exact bytes.

## Architecture change

Home World 01 is no longer composed from separate:
- sky;
- city far;
- city mid;
- street foreground;
- arch;
- platform;
- environment props;
- helper bots.

Instead use ONE complete World 01 background containing all of those visual elements.

Scrubby remains a separate runtime layer.
HUD / four Home shortcuts / Play / Win Streak track / bottom nav / ad slot remain live Godot UI.

The baked image already contains:
- city;
- accepted sky proportion;
- Whispering Park portal;
- `WHISPERING PARK`;
- `AREA 1`;
- world platform;
- environment props;
- helper bots;
- street/foreground.

Therefore the runtime MUST NOT add duplicate world art.

## Manifest / lifecycle

Integrate the new world asset into the existing approved-art lifecycle rather than bypassing it.

Preferred implementation:
- add a new manifest ART entry using the next valid HOME id (inspect current manifest before choosing);
- group/slug clearly identify `world_01_whispering_park_background`;
- path is the final world path above;
- provider records ChatGPT image generation provenance if schema permits;
- status `APPROVED`;
- `approved_sha256` exactly:
  `8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b`.

Do not mutate the historical approval hashes/statuses of old assets merely because they are retired from active presentation.

## Exact Scrubby placement contract

Canonical 1080x2160 background coordinate space:

- canvas: `1080 x 2160`
- center X: **540**
- platform top visual region:
  `Rect2(256, 1240, 570, 97)` approximately
- Scrubby feet anchor:
  **Vector2(540, 1297)**
- recommended Scrubby visual safe box:
  **Rect2(353, 779, 374, 518)**

Requirements:

1. Scrubby uses its existing approved texture.
2. Preserve texture aspect ratio.
3. Center Scrubby on X=540.
4. Align the ACTUAL VISIBLE FEET to y=1297.
5. Do not use transparent texture padding as the ground-contact reference.
6. Keep Scrubby inside the recommended visual safe box unless visual inspection proves a small adjustment is necessary.
7. Do not cover the baked `WHISPERING PARK / AREA 1` sign.
8. Do not cover baked helper bots.
9. Scale all canonical coordinates uniformly when viewport differs from 1080x2160.
10. Do not add a second HOME-010/HOME-011 platform.

If needed, implement a named `ScrubbyWorldAnchor` and a documented visible-feet offset for HOME-026 so the placement is deterministic and testable.

## Retire duplicate World 01 component presentation

For World 01 active Home presentation, retire the old component art that is now baked into the single world image.

At minimum review and retire active presentation for:
- HOME-001..004 old layered background family;
- HOME-006 / HOME-007 portal art;
- HOME-010 / HOME-011 platform art;
- HOME-013..021 old environment props;
- HOME-022..024 helper bots.

Also remove the active LIVE area title/number nodes for World 01 because the owner chose baked `WHISPERING PARK / AREA 1`.

Preserve files/history. Do not delete approved source assets.

Presentation accounting must use an honest mode such as:
- `WORLD_BAKED_RETIRED`
- `OWNER_RETIRED`
- `OWNER_DISABLED`
rather than fake-visible.

## Four-panel Home

Home now has exactly four shortcut panels.

LEFT:
1. SHOP
2. COLLECTION

RIGHT:
1. TASKS
2. DAILY

Remove Home entry panels for:
- Win Streak
- Gifts
- No Ads
- Cards Exchange

Do not delete underlying services/data.

Behavior ownership:
- Win Streak is represented by the lower reward track.
- Gifts/rewards remain canonical service-driven/automatic.
- No Ads belongs inside Shop.
- Cards Exchange belongs inside Collection.

Do not invent full Shop/Collection sub-page product flows in this task unless existing architecture already owns them. Preserve routing seams for future tasks.

### Panel visual rules

- panel containers slightly smaller than V03;
- visible outer margin from screen edges;
- near-transparent / lightly tinted panel background;
- thin outline/glow allowed;
- icon + live label;
- panel itself must not dominate the world art;
- panels must not cover Scrubby or important baked helper bots.

Icon rules:
- SHOP: enlarge;
- COLLECTION: enlarge;
- TASKS: **keep current icon size**;
- DAILY: **keep current icon size**.

All four panel containers use one coherent size/style system.

If vision is available, inspect the exact World 01 image and choose the two left/two right panel locations from true negative-space zones that do not obscure helper bots.

## Play

- V03 `SHOP | PLAY | CARDS EXCHANGE` row is retired.
- Play becomes centered standalone CTA again.
- Use V03 Play size as the starting point.
- Keep native white play triangle.
- Keep live PLAY/CONTINUE and frontier-level subtitle.
- HOME-078 remains retired.
- compact coming-soon/status text must not distort the reward track.

## Profile

- keep horizontally narrow profile card;
- keep large portrait;
- portrait remains in front of frame;
- fix portrait bottom anchoring so the visible robot sits against the inner bottom of ProfileAvatarFrame;
- frame side/bottom segments stay visible;
- thicken Bot Parts progress bar;
- show only live `N/250`;
- center `N/250` inside the bar;
- Level badge remains separate/attached;
- no top duplicate Settings/menu.

## Currency / Hearts

- enlarge Scrub Bucks icon;
- enlarge Heart icon;
- icons visually sit in front of their chip panels;
- add visible plus button to Scrub Bucks;
- add visible plus button to Hearts;
- plus buttons emit intent only;
- do not invent price/product/transaction behavior.

Add explicit signals/intents such as:
- `scrub_bucks_purchase_requested`
- `hearts_purchase_requested`
or use an existing equivalent routing seam if one exists.

## Gift Meter

Preserve V03 compact behavior:
- live ratio only `N/1000`;
- no long caption;
- no event timer;
- no Event Points.
Emblem/crate may be modestly enlarged.

## Win Streak track

Preserve:
- thin track;
- five gift objects;
- only `1 / 5 / 10 / 25 / 100`;
- no plus signs;
- no per-step WIN text;
- no repeated SB icons;
- HOME-087 retired;
- reached/current/future state still readable.

No separate Win Streak Home shortcut.

## Bottom nav + ad slot

Bottom nav remains:
- Events
- Robots
- Home
- Ranks
- Settings

Keep:
- Home selected;
- current RANKS wording.

NEW owner layout:
- BottomNav is NOT the final screen-bottom element.
- Add dedicated persistent `AdBannerSlot` BELOW BottomNav.
- Layout bottom sequence:
  `WinStreakTrack -> BottomNav -> AdBannerSlot -> screen bottom`.

AdBannerSlot requirements:
- dedicated named container;
- no world/background image visually leaking into it;
- no fake ad provider/content;
- provide a clean integration seam for a future ad SDK;
- provide collapse/visibility seam for future No-Ads entitlement;
- reserve a reasonable responsive height without turning a speculative provider size into gameplay truth.
- tests must prove layout adapts when the ad slot is hidden/collapsed.

## Modal behavior

Preserve the V03 fix:
- when Daily or Settings modal/page is open, Home action UI disappears and receives no input;
- close/back restores exact Home state;
- topmost modal closes first.

Because removed Home shortcuts no longer exist, update modal tests accordingly instead of preserving dead Gifts/Cards Home-button assumptions.

Prefer one named `HomeActionLayer` / equivalent container so modal hiding does not depend on obsolete individual rows.

## World progression seam

Create a data-driven future-world seam, but DO NOT invent level ranges.

World 01 current default:
- id: world_01
- display baked in art: Whispering Park / Area 1
- background: the approved World 01 asset
- Scrubby anchor contract above.

Future architecture should allow:
`world_id -> background asset + Scrubby anchor/safe box`

Do NOT create speculative World 02+ names or range mapping in production code.

## 83-point source of truth

Every item in:
`coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md`
must be implemented or explicitly accounted for.

Create a V04 completion ledger:

`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-V04-83-COMPLETION-LEDGER.md`

Exactly 83 numbered rows.

Allowed statuses:
- `FIXED`
- `PRESERVED_CURRENT`
- `DEFERRED_BY_OWNER_ARCHITECTURE`
- `BLOCKED_WITH_PROOF`

No missing/duplicate rows.

## Visual evidence

Use the actual production Home.

Capture:
- 1080x2160
- 1290x2796
- 1080x1920
- 1536x2048

Also:
- Daily modal open
- Settings modal open
- AdBannerSlot visible
- AdBannerSlot collapsed/No-Ads simulation

Store under:
`coordination/sessions/M42-C001/runtime_evidence/home_v04/`

If vision is available, verify:
- no duplicate portal/platform/helper art;
- Scrubby feet correctly sit on baked platform;
- baked helper bots remain visible;
- 2+2 panels do not obscure Scrubby/helpers;
- profile portrait sits in frame correctly;
- city/world background reads correctly;
- Play centered;
- ad slot below nav.

Do not self-claim owner acceptance.

## Tests

Update/add focused tests for at least:

1. exact new world background SHA/dimensions;
2. new world background binds through approved lifecycle;
3. old world-layer art not instantiated/presented for World 01;
4. no live area title/number overlay on World 01;
5. no duplicate platform nodes;
6. no duplicate helper bot nodes;
7. Scrubby anchor X/Y contract at 1080x2160;
8. visible-feet offset deterministic;
9. Scrubby safe box;
10. 2+2 panel membership exactly;
11. removed Home shortcuts absent;
12. SHOP icon enlarged;
13. COLLECTION icon enlarged;
14. TASKS icon current size preserved;
15. DAILY icon current size preserved;
16. panel outer margin;
17. panel near-transparent style;
18. Play standalone centered;
19. profile portrait bottom anchored;
20. portrait remains over frame;
21. Bot Parts bar thicker;
22. ratio centered inside bar;
23. currency/heart icons enlarged/foregrounded;
24. both plus buttons visible and emit intents only;
25. Gift Meter compact;
26. reward track simplified;
27. BottomNav + AdBannerSlot order;
28. ad slot can collapse;
29. Daily modal hides action layer;
30. Settings modal hides action layer;
31. responsive matrix/touch targets;
32. all retired historical assets remain byte-identical.

Required runs:
- `m42_assets.gd`
- `m42_home.gd`
- `m42_home_composition.gd`
- V04 focused suite
- `m42_navigation.gd`
- `m42_opening.gd`
- root `run_tests.gd`
- `git diff --check`

Require exit 0 and zero SCRIPT ERROR.

## Asset integrity

Before implementation record Git blobs for all previously owner-approved production PNGs.

After implementation prove:
- old approved PNGs unchanged;
- the exact new world image SHA is correct;
- no silent regeneration/recompression;
- source owner-inbox bytes equal promoted final bytes.

## Log

Create:
`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-REBUILD-V04.md`

Include:
- baseline SHA;
- exact world-image SHA/dimensions;
- source->final byte identity;
- manifest change;
- retirement accounting;
- Scrubby anchor geometry;
- 83-item ledger summary;
- changed files;
- visual evidence;
- all test results;
- final implementation SHA.

Finish only with:

`AWAITING_CHATGPT_AUDIT / M42 HOME REBUILD V04`
