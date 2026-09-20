# M32-C001 V01 — ChatGPT Code Audit

Date: 2026-09-20  
Repository: `Sekiph82/Scrubbots`  
Milestone: `M32 — Scrubbot Final Visuals`  
Auditor: ChatGPT

Implementation SHA: `19c1c9887447c58fde20735e8d12638468d6ddfd`  
Claude log commit: `1be851ecad109118e93b8d14a1f450ae926f35ae`  
Claude log: `coordination/sessions/M32-C001/CLAUDE_LOG_V01.md`  
Audit authority: `coordination/sessions/M32-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`

## Verdict

**CHANGES_REQUIRED / M32-C001 V01**

The core visual architecture is sound and the implementation preserves the accepted gameplay-authority boundaries, but the mandatory density/performance evidence is incomplete and one reported density number is not a reliable live-concurrency measurement.

Do **not** proceed to the formal owner F6 closure gate yet. Close the focused V02 evidence gap first.

## What passed

### Canonical asset authority — PASS

M32 uses the existing owner-approved `assets/ui/final/characters/scrubby/scrubby_gameplay.png`. No new AI art was generated. The existing Scrubby family and provenance were audited rather than regenerated.

### Gameplay/presentation separation — PASS

`ScrubbotVisual` is a presentation-only child of `ScrubbotAgent`. Bob/lean/squash modify the local Sprite2D only. The authoritative agent route position, progress, speed and completion path remain unchanged.

### Arrival/disappearance lifecycle — PASS

`ScrubbotRetireEchoController` observes the authoritative M20 `authenticated_clear` event and creates only a detached visual echo. It does not delay M20 finalization or own gameplay state.

### Debug fallback isolation — PASS

The canonical visual suppresses the legacy colored debug circle through the narrow `_visual_present` presentation flag. The fallback remains available only when the canonical visual cannot attach.

### Retry hygiene / echo cap — PASS

Retire echoes are bounded by a hard cap and are cleared/reset on successful Retry.

### Orientation decision — PASS

V01 correctly avoids route-dependent mirroring/rotation because no owner-approved directional rule exists.

### M31 coexistence architecture — PASS

M31 cleaning FX and the M32 retire echo are separate presentation observers/layers and neither changes gameplay truth.

## Blocking finding F-M32-V01-001 — density/performance evidence is not valid enough for closure

The master audit criteria require measured high-density evidence relevant to the production 59x59 envelope, including **travel-visual update cost**, 1x/2x behavior and bounded cleanup.

### A. The reported “395 live Scrubby visuals” is not a reliable live-agent measurement

The M32 integration test drives hundreds of `runtime.tick(1.0)` calls inside tight synchronous loops and counts children of `AgentLayer` without yielding a SceneTree frame inside those loops.

But the accepted M19/M20 finalization path removes completed assignments by calling `queue_free()` on the agent. A queued node is not actually freed until the SceneTree reaches the deferred deletion point.

Therefore the reported `peak simultaneous live Scrubby visuals: 395` can include already-finalized agents waiting for deferred deletion. It is not a trustworthy measurement of simultaneous live gameplay assignments/visuals and must not be used as M32 density evidence.

### B. Travel-animation update cost was not measured

The audit criteria explicitly require measured visual update/animation cost. The V01 test records counts but does not time the `ScrubbotVisual.animate()` / per-frame visual update workload. There is no measured ms/frame or equivalent benchmark for the new travel presentation.

### C. The density run does not actually exercise the visual process loop at 1x/2x

During the tight density loops there is no `await process_frame`, and the test does not manually call `animate()` for every production visual in those loops. So the 1x/2x section exercises runtime/gameplay ticks and node accumulation, but not the actual per-frame M32 travel-animation work required by the audit.

### D. 59x59 M32 presentation evidence is missing

The repository already has an accepted 59x59 production-ceiling sanity fixture in `tests/m26_scale_59_sanity.gd`, using a bounded 30 in-flight workload on a 59x59 board. M32 should add presentation-focused scale evidence tied explicitly to that envelope instead of relying only on the 20x20 Hazard Bot host.

## Required V02 repair

Do not redesign the visual system. Keep the accepted V01 architecture.

Add a focused M32 V02 performance/density evidence test, preferably `tests/m32_scale_59_visuals.gd` or an equivalently clear path.

The V02 evidence must:

1. exercise a **59x59** board context;
2. use a realistic bounded concurrent-agent workload consistent with accepted production-scale evidence, with the existing M26 30-in-flight scale fixture as the default reference unless repository truth now proves another bound;
3. attach the real canonical `ScrubbotVisual` to every measured agent;
4. measure actual presentation-update cost over many deterministic animation frames using `Time.get_ticks_usec()` or the repository benchmark style;
5. report total and per-frame update timing without inventing physical-device FPS;
6. prove shared texture identity across the measured visual population;
7. prove cleanup returns live visual/agent counts to zero after real SceneTree/deferred cleanup;
8. include 1x and 2x-equivalent animation/event-density coverage that actually advances presentation work;
9. keep retire echoes bounded and prove cleanup;
10. explain whether pooling or further optimization is required from the measured evidence.

Also correct the V01 log interpretation of the `395` figure in `CLAUDE_LOG_V02.md`. Do not silently repeat it as true live concurrency.

## Optional cleanup

The top comment in `scrubbot_agent.gd` still says the agent “owns NO child nodes,” which is no longer literally true now that the production agent can contain `ScrubbotVisual`. Update that stale comment if you touch the file, but do not turn this into a gameplay rewrite.

## Regression floor for V02

Run at least:

- new 59x59 M32 visual performance/density evidence;
- `tests/m32_scrubbot_visual_evidence.gd`;
- root `tests/run_tests.gd`;
- M31 focused evidence;
- M30 Retry/completion evidence;
- M29 movement/presentation evidence;
- M20 queue-free/lifecycle evidence;
- existing `tests/m26_scale_59_sanity.gd`;
- `git diff --check`.

## Handoff

After V02 is committed and pushed, write `coordination/sessions/M32-C001/CLAUDE_LOG_V02.md` in a separate documentation commit.

Expected handoff:

`AWAITING_AUDIT / M32-C001 V02 / OWNER_F6_REQUIRED`

## Verdict string

`CHANGES_REQUIRED / M32-C001 V01`