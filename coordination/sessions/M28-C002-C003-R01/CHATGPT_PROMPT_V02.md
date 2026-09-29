# M28-C002-C003-R01 — GAMEPLAY + HOME FINAL REMEDIATION MASTER PROMPT V02

Status: READY FOR CLAUDE
Date: 2026-09-29
Repository: `Sekiph82/Scrubbots`
Branch: `main`

This V02 supersedes `CHATGPT_PROMPT_V01.md`.

Do not edit root `TASKS.md`.

## Mission

Resolve the owner's final five playtest/visual findings in one remediation cycle, without redesigning unrelated systems.

### 1. Timed 2x must auto-start gameplay at 2x while active

Canonical owner behavior:

- if a timed 2x entitlement (15m / 30m / 60m) still has remaining wall-clock time, every new gameplay/level launch must START at live 2x automatically;
- Level 2 timed purchase -> Level 3/4/... must start 2x while remaining time > 0;
- app relaunch -> first gameplay must start 2x if timed entitlement is still active;
- Home / Results / pause / background / closed-app time continues counting against the existing absolute wall-clock expiry;
- player may manually toggle to 1x during a level at zero extra cost;
- next newly launched level returns to default live 2x while timed entitlement remains active;
- when timed entitlement is expired, normal new gameplay starts 1x;
- current-level 200 SB entitlement remains scoped only to its purchased level;
- preserve M55 anti-rollback/high-water behavior;
- preserve free M23 supply-exhausted automatic 2x independently.

Fix the real production lifecycle, not just the HUD. Timed remaining > 0 + new gameplay host + runtime 1x is forbidden.

### 2. Remove WAITING / ACTIVE text from the five-slot row

On the five permanent gameplay slots:

- remove visible `WAITING` / `ACTIVE` text labels;
- keep all authoritative slot state and color/status behavior intact;
- do not remove counts or other owner-approved necessary information unless required by the implementation;
- the slot should communicate state visually via color/presentation, not those words;
- apply to the temporary sixth slot too if the same label component is reused.

No gameplay logic change.

### 3. Railway-first Scrubbot routing

Current visual problem: Scrubbots leave the bottom connector/railway too early and travel long straight/diagonal paths through the pixel-art board.

Required behavior:

- Scrubbot exits its slot through the existing connector and joins the railway;
- it follows the railway around the board perimeter toward the target;
- it leaves the railway only from the valid rail point/segment closest to the target pixel;
- only the final leg from rail exit to target may travel directly through the board;
- choose the shortest valid railway-first route, not a straight shortcut from the slot;
- routing must remain deterministic;
- preserve authoritative target choice, claim/reservation identity, clear order, FIFO/conservation, solver truth and completion truth;
- this is travel-path/presentation routing only unless a narrowly required route abstraction must change;
- no teleporting, no corner cutting outside the railway corridor, no long board-crossing diagonal from the bottom rail.

Add tests covering targets near left/right/top/bottom regions and at least one corner-adjacent target.

### 4. Dynamic visible pixel grid + subtle pixel-tile/bevel treatment

All level pixel art must make individual logical pixels visually countable.

Implement a dynamic presentation layer based on the actual board logical width/height, not a fixed PNG mask.

Preferred direction:

- renderer/shader/overlay derived from the real grid dimensions;
- no one-Node-per-pixel implementation;
- thin dark separation/gutter between logical pixels;
- very subtle tile/bevel depth so each logical pixel reads as an individual pixel tile;
- mild rounded/beveled appearance is acceptable, but do not make cells look like large toy buttons;
- preserve palette colors and logical cell geometry;
- cleared/empty cells must not retain a ghost grid/tile overlay;
- adapt line/bevel strength by board resolution so 20–59 px levels remain readable without the grid overwhelming dense art;
- board hit-testing, target coordinates, clear truth and solver logic must remain unchanged.

Validate at representative small/medium/large logical grids, including dense levels.

### 5. Replace Home background with the owner-selected asset

Use exactly this owner-selected local file as the Home background source:

`C:\Users\sekip\Desktop\ScrubBots\assets\ui\final\home\background\home_background.png`

Canonical repo-relative path:

`assets/ui/final/home/background/home_background.png`

Requirements:

- use that existing file; do NOT regenerate, redraw, upscale, recolor or substitute it;
- wire Home to this asset as the canonical background;
- keep existing live Home UI overlays, buttons, counters and navigation functional;
- preserve the current Home layout unless only minimal fitting/anchoring adjustments are required for the new background;
- do not bake live UI into the background;
- verify the asset is actually the one rendered at runtime;
- ensure no stale older Home background remains on top or underneath creating duplicate imagery.

## Validation-first

Before editing, inspect current implementation and identify the smallest production changes.

Do not alter:
- economy prices/durations;
- Heart/booster rules;
- M23 auto-2x semantics;
- accepted popup family;
- accepted Gameplay V02 composition outside these five findings;
- target/solver/claim/reservation truth;
- unrelated Home feature implementation.

## Required tests

Add focused coverage proving at minimum:

1. timed 2x purchase -> next level starts live 2x;
2. app relaunch -> gameplay starts live 2x while entitlement remains active;
3. manual 1x within a level costs nothing; next new level still starts 2x while timed remains;
4. expired timed entitlement -> new gameplay starts 1x;
5. current-level 2x does not leak to next level;
6. free M23 auto-2x remains independent;
7. WAITING/ACTIVE strings are absent from five/six-slot runtime presentation;
8. railway-first route hugs the perimeter rail and exits at the nearest valid rail point for representative targets;
9. route change does not alter target/claim/clear identity;
10. grid aligns exactly with logical cells across representative dimensions and clears with cells;
11. grid/bevel is presentation-only and does not alter hit/target coordinates;
12. Home runtime uses `assets/ui/final/home/background/home_background.png`.

## Evidence

Create fresh evidence under:

`coordination/sessions/M28-C002-C003-R01/evidence/`

At minimum:
- timed 2x on new level;
- five-slot row without WAITING/ACTIVE;
- railway-first movement frame sequence or short video;
- grid/bevel screenshots at small/medium/large logical grids;
- Home with the new background asset.

If practical, reuse Godot Movie Maker for short runtime evidence without adding dependencies.

## Regression gate

Run:
- new focused remediation suite(s);
- M28 final gate;
- M29 input/speed;
- M30 retry/completion;
- M39 economy;
- M40 save;
- M43-C003;
- M52;
- M55;
- routing/clearing/solver regressions affected by the railway path;
- Home/M42 regressions affected by the background;
- root suite;
- `git diff --check`.

Report pre-existing unrelated flakes separately. Do not hide them.

## Required outputs

Create:
- `coordination/sessions/M28-C002-C003-R01/CLAUDE_LOG_V02.md`
- `coordination/sessions/M28-C002-C003-R01/REMEDIATION_MATRIX_V02.md`
- fresh evidence directory.

Commit and push all authorized work to `main`.

Return:
1. final SHA;
2. files changed;
3. focused + regression results;
4. evidence links;
5. exact owner replay items still required.

Finish exactly:

`AWAITING_CHATGPT_AUDIT / M28-C002-C003-R01 FIVE-FINDING REMEDIATION V02`
