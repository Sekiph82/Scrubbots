# M42-C003 — CLAUDE LOG V01 — Home Scrubby Runtime Animation

Date: 2026-10-01
Task: `SB-M42-035`
Prompt: `coordination/sessions/M42-C003/CHATGPT_PROMPT_V01.md`
Criteria: `coordination/sessions/M42-C003/CHATGPT_AUDIT_CRITERIA_V01.md`
Status: `BLOCKED_ANIMATION_ASSET_PRODUCTION / SB-M42-035 REMAINS OPEN`

## Sync

- Repo `Sekiph82/Scrubbots`, branch `main`; fast-forwarded to `b6efa0c` (incoming: TASKS / coordination / M42-C003 prompt + criteria, MAINT-SUPPLY prompt).
- Pre-existing local owner work preserved and not committed (`project.godot` drift, untracked assets / `.import` files, `tests/_m55_diag_tmp.gd`).
- Root `TASKS.md` not edited.

## Asset gate finding

- No Wave / Bow / Turn frame set exists anywhere in the repo (approved or candidate). Scrubby assets present: HOME-026 `scrubby_home_pose.png` plus unrelated poses and the two forbidden V03 overlay layers (`scrubby_face_blink_layer.png`, `scrubby_brush_arm_layer.png`).
- This session has no owner-approved image pipeline that can author ~46 frame-coherent, pixel-registered gesture frames matching HOME-026 at production quality (identity, lighting, brush continuity, soles line, keep-out zones). The project's primary provider (ChatGPT image generation) is not reachable from here. I did not upload HOME-026 or any owner art to an external service: that needs owner permission, and single-image generators do not hold frame-to-frame registration anyway.
- Any frames produced here would be raw candidates needing owner approval (`assets/ui/generated/` → `assets/ui/final/` only after approval). They could not ship as final art in this cycle.

Per the prompt and criteria C, I stopped before the runtime. Nothing was faked: no rotation/warp of HOME-026, no overlay revival, no placeholder frames.

## What was produced

- `coordination/sessions/M42-C003/ASSET_PRODUCTION_SPEC_V01.md`, the exact frame specification and runtime plan:
  - frame lists and durations at 12 fps: Wave 14 / Bow 15 / Turn 17 authored in-betweens, with HOME-026 bookending each gesture at runtime;
  - canvas 1158x1358 RGBA, pivot / ground contact (592, 1318), soles ±1 texel, foot drift ±6, head-top ±4, bristles ≤ y 1334;
  - texture-space keep-out zones computed from the accepted M42-C002 geometry at all four viewports: K1 COLLECTION x0..69 y40..308, K2 DAILY x1115..1158 y40..308, K3 right bot x1059..1158 y829..1339 (0 texels), K4 left bot x0..125 y999..1358 (no growth beyond HOME-026's brush footprint x27..124 y1134..1288, ≤ 7944 texels); HUD / Gift / Play / track / nav map outside the canvas, so "stay inside canvas" protects them;
  - continuity / forbidden-technique rules, acceptance checks and the generated → final promotion path;
  - runtime plan for a single `HomeScrubbyHero` component: geometry from HomeScreen, preloaded frames, procedural idle about the soles pivot, 6–12 s scheduler (40/35/25, no repeat, no stacking, RNG/clock seams), canonical `AppState.effects` live Reduced Effects, visibility / modal / focus / pause inertness, tests, evidence tool;
  - an owner-approvable alternative: an artist-painted layered rig.

## Code / tests

None changed. Runtime not implemented (`RUNTIME_ARCHITECTURE_NOT_SHIPPING`). Shipping Home is identical to the accepted M42-C002 state: `SCRUBBY_SCALE = 1.612`, static HOME-026, and the 1536x2048 mirrored world edges untouched. With no code change, no regression suites were rerun.

## Unblock

The owner or ChatGPT provides frame sets meeting the spec (or approves the layered-rig route). Then M42-C003 can be re-issued and implemented against the plan in §6 of the spec.

## Handoff

`BLOCKED_ANIMATION_ASSET_PRODUCTION / SB-M42-035 REMAINS OPEN`
