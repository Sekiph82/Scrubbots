# M20-C001 V08 — Final Whole-Sprint Validation-Only Gate

You are Claude, implementer/test runner only. ChatGPT owns independent audit verdicts and task closure.

Canonical repository:
`https://github.com/Sekiph82/Scrubbots`

Canonical live tracker:
repository-root `TASKS.md` ONLY.

Read first:
- `TASKS.md`
- `CLAUDE.md`
- `AGENTS.md`
- `coordination/AUDIT_POLICY.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V07.md`
- `coordination/sessions/M20-C001/CHATGPT_FULL_SURFACE_REAUDIT_V08.md`
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_CRITERIA_V08.md`
- current M20 V01-V07 tests/logs only as regression references.

This is a **VALIDATION-ONLY** gate for gameplay production.

## 0. GitHub-first tracker start gate

Expected initial canonical state:
- milestone M20;
- task/sprint M20-C001 V07;
- status AWAITING_AUDIT;
- required actor CHATGPT;
- progress 290/719 main+ui;
- overall 290/943;
- lastCompletedTaskId M19-C001-V06;
- all SB-M20-001..014 `[ ]`.

BEFORE any V08 test/smoke/doc edit or temporary sensitivity mutation:
1. sync `origin/main` safely, preserving owner/local work;
2. set root `TASKS.md` Project Status only to:
   - Current Sprint: `M20-C001 V08 — final whole-sprint validation-only gate`;
   - Current Task: `M20-C001-V08`;
   - Current Task Status: `IN_PROGRESS`;
   - Required Actor: `CLAUDE`;
   - Next Task/Action: execute the full V08 validation-only gate and return to ChatGPT;
   - progress/lastCompleted unchanged;
3. commit tracker-only start transition;
4. push to `origin/main`;
5. verify remote start transition;
6. record that NO V08 test/smoke/doc edit and NO temporary production mutation existed before that successful push.

If safe sync is blocked by owner/local work, STOP `BLOCKED` without restoring/resetting it.

## 1. Production immutability lock

Before validation record exact current blobs:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` expected `06391839523cbc27e88a4b3ef12b730012cd45fa`;
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` expected `eee10149e4f116af6706beec832042352bf3a6dd`.

No committed `scripts/**` change is authorized in V08.

Temporary sensitivity mutations are allowed only after the start push, one at a time, and MUST be restored exactly before another mutation/final suite. If any real production defect is exposed, DO NOT FIX IT in V08. Set tracker `BLOCKED / CHATGPT`, record `V08_VALIDATION_EXPOSED_PRODUCTION_DEFECT`, push validation evidence, and stop.

## 2. Fresh auditor-authored validation section

Add a clearly named fresh V08 block such as:
`_run_m20_v08_auditor_validation_tests()`.

Do NOT merely call V07 aggregate functions. Reuse low-level wiring helpers when sensible, but use fresh boards/arrangements and direct assertions.

## 3. Single M20 owner / claim lifecycle

Freshly prove:
- one healthy loop binds;
- benign diagnostic `assignment_arrived` observer does not block it;
- second live loop on same dispatcher fails bind and adds no M20 transaction connection;
- first loop remains coherent;
- second loop cannot activate/reset canonical state;
- one real arrival gives first loop exactly one clear/count increment;
- owner loop `reset()` while still alive does NOT release the claim;
- a second loop remains rejected after owner reset;
- after the owner loop reference is genuinely released and its callback disappears, a fresh loop can claim once;
- no strong-cycle leak keeps old loop alive.

If true GC/frame behavior needs a dedicated SceneTree smoke, create `tests/m20_v08_lifecycle_smoke.gd`.

## 4. `agent_parent` lifecycle validation

Freshly cover:
- omitted -> self;
- explicit null -> self;
- wrong scalar/object -> bind false;
- healthy explicit Node -> agent attaches there;
- queued explicit Node -> bind false;
- truly-freed explicit Node before bind -> bind false/no SCRIPT ERROR/no self fallback;
- explicit parent queued or freed from a bind-time coherence callback -> bind false and dispatcher remains unbound;
- healthy bind, then explicit parent truly destroyed before dispatch -> dispatch fails closed, no current reservation, no active/orphan agent;
- explicit factory default/invalidated law remains unchanged.

Use a narrow existing callback seam or test support only; do not modify production.

## 5. Renderer lifecycle validation

Freshly prove:
- omitted and explicit-null headless success;
- representative int/float/String/Vector2/container/RefCounted/wrong Node rejection;
- queued renderer before bind rejection;
- truly-freed renderer before bind rejection;
- failed-bind metadata/claim recovery on same loop;
- second bind refusal preserves original configured renderer expectation;
- prove preservation both by foreign-board drift AND queued/dead original renderer;
- foreign renderer after bind -> activation fails before new dispatch;
- real assignment then renderer queued before arrival -> no clear, candidate still present, exact reservation+dispatcher assignment held, cleared_count unchanged;
- real assignment then renderer truly freed before arrival -> same no-clear law;
- explicit reset cleans only allowed pair/agent afterward;
- healthy renderer clear -> target alpha 0, unrelated pixel unchanged;
- headless clear works.

## 6. Direct M20 arrival-preflight desynchronization matrix

For each case create a fresh real pending-arrived assignment where needed. Temporarily disconnect the loop arrival callback only when necessary to reach ARRIVED without auto-clearing, then call the M20 boundary directly and clean up safely.

Independently test:
1. wrong owner;
2. wrong target;
3. wrong color;
4. wrong source agent;
5. unknown owner;
6. missing reservation;
7. same original board: release original `(T,O)`, reserve the SAME T for a DIFFERENT owner `O2`; inject original arrival; M20 must reject and later reset must preserve `T->O2`;
8. ReservationState `rebind(foreign_board)`, create a foreign replacement reservation, inject original arrival; M20 rejects; later reset must preserve foreign reservation;
9. ColorCandidateIndex `rebind(foreign_board)` before arrival; M20 rejects, board/reservation/dispatcher current attempt untouched until explicit reset;
10. ColorCandidateIndex `rebind(null)` before arrival (neutralized/unbound); M20 rejects cleanly;
11. target externally CLEARED before arrival;
12. renderer foreign-board;
13. renderer queued/dead;
14. stale replay after reset;
15. duplicate current/queued completion.

For every reject take direct before/after observations appropriate to the case:
- BoardState target and unrelated cell state;
- cleared_count;
- candidate target/unrelated candidate membership;
- dispatcher owner presence;
- exact reservation/replacement/foreign reservation;
- active/orphan agent cleanup only after explicit reset.

No failed M20 preflight may silently finalize or erase foreign/replacement ownership.

## 7. Activation public-boundary matrix with per-case snapshots

Do NOT run a batch of invalid inputs and assert only one final aggregate snapshot.

For EACH case below, create a fresh attempt or take/compare an exact detached snapshot immediately around the call:
- slot -1;
- slot 5;
- non-int slot;
- unavailable slot;
- origin NaN x;
- origin NaN y;
- origin +INF;
- origin -INF;
- speed NaN;
- speed +INF;
- speed -INF;
- speed 0;
- speed negative;
- absent color/no target;
- enclosed matching target;
- nested activation;
- activation while arrival drain active;
- reset during activation preflight;
- reset inside M19 dispatch;
- post-dispatch M20 coherence loss.

Snapshot/check as applicable:
- BoardState states;
- dispatcher active count;
- next owner id;
- exact reservation owner map/count;
- five slots' palette/availability/activity fields.

For failures that legitimately consume an owner token before a downstream reset/coherence barrier, assert monotonic/no-reuse rather than incorrectly requiring unchanged owner id.

Also include one ordinary valid finite activation as control.

## 8. Fresh SB-M20-001..014 final ledger

In V08 fresh arrangements, directly prove every row:
- 001 healthy complete synchronized tuple;
- 002 no-target + enclosed no bot;
- 003 frame-aware no-return/deferred disappearance/no orphan;
- 004 true 1x1 and exhaustion;
- 005 one-color repeated clearing to exhaustion;
- 006 multi-color correct slot/color clearing with no cross-color corruption;
- 007 five simultaneous/in-flight successful assignments with unique owners, distinct targets, exact pairs; one resolves preserving four; all eventually resolve;
- 008 Easy representative;
- 009 Medium representative;
- 010 Hard representative;
- 011 Very Hard representative;
- 012 59x59 max;
- 013 valid rectangular production board;
- 014 use the fresh V08 desync/reset/duplicate/rollback matrix.

Also prove:
- AL-028 A blocks B; clear A; SECOND REAL activation selects/routes B; B clears;
- >=25 sequential activate/arrival/clear cycles;
- reset with multiple in-flight assignments;
- M20 does not mutate slot palette/availability/activity;
- CompleteClearingLoop does not add a normal-path BoardState full scan.

## 9. Rollback/reset/contention fresh high-risk arrangements

Freshly exercise or independently rearrange:
- candidate mutate-before-false;
- reservation mutate-before-false;
- candidate true-without-postcondition;
- reservation true-without-postcondition;
- unrelated same-color candidate loss;
- unrelated reservation identity swap;
- exact owner-map rollback or explicit ROLLBACK_FAILED;
- reset during candidate phase;
- reset during reservation phase;
- duplicate current arrival;
- distinct nested FIFO;
- pair-narrow reset original pair + unrelated pair;
- foreign-board replacement survives;
- same-board owner replacement survives;
- post-dispatch generation barrier.

Keep all exact production category gates unchanged; use existing test-only harness seams only.

## 10. Sensitivity mutations — mandatory

Run after start push, one at a time, restore exactly each time.

S1 consumer claim bypass:
- force different consumers to be accepted;
- named second-loop test must fail for intended reason.

S2 `agent_parent` equality/null regression:
- use equality/null presence instead of captured Variant presence;
- truly-freed explicit-parent frame test must fail.

S3 renderer equality/null regression:
- use equality/current-reference presence instead of `_renderer_expected`;
- truly-freed configured-renderer test must fail.

S4 post-dispatch generation barrier removal/reordering:
- reset-inside-M19-dispatch test must expose stale-success regression.

S5 reservation owner-map proof weakened to count-only:
- identity-swap adversary must fail for intended reason.

S6 pair-narrow dispatcher reset weakened to owner-wide release:
- foreign/same-board replacement preservation test must fail for intended reason.

Record exact mutation, exact failing test names/messages/counts, restore proof and production blob after each. Never commit mutations.

## 11. Documentation-only correction

Gameplay production remains immutable.

Correct the current non-historical stale paragraph in `docs/02_TECH_ARCHITECTURE.md` under/around "What is explicitly NOT built yet":
- do not say M14 reservation, M15 TargetSelector, M16/M17 routing or M18/M19 Scrubbot/dispatcher are future;
- do not say M10 ACTIVE/CLEARED owner QA is pending if current TASKS says complete;
- accurately state the current M20 boundary and what remains future (M21+ content/UI/etc.) without inventing design decisions;
- use root `TASKS.md` casing for current tracker references where you touch the text.

Do not rewrite historical audit/prompt evidence.

## 12. Final immutable-production validation

After ALL temporary mutations are restored:
- verify clearing-loop blob exactly `06391839523cbc27e88a4b3ef12b730012cd45fa`;
- verify dispatcher blob exactly `eee10149e4f116af6706beec832042352bf3a6dd`;
- prove committed `scripts/**` diff vs V07 implementation commit is EMPTY;
- run `godot --version`;
- run full root suite;
- run queue-free smoke;
- run V04 lifecycle smoke;
- run V05 lifecycle smoke;
- run V07 lifecycle smoke;
- run V08 frame-aware smoke if created;
- record zero final SCRIPT ERROR / Parse Error;
- run `git diff --check`;
- record exact changed files and scope grep.

## 13. Handoff

If all validation is clean:
- do NOT close any SB-M20 checkbox;
- do NOT mark COMPLETE/READY_FOR_NEXT_TASK;
- set root tracker to `M20-C001-V08 / AWAITING_AUDIT / CHATGPT`;
- keep progress 290/719 and 290/943, lastCompleted M19-C001-V06;
- write `coordination/sessions/M20-C001/CLAUDE_LOG_V08.md`;
- commit/push allowed validation tests/smoke/doc/log/tracker only;
- verify remote;
- return exactly `AWAITING_AUDIT` and stop.

If ANY validation exposes a production defect:
- DO NOT fix production;
- set tracker `BLOCKED / CHATGPT` with blocker `V08_VALIDATION_EXPOSED_PRODUCTION_DEFECT`;
- preserve/push the failing validation evidence without committing the temporary mutation;
- return `BLOCKED` and stop.