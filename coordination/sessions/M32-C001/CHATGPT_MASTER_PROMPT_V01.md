# M32-C001 V01 — Scrubbot Final Visuals Master Implementation Prompt

Repository: `Sekiph82/Scrubbots`  
Branch: `main`  
Milestone: `M32 — Scrubbot Final Visuals [VISUAL REFERENCE]`  
Implementation actor: Claude  
Tracker authority: root `TASKS.md` is ChatGPT-write-owned. Claude MUST NOT edit it.

## 0. Start / sync contract

Before editing anything:

1. Confirm repository `Sekiph82/Scrubbots`, branch `main`.
2. Fetch and fast-forward safely to `origin/main`. Never force-push and never hard-reset over owner work.
3. Read:
   - `CLAUDE.md`
   - root `TASKS.md` read-only
   - `coordination/sessions/M32-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`
   - `coordination/OWNER_ROBOT_ROSTER_V01.md`
   - `assets/ui/VISUAL_ASSET_INDEX.md`
   - `docs/MASTER_UI_SYSTEM.md`
   - `scripts/gameplay/agents/scrubbot_agent.gd`
   - `scripts/gameplay/dispatch/scrubbot_dispatcher.gd`
   - `scripts/gameplay/clearing/complete_clearing_loop.gd`
   - `scripts/gameplay/board/board_presentation.gd`
   - `scripts/gameplay/runtime/production_gameplay_host.gd`
   - M29-M31 focused evidence relevant to movement, relayout, retry and cleaning FX.
4. Inspect `git status` before work. Preserve owner files and unrelated local edits.
5. Run the relevant baseline regressions before invasive changes when practical.
6. M31 is CLOSED. Do not reopen or redesign M31 cleaning effects unless M32 causes a concrete regression.
7. Do not implement M33 audio, M34 haptics, robot economy/unlocks, Home, Results, Collection, or other future milestones.

## 1. M32 purpose

Replace the temporary colored debug-circle Scrubbot presentation with the owner-approved canonical **Scrubby** gameplay visual while preserving every accepted gameplay contract.

M32 is visual integration and visual animation. It is not a movement rewrite.

Current gameplay truth remains:

`TargetSelector -> RoutingSystem -> ScrubbotDispatcher -> ScrubbotAgent route traversal -> M20 authenticated clear`

The canonical Scrubby art follows that truth. It never decides it.

## 2. Canonical M32 checklist

M32 must address the evidence needed for:

- `SB-M32-001..010`
- `SB-M32-UI-001..011`

Do not mechanically generate new pictures to turn checklist items green. Several UI-generation requirements may already be satisfied by the existing owner-approved asset-production work; audit and document that evidence.

## 3. Canonical Scrubby assets: use what already exists

`coordination/OWNER_ROBOT_ROSTER_V01.md` establishes Scrubby as the franchise anchor and states that the existing Scrubby family is already canonical.

Audit these exact assets first:

- `assets/ui/final/characters/scrubby/scrubby_master.png`
- `assets/ui/final/characters/scrubby/scrubby_gameplay.png`
- `assets/ui/final/characters/scrubby/scrubby_portrait.png`
- `assets/ui/final/characters/scrubby/scrubby_home_pose.png`
- `assets/ui/final/characters/scrubby/scrubby_face_blink_layer.png`
- `assets/ui/final/characters/scrubby/scrubby_brush_arm_layer.png`
- `assets/ui/final/gameplay/profile/scrubby_portrait.png`
- `assets/ui/final/popups/help/help_scrubby_pose.png`
- `assets/ui/final/popups/victory/victory_scrubby_pose.png`

Also inspect production/provenance material in:

- `assets/ui/VISUAL_ASSET_INDEX.md`
- `coordination/codex_visual_assets/`
- `coordination/OWNER_ROBOT_ROSTER_V01.md`.

### Asset rule

**Do not generate new Scrubby art in this cycle.**

Do not replace canonical assets just because another pose or filename would be easier. Do not spend image-generation credits. If a required runtime behavior cannot be represented with the existing gameplay/layer assets, stop and document the exact visual gap for owner decision rather than silently inventing a new design.

Originals must remain preserved. If technical optimization requires a derived runtime copy, preserve the original and document why/how the derivative was produced.

## 4. Scope: default Scrubby only

M32 integrates the default canonical Scrubby into the current production gameplay path.

Although Robot 2..10 static assets exist or are being produced under the canonical roster, do **not** add robot selection, robot unlocks, robot perks, economy behavior, Collection behavior or runtime roster switching here. Those belong to later systems.

Architect the visual component so future robot skins can replace presentation assets without changing target/routing/clearing logic, but do not build the future selection system now.

## 5. Current agent contract that must survive

`ScrubbotAgent` currently owns deterministic board-local route traversal:

