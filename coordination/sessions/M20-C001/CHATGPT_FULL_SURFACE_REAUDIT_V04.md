# M20-C001 — Full Surface Re-Audit V04

Status: **FINDING SET FROZEN — CORRECTION V04 AUTHORIZED**

Basis:
- `CHATGPT_AUDIT_V03.md`;
- current production commit `28da9701c3185188b4563aaccb73feaf6032c576`;
- Strict Audit Standard v2 / full attack-surface rule.

Top-level finding IDs remain F-M20-STRICT-001..007. This document freezes only residual subfindings so V04 does not become a serial whack-a-mole pass.

## Current accepted baseline

Preserve without redesign:
- CompleteClearingLoop remains the M20 orchestrator;
- exact production-script bind boundary for all six canonical collaborators;
- M19 owns dispatch/agent identity;
- BoardState owns ACTIVE/CLEARED physical truth;
- ColorCandidateIndex owns derived raw color candidates;
- ReservationState owns ephemeral target ownership;
- clear commit order remains BoardState -> candidate -> reservation -> dispatcher finalize -> optional renderer;
- activation and arrival serialization remain;
- distinct nested arrivals remain lossless FIFO;
- current owner+agent arrival dedup remains;
- exact detached reservation owner-map postcondition/rollback remains;
- renderer remains post-commit presentation only;
- no M21/win/lose/scoring/session/slot-policy behavior.

## Public/stateful surface matrix

### `bind(...)`
Check:
- null/scalar/wrong-category each parameter;
- exact production category;
- exact same-bundle identity;
- configured five-slot requirement;
- active dispatcher rejection;
- ordinary second bind preserve;
- nested bind defense;
- Node lifecycle for dispatcher/renderer: live, queued-for-delete, already freed;
- no method call on invalid object;
- no ghost signal connection on failure.

Residual finding: **F-M20-STRICT-001.K**.

### `is_bound()` / `is_coherent()`
Check:
- unbound false;
- healthy exact bundle true;
- candidate/reservation rebind false;
- renderer rebind/free/queue-delete false;
- dispatcher free/queue-delete false without SCRIPT ERROR;
- no stale live claim after Node lifetime ends.

Residual finding: **F-M20-STRICT-001.K**.

### `activate_slot(...)`
Check:
- unbound;
- slot negative/5+/non-int;
- unavailable;
- invalid palette sentinel;
- Vector2 NaN/INF;
- speed <=0 / NaN / +/-INF;
- activation recursion;
- arrival-in-progress recursion;
- reset pending before preflight;
- dependency drift before dispatch;
- reset during M19 dispatch callback;
- M20-only coherence drift during M19 dispatch callback;
- post-dispatch result truth;
- deterministic cleanup before returning reset/coherence failure;
- monotonic owner IDs never reused.

Residual finding: **F-M20-STRICT-002.K**.

### authenticated arrival / serial queue
Check:
- wrong owner/target/color/agent;
- duplicate current arrival;
- duplicate queued arrival;
- distinct nested arrival FIFO;
- stale tuple after reset;
- current identity cleared after all outcomes;
- current/queue remain private;
- exact M19 arrival bridge remains once-only.

Current V03 correction accepted. Regression-only in V04.

### clear transaction
Check:
- BoardState write false/postcondition;
- immutable color;
- candidate sync false/lie/rollback through test-only harness;
- reservation false/lie/collateral swap;
- exact pre/post owner-map;
- dispatcher finalize false/postcondition;
- renderer only after authoritative commit;
- rollback does not report ordinary success unless exact state is proven;
- ROLLBACK_FAILED remains explicit fatal outcome.

Current V03 correction accepted. Regression-only in V04.

### `reset()`
Check:
- unbound;
- idle coherent bundle;
- active assignments;
- reset during activation;
- reset during arrival;
- repeated/nested reset;
- stale queued arrivals;
- candidate/reservation drift;
- reservation destructive rebind to foreign board;
- reservation same-board replacement owner/target drift;
- dispatcher queued for deletion;
- dispatcher already freed;
- no foreign reservation deletion;
- no method call on invalid Node;
- BoardState/candidate truth not rewound;
- owner counter never rewound.

Residual finding: **F-M20-STRICT-006.K**.

### observation getters
`get_cleared_count()` / `get_last_outcome()` remain read-only and detached. No new issue.

## Frozen subfinding F-M20-STRICT-001.K

### Node lifetime category
Exact script identity does not prove a Node is still callable.

V04 law:
- before `get_script()` on a Node/Object, prove instance validity;
- for production Node dependencies that must remain usable, reject `is_queued_for_deletion()` too;
- `bind()` rejects freed/queued dispatcher and renderer without SCRIPT ERROR;
- live `_probe()` checks dispatcher and renderer liveness before calling them;
- `is_coherent()` on a dead/dying dependency returns false;
- `activate_slot()` on a dead/dying dispatcher returns a stable failure rather than faulting;
- reset never calls an already-invalid dispatcher.

