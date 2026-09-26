# SB-M42 HOME POLISH V05 — IMPLEMENTATION PROMPT

Status: ACTIVE
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Scope: SB-M42-011 + SB-M42-017 visual polish after audited V04

## Authority

Read first:

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_M42_HOME_POLISH_V05.md`
4. `coordination/OWNER_M42_HOME_REBUILD_V04_SINGLE_WORLD_BACKGROUND.md`
5. `coordination/sessions/M42-C001/audits/SB-M42-HOME-REBUILD_V04_CHATGPT_AUDIT_V01.md`
6. `assets/ui/HOME_ASSET_MANIFEST.json`
7. `scripts/ui/home/home_screen.gd`
8. `scripts/ui/home/home_style.gd`
9. `scripts/ui/home/home_presentation_map.gd`

V05 supersedes V04 only on the specific visual/layout points recorded in the V05 owner decision.

Do NOT edit:
- root `TASKS.md`
- owner decision files
- ChatGPT audit/criteria files

## Mission

Polish the existing V04 Home without changing the World 01 art placement.

Primary goals:
- keep HOME-120 world image transform unchanged;
- enlarge Scrubby while keeping his feet anchor fixed;
- make four shortcut panels visibly translucent rather than nearly invisible;
- rebuild Scrub Bucks / Hearts HUD toward the master mobile-game style;
- rebuild Gift Meter toward the master Gift Bar style while preserving current Gift Meter semantics;
- rebuild Win Streak track toward the master reward-rail style;
- shrink AdBannerSlot to the owner-marked banner height;
- move Play + Win Streak + BottomNav downward as one bottom-anchored stack when ad height shrinks.

## A. Hard world-transform lock

This is non-negotiable.

HOME-120:
- bytes unchanged;
- manifest approval unchanged;
- current V04 placement unchanged.

At 1080x2160:
- world scale must remain 1.0000;
- world offset must remain (0,0).

Preserve the V04 transform behavior at the full matrix using the baseline values recorded in the owner decision.

Do NOT:
- zoom HOME-120;
- shift it vertically to make room for UI;
- change its canonical crop;
- regenerate it;
- alter the world catalog anchor data unless required solely for Scrubby-size metadata.

The ad-slot clip boundary may move downward. The image itself must not.

Add a regression test that compares world transform against V04 baseline at all required viewports within a small tolerance.

## B. Scrubby hero enlargement

V04 canonical:
- center X = 540;
- feet anchor = (540,1297).

Keep both exact.

Increase Scrubby visible scale by approximately **15%** relative to V04.

Implementation rule:
- scale about the visible-feet anchor;
- do not scale from texture center;
- feet remain on y=1297;
- body grows upward/outward;
- do not cover the baked sign;
- do not materially overlap baked helper bots;
- do not move HOME-120.

A target factor around 1.15 × the V04 character fit is preferred. If helper-bot/sign collision appears, reduce only enough to clear them and document the final factor.

## C. Four shortcut panel styling

Keep exact membership:
LEFT:
- SHOP
- COLLECTION

RIGHT:
- TASKS
- DAILY

Current panel background is too faint.

Restyle all four with one coherent native Godot StyleBox:
- dark navy/cyan glass tint;
- target body alpha roughly **0.40–0.48**;
- 2–3 px cyan/blue outline;
- subtle glow/shadow permitted;
- clearly visible as a panel against the world;
- still transparent enough for world art to read through;
- preserve current outer margin.

Icon rules remain:
- SHOP enlarged;
- COLLECTION enlarged;
- TASKS exact current V04/V03 drawn size;
- DAILY exact current V04/V03 drawn size.

Do not enlarge TASKS or DAILY.

## D. Currency / Hearts HUD rebuild

Use the visual language in:
`assets/art/references/_owner_inbox/Game Screens/main screen.png`

Interpret the reference as STYLE ONLY. Preserve current ScrubBots semantics.

### Shared geometry

Build each currency widget as a layered assembly:

1. large foreground icon on left;
2. dark-blue rounded pill/chassis behind;
3. large live value text centered/left-centered in pill;
4. bright-green circular plus button attached at right;
5. icon and plus button visually above pill in z-order.

The icon must overhang the pill bounds rather than appear as a tiny image inside it.

### Scrub Bucks

- approved banknote icon only;
- never restore coin/star currency;
- live balance only;
- plus emits `scrub_bucks_purchase_requested`;
- no fake purchase behavior.

### Hearts

- approved red-heart icon;
- live N/max;
- canonical regen timer may show as secondary text only when hearts are below max;
- plus emits `hearts_purchase_requested`;
- no fake purchase behavior.

### Visual targets

At 1080x2160:
- icon height approximately 110–122 px;
- pill height approximately 82–94 px;
- plus target >=88 px and visually circular;
- large white outlined value text;
- consistent geometry between SB and Hearts.

Do not let icon/plus overlap adjacent HUD widgets.

## E. Gift Meter rebuild

Current semantics remain:
- ratio N/1000 only;
- no NEXT GIFT copy;
- no Event Points;
- no event timer.

Restyle using the master Gift Bar visual grammar.

Structure:
- left foreground HOME-051 emblem;
- central rounded navy outer chassis;
- inset gold/yellow fill/progress bar;
- live N/1000 centered inside the progress area;
- right foreground HOME-054 reward crate;
- claimable badge may overlap crate;
- emblem and crate above chassis in z-order.

At 1080x2160:
- emblem and crate should be visibly larger than current V04;
- outer chassis should read as a substantial assembled widget, not a thin flat progress strip;
- ratio text large white with dark outline/shadow;
- gold fill should have strong contrast against navy chassis.

Do NOT create the reference's timer tab or fake 2d15h value.

## F. Win Streak reward track rebuild

Preserve:
- five gift milestones;
- values exactly 1, 5, 10, 25, 100;
- no '+' prefixes;
- no WIN labels;
- no per-step SB icons;
- reached/current/future states;
- HOME-087 retired.

Restyle toward the master reference:

- shallow dark-blue rounded rail/chassis;
- progress line integrated through rail;
- HOME-086 streak badge on the left in foreground, allowed to overhang rail;
- HOME-090..094 gift icons larger and allowed to overhang rail top;
- numeric labels centered below each gift;
- reached gifts bright/full;
- current gift gets strongest accent/glow;
- future gifts slightly dimmed but readable.

The result should read as reward objects placed on a track, not five tiny images trapped inside equal cells.

Keep total widget shallow enough for the bottom-stack reflow.

## G. AdBannerSlot height fix

Current reserved area is visually too tall.

Canonical target at 1080x2160:
- visible AdBannerSlot height approximately **144 px**.

Responsive implementation:
- derive from safe width if useful;
- clamp approximately **96–160 px**;
- do not let the slot use vertical EXPAND/FILL;
- explicit reservation only;
- no fake ad content;
- keep empty AdMount;
- keep collapse seam.

Add tests proving the slot does not absorb leftover vertical space.

## H. Bottom-anchored lower stack

Refactor the lower live UI so the vertical order is explicitly bottom anchored:

`PLAY -> WinStreakRewardTrack -> BottomNav -> AdBannerSlot -> screen bottom`

AdBannerSlot is the bottom-most fixed reservation.

When the ad slot gets shorter:
- BottomNav must move downward;
- Win Streak track must move downward by the same effective released distance;
- Play must move downward with the same stack;
- HOME-120 must NOT move;
- Scrubby feet anchor must NOT move.

A dedicated `BottomActionStack` or equivalent container is preferred.

Do not distribute the released space into arbitrary gaps above or between elements.

Keep the coming-soon/status pill attached to Play so it does not become a new layout row.

The baked helper bot near the Play region should therefore appear closer to Play after this reflow. This is desired.

## I. Preserve modal behavior

Do not regress:
- Daily modal hides Home action layer + HUD plus buttons;
- Settings modal hides Home action layer + HUD plus buttons;
- close/back restores exact state;
- no visible/clickable Home actions behind modal.

If BottomActionStack is introduced, it must be included in the same modal hiding architecture.

## J. Required focused tests

Update/add focused coverage for:

1. HOME-120 SHA/path unchanged.
2. World transform unchanged from V04 at 1080x2160.
3. World transform preserved within tolerance at full viewport matrix.
4. Background itself does not shift when AdBannerSlot height changes.
5. Scrubby center X remains 540.
6. Scrubby feet remain y=1297.
7. Scrubby visible scale is ~15% larger than V04.
8. Scrubby still clears sign and helper bots.
9. Four panels only.
10. panel alpha is in clear translucent range, not nearly invisible.
11. panel outline visible.
12. SHOP/COLLECTION icon size preserved/enlarged as V04 contract.
13. TASKS/DAILY exact V04 size.
14. SB icon foreground-overhang geometry.
15. Heart icon foreground-overhang geometry.
16. both plus buttons circular/visible >=88.
17. plus signals do not mutate economy.
18. Gift Meter ratio only.
19. Gift Meter emblem/crate foreground z-order.
20. Gift Meter gold fill/chassis structure.
21. Win Streak rail shallow.
22. Win Streak gifts overhang rail.
23. reward labels exactly 1/5/10/25/100.
24. no '+' / WIN / repeated SB icons.
25. AdBannerSlot ~144 px at canonical viewport.
26. AdBannerSlot does not vertically expand.
27. stack order = Play -> Track -> Nav -> Ad.
28. shrinking ad slot lowers Play/Track/Nav while world transform stays fixed.
29. Daily modal still hides new stack.
30. Settings modal still hides new stack.
31. required touch targets remain >=88 px.
32. all old approved PNGs and HOME-120 bytes unchanged.

Required runs:
- `tests/m42_assets.gd`
- `tests/m42_home.gd`
- `tests/m42_home_composition.gd`
- `tests/m42_home_v04.gd` updated for preserved invariants
- new V05 focused suite if cleaner
- `tests/m42_navigation.gd`
- `tests/m42_opening.gd`
- root `tests/run_tests.gd`
- `git diff --check`

All must exit 0 with zero SCRIPT ERROR.

## K. Runtime visual evidence

Capture production Home at:
- 1080x2160
- 1290x2796
- 1080x1920
- 1536x2048

Also:
- Daily modal
- Settings modal
- Ad slot visible
- Ad slot collapsed

Store under:
`coordination/sessions/M42-C001/runtime_evidence/home_v05/`

If vision is available, explicitly inspect:
- world background did not move;
- Scrubby is visibly larger but feet unchanged;
- four panels are clearly visible yet translucent;
- SB/Heart widgets resemble assembled icon+pilled-value+plus controls;
- Gift Meter resembles a game HUD meter rather than flat bar;
- Win Streak resembles reward rail;
- ad area is substantially shorter;
- Play/Track/Nav have shifted downward together.

## L. Asset integrity

Before and after:
- verify all previously approved production PNG Git blobs unchanged;
- verify HOME-120 exact bytes unchanged;
- no new image generation is needed for this task.

## M. Log

Create:
`coordination/sessions/M42-C001/task_logs/SB-M42-HOME-POLISH-V05.md`

Include:
- baseline SHA;
- changed files;
- exact world-transform regression values;
- final Scrubby scale factor;
- panel alpha/border values;
- currency/heart HUD geometry;
- Gift Meter geometry;
- Win Streak geometry;
- ad-slot canonical height;
- Play/Track/Nav before/after Y positions at 1080x2160;
- all test results;
- asset integrity proof;
- final implementation SHA.

Do NOT claim owner visual acceptance.

Finish with:

`AWAITING_CHATGPT_AUDIT / M42 HOME POLISH V05`