- agent `position` is authoritative visual movement position in board-local cell units;
- speed is route-distance based;
- arrival snaps exactly to the route endpoint;
- `agent_completed` emits once;
- dispatcher authenticates identity;
- M20 commits the clear;
- dispatcher finalization removes gameplay ownership and schedules safe destruction.

Preserve this contract.

Do not:
- tween the authoritative agent position;
- offset the agent away from the route to make animation look better;
- change speed based on animation;
- trigger clear from an animation callback;
- delay authenticated clear while waiting for an animation;
- add target selection/routing logic to the visual component.

## 6. Recommended presentation architecture

Create one narrow reusable visual component, suggested:

`scripts/gameplay/presentation/scrubbot_visual.gd`

or an equivalent clearly named component consistent with the repository.

A good structure is:

`ScrubbotAgent (authoritative board-local Node2D position)`
`  -> ScrubbotVisual (presentation-only local transform)`
`       -> body/gameplay sprite`
`       -> optional blink layer`
`       -> optional brush/tool layer`

The agent moves along the route exactly as before. Any visual bob/lean/blink/tool motion happens inside `ScrubbotVisual` local space.

Use shared/preloaded textures. Never decode the PNG into a new Image/Texture for every spawned agent.

The old `_draw()` colored circle must not appear in the normal canonical production path once Scrubby is available. It may remain as an explicit debug/headless/missing-asset fallback if clearly isolated and tested.

## 7. Gameplay scale and visual size

Scrubby must be legible but must not cover a large cluster of board cells.

Determine gameplay sprite scale from the current board cell scale and actual owner asset bounds. Do not hard-code screen pixels into gameplay logic.

Requirements:

- stable apparent size relative to a cell/rail path;
- no distortion;
- no accidental crop from transparent asset margins;
- correct centering/anchor;
- correct placement on rectangular and square boards;
- responsive relayout rescales the existing presentation correctly;
- no recreation of BoardRenderer/AgentLayer authority.

Test multiple portrait viewports, including the established small 683x1366 class and normal 1080-wide portrait layouts.

## 8. Travel animation

Travel must visually read as a small cleaning robot moving with purpose.

Use restrained presentation-only motion from the existing layers where useful:

- subtle bob/lean;
- blink cadence;
- small brush/tool-arm movement;
- optional subtle squash/stretch if it does not blur the character.

Keep animation inexpensive and deterministic enough for tests. Random cosmetic timing, if any, must never affect gameplay tests.

At 2x, the bot must remain readable rather than vibrating or over-animating.

Do not introduce screen-space path interpolation. The agent's accepted board-local route remains the only travel path.

## 9. Arrival and disappearance

This is the most important lifecycle constraint in M32.

Current M20 finalization is authoritative and must remain fast. Do not hold an arrived gameplay assignment open so a fade can finish.

Provide a short visible arrival/disappearance treatment without changing clear timing. Suitable patterns include:

- a detached presentation-only Scrubby echo spawned from the committed `authenticated_clear` event and faded/squashed quickly; or
- another equally safe presentation-only mechanism that survives only as a visual and owns no gameplay identity.

If using an arrival echo:

- spawn it only from an authoritative committed clear, not raw guessed arrival;
- place it at the exact cleared cell/agent endpoint;
- keep it short and bounded;
- clear it on Retry;
- do not retain gameplay reservations/claims/agent ownership;
- do not emit gameplay signals;
- cap any concurrent retirement visuals if needed.

M31 already shows puff + sparkle on committed clear. M32 arrival/disappearance must coexist with M31 rather than becoming a second explosion.

## 10. Direction/orientation

Audit whether the owner-approved Scrubby gameplay artwork has a safe direction/orientation treatment.

No direction-specific owner decision is currently assumed by this prompt.

Therefore V01 default is: preserve the canonical gameplay pose without route-dependent mirroring/rotation unless existing owner documentation clearly authorizes it.

If you find an explicit owner-approved orientation rule, implement it presentation-only and document the source.

Do not mirror an asymmetric brush/tool design merely because the robot travels left.

## 11. Import / texture quality

Audit the actual canonical PNGs rather than assuming they are pixel art.

These Scrubby assets are polished transparent character artwork. Configure runtime rendering/import for:

- clean alpha edges;
- crisp readable downscale;
- no texture bleeding;
- no unnecessary per-instance memory duplication;
- reasonable mobile texture memory;
- consistent filtering under movement/scale.

Do not blindly force nearest-neighbor pixel filtering onto anti-aliased 3D-style art.

If a runtime-size derivative is genuinely needed for performance, keep the canonical source untouched and record objective evidence.

## 12. UI-generation checklist audit

For `SB-M32-UI-001..006`, inspect the existing visual-production records and canonical paths.

Expected approach:

- confirm owner-approved Scrubby was the reference;
- confirm only required pose/state families were produced;
- confirm master/gameplay/portrait/home/layers/profile/help/victory requirements exist where the implemented product uses them;
- confirm raw/provenance records remain separate from promoted final assets;
- do not regenerate approved files.

