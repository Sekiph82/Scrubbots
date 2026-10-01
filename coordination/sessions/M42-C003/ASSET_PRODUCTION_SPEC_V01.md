# M42-C003 — Home Scrubby Gesture Frames — ASSET PRODUCTION SPEC V01

Date: 2026-10-01
Task: `SB-M42-035` (blocked at the asset gate)
Authority: `coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V01.md`, `coordination/sessions/M42-C003/CHATGPT_PROMPT_V01.md`
Geometry source: accepted M42-C002 (`SCRUBBY_SCALE = 1.612`, OWNER PASS), `coordination/sessions/M42-C002/evidence/measurement_report.md`

All coordinates below are **HOME-026 texture pixels** (`assets/ui/final/characters/scrubby/scrubby_home_pose.png`, 1158x1358 RGBA, sha256 `fc30b992787c644822a6cd02510e481fab9010cd89ab75fc4a9909ca713d5c18`). HOME-026 is never modified and stays the static fallback / idle front pose.

## 1. Deliverables

| Set | Duration @ 12 fps | Frames to author | Runtime sequence |
|---|---|---|---|
| Wave | 1.25 s | `wave_01.png` .. `wave_14.png` (14) | HOME-026, wave_01..14, HOME-026 |
| Bow | 1.333 s | `bow_01.png` .. `bow_15.png` (15) | HOME-026, bow_01..15, HOME-026 |
| Turn / Look | 1.5 s | `turn_01.png` .. `turn_17.png` (17) | HOME-026, turn_01..17, HOME-026 |

46 authored frames total. The runtime bookends every gesture with HOME-026 itself, so start/end are pixel-exact idle by construction; authored first and last in-betweens must therefore ease out of / into the HOME-026 pose without a visible pop.

Optional (only if owner wants it): `blink_01..03` (3 frames, eyes only) — the single motion allowed under Reduced Effects.

Raw candidates: `assets/ui/generated/characters/home_animation/{wave,bow,turn}/` (never loaded by the game).
After owner approval only: promote byte-identical to `assets/ui/final/characters/scrubby/home_animation/{wave,bow,turn}/` and pin each file's `approved_sha256` in `assets/ui/HOME_ASSET_MANIFEST.json` (new HOME-1xx ids, provenance + approval authority recorded).

## 2. Canvas / registration — every frame (BLOCKING)

- Canvas exactly **1158 x 1358**, RGBA8 PNG, straight (non-premultiplied) alpha, fully transparent background, no matte/halo, no drop shadow baked outside the character's existing contact shading.
- **Pivot / ground contact = (592, 1318)**: x 592 = HOME-026 visible centre (`27 + 1130/2`), y 1318 = HOME-026 soles line (`SCRUBBY_FEET_Y`). Runtime scales the frame about this point, so it must mean the same thing in every frame.
- Soles: the lowest sole pixels of both feet stay on y = 1318 (±1 texel) in every frame. Feet do not slide: each foot's x-extent may differ from HOME-026 by at most ±6 texels (Turn may rotate the feet in place, not step).
- Brush bristles may reach below the soles exactly as in HOME-026 (to y ≤ 1334), never lower.
- Scale: identical character scale to HOME-026 — same head width, body height, limb thickness. No re-framing, no zoom, no crop. Any upright frame's head/leaf top stays within ±4 texels of HOME-026's top (y 7); Bow frames may only go lower.
- Every opaque texel stays inside the 1158 x 1358 canvas (no edge contact on left/right/top — at 1.612 the canvas edge is the safety boundary for the DAILY panel at 1080x1920, 26.6 screen px clearance today).

## 3. Keep-out zones — every frame (BLOCKING, auto-tested)

Derived from the four required viewports (1080x2160, 1080x1920, 1290x2796, 1536x2048) by mapping each live control / baked helper-bot rect into texture space with the accepted transform. Rects are `[x0, x1) x [y0, y1)`.

| Zone | Texture rect | Rule | Source |
|---|---|---|---|
| K1 COLLECTION panel | x 0..69, y 40..308 | 0 opaque texels (alpha > 128) | 1080x2160 hit rect |
| K2 DAILY panel | x 1115..1158, y 40..308 | 0 opaque texels | 1080x2160 hit rect |
| K3 right helper bot | x 1059..1158, y 829..1339 | 0 opaque texels | all four viewports |
| K4 left helper bot | x 0..125, y 999..1358 | opaque texels only inside HOME-026's existing brush footprint there (bounds x 27..124, y 1134..1288; ≤ 7944 texels) — the owner-accepted brush/bucket relationship may not grow | all four viewports |

HUD, Gift Meter, Play, reward track and BottomNav map entirely outside the canvas at all four viewports, so rule 2 (stay inside the canvas) protects them.

## 4. Visual continuity (BLOCKING, owner-judged)

