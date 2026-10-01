# M42-C003 — HOME SCRUBBY RUNTIME ANIMATION — IMPLEMENTATION PROMPT V01

Date: 2026-10-01
Repository: `Sekiph82/Scrubbots`
Branch: `main`
Task: `SB-M42-035`
Status: READY FOR CLAUDE / ASSET QUALITY GATED

Owner authority:
`coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V01.md`

Scale/placement prerequisite:
`SB-M42-034` is OWNER PASS / CLOSED at canonical `SCRUBBY_SCALE = 1.612`.

Do not edit root `TASKS.md`.

## Mission

Create the dedicated presentation-only Home Scrubby animation system against the accepted 1.612 hero presentation.

Required behavior:

- calm idle micro-motion;
- Wave gesture;
- Bow gesture;
- Turn/Look gesture;
- low-frequency 6–12 s gesture scheduling;
- no immediate repeat;
- stable feet/platform registration;
- responsive-safe presentation;
- modal/route/focus lifecycle safety;
- canonical Reduced Effects integration;
- static HOME-026 fallback;
- no gameplay/economy/progression authority.

## Important existing visual behavior

The 1536×2048 Home evidence uses the existing wide-screen mirrored continuation:

- `WorldEdgeLeft` / `WorldEdgeRight`;
- same world texture;
- `flip_h = true`.

Owner noticed and explicitly accepted this current behavior.

**Do not change, remove, redesign or reinterpret the wide-screen mirror continuation in this task.**

It is outside SB-M42-035.

## Locked hero geometry

Preserve:

`SCRUBBY_SCALE = 1.612`

and the owner-approved M42-C002 placement contract.

The canonical idle/front pose remains:

`assets/ui/final/characters/scrubby/scrubby_home_pose.png`

HOME-026 must remain the fail-safe static fallback.

Every animation state must return exactly to the same canonical:
- center X;
- feet/platform contact;
- base visible scale.

No animation may silently resize the accepted hero.

## Component architecture

Create one dedicated presentation component, preferably:

`scripts/ui/home/home_scrubby_hero.gd`

or equivalent.

It should own:
- visual animation state;
- frame/texture swapping;
- idle transform animation;
- gesture scheduler;
- gesture cooldown/no-repeat rule;
- modal/visibility/focus pause;
- Reduced Effects response;
- deterministic test seams.

HomeScreen should provide layout geometry and bind the component.

Do not create a second navigation or state authority.

## Idle

Use lightweight Godot-native presentation animation.

Allowed:
- subtle body bob;
- tiny tilt;
- gentle squash/stretch if visually clean.

Requirements:
- restrained;
- feet remain visually registered to platform;
- no slow drift;
- no accumulated transform error;
- exact return to canonical base transform.

## Gesture frame assets — BLOCKING QUALITY RULE

Wave, Bow and Turn/Look require real pose/frame sequences or an approved sprite atlas.

Current repo has **no approved wave/bow/turn frame set**.

Do NOT fake these gestures by:
- rotating the whole static image like a cardboard cutout;
- reviving old `scrubby_face_blink_layer`;
- reviving old `scrubby_brush_arm_layer`;
- crude runtime slicing/warping that visibly breaks the character;
- shipping placeholder frames as final art.

If the execution environment has an approved image-generation / image-editing capability, new gesture frame sets may be authored using HOME-026 as the identity/lighting/scale reference.

If the execution environment cannot create production-quality gesture frames, **STOP before pretending SB-M42-035 is complete** and hand back:

`BLOCKED_ANIMATION_ASSET_PRODUCTION / RUNTIME_ARCHITECTURE_NOT_SHIPPING`

with an exact asset-production specification.

Do not substitute fake art merely to make tests pass.

## Gesture contracts

### Wave
- 1.0–1.5 s;
- single friendly gesture;
- no loop;
- return to exact idle.

### Bow
- 1.0–1.6 s;
- believable bow;
- feet remain planted;
- return to exact idle.

### Turn / Look
- 1.2–1.8 s;
- real pose/frame progression;
- not whole-image rotation;
- no lateral displacement off the hero platform;
- return to exact idle.

Suggested 10–12 fps unless evidence supports another rate.

## Frame registration — BLOCKING

All gesture frames must have consistent:

- transparent canvas;
- scale relative to accepted 1.612 hero;
- canonical feet/ground registration;
- pivot;
- alpha bounds;
- lighting;
- brush/hand continuity.

Recommended asset path:

`assets/ui/final/characters/scrubby/home_animation/`

with:
- `wave/`;
- `bow/`;
- `turn/`.

Do not replace HOME-026.

## Scheduler

