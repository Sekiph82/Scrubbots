# M32-C001 V01 — Claude Implementation Log

Milestone: `M32 — Scrubbot Final Visuals [VISUAL REFERENCE]`
Actor: Claude (Opus 4.8)
Status handoff: **AWAITING_AUDIT / M32-C001 V01 / OWNER_F6_REQUIRED**

## 1. Summary

Replaced the temporary colored debug-circle Scrubbot presentation with the owner-approved
canonical **Scrubby** gameplay artwork, integrated presentation-only into the accepted
production stack. Every M18–M31 gameplay/presentation contract is preserved. No new AI art
was generated and no owner-approved asset was modified or regenerated.

M32 is visual integration + restrained visual animation only. `TargetSelector -> RoutingSystem
-> ScrubbotDispatcher -> ScrubbotAgent traversal -> M20 authenticated clear` is unchanged and
untouched: the visual consumes gameplay state, never becomes it.

## 2. Implementation SHA

- Implementation commit: **19c1c98** — `feat(M32-C001 V01): canonical Scrubby gameplay visual + arrival echo`
- Documentation commit (this log): see the following commit on `main`.
- Branch: `main` (repo `Sekiph82/Scrubbots`). Synced by fast-forward from `f3dee92`; no
  force-push, no reset, no destructive cleanup. Pre-existing local owner work (`project.godot`
  editor resave, untracked `.import`/`.uid` files) was preserved and intentionally left out of
  the M32 commits.

## 3. Exact canonical assets used

- `assets/ui/final/characters/scrubby/scrubby_gameplay.png` (1230×1278) — the live travel body
  sprite AND the detached retire-echo sprite (same shared cached texture).

No other Scrubby asset was consumed by runtime code in V01. All nine canonical Scrubby family
assets were audited and confirmed present (see §5); the additional poses (master/portrait/home/
profile/help/victory) belong to Home/Results/Collection/HUD milestones that are out of M32 scope.

## 4. No new AI art

Explicit statement: **no new AI image generation was performed in this cycle.** No image
generation credits were spent. The single gameplay pose already in the repo (owner Phase-1
production) is reused unchanged. Originals remain byte-preserved; no derived runtime copy was
required (see §9).

## 5. Provenance / asset audit — `SB-M32-UI-001..006`

Audited against `assets/ui/VISUAL_ASSET_INDEX.md` and `coordination/OWNER_ROBOT_ROSTER_V01.md`.

| Canonical asset | Present | Provenance (VISUAL_ASSET_INDEX) |
|---|---|---|
| `characters/scrubby/scrubby_master.png` | yes | Phase 1 |
| `characters/scrubby/scrubby_gameplay.png` | yes | Phase 1 (used at runtime) |
| `characters/scrubby/scrubby_portrait.png` | yes | Phase 1 |
| `characters/scrubby/scrubby_home_pose.png` | yes | Phase 1 |
| `characters/scrubby/scrubby_face_blink_layer.png` | yes | Phase 1 (not composited in V01, §7) |
| `characters/scrubby/scrubby_brush_arm_layer.png` | yes | Phase 1 (not composited in V01, §7) |
| `gameplay/profile/scrubby_portrait.png` | yes | present |
| `popups/help/help_scrubby_pose.png` | yes | present |
| `popups/victory/victory_scrubby_pose.png` | yes | present |

Result: the owner-approved Scrubby family already satisfies the UI-generation checklist wording;
no duplicate generation was needed or performed. Raw/provenance records remain separate under
`assets/ui/generated/` and `coordination/codex_visual_assets/`; only the promoted `final/` asset
is referenced at runtime, and it is not overwritten.

`SB-M32-UI-007` (owner visual approval of the production integration) requires the F6 gate (§12).
`SB-M32-UI-008..011` (silent-overwrite protection, Godot import correctness, gameplay separation,
viewport readability) are covered by §3/§7/§8/§10/§11 evidence.

## 6. Files changed

New:
- `scripts/gameplay/presentation/scrubbot_visual.gd`
- `scripts/gameplay/presentation/scrubbot_retire_echo_controller.gd`
- `scripts/debug/m32_scrubbot_visual_playtest.gd`
- `scenes/debug/m32_scrubbot_visual_playtest.tscn`
- `tests/m32_scrubbot_visual_evidence.gd`

