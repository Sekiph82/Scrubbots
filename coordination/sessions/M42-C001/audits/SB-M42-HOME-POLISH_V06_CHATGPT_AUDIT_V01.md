# SB-M42 HOME POLISH V06 — ChatGPT Independent Audit V01

Date: 2026-09-26
Auditor: ChatGPT
Baseline SHA: `e0949811797fbbdc651a3ba568f7afad4b549e21`
Implementation SHA: `0f0614f31e20abd4874d7543c6c513edbd86de5a`
Evidence / Claude log SHA: `ba9ea7f356b30407a710ecfec6e52011ee474ef1`

Owner decision:
`coordination/OWNER_M42_HOME_POLISH_V06.md`

Prompt:
`coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-POLISH_V06.md`

Criteria:
`coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-POLISH_V06.md`

## Verdict

**AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW**

No source/test remediation is required from the independent code audit.

SB-M42-011 and SB-M42-017 remain open because V06 still requires owner runtime visual acceptance.

## 1. Protected scope

Independent compare `e094981..0f0614f` changes only:
- economy config/docs;
- HeartService documentation/default seam;
- Home screen;
- focused regression tests / snapshot harness.

Verified:
- PNG changes: **0**
- `TASKS.md` changed by Claude: **no**
- HOME manifest blob changed: **no**
- owner decision files changed by Claude: **no**

## 2. HOME-120 lock

Baseline and V06 use the exact same Git blob:

`208795e92533844065110a644ecf2c87184aca82`

for:
`assets/ui/final/home/worlds/world_01_whispering_park_1080x2160.png`

Therefore World 01 art bytes are unchanged.

The focused V06 suite locks the previously audited full viewport/inset transform matrix and separately verifies changing/collapsing the ad slot does not move HOME-120.

Canonical 1080×2160 remains scale 1.0000 / offset (0,0).

## 3. Scrubby hero / focus separation

Verified source/test contract:
- total hero scale = **1.24× V04 fit**
- center X = **540**
- soles Y = **1297**
- growth is anchored from the soles
- baked sign collision = none
- four helper-bot collisions = none

`HeroFocusShade` is:
- native Godot GradientTexture2D
- dark navy, not bright
- peak alpha **0.20**
- radial/cosine feather to zero
- above WorldBackground
- behind Scrubby
- starts below the baked sign
- does not reach the helper-bot exclusion zones

No new raster asset was added.

## 4. Four shortcut panels

Verified:
- SHOP / COLLECTION / TASKS / DAILY only
- body alpha **0.51**
- cyan outline **3 px**
- panel dimensions/margins remain V05
- SHOP/COLLECTION icon sizing unchanged from V05
- TASKS/DAILY icon sizing unchanged from V05/V03

## 5. Scrub Bucks / Hearts widgets

Verified V06 geometry:
- visible icon remains **110 px**
- pill height **68 px**
- plus glyph **52 px**
- transparent hit target **88×88**
- plus visual is inside the right end of the pill
- no green circle
- native white plus + navy outline + cyan glow
- request signals remain intent-only and do not mutate economy

## 6. Heart display / canonical timing

V06 correctly supersedes the old 30-minute interval:

- `hearts.regen_seconds`: **1800 → 900**
- max remains 5
- refill/purchase prices unchanged
- wall-clock/offline/background semantics unchanged

UI:
- no `N/5` inside pill
- current count is white text on the Heart icon
- full state displays static `15:00`
- after consume, countdown comes from `HeartService.seconds_to_next()`
- Home only refreshes presentation at 1 Hz; it does not own authoritative timer state

Focused Heart tests verify:
- consume from full => 900 seconds remaining
- 899 sec => no regen
- 900 sec => +1 Heart
- multiple missing Hearts regenerate every 900 sec
- offline accrual remains correct
- clock rollback remains fail-closed
- purchase/refill behavior remains atomic

## 7. Gift Meter / Win Streak / locked V05 areas

V06 focused tests explicitly lock V05 geometry for:
- Gift Meter
- Win Streak rail
- Play
- BottomNav
- profile
- modal behavior

No V06 redesign was introduced in those owner-locked areas.

## 8. Ad slot / lower stack

Verified:
- 1080×2160 AdBannerSlot = **100 px**
- responsive clamp = **72..112 px**
- no vertical EXPAND
- empty AdMount preserved
- collapse seam preserved

At canonical 1080×2160:
- Play: 1515 → **1559**
- Win Streak: 1686 → **1730**
- BottomNav: 1822 → **1866**
- Ad slot: 2016 → **2060**

All move exactly **+44 px**, while HOME-120 remains fixed.

## 9. Regression evidence

Claude log records:
- m39b_hearts_speed PASS
- m40_save_system PASS
- m42_assets 4/4
- m42_home 19/19
- m42_home_composition 9/9
- m42_home_v04 18/18
- m42_home_v05 13/13
- m42_home_v06 13/13
- m42_navigation 12/12
- m42_opening 8/8
- root 5322 checks ALL PASS
- all exit 0
- zero SCRIPT ERROR
- same 8 intentional corrupt-image engine ERROR lines
- git diff --check clean

The V06 focused tests are substantive and directly exercise the owner requirements.

## 10. Owner screenshot review

The supplied V06 runtime screenshot confirms the intended direction visually:
- Scrubby is materially more dominant than V05.
- Heart count is on the Heart icon.
- Heart pill shows 15:00.
- plus glyphs sit inside the thinner pills.
- panels are more readable.
- lower action stack is lower than V05.

One visual item should remain under owner review before closing 011/017:
the dark ad-reservation band still reads larger than expected in the embedded debug screenshot, despite the code-level slot measuring 100 px at the canonical 1080×2160 reference and 72..112 responsively. This may be embedded-debug scaling/safe-area presentation rather than the AdBannerSlot itself. Do not alter it from screenshot impression alone without measuring the actual runtime region at the owner's test viewport.

## Gate impact

- SB-M42-011: **CODE_AUDIT_PASS / V06 / OWNER_VISUAL_REVIEW_REQUIRED**
- SB-M42-017: **CODE_AUDIT_PASS / V06 / OWNER_VISUAL_REVIEW_REQUIRED**
- SB-M42-032: unchanged Android physical-device gate
- SB-M42-033: unchanged iOS-later gate

## Final

**AUDITED_PASS / CODE READY FOR OWNER VISUAL REVIEW**
