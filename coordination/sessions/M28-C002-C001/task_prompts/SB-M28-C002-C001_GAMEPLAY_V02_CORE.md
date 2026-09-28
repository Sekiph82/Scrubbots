# SB-M28-C002-C001 — GAMEPLAY SCREEN V02 CORE PRODUCTION CONVERGENCE

Status: READY FOR CLAUDE
Date: 2026-09-28
Repository: `Sekiph82/Scrubbots`
Branch: `main`

## Purpose

Start the owner-requested **actual gameplay screen** now.

This cycle converts the current historical M28 screen into the owner-approved Gameplay Composition V02 production layout while preserving every authoritative gameplay system already working underneath it.

This is not a mockup exercise. Work on the real production gameplay screen used by `ProductionGameplayHost`.

## Active tracked scope

Primary M28-C002 rows for this core cycle:

- SB-M28-C002-001 production Gameplay V02 native scene/layout
- 002 real BoardRenderer dominant region / rectangular aspect
- 003 full four-sided Railroad V1 production skin
- 004 five permanent visible slot-to-bottom-rail connectors
- 005 five baseline slots + temporary sixth slot
- 006 5x3 Batch Supply view when configured for five columns, preserving 3/4/5-column truth
- 007 only front batches interactive; preview rows non-interactive/distinct
- 008 Pause + 2x side by side top-right with live states
- 009 selected robot/profile presentation, no Heart HUD / gameplay Settings
- 010 four canonical booster controls
- 011 live booster quantity/price/locked/unavailable/selected overlays
- 016 approved background/Scrubby/decorative hierarchy
- 017 responsive viewport matrix
- 018 mouse/touch mapping, rapid taps, popup-input-isolation readiness, sixth-slot readability

Do not falsely close these dependency rows in this cycle unless their owning systems truly exist:
- 012 canonical Booster Acquire popup routing
- 013 canonical final 2x Acquire popup routing
- 014 canonical Pause popup
- 015 final modal-stack input suppression
- 019 full final owner-review pack including those popups
- 020 final independent audit + owner playtest acceptance

Existing functional speed-acquisition behavior may remain operational; do not redesign it into the future M43-C003 canonical popup here.

## Read first

1. `CLAUDE.md`
2. root `TASKS.md` READ ONLY
3. `coordination/OWNER_GAMEPLAY_SCREEN_COMPOSITION_V02.md`
4. `coordination/OWNER_GAMEPLAY_MASTER_VISUAL_V01.md`
5. `assets/ui/final/gameplay/master/scrubbots_gameplay_master.png` — reference only, never ship as a flattened interactive screen
6. `docs/MASTER_UI_SYSTEM.md`
7. Railroad authorities:
   - `coordination/OWNER_SCRUBBOT_RAILROAD_DECISION_V01.md`
   - `coordination/OWNER_SCRUBBOT_RAILROAD_INTERIOR_PATH_DECISION_V01.md`
8. speed/economy authorities:
   - `coordination/OWNER_GAMEPLAY_SPEED_RULE_V01.md`
   - `coordination/OWNER_ECONOMY_REWARDS_V01.md`
   - `coordination/OWNER_TIMED_2X_CLOCK_ROLLBACK_V01.md`
9. current production:
   - `scripts/ui/gameplay_screen.gd`
   - `scripts/gameplay/runtime/production_gameplay_host.gd`
   - `scripts/ui/scrub_rail_view.gd`
   - `scripts/gameplay/routing/scrub_rail_geometry.gd`
   - FiveSlotStrip / BatchSupplyPanel / booster/economy runtime surfaces
10. approved assets under `assets/ui/final/gameplay/**`
11. relevant M28/M29/M39/M52/M55 tests and evidence.

Do NOT edit root `TASKS.md`.

## Current-screen problem to fix

The historical gameplay screen still contains pre-V02 composition elements such as:
- a bottom Pause / ad placeholder / speed row;
- top region as an empty spacer;
- native decoration placeholders;
- historical placement that does not match the approved Gameplay Master V01.