Do not apply Node queue-deletion semantics to RefCounted dependencies as if they were Nodes.

### Current-law prose
Correct the stale `bind()` comment that still says candidate/reservation subclasses are accepted. Production exact-category law must be described consistently.

## Frozen subfinding F-M20-STRICT-002.K

`ScrubbotDispatcher.dispatch()` is an external callback-bearing boundary from M20's perspective.

V04 law after dispatcher returns:
1. hold the raw DispatchResult;
2. check M20 `_reset_requested` / generation before trusting it;
3. reset/generation change wins and returns `RESETTING`;
4. re-check full live M20 coherence;
5. coherence loss requests safe cleanup/reset and returns `COHERENCE_FAILED`;
6. only if both barriers pass may caller receive the captured result.

Direct sensitivity must place reset/coherence drift INSIDE an M19 callback after M20 preflight, not before dispatcher entry.

Required reset variant:
- use a callback late enough that uncorrected V03 can otherwise return a successful dispatch;
- call only `loop.reset()` so M19's own generation is not directly changed;
- pre-fix expected observation: stale success can escape, then deferred reset cleans it;
- corrected expected observation: caller gets RESETTING, no live assignment/reservation remains when `activate_slot()` returns.

Required M20-only coherence variant:
- mutate a collaborator M19 does not own, preferably queue-free the optional renderer from an M19 callback;
- uncorrected V03 can return M19 success;
- corrected M20 catches live-coherence loss, cleans the newly-created assignment deterministically, and returns COHERENCE_FAILED.

If an owner ID was already allocated before reset/drift, it may remain consumed. It must never be reused.

## Frozen subfinding F-M20-STRICT-006.K

### Reservation-safe dispatcher reset
M20 may call dispatcher reset after the shared ReservationState has drifted.

The dispatcher owns one immutable target per active entry. Reset cleanup must therefore be pair-narrow, not owner-wide.

For each active entry `(owner O, target T)`:
- prove ReservationState still belongs to dispatcher's original board before any reservation mutation;
- prove `get_target_for_owner(O) == T`;
- prove `get_owner(T) == O`;
- then call exact `release(T, O)`;
- otherwise skip reservation mutation;
- always continue cancelling/detaching/queue-freeing the dispatcher's own agent and removing its own active bookkeeping.

Never use `release_for_owner(O)` as reset authority for an active entry.

Direct adversaries:
1. foreign board B, same owner O, arbitrary B target;
2. foreign board B, same numeric target index T and same owner O;
3. same original board A but O has been moved to V != T;
4. reservation missing entirely;
5. normal coherent exact T<->O pair.

Expected:
- cases 1-4 do not delete unrelated/replacement reservation truth;
- case 5 releases exactly T<->O;
- dispatcher active agent/bookkeeping is cancelled/cleared in all reset cases where dispatcher remains live.

### Invalid dispatcher at M20 reset
- queued dispatcher is incoherent for new work;
- if still instance-valid, reset may clean it while callable;
- already-freed dispatcher must never receive a method call;
- M20 local queue/current/reset bookkeeping reaches a deterministic safe state;
- do not claim impossible agent recovery after an externally destroyed dependency.

## Regression locks

V04 must preserve:
- V03 exact candidate/reservation category rejection;
- V03 owner-map exactness;
- V03 current-arrival dedup;
- V02 clear order and renderer-after-finalize law;
- V02 transactional arrival/reset behavior;
- real 1x1;
- full AL-028 A then second real B activation/clear;
- five simultaneous owner/target/reservation identity;
- first-of-five preserves remaining four;
- failed-preflight reset recovery;
- renderer rollback stays opaque;
- queue_free frame smoke;
- one-color exhaustion;
- multi-color;
- Easy/Medium/Hard/Very Hard;
- 59x59;
- rectangular;
- rapid 25+;
- all M11-M19 strict regressions.

## Scope freeze

Expected production changes:
- `scripts/gameplay/clearing/complete_clearing_loop.gd`;
- minimal reset-only hardening in `scripts/gameplay/dispatch/scrubbot_dispatcher.gd` for F-M20-STRICT-006.K.

No other production file is authorized unless a direct V04 test proves a blocker, in which case STOP `BLOCKED`.

Allowed tests:
- `tests/run_tests.gd`;
- narrow `tests/support/m20_*` / existing M19 support reuse;
- narrow dedicated smoke only if required to isolate freed/queued Node behavior.

Allowed docs:
- current M20 architecture clarification;
- `CLAUDE_LOG_V04.md`;
- root TASKS lifecycle fields.

## Next-stage rule

V04 changes production. Even if V04 source audit is clean, M20 remains a critical orchestration milestone and ChatGPT cannot run Godot independently. Therefore final M20 closure will require a subsequent auditor-authored **V05 validation-only** pass with accepted production blobs locked.
