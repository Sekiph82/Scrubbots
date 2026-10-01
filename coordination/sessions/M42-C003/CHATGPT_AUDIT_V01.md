# M42-C003 — CHATGPT INDEPENDENT AUDIT V01

Date: 2026-10-01
Auditor: ChatGPT
Repository: `Sekiph82/Scrubbots`
Audited commit: `2cfe0b18a9717469cbc9faa6395efc4fa3ac39b6`
Task: `SB-M42-035`
Prompt: `coordination/sessions/M42-C003/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M42-C003/CHATGPT_AUDIT_CRITERIA_V01.md`

## Verdict

**BLOCKED_ANIMATION_ASSET_PRODUCTION / CORRECT STOP / SB-M42-035 REMAINS OPEN**

Claude correctly stopped at the prompt's blocking art-quality gate.

This is not an implementation FAIL. The prompt explicitly forbids shipping fake Wave/Bow/Turn gestures when production-quality registered frame art is unavailable.

## A. M42-C002 prerequisite

**PASS / PRESERVED.**

No production code changed in the audited commit.

Shipping Home therefore remains on the owner-approved:

- `SCRUBBY_SCALE = 1.612`;
- accepted sole/platform placement;
- accepted 940×1672 Home world;
- static HOME-026 fallback;
- accepted wide/tablet mirrored side continuation.

## B. Gesture asset inventory

**BLOCKER CONFIRMED.**

Current repository Scrubby assets include:

- `scrubby_home_pose.png`;
- `scrubby_master.png`;
- `scrubby_gameplay.png`;
- `scrubby_portrait.png`;
- old `scrubby_face_blink_layer.png`;
- old `scrubby_brush_arm_layer.png`;
- unrelated popup/loading/splash/marketing poses.

There is no committed:

- `home_animation/wave`;
- `home_animation/bow`;
- `home_animation/turn`;

frame sequence or approved atlas.

Therefore criteria C cannot pass yet.

## C. Correct refusal to fake final art

**PASS.**

Claude did NOT:

- rotate HOME-026 as a fake Turn;
- warp/slice the static sprite;
- revive forbidden old overlay layers;
- create placeholder frames and claim them production-ready;
- start runtime code that would imply the gesture task was shippable.

This matches the prompt's required blocked disposition.

## D. Asset production specification

**PASS / SUFFICIENT TO UNBLOCK ART PRODUCTION.**

`ASSET_PRODUCTION_SPEC_V01.md` provides a concrete production contract:

- 46 authored in-between frames:
  - Wave 14;
  - Bow 15;
  - Turn/Look 17;
- HOME-026 bookends each runtime gesture;
- exact 1158×1358 RGBA canvas;
- canonical pivot/ground contact (592,1318);
- soles ±1 texel;
- foot drift ±6 texels;
- head-top and brush limits;
- exact keep-out zones derived from accepted M42-C002 geometry;
- identity/lighting/brush continuity rules;
- generated → owner review → final promotion path;
- per-frame validation expectations.

The spec is materially detailed enough for an image-production pass.

## E. Runtime plan

**PASS AS PLAN / NOT IMPLEMENTED.**

The proposed runtime architecture is consistent with the approved prompt:

- one `HomeScrubbyHero` presentation component;
- HomeScreen remains layout authority;
- frame swaps keep one canonical rect;
- cached/preloaded textures;
- restrained procedural idle;
- 6–12 second scheduler;
- 40/35/25 Wave/Turn/Bow weighting;
- no immediate repeat;
- no stacking;
- canonical `AppState.effects` Reduced Effects;
- modal/visibility/focus/pause lifecycle suppression;
- presentation-only state.

No runtime acceptance is granted because no runtime implementation exists yet.

## F. Regression disposition

**ACCEPTABLE FOR BLOCKED ART-ONLY COMMIT.**

The audited commit changes only:

- `ASSET_PRODUCTION_SPEC_V01.md`;
- `CLAUDE_LOG_V01.md`.

No production or test code changed.

Therefore not rerunning the Godot regression suite for this documentation-only blocked handoff is acceptable.

## G. Wide-screen mirror observation

Owner noticed the 1536×2048 mirrored side continuation during M42-C002 review and explicitly accepted the overall visual result.

This behavior is pre-existing:

- `WorldEdgeLeft`;
- `WorldEdgeRight`;
- same Home world texture;
- `flip_h = true`.

It is not an image-file mutation and is outside SB-M42-035.

Do not change it in the animation cycle.

## Unblock requirement

SB-M42-035 can resume only after one of the following owner-approved art routes is available:

### Route A — registered frame animation

Produce Wave/Bow/Turn candidate frames against HOME-026 using `ASSET_PRODUCTION_SPEC_V01.md`, review them visually, then promote accepted bytes to the final asset tree.

### Route B — artist-painted layered rig

Only if owner explicitly chooses the alternative and the rig art itself is approved. Runtime deformation of the single static HOME-026 image is still not authorized.

## Final

**BLOCKED_ANIMATION_ASSET_PRODUCTION / CORRECT STOP / SB-M42-035 REMAINS OPEN**
