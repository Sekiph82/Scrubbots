# SB-M42 HOME REBUILD V04 — ChatGPT Independent Audit V01

Date: 2026-09-26
Auditor: ChatGPT
Baseline SHA: `a61cfd9932956bb5426657b522041c69363df794`
Owner reference commit: `390ea448b299c0ca42684db027fb434d57b2339d`
Implementation SHA: `a8b953ef25cb3b31002678f07afc6bf4342626ed`
Evidence / Claude log SHA: `dba743f9f6322d051ae456050f225a59d5dd4a88`

Owner decision:
`coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md`

Prompt:
`coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-REBUILD_V04.md`

Criteria:
`coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-REBUILD_V04.md`

## Verdict

**AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW**

No code remediation is required from the independent source/diff/test audit.

SB-M42-011 and SB-M42-017 remain open until the owner runs the current build and visually accepts the V04 Home composition.

## 1. Exact World 01 asset gate

ChatGPT independently verified the canonical locally generated owner asset used for this task:

- dimensions: **1080 × 2160**
- SHA-256: **`8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b`**
- Git blob SHA for those exact bytes: **`208795e92533844065110a644ecf2c87184aca82`**

At implementation SHA `a8b953e`, GitHub reports the same Git blob SHA for both:

- `assets/art/references/_owner_inbox/world_01_whispering_park_1080x2160.png`
- `assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png`

Therefore the promoted final asset is byte-for-byte identical to the owner-approved 1080×2160 source. No resize, recompression, redraw or regeneration occurred during promotion.

## 2. Manifest lifecycle

Independent baseline-vs-implementation parsing of `HOME_ASSET_MANIFEST.json` shows:

- baseline entries: **119**
- implementation entries: **120**
- historical entry modifications: **0**
- new entry only: **HOME-120**

HOME-120 is:

- slug `world_01_whispering_park_background`
- group `world`
- kind `ART`
- final World 01 path
- status `APPROVED`
- exact approved SHA-256 `8e04eda6…5e5b`
- owner V04 decision recorded as approval authority.

No old approval hash/status was rewritten.

## 3. Previous owner-approved PNG integrity

ChatGPT independently parsed the ten earlier owner Home-art approval artifacts and checked all 49 recorded Git blobs against the complete implementation tree.

Result:

- old owner-approved rows: **49**
- unique old approved IDs: **49**
- missing paths: **0**
- Git blob mismatches: **0**

Thus every previously owner-approved Home production PNG remains byte-identical.

## 4. Single-world-background architecture

The production presentation map now contains all **51 APPROVED ART entries** with an exact ID match to the manifest:

- **24 STATIC**
- **18 WORLD_BAKED_RETIRED**
- **7 OWNER_RETIRED**
- **2 OWNER_DISABLED**
- missing/extra presentation rows: **0**

The 18 WORLD_BAKED_RETIRED entries correctly cover the old layered background, portal, platform-main, environment and helper-bot component art now baked into HOME-120.

Runtime tests explicitly reject duplicate presentation of:

- HOME-001..004 old background layers;
- HOME-006/007 arch;
- HOME-010/011 platform art;
- HOME-013..021 environment;
- HOME-022..024 helper bots;
- live WHISPERING PARK / AREA overlays.

At canonical 1:2, HOME-120 is drawn exactly once.

## 5. World data seam

`data/config/home_worlds_v1.json` correctly defines only:

- `default_world = world_01`
- HOME-120 background slug;
- 1080×2160 canonical canvas;
- Scrubby feet anchor;
- Scrubby safe box;
- baked sign / platform / helper-bot geometry.

No `world_02`, no level range and no speculative progression mapping exists.

`HomeWorldCatalog.world("world_99")` is intentionally empty rather than inventing a fallback world.

## 6. Scrubby canonical placement

The focused V04 test uses the actual visible HOME-026 geometry rather than transparent texture padding.

Verified contract:

- canonical center X = **540**
- visible soles Y = **1297**
- configured safe box = **x 353..727 / y 779..1297**
- actual visible character stays within the horizontal safe box;
- only brush-bristle tips extend about 5 px below the soles line;
- baked world sign is not intersected;
- measured helper-bot rects are not intersected;
- Scrubby remains a separate runtime layer above HOME-120.

The responsive matrix rechecks the mapped feet anchor across all required viewports.

## 7. Four-panel Home

Independent source/test review verifies exactly four Home shortcuts:

Left:
- SHOP
- COLLECTION

Right:
- TASKS
- DAILY

Absent from Home:
- Win Streak
- Gifts
- No Ads
- Cards Exchange

Underlying Gift / Exchange / Streak services remain present.

Panel presentation:

- one common **210×156** panel size system;
- near-transparent tint, alpha <= 0.35;
- thin cyan outline;
- >=20 px outer margin;
- SHOP and COLLECTION icons enlarged >1.15× the V03 drawn size;
- TASKS and DAILY retain the exact V03 fitted icon size;
- responsive tests reject panel overlap with Scrubby or measured baked helper bots.

The two nested ownership flows remain intentionally deferred:
- Cards Exchange belongs to future Collection flow;
- No Ads belongs to future Shop flow.

This is consistent with the V04 prompt's explicit instruction not to invent full Shop/Collection subpages in this task. Their Home panels are removed, underlying seams/services are preserved, and the 83-point ledger marks those two items `DEFERRED_BY_OWNER_ARCHITECTURE` rather than falsely claiming completion.

