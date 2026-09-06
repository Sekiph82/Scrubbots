---
coordinationSchema: scrubbots-coordination/v4
artifactType: claude-log
cycleId: M18-C001
version: 01
actor: CLAUDE
status: AWAITING_AUDIT
promptUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M18-C001/CHATGPT_PROMPT_V01.md
criteriaUrl: https://github.com/Sekiph82/Scrubbots/blob/main/coordination/sessions/M18-C001/CHATGPT_AUDIT_CRITERIA_V01.md
startingCommit: def36d03e019fb17c6d365ddc4d51ce6dc187df8
currentCommit: uncommitted-at-write-time
---

# SCRUBBOTS - Claude Log V01

Evidence for exactly CHATGPT_PROMPT_V01.md (M18-C001). Claude does not audit
itself. Scope: SB-M18-001..015 — the lightweight ScrubbotAgent. No M19
Dispatcher, no M20 vertical slice.

## Inputs read

- CLAUDE.md (incl. all owner overrides; §3 locked params, §4 module boundary).
- coordination/sessions/M18-C001/CHATGPT_PROMPT_V01.md, CHATGPT_AUDIT_CRITERIA_V01.md.
- coordination/sessions/M17-C002/CHATGPT_AUDIT_V01.md (M17 production routing audited complete).
- docs/05_TECH_DECISIONS.md (ADR-024 M16 contract, ADR-025 production routing).
- scripts/gameplay/routing/route_result.gd, route_request.gd (the consumed contract).
- scripts/gameplay/routing/production_routing_system.gd, production_access_query.gd.
- scripts/gameplay/routing/prototypes/routing_lab_scenarios.gd (deterministic scenario/route builders reused for tests).
- scripts/gameplay/board/board_state.gd, targeting/reservation_state.gd, data/palette_colors.gd.
- tests/run_tests.gd (headless harness convention).

## Repository start state

- Branch `main`, synced to `origin/main` via `git fetch` + `git merge --ff-only`
  (0 ahead / 13 behind → fast-forwarded to `def36d03`). No destructive ops.
- Owner-modified tracked files present at start and PRESERVED untouched:
  `project.godot`, `scenes/debug/routing_prototype_lab.tscn`. Verified the 13
  incoming commits do not touch these before fast-forwarding.
- Numerous untracked owner artifacts (`*.uid`, `_owner_inbox/*.import`,
  `docs/logs/`, a stray scratchpad file) left untouched.
- Baseline headless suite before any change: **1412 checks, 0 failures**.

## Prior audit feedback / AL learnings applied

- ADR-009 explicit `preload()` (no bare `class_name`) for new gameplay scripts.
- Board-local coordinate space per route_request.gd (no baked screen pixels).
- ADR-024 no-retarget: agent rejects a route whose `target_index` differs from
  the assigned request target.
- Renderer/quantization AL is renderer-specific; N/A here (no pixel readback).

## Work performed

New:
- `scripts/gameplay/agents/scrubbot_agent.gd` — lightweight `Node2D`, one
  in-flight movement. `assign()` fails closed on invalid owner/color/target,
  failed route, target mismatch, <2 points, spawn-origin mismatch, endpoint
  mismatch, non-positive speed. Route-distance based `advance(delta)` +
  `_process`; exact endpoint snap; `agent_completed` once; idempotent `cancel()`;
  no child/tween/timer nodes; detached route copies. Assigned color is identity
  metadata only — no carry/return/deliver/dispatch/select/route API.
- `scripts/debug/scrubbot_agent_debug.gd` + `scenes/debug/scrubbot_agent_debug.tscn`
  — throwaway visual harness driving one agent along a real S2 production route
  under a scaled container (units→px in the container, not the agent). NOT M27 art.

Changed:
- `tests/run_tests.gd` — added ScrubbotAgent preload; `_run_m18_agent_tests`,
  `_run_m18_agent_stress_tests`, `_run_m18_agent_debug_scene_smoke`. Updated the
  M11-27 "no agents directory" guard to assert the agent now legitimately exists
  (same supersession pattern already used for the M16 routing guard).
- `docs/05_TECH_DECISIONS.md` — ADR-026 (ScrubbotAgent movement-only consumer;
  board-local movement/presentation boundary; pooling deferred). ADR-025 intact.

## Files changed

- A scripts/gameplay/agents/scrubbot_agent.gd
- A scripts/debug/scrubbot_agent_debug.gd
- A scenes/debug/scrubbot_agent_debug.tscn
- M tests/run_tests.gd
- M docs/05_TECH_DECISIONS.md
- A coordination/sessions/M18-C001/CLAUDE_LOG_V01.md

Owner-modified `project.godot` / `routing_prototype_lab.tscn` and untracked owner
artifacts deliberately NOT staged. `.uid` files not committed (repo convention:
none are tracked; Godot regenerates them).

## Validation evidence

