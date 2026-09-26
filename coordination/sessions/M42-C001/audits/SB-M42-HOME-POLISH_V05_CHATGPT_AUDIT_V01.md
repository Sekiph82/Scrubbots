# SB-M42 HOME POLISH V05 — ChatGPT Independent Audit V01

Date: 2026-09-26
Auditor: ChatGPT
Baseline SHA: `4b961bb13e1ff9c74dcc3a943de93071453d22bb`
Implementation SHA: `6d1708a3981585ce115e14290eff104f1ddaa232`
Evidence / Claude log SHA: `43df37b19f6a41c4fc09eccc13d47f2dfc61f186`

Owner decision:
`coordination/OWNER_M42_HOME_POLISH_V05.md`

Prompt:
`coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-POLISH_V05.md`

Criteria:
`coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-POLISH_V05.md`

## Verdict

**AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW**

No source/test remediation is required from the independent audit.

SB-M42-011 and SB-M42-017 remain open because V05 explicitly requires fresh owner runtime visual acceptance.

## 1. Commit scope / protected files

Independent compare `4b961bb..6d1708a` is exactly one implementation commit changing five source/test files:

- `scripts/ui/home/home_screen.gd`
- `scripts/ui/home/home_style.gd`
- `tests/m42_home.gd`
- `tests/m42_home_v04.gd`
- `tests/m42_home_v05.gd`

Verified:
- PNG changes: **0**
- manifest changes: **0**
- root `TASKS.md` changes by Claude: **0**
- owner decision changes by Claude: **0**
- ChatGPT prompt/audit/criteria changes by Claude: **0**

The follow-up `43df37b` is evidence/log only.

## 2. HOME-120 asset lock

GitHub blob identity is unchanged from baseline to implementation:

`208795e92533844065110a644ecf2c87184aca82`

for:

`assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png`

This is the previously approved exact file whose SHA-256 is:

`8e04eda668aabd9f96172c0e82fd7dd47e61083cb691402a313120443a525e5b`

No World 01 image generation, recompression, replacement or manifest mutation occurred in V05.

## 3. World transform lock

The previous V04 implementation derived the world transform from live HUD/stack geometry. V05 correctly separates this concern by introducing `compute_world_transform(viewport, safe_top, safe_bottom)`, using frozen V04 reference geometry.

The focused suite embeds and checks the complete audited V04 transform matrix with tolerances of:
- scale < 0.0005
- offset distance < 0.6 px

Verified canonical result:
- 1080×2160: scale **1.00000**, offset **(0,0)**

The matrix also covers all required phone/tablet sizes with both zero and synthetic top/bottom insets.

A separate focused case changes/collapses AdBannerSlot and verifies:
- HOME-120 global rect does not change;
- Scrubby placement does not change;
- only the live clip boundary changes.

This satisfies the V05 hard background-lock contract.

## 4. Scrubby hero enlargement

Source and focused tests verify:

- V04 base fit `k_v04 = 0.330973`
- V05 multiplier = **1.15**
- final fit `k = 0.380619`
- center X remains **540**
- soles Y remains **1297**
- scaling is derived around the visible feet anchor rather than texture center
- baked sign collision: none
- helper-bot collision: none

The measured visible bounds widen/upscale while preserving the same canonical feet line.

## 5. Four-panel glass treatment

Home remains exactly four shortcut panels:
- SHOP
- COLLECTION
- TASKS
- DAILY

Verified styling constants:
- body alpha **0.44**
- cyan outline **3 px**
- outer margin preserved
- common 210×156 panel geometry

Icon rules remain correct:
- SHOP / COLLECTION retain V04 enlargement
- TASKS / DAILY retain exact V04/V03 fitted size

The V05 test verifies these sizes from the actual textures/drawn icon boxes rather than by label-only assertions.

## 6. Scrub Bucks / Hearts HUD

The implementation now constructs both as layered assembled widgets:

- foreground icon
- dark-blue pill/chassis
- large live value
- separate green circular plus button attached to the right edge

Verified canonical geometry:
- icon drawn at **110×110**
- pill height **84–88 px**
- plus **88×88**
- plus corner radius resolves to a circle
- icon visibly overhangs top/bottom/left of the pill
- plus overlaps/attaches to pill end and is drawn after/in front of it
- Scrub Bucks / Hearts widgets and icons do not overlap each other or ProfileCard

Functional safety:
- `scrub_bucks_purchase_requested` and `hearts_purchase_requested` emit correctly
- economy snapshot remains unchanged after both signals
- no fake purchase/charge/product behavior is introduced

## 7. Gift Meter rebuild

Verified composition:

