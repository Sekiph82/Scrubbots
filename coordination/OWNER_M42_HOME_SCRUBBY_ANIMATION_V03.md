# OWNER M42 HOME SCRUBBY ANIMATION V03

Date: 2026-10-01
Authority: OWNER
Status: ACTIVE / SUPERSEDES V02 WHERE CONFLICTING
Task: SB-M42-035

## Owner decision after V02 constraint audit

Do **not** regenerate the 63 approved source frames.

Preserve the owner-approved HOME hero scale and solve the V02 conflict technically.

Canonical idle/fallback remains:
`assets/ui/final/characters/scrubby/scrubby_home_pose.png`

Canonical Home presentation remains:
`SCRUBBY_SCALE = 1.612`

The 63-frame owner archive remains the only source-art authority:
Wave 14 + Bow 15 + Turn/Look 17 + Full Turn 17.

## Representation change

HOME-026 remains a 1158x1358 texture. Animation frames are no longer required to fit inside that same source texture canvas.

Claude may create one **common larger transparent animation canvas** sized deterministically from the normalized 63-frame union, with generous safety margins.

All promoted gesture frames must share:

- the exact same animation canvas dimensions;
- the exact same animation-space soles/root pivot;
- one uniform scale per visual source family;
- transparent background;
- no per-frame scale/warp;
- no crop of approved character art.

At runtime, the animation texture is positioned from the canonical **screen-space soles pivot**, not by pretending it has the same texture rectangle as HOME-026.

## Scale authority

Preserving Scrubby's visible character scale has priority over decorative helper separation.

Family scale should match HOME-026 identity using stable features such as visor/head width and limb/body thickness. No frame may be individually shrunk to pass a side-helper gate.

Minor unavoidable style/proportion differences from the generated source art are accepted if:

- the character clearly remains the same Scrubby;
- there is no visible grow/shrink pulse within a gesture;
- HOME-026 -> gesture -> HOME-026 transition is visually reasonable at runtime;
- no hard UI collision occurs.

## Screen-space safety authority

V01/V02 texture-space K1-K4 coordinates are **diagnostic legacy evidence**, not V03 blocking geometry for animation textures.

V03 hard blockers are live screen-space intersections at the required Home viewports:

- Play CTA;
- top HUD/currency area;
- shortcut panels / live tappable Home UI;
- viewport clipping.

The decorative left/right helper bots are **warning-only** for all four gestures. Scrubby may visually pass in front of/near a decorative helper during a gesture. Do not shrink the hero to avoid that.

If helper overlap looks poor, prefer a minimal presentation-layer z-order or helper visibility adjustment during a large gesture over changing Scrubby scale.

Do not move functional Home controls.

## Four gestures

1. Wave: 14
2. Bow: 15
3. Turn/Look: 17, bilateral right -> center -> left -> center
4. Full Turn: 17, rare 360-degree in-place turn

Scheduler weights:
- Wave 35
- Turn/Look 30
- Bow 25
- Full Turn 10

No immediate repeat and no stacking.

## Delegation

Claude is authorized to complete the technical remediation, promotion, runtime implementation, tests, and evidence without asking the owner to resize, crop, copy, rename, or regenerate image files.

Only stop if a genuine hard UI collision remains at HOME-authority scale after the V03 larger-canvas runtime model has been implemented and measured.
