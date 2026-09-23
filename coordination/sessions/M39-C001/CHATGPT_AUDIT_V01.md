# M39-C001 V01 — ChatGPT Audit

Date: 2026-09-24
Verdict: **CHANGES_REQUIRED / M39-C001 V01 / FINDING_SET_FROZEN**

Implementation commits:
`0974ad3`, `43f635b`, `f549764`, `940f38a`, `25332d1`
Claude log: `coordination/sessions/M39-C001/CLAUDE_LOG_V01.md`

M39 is critical/stateful. The following material findings are frozen for V02.

## F-M39-001 — M24 live 5/6 slot integration is incomplete
Claude itself records SB-M39-031 PARTIAL_INTEGRATION.
`SlotCapacityAuthority` exists, but the real `FiveSlotBatchEngine` remains the locked five-slot implementation and was not modified in the M39 commits.

A capacity authority that the live engine does not consume does not satisfy authoritative capacity 5/6.

## F-M39-002 — M27 proof/canonical state does not include capacity
SB-M39-032 is explicitly PARTIAL_INTEGRATION.
The real proof state/solver files were not modified in M39. Therefore 5-slot and 6-slot solver state are not end-to-end canonicalized/proven.

## F-M39-003 — Random/Selector/Tornado are adapter-only, not production-integrated
`BoosterService` is written against a duck-typed adapter.
No production engine adapter implementation is present and no production M23/M24/M25/M26/M27 runtime file consumes BoosterService.

Therefore:
- Random does not actually reorder authoritative M23 remaining supply;
- Selector does not actually extract from authoritative supply into real rightmost EMPTY slot;
- Tornado does not actually reconcile live BoardState/supply/slots/claims/agents/solver.

The unit tests prove a fake adapter contract, not the shipping cross-engine transaction.

This blocks SB-M39-034..040, not only 031/032.

## F-M39-004 — shipping manual 2x is not gated by SpeedEntitlementService
SpeedEntitlementService exists as a standalone service, but the M39 phase commits do not modify the existing production speed request path/GameplaySpeedAuthority integration.
Thus SB-M39-027 is not proven in shipping runtime.

The free M23-exhausted automatic 2x must remain entitlement-independent while manual requests are gated.

## F-M39-005 — EconomyServices.import_snapshot is not actually all-or-nothing
The method mutates live services sequentially and returns false on the first later failure without rolling back earlier successful imports.

Its comment claims all-or-nothing staging, but no staging/rollback exists inside EconomyServices itself.

M40's outer SaveService may restore after a failed load, but M39's aggregate import contract remains independently unsafe and can be called outside SaveService.

## F-M39-006 — integer-domain validation silently accepts fractional values
Multiple state imports accept TYPE_FLOAT and convert with `int()`, including wallet balances, booster charges, card counts and other integer-only economy state.

Example class of defect: a persisted/malformed value such as 1.9 can be accepted and silently truncated to 1 instead of failing closed.

The criteria require integer balances/counts.

## F-M39-007 — Cards Exchange transaction can credit before removal and ignores removal failure
`CardsExchangeService.exchange_card()` and `exchange_all_extras()` grant SB before removing copies, then ignore the boolean result of `remove_copies()`.

A failed/inconsistent removal after credit can create SB without consuming the intended duplicates. V02 must implement real all-or-nothing exchange with rollback/fault-injection evidence.

## F-M39-008 — Daily task state is not fully snapshot-persisted
`DailyService.snapshot()` stores only `last_claim_day` and login `streak`.
It does not persist current-day task completion state / task claim presentation state required by the owner save requirements and M40 criteria.

Reward transaction IDs prevent some double-grants, but they do not restore the Daily task state itself.

## F-M39-009 — collection/import validation accepts noncanonical state
Collection snapshot import does not reject unknown card IDs before storing them and accepts fractional counts via integer coercion. Claimed set IDs are not tightly validated against 1..15.

This violates fail-closed collection/save state requirements.

## F-M39-010 — runtime economy composition is not wired into the production gameplay flow
M39 adds services/tests/composition root but does not modify the production gameplay composition to connect progression outcomes, Heart loss/restart, first-clear reward, Win Streak, current-level completion entitlement clearing and booster actions to the live runtime.

Service-level correctness alone is insufficient for shipping Economy V1 event authority.

## Device gate
SB-M39-033 sixth-slot mobile safe-area evidence remains DEVICE/OWNER_REQUIRED after real 5/6 runtime integration exists.

## Required next step
V02 is a full integration + atomicity remediation, followed by strict adversarial validation. Do not patch only 031/032.

Verdict string:
`CHANGES_REQUIRED / M39-C001 V01 / FINDING_SET_FROZEN`
