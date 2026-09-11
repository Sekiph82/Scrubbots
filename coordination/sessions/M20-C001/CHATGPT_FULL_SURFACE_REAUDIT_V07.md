# M20-C001 — Whole-Sprint Full-Surface Re-Audit V07

Status: **CHANGES_REQUIRED / WHOLE-SPRINT FINDING SET FROZEN**

Authority:
- `coordination/AUDIT_POLICY.md` including owner-directed 2026-09-11 sprint-wide two-pass rule;
- `coordination/sessions/M20-C001/CHATGPT_AUDIT_V06.md`;
- root `TASKS.md` as sole live tracker.

This freeze is intentionally broader than the latest diff. It is the result of the mandatory two-pass audit over the entire M20 sprint and its immediate M19/M13/M14/M17 dependencies.

## Accepted architecture that V07 must preserve

- `CompleteClearingLoop` is the separate M20 cross-module orchestrator.
- BoardState owns physical ACTIVE/CLEARED truth.
- ColorCandidateIndex owns derived ACTIVE candidate truth.
- ReservationState owns ephemeral owner<->target truth.
- ScrubbotDispatcher owns assignment/agent identity and authenticated arrival.
- ProductionAccessQuery reads BoardState live; no second access cache.
- healthy clear order is BoardState -> candidate -> reservation -> dispatcher finalize -> renderer.
- renderer is presentation-only and optional headless gameplay is valid.
- V06 `_renderer_expected` null-vs-dead correction is accepted and must not regress.
- reset/generation, exact owner-map rollback, current-arrival dedup, distinct FIFO and pair-narrow reset remain.
- no M21+, win/lose/scoring/session completion, slot cooldown/queue/consumption policy.

## Frozen production correction A — single M20 transaction owner per dispatcher

Finding: `F-M20-STRICT-001.M`.

Two separate CompleteClearingLoop instances can currently bind the same healthy dispatcher while active count is zero, producing two transaction controllers on the same arrival signal/state bundle.

Required:
- add a dispatcher-owned single M20 arrival-consumer claim;
- claim identity must be non-owning/weak or equivalently cycle-safe;
- unrelated diagnostic signal observers must not count as the M20 transaction-owner claim;
- a first healthy loop may claim + connect exactly once;
- a second live loop against the same dispatcher must fail bind cleanly;
- second failure creates no second M20 arrival connection, commits no bundle, and does not affect the first loop;
- first loop remains coherent and can activate/clear/reset;
- failed claim/connect rolls back any just-created claim/connection safely;
- no global singleton/service locator.

A narrow M19 seam is allowed solely for this claim. Do not move clearing logic into M19.

## Frozen production correction B — explicit M19 agent_parent null-alias

Finding: `F-M20-STRICT-001.N` (upstream sibling exposed by the V05 Godot runtime fact).

Required:
- intentional default/explicit-null parent remains dispatcher `self`;
- any non-NIL explicit parent is a configured dependency;
- configured parent must be a live Node before coherence callbacks and again after them;
- truly-freed explicit Node must fail bind even if it compares `== null`;
- queued parent must fail bind;
- scalar/wrong-object explicit parent must fail cleanly if bind input is made untyped to preserve Variant identity;
- healthy explicit parent remains accepted and used;
- no silent fallback from invalid explicit parent to default self;
- preserve post-bind attach-time parent liveness gate;
- preserve explicit factory behavior.

Use a captured `parent_expected`/equivalent configuration bit derived from Variant type or another mechanism immune to freed-Object equality aliasing. Do not use `agent_parent != null` as configuration authority.

## Frozen evidence batch C — complete renderer lifecycle matrix

Directly close in one pass:
- omitted renderer;
- explicit null;
- int, float, String, Vector2, Array/Dictionary or equivalent representative non-object variants;
- arbitrary RefCounted;
- wrong Node;
- queued exact renderer before bind;
- truly-freed exact renderer before bind;
- healthy exact renderer;
- failed renderer bind followed by clean retry on the SAME loop;
- healthy renderer bind followed by refused second bind, proving original renderer expectation remains authoritative;
- renderer reconfigured to foreign board after bind -> incoherent/fail closed;
- renderer queued after dispatch but before arrival -> no BoardState/candidate/reservation/finalize/cleared-count mutation until explicit reset cleanup;
- truly-freed renderer after dispatch but before arrival using frame-aware smoke;
- healthy clear changes target pixel alpha only and preserves an unrelated pixel;
- renderer-loss reset remains safe.

Sensitivity must prove the V06 presence bit is still load-bearing. Do not recreate V06 criterion 204's artificial root-runner-vs-smoke distinction.

## Frozen evidence batch D — full arrival-preflight desynchronization matrix

Use a real pending M19 assignment and direct M20 arrival boundary evidence.

Cover independently:
- wrong owner;
- wrong target;
- wrong color;
- wrong source agent;
- unknown owner;
- missing reservation;
- same-board replacement/wrong owner reservation;
- ReservationState rebound to foreign board, including a foreign replacement reservation that must survive cleanup;
- ColorCandidateIndex rebound to foreign board;
- ColorCandidateIndex unbound/neutralized before arrival where safely reproducible;
- target externally already CLEARED;
- configured renderer foreign-board/dead before arrival;
- stale replay after reset;
- duplicate correct completion/current-arrival dedup.