Modified (additive, presentation-only):
- `scripts/gameplay/agents/scrubbot_agent.gd` — `_visual_present` flag + `set_visual_present()` /
  `is_visual_present()` + `_draw()` early-return. Zero change to movement/route/progress/identity.
- `scripts/gameplay/board/board_presentation.gd` — identity-stable `RetireFxLayer` +
  `get_retire_fx_layer()`.
- `scripts/gameplay/runtime/production_gameplay_host.gd` — dispatcher agent factory injection,
  retire-echo controller wiring + retry reset + accessor.

## 7. Animation architecture

```
ScrubbotAgent (authoritative board-local Node2D position — unchanged)
  └── ScrubbotVisual (presentation-only, local transform)
        └── body Sprite2D (canonical scrubby_gameplay.png)
```

- The agent moves along the accepted board-local route exactly as before. The visual reads only
  the parent transform; it writes nothing to gameplay.
- Travel motion (V01): restrained bob (vertical), lean (small rotation) and subtle squash/stretch,
  all applied to the LOCAL body sprite (`ScrubbotVisual.animate(delta)` / `_process`). The
  authoritative `ScrubbotAgent.position` is never moved, offset or retimed by animation.
- Sizing is in board-local CELL units (`BODY_SPAN_CELLS = 1.8`, mapped to the larger texture
  dimension so no crop). Because the AgentLayer already scales one cell-unit to the renderer's
  integer cell size, a responsive relayout rescales the visual for free; no screen pixels are
  baked into gameplay or the visual sizing.
- Blink and brush-arm layers are **intentionally not composited in V01**. The layer PNGs are
  separate canvases with different sizes/aspect (blink 1536×1024, brush 1395×1127) from the
  gameplay pose (1230×1278) and carry no owner-provided registration offsets; stacking them would
  misregister the face/arm. Per prompt §19 this is documented as a bounded gap rather than guessed.
  Travel readability is carried by the transform motion above. See §13.
- Direction/orientation: no owner directional decision exists, so V01 keeps the canonical
  non-directional gameplay pose (no route-dependent mirroring/rotation), per audit §7.
- Injection: the dispatcher's existing `agent_factory` seam (used by both `dispatch()` and the
  production `dispatch_preclaimed()` path) is bound to a host factory that returns a fresh,
  unparented, UNASSIGNED `ScrubbotAgent` carrying one `ScrubbotVisual` child. The dispatcher's
  ownability/assignment postconditions are unaffected (agent still UNASSIGNED + unparented at
  assign; the visual is only its child).

## 8. Authoritative arrival/disappearance event source

- Source: `CompleteClearingLoop.authenticated_clear(owner_id, target_index, color_id, agent)` —
  emitted exactly once per committed CLEARED transaction, only after BoardState → candidate →
  reservation → dispatcher-finalize all succeed. It is never emitted on a preflight rejection,
  any rollback, a fatal transaction or a reset.
- `ScrubbotRetireEchoController` is a pure observer of that signal (mirroring the accepted M31
  `CleaningEffectsController` pattern). On a committed clear it spawns ONE short detached Scrubby
  echo at the exact cleared cell (`cell.x+0.5, cell.y+0.5`), which fades + shrinks over `LIFETIME
  = 0.28s` and frees itself. It owns no reservation/claim/agent identity, emits no gameplay signal,
  and the M20 finalize is never delayed to wait for it. A rolled-back/rejected/reset clear cannot
  produce an echo because the signal never fires on those paths.
- Coexistence with M31: the M31 puff/sparkle is a small clean cue on the `CleaningFxLayer` (under
  agents); the M32 echo is the vanishing bot silhouette on the `RetireFxLayer` (above agents).
  Both are short and restrained — not a second reward explosion.
- Concurrency cap `MAX_ACTIVE_ECHOES = 16` is a presentation safety valve only; a suppressed echo
  is counted and dropped and never blocks/queues/delays a clear.

## 9. Import / render decisions

Audited the actual canonical PNGs (smooth transparent 3D-style character art, NOT pixel art). The
existing import config for `scrubby_gameplay.png` is already correct and was **left unchanged**:

- `compress/mode=0` (lossless), `mipmaps/generate=false`, `process/fix_alpha_border=true`.
- Default canvas texture filter is Linear (no project nearest override); the visual/echo sprites
  additionally set `texture_filter = TEXTURE_FILTER_LINEAR` explicitly for crisp anti-aliased
  downscale and to guarantee no nearest-neighbour is ever forced onto the smooth art.