Default target:
- idle interval randomly/deterministically sampled in 6–12 s;
- Wave ~40%;
- Turn/Look ~35%;
- Bow ~25%;
- no immediate repeat;
- never stack gestures;
- gesture returns to idle before next timer begins.

Expose deterministic RNG/clock seams for tests.

A Home-entry wave is optional only if protected by cooldown so repeated navigation cannot spam it.

## Canonical Reduced Effects

Use:

`AppState.effects : EffectsSettingsService`

and its live:
`changed(reduced: bool)`

signal.

When Reduced Effects is ON:
- disable Wave/Bow/Turn;
- disable large idle bob/tilt/squash;
- static HOME-026 is acceptable;
- optional minimal blink only if it uses approved frame art.

The setting must apply live without rebuilding Home.

No second Reduced Effects state.

## Lifecycle / modal behavior

Decorative animation must be inert when:
- Home is not visible/current route;
- app is paused/backgrounded;
- app loses focus;
- full-screen transition is underway.

When a modal/settings overlay covers Home:
- do not start a new large gesture;
- current gesture may finish safely or return to idle without snap;
- resume scheduling cleanly after modal closes.

Use existing Home `set_modal_active` / visibility / app lifecycle seams where possible.

Do not delay Play or navigation.

## Presentation-only truth

The component must never mutate:
- AppState economy;
- progression;
- Hearts;
- rewards;
- level state;
- navigation route;
- Scrubby equipment/selection truth.

No durable save state for animation phase/timer/RNG.

## Performance

Require:
- all frame textures cached/preloaded;
- no per-frame asset loading;
- no one-node-per-frame creation;
- no timer/signal accumulation across Home enter/leave;
- no tween accumulation;
- stable memory/object count;
- animation component inactive outside Home.

## Responsive invariants

Validate:
- 1080×2160;
- 1080×1920;
- 1290×2796;
- 1536×2048.

Across all gesture frames/states:
- feet remain correctly registered;
- no functional UI opaque collision;
- no clipping through Play/HUD/shortcut panels;
- no scale/anchor jitter;
- no unexpected interaction with the accepted left-helper brush relationship.

Do not change the accepted 1536×2048 mirrored side continuation.

## Required tests

Create focused M42-C003 tests covering:

1. component/static fallback;
2. exact 1.612 base geometry;
3. idle transform returns exactly to base;
4. gesture durations;
5. no immediate repeat;
6. never stacked gestures;
7. gesture → idle exact restoration;
8. frame feet registration;
9. all four responsive viewports;
10. live Reduced Effects ON/OFF;
11. modal suppression/resume;
12. route visibility suppression/resume;
13. app focus/pause suppression/resume;
14. repeated Home enter/leave with no timer/signal/tween accumulation;
15. presentation-only AppState/economy/progression snapshot identity;
16. Home buttons remain immediately usable.

## Required visual evidence

If production gesture assets are created, capture:

- idle runtime sequence/contact sheet or short capture;
- Wave capture;
- Bow capture;
- Turn/Look capture;
- Reduced Effects static demonstration;
- four responsive Home screenshots;
- repeated enter/leave stability report.

Store under:

`coordination/sessions/M42-C003/evidence/`

Owner visual acceptance is mandatory.

## Regression

Run:
- focused M42-C003;
- M42 Home/v04/v05/v06/v07/C002;
- M42 navigation/opening/assets;
- M41 Reduced Effects/settings;
- M40 save/bootstrap;
- relevant M43 modal/Home integration;
- root suite;
- `git diff --check`.

## Governance

Do not edit `TASKS.md`.

Do not mutate owner/local files.

No destructive git operations.

## Required handoff

If full production animation + assets are implemented:

Create:
- `coordination/sessions/M42-C003/CLAUDE_LOG_V01.md`
- `coordination/sessions/M42-C003/IMPLEMENTATION_MATRIX_V01.md`
- fresh evidence.

Return:
1. final SHA;
2. component architecture;
3. animation asset inventory;
4. scheduler details;
5. Reduced Effects/lifecycle behavior;
6. responsive results;
7. regression summary;
8. direct GitHub links to owner-review captures.

Finish:

`AWAITING_CHATGPT_AUDIT / M42-C003 HOME SCRUBBY RUNTIME ANIMATION V01`

If production-quality frame assets cannot be authored in the execution environment:

- do not claim task completion;
- do not ship fake gestures;
- provide exact frame/canvas/pivot/feet-registration asset specification and implementation plan;
- finish:

`BLOCKED_ANIMATION_ASSET_PRODUCTION / SB-M42-035 REMAINS OPEN`
