# M26-C001 V01 — ChatGPT Strict Audit

Date: 2026-09-18
Repository: `Sekiph82/Scrubbots`
Milestone: `M26 — Auto Dispatch Scheduler`
Cycle: `M26-C001 V01`
Auditor: ChatGPT
Implementation SHA: `1bd49497f3e67cedb63952397b1f48a68d12c228`
Claude log: `coordination/sessions/M26-C001/CLAUDE_LOG_V01.md`
Criteria: `coordination/sessions/M26-C001/CHATGPT_MASTER_AUDIT_CRITERIA_V01.md`

## Verdict

**CHANGES_REQUIRED / FULL M26 IMPLEMENTED / FOUR M26-LOCAL TRANSACTION & COHERENCE DEFECTS REMAIN**

Claude implemented the full `SB-M26-001..030` surface in one implementation commit. This is not a partial work-package handoff.

The major architecture is accepted provisionally:
- M25 remains target-claim authority;
- preclaimed dispatcher path avoids a second target selection/reservation;
- no-target/no-route/no-claim paths spawn zero robots;
- one accepted scheduler step creates at most one robot;
- BLUE 8/14/12 same-color ordering remains delegated to M25;
- authenticated clear bridge exists;
- Hazard Bot and 59x59 evidence are substantial;
- root suite reported 5193/0.

However, four M26-local transaction/coherence defects are blocking closure.

## Governance / diff integrity

Verified start -> implementation:
- start `dc8e27f7f3347cc479dbfbc327a9a8bb5e67903b`
- implementation `1bd49497f3e67cedb63952397b1f48a68d12c228`

Implementation changes only M26-related production/test files plus the narrow dispatcher/M20 integration seams. Root `TASKS.md` is absent. M27/M28 implementation is absent.

Implementation -> main is one log-only commit containing `CLAUDE_LOG_V01.md`.

## F-M26-V01-STRICT-001 — scheduler reset request is LOST during an active step

`AutoDispatchScheduler.reset()` currently does:

```
if _resetting or _in_step:
    return
```

This is not a deferred reset. A reset requested synchronously from any callback boundary while `step()` is active is silently discarded.

Therefore an outer step may continue to:
- keep the M25 claim;
- route;
- call `dispatch_preclaimed`;
- spawn/register a robot;

even though reset was requested before spawn.

The master prompt/criteria explicitly require reset-generation invalidation and direct evidence for reset injected before spawn.

Required correction:
- reset during step must record intent/generation and be drained at a safe point;
- the active step must observe generation movement after every callback-bearing boundary and abort/rollback before spawn/public success;
- no reset request may disappear merely because `_in_step` is true.

## F-M26-V01-STRICT-002 — reset ignores failed M25 rollback and then destroys remaining authority truth

M26 reset loops:

```
for owner_id in _assignments.keys():
    _claim.rollback_claim(claim_id)
_loop.reset()
_assignments.clear()
```

The boolean result of `rollback_claim` is ignored.

If one exact M25 claim tuple is incoherent and rollback returns false:
1. M25 may still retain the claim/M24 committed work;
2. M26 still calls M20/dispatcher reset, potentially releasing/cancelling reservation/agent truth;
3. M26 still clears its own assignment ledger.

This can create an orphan M25/M24 committed tuple with no scheduler mapping and no dispatcher agent.

Required correction:
- preflight/transactional reset;
- do not destroy dispatcher/reservation truth or clear scheduler ledger when any M25 rollback cannot be proven/committed;
- define deterministic failure result;
- healthy multi-claim reset remains idempotent;
- direct adversarial fixture with one intentionally incoherent live claim + one healthy sibling.

## F-M26-V01-STRICT-003 — authenticated-clear mapping is erased before M25 finalization succeeds

`_on_authenticated_clear()` currently:
1. reads scheduler assignment;
2. erases `_assignments[owner_id]`;
3. calls `_claim.finalize_clear(claim_id)`;
4. ignores the boolean result;
5. wakes waiting colors.

If `M25.finalize_clear` fails because the exact M24 work tuple was externally drifted/stale, the scheduler has already lost the only owner->claim mapping.

That turns a recoverable/fail-closed inconsistency into a stranded M25 claim/M24 committed state with no scheduler ledger entry.

Required correction:
- verify immutable identity including exact agent, not just owner/target/color;
- call M25 finalization first;
- erase scheduler assignment only after finalization succeeds;
- wake only after successful finalization;
- on failure preserve assignment/claim mapping and surface deterministic fatal/failure state rather than pretending completion.

Direct tests must include:
- exact successful authenticated clear;
- duplicate/stale notification;
- wrong agent with otherwise correct owner/target/color;
- forced M25 finalize failure from exact-work drift;
- scheduler ledger retained on failure and no quota double-decrement.

## F-M26-V01-STRICT-004 — scheduler bind does not prove one exact cross-engine bundle

M26 bind checks:
- M25 `is_bound()` only;
- M24 script category only;
- M20 `is_bound()` only.

It does not prove that:
- M25 is bound to this exact BoardState, this exact M24 engine, this exact ReservationState;
- M20 is bound to this exact BoardState, exact ReservationState and exact dispatcher;
- the supplied M24 is the same one M25 owns.

A scheduler can therefore bind individually-valid collaborators from different sessions.

Required correction:
- add only minimal read-only coherence seams where needed;
- M25 should expose exact `is_bound_to(board,batches,reservations)` or equivalent;
- M20 arrival-only/legacy loop should expose exact `is_bound_to(board,reservations,dispatcher)` or equivalent;
- scheduler bind must reject foreign M24/M25/M20 bundles with zero side effects;
- do not expose mutable internal references.

## Accepted V01 behavior to preserve

V02 is a narrow remediation. Preserve:
- preclaimed dispatcher architecture;
- no second TargetSelector/reservation;
- exact reservation owner/target proof;
- no ghost on no target/no claim/no route;
- one assignment per step;
- deterministic cross-color fairness;
- M25 same-color arbitration;
- WAITING no-churn;
- BLUE15 exact completion;
- Hazard Bot real-slot-anchor routing evidence;
- 59x59 sanity;
- legacy M19/M20 APIs and regressions.

## Closure decision

Do not close `SB-M26-001..030` yet.

Open one `M26-C001 V02` remediation containing ONLY the four findings above. Do not re-open M25. Do not implement M27.
