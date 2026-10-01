# M42-C003 - Home Scrubby Gesture Frames - ASSET PRODUCTION SPEC V03

Date: 2026-10-01
Task: SB-M42-035
Authority: `coordination/OWNER_M42_HOME_SCRUBBY_ANIMATION_V03.md`
Supersedes V02 where conflicting.

## 1. Inputs

Use the already staged and verified V02 owner source bytes and committed preparation evidence.

Canonical archive SHA-256:
`f5c34699f14dabc53a5c8126ad81dabd811711d1acd96fda47e523a18ad64458`

Canonical HOME-026 stays unchanged:
`assets/ui/final/characters/scrubby/scrubby_home_pose.png`
SHA-256:
`fc30b992787c644822a6cd02510e481fab9010cd89ab75fc4a9909ca713d5c18`

No new art generation.

## 2. Production counts

- Wave 14
- Bow 15
- Turn/Look 17
- Full Turn 17
- Total 63

V02 sequence-remediation rules remain active.

## 3. V03 common animation canvas

Do not force animation art into 1158x1358.

The committed asset tool must compute a deterministic **common animation canvas** after family-scale normalization:

1. choose one uniform scale per source family to match HOME-026 visual scale;
2. register every pose to a common soles/root origin;
3. measure the union bounds of all 63 normalized frames;
4. add deterministic transparent safety margin on every side;
5. round canvas dimensions deterministically to a practical multiple (for example 8 or 16);
6. choose one common animation-space pivot `P_anim=(px,py)`;
7. output all 63 promoted frames with exactly that canvas and pivot.

No frame-specific canvas, scale, crop, stretch, skew, or art mutation.

High-quality uniform upscaling is allowed because source raster resolution is lower than HOME-026. Use one deterministic resampler and document it.

## 4. Runtime mapping

The animation component must not assume animation texture size equals HOME-026 texture size.

Let `k` be the current screen pixels per HOME texture pixel implied by accepted M42-C002 layout.

HOME texture placement remains unchanged.

For an animation frame:

- render at native normalized animation pixel size multiplied by the same `k`;
- set its screen position so `P_anim * k` lands exactly on the accepted HOME soles/root screen pivot;
- swaps between animation frames must not change the control's root/pivot;
- returning to HOME-026 restores the canonical HOME texture/rect without changing the screen pivot.

The result must maintain the owner-approved 1.612 Home hero physical scale.

## 5. Scale fitting

Use family-level uniform scale only.

Do not use total canvas dimensions as identity measurement.

Prioritize:

1. visor/head width;
2. torso/limb thickness;
3. character height in upright comparable poses;
4. ground/root alignment;
5. transition quality.

The V02 85% diagnostic is not a production rule.

Emit a report comparing each family's normalized identity measurements to HOME-026.

## 6. Screen-space collision validation

Run the actual normalized animation frames through the accepted Home transform at:

- 1080x2160
- 1080x1920
- 1290x2796
- 1536x2048

Blocking:
- Play CTA intersection;
- top HUD/currency intersection;
- functional shortcut/panel hit-rect intersection;
- viewport clipping of required character art.

Warning only:
- left/right decorative helper visual overlap.

Legacy texture-space K1-K4 counts may still be reported for continuity but cannot fail V03.

If decorative helper overlap is ugly, presentation-only z-order/temporary helper visibility adjustment is allowed during large gestures. Never shrink individual frames.

## 7. Transition acceptance

Create real-scale transition evidence:
HOME-026 -> first gesture frames -> gesture -> final gesture frames -> HOME-026.

A transition fails if there is an obvious size pulse, root jump, or discontinuous screen translation.

Pose change itself is expected. Pixel identity is not required.

## 8. Promotion

After V03 deterministic and screen-space gates pass, promotion is authorized to:
`assets/ui/final/characters/scrubby/home_animation/{wave,bow,turn,full_turn}/`

Update HOME asset manifest with exact promoted SHA-256 and provenance.

Runtime may load only final assets.

## 9. Runtime

One `HomeScrubbyHero` component.

Scheduler:
- Wave 35
- Turn/Look 30
- Bow 25
- Full Turn 10
- 6-12 s
- no immediate repeat
- no stack

Reduced Effects and lifecycle behavior remain as V02.

## 10. Evidence

Required:

- V03 family scale report;
- common animation canvas + pivot report;
- all 63 frame measurements and SHA;
- deterministic rerun proof;
- four contact sheets;
- four HOME transition strips at true runtime scale;
- four required viewport captures;
- screen-space collision report naming actual UI nodes/rects;
- helper-overlap warning report;
- Reduced Effects evidence;
- 20x lifecycle stability proof;
- complete current regression suite.

Independent ChatGPT audit remains final technical gate.
