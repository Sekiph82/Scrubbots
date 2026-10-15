# M49 Responsive UI — CLAUDE milestone master plan V01 (autonomous V02)

Date 2026-10-15 · Claude-authored under `coordination/autonomy/SCRUBBOTS_CLAUDE_AUTONOMOUS_MASTER_V02.md`. Scope: the existing rows `SB-M49-001..032`. No new product rule; no art change.

## Current state (inspected, not assumed)
- Foundations exist:
  - 1080×2160 reference viewport with `canvas_items` / `expand` stretch (`project.godot` HEAD) — 011;
  - `SafeAreaRoot` (+ synthetic-inset seam) — 012;
  - `UiTokens` (TOUCH_MIN 88) — 013;
  - `ResponsiveLayout` COMPACT / NORMAL / TALL — 014.
- Earlier evidence exists per subsystem, scattered across separate suites: M22 rail matrix, M28 layout, M42 home V04–V07 safe area, M43 R15 settings / daily matrix, M47 touch.
- What M49 adds: ONE permanent cross-surface matrix suite, `tests/m49_responsive_matrix.gd`, run on GitHub CI (`validation_only`).

## Matrix
- Physical 1080×1920 (16:9), 720×1280 (16:9 compact), 1080×2160 (18:9 reference), 1170×2532 (19.5:9), 1080×2400 (20:9), 1290×2796 (tall), 1440×3200 (tall 20:9), 1536×2048 (tablet).
- Each maps to the logical canvas used by the stretch policy (width-anchored ≥ 1080 or height-anchored 2160).
- Notch / cutout: synthetic insets top 132 / bottom 96.

## Cases (acceptance)
| Case | What it proves | Rows |
|---|---|---|
| m01 | COMPACT / NORMAL / TALL classification of every logical size; the required-device list (015–019) is the five canonical phones | 001–006, 014–019 |
| m02 | Home across the matrix and under notch insets: PLAY, four panels, bottom nav, HUD and Gift Meter inside the safe rect; PLAY / panel / nav buttons ≥ 88 px; PLAY does not overlap the panels | 001–006, 020, 021 |
| m03 | Gameplay L1 across the matrix and notch: board non-empty and inside the viewport; five slot views inside and non-overlapping; supply front hit rects inside and non-overlapping; Pause / 2x inside and top-right; four boosters ≥ 88 px and inside | 007, 008, 020, 023 |
| m04 | Touch mapping: a real platform-ordered tap (`push_input`) at each enabled front's hit-rect centre places exactly that column, on compact, reference and tall | 010 |
| m05 | +1 Slot sixth slot: six slot views inside and non-overlapping, 6-slot shell selected, on every size | 025 |
| m06 | Rectangular (3×2 fixture) and 59×59 boards in the production GameplayScreen: undistorted aspect, inside the board region | 009 |
| m07 | Popups under notch insets on compact and tall (Tasks, Daily, Gift Bar, Shop, Help & Tips, deep-link destinations): frame inside the safe rect | 021, 028 (modal), 030 (deep links) |
| m08 | Results WON (journey + Next Cleanup) on compact and tall: primary CTA ≥ 88 px and inside; journey strip inside | 026, 031, 032 (partial) |

## Not claimed / gated
- 022 / 027 localization-expansion stress (no shipped translations yet; needs a pseudo-locale strategy): open.
- 029 rewarded-ad / store return transitions (production provider unavailable): dependency-gated.
- 030 account / cloud conflict screens (not implemented): dependency-gated.
- Real-device visual sign-off: owner.

## CI
One planned `validation_only` run + at most one narrow remedial rerun (V02 policy). No APK.
