# M32-C001 V02 — ChatGPT Code Audit

Date: 2026-09-20  
Repository: `Sekiph82/Scrubbots`  
Milestone: `M32 — Scrubbot Final Visuals`  
Auditor: ChatGPT

V01 implementation SHA: `19c1c9887447c58fde20735e8d12638468d6ddfd`  
V02 evidence/fix SHA: `2c48e3022641c99c2324c1cfa265eff0a97bf657`  
Claude V02 log commit: `35068358bf037b3c722adb051277b8b9ab4ca7da`  
V02 criteria: `coordination/sessions/M32-C001/CHATGPT_AUDIT_CRITERIA_V02.md`

## Verdict

**CODE_AUDIT_PASS / M32-C001 V02 / OWNER_F6_REQUIRED**

V02 closes the sole blocking V01 finding `F-M32-V01-001`. The accepted V01 architecture remains intact and the missing 59x59 presentation/performance evidence is now adequate for the owner visual gate.

## V02 finding closure

### 1. 59x59 presentation-scale evidence — PASS

`tests/m32_scale_59_visuals.gd` uses the accepted M26 production-scale fixture shape: a 59x59 board with a deterministic bounded 30-in-flight population. This is explicitly tied to the existing production-ceiling evidence rather than the 20x20 Hazard Bot scene alone.

### 2. Real canonical Scrubby visuals — PASS

All 30 authoritative live assignments are created through the M32 factory shape and carry a real `ScrubbotVisual`. The test waits for `_ready()` so the actual canonical `scrubby_gameplay.png` body exists before measurement.

### 3. Correct live-concurrency accounting — PASS

The invalid V01 `395` child-node figure is explicitly withdrawn. V02 uses `ScrubbotDispatcher.get_active_count()` and `AutoDispatchScheduler.live_assignment_count()` as the live gameplay authority and proves both equal 30 before measurement.

### 4. Deferred queue_free cleanup — PASS

After all 30 authenticated clears, the test awaits SceneTree frames before inspecting remaining agent presentation nodes. It then proves authoritative assignment counts are zero and no non-queued live ScrubbotAgent presentation nodes remain.

### 5. Shared texture identity — PASS

Every measured visual uses the same canonical `Texture2D` object. No per-agent source-image decode or duplicate texture allocation is introduced.

### 6. Actual ScrubbotVisual animation timing — PASS

The benchmark directly executes the real `ScrubbotVisual.animate(delta)` work over the 30-visual population and measures it with `Time.get_ticks_usec()`.

Recorded headless values from Claude's V02 run:

- 30 visuals;
- 600-frame workload: `19.536 ms` total, `0.03256 ms/frame`;
- 1200-frame stress workload: `40.286 ms` total, `0.03357 ms/frame`;
- approximately `1.0853 µs / visual / frame`.

These are headless test-environment measurements only, not physical-device FPS claims.

### 7. 2x interpretation — PASS WITH NOTE

The 1200-frame case is acceptable as a conservative synthetic higher-workload presentation stress case, but it is not a literal model of the production 2x runtime.

In production, `ProductionRuntimeController` implements 2x by doubling the agent travel delta and halving dispatch cadence. `ScrubbotVisual._process()` itself still executes once per rendered process frame; it receives ordinary presentation delta rather than being explicitly called twice per real frame.

Therefore the V02 1200-frame result should be read as **synthetic doubled presentation work**, not as a claim that production 2x literally doubles ScrubbotVisual process calls per second. This does not block M32 because the synthetic test is conservative and the real owner F6 scene still exercises actual 1x/2x gameplay behavior.

### 8. Retire-echo bound / cleanup — PASS

Thirty committed clears exceed the hard echo cap of 16, proving saturation behavior. Overflow remains presentation-only, and explicit cleanup returns active echo/layer counts to zero.

### 9. Pooling decision — PASS

No pooling was added. Given the measured bounded workload, shared texture resource and ~0.033 ms/frame headless animation cost for 30 visuals, retaining the simple allocation/free path is justified. Revisit only if future device profiling or a higher approved concurrency bound provides contrary evidence.

### 10. Regression floor — PASS

Claude records green results for:

- `tests/m32_scale_59_visuals.gd`;
- `tests/m32_scrubbot_visual_evidence.gd`;
- `tests/m26_scale_59_sanity.gd`;
- root `tests/run_tests.gd`;
- M31 focused + 59x59 FX evidence;
- M30 Retry/completion;
- M29 movement/presentation;
- M20 queue-free/lifecycle;
- `git diff --check`.

The V02 commit diff was independently inspected. It adds only the focused evidence test plus a documentation-comment correction in `scrubbot_agent.gd`; it does not redesign gameplay or the accepted V01 visual architecture.

## Owner F6 gate now required

Run:

`res://scenes/debug/m32_scrubbot_visual_playtest.tscn`

Owner must visually verify at minimum:

1. canonical Scrubby appearance is correct;
2. gameplay scale is appropriate;
3. travel path visually follows the route without drift;
4. bob/lean/squash is restrained and readable;
5. disappearance echo is visible but not excessive;
6. M31 puff/sparkle coexists cleanly;
7. actual 1x and 2x both look acceptable;
8. BURST/high-density view remains readable;
9. RETRY leaves no stale Scrubby or echo;
10. no colored debug-circle fallback is visible in normal production play.

Blink/brush layer animation is not required for V01/V02 closure because no owner registration offsets exist for those differently sized canvases; Claude correctly did not guess alignment.

## Verdict string

`CODE_AUDIT_PASS / M32-C001 V02 / OWNER_F6_REQUIRED`