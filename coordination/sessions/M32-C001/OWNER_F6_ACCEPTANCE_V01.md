# M32-C001 — Owner F6 Acceptance V01

Date: 2026-09-20  
Milestone: `M32 — Scrubbot Final Visuals`  
Scene: `res://scenes/debug/m32_scrubbot_visual_playtest.tscn`

## Owner-observed runtime acceptance

The owner manually ran the dedicated M32 F6 production-stack playtest after V02 code audit passed.

The owner reported **“hersey ok” / everything is OK** after reviewing the requested M32 gate.

Accepted owner-visible behavior:

1. The canonical Scrubby character appears in normal production gameplay.
2. Scrubby gameplay scale/readability is acceptable.
3. Travel visually follows the accepted route without visible path drift.
4. The V01 bob/lean/squash travel treatment is acceptable.
5. The short disappearance/retire echo is acceptable.
6. M31 cleaning puff + sparkle coexist acceptably with the M32 Scrubby presentation.
7. Actual gameplay at both 1x and 2x is visually acceptable.
8. BURST/high-density presentation is acceptable.
9. RETRY cleanup is acceptable with no reported stale Scrubby/echo residue.
10. No colored debug-circle fallback was reported in the normal production path.

The supplied F6 screenshot also shows multiple canonical Scrubby instances in the production gameplay composition at the small 683x1366 test viewport, consistent with the owner acceptance.

## Accepted bounded limitations

- Blink and brush-arm layers remain uncomposited because the owner assets do not provide registration offsets for their different canvases. M32 does not guess those offsets.
- No route-dependent mirroring/facing is introduced because no owner-approved directional rule exists.

These are accepted as non-blocking for M32 V1.

## Owner verdict

`OWNER_F6_PASS / M32 SCRUBBOT FINAL VISUALS ACCEPTED`