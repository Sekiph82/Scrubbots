# M32-C001 V01 — ChatGPT Master Audit Criteria

Milestone: `M32 — Scrubbot Final Visuals [VISUAL REFERENCE]`

Authority:
- root `TASKS.md`
- `CLAUDE.md`
- `coordination/OWNER_ROBOT_ROSTER_V01.md`
- `assets/ui/VISUAL_ASSET_INDEX.md`
- `docs/MASTER_UI_SYSTEM.md`
- accepted M18-M31 gameplay/presentation contracts

## 1. Canonical asset authority

PASS only if M32 audits and uses the existing owner-approved Scrubby family before considering any new art.

Canonical Scrubby sources include:
- `assets/ui/final/characters/scrubby/scrubby_master.png`
- `assets/ui/final/characters/scrubby/scrubby_gameplay.png`
- `assets/ui/final/characters/scrubby/scrubby_portrait.png`
- `assets/ui/final/characters/scrubby/scrubby_home_pose.png`
- `assets/ui/final/characters/scrubby/scrubby_face_blink_layer.png`
- `assets/ui/final/characters/scrubby/scrubby_brush_arm_layer.png`
- `assets/ui/final/gameplay/profile/scrubby_portrait.png`
- `assets/ui/final/popups/help/help_scrubby_pose.png`
- `assets/ui/final/popups/victory/victory_scrubby_pose.png`

Do not regenerate an existing canonical asset merely to normalize naming or style. New AI image generation is out of scope unless the owner explicitly reopens asset generation.

## 2. Source preservation / provenance

Original owner-approved files remain byte-preserved unless the owner explicitly authorizes replacement. If runtime optimization requires a derived copy, preserve the original and document the derived path, method and reason.

`SB-M32-UI-001..006` may be satisfied by auditing the already-produced canonical assets and their production/provenance records. Do not generate duplicate assets just to satisfy checklist wording.

## 3. Gameplay separation

Final Scrubbot visuals must not alter:
- target selection;
- route computation or route points;
- agent travel distance/speed truth;
- reservation/claim identity;
- BoardState;
- supply/slot truth;
- M27 solver/deadlock truth;
- M30 terminal truth;
- M31 cleaning-event truth.

Visual animation must consume gameplay state, never become gameplay state.

## 4. Travel animation

The live Scrubbot visual must follow the existing `ScrubbotAgent` board-local position. Any bob, tilt, blink, brush/tool motion or squash is applied only to a visual child/local presentation transform.

Reject any implementation that tweens or offsets the authoritative agent position away from the route, changes route progress, changes speed, or decides arrival from animation completion.

## 5. Arrival / disappearance authority

Arrival/disappearance must preserve the accepted M19/M20 lifecycle. M20 committed-clear/finalization may not be delayed to wait for art animation.

If a visible post-clear arrival/disappearance animation needs to outlive the gameplay agent, use a detached presentation-only echo/overlay driven by an authoritative committed event. Do not keep completed gameplay assignments alive merely for animation.

No visual may appear on a failed/rolled-back clear as though the clear committed.

## 6. Agent cleanup / retry hygiene

Successful Retry must leave no stale Scrubbot visual, detached arrival echo, tween or callback from the previous attempt. Cancel/reset semantics and M30 Retry gates remain unchanged.

## 7. Direction/orientation

Do not invent directional art, left/right mirroring, facing policy or rotation that changes the owner-approved design without evidence/owner approval.

PASS for `SB-M32-009` if the implementation explicitly audits orientation and either:
- implements an owner-approved orientation rule; or
- records that V01 intentionally keeps the canonical non-directional gameplay pose because no direction-specific owner approval exists.

## 8. Import/render quality

Use settings appropriate to the actual smooth transparent character artwork. Do not blindly apply pixel-art nearest filtering to polished 3D/anti-aliased art.

Audit alpha edges, scaling quality, filtering/mipmaps/compression as applicable, mobile memory implications, and shared texture reuse. No per-agent source-image decode or duplicated Texture2D allocation.

## 9. Visual component architecture

Prefer one narrow reusable Scrubbot visual component/presentation controller. Runtime identity belongs to gameplay; image layers, blink/tool motion and detached retirement visuals belong to presentation.

The production path must stop drawing the old colored debug circle when the canonical visual is available. A debug/headless fallback may remain if clearly isolated.

## 10. Density / 59x59 performance

Require measured evidence under a high-agent-density workload relevant to the production maximum board envelope.

Audit at minimum:
- peak simultaneous visible Scrubbot visuals;
- update cost for travel visual animation;
- texture sharing / no per-instance decode;
- detached arrival visual cap/cleanup if such echoes exist;
- behavior at 1x and 2x;
- no unbounded visual queue/pool.

Do not invent device FPS. Record exactly what the test environment measures.

## 11. Phone viewport matrix

Final gameplay Scrubby must remain readable, correctly scaled and aligned on multiple portrait viewport sizes, including at least the established 683x1366-style small test and the project's normal 1080-wide portrait design range. Relayout must not recreate/strand agent presentation authority.

## 12. M31 coexistence

M32 must coexist cleanly with the accepted M31 puff/sparkle effect. Scrubby remains visually readable; cleaning FX remain subordinate; neither system may hide or displace board truth.

## 13. Owner F6 gate

Code audit may return:

`CODE_AUDIT_PASS / M32-C001 V01 / OWNER_F6_REQUIRED`

Final M32 closure requires owner visual acceptance of a dedicated production-stack playtest covering:
- canonical Scrubby appearance and scale;
- travel readability;
- blink/tool animation if implemented;
- arrival/disappearance;
- coexistence with M31 cleaning FX;
- 1x/2x;
- high-density readability;
- Retry cleanup;
- no visible debug-circle fallback in the normal production path;
- representative phone-size relayout.

## 14. Regression floor

Require:
- focused M32 visual/lifecycle tests;
- root suite;
- M31 cleaning-effects evidence;
- M30 completion/retry evidence;
- M29 realtime movement/presentation identity evidence;
- M20 authenticated clear lifecycle;
- M19 dispatcher lifecycle;
- 59x59/high-density sanity;
- `git diff --check`.

No drive-by economy, collection, Home, Results, Audio, Haptics or robot-unlock implementation.

## 15. Checklist closure discipline

`SB-M32-001..010` and `SB-M32-UI-001..011` may be marked complete only when there is concrete implementation/audit evidence for each item. Existing generated assets count when their owner approval/provenance is verified; duplicate generation is not required.

Claude must not edit root `TASKS.md`.

## Verdict targets

Successful code audit before owner visual gate:

`CODE_AUDIT_PASS / M32-C001 V01 / OWNER_F6_REQUIRED`

After owner visual acceptance:

`AUDITED_PASS / M32 SCRUBBOT FINAL VISUALS CLOSED`