# OWNER M42 HOME POLISH V07 — DESKTOP SAFE-AREA FIX

Date: 2026-09-26
Authority: OWNER
Scope: tiny final fix for desktop/Godot embedded-debug bottom safe-area inflation

## Problem

In the Windows Godot embedded/debug runtime, `DisplayServer.get_display_safe_area()` can report the desktop work area rather than the full physical screen. The Windows taskbar/work-area difference is then interpreted by `SafeAreaRoot` as a mobile-style bottom safe inset.

Because Home's `AdBannerSlot` intentionally paints through a real mobile bottom safe inset, that false desktop inset makes the dark ad region appear roughly twice as tall as the actual V06 ad reservation.

At the owner's current 683×1366 debug viewport:
- V06 AdBannerSlot itself is clamped to 72 logical px.
- the extra apparent dark area comes from the desktop/taskbar safe-area interpretation.

## Owner decision

Desktop operating systems must NOT derive mobile UI safe-area margins from `DisplayServer.get_display_safe_area()`.

For:
- Windows
- macOS
- Linux
- FreeBSD / BSD desktop variants if encountered

runtime safe-area margins default to zero.

Real runtime safe-area probing remains enabled for:
- Android
- iOS

Web may keep the current runtime probe because browser/mobile-web handling is platform/browser dependent and is not the source of this Windows defect.

## Synthetic test seam

`set_synthetic_insets(...)` remains authoritative on every platform, including desktop/headless tests.

The existing synthetic safe-area test matrix must continue to work exactly as before.

Order of precedence in `SafeAreaRoot._apply_safe_area()`:

1. synthetic insets, when set;
2. if runtime platform is desktop, use zero margins;
3. otherwise use the existing DisplayServer safe-area probe;
4. invalid/empty probe falls back to zero.

## Home behavior

Do NOT change:
- V06 AdBannerSlot sizing rule (100 px @1080, responsive clamp 72..112);
- HOME-120;
- World transform;
- Scrubby;
- HeroFocusShade;
- shortcut panels;
- currency/Heart HUD;
- Gift Meter;
- Win Streak;
- Play;
- BottomNav;
- Heart regen;
- mobile safe-area behavior.

Keep the existing `expand_margin_bottom` behavior on BottomNav/AdBannerSlot so a genuine mobile gesture/home-indicator inset is painted cleanly.

## Expected desktop result

At the owner's 683×1366 Windows embedded-debug viewport:
- safe-area bottom inset should resolve to 0;
- AdBannerSlot should remain the width-clamped 72 logical px reservation;
- the additional taskbar-derived dark strip should disappear.

This is a safe-area platform bug fix, not a new Home redesign.

Final owner runtime screenshot remains required before closing SB-M42-011 / SB-M42-017.
