# OWNER M42 HOME SCRUBBY ANIMATION V01

Date: 2026-09-29
Authority: OWNER
Status: PLANNED / OWNER-DESIGNED
Target task: SB-M42-034
Target cycle: M42-C002 — Home Scrubby Runtime Animation

## Goal

Make Scrubby feel alive on the Home screen without turning Home into a noisy animation showcase.

Scrubby remains the dominant visual focus and remains a separate runtime hero layer above the static Home world background.

This task must not bake Scrubby into the Home background.

## Existing architecture to preserve

Current Home already renders Scrubby separately as `Art_scrubby` inside the character layer.

Preserve:

- the latest accepted Home background/layout authority after the current M28-C002-C003-R01 V02 background replacement;
- current responsive Scrubby anchor / feet alignment / safe-area behavior;
- live Home UI overlays and navigation;
- current static `scrubby_home_pose.png` as the fail-safe fallback;
- Reduced Effects accessibility behavior.

Do not revive the old V03 disabled `scrubby_face_blink_layer` / `scrubby_brush_arm_layer` assets as the implementation shortcut. Build a clean dedicated hero-animation component.

## Animation design

### A. Idle

Most of the time Scrubby stays in a calm idle state.

Idle may use lightweight Godot-native transform animation:

- subtle vertical body bob;
- very small body tilt;
- gentle squash/stretch if it remains visually clean;
- occasional blink only if implemented as part of the new approved hero animation set.

Idle must never shift the feet off the canonical platform contact point.

### B. Wave

Short friendly wave gesture.

Target:
- approximately 1.0–1.5 s;
- one gesture, then return to idle;
- no repeated looping wave.

### C. Bow

Short polite bow/reverence animation.

Target:
- approximately 1.0–1.6 s;
- body bends/leans while maintaining believable foot contact;
- returns exactly to canonical idle pose/anchor.

### D. Turn / Look Around

Scrubby briefly turns or looks around in place.

This should be a real pose/frame sequence, not a flat 2D texture rotated like a cardboard cutout.

Target:
- approximately 1.2–1.8 s;
- small turn/look, then return to front idle;
- no displacement away from the Home hero platform.

## Scheduling / behavior

Recommended default behavior:

1. Home becomes active.
2. Scrubby enters calm idle.
3. After an idle interval of roughly 6–12 seconds, one decorative gesture may play.
4. Gesture selection uses a deterministic/randomized presentation scheduler with no immediate repeat:
   - Wave ~40%
   - Look/Turn ~35%
   - Bow ~25%
5. After gesture completion, return to idle.
6. Never stack two gestures.

A greeting wave may optionally play on Home entry, but it must use a cooldown so repeated Home <-> screen navigation does not cause constant waving.

No animation should delay Play/navigation.

## Pause / lifecycle rules

Decorative hero animation must pause or become inert when:

- Home is not the active route;
- app is backgrounded / loses focus;
- a full-screen transition is occurring.

When a modal covers Home, do not begin a new large gesture. Existing short gesture may either finish safely or return to idle without visual snapping.

No animation state is durable gameplay/save truth.

## Reduced Effects

When Reduced Effects is ON:

- disable large bob/turn/bow/wave motion;
- Scrubby may remain static or use only a minimal low-motion blink if owner-approved;
- no economic/gameplay/UI state changes.

## Asset strategy

Use a hybrid approach.

### Procedural / Godot-native

Idle micro-motion should preferably use `AnimationPlayer` / Tween on the Home hero container so it is cheap and resolution-independent.

### Frame animation

Wave, Bow and Turn/Look should use transparent frame sequences or an approved sprite atlas with consistent:

- canvas size;
- pivot;
- feet/ground line;
- character scale;
- lighting;
- brush/hand continuity;
- alpha bounds.

Suggested repo location:

`assets/ui/final/characters/scrubby/home_animation/`

Suggested structure:

- `idle/`
- `wave/`
- `bow/`
- `turn/`

Frame rate target: 10–12 fps is sufficient unless visual testing proves a higher rate is required.

Do not generate a giant video layer for Scrubby. Keep the runtime hero transparent and composable over the Home world.

## Godot component design

Create one dedicated presentation component, for example:

`HomeScrubbyHero`

It should own:

- current animation state;
- frame/texture presentation;
- idle AnimationPlayer/Tween;
- gesture scheduler;
- route/modal/focus pause hooks;
- Reduced Effects response.

It must remain presentation-only.

The component must not:

- mutate AppState/economy/progression;
- receive gameplay input authority;
- block Home buttons;
- create a second Home navigation state;
- change Scrubby selection/equipment truth.

## Responsive invariants

Across supported Home viewports:

- Scrubby's soles stay aligned to the owner-approved platform/ground line;
- animation never clips through the Play CTA/top HUD/shortcut panels;
- frame changes must not produce scale/anchor jitter;
- visual bbox may move internally, but the component's canonical layout contract stays stable.

Validate at minimum:

- 1080x2160;
- 1080x1920;
- 1290x2796;
- 1536x2048.

## Performance

Requirements:

- no per-frame asset loading;
- preload/cache animation textures;
- no one-node-per-frame construction;
- no timer/signal accumulation across Home re-entry;
- clean release/pause on route changes;
- no measurable impact on gameplay because the component exists only on Home.

## Evidence / owner gate

Implementation cycle must provide:

- idle runtime capture;
- wave capture;
- bow capture;
- turn/look capture;
- responsive Home screenshots;
- Reduced Effects demonstration;
- repeated Home enter/leave stability proof.

Owner visual acceptance is required before SB-M42-034 closes.

## Sequencing

Do not interrupt the current M28-C002-C003-R01 V02 remediation.

Canonical order:

1. close M28-C002-C003-R01 V02 + owner replay;
2. execute SB-M39-053 clock-boundary test-stability follow-up;
3. execute SB-M42-034 Home Scrubby Runtime Animation;
4. return to the existing M43/meta roadmap.

No implementation prompt is opened until this task becomes current.
