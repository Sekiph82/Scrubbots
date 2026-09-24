# M39-C001 V04 — Targeted Final Economy Integration Criteria

Authority:
- CHATGPT_AUDIT_V03.md frozen F-M39-V03-001..005
- OWNER_ECONOMY_REWARDS_V01.md
- accepted M23..M30 authority
- M37 V03 AUDITED_PASS

Do not redo accepted V03 repairs.

## 1. Tornado selected-color targeted cancellation

Tornado must work while the selected color has in-flight work.

Before commit, preflight the exact selected-color identities across:
- M26 scheduler assignments;
- M25 claims;
- ReservationState pairs;
- M24 committed work;
- dispatcher/agent identity.

Commit must cancel/reconcile ONLY the selected color:
- selected-color agents cancelled/freed safely;
- selected-color claims/reservations released exactly;
- selected-color committed work rolled back/reconciled;
- selected-color supply/slots removed;
- selected-color ACTIVE cells cleared;
- unrelated colors' live work remains intact.

No global scheduler/dispatcher reset is allowed.

If preflight cannot prove exact coherence, fail closed and consume nothing.

Fault tests must inject failure:
- before targeted cancellation;
- after one selected-color cancellation;
- after claim/work rollback;
- after board mutation;
- after slot/supply mutation.

Every failure restores exact full pre-state and no charge/SB loss.

## 2. Real production local-calendar provider

The shipping EconomyServices/AppState graph must inject a local-calendar provider.

The provider must produce a day identity/ordinal whose next local calendar day is consecutive even across:
- month boundary;
- year boundary;
- leap-day boundary where applicable.

Do not fall back to UTC epoch-day arithmetic in production.

Tests must prove:
- same local day across a UTC boundary does not create a new Daily;
- local-midnight crossing creates the next Daily;
- month/year transition increments correctly;
- clock rollback remains fail-closed;
- relaunch preserves timestamps/high-water state.

## 3. +1 Slot exact rollback

If any step after economy reservation fails, exact pre-state must return:
- charge/SB;
- SlotCapacityAuthority;
- FiveSlotBatchEngine capacity;
- FiveSlotStrip capacity;
- origin/routing state.

No method may return false while M24 remains at six.

Prefer preflight of presentation resize if possible, otherwise add a safe M24 shrink/rollback operation limited to an uncommitted sixth-slot transition.

Add forced strip-growth failure test.

## 4. Atomic progression first-clear transaction

A new frontier WON must commit progression + first-clear reward + Win Streak/Gift Meter + entitlement completion as one coordinated transaction.

Inject failures after:
- progression staged/accepted;
- base first-clear reward;
- streak/Gift Meter update;
- entitlement completion.

On any failure, exact pre-state must be restored for:
- LevelProgressionService;
- wallet;
- Bot Parts;
- streak;
- Gift Meter;
- RewardGrant applied tx set;
- entitlement state.

Stale/future/replay remains zero-mutation.

## 5. Canonical production action seams

Expose one production action surface for:
- +1 Slot;
- Random;
- Selector;
- Tornado;
- current-level/timed 2x purchases;
- Heart purchases;
- Daily/Gift/Collection claims;
- Cards Exchange;
- robot unlock.

The action surface must:
- call canonical services/adapters;
- return explicit success/failure;
- not let UI mutate wallet/service internals directly;
- expose a committed-success notification/result that M40 can bind to persistence.

Final visual UI is not required.

## 6. Regression / gate

Run:
- targeted M19/M25/M26 cancellation tests;
- M23..M30 regressions;
- M37 V03;
- M38 V02;
- all M39 V01..V04 suites;
- root suite;
- git diff --check.

SB-M39-033 remains DEVICE/OWNER_REQUIRED after code audit for real handset sixth-slot safe-area/touch/readability.

Handoff:
`AWAITING_AUDIT / M39-C001 V04 / DEVICE_GATE_REMAINS`