`SB-M32-UI-007` still requires owner visual approval of the production integration. `SB-M32-UI-008..011` require protection against silent overwrite, Godot integration/import correctness, gameplay separation and viewport readability evidence.

## 13. Retry / terminal hygiene

Successful M30 Retry must remove every M32-only transient visual from the prior attempt:

- detached arrival echoes;
- presentation tweens;
- delayed callbacks;
- stale visual nodes.

Do not alter the M30 Retry gate itself.

On terminal WON/LOST, M32 does not decide terminal state. Any final Scrubby presentation is subordinate to M30 truth.

## 14. Performance / density

M32 must include a focused high-density presentation stress test.

At minimum measure in the actual test environment:

- peak simultaneous live Scrubbot visuals under a dense dispatch workload;
- visual update/animation cost;
- texture sharing behavior;
- any arrival-echo peak/cap/suppression if such a system exists;
- cleanup to zero;
- 1x and 2x behavior;
- 59x59 production board context where relevant.

Do not claim physical-phone FPS unless measured on a device.

Do not add speculative object pooling. Pool only if profiling proves a material benefit.

## 15. Tests / evidence

Add focused M32 evidence proving at least:

### Visual attachment
- a production Scrubbot gets one canonical visual component;
- the normal production path does not draw the old colored debug circle;
- canonical textures are shared, not decoded per bot.

### Movement separation
- route/position/progress truth is identical with visual animation enabled vs presentation disabled/fallback;
- local visual bob/tool motion does not change agent position;
- exact endpoint/one-shot completion remains intact.

### Arrival/disappearance
- a committed clear produces the intended presentation treatment at the correct location;
- rollback/rejected/reset paths do not falsely present a committed disappearance;
- presentation does not delay M20 clear/finalization.

### Retry
- successful Retry removes all stale M32 presentation state;
- no delayed visual callback reappears in the new attempt.

### Responsive layout
- representative rectangular board geometry remains aligned;
- small and normal portrait viewports remain readable;
- relayout preserves accepted presentation identities.

### Density
- bounded/high-density behavior and measured update cost;
- 1x and 2x.

## 16. Regression floor

Run at minimum:

- new M32 focused tests;
- root `res://tests/run_tests.gd`;
- M31 cleaning-effects evidence and scale stress;
- M30 completion/retry/manual smoke;
- M29 realtime movement/presentation identity/runtime smoke;
- M20 clearing lifecycle evidence;
- M19 dispatcher lifecycle tests relevant to queue-free/finalization;
- M26/59x59 production-scale sanity where relevant;
- `git diff --check`.

Any M32-caused gameplay regression is blocking.

## 17. Dedicated owner F6 scene

Create:

`res://scenes/debug/m32_scrubbot_visual_playtest.tscn`

using the real production gameplay stack.

Make visual review quick. Debug-only controls/readouts may include:

- AUTO-SOLVE;
- SPEED 1x/2x;
- FX ON/OFF for M31 coexistence comparison if convenient;
- a density/stress action that does not mutate gameplay truth incorrectly;
- RETRY;
- live agent/visual/arrival-echo counts.

The owner must be able to verify:

1. Scrubby is the correct canonical character.
2. Gameplay scale is appropriate.
3. Motion follows the path exactly and reads cleanly.
4. Blink/brush/travel animation is restrained.
5. Arrival/disappearance is visible but does not become a reward explosion.
6. M31 puff/sparkle still reads correctly.
7. 1x and 2x are acceptable.
8. High density stays readable.
9. RETRY leaves no stale bot/echo.
10. No normal-production debug circle is visible.

Claude cannot self-close M32. Handoff must remain `AWAITING_AUDIT` / owner F6 required.

## 18. Documentation / commit discipline

Claude may add focused M32 technical evidence/docs in the session folder as needed.

Claude MUST NOT edit root `TASKS.md`.

Implementation code/tests come first in a focused commit. Then write:

`coordination/sessions/M32-C001/CLAUDE_LOG_V01.md`

in a separate final documentation commit.

The log must record:

- implementation SHA;
- exact canonical assets used;
- provenance/asset audit result for `SB-M32-UI-001..006`;
- files changed;
- animation architecture;
- authoritative arrival/disappearance event source;
- import/render decisions;
- performance measurements;
- regression commands/results;
- owner F6 scene path;
- known limitations;
- explicit statement that no new AI art was generated;
- final handoff status `AWAITING_AUDIT`.

## 19. Stop conditions

Stop and report instead of guessing if:

- a supposedly canonical Scrubby asset is missing/corrupt;
- required arrival animation would require weakening M20/M19 lifecycle truth;
- an owner decision is required for directional art;
- a new image/pose appears necessary;
- current repo state contradicts the owner roster/provenance documents.

Do not silently expand scope.

## Expected handoff

After implementation and all automated evidence is green:

`AWAITING_AUDIT / M32-C001 V01 / OWNER_F6_REQUIRED`