Environment: `godot --version` → **4.7.1.stable.official.a13da4feb**.
Full headless run: `godot --headless --path . -s res://tests/run_tests.gd`
→ **1483 checks, 0 failures, RESULT: ALL PASS**. No leaked-RID / leaked-ObjectDB
warnings from M18 code (unfreed throwaway test agents fixed; the ERROR/WARNING
lines that remain are pre-existing deliberate corrupt-file importer tests and a
layout anchor warning). `git diff --check` clean (only LF→CRLF advisories).

Prompt "Required tests" 1–38 mapped to actual checks (all CLAUDE_TEST_PASS):

1. valid assignment succeeds — `valid assignment succeeds` / `-> MOVING`.
2. invalid owner rejected — `_m18_reject(-1,...)`.
3. invalid color rejected — `_m18_reject(0,-1,...)`.
4. invalid target rejected — bad_target `target_index=-1`.
5. failed RouteResult rejected — `RouteResult.failure(NO_ROUTE)`.
6. route target mismatch rejected — `success_route(target+777)`.
7. spawn origin mismatch rejected — first point shifted.
8. assigned color retained — `color_id==3`.
9. assigned target retained — `target_index==req.target_index`.
10. detached route retained safely — mutating `get_route_points()` copy does not leak.
11. movement begins at spawn origin — position == pts[0].
12. small delta advances — progress in (0,1).
13. large delta multi-segment — 0.5 in one advance == 50×0.01 (distance-based, not point-skip).
14. zero delta no move — position & progress unchanged.
15. endpoint reached exactly — position == pts[-1].
16. arrival emitted once — signal hits.size()==1 after over-advancing.
17. completion identity — (owner=0, target, color=3).
18. BoardState not mutated — snapshot equal after full run.
19. ReservationState not mutated — reserved owner still 0.
20. no return after arrival — position stays at endpoint on further advance.
21. no resource-carry/return API — no get_carried_color/get_payload/deliver/return_to_slot.
22. cancel before arrival stops movement — position frozen after cancel.
23. cancel prevents completion — 0 signals, never ARRIVED.
24. repeated cancel safe — cancel();cancel() still 0 signals.
25. free cancelled → no orphan — child_count==0 then free.
26. free completed → no orphan — child_count==0 then free.
27–30. 5 / 10 / 25 / >25(40) concurrent — all arrive, one signal each, no orphans.
31. deterministic repeat — two agents, identical delta seq, positions equal each step.
32. 59×59 route compatibility — S7 route assigned, exact endpoint.
33. rectangular Very Hard — S8 53×59 route assigned and completes.
34. no TargetSelector call — no select_and_reserve/select_target.
35. no route computation — no compute_route on agent.
36. no Dispatcher — no dispatch/dispatch_next; no dispatcher file added.
37. full Godot 4.7.1 suite passes — 1483/0.
38. debug scene smoke — scene loads, builds one agent, MOVING → arrives, signal received.

Performance (headless CPU only, NO FPS/GPU claim), route-compute + full move to
arrival for all agents:
- 5 agents ≈ 11.7 ms
- 10 agents ≈ 21.8 ms
- 25 agents ≈ 66.7 ms
- 40 agents (>25) ≈ 159.8 ms

Pooling (SB-M18-015): **NOT justified yet** — agent is a childless Node2D with no
per-frame allocation; create/assign/run/free of up to 40 concurrent agents showed
no materially problematic lifecycle cost. Deferred to real Dispatcher (M19)
profiling. Recorded in ADR-026 and printed by the stress test.

## Failures and fixes (kept for history)

1. Existing `M11-27: no agents directory` guard failed once the agents module was
   added — expected. Updated it to assert the agent file now exists (mirrors the
   M16 routing-guard supersession). Not an erased failure: the guard was
   legitimately superseded by M18 scope.
2. Stress "completion signal fired once per agent" reported 0 — the counter was a
   plain `int` captured by value inside the signal lambda (GDScript captures
   primitives by value). Fixed by counting into an `Array` (by-ref).
3. Godot reported leaked CanvasItem RIDs / ObjectDB instances — throwaway
   rejection-path agents (`ScrubbotAgent.new().assign(...)`) were unparented
   Nodes never freed. Added `_m18_reject()` helper that frees them; leaks gone.

## Task/docs/coordination/H!veAI updates

- Per M10-C001 V05 ownership normalization: Claude did NOT modify `tasks.md`,
  `.hiveai/*`, `coordination/SESSION_INDEX.md`, `coordination/AUDIT_INDEX.md`, or
  any CHATGPT audit file. ChatGPT owns those after audit.
- Docs: added ADR-026 to `docs/05_TECH_DECISIONS.md` (durable M18 architecture
  choice). ADR-025 unchanged.

## Commit and push evidence

Staged only the six M18 files listed above. Commit + push recorded in the PR/push
receipt; per the non-self-referential final SHA rule this log is not re-committed
to embed its own commit SHA.

## Handoff

Status: **AWAITING_AUDIT**. Independent audit (diff/code/tests, optional Godot
rerun) is ChatGPT's step. Godot was rerun locally here (4.7.1, 1483/0); ChatGPT
should disclose if it does not independently rerun.
