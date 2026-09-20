# M32-C001 V02 — Performance / Density Evidence Repair Prompt

Repository: `Sekiph82/Scrubbots`  
Branch: `main`

V01 implementation is architecturally accepted, but the audit found one blocking evidence defect.

Read first:

- `coordination/sessions/M32-C001/CHATGPT_AUDIT_V01.md`
- `coordination/sessions/M32-C001/CHATGPT_AUDIT_CRITERIA_V02.md`
- `coordination/sessions/M32-C001/CLAUDE_LOG_V01.md`
- `tests/m32_scrubbot_visual_evidence.gd`
- `tests/m26_scale_59_sanity.gd`

## Scope

Do **not** redesign M32. Keep the canonical Scrubby visual component, agent factory injection, authoritative agent movement, authenticated-clear retire echo, M31 coexistence, Retry reset, and the no-new-AI-art rule.

Fix only the performance/density evidence gap.

## Required work

Create a dedicated 59x59 M32 visual stress/benchmark test, preferably `tests/m32_scale_59_visuals.gd`.

The test must:

1. use a 59x59 board context;
2. create a realistic bounded population of concurrently live agents using the accepted production-scale pattern, with the existing M26 30-in-flight fixture as the default reference;
3. attach the real `ScrubbotVisual` to every measured agent;
4. prove all visuals share one canonical texture resource;
5. deterministically advance the presentation animation for many frames and time that work with `Time.get_ticks_usec()`;
6. report actual measured presentation-update ms/frame at 1x and a 2x-equivalent update/event-density case;
7. process SceneTree/deferred deletion before asserting final agent-node counts;
8. use authoritative live-assignment counts where available rather than treating every child awaiting `queue_free()` as live gameplay;
9. prove final agent visuals and retire echoes clean back to zero;
10. retain bounded retire-echo behavior;
11. record whether pooling/optimization is required from the measurement.

Correct the V01 density interpretation: the `395` count came from a tight loop that did not process deferred `queue_free()`, so it must not be described as true simultaneous live concurrency.

If useful, update the stale `scrubbot_agent.gd` header sentence claiming the agent owns no child nodes. Do not change gameplay behavior for that documentation cleanup.

## Regression floor

Run:

- new `tests/m32_scale_59_visuals.gd`;
- `tests/m32_scrubbot_visual_evidence.gd`;
- `tests/m26_scale_59_sanity.gd`;
- root `tests/run_tests.gd`;
- M31 focused tests;
- M30 Retry/completion tests;
- M29 movement/presentation tests;
- M20 queue-free/lifecycle tests;
- `git diff --check`.

Commit implementation/tests first.

Then write and commit separately `coordination/sessions/M32-C001/CLAUDE_LOG_V02.md`.

The V02 log must include exact measured values and the corrected interpretation of V01's `395` node count.

Do not edit root `TASKS.md`.

Final handoff:

`AWAITING_AUDIT / M32-C001 V02 / OWNER_F6_REQUIRED`