## 8. Play / profile / HUD

Verified:

- V03 SHOP | PLAY | CARDS row is gone;
- Play is standalone and horizontally centered;
- Play remains approximately V03 size, not restored to oversized V02;
- native white triangle remains;
- HOME-078 remains retired;
- live frontier subtitle remains;
- coming-soon status is a child/pill of Play and does not alter reward-track layout.

Profile:

- card stays narrow;
- portrait remains large/in front of frame;
- visible portrait bottom is tied to the frame's inner bottom;
- frame sides remain exposed;
- Bot Parts bar is 42 px vs V03 24 px;
- only `N/250` is shown, centered inside the bar;
- level remains separate;
- no top duplicate Settings/menu.

Currency:

- Scrub Bucks and Heart icons are enlarged and overhang in front of their chips;
- both plus buttons are visible >=88 px;
- buttons emit intent signals only;
- economy snapshot is unchanged by the signals.

## 9. Gift Meter / Win Streak

Verified:

- Gift Meter remains ratio-only `N/1,000`;
- no old long Next Gift/Event caption;
- emblem/crate modestly enlarged;
- reward track remains thin;
- five gift objects remain;
- labels are exactly `1 / 5 / 10 / 25 / 100`;
- no per-step plus, WIN copy or repeated SB icon;
- HOME-087 remains retired;
- current/reached/future state remains visual through styling/progress.

## 10. Bottom nav / AdBannerSlot

Verified:

- BottomNav remains five buttons;
- HOME selected;
- RANKS wording preserved;
- dedicated `AdBannerSlot` exists below BottomNav;
- `AdMount` is empty, so no fake advertisement content was invented;
- slot is the bottom layout element when enabled;
- world canvas is clipped at the ad-slot top;
- `set_ad_slot_enabled(false)` collapses the slot and moves nav to the bottom;
- re-enable restores the layout.

This provides a clean future ad-provider / No-Ads entitlement seam without hardcoding a provider.

## 11. Modal behavior

Daily and Settings focused tests verify:

- `HomeActionLayer` and HUD plus buttons hide while modal is open;
- no visible Home button leaks behind Daily;
- close/back restores the exact Home state and Play geometry;
- Settings via the real app root uses the same modal behavior;
- persistent ad slot remains a separate reserved region.

This preserves the successful V03 modal fix while removing dependencies on obsolete Home shortcuts.

## 12. 83-point ledger

ChatGPT independently parsed:

`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-V04-83-COMPLETION-LEDGER.md`

Result:

- rows: **83**
- missing numbers: **0**
- duplicate numbers: **0**
- FIXED: **70**
- PRESERVED_CURRENT: **11**
- DEFERRED_BY_OWNER_ARCHITECTURE: **2**
- BLOCKED_WITH_PROOF: **0**

The two deferred rows are #74 Cards Exchange inside Collection and #75 No Ads inside Shop, both explicitly deferred by the V04 architecture rather than omitted.

## 13. Tests / regression evidence

Claude's implementation log records on tree `a8b953e`:

- `m42_assets`: 4/4 PASS
- `m42_home`: 19/19 PASS
- `m42_home_composition`: 9/9 PASS
- `m42_home_v04`: 18/18 PASS
- `m42_navigation`: 12/12 PASS
- `m42_opening`: 8/8 PASS
- root: 5322 checks, ALL PASS
- all exit 0
- zero SCRIPT ERROR
- same eight intentional corrupt-image engine ERROR lines as baseline
- `git diff --check`: clean

The V04 focused suite is substantive. It directly checks asset identity, lifecycle binding, duplicate-world removal, visible-feet geometry, panel membership/icon sizing, margins/transparency, Play, profile, purchase-intent-only HUD, ad slot, modal behavior, world seam, responsive matrix and historical asset integrity.

## 14. Runtime evidence

Repository evidence exists for:

- 1080×2160
- 1290×2796
- 1080×1920
- 1536×2048
- ad slot collapsed
- Daily modal
- Settings modal
- visual iteration captures.

Claude recorded visual inspection and disclosed three residual adaptive-layout compromises:
- a wider street band on the tallest phone;
- top sky partly behind HUD on 16:9;
- narrow mirrored side continuation on tablet.

Those are not code-test failures under the V04 contract, but owner visual review remains authoritative.

## 15. Non-blocking process note

The reference commit `390ea44` also contains deletion of the superseded `tests/m42_home_v03.gd` because that deletion was already staged. This is not an ideal reference-only commit boundary, but the deletion is intentional and the valid V03 invariants were migrated into V04/composition tests. Git history preserves the old test. This does not block V04.

## Gate impact

- SB-M42-011: **CODE_AUDIT_PASS / V04 / OWNER_VISUAL_REVIEW_REQUIRED**
- SB-M42-017: **CODE_AUDIT_PASS / V04 / OWNER_VISUAL_REVIEW_REQUIRED**
- SB-M42-014 / 016 / 018 remain closed.
- SB-M42-032 remains Android real-device cinematic gate.
- SB-M42-033 remains iOS-later device gate.

## Final

**AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW**

Next action: owner pulls current `main`, runs the game and reviews the actual V04 Home screen. Final Home closure requires the owner's runtime screenshot/acceptance.