- Texture sharing: the canonical texture is loaded once into a static cache and reused by every
  live visual and every echo — no per-agent `Image`/`Texture2D` decode or duplicate allocation.
- No runtime-size derivative was needed, so the original is untouched (no derived copy exists).

## 10. Performance / density measurements

Measured headlessly on the real production stack (20×20 Hazard Bot), driven auto-solve, at 1x and
2x (from `tests/m32_scrubbot_visual_evidence.gd`):

- Peak simultaneous live Scrubby visuals: **395 (1x)**, **395 (2x)** — one visual per live agent,
  bounded by the accepted dispatch pipeline, not by M32; all sharing the one cached texture.
- Retire-echo peak concurrent: **within the cap of 16** at both 1x and 2x (bounded, no unbounded
  queue; over-cap requests suppressed deterministically).
- Cleanup to zero verified: aging frees expired echoes and Retry clears all echoes to 0.
- No object pooling added (prompt §14) — profiling showed the bounded allocate-and-free path is
  sufficient.
- No device/phone FPS is claimed; only what the headless test environment measures is reported.

## 11. Viewport / relayout

- Integration exercises both a 1080×2160 portrait build and a representative small **683×1366**
  relayout; the `RetireFxLayer` (and the accepted AgentLayer/CleaningFxLayer) keep identity across
  relayout, so live agent/echo presentation is never stranded on a stale off-screen node.
- Gameplay sprite scale is derived from cell units, not screen pixels, so it stays stable/aligned
  on rectangular and square boards and across viewport sizes.

## 12. Owner F6 scene

`res://scenes/debug/m32_scrubbot_visual_playtest.tscn` (script `scripts/debug/m32_scrubbot_visual_playtest.gd`)
runs the real production stack with debug-only controls: AUTO-SOLVE, SPEED 1x/2x, FX ON/OFF (M31
coexistence), ECHO ON/OFF, BURST (presentation-only echo density stress), RETRY, and a live
readout (agents | echo active/peak/suppressed | cues). The owner verifies canonical character,
scale, path-exact motion, restrained animation, visible-but-not-explosive disappearance, M31
coexistence, 1x/2x, high-density readability, Retry cleanup and no debug-circle in normal play.

Claude cannot self-close M32. Owner F6 visual acceptance is required.

## 13. Known limitations

- Blink and brush-arm layer compositing is deferred to a future cycle: the layers lack owner
  registration offsets against the gameplay pose (different canvas sizes), so V01 does not stack
  them. If the owner wants animated blink/brush at gameplay scale, provide per-layer anchor/offset
  data (or an aligned layer export) and it can be added presentation-only.
- No directional/facing art (no owner rule); the canonical pose is used for all travel directions.
- Density figure (395 peak visuals) is a headless measurement of the accepted pipeline on the
  Hazard Bot level, not a device-FPS claim.

## 14. Regression commands / results

All green:

- `godot --headless --path . -s res://tests/m32_scrubbot_visual_evidence.gd` → **PASS**
- `godot --headless --path . -s res://tests/run_tests.gd` → **Failures: 0 / RESULT: ALL PASS**
  (exit 0; engine-exit leak warnings are pre-existing headless noise, unrelated to M32)
- `godot --headless --path . -s res://tests/m31_cleaning_effects_evidence.gd` → **PASS**
- `godot --headless --path . -s res://tests/m31_scale_59_effects.gd` → **PASS**
- `godot --headless --path . -s res://tests/m29_realtime_movement_smoke.gd` → **PASS**
- `godot --headless --path . -s res://tests/m29_presentation_identity_evidence.gd` → **PASS**
- `godot --headless --path . -s res://tests/m29_hazard_bot_runtime_smoke.gd` → **PASS**
- `godot --headless --path . -s res://tests/m30_transaction_safe_retry.gd` → **PASS**
- `godot --headless --path . -s res://tests/m30_completion_authority.gd` → **PASS**
- `godot --headless --path . -s res://tests/m20_v10_lifecycle_smoke.gd` → **PASS**
- `godot --headless --path . -s res://tests/m20_queue_free_smoke.gd` → **PASS**
- `git diff --check` → clean (only benign LF→CRLF notice)

## 15. Handoff

**AWAITING_AUDIT / M32-C001 V01 / OWNER_F6_REQUIRED**

Root `TASKS.md` was not edited (ChatGPT-write-owned). No audit verdict was authored by Claude.
