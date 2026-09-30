# M42-C002 — HOME SCRUBBY HERO SCALE + PLACEMENT LOCK — IMPLEMENTATION PROMPT V01

Date: 2026-09-30
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: `SB-M42-034`
Status: READY FOR CLAUDE

Owner authority:
`coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V01.md`

Current Home world authority:
`data/config/home_worlds_v1.json`

Do not edit root `TASKS.md`.

## Mission

Enlarge the current production Home Scrubby hero by exactly **+30%** from:

`SCRUBBY_SCALE = 1.24`

to the owner-locked canonical target:

`SCRUBBY_SCALE = 1.612`

This cycle is ONLY:

- hero scale;
- responsive placement;
- feet/platform anchoring;
- collision/readability validation;
- owner visual evidence.

Do NOT implement animation yet.

Do NOT create/finalize Wave/Bow/Turn-Look assets yet.

SB-M42-035 remains blocked until this cycle receives owner visual PASS.

## Current production facts to preserve

Current code:

`scripts/ui/home/home_screen.gd`

contains:

`const SCRUBBY_SCALE := 1.24`

Current placement is derived from:

- owner-approved HOME-026 `scrubby_home_pose.png`;
- visible bbox `Rect2(27, 7, 1130, 1327)`;
- visible soles line `SCRUBBY_FEET_Y = 1318.0`;
- current world's `scrubby_safe_box`;
- current world's `scrubby_feet_anchor`.

Current world:

- canvas: **940×1672**;
- background slug: `home_background_whispering_park`;
- feet anchor: **(470, 1240)**;
- safe box: **(305,620,330,620)**;
- platform rect: **(60,1180,820,220)**;
- baked sign rect: **(230,405,480,140)**.

Do not revert to stale HOME-120/1080×2160 background geometry.

The current Home background replacement from M28 is authority.

## Owner scale lock — BLOCKING

Set:

`SCRUBBY_SCALE := 1.612`

Exactly.

No:
- 1.60;
- 1.61;
- 1.615;
- "close enough";
- responsive scale-down below 1.612.

The hero remains 1.612 relative to the existing V04 safe-box fit.

If a viewport collision appears, solve it through placement/layout tuning, not by shrinking the hero.

## Soles / platform anchor — BLOCKING

The hero must continue scaling about the visible soles.

Required invariant:

- visible soles remain registered to the canonical Home platform contact point;
- center X remains registered to the canonical hero anchor;
- changing from 1.24 to 1.612 must not make Scrubby float or sink into the platform.

The accepted hero image itself must not be cropped/scaled non-uniformly.

Use the current exact HOME-026 texture:

`assets/ui/final/characters/scrubby/scrubby_home_pose.png`

Do not regenerate or replace it.

## Responsive placement

Validate at minimum:

- 1080×2160;
- 1080×1920;
- 1290×2796;
- 1536×2048.

At all four:

- hero remains fully readable;
- soles remain on platform;
- hero does not collide with the baked sign;
- hero does not obscure Play;
- hero does not obstruct TopCurrencyHUD;
- hero does not obstruct Gift Meter;
- hero does not overlap BottomNav;
- hero does not make SHOP/COLLECTION/TASKS/DAILY unusable;
- helper-bot avoidance remains coherent;
- no clipping outside the visible Home world in an obviously broken way.

A controlled visual overlap with decorative world art is acceptable if it matches the existing Home composition, but functional UI overlap is not.

## Placement policy

Preserve the current canonical feet anchor whenever possible.

If 1.612 creates an actual collision in one or more supported viewports:

1. retain scale 1.612;
2. preserve visible soles/platform contact;
3. use minimal horizontal/vertical hero-anchor/layout tuning;
4. keep the same placement rule responsive and deterministic;
5. do not introduce per-viewport magic-number lookup tables unless no geometry-derived solution exists.

Any anchor/layout change must be documented and measured.

## Separate runtime hero layer

Scrubby remains:

- separate runtime `Art_scrubby`;
- above the Home background;
- presentation-only;
- non-input-blocking.

Do not bake Scrubby into the Home background.

Do not revive:
- `scrubby_face_blink_layer`;
- `scrubby_brush_arm_layer`;

as a shortcut.

No animation component in this task.

## HeroFocusShade

Current HeroFocusShade may require minor size/position adjustment because the hero becomes materially larger.

Allowed:
- geometry-only shade adjustment needed to remain centered behind the enlarged torso.

Not allowed:
- new raster shade asset;
- bright/glowing redesign;
- covering sign/helper bots/UI;
- changing the Home visual style.

If no adjustment is needed, leave it unchanged.

## UI/input truth — LOCKED

Do not change:

- Play behavior;
- Home navigation;
- currency/Heart/Gift truth;
- shortcuts;
- modal behavior;
- BottomNav behavior;
- ad-slot behavior;
- economy;
- progression;
- gameplay launch;
- Home world selection.

The task is presentation-only.

## Required focused tests

Create a dedicated M42-C002 focused suite.

### 1. Exact scale

Assert production constant:

`SCRUBBY_SCALE == 1.612`

and verify:

`1.612 / 1.24 == 1.30`

within floating tolerance.

### 2. 32/geometry placement math

For each required viewport:

- compute world transform;
- compute hero canonical rect;
- compute screen-space visible rect;
- compute soles screen-space position;
- compute canonical platform contact screen-space position.

Require soles/contact error <= **1 px**.

### 3. UI collision matrix

For every required viewport prove hero visible rect does not intersect functional UI rects that must remain clear:

- TopCurrencyHUD;
- GiftMeter;
- Play;
- BottomNav;
- active shortcut hit rects.

If decorative panel artwork overlaps by design while hit areas remain clear, report exact geometry and do not hide it.

### 4. Sign/helper checks

Prove:
- no baked-sign collision;
- helper-bot avoidance remains valid;
- no new unusable shortcut state.

### 5. Responsive relayout

Resize a live Home instance through all four viewport sizes.

Require:
- same Scrubby node instance;
- texture object unchanged;
- no duplicate hero nodes;
- no duplicate shade nodes;
- no accumulating signal/timer/tween state;
- deterministic return to prior geometry when returning to 1080×2160.

### 6. UI truth

Run existing Home interaction/navigation suites and prove scale/placement changes do not block buttons or mutate state.

## Fresh visual evidence — REQUIRED

Create under:

`coordination/sessions/M42-C002/evidence/`

At minimum:

- `home_scrubby_1612_1080x2160.png`
- `home_scrubby_1612_1080x1920.png`
- `home_scrubby_1612_1290x2796.png`
- `home_scrubby_1612_1536x2048.png`

Also create:

- one 1080×2160 **before 1.24 vs after 1.612** comparison montage;
- a measurement report with:
  - viewport;
  - world scale/offset;
  - old 1.24 visible rect;
  - new 1.612 visible rect;
  - feet screen position;
  - platform contact position;
  - sign/UI collision results;
  - helper-bot collision results.

Use the latest current Home background.

Do not use stale historical V04/V05/V06 background screenshots as the final evidence source.

## Owner visual gate

Technical PASS will still require OWNER review.

Owner questions will be:

1. Is the +30% enlargement visually correct?
2. Does Scrubby still feel correctly planted on the platform?
3. Is the composition good at all four required viewports?
4. Is any UI or helper-bot relationship visually awkward?

Only owner PASS closes SB-M42-034.

## Regression gate

Run at minimum:

- new M42-C002 focused suite;
- existing M42 Home;
- M42 navigation;
- M42 opening;
- M42 responsive/Home world tests;
- M40 save/bootstrap;
- M43 relevant Home/modal integration;
- root suite;
- `git diff --check`.

No gameplay/level/routing regression work is expected.

## Governance

Do not edit root `TASKS.md`.

Preserve owner/local files.

No destructive reset/clean/force push.

## Required outputs

Create:

- `coordination/sessions/M42-C002/CLAUDE_LOG_V01.md`
- `coordination/sessions/M42-C002/IMPLEMENTATION_MATRIX_V01.md`
- `coordination/sessions/M42-C002/evidence/`

Commit/push to `main`.

Return:
1. final SHA;
2. exact scale change;
3. any placement/shade changes;
4. four viewport geometry results;
5. collision matrix;
6. regression summary;
7. direct GitHub links to all owner-review screenshots.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M42-C002 HOME SCRUBBY SCALE LOCK V01`
