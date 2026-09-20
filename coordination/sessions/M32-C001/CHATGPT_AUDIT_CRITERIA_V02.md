# M32-C001 V02 — Focused Audit Criteria

Purpose: close only the V01 performance/density evidence gap identified in `CHATGPT_AUDIT_V01.md`.

The accepted V01 visual architecture is not to be rewritten unless the new measurements reveal a concrete defect.

## Required PASS conditions

### 1. 59x59 presentation-scale evidence

A dedicated M32 test must exercise the 59x59 production board envelope. Using the accepted M26 59x59 / 30-in-flight fixture shape is acceptable unless current repository truth proves a different production concurrency bound.

### 2. Real Scrubby visuals

Every measured live agent in the scale test must carry the real `ScrubbotVisual` using the canonical shared Scrubby texture.

### 3. Actual animation-update timing

Measure the actual M32 presentation update workload over many deterministic frames. The measurement must include calls equivalent to the real `ScrubbotVisual.animate(delta)` work for the measured population.

Report visual count, frame count, total elapsed ms, average presentation-update ms/frame, a 1x case and a 2x-equivalent case. Do not claim physical-device FPS.

### 4. Correct concurrency accounting

Do not count nodes merely because they remain children after `queue_free()` in a tight loop. If SceneTree-owned cleanup is part of the test, yield/process frames so deferred deletion actually occurs before asserting final live counts. Use authoritative dispatcher/scheduler live-assignment counts where appropriate.

### 5. Cleanup

After drain/reset and deferred deletion: live dispatcher assignments = 0, live agent presentation nodes = 0, active retire echoes = 0, and no stale visual callback/node survives.

### 6. Shared texture

All measured Scrubby visuals must share the same canonical Texture2D resource object. No per-agent source decode/allocation.

### 7. Echo bound

Retire echoes remain capped, overflow is presentation-only, and cleanup returns to zero.

### 8. Pooling decision

Pooling remains absent unless the new measured evidence proves it is needed. The V02 log must state the decision from evidence.

### 9. Regression

All V01 M32 correctness tests and the specified regression floor remain green.

### 10. Documentation correction

`CLAUDE_LOG_V02.md` must explicitly state that the earlier “395 live visuals” figure was an invalid/ambiguous node-tree measurement because deferred `queue_free()` cleanup was not processed inside the tight loop, and replace it with corrected V02 measurements.

## Successful verdict target

`CODE_AUDIT_PASS / M32-C001 V02 / OWNER_F6_REQUIRED`