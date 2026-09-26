# SB-M42 HOME POLISH V07 — CHATGPT AUDIT CRITERIA

## Verdict

Pass only if the Windows desktop false safe-area inflation is fixed without changing V06 Home geometry.

## 1. Platform policy

Independent source inspection must verify:
- Windows runtime safe area policy = zero margins
- macOS = zero
- Linux = zero
- Android uses DisplayServer safe area
- iOS uses DisplayServer safe area
- Web may use DisplayServer safe area
- unknown desktop-like platforms fail safely to zero

A small explicit testable helper is preferred.

## 2. Synthetic seam

- synthetic insets override platform policy
- M28 synthetic non-zero safe-area behavior remains unchanged
- M42 synthetic viewport matrix remains unchanged

## 3. Home lock

No changes to V06 Home geometry/constants:
- HOME-120
- world transform
- AD_SLOT_RATIO / min / max
- Scrubby
- HeroFocusShade
- 4 panels
- currency / Heart HUD
- Gift Meter
- Win Streak
- Play
- BottomNav
- Heart regen

## 4. Windows expected geometry

At width 683:
- V06 ad reservation computes/clamps to 72 logical px
- desktop bottom safe-area margin resolves to zero
- no taskbar/work-area delta is added as mobile safe-area
- AdBannerSlot remains the only dark ad reservation below BottomNav

## 5. Mobile behavior

- genuine Android/iOS safe-area probe remains active
- BottomNav/AdBannerSlot may still paint through a genuine mobile bottom inset
- no removal of expand-margin behavior solely to hide the Windows symptom

## 6. Tests

Required:
- focused V07 safe-area suite PASS
- m28_gameplay_layout_smoke PASS
- m42_home_v06 PASS
- m42_navigation PASS
- root run_tests PASS
- zero SCRIPT ERROR
- git diff --check clean

## 7. Integrity

- PNG changes = 0
- manifest unchanged
- HOME-120 unchanged
- TASKS.md / owner files / ChatGPT files untouched by Claude

## Result labels

- AUDITED_PASS / OWNER_RUNTIME_RECHECK_REQUIRED
- CHANGES_REQUIRED
