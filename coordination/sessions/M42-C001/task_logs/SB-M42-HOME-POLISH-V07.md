# SB-M42 HOME POLISH V07 — Claude implementation log (desktop safe-area fix)

Status: **AWAITING_CHATGPT_AUDIT** (implementer log; no self-audit; owner visual acceptance NOT claimed)

Prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-POLISH_V07.md`
Owner decision: `coordination/OWNER_M42_HOME_POLISH_V07_DESKTOP_SAFE_AREA.md`

## Commits

| Role | SHA |
|---|---|
| Baseline (synced `origin/main`) | `30b857c` |
| Implementation + tests (final implementation SHA) | `632bc2e` |
| Evidence + this log | follow-up commit |

## Changed files

- `scripts/ui/safe_area_root.gd` — platform policy (only runtime change; CRLF/space style preserved).
- `tests/m42_home_v07_safe_area.gd` (new, 9 cases).
- `tests/tools/home_safe_area_probe.gd` (new windowed runtime probe; not part of any suite).
- Evidence: `coordination/sessions/M42-C001/runtime_evidence/home_v07/`.

Not changed: `home_screen.gd` and every V06 constant (AD_SLOT_RATIO 100/1080, clamp 72..112, world transform,
Scrubby 1.24, HeroFocusShade, panel alpha 0.51, pills 68, plus glyphs, Gift Meter, Win Streak, Play, BottomNav),
Heart regen, modal logic, `expand_margin_bottom` inset painting, assets/manifest, TASKS.md, owner/ChatGPT files.

## Platform-policy helper

```gdscript
const RUNTIME_SAFE_AREA_PLATFORMS := ["Android", "iOS", "Web"]
static func uses_runtime_display_safe_area(os_name: String) -> bool
static func margins_from_probe(safe: Rect2i, screen: Vector2i, viewport_size: Vector2) -> Array   # [l,t,r,b]
func get_applied_margins() -> Array
```

`_apply_safe_area()` precedence: 1) synthetic insets (exactly as before, every platform); 2) any OS not in the list
(Windows, macOS, Linux, FreeBSD/NetBSD/OpenBSD/"BSD", …) → zero margins; 3) Android/iOS/Web → the existing probe
conversion (moved unchanged into `margins_from_probe`); 4) invalid/empty probe → zero.

## Windows before / after (real embedded window, this machine)

`godot --path . --resolution 683x1366 -s res://tests/tools/home_safe_area_probe.gd` (Home in the ROOT window, project
stretch `canvas_items` / base 1080x2160, no synthetic insets):

| Item | Value |
|---|---|
| OS | Windows |
| Window size | 683 x 1366 |
| Screen size | 2560 x 1600 |
| `get_display_safe_area()` | (0,0) 2560 x 1504 → desktop work area (96 px taskbar) |
| Logical viewport | 1080 x 2160 (stretch scales the 683x1366 window) |
| Pre-V07 margins (same probe, old conversion) | [0, 0, 0, **130**] — false bottom inset |
| V07 applied margins | [0, 0, 0, **0**] |
| AdBannerSlot | (0, 2060) 1080 x **100** logical (≈ 63 window px), ends at the screen bottom |
| BottomNav | (0, 1866) 1080 x 178 |
| PLAY | (305, 1559) 470 x 155 |
| World transform | scale 1.0, offset (0, 0) — unchanged |

Pre-V07 the ad slot moved up to y 1930 and its panel painted through the false 130 px inset: a dark band of 230 logical
px (~2.3x the reservation) — the owner's defect. V07: exactly the 100 px reservation, no taskbar-derived strip.
Note: in the real app a 683x1366 window has a 1080-wide LOGICAL viewport (stretch), so the ad is 100 logical px; the
72 px width clamp applies only to a 683-px logical viewport, which the focused test covers directly (see below).

Evidence: `home_windows_runtime.png` (V07), `home_windows_pre_v07_simulated.png` (the measured pre-V07 margins applied
through the synthetic seam), `compare_pre_v07_vs_v07_683x1366.png`, `runtime_probe.txt`. Vision inspected: V07 shows
only the thin ad band under the nav; the simulation reproduces the tall dark band.

## Tests

`tests/m42_home_v07_safe_area.gd` — 9/9 cases, 0 failures:
1–6 policy: Windows / macOS / Linux / FreeBSD / NetBSD / OpenBSD / "BSD" false; Android / iOS / Web true.
7 synthetic insets override desktop policy (exact, negatives still clamp, clearing returns to policy).
8 empty/invalid probe → zeros; mobile probe conversion unchanged ([0,132,0,96]); a desktop work-area probe would have
produced a false 48 px inset (sanity) and is never used on desktop.
9 Home 1080x2160 without synthetic insets: margins 0, AdBannerSlot 100 px at the bottom.
10 Home 683x1366 logical: bottom inset 0, ad reservation 72 px (width clamp), nav directly above it, inset painting kept.
    (A 683-px logical viewport is below the V06 layout's minimum width; V06 targets the 1080 logical canvas.)
11 full 14-row V06 world-transform matrix unchanged.
12 synthetic [0,132,0,96] matrix at 7 sizes: margins applied, all buttons ≥ 88 inside the safe area, ad at the safe
bottom and still painting through the inset (expand_margin_bottom ≥ 96). Plus V06 constants asserted unchanged.

| Suite | Result | SCRIPT ERROR | engine ERROR* |
|---|---|---|---|
| `tests/m42_home_v07_safe_area.gd` | 9/9, exit 0 | 0 | 0 |
| `tests/m28_gameplay_layout_smoke.gd` | PASS, exit 0 | 0 | 14 (`Parameter "t" is null` — identical 14 on the baseline safe_area_root.gd, pre-existing) |
| `tests/m22_responsive_smoke.gd` (safe-area smoke, extra) | PASS, exit 0 | 0 | 0 |
| `tests/m42_home_v06.gd` | 13/13, exit 0 | 0 | 0 |
| `tests/m42_home_v05.gd` | 13/13, exit 0 | 0 | 0 |
| `tests/m42_home_v04.gd` | 18/18, exit 0 | 0 | 0 |
| `tests/m42_home.gd` | 19/19 PASS, exit 0 | 0 | 0 |
| `tests/m42_home_composition.gd` | 9/9, exit 0 | 0 | 0 |
| `tests/m42_assets.gd` | 4/4 PASS, exit 0 | 0 | 0 |
| `tests/m42_navigation.gd` | 12/12 PASS, exit 0 | 0 | 0 |
| `tests/m42_opening.gd` | 8/8 PASS, exit 0 | 0 | 0 |
| `tests/run_tests.gd` | 5322 checks, ALL PASS, exit 0 | 0 | 8 (pre-existing intentional corrupt-PNG fixtures = baseline) |

\* excluding exit-time teardown notices. `git diff --check` clean. Headless `project.godot` churn restored, not committed.

## Asset / protected-file integrity

All 470 PNG blobs under `assets/` identical to the baseline tree (0 mismatches); `HOME_ASSET_MANIFEST.json`, HOME-120,
`TASKS.md` and `coordination/OWNER_*` unchanged (`git diff --quiet`). No ChatGPT audit/criteria file touched.

Final handoff: `AWAITING_CHATGPT_AUDIT / M42 HOME POLISH V07`
