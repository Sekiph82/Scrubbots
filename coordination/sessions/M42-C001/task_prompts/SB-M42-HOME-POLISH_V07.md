# SB-M42 HOME POLISH V07 — DESKTOP SAFE-AREA FIX

Status: ACTIVE
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_M42_HOME_POLISH_V07_DESKTOP_SAFE_AREA.md`
4. `coordination/OWNER_M42_HOME_POLISH_V06.md`
5. `coordination/sessions/M42-C001/audits/SB-M42-HOME-POLISH_V06_CHATGPT_AUDIT_V01.md`
6. `scripts/ui/safe_area_root.gd`
7. `scenes/components/ui/common/safe_area_root.tscn`
8. `scripts/ui/home/home_screen.gd`

Do NOT edit:
- root `TASKS.md`
- owner decision files
- ChatGPT audit/criteria files

## Mission

Fix the Windows/Godot embedded-debug false bottom safe-area inflation without changing Home V06.

The bug:
`DisplayServer.get_display_safe_area()` on Windows may reflect the desktop work area (excluding the taskbar). The current `SafeAreaRoot` interprets that work-area difference as a mobile bottom safe inset. Home then paints AdBannerSlot through that false inset, making the dark ad band appear much taller than the actual slot.

## Required implementation

### 1. Platform-aware runtime safe area

Refactor `SafeAreaRoot._apply_safe_area()` so precedence is:

1. if synthetic insets are set, use them exactly;
2. desktop runtime platforms use zero safe-area margins;
3. Android/iOS use the existing DisplayServer safe-area probe;
4. Web may keep the existing probe;
5. invalid/empty probe falls back to zero.

Desktop platforms to treat as zero at runtime:
- Windows
- macOS
- Linux
- FreeBSD
- NetBSD
- OpenBSD
- DragonFly BSD if Godot reports it

Do not hard-code against the actual current machine only. Use a small explicit helper such as:

`static func uses_runtime_display_safe_area(os_name: String) -> bool`

or equivalent, so the platform policy is directly testable.

Suggested policy:
- Android -> true
- iOS -> true
- Web -> true
- everything else -> false

Then `_apply_safe_area()` can return zero margins for non-runtime-safe-area platforms.

### 2. Preserve synthetic seam

This is critical.

`set_synthetic_insets(left, top, right, bottom)` must override platform policy and work on desktop/headless exactly as before.

Do not remove or weaken the M28/M42 synthetic safe-area coverage.

### 3. Do NOT touch Home geometry

Do not change any V06 Home constants or visual layout:

- `AD_SLOT_RATIO`
- `AD_SLOT_MIN_H`
- `AD_SLOT_MAX_H`
- HOME-120
- world transform
- Scrubby scale/anchor
- HeroFocusShade
- panel alpha
- currency/Heart pills
- plus glyphs
- Gift Meter
- Win Streak
- Play
- BottomNav
- Heart regen
- modal behavior

The V06 ad reservation remains:
- 100 px @1080 width
- clamp 72..112

Keep `expand_margin_bottom` behavior. Genuine mobile gesture/home-indicator safe-area painting is still desired.

## Required tests

Add focused coverage for SafeAreaRoot.

At minimum prove:

1. `uses_runtime_display_safe_area("Windows") == false`
2. macOS == false
3. Linux == false
4. Android == true
5. iOS == true
6. Web == true
7. synthetic insets still override desktop policy
8. invalid/empty DisplayServer safe area still falls back to zero
9. Home V06 canonical 1080x2160 AdBannerSlot remains 100 px
10. Home 683x1366 width case resolves to the width-clamped 72 px ad reservation when bottom safe inset is zero
11. full V06 world transform matrix remains unchanged
12. existing non-zero synthetic safe-area matrix remains valid

A dedicated test such as:
`tests/m42_home_v07_safe_area.gd`
is preferred.

Also run:
- `tests/m28_gameplay_layout_smoke.gd`
- `tests/m42_home_v06.gd`
- `tests/m42_navigation.gd`
- `tests/run_tests.gd`
- `git diff --check`

All must exit 0 with zero SCRIPT ERROR.

## Runtime evidence

Capture a fresh Windows embedded/debug Home screenshot at the owner's approximate 683×1366 viewport if available.

Also log:
- actual viewport logical size;
- SafeAreaRoot margins left/top/right/bottom;
- AdBannerSlot rect;
- BottomNav rect.

Expected Windows result:
- bottom safe inset = 0;
- at 683 px width, AdBannerSlot height = 72 logical px;
- no taskbar-derived extra dark strip.

Store evidence under:
`coordination/sessions/M42-C001/runtime_evidence/home_v07/`

## Asset / protected-file integrity

- no PNG changes;
- manifest unchanged;
- HOME-120 unchanged;
- no owner/ChatGPT/TASKS edits by Claude.

## Log

Create:
`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-POLISH-V07.md`

Include:
- baseline/final SHA
- changed files
- platform-policy helper
- Windows before/after safe-area behavior
- 683×1366 measured ad/safe-area geometry if runtime capture is available
- test results
- asset integrity proof

Do NOT claim owner visual acceptance.

Finish:
`AWAITING_CHATGPT_AUDIT / M42 HOME POLISH V07`
