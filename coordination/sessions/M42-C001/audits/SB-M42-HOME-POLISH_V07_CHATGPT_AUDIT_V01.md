# SB-M42 HOME POLISH V07 — ChatGPT Independent Audit V01

Date: 2026-09-26
Auditor: ChatGPT
Baseline SHA: `30b857cc5bb9e94d74a1b06e49c181f2cb1d2a66`
Implementation SHA: `632bc2ef74cb239f7e7ba1d8955499604dafa15d`
Evidence / Claude log SHA: `701823f0ff2b15682028858ecb2eb6ce27f57e59`

Owner decision:
`coordination/OWNER_M42_HOME_POLISH_V07_DESKTOP_SAFE_AREA.md`

Prompt:
`coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-POLISH_V07.md`

Criteria:
`coordination/sessions/M42-C001/audit_criteria/SB-M42-HOME-POLISH_V07.md`

## Verdict

**AUDITED_PASS / OWNER_RUNTIME_RECHECK_REQUIRED**

The Windows/Godot embedded-debug false bottom safe-area inflation is fixed at code level and is also consistent with the owner-supplied runtime screenshots.

No further code remediation is required for V07.

## 1. Commit scope

Independent compare `30b857c..632bc2e` contains exactly three files:

- `scripts/ui/safe_area_root.gd`
- `tests/m42_home_v07_safe_area.gd`
- `tests/tools/home_safe_area_probe.gd`

Verified:
- Home screen source changed: **no**
- V06 Home constants changed: **no**
- PNG changes: **0**
- asset manifest changes: **0**
- root `TASKS.md` changes by Claude: **0**
- owner / ChatGPT files changed by Claude: **0**

This is correctly scoped as a shared SafeAreaRoot policy fix rather than another Home redesign.

## 2. Platform policy

`SafeAreaRoot` now exposes:

- `uses_runtime_display_safe_area(os_name)`
- `margins_from_probe(...)`
- `get_applied_margins()`

Runtime probe policy is explicit:

- Android: probe enabled
- iOS: probe enabled
- Web: probe enabled
- Windows: zero runtime safe-area margins
- macOS: zero
- Linux: zero
- BSD desktop variants: zero
- unknown/non-listed desktop-like OS: fail-safe zero

This prevents desktop work-area/taskbar geometry from being interpreted as a mobile notch/home-indicator inset.

## 3. Precedence / synthetic seam

Independent source review verifies `_apply_safe_area()` precedence:

1. synthetic insets, when present;
2. desktop runtime -> zero margins;
3. Android/iOS/Web -> DisplayServer probe;
4. invalid/empty probe -> zero.

Therefore the existing synthetic safe-area test seam remains authoritative even on desktop/headless runs.

This preserves M28/M42 notch/gesture-bar regression coverage.

## 4. Mobile behavior preserved

The fix does **not** remove genuine mobile safe-area support.

Android and iOS still use `DisplayServer.get_display_safe_area()`, with the previous viewport-space conversion moved into a pure helper.

The Home BottomNav / AdBannerSlot `expand_margin_bottom` behavior remains untouched, so a real mobile gesture/home-indicator inset can still be painted cleanly.

## 5. Windows runtime probe evidence

Repository runtime evidence records a real Windows 683×1366 window:

- physical window: **683×1366**
- screen: **2560×1600**
- raw DisplayServer safe area: **2560×1504**
- old/pre-V07 conversion: **[0,0,0,130]**
- V07 applied margins: **[0,0,0,0]**
- logical viewport after project stretch: **1080×2160**
- AdBannerSlot: **(0,2060), 1080×100**
- BottomNav: **(0,1866), 1080×178**
- Play: **(305,1559), 470×155**
- world transform: **scale 1.0 / offset (0,0)**

The old Windows work-area conversion therefore produced a false 130-logical-pixel bottom inset. V07 removes exactly that false inset.

## 6. Independent screenshot measurement

The owner supplied the resulting V07 runtime images in this conversation.

ChatGPT independently measured the direct 683×1366 runtime image:

- contiguous dark ad band at the bottom: approximately **62 px** in the physical screenshot.

Expected physical height from a 100-logical-pixel AdBannerSlot rendered in a 683-wide window with the project's 1080-wide logical canvas:

`100 × 683 / 1080 ≈ 63.2 px`

The measured ~62 px is therefore consistent with the intended **single 100-logical-pixel ad reservation** after scaling.

The full desktop embedded screenshot independently shows a bottom dark band of about **49–50 displayed px** inside the scaled game viewport, again consistent with the same 100-logical-pixel slot at that editor preview scale.

This is materially different from the pre-V07 doubled/tall dark region.

## 7. 683-logical-width focused seam

The focused V07 suite also directly constructs a 683×1366 **logical** viewport and verifies:

- bottom safe inset = 0
- AdBannerSlot = **72 px**, from the existing 72..112 clamp
- nav sits immediately above the ad
- genuine mobile inset-painting behavior remains available.

This is separate from the real 683×1366 desktop window, where project stretch yields a 1080-wide logical viewport and therefore a 100 px slot.

That distinction is correct.

## 8. V06 Home lock

V07 focused tests explicitly prove the following remain unchanged:

- `AD_SLOT_RATIO = 100/1080`
- `AD_SLOT_MIN_H = 72`
- `AD_SLOT_MAX_H = 112`
- Scrubby scale = 1.24
- panel alpha = 0.51
- currency/Heart pill height = 68
- full V06/V05/V04 world-transform matrix
- synthetic safe-area layout matrix

No V07 source change occurred in `home_screen.gd`.

## 9. Tests

Claude's log records:

- `m42_home_v07_safe_area`: 9/9 PASS
- `m28_gameplay_layout_smoke`: PASS
- `m22_responsive_smoke`: PASS
- `m42_home_v06`: 13/13
- `m42_home_v05`: 13/13
- `m42_home_v04`: 18/18
- `m42_home`: 19/19
- `m42_home_composition`: 9/9
- `m42_assets`: 4/4
- `m42_navigation`: 12/12
- `m42_opening`: 8/8
- root: 5322 checks ALL PASS
- all exit 0
- zero SCRIPT ERROR
- root's same 8 intentional corrupt-image engine errors
- M28's 14 engine errors reproduced on baseline
- `git diff --check`: clean

## 10. Asset / protected-file integrity

Independent implementation compare shows zero PNG changes.

Claude additionally reports all asset PNG blobs unchanged and manifest/HOME-120 untouched.

Because the implementation commit modifies no Home art or Home layout source, V07 does not reopen any previously approved art lifecycle.

## Gate impact

- SB-M42-011: **CODE_AUDIT_PASS / V07 / OWNER_VISUAL_ACCEPTANCE_REQUIRED**
- SB-M42-017: **CODE_AUDIT_PASS / V07 / OWNER_VISUAL_ACCEPTANCE_REQUIRED**
- SB-M42-032: unchanged Android physical-device cinematic gate
- SB-M42-033: unchanged iOS-later gate

## Final

**AUDITED_PASS / OWNER_RUNTIME_RECHECK_REQUIRED**

The ad-area bug is fixed. The current screenshots now show only the intended ad reservation rather than a taskbar-derived extra safe-area strip.

If the owner visually accepts the current Home, SB-M42-011 and SB-M42-017 can be closed.
