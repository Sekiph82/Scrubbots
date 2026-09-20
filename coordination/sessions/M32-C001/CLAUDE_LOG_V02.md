# M32-C001 V02 — Claude Implementation Log

Milestone: `M32 — Scrubbot Final Visuals [VISUAL REFERENCE]`
Actor: Claude (Opus 4.8)
Status handoff: **AWAITING_AUDIT / M32-C001 V02 / OWNER_F6_REQUIRED**

## 1. Scope

V01 was architecturally accepted (`CHATGPT_AUDIT_V01.md`). V02 closes the single blocking
evidence defect **F-M32-V01-001** (density/performance evidence not valid enough for closure).
No visual redesign: the accepted V01 Scrubby architecture — `ScrubbotVisual` component, agent
factory injection, authoritative agent movement, `authenticated_clear` retire echo, M31
coexistence, Retry reset, no-new-AI-art — is preserved unchanged. No new AI art generated.

## 2. Commits

- Implementation/test commit: **2c48e30** — `test(M32-C001 V02): 59x59 Scrubby visual scale + animation-cost benchmark`
- Documentation commit (this log): see the following commit on `main`.
- Branch `main` (`Sekiph82/Scrubbots`), fast-forwarded from `f3dee92`→`260c21e` before work; no
  force-push / reset / destructive cleanup. Pre-existing local owner work (`project.godot`,
  untracked `.import`/`.uid`) preserved and left out of the M32 commits.

## 3. Correction of the V01 "395 live visuals" figure

**The V01 log's "peak simultaneous live Scrubby visuals: 395 (1x/2x)" was an invalid/ambiguous
measurement and is withdrawn.** It counted children of `AgentLayer` inside tight synchronous
`runtime.tick(1.0)` loops that never yielded a SceneTree frame. The accepted M19/M20 finalization
path removes a completed assignment with `queue_free()`, whose deletion is **deferred** until the
SceneTree reaches its idle deletion point. With no frame processed inside the loop, already-
finalized agents awaiting deferred deletion were still counted, so `395` conflated live gameplay
assignments with not-yet-freed corpses. It must not be read as true simultaneous live concurrency.

Corrected V02 accounting uses the **authoritative** `ScrubbotDispatcher.get_active_count()` /
`AutoDispatchScheduler.live_assignment_count()` for live concurrency, and processes deferred
`queue_free()` (awaiting SceneTree frames) before asserting final live-node counts.

## 4. New evidence: `tests/m32_scale_59_visuals.gd`

Reuses the accepted M26 59×59 / 30-in-flight production-scale fixture shape
(`tests/m26_scale_59_sanity.gd`), but binds the dispatcher with the **real M32 agent factory** +
an **in-tree AgentLayer**, so every one of the `BATCH = 30` concurrently-live agents carries a real
`ScrubbotVisual` on the canonical shared Scrubby texture.

It proves, on a 59×59 board (3481 cells):

1. **59×59 context** — full production board envelope, `BATCH = 30` bottom-row ACTIVE cells
   (M26 reference bound), rest CLEARED for real-but-bounded deterministic density.
2. **Authoritative live population** — exactly 30 assignments; `dispatcher.get_active_count() == 30`
   and `sched.live_assignment_count() == 30` (not a tree-child count).
3. **Real visuals** — all 30 live agents carry a `ScrubbotVisual` whose body sprite built from the
   canonical `scrubby_gameplay.png`.
4. **Shared texture** — all 30 visuals return the SAME `Texture2D` object (no per-agent decode).
5. **Measured animation-update cost** — timed `ScrubbotVisual.animate(delta)` over the whole live
   population for many deterministic frames with `Time.get_ticks_usec()`.
6. **1x and 2x-equivalent** — 600 frames (1x) and 1200 frames (2x-equivalent: at 2× game speed
   twice as many travel frames elapse per real second → double the per-second animation workload).