V02 supersedes those placement rules.

The new shipping composition must follow the owner master, not preserve obsolete layout merely because old tests assert it.

Migrate tests deliberately while preserving gameplay-safety intent.

## Canonical V02 structure

### Top
- compact player/profile chip at top-left;
- **Pause + 2x side by side at top-right**;
- no Settings;
- no Heart HUD;
- no Goal/Moves/Time;
- no Level/lock rail.

### Board
- BoardRenderer remains the real board;
- largest practical gameplay region;
- preserve rectangular aspect;
- full four-sided Railroad V1 around board;
- exactly 2.0 logical-cell artwork clearance;
- 1.0 logical-cell rail width;
- rail centreline 2.5 cells outside board boundary;
- railroad visually subordinate to pixel art.

### Slots / rail connectors
- five baseline execution slots immediately below board;
- all five slot-to-bottom-rail connectors **always visible**, even empty;
- connector origin and bottom-rail termination must come from the same authoritative geometry/spawn mapping used by real movement;
- connector is not decorative fake geometry;
- when +1 Slot creates the temporary sixth slot, the sixth connector appears only for that attempt/capacity state and remains readable.

### Batch Supply
- below slots;
- for five-column levels show **5 columns x 3 visible rows**;
- continue supporting canonical 3/4/5 column counts;
- deeper queue remains hidden runtime truth;
- only supply-front batches interactive;
- preview rows visibly distinct and input-disabled;
- color/count are live Godot UI.

### Lower support
- Scrubby/tutorial support low-left;
- speech bubble area above;
- cleaning props lower priority;
- exactly four boosters in one compact horizontal row:
  +1 Slot / Random / Selector / Tornado;
- no ad banner/placeholder in this owner gameplay composition.

## Use approved assets, do not regenerate

Inspect and reuse the committed family under `assets/ui/final/gameplay/**`, including where appropriate:

- `environment/gameplay_environment.png`
- profile panel / Scrubby portrait / Bot Parts bar assets
- `controls/button_pause.png`
- `controls/button_speed_2x.png`
- `controls/button_speed_2x_active.png`
- `controls/button_speed_2x_countdown_frame.png`
- Railroad assets
- slot assets
- Batch panel/tile assets
- tutorial speech bubble
- approved decorative cleaning props/equipment
- existing canonical booster art elsewhere in `assets/ui/final`

Do not overwrite/regenerate any approved asset.

Do not promote the flattened gameplay master into an interactive background screenshot. It is a compositional reference only.

## Top-left profile

Use current authoritative data only.

At minimum:
- Scrubby portrait until equipped-robot authority exists;
- live current campaign level;
- live Bot Parts/progress only if an existing canonical authority already provides the exact value.

Do not invent XP/player-level systems.

No Heart icon/count on gameplay.

## Pause / 2x top-right

Move the existing production control seams to the V02 top-right composition.

### Pause
For this cycle:
- button is correctly placed and usable;
- preserve existing pause behavior;
- do not invent the final M43-C002 Pause popup yet.

### 2x
Preserve authoritative economy/runtime behavior.

Visual states must support:
- inactive/unentitled: `2x`;
- active current-level entitlement: selected 2x;
- active timed entitlement: selected state with live remaining wall-clock label, e.g. `14:38`;
- free supply-exhausted automatic 2x remains distinct from paid ownership and never opens purchase UI.

Existing acquisition behavior must keep functioning, but final M43-C003 popup visual is deferred.

Do not bypass `SpeedEntitlementService`.
Do not break the persisted anti-rollback high-water rule.

Update timed display from wall-clock entitlement truth without tying it to gameplay `delta` or `time_scale`.

## Booster row

Bind exactly four canonical boosters to the existing authoritative services.

Display live:
- icon;
- owned charge count;
- canonical price when purchasable with zero charge;
- selected/available/unavailable/locked state.