- overall assembly height: **128 px**
- central navy chassis: **88 px**
- gold/yellow progress bar: **54 px**
- HOME-051 emblem: **132×132**
- HOME-054 crate: **132×132**
- emblem and crate overhang chassis ends and draw above chassis
- live `N/1,000` remains centered in the bar
- gold fill is constrained so it is not obscured by the foreground emblem/crate
- no NEXT GIFT text
- no Event Points
- no invented timer/tab

The actual Gift Meter semantics remain unchanged.

## 8. Win Streak reward rail

Verified:

- total track height **120 px**
- rail <=90 px
- HOME-086 badge overhangs the rail in foreground
- HOME-090..094 gifts overhang rail top
- numeric labels remain exactly:
  `1 / 5 / 10 / 25 / 100`
- no `+` prefixes
- no `WIN` labels
- no repeated Scrub Bucks icon
- HOME-087 remains absent from active track presentation
- reached/current/future visual states are differentiated
- current step receives gold value + glow

The track remains shallow enough to preserve the requested lower-stack reflow.

## 9. AdBannerSlot

Verified source/test contract:

- ratio = `144 / 1080`
- clamp = **96..160 px**
- canonical 1080×2160 height = **144 px**
- vertical size flags exclude EXPAND
- slot size equals explicit minimum reservation
- `AdMount` remains empty
- no fake ad content exists
- collapse seam remains functional

This closes the oversized empty-ad-region defect at code/layout level.

## 10. BottomActionStack reflow

The implementation explicitly builds:

`PlayButton -> WinStreakRewardTrack -> BottomNav`

inside `BottomActionStack`, immediately above `AdBannerSlot`.

At 1080×2160 the audited layout values are:

| Element | V04 Y | V05 Y | Delta |
|---|---:|---:|---:|
| Play | 1490 | 1515 | +25 |
| Win Streak | 1661 | 1686 | +25 |
| BottomNav | 1797 | 1822 | +25 |
| AdBannerSlot | 1991 | 2016 | +25 |

The V05 test does not merely compare constants. It dynamically collapses the ad slot and verifies all three upper elements move by the same released amount while HOME-120 remains unchanged, then re-enables the slot and verifies exact position restoration.

The coming-soon/status label remains a child of Play and does not introduce a separate layout row.

## 11. Modal regression

Verified through actual Home and app-root tests:

- Daily hides HomeActionLayer, BottomActionStack and both HUD plus buttons
- Daily close restores exact Play geometry/state
- Settings opened through the real bottom-nav Settings path hides the same controls
- Back closes Settings and restores the stack

The successful V03/V04 modal fix is preserved after the V05 stack refactor.

## 12. Responsive / touch coverage

`m42_home_v05.gd` contains 13 substantive cases and validates seven viewport sizes, each with:
- no synthetic insets
- synthetic 132/96 top/bottom insets

It asserts:
- all BaseButtons >=88 px
- controls remain inside safe area
- Play remains below the mapped platform region
- AdBannerSlot remains within 96..160 and flush with safe-area bottom
- World transform remains locked to V04 expectations

## 13. Regression evidence

Claude's log records on implementation SHA `6d1708a`:

- `m42_assets`: 4/4 PASS
- `m42_home`: 19/19 PASS
- `m42_home_composition`: 9/9 PASS
- `m42_home_v04`: 18/18 PASS
- `m42_home_v05`: 13/13 PASS
- `m42_navigation`: 12/12 PASS
- `m42_opening`: 8/8 PASS
- root suite: 5322 checks ALL PASS
- all exits 0
- zero SCRIPT ERROR
- same eight intentional corrupt-image engine ERROR lines as baseline
- `git diff --check`: clean

The focused test contents substantively map to the V05 owner requirements.

## 14. Runtime evidence limitation

The repository contains V05 runtime evidence at:

`coordination/sessions/M42-C001/runtime_evidence/home_v05/`

including:
- 1080×2160
- 1290×2796
- 1080×1920
- 1536×2048
- V04-vs-V05 comparison
- ad-slot collapsed
- Daily modal
- Settings modal

The GitHub connector can verify these binary files exist in the evidence commit but does not expose their pixel content for independent visual inspection. Therefore this code audit intentionally does not replace owner visual acceptance.

## Gate impact

- SB-M42-011: **CODE_AUDIT_PASS / V05 / OWNER_VISUAL_REVIEW_REQUIRED**
- SB-M42-017: **CODE_AUDIT_PASS / V05 / OWNER_VISUAL_REVIEW_REQUIRED**
- SB-M42-032: unchanged Android real-device cinematic gate
- SB-M42-033: unchanged iOS-later gate

## Final

**AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW**

Next action: owner pulls current main, runs the game, and supplies a fresh V05 Home screenshot. Final Home closure still depends on owner visual acceptance.