- Same identity as HOME-026: white/teal shell, black visor with blue smile eyes, green two-leaf sprout, teal backpack, shield emblem, teal joints.
- Same lighting: key-light direction, rim light, specular placement and colour temperature identical to HOME-026; no frame-to-frame flicker of highlights or outline thickness.
- Brush continuity: the long-handled brush stays in the same hand (viewer's left) for all three gestures, same length and bristle colour; it never vanishes, teleports, or changes hands.
- Wave: the already-raised hand (viewer's right) performs one friendly wave (2 side-to-side oscillations max), then returns to the HOME-026 raised-hand position.
- Bow: forward bend from the hips/torso, head lowers, ≤ ~20° visual lean; both soles stay planted; brush stays held, bristles stay on/near the platform; hold at the bottom 2–3 frames.
- Turn / Look: head-led look to one side (≈ 25–35° perceived yaw) with shoulders following slightly, then back to front; painted as real 3/4 views (visor/sprout/backpack re-drawn in perspective) — never a flipped, skewed or rotated copy of HOME-026.
- Forbidden: whole-image rotation/skew/scale standing in for motion; runtime slicing/warping of HOME-026; revival or reuse of `scrubby_face_blink_layer.png` / `scrubby_brush_arm_layer.png`; placeholder or AI-artefacted frames (melted hands, changing finger count, shifting emblem, noisy outlines).

## 5. Acceptance

Automated (implemented with the runtime, see plan): canvas size, alpha mode, soles line ±1, foot drift ±6, top-of-head ±4, K1–K4, inside-canvas, per-frame sha pin, consistent alpha-bbox centre drift report.
Owner: per-gesture contact sheet + 12 fps loop capture at 1080x2160 over the live Home, side-by-side with HOME-026, then the four-viewport runtime captures listed in the M42-C003 prompt.

## 6. Runtime implementation plan (ready once frames are approved)

One presentation component `scripts/ui/home/home_scrubby_hero.gd` (`HomeScrubbyHero extends Control`), created by HomeScreen in place of the bare `Art_scrubby` TextureRect inside `Background/Layer_characters` (child TextureRect keeps the name `Art_scrubby`, so M42-C002 geometry/tests keep working).

- **Geometry**: `HomeScreen._layout_world()` keeps computing the canonical 1.612 rect via `get_scrubby_canonical()` and calls `hero.set_base_rect(rect, pivot_screen)`; the component never computes layout. Frame swaps change only `texture` (same canvas ⇒ same rect), so no jitter.
- **Textures**: all frames preloaded once (`const` arrays of `preload()`), one TextureRect reused; no per-frame load, no node per frame.
- **Idle**: procedural transform on the TextureRect about the soles pivot (`pivot_offset = (592,1318)·k`): bob ≤ 3 screen px at 1080x2160 equivalent (scaled by world scale), tilt ≤ 0.6°, optional squash ≤ 1%; pure function of a phase clock (`sin`), so it returns exactly to identity at phase 0 — no Tween accumulation, no drift. Feet stay registered because bob is applied as squash about the soles (height change, base fixed), not as translation.
- **Scheduler**: idle interval uniform 6–12 s; weights Wave 40 / Turn 35 / Bow 25; never the previous gesture; single state machine `IDLE → GESTURE → IDLE`, next interval starts only after return; injected `RandomNumberGenerator` + clock callable seams for tests; optional entry wave with ≥ 60 s cooldown (off by default).
- **Reduced Effects**: `bind(app)` → `app.effects.is_reduced()` + `app.effects.changed.connect(_on_reduced)`; ON = stop scheduler, finish nothing new, snap-free ease to identity over ≤ 150 ms, then static HOME-026 (blink only if approved blink frames exist); OFF = resume. Disconnected in `_exit_tree`. No second setting.
- **Lifecycle**: inert (`set_process(false)`, scheduler paused, current gesture allowed to finish) when `not is_visible_in_tree()` (Home route hidden: `main.gd` sets `_home.visible`), when `home.is_modal_active()` (popups / `set_modal_active("settings")`) — no new gesture starts; and on `NOTIFICATION_APPLICATION_FOCUS_OUT/PAUSED` in the component's own `_notification` (resume on FOCUS_IN/RESUMED). Resume restarts a fresh 6–12 s interval (no catch-up burst).
- **Presentation-only**: `mouse_filter = IGNORE` throughout; no AppState writes, no save fields, no signals into navigation.
- **Tests** `tests/m42_c003_scrubby_animation.gd`: the 16 required cases in the prompt plus the §5 frame checks over every approved frame at the four viewports (reusing `tests/m42_c002_scrubby_scale.gd` `measure()` / `opaque_in()` with the frame's alpha).
- **Evidence tool** `tests/tools/m42_c003_animation_evidence.gd`: deterministic clock/RNG → per-gesture frame strips and contact sheets, Reduced Effects static frame, four viewport screenshots, 20× Home enter/leave object/timer/signal count report.

## 7. Alternative if frame painting is impractical

A properly **artist-painted layered rig** (separately painted head/visor, torso, backpack, each arm, brush, legs, with occluded areas painted in, same canvas + pivot as above) animated with Godot `Skeleton2D`/`Polygon2D` would also satisfy the owner rule — it is not runtime slicing of HOME-026. Requires the owner to approve the layered source and still needs real 3/4 head paintings for Turn/Look.