Do not add a fifth booster.

Do not silently spend from UI.

If canonical final BoosterAcquirePopup does not yet exist, preserve the existing action behavior or expose the correct request seam, but do not fake-complete SB-M28-C002-012.

## Production input

This is a real gameplay screen.

Preserve:
- BoardRenderer coordinate mapping;
- supply-front click activation;
- slot non-selection law;
- target/routing/reservation truth;
- rapid dispatch;
- Railroad motion;
- booster gameplay authority;
- completion/retry;
- current modal/acquisition input safety that already exists.

Presentation must not become gameplay authority.

## Responsive targets

Validate at minimum:
- 1080x2160
- 1170x2532
- 1290x2796
- 1080x2400
- 1440x3200
- short 1080x1920 / 16:9-class portrait
- representative tablet portrait

Use safe-area tests including notch/top inset and bottom gesture inset.

Rules:
- board/rail readability protected before decorative art;
- no essential control outside safe area;
- Pause/2x >= canonical touch minimum;
- supply fronts remain tappable;
- 5x3 supply remains readable;
- sixth slot does not collide with supply/connector geometry.

## Evidence

Create deterministic production-path screenshots for owner review for the core V02 state:

1. fresh Level 1 or Level 2 at 1080x2160;
2. active cleaning with several Scrubbots on connector/rail/interior path;
3. all five normal slots occupied/readable;
4. temporary sixth-slot state;
5. timed 2x state showing a real live countdown;
6. tall-phone view;
7. short-phone view.

Use real app/root production path and real level content.

Do not invent new owner click solutions. Use existing owner plan sequences for deterministic progression where needed.

It is acceptable that final Pause/BoosterAcquire popup screenshots remain deferred to the dependency cycle. State that explicitly.

## Tests

Add focused M28-C002-C001 tests for:
- no obsolete bottom ad placeholder;
- no gameplay Settings / Heart / Goal/Moves/Time;
- top-left profile + top-right Pause/2x;
- board dominance and rectangular aspect;
- four-sided rail geometry;
- five permanent connectors aligned with actual slot/rail mapping;
- sixth connector conditional on sixth slot;
- supply 3/4/5-column support and 3 visible rows for five-column case;
- preview rows non-interactive;
- front click mapping unchanged;
- exactly four booster controls;
- live booster data;
- timed 2x countdown state;
- safe areas;
- responsive matrix;
- no input-coordinate regression;
- no node/signal accumulation across retry/rebuild.

Run relevant:
- M22/M23/M24/M25/M26/M27;
- M28/M29 historical safety regressions (migrate obsolete placement assertions intentionally);
- M30;
- M39;
- M40;
- M42 navigation;
- M52 owner First 10/R01/R02;
- M55 core/long-run/2x anti-rollback;
- root suite;
- `git diff --check`.

Do not force obsolete bottom-row visual assertions to remain true; replace them with V02 owner authority while retaining safety/interaction assertions.

## Outputs

Create:
- `coordination/sessions/M28-C002-C001/GAMEPLAY_V02_CORE_MATRIX_V01.md`
- `coordination/sessions/M28-C002-C001/OWNER_GAMEPLAY_V02_REVIEW_V01.md`
- `coordination/sessions/M28-C002-C001/CLAUDE_LOG_V01.md`
- screenshot evidence under the same session.

The owner-review file must clearly separate:
- core V02 items ready for visual review;
- dependency-deferred final popup integrations (SB-M28-C002-012..015/019);
- any genuine visual-only choices, without inventing new design policy.

## Scope locks

Do not:
- implement M43-C002/C003 final popup families here;
- change level content/supply plans/difficulty;
- create a solver/new click solution;
- change Railroad routing truth;
- change economy prices/Heart/2x rules;
- regenerate approved assets;
- edit TASKS.md.

## Handoff

Commit and push.

Finish with:

`AWAITING_CHATGPT_AUDIT / M28-C002-C001 GAMEPLAY V02 CORE`
