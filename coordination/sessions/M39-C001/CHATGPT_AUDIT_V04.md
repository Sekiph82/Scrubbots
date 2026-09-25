# M39-C001 V04 — ChatGPT Independent Full-Surface Audit

Date: 2026-09-25
Verdict: **AUDITED_PASS / M39 ECONOMY CODE CLOSED / DEVICE_OWNER_GATE_REMAINS**

Implementation: `3a8943d`
Claude log: `coordination/sessions/M39-C001/CLAUDE_LOG_V04.md`
Criteria: `coordination/sessions/M39-C001/CHATGPT_AUDIT_CRITERIA_V04.md`

## Executive result

Independent source review finds the V04 implementation materially closes
F-M39-V03-001..005.

However final `AUDITED_PASS` is withheld because one explicitly required
regression suite, `tests/m38_v02_strict.gd`, contains a pre-existing runtime
SCRIPT ERROR that aborts `_reward_failure_no_mutation()` while the suite still
prints PASS.

That evidence defect is now tracked by:
`coordination/sessions/M38-C001/CHATGPT_FULL_SURFACE_REAUDIT_V02.md`
and M38 V03.

This is an evidence/regression gate, not a newly found M39 V04 production defect.

## Pass A — implementation/state sweep

### F-M39-V03-001 Tornado targeted selected-color cancellation — SOURCE/DIRECT TEST ACCEPTED

Accepted:
- read-only selected-color identity preflight;
- exact scheduler -> M25 claim -> reservation pair -> M24 work -> dispatcher agent coherence;
- reversible detach/reattach;
- targeted agent cancellation only after reversible stages pass;
- no global generation/reset;
- unrelated color work preserved;
- board/slot/supply rollback stages are explicit.

V04 also corrected two real V03 defects:
- scheduler snapshot key mismatch (`color` vs `color_id`);
- captured supply rollback state.

The irreversible agent-cancel phase is preflighted synchronously before the
first cancellation. `cancel_owner` has no cross-owner callback and cancellation
of one owner does not invalidate another preflighted owner, so no material
closure defect is found in the current finalization sequence.

### F-M39-V03-002 production local calendar — SOURCE/DIRECT TEST ACCEPTED

Accepted:
- production AppState injects `LocalCalendar.system_provider()`;
- OS local date is used instead of unix/86400;
- civil ordinal handles month/year/leap boundaries;
- deterministic offset providers exist for tests;
- Daily persisted timestamp/high-water state remains intact.

### F-M39-V03-003 +1 Slot rollback — SOURCE/DIRECT TEST ACCEPTED

Accepted:
- engine `rollback_grow_to_sixth()` exists for the uncommitted transition;
- economy reservation, capacity authority, engine and strip are restored on
  forced engine/strip failure;
- SB refund price propagation was fixed;
- direct V04 fault tests cover charge and SB payment paths.

### F-M39-V03-004 atomic first-clear — SOURCE/DIRECT TEST ACCEPTED

Accepted:
- `FirstClearTransaction` snapshots progression + full EconomyServices;
- frontier decision occurs first;
- first-clear, streak/Gift, entitlement are staged;
- any forced downstream failure imports both pre-snapshots;
- stale/future/replay remains zero-mutation.

### F-M39-V03-005 canonical production action facade — SOURCE/DIRECT TEST ACCEPTED

Accepted:
- all four boosters;
- Heart/2x purchase paths;
- Daily/Gift/Collection claims;
- exchange;
- robot unlock;
- explicit success/failure result;
- committed-success save callback/signal;
- failed actions do not emit/save;
- gameplay boosters require a host.

Final visual UI remains outside M39.

## Pass B — evidence/test/policy sweep

Direct V04 tests are load-bearing for:
- same-color in-flight Tornado success + unrelated-color preservation;
- per-stage Tornado rollback;
- local-calendar boundaries;
- engine/strip +1 rollback;
- first-clear fault stages;
- action-facade save/emit count.

The aggregate root result `5336/0` is NOT accepted as sufficient regression
evidence because M38 strict emits a runtime SCRIPT ERROR yet still exits 0.

### Regression evidence gap

M39 V04 criteria explicitly require M38 V02 regression.

