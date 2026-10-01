# M42-C003 — CHATGPT AUDIT CRITERIA V01

Date: 2026-10-01
Auditor: ChatGPT
Task: `SB-M42-035`

Expected verdict only if complete:

`AUDITED_PASS / OWNER ANIMATION VISUAL ACCEPTANCE REQUIRED`

## A. Prerequisite geometry — BLOCKING

Base hero remains exactly:
- `SCRUBBY_SCALE = 1.612`;
- accepted M42-C002 center/feet placement;
- current 940×1672 Home world.

No scale regression.

## B. Dedicated presentation component

One clear hero animation component owns animation/scheduler/lifecycle.

No second navigation/economy/save authority.

## C. Production gesture art — BLOCKING

Wave/Bow/Turn require real pose/frame sequences or approved atlas.

FAIL for:
- whole-image rotation standing in for Turn;
- old face/brush overlay revival;
- visibly crude cutout deformation;
- placeholder/fake art treated as final.

If real gesture art is absent, verdict cannot be PASS.

## D. Idle / gesture restoration

Idle is restrained.

Every gesture returns exactly to canonical idle:
- scale;
- feet;
- anchor;
- transform;
- front pose.

No drift/jitter.

## E. Scheduler

- 6–12 s target idle interval;
- Wave/Turn/Bow distribution represented;
- no immediate repeat;
- no stacking;
- deterministic test seam.

## F. Reduced Effects — BLOCKING

Uses canonical `AppState.effects`.

Live toggle ON suppresses large decorative motion.

Live toggle OFF restores normal presentation.

No duplicate setting state.

## G. Lifecycle / modal safety — BLOCKING

No new gesture starts when:
- Home hidden;
- modal/settings covers Home;
- app backgrounded/paused;
- focus lost.

Resume is clean and non-duplicating.

## H. Responsive / interaction

All required viewports remain acceptable.

No functional UI collision.

Play/navigation remains immediate.

Accepted 1536×2048 mirrored world-edge behavior must remain unchanged.

## I. Performance

No per-frame asset loading.

No timer/signal/tween/object accumulation across repeated Home route cycles.

## J. Presentation-only truth

Economy/progression/navigation save truth unchanged by animation.

No durable animation state.

## K. Fresh evidence / owner gate

Require runtime visual evidence for:
- idle;
- Wave;
- Bow;
- Turn/Look;
- Reduced Effects;
- responsive screens.

Technical PASS still requires owner visual acceptance.

## L. Regression/governance

Relevant M41/M42/M43/M40/root suites PASS.

`git diff --check` clean.

Claude must not edit root `TASKS.md`.

## Asset-blocked disposition

If production-quality Wave/Bow/Turn frames are unavailable, correct verdict is not a code PASS.

Use:

`BLOCKED_ANIMATION_ASSET_PRODUCTION / SB-M42-035 REMAINS OPEN`

rather than accepting placeholder art.
