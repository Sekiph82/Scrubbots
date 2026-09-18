# M26-C001 V02 — Strict Remediation Audit Criteria

Milestone: `M26 — Auto Dispatch Scheduler`
Cycle: `M26-C001 V02`
Prior audit: `coordination/sessions/M26-C001/CHATGPT_AUDIT_V01.md`

## Verdict policy

PASS only if all four M26 V01 findings are closed in production code + direct adversarial evidence, while all accepted V01 behavior and regressions remain green.

## 1. Deferred/generation-safe reset during step

A reset requested while scheduler `step()` is active must not be dropped.

Required:
- monotonic scheduler generation or equivalent;
- reset records intent while step is active;
- active step checks reset/generation after every external/callback-bearing boundary that can inject reset;
- if reset moves before assignment commit, step returns reset/failure and creates zero robot;
- if a M25 claim already exists, it is rolled back safely before reset teardown;
- deferred reset drains after the step unwinds;
- later scheduling still works.

Direct injection points:
- origin-provider callback;
- route/access callback;
- dispatcher preclaimed factory/assign/add-child callback if test seam exists;
- at minimum one reset before dispatch and one reset inside preclaimed dispatch.

## 2. Transaction-safe reset

Reset must return/record success/failure deterministically.

Before destructive M20/dispatcher teardown:
- every scheduler live assignment must still map to an exact live M25 claim;
- rollback of every claim must be guaranteed, or cleanup must be all-or-nothing/compensated.

Required adversarial fixture:
- two live scheduler assignments;
- corrupt/drift one claim's exact M24 work tuple so M25 rollback fails;
- scheduler reset must fail closed BEFORE destroying the healthy sibling or clearing scheduler ledger;
- dispatcher agents/reservations/mappings remain recoverable;
- after repairing the drift, reset succeeds and leaves zero scheduler assignments, M25 claims, dispatcher active agents and scheduler reservations;
- unrelated reservation survives.

## 3. Authenticated-clear finalize ordering

M26 must preserve the scheduler assignment until M25 finalize succeeds.

Notification must match:
- owner;
- target;
- color;
- exact agent instance.

Required:
- wrong agent ignored/fails closed;
- wrong target/color ignored;
- stale/duplicate notification does not decrement quota;
- exact valid notification calls M25.finalize_clear once;
- assignment erased only after true finalize success;
- wake occurs only after success;
- forced finalize failure retains scheduler assignment + M25 claim + M24 committed truth for diagnosis/recovery;
- no quota decrement on failed finalization.

If a fatal scheduler state is introduced, it must block new scheduling until reset/recovery, not silently continue.

## 4. Exact bundle coherence at bind

Scheduler bind must prove:
- M25 exact bound BoardState == scheduler board;
- M25 exact bound M24 == scheduler batch engine;
- M25 exact ReservationState == scheduler reservations;
- M20 exact BoardState == scheduler board;
- M20 exact ReservationState == scheduler reservations;
- M20 exact dispatcher == scheduler dispatcher.

Minimal read-only seams allowed:
- `BatchTargetClaimEngine.is_bound_to(board,batches,reservations)`;
- `CompleteClearingLoop.is_bound_to(board,reservations,dispatcher)`;
or equivalent exact identity queries.

Direct tests:
- coherent bundle accepted;
- foreign M24 rejected;
- foreign M25 board/reservations rejected;
- foreign M20 loop rejected;
- zero signal connection / partial bind side effects on rejection.

## 5. Preserve no-ghost and preclaimed semantics

Re-run:
- no target;
- no claim;
- invalid route;
- mismatched route;
- failed preclaimed assignment;
- exact successful assignment;
- no retarget;
- exactly one agent;
- reservation stays M25-owned until M20 resolves it.

## 6. Preserve pacing/fairness/waiting

Re-run:
- one accepted assignment max per step;
- BLUE8/14/12 spill;
- cross-color round-robin;
- WAITING no churn;
- wake after authenticated clear/resume;
- BLUE15 exactly 15 clears.

## 7. Preserve integration/performance evidence

Re-run:
- full root suite;
- `m26_hazard_bot_integration.gd`;
- `m26_scale_59_sanity.gd`;
- all M25 V01/V02/V03 evidence;
- M24/M23;
- M22 V07/V06/connector;
- representative M20/M19/M18/M21;
- `git diff --check`.

## 8. Governance

- root TASKS.md read-only for Claude;
- no M27;
- no M28 gameplay UI;
- zero image credits;
- implementation commit(s) first;
- `CLAUDE_LOG_V02.md` separate final commit;
- map F-M26-V01-STRICT-001..004 to exact code + tests.

If V02 passes, ChatGPT may close all `SB-M26-001..030` together and advance to M27.