Claude's own log correctly disclosed:
`m38_v02_strict` PASS + SCRIPT ERROR in the reward-failure sub-check.

Therefore SB-M39-052 remains open until M38 V03 repairs the harness and the
required M39 V04 suites are rerun against that repaired evidence.

## Interaction sweep

Checked:
- Tornado targeted cancel + unrelated active work;
- Tornado rollback + claims/reservations/M24 work;
- +1 rollback + presentation/origin;
- first-clear rollback + RewardGrant/Gift/Streak/entitlement;
- action facade + persistence callback;
- local-day state + M40 save/relaunch.

No additional material M39 production defect found.

## Sprint task ledger

| Task | Status | Audit note |
|---|---|---|
| SB-M39-001 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-002 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-003 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-004 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-005 | PROVEN | V04 remediation source + direct adversarial evidence reviewed; material finding closed. |
| SB-M39-006 | PROVEN | V04 remediation source + direct adversarial evidence reviewed; material finding closed. |
| SB-M39-007 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-008 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-009 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-010 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-011 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-012 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-013 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-014 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-015 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-016 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-017 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-018 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-019 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-020 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-021 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-022 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-023 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-024 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-025 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-026 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-027 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-028 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-029 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-030 | PROVEN | V04 remediation source + direct adversarial evidence reviewed; material finding closed. |
| SB-M39-031 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-032 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-033 | OWNER_GATE | Sixth-slot code/presentation/origin path accepted; real handset safe-area/touch/readability remains DEVICE/OWNER_REQUIRED. |
| SB-M39-034 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-035 | PROVEN | V04 remediation source + direct adversarial evidence reviewed; material finding closed. |
| SB-M39-036 | PROVEN | V04 remediation source + direct adversarial evidence reviewed; material finding closed. |
| SB-M39-037 | PROVEN | V04 remediation source + direct adversarial evidence reviewed; material finding closed. |
| SB-M39-038 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-039 | PROVEN | V04 remediation source + direct adversarial evidence reviewed; material finding closed. |
| SB-M39-040 | PROVEN | V04 remediation source + direct adversarial evidence reviewed; material finding closed. |
| SB-M39-041 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-042 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-043 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-044 | PROVEN | V04 remediation source + direct adversarial evidence reviewed; material finding closed. |
| SB-M39-045 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-046 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-047 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-047A | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-047B | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-047C | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-048 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-049 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-050 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-051 | PROVEN | Prior V03 proof retained; V04 interactions reviewed. |
| SB-M39-052 | GAP | M39 V04 direct suites are green, but required M38 strict regression is false-positive until M38 V03 repairs the aborted reward-failure sub-test. |

## Current M39 state

Code-side open:
- SB-M39-052 only, pending repaired M38 strict regression evidence.

Owner/device open:
- SB-M39-033 real handset sixth-slot safe-area/touch/readability.

Verdict string:
`CODE_AUDIT_PASS / M39-C001 V04 / SB-M39-052 REGRESSION_REQUIRED / SB-M39-033 DEVICE_OWNER_REQUIRED`


## Final regression-gate closure — 2026-09-25

M38 V03 repaired the previously false-positive strict suite without changing
production M38 code.

The repaired suite now:
- executes the reward-failure/no-mutation path with a true RewardGrantService subclass;
- reports 11/11 expected cases complete;
- contains no SCRIPT ERROR;
- fails nonzero when a named case aborts.

Claude then reran the M39 V04 required regressions:
- `m39_v04_integration.gd`: PASS
- `m39_v04_tornado_inflight.gd`: PASS
- repaired `m38_v02_strict.gd`: PASS 11/11, no SCRIPT ERROR
- `m40_v04_bootstrap.gd`: PASS
- root: 5336 checks / 0 failures

Therefore SB-M39-052 regression evidence is now closed.

M39 code/audit status:
- all code tasks: AUDITED_PASS
- SB-M39-033: remains DEVICE/OWNER_REQUIRED for real-phone sixth-slot
  safe-area/touch/readability.

Final verdict string:
`AUDITED_PASS / M39 ECONOMY CODE CLOSED / SB-M39-033 DEVICE_OWNER_REQUIRED`
