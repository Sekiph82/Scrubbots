# SB-M42 HOME POLISH V05 — Claude implementation log

Status: **AWAITING_CHATGPT_AUDIT** (implementer log; no self-audit; owner visual acceptance NOT claimed)

Prompt: `coordination/sessions/M42-C001/task_prompts/SB-M42-HOME-POLISH_V05.md`
Owner decision: `coordination/OWNER_M42_HOME_POLISH_V05.md`

## Commits

| Role | SHA |
|---|---|
| Baseline (synced `origin/main`) | `4b961bb` |
| Implementation + tests (final implementation SHA) | `6d1708a` |
| Evidence + this log | follow-up commit |

## Changed files

- `scripts/ui/home/home_screen.gd` — world-transform lock, Scrubby x1.15, BottomActionStack, currency widgets, Gift
  Meter assembly, reward rail, ad-slot reservation.
- `scripts/ui/home/home_style.gd` — `style_light_panel(b, label_top, alpha, border)`.
- `tests/m42_home_v05.gd` (new, 13 cases); `tests/m42_home_v04.gd` and `tests/m42_home.gd` updated (see below).
- Evidence: `coordination/sessions/M42-C001/runtime_evidence/home_v05/`.

No asset, manifest, world-catalog, TASKS.md, owner-decision or ChatGPT-file change.

## A. World-transform lock

V04 derived the transform from the live layout. V05 makes it a **pure function**
`HomeScreen.compute_world_transform(viewport, safe_top, safe_bottom)` of the viewport, the safe area and the frozen
V04 reference geometry measured on `a8b953e` with the same harness (per layout mode COMPACT/NORMAL/TALL:
V04 stack height PLAY→ad 477/501/525, Gift Meter bottom 398/406/414, ad reservation round(clamp(w·50/320,100,180))).
HUD, stack or ad-slot changes therefore cannot move HOME-120; only the canvas clip (ad-slot top) moves.

Regression (`m42_home_v05` world_lock_matrix, tolerance scale 5e-4 / offset 0.6 px) — all equal to V04:

| Viewport | insets top/bottom | scale | offset |
|---|---|---|---|
| 1080x2160 | 0/0 | 1.00000 | (0, 0) |
| 1080x2160 | 132/96 | 1.00000 | (0, 0) |
| 1170x2532 | 0/0 | 1.08889 | (-3, 0) |
| 1170x2532 | 132/96 | 1.08333 | (0, 0) |
| 1290x2796 | 0/0 | 1.21111 | (-9, 0) |
| 1290x2796 | 132/96 | 1.19444 | (0, 0) |
| 1080x2400 | 0/0 | 1.03287 | (-17.75, 0) |
| 1080x2400 | 132/96 | 1.00000 | (0, 0) |
| 1440x3200 | 0/0 | 1.39815 | (-35, 0) |
| 1440x3200 | 132/96 | 1.35370 | (-11, 0) |
| 1080x1920 | 0/0 | 1.00000 | (0, -79) |
| 1080x1920 | 132/96 | 0.91329 | (46.8, -58.4) |
| 1536x2048 | 0/0 | 1.41185 | (5.6, -515.9) |
| 1536x2048 | 132/96 | 1.08237 | (183.5, -168.8) |

`world_fixed_when_ad_changes`: collapsing the ad slot and setting it to 96 px leave the HOME-120 rect and Scrubby
unchanged. Because the ad slot is now shorter, on tall phones the clip boundary sits a few px below the image bottom;
that band lies behind the opaque nav dock (asserted in `m42_home_v04` responsive_matrix: the world covers the canvas
down to the BottomNav top).

## B. Scrubby

k_v04 = 0.330973 (V04 safe-box fit), **final factor 1.15** → k = 0.380619, scaled about the visible soles.
Canonical: centre X 540.000, soles Y 1297.000; visible rect x 325.0..755.0, y 798.0..1303.1 (brush bristles +6.1 px).
Clears the baked sign (bottom 745) and all four helper-bot rects; no reduction was needed.

## C. Panels

Body `Color(0.030, 0.105, 0.290, 0.44)` (hover +0.10, pressed +0.16, disabled 0.44), outline 3 px
`Color(0.50, 0.87, 1.0, 0.90)` (disabled 0.80), soft cyan glow 8 px. Size 210x156, edge margin 26 px.
Icons unchanged: SHOP/COLLECTION 1.2 x V03 box, TASKS/DAILY exact V03 size.

## D. Currency / Hearts widgets (1080x2160)

`ScrubBucksWidget` / `HeartsWidget` = pill (UiValueChip, 262 wide, 88 tall; min 84) + (+) Button 88x88
(corner radius 44, white rim, content margins 0) overlapping the pill's right end by 22 px and drawn after it.
Icon footprint 80, drawn 110x110 (pop 1.375), right edge on the footprint edge, overhanging the pill top, bottom and
left end, above the pill body. Value font 46, outline 12. Row gap 26 so the icons never touch. SB icon at
(714, 21, 110x110), SB pill (734, 32, 262x88), (+) (974, 32, 88x88). (+) emit `scrub_bucks_purchase_requested` /
`hearts_purchase_requested` only (economy snapshot unchanged).

## E. Gift Meter (1080x2160)

Assembly 128 px tall: navy chassis (884x88, 4 px cyan edge, radius 44) at x 98..982; inset gold bar 736x54 at x
172..908 on a darker trough with the live `N/1,000` (38 px, outline 12) centred; HOME-051 emblem 132x132 at x 34 and
HOME-054 crate 132x132 at x 914 (above the chassis, overhanging both ends); claimable badge on the crate. The gold bar
starts/ends past the emblem/crate so the fill is never hidden. No NEXT GIFT / timer / Event Points.

