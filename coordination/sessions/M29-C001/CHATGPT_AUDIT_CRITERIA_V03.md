# M29-C001 V03 — Graphical Presentation Identity Criteria

Cycle: `M29-C001 V03`
Blocking finding: `F-M29-MANUAL-001`

## 1. Stable renderer identity
After GameplayScreen configuration, any number of `relayout()` calls must preserve exact:
`presentation.get_renderer()` object identity.

No duplicate BoardRenderer children.

## 2. Stable AgentLayer identity
Any number of relayouts must preserve exact:
`presentation.get_agent_layer()` object identity.

No duplicate AgentLayer children.

## 3. Geometry update, not node replacement
Relayout may:
- reconfigure existing renderer size/cell size;
- reposition BoardPresentation;
- rescale existing AgentLayer;
- update rail geometry.

Relayout must not replace the runtime-bound renderer or agent layer.

## 4. Live agent survives relayout
Spawn or attach a real moving ScrubbotAgent, relayout/resize while it is in flight, and prove:
- same agent instance remains alive;
- same parent AgentLayer;
- same board-local route/progress truth;
- presentation transform updates safely.

## 5. Visible clear coherence
Bind the real M20 path to the renderer used by the production screen.
After an authenticated clear:
- BoardState cell is CLEARED;
- `presentation.get_renderer()` is the SAME renderer M20 is bound to;
- that renderer's corresponding pixel alpha is 0.

This must be checked after at least one relayout.

## 6. Owner viewport regression
Direct evidence at:
- 1080×2160;
- 683×1366.

Exercise a resize/relayout transition and repeat identity/clear checks.

## 7. Real SceneTree clock smoke
Add a production-style smoke that leaves `ProductionRuntimeController` processing enabled and advances real SceneTree frames. Do NOT drive progress by directly calling `runtime.tick()` in this test.

At 683×1366:
- a successful front activation creates committed work;
- at least one real ScrubbotAgent progress value increases across subsequent frames;
- the agent arrives within a bounded real-frame interval;
- committed count decreases/finalizes through the normal M20/M25 chain;
- the CURRENT visible renderer pixel becomes transparent;
- runtime is not spuriously system-suspended while the embedded game viewport is actively focused.

If focus/background suspension is intentionally triggered, focus regain must resume movement without stale input.

## 8. Full production smoke
Real M29 Hazard Bot runtime:
- 400 authenticated clears;
- final ACTIVE=0;
- no ghost;
- no duplicate target;
- M23 exhausted;
- auto-2x preserved.

## 9. Preserve accepted gameplay
Do not rewrite M23–M27, M29 input gate, speed authority, pause/focus or exact visible slot-origin mapping.

## 10. Governance
- root TASKS read-only for Claude;
- no M30 implementation;
- implementation commit first;
- `CLAUDE_LOG_V03.md` separate final commit;
- zero AI image generation.
