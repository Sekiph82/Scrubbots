# OWNER M42 HOME SCRUBBY ANIMATION V02

Date: 2026-10-01
Authority: OWNER
Status: ACTIVE / SUPERSEDES V01 WHERE CONFLICTING
Target task: SB-M42-035
Target cycle: M42-C003 V02

## Owner revision

The owner has completed the source-art production pass and explicitly delegates the remaining technical cleanup, registration, normalization, promotion, runtime integration, and validation to ChatGPT/Codex without requiring further manual image-prep work from the owner.

Canonical idle/fallback remains:

`assets/ui/final/characters/scrubby/scrubby_home_pose.png` (HOME-026)

Canonical Home hero scale remains:

`SCRUBBY_SCALE = 1.612`

## Four approved gesture families

The runtime now has four decorative gesture families:

1. Wave: 14 production frames.
2. Bow: 15 production frames.
3. Turn / Look Around: 17 production frames.
4. Full Turn: 17 production frames.

The owner-provided source archive contains 63 PNG frames total and is the only approved source-art pool for this cycle. No new AI art is required or authorized for technical cleanup.

## Turn / Look Around behavior lock

Turn / Look must look both directions and return to center:

- frame 1: center;
- frames 2-5: look right, reaching about 25-35 degrees perceived yaw;
- frames 6-8: return toward center;
- frames 9-12: look left, reaching about 25-35 degrees perceived yaw;
- frames 13-17: return to HOME-026 center.

A final production sequence may reorder or reuse owner-approved source frames to satisfy this behavior. It may also derive the final Turn / Look sequence from the approved Full Turn source family if that gives better HOME-026 identity/scale continuity than the dedicated Turn / Look source family. No new painted frame may be invented by the implementation agent.

## Full Turn behavior

Full Turn is a real in-place 360-degree decorative rotation sequence, not a flat image rotation. It is intentionally rare.

Default scheduler weights for V02:

- Wave: 35
- Turn / Look: 30
- Bow: 25
- Full Turn: 10

No immediate repeat. Never stack gestures.

These weights are presentation tuning, not save/gameplay truth.

## Source-frame remediation authority

The implementation agent may, without asking the owner again:

- reorder approved source frames;
- duplicate approved source frames to hold/ease a pose;
- omit source frames that introduce a wrong gesture;
- reverse a clean subsequence;
- derive Turn / Look from the Full Turn source family;
- perform deterministic alpha cleanup, transparent padding, uniform family scaling, and registration.

The implementation agent may not:

- generate new character art;
- warp/stretch a frame non-uniformly;
- use a different scale for individual frames within one visual family;
- rotate/skew a flat HOME-026 texture as a replacement for real art;
- revive the forbidden old face/brush layers.

## Known source-art observations to remediate technically

- Wave source is visually coherent but its raw endpoint does not necessarily match HOME-026 closely enough.
- Bow source contains late frames that drift into a wave-like hand gesture; the final Bow sequence must remain Bow-only and may be rebuilt from the clean Bow subset.
- Dedicated Turn / Look source has a noticeably different raw source scale/proportion than HOME-026; if normalization cannot preserve identity without visible shrink/grow, derive Turn / Look from Full Turn source frames.
- Full Turn is a valid fourth source family and must be treated as real production work, not discarded.

## Acceptance delegation

The owner has already supplied/approved the source-art pool and delegates technical promotion to ChatGPT/Codex when:

- the source archive hash matches the canonical manifest;
- normalized frames pass deterministic registration and alpha/canvas checks;
- runtime transition evidence shows no unacceptable pop/jitter;
- required regression tests pass;
- the independent ChatGPT audit does not find a blocking defect.

No additional owner frame-by-frame prep action is required before Codex work begins.