7. **Correct cleanup** — drain authenticates all 30 clears, then deferred `queue_free()` is
   processed via awaited SceneTree frames BEFORE asserting: live assignments = 0, live agent
   presentation nodes = 0, active echoes = 0, zero ACTIVE cells; `sched.reset()` idempotent-zero.
8. **Retire echo bound** — 30 clears > cap 16, so echoes hit the cap exactly, overflow is
   presentation-only (counted `suppressed`), and cleanup returns to zero.

## 5. Measured values (headless, this environment)

```
SCALE59_VIS visuals=30
  1x: frames=600  total=19.536 ms  per_frame=0.03256 ms
  2x: frames=1200 total=40.286 ms  per_frame=0.03357 ms
  per_visual_per_frame = 1.0853 us
```

Interpretation:
- Per-frame cost to animate the entire 30-visual live population is ~**0.033 ms/frame** (~1.09 µs
  per visual per frame). At 30 concurrent bots this is a negligible fraction of any per-frame
  budget; the 2×-equivalent case is linear (≈2× the frames ⇒ ≈2× the total, identical per-frame).
- No physical-device FPS is claimed — only what the headless test environment measures.

## 6. Pooling / optimization decision (from evidence)

**No pooling or further optimization is required.** The measured per-frame animation cost is
~0.033 ms for the full accepted-scale live population, the texture is shared (one decode for all
bots), and the retire echo is hard-capped. Adding an object pool would be speculative complexity
against a workload already ~1 µs/visual/frame. Decision: keep the simple allocate-and-free path
(consistent with M31), revisit only if a future measured workload proves otherwise.

## 7. Documentation cleanup

`scripts/gameplay/agents/scrubbot_agent.gd` header sentence "owns NO child nodes" was corrected to
note that a presentation-only `ScrubbotVisual` child may be attached and is freed together with the
agent (no gameplay identity, no-orphan guarantee unchanged). No gameplay behavior changed.

## 8. Regression commands / results

All green:

- `godot --headless -s res://tests/m32_scale_59_visuals.gd` → **PASS** (measured values §5)
- `godot --headless -s res://tests/m32_scrubbot_visual_evidence.gd` → **PASS**
- `godot --headless -s res://tests/m26_scale_59_sanity.gd` → **PASS**
- `godot --headless -s res://tests/run_tests.gd` → **Failures: 0 / RESULT: ALL PASS** (exit 0)
- `godot --headless -s res://tests/m31_cleaning_effects_evidence.gd` → **PASS**
- `godot --headless -s res://tests/m31_scale_59_effects.gd` → **PASS**
- `godot --headless -s res://tests/m30_transaction_safe_retry.gd` → **PASS**
- `godot --headless -s res://tests/m30_completion_authority.gd` → **PASS**
- `godot --headless -s res://tests/m29_realtime_movement_smoke.gd` → **PASS**
- `godot --headless -s res://tests/m29_presentation_identity_evidence.gd` → **PASS**
- `godot --headless -s res://tests/m20_queue_free_smoke.gd` → **PASS**
- `godot --headless -s res://tests/m20_v10_lifecycle_smoke.gd` → **PASS**
- `git diff --check` → clean (only benign LF→CRLF notice)

## 9. Known limitations

- The measurement is a headless GDScript benchmark of `animate()` over the live population; it is
  intentionally not a device-FPS figure. The 30-bot bound follows the accepted M26 production-scale
  reference; if a future owner/scale decision raises the concurrency bound, re-run with that bound.
- V01 visual-design limitations are unchanged (single gameplay pose; blink/brush layers deferred
  for lack of owner registration offsets; no directional art). V02 is evidence-only.

## 10. Handoff

**AWAITING_AUDIT / M32-C001 V02 / OWNER_F6_REQUIRED**

Root `TASKS.md` not edited (ChatGPT-write-owned). No audit verdict authored by Claude.