## F. Win Streak rail (1080x2160)

Track 120 px (= V04 height, so released ad space maps 1:1 onto the stack). Rail 986x82 (radius 34, cyan edge) from
y 1724; HOME-086 badge 112x112 in front, overhanging the rail's left end; progress line inside at y≈56 of the track;
gifts 82 px tall standing on the line and overhanging the rail top; values 1/5/10/25/100 (30 px) centred under them.
Current step: gold value + gold glow panel behind the gift; reached full; future dimmed (alpha 0.8/0.6).

## G/H. Ad slot + bottom stack (1080x2160)

AdBannerSlot = round(width·144/1080) clamped 96..160 → **144 px**, `SIZE_SHRINK_END`, never EXPAND; empty AdMount;
collapse seam kept. `BottomActionStack` (PLAY → WinStreakRewardTrack → BottomNav) is `SIZE_SHRINK_END` under the
expanding WorldMargin, so all released height lowers the whole stack.

| Element | V04 top Y | V05 top Y | Δ |
|---|---|---|---|
| PlayButton | 1490 | 1515 | +25 |
| WinStreakRewardTrack | 1661 | 1686 | +25 |
| BottomNav | 1797 | 1822 | +25 |
| AdBannerSlot | 1991 (169 px) | 2016 (144 px) | +25 |

(V04 values from the audited V04 build/harness; V05 measured.) `stack_reflow`: collapsing the slot lowers PLAY,
track and nav by exactly ad height + one layout gap; re-enabling restores exact positions; HOME-120 never moves.
The status pill remains a child of PLAY.

## I. Modals

`HomeActionLayer` (now containing `BottomActionStack`) + both (+) hidden for Daily and Settings (real `main.tscn`);
close/back restores the exact stack.

## Visual evidence (vision inspected)

`coordination/sessions/M42-C001/runtime_evidence/home_v05/`: `home_1080x2160.png`, `home_1290x2796.png`,
`home_1080x1920.png`, `home_1536x2048.png`, `home_adslot_collapsed_1080x2160.png`, `modal_daily_1080x2160.png`,
`modal_settings_1080x2160.png`, `compare_v04_vs_v05_1080x2160.png`, `iter1_home_1080x2160.png`.
Checked against the V04 evidence: world image pixel-aligned in both (identical placement); Scrubby visibly larger with
feet on the same platform spot; panels clearly visible yet see-through; SB/Hearts read as icon + pill + (+) widgets;
Gift Meter reads as an assembled HUD meter; reward rail with gifts on it; ad band clearly shorter; PLAY/track/nav
lower by the same 25 px; action UI absent behind Daily and Settings.
Iteration fixes: gold fill hidden under the emblem (bar now starts past it); taller HUD/meter pushed DAILY into the
upper-right bot at 1080x2160 (HUD margin 36→32, gap min 54, meter 128); a 150 px rail made the short-screen stack
taller than V04 so PLAY rose onto the platform (rail = V04 120 px); overlapping SB/heart icons (row gap 26, icon 110);
(+) grew to 88x100 from its font (content margins 0, font 52).
Residual (as in V04): on 1536x2048 the right column still shifts inward to clear the upper-right helper bot.

## Tests (headless, tree = `6d1708a`)

| Suite | Result | SCRIPT ERROR | engine ERROR* |
|---|---|---|---|
| `tests/m42_assets.gd` | 4/4 PASS, exit 0 | 0 | 0 |
| `tests/m42_home.gd` | 19/19 PASS, exit 0 | 0 | 0 |
| `tests/m42_home_composition.gd` | 9/9, exit 0 | 0 | 0 |
| `tests/m42_home_v04.gd` | 18/18, exit 0 | 0 | 0 |
| `tests/m42_home_v05.gd` | 13/13, exit 0 | 0 | 0 |
| `tests/m42_navigation.gd` | 12/12 PASS, exit 0 | 0 | 0 |
| `tests/m42_opening.gd` | 8/8 PASS, exit 0 | 0 | 0 |
| `tests/run_tests.gd` | 5322 checks, ALL PASS, exit 0 | 0 | 8 (pre-existing intentional corrupt-PNG fixtures = baseline) |

\* excluding exit-time teardown notices. `git diff --check` clean. Headless `project.godot` churn restored, not committed.

Suite updates: `m42_home_v04` keeps V04 invariants but now asserts the V05-changed values (the V04 base fit stays in
the safe box while V05 enlarges it; panel alpha 0.40..0.48 / 2–3 px; (+) attached over the pill end; ad 96..160; world
covers the canvas down to the nav top). `m42_home` region check now expects `BottomActionStack`.

Prompt list → `m42_home_v05`: 1,32 asset_integrity; 2–3 world_lock_matrix; 4 world_fixed_when_ad_changes; 5–8
scrubby_hero; 9–13 panels_glass; 14–17 currency_widgets; 18–20 gift_meter; 21–24 reward_rail; 25–26 ad_slot;
27 bottom_stack; 28 stack_reflow; 29–30 modals_hide_stack; 31 touch_targets (7 sizes x 2 inset sets, PLAY below the
platform region at every size).

## Asset integrity

All 457 PNG blobs under `assets/ui/final` (49 historical approved + HOME-120 + non-Home finals) identical to the baseline
tree (0 mismatches); HOME-120 SHA-256 `8e04eda6…5e5b` re-verified; all 51 manifest APPROVED pins match. No image
generated.

Final handoff: `AWAITING_CHATGPT_AUDIT / M42 HOME POLISH V05`