For every reject assert directly:
- target not newly cleared by M20;
- no unrelated candidate/reservation state lost;
- current dispatcher assignment is not silently finalized by the failed preflight;
- cleared_count unchanged;
- reset cleanup is pair-narrow and does not destroy foreign/replacement reservation truth.

## Frozen evidence batch E — activation public-boundary matrix

Direct M20 activation tests must include:
- slot -1 / 5;
- non-int slot;
- unavailable slot;
- finite valid origin/speed;
- Vector2 components NaN/+INF/-INF;
- speed NaN/+INF/-INF/0/negative;
- no-target and enclosed-target no bot/no reservation/no board mutation;
- nested activation remains REENTRANT;
- activation while arrival drain active remains REENTRANT;
- reset during preflight and inside M19 dispatch keeps RESETTING precedence;
- all slot model fields remain unchanged by M20 dispatch success/failure.

## Frozen evidence batch F — fresh SB-M20-001..014 ledger validation

V07 must add/retain direct evidence for all fourteen root tasks in the same full-suite state:

1. complete sequence exact synchronized post-arrival tuple;
2. no target -> no bot;
3. no return -> queue_free and actually gone after frame;
4. true 1x1;
5. one-color repeat until exhausted;
6. multi-color;
7. five configured slots with five unique owners, five distinct targets, five exact reservation pairs; resolve all five;
8. Easy production dimensions;
9. Medium;
10. Hard;
11. Very Hard;
12. 59x59;
13. rectangular production board;
14. state-desync adversary matrix from D plus rollback/reset/duplicate ownership.

Also preserve:
- AL-028 gate A -> second REAL activation selects/routes/clears B;
- rapid 25+ sequential cycles;
- exact unrelated candidate/reservation preservation;
- no normal-clear full-board scan in CompleteClearingLoop;
- M19 V01-V06 regressions.

## Frozen evidence batch G — duplicate ownership/contention

In addition to rejecting a second clearing-loop transaction owner on one dispatcher:
- prove a benign diagnostic `assignment_arrived` observer does not itself block the one M20 owner claim;
- prove one activation yields one canonical clear and one cleared-count increment in the owning loop;
- prove a second loop cannot steal attribution/reset authority by binding the same dispatcher;
- preserve M19 one-by-one/re-entry law.

Do not broaden this into a global singleton redesign or a new ReservationState namespace system. The correction is only the directly-observed same-dispatcher M20 ownership hole.

## Frozen evidence batch H — rollback/reset interaction regressions

Freshly preserve at least one direct arrangement for each:
- candidate mutate-before-false rollback;
- reservation mutate-before-false rollback;
- unrelated same-color candidate loss sensitivity;
- unrelated reservation identity swap -> exact rollback proof or ROLLBACK_FAILED;
- reset during candidate phase;
- reset during reservation phase;
- distinct nested arrival FIFO;
- duplicate current arrival dedup;
- pair-narrow dispatcher reset on original pair;
- foreign-board and same-board replacement reservation preservation;
- post-dispatch generation barrier.

## Frozen documentation reconciliation

Update current, non-historical docs/comments only:
- `tests/run_tests.gd` M20 overview must state renderer AFTER dispatcher finalize;
- `docs/02_TECH_ARCHITECTURE.md` must not claim simultaneous active Scrubbots are hard-bounded by slot count while no per-slot in-flight/busy rule exists. State the actual M20 law: one bot per activation; per-slot/global concurrency limits remain later/design-gated unless explicitly implemented.

Do not rewrite historical prompts/audits merely because their old order is historical evidence.

## Sibling surfaces checked and frozen clean

- explicit agent_factory default-vs-invalidated state: already protected by `_explicit_factory`;
- renderer default-vs-dead: V06 correction accepted;
- RefCounted canonical board/candidate/reservation/slot deps: not externally-freed Node lifecycle class;
- route memo null/present semantics: already M19 regression-locked;
- owner-wide reset cleanup: already pair-narrow regression-locked.

## Interaction surfaces checked

- reset + callback;
- reset + dependency drift;
- lifecycle death + optional dependency;
- rollback + unrelated state;
- duplicate/re-entry + queue/current identity;
- completion + stale identity;
- scale + state synchronization;
- presentation loss + canonical gameplay state;
- duplicate clearing-loop ownership + arrival attribution.

No other material source correction is frozen for V07.

## V07 production scope

Allowed production changes:
- `scripts/gameplay/clearing/complete_clearing_loop.gd` only as needed for the single-consumer claim integration;
- `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` only for the M20 consumer claim and explicit `agent_parent` lifecycle correction.

Read-only production:
- BoardState;
- BoardRenderer;
- SlotSystem;
- ColorCandidateIndex;
- ReservationState;
- TargetSelector;
- ProductionAccessQuery/ProductionTargetAccess/ProductionRoutingSystem;
- ScrubbotAgent.

Allowed test/docs:
- `tests/run_tests.gd`;
- narrow M20/M19 lifecycle smoke/support files;
- `docs/02_TECH_ARCHITECTURE.md`;
- `coordination/sessions/M20-C001/CLAUDE_LOG_V07.md`;
- root `TASKS.md` lifecycle fields only.

## Closure disposition

V07 changes production, therefore it cannot be final M20 closure. A clean V07 correction will be followed by exactly one auditor-authored **V08 validation-only whole-sprint gate** with production immutable. Final SB-M20-001..014 closure is possible only after V08 passes independent ChatGPT audit